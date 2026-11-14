extends SceneTree
var app
var level: HarborLevel
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label_: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label_)
func close_dialogue() -> void:
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = -1
		app.ui.advance_dialogue()
func capture(name_: String) -> void:
	level.camera.position = Vector2(clampf(level.player.position.x+65,288,level.world_length-288),162)
	app.ui.zone_text.text = ""
	await process_frame
	await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/finale_polish_"+name_+".png")
func run() -> void:
	RouteSave.save_path = "res://tests/harbor_finale_polish_checkpoint.json"
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.start_route(false,8)
	close_dialogue()
	level = app.level
	level.set_process(false)
	level.player.set_physics_process(false)
	level.set_stage(7)
	level.refresh_objects()
	level.gate_open = true
	level.set_stage(8)
	level.refresh_objects()
	level.player.position = Vector2(2870,280)
	var crossed: Array[bool] = [false,false,false,false]
	for step in 180:
		var prior: Array = level.civilians.map(func(c): return c.position)
		level.advance_survivors(0.05)
		for i in 4:
			if prior[i].x<2830 and level.civilians[i].position.x>=2830:
				crossed[i] = absf(level.civilians[i].position.y-222)<1
		if step==40: await capture("gate_crossing")
	check(crossed.all(func(v): return v),"all four survivors cross between gate posts at y=222")
	check(level.civilian_gate_steps.all(func(v): return v==4),"all four finish the gate waypoints")
	level.set_stage(11)
	level.refresh_objects()
	level.chief_saved = true
	level.set_stage(12)
	level.player.position = Vector2(4510,280)
	level.start_boss()
	level.anchored.set_physics_process(false)
	check(level.anchored.max_health==2400,"Anclado has fifty percent more health")
	level.advance_guard_last_stand(0.75)
	check(level.chief_guards.all(func(g): return g.animation=="shoot") and level.anchored.health<2400,"both guards shoot and hit the Anclado")
	await capture("guards_firing")
	var intro_time := level.guard_intro_time
	level.blocked = true
	level._process(2)
	check(level.guard_intro_time==intro_time,"dialogue pauses guard last stand")
	level.blocked = false
	level._process(0)
	level.advance_guard_last_stand(0.65)
	check(level.guards_down.all(func(v): return v) and level.chief_guards.all(func(g): return g.animation=="death"),"both guards are struck down immediately")
	await create_timer(0.7).timeout
	level.advance_guard_last_stand(0.7)
	check(level.guard_intro_time<0 and level.chief_guards.all(func(g): return not g.is_playing()),"death ends with persistent corpses")
	await capture("guards_fallen")
	for fraction in [0.65,0.3,0.1]:
		level.anchored.health = int(level.anchored.max_health*fraction)
		level.advance_boss()
		check(level.enemies.size()==1 and level.arrivals.is_empty(),"no Huecos at health fraction "+str(fraction))
	level.anchored.phase_two = false
	level.anchored.enter("approach",0,"walk")
	level.anchored._physics_process(0.01)
	check(is_equal_approx(level.anchored.velocity.length(),55),"boss approach is faster")
	level.anchored.phase_two = true
	level.anchored.enter("approach",0,"walk")
	level.anchored._physics_process(0.01)
	check(is_equal_approx(level.anchored.velocity.length(),68),"second phase is faster")
	level.anchored.take_damage(100000,level.player.position)
	level.advance_boss()
	var saved := level.snapshot()
	level.restore(saved)
	check(level.chief_guards.all(func(g): return g.animation=="death" and not g.is_playing()),"checkpoint restores dead guards instead of escaping guards")
	level.player.position = Vector2(level.world_length-30,280)
	level._process(0.01)
	var farthest := 0.0
	for bg in level.station_walls.get_children():
		farthest = maxf(farthest,bg.position.x+bg.texture.get_width()*bg.scale.x/2)
	check(farthest>=level.world_length,"painted background covers the complete right camera edge")
	await capture("right_edge")
	app.ui.result_screen(true,level.kills,level.damage_received,level.elapsed,8)
	await capture("results")
	print("FINALE POLISH FAILURES: ",failures)
	app.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
