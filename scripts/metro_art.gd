class_name MetroArt
extends RefCounted
static var data: Dictionary = {}
static func item(sheet: String, index: int) -> AtlasTexture:
	if data.is_empty(): data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/metro/regions.json"))
	var r: Array = data[sheet][index]
	return RouteArt.region("metro/" + sheet + ".png",Rect2(r[0],r[1],r[2],r[3]))
static func cutout(sprite: CanvasItem) -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/character_clip.gdshader")
	material.set_shader_parameter("alpha_cutoff",0.72)
	sprite.material = material
static func opening() -> Array:
	return RouteStory.dialogue("level3_open")
