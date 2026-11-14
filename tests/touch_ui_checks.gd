extends SceneTree
var app
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",message)
func tap(pos: Vector2) -> void:
	for down in [true,false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = pos
		event.pressed = down
		Input.parse_input_event(event)
		await process_frame
func run() -> void:
	RouteSave.save_path = "res://tests/touch_ui_test.json"
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.touch.set_enabled(true)
	app.ui.menu(false)
	await tap(Vector2(288,135))
	check(app.mode == "intro","screen touch activates new story menu button")
	await create_timer(0.4).timeout
	if app.mode == "intro":
		var page: int = app.ui.screen.page
		await tap(Vector2(468,300))
		await create_timer(0.4).timeout
		check(app.ui.screen.page == page+1,"screen touch activates cinematic continue button once")
	app.start_route(false,1)
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = -1
		app.ui.advance_dialogue()
	app.pause_route()
	await tap(Vector2(285,119))
	check(not paused,"screen touch activates resume button")
	app.pause_route()
	await tap(Vector2(285,169))
	check(app.ui.pause_panel.find_children("*","Label",true,false).any(func(l): return l.text.begins_with("Joystick")),"pause help describes touch controls")
	await tap(Vector2(285,255))
	await tap(Vector2(285,219))
	check(app.mode == "menu","pause back and menu buttons are reachable by touch")
	app.start_route(false,1)
	app.on_player_died()
	await tap(Vector2(208,268))
	check(app.mode == "playing" and app.level.level_number == 1,"touch retry restarts the route")
	app.show_menu()
	for number in range(1,9): RouteSave.mark_level_completed(number)
	app.handle_command("new")
	await process_frame
	var scroll = app.ui.screen.find_children("*","ScrollContainer",true,false)[0]
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = Vector2(288,210)
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	for y in [180,150,120,90]:
		var motion := InputEventScreenDrag.new()
		motion.index = 0
		motion.position = Vector2(288,y)
		motion.relative = Vector2(0,-30)
		Input.parse_input_event(motion)
		await process_frame
	down.pressed = false
	down.position = Vector2(288,90)
	Input.parse_input_event(down)
	await process_frame
	check(is_instance_valid(scroll) and scroll.scroll_vertical > 0,"unlocked routes scroll with a finger")
	app.queue_free()
	await process_frame
	for suffix in ["", ".tmp", ".progress", ".progress.tmp"]:
		var path: String = RouteSave.save_path+suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	print("TOUCH UI FAILURES: ",failures)
	quit(0 if failures==0 else 1)
