extends SceneTree
var app
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",message)
func finger(id: int, pos: Vector2, pressed: bool, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = pos
	event.pressed = pressed
	event.canceled = canceled
	root.push_input(event,true)
func drag(id: int, pos: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = id
	event.position = pos
	root.push_input(event,true)
func close_dialogue() -> void:
	for i in 60:
		if not app.ui.dialogue_active: return
		finger(7,Vector2(300,255),true)
		finger(7,Vector2(300,255),false)
func capture(file: String) -> void:
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/"+file+".png")
func run() -> void:
	RouteSave.save_path = "res://tests/touch_test.json"
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	check(not app.touch.enabled,"desktop keeps normal controls")
	app.touch.set_enabled(true)
	check(RouteControls.touch_mode and app.ui.mobile,"mobile interface enabled")
	check(app.touch.atlas.get_image().get_pixel(0,0).a == 0,"atlas has real transparency")
	for row in 3:
		for col in 8:
			var rect: Rect2 = app.touch.icon(col,row).region
			check(Rect2(Vector2.ZERO,app.touch.atlas.get_size()).encloses(rect),"atlas region in bounds")
	app.start_intro()
	await create_timer(0.4).timeout
	var intro = app.ui.screen
	var before: int = intro.page
	finger(1,Vector2(250,242),true)
	finger(1,Vector2(250,242),false)
	await create_timer(0.4).timeout
	check(intro.page == before+1,"touch advances cinematic once")
	app.start_route(false,8)
	await process_frame
	check(app.ui.dialogue_active,"opening dialogue exists")
	app.ui.dialog_text.visible_characters = 0
	var line: int = app.ui.line_index
	finger(1,Vector2(300,255),true)
	finger(1,Vector2(300,255),false)
	check(app.ui.line_index == line and app.ui.dialog_text.visible_characters > 0,"first dialogue tap reveals text without skipping")
	close_dialogue()
	check(not app.ui.dialogue_active and not app.level.blocked,"touch can finish opening dialogue")
	app.touch.refresh()
	var p = app.level.player
	p.action_time = 0
	p.weapon_slot = 1
	p.pistol_equipped = true
	p.magazine = 12
	p.reserve = 24
	app.touch.refresh()
	await capture("touch_01_gameplay")
	var start: Vector2 = p.position
	finger(0,Vector2(92,266),true)
	finger(1,Vector2(512,270),true)
	await create_timer(0.65).timeout
	check(p.position.x>start.x and p.magazine<12,"two fingers move and shoot together")
	finger(1,Vector2(512,270),false)
	check(not RouteControls.virtual_attack and RouteControls.virtual_move.x>0,"release attack keeps joystick moving")
	drag(0,Vector2(-30,450))
	check(RouteControls.virtual_move.length()<=1,"joystick remains bounded outside its base")
	finger(0,Vector2(-30,450),false,true)
	check(RouteControls.virtual_move == Vector2.ZERO,"canceled finger releases joystick")
	p.action_time = 0
	p.magazine = 5
	app.touch.refresh()
	finger(2,Vector2(444,229),true)
	check(p.action == "reload","reload tap starts reload")
	finger(2,Vector2(444,229),false)
	await create_timer(1.8).timeout
	check(p.magazine == 12,"reload transfers ammunition")
	p.action_time = 0
	finger(3,Vector2(444,290),true)
	var slot: int = p.weapon_slot
	await create_timer(0.5).timeout
	check(slot == 2 and p.weapon_slot == slot,"weapon switch happens once per touch")
	finger(3,Vector2(444,290),false)
	app.touch.refresh()
	check(app.touch.icons.attack == 2,"attack icon follows shotgun")
	finger(0,Vector2(92,266),true)
	finger(1,Vector2(512,270),true)
	finger(4,Vector2(544,24),true)
	check(paused and RouteControls.virtual_move == Vector2.ZERO and not RouteControls.virtual_attack,"pause releases both held controls")
	app.touch.refresh()
	await capture("touch_02_pause")
	app.resume_route()
	check(app.touch.fingers.is_empty(),"resume cannot restore stale finger presses")
	p.action_time = 0
	finger(0,Vector2(92,266),true)
	app.ui.start_dialogue([{"name":"NICO","portrait":1,"text":"El camino está despejado."}])
	app.touch.refresh()
	check(RouteControls.virtual_move == Vector2.ZERO and not app.touch.stick.visible,"dialogue clears movement and hides combat controls")
	await capture("touch_03_dialogue")
	close_dialogue()
	app.level.stage = 4
	p.position.x = app.level.destination()
	p.action_time = 0
	app.touch.refresh()
	check(app.touch.buttons.interact.visible,"interaction appears near a usable object")
	finger(2,Vector2(520,198),true)
	finger(2,Vector2(520,198),false)
	check(app.reading_document and app.ui.dialogue_active,"hand button opens the document")
	await capture("touch_04_document")
	close_dialogue()
	check(not app.reading_document,"touch closes document and resumes route")
	finger(0,Vector2(92,266),true)
	app.touch._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(paused and RouteControls.virtual_move == Vector2.ZERO,"focus loss releases input and pauses")
	app.resume_route()
	app.touch.fit_safe_area(Rect2(24,0,528,324))
	check(app.ui.root.position.x>=24 and app.ui.root.position.x+576*app.ui.root.scale.x<=552.1,"UI fits a simulated safe area")
	app.touch.update_safe_area()
	app.show_menu()
	app.touch.refresh()
	check(not app.touch.buttons.attack.visible and not RouteControls.virtual_attack,"menu cannot leave attack held")
	for number in range(1,9):
		app.start_route(false,number)
		for attempt in 8:
			await process_frame
			if app.ui.dialogue_active: close_dialogue()
			if app.mode in ["radio_scene","pistol_scene"]:
				app.ui.screen.finish()
				await create_timer(0.3).timeout
			if app.mode == "playing" and not app.level.blocked: break
		app.touch.refresh()
		check(app.touch.combat and app.touch.stick.visible,"touch controls available after level %d opening" % number)
		check(not app.ui.hint.text.contains("Tab") and not app.ui.hint.text.contains("Espacio"),"mobile hints for level %d" % number)
	app.show_menu()
	app.touch.set_enabled(false)
	check(not app.ui.mobile and app.ui.ammo_panel.position == Vector2(8,263),"desktop layout restored")
	app.queue_free()
	await process_frame
	await process_frame
	for suffix in ["", ".tmp", ".progress", ".progress.tmp"]:
		var path: String = RouteSave.save_path+suffix
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	print("TOUCH FAILURES: ",failures)
	quit(0 if failures==0 else 1)
