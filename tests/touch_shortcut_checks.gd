extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ", text)
func key(code: Key, echo_: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	event.echo = echo_
	root.push_input(event,true)
func run() -> void:
	RouteSave.save_path = "res://tests/touch_shortcut_test.json"
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	key(KEY_F8)
	check(not app.touch.enabled,"F8 no longer toggles touch controls")
	key(KEY_T)
	check(app.touch.enabled,"T enables touch controls")
	key(KEY_T,true)
	check(app.touch.enabled,"key repeat does not toggle repeatedly")
	await create_timer(1.5).timeout
	check(is_instance_valid(app) and app.touch.enabled,"game remains active after enabling touch")
	key(KEY_T)
	check(not app.touch.enabled,"T disables touch controls")
	app.start_route(false,1)
	app.pause_route()
	app.ui.controls(true)
	var option = app.ui.pause_panel.find_children("*","Button",true,false).filter(func(b): return b.text.begins_with("Mostrar controles"))[0]
	option.pressed.emit()
	check(app.touch.enabled and paused,"pause option enables touch without resuming")
	var hide = app.ui.pause_panel.find_children("*","Button",true,false).filter(func(b): return b.text.begins_with("Ocultar controles"))[0]
	check(is_instance_valid(hide),"option label updates after toggling")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/touch_controls_option.png")
	hide.pressed.emit()
	check(not app.touch.enabled and not Input.emulate_touch_from_mouse,"disabling restores mouse input")
	app.resume_route()
	check(not paused and is_instance_valid(app.level),"resume preserves the current level")
	app.queue_free()
	await process_frame
	print("TOUCH SHORTCUT FAILURES: ",failures)
	quit(0 if failures==0 else 1)
