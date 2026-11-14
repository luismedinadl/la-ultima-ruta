class_name ContainmentLevel
extends MetroLevel
## Five finite encounters; documents and the final weapon are explicit progression gates.
signal document_requested(content: Array)
var document_read: Array = []
var pending_document := -1
var route_choices: Array = [-1,-1]
var evidence: Array[Sprite2D] = []
var shotgun_pickup: Sprite2D
var shell_pickup: Sprite2D
var shells_taken := false
var hollow_unlocked := false
const DOCUMENT_POINTS := [Vector2(3160,231),Vector2(4850,231)]
const GUN_POINT := Vector2(5160,250)

func configure_route() -> void:
	level_number = 4
	wave_count = 5
	world_length = 5600
	pickup_x = 3160
	package_point = DOCUMENT_POINTS[0]
	crossing_x = 2160
	delivery_x = 5320
	district_two = 2160
	district_three = 4160
	route_points = [1160.0,2160.0,3160.0,4160.0,5160.0]

func create_player() -> RoutePlayer:
	return ShotgunPlayer.new()

func prepare_entrance() -> void:
	# No unbounded ambient spawner. Each encounter owns all its enemies.
	intro_spawned = true

func build_street() -> void:
	# Complete campsite backgrounds replace every reused urban facade.
	# Structures stay behind y=190; the player lane begins at y=204.
	station_walls = Node2D.new()
	station_walls.name = "CampBackgrounds"
	station_walls.z_index = -5
	add_child(station_walls)
	var last_start := delivery_x-288.0
	var stride := last_start/10.0
	for index in 11:
		var variant := "medical" if index<4 else "isolation" if index<10 else "perimeter"
		var background := add_sprite(station_walls,RouteArt.texture("containment/backgrounds/"+variant+".png"),Vector2(index*stride+288,162),Vector2(576,324))
		background.name = "CampSection%02d" % index
		background.add_to_group("containment_backgrounds")
		# Blend only the border between adjacent painted sections, never draw scenery.
		var blend := ShaderMaterial.new()
		blend.shader = preload("res://scripts/camp_join.gdshader")
		blend.set_shader_parameter("join_width",(576.0-stride)/576.0 if index>0 else 0.0)
		background.material = blend
	gate = add_sprite(station_walls,ContainmentArt.item(2),Vector2(delivery_x,180),Vector2(120,125),true)
	RouteStory.sign(station_walls,"04_salida_campamento.png",Vector2(delivery_x+160,108),208)
	gate.name = "PerimeterExit"
	ContainmentArt.cutout(gate)

func containment_prop(index: int, pos: Vector2, size_: Vector2, footprint: Vector2 = Vector2.ZERO) -> Sprite2D:
	var sprite := add_sprite(actors,ContainmentArt.item(index),pos,size_,true)
	ContainmentArt.cutout(sprite)
	if footprint != Vector2.ZERO:
		var body := StaticBody2D.new()
		body.collision_layer = 4
		body.collision_mask = 0
		body.position = pos-Vector2(0,footprint.y/2)
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = footprint
		shape.shape = rectangle
		body.add_child(shape)
		add_child(body)
	return sprite

func build_props() -> void:
	# Ambulances, tents, lamps and rear cages belong to the painted camp backdrop.
	# Only playable obstacles and collectible objects are separate sprites.
	# Two continuous central dividers create actual upper/lower paths that rejoin.
	for origin in [1450,3450]:
		for x in range(origin,origin+401,80):
			containment_prop(4,Vector2(x,265),Vector2(82,36),Vector2(82,20))
	for i in 2:
		evidence.append(containment_prop(6,DOCUMENT_POINTS[i],Vector2(28,25)))
	shotgun_pickup = containment_prop(7,GUN_POINT,Vector2(49,18))
	shell_pickup = containment_prop(8,Vector2(5350,294),Vector2(24,23))
	for x in [1330,2320,3330,4330,5010]:
		medkits[str(x)] = prop(2,Vector2(x,292),Vector2(23,23))
	for i in 7:
		var x: float = [1320,1810,2370,2880,3390,3900,4480][i]
		var box := add_sprite(actors,RouteArt.weapon_item(0),Vector2(x,294 if i%2==0 else 222),Vector2(25,20),true)
		ammo_pickups[str(i)] = {"sprite":box,"amount":12}

func _process(delta: float) -> void:
	ambient_time += delta
	freeze_time = maxf(0,freeze_time-delta)
	if not blocked and not player.dead:
		elapsed += delta
		collect_ammo()
		collect_medkits()
		collect_shells()
		for i in 2:
			if route_choices[i] == -1 and player.position.x >= [1640,3640][i]:
				route_choices[i] = 0 if player.position.y < 250 else 1
				announcement.emit("PASO DE SERVICIO" if route_choices[i] == 0 else "PATIO DE CARGA")
		if stage in [0,2,6] and player.position.x >= destination()-150:
			start_wave(int(stage/2.0)+1)
	update_camera(65.0)
	shake = move_toward(shake,0,delta*18)
	camera.offset = Vector2(sin(ambient_time*91),cos(ambient_time*83))*shake
	marker.texture = RouteArt.fx(7,int(ambient_time*7)%6)
	marker.visible = stage%2 == 0 and stage < 11
	marker.position = Vector2(destination(),170)
	if stage == 4: marker.position.y = 195
	if stage == 8: marker.position.y = 218

func clamp_actor(pos: Vector2) -> Vector2:
	var min_x := arena_center-280 if stage%2==1 and stage<10 else 26.0
	var max_x := arena_center+280 if stage%2==1 and stage<10 else world_length-30
	return Vector2(clampf(pos.x,min_x,max_x),clampf(pos.y,204,306))

func spawn_enemy(pos: Vector2, tough: bool, alerted: bool, panel: bool = false, dog: bool = false) -> MetroEnemy:
	if not hollow_unlocked or tough or dog: return super.spawn_enemy(pos,tough,alerted,panel,dog)
	var enemy := HollowEnemy.new()
	enemy.level = self
	enemy.difficulty = 1.18
	enemy.awareness = 2 if alerted else 0
	enemy.show_awareness_icon = not alerted
	enemy.position = safe_spawn(pos)
	actors.add_child(enemy)
	enemy.killed.connect(enemy_killed)
	enemies.append(enemy)
	return enemy

func start_wave(number: int) -> void:
	wave_index = number
	stage = number*2-1
	arena_center = route_points[number-1]
	goal = objective_text()
	build_navigation()
	var count: int = [6,7,7,8,7][number-1]
	var resistant_count: int = [1,2,2,3,1][number-1]
	for i in count:
		var pos := Vector2(arena_center+(-225 if i%2==0 else 225),215+(i%3)*38)
		var alerted: bool = not (number in [2,4] and route_choices[0 if number==2 else 1]==0)
		spawn_enemy(pos,i<resistant_count,alerted)
	if number in [1,2,4,5]:
		spawn_enemy(Vector2(arena_center+250,290),false,true,false,true)
		audio.cue("dog_growl",-12)
	announcement.emit("EL HUECO · mantén la distancia" if number==5 else tr("ENCUENTRO %d / 5") % number)
	audio.cue("hollow" if number==5 else "wave",-14)
	if not hollow_unlocked and count>=5: audio.cue("zombie",-16)

func enemy_killed(_enemy: RouteEnemy) -> void:
	kills += 1
	if stage%2==1 and stage<10 and remaining()==0:
		stage += 1
		goal = objective_text()
		announcement.emit(tr("PASO DESPEJADO · ") + tr(goal))
		checkpoint.emit(snapshot())

func destination() -> float:
	if stage >= 10: return delivery_x
	return route_points[mini(int(stage/2.0),4)]

func objective_text() -> String:
	return ["Alcanza el puesto de contención","Despeja el control sanitario","Cruza el centro de clasificación","Despeja el patio","Lee el registro del supervisor","Sobrevive al cierre del centro","Avanza al depósito de jaulas","Despeja el último depósito","Busca equipo en la salida de emergencia","Sobrevive a los Huecos","Cruza la salida de emergencia","Pruebas recuperadas"][clampi(stage,0,11)]

func nearby_document() -> int:
	if stage%2==1: return -1
	for i in 2:
		if player.position.distance_to(DOCUMENT_POINTS[i]) < 42: return i
	return -1

func interaction_action() -> String:
	if stage >= 11: return ""
	if nearby_document() >= 0: return "leer documento"
	if stage == 8 and player.position.distance_to(GUN_POINT)<48: return "recoger escopeta"
	if stage == 10 and absf(player.position.x-delivery_x)<55: return "abrir salida con la tarjeta"
	return ""

func interaction_hint() -> String:
	var action := interaction_action()
	if not action.is_empty(): return "E / Enter · " + tr(action)
	if stage >= 11: return "Ruta completada"
	if stage%2==1: return "Espacio / clic · atacar   R · recargar   Q · cambiar arma"
	return tr("Objetivo · %d m →") % int(absf(destination()-player.position.x)/METRE)

func interact() -> void:
	if blocked or player.dead or player.action_time>0: return
	var doc := nearby_document()
	if doc >= 0:
		pending_document = doc
		blocked = true
		document_requested.emit([ContainmentArt.document(doc)])
	elif stage==8 and player.position.distance_to(GUN_POINT)<48:
		(player as ShotgunPlayer).acquire_shotgun()
		shotgun_pickup.hide()
		hollow_unlocked = true
		audio.cue("pickup")
		start_wave(5)
		# Pause the encounter while Nico reacts; no document or checkpoint is created.
		pending_document = -1
		blocked = true
		document_requested.emit([{"name":"NICO","portrait":0,"text":"¿Qué rayos son esas cosas? ¡Ya no parecen humanas!"}])
	elif stage==10 and absf(player.position.x-delivery_x)<55:
		open_exit()
		stage = 11
		blocked = true
		delivered.emit()

func document_closed() -> void:
	var doc := pending_document
	if doc >= 0 and not document_read.has(doc): document_read.append(doc)
	pending_document = -1
	blocked = false
	if doc < 0: return # Spoken reaction: resume the existing wave.
	if doc==0 and stage==4:
		announcement.emit("TARJETA DEL SUPERVISOR RECUPERADA")
		start_wave(3)
	else: checkpoint.emit(snapshot())

func finish_interaction(_action: String) -> void:
	pass

func open_exit() -> void:
	var r: Array = ContainmentArt.records("containment").exit_open[0].rect
	gate.texture = RouteArt.region("containment/exit_open.png",Rect2(r[0],r[1],r[2],r[3]))
	gate.scale = Vector2(120,125)/gate.texture.get_size()
	gate.offset.y = -gate.texture.get_height()/2.0
	ContainmentArt.cutout(gate)
	audio.cue("delivery",-15)

func collect_shells() -> void:
	var p := player as ShotgunPlayer
	if not p.has_shotgun or shells_taken or p.shell_reserve>=p.MAX_SHELL_RESERVE: return
	if p.position.distance_to(shell_pickup.position)>20: return
	p.shell_reserve = mini(p.MAX_SHELL_RESERVE,p.shell_reserve+4)
	shells_taken = true
	shell_pickup.hide()
	audio.cue("pickup",-16)
	announcement.emit("CARTUCHOS DE ESCOPETA")

func shotgun_shot(actor: ShotgunPlayer) -> void:
	# Nine independent pellets: blockers stop each ray; damage aggregates once per victim.
	make_noise(actor.position,460,true)
	var hits: Dictionary = {}
	for i in 9:
		var heading := actor.facing.rotated(deg_to_rad((i-4)*4.0))
		var excluded: Array[RID] = [actor.get_rid()]
		excluded.append_array(projectile_exclusions())
		var query := PhysicsRayQueryParameters2D.create(actor.position,actor.position+heading*210,6,excluded)
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		if hit.is_empty(): continue
		if hit.collider is RouteEnemy:
			var distance := actor.position.distance_to(hit.position)
			hits[hit.collider] = int(hits.get(hit.collider,0))+(26 if distance<100 else 18)
			spawn_fx(hit.position+Vector2(0,-20),2,0.15)
	for enemy in hits:
		enemy.take_damage(mini(156,int(hits[enemy])),actor.position)
		if not enemy.dead: enemy.knockback = (enemy.position-actor.position).normalized()*150
	var flash := add_sprite(self,RouteArt.weapon_item(4),actor.position+Vector2(0,-23)+actor.facing*24,Vector2(25,21))
	flash.rotation = actor.facing.angle()
	flash.z_index = 5
	get_tree().create_timer(0.09,false).timeout.connect(flash.queue_free)
	audio.cue("shotgun",-10)
	shake = maxf(shake,1.4)

func snapshot() -> Dictionary:
	var data := super.snapshot()
	var p := player as ShotgunPlayer
	data.merge({"document_read":document_read.duplicate(),"route_choices":route_choices.duplicate(),"hollow_unlocked":hollow_unlocked,"has_shotgun":p.has_shotgun,"weapon_slot":p.weapon_slot,"shells":p.shells,"shell_reserve":p.shell_reserve,"shells_taken":shells_taken})
	return data

func restore(data: Dictionary) -> void:
	# Safe checkpoints have no live combatants; a retry restarts the next encounter.
	stage = int(data.stage)
	for enemy in enemies: enemy.queue_free()
	enemies.clear()
	player.position = Vector2(clampf(float(data.x),26,world_length-30),290)
	player.health = clampi(int(data.health),1,100)
	player.magazine = clampi(int(data.get("magazine",12)),0,12)
	player.reserve = clampi(int(data.get("reserve",36)),0,36)
	kills = int(data.kills)
	damage_received = int(data.damage)
	elapsed = float(data.elapsed)
	collected = data.get("collected",[]).duplicate()
	ammo_taken = data.get("ammo_taken",[]).duplicate()
	for key in medkits: medkits[key].visible = not collected.has(key)
	for key in ammo_pickups: ammo_pickups[key].sprite.visible = not ammo_taken.has(key)
	document_read = data.get("document_read",[]).duplicate()
	route_choices = data.get("route_choices",[-1,-1]).duplicate()
	hollow_unlocked = bool(data.get("hollow_unlocked",stage>=10))
	var p := player as ShotgunPlayer
	p.has_shotgun = bool(data.get("has_shotgun",false))
	p.weapon_slot = clampi(int(data.get("weapon_slot",1)),0,2 if p.has_shotgun else 1)
	p.pistol_equipped = p.weapon_slot!=0
	p.shells = clampi(int(data.get("shells",0)),0,4)
	p.shell_reserve = clampi(int(data.get("shell_reserve",0)),0,12)
	p.animate("idle")
	shells_taken = bool(data.get("shells_taken",false))
	shell_pickup.visible = not shells_taken
	shotgun_pickup.visible = not p.has_shotgun
	goal = objective_text()
	blocked = false
	camera.reset_smoothing()
