class_name AnchoredEnemy
extends MetroEnemy
## Telegraph -> locked attack -> recovery. Damage never cancels a telegraph or hides an attack.
var state := "approach"
var state_time := 0.0
var attack_number := 0
var locked_heading := Vector2.RIGHT
var phase_two := false
var phase_pending := false
var cue: Label
func _ready() -> void:
	max_health = 2400
	health = max_health
	awareness = 2
	show_awareness_icon = false
	collision_layer = 2
	collision_mask = 4
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 24
	shape.shape = circle
	add_child(shape)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = HarborArt.boss_frames()
	var canvas: Array = HarborArt.data().boss_canvas
	sprite.scale = Vector2.ONE*(118.0/float(canvas[1]))
	sprite.offset.y = -float(canvas[1])/2
	add_child(sprite)
	MetroArt.cutout(sprite)
	sprite.frame_changed.connect(sync_sprite_anchor)
	sprite.animation_changed.connect(sync_sprite_anchor)
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(-64,-125)
	health_bar.size = Vector2(128,7)
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.show_percentage = false
	health_bar.add_theme_font_size_override("font_size",1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("913c50")
	health_bar.add_theme_stylebox_override("fill",fill)
	var back := StyleBoxFlat.new()
	back.bg_color = Color("18202b")
	health_bar.add_theme_stylebox_override("background",back)
	add_child(health_bar)
	health_bar.size = Vector2(128,6)
	cue = Label.new()
	cue.position = Vector2(-100,-145)
	cue.size = Vector2(200,18)
	cue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cue.add_theme_font_size_override("font_size",10)
	add_child(cue)
	animate("walk")
func animate(next: String) -> void:
	action = next
	if next=="walk" or sprite.sprite_frames.has_animation(next): sprite.play("walk_"+str(direction) if next=="walk" else next)
func sync_sprite_anchor() -> void:
	# Exclude only pixels owned by neighbouring atlas figures, without trimming our own limbs.
	if not sprite.sprite_frames.has_animation(sprite.animation): return
	var tex := sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	if tex==null or sprite.material==null: return
	var cuts: PackedVector4Array = tex.get_meta("harbor_exclusions",PackedVector4Array())
	var shader_material := sprite.material as ShaderMaterial
	shader_material.set_shader_parameter("excluded_count",cuts.size())
	if not cuts.is_empty():
		cuts.resize(256)
		shader_material.set_shader_parameter("excluded_rects",cuts)
func enter(next: String, seconds: float, animation: String, text: String = "") -> void:
	state = next
	state_time = seconds
	hit_done = false
	cue.text = text
	animate(animation)
func _physics_process(delta: float) -> void:
	if dead: return
	if level.blocked or level.freeze_time>0 or level.player.dead:
		sprite.pause()
		return
	if not sprite.is_playing(): animate(action)
	if level.guard_intro_time>=0: return
	state_time -= delta
	var toward: Vector2 = level.player.position-position
	if state=="approach":
		direction = RouteControls.direction_index(toward)
		sprite.flip_h = direction<=4 if phase_two and direction in [3,5] else direction>4
		animate("walk")
		velocity = toward.normalized()*(68.0 if phase_two else 55.0)
		move_and_slide()
		position = level.clamp_actor(position)
		if toward.length()<85 or state_time<=-1.5:
			locked_heading = toward.normalized()
			if locked_heading==Vector2.ZERO: locked_heading = Vector2.RIGHT
			sprite.flip_h = locked_heading.x<0
			var attack := attack_number%3
			attack_number += 1
			enter(["charge_ready","sweep_ready","slam_ready"][attack],0.85 if phase_two else 1.05,["charge_ready","sweep_ready","slam_ready"][attack],["¡CARGA! · Apártate","¡BARRIDO! · Aléjate","¡GOLPE! · Retrocede"][attack])
			level.audio.cue("anclado",-12)
	elif state.ends_with("_ready") and state_time<=0:
		enter(state.replace("_ready",""),0.9 if state=="charge_ready" else 0.5,state.replace("_ready",""))
	elif state=="charge":
		velocity = locked_heading*(290 if phase_two else 250)
		move_and_slide()
		var bounded: Vector2 = level.clamp_actor(position)
		var stopped := bounded.distance_to(position)>0.1 or get_slide_collision_count()>0
		position = bounded
		if not hit_done and position.distance_to(level.player.position)<40:
			hit_done = true
			level.player.take_damage(32,position)
		if state_time<=0 or stopped: enter("rest",1.55,"rest","ARMAZÓN EXPUESTO")
	elif state in ["sweep","slam"]:
		if not hit_done:
			hit_done = true
			var offset: Vector2 = level.player.position-position
			if offset.length()<(66 if state=="slam" else 61) and (state=="slam" or offset.normalized().dot(locked_heading)>-0.1):
				level.player.take_damage(30 if state=="slam" else 26,position)
			level.spawn_fx(position+locked_heading*35,2,0.4)
			level.audio.cue("hit",-9,0.6)
			level.shake = 2
		if state_time<=0: enter("rest",1.45,"rest","ARMAZÓN EXPUESTO")
	elif state=="rest" and state_time<=0:
		if phase_pending:
			phase_pending = false
			phase_two = true
			sprite.sprite_frames = HarborArt.boss_frames(true)
			enter("phase",1.2,"phase","¡SE ROMPEN LAS SUJECIONES!")
			level.audio.cue("anclado",-8)
		else: enter("approach",0,"walk")
	elif state=="phase" and state_time<=0: enter("approach",0,"walk")
func take_damage(amount: int, _source: Vector2) -> void:
	if dead or level.blocked: return
	var actual := maxi(1,roundi(amount*(1.3 if state=="rest" else 0.65)))
	health = maxi(0,health-actual)
	health_bar.value = health
	level.spawn_fx(position+Vector2(0,-45),1,0.3)
	if health<=int(max_health/2.0) and not phase_two: phase_pending = true
	if health<=0:
		dead = true
		collision_layer = 0
		collision_mask = 0
		cue.hide()
		health_bar.hide()
		animate("death")
		level.audio.cue("anclado_death",-7)
		killed.emit(self)
