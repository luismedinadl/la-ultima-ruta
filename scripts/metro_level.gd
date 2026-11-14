class_name MetroLevel
extends RouteLevel
## Four finite encounters plus two distracted groups. Even stages are checkpoints.
const PANEL_SECONDS := 30.0
var panel_position := Vector2(4160,230)
var terminal: Sprite2D
var battery_installed := false
var battery_carried := false
var panel_progress := 0.0
var panel_interrupted := false
var defense_elapsed := 0.0
var defense_batch := 0
var intro_spawned := false
var noise_lesson := false
var station_walls: Node2D
var panel_bar: ProgressBar

func configure_route() -> void:
	level_number = 3
	wave_count = 4
	pickup_x = 2160
	package_point = Vector2(2160,231)
	crossing_x = 3160
	delivery_x = 4660
	world_length = 4940
	district_two = 2160
	district_three = 3500
	route_points = [1160.0,2160.0,3160.0,4160.0]

func _ready() -> void:
	configure_route()
	super._ready()
	call_deferred("prepare_entrance")

func build_street() -> void:
	var floor_layer := Node2D.new()
	floor_layer.z_index = -10
	add_child(floor_layer)
	for x in range(0,int(world_length)+128,128):
		for y in [196,324]:
			var tile := add_sprite(floor_layer,RouteArt.texture("metro/floor.png"),Vector2(x+64,y),Vector2(128,128))
			tile.modulate = Color(0.72,0.78,0.80)
	station_walls = Node2D.new()
	station_walls.z_index = -5
	add_child(station_walls)
	for x in range(0,int(world_length)+176,176):
		var index := [0,1,2,4][int(x/176.0)%4] as int
		if x > 1800 and x < 2500: index = 2 if x%352 == 0 else 6
		if x > 2600 and x < 3600: index = 8 if x%352 == 0 else 9
		if x > 3800: index = 7
		add_sprite(station_walls,MetroArt.item("modules",index),Vector2(x+88,196),Vector2(178,196),true)
	# Portal artwork is separate, so opening the exit never stretches the walls.
	add_sprite(station_walls,MetroArt.item("modules",5),Vector2(160,196),Vector2(132,196),true)
	for x in range(2690,3590,128):
		var edge := RouteArt.region("metro/modules.png",Rect2(598,770,162,33))
		add_sprite(floor_layer,edge,Vector2(x,316),Vector2(128,10))

	RouteStory.sign(station_walls,"03_metro_campamento.png",Vector2(160,95),176)

func metro_prop(index: int, pos: Vector2, size_: Vector2, solid: bool = false) -> Sprite2D:
	var sprite := add_sprite(actors,MetroArt.item("props",index),pos,size_,true)
	MetroArt.cutout(sprite)
	if solid:
		var body := StaticBody2D.new()
		body.collision_layer = 4
		body.collision_mask = 0
		body.position = pos-Vector2(0,8)
		var col := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(size_.x*0.85,22)
		col.shape = rect
		body.add_child(col)
		add_child(body)
	return sprite

func build_props() -> void:
	for x in [420,1520,2530,3450,3900]:
		metro_prop(6,Vector2(x,223),Vector2(74,48),true)
	for x in [680,1210,2860]:
		metro_prop(5,Vector2(x,274),Vector2(42,44),true)
	for x in [1850,2350,3650]:
		metro_prop(7,Vector2(x,216),Vector2(38,62),true)
	package = metro_prop(0,package_point,Vector2(28,36))
	terminal = metro_prop(1,panel_position,Vector2(40,60))
	gate = add_sprite(self,MetroArt.item("modules",10),Vector2(delivery_x,196),Vector2(130,178),true)
	gate.z_index = -3
	prop(7,Vector2(delivery_x+105,217),Vector2(36,34))
	prop(0,Vector2(delivery_x+87,214),Vector2(23,24))
	for x in [1390,2410,3370,4020,4390]:
		medkits[str(x)] = prop(2,Vector2(x,290),Vector2(23,23))
	for i in 6:
		var x: float = [1310,1900,2460,3070,3720,4090][i]
		var box := add_sprite(actors,RouteArt.weapon_item(0),Vector2(x,295),Vector2(25,20),true)
		ammo_pickups[str(i)] = {"sprite":box,"amount":12}
	panel_bar = ProgressBar.new()
	panel_bar.position = panel_position+Vector2(-42,-83)
	panel_bar.size = Vector2(84,8)
	panel_bar.show_percentage = false
	panel_bar.add_theme_font_size_override("font_size",1)
	panel_bar.max_value = PANEL_SECONDS
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("c38c45")
	var background := StyleBoxFlat.new()
	background.bg_color = Color("18212b")
	panel_bar.add_theme_stylebox_override("fill",fill)
	panel_bar.add_theme_stylebox_override("background",background)
	panel_bar.visible = false
	add_child(panel_bar)
	panel_bar.size = Vector2(84,8)

func build_weather() -> void:
	# Interior: no screen-wide rain; humidity comes from the painted floor.
	rain = Node2D.new()
	add_child(rain)

func prepare_entrance() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if intro_spawned: return
	intro_spawned = true
	spawn_enemy(Vector2(920,233),false,false)
	spawn_enemy(Vector2(980,294),false,false)

func spawn_enemy(pos: Vector2, tough: bool, alerted: bool, panel: bool = false, dog: bool = false) -> MetroEnemy:
	var enemy: MetroEnemy = InfectedDog.new() if dog else MetroEnemy.new()
	enemy.level = self
	enemy.resistant = tough
	enemy.difficulty = 1.18
	enemy.awareness = 2 if alerted else 0
	enemy.show_awareness_icon = not alerted
	enemy.panel_attacker = panel
	enemy.position = safe_spawn(pos)
	actors.add_child(enemy)
	enemy.killed.connect(enemy_killed)
	enemies.append(enemy)
	return enemy

func _process(delta: float) -> void:
	ambient_time += delta
	freeze_time = maxf(0,freeze_time-delta)
	if not blocked and not player.dead:
		elapsed += delta
		collect_ammo()
		collect_medkits()
		if not noise_lesson and player.position.x > 600:
			noise_lesson = true
			announcement.emit("Si te ven, te persiguen. Disparar atrae a los cercanos.")
		if stage == 0 and player.position.x >= 1000: start_wave(1)
		elif stage == 4 and player.position.x >= 2990: start_wave(3)
		if stage == 7: update_defense(delta)
	update_camera(65.0)
	shake = move_toward(shake,0,delta*18)
	camera.offset = Vector2(sin(ambient_time*91),cos(ambient_time*83))*shake
	marker.texture = RouteArt.fx(7,int(ambient_time*7)%6)
	marker.visible = stage%2 == 0 and stage < 9
	marker.position = Vector2(destination(),156+sin(ambient_time*3)*2)
	if stage == 2: marker.position.y = package_point.y-44
	panel_bar.visible = stage == 7
	panel_bar.value = panel_progress
	if stage == 7: goal = "Defiende el control · %d%% · %s" % [int(panel_progress/PANEL_SECONDS*100),"INTERRUMPIDO" if panel_interrupted else "reiniciando"]

func clamp_actor(pos: Vector2) -> Vector2:
	var min_x := 26.0
	var max_x := world_length-30
	if stage%2 == 1 and stage < 8:
		min_x = arena_center-300
		max_x = arena_center+300
	return Vector2(clampf(pos.x,min_x,max_x),clampf(pos.y,204,306))

func clear_sight(from: Vector2, to: Vector2) -> bool:
	return get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from,to,4)).is_empty()

func make_noise(pos: Vector2, radius: float, loud: bool) -> void:
	for enemy in enemies:
		if enemy.dead or enemy.position.distance_to(pos) > radius: continue
		# Thick intervening obstacles dampen sound but never make a nearby gun silent.
		if not clear_sight(pos,enemy.position) and enemy.position.distance_to(pos) > radius*0.55: continue
		(enemy as MetroEnemy).hear_noise(pos,loud)

func pistol_shot(actor: RoutePlayer) -> void:
	make_noise(actor.position,360,true)
	super.pistol_shot(actor)

func player_strike(actor: RoutePlayer) -> void:
	make_noise(actor.position,80,false)
	super.player_strike(actor)

func start_wave(number: int) -> void:
	wave_index = number
	stage = number*2-1
	arena_center = route_points[number-1]
	goal = objective_text()
	build_navigation()
	announcement.emit("ENCUENTRO %d / 4" % number)
	audio.cue("wave",-16)
	audio.cue("zombie",-16)
	if number == 4:
		defense_elapsed = 0
		defense_batch = 0
		panel_progress = 0
		spawn_defense_batch()
		return
	var count: int = [5,6,7][number-1]
	var tough: int = [1,2,2][number-1]
	for i in count:
		var offset := Vector2(-220 if i%2 == 0 else 220,220+(i%3)*35)
		spawn_enemy(Vector2(arena_center,0)+offset,i<tough,true)
	if number in [2,3]:
		spawn_enemy(Vector2(arena_center+245,290),false,true,false,true)
		audio.cue("dog_growl",-12)
		announcement.emit("PERRO INFECTADO · esquiva su mordida")
	# Distracted groups are finite and can be dealt with before the main encounter.
	for enemy in enemies:
		if not enemy.dead: (enemy as MetroEnemy).hear_noise(player.position,true)

func spawn_defense_batch() -> void:
	var count: int = [2,3,3][defense_batch]
	for i in count:
		spawn_enemy(panel_position+Vector2(-230 if (i+defense_batch)%2 == 0 else 230,(-10+i*30)),i==0,true,true)
	if defense_batch == 2:
		spawn_enemy(panel_position+Vector2(-245,65),false,true,false,true)
		audio.cue("dog_growl",-12)
	defense_batch += 1
	announcement.emit("CONTROL · refuerzos %d / 3" % defense_batch)

func update_defense(delta: float) -> void:
	defense_elapsed += delta
	if defense_batch < 3 and defense_elapsed >= defense_batch*10.0: spawn_defense_batch()
	panel_interrupted = false
	for enemy in enemies:
		if not enemy.dead and enemy.position.distance_to(panel_position) < 46:
			panel_interrupted = true
			break
	if not panel_interrupted: panel_progress = minf(PANEL_SECONDS,panel_progress+delta)
	terminal.texture = MetroArt.item("props",4 if panel_interrupted else 2)
	if panel_progress >= PANEL_SECONDS and defense_batch == 3 and remaining() == 0:
		stage = 8
		terminal.texture = MetroArt.item("props",3)
		open_exit()
		goal = objective_text()
		announcement.emit("SALIDA ABIERTA")
		checkpoint.emit(snapshot())

func enemy_killed(_enemy: RouteEnemy) -> void:
	kills += 1
	if stage in [1,3,5] and remaining() == 0:
		stage += 1
		if stage == 4:
			spawn_enemy(Vector2(2920,224),false,false)
			spawn_enemy(Vector2(2960,294),false,false)
		goal = objective_text()
		announcement.emit("PASO DESPEJADO · " + goal)
		checkpoint.emit(snapshot())

func destination() -> float:
	if stage <= 1: return 1160
	if stage <= 3: return pickup_x
	if stage <= 5: return 3160
	if stage <= 7: return panel_position.x
	return delivery_x

func objective_text() -> String:
	return ["Entra en la estación","Despeja el vestíbulo","Recoge la batería de mantenimiento","Sobrevive en mantenimiento","Avanza por el andén","Despeja el paso al control","Instala la batería en el control","Defiende el control","Cruza la salida abierta","Estación completada"][clampi(stage,0,9)]

func interaction_hint() -> String:
	if stage == 2 and player.position.distance_to(package_point) < 48: return "E / Enter · recoger batería"
	if stage == 6 and player.position.distance_to(panel_position) < 48: return "E / Enter · instalar batería"
	if stage == 8 and absf(player.position.x-delivery_x) < 55: return "E / Enter · cruzar salida"
	if stage == 7: return "Aleja a los infectados del panel para reanudar el arranque"
	if stage%2 == 1: return "Espacio / clic · disparar   R · recargar   Q · cuchillo"
	return "Objetivo · %d m →" % int(absf(destination()-player.position.x)/METRE)

func interact() -> void:
	if blocked or player.dead or player.action_time > 0: return
	if stage == 2 and player.position.distance_to(package_point) < 48: player.interact_animation("pickup_package")
	elif stage == 6 and battery_carried and player.position.distance_to(panel_position) < 48: player.interact_animation("delivery")
	elif stage == 8 and absf(player.position.x-delivery_x) < 55:
		stage = 9
		blocked = true
		delivered.emit()

func finish_interaction(action: String) -> void:
	if action == "pickup_package" and stage == 2:
		battery_carried = true
		package.hide()
		station_walls.modulate = Color(0.80,0.84,0.85)
		start_wave(2)
	elif action == "delivery" and stage == 6:
		battery_installed = true
		battery_carried = false
		start_wave(4)

func snapshot() -> Dictionary:
	var data := super.snapshot()
	data["battery_carried"] = battery_carried
	data["battery_installed"] = battery_installed
	data["noise_lesson"] = noise_lesson
	var survivors: Array = []
	for enemy in enemies:
		if enemy.dead: continue
		survivors.append({"x":enemy.position.x,"y":enemy.position.y,"health":enemy.health,"resistant":enemy.resistant,"awareness":(enemy as MetroEnemy).awareness,"kind":"dog" if enemy is InfectedDog else "zombie","show_awareness_icon":(enemy as MetroEnemy).show_awareness_icon})
	data["metro_enemies"] = survivors
	return data

func restore(data: Dictionary) -> void:
	stage = int(data.stage)
	intro_spawned = true
	for enemy in enemies:
		enemy.get_parent().remove_child(enemy)
		enemy.queue_free()
	enemies.clear()
	player.position = Vector2(clampf(float(data.x),26,world_length-30),265)
	player.health = clampi(int(data.health),1,100)
	player.magazine = clampi(int(data.get("magazine",12)),0,12)
	player.reserve = clampi(int(data.get("reserve",36)),0,RoutePlayer.MAX_RESERVE)
	player.pistol_equipped = bool(data.get("pistol_equipped",true))
	player.animate("idle")
	kills = int(data.kills)
	damage_received = int(data.damage)
	elapsed = float(data.elapsed)
	collected = data.get("collected",[]).duplicate()
	ammo_taken = data.get("ammo_taken",[]).duplicate()
	for key in medkits: medkits[key].visible = not collected.has(key)
	for key in ammo_pickups: ammo_pickups[key].sprite.visible = not ammo_taken.has(key)
	battery_carried = bool(data.get("battery_carried",stage in [4,6]))
	battery_installed = bool(data.get("battery_installed",stage==8))
	noise_lesson = bool(data.get("noise_lesson",false))
	package.visible = stage <= 2
	if stage >= 4: station_walls.modulate = Color(0.80,0.84,0.85)
	terminal.texture = MetroArt.item("props",3 if stage == 8 else 1)
	gate.texture = MetroArt.item("modules",11 if stage == 8 else 10)
	for saved in data.get("metro_enemies",[]):
		var enemy := spawn_enemy(Vector2(saved.x,saved.y),bool(saved.resistant),int(saved.awareness)==2,false,saved.get("kind","zombie")=="dog")
		enemy.show_awareness_icon = bool(saved.get("show_awareness_icon",true))
		enemy.health = clampi(int(saved.health),1,enemy.max_health)
		enemy.health_bar.value = enemy.health
	goal = objective_text()
	blocked = false
	camera.reset_smoothing()

func open_exit() -> void:
	# The approved open portal sits behind a retracting strip of actual shutter art.
	gate.texture = MetroArt.item("modules",11)
	var shutter_texture := RouteArt.region("metro/modules.png",Rect2(946,445,218,167))
	var shutter := Sprite2D.new()
	shutter.texture = shutter_texture
	shutter.centered = false
	shutter.position = Vector2(delivery_x-52,50)
	shutter.scale = Vector2(104.0/218.0,128.0/167.0)
	shutter.z_index = -2
	add_child(shutter)
	var tween := create_tween()
	tween.tween_method(func(height: float): shutter_texture.region.size.y = height,167.0,1.0,0.8)
	tween.tween_callback(shutter.queue_free)
