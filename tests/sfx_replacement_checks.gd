extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var audio := RouteAudio.new()
	root.add_child(audio)
	for key in RouteAudio.CUE_FILES:
		audio.cue(key)
		var player := audio.get_child(audio.get_child_count()-1) as AudioStreamPlayer
		assert(player.stream is AudioStreamOggVorbis)
		assert(player.stream.resource_path.ends_with(RouteAudio.CUE_FILES[key]))
		assert(player.stream.get_length()>0 and not player.stream.loop)
		print("PASS ",key," -> ",RouteAudio.CUE_FILES[key])
	audio.cue("reload")
	assert(audio.get_child(audio.get_child_count()-1).stream.resource_path.ends_with("reload.wav"))
	var enemy := RouteEnemy.new()
	assert(enemy.death_sound()=="death")
	enemy.resistant = true
	assert(enemy.death_sound()=="resistant_death")
	enemy.free()
	print("PASS distinct resistant death and unchanged pistol reload")
	audio.queue_free()
	await process_frame
	await process_frame
	quit()
