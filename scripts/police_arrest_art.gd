class_name PoliceArrestArt
extends RefCounted
static func create(parent: Node, pos: Vector2, arrest: bool) -> AnimatedSprite2D:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("arrest" if arrest else "idle")
	var action := "arrest" if arrest else "idle"
	frames.set_animation_loop(action,false)
	frames.set_animation_speed(action,2)
	var regions := [Rect2(170,56,337,622),Rect2(717,56,374,627),Rect2(1232,56,378,627)] if arrest else [Rect2(1809,42,262,635)]
	for region in regions:
		var atlas := AtlasTexture.new()
		atlas.atlas = load("res://assets/harbor/police_arrest.png")
		atlas.region = region
		atlas.margin = Rect2((400-region.size.x)/2,650-region.size.y,400-region.size.x,650-region.size.y)
		atlas.filter_clip = true
		frames.add_frame(action,atlas)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.position = pos
	sprite.scale = Vector2.ONE*(62.0/635.0)
	sprite.offset.y = -325
	parent.add_child(sprite)
	MetroArt.cutout(sprite)
	sprite.play(action)
	return sprite
