extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	RouteControls.setup()
	var audio := RouteAudio.new()
	root.add_child(audio)
	var level := SurvivalLevel.new()
	level.audio = audio
	root.add_child(level)
	level.set_process(false)
	level.player.set_physics_process(false)
	level.begin_round(101)
	level.phase = "combat"
	for i in 35: level._process(0.7)
	assert(level.remaining()==24 and level.pending_enemies==78)
	var enemy = level.enemies[0]
	var origin: Vector2 = enemy.position
	for i in 20: await physics_frame
	assert(enemy.position.distance_to(origin)>1)
	print("PASS live enemies pursue Nico and large waves retain queued enemies")
	level.begin_round(10)
	await process_frame
	level.phase = "combat"
	level.spawn_next()
	var boss = level.enemies[0]
	for i in 20: await physics_frame
	assert(boss is AnchoredEnemy and level.remaining()==1)
	for state in ["charge","sweep","slam"]:
		boss.enter(state,0.2,state)
		boss._physics_process(0.1)
	print("PASS Anclado moves and executes attacks in survival")
	level.queue_free()
	audio.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
