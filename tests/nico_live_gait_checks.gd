extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ", label)
func run() -> void:
	RouteControls.setup()
	var audio := RouteAudio.new()
	root.add_child(audio)
	var level := RouteLevel.new()
	level.audio = audio
	level.level_number = 2
	root.add_child(level)
	level.set_process(false)
	level.blocked = false
	var p = level.player
	for armed in [false,true]:
		p.has_pistol = true
		p.pistol_equipped = armed
		for move in [Vector2.RIGHT,Vector2.LEFT,Vector2(1,1).normalized(),Vector2(-1,1).normalized(),Vector2(1,-1).normalized(),Vector2(-1,-1).normalized()]:
			RouteControls.release_touch()
			await physics_frame
			await physics_frame
			p.position = Vector2(400,270)
			p.direction = RouteControls.direction_index(move)
			p.animate("idle")
			var texture = p.sprite.sprite_frames.get_frame_texture(p.sprite.animation,0)
			var expected = p.WALK_ART.data()[p.WALK_ART.row_for(p.direction,armed)*6+1].rect
			check(texture.region == Rect2(expected[0],expected[1],expected[2],expected[3]),"rest uses closed passing pose")
			var seen := {}
			RouteControls.virtual_move = move
			for tick in 34:
				await physics_frame
				seen[p.sprite.frame] = true
			check(seen.size() >= 5,"actual moving actor advances gait %s %s" % [armed,move])
			RouteControls.release_touch()
			await physics_frame
			await physics_frame
			check(p.action == "idle" and p.sprite.frame == 0,"release returns to narrow rest")
	p.position = Vector2(26,280)
	RouteControls.virtual_move = Vector2.LEFT
	for i in 8: await physics_frame
	check(p.action == "idle" and p.walk_distance == 0,"blocked travel does not animate steps")
	RouteControls.release_touch()
	p.position = Vector2(200,280)
	p.direction = 6
	p.animate("idle")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("C:/Users/medin/Documents/Codex/2026-10-21/quiero-que-desarrolles-un-videojuego-completo/work/nico-rest-fixed.png")
	check(p.WALK_ART.sample(11) == p.WALK_ART.sample(55),"cycle repeats every 44 pixels regardless of elapsed time")
	print("LIVE GAIT FAILURES: ",failures)
	quit(failures)
