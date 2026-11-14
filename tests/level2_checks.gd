extends SceneTree
var app
var errors := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	if not ok: errors += 1
	print("PASS " if ok else "FAIL ",text)
func dialogue() -> void:
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = 1000
		app.ui.advance_dialogue()
func run() -> void:
	RouteSave.save_path = "user://level2_test.json"
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false,2)
	await process_frame
	var l = app.level
	var p = l.player
	check(l.level_number == 2 and l.wave_count == 5,"level2 configuration")
	check(l.blocked and p.has_pistol and p.pistol_equipped,"armed opening dialogue blocks play")
	p.begin_attack()
	check(p.magazine == 12,"dialogue blocks ammunition consumption")
	dialogue()
	check(not l.blocked,"dialogue unlocks play")
	p.controls_enabled = false
	check(p.reserve == 36,"initial reserve respects 36 round limit")
	check(l.ammo_pickups.size() == 10,"ten ammo boxes across the route")
	await physics_frame
	await physics_frame
	await process_frame
	for item in l.ammo_pickups.values():
		check(item.sprite.position.x > 1230.0,"ammo is beyond all possible first objectives")
		check(item.amount == 12,"only 12 round ammo boxes spawn")
	var old_save = l.snapshot()
	old_save.reserve = 144
	l.restore(old_save)
	check(p.reserve == 36,"old save reserve clamped to 36")
	p.reserve = 20
	p.position = l.ammo_pickups["0"].sprite.position
	l.collect_ammo()
	check(p.reserve == 32 and l.ammo_taken.has("0"),"walkover ammo adds once")
	l.collect_ammo()
	check(p.reserve == 32,"ammo cannot be collected twice")
	p.magazine = 3
	p.begin_reload()
	for frame in range(100): await physics_frame
	check(p.magazine == 12 and p.reserve == 23,"reload transfers exactly missing rounds: %s/%s action=%s remaining=%s" % [p.magazine,p.reserve,p.action,p.action_time])
	p.magazine = 5
	p.begin_reload()
	app.pause_route()
	await create_timer(0.3).timeout
	check(p.magazine == 5,"pause freezes reload")
	app.resume_route()
	for frame in range(100): await physics_frame
	var saved = l.snapshot()
	check(RouteSave.write_data(saved),"level2 checkpoint written")
	app.start_route(true)
	l = app.level
	p = l.player
	p.controls_enabled = false
	check(l.level_number == 2 and l.pickup_slot == saved.pickup_slot and p.reserve == saved.reserve,"continue restores level location ammo")
	check(l.ammo_taken.has("0") and not l.ammo_pickups["0"].sprite.visible,"continue preserves collected ammo")
	p.position = l.package_point
	l.interact()
	await create_timer(0.9).timeout
	check(l.stage == 1 and l.remaining() == 5,"package starts first wave")
	var enemy = l.enemies[0]
	for e in l.enemies: e.set_physics_process(false)
	p.position = Vector2(l.pickup_x,260)
	enemy.position = p.position + Vector2(100,0)
	for i in range(1,l.enemies.size()): l.enemies[i].position = p.position + Vector2(-220,40)
	await physics_frame
	await physics_frame
	var hp = enemy.health
	p.action_time = 0
	p.begin_attack()
	check(p.magazine == 11 and enemy.health == hp-44,"shot consumes round and damages target")
	p.action_time = 0
	p.magazine = 0
	p.reserve = 0
	p.begin_attack()
	check(p.magazine == 0 and enemy.health == hp-44,"empty gun cannot deal damage")
	# Clear known encounters to validate finite wave counts and state transitions.
	for number in range(1,6):
		if number > 1:
			p.position = Vector2(l.route_points[number-1]-150,250)
			await create_timer(0.05).timeout
		var resistant := 0
		for e in l.enemies:
			if not e.dead and e.resistant: resistant += 1
		check(l.remaining() == [5,7,8,9,10][number-1] and resistant == [1,2,3,4,5][number-1],"finite wave %d and resistant count" % number)
		for e in l.enemies.duplicate():
			if not e.dead: e.take_damage(9999,p.position)
		await process_frame
		check(l.stage == number*2,"wave %d unlocks next objective" % number)
	check(l.kills == 39 and not l.gate.visible,"39 enemies unlock delivery")
	p.position = Vector2(l.delivery_x,220)
	p.action_time = 0
	l.interact()
	await create_timer(0.9).timeout
	check(app.ui.dialogue_active and l.blocked,"delivery closing dialogue")
	dialogue()
	check(app.mode == "result" and l.stage == 11,"level2 completes")
	app.handle_command("retry")
	check(app.level.level_number == 2 and app.level.stage == 0,"retry stays on level2")
	app.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.2).timeout
	RouteArt.frame_cache.clear()
	RouteArt.textures.clear()
	DirAccess.remove_absolute(RouteSave.save_path)
	print("LEVEL2 failures: ",errors)
	quit(1 if errors else 0)
