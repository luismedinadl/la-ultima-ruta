extends SceneTree
var app
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",message)
func press(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.physical_keycode = key
	Input.parse_input_event(event)
func run() -> void:
	RouteSave.save_path = "user://intro_test_checkpoint.json"
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.handle_command("level1")
	await create_timer(0.4).timeout
	check(app.mode=="intro" and not is_instance_valid(app.level),"new level 1 starts prologue without live actors")
	check(not app.ui.hud.visible and not app.ui.dialogue_active,"game HUD and dialogue hidden during prologue")
	var intro = app.ui.screen
	check(intro.pages.size()==6,"all six approved passages loaded")
	for i in 6:
		await process_frame
		check(intro.page==i,"page order "+str(i))
		check(intro.body.get_line_count()<=2,"text fits caption on page "+str(i))
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/screenshots/intro_%02d.png" % i)
		await press(KEY_E)
		await create_timer(0.45).timeout
	check(app.mode=="playing" and app.level.level_number==1,"full prologue enters level 1")
	check(app.ui.dialogue_active and app.ui.line_index==0 and app.level.blocked,"first boss line preserved; no input leaks into gameplay")
	app.handle_command("retry")
	await process_frame
	check(app.mode=="playing" and app.level.level_number==1,"retry bypasses prologue")
	app.show_menu()
	await process_frame
	app.handle_command("level1")
	await create_timer(0.4).timeout
	await press(KEY_ESCAPE)
	await create_timer(0.3).timeout
	check(app.mode=="playing" and app.ui.dialogue_active and not paused,"Escape skips intro without pausing level")
	app.level.set_process(false)
	var saved: Dictionary = app.level.snapshot()
	saved.x = 300.0
	check(RouteSave.write_data(saved),"isolated continuation fixture saved")
	app.show_menu()
	await process_frame
	app.handle_command("continue")
	await process_frame
	check(app.mode=="playing" and not app.ui.dialogue_active and app.level.player.position.x==300.0,"continue restores checkpoint without prologue")
	for n in [2,3,4]:
		app.handle_command("level"+str(n))
		await process_frame
		check(app.mode=="playing" and app.level.level_number==n,"other level bypasses prologue "+str(n))
	app.queue_free()
	await process_frame
	DirAccess.remove_absolute(RouteSave.save_path)
	print("INTRO FAILURES: ",failures)
	quit(1 if failures else 0)
