class_name HarborLevel
extends BroadcastLevel
## Eight-level finale. Progress is saved only outside combat; all reinforcements are finite.
const HARBOR_SAFE := [0,2,4,5,7,8,10,11,12,14]
const HARBOR_FIGHTS := [1,3,6,9,13]
const STOPS := [650.0,1610.0,2570.0,3530.0,4490.0,5450.0]
var service_gate: Sprite2D
var relay_ammo_marker: Sprite2D
var manifest_prop: Sprite2D
var gate_target: StaticBody2D
var divider_bodies: Array[StaticBody2D] = []
var gate_opening := false
var gate_progress := 0.0
const CONTROL_POS := Vector2(2780,207)
const CHIEF_ACCESS_LIMIT := 2964.0
var cargo_gate: Sprite2D
var gate_control: Sprite2D
var crate: Sprite2D
var gangway: Sprite2D
var chief_guards: Array[AnimatedSprite2D] = []
var chief_block: StaticBody2D
var boss_npc: AnimatedSprite2D
var arrest_scene: AnimatedSprite2D
var arrest_officer: AnimatedSprite2D
var civilians: Array[AnimatedSprite2D] = []
const CIVILIAN_GATE_PATH := [Vector2(2790,222),Vector2(2840,222),Vector2(2898,222),Vector2(2940,205)]
var civilian_gate_steps: Array[int] = [0,0,0,0]
var guard_intro_time := -1.0
var guard_shot_round := 0
var guards_down: Array[bool] = [false,false]
var cargo_block: StaticBody2D
var anchored: AnchoredEnemy
var escort_distance := 0.0
var boss_batches := 0
var escape_time := 0.0
var gate_open := false
var chief_saved := false # Legacy checkpoint flag: blockade broken (story revision 2).
var boss_defeated := false
func configure_route() -> void:
	level_number = 8
	wave_count = 5
	world_length = 5952
	pickup_x = STOPS[0]
	delivery_x = 5670
	route_points.assign([STOPS[0],STOPS[1],STOPS[2],STOPS[3],STOPS[4]])
	hollow_unlocked = true
func build_street() -> void:
	station_walls = Node2D.new()
	station_walls.z_index = -5
	add_child(station_walls)
	# Extend the final terminal panorama to the camera boundary instead of
	# overlaying another terminal whose building would cover the boarding ramp.
	for i in 12:
		var name_: String = ["access","cargo","control","crossing","arena","terminal"][mini(5,int(i/2.0))]
		var width := world_length-i*480 if i==11 else 576.0
		var texture: Texture2D = load(HarborArt.FOLDER+name_+".png")
		if i>=10:
			texture = load(HarborArt.FOLDER+"terminal_clean.png")
			if i==10:
				# Only the open quay continues from the arena; the ship appears once.
				var quay := AtlasTexture.new()
				quay.atlas = texture
				quay.region = Rect2(0,0,int(texture.get_width()*0.4),texture.get_height())
				quay.filter_clip = true
				texture = quay
		var bg := add_sprite(station_walls,texture,Vector2(i*480+width/2.0,162),Vector2(width,324))
		var blend := ShaderMaterial.new()
		blend.shader = preload("res://scripts/harbor_join.gdshader")
		if i==10:
			blend.set_shader_parameter("atlas_width",float((texture as AtlasTexture).region.size.x)/(texture as AtlasTexture).atlas.get_width())
		if i>=10: blend.set_shader_parameter("color_balance",Vector3(0.78,0.90,1.0))
		blend.set_shader_parameter("join_width",96.0/width if i>0 else 0.0)
		bg.material = blend
func harbor_item(index: int, pos: Vector2, size_: Vector2) -> Sprite2D:
	var s := add_sprite(actors,HarborArt.item(index),pos,size_,true)
	MetroArt.cutout(s)
	return s
func solid(pos: Vector2, size_: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 4
	body.collision_mask = 0
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size_
	col.shape = shape
	body.add_child(col)
	add_child(body)
	return body
func build_props() -> void:
	relay_ammo_marker = add_sprite(self,RouteArt.fx(7,0),Vector2(2810,255),Vector2(18,18))
	relay_ammo_marker.z_index = 5
	var arrow_material := ShaderMaterial.new()
	arrow_material.shader = preload("res://scripts/ammo_marker_red.gdshader")
	relay_ammo_marker.material = arrow_material
	relay_ammo_marker.hide()
	manifest_prop = access_item(3,Vector2(1610,252),Vector2(44,40))
	gate_control = access_item(1,CONTROL_POS,Vector2(20,48))
	cargo_gate = access_item(0,Vector2(2830,236),Vector2(96,81),true)
	# Dedicated wide open gate: rear post joins cargo, front post reaches the road edge.
	# Source ground anchors (150,450) and (1430,905) keep normal-sized posts.
	service_gate = Sprite2D.new()
	service_gate.texture = preload("res://assets/harbor/access_revision/service_gate_wide_open.png")
	service_gate.centered = false
	service_gate.offset = Vector2(-1430,-905)
	# Rear foot sits in the service lane (y=250), in front of the dividing fence.
	# Only the floor rail changes slope; upright posts keep their original proportions.
	service_gate.scale = Vector2(0.16,59.0/440.0)
	service_gate.position = Vector2(3071,309)
	actors.add_child(service_gate)
	MetroArt.cutout(service_gate)
	# Rail belongs to the ground; posts retain independent foot-based depth sorting.
	service_gate.z_index = -1
	var rail_material := service_gate.material as ShaderMaterial
	rail_material.set_shader_parameter("excluded_count",2)
	rail_material.set_shader_parameter("excluded_rects",PackedVector4Array([
		Vector4(0,0,290.0/1536.0,1),Vector4(1350.0/1536.0,0,1,1)]))
	service_post(Rect2(40,145,250,330),Vector2(170,465))
	service_post(Rect2(1350,580,155,355),Vector2(1430,905))
	solid(Vector2(2870,253),Vector2(38,24))
	solid(Vector2(3071,306),Vector2(26,22))
	cargo_block = solid(Vector2(2830,209),Vector2(18,54))
	gate_target = solid(CONTROL_POS,Vector2(20,22))
	gate_target.collision_layer = 8 # Shootable relay; actors cannot interact to open it.
	boss_npc = HarborArt.npc(actors,Vector2(2890,202))
	# Continuous mesh divides cargo and service lanes; bullets can pass through it.
	for x in range(2420,3960,170):
		var fence := access_item(0,Vector2(x,244),Vector2(174,50))
		if x==2420:
			# Start at the third post, beside the cargo building; keep later panels aligned.
			var section := fence.texture as AtlasTexture
			section.region.position.x += 630
			section.region.size.x -= 630
			fence.position.x += 54.81
	divider_bodies.append(solid(Vector2(3207,242),Vector2(1526,10)))
	crate = harbor_item(4,Vector2(4370,198),Vector2(156,100))
	gangway = harbor_item(6,Vector2(4550,189),Vector2(145,67))
	chief_guards.append(CorporateGuardArt.npc(actors,Vector2(4650,218),0))
	chief_guards.append(CorporateGuardArt.npc(actors,Vector2(4730,226),1))
	chief_block = solid(Vector2(4640,258),Vector2(18,104))
	for i in 4:
		var person: String = ["mara","worker","woman","injured"][i]
		civilians.append(RescueArt.npc(person,actors,Vector2(2730-i*34,205)))
		civilians[i].hide()
	# The continuous fence also protects the civilian crossing; no concrete roadblocks.
	for x in [800,1800,2860,3970,4220,4300]:
		ammo_pickups[str(x)] = {"sprite":add_sprite(actors,RouteArt.weapon_item(0),Vector2(x,286),Vector2(25,20),true),"amount":12}
	for x in [840,1840,2900,4010,4260,4340]:
		shell_boxes[str(x)] = containment_prop(8,Vector2(x,286),Vector2(24,23))
	for x in [1910,4060,4370]: medkits[str(x)] = prop(2,Vector2(x,295),Vector2(23,23))
	arrest_officer = PoliceArrestArt.create(actors,Vector2(5480,205),false)
	PoliceArrestArt.create(actors,Vector2(5515,202),false)
	arrest_scene = PoliceArrestArt.create(actors,Vector2(5480,205),true)
	arrest_scene.hide()
	arrest_scene.stop()
	for entry in [[2570,"VÉRTICE · CARGA"],[3530,"TERMINAL DE PASAJEROS →"],[5570,"BARCO DE RESCATE"]]:
		var sign_node := Label.new()
		sign_node.text = entry[1]
		sign_node.position = Vector2(float(entry[0])-110,111)
		sign_node.size = Vector2(220,22)
		sign_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sign_node.add_theme_font_size_override("font_size",12)
		sign_node.add_theme_color_override("font_shadow_color",Color.BLACK)
		sign_node.add_theme_constant_override("shadow_offset_x",1)
		sign_node.add_theme_constant_override("shadow_offset_y",1)
		add_child(sign_node)
func service_post(region: Rect2, ground_anchor: Vector2) -> void:
	var post := Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = service_gate.texture
	atlas.region = region
	atlas.filter_clip = true
	post.texture = atlas
	post.centered = false
	post.offset = region.position-ground_anchor
	post.scale = Vector2.ONE*0.16
	post.position = service_gate.position+(ground_anchor-Vector2(1430,905))*service_gate.scale
	actors.add_child(post)
	MetroArt.cutout(post)
func access_item(index: int, pos: Vector2, size_: Vector2, is_gate: bool = false) -> Sprite2D:
	var access_sprite := Sprite2D.new()
	access_sprite.position = pos
	actors.add_child(access_sprite)
	HarborAccessArt.apply(access_sprite,index,size_,is_gate)
	return access_sprite
func refresh_objects() -> void:
	if not is_instance_valid(cargo_gate): return
	refresh_crossing_supplies()
	if stage==7 and not ammo_pickups.has("relay"):
		ammo_pickups["relay"] = {"sprite":add_sprite(actors,RouteArt.weapon_item(0),Vector2(2810,288),Vector2(25,20),true),"amount":12}
		ammo_pickups["relay"].sprite.visible = not ammo_taken.has("relay")
	HarborAccessArt.apply(cargo_gate,5 if gate_open else mini(5,int(gate_progress*6)),Vector2(96,81),true)
	HarborAccessArt.apply(gate_control,2 if gate_open or gate_opening else 1,Vector2(20,48))
	cargo_block.collision_layer = 0 if gate_open else 4
	set_harbor_texture(crate,5 if stage>=12 else 4,Vector2(156,100))
	set_harbor_texture(gangway,7 if stage>=12 else 6,Vector2(145,67))
	chief_block.collision_layer = 4 if stage in [10,11] else 0
	boss_npc.visible = stage==5 or stage>=10
	if stage<10:
		boss_npc.position = Vector2(2890,202)
		boss_npc.flip_h = false
		boss_npc.play("idle")
	elif stage<=11:
		boss_npc.position = Vector2(4690,218)
		boss_npc.flip_h = true
		boss_npc.play("idle")
	for i in chief_guards.size():
		var guard := chief_guards[i]
		guard.visible = stage>=10
		if stage<=11:
			guard.position = Vector2(4650+i*80,218+i*8)
			guard.play("idle")
		elif guards_down[i]:
			guard.play("death")
			guard.set_frame_and_progress(guard.sprite_frames.get_frame_count("death")-1,0)
			guard.pause()
	for i in civilians.size():
		civilians[i].visible = stage>=5
		if stage<=7:
			civilian_gate_steps[i] = 0
			civilians[i].position = Vector2(2730-i*34,205)
			civilians[i].play("idle")
	update_arrest()
func advance_survivors(delta: float) -> void:
	if stage<8: return
	for i in civilians.size():
		# Cross the physical opening at y=222, between the cargo gate's posts.
		if stage<12 and civilian_gate_steps[i]<CIVILIAN_GATE_PATH.size():
			var waypoint: Vector2 = CIVILIAN_GATE_PATH[civilian_gate_steps[i]]
			civilians[i].position = civilians[i].position.move_toward(waypoint,delta*64)
			civilians[i].play("walk")
			if civilians[i].position.distance_to(waypoint)<0.5: civilian_gate_steps[i] += 1
			continue
		var survivor_target: Vector2
		var speed_ := 64.0
		if stage==8: survivor_target = Vector2(minf(3270-i*32,player.position.x+130-i*28),205)
		elif stage==9: survivor_target = Vector2(3910-i*32,205)
		elif stage in [10,11]:
			var progress := clampf((civilians[i].position.x-(3910-i*32))/float(4480-i*28-(3910-i*32)),0.0,1.0)
			survivor_target = Vector2(minf(4480-i*28,player.position.x+130-i*28),lerpf(205,218,progress))
			# Wait in place if Nico is behind; descend gradually while walking onward.
			if survivor_target.x<=civilians[i].position.x: survivor_target.y = civilians[i].position.y
		else:
			survivor_target = Vector2(5530+i*25,211)
			speed_ = 110.0
		# Never rewind the group if Nico walks back for supplies.
		survivor_target.x = maxf(survivor_target.x,civilians[i].position.x)
		civilians[i].position = civilians[i].position.move_toward(survivor_target,speed_*delta)
		civilians[i].play("walk" if civilians[i].position.distance_to(survivor_target)>1 else "idle")
	if stage>=12:
		boss_npc.flip_h = false
		boss_npc.position = boss_npc.position.move_toward(Vector2(5480,205),delta*100)
		boss_npc.play("walk" if boss_npc.position.x<5479 else "idle")
	update_arrest()
func update_arrest() -> void:
	var detained := stage>=12 and boss_npc.position.x>=5479
	arrest_officer.visible = not detained
	if detained:
		boss_npc.hide()
		if not arrest_scene.visible:
			arrest_scene.show()
			arrest_scene.play("arrest")
	else:
		arrest_scene.hide()
		arrest_scene.stop()
func survivors_at_blockade() -> bool:
	for i in civilians.size():
		if civilians[i].position.distance_to(Vector2(4480-i*28,218))>3: return false
	return true
func survivors_at_rescue() -> bool:
	for i in civilians.size():
		if civilians[i].position.distance_to(Vector2(5530+i*25,211))>3: return false
	return true
func refresh_crossing_supplies() -> void:
	# Restock along Nico's lane, after opening the gate and before the next encounter.
	var key := "crossing_supplies"
	var extra_shells := "crossing_extra_shells"
	if stage<8:
		if shell_boxes.has(extra_shells):
			shell_boxes[extra_shells].queue_free()
			shell_boxes.erase(extra_shells)
		if ammo_pickups.has(key):
			ammo_pickups[key].sprite.queue_free()
			ammo_pickups.erase(key)
		for items in [shell_boxes,medkits]:
			if items.has(key):
				items[key].queue_free()
				items.erase(key)
		return
	if not ammo_pickups.has(key):
		ammo_pickups[key] = {"sprite":add_sprite(actors,RouteArt.weapon_item(0),Vector2(3140,284),Vector2(25,20),true),"amount":12}
	if not shell_boxes.has(key): shell_boxes[key] = containment_prop(8,Vector2(3210,284),Vector2(24,23))
	if not shell_boxes.has(extra_shells): shell_boxes[extra_shells] = containment_prop(8,Vector2(3330,284),Vector2(24,23))
	if not medkits.has(key): medkits[key] = prop(2,Vector2(3280,284),Vector2(23,23))
	ammo_pickups[key].sprite.visible = not ammo_taken.has(key)
	shell_boxes[key].visible = not shells_collected.has(key)
	shell_boxes[extra_shells].visible = not shells_collected.has(extra_shells)
	medkits[key].visible = not collected.has(key)
func set_harbor_texture(s: Sprite2D, index: int, size_: Vector2) -> void:
	s.texture = HarborArt.item(index)
	s.scale = size_/s.texture.get_size()
	s.offset.y = -int(s.texture.get_height()/2.0)
func destination() -> float:
	if stage<=2: return STOPS[0] if stage<2 else STOPS[1]
	if stage<=4: return STOPS[1]
	if stage==5: return 2864
	if stage==7: return CONTROL_POS.x
	if stage<=7: return STOPS[2]
	if stage<=9: return STOPS[3]
	if stage<=12: return 4510
	if stage==13: return STOPS[4]
	return delivery_x
func objective_text() -> String:
	return ["Llega al puerto","Despeja el acceso","Cruza el patio de carga","Despeja el patio","Lee la orden de embarque","Habla con el Jefe","Despeja el control de la reja","Dispara al interruptor de la reja","Llega al paso protegido","Protege el cruce de los civiles","Acompaña al grupo hasta el muelle","El Jefe bloquea el paso","Protege la huida del grupo","Derrota al Anclado","Reúnete con Mara y embarca","La última ruta terminó"][clampi(stage,0,15)]
func clamp_actor(pos: Vector2) -> Vector2:
	var left := maxf(26,arena_center-280) if stage in HARBOR_FIGHTS else 26.0
	var right := minf(world_length-30,arena_center+280) if stage in HARBOR_FIGHTS else minf(world_length-30,destination()+100)
	# Talking, fighting and shooting the relay share one forward boundary.
	if stage in [5,6,7]: right = CHIEF_ACCESS_LIMIT
	if stage in [10,11,12]: right = 4570
	var top := 248.0 if pos.x>2444 and pos.x<3970 else 204.0
	return Vector2(clampf(pos.x,left,right),clampf(pos.y,top,306))
func _process(delta: float) -> void:
	ambient_time += delta
	freeze_time = maxf(0,freeze_time-delta)
	if not blocked and not player.dead:
		elapsed += delta
		collect_ammo()
		collect_shells()
		collect_medkits()
		advance_arrivals(delta)
		if stage in [0,2,8] and player.position.x>=destination()-160:
			start_wave({0:1,2:2,8:4}[stage])
		if stage in [1,3,6,9]: advance_encounter()
		advance_gate(delta)
		advance_survivors(delta)
		if stage==10 and player.position.x>=4485 and survivors_at_blockade():
			set_stage(11)
			refresh_objects()
			checkpoint.emit(snapshot())
			read_sequence("standoff")
		elif stage==11: read_sequence("standoff")
		elif stage==12: read_sequence("breakout")
		if stage==13:
			advance_guard_last_stand(delta)
			advance_boss()
	update_camera(65.0)
	shake = move_toward(shake,0,delta*18)
	camera.offset = Vector2(sin(ambient_time*91),cos(ambient_time*83))*shake
	marker.visible = stage not in HARBOR_FIGHTS and stage<15
	marker.texture = RouteArt.fx(7,int(ambient_time*7)%6)
	marker.position = Vector2(destination(),210 if stage==5 else 184)
	# Keep the ammo cue attached to the actual pickup, including after a reload.
	relay_ammo_marker.visible = ammo_pickups.has("relay") and not ammo_taken.has("relay") and stage<15
	if relay_ammo_marker.visible:
		relay_ammo_marker.position = ammo_pickups["relay"].sprite.position+Vector2(0,-33)
		relay_ammo_marker.texture = RouteArt.fx(7,int(ambient_time*7)%6)
	for c in civilians:
		c.speed_scale = 0 if blocked else 1
	boss_npc.speed_scale = 0 if blocked else 1
	for guard in chief_guards: guard.speed_scale = 0 if blocked else 1
	arrest_scene.speed_scale = 0 if blocked else 1
	for drop in rain.get_children():
		if not blocked: drop.position += Vector2(-28,150)*delta
		if drop.position.y > get_viewport_rect().size.y + 20: drop.position = Vector2(rng.randf_range(0, get_viewport_rect().size.x),-20)
func start_wave(number: int) -> void:
	if stage in HARBOR_FIGHTS: return
	wave_index = number
	arena_center = route_points[number-1]
	if number==3: arena_center = CHIEF_ACCESS_LIMIT-280
	reinforcement_sent = false
	set_stage([1,3,6,9][number-1])
	if number==4: escort_distance = 0
	build_navigation()
	match number:
		1: queue_group(5,2,0)
		2: queue_group(5,2,1)
		3: queue_group(5,2,1)
		4: queue_group(5,2,1)
	audio.cue("wave",-13)
	announcement.emit("ENCUENTRO %d / 4" % number)
func advance_encounter() -> void:
	if not arrivals.is_empty(): return
	if stage in [6,9] and not reinforcement_sent and remaining()<=2:
		reinforcement_sent = true
		queue_group(4,1,0)
		announcement.emit("MÁS INFECTADOS POR LOS ACCESOS")
		return
	if remaining()>0: return
	set_stage({1:2,3:4,6:7,9:10}[stage])
	# Survivors continue on foot after combat; refresh never teleports them.
	refresh_objects()
	checkpoint.emit(snapshot())
func queue_group(hollows: int, tough: int, dogs: int) -> void:
	var first_new := arrivals.size()
	super.queue_group(hollows,tough,dogs)
	for i in range(first_new,arrivals.size()):
		var entry: Dictionary = arrivals[i]
		if stage==6:
			# Entrances stay beyond both player boundaries, including reinforcements.
			var entry_x := arena_center-440 if (i-first_new)%2==0 else CHIEF_ACCESS_LIMIT+160
			entry.position = Vector2(entry_x,270+((i-first_new)%2)*20)
		elif stage==9:
			entry.position = Vector2(arena_center+(-440 if (i-first_new)%2==0 else 440),270+((i-first_new)%2)*20)
		else: entry.position = clamp_actor(entry.position)
		entry.warning.position = entry.position-Vector2(0,45)
func clamp_enemy(pos: Vector2) -> Vector2:
	if stage==9:
		return Vector2(clampf(pos.x,arena_center-480,arena_center+480),clampf(pos.y,264,306))
	if stage==6:
		return Vector2(clampf(pos.x,arena_center-480,CHIEF_ACCESS_LIMIT+200),clampf(pos.y,264,306))
	return super.clamp_enemy(pos)
func enemy_path(pos: Vector2, target: Vector2) -> PackedVector2Array:
	# The service gate's front post is outside the control arena's navigation grid.
	# Guide incoming enemies above its footprint before returning to the normal path.
	if stage==6 and pos.x>3040 and target.x<3040:
		if pos.y>278:
			return PackedVector2Array([Vector2(maxf(pos.x,3104),276),Vector2(3036,276),target])
		return PackedVector2Array([Vector2(3036,276),target])
	if stage==6 and pos.x<3102 and target.x>3102:
		if pos.y>278:
			return PackedVector2Array([Vector2(minf(pos.x,3036),276),Vector2(3106,276),target])
		return PackedVector2Array([Vector2(3106,276),target])
	return super.enemy_path(pos,target)
func advance_arrivals(delta: float) -> void:
	if stage not in [6,9]:
		super.advance_arrivals(delta)
		return
	for entry in arrivals.duplicate():
		entry.delay -= delta
		if entry.delay>0: continue
		# Entrances are at least 160 px beyond the playable bounds: never swap sides.
		spawn_enemy(entry.position,entry.tough,true,false,entry.dog)
		entry.warning.queue_free()
		arrivals.erase(entry)
func interaction_hint() -> String:
	if stage==14 and absf(player.position.x-delivery_x)<100 and not survivors_at_rescue(): return "Espera a Mara y al grupo"
	if stage==7: return "Dispara al interruptor rojo del lado de carga"
	if stage in HARBOR_FIGHTS: return "Espacio / clic · atacar   R · recargar   Q · cambiar arma"
	if absf(player.position.x-destination())<70:
		return "E / Enter · "+{4:"leer orden",5:"hablar con el Jefe",7:"abrir reja",14:"embarcar"}.get(stage,"avanzar")
	return "Objetivo · %d m →   Tab · documentos" % int(absf(destination()-player.position.x)/METRE)
func interact() -> void:
	if blocked or player.dead or player.action_time>0 or absf(player.position.x-destination())>=70: return
	match stage:
		4: read_sequence("manifest")
		5: read_sequence("chief")
		14:
			if not survivors_at_rescue():
				announcement.emit("Espera a que todos lleguen al barco")
				return
			set_stage(15)
			blocked = true
			delivered.emit()
func read_sequence(key: String) -> void:
	pending_read = key
	blocked = true
	document_requested.emit(HarborArt.dialogue(key))
func review_documents() -> void:
	if blocked or player.dead: return
	if stage in HARBOR_FIGHTS:
		announcement.emit("Despeja la zona antes de leer")
		return
	if stage<5:
		announcement.emit("La orden de embarque está en el patio de carga")
		return
	read_sequence("review")
func document_closed() -> void:
	var key := pending_read
	pending_read = ""
	blocked = false
	match key:
		"manifest":
			document_read.assign([0])
			set_stage(5)
		"chief": start_wave(3)
		"cross":
			gate_open = true
			set_stage(8)
			audio.cue("delivery",-15)
		"standoff":
			chief_saved = true
			set_stage(12)
			refresh_objects()
			audio.cue("anclado",-8)
			shake = 3
			checkpoint.emit(snapshot())
			read_sequence("breakout")
		"breakout": start_boss()
	refresh_objects()
	if stage in HARBOR_SAFE: checkpoint.emit(snapshot())
func start_boss() -> void:
	if stage!=12: return
	set_stage(13)
	arena_center = 4590
	boss_batches = 0
	build_navigation()
	anchored = AnchoredEnemy.new()
	anchored.level = self
	anchored.position = Vector2(4770,260)
	actors.add_child(anchored)
	anchored.killed.connect(enemy_killed)
	enemies.append(anchored)
	guard_intro_time = 0.0
	guard_shot_round = 0
	guards_down.assign([false,false])
	for guard in chief_guards: guard.play("shoot")
	anchored.sprite.flip_h = true
	anchored.enter("sweep_ready",0.8,"sweep_ready")
	announcement.emit("EL ANCLADO · Esquiva y ataca durante su recuperación")
	audio.cue("wave",-8,0.65)
func advance_guard_last_stand(delta: float) -> void:
	if guard_intro_time<0 or not is_instance_valid(anchored): return
	var previous := guard_intro_time
	guard_intro_time += delta
	var approach_delta := minf(guard_intro_time,0.55)-minf(previous,0.55)
	for i in chief_guards.size():
		var guard := chief_guards[i]
		guard.position = guard.position.move_toward(Vector2(4710+i*30,244+i*30),approach_delta*150)
		if not guards_down[i]: guard.play("walk" if guard_intro_time<0.55 else "shoot")
	while guard_shot_round<3 and guard_intro_time>=0.55+guard_shot_round*0.18:
		guard_shot_round += 1
		for guard in chief_guards:
			var heading := (anchored.position-guard.position).normalized()
			var flash := add_sprite(self,RouteArt.weapon_item(4),guard.position+Vector2(0,-30)+heading*20,Vector2(20,16))
			flash.rotation = heading.angle()
			flash.z_index = 4
			get_tree().create_timer(0.08,false).timeout.connect(flash.queue_free)
			anchored.take_damage(8,guard.position)
		audio.cue("pistol",-19)
	if previous<1.05 and guard_intro_time>=1.05:
		anchored.enter("sweep",0.5,"sweep")
		audio.cue("hit",-8,0.6)
		shake = 3
	for i in chief_guards.size():
		if not guards_down[i] and guard_intro_time>=1.17+i*0.12:
			guards_down[i] = true
			chief_guards[i].play("death")
			spawn_fx(chief_guards[i].position+Vector2(0,-20),2,0.2)
	if guard_intro_time>=2.0:
		guard_intro_time = -1
		if not anchored.dead: anchored.enter("rest",0.5,"rest","ARMAZÓN EXPUESTO")
func advance_boss() -> void:
	if not is_instance_valid(anchored): return
	if anchored.dead and remaining()==0 and arrivals.is_empty():
		boss_defeated = true
		set_stage(14)
		refresh_objects()
		announcement.emit("EL CAMINO ESTÁ LIBRE · MARA TE ESPERA")
		checkpoint.emit(snapshot())
func snapshot() -> Dictionary:
	var data := super.snapshot()
	data.level = 8
	data.gate_open = gate_open
	data.chief_saved = chief_saved
	data.boss_defeated = boss_defeated
	data.harbor_story_version = 2
	data.civilian_positions = civilians.map(func(c): return [c.position.x,c.position.y])
	data.chief_position = [boss_npc.position.x,boss_npc.position.y]
	data.guard_positions = chief_guards.map(func(g): return [g.position.x,g.position.y])
	data.civilian_gate_steps = civilian_gate_steps.duplicate()
	data.guards_down = guards_down.duplicate()
	return data
func restore(data: Dictionary) -> void:
	guard_intro_time = -1
	guard_shot_round = 0
	guards_down.assign([int(data.stage)>=14,int(data.stage)>=14])
	gate_opening = false
	gate_progress = 0.0
	gate_open = bool(data.get("gate_open",false))
	chief_saved = bool(data.get("chief_saved",false))
	boss_defeated = bool(data.get("boss_defeated",false))
	# Old saves at the removed rescue objective resume at the new confrontation.
	var restored := data.duplicate(true)
	if int(data.get("harbor_story_version",1))<2 and int(data.stage) in [11,12]:
		restored.stage = 11
		restored.x = 4510
		chief_saved = false
	super.restore(restored)
	for i in civilians.size():
		var fallback := Vector2(2730-i*34,205)
		if stage==10: fallback = Vector2(3910-i*32,205)
		elif stage in [11,12]: fallback = Vector2(4480-i*28,218)
		elif stage>=14: fallback = Vector2(5530+i*25,211)
		civilians[i].position = saved_position(data.get("civilian_positions",[]),i,fallback)
		civilian_gate_steps[i] = 0
		for point in CIVILIAN_GATE_PATH:
			if civilians[i].position.x>=point.x: civilian_gate_steps[i] += 1
		if data.get("civilian_gate_steps",[]).size()==4:
			civilian_gate_steps[i] = clampi(int(data.civilian_gate_steps[i]),0,4)
	if stage>=12:
		var cp: Array = data.get("chief_position",[5480,205] if stage>=14 else [4690,218])
		boss_npc.position = Vector2(float(cp[0]),float(cp[1]))
		for i in chief_guards.size():
			chief_guards[i].position = saved_position(data.get("guard_positions",[]),i,Vector2(4650+i*80,218+i*8))
			# Earlier saves moved the guards to the rescue. They now remain at the fight.
			if stage>=14 and not data.has("guards_down"): chief_guards[i].position = Vector2(4650+i*80,218+i*8)
	refresh_objects()
func saved_position(positions: Array, index: int, fallback: Vector2) -> Vector2:
	if index>=positions.size() or not positions[index] is Array or positions[index].size()!=2: return fallback
	return Vector2(float(positions[index][0]),float(positions[index][1]))

# Shooting shares the normal weapon range, aim and obstacle checks.
func projectile_exclusions() -> Array[RID]:
	var result: Array[RID] = []
	for body in divider_bodies: result.append(body.get_rid())
	return result
func relay_hit(from: Vector2, heading: Vector2, distance: float) -> bool:
	var excluded := projectile_exclusions()
	excluded.append(player.get_rid())
	var query := PhysicsRayQueryParameters2D.create(from,from+heading*distance,14,excluded)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider==gate_target
func assisted_aim(pos: Vector2, distance: float, fallback: Vector2) -> Vector2:
	if stage==7 and not gate_open and not gate_opening:
		var direction := (CONTROL_POS-pos).normalized()
		if relay_hit(pos,direction,distance): return direction
	return super.assisted_aim(pos,distance,fallback)
func pistol_shot(actor: RoutePlayer) -> void:
	super.pistol_shot(actor)
	try_gate_shot(actor.position,actor.facing,280)
func shotgun_shot(actor: ShotgunPlayer) -> void:
	super.shotgun_shot(actor)
	for i in 9:
		try_gate_shot(actor.position,actor.facing.rotated(deg_to_rad((i-4)*4.0)),210)
func try_gate_shot(from: Vector2, heading: Vector2, distance: float) -> void:
	if stage!=7 or blocked or gate_open or gate_opening: return
	if not relay_hit(from,heading,distance): return
	gate_opening = true
	gate_progress = 0.0
	refresh_objects()
	announcement.emit("Interruptor destruido · Abriendo reja")
func advance_gate(delta: float) -> void:
	if not gate_opening: return
	gate_progress = minf(1.0,gate_progress+delta/0.9)
	HarborAccessArt.apply(cargo_gate,mini(5,int(gate_progress*6)),Vector2(96,81),true)
	if gate_progress<1: return
	gate_opening = false
	gate_open = true
	refresh_objects()
	read_sequence("cross")
