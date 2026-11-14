extends SceneTree
var failures := 0
var app
var l: DistributionLevel
var dogs := 0
var snapshots: Array = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",message)
func close_dialogue() -> void:
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = -1
		app.ui.advance_dialogue()
func stop_enemies() -> void:
	for enemy in l.enemies: enemy.set_physics_process(false)
func settle() -> void:
	l._process(3)
	stop_enemies()
func defeat(avoid: bool = false) -> void:
	for enemy in l.enemies.duplicate():
		if enemy.dead or (avoid and enemy.get_meta("optional",false)): continue
		if enemy is InfectedDog: dogs += 1
		enemy.take_damage(10000,l.player.position)
func finish_encounter(avoid: bool = false) -> void:
	for i in 8:
		settle()
		defeat(avoid)
		l._process(0.01)
		if l.stage not in l.FIGHT_STAGES: return
	check(false,"encounter must finish without endless spawns")
func interact() -> void:
	l.player.position = Vector2(l.destination(),270)
	l.player.action_time = 0
	l.interact()
func remember() -> void:
	if l.stage in l.SAFE_STAGES: snapshots.append(l.snapshot())
func capture(file: String) -> void:
	l.camera.position.x = clampf(l.player.position.x+65,288,l.world_length-288)
	app.ui.zone_text.text = ""
	if app.ui.dialogue_active:
		app.ui.reveal = app.ui.dialog_text.text.length()
		app.ui.dialog_text.visible_characters = -1
	await create_timer(0.8).timeout
	await process_frame
	await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/distribution_"+file+".png")
func run_path(avoid: bool) -> void:
	dogs = 0
	snapshots.clear()
	app.start_route(false,6)
	await physics_frame
	l = app.level
	check(l.blocked and app.ui.dialog_name.text=="MARA","level 6 opening has Mara and blocks controls")
	close_dialogue()
	l.set_process(false)
	l.player.controls_enabled = false
	remember()
	for i in 4: await physics_frame
	check(l.ammo_pickups.size()==6 and l.shell_boxes.size()==4,"six pistol boxes and four shell boxes total")
	for key in l.ammo_pickups:
		check(is_equal_approx(l.ammo_pickups[key].sprite.position.x,float(key)),"pickup position preserved "+key)
	check(l.player.test_move(Transform2D(0,Vector2(1450,285)),Vector2(0,-80)),"pallet has real blocking collision")
	l.player.position = Vector2(650,270)
	l.start_wave(1)
	check(l.remaining()==0 and l.arrivals.size()==6,"first encounter warns before any enemy appears")
	l.blocked = true
	l._process(3)
	check(l.remaining()==0,"dialogue freezes pending arrivals")
	l.blocked = false
	settle()
	check(l.remaining()==6,"first encounter has exactly six enemies")
	finish_encounter()
	remember()
	interact()
	check(l.stage==3 and l.access_card and not l.card_sprite.visible,"card pickup unlocks sorting")
	remember()
	await capture("01_reception")
	l.player.position = Vector2(1610,280)
	l.start_wave(2)
	stop_enemies()
	settle()
	check(l.remaining()==8,"sorting contains eight including four optional Huecos")
	if not avoid:
		l.make_noise(l.player.position,550,true)
		for enemy in l.enemies:
			if not enemy.dead: check(enemy.awareness==2,"gun noise wakes sorting group")
	finish_encounter(avoid)
	check(l.stage==5 and l.remaining()==(4 if avoid else 0),"sorting allows bypass of only dormant optional enemies")
	interact()
	check(l.blocked and app.ui.lines[0].document,"mandatory delivery record is readable")
	await capture("02_registry")
	close_dialogue()
	check(l.stage==6 and l.document_read.has(0) and l.remaining()==0,"record retires avoided enemies without fake kills")
	remember()
	l.player.position = Vector2(2570,270)
	l.start_wave(3)
	finish_encounter()
	check(l.stage==8,"both cold storage groups required")
	remember()
	interact()
	await capture("03_continuity")
	close_dialogue()
	remember()
	l.player.position = Vector2(3530,270)
	l.start_wave(4)
	finish_encounter()
	check(l.stage==11,"office safe only after both groups")
	remember()
	interact()
	close_dialogue()
	check(l.stage==12 and not l.phone_finished,"order precedes phone call")
	remember()
	interact()
	check(app.ui.lines[0].text.contains("llamar"),"Nico explicitly initiates call to boss")
	await capture("04_phone")
	close_dialogue()
	check(l.stage==13 and l.phone_finished,"phone unlocks archive copy")
	remember()
	l.review_documents()
	check(l.blocked and app.ui.lines.size()==9,"collected documents can be read again")
	close_dialogue()
	check(l.stage==13,"review never advances route")
	interact()
	check(app.ui.lines[0].text.contains("borrarán"),"deletion notice precedes copying")
	close_dialogue()
	check(l.stage==14 and l.records_copied and l.arrivals.size()==5,"copy is immediate and alarm starts finite combat")
	settle()
	await capture("05_alarm")
	finish_encounter()
	check(l.stage==15,"control opens exit without countdown")
	remember()
	l.player.position = Vector2(5450,270)
	l.start_wave(6)
	finish_encounter()
	check(l.stage==17 and l.kills==(44 if avoid else 48) and dogs==3,"correct finite total and three dogs")
	remember()
	await capture("06_exit")
	for saved in snapshots:
		check(RouteSave.write_data(saved) and not RouteSave.read_data().is_empty(),"checkpoint accepted stage "+str(saved.stage))
		l.restore(RouteSave.read_data())
		check(l.stage==int(saved.stage) and not l.blocked and l.remaining()==0 and l.arrivals.is_empty(),"checkpoint restores safely "+str(saved.stage))
	l.restore(snapshots.back())
	interact()
	close_dialogue()
	check(app.mode=="result" and l.stage==18,"results follow final Mara conversation")
	await capture("07_results")
func run() -> void:
	RouteSave.save_path = "user://distribution_test.json"
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await run_path(true)
	await run_path(false)
	for key in DistributionArt.script_data().dialogues:
		for line in DistributionArt.dialogue(key):
			app.ui.start_dialogue([line])
			await process_frame
			check(app.ui.dialog_text.get_line_count()<=3,"dialogue fits "+key)
	for doc in 4:
		for line in DistributionArt.document(doc):
			app.ui.start_dialogue([line])
			await process_frame
			check(app.ui.dialog_text.get_line_count()<=8,"document page fits "+str(doc))
	app.queue_free()
	for i in 5: await process_frame
	DirAccess.remove_absolute(RouteSave.save_path)
	print("DISTRIBUTION FAILURES: ",failures)
	quit(1 if failures else 0)
