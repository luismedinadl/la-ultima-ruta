extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	RouteSave.save_path = "res://tests/containment_preview_checkpoint.json"
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false,4)
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = 1000
		app.ui.advance_dialogue()
	var l: ContainmentLevel = app.level
	l.player.controls_enabled = false
	l.player.position = Vector2(1100,275)
	l.stage = 2
	l.goal = l.objective_text()
	app.ui.zone_timeout = 0
	app.ui.zone_text.hide()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/19_containment.png")
	l.stage = 4
	l.player.position = l.DOCUMENT_POINTS[0]
	l.interact()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/20_readable_document.png")
	app.ui.dialog.hide()
	app.ui.dialogue_active = false
	app.reading_document = false
	l.stage = 8
	l.blocked = false
	l.player.position = Vector2(5160,280)
	(l.player as ShotgunPlayer).acquire_shotgun()
	l.shotgun_pickup.hide()
	l.hollow_unlocked = true
	l.player.direction = 6
	l.player.animate("idle")
	var enemy := l.spawn_enemy(Vector2(5290,275),false,true)
	enemy.direction = 2
	enemy.animate("idle")
	enemy.set_physics_process(false)
	l.stage = 9
	l.goal = "Escopeta recuperada · salida de emergencia"
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/21_shotgun_hollow.png")
	l.open_exit()
	l.enemies.erase(enemy)
	enemy.queue_free()
	l.player.position = Vector2(5290,275)
	l.goal = "Salida abierta · pruebas recuperadas"
	l.stage = 11
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/23_emergency_exit.png")
	app.queue_free()
	await process_frame
	root.content_scale_size = Vector2i(880,720)
	root.size = Vector2i(880,720)
	for direction in 8:
		for index in 8:
			var folder := HollowEnemy.ART if index<4 else ShotgunPlayer.ART
			var action_: String = ["walk","attack","hurt","death","walk","shoot","reload","death"][index]
			var sprite := Sprite2D.new()
			sprite.texture = ContainmentArt.frames(folder,index>=4).get_frame_texture(action_+"_"+str(direction),2 if action_=="death" else 1)
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.flip_h = direction>4
			sprite.scale = Vector2.ONE*ContainmentArt.size_scale(folder)
			sprite.position = Vector2(55+index*110,48+direction*86-(144*ContainmentArt.size_scale(folder) if action_=="death" else 0))
			ContainmentArt.cutout(sprite)
			root.add_child(sprite)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/22_containment_states.png")
	DirAccess.remove_absolute(RouteSave.save_path)
	print("CONTAINMENT_RENDER_OK")
	quit()
