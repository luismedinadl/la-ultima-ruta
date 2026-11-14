extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	RouteSave.save_path = "user://level2_preview.json"
	root.size = Vector2i(1152,648)
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false,2)
	app.ui.dialog_text.visible_characters = 1000
	app.ui.reveal = 1000
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/11_level2_dialogue.png")
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = 1000
		app.ui.advance_dialogue()
	var l = app.level
	l.player.position = Vector2(l.pickup_x-100,260)
	l.player.direction = 6
	l.player.animate("idle")
	l.player.controls_enabled = false
	await create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/12_level2_pistol.png")
	l.start_wave(1)
	for e in l.enemies: e.set_physics_process(false)
	l.enemies[0].position = l.player.position + Vector2(110,0)
	await physics_frame
	await physics_frame
	l.player.begin_attack()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/13_level2_shot.png")
	print("LEVEL2_RENDER_OK")
	quit()
