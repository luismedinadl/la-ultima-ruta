extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label_: String) -> void:
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label_)
func run() -> void:
	RouteControls.setup()
	var audio := RouteAudio.new()
	root.add_child(audio)
	var l := MetroLevel.new()
	l.audio = audio
	root.add_child(l)
	l.set_process(false)
	l.intro_spawned = true
	l.blocked = false
	var p := l.player
	p.set_physics_process(false)
	p.position = Vector2(1940,280)
	var dog := l.spawn_enemy(Vector2(1700,280),false,true,false,true) as InfectedDog
	var normal := l.spawn_enemy(Vector2(1500,280),false,true)
	normal.dead = true
	check(is_equal_approx(dog.movement_speed(),113.28) and is_equal_approx(dog.movement_speed(),normal.movement_speed()*4),"dog is twice its previous speed and four times normal zombie speed")
	check(dog.max_health == 110 and dog.damage_override == 24,"dog health and bite damage")
	var start := dog.position
	for i in 30: await physics_frame
	check(dog.position.distance_to(start)>52 and dog.position.distance_to(start)<61,"dog physically travels at expected speed")
	check(dog.action == "walk","chase plays run animation")
	dog.position = Vector2(1700,280)
	p.position = Vector2(1730,280)
	dog.cooldown = 0
	dog.timer = 0
	p.invulnerability = 0
	for i in 10: await physics_frame
	check(p.health == 100 and dog.action == "attack","bite has readable anticipation")
	for i in 12: await physics_frame
	check(p.health == 76,"bite lands once for 24 damage")
	for i in 20: await physics_frame
	check(p.health == 76,"recovery does not deal repeated damage")
	dog.cooldown = 0
	dog.timer = 0
	p.invulnerability = 0
	for i in 4: await physics_frame
	p.position += Vector2(100,0)
	for i in 20: await physics_frame
	check(p.health == 76,"moving out of reach dodges the bite")
	dog.set_physics_process(false)
	dog.take_damage(44,p.position)
	check(dog.health == 66 and dog.action == "hurt","pistol damage plays dog hurt animation")
	var saved := l.snapshot()
	l.restore(saved)
	var restored: InfectedDog = null
	for enemy in l.enemies:
		if enemy is InfectedDog: restored = enemy
	check(restored != null and restored.health == 66,"snapshot restores dog type and health")
	restored.set_physics_process(false)
	restored.take_damage(1000,p.position)
	await create_timer(0.7).timeout
	check(restored.dead and restored.collision_layer == 0 and restored.sprite.frame == 2,"death leaves nonblocking prone corpse")
	var frames := DogArt.frames()
	var frame_count := 0
	for animation in frames.get_animation_names():
		for index in frames.get_frame_count(animation):
			var atlas := frames.get_frame_texture(animation,index) as AtlasTexture
			check(atlas.margin.position.x >= 0 and atlas.margin.position.y >= 0 and atlas.get_size() == Vector2(320,320),"valid dog atlas frame")
			frame_count += 1
	check(frame_count == 192,"eight directions for all dog states")
	l.queue_free()
	audio.queue_free()
	await process_frame
	await create_timer(0.4).timeout
	print("DOG failures: ",failures)
	quit(failures)
