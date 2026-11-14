extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ", message)
func clean() -> void:
	for suffix in ["", ".tmp", ".progress", ".progress.tmp"]:
		var path: String = RouteSave.save_path + suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
func run() -> void:
	RouteSave.save_path = "res://tests/menu_progress_test.json"
	clean()
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	var buttons: Array[Button] = []
	for child in app.ui.screen.get_children():
		if child is Button: buttons.append(child)
	check(buttons.size() == 5, "five menu buttons")
	check(buttons.map(func(b): return b.text) == ["Nueva historia", "Continuar historia", "Seleccionar nivel", "Supervivencia", "Salir"], "requested labels and no controls button")
	check(buttons[1].disabled and buttons[2].disabled and buttons[3].disabled, "continue without save and future survival disabled")
	for b in buttons: check(is_equal_approx(b.position.x + b.size.x / 2, 288), "button centered")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/menu_story.png")
	app.handle_command("level8")
	check(app.mode == "menu" and not is_instance_valid(app.level), "locked level command cannot skip campaign")
	var menu = app.ui.screen
	app.handle_command("select_level")
	check(app.ui.screen == menu, "direct route selector stays locked")
	app.handle_command("new")
	check(app.mode == "intro", "new story opens introduction instead of selector")
	app.start_route(false, 1)
	await process_frame
	app.on_delivered()
	check(RouteSave.completed_levels() == [1], "finishing a level records it")
	check(not RouteSave.story_completed(), "one completed level does not unlock selection")
	var checkpoint: Dictionary = app.level.snapshot()
	check(RouteSave.write_data(checkpoint), "checkpoint stored")
	app.show_menu()
	app.handle_command("continue")
	check(app.level.level_number == 1 and app.mode == "playing", "continue restores story checkpoint")
	for number in range(2, 8): check(RouteSave.mark_level_completed(number), "completion saved for level %d" % number)
	check(not RouteSave.story_completed(), "seven levels remain locked")
	check(RouteSave.mark_level_completed(8) and RouteSave.story_completed(), "all eight levels unlock selection")
	RouteSave.mark_level_completed(8)
	check(RouteSave.completed_levels().size() == 8, "replay does not duplicate completion")
	check(not RouteSave.mark_level_completed(9), "invalid level rejected")
	app.show_menu()
	app.handle_command("select_level")
	check(app.ui.screen.find_children("*", "Button", false, false).size() == 9, "unlocked selector has eight levels and back")
	app.handle_command("level1")
	check(app.mode == "intro", "restarting story still includes introduction")
	RouteSave.write_data(checkpoint)
	check(RouteSave.story_completed(), "checkpoint replacement preserves unlock")
	app.queue_free()
	await process_frame
	await process_frame
	clean()
	print("MENU PROGRESS FAILURES: ", failures)
	quit(0 if failures == 0 else 1)

