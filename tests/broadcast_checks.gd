extends SceneTree
var failures := 0
var app
var l: BroadcastLevel
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
func finish_encounter() -> void:
	for attempt in 8:
		l._process(3)
		for enemy in l.enemies:
			enemy.set_physics_process(false)
			if enemy.dead: continue
			check(not enemy.show_awareness_icon,"wave enemies have no question marks")
			if enemy is InfectedDog: dogs += 1
			enemy.take_damage(10000,l.player.position)
		l._process(0.01)
		if l.stage not in l.FIGHT_STAGES: return
	check(false,"finite encounter terminates")
func interact() -> void:
	l.player.position = Vector2(l.destination(),255)
	l.player.action_time = 0
	l.interact()
func remember() -> void:
	check(l.stage in l.SAFE_STAGES,"safe progression stage "+str(l.stage))
	snapshots.append(l.snapshot())
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
		root.get_texture().get_image().save_png("res://docs/screenshots/broadcast_"+file+".png")
func run() -> void:
	RouteSave.save_path = "res://tests/broadcast_checkpoint_test.json"
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	for key in BroadcastArt.script_data().dialogues:
		for entry in BroadcastArt.dialogue(key):
			app.ui.start_dialogue([entry])
			await process_frame
			check(app.ui.dialog_text.get_line_count()<=3,"dialogue fits panel: "+key)
	app.ui.dialogue_active = false
	app.ui.dialog.hide()
	app.start_route(false,6)
	close_dialogue()
	app.handle_command("next_level")
	await physics_frame
	l = app.level
	check(l.level_number==7 and l.blocked,"level 6 connects to 7 with opening dialogue")
	close_dialogue()
	l.set_process(false)
	l.player.controls_enabled = false
	remember()
	check(l.ammo_pickups.size()==7 and l.shell_boxes.size()==6 and l.medkits.size()==2,"approved limited supplies")
	for key in l.ammo_pickups:
		check(float(key)>900 and l.ammo_pickups[key].sprite.position.x==float(key),"no ammo before first encounter or clamped pickups")
	l.player.position = Vector2(650,255)
	l._process(0.01)
	check(l.arrivals.size()==7 and l.remaining()==0,"first encounter warns before spawning")
	l.blocked = true
	var before := l.elapsed
	l._process(5)
	check(l.remaining()==0 and l.elapsed==before,"dialogue freezes encounter and time")
	l.blocked = false
	finish_encounter()
	check(l.kills==7 and l.stage==2,"entrance has seven enemies")
	remember()
	interact()
	close_dialogue()
	remember()
	l.review_documents()
	check(app.ui.dialogue_active and not app.ui.dialog_face.visible,"instructions use readable document panel")
	close_dialogue()
	check(l.stage==3,"reading instructions does not advance objective")
	interact()
	check(l.stage==4 and l.power_on,"switch powers equipment and triggers second group")
	finish_encounter()
	remember()
	interact()
	await capture("01_power")
	close_dialogue()
	remember()
	l.player.position = Vector2(2570,255)
	l._process(0.01)
	finish_encounter()
	check(l.kills==23 and l.stage==8,"antenna has nine including one dog")
	remember()
	interact()
	close_dialogue()
	remember()
	await capture("02_antenna")
	interact()
	check(app.ui.dialogue_active and l.blocked and not l.files_sent,"transmission pauses route until confirmation")
	app.ui.line_index = 5
	app.ui.show_line()
	check(app.ui.dialog_name.text=="OPERADORA" and app.ui.dialog_face.texture.resource_path.ends_with("operator.png"),"operator uses own approved portrait")
	await capture("03_confirmation")
	close_dialogue()
	check(l.files_sent and l.stage==10,"radio contact and attempted transmission persist")
	remember()
	await capture("04_studio")
	l.player.position = Vector2(4490,255)
	l._process(0.01)
	finish_encounter()
	check(l.kills==34 and l.stage==12,"service encounter has eleven")
	remember()
	interact()
	close_dialogue()
	remember()
	check(l.harbor_confirmed,"central confirms evacuation before exit")
	l.player.position = Vector2(5450,255)
	l._process(0.01)
	finish_encounter()
	check(l.kills==44 and dogs==3 and l.stage==15,"exactly 44 enemies and three dogs, no infinite spawns")
	remember()
	await capture("05_exit")
	for data in snapshots:
		check(RouteSave.write_data(data),"write checkpoint stage "+str(data.stage))
		var parsed := RouteSave.read_data()
		check(not parsed.is_empty(),"JSON validation stage "+str(data.stage))
		if parsed.is_empty(): continue
		l.restore(parsed)
		check(l.stage==int(data.stage) and l.remaining()==0 and l.arrivals.is_empty(),"restore safe stage without repeated wave")
		check(l.files_sent==data.files_sent and l.power_on==data.power_on and l.antenna_connected==data.antenna_connected,"equipment and proof flags restore")
	l.review_documents()
	check(app.ui.lines.size()==2,"received confirmation can be read again")
	close_dialogue()
	interact()
	close_dialogue()
	check(app.mode=="result","level completes with result screen")
	var next := false
	for node in app.ui.screen.get_children():
		if node is Button and node.text.begins_with("Continuar al"): next=true
	check(next,"completed level 7 offers level 8")
	await capture("06_results")
	app.show_menu()
	for number in range(1,9): RouteSave.mark_level_completed(number)
	app.ui.route_select()
	var count := 0
	for node in app.ui.screen.get_children():
		if node is Button and node.text.begins_with("Nivel"): count+=1
	check(count==8,"selector exposes eight routes")
	print("BROADCAST CHECKS: ",failures," failures")
	DirAccess.remove_absolute(RouteSave.save_path)
	app.queue_free()
	await process_frame
	quit(failures)
