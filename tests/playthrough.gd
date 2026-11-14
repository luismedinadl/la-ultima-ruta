extends SceneTree
## Integration checks drive real game state and actor damage, not a mock model.
var failures: Array[String] = []
var checks := 0
var capture := false
var app

func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("CHECK FAILED: " + message)
	else: print("PASS: ", message)

func settle(seconds: float = 0.05) -> void:
	await create_timer(seconds).timeout

func screenshot(name_: String) -> void:
	if not capture: return
	await create_timer(0.4).timeout
	if is_instance_valid(app.level):
		app.level.camera.force_update_scroll()
		print("CAPTURE ", name_, " player=", app.level.player.position, " camera=", app.level.camera.get_screen_center_position())
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
	root.get_texture().get_image().save_png("res://docs/screenshots/" + name_ + ".png")

func finish_dialogue() -> void:
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = app.ui.dialog_text.text.length()
		app.ui.reveal = app.ui.dialog_text.text.length()
		app.ui.advance_dialogue()

func clear_wave() -> void:
	for enemy in app.level.enemies:
		if not enemy.dead: enemy.take_damage(1000, app.level.player.position)
	await settle()

func run() -> void:
	RouteSave.save_path = "user://automated_test_checkpoint.json"
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await settle(0.2)
	check(app.mode == "menu", "Main menu opens")
	await screenshot("01_menu")
	app.start_route(false)
	await settle(0.2)
	check(app.ui.dialogue_active and app.level.blocked, "Opening dialogue blocks gameplay")
	var p = app.level.player
	var before: Vector2 = p.position
	Input.action_press("route_right")
	Input.action_press("route_attack")
	await settle(0.15)
	Input.action_release("route_attack")
	Input.action_release("route_right")
	check(p.position == before and p.action == "idle", "Cannot move or attack during dialogue")
	app.ui.dialog_text.visible_characters = app.ui.dialog_text.text.length()
	app.ui.reveal = app.ui.dialog_text.text.length()
	await screenshot("02_dialogue")
	finish_dialogue()
	check(not app.level.blocked, "Last dialogue line unlocks player")
	Input.action_press("route_right")
	await settle(0.2)
	Input.action_release("route_right")
	check(p.position.x > before.x + 2, "Movement uses actual input actions")
	p.position = Vector2(RouteLevel.LOCAL, 225)
	app.level.interact()
	check(p.action == "pickup_package", "Pickup plays animation before starting wave")
	await settle(1.0)
	check(app.level.stage == 1 and app.level.remaining() == 3 and p.carrying, "Package starts exactly 3 enemies")
	var enemy = app.level.enemies[0]
	enemy.position = p.position + Vector2(25, 0)
	var old_hp: int = enemy.health
	p.begin_attack()
	await settle(0.26)
	check(enemy.health < old_hp, "Knife animation applies damage in reach")
	var hp: int = p.health
	p.take_damage(15, p.position + Vector2(10, 0))
	p.take_damage(15, p.position + Vector2(10, 0))
	check(p.health == hp - 15, "Invulnerability prevents repeated damage")
	app.pause_route()
	var pause_pos: Vector2 = p.position
	var pause_time: float = app.level.elapsed
	await settle(0.2)
	check(p.position == pause_pos and app.level.elapsed == pause_time, "Pause freezes actors and route timer")
	app.resume_route()
	await settle(0.2)
	await screenshot("03_combat")
	await clear_wave()
	check(app.level.stage == 2 and app.level.kills == 3, "Wave 1 completes and unlocks crossing objective")
	check(int(RouteSave.read_data().get("stage", -1)) == 2, "Safe checkpoint is written")
	app.start_route(true)
	await settle(0.1)
	check(app.level.stage == 2 and app.level.kills == 3 and not app.ui.dialogue_active, "Continue restores progress without replaying dialogue")
	p = app.level.player
	p.position = Vector2(RouteLevel.CROSSING - 165, 245)
	await settle(0.1)
	check(app.level.stage == 3 and app.level.remaining() == 5, "Crossing zone starts exactly 5 enemies")
	app.level.camera.position = Vector2(RouteLevel.CROSSING + 65, 162)
	app.level.camera.reset_smoothing()
	await screenshot("05_crossing")
	await clear_wave()
	check(app.level.stage == 4 and app.level.kills == 8, "Wave 2 unlocks delivery route")
	p.health = 50
	p.position = Vector2(2510, 224)
	await process_frame
	await process_frame
	check(p.health == 85 and app.level.collected.has("2510"), "Medkit heals once")
	await process_frame
	await process_frame
	check(p.health == 85, "Collected medkit cannot be reused")
	p.position = Vector2(RouteLevel.DELIVERY - 195, 245)
	await settle(0.1)
	check(app.level.stage == 5 and app.level.remaining() == 6, "Final zone starts exactly 6 enemies")
	check(app.level.enemies[-1].resistant and app.level.enemies[-1].health == 190, "Final wave includes one resistant zombie")
	app.level.camera.position = Vector2(RouteLevel.DELIVERY + 65, 162)
	app.level.camera.reset_smoothing()
	await screenshot("06_delivery_district")
	await clear_wave()
	check(app.level.stage == 6 and app.level.kills == 14 and not app.level.gate.visible, "All 14 kills unlock entrance")
	p.action_time = 0
	p.position = Vector2(RouteLevel.DELIVERY, 225)
	app.level.interact()
	await settle(1.0)
	check(app.ui.dialogue_active and app.level.blocked, "Delivery opens closing dialogue and locks action")
	finish_dialogue()
	check(app.mode == "result", "Closing dialogue reaches results screen")
	await screenshot("04_completed")
	app.start_route(false)
	await settle(0.05)
	finish_dialogue()
	p = app.level.player
	p.health = 1
	p.invulnerability = 0
	p.take_damage(15, p.position + Vector2.RIGHT)
	await settle(1.2)
	check(app.mode == "result" and p.dead, "Death animation reaches defeat screen")
	app.start_route(false)
	await settle(0.05)
	check(app.level.player.health == 100 and app.level.kills == 0, "Retry resets route and player")
	app.show_menu()
	await settle()
	check(not is_instance_valid(app.level) and app.mode == "menu", "Returning to menu releases the level")
	app.queue_free()
	await process_frame
	await process_frame
	RouteArt.frame_cache.clear()
	RouteArt.textures.clear()
	await settle(0.15)
	DirAccess.remove_absolute(RouteSave.save_path)
	print("PLAYTHROUGH: ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
