class_name RouteLevel
extends Node2D
## Level 1 state machine: pickup -> wave 1 -> crossing -> wave 2 ->
## delivery district -> wave 3 -> unlocked delivery. No infinite spawners.
signal objective_changed(text: String)
signal announcement(text: String)
signal player_died
signal delivered
signal checkpoint(data: Dictionary)
const METRE := 20.0
const OBJECTIVE_GAP := 50.0 * METRE
const START_X := 160.0
const LOCAL := START_X + OBJECTIVE_GAP
const CROSSING := LOCAL + OBJECTIVE_GAP
const DELIVERY := CROSSING + OBJECTIVE_GAP
const LENGTH := DELIVERY + 360.0
const DISTRICT_TWO := (LOCAL + CROSSING) / 2.0
const DISTRICT_THREE := (CROSSING + DELIVERY) / 2.0
@export var level_number := 1
var world_length := LENGTH
var pickup_x := LOCAL
var crossing_x := CROSSING
var delivery_x := DELIVERY
var district_two := DISTRICT_TWO
var district_three := DISTRICT_THREE
var route_points: Array[float] = [LOCAL, CROSSING, DELIVERY]
var wave_count := 3
var package_point := Vector2(LOCAL, 207)
var pickup_slot := 0
var ammo_pickups: Dictionary = {}
var ammo_taken: Array = []
var navigation: AStarGrid2D
var navigation_origin := Vector2.ZERO

var audio: RouteAudio
var player: RoutePlayer
var actors: Node2D
var camera: Camera2D
var enemies: Array[RouteEnemy] = []
var blocked := true
var freeze_time := 0.0
var shake := 0.0
var elapsed := 0.0
var kills := 0
var damage_received := 0
var stage := 0
var goal := "Dirígete al Local 24"
var marker: Sprite2D
var package: Sprite2D
var gate: Sprite2D
var medkits: Dictionary = {}
var collected: Array = []
var rain: Node2D
var rng := RandomNumberGenerator.new()
var arena_center := pickup_x
var ambient_time := 0.0
var lamps: Array[Sprite2D] = []
var last_district := -1
var wave_index := 0
var wave_locks: Array[Sprite2D] = []

func _ready() -> void:
	rng.seed = 24012026
	if level_number == 2:
		wave_count = 5
		pickup_slot = randi_range(0, 2)
		package_point = [Vector2(1090, 240), Vector2(1160, 284), Vector2(1230, 225)][pickup_slot]
		pickup_x = package_point.x
		crossing_x = 3160
		delivery_x = 5160
		world_length = delivery_x + 360
		district_two = 2160
		district_three = 4160
		route_points = [pickup_x, 2160.0, 3160.0, 4160.0, delivery_x]
	goal = objective_text()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	build_street()
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	build_props()
	player = create_player()
	player.level = self
	player.has_pistol = level_number >= 2
	player.pistol_equipped = player.has_pistol
	player.position = Vector2(START_X, 251)
	actors.add_child(player)
	player.damaged.connect(func(amount: int): damage_received += amount)
	player.died.connect(func(): player_died.emit())
	player.interaction_finished.connect(finish_interaction)
	camera = Camera2D.new()
	camera.position = Vector2(288, 162)
	# Direct follow keeps Nico at the same screen position on start/stop.
	camera.position_smoothing_enabled = false
	camera.position_smoothing_speed = 5
	add_child(camera)
	camera.make_current()
	update_camera(65.0)
	marker = Sprite2D.new()
	marker.texture = RouteArt.fx(7, 0)
	marker.scale = Vector2.ONE * 0.18
	marker.position = Vector2(pickup_x, 153)
	marker.z_index = 5
	add_child(marker)
	build_weather()
	if level_number >= 2: call_deferred("settle_supplies")

func add_sprite(parent: Node, tex: Texture2D, pos: Vector2, size_: Vector2, bottom: bool = false) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.position = pos
	sprite.scale = size_ / tex.get_size()
	if bottom: sprite.offset.y = -tex.get_height() / 2.0
	parent.add_child(sprite)
	return sprite

func build_street() -> void:
	var ground := Node2D.new()
	ground.z_index = -10
	add_child(ground)
	var tiles: Array[Texture2D] = []
	for row in range(8):
		for col in range(8):
			tiles.append(RouteArt.cell("tiles/tiles.png", 8, 8, col, row, 3))
	for x in range(0, int(world_length) + 32, 32):
		for y in range(0, 352, 32):
			var index := 1
			if y < 160: index = 16 + rng.randi_range(0, 7)
			elif y == 160 or y == 320: index = 8 + (0 if y == 160 else 4)
			elif y == 192: index = 48 + rng.randi_range(0, 7)
			if absf(x - crossing_x) < 70 and y >= 192: index = 25
			var surface: Texture2D = tiles[index]
			if index == 1:
				# A continuous low-contrast asphalt patch replaces tiled neon reflections.
				surface = RouteArt.cell("tiles/asphalt_quiet_v01.png", 4, 4, int(x / 32.0) % 4, int(y / 32.0) % 4)
			var tile := add_sprite(ground, surface, Vector2(x + 16, y + 16), Vector2(32, 32))
			tile.modulate = Color(0.68, 0.74, 0.87) if x < district_two else Color(0.82, 0.75, 0.78) if x < district_three else Color(0.75, 0.63, 0.78)
	# Sidewalk atlas cells contain an 8 px strip of the old reflective road.
	# Cover only that street portion, matching the asphalt's world-aligned UVs.
	for x in range(0, int(world_length) + 32, 32):
		if absf(x - crossing_x) < 70: continue
		var asphalt := RouteArt.cell("tiles/asphalt_quiet_v01.png", 4, 4, int(x / 32.0) % 4, 2)
		var patch_region := asphalt.region
		patch_region.position.y += patch_region.size.y * 0.75
		patch_region.size.y *= 0.25
		var patch := add_sprite(ground, RouteArt.region("tiles/asphalt_quiet_v01.png", patch_region), Vector2(x + 16, 220), Vector2(32, 8))
		patch.modulate = Color(0.68, 0.74, 0.87) if x < district_two else Color(0.82, 0.75, 0.78) if x < district_three else Color(0.75, 0.63, 0.78)
	var buildings := Node2D.new()
	buildings.z_index = -5
	add_child(buildings)
	for x in range(80, int(world_length), 184):
		if absf(x - pickup_x) < 200 or absf(x - delivery_x) < 200 or absf(x - crossing_x) < 160: continue
		var index := [2, 5, 2, 4, 5][floori(x / 184.0) % 5] as int
		var facade := add_sprite(buildings, RouteArt.freight_facade(floori(x / 184.0) % 5) if level_number == 2 else RouteArt.cell("tiles/architecture.png", 3, 2, index % 3, floori(index / 3.0), 4), Vector2(x, 180), Vector2(186, 176), true)
		facade.modulate = Color(0.7, 0.75, 0.88)
	add_sprite(buildings, RouteArt.freight_facade(0) if level_number == 2 else RouteArt.cell("tiles/architecture.png", 3, 2, 0, 0, 4), Vector2(pickup_x, 180), Vector2(222, 184), true)
	add_sprite(buildings, RouteArt.freight_facade(5) if level_number == 2 else RouteArt.cell("tiles/architecture.png", 3, 2, 1, 0, 4), Vector2(delivery_x, 180), Vector2(222, 184), true)

	if level_number == 1:
		RouteStory.caption_at(buildings, "Shop 24", Vector2(pickup_x, 108), 115)

	if level_number == 2:
		var cutout := ShaderMaterial.new()
		cutout.shader = preload("res://scripts/character_clip.gdshader")
		cutout.set_shader_parameter("alpha_cutoff",0.72)
		for building in buildings.get_children(): building.material = cutout

	if level_number == 2:
		RouteStory.sign(buildings,"02_recepcion_carga.png",Vector2(delivery_x,88),160)
		RouteStory.sign(buildings,"03_metro_campamento.png",Vector2(delivery_x+190,125),176)

func prop(index: int, pos: Vector2, size_: Vector2, obstacle: Vector2 = Vector2.ZERO) -> Sprite2D:
	var result := add_sprite(actors, RouteArt.prop(index), pos, size_, true)
	if index == 9:
		# Sort at the body centre, not the bottom of the painted ground shadow.
		# Compensate the sprite offset so the car artwork does not move.
		var sort_shift := size_.y * 0.45
		result.position.y -= sort_shift
		result.offset.y += sort_shift / result.scale.y
	if obstacle != Vector2.ZERO:
		var body := StaticBody2D.new()
		body.collision_layer = 4
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		if index == 9:
			# Expanded perimeter keeps actor feet outside the bumper and side panels.
			# Scale with the artwork; leave space to walk around either end.
			body.position = pos
			body.add_to_group("car_obstacles")
			var hull := ConvexPolygonShape2D.new()
			var points := PackedVector2Array()
			for point in [Vector2(-0.56, -0.48), Vector2(-0.18, -0.85), Vector2(0.49, -0.76), Vector2(0.56, -0.28), Vector2(0.10, 0.04), Vector2(-0.52, -0.06)]:
				points.append(point * size_)
			hull.points = points
			shape.shape = hull
		else:
			body.position = pos + Vector2(0, -obstacle.y / 2)
			var rect := RectangleShape2D.new()
			rect.size = obstacle
			shape.shape = rect
		body.add_child(shape)
		add_child(body)
	return result

func build_props() -> void:
	for x in range(260, int(world_length), 235):
		if absf(x - pickup_x) < 100 or absf(x - delivery_x) < 100: continue
		prop(5, Vector2(x + 31, 207), Vector2(24, 26))
		prop(19, Vector2(x - 30, 208), Vector2(39, 28))
		prop(7, Vector2(x + 48, 211), Vector2(26, 29))
		if floori(x / 235.0) % 3 == 0:
			prop(4, Vector2(x + 80, 212), Vector2(25, 37), Vector2(16, 15))
		if floori(x / 235.0) % 2 == 0:
			var puddle := prop(14, Vector2(x - 7, 295), Vector2(70, 23))
			puddle.modulate = Color(0.65, 0.68, 0.72, 0.26)
	for x in range(350, int(world_length), 680):
		var lamp := prop(10, Vector2(x, 211), Vector2(30, 102))
		lamps.append(lamp)
		var reflection := add_sprite(self, RouteArt.fx(5, 3), Vector2(x, 257), Vector2(65, 42))
		reflection.modulate.a = 0.20
		reflection.z_index = -1
		prop(11, Vector2(x + 76, 213), Vector2(22, 60))
	for x in range(650, int(world_length), 1400):
		if absf(x - pickup_x) < 250 or absf(x - delivery_x) < 250: continue
		prop(9, Vector2(x, 294), Vector2(100, 75), Vector2(74, 30))
		prop(6, Vector2(x + 70, 303), Vector2(18, 24))
	prop(8, Vector2(crossing_x + 140, 300), Vector2(78, 41), Vector2(58, 14))
	prop(9, Vector2(crossing_x - 200, 226), Vector2(108, 77), Vector2(78, 25))
	package = prop(0, package_point, Vector2(23, 24))
	gate = prop(8, Vector2(delivery_x, 199), Vector2(92, 40))
	for x in ([610, 1660, 2510, 2850] if level_number == 1 else [600, 1540, 2540, 3540, 4540, 4900]):
		medkits[str(x)] = prop(2, Vector2(x, 222), Vector2(23, 23))
		prop(7, Vector2(x + 28, 217), Vector2(36, 34))

	if level_number == 2:
		# Recognizable supply caches; no Local 24 package in this district.
		prop(7, package_point + Vector2(28, 0), Vector2(35, 29))
		# Supplies start beyond every possible first objective; keep saved pickup IDs.
		var supply_ids := [0, 1, 3, 4, 6, 7, 9, 10, 12, 13]
		for index in range(supply_ids.size()):
			var i: int = supply_ids[index]
			var x: float = 1370.0 + index * 400.0
			var item := add_sprite(actors, RouteArt.weapon_item(0), Vector2(x, 235 if i % 2 == 0 else 299), Vector2(25, 20), true)
			ammo_pickups[str(i)] = {"sprite": item, "amount": 12}

func build_weather() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	rain = Node2D.new()
	layer.add_child(rain)
	for i in range(38):
		var drop := add_sprite(rain, RouteArt.fx(4, i % 6), Vector2(rng.randf_range(0, get_viewport_rect().size.x), rng.randf_range(0, get_viewport_rect().size.y)), Vector2(18, 25))
		drop.modulate = Color(0.7, 0.83, 1, 0.15)

func _process(delta: float) -> void:
	ambient_time += delta
	freeze_time = maxf(0, freeze_time - delta)
	if not blocked and not player.dead:
		elapsed += delta
		if stage > 0 and stage < wave_count * 2 and stage % 2 == 0 and player.position.x >= destination() - (200 if level_number == 1 and stage == 4 else 170):
			start_wave(int(stage / 2.0) + 1)
		collect_ammo()
		collect_medkits()
		var district := 0 if player.position.x < district_two else 1 if player.position.x < district_three else 2
		if district != last_district:
			last_district = district
			announcement.emit((["01  /  COMERCIO EN SILENCIO", "02  /  EL CRUCE", "03  /  ÚLTIMA ENTREGA"] if level_number == 1 else ["DISTRITO DE CARGA", "PASO FERROVIARIO", "PUESTO DE EVACUACIÓN"])[district])
	update_camera(65.0)
	shake = move_toward(shake, 0, delta * 18)
	camera.offset = Vector2(sin(ambient_time * 91), cos(ambient_time * 83)) * shake
	marker.texture = RouteArt.fx(7, int(ambient_time * 7) % 6)
	marker.position.y = 150 + sin(ambient_time * 3) * 3
	marker.visible = stage % 2 == 0
	marker.position.x = destination()
	if level_number == 2 and stage == 0: marker.position.y = package_point.y - 38 + sin(ambient_time * 3) * 2
	for drop in rain.get_children():
		drop.position += Vector2(-12, 96) * delta
		if drop.position.y > get_viewport_rect().size.y + 20: drop.position = Vector2(rng.randf_range(0, get_viewport_rect().size.x), -20)
	for lamp in lamps:
		lamp.modulate.a = 0.86 + 0.14 * sin(ambient_time * 11 + lamp.position.x)

func clamp_actor(pos: Vector2) -> Vector2:
	var min_x := 26.0
	var max_x := world_length - 30
	if stage % 2 == 1 and stage < wave_count * 2:
		min_x = arena_center - 280
		max_x = arena_center + 280
	return Vector2(clampf(pos.x, min_x, max_x), clampf(pos.y, 204, 306))

func remaining() -> int:
	var count := 0
	for enemy in enemies:
		if not enemy.dead: count += 1
	return count

func nearest_enemy(pos: Vector2, distance: float) -> RouteEnemy:
	var result: RouteEnemy = null
	for enemy in enemies:
		if enemy.dead: continue
		var d := pos.distance_to(enemy.position)
		if d < distance:
			distance = d
			result = enemy
	return result

func player_strike(actor: RoutePlayer) -> void:
	var hit := false
	for enemy in enemies:
		if enemy.dead: continue
		var offset := enemy.position - actor.position
		if offset.length() <= 43 and (offset.normalized().dot(actor.facing) > 0.1 or offset.length() < 17):
			enemy.take_damage(34, actor.position)
			spawn_fx(enemy.position + Vector2(0, -22), 2, 0.18)
			hit = true
	if hit:
		audio.cue("hit", -8, rng.randf_range(0.9, 1.1))
		freeze_time = 0.045
		shake = 1.8

func spawn_fx(pos: Vector2, row: int, scale_: float) -> void:
	var effect := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.set_animation_loop("default", false)
	frames.set_animation_speed("default", 22)
	for i in range(6): frames.add_frame("default", RouteArt.fx(row, i))
	effect.sprite_frames = frames
	effect.position = pos
	effect.scale = Vector2.ONE * scale_
	effect.z_index = 4
	add_child(effect)
	effect.animation_finished.connect(effect.queue_free)
	effect.play()

func start_wave(number: int) -> void:
	wave_index = number
	stage = number * 2 - 1
	arena_center = route_points[number - 1]
	goal = objective_text()
	var definition := RoutePlan.wave(number) if level_number == 1 else RouteLevelTwo.wave(number)
	objective_changed.emit(goal)
	announcement.emit(tr("OLEADA %d  /  %d INFECTADOS") % [number, definition.count])
	audio.cue("wave", -14)
	if definition.count>=5: audio.cue("zombie",-16)
	for side in [-1, 1]:
		for y in [250, 306]:
			wave_locks.append(prop(8, Vector2(arena_center + side * 280, y), Vector2(55, 34)))
	build_navigation()
	var offsets: Array = definition.entries
	for i in range(definition.count):
		var enemy := load("res://scenes/enemy.tscn").instantiate() as RouteEnemy
		enemy.level = self
		enemy.resistant = i == definition.resistant_index if level_number == 1 else i < int(definition.resistant_count)
		enemy.difficulty = 1.0 if level_number == 1 else 1.18
		enemy.position = safe_spawn(Vector2(arena_center + offsets[i % offsets.size()].x, offsets[i % offsets.size()].y))
		actors.add_child(enemy)
		enemy.killed.connect(enemy_killed)
		enemies.append(enemy)

func enemy_killed(_enemy: RouteEnemy) -> void:
	kills += 1
	if remaining() == 0:
		stage += 1
		goal = objective_text()
		for barrier in wave_locks: barrier.queue_free()
		wave_locks.clear()
		if stage == wave_count * 2: gate.hide()
		objective_changed.emit(goal)
		announcement.emit(tr("RUTA DESPEJADA  /  ") + tr("ENTRADA ABIERTA" if stage == wave_count * 2 else "PUNTO SEGURO"))
		checkpoint.emit(snapshot())

func interaction_action() -> String:
	if player.action_time > 0: return ""
	if stage == 0 and player.position.distance_to(package_point) < 62: return "recoger paquete"
	if stage == wave_count * 2 and player.position.distance_to(Vector2(delivery_x, 207)) < 65: return "entregar paquete"
	return ""

func interaction_hint() -> String:
	var action := interaction_action()
	if not action.is_empty(): return "E / Enter · " + tr(action)
	if stage % 2 == 1 and stage < wave_count * 2: return "Espacio / clic · disparar   R · recargar   Q · arma" if player.has_pistol else "Espacio · cuchillo    |    Muévete para esquivar"
	if player.action_time > 0: return ""
	for key in medkits:
		if not collected.has(key) and player.position.distance_to(medkits[key].position) < 45:
			return "Botiquín (+35) · recogida automática" if player.health < 100 else "Salud completa"
	var target_x := destination()
	var distance := int(absf(target_x - player.position.x) / METRE)
	return tr("←  Objetivo · %d m") % distance if player.position.x > target_x else tr("Objetivo · %d m  →") % distance

func interact() -> void:
	if blocked or player.dead or player.action_time > 0: return
	if stage == 0 and player.position.distance_to(package_point) < 62:
		player.interact_animation("pickup_package")
	elif stage == wave_count * 2 and player.position.distance_to(Vector2(delivery_x, 207)) < 65:
		player.interact_animation("delivery")

func collect_medkits() -> void:
	# Shared by every route: touching a kit heals once, only when health is missing.
	if blocked or player.dead or player.health >= 100: return
	for key in medkits:
		if collected.has(key) or player.position.distance_to(medkits[key].position) > 20: continue
		player.health = mini(100, player.health + 35)
		collected.append(key)
		medkits[key].hide()
		audio.cue("pickup")
		if player.health >= 100: break

func finish_interaction(action: String) -> void:
	if action == "pickup_package":
		package.hide()
		player.carrying = true
		audio.cue("pickup")
		start_wave(1)
	elif action == "delivery":
		stage = wave_count * 2 + 1
		blocked = true
		player.carrying = false
		audio.cue("delivery")
		delivered.emit()

func snapshot() -> Dictionary:
	return {"level": level_number, "pickup_slot": pickup_slot, "ammo_taken": ammo_taken.duplicate(), "magazine": player.magazine, "reserve": player.reserve, "pistol_equipped": player.pistol_equipped, "layout_version": 3, "stage": stage, "x": player.position.x, "health": player.health, "kills": kills, "damage": damage_received, "elapsed": elapsed, "collected": collected.duplicate()}

func restore(data: Dictionary) -> void:
	stage = int(data.stage)
	if level_number == 2:
		pickup_slot = clampi(int(data.get("pickup_slot", 0)), 0, 2)
		package_point = [Vector2(1090, 240), Vector2(1160, 284), Vector2(1230, 225)][pickup_slot]
		pickup_x = package_point.x
		route_points[0] = pickup_x
		package.position = package_point
		player.magazine = clampi(int(data.get("magazine", 12)), 0, 12)
		player.reserve = clampi(int(data.get("reserve", RoutePlayer.MAX_RESERVE)), 0, RoutePlayer.MAX_RESERVE)
		player.pistol_equipped = bool(data.get("pistol_equipped", true))
		player.animate("idle")
		ammo_taken = data.get("ammo_taken", []).duplicate()
		for key in ammo_taken:
			if ammo_pickups.has(str(key)): ammo_pickups[str(key)].sprite.hide()
	var restored_x := float(data.x)
	# Preserve existing progress when loading checkpoints from the long route.
	if int(data.get("layout_version", 1)) < 3:
		var old_anchors := [160.0, 1050.0, 8000.0, 15800.0, 16400.0] if int(data.get("layout_version", 1)) == 1 else [160.0, 760.0, 1360.0, 1960.0, 2320.0]
		var new_anchors := [START_X, pickup_x, crossing_x, delivery_x, world_length]
		var segment := 0 if stage == 0 else 1 if stage == 2 else 2 if stage == 4 else 3
		var progress := clampf(inverse_lerp(old_anchors[segment], old_anchors[segment + 1], restored_x), 0, 1)
		restored_x = lerpf(new_anchors[segment], new_anchors[segment + 1], progress)
	player.position = Vector2(clampf(restored_x, 30, world_length - 30), 252)
	player.health = clampi(int(data.health), 1, 100)
	player.carrying = stage > 0
	kills = int(data.kills)
	damage_received = int(data.damage)
	elapsed = float(data.elapsed)
	collected = data.get("collected", [])
	if int(data.get("layout_version", 1)) < 2:
		var pickup_remap := {"2300": "430", "6200": "1060", "10600": "1570", "14500": "1770"}
		collected = collected.map(func(key): return pickup_remap.get(str(key), str(key)))
	if int(data.get("layout_version", 1)) < 3:
		var pickup_remap := {"430": "610", "1060": "1660", "1570": "2510", "1770": "2850"}
		collected = collected.map(func(key): return pickup_remap.get(str(key), str(key)))
	for key in collected:
		if medkits.has(key): medkits[key].hide()
	package.visible = stage == 0
	gate.visible = stage != wave_count * 2
	goal = objective_text()
	blocked = false
	update_camera(65.0)
	camera.reset_smoothing()

func destination() -> float:
	return route_points[mini(int(stage / 2.0), wave_count - 1)]

func objective_text() -> String:
	if level_number == 1: return RoutePlan.objective(stage)
	if stage == 0: return "Recoge el paquete marcado"
	if stage % 2 == 1 and stage < 10: return tr("Sobrevive · oleada %d / 5") % (int((stage + 1) / 2.0))
	if stage == 10: return "Entrega en el puesto de evacuación"
	if stage > 10: return "Entrega completada"
	return ["", "Avanza al almacén", "Cruza el paso ferroviario", "Llega al control de carga", "Alcanza la evacuación"][int(stage / 2.0)]

func collect_ammo() -> void:
	if not player.has_pistol: return
	for key in ammo_pickups:
		if ammo_taken.has(key): continue
		var item: Dictionary = ammo_pickups[key]
		if player.position.distance_to(item.sprite.position) > 20 or player.reserve >= RoutePlayer.MAX_RESERVE: continue
		var amount := mini(int(item.amount), RoutePlayer.MAX_RESERVE - player.reserve)
		player.reserve += amount
		ammo_taken.append(key)
		item.sprite.hide()
		audio.cue("pickup", -16)
		announcement.emit(tr("+%d MUNICIÓN") % amount)
		var halo := add_sprite(self, RouteArt.weapon_item(7), item.sprite.position, Vector2(30,20))
		halo.z_index = 3
		var tween := create_tween()
		tween.tween_property(halo,"modulate:a",0.0,0.35)
		tween.tween_callback(halo.queue_free)

func pistol_shot(actor: RoutePlayer) -> void:
	# Hitscan queries feet-space colliders, then displays the shot at hand height.
	# The first wall or enemy stops the bullet; no shooting through cars.
	var from := actor.position
	var end := from + actor.facing * 280
	var excluded: Array[RID] = [actor.get_rid()]
	excluded.append_array(projectile_exclusions())
	var query := PhysicsRayQueryParameters2D.create(from, end, 6, excluded)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		end = hit.position
		if hit.collider is RouteEnemy:
			hit.collider.take_damage(44, from)
			spawn_fx(end + Vector2(0,-20),2,0.15)
		else:
			var spark := add_sprite(self, RouteArt.weapon_item(6), end + Vector2(0,-20), Vector2(12,12))
			get_tree().create_timer(0.10,false).timeout.connect(spark.queue_free)
	var flash := add_sprite(self,RouteArt.weapon_item(4), from + Vector2(0,-22) + actor.facing * 16,Vector2(14,14))
	flash.rotation = actor.facing.angle()
	flash.z_index = 5
	get_tree().create_timer(0.07,false).timeout.connect(flash.queue_free)
	var casing := add_sprite(self,RouteArt.weapon_item(5), from + Vector2(8,-20),Vector2(3,5))
	var tween := create_tween()
	tween.tween_property(casing,"position",from + Vector2(14,-1),0.18)
	tween.tween_property(casing,"modulate:a",0.0,0.25)
	tween.tween_callback(casing.queue_free)
	audio.cue("pistol", -12, rng.randf_range(0.96,1.04))
	shake = maxf(shake,0.65)

func can_see_enemy(from: Vector2, enemy: RouteEnemy) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from,enemy.position,4)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func clamp_enemy(pos: Vector2) -> Vector2:
	return clamp_actor(pos)

func safe_spawn(pos: Vector2) -> Vector2:
	var circle := CircleShape2D.new()
	circle.radius = 11
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.collision_mask = 4
	for dy in [0,-24,24,-48,48,-72,72]:
		for dx in [0,-20,20,-40,40,-64,64,-80,80]:
			var candidate := clamp_enemy(pos + Vector2(dx,dy))
			query.transform = Transform2D(0,candidate)
			if get_world_2d().direct_space_state.intersect_shape(query,1).is_empty(): return candidate
	return clamp_enemy(pos)

func build_navigation() -> void:
	navigation = AStarGrid2D.new()
	navigation_origin = Vector2(arena_center-272,204)
	navigation.region = Rect2i(0,0,35,7)
	navigation.cell_size = Vector2(16,16)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	var circle := CircleShape2D.new()
	circle.radius = 10
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.collision_mask = 4
	for x in 35:
		for y in 7:
			query.transform = Transform2D(0,navigation_origin + Vector2(x,y)*16)
			navigation.set_point_solid(Vector2i(x,y),not get_world_2d().direct_space_state.intersect_shape(query,1).is_empty())

func nearest_nav_cell(pos: Vector2) -> Vector2i:
	var cell := Vector2i(((pos-navigation_origin)/16).round())
	cell.x = clampi(cell.x,0,34)
	cell.y = clampi(cell.y,0,6)
	var best := cell
	var distance := INF
	for x in 35:
		for y in 7:
			var candidate := Vector2i(x,y)
			if navigation.is_point_solid(candidate): continue
			var d := Vector2(candidate-cell).length_squared()
			if d < distance:
				distance = d
				best = candidate
	return best

func enemy_path(pos: Vector2, target: Vector2) -> PackedVector2Array:
	if navigation == null: return PackedVector2Array([target])
	var ids := navigation.get_id_path(nearest_nav_cell(pos),nearest_nav_cell(target))
	var points := PackedVector2Array()
	for i in range(1,ids.size()): points.append(navigation_origin+Vector2(ids[i])*16)
	points.append(target)
	return points

func settle_supplies() -> void:
	# Wait for static car/bin shapes to enter the physics world before placing loot.
	await get_tree().physics_frame
	await get_tree().physics_frame
	for item in ammo_pickups.values():
		item.sprite.position = safe_spawn(item.sprite.position)

func nearest_visible_enemy(pos: Vector2, distance: float) -> RouteEnemy:
	var target: RouteEnemy = null
	for enemy in enemies:
		if enemy.dead: continue
		var d := pos.distance_to(enemy.position)
		if d < distance and can_see_enemy(pos,enemy):
			distance = d
			target = enemy
	return target

func projectile_exclusions() -> Array[RID]:
	return []

func assisted_aim(pos: Vector2, distance: float, fallback: Vector2) -> Vector2:
	var target := nearest_visible_enemy(pos,distance)
	return (target.position-pos).normalized() if target != null else fallback

func create_player() -> RoutePlayer:
	return load("res://scenes/player.tscn").instantiate() as RoutePlayer

# Preserve the designed street height; widen only the visible world on phones.
func update_camera(look_ahead: float = 65.0) -> void:
	var viewport_size := get_viewport_rect().size
	var zoom_factor := maxf(viewport_size.y / 324.0, viewport_size.x / world_length)
	camera.zoom = Vector2.ONE * zoom_factor
	var half_width := viewport_size.x / zoom_factor / 2.0
	camera.position = Vector2(clampf(player.position.x + look_ahead, half_width, world_length-half_width), 162)
	# Shake cannot reveal space beyond the start or end of the scenery.
	camera.limit_left = 0
	camera.limit_right = ceili(world_length)
	camera.limit_top = 0
	camera.limit_bottom = 324
