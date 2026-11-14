extends SceneTree
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("PASS: " if ok else "FAIL: ", message)
func run() -> void:
	RouteSave.save_path = "user://automated_movement_test.json"
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false)
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = 1000
		app.ui.advance_dialogue()
	var p = app.level.player
	p.controls_enabled = false
	for direction in range(8):
		p.direction = direction
		p.animate("idle")
		var pos: Vector2 = p.position
		await create_timer(0.25).timeout
		check(p.sprite.frame == 0 and not p.sprite.is_playing() and p.position == pos, "Stable idle direction %d" % direction)
		p.animate("walk")
		var reference := RouteArt.nico_anchor("idle", direction, 0)
		var aligned := true
		for frame in range(6):
			p.sprite.set_frame_and_progress(frame, 0)
			p.sync_sprite_anchor()
			var actual: Vector2 = RouteArt.nico_anchor("walk", direction, frame) + p.sprite.offset
			aligned = aligned and actual.distance_to(reference) < 0.01
		check(aligned, "Six walking frames share head pivot %d" % direction)
	p.position = Vector2(1030, 250)
	p.controls_enabled = true
	var before: Vector2 = p.position
	Input.action_press("route_right")
	for i in range(40): await physics_frame
	Input.action_release("route_right")
	var travelled: float = p.position.x - before.x
	check(travelled > 62 and travelled < 78, "Actual traversal at 105 px/s: %.2f px in ~2/3 s" % travelled)
	for i in range(2): await physics_frame
	before = p.position
	await create_timer(1.2).timeout
	check(p.position == before and p.sprite.frame == 0 and not p.sprite.is_playing(), "Stopping returns to a still pose for more than one old idle cycle")
	Input.action_press("route_right")
	Input.action_press("route_up")
	for i in range(4): await physics_frame
	check(absf(p.velocity.length() - RoutePlayer.SPEED) < 0.1, "Diagonal speed remains normalized")
	Input.action_release("route_right")
	Input.action_release("route_up")
	app.queue_free()
	await process_frame
	RouteArt.frame_cache.clear()
	RouteArt.textures.clear()
	RouteArt.character_regions.clear()
	RouteArt.anchor_cache.clear()
	await create_timer(0.15).timeout
	DirAccess.remove_absolute(RouteSave.save_path)
	print("MOVEMENT_CHECKS: ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
