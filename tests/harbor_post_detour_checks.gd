extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	RouteSave.save_path = "res://tests/harbor_detour_checkpoint.json"
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.start_route(false,8)
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = -1
		app.ui.advance_dialogue()
	var level: HarborLevel = app.level
	level.set_process(false)
	level.player.set_physics_process(false)
	level.set_stage(6)
	level.arena_center = level.CHIEF_ACCESS_LIMIT-280
	level.player.position = Vector2(2950,290)
	await physics_frame
	await physics_frame
	level.build_navigation()
	var failures := 0
	for kind in [0,1,2]:
		var enemy := level.spawn_enemy(Vector2(3104,300),kind==1,true,false,kind==2)
		enemy.set_physics_process(false)
		var moved_up := false
		for step in 1000:
			enemy._physics_process(1.0/60.0)
			if enemy.position.y<282: moved_up = true
			if enemy.position.x<3038: break
		var passed := moved_up and enemy.position.x<3038
		if not passed: failures += 1
		print("PASS " if passed else "FAIL ","enemy type ",kind," goes above post and continues: ",enemy.position)
		enemy.queue_free()
		level.enemies.clear()
		await process_frame
	print("POST DETOUR FAILURES: ",failures)
	app.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
