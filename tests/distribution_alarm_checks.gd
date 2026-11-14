extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",message)
func run() -> void:
	RouteControls.setup()
	var audio := RouteAudio.new()
	root.add_child(audio)
	var level := DistributionLevel.new()
	level.audio = audio
	root.add_child(level)
	level.set_process(false)
	level.player.set_physics_process(false)
	check(not is_instance_valid(level.alarm_player),"no alarm before copying records")
	level.player.position = Vector2(4490,280)
	level.set_stage(13)
	level.pending_read = "copy"
	level.document_closed()
	check(level.stage == 14 and level.alarm_player.playing,"copying records activates alarm")
	check((level.alarm_player.stream as AudioStreamOggVorbis).loop,"OGG loops")
	level.alarm_player.play(level.alarm_player.stream.get_length()-0.15)
	await create_timer(0.9).timeout
	check(level.alarm_player.playing and level.alarm_player.get_playback_position()<2.0,"alarm crosses loop boundary without stopping")
	var instance := level.alarm_player.get_instance_id()
	level.sync_alarm()
	check(instance == level.alarm_player.get_instance_id(),"one alarm player")
	paused = true
	await process_frame
	check(not level.alarm_player.can_process(),"alarm follows pause")
	paused = false
	level.set_stage(15)
	check(level.alarm_player.playing,"alarm continues after fight")
	level.player.position.x = level.ALARM_EXIT_X
	level.sync_alarm()
	check(not level.alarm_player.playing,"crossing into yard stops alarm")
	level.player.position.x = 4490
	level.set_stage(14)
	level.player.dead = true
	level.sync_alarm()
	check(not level.alarm_player.playing,"death stops alarm")
	level.player.dead = false
	level.sync_alarm()
	root.remove_child(level)
	check(not level.alarm_player.playing and level.alarm_player.stream == null,"leaving level releases alarm")
	level.free()
	audio.queue_free()
	await process_frame
	print("ALARM_FAILURES=",failures)
	quit(failures)

