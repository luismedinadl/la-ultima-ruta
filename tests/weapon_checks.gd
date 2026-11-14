extends SceneTree
var errors := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	if not ok: errors += 1
	print("PASS " if ok else "FAIL ",text)
func run() -> void:
	RouteControls.setup()
	var audio := RouteAudio.new()
	root.add_child(audio)
	var l := RouteLevel.new()
	l.level_number = 2
	l.audio = audio
	root.add_child(l)
	l.set_process(false)
	l.blocked = false
	var p := l.player
	p.set_physics_process(false)
	var e := RouteEnemy.new()
	e.level = l
	l.actors.add_child(e)
	e.set_physics_process(false)
	l.enemies.append(e)
	p.position = Vector2(570,270)
	e.position = Vector2(740,270)
	await physics_frame
	await physics_frame
	var hp := e.health
	p.facing = Vector2.RIGHT
	l.pistol_shot(p)
	check(e.health == hp,"car blocks bullet")
	p.position = Vector2(710,270)
	await physics_frame
	await physics_frame
	l.pistol_shot(p)
	check(e.health == hp-44,"clear line damages first enemy")
	p.reserve = 36
	p.position = l.ammo_pickups["0"].sprite.position
	l.collect_ammo()
	check(not l.ammo_taken.has("0"),"full reserve leaves ammo on ground")
	p.reserve = 32
	l.collect_ammo()
	check(p.reserve == 36 and l.ammo_taken.has("0"),"pickup respects reserve capacity")
	p.action_time = 0
	p.magazine = 4
	p.reserve = 3
	p.begin_reload()
	p.set_physics_process(true)
	await create_timer(1.3).timeout
	check(p.magazine == 7 and p.reserve == 0,"partial reload cannot invent ammunition")
	p.magazine = 1
	p.reserve = 20
	p.action_time = 0
	p.begin_reload()
	p.invulnerability = 0
	p.take_damage(1,p.position+Vector2(10,0))
	await create_timer(1.3).timeout
	check(p.magazine == 1 and p.reserve == 20,"damage interrupts reload without consuming ammunition")
	p.pistol_equipped = false
	p.action_time = 0
	p.begin_attack()
	check(p.action == "knife_attack","knife remains usable with pistol unlocked")
	p.action_time = 0
	p.switch_weapon()
	await create_timer(0.4).timeout
	check(p.pistol_equipped and p.action == "idle","equip animation returns to armed idle")
	p.switch_weapon()
	await create_timer(0.4).timeout
	check(not p.pistol_equipped and p.action == "idle","holster animation returns to knife idle")
	l.queue_free()
	audio.queue_free()
	await process_frame
	await process_frame
	RouteArt.frame_cache.clear()
	RouteArt.textures.clear()
	print("WEAPON failures: ",errors)
	quit(1 if errors else 0)
