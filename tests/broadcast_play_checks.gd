extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text_: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",text_)
func dialogue(app) -> void:
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = -1
		app.ui.advance_dialogue()
func run() -> void:
	RouteSave.save_path = "res://tests/broadcast_play_test.json"
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false,7)
	await physics_frame
	dialogue(app)
	var l: BroadcastLevel = app.level
	var p := l.player as ShotgunPlayer
	l.set_process(false)
	check(p.test_move(Transform2D(0,Vector2(3540,270)),Vector2(0,-80)),"broadcast desk has blocking collision")
	var before := p.position
	RouteControls.virtual_move = Vector2.RIGHT
	await create_timer(0.5).timeout
	RouteControls.virtual_move = Vector2.ZERO
	check(p.position.x-before.x>40,"movement retains existing speed")
	p.position = Vector2(650,270)
	var enemy := l.spawn_enemy(Vector2(780,270),false,true)
	var old_distance := p.position.distance_to(enemy.position)
	await create_timer(0.4).timeout
	check(p.position.distance_to(enemy.position)<old_distance,"Hueco pursues with live physics")
	enemy.set_physics_process(false)
	enemy.position = Vector2(760,270)
	await physics_frame
	await physics_frame
	var hp := enemy.health
	p.facing = Vector2.RIGHT
	p.begin_attack()
	check(enemy.health<hp and p.magazine==11,"pistol impact consumes one bullet")
	await create_timer(0.6).timeout
	var other := l.spawn_enemy(Vector2(750,290),false,true)
	other.set_physics_process(false)
	await physics_frame
	await physics_frame
	var hp2 := other.health
	p.weapon_slot = 2
	p.pistol_equipped = true
	p.action_time = 0
	p.begin_attack()
	check(other.health<hp2 and p.shells==3,"shotgun spread reaches another target")
	await create_timer(0.9).timeout
	p.weapon_slot = 0
	p.pistol_equipped = false
	p.action_time = 0
	var close := l.spawn_enemy(p.position+Vector2(24,0),false,true)
	close.set_physics_process(false)
	var hp3 := close.health
	p.begin_attack()
	await create_timer(0.3).timeout
	check(close.health<hp3,"knife damage matches animation timing")
	p.set_physics_process(false)
	p.reserve = 0
	p.shell_reserve = 0
	for key in ["3620","5100"]:
		p.position = l.ammo_pickups[key].sprite.position
		l.collect_ammo()
		l.collect_shells()
	check(p.reserve==24 and p.shell_reserve==0,"pistol boxes grant only bullets")
	for key in ["3660","5140"]:
		p.position = l.shell_boxes[key].position
		l.collect_ammo()
		l.collect_shells()
	check(p.reserve==24 and p.shell_reserve==8,"shotgun boxes grant only shells")
	p.health = 60
	p.position = l.medkits["2090"].position
	l.collect_medkits()
	check(p.health>60 and l.collected.has("2090"),"automatic medkit pickup works")
	l.set_stage(13)
	l.power_on = true
	l.antenna_connected = true
	l.files_sent = true
	l.harbor_confirmed = true
	var saved := l.snapshot()
	check(RouteSave.write_data(saved) and not RouteSave.read_data().is_empty(),"supply state writes safe checkpoint")
	app.start_route(true)
	await process_frame
	l = app.level
	check(l.stage==13 and not l.blocked and l.files_sent and l.harbor_confirmed,"real Continue restores transmission and evacuation")
	for key in ["3620","5100"]:
		check(not l.ammo_pickups[key].sprite.visible,"Continue cannot duplicate pistol supplies")
	for key in ["3660","5140"]:
		check(not l.shell_boxes[key].visible,"Continue cannot duplicate shotgun supplies")
	app.handle_command("documents")
	check(l.blocked and app.ui.dialogue_active,"documents button opens evidence and pauses actors")
	dialogue(app)
	check(not l.blocked and l.stage==13,"closing archive preserves objective")
	app.pause_route()
	var elapsed := l.elapsed
	await create_timer(0.2,true).timeout
	check(paused and l.elapsed==elapsed,"pause freezes route clock")
	app.resume_route()
	app.queue_free()
	for i in 5: await process_frame
	DirAccess.remove_absolute(RouteSave.save_path)
	print("BROADCAST PLAY FAILURES: ",failures)
	quit(1 if failures else 0)
