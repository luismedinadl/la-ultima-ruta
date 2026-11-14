extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.content_scale_size = Vector2i(576,648)
	root.size = Vector2i(576,648)
	RenderingServer.set_default_clear_color(Color("18212b"))
	var frames := RouteArt.pistol_frames()
	for direction in 8:
		for frame in 6:
			var sprite := AnimatedSprite2D.new()
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.sprite_frames = frames
			RouteArt.bind_character_clip(sprite)
			sprite.material.set_shader_parameter("alpha_cutoff",0.72)
			sprite.animation = "hurt_" + str(direction)
			sprite.frame = frame
			sprite.flip_h = RouteArt.pistol_flip("hurt",direction)
			sprite.scale = Vector2.ONE * (55.0 / RouteArt.pistol_height("hurt",direction))
			sprite.position = Vector2(48 + frame*96,75 + direction*80 - 82*sprite.scale.y)
			root.add_child(sprite)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/14_hurt_frames.png")
	print("HURT_RENDER_OK: 48 frames, eight directions")
	quit()
