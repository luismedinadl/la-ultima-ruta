extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ", description)
func tick() -> void:
	await process_frame
	await process_frame
func run() -> void:
	RouteControls.setup()
	var audio := RouteAudio.new()
	root.add_child(audio)
	for number in [1, 2, 3]:
		var level: RouteLevel = MetroLevel.new() if number == 3 else RouteLevel.new()
		level.level_number = number
		level.audio = audio
		root.add_child(level)
		var p := level.player
		p.set_physics_process(false)
		var key = level.medkits.keys()[0]
		var kit = level.medkits[key]
		p.position = kit.position
		level.blocked = false
		await tick()
		check(kit.visible and not level.collected.has(key), "full health preserves kit level %d" % number)
		p.health = 50
		level.blocked = true
		await tick()
		check(p.health == 50 and kit.visible, "dialogue blocks pickup")
		level.blocked = false
		p.dead = true
		await tick()
		check(p.health == 50 and kit.visible, "dead player cannot collect")
		p.dead = false
		p.position = kit.position + Vector2(35, 0)
		await tick()
		check(p.health == 50 and kit.visible, "must pass over kit")
		p.position = kit.position
		await tick()
		check(p.health == 85 and not kit.visible and level.collected.has(key), "automatic healing without input level %d" % number)
		await tick()
		check(p.health == 85, "kit cannot heal twice")
		var saved := level.snapshot()
		level.restore(saved)
		check(not kit.visible and level.collected.has(key), "checkpoint preserves consumed kit")
		var second = level.medkits[level.medkits.keys()[1]]
		p.health = 90
		p.position = second.position
		await tick()
		check(p.health == 100 and not second.visible, "healing capped at 100")
		level.queue_free()
		await tick()
	audio.queue_free()
	await tick()
	await create_timer(0.4).timeout
	print("MEDKIT failures: ", failures)
	quit(failures)
