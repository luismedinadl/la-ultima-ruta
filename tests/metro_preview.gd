extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	RouteSave.save_path = "user://metro_preview.json"
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false,3)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/15_metro_dialogue.png")
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = 1000
		app.ui.advance_dialogue()
	var l = app.level
	var p = l.player
	p.controls_enabled = false
	for enemy in l.enemies: enemy.set_physics_process(false)
	for section in [0,1,2,3]:
		for enemy in l.enemies:
			enemy.get_parent().remove_child(enemy)
			enemy.queue_free()
		l.enemies.clear()
		l.noise_lesson = true
		p.position = Vector2([820,2120,3060,4090][section],270)
		l.stage = [0,2,4,6][section]
		l.goal = l.objective_text()
		p.direction = 6
		p.animate("idle")
		if section == 0:
			l.spawn_enemy(Vector2(920,233),false,false).set_physics_process(false)
			l.spawn_enemy(Vector2(980,294),false,false).set_physics_process(false)
		if section == 3:
			l.battery_carried = true
			l.battery_installed = true
			l.start_wave(4)
			for enemy in l.enemies: enemy.set_physics_process(false)
			l.panel_progress = 15
		await process_frame
		await process_frame
		app.ui.zone_text.modulate.a = 0
		app.ui.zone_timeout = 0
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/16_metro_%d.png" % section)
	print("METRO_RENDER_OK")
	app.show_menu()
	app.queue_free()
	await process_frame
	quit()
