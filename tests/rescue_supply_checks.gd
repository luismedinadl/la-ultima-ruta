extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",message)
func run() -> void:
	RouteSave.save_path = "user://rescue_supply_test.json"
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false,5)
	app.ui.screen.finish()
	await create_timer(0.3).timeout
	for i in 6: await physics_frame
	var l = app.level
	l.set_process(false)
	l.player.set_physics_process(false)
	for key in l.ammo_pickups:
		check(is_equal_approx(l.ammo_pickups[key].sprite.position.x,float(key)),"pistol box retains authored position "+key)
	l.stage = 8
	l.player.reserve = 0
	l.player.shell_reserve = 0
	for key in ["4090","4125"]:
		l.player.position = l.ammo_pickups[key].sprite.position
		l.collect_ammo()
		l.collect_shells()
	check(l.player.reserve==24 and l.player.shell_reserve==0,"two pistol boxes deliver 24 bullets and no shells")
	for key in ["4090","4125"]:
		l.player.position = l.shell_boxes[key].position
		l.collect_ammo()
		l.collect_shells()
	check(l.player.reserve==24 and l.player.shell_reserve==8,"two shotgun boxes deliver eight shells without changing bullets")
	var saved: Dictionary = l.snapshot()
	l.restore(saved)
	for key in ["4090","4125"]:
		check(not l.ammo_pickups[key].sprite.visible and not l.shell_boxes[key].visible,"collected supplies remain absent after restore "+key)
	await create_timer(0.5).timeout
	app.queue_free()
	for i in 4: await process_frame
	DirAccess.remove_absolute(RouteSave.save_path)
	print("SUPPLY FAILURES: ",failures)
	quit(1 if failures else 0)
