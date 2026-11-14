class_name HarborAccessArt
extends RefCounted
## Fixed cells preserve the gate posts throughout the six opening frames.
static func texture(index: int, gate: bool = false) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/harbor/access_revision/" + ("gate.png" if gate else "fixtures.png"))
	if gate:
		var origins := [Vector2(0,64),Vector2(538,64),Vector2(1042,64),Vector2(0,539),Vector2(538,539),Vector2(1040,539)]
		var origin: Vector2 = origins[index]
		var width := minf(512,1536-origin.x)
		atlas.region = Rect2(origin,Vector2(width,432))
		atlas.margin = Rect2(0,0,512-width,0)
	else:
		atlas.region = [Rect2(40,145,1000,282),Rect2(1150,24,202,480),Rect2(382,532,200,460),Rect2(932,620,405,380)][index]
	atlas.filter_clip = true
	return atlas
static func apply(sprite: Sprite2D, index: int, size_: Vector2, gate: bool = false) -> void:
	sprite.texture = texture(index,gate)
	sprite.scale = size_/sprite.texture.get_size()
	sprite.offset.y = -sprite.texture.get_height()/2.0
	MetroArt.cutout(sprite)
