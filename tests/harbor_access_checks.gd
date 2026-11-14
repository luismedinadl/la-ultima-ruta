extends SceneTree
var app
var level: HarborLevel
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label_: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label_)
func close_dialogue() -> void:
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = -1
		app.ui.advance_dialogue()
func capture(name_: String) -> void:
	level.camera.position = Vector2(level.player.position.x+65,162)
	app.ui.zone_text.text = ""
	await process_frame
	await process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/access_"+name_+".png")
func run() -> void:
	RouteSave.save_path = "res://tests/access_checkpoint_test.json"
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.start_route(false,8)
	close_dialogue()
	level = app.level
	level.set_process(false)
	level.player.set_physics_process(false)
	level.set_stage(4)
	level.player.position = Vector2(1610,280)
	level.refresh_objects()
	check(level.manifest_prop.visible and level.manifest_prop.position.x==1610,"physical document at reading point")
	await capture("document")
	level.interact()
	check(app.ui.dialogue_active,"order opens its text")
	close_dialogue()
	level.player.position = Vector2(level.destination(),280)
	check(level.boss_npc.animation=="idle" and level.boss_npc.sprite_frames.get_frame_count("idle")==1,"chief stands still")
	check(level.boss_npc.position.x>level.cargo_gate.position.x,"chief inside cargo gate")
	check(level.civilians.all(func(c): return c.visible and c.position.x<2830 and c.position.y<242),"four survivors wait on cargo side")
	await capture("waiting")
	var conversation_limit := level.clamp_actor(Vector2(5000,280)).x
	level.interact()
	close_dialogue()
	check(not level.boss_npc.visible,"chief leaves after conversation")
	check(level.clamp_actor(Vector2(5000,280)).x==conversation_limit,"combat preserves conversation forward boundary")
	for x in [2795.0,2864.0,2930.0,2964.0]:
		check(level.clamp_actor(Vector2(x,280)).x==x,"combat does not pull Nico back at "+str(x))
	check(level.arena_center+280==conversation_limit,"combat navigation follows the shared boundary")
	level.arrivals.clear()
	level.set_stage(7)
	level.refresh_objects()
	check(not level.ammo_pickups.has("crossing_supplies") and not level.medkits.has("crossing_supplies"),"crossing supplies wait until gate opens")
	check(level.clamp_actor(Vector2(5000,280)).x==conversation_limit,"clearing the wave preserves forward boundary")
	var rear_foot := level.service_gate.position+(Vector2(170,465)-Vector2(1430,905))*level.service_gate.scale
	check(rear_foot.y>244,"service post stands on Nico's side of the dividing fence")
	await physics_frame
	await physics_frame
	var space := level.get_world_2d().direct_space_state
	check(not space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(2790,209),Vector2(2870,209),4)).is_empty(),"cargo gate blocks cargo lane")
	check(space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(2790,280),Vector2(2870,280),4)).is_empty(),"service gate is open by default")
	check(level.service_gate.position.y>=306 and level.service_gate.texture.resource_path.ends_with("service_gate_wide_open.png"),"dedicated wide gate reaches the lower road edge")
	check(space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(2950,280),Vector2(3060,280),4)).is_empty(),"wide service opening has no blocking leaf")
	check(level.player.test_move(Transform2D(0,Vector2(2870,280)),Vector2(0,-50)),"rear post blocks Nico's body approaching from below")
	check(level.player.test_move(Transform2D(0,Vector2(3030,298)),Vector2(60,0)),"front post blocks Nico's body approaching from the side")
	check(not level.player.test_move(Transform2D(0,Vector2(2940,280)),Vector2(60,0)),"Nico can cross the open rail")
	check(level.service_gate.z_index<level.player.z_index,"rail renders below Nico")
	var previous_position := level.player.position
	level.player.position = Vector2(2960,282)
	await capture("rail_under_player")
	level.player.position = previous_position
	check(not space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(2700,280),Vector2(2700,205),4)).is_empty(),"fence blocks actors from survivors")
	level.interact()
	check(not level.gate_open and not level.gate_opening and not level.blocked,"interaction cannot open gate")
	level.player.facing = Vector2.LEFT
	level.pistol_shot(level.player)
	check(not level.gate_opening,"missed shot cannot open gate")
	level.player.facing = level.assisted_aim(level.player.position,280,Vector2.RIGHT)
	check(level.player.facing.distance_to((level.CONTROL_POS-level.player.position).normalized())<0.01,"touch aim targets visible relay")
	level.pistol_shot(level.player)
	check(level.gate_opening and not level.gate_open,"pistol hit starts opening")
	level._process(0.4)
	check(level.gate_progress>0 and level.cargo_block.collision_layer==4,"gate animates before collision releases")
	await capture("opening")
	var progress := level.gate_progress
	level.blocked = true
	level._process(1)
	check(level.gate_progress==progress,"dialogue pauses opening")
	level.blocked = false
	level._process(0.6)
	check(level.gate_open and level.cargo_block.collision_layer==0 and app.ui.dialogue_active,"gate finishes before invitation")
	close_dialogue()
	check(level.stage==8,"crossing progresses")
	var supply_key := "crossing_supplies"
	var supply_start := level.player.position
	level.player.reserve = 0
	level.player.shell_reserve = 0
	level.player.health = 30
	level.player.position = level.ammo_pickups[supply_key].sprite.position
	level.collect_ammo()
	level.player.position = level.shell_boxes[supply_key].position
	level.collect_shells()
	level.player.position = level.medkits[supply_key].position
	level.collect_medkits()
	check(level.player.reserve==12 and level.player.shell_reserve==4 and level.player.health==65,"crossing supplies give pistol ammo, shells and health on contact")
	level.refresh_objects()
	check(not level.ammo_pickups[supply_key].sprite.visible and not level.shell_boxes[supply_key].visible and not level.medkits[supply_key].visible,"collected crossing supplies do not respawn")
	level.player.position = supply_start
	var before := level.civilians[0].position
	level._process(0.1)
	check(level.civilians[0].position.x>before.x and level.civilians[0].position.distance_to(before)<6.5,"survivors walk without teleporting")
	await capture("open")
	var saved := level.snapshot()
	level.restore(saved)
	check(level.gate_open and not level.gate_opening,"open gate checkpoint restores")
	level.set_stage(7)
	level.gate_open = false
	level.gate_progress = 0
	level.refresh_objects()
	await physics_frame
	level.player.facing = (level.CONTROL_POS-level.player.position).normalized()
	level.shotgun_shot(level.player)
	check(level.gate_opening,"shotgun also activates relay")
	print("ACCESS FAILURES: ",failures)
	app.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
