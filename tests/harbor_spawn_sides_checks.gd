extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label_: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label_)
func run() -> void:
	RouteSave.save_path = "res://tests/harbor_spawn_sides_checkpoint.json"
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.start_route(false,8)
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = -1
		app.ui.advance_dialogue()
	var level: HarborLevel = app.level
	level.set_process(false)
	level.player.set_physics_process(false)
	for player_x in [2795.0,2864.0,2933.0,2964.0]:
		level.set_stage(5)
		level.player.position = Vector2(player_x,280)
		level.start_wave(3)
		check(level.arrivals.size()==8,"initial wave preserves eight enemies")
		check(level.arrivals.all(func(e): return absf(e.position.x-player_x)>=90),"entrances safe at "+str(player_x))
		await physics_frame
		level.advance_arrivals(3)
		var front := 0
		var behind := 0
		for enemy in level.enemies:
			enemy.set_physics_process(false)
			if enemy.position.x>player_x: front += 1
			else: behind += 1
			var before_x: float = enemy.position.x
			enemy._physics_process(0.1)
			check(absf(enemy.position.x-before_x)<40,"entry moves without snapping into player bounds")
		check(front==4 and behind==4,"four enemies enter from each side at "+str(player_x))
		level.queue_group(4,1,0)
		check(level.arrivals.filter(func(e): return e.position.x>player_x).size()==2,"reinforcements also enter from ahead")
		check(level.arrivals.filter(func(e): return e.position.x<player_x).size()==3,"reinforcements also enter from behind")
		for entry in level.arrivals: entry.warning.queue_free()
		level.arrivals.clear()
		for enemy in level.enemies: enemy.queue_free()
		level.enemies.clear()
		await process_frame
	print("SPAWN SIDES FAILURES: ",failures)
	app.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
