extends SceneTree
var failures := 0
var app
func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",description)
func dialogue() -> void:
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = 1000
		app.ui.advance_dialogue()
func defeat_group(level) -> void:
	for enemy in level.enemies.duplicate():
		if not enemy.dead: enemy.take_damage(1000,level.player.position)
func run() -> void:
	RouteSave.save_path = "user://metro_test.json"
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false,3)
	await physics_frame
	await physics_frame
	await process_frame
	var l = app.level
	var p = l.player
	p.controls_enabled = false
	check(l.level_number == 3 and p.has_pistol and p.reserve == 36,"metro starts armed with 36 reserve")
	check(l.blocked and l.remaining() == 2,"dialogue blocks two distracted enemies")
	dialogue()
	check(not l.blocked,"intro releases player")
	var e = l.enemies[0]
	p.position = Vector2(700,240)
	e.position = Vector2(920,240)
	e.watch_direction = Vector2.RIGHT
	var origin = e.position
	for i in 30: await physics_frame
	check(e.awareness == 0 and e.position.distance_to(origin)<1,"distant silent player leaves enemy distracted")
	l.make_noise(e.position+Vector2(60,0),80,false)
	check(e.awareness == 1,"knife noise provokes investigation")
	await physics_frame
	await physics_frame
	check(e.alert_icon.visible,"distracted enemies retain noise indicators")
	var nodes_before_noise = l.get_child_count()
	l.enemies[1].position = Vector2(1600,300)
	l.enemies[1].awareness = 0
	l.make_noise(e.position+Vector2(20,0),360,true)
	check(e.awareness == 2,"gun noise alerts nearby enemy")
	check(l.get_child_count() == nodes_before_noise,"noise creates no visible circles")
	check(l.enemies[1].awareness == 0 and l.remaining() == 2,"gun noise neither reaches distant enemies nor spawns more")
	for i in 30: await physics_frame
	check(e.awareness == 2,"silence does not reset pursuit")
	var watcher = l.enemies[1]
	watcher.position = Vector2(750,300)
	watcher.watch_direction = Vector2.RIGHT
	p.position = Vector2(830,300)
	for i in 30: await physics_frame
	check(watcher.awareness == 2,"direct sight alerts without firing")
	# Static turnstile at 680 blocks sight and bullets along its footprint.
	check(not l.clear_sight(Vector2(650,266),Vector2(710,266)),"obstacle blocks line of sight")
	l.set_process(false)
	p.position = Vector2(1160,260)
	l.start_wave(1)
	check(l.stage == 1 and l.remaining() == 7,"vestibule has five plus finite entrance group")
	var wave_enemy = l.enemies[-1]
	wave_enemy.take_damage(1,p.position)
	await physics_frame
	await physics_frame
	check(not wave_enemy.show_awareness_icon and not wave_enemy.alert_icon.visible,"wave enemies show no indicators even when hit")
	defeat_group(l)
	check(l.stage == 2,"vestibule unlocks battery")
	p.position = l.package_point
	l.interact()
	for i in 65: await physics_frame
	check(l.stage == 3 and l.battery_carried and not l.package.visible and l.remaining() == 7,"battery pickup starts maintenance encounter")
	check(l.enemies.filter(func(enemy): return enemy is InfectedDog and not enemy.dead).size() == 1,"one dog added to maintenance")
	defeat_group(l)
	check(l.stage == 4 and l.remaining() == 2,"maintenance leaves two distracted platform enemies")
	var saved = l.snapshot()
	check(RouteSave.write_data(saved) and RouteSave.read_data().level == 3,"metro checkpoint accepted")
	app.start_route(true)
	l = app.level
	p = l.player
	l.set_process(false)
	p.controls_enabled = false
	check(l.stage == 4 and l.battery_carried and l.remaining() == 2,"resume preserves battery and remaining enemies")
	p.position = Vector2(3160,260)
	l.start_wave(3)
	check(l.remaining() == 10,"platform encounter includes finite distracted pair")
	check(l.enemies.filter(func(enemy): return enemy is InfectedDog and not enemy.dead).size() == 1,"one dog added to platform")
	defeat_group(l)
	check(l.stage == 6,"platform unlocks panel")
	p.position = l.panel_position
	p.action_time = 0
	l.interact()
	for i in 65: await physics_frame
	check(l.stage == 7 and l.battery_installed and l.remaining() == 2,"installation starts first defense batch")
	for enemy in l.enemies: enemy.set_physics_process(false)
	var blocker = l.enemies[-1]
	blocker.position = l.panel_position
	l.update_defense(1.0)
	check(l.panel_progress == 0 and l.panel_interrupted,"enemy at panel interrupts progress")
	blocker.position += Vector2(100,0)
	l.update_defense(1.0)
	check(l.panel_progress == 1.0 and not l.panel_interrupted,"clearing panel resumes without reset")
	l.set_process(true)
	app.pause_route()
	var progress = l.panel_progress
	await create_timer(0.2).timeout
	check(l.panel_progress == progress,"pause freezes panel defense")
	app.resume_route()
	l.set_process(false)
	l.update_defense(10.0)
	check(l.defense_batch == 2,"second batch is finite")
	l.update_defense(10.0)
	check(l.defense_batch == 3,"third and last batch")
	check(l.enemies.filter(func(enemy): return enemy is InfectedDog and not enemy.dead).size() == 1,"one dog in final defense")
	defeat_group(l)
	l.update_defense(30.0)
	check(l.stage == 8 and l.kills == 33,"33 kills and completed reboot unlock exit")
	p.position = Vector2(l.delivery_x,260)
	p.action_time = 0
	l.interact()
	check(l.stage == 9 and app.ui.dialogue_active,"exit opens closing dialogue")
	dialogue()
	check(app.mode == "result","metro completes")
	app.handle_command("retry")
	check(app.level.level_number == 3,"retry stays in metro")
	app.start_route(false,2)
	app.handle_command("next_level")
	check(app.level.level_number == 3,"level 2 can continue to level 3")
	app.show_menu()
	app.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.4).timeout
	print("METRO failures: ",failures)
	quit(failures)
