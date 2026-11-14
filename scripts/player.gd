class_name RoutePlayer
extends CharacterBody2D
## State-based actor: locomotion, melee, interaction, hurt and death never overlap.
signal damaged(amount: int)
signal died
signal interaction_finished(action: String)
const SPEED := 105.0
const MAX_RESERVE := 36
const WALK_ART = preload("res://scripts/nico_walk_art.gd")
var lateral_walk_active := false
var walk_distance := 0.0
var level: Node2D
var sprite: AnimatedSprite2D
var health := 100
var facing := Vector2.RIGHT
var direction := 6
var action := "idle"
var action_time := 0.0
var attack_elapsed := 0.0
var hit_done := false
var invulnerability := 0.0
var knockback := Vector2.ZERO
var steps := 0.0
var carrying := false
var dead := false
var controls_enabled := true
var has_pistol := false
var pistol_equipped := false
var magazine := 12
var reserve := MAX_RESERVE
var switch_target := true

func _ready() -> void:
	collision_layer = 1
	collision_mask = 4
	var shape := CollisionShape2D.new()
	var capsule := CircleShape2D.new()
	capsule.radius = 9.0
	shape.shape = capsule
	add_child(shape)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = RouteArt.frames("nico")
	sprite.scale = Vector2.ONE * 0.34
	sprite.position = Vector2(0, -24)
	add_child(sprite)
	RouteArt.bind_character_clip(sprite)
	sprite.frame_changed.connect(sync_sprite_anchor)
	animate("idle")

func animate(next: String) -> void:
	var previous_action := action
	var previous_frame := sprite.frame
	var previous_progress := sprite.frame_progress
	action = next
	var armed := has_pistol and pistol_equipped
	lateral_walk_active = next in ["idle", "walk"] and WALK_ART.supports(direction)
	if lateral_walk_active:
		var frames: SpriteFrames = WALK_ART.frames(armed)
		if sprite.sprite_frames != frames: sprite.sprite_frames = frames
		sprite.flip_h = WALK_ART.flipped(direction, armed)
		sprite.scale = Vector2.ONE * WALK_ART.scale_for(direction, armed)
		sprite.position = Vector2(0, -WALK_ART.ground(direction, armed))
		sprite.offset = Vector2.ZERO
		(sprite.material as ShaderMaterial).set_shader_parameter("alpha_cutoff", 0.5)
		sprite.play(next + "_" + str(direction))
		if next == "idle":
			walk_distance = 0.0
			sprite.set_frame_and_progress(0, 0.0)
			sprite.pause()
		else:
			# Locomotion follows real travel, not the render clock or input alone.
			if previous_action != "walk": walk_distance = 0.0
			var pose: Vector2 = WALK_ART.sample(walk_distance)
			sprite.set_frame_and_progress(int(pose.x), pose.y)
			sprite.pause()
		return
	sprite.sprite_frames = RouteArt.pistol_frames() if armed else RouteArt.frames("nico")
	var source := "walk" if next == "idle" else "reload" if next in ["pickup_package","delivery","equip"] else next
	sprite.flip_h = RouteArt.pistol_flip(source,direction) if armed else direction == 3
	if armed:
		var scale_ := 55.0 / RouteArt.pistol_height(source,direction)
		sprite.scale = Vector2.ONE * scale_
		sprite.position = Vector2(0,-82*scale_)
	else:
		sprite.scale = Vector2.ONE * 0.34
		sprite.position = Vector2(0,-24)
	(sprite.material as ShaderMaterial).set_shader_parameter("alpha_cutoff",0.72 if armed else 0.0)
	sprite.play(next + "_" + str(direction))
	# Idle and walk begin with the same pose; idle holds it completely still.
	if next == "idle":
		sprite.set_frame_and_progress(0, 0.0)
		sprite.pause()
	elif next == "walk" and previous_action == "walk":
		sprite.set_frame_and_progress(previous_frame % 6, previous_progress)
	sync_sprite_anchor()

func sync_sprite_anchor() -> void:
	# Stabilize the head while walking; legs retain all six animated frames.
	# This changes the display pivot, not the approved PNG or collision body.
	sprite.offset = Vector2.ZERO
	if lateral_walk_active: return
	if action == "walk" and not pistol_equipped:
		sprite.offset = RouteArt.nico_anchor("idle", direction, 0) - RouteArt.nico_anchor("walk", direction, sprite.frame)

func _physics_process(delta: float) -> void:
	if level.blocked or level.freeze_time > 0: return
	invulnerability = maxf(0, invulnerability - delta)
	sprite.modulate = Color(1.8, 0.65, 0.65) if invulnerability > 0 and int(invulnerability * 18) % 2 == 0 else Color.WHITE
	if dead:
		action_time -= delta
		if action_time <= 0:
			set_physics_process(false)
			died.emit()
		return
	if action_time > 0:
		action_time -= delta
		attack_elapsed += delta
		if action == "knife_attack" and not hit_done and attack_elapsed >= 0.17:
			hit_done = true
			level.player_strike(self)
		velocity = knockback
		# The pistol allows a controlled strafe, including while reloading.
		if controls_enabled and action in ["shoot","reload"]:
			velocity += RouteControls.movement() * SPEED * 0.65
		knockback = knockback.move_toward(Vector2.ZERO, delta * 380.0)
		move_and_slide()
		position = level.clamp_actor(position)
		if action_time <= 0:
			var finished := action
			if finished == "equip": pistol_equipped = switch_target
			if finished == "reload": complete_reload()
			animate("idle")
			if finished in ["pickup_package", "delivery"]: interaction_finished.emit(finished)
		return
	if not controls_enabled: return
	if has_pistol and Input.is_action_just_pressed("route_switch"):
		switch_weapon()
		return
	if has_pistol and pistol_equipped and Input.is_action_just_pressed("route_reload"):
		begin_reload()
		if action_time > 0: return
	var move := RouteControls.movement()
	if move.length_squared() > 0:
		facing = move.normalized()
		direction = RouteControls.direction_index(facing)
	if RouteControls.attacking():
		begin_attack()
		return
	var previous_position := position
	velocity = move * SPEED
	move_and_slide()
	position = level.clamp_actor(position)
	var travelled := position.distance_to(previous_position)
	if move.length_squared() > 0 and travelled > 0.01:
		if action != "walk": walk_distance = 0.0
		walk_distance += travelled
		animate("walk")
	else:
		animate("idle")
	if travelled > 0.01:
		steps += delta
		if steps >= 0.25:
			steps = 0
			level.audio.cue("step", -24, randf_range(0.9, 1.1))

func begin_attack() -> void:
	if dead or action_time > 0 or level.blocked: return
	if has_pistol and pistol_equipped:
		fire_pistol()
		return
	# Small aim assist turns toward a nearby attacker, without extending reach.
	var nearest = level.nearest_enemy(position, 48.0)
	if nearest != null:
		facing = (nearest.position - position).normalized()
		direction = RouteControls.direction_index(facing)
	animate("knife_attack")
	action_time = 0.49
	attack_elapsed = 0.0
	hit_done = false
	level.audio.cue("knife", -12, randf_range(0.93, 1.05))

func take_damage(amount: int, source: Vector2) -> void:
	if dead or invulnerability > 0 or level.blocked: return
	var actual := mini(amount, health)
	health -= actual
	damaged.emit(actual)
	invulnerability = 0.95
	knockback = (position - source).normalized() * 100.0
	level.spawn_fx(position + Vector2(0, -20), 8, 0.30)
	level.shake = 3.0
	if health <= 0:
		dead = true
		level.audio.cue("death_nico", -9)
		animate("death")
		action_time = 0.9
	else:
		level.audio.cue("hurt", -9)
		animate("hurt")
		action_time = 0.28

func interact_animation(next: String) -> void:
	if dead or action_time > 0: return
	direction = 4
	animate(next)
	action_time = 0.80
	attack_elapsed = 0

func begin_reload() -> void:
	if dead or level.blocked or action_time > 0 or not pistol_equipped or magazine >= 12 or reserve <= 0: return
	animate("reload")
	action_time = 1.2
	level.audio.cue("reload",-14)

func fire_pistol() -> void:
	if magazine <= 0:
		if reserve > 0: begin_reload()
		else: level.audio.cue("empty",-17)
		return
	if not RouteControls.touch_mode and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		facing = (get_global_mouse_position()-position-Vector2(0,-20)).normalized()
	else:
		facing = level.assisted_aim(position,280,facing)
	if facing == Vector2.ZERO: facing = Vector2.RIGHT
	direction = RouteControls.direction_index(facing)
	magazine -= 1
	animate("shoot")
	action_time = 0.26
	level.pistol_shot(self)

func switch_weapon() -> void:
	if not has_pistol or dead or level.blocked or action_time > 0: return
	switch_target = not pistol_equipped
	pistol_equipped = true
	animate("equip")
	if not switch_target: sprite.play_backwards("equip_"+str(direction))
	action_time = 0.32

func complete_reload() -> void:
	var amount := mini(12-magazine,reserve)
	magazine += amount
	reserve -= amount
