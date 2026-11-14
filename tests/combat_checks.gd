extends SceneTree
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("PASS: " if ok else "FAIL: ", message)
func run() -> void:
	RouteSave.save_path = "user://automated_combat_test.json"
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false)
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = 1000
		app.ui.advance_dialogue()
	var p = app.level.player
	p.controls_enabled = false
	p.position = Vector2(RouteLevel.LOCAL, 250)
	app.level.start_wave(1)
	var enemy = app.level.enemies[0]
	enemy.position = p.position + Vector2(18, 0)
	app.level.enemies[1].position = Vector2(RouteLevel.LOCAL - 240, 300)
	app.level.enemies[2].position = Vector2(RouteLevel.LOCAL + 240, 300)
	await create_timer(1.0).timeout
	check(p.health < 100, "Enemy AI attacks and damages stationary player")
	check(app.level.damage_received > 0, "Damage statistics track actual enemy attack")
	var hp: int = enemy.health
	p.position = Vector2(RouteLevel.LOCAL - 200, 205)
	p.action_time = 0
	p.begin_attack()
	await create_timer(0.23).timeout
	check(enemy.health == hp, "Knife cannot damage targets outside reach")
	enemy.take_damage(1000, p.position)
	await create_timer(1.0).timeout
	check(enemy.dead and enemy.sprite.animation.begins_with("death") and enemy.sprite.frame == 5, "Corpse retains last death frame")
	var remaining: int = app.level.remaining()
	enemy.take_damage(1000, p.position)
	check(app.level.remaining() == remaining and app.level.kills == 1, "Dead enemy cannot be counted twice")
	for e in app.level.enemies:
		if not e.dead: e.take_damage(1000, p.position)
	await create_timer(0.1).timeout
	check(app.level.stage == 2 and app.level.remaining() == 0, "Cleared wave does not respawn")
	var file := FileAccess.open(RouteSave.save_path, FileAccess.WRITE)
	file.store_string('{"version":1,"stage":{},"x":0,"health":100,"kills":0,"damage":0,"elapsed":0}')
	file.close()
	check(RouteSave.read_data().is_empty(), "Malformed checkpoint is rejected safely")
	app.queue_free()
	await process_frame
	RouteArt.frame_cache.clear()
	RouteArt.textures.clear()
	await create_timer(0.15).timeout
	DirAccess.remove_absolute(RouteSave.save_path)
	print("COMBAT_CHECKS: ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
