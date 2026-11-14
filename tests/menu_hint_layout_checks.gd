extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var ui := RouteUI.new()
	root.add_child(ui)
	for mobile in [false,true]:
		ui.mobile_layout(mobile)
		ui.menu(false)
		ui.show_menu_hint("Continuar historia","Empieza una nueva historia para guardar tu progreso.")
		await process_frame
		await process_frame
		var box = ui.pause_panel.get_child(0)
		var message = box.get_child(1)
		assert(message.size.x<=320 and message.position.x+message.size.x<=box.size.x-20)
		assert(message.get_line_count()>1)
		assert(message.position.y+message.size.y<=110)
		print("PASS wrapped hint fits panel, mobile=",mobile)
		if not mobile and DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/screenshots/menu_hint_layout.png")
		ui.close_pause()
	ui.queue_free()
	await process_frame
	quit()
