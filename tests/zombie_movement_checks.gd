extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for tough in [false, true]:
		var enemy := RouteEnemy.new()
		enemy.resistant = tough
		root.add_child(enemy)
		enemy.set_physics_process(false)
		for direction in 8:
			enemy.direction = direction
			enemy.animate("idle")
			var idle := enemy.sprite.sprite_frames.get_frame_texture(enemy.sprite.animation, 0) as AtlasTexture
			await create_timer(0.22).timeout
			assert(enemy.sprite.frame == 0 and not enemy.sprite.is_playing())
			enemy.animate("walk")
			var walk := enemy.sprite.sprite_frames.get_frame_texture(enemy.sprite.animation, 0) as AtlasTexture
			assert(idle.atlas == walk.atlas and idle.region == walk.region and idle.margin == walk.margin)
			for frame in 6:
				enemy.sprite.frame = frame
				assert((RouteArt.zombie_walk_anchor(direction, frame) + enemy.sprite.offset).is_equal_approx(RouteArt.zombie_walk_anchor(direction, 0)))
			enemy.animate("attack")
			assert(enemy.sprite.offset == Vector2.ZERO and enemy.sprite.is_playing())
			enemy.animate("death")
			assert(enemy.sprite.offset == Vector2.ZERO and enemy.sprite.is_playing())
		enemy.queue_free()
		await process_frame
	RouteArt.frame_cache.clear()
	RouteArt.textures.clear()
	print("ZOMBIE_MOVEMENT: PASS normal/resistant, eight directions, stable idle, six aligned walk frames, attack/death unaffected")
	quit()

