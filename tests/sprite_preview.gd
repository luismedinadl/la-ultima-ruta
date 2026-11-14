extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1200, 800)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(viewport)
	var bg := ColorRect.new()
	bg.color = Color("263442")
	bg.size = viewport.size
	viewport.add_child(bg)
	for row in 4:
		for col in 6:
			var sprite := AnimatedSprite2D.new()
			sprite.sprite_frames = RouteArt.frames("nico" if row < 2 else "zombie")
			viewport.add_child(sprite)
			RouteArt.bind_character_clip(sprite)
			sprite.position = Vector2(100 + col * 200, 100 + row * 200)
			sprite.animation = ["walk_6", "knife_attack_6", "walk_6", "death_1"][row]
			sprite.frame = col
	await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://docs/screenshots/07_sprite_crops.png")
	print("SPRITE_RENDER_OK")
	quit()
