class_name SurvivalLevel
extends ContainmentLevel
## Independent endless run: never reads or writes campaign checkpoints.
const LOCATIONS := ["Distrito comercial","Distrito de carga","Metro","Campamento","Canal","Centro de distribución","Estación de radio","Puerto"]
var completed_waves := 0
var phase := "supplies"
var phase_time := 0.0
var pending_enemies := 0
var spawn_time := 0.0
var spawned := 0
var scenery := 0
var guard_intro_time := -1.0 # Shared Anclado behaviour; no story cutscene here.
var drops: Array[Dictionary] = []
var backdrop: Node2D
var fade: ColorRect
var changed_scene := false

static func scenario_for(number: int) -> int:
	return int((number-1)/5.0)%8
static func count_for(number: int) -> int:
	return 1 if number%10==0 else number+1

static func ammo_sets_for(number: int) -> int:
	return maxi(2 if number%10==0 else 1, 1+int((number-1)/5.0))

func _ready() -> void:
	rng.randomize()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world_length = 960
	arena_center = 480
	level_number = 1
	actors = Node2D.new()
	actors.y_sort_enabled = true
	add_child(actors)
	player = ShotgunPlayer.new()
	player.level = self
	player.has_pistol = true
	player.pistol_equipped = true
	player.position = Vector2(480,270)
	actors.add_child(player)
	(player as ShotgunPlayer).acquire_shotgun()
	(player as ShotgunPlayer).weapon_slot = 1
	player.animate("idle")
	player.magazine = 12
	player.reserve = 24
	player.damaged.connect(func(amount: int): damage_received += amount)
	player.died.connect(func(): player_died.emit())
	camera = Camera2D.new()
	camera.position = Vector2(480,162)
	add_child(camera)
	camera.make_current()
	build_weather()
	var overlay := CanvasLayer.new()
	overlay.layer = 20
	add_child(overlay)
	fade = ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.color = Color(0,0,0,0)
	overlay.add_child(fade)
	set_scenery(0)
	begin_round(1)

func set_scenery(index: int) -> void:
	scenery = index
	level_number = index+1
	if is_instance_valid(backdrop):
		remove_child(backdrop)
		backdrop.queue_free()
	backdrop = Node2D.new()
	backdrop.z_index = -5
	add_child(backdrop)
	if index<3:
		# Reuse the actual modular city and metro assets, without story props.
		for x in range(0,1024,128):
			for y in [192,320]:
				var floor_tile := add_sprite(backdrop,RouteArt.texture("metro/floor.png" if index==2 else "tiles/asphalt_quiet_v01.png"),Vector2(x+64,y),Vector2(128,128))
				floor_tile.modulate = Color(0.68,0.74,0.87)
		if index<2:
			for x in range(0,1024,32):
				for y in [160,192]:
					var cell := 8 if y==160 else 48+int(x/32.0)%4
					var tile_texture := RouteArt.cell("tiles/tiles.png",8,8,cell%8,int(cell/8.0),3)
					# The bottom of the old sidewalk tile includes bright road reflections.
					# Crop them without stretching the pavement; the quiet asphalt lies below.
					var tile_height := 24 if y==192 else 32
					if y==192: tile_texture.region.size.y *= 24.0/32.0
					var tile := add_sprite(backdrop,tile_texture,Vector2(x+16,y+tile_height/2.0),Vector2(32,tile_height))
					tile.modulate = Color(0.68,0.74,0.87)
		for x in range(0,1104,184):
			var texture: Texture2D
			if index==2: texture = MetroArt.item("modules",[0,1,2,4][int(x/184.0)%4])
			elif index==1: texture = RouteArt.freight_facade(int(x/184.0)%5)
			else: texture = RouteArt.cell("tiles/architecture.png",3,2,int(x/184.0)%3,1,4)
			var wall := add_sprite(backdrop,texture,Vector2(x+92,196 if index==2 else 180),Vector2(186,196 if index==2 else 176),true)
			if index<2: wall.modulate = Color(0.7,0.75,0.88)
	else:
		var path: String = ["containment/backgrounds/medical.png","rescue/pumps.png","distribution/sorting.png","broadcast/access.png","harbor/cargo.png"][index-3]
		for i in 2:
			var bg := add_sprite(backdrop,RouteArt.texture(path),Vector2(288+i*480,162),Vector2(576,324))
			var blend := ShaderMaterial.new()
			blend.shader = preload("res://scripts/camp_join.gdshader")
			blend.set_shader_parameter("join_width",0.0 if i==0 else 96.0/576.0)
			bg.material = blend
	rain.visible = index not in [2,5]
	audio.set_route_ambience(index+1)
	if index==5: audio.ambience.stream_paused = true

func begin_round(number: int) -> void:
	wave_index = number
	for enemy in enemies:
		if is_instance_valid(enemy): enemy.queue_free()
	enemies.clear()
	for drop in drops:
		if is_instance_valid(drop.sprite): drop.sprite.queue_free()
	drops.clear()
	spawned = 0
	pending_enemies = count_for(number)
	spawn_time = 0
	phase = "supplies"
	phase_time = 6.0
	blocked = false
	# Only ammunition is restocked. Health never recovers during a survival run.
	var sets := ammo_sets_for(number)
	for i in sets:
		# Spread supplies across reachable ground. Extremely long runs reuse positions,
		# leaving extra boxes there until the player has room to collect them.
		var column := i%10
		var supply_x: float = 480.0+[-1,1,-2,2,-3,3,-4,4,-5,5][column]*68.0
		add_drop("pistol",Vector2(supply_x,252))
		add_drop("shells",Vector2(supply_x,292))
	announcement.emit("%s · OLEADA %d%s" % [LOCATIONS[scenery],number," · EL ANCLADO" if number%10==0 else ""])
	update_goal()

func add_drop(kind: String, pos: Vector2) -> void:
	assert(kind in ["pistol", "shells"])
	var texture: Texture2D = RouteArt.weapon_item(0) if kind=="pistol" else ContainmentArt.item(8)
	var sprite := add_sprite(actors,texture,pos,Vector2(25,23),true)
	if kind=="shells": ContainmentArt.cutout(sprite)
	else: MetroArt.cutout(sprite)
	drops.append({"kind":kind,"sprite":sprite})

func collect_drops() -> void:
	var p := player as ShotgunPlayer
	for drop in drops.duplicate():
		if player.position.distance_to(drop.sprite.position)>22: continue
		match drop.kind:
			"pistol":
				if p.reserve>=p.MAX_RESERVE: continue
				p.reserve = mini(p.MAX_RESERVE,p.reserve+12)
			"shells":
				if p.shell_reserve>=p.MAX_SHELL_RESERVE: continue
				p.shell_reserve = mini(p.MAX_SHELL_RESERVE,p.shell_reserve+4)
		drop.sprite.queue_free()
		drops.erase(drop)
		audio.cue("pickup",-16)

func spawn_next() -> void:
	var enemy: MetroEnemy
	if wave_index%10==0: enemy = AnchoredEnemy.new()
	else:
		match rng.randi_range(0,3):
			0: enemy = MetroEnemy.new()
			1:
				enemy = MetroEnemy.new()
				enemy.resistant = true
			2: enemy = InfectedDog.new()
			3: enemy = HollowEnemy.new()
	enemy.level = self
	enemy.awareness = 2
	enemy.show_awareness_icon = false
	enemy.position = Vector2(65 if spawned%2==0 else 895,rng.randf_range(235,296))
	# Spawn outside the current view when possible, never on top of Nico.
	if enemy.position.distance_to(player.position)<140: enemy.position.x = 895 if player.position.x<480 else 65
	actors.add_child(enemy)
	enemy.killed.connect(enemy_killed)
	enemies.append(enemy)
	spawned += 1
	pending_enemies -= 1

func enemy_killed(_enemy: RouteEnemy) -> void:
	kills += 1

func _process(delta: float) -> void:
	if player.dead: return
	ambient_time += delta
	freeze_time = maxf(0,freeze_time-delta)
	if phase=="transition":
		phase_time += delta
		fade.color.a = clampf(phase_time/0.6 if phase_time<0.6 else (1.4-phase_time)/0.6,0,1)
		if phase_time>=0.6 and not changed_scene:
			changed_scene = true
			set_scenery(scenario_for(wave_index+1))
			player.position = Vector2(480,270)
		if phase_time>=1.4:
			fade.color.a = 0
			begin_round(wave_index+1)
	else:
		elapsed += delta
		collect_drops()
		if phase=="supplies":
			phase_time -= delta
			if phase_time<=0:
				phase = "combat"
				audio.cue("wave",-14)
		elif phase=="combat":
			# Bound corpse retention as well as live enemies in very long runs.
			var corpses := enemies.filter(func(e): return e.dead)
			while corpses.size()>12:
				var corpse: RouteEnemy = corpses.pop_front()
				enemies.erase(corpse)
				corpse.queue_free()
			spawn_time -= delta
			if pending_enemies>0 and remaining()<24 and spawn_time<=0:
				spawn_next()
				spawn_time = 0.65
			if pending_enemies==0 and remaining()==0:
				completed_waves = wave_index
				if scenario_for(wave_index+1)!=scenery:
					phase = "transition"
					phase_time = 0
					changed_scene = false
					blocked = true
				else: begin_round(wave_index+1)
	update_goal()
	update_camera(0.0)
	shake = move_toward(shake,0,delta*18)
	camera.offset = Vector2(sin(ambient_time*91),cos(ambient_time*83))*shake
	for drop in rain.get_children():
		drop.position += Vector2(-28,150)*delta
		if drop.position.y > get_viewport_rect().size.y + 20: drop.position = Vector2(rng.randf_range(0, get_viewport_rect().size.x),-20)

func update_goal() -> void:
	goal = "Oleada %d · %s" % [wave_index,"El Anclado" if wave_index%10==0 else "Elimina a los infectados"]
	if phase=="supplies": goal = "Oleada %d en %d s · Recoge suministros" % [wave_index,maxi(1,ceili(phase_time))]
	elif phase=="transition": goal = "Avanzando al siguiente escenario"

func clamp_actor(pos: Vector2) -> Vector2:
	return Vector2(clampf(pos.x,56,904),clampf(pos.y,210,306))
func clamp_enemy(pos: Vector2) -> Vector2:
	return clamp_actor(pos)
func enemy_path(_pos: Vector2, target: Vector2) -> PackedVector2Array:
	return PackedVector2Array([target])
func interact() -> void: pass
func interaction_hint() -> String:
	return "Espacio / clic · atacar   R · recargar   Q · cambiar arma"


