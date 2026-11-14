extends SceneTree
var failures := 0
var app
var l: RescueLevel
var safe_saves: Array = []
var dogs := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",message)
func dialogue() -> void:
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = -1
		app.ui.advance_dialogue()
func defeat() -> void:
	for enemy in l.enemies.duplicate():
		if not enemy.dead:
			if enemy is InfectedDog: dogs += 1
			enemy.take_damage(10000,l.player.position)
func remember() -> void:
	safe_saves.append(l.snapshot())
func capture(name_: String) -> void:
	l.camera.position.x = clampf(l.player.position.x+65,288,l.world_length-288)
	app.ui.zone_text.text = ""
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/rescue_"+name_+".png")
func run() -> void:
	RouteSave.save_path = "user://rescue_test_checkpoint.json"
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false,5)
	app.ui.screen.finish()
	await create_timer(0.3).timeout
	await physics_frame
	l = app.level
	check(l.blocked and app.ui.dialog_name.text=="MARA","opening shows Mara and pauses actors")
	check(l.player.has_shotgun and l.player.reserve==36,"level 5 retains three weapons and capped reserve")
	check(l.gate==null,"small isolated exit fence removed")
	await capture("00_opening")
	dialogue()
	l.set_process(false)
	l.player.controls_enabled = false
	remember()
	l.player.position = Vector2(1120,260)
	l.start_wave(1)
	check(l.remaining()==6,"refuge encounter contains six enemies")
	defeat()
	check(l.stage==2,"refuge unlocks after clearing")
	remember()
	l.update_people()
	await capture("01_refuge")
	l.interact()
	check(l.blocked and app.ui.dialogue_active,"Mara conversation locks controls")
	dialogue()
	check(l.stage==3 and not l.blocked,"conversation releases route to pumps")
	remember()
	l.player.position = Vector2(2110,260)
	l.start_wave(2)
	check(l.remaining()==8,"pump approach has eight including dog")
	var distracted := 0
	for enemy in l.enemies:
		if not enemy.dead and enemy.awareness==0: distracted+=1
	check(distracted==4,"four authored enemies react to noise")
	l.make_noise(l.player.position,600,true)
	for enemy in l.enemies:
		if not enemy.dead: check(enemy.awareness==2,"noise wakes nearby distracted enemy")
	defeat()
	check(l.stage==5,"pump encounter unlocks generator")
	remember()
	l.player.position = Vector2(3090,240)
	await capture("02_generator")
	l.interact()
	dialogue()
	check(l.stage==7 and l.remaining()==5,"generator starts first finite group")
	defeat()
	l._process(0.1)
	check(l.remaining()==4 and l.reinforcements_sent,"generator sends exactly four reinforcements")
	defeat()
	l._process(l.OPEN_SECONDS)
	check(l.stage==8 and l.remaining()==0,"timer and last kill both required to open gate")
	l.update_people()
	for npc in l.survivors:
		check(not npc.visible,"civilians hidden before Nico calls them")
	for key in ["4090","4125"]:
		check(l.ammo_pickups.has(key) and l.shell_boxes.has(key),"one box per weapon at final supply column "+key)
	remember()
	l.player.position = Vector2(4140,225)
	l.interact()
	l.update_people()
	for npc in l.survivors:
		check(not npc.visible,"civilians remain hidden during invitation dialogue")
	dialogue()
	check(l.stage==10 and l.remaining()==9,"crossing contains nine including second dog")
	l.update_people()
	for npc in l.survivors:
		check(npc.visible,"civilians appear after invitation completes")
	await physics_frame
	await physics_frame
	var from_street := Transform2D(0,Vector2(4140,250))
	check(l.player.test_move(from_street,Vector2(0,-110)),"physical divider blocks Nico entering civilian lane")
	for enemy in l.enemies:
		if not enemy.dead:
			check(enemy.test_move(from_street,Vector2(0,-110)),"physical divider blocks enemy including dog")
	check(l.clamp_actor(Vector2(4140,160)).y>=l.COMBAT_EDGE,"spawn and knockback cannot bypass protected lane")
	for enemy in l.enemies:
		enemy.set_physics_process(false)
		if not enemy.dead: enemy.position = Vector2(4160,250)
	l._process(1)
	check(not l.crossing_stopped and l.crossing_progress>0,"civilians move alongside combat behind barrier")
	check(l.survivors[0].position.y==l.CIVILIAN_Y,"civilians use street shoulder, not rear bridge")
	await capture("03_defense")
	var before := l.crossing_progress
	l.blocked = true
	l._process(2)
	check(l.crossing_progress==before,"dialogue blocking freezes crossing")
	l.blocked = false
	defeat()
	l._process(0.1)
	check(l.final_wave_sent and l.wave_index==5 and l.remaining()==6,"fifth wave adds six enemies during escort")
	l._process(2)
	check(l.remaining()==6,"fifth wave never duplicates")
	defeat()
	l._process(0.1)
	check(l.last_wave_sent and l.wave_index==6 and l.remaining()==6,"sixth wave arrives immediately if fifth cleared early")
	l._process(l.CROSS_SECONDS)
	check(l.stage==10 and l.remaining()==6,"cannot finish rescue with sixth wave alive; no duplicate spawn")
	defeat()
	l._process(l.CROSS_SECONDS)
	check(l.stage==11 and l.kills==44 and dogs==2,"six encounters total 44 enemies and only two dogs")
	check(l.survivors.size()==4 and l.survivors[3].position.x>4200,"Mara and all three survivors reach safe side")
	remember()
	l.player.position = Vector2(4320,250)
	await capture("04_safe")
	for saved in safe_saves:
		check(RouteSave.write_data(saved) and not RouteSave.read_data().is_empty(),"safe checkpoint accepted "+str(saved.stage))
		l.restore(saved)
		check(l.stage==int(saved.stage) and l.remaining()==0 and not l.blocked,"safe checkpoint restores "+str(saved.stage))
	l.restore(safe_saves.back())
	l.player.position = Vector2(4320,250)
	l.interact()
	check(app.awaiting_end and app.ui.dialog_name.text=="MARA","final conversation starts after rescue")
	dialogue()
	check(app.mode=="result" and l.stage==12,"level ends at result screen")
	await capture("05_result")
	for key in ["opening","refuge","generator","crossing","ending"]:
		for line in RescueArt.dialogue(key):
			app.ui.start_dialogue([line])
			await process_frame
			check(app.ui.dialog_text.get_line_count()<=3,"readable dialogue "+key)
	app.queue_free()
	for i in 4: await process_frame
	DirAccess.remove_absolute(RouteSave.save_path)
	print("RESCUE FAILURES: ",failures)
	quit(1 if failures else 0)
