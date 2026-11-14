extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ", message)
func run() -> void:
	RouteControls.setup()
	var audio := RouteAudio.new()
	root.add_child(audio)
	var level := RouteLevel.new()
	level.audio = audio
	root.add_child(level)
	level.set_process(false)
	var p := level.player
	p.set_physics_process(false)
	var body_position := p.position
	for armed in [false, true]:
		p.has_pistol = true
		p.pistol_equipped = armed
		for direction in [1, 2, 3, 5, 6, 7]:
			p.direction = direction
			p.animate("idle")
			var idle_position := p.sprite.position
			var idle_scale := p.sprite.scale
			var idle_texture = p.sprite.sprite_frames.get_frame_texture(p.sprite.animation, 0)
			p.animate("walk")
			var frames := p.sprite.sprite_frames
			check(frames.get_frame_count(p.sprite.animation) == 6, "six poses %s / %d" % [armed, direction])
			check(p.sprite.position == idle_position and p.sprite.scale == idle_scale, "idle to walk keeps pivot and size")
			check(frames.get_frame_texture(p.sprite.animation, 0).region == idle_texture.region, "idle shares first contact pose")
			p.walk_distance = 44.0 * 3.54 / 5.8
			p.animate("walk")
			check(p.sprite.frame == 3 and is_equal_approx(p.sprite.frame_progress, 0.4), "repeated movement keeps step phase")
			p.direction = 1 if direction != 1 else 6
			p.animate("walk")
			check(p.sprite.frame == 3, "turning keeps step phase")
			await create_timer(0.11).timeout
			check(p.sprite.frame == 3, "no distance means no artificial step advancement")
			check(p.sprite.offset == Vector2.ZERO and p.position == body_position, "animation does not shift actor")
			p.animate("idle")
			await create_timer(0.11).timeout
			check(p.sprite.frame == 0 and not p.sprite.is_playing(), "idle stays still")
		for direction in [0, 4]:
			p.direction = direction
			p.animate("walk")
			check(not p.lateral_walk_active, "vertical walk keeps original artwork")
		p.direction = 6
		p.animate("shoot" if armed else "knife_attack")
		check(not p.lateral_walk_active and p.sprite.sprite_frames.has_animation(p.sprite.animation), "combat keeps its original frames")
	var shotgun := ShotgunPlayer.new()
	shotgun.level = level
	level.add_child(shotgun)
	shotgun.set_physics_process(false)
	shotgun.has_pistol = true
	shotgun.pistol_equipped = true
	shotgun.direction = 6
	shotgun.animate("walk")
	shotgun.acquire_shotgun()
	shotgun.animate("walk")
	check(not shotgun.lateral_walk_active, "shotgun retains its own animation")
	print("NICO WALK FAILURES: ", failures)
	quit(failures)
