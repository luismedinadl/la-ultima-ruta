extends SceneTree
var errors := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	if not ok: errors += 1
	print("PASS " if ok else "FAIL ",description)
func run() -> void:
	var app = load("res://scripts/main.gd").new()
	root.add_child(app)
	app.start_route(false,1)
	await process_frame
	for mobile in [false,true]:
		app.touch.set_enabled(mobile)
		# Reproduce the locked-parent context of OS focus/suspension delivery.
		app.ui.root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		app.ui.root.propagate_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		await process_frame
		check(paused,"focus loss pauses gameplay")
		check(is_instance_valid(app.ui.pause_panel) and app.ui.pause_panel.is_inside_tree(),"pause panel attached to UI tree")
		var count := 0
		for child in app.ui.root.get_children():
			if child == app.ui.pause_panel: count += 1
		check(count == 1,"repeated notifications keep one pause panel")
		app.resume_route()
		check(not paused and app.ui.pause_panel == null,"resume clears pause")
		await process_frame
	app.ui.root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	app.show_menu()
	await process_frame
	check(not paused and app.ui.pause_panel == null,"stale focus event cannot pause main menu")
	app.queue_free()
	await process_frame
	print("PAUSE_FOCUS_ERRORS=",errors)
	quit(errors)
