extends SceneTree
var failures := 0
var app
var l: HarborLevel
var snapshots: Array = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",message)
func close_dialogue() -> void:
	for i in 100:
		if not app.ui.dialogue_active: return
		app.ui.dialog_text.visible_characters = -1
		app.ui.advance_dialogue()
func interact() -> void:
	l.player.position = Vector2(l.destination(),270)
	l.player.action_time = 0
	l.interact()
func remember() -> void:
	check(l.stage in l.HARBOR_SAFE,"safe stage "+str(l.stage))
	var data := l.snapshot()
	snapshots.append(data.duplicate(true))
	check(RouteSave.write_data(data),"checkpoint writes")
	check(not RouteSave.read_data().is_empty(),"checkpoint validates")
func fight() -> void:
	for attempt in 12:
		l._process(3)
		for e in l.enemies:
			e.set_physics_process(false)
			if not e.dead:
				check(not (e as MetroEnemy).show_awareness_icon,"wave has no question mark")
				e.take_damage(100000,l.player.position)
		l._process(0.01)
		if l.stage not in [1,3,6,9]: return
	check(false,"finite battle finishes")
func capture(file: String) -> void:
	l.camera.position.x = clampf(l.player.position.x+65,288,l.world_length-288)
	app.ui.zone_text.text = ""
	if app.ui.dialogue_active:
		app.ui.reveal = app.ui.dialog_text.text.length()
		app.ui.dialog_text.visible_characters = -1
	await process_frame
	await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/harbor_"+file+".png")
func run() -> void:
	RouteSave.save_path = "res://tests/harbor_checkpoint_test.json"
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.start_route(false,7)
	close_dialogue()
	app.handle_command("next_level")
	await physics_frame
	l = app.level
	check(l is HarborLevel and l.level_number==8,"level seven connects to finale")
	close_dialogue()
	l.set_process(false)
	l.player.controls_enabled = false
	remember()
	check(l.ammo_pickups.size()==6 and l.shell_boxes.size()==6,"separate pistol and shell supplies")
	check(l.civilians.all(func(c): return not c.visible),"civilians hidden before invitation")
	await capture("01_access")
	l.player.position = Vector2(650,270)
	l._process(0.01)
	check(l.stage==1 and l.arrivals.size()==7,"first finite encounter queued")
	var t := l.elapsed
	l.blocked = true
	l._process(10)
	check(l.remaining()==0 and l.elapsed==t,"dialogue freezes time and spawning")
	l.blocked = false
	fight()
	check(l.stage==2 and l.kills==7,"entrance cleared")
	remember()
	l.player.position = Vector2(1610,270)
	l._process(0.01)
	fight()
	check(l.stage==4 and l.kills==15,"cargo cleared with dog added")
	remember()
	interact()
	check(app.ui.dialogue_active,"manifest is readable")
	close_dialogue()
	check(l.stage==5,"manifest leads to chief")
	remember()
	l.player.position = Vector2(2570,270)
	await capture("02_chief")
	interact()
	close_dialogue()
	check(l.stage==6,"chief confrontation triggers control fight")
	fight()
	check(l.stage==7 and l.kills==28,"control has finite reinforcements")
	remember()
	l.player.position = Vector2(2740,280)
	await physics_frame
	await physics_frame
	l.player.facing = l.assisted_aim(l.player.position,280,Vector2.RIGHT)
	l.pistol_shot(l.player)
	check(l.civilians.all(func(c): return c.visible and c.position.x<2830),"civilians wait until gate opens")
	l._process(1.0)
	close_dialogue()
	check(l.stage==8 and l.gate_open and l.cargo_block.collision_layer==0,"shot opens real gate")
	check(l.civilians.all(func(c): return c.visible),"civilians remain visible after radio instruction")
	remember()
	l.player.position = Vector2(3530,280)
	l._process(0.01)
	l._process(2)
	check(l.civilians[0].position.y<=222,"civilians cross the opening then follow the protected shoulder")
	check(l.clamp_actor(Vector2(3500,205)).y>=248,"combatants cannot enter civilian shoulder")
	await capture("03_crossing")
	fight()
	check(l.stage==10 and l.kills==41,"crossing combat ends without idle countdown")
	remember()
	l.player.position = Vector2(4510,280)
	var last_group_x: float = l.civilians[0].position.x
	for step in 600:
		l._process(0.1)
		if l.pending_read=="standoff": break
		check(l.civilians[0].position.x-last_group_x<=6.5,"survivors walk continuously toward blockade")
		last_group_x = l.civilians[0].position.x
	check(l.stage==11 and app.ui.dialogue_active,"chief and guards stop the group before breakout")
	check(l.chief_guards.size()==2 and l.chief_guards.all(func(g): return g.visible),"two corporate guards block the way")
	check(l.survivors_at_blockade(),"all four survivors reach the confrontation")
	await capture("04_standoff")
	remember()
	while app.ui.dialogue_active and l.pending_read=="standoff":
		app.ui.dialog_text.visible_characters = -1
		app.ui.advance_dialogue()
	check(l.stage==12 and app.showing_harbor_breach,"breakout follows confrontation with dedicated cinematic")
	remember()
	var before_boss := l.snapshot()
	await capture("04_breakout")
	close_dialogue()
	check(l.stage==13 and is_instance_valid(l.anchored),"boss created once")
	var boss := l.anchored
	boss.set_physics_process(false)
	l._process(2.1)
	await capture("04_boss")
	# Telegraph locks its target, pauses, then exposes a damage window.
	l.player.position = boss.position+Vector2(-80,0)
	boss.enter("charge_ready",1.0,"charge_ready")
	boss.locked_heading = Vector2.LEFT
	l.blocked = true
	boss._physics_process(0.5)
	check(boss.state_time==1.0,"boss telegraph pauses")
	l.blocked = false
	boss._physics_process(1.1)
	check(boss.state=="charge","charge starts only after windup")
	boss.enter("rest",1.5,"rest")
	var hp := boss.health
	boss.take_damage(34,l.player.position)
	check(hp-boss.health==44,"knife deals useful damage during recovery")
	boss.take_damage(620,l.player.position)
	l._process(0.01)
	check(l.arrivals.is_empty() and l.remaining()==1,"no reinforcements at first health threshold")
	boss.take_damage(500,l.player.position)
	l._process(0.01)
	check(l.arrivals.is_empty() and l.remaining()==1,"no reinforcements at second health threshold")
	l._process(3)
	for e in l.enemies:
		e.set_physics_process(false)
		if e!=boss and not e.dead: e.take_damage(100000,l.player.position)
	boss.take_damage(100000,l.player.position)
	l._process(0.01)
	check(l.stage==14 and l.boss_defeated,"boss death unlocks embarkation")
	remember()
	l.player.position = Vector2(5590,270)
	await capture("05_rescue")
	# A saved pre-boss state restores flags and has no stale enemies.
	l.restore(before_boss)
	check(l.stage==12 and l.remaining()==0 and l.chief_saved,"pre-boss restore is clean")
	for data in snapshots:
		check(RouteSave.write_data(data),"write each safe state")
		var restored := RouteSave.read_data()
		check(not restored.is_empty(),"accept each safe state")
		l.restore(restored)
		check(l.stage==int(data.stage),"restore exact progression")
	l.restore(snapshots.back())
	l._process(20)
	interact()
	close_dialogue()
	check(app.mode=="finale","embarkation starts final scenes")
	await process_frame
	check(app.ui.screen.pages.size()==7,"five story pages and two final messages loaded")
	check(app.ui.screen.pages.back().text=="Gracias por jugar","last message is exactly Gracias por jugar")
	app.ui.screen.finish()
	await create_timer(0.5).timeout
	check(app.mode=="result","ending reaches results")
	check(app.ui.screen.find_children("*","Button",true,false).all(func(btn): return not btn.text.contains("Nivel 9")),"no ninth level")
	for key in ["opening","chief","cross","breakout","standoff","ending"]:
		for entry in HarborArt.dialogue(key):
			app.ui.start_dialogue([entry])
			await process_frame
			check(app.ui.dialog_text.get_line_count()<=3,"dialogue fits: "+key)
	RouteSave.write_data(before_boss)
	app.start_route(true,8)
	await process_frame
	check(app.level.stage==12 and app.level.remaining()==0 and app.ui.dialogue_active,"continue resumes the pre-boss escape cinematic")
	print("HARBOR FAILURES: ",failures)
	app.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)

