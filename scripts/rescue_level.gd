class_name RescueLevel
extends ContainmentLevel
## Finite rescue route. Only safe stages are saved; each dialogue has one explicit continuation.
const GENERATOR_X := 3100.0
const CROSSING_X := 4160.0
const OPEN_SECONDS := 32.0
const CROSS_SECONDS := 55.0
const CIVILIAN_Y := 169.0
const BARRIER_START := 3360.0
const COMBAT_EDGE := 212.0
var final_wave_sent := false
var last_wave_sent := false
var pending_rescue := ""
var generator: Sprite2D
var control_box: Sprite2D
var survivors: Array[AnimatedSprite2D] = []
var opening_progress := 0.0
var crossing_progress := 0.0
var reinforcements_sent := false
var crossing_stopped := false
var shells_collected: Array = []
var shell_boxes: Dictionary = {}
var generator_sound: AudioStreamPlayer2D

func configure_route() -> void:
	level_number = 5
	wave_count = 6
	world_length = 4416
	pickup_x = 1160
	crossing_x = 2160
	delivery_x = 4320
	district_two = 1920
	district_three = 3360
	route_points = [1160.0,2160.0,GENERATOR_X,CROSSING_X]
	hollow_unlocked = true

func _ready() -> void:
	super._ready()
	(player as ShotgunPlayer).acquire_shotgun()
	(player as ShotgunPlayer).weapon_slot = 1
	player.animate("idle")
	update_people()

func build_street() -> void:
	station_walls = Node2D.new()
	station_walls.z_index = -5
	add_child(station_walls)
	for i in 9:
		var variant := "workshop" if i<4 else "pumps" if i<7 else "crossing"
		var background := add_sprite(station_walls,load(RescueArt.FOLDER+variant+".png"),Vector2(i*480+288,162),Vector2(576,324))
		var shader_material := ShaderMaterial.new()
		shader_material.shader = preload("res://scripts/camp_join.gdshader")
		shader_material.set_shader_parameter("join_width",96.0/576.0 if i>0 else 0.0)
		background.material = shader_material
	for entry in [[0,1160,77,116],[1,3110,78,145],[2,4300,60,125]]:
		var sign_node := add_sprite(station_walls,RescueArt.sign(entry[0]),Vector2(entry[1],entry[2]),Vector2(entry[3],28))
		MetroArt.cutout(sign_node)

func build_props() -> void:
	# Matches the continuous concrete divider painted into the new background.
	# Collision layer 4 blocks both Nico and all enemy types, including dogs.
	var barrier := StaticBody2D.new()
	barrier.name = "CivilianLaneBarrier"
	barrier.collision_layer = 4
	barrier.collision_mask = 0
	barrier.position = Vector2((BARRIER_START+world_length)/2.0,190)
	var barrier_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(world_length-BARRIER_START,18)
	barrier_shape.shape = rectangle
	barrier.add_child(barrier_shape)
	add_child(barrier)
	generator = add_sprite(station_walls,RescueArt.prop(0),Vector2(3070,149),Vector2(74,57),true)
	control_box = add_sprite(station_walls,RescueArt.prop(2),Vector2(3138,149),Vector2(24,40),true)
	MetroArt.cutout(generator)
	MetroArt.cutout(control_box)
	for person in ["mara","worker","woman","injured"]:
		survivors.append(RescueArt.npc(person,station_walls,Vector2.ZERO,1.0))
	for x in [1330,2380,3470]:
		medkits[str(x)] = prop(2,Vector2(x,292),Vector2(23,23))
	# Extra supplies immediately before calling the civilians at x=4160.
	for x in [1390,2440,3510,4050,4090,4125]:
		var sprite := add_sprite(actors,RouteArt.weapon_item(0),Vector2(x,250 if x in [4090,4125] else 294),Vector2(25,20),true)
		ammo_pickups[str(x)] = {"sprite":sprite,"amount":12}
	for x in [2520,3960,4090,4125]:
		shell_boxes[str(x)] = containment_prop(8,Vector2(x,290),Vector2(24,23))
	generator_sound = AudioStreamPlayer2D.new()
	generator_sound.position = Vector2(GENERATOR_X,180)
	generator_sound.stream = load("res://assets/audio/drone.wav").duplicate()
	var stream := generator_sound.stream as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(stream.get_length()*stream.mix_rate)
	generator_sound.volume_db = -24
	generator_sound.max_distance = 650
	add_child(generator_sound)

func settle_supplies() -> void:
	# These authored pickups already occupy clear street space. Base safe_spawn
	# clamps to the CURRENT objective, which would move all future pistol boxes
	# back to the workshop during startup. Preserve their route positions.
	pass

func _process(delta: float) -> void:
	ambient_time += delta
	freeze_time = maxf(0,freeze_time-delta)
	if not blocked and not player.dead:
		elapsed += delta
		collect_ammo()
		collect_medkits()
		collect_shells()
		if stage==0 and player.position.x>=1010: start_wave(1)
		elif stage==3 and player.position.x>=2010: start_wave(2)
		elif stage==7:
			opening_progress = minf(OPEN_SECONDS,opening_progress+delta)
			if not reinforcements_sent and (opening_progress>=12 or remaining()==0):
				reinforcements_sent = true
				spawn_group(4,1,false,true)
				announcement.emit("LLEGAN MÁS INFECTADOS · 4")
			goal = "Abriendo compuerta · %d%% · despeja la zona" % int(opening_progress/OPEN_SECONDS*100)
			if opening_progress>=OPEN_SECONDS and remaining()==0:
				set_stage(8)
				set_machine_state()
				checkpoint.emit(snapshot())
		elif stage==10:
			# Civilians keep moving behind the divider while Nico fights alongside them.
			crossing_stopped = false
			crossing_progress = minf(CROSS_SECONDS,crossing_progress+delta)
			if not final_wave_sent and (crossing_progress>=22 or remaining()==0):
				final_wave_sent = true
				wave_index = 5
				spawn_group(6,2,false,true)
				audio.cue("wave",-15)
				announcement.emit("OLEADA 5 / 6 · SIGUE PROTEGIENDO AL GRUPO")
			elif final_wave_sent and not last_wave_sent and (crossing_progress>=40 or remaining()==0):
				last_wave_sent = true
				wave_index = 6
				spawn_group(6,2,false,true)
				audio.cue("wave",-15)
				announcement.emit("OLEADA 6 / 6 · PROTEGE LA SALIDA")
			goal = "Protege al grupo · %d%%" % int(crossing_progress/CROSS_SECONDS*100)
			if crossing_progress>=CROSS_SECONDS and last_wave_sent and remaining()==0:
				set_stage(11)
				announcement.emit("LOS TRES SUPERVIVIENTES ESTÁN A SALVO")
				checkpoint.emit(snapshot())
	update_people()
	update_camera(65.0)
	shake = move_toward(shake,0,delta*18)
	camera.offset = Vector2(sin(ambient_time*91),cos(ambient_time*83))*shake
	marker.visible = stage in [0,2,3,5,8,11]
	marker.texture = RouteArt.fx(7,int(ambient_time*7)%6)
	marker.position = Vector2(destination(),188)

func set_stage(value: int) -> void:
	stage = value
	goal = objective_text()

func start_wave(number: int) -> void:
	wave_index = number
	arena_center = route_points[number-1]
	set_stage([1,4,7,10][number-1])
	build_navigation()
	match number:
		1: spawn_group(6,1,false,true)
		2: spawn_group(7,2,true,false)
		3: spawn_group(5,1,false,true)
		4: spawn_group(8,2,true,true)
	audio.cue("wave",-15)
	announcement.emit("OLEADA %d / 6" % number)

func spawn_group(count: int, tough_count: int, dog: bool, alerted: bool) -> void:
	for i in count:
		var spawn_y := 250+(i%3)*24 if arena_center>=BARRIER_START else 218+(i%3)*36
		var enemy := spawn_enemy(Vector2(arena_center+(-220 if i%2==0 else 220),spawn_y),i<tough_count,alerted or i<3)
		if not alerted and i>=3: enemy.watch_direction = Vector2.RIGHT
	if dog:
		spawn_enemy(Vector2(arena_center+220,288),false,true,false,true)
		audio.cue("dog_growl",-14)

func enemy_killed(_enemy: RouteEnemy) -> void:
	kills += 1
	if stage in [1,4] and remaining()==0:
		set_stage(2 if stage==1 else 5)
		announcement.emit("PASO DESPEJADO · "+goal)
		checkpoint.emit(snapshot())

func clamp_actor(pos: Vector2) -> Vector2:
	var fighting := stage in [1,4,7,10]
	var left := maxf(26,arena_center-270) if fighting else 26.0
	var right := minf(world_length-30,arena_center+270) if fighting else world_length-30
	# Prevent bypassing interactions and leaving survivors behind.
	if not fighting: right = minf(right,destination()+100)
	var x := clampf(pos.x,left,right)
	# Also covers spawns, knockback and save restoration at the divider ends.
	return Vector2(x,clampf(pos.y,COMBAT_EDGE if x>=BARRIER_START-12 else 204.0,306))

func destination() -> float:
	if stage<=2: return 1160
	if stage<=4: return 2160
	if stage<=7: return GENERATOR_X
	if stage<=10: return CROSSING_X
	return delivery_x

func objective_text() -> String:
	return {0:"Llega al taller",1:"Despeja la entrada del taller",2:"Habla con Mara",3:"Llega a la estación de bombas",4:"Despeja el acceso al control",5:"Enciende el generador",6:"Escucha a Mara",7:"Sobrevive mientras se abre la compuerta",8:"Llega al paso del canal",9:"Avisa a Mara",10:"Protege el paso",11:"Reúnete con Mara",12:"Supervivientes a salvo"}.get(stage,"")

func interaction_hint() -> String:
	if stage in [1,4,7,10]: return "Espacio / clic · atacar   R · recargar   Q · cambiar arma"
	if absf(player.position.x-destination())<65:
		if stage in [2,11]: return "E / Enter · hablar con Mara"
		if stage==5: return "E / Enter · encender el generador"
		if stage==8: return "E / Enter · avisar a Mara"
	return "Objetivo · %d m →" % int(absf(destination()-player.position.x)/METRE)

func interact() -> void:
	if blocked or player.dead or player.action_time>0 or absf(player.position.x-destination())>=65: return
	match stage:
		2: talk("refuge")
		5: talk("generator")
		8: talk("crossing")
		11:
			blocked = true
			set_stage(12)
			delivered.emit()

func talk(key: String) -> void:
	pending_rescue = key
	blocked = true
	document_requested.emit(RescueArt.dialogue(key))

func document_closed() -> void:
	blocked = false
	match pending_rescue:
		"refuge":
			set_stage(3)
			checkpoint.emit(snapshot())
		"generator":
			opening_progress = 0
			reinforcements_sent = false
			start_wave(3)
			set_machine_state()
			make_noise(Vector2(GENERATOR_X,230),550,true)
		"crossing":
			crossing_progress = 0
			final_wave_sent = false
			last_wave_sent = false
			start_wave(4)
	pending_rescue = ""

func set_machine_state() -> void:
	var powered := stage>=7
	generator.texture = RescueArt.prop(1 if powered else 0)
	control_box.texture = RescueArt.prop(3 if powered else 2)
	if powered and not generator_sound.playing: generator_sound.play()
	elif not powered: generator_sound.stop()

func update_people() -> void:
	for i in survivors.size():
		var npc := survivors[i]
		npc.visible = stage<=2 or stage>=10
		var walking := stage==10 and not blocked and not player.dead and not crossing_stopped and crossing_progress<CROSS_SECONDS
		if stage<=2: npc.position = Vector2(1150+i*20,169+i%2*7)
		else:
			var progress := crossing_progress/CROSS_SECONDS if stage==10 else 1.0 if stage>=11 else 0.0
			npc.position = Vector2(lerpf(3995-i*32,4320-i*30,progress),CIVILIAN_Y)
		npc.play("walk" if walking else "talk" if i==0 and blocked else "idle")
		if blocked: npc.pause()

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
	return {"level":5,"stage":stage,"x":p.position.x,"health":p.health,"kills":kills,"damage":damage_received,"elapsed":elapsed,"collected":collected.duplicate(),"ammo_taken":ammo_taken.duplicate(),"magazine":p.magazine,"reserve":p.reserve,"shells":p.shells,"shell_reserve":p.shell_reserve,"weapon_slot":p.weapon_slot,"shells_collected":shells_collected.duplicate()}

func restore(data: Dictionary) -> void:
	for enemy in enemies: enemy.queue_free()
	enemies.clear()
	set_stage(int(data.stage))
	player.position = clamp_actor(Vector2(float(data.x),290))
	player.health = clampi(int(data.health),1,100)
	player.magazine = clampi(int(data.get("magazine",12)),0,12)
	player.reserve = clampi(int(data.get("reserve",36)),0,36)
	kills = int(data.kills)
	damage_received = int(data.damage)
	elapsed = float(data.elapsed)
	collected = data.get("collected",[]).duplicate()
	ammo_taken = data.get("ammo_taken",[]).duplicate()
	shells_collected = data.get("shells_collected",[]).duplicate()
	for key in medkits: medkits[key].visible = not collected.has(key)
	for key in ammo_pickups: ammo_pickups[key].sprite.visible = not ammo_taken.has(key)
	for key in shell_boxes: shell_boxes[key].visible = not shells_collected.has(key)
	var p := player as ShotgunPlayer
	p.shells = clampi(int(data.get("shells",4)),0,4)
	p.shell_reserve = clampi(int(data.get("shell_reserve",8)),0,12)
	p.weapon_slot = clampi(int(data.get("weapon_slot",1)),0,2)
	p.pistol_equipped = p.weapon_slot!=0
	p.animate("idle")
	opening_progress = OPEN_SECONDS if stage>=8 else 0.0
	crossing_progress = CROSS_SECONDS if stage>=11 else 0.0
	final_wave_sent = stage>=11
	last_wave_sent = stage>=11
	pending_rescue = ""
	blocked = false
	set_machine_state()
	update_people()

func _exit_tree() -> void:
	if is_instance_valid(generator_sound):
		generator_sound.stop()
		generator_sound.stream = null
