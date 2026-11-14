extends SceneTree
var errors := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text_: String) -> void:
	if not ok: errors += 1
	print("PASS " if ok else "FAIL ",text_)
func capture(file: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/"+file+".png")
func run() -> void:
	RouteSave.save_path = "user://radio_test.json"
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false,5)
	await create_timer(0.4).timeout
	check(app.mode=="radio_scene" and app.level.blocked and not app.ui.hud.visible,"radio scene precedes Mara and hides gameplay HUD")
	var scene = app.ui.screen
	check(scene.pages.size()==2 and scene.page==0,"two illustrated discovery panels")
	var position: Vector2 = app.level.player.position
	RouteControls.virtual_move = Vector2.RIGHT
	await create_timer(0.2).timeout
	RouteControls.virtual_move = Vector2.ZERO
	check(app.level.player.position==position and app.level.elapsed==0,"movement and route clock frozen")
	check(scene.body.get_line_count()<=2,"discovery caption fits")
	await capture("radio_01_discovery")
	scene.advance()
	await create_timer(0.4).timeout
	check(scene.page==1 and scene.body.text.contains("funciona"),"Nico confirms radio works")
	await capture("radio_02_powered")
	scene.advance()
	await create_timer(0.3).timeout
	check(app.mode=="playing" and app.level.blocked and app.ui.dialog_name.text=="MARA","existing Mara call follows radio scene")
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = -1
		app.ui.advance_dialogue()
	check(not app.level.blocked,"controls return after existing opening")
	app.start_route(true)
	await process_frame
	check(app.mode=="playing" and not app.ui.dialogue_active,"continue does not repeat discovery")
	app.start_route(false,5)
	await create_timer(0.4).timeout
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	await create_timer(0.3).timeout
	check(app.mode=="playing" and app.ui.dialog_name.text=="MARA" and not paused,"skip leads to Mara without pausing")
	app.queue_free()
	for i in 4: await process_frame
	DirAccess.remove_absolute(RouteSave.save_path)
	print("RADIO FAILURES: ",errors)
	quit(1 if errors else 0)
