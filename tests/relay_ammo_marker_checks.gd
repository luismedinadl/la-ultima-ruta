extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	RouteSave.save_path = "res://tests/relay_marker_checkpoint.json"
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.start_route(false,8)
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = -1
		app.ui.advance_dialogue()
	var level = app.level
	level.set_process(false)
	level.player.set_physics_process(false)
	level.set_stage(7)
	level.refresh_objects()
	level.player.position = Vector2(2760,288)
	level._process(0)
	assert(level.relay_ammo_marker.visible)
	assert(level.relay_ammo_marker.position == Vector2(2810,255))
	await process_frame
	await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/relay_ammo_red_arrow.png")
	level.player.reserve = 0
	level.player.position = Vector2(2810,288)
	level._process(0)
	assert(level.ammo_taken.has("relay"))
	assert(not level.relay_ammo_marker.visible)
	print("PASS red ammo marker placement and automatic pickup visibility")
	app.queue_free()
	await process_frame
	await process_frame
	quit()
