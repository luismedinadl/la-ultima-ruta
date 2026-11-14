extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	RouteSave.save_path = "res://tests/completed_continue_checkpoint.json"
	var fresh := {"stage":0,"level":1,"x":100,"health":100,"kills":0,"damage":0,"elapsed":0}
	assert(RouteSave.write_data(fresh.duplicate(true)))
	assert(RouteSave.can_continue())
	for number in range(1,9): assert(RouteSave.mark_level_completed(number))
	assert(RouteSave.finish_current_run())
	assert(not RouteSave.can_continue() and RouteSave.story_completed())
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	var buttons = app.ui.screen.find_children("*","Button",true,false)
	assert(buttons.any(func(b): return b.text=="Continuar historia" and b.disabled))
	assert(buttons.any(func(b): return b.text=="Seleccionar nivel" and not b.disabled))
	app.handle_command("continue")
	assert(app.mode=="menu")
	print("PASS finished run disables Continue and retains level selection")
	assert(RouteSave.write_data(fresh.duplicate(true)))
	assert(RouteSave.can_continue() and RouteSave.story_completed())
	print("PASS new run can continue without losing unlocked levels")
	var legacy := {"version":1,"stage":14,"level":8,"x":5600,"health":100,"kills":48,"damage":0,"elapsed":100,"gate_open":true,"chief_saved":true,"boss_defeated":true}
	var file := FileAccess.open(RouteSave.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	assert(not RouteSave.can_continue())
	print("PASS legacy completed checkpoint cannot resume")
	app.queue_free()
	await process_frame
	await process_frame
	quit()
