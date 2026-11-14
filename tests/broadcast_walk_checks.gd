extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	RouteSave.save_path = "res://tests/broadcast_walk_test.json"
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false,7)
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = -1
		app.ui.advance_dialogue()
	var l: BroadcastLevel = app.level
	l.set_process(false)
	# Isolate geometry: encounters are covered by distribution_checks.
	l.set_stage(15)
	Engine.time_scale = 4
	var failures := 0
	for target in [Vector2(650,255),Vector2(1610,255),Vector2(2570,255),Vector2(3530,255),Vector2(4490,255),Vector2(5450,255),Vector2(5660,255)]:
		var timeout := 0.0
		while l.player.position.distance_to(target)>9 and timeout<15:
			RouteControls.virtual_move = (target-l.player.position).normalized()
			await physics_frame
			timeout += 1.0/60.0*Engine.time_scale
		RouteControls.virtual_move = Vector2.ZERO
		var passed := l.player.position.distance_to(target)<=9
		if not passed: failures += 1
		print("PASS " if passed else "FAIL ","walkable passage to ",target," reached ",l.player.position)
		if not passed: break
	Engine.time_scale = 1
	app.queue_free()
	for i in 4: await process_frame
	DirAccess.remove_absolute(RouteSave.save_path)
	print("WALK FAILURES: ",failures)
	quit(1 if failures else 0)
