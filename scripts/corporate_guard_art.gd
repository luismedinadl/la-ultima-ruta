class_name CorporateGuardArt
extends RefCounted
static func portrait() -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = load("res://assets/harbor/corporate_guards.png")
	texture.region = Rect2(41,69,177,210)
	texture.filter_clip = true
	return texture
static func npc(parent: Node, pos: Vector2, variant: int) -> AnimatedSprite2D:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/harbor/corporate_guards.json"))
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for action in ["idle","walk"]:
		frames.add_animation(action)
		frames.set_animation_speed(action,8)
		for index in ([0] if action=="idle" else [1,2,3,4,5]):
			var r: Array = data.regions[variant*6+index]
			var texture := AtlasTexture.new()
			texture.atlas = load("res://assets/harbor/corporate_guards.png")
			texture.region = Rect2(r[0],r[1],r[2],r[3])
			texture.margin = Rect2((270-r[2])/2.0,440-r[3],270-r[2],440-r[3])
			texture.filter_clip = true
			frames.add_frame(action,texture)
	var sprite := AnimatedSprite2D.new()
	var combat: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/harbor/corporate_guards_combat.json"))
	for action in ["shoot","death"]:
		var row := variant*2+(1 if action=="death" else 0)
		frames.add_animation(action)
		frames.set_animation_speed(action,10)
		frames.set_animation_loop(action,action=="shoot")
		for i in 6:
			var r: Array = combat.regions[row*6+i]
			var texture := AtlasTexture.new()
			texture.atlas = load("res://assets/harbor/corporate_guards_combat.png")
			texture.region = Rect2(r[0],r[1],r[2],r[3])
			texture.margin = Rect2(r[0]-i*256+64,300-combat.ground[row]+r[1],384-r[2],300-r[3])
			texture.filter_clip = true
			frames.add_frame(action,texture)
	sprite.sprite_frames = frames
	sprite.position = pos
	sprite.scale = Vector2.ONE*(62.0/440.0)
	sprite.offset.y = -220
	parent.add_child(sprite)
	MetroArt.cutout(sprite)
	sprite.set_meta("combat_scale",59.5/float(combat.reference_height[variant]))
	sprite.animation_changed.connect(func():
		var fighting := sprite.animation in ["shoot","death"]
		sprite.scale = Vector2.ONE*(float(sprite.get_meta("combat_scale")) if fighting else 62.0/440.0)
		sprite.offset.y = -150 if fighting else -220)
	sprite.play("idle")
	return sprite
