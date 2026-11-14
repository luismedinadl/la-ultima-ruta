extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(576,324)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(viewport)
	var level := RouteLevel.new()
	viewport.add_child(level)
	level.set_process(false)
	level.set_physics_process(false)
	level.player.set_physics_process(false)
	level.camera.position = Vector2(480,162)
	level.camera.zoom = Vector2(1,1)
	level.player.position = Vector2(625,340)
	await physics_frame
	level.player.move_and_collide(Vector2(0,-100))
	level.player.direction = 6
	level.player.animate("idle")
	await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://docs/screenshots/10_quiet_road.png")
	print("CAR_CONTACT_RENDER_OK")
	quit()


