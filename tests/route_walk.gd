extends SceneTree
## Accelerated traversal uses actual movement, collisions and melee damage.
## It never teleports the player or kills enemies through test damage calls.
var app
var simulated := 0.0
var last_stage := -1
var finished := false

func _initialize() -> void:
	call_deferred("start")

func start() -> void:
	RouteSave.save_path = "user://automated_walk_checkpoint.json"
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 120
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false)
	process_frame.connect(drive)

func drive() -> void:
	if finished or not is_instance_valid(app): return
	if app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = app.ui.dialog_text.text.length()
		app.ui.reveal = app.ui.dialog_text.text.length()
		app.ui.advance_dialogue()
		return
	if app.mode == "result":
		finished = true
		print("WALK_RESULT: stage=", app.level.stage, " health=", app.level.player.health, " kills=", app.level.kills, " time=", app.level.elapsed, " damage=", app.level.damage_received)
		RouteControls.virtual_move = Vector2.ZERO
		RouteControls.virtual_attack = false
		call_deferred("finish", 0 if app.level.stage == 7 else 1)
		return
	var level = app.level
	var p = level.player
	if level.stage != last_stage:
		last_stage = level.stage
		print("WALK_STAGE: ", last_stage, " x=", p.position.x, " hp=", p.health, " time=", level.elapsed)
	if level.elapsed > 1100:
		push_error("Traversal timed out at x=" + str(p.position.x))
		quit(1)
		return
	var enemy = level.nearest_enemy(p.position, 1000)
	RouteControls.virtual_attack = false
	if enemy != null:
		var difference: Vector2 = enemy.position - p.position
		if difference.length() < 40:
			RouteControls.virtual_attack = true
			RouteControls.virtual_move = -difference.normalized()
		else:
			RouteControls.virtual_move = difference.normalized()
	else:
		var target := Vector2(RouteLevel.LOCAL, 225) if level.stage == 0 else Vector2(RouteLevel.CROSSING, 250) if level.stage == 2 else Vector2(RouteLevel.DELIVERY, 250)
		if level.stage == 6: target.y = 225
		var difference: Vector2 = target - p.position
		# Keep to the open road corridor; enter the sidewalk only at objectives.
		if absf(difference.x) > 100: difference.y = 250 - p.position.y
		RouteControls.virtual_move = difference.normalized() if difference.length() > 15 else Vector2.ZERO
		if "E / Enter" in level.interaction_hint(): level.interact()

func finish(code: int) -> void:
	Engine.time_scale = 1.0
	app.queue_free()
	await process_frame
	await process_frame
	RouteArt.frame_cache.clear()
	RouteArt.textures.clear()
	await create_timer(0.15).timeout
	DirAccess.remove_absolute(RouteSave.save_path)
	quit(code)
