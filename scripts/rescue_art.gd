class_name RescueArt
extends RefCounted
const FOLDER := "res://assets/rescue/"
static var metadata: Dictionary = {}
static var animations: Dictionary = {}
static func data() -> Dictionary:
	if metadata.is_empty(): metadata = JSON.parse_string(FileAccess.get_file_as_string(FOLDER+"regions.json"))
	return metadata
static func region(file: String, r: Array) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = load(FOLDER+file+".png")
	texture.region = Rect2(r[0],r[1],r[2],r[3])
	texture.filter_clip = true
	return texture
static func prop(index: int) -> Texture2D:
	return region("props",data().props[index])
static func sign(index: int) -> Texture2D:
	return region("signs",data().signs[index])
static func portrait(index: int = 0) -> Texture2D:
	return region("portraits",[index*512,0,512,400])
static func frames(person: String) -> SpriteFrames:
	if animations.has(person): return animations[person]
	var result := SpriteFrames.new()
	result.remove_animation("default")
	for action in ["walk","idle","talk"]:
		result.add_animation(action)
		result.set_animation_loop(action,true)
		result.set_animation_speed(action,7 if action=="walk" else 2)
		var indices: Array = [0,1,2,3,4,5] if action=="walk" else [8] if action=="idle" else [10,11]
		for i in indices:
			var pose: Dictionary = data()[person].cells[i]
			var texture := region(person,pose.rect)
			texture.margin = Rect2(256-float(pose.anchor[0]),480-float(pose.anchor[1]),512-float(pose.rect[2]),512-float(pose.rect[3]))
			result.add_frame(action,texture)
	animations[person] = result
	return result
static func npc(person: String, parent: Node, pos: Vector2, height_factor: float = 1.0) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames(person)
	sprite.position = pos
	var factor := float(data()[person].scale)*height_factor
	sprite.scale = Vector2.ONE*factor
	sprite.offset.y = -224
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	MetroArt.cutout(sprite)
	parent.add_child(sprite)
	sprite.play("idle")
	return sprite
static func dialogue(key: String) -> Array:
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FOLDER+"dialogues.json"))
	return content[key].duplicate(true)
