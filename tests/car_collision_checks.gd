extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var level := RouteLevel.new()
	root.add_child(level)
	level.set_process(false)
	level.set_physics_process(false)
	var player := level.player
	player.set_physics_process(false)
	await physics_frame
	var cars := get_nodes_in_group("car_obstacles")
	assert(cars.size() >= 2)
	# Isolate car geometry from nearby bins and barriers for these sweeps.
	player.collision_mask = 8
	for car in cars: car.collision_layer = 8
	await physics_frame
	for car in cars:
		for other in cars: other.collision_layer = 8 if other == car else 0
		await physics_frame
		# Sweep the real player's collision circle into every side of each car.
		for step in 24:
			var offset := Vector2.from_angle(TAU * step / 24.0) * 120 + Vector2(0,-30)
			player.position = car.position + offset
			var target: Vector2 = car.position + Vector2(0,-30)
			var collision := player.move_and_collide(target-player.position)
			assert(collision != null, "Car side must block player")
			assert(collision.get_collider() == car, "Sweep must hit car itself")
		# In front, the player must render above the car rather than vanish under it.
		player.position = car.position + Vector2(-25,60)
		player.move_and_collide(Vector2(0,-100))
		var car_sprite: Sprite2D
		for child in level.actors.get_children():
			if child is Sprite2D and is_equal_approx(child.position.x,car.position.x) and child.texture is AtlasTexture and child.texture.region == Rect2(1034,296,360,260):
				car_sprite = child
		assert(car_sprite != null)
		assert(player.position.y > car_sprite.position.y, "Front contact must draw player over car")
		# A clear lane remains around either parked-car placement.
		var lane := 215.0 if car.position.y > 260 else 250.0
		player.position = Vector2(car.position.x - 90, lane)
		assert(player.move_and_collide(Vector2(180,0), true) == null, "Car must remain passable around its footprint")
	level.queue_free()
	await process_frame
	RouteArt.frame_cache.clear()
	RouteArt.textures.clear()
	print("CAR_COLLISION: PASS all cars, 24 approach directions and front depth sorting and open bypass lanes")
	quit()


