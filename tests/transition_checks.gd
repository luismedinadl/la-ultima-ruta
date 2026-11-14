extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures.append(message)
func run() -> void:
	RouteSave.save_path = "user://automated_transition_test.json"
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false)
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = 1000
		app.ui.advance_dialogue()
	var p = app.level.player
	p.position = Vector2(1030, 250)
	await create_timer(1.5).timeout
	var resting_x: float = p.position.x - app.level.camera.get_screen_center_position().x
	Input.action_press("route_right")
	await create_timer(0.6).timeout
	var moving_x: float = p.position.x - app.level.camera.get_screen_center_position().x
	Input.action_release("route_right")
	await create_timer(0.6).timeout
	var stopped_x: float = p.position.x - app.level.camera.get_screen_center_position().x
	print("SCREEN_X idle/move/stop: ", resting_x, ", ", moving_x, ", ", stopped_x)
	check(absf(moving_x - resting_x) < 2.0 and absf(stopped_x - resting_x) < 2.0, "Camera does not slide Nico forward on start or backward on stop")
	for d in range(8):
		var frames: SpriteFrames = p.sprite.sprite_frames
		var idle := frames.get_frame_texture("idle_" + str(d), 0) as AtlasTexture
		var walk := frames.get_frame_texture("walk_" + str(d), 0) as AtlasTexture
		check(idle.atlas == walk.atlas and idle.region == walk.region, "Identical starting silhouette direction %d" % d)
	app.queue_free()
	await process_frame
	RouteArt.frame_cache.clear()
	RouteArt.textures.clear()
	RouteArt.anchor_cache.clear()
	RouteArt.character_regions.clear()
	await create_timer(0.15).timeout
	DirAccess.remove_absolute(RouteSave.save_path)
	print("TRANSITION_CHECKS: ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
