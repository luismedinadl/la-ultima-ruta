extends SceneTree
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	check(is_instance_valid(app.ui.screen), "Menu created")
	app.ui.start_dialogue([{ "name": "NICO", "text": "Prueba de diálogo.", "portrait": 0 }])
	check(app.ui.dialogue_active, "Dialogue locks input")
	app.ui.advance_dialogue()
	app.ui.reveal = 100
	await process_frame
	app.ui.advance_dialogue()
	check(not app.ui.dialogue_active, "Dialogue completes")
	print("UI_SMOKE: ", "PASS" if failures.is_empty() else failures)
	app.queue_free()
	await process_frame
	await process_frame
	RouteArt.frame_cache.clear()
	RouteArt.textures.clear()
	await create_timer(0.15).timeout
	quit(0 if failures.is_empty() else 1)
