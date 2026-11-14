extends SceneTree
var app
func _initialize() -> void: call_deferred("run")
func run() -> void:
	RouteSave.save_path = "res://tests/survival_isolation.json"
	RouteSave.write_data({"stage":0,"level":1,"x":160,"health":90,"kills":2,"damage":10,"elapsed":20})
	var before := FileAccess.get_file_as_string(RouteSave.save_path)
	for i in range(1,9): RouteSave.mark_level_completed(i)
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	var unlocked_path := RouteSave.save_path
	RouteSave.save_path = "res://tests/survival_locked_%d.json" % Time.get_ticks_usec()
	app.show_menu()
	app.handle_command("survival")
	assert(app.mode=="menu" and not is_instance_valid(app.level))
	assert(app.ui.screen.find_children("*","Button",true,false).any(func(b): return b.text=="Supervivencia" and b.disabled))
	RouteSave.save_path = unlocked_path
	app.show_menu()
	assert(app.ui.screen.find_children("*","Button",true,false).any(func(b): return b.text=="Supervivencia" and not b.disabled))
	print("PASS survival locked before completion and enabled afterwards")
	app.handle_command("survival")
	var level = app.level
	assert(level is SurvivalLevel and not app.ui.dialogue_active)
	assert(level.player.has_pistol and level.player.has_shotgun)
	assert(level.wave_index==1 and level.pending_enemies==2 and level.drops.size()==2)
	level.set_process(false)
	level.player.set_physics_process(false)
	level.rng.seed = 128
	var types := {}
	for wave in range(1,42):
		assert(level.wave_index==wave and level.scenery==SurvivalLevel.scenario_for(wave))
		assert(level.drops.size()>=2)
		assert(level.drops.all(func(d): return d.kind in ["pistol", "shells"]))
		var expected_sets := maxi(2 if wave%10==0 else 1,1+int((wave-1)/5.0))
		assert(level.drops.filter(func(d): return d.kind=="pistol").size()==expected_sets)
		assert(level.drops.filter(func(d): return d.kind=="shells").size()==expected_sets)
		for drop in level.drops: assert(level.clamp_actor(drop.sprite.position)==drop.sprite.position)
		if wave in [1,6,11,16,21,26,31,36]:
			app.ui.zone_text.text = ""
			await process_frame
			await process_frame
			if DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://docs/screenshots/survival_%02d.png" % wave)
		level._process(6.1)
		var spawned := 0
		while level.phase=="combat":
			level._process(0.7)
			for enemy in level.enemies:
				if enemy.dead: continue
				enemy.set_physics_process(false)
				if wave%10==0: assert(enemy is AnchoredEnemy and level.enemies.size()==1)
				else: assert(not enemy is AnchoredEnemy)
				types["boss" if enemy is AnchoredEnemy else "dog" if enemy is InfectedDog else "hollow" if enemy is HollowEnemy else "tough" if enemy.resistant else "basic"] = true
				enemy.take_damage(100000,level.player.position)
				spawned += 1
		assert(spawned==SurvivalLevel.count_for(wave))
		assert(level.completed_waves==wave)
		if level.phase=="transition":
			assert(level.blocked)
			level._process(0.7)
			level._process(0.8)
		await process_frame
	print("PASS waves 1-41: exact counts, isolated bosses, 8 scenarios and wraparound; types=",types.keys())
	assert(types.size()==5)
	level.player.reserve = 0
	level.player.shell_reserve = 0
	level.player.health = 20
	for drop in level.drops.duplicate():
		level.player.position = drop.sprite.position
		level.collect_drops()
	assert(level.player.reserve>0 and level.player.shell_reserve>0 and level.player.health==20)
	assert(before==FileAccess.get_file_as_string(RouteSave.save_path))
	print("PASS supplies auto-collect and campaign checkpoint unchanged")
	app.touch.set_enabled(true)
	app.touch.refresh()
	assert(app.touch.buttons.attack.visible and app.touch.buttons.switch.visible)
	assert(not app.touch.buttons.documents.visible and not app.touch.buttons.interact.visible)
	app.touch.set_enabled(false)
	print("PASS mobile combat controls without document or interaction buttons")
	app.pause_route()
	assert(paused)
	app.resume_route()
	assert(not paused)
	level.player.invulnerability = 0
	level.player.take_damage(1000,Vector2.ZERO)
	level.player.died.emit()
	assert(app.mode=="result")
	app.handle_command("retry")
	assert(app.level is SurvivalLevel and app.level.wave_index==1 and app.level.completed_waves==0)
	assert(before==FileAccess.get_file_as_string(RouteSave.save_path))
	print("PASS pause, death results and retry reset the survival run only")
	app.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	quit()
