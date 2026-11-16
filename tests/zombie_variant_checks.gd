extends SceneTree
const ART = preload("res://scripts/zombie_variant_art.gd")
var errors := 0
var kills := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	if not ok: errors += 1
	print("PASS " if ok else "FAIL ", description)
func run() -> void:
	ART.bag.clear()
	for group in 5:
		var picks := []
		for i in 5: picks.append(ART.choose())
		picks.sort()
		check(picks == [0,1,2,3,5], "random group includes five basic designs")
	for variant in [1,2,3,4,5]:
		var frames := ART.frames(variant)
		var valid := true
		for action in ["idle","walk","attack","hurt","death"]:
			for direction in 8:
				var key: String = action+"_"+str(direction)
				valid = valid and frames.get_frame_count(key) == (1 if action == "idle" else 6)
				valid = valid and frames.get_animation_loop(key) == (action == "walk")
				for f in frames.get_frame_count(key):
					var tex := frames.get_frame_texture(key,f) as AtlasTexture
					valid = valid and Rect2(Vector2.ZERO,tex.atlas.get_size()).encloses(tex.region)
		check(valid,"variant %d: five actions, eight directions, valid atlas bounds"%variant)
	RouteControls.setup()
	# This design's front three-quarter pose was drawn facing screen right.
	for action in ["idle", "walk", "attack", "hurt", "death"]:
		for f in (1 if action == "idle" else 6):
			var left := RouteControls.direction_index(Vector2(-1, 1))
			var right := RouteControls.direction_index(Vector2(1, 1))
			check(ART.flipped(ART.ICON_ZOMBIE, action, left, f) and not ART.flipped(ART.ICON_ZOMBIE, action, right, f), "icon zombie faces the target on both front diagonals")
	var audio := RouteAudio.new()
	root.add_child(audio)
	var level := RouteLevel.new()
	level.audio = audio
	root.add_child(level)
	level.set_process(false)
	level.player.set_physics_process(false)
	level.blocked = false
	level.freeze_time = 0
	for variant in [0,1,2,3,4,5]:
		var enemy := RouteEnemy.new()
		enemy.appearance = variant
		enemy.resistant = variant == 4
		enemy.level = level
		level.actors.add_child(enemy)
		enemy.set_physics_process(false)
		check(enemy.health == (190 if variant == 4 else 86) and enemy.movement_speed() == (19 if variant == 4 else 24),"same basic stats: %d"%variant)
		check((enemy.get_child(0) as CollisionShape2D).shape.radius == 9,"same collision: %d"%variant)
		enemy.position = level.player.position+Vector2(15,0)
		level.player.health = 100
		level.player.invulnerability = 0
		enemy.animate("attack")
		enemy.timer = 0.85
		enemy.attack_elapsed = 0.37
		enemy._physics_process(0.02)
		check(level.player.health == (78 if variant == 4 else 85),"attack deals expected damage: %d"%variant)
		enemy.take_damage(10,enemy.position+Vector2(10,0))
		check(enemy.health == (180 if variant == 4 else 76) and enemy.action == "hurt" and enemy.appearance == variant,"hurt preserves appearance: %d"%variant)
		enemy.killed.connect(func(_e): kills += 1)
		enemy.take_damage(1000,enemy.position)
		enemy.take_damage(1000,enemy.position)
		await create_timer(0.9).timeout
		check(enemy.dead and enemy.sprite.frame == 5 and enemy.collision_layer == 0,"death holds corpse: %d"%variant)
	check(kills == 6,"death counted once per enemy")
	var resistant := RouteEnemy.new()
	resistant.resistant = true
	level.actors.add_child(resistant)
	resistant.set_physics_process(false)
	check(resistant.appearance == 4 and resistant.health == 190,"resistant uses new art and keeps health")
	for special in [InfectedDog.new(),HollowEnemy.new()]:
		level.actors.add_child(special)
		special.set_physics_process(false)
		check(special.appearance == 0 and not special.allow_basic_variants,"special enemy keeps own art")
	for variant in [1,2,3,4,5]:
		var metro := MetroEnemy.new()
		metro.appearance = variant
		metro.resistant = variant == 4
		level.actors.add_child(metro)
		metro.set_physics_process(false)
		metro.hear_noise(Vector2.ZERO,false)
		check(metro.awareness == 1,"variant investigates noise")
		metro.hear_noise(Vector2.ZERO,true)
		check(metro.awareness == 2 and metro.appearance == variant,"variant alerted by loud noise")
	level.queue_free()
	audio.queue_free()
	await process_frame
	print("ZOMBIE_VARIANTS_ERRORS=",errors)
	quit(errors)

