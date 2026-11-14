class_name DistributionLevel
extends ContainmentLevel
## Six authored encounters. Documents advance explicit states; no timed defense.
const POINTS := [650.0,1610.0,2570.0,3530.0,4490.0,5450.0]
const SAFE_STAGES := [0,2,3,6,8,9,11,12,13,15,17]
const FIGHT_STAGES := [1,4,7,10,14,16]
var access_card := false
var records_copied := false
var phone_finished := false
var pending_read := ""
var reinforcement_sent := false
var arrivals: Array[Dictionary] = []
var shell_boxes: Dictionary = {}
var shells_collected: Array = []
var card_sprite: Sprite2D
var card_reader: Sprite2D
var sample_case: Sprite2D
var desk_phone: Sprite2D
var computer: Sprite2D
var memory: Sprite2D
var beacon: Sprite2D
var gate_art: Sprite2D
var obstacle_bodies: Array[StaticBody2D] = []
var alarm_player: AudioStreamPlayer
const ALARM_EXIT_X := 4900.0

func sync_alarm() -> void:
	# Stay audible after combat until Nico passes the control-room exit.
	var active := stage in [14,15] and is_instance_valid(player) and not player.dead and player.position.x < ALARM_EXIT_X
	if active:
		if not is_instance_valid(alarm_player):
			alarm_player = AudioStreamPlayer.new()
			alarm_player.process_mode = Node.PROCESS_MODE_PAUSABLE
			var stream := load("res://assets/audio/alarm.ogg").duplicate() as AudioStreamOggVorbis
			stream.loop = true
			stream.loop_offset = 0.0
			alarm_player.stream = stream
			alarm_player.volume_db = -16.0
			add_child(alarm_player)
		if not alarm_player.playing: alarm_player.play()
	elif is_instance_valid(alarm_player):
		alarm_player.stop()

func _exit_tree() -> void:
	if is_instance_valid(alarm_player):
		alarm_player.stop()
		alarm_player.stream = null

func configure_route() -> void:
	level_number = 6
	wave_count = 6
	world_length = 5856
	pickup_x = POINTS[0]
	crossing_x = POINTS[2]
	delivery_x = 5660
	district_two = 960
	district_three = 1920
	route_points.assign(POINTS)
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
	var variants := ["dock","sorting","cold","office","control","exit"]
	for i in 12:
		var bg := add_sprite(station_walls,load(DistributionArt.FOLDER+variants[int(i/2.0)]+".png"),Vector2(i*480+288,162),Vector2(576,324))
		var blend := ShaderMaterial.new()
		blend.shader = preload("res://scripts/camp_join.gdshader")
		blend.set_shader_parameter("join_width",96.0/576.0 if i>0 else 0.0)
		bg.material = blend
	for i in 6:
		var plate := add_sprite(station_walls,DistributionArt.item(3,"fixtures"),Vector2(POINTS[i],72),Vector2(142,28))
		MetroArt.cutout(plate)
		var name_ := Label.new()
		name_.text = ["RECEPCIÓN","ALMACÉN","CONSERVACIÓN","ARCHIVOS","CONTROL","SALIDA"][i]
		name_.position = Vector2(POINTS[i]-68,64)
		name_.size = Vector2(136,20)
		name_.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_.add_theme_font_size_override("font_size",11)
		name_.add_theme_color_override("font_color",Color("e3d5b9"))
		station_walls.add_child(name_)

func item(index: int, pos: Vector2, size_: Vector2, footprint := Vector2.ZERO, sheet := "interactives") -> Sprite2D:
	var sprite := add_sprite(actors,DistributionArt.item(index,sheet),pos,size_,true)
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
	card_sprite = item(0,Vector2(650,224),Vector2(16,24))
	card_reader = item(1,Vector2(1720,188),Vector2(22,36))
	sample_case = item(4,Vector2(2570,215),Vector2(70,48),Vector2(62,16))
	item(3,Vector2(1610,221),Vector2(24,24))
	item(0,Vector2(3565,226),Vector2(112,50),Vector2(102,20),"desk")
	var order := item(3,Vector2(3535,188),Vector2(24,24))
	order.z_index = 1
	desk_phone = item(6,Vector2(3600,188),Vector2(32,24))
	desk_phone.z_index = 1
	item(0,Vector2(4500,222),Vector2(94,50),Vector2(84,20),"desk")
	computer = item(8,Vector2(4490,184),Vector2(49,42))
	computer.z_index = 1
	memory = item(10,Vector2(4532,183),Vector2(14,14))
	memory.z_index = 1
	beacon = item(11,Vector2(4650,126),Vector2(18,28))
	gate_art = item(0,Vector2(4805,148),Vector2(166,144),Vector2.ZERO,"fixtures")
	for pos in [Vector2(1450,239),Vector2(1760,239),Vector2(2380,229),Vector2(2740,285),Vector2(4300,229),Vector2(4660,285),Vector2(5290,229)]:
		item(2,pos,Vector2(56,40),Vector2(48,22),"fixtures")
	for x in [900,2860,4820]: medkits[str(x)] = prop(2,Vector2(x,286),Vector2(23,23))
	for x in [990,2080,3030,4370,4410,5170]:
		var box := add_sprite(actors,RouteArt.weapon_item(0),Vector2(x,282),Vector2(25,20),true)
		ammo_pickups[str(x)] = {"sprite":box,"amount":12}
	for x in [2150,4370,4410,5200]:
		shell_boxes[str(x)] = containment_prop(8,Vector2(x,246),Vector2(24,23))

func settle_supplies() -> void:
	# Authored pickups never use safe_spawn: its current-objective clamp moves future loot.
	pass

func _process(delta: float) -> void:
	sync_alarm()
	ambient_time += delta
	freeze_time = maxf(0,freeze_time-delta)
	if not blocked and not player.dead:
		elapsed += delta
		collect_ammo()
		collect_medkits()
		collect_shells()
		advance_arrivals(delta)
		if stage in [0,3,6,9,15] and player.position.x>=destination()-160:
			start_wave({0:1,3:2,6:3,9:4,15:6}[stage])
		if stage in FIGHT_STAGES: advance_encounter()
		elif stage==5 and threat_count()>0: set_stage(4)
		var district := clampi(int(player.position.x/960),0,5)
		if district!=last_district:
			last_district = district
			audio.ambience.volume_db = -17 if district in [0,5] else -65
			announcement.emit(["MUELLE DE RECEPCIÓN","ALMACÉN DE CLASIFICACIÓN","CÁMARAS DE CONSERVACIÓN","ARCHIVO DE ENVÍOS","CONTROL DE DESPACHOS","PATIO DE SALIDA"][district])
	update_camera(65.0)
	shake = move_toward(shake,0,delta*18)
	camera.offset = Vector2(sin(ambient_time*91),cos(ambient_time*83))*shake
	marker.visible = stage not in FIGHT_STAGES and stage<18
	marker.texture = RouteArt.fx(7,int(ambient_time*7)%6)
	marker.position = Vector2(destination(),182)
	beacon.modulate = Color(1.8,0.5,0.4) if stage==14 and int(ambient_time*5)%2==0 else Color.WHITE

func set_stage(value: int) -> void:
	stage = value
	goal = objective_text()
	sync_alarm()

func destination() -> float:
	if stage<=2: return POINTS[0]
	if stage<=5: return POINTS[1]
	if stage<=8: return POINTS[2]
	if stage<=11: return POINTS[3]
	if stage==12: return 3600
	if stage<=14: return POINTS[4]
	if stage<=16: return POINTS[5]
	return delivery_x

func objective_text() -> String:
	return ["Llega al muelle de recepción","Despeja la caseta","Recoge la tarjeta de acceso","Entra al almacén","Elimina a los vigilantes; evita el ruido","Lee el registro de entregas","Entra en conservación","Despeja las cámaras","Lee el informe de Continuidad","Busca la oficina de archivos","Despeja la entrada de archivos","Lee la orden de traslado","Llama al Jefe desde el teléfono","Copia los registros en el control","Sal del control: elimina a los infectados","Cruza el patio de salida","Despeja la salida","Sal con las pruebas","Registros recuperados"][clampi(stage,0,18)]

func start_wave(number: int) -> void:
	wave_index = number
	arena_center = POINTS[number-1]
	reinforcement_sent = false
	set_stage([1,4,7,10,14,16][number-1])
	build_navigation()
	match number:
		1: queue_group(5,1,0)
		2:
			queue_group(1,2,1)
			for i in 4:
				var enemy := spawn_enemy(Vector2(POINTS[1]-105+i*62,214),false,false)
				enemy.set_meta("optional",true)
				enemy.watch_direction = Vector2.UP
		3: queue_group(2,2,0)
		4: queue_group(4,1,0)
		5: queue_group(3,2,0)
		6: queue_group(4,1,1)
	audio.cue("wave",-15)
	announcement.emit(tr("ENCUENTRO %d / 6 · ATENCIÓN A LOS ACCESOS") % number)

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

func threat_count() -> int:
	var count := 0
	for enemy in enemies:
		if not enemy.dead and (not enemy.get_meta("optional",false) or enemy.awareness>0): count+=1
	return count

func advance_encounter() -> void:
	if not arrivals.is_empty(): return
	if stage==7 and not reinforcement_sent and remaining()<=2:
		reinforcement_sent = true
		queue_group(4,0,0)
		announcement.emit("SE ABRE UN ACCESO · LLEGAN MÁS INFECTADOS")
		return
	if stage==10 and not reinforcement_sent and remaining()==0:
		reinforcement_sent = true
		queue_group(3,1,1)
		announcement.emit("MÁS INFECTADOS EN LA ENTRADA DE ARCHIVOS")
		return
	if stage==14 and not reinforcement_sent and remaining()<=2:
		reinforcement_sent = true
		queue_group(4,1,0)
		announcement.emit("OTRO GRUPO LLEGA AL CONTROL")
		return
	var clear := threat_count()==0 if stage==4 else remaining()==0
	if not clear: return
	set_stage(stage+1)
	refresh_objects()
	announcement.emit(tr("PASO DESPEJADO · ") + tr(goal))
	if stage in SAFE_STAGES: checkpoint.emit(snapshot())

func enemy_killed(_enemy: RouteEnemy) -> void:
	kills += 1

func clamp_actor(pos: Vector2) -> Vector2:
	var fight := stage in FIGHT_STAGES or stage==5
	var left := maxf(26,arena_center-280) if fight else 26.0
	var right := minf(world_length-30,arena_center+280) if fight else minf(world_length-30,destination()+90)
	return Vector2(clampf(pos.x,left,right),clampf(pos.y,204,306))

func interaction_action() -> String:
	if absf(player.position.x-destination())<65:
		match stage:
			2: return "recoger tarjeta"
			5,8,11: return "leer documento"
			12: return "llamar al Jefe"
			13: return "copiar registros"
			17: return "salir con las pruebas"
	return ""

func interaction_hint() -> String:
	var action := interaction_action()
	if not action.is_empty(): return "E / Enter · " + tr(action)
	if stage in FIGHT_STAGES: return "Espacio / clic · atacar   R · recargar   Q · cambiar arma"
	return tr("Objetivo · %d m →   Tab · documentos") % int(absf(destination()-player.position.x)/METRE)

func interact() -> void:
	if blocked or player.dead or player.action_time>0 or absf(player.position.x-destination())>=65: return
	match stage:
		2:
			access_card = true
			set_stage(3)
			refresh_objects()
			audio.cue("pickup",-15)
			checkpoint.emit(snapshot())
		5:
			if threat_count()>0: return
			read_sequence("registry",0)
		8: read_sequence("report",1)
		11: read_sequence("order",2)
		12: read_sequence("phone")
		13: read_sequence("copy",3)
		17:
			set_stage(18)
			blocked = true
			delivered.emit()

func read_sequence(key: String, doc: int = -1) -> void:
	pending_read = key
	blocked = true
	var lines: Array = DistributionArt.document(doc) if doc>=0 else []
	if key!="order": lines.append_array(DistributionArt.dialogue(key))
	if key=="report": set_texture(sample_case,5,Vector2(70,48))
	if key=="phone": set_texture(desk_phone,7,Vector2(32,24))
	document_requested.emit(lines)

func review_documents() -> void:
	if blocked or player.dead: return
	if stage in FIGHT_STAGES:
		announcement.emit("Despeja la zona para consultar los documentos")
		return
	var lines: Array = []
	for index in document_read: lines.append_array(DistributionArt.document(index))
	if lines.is_empty():
		announcement.emit("Todavía no has recogido documentos")
		return
	pending_read = "review"
	blocked = true
	document_requested.emit(lines)

func document_closed() -> void:
	var key := pending_read
	pending_read = ""
	blocked = false
	match key:
		"registry":
			if not document_read.has(0): document_read.append(0)
			# Only untouched, dormant optional enemies are left behind; no fake kills.
			for enemy in enemies.duplicate():
				if not enemy.dead and enemy.get_meta("optional",false):
					enemies.erase(enemy)
					enemy.queue_free()
			set_stage(6)
		"report":
			if not document_read.has(1): document_read.append(1)
			set_stage(9)
		"order":
			if not document_read.has(2): document_read.append(2)
			set_stage(12)
		"phone":
			phone_finished = true
			set_stage(13)
		"copy":
			if not document_read.has(3): document_read.append(3)
			records_copied = true
			audio.cue("delivery",-14)
			start_wave(5)
	refresh_objects()
	if key!="review" and stage in SAFE_STAGES: checkpoint.emit(snapshot())

func set_texture(sprite: Sprite2D, index: int, size_: Vector2, sheet := "interactives") -> void:
	sprite.texture = DistributionArt.item(index,sheet)
	sprite.scale = size_/sprite.texture.get_size()
	sprite.offset.y = -sprite.texture.get_height()/2.0

func refresh_objects() -> void:
	card_sprite.visible = not access_card
	set_texture(card_reader,2 if access_card else 1,Vector2(22,36))
	set_texture(sample_case,5 if document_read.has(1) else 4,Vector2(70,48))
	set_texture(desk_phone,7 if phone_finished else 6,Vector2(32,24))
	set_texture(computer,9 if records_copied else 8,Vector2(49,42))
	memory.visible = not records_copied
	set_texture(gate_art,1 if stage>=15 else 0,Vector2(166,144),"fixtures")

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
	return {"level":6,"stage":stage,"x":p.position.x,"health":p.health,"kills":kills,"damage":damage_received,"elapsed":elapsed,"collected":collected.duplicate(),"ammo_taken":ammo_taken.duplicate(),"magazine":p.magazine,"reserve":p.reserve,"shells":p.shells,"shell_reserve":p.shell_reserve,"weapon_slot":p.weapon_slot,"shells_collected":shells_collected.duplicate(),"document_read":document_read.duplicate(),"access_card":access_card,"records_copied":records_copied,"phone_finished":phone_finished}

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
	access_card = bool(data.get("access_card",stage>=3))
	phone_finished = bool(data.get("phone_finished",stage>=13))
	records_copied = bool(data.get("records_copied",stage>=15))
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
