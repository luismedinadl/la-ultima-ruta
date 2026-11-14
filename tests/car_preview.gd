extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 520)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(viewport)
	var background := ColorRect.new()
	background.color = Color("263442")
	background.size = viewport.size
	viewport.add_child(background)
	var sprite := Sprite2D.new()
	sprite.texture = RouteArt.prop(9)
	sprite.position = Vector2(360, 260)
	sprite.scale = Vector2(2, 2)
	viewport.add_child(sprite)
	await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://docs/screenshots/08_car_crop.png")
	print("CAR_RENDER_OK")
	quit()
