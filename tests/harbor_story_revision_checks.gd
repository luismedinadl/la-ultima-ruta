extends SceneTree
var app
var level: HarborLevel
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",message)
func close_dialogue() -> void:
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = -1
		app.ui.advance_dialogue()
func run() -> void:
	RouteSave.save_path = "res://tests/harbor_story_revision_checkpoint.json"
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.start_route(false,8)
	close_dialogue()
	level = app.level
	level.set_process(false)
	level.player.set_physics_process(false)
	level.gate_open = true
	level.set_stage(9)
	level.civilian_gate_steps.assign([4,4,4,4])
	for i in 4: level.civilians[i].position = Vector2(3800-i*32,205)
	var prior := level.civilians[0].position
	level.set_stage(10)
	level.refresh_objects()
	check(level.civilians[0].position==prior,"clearing combat never teleports survivors")
	level.player.position = Vector2(4510,280)
	for i in 200:
		level._process(0.1)
		if level.stage==11: break
	check(level.survivors_at_blockade() and level.stage==11,"four visible survivors arrive at chief blockade")
	check(level.chief_block.collision_layer==4 and level.chief_guards.all(func(g): return g.visible),"chief and two guards physically block the passage")
	prior = level.civilians[0].position
	level._process(3)
	check(level.civilians[0].position==prior,"group waits during confrontation")
	var saved := level.snapshot()
	check(RouteSave.write_data(saved) and not RouteSave.read_data().is_empty(),"new checkpoint validates")
	close_dialogue()
	check(level.stage==13 and is_instance_valid(level.anchored) and level.chief_block.collision_layer==0,"breakout clears blockade and starts boss automatically")
	level.anchored.set_physics_process(false)
	level._process(0.1)
	check(level.civilians[0].position.x>prior.x and level.civilians[0].position.distance_to(prior)<12,"survivors run out visibly without teleporting")
	check(level.boss_npc.animation=="walk" and not level.guards_down[0],"chief flees while guards stay to fight")
	level.restore(saved)
	check(level.civilians[0].position==prior,"checkpoint restores exact group positions")
	var legacy := saved.duplicate(true)
	legacy.erase("harbor_story_version")
	legacy.erase("civilian_positions")
	legacy.stage = 12
	legacy.chief_saved = true
	legacy.x = 4690
	level.restore(legacy)
	check(level.stage==11 and level.player.position.x==4510 and not level.chief_saved,"old rescue checkpoint migrates to new confrontation")
	level.chief_saved = true
	level.boss_defeated = true
	level.set_stage(14)
	level.refresh_objects()
	level.player.position = Vector2(5670,280)
	level.interact()
	check(level.stage==14,"cannot embark before the group arrives")
	level._process(20)
	check(level.survivors_at_rescue(),"all survivors reach the boat on foot")
	level.interact()
	check(level.stage==15,"embarkation unlocks with group safe")
	var transcript := JSON.stringify(BroadcastArt.dialogue("transmission"))
	check(transcript.contains("archivos no llegaron") and not transcript.contains("guardé una copia"),"level seven clearly reports failed file transfer")
	check(JSON.stringify(HarborArt.dialogue("ending")).contains("Se los entregaré a las autoridades"),"Nico tells Mara the evidence is safe before boarding")
	print("STORY REVISION FAILURES: ",failures)
	app.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
