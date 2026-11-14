extends SceneTree
var failures := 0
var app
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",message)
func dialogue() -> void:
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = 1000
		app.ui.advance_dialogue()
func defeat(level) -> void:
	for enemy in level.enemies.duplicate():
		if not enemy.dead: enemy.take_damage(1000,level.player.position)
func run() -> void:
	RouteSave.save_path = "res://tests/containment_test_checkpoint.json"
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false,4)
	await physics_frame
	await physics_frame
	var l: ContainmentLevel = app.level
	var p := l.player as ShotgunPlayer
	p.controls_enabled = false
	check(l.blocked and not p.has_shotgun and p.reserve==36,"level 4 intro blocks movement, starts with pistol only")
	dialogue()
	l.set_process(false)
	check(not l.blocked,"intro releases movement")
	var dogs := 0
	for number in range(1,5):
		if number==3:
			p.position = l.DOCUMENT_POINTS[0]
			l.interact()
			check(l.blocked and app.ui.dialogue_active and app.ui.dialog_name.text.begins_with("REGISTRO"),"document opens as readable text and blocks actors")
			var before := p.position
			RouteControls.virtual_move = Vector2.RIGHT
			for i in 5: await physics_frame
			check(p.position==before,"document pauses movement")
			dialogue()
			RouteControls.virtual_move = Vector2.ZERO
			check(l.document_read.has(0) and l.stage==5,"closing record grants card and starts third encounter")
		else: l.start_wave(number)
		for enemy in l.enemies:
			if not enemy.dead and enemy is InfectedDog: dogs += 1
		check(l.remaining()==[7,8,7,9][number-1],"finite encounter count "+str(number))
		defeat(l)
		check(l.stage==number*2,"encounter unlocks next objective "+str(number))
	check(dogs==3,"three individual dogs before final encounter")
	p.position = l.DOCUMENT_POINTS[1]
	l.interact()
	check(app.ui.dialog_text.text.contains("Se cancela la evacuación de los civiles."),"second document contains evacuation revelation")
	dialogue()
	var before_ammo := p.magazine+p.reserve
	p.position = l.GUN_POINT
	l.interact()
	check(p.has_shotgun and p.weapon_slot==2 and p.shells==4 and p.shell_reserve==8,"emergency exit grants shotgun and separate ammunition")
	# Picking up the shotgun now opens Nico's reaction to the Huecos.
	# Combat must remain blocked until the same dialogue the player sees is closed.
	check(l.blocked and app.ui.dialogue_active,"Huecos reaction pauses combat after pickup")
	p.switch_weapon()
	p.shells = 1
	p.begin_reload()
	check(p.weapon_slot==2 and p.action!="reload" and p.shells==1 and p.shell_reserve==8,"dialogue correctly blocks weapon switching and reload")
	p.shells = 4
	dialogue()
	check(not l.blocked and not app.ui.dialogue_active,"closing Huecos reaction resumes combat")
	var hollow_count := 0
	for enemy in l.enemies:
		if enemy.dead: continue
		enemy.set_physics_process(false)
		if enemy is HollowEnemy: hollow_count += 1
		check(enemy is HollowEnemy or enemy is InfectedDog or enemy.resistant,"final encounter replaces all basic humans")
	check(l.remaining()==8 and hollow_count==6,"final encounter: six Huecos, resistant and dog")
	# Isolate three targets in distinct pellet lanes. No fabricated damage calls.
	var targets: Array = []
	for enemy in l.enemies:
		if enemy.dead: continue
		enemy.position = Vector2(5400,210)
		if enemy is HollowEnemy and targets.size()<3: targets.append(enemy)
	p.position = Vector2(5040,280)
	p.facing = Vector2.RIGHT
	for i in 3: targets[i].position = p.position+Vector2(75,(i-1)*16)
	await physics_frame
	await physics_frame
	l.shotgun_shot(p)
	check(targets.all(func(e): return e.health<e.max_health),"one discharge damages three separate enemies")
	check(p.magazine+p.reserve==before_ammo,"shotgun does not spend pistol ammunition")
	# Wall obstruction physically blocks pellets.
	var wall := StaticBody2D.new()
	wall.collision_layer = 4
	wall.position = p.position+Vector2(35,0)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(10,100)
	shape.shape = box
	wall.add_child(shape)
	l.add_child(wall)
	await physics_frame
	await physics_frame
	var old_health: int = targets[1].health
	l.shotgun_shot(p)
	check(targets[1].health==old_health,"solid obstacle blocks shotgun pellets")
	wall.queue_free()
	p.shells = 1
	p.shell_reserve = 6
	p.begin_reload()
	check(p.action=="reload" and p.action_time>1.5,"shotgun reload has deliberate delay")
	for i in 105: await physics_frame
	check(p.shells==4 and p.shell_reserve==3,"reload transfers only shotgun shells")
	p.switch_weapon()
	for i in 25: await physics_frame
	check(p.weapon_slot==0 and not p.pistol_equipped,"Q switches shotgun to knife")
	p.switch_weapon()
	for i in 25: await physics_frame
	check(p.weapon_slot==1 and p.pistol_equipped,"Q switches knife to pistol")
	p.switch_weapon()
	for i in 25: await physics_frame
	check(p.weapon_slot==2,"Q switches pistol to shotgun")
	p.position = l.shell_pickup.position
	l.collect_shells()
	l.collect_shells()
	check(p.shell_reserve==7 and l.shells_taken,"shell box auto collects exactly once")
	defeat(l)
	check(l.stage==10 and l.kills==39,"five finite encounters total 39 kills")
	var data := l.snapshot()
	check(RouteSave.write_data(data) and not RouteSave.read_data().is_empty(),"level 4 checkpoint validates")
	app.start_route(true)
	l = app.level
	p = l.player
	check(l.stage==10 and p.has_shotgun and p.shell_reserve==7 and l.document_read.size()==2,"resume preserves weapon, shells and read evidence")
	p.position = Vector2(l.delivery_x,230)
	l.interact()
	dialogue()
	check(app.mode=="result" and l.stage==11,"exit and ending reach completion screen")
	for folder in [HollowEnemy.ART,ShotgunPlayer.ART]:
		var frames := ContainmentArt.frames(folder,folder==ShotgunPlayer.ART)
		var valid := true
		for animation in frames.get_animation_names():
			for i in frames.get_frame_count(animation):
				var atlas := frames.get_frame_texture(animation,i) as AtlasTexture
				valid = valid and atlas.get_size()==Vector2(512,512) and atlas.margin.position.x>=0 and atlas.margin.position.y>=0
		check(valid,"all atlas crops padded safely: "+folder)
	DirAccess.remove_absolute(RouteSave.save_path)
	app.queue_free()
	await process_frame
	await create_timer(0.4).timeout
	print("CONTAINMENT failures: ",failures)
	quit(failures)
