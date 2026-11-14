extends SceneTree
class SpyAudio extends RouteAudio:
	var heard: Array[String] = []
	func cue(name_: String, _volume: float = -9, _pitch: float = 1) -> void:
		heard.append(name_)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	RouteControls.setup()
	var audio := SpyAudio.new()
	root.add_child(audio)
	for kind in [1,3,4]:
		var level: RouteLevel = RouteLevel.new() if kind==1 else MetroLevel.new() if kind==3 else ContainmentLevel.new()
		level.audio = audio
		root.add_child(level)
		level.set_process(false)
		level.player.set_physics_process(false)
		audio.heard.clear()
		level.start_wave(2 if kind==1 else 1)
		assert(audio.heard.has("zombie"))
		if kind==4:
			audio.heard.clear()
			level.hollow_unlocked = true
			level.start_wave(5)
			assert(not audio.heard.has("zombie") and audio.heard.has("hollow"))
		print("PASS horde audio level ",kind)
		level.queue_free()
		await process_frame
	audio.queue_free()
	await process_frame
	quit()
