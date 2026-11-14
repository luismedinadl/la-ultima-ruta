extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var frames := RouteArt.pistol_frames()
	var count := 0
	for animation in frames.get_animation_names():
		assert(frames.get_frame_count(animation) == 6)
		for i in 6:
			var texture := frames.get_frame_texture(animation,i) as AtlasTexture
			assert(texture.region.has_area())
			assert(texture.margin.position.x >= 0 and texture.margin.position.y >= 0)
			assert(texture.get_size() == Vector2(512,512))
			count += 1
	print("PISTOL_ART: ",count," frames checked; all directions, padded bounds and pivots")
	RouteArt.frame_cache.clear()
	RouteArt.textures.clear()
	quit()
