class_name RouteStory
extends RefCounted
## Shared connection text is editable without changing the progression logic.
const FOLDER := "res://assets/ui/connections/"
static func dialogue(key: String) -> Array:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FOLDER+"dialogues.json"))
	return data[key].duplicate(true)

static func camp_ending(read_order: bool) -> Array:
	var result := dialogue("level4_end_start")
	result.append_array(dialogue("level4_read_order" if read_order else "level4_read_record"))
	result.append_array(dialogue("level4_end_finish"))
	return result

static func sign(parent: Node2D, file: String, location: Vector2, width: float) -> Sprite2D:
	# Use alpha bounds in an atlas; original approved images stay intact.
	var regions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FOLDER+"regions.json"))
	var r: Array = regions[file]
	var atlas := AtlasTexture.new()
	atlas.atlas = load(FOLDER+file)
	atlas.region = Rect2(r[0],r[1],r[2],r[3])
	atlas.filter_clip = true
	var sprite := Sprite2D.new()
	sprite.name = file.get_basename()
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = location
	sprite.scale = Vector2.ONE * width/float(r[2])
	sprite.add_to_group("route_connection_signs")
	parent.add_child(sprite)
	return sprite
