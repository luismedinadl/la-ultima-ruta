extends SceneTree
var app
var nav: AStarGrid2D
var ticks := 0
var last_stage := -1
var route := PackedVector2Array()
var destination := Vector2.ZERO
var finished := false
func _initialize() -> void: call_deferred("run")
func run() -> void:
	RouteSave.save_path = "res://tests/containment_walk_checkpoint.json"
	Engine.time_scale = 6
	Engine.physics_ticks_per_second = 120
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false,4)
	await physics_frame
	await physics_frame
	nav = AStarGrid2D.new()
	nav.region = Rect2i(0,0,380,7)
	nav.cell_size = Vector2(16,16)
	nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.update()
	var shape := CircleShape2D.new()
	shape.radius = 10
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.collision_mask = 4
	for x in 380:
		for y in 7:
			q.transform = Transform2D(0,Vector2(x*16,y*16+204))
			nav.set_point_solid(Vector2i(x,y),not app.level.get_world_2d().direct_space_state.intersect_shape(q,1).is_empty())
	process_frame.connect(drive)
func cell(pos: Vector2) -> Vector2i:
	var c := Vector2i(Vector2(pos.x/16,(pos.y-204)/16).round())
	c.x = clampi(c.x,0,379)
	c.y = clampi(c.y,0,6)
	var best := c
	var d := INF
	for x in range(maxi(0,c.x-5),mini(380,c.x+6)):
		for y in 7:
			var test := Vector2i(x,y)
			if nav.is_point_solid(test): continue
			var dd := Vector2(test-c).length_squared()
			if dd < d:
				d = dd
				best = test
	return best
func drive() -> void:
	if finished: return
	if app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = 1000
		app.ui.advance_dialogue()
		return
	var l = app.level
	var p = l.player
	if app.mode == "result":
		finished = true
		print("CONTAINMENT_WALK_RESULT stage=",l.stage," kills=",l.kills," hp=",p.health," time=",l.elapsed," reserve=",p.reserve," pickups=",l.ammo_taken.size())
		DirAccess.remove_absolute(RouteSave.save_path)
		call_deferred("finish",0 if l.stage == 11 else 1)
		return
	if l.stage != last_stage:
		last_stage = l.stage
		print("CONTAINMENT_WALK stage=",l.stage," x=",p.position.x," hp=",p.health," reserve=",p.reserve)
	if l.elapsed > 700:
		print("CONTAINMENT_WALK_TIMEOUT pos=",p.position," target=",destination," stage=",l.stage," remaining=",l.remaining())
		quit(1)
		return
	RouteControls.virtual_attack = false
	RouteControls.virtual_move = Vector2.ZERO
	if p.action_time <= 0:
		if p.weapon_slot==2 and p.shells+p.shell_reserve==0: p.switch_weapon()
		elif p.weapon_slot==1 and p.magazine+p.reserve==0: p.switch_weapon()
		elif p.weapon_slot==0 and p.magazine+p.reserve>0: p.switch_weapon()
	var enemy = l.nearest_enemy(p.position,1000)
	if enemy != null and p.position.distance_to(enemy.position) < (265 if p.pistol_equipped else 38) and l.can_see_enemy(p.position,enemy):
		RouteControls.virtual_attack = true
		if not p.pistol_equipped or p.position.distance_to(enemy.position) > 110:
			return
		# Escape to the clearest reachable point before taking another shot.
		var escape: Vector2 = p.position
		var best := -INF
		for i in 16:
			var candidate: Vector2 = l.clamp_actor(p.position + Vector2.from_angle(TAU*i/16.0)*110)
			if p.position.distance_to(candidate) < 25: continue
			if nav.is_point_solid(cell(candidate)): continue
			var safety := 10000.0
			for e in l.enemies:
				if not e.dead: safety = minf(safety,candidate.distance_to(e.position))
			if safety > best:
				best = safety
				escape = candidate
		var ids := nav.get_id_path(cell(p.position),cell(escape))
		if ids.size() > 1:
			RouteControls.virtual_move = (Vector2(ids[1].x*16,ids[1].y*16+204)-p.position).normalized()
		else: RouteControls.virtual_move = (escape-p.position).normalized()
		return
	var target := Vector2(l.destination(),250)
	if enemy != null: target = enemy.position
	elif l.stage == 4: target = l.DOCUMENT_POINTS[0]
	elif l.stage == 8: target = l.GUN_POINT
	elif l.stage == 10: target = Vector2(l.delivery_x,230)
	if enemy == null and p.reserve < 30 and l.stage<8:
		var nearest := 650.0
		for key in l.ammo_pickups:
			if l.ammo_taken.has(key): continue
			var pos: Vector2 = l.ammo_pickups[key].sprite.position
			var d: float = p.position.distance_to(pos)
			if d < nearest:
				nearest = d
				target = pos
	if enemy == null and p.health < 75:
		for key in l.medkits:
			if not l.collected.has(key) and p.position.distance_to(l.medkits[key].position) < 550:
				target = l.medkits[key].position
				break
	if "E / Enter" in l.interaction_hint() and (l.nearby_document()<0 or not l.document_read.has(l.nearby_document())): l.interact()
	ticks += 1
	if ticks % 12 == 0 or target.distance_to(destination) > 20 or route.is_empty():
		destination = target
		route.clear()
		for id in nav.get_id_path(cell(p.position),cell(target)): route.append(Vector2(id.x*16,id.y*16+204))
		if route.size() > 1: route.remove_at(0)
	while route.size() > 1 and p.position.distance_to(route[0]) < 8: route.remove_at(0)
	if p.position.distance_to(target) < 22: RouteControls.virtual_move = (target-p.position).normalized()
	elif not route.is_empty(): RouteControls.virtual_move = (route[0]-p.position).normalized()

func finish(code: int) -> void:
	RouteControls.virtual_attack = false
	RouteControls.virtual_move = Vector2.ZERO
	app.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	quit(code)
