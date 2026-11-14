extends SceneTree
var failures := 0
var ended := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",message)
func run() -> void:
	RouteSave.save_path = "res://tests/metro_audio_test.json"
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	check(app.audio.music.stream.resource_path.ends_with("lost.ogg") and app.audio.music.playing, "lost plays on initial menu")
	check(app.audio.music.stream.loop, "menu track loops")
	check(app.audio.ambience.stream_paused, "initial menu has no rain sound")
	check(app.audio.ambience.stream.resource_path.ends_with("rain.ogg") and app.audio.ambience.stream.loop,"new rain OGG loaded with looping enabled")
	app.audio.set_route_ambience(0)
	check(app.audio.music.stream.resource_path.ends_with("drone.wav"), "introduction keeps its existing background")
	for number in range(1,9):
		app.audio.set_route_ambience(number)
		check(app.audio.music.stream.resource_path.ends_with("leberchsuspense_loop.ogg") and app.audio.music.playing and not app.audio.music.stream_paused,"suspense plays in level %d" % number)
		check(app.audio.ambience.stream_paused == (number == 3),"rain absent only underground")
		app.audio.ambience.volume_db = -65
		check(app.audio.music.volume_db == -15 and app.audio.music.playing,"indoor rain fade does not mute music")
	app.start_route(false,3)
	app.audio.ambience.stream_paused = false
	app.audio.ambience.play(app.audio.ambience.stream.get_length()-0.15)
	await create_timer(0.4).timeout
	check(app.audio.ambience.playing and app.audio.ambience.get_playback_position()<1.0,"rain crosses loop boundary without stopping")
	app.audio.ambience.stream_paused = true
	await process_frame
	var stream: AudioStreamOggVorbis = app.audio.music.stream
	check(stream != null and stream.loop and stream.loop_offset == 0,"native OGG looping enabled")
	app.audio.music.finished.connect(func(): ended = true)
	app.audio.music.play(stream.get_length()-0.3)
	await create_timer(0.9).timeout
	check(not ended and app.audio.music.playing and app.audio.music.get_playback_position()<2.0,"loop boundary crossed without stopping")
	app.show_menu()
	check(app.audio.music.stream.resource_path.ends_with("lost.ogg") and app.audio.ambience.stream_paused,"menu restores lost without rain")
	app.queue_free()
	await process_frame
	for suffix in ["", ".tmp", ".progress", ".progress.tmp"]:
		if FileAccess.file_exists(RouteSave.save_path+suffix): DirAccess.remove_absolute(RouteSave.save_path+suffix)
	print("ALL LEVEL AUDIO FAILURES: ",failures)
	quit(failures)
