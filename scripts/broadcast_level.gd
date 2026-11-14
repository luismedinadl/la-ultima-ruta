class_name BroadcastLevel
extends ContainmentLevel
## Explicit safe states separate finite combat from equipment and radio conversations.
const POINTS := [650.0,1610.0,2570.0,3530.0,4490.0,5450.0]
const SAFE_STAGES := [0,2,3,5,6,8,9,10,12,13,15]
const FIGHT_STAGES := [1,4,7,11,14]
var power_on := false
var antenna_connected := false
var files_sent := false
var harbor_confirmed := false
var pending_read := ""
var reinforcement_sent := false
var arrivals: Array[Dictionary] = []
var shell_boxes: Dictionary = {}
var shells_collected: Array = []
var power_switch: Sprite2D
var antenna_switch: Sprite2D
var computer: Sprite2D
var memory: Sprite2D
var status_label: Label
var obstacle_bodies: Array[StaticBody2D] = []

func configure_route() -> void:
	level_number = 7
	wave_count = 5
	world_length = 5856
	pickup_x = POINTS[0]
	crossing_x = POINTS[2]
	delivery_x = 5660
	district_two = 960
	district_three = 1920
	route_points.assign([POINTS[0],POINTS[1],POINTS[2],POINTS[4],POINTS[5]])
	hollow_unlocked = true

func _ready() -> void:
	super._ready()
	(player as ShotgunPlayer).acquire_shotgun()
	player.weapon_slot = 1
	player.animate("idle")
	refresh_objects()

func build_street() -> void:
	station_walls = Node2D.new()
	station_walls.z_index = -5
	add_child(station_walls)
	var variants := ["access","power","antenna","studio","service","exit"]
	for i in 12:
		var bg := add_sprite(station_walls,load(BroadcastArt.FOLDER+variants[int(i/2.0)]+".png"),Vector2(i*480+288,162),Vector2(576,324))
		var blend := ShaderMaterial.new()
		blend.shader = preload("res://scripts/camp_join.gdshader")
		blend.set_shader_parameter("join_width",96.0/576.0 if i>0 else 0.0)
		bg.material = blend
	for i in 6:
		var plate := add_sprite(station_walls,DistributionArt.item(3,"fixtures"),Vector2(POINTS[i],76),Vector2(154,28))
		MetroArt.cutout(plate)
		var sign_node := Label.new()
		sign_node.text = ["ESTACIÓN DE RADIO","ENERGÍA","ANTENA","SALA DE EMISIÓN","SALIDA DE SERVICIO","PUERTO →"][i]
		sign_node.position = Vector2(POINTS[i]-75,68)
		sign_node.size = Vector2(150,20)
		sign_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sign_node.add_theme_font_size_override("font_size",10)
		station_walls.add_child(sign_node)

func item(index: int, pos: Vector2, size_: Vector2, footprint := Vector2.ZERO) -> Sprite2D:
	var sprite := add_sprite(actors,BroadcastArt.item(index),pos,size_,true)
	MetroArt.cutout(sprite)
	if footprint != Vector2.ZERO:
		var body := StaticBody2D.new()
		body.position = pos-Vector2(0,footprint.y/2)
		body.collision_layer = 4
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = footprint
		shape.shape = rect
		body.add_child(shape)
		add_child(body)
		obstacle_bodies.append(body)
	return sprite

func build_props() -> void:
	power_switch = item(0,Vector2(1610,200),Vector2(38,58))
	antenna_switch = item(2,Vector2(2570,202),Vector2(42,62))
	item(9,Vector2(3540,231),Vector2(112,48),Vector2(102,22))
	computer = item(4,Vector2(3530,195),Vector2(44,39))
	computer.z_index = 1
	memory = item(7,Vector2(3564,194),Vector2(12,12))
	memory.z_index = 1
	var radio := item(8,Vector2(3497,195),Vector2(26,21))
	radio.z_index = 1
	item(10,Vector2(4490,199),Vector2(24,40))
	item(11,Vector2(1660,196),Vector2(20,24))
	status_label = Label.new()
	status_label.position = Vector2(3430,128)
	status_label.size = Vector2(200,30)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size",9)
	status_label.add_theme_color_override("font_color",Color("a9d6d8"))
	add_child(status_label)
	# Every supply has a fixed world position; no clamp against the current objective.
	for x in [1040,2200,3620,4180,5020,5100,5180]:
		var box := add_sprite(actors,RouteArt.weapon_item(0),Vector2(x,280),Vector2(25,20),true)
		ammo_pickups[str(x)] = {"sprite":box,"amount":12}
	for x in [2050,3660,4220,5060,5140,5220]:
		shell_boxes[str(x)] = containment_prop(8,Vector2(x,280),Vector2(24,23))
	for x in [2090,4880]: medkits[str(x)] = prop(2,Vector2(x,245),Vector2(23,23))

func settle_supplies() -> void:
	pass

func build_weather() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	rain = Node2D.new()
	layer.add_child(rain)
	for i in 18:
		var drop := add_sprite(rain,RouteArt.fx(4,i%6),Vector2(rng.randf_range(0, get_viewport_rect().size.x),rng.randf_range(0, get_viewport_rect().size.y)),Vector2(12,20))
		drop.modulate.a = 0.22

func _process(delta: float) -> void:
	ambient_time += delta
	freeze_time = maxf(0,freeze_time-delta)
	if not blocked and not player.dead:
		elapsed += delta
		collect_ammo()
		collect_medkits()
		collect_shells()
		advance_arrivals(delta)
		if stage in [0,6,10,13] and player.position.x>=destination()-160:
			start_wave({0:1,6:3,10:4,13:5}[stage])
		if stage in FIGHT_STAGES: advance_encounter()
	update_camera(65.0)
	shake = move_toward(shake,0,delta*18)
	camera.offset = Vector2(sin(ambient_time*91),cos(ambient_time*83))*shake
	marker.visible = stage not in FIGHT_STAGES and stage<16
	marker.texture = RouteArt.fx(7,int(ambient_time*7)%6)
	marker.position = Vector2(destination(),174)
	var district := clampi(int(player.position.x/960),0,5)
	rain.visible = district in [0,2,5]
	if district!=last_district:
		last_district = district
		audio.ambience.volume_db = -19 if rain.visible else -65
		announcement.emit(["ESTACIÓN DE RADIO","ALIMENTACIÓN DE EMERGENCIA","PATIO DE LA ANTENA","SALA DE EMISIÓN","PASILLO DE SERVICIO","SALIDA HACIA EL PUERTO"][district])
	for drop in rain.get_children():
		drop.position += Vector2(-28,150)*delta
		if drop.position.y > get_viewport_rect().size.y + 20: drop.position = Vector2(rng.randf_range(0, get_viewport_rect().size.x),-20)

func set_stage(value: int) -> void:
	stage = value
	goal = objective_text()

func destination() -> float:
	if stage<=2: return POINTS[0]
	if stage<=5: return POINTS[1]
	if stage<=8: return POINTS[2]
	if stage==9: return POINTS[3]
	if stage<=12: return POINTS[4]
	if stage<=14: return POINTS[5]
	return delivery_x

func objective_text() -> String:
	return ["Entra en la estación","Despeja la entrada","Comprueba la entrada","Activa la alimentación de emergencia","Elimina a los infectados","Comprueba la conexión","Llega al patio de la antena","Despeja el patio","Conecta la antena","Envía los archivos desde emisión","Busca la salida de servicio","Abre camino hasta la salida","Escucha las indicaciones por radio","Cruza el patio de salida","Despeja la salida al puerto","Sal de la estación","Rescate contactado"][clampi(stage,0,16)]

func start_wave(number: int) -> void:
	if stage in FIGHT_STAGES or not arrivals.is_empty(): return
	wave_index = number
	arena_center = route_points[number-1]
	reinforcement_sent = false
	set_stage(FIGHT_STAGES[number-1])
	build_navigation()
	match number:
		1,2: queue_group(5,2,0)
		3: queue_group(4,1,1)
		4,5: queue_group(4,2,0)
	audio.cue("wave",-15)
	announcement.emit(tr("ENCUENTRO %d / 5 · ATENCIÓN A LOS ACCESOS") % number)

func advance_encounter() -> void:
	if not arrivals.is_empty(): return
	if stage in [7,11,14] and not reinforcement_sent and remaining()<=2:
		reinforcement_sent = true
		queue_group(3,1 if stage==11 else 0,0 if stage==7 else 1)
		announcement.emit("OTRO GRUPO SE ACERCA · CUIDADO CON LOS ACCESOS")
		return
	if remaining()>0: return
	set_stage(stage+1)
	refresh_objects()
	announcement.emit(tr("PASO DESPEJADO · ") + tr(goal))
	checkpoint.emit(snapshot())

func enemy_killed(_enemy: RouteEnemy) -> void:
	kills += 1

func clamp_actor(pos: Vector2) -> Vector2:
	var left := maxf(26,arena_center-280) if stage in FIGHT_STAGES else 26.0
	var right := minf(world_length-30,arena_center+280) if stage in FIGHT_STAGES else minf(world_length-30,destination()+90)
	return Vector2(clampf(pos.x,left,right),clampf(pos.y,204,306))

func interaction_action() -> String:
	if stage in FIGHT_STAGES: return ""
	if absf(player.position.x-destination())<65 and player.position.y<275:
		return {2:"comprobar entrada",3:"activar energía",5:"comprobar conexión",8:"conectar antena",9:"enviar a la central",12:"escuchar la radio",15:"salir de la estación"}.get(stage,"")
	return ""

func interaction_hint() -> String:
	var action := interaction_action()
	if not action.is_empty(): return "E / Enter · " + tr(action)
	if stage in FIGHT_STAGES: return "Espacio / clic · atacar   R · recargar   Q · cambiar arma"
	if absf(player.position.x-destination())<65 and player.position.y>=275:
		return "Acércate al marcador para interactuar"
	return tr("Objetivo · %d m →   Tab · instrucciones") % int(absf(destination()-player.position.x)/METRE)

func interact() -> void:
	if blocked or player.dead or player.action_time>0 or absf(player.position.x-destination())>=65 or player.position.y>=275: return
	match stage:
		2: read_sequence("entrance")
		3:
			power_on = true
			refresh_objects()
			audio.cue("pickup",-15)
			start_wave(2)
		5: read_sequence("power")
		8: read_sequence("antenna")
		9: read_sequence("transmission")
		12: read_sequence("harbor")
		15:
			set_stage(16)
			blocked = true
			delivered.emit()

func read_sequence(key: String) -> void:
	pending_read = key
	blocked = true
	if key=="antenna":
		antenna_connected = true
		refresh_objects()
	document_requested.emit(BroadcastArt.dialogue(key))

func review_documents() -> void:
	if blocked or player.dead: return
	if stage in FIGHT_STAGES:
		announcement.emit("Despeja la zona para consultar las instrucciones")
		return
	if stage<3:
		announcement.emit("Las instrucciones están junto al cuadro eléctrico")
		return
	document_read.assign([0])
	pending_read = "review"
	blocked = true
	var lines := BroadcastArt.document(0)
	if files_sent:
		lines.append({"name":"CONFIRMACIÓN DE ENVÍO","document":true,"text":"Archivos recibidos.\n\nCopia guardada en la central regional de emergencias."})
	document_requested.emit(lines)

func document_closed() -> void:
	var key := pending_read
	pending_read = ""
	blocked = false
	match key:
		"entrance": set_stage(3)
		"power": set_stage(6)
		"antenna": set_stage(9)
		"transmission":
			files_sent = true # Legacy save flag: transmission attempt and radio contact completed.
			set_stage(10)
			audio.cue("delivery",-14)
		"harbor":
			harbor_confirmed = true
			set_stage(13)
	refresh_objects()
	if stage in SAFE_STAGES: checkpoint.emit(snapshot())

func set_texture(sprite: Sprite2D, index: int, size_: Vector2) -> void:
	sprite.texture = BroadcastArt.item(index)
	sprite.scale = size_/sprite.texture.get_size()
	sprite.offset.y = -sprite.texture.get_height()/2.0

func refresh_objects() -> void:
	set_texture(power_switch,1 if power_on else 0,Vector2(38,58))
	set_texture(antenna_switch,3 if antenna_connected else 2,Vector2(42,62))
	set_texture(computer,6 if files_sent else 5 if antenna_connected else 4,Vector2(44,39))
	memory.visible = not files_sent
	status_label.text = "ENVÍO INTERRUMPIDO\nLleva la memoria al rescate" if files_sent else "Conexión con la central disponible" if antenna_connected else "Antena desconectada" if power_on else "Equipo apagado"

func queue_group(hollows: int, tough: int, dogs: int) -> void:
	# Mark entry locations before spawning. Only _process advances these warnings.
	var count := hollows+tough+dogs
	for i in count:
		var side := -1 if i%2==0 else 1
		var pos := Vector2(arena_center+side*240,218+(i%3)*36)
		var warning := add_sprite(self,RouteArt.fx(7,0),pos-Vector2(0,45),Vector2(18,24))
		warning.z_index = 5
		warning.modulate = Color(1.0,0.45,0.25)
		arrivals.append({"position":pos,"tough":i>=hollows and i<hollows+tough,"dog":i>=hollows+tough,"delay":0.9+0.12*i,"warning":warning})
	if dogs>0: audio.cue("dog_growl",-13)

func advance_arrivals(delta: float) -> void:
	for entry in arrivals.duplicate():
		entry.delay -= delta
		if entry.delay>0: continue
		if player.position.distance_to(entry.position)<90:
			entry.position.x = arena_center-240 if entry.position.x>arena_center else arena_center+240
			entry.warning.position = entry.position-Vector2(0,45)
			entry.delay = 0.7
			continue
		spawn_enemy(entry.position,entry.tough,true,false,entry.dog)
		entry.warning.queue_free()
		arrivals.erase(entry)

func collect_shells() -> void:
	var p := player as ShotgunPlayer
	for key in shell_boxes:
		if shells_collected.has(key) or p.shell_reserve>=p.MAX_SHELL_RESERVE: continue
		if p.position.distance_to(shell_boxes[key].position)>20: continue
		p.shell_reserve = mini(p.MAX_SHELL_RESERVE,p.shell_reserve+4)
		shells_collected.append(key)
		shell_boxes[key].hide()
		audio.cue("pickup",-16)
		announcement.emit("+4 CARTUCHOS DE ESCOPETA")

func snapshot() -> Dictionary:
	var p := player as ShotgunPlayer
	return {"level":7,"stage":stage,"x":p.position.x,"health":p.health,"kills":kills,"damage":damage_received,"elapsed":elapsed,"collected":collected.duplicate(),"ammo_taken":ammo_taken.duplicate(),"magazine":p.magazine,"reserve":p.reserve,"shells":p.shells,"shell_reserve":p.shell_reserve,"weapon_slot":p.weapon_slot,"shells_collected":shells_collected.duplicate(),"document_read":document_read.duplicate(),"power_on":power_on,"antenna_connected":antenna_connected,"files_sent":files_sent,"harbor_confirmed":harbor_confirmed}

func restore(data: Dictionary) -> void:
	for entry in arrivals: entry.warning.queue_free()
	arrivals.clear()
	for enemy in enemies: enemy.queue_free()
	enemies.clear()
	set_stage(int(data.stage))
	player.position = clamp_actor(Vector2(float(data.x),280))
	player.health = clampi(int(data.health),1,100)
	player.magazine = clampi(int(data.get("magazine",12)),0,12)
	player.reserve = clampi(int(data.get("reserve",36)),0,36)
	kills = int(data.kills)
	damage_received = int(data.damage)
	elapsed = float(data.elapsed)
	collected = data.get("collected",[]).duplicate()
	ammo_taken = data.get("ammo_taken",[]).duplicate()
	shells_collected = data.get("shells_collected",[]).duplicate()
	document_read.clear()
	for index in data.get("document_read",[]): document_read.append(int(index))
	power_on = bool(data.get("power_on",false))
	antenna_connected = bool(data.get("antenna_connected",false))
	files_sent = bool(data.get("files_sent",false))
	harbor_confirmed = bool(data.get("harbor_confirmed",false))
	for key in medkits: medkits[key].visible = not collected.has(key)
	for key in ammo_pickups: ammo_pickups[key].sprite.visible = not ammo_taken.has(key)
	for key in shell_boxes: shell_boxes[key].visible = not shells_collected.has(key)
	var p := player as ShotgunPlayer
	p.shells = clampi(int(data.get("shells",4)),0,4)
	p.shell_reserve = clampi(int(data.get("shell_reserve",8)),0,12)
	p.weapon_slot = clampi(int(data.get("weapon_slot",1)),0,2)
	p.pistol_equipped = p.weapon_slot!=0
	p.animate("idle")
	pending_read = ""
	blocked = false
	refresh_objects()
