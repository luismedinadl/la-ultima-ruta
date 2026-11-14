extends SceneTree
var app
var l: HarborLevel
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",message)
func run() -> void:
	RouteSave.save_path = "res://tests/harbor_combat_checkpoint.json"
	app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.start_route(false,8)
	while app.ui.dialogue_active:
		app.ui.dialog_text.visible_characters = -1
		app.ui.advance_dialogue()
	l = app.level
	l.set_process(false)
	l.player.controls_enabled = false
	l.set_stage(12)
	l.chief_saved = true
	l.gate_open = true
	l.player.position = Vector2(4590,270)
	l.start_boss()
	var boss := l.anchored
	boss.set_physics_process(false)
	l.advance_guard_last_stand(2.1)
	await physics_frame
	await physics_frame
	await process_frame
	var hp := boss.health
	l.player.facing = (boss.position-l.player.position).normalized()
	l.pistol_shot(l.player)
	check(boss.health<hp,"pistol ray hits boss collider")
	hp = boss.health
	l.shotgun_shot(l.player)
	check(boss.health<hp,"shotgun pellets hit boss collider")
	boss.animate("charge")
	boss.sprite.frame = 1
	boss.sync_sprite_anchor()
	check(int((boss.sprite.material as ShaderMaterial).get_shader_parameter("excluded_count"))>0,"attack frames exclude neighbouring artwork")
	boss.animate("walk")
	check(int((boss.sprite.material as ShaderMaterial).get_shader_parameter("excluded_count"))==0,"clean walk frames clear the previous clipping mask")
	# Each attack must hurt in range and miss outside its readable reach.
	for attack in ["charge","sweep","slam"]:
		boss.position = Vector2(4590,260)
		l.player.position = Vector2(4600,260)
		l.player.health = 100
		l.player.invulnerability = 0
		boss.locked_heading = Vector2.RIGHT
		boss.enter(attack,0.5,attack)
		boss._physics_process(0.01)
		check(l.player.health<100,attack+" damages in range")
		boss.position = Vector2(4590,260)
		l.player.position = Vector2(4800,300)
		l.player.health = 100
		l.player.invulnerability = 0
		boss.enter(attack,0.5,attack)
		boss._physics_process(0.01)
		check(l.player.health==100,attack+" can be avoided")
	boss.health = 700
	boss.phase_pending = true
	boss.enter("rest",0.01,"rest")
	boss._physics_process(0.02)
	check(boss.phase_two and boss.state=="phase","second phase waits for a recovery window")
	check(boss.sprite.sprite_frames==HarborArt.boss_frames(true),"second phase uses actual broken-restraint sprites")
	# Kill with the real knife hit path and zero ammunition. No test damage multiplier.
	l.player.magazine = 0
	l.player.reserve = 0
	l.player.shells = 0
	l.player.shell_reserve = 0
	l.player.weapon_slot = 0
	l.player.pistol_equipped = false
	boss.health = boss.max_health
	var strikes := 0
	while not boss.dead and strikes<60:
		boss.enter("rest",1.5,"rest")
		l.player.position = boss.position+Vector2(-36,0)
		l.player.facing = Vector2.RIGHT
		l.player_strike(l.player)
		strikes += 1
	check(boss.dead and strikes<=60,"knife can finish boss through real hit detection: "+str(strikes))
	# Supplies at full capacity remain available; walking over a needed item consumes it.
	var box: Sprite2D = l.ammo_pickups["4300"].sprite
	l.player.position = box.position
	l.player.reserve = 36
	l.collect_ammo()
	check(box.visible,"full pistol reserve leaves pickup")
	l.player.reserve = 0
	l.collect_ammo()
	check(l.player.reserve==12 and not box.visible,"walking over pistol box gives twelve")
	l.player.position = l.shell_boxes["4340"].position
	l.player.shell_reserve = 0
	l.collect_shells()
	check(l.player.shell_reserve==4,"walking over shell box gives four")
	l.player.position = l.medkits["4370"].position
	l.player.health = 30
	l.collect_medkits()
	check(l.player.health>30,"medkit works without interaction")
	# Query the actual physics bodies on the civilian boundary and closed gate.
	l.gate_open = false
	l.refresh_objects()
	await physics_frame
	var space := l.get_world_2d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(3500,270),Vector2(3500,205),4))
	check(not hit.is_empty(),"physical barrier protects civilian lane")
	hit = space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(2790,209),Vector2(2870,209),4))
	check(not hit.is_empty(),"closed cargo gate physically blocks passage")
	l.gate_open = true
	l.refresh_objects()
	await physics_frame
	hit = space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(2790,209),Vector2(2870,209),4))
	check(hit.is_empty(),"opening cargo gate removes collision")
	print("HARBOR COMBAT FAILURES: ",failures)
	app.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)

