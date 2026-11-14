extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	RouteSave.save_path = "user://dog_preview.json"
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false,3)
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = 1000
		app.ui.advance_dialogue()
	var l = app.level
	l.intro_spawned = true
	l.noise_lesson = true
	l.stage = 2
	l.goal = l.objective_text()
	l.player.position = Vector2(2110,270)
	l.player.controls_enabled = false
	l.player.direction = 6
	l.player.animate("idle")
	var dog = l.spawn_enemy(Vector2(2200,270),false,true,false,true)
	dog.set_physics_process(false)
	dog.direction = 2
	dog.animate("idle")
	await process_frame
	await process_frame
	app.ui.zone_text.modulate.a = 0
	app.ui.zone_timeout = 0
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/17_infected_dog.png")
	# Render every direction/action in-engine for crop and orientation inspection.
	app.show_menu()
	app.queue_free()
	await process_frame
	root.content_scale_size = Vector2i(800,640)
	root.size = Vector2i(800,640)
	for direction in 8:
		for index in 5:
			var action_: String = ["idle","walk","attack","hurt","death"][index]
			var sprite := Sprite2D.new()
			sprite.texture = DogArt.frames().get_frame_texture(action_+"_"+str(direction),2 if action_ == "death" else 1)
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.flip_h = direction > 4
			sprite.scale = Vector2.ONE*0.40
			sprite.position = Vector2(80+index*160,48+direction*78-(51 if action_ == "death" else 0))
			MetroArt.cutout(sprite)
			root.add_child(sprite)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/18_dog_states.png")
	print("DOG_RENDER_OK")
	quit()
