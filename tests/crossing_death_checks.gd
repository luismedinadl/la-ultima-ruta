extends SceneTree
class SpyAudio extends RouteAudio:
	var heard: Array[String] = []
	func cue(name_: String, _volume: float = -9, _pitch: float = 1) -> void: heard.append(name_)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	RouteControls.setup()
	var audio := SpyAudio.new()
	root.add_child(audio)
	var level := HarborLevel.new()
	level.audio = audio
	root.add_child(level)
	level.set_process(false)
	level.player.set_physics_process(false)
	level.player.position = Vector2(3370,280)
	level.start_wave(4)
	level.advance_arrivals(5)
	assert(level.enemies.any(func(e): return e.position.x<level.player.position.x))
	assert(level.enemies.any(func(e): return e.position.x>level.player.position.x))
	for enemy in level.enemies: enemy.set_physics_process(false)
	level.queue_group(4,1,0)
	assert(level.arrivals.any(func(e): return e.position.x<level.player.position.x))
	assert(level.arrivals.any(func(e): return e.position.x>level.player.position.x))
	print("PASS initial crossing wave and reinforcements enter both sides")
	level.civilian_gate_steps.assign([4,4,4,4])
	for i in 4: level.civilians[i].position = Vector2(3910-i*32,205)
	level.set_stage(10)
	level.refresh_objects()
	level.advance_survivors(0.1)
	for i in 4: assert(level.civilians[i].position==Vector2(3910-i*32,205))
	level.player.position.x = 4500
	level.advance_survivors(0.1)
	for i in 4:
		assert(level.civilians[i].position.x>3910-i*32)
		assert(absf(level.civilians[i].position.y-205)<0.1)
	print("PASS no downward jump; civilians resume forward movement")
	level.blocked = false
	level.player.health = 100
	level.player.invulnerability = 0
	audio.heard.clear()
	level.player.take_damage(10,Vector2.ZERO)
	assert(audio.heard==["hurt"])
	level.player.invulnerability = 0
	level.player.take_damage(100,Vector2.ZERO)
	assert(level.player.health==0 and level.player.dead)
	assert(audio.heard==["hurt","death_nico"])
	level.player.take_damage(100,Vector2.ZERO)
	assert(audio.heard.size()==2)
	assert(load("res://assets/audio/death_nico.ogg") is AudioStreamOggVorbis)
	print("PASS Nico death sound only once on fatal damage; hurt remains nonfatal")
	level.queue_free()
	audio.queue_free()
	await process_frame
	await process_frame
	quit()
