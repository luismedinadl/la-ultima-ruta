extends SceneTree
var app
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",message)
func close_dialogue() -> void:
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = -1
		app.ui.advance_dialogue()
func capture(file: String) -> void:
	app.ui.zone_text.text = ""
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/"+file+".png")
func run() -> void:
	RouteSave.save_path = "res://tests/connections_test.json"
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false,2)
	await process_frame
	check(app.ui.lines.size()==7 and app.awaiting_pistol_scene,"level 2 starts approved depot conversation")
	var p = app.level.player
	var ammo: int = p.magazine+p.reserve
	var pos: Vector2 = p.position
	close_dialogue()
	await create_timer(0.4).timeout
	check(app.mode=="pistol_scene" and app.level.blocked and not app.ui.hud.visible,"pickup illustration pauses level and hides HUD")
	check(app.ui.screen.pages.size()==2,"pickup contains two approved lines")
	var time: float = app.level.elapsed
	RouteControls.virtual_move = Vector2.RIGHT
	await create_timer(0.15).timeout
	RouteControls.virtual_move = Vector2.ZERO
	check(p.position==pos and app.level.elapsed==time,"movement and timer stay frozen")
	await capture("connections_01_pistol")
	app.ui.screen.advance()
	await create_timer(0.4).timeout
	check(app.ui.screen.page==1,"pickup advances normally")
	app.ui.screen.advance()
	await create_timer(0.3).timeout
	check(app.mode=="playing" and not app.level.blocked and p.magazine+p.reserve==ammo,"pickup releases controls without changing ammunition")
	app.start_route(true)
	await process_frame
	check(app.mode=="playing" and not app.awaiting_pistol_scene and not app.ui.dialogue_active,"saved level 2 bypasses pickup scene")
	app.level.blocked = true
	app.level.player.position.x = app.level.delivery_x
	app.level.camera.position.x = app.level.delivery_x
	app.ui.zone_timeout = 0
	await capture("connections_02_cargo")
	app.on_delivered()
	check(app.ui.lines[1].text=="Aquí solo se reciben paquetes.","level 2 ending explains cargo reception")
	close_dialogue()
	app.handle_command("next_level")
	await process_frame
	check(app.level.level_number==3 and app.ui.lines[0].text=="Ya estoy en la estación. No hay luz.","next level opens new metro dialogue")
	app.ui.dialog.hide()
	app.ui.dialogue_active = false
	app.ui.zone_timeout = 0
	await capture("connections_03_metro")
	app.on_delivered()
	check(app.ui.lines[1].text.contains("campamento"),"metro ending connects camp")
	close_dialogue()
	app.start_route(false,4)
	await process_frame
	app.ui.dialog.hide()
	app.ui.dialogue_active = false
	app.level.player.position.x = app.level.delivery_x
	app.level.camera.position.x = app.level.delivery_x
	await capture("connections_04_exit")
	app.level.document_read = [0]
	app.on_delivered()
	check(app.ui.lines[5].text.contains("paquetes") and not str(app.ui.lines).contains("no iban a evacuarnos"),"unread optional document never revealed by Nico")
	app.level.document_read = [0,1]
	app.on_delivered()
	check(app.ui.lines[5].text.contains("no iban a evacuarnos"),"read evacuation order uses approved accusation")
	for entry in ContainmentArt.opening():
		app.ui.start_dialogue([entry])
		await process_frame
		check(app.ui.dialog_text.get_line_count()<=3,"camp opening fits dialogue panel")
	for key in ["level2_open","level2_end","level3_open","level3_end","level4_end_start","level4_read_order","level4_read_record","level4_end_finish"]:
		for line in RouteStory.dialogue(key):
			app.ui.start_dialogue([line])
			await process_frame
			check(app.ui.dialog_text.get_line_count()<=3,"dialogue fits: "+key)
	app.start_route(false,2)
	close_dialogue()
	await create_timer(0.4).timeout
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	await create_timer(0.3).timeout
	check(app.mode=="playing" and not paused and not app.level.blocked,"Escape skips pickup without pausing gameplay")
	app.queue_free()
	for i in 4: await process_frame
	DirAccess.remove_absolute(RouteSave.save_path)
	print("CONNECTION FAILURES: ",failures)
	quit(1 if failures else 0)
