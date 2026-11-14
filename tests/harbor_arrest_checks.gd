extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	RouteSave.save_path = "res://tests/arrest_checkpoint.json"
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.start_route(false,8)
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = -1
		app.ui.advance_dialogue()
	var level = app.level
	level.set_process(false)
	level.player.set_physics_process(false)
	level.chief_saved = true
	level.boss_defeated = true
	level.set_stage(14)
	level.boss_npc.position = Vector2(5480,205)
	for i in 4: level.civilians[i].position = Vector2(5530+i*25,211)
	level.player.position = Vector2(5640,280)
	level.refresh_objects()
	level._process(0)
	assert(level.arrest_scene.visible and not level.boss_npc.visible and not level.arrest_officer.visible)
	await create_timer(1.8).timeout
	assert(level.arrest_scene.frame==2 and not level.arrest_scene.is_playing())
	print("PASS policeman cuffs chief and holds final pose")
	app.ui.zone_text.text = ""
	await process_frame
	await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/harbor_police_arrest.png")
	var data = level.snapshot()
	level.restore(data)
	assert(level.arrest_scene.visible and not level.boss_npc.visible)
	print("PASS arrest restored without duplicate chief")
	var dialogue = HarborArt.dialogue("ending")
	for line in dialogue: assert(line.name in ["NICO","MARA"])
	assert(JSON.stringify(dialogue).contains("autoridades"))
	assert(RouteAudio.CUE_FILES.anclado_death=="anclado_death.ogg")
	assert(RouteAudio.CUE_FILES.zombie=="zombie.ogg")
	print("PASS Mara dialogue and new audio assignments")
	app.queue_free()
	await process_frame
	await process_frame
	quit()
