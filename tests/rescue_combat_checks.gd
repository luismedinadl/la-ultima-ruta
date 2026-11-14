extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label_: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label_)
func run() -> void:
	RouteSave.save_path = "user://rescue_combat_test.json"
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false,5)
	app.ui.screen.finish()
	await create_timer(0.3).timeout
	await physics_frame
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = -1
		app.ui.advance_dialogue()
	var l = app.level
	var p = l.player
	l.set_process(false)
	var start: Vector2 = p.position
	RouteControls.virtual_move = Vector2.RIGHT
	await create_timer(0.5).timeout
	RouteControls.virtual_move = Vector2.ZERO
	check(p.position.x-start.x>40,"real movement retains responsive speed")
	p.position = Vector2(1100,260)
	var e = l.spawn_enemy(Vector2(1230,260),false,true)
	var distance: float = e.position.distance_to(p.position)
	await create_timer(0.5).timeout
	check(e.position.distance_to(p.position)<distance,"enemy advances with live physics")
	e.set_physics_process(false)
	e.position = Vector2(1210,260)
	var hp: int = e.health
	p.facing = Vector2.RIGHT
	p.begin_attack()
	check(e.health<hp and p.magazine==11,"pistol attack hits and consumes one round")
	await create_timer(0.6).timeout
	var other = l.spawn_enemy(Vector2(1200,280),false,true)
	other.set_physics_process(false)
	await physics_frame
	await physics_frame
	var hp2: int = other.health
	p.weapon_slot = 2
	p.pistol_equipped = true
	p.action_time = 0
	p.begin_attack()
	check(other.health<hp2 and p.shells==3,"shotgun cone hits second nearby target")
	await create_timer(0.95).timeout
	p.weapon_slot = 0
	p.pistol_equipped = false
	p.action_time = 0
	var close = l.spawn_enemy(p.position+Vector2(24,0),false,true)
	close.set_physics_process(false)
	var hp3: int = close.health
	p.begin_attack()
	await create_timer(0.3).timeout
	check(close.health<hp3,"knife connects through timed animation")
	p.health = 60
	p.position = l.medkits["1330"].position
	l.collect_medkits()
	check(p.health>60 and l.collected.has("1330"),"medkit collects automatically")
	p.shell_reserve = 2
	p.position = l.shell_boxes["2520"].position
	l.collect_shells()
	check(p.shell_reserve==6 and l.shells_collected.has("2520"),"four shells collect automatically")
	app.queue_free()
	for i in 4: await process_frame
	DirAccess.remove_absolute(RouteSave.save_path)
	print("RESCUE COMBAT FAILURES: ",failures)
	quit(1 if failures else 0)
