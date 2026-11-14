class_name RouteEnemy
extends CharacterBody2D
## Finite enemy instance. Death keeps the last animation frame as a corpse.
signal killed(enemy: RouteEnemy)
const VARIANT_ART = preload("res://scripts/zombie_variant_art.gd")
# -1 selects a random basic design on spawn; 0 is the original elderly man.
var appearance := -1
var allow_basic_variants := true
var level: Node2D
var sprite: AnimatedSprite2D
var max_health := 86
var health := 86
var resistant := false
var direction := 0
var action := "idle"
var timer := 0.0
var cooldown := 0.0
var attack_elapsed := 0.0
var hit_done := false
var dead := false
var knockback := Vector2.ZERO
var health_bar: ProgressBar
var seed_offset := 0.0
var difficulty := 1.0
var path := PackedVector2Array()
var path_timer := 0.0
var speed_multiplier := 1.0
var damage_override := 0
var attack_windup := 0.38
var attack_duration := 0.85
var attack_interval := 1.5
var attack_start_distance := 25.0
var attack_reach := 32.0

func _ready() -> void:
	if not allow_basic_variants:
		appearance = 0
	elif resistant:
		appearance = VARIANT_ART.RESISTANT
	elif appearance < 0:
		appearance = VARIANT_ART.choose()
	collision_layer = 2
	collision_mask = 4
	if resistant:
		max_health = 190
		health = max_health
	max_health = roundi(max_health * difficulty)
	health = max_health
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9
	col.shape = circle
	add_child(col)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = VARIANT_ART.frames(appearance) if appearance > 0 else RouteArt.frames("zombie")
	sprite.scale = Vector2.ONE * (0.39 if resistant else 0.34)
	sprite.position = Vector2(0, -24 if not resistant else -28)
	# The resistant sheet already contains the approved red palette.
	add_child(sprite)
	RouteArt.bind_character_clip(sprite)
	if appearance > 0:
		(sprite.material as ShaderMaterial).set_shader_parameter("alpha_cutoff",0.72)
	sprite.frame_changed.connect(sync_sprite_anchor)
	health_bar = ProgressBar.new()
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("b94c54")
	health_bar.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("252832")
	health_bar.add_theme_stylebox_override("background", background)
	health_bar.add_theme_font_size_override("font_size", 1)
	add_child(health_bar)
	health_bar.position = Vector2(-16, -68 if appearance == VARIANT_ART.RESISTANT else -54)
	health_bar.size = Vector2(32, 3)
	health_bar.visible = resistant
	seed_offset = float(get_instance_id() % 100) * 0.1
	animate("idle")

func animate(next: String) -> void:
	action = next
	if appearance > 0:
		sprite.flip_h = VARIANT_ART.flipped(appearance,next,direction)
		sprite.scale = Vector2.ONE*VARIANT_ART.scale_for(appearance,next,direction)
		sprite.position = Vector2(0,-VARIANT_ART.ground(appearance,next,direction))
	sprite.play(next + "_" + str(direction))
	if next == "idle":
		sprite.set_frame_and_progress(0, 0.0)
		sprite.pause()
	sync_sprite_anchor()

func sync_sprite_anchor() -> void:
	# Hold the same head pivot through locomotion; legs retain all six frames.
	# Combat animations and physical hit recoil keep their original motion.
	sprite.offset = Vector2.ZERO
	if appearance > 0:
		sprite.flip_h = VARIANT_ART.flipped(appearance,action,direction,sprite.frame)
		return
	if action == "walk":
		sprite.offset = RouteArt.zombie_walk_anchor(direction, 0) - RouteArt.zombie_walk_anchor(direction, sprite.frame)

func _physics_process(delta: float) -> void:
	if dead or level.blocked or level.freeze_time > 0: return
	cooldown = maxf(0, cooldown - delta)
	if timer > 0:
		timer -= delta
		attack_elapsed += delta
		if action == "attack" and not hit_done and attack_elapsed >= attack_windup:
			hit_done = true
			if position.distance_to(level.player.position) < attack_reach:
				level.player.take_damage(damage_override if damage_override > 0 else 22 if resistant else 15, position)
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO, delta * 260)
		move_and_slide()
		position = level.clamp_enemy(position)
		if timer <= 0: animate("idle")
		return
	if level.player.dead:
		animate("idle")
		return
	var target := movement_target()
	var toward: Vector2 = target - position
	direction = RouteControls.direction_index(toward)
	if position.distance_to(level.player.position) < attack_start_distance and cooldown <= 0:
		animate("attack")
		timer = attack_duration
		attack_elapsed = 0
		hit_done = false
		cooldown = attack_interval
		attack_started()
		return
	var spacing := Vector2.ZERO
	for enemy in level.enemies:
		if enemy == self or enemy.dead: continue
		var difference: Vector2 = position - enemy.position
		if difference.length() < 22:
			spacing += difference.normalized() * 14
	if toward.length() > 22:
		var heading := toward.normalized()
		if level.level_number >= 2:
			path_timer -= delta
			if path_timer <= 0:
				path = level.enemy_path(position,target)
				path_timer = 0.35
			while path.size() > 1 and position.distance_to(path[0]) < 9: path.remove_at(0)
			if not path.is_empty(): heading = (path[0]-position).normalized()
		velocity = heading * movement_speed() + spacing
		move_and_slide()
		position = level.clamp_enemy(position)
		animate("walk")
	else:
		animate("idle")

func take_damage(amount: int, source: Vector2) -> void:
	if dead: return
	health = maxi(0, health - amount)
	health_bar.value = health
	health_bar.show()
	knockback = (position - source).normalized() * (45 if resistant else 110)
	level.spawn_fx(position + Vector2(0, -20), 1, 0.22)
	if health <= 0:
		dead = true
		collision_layer = 0
		collision_mask = 0
		health_bar.hide()
		animate("death")
		level.audio.cue(death_sound(), -16)
		killed.emit(self)
	else:
		animate("hurt")
		timer = 0.28

func movement_target() -> Vector2:
	return level.player.position

func movement_speed() -> float:
	return (19.0 if resistant else 24.0)*difficulty*speed_multiplier

func death_sound() -> String:
	return "resistant_death" if resistant else "death"

func attack_started() -> void:
	pass
