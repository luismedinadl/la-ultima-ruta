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
	var captions := {
		"02_recepcion_carga.png": "Cargo receiving",
		"03_metro_campamento.png": "Subway · Camp access →",
		"04_salida_campamento.png": "Camp exit · Service corridor →",
	}
	sign_caption(sprite, captions[file])
	return sprite

static func sign_caption(sprite: Sprite2D, meaning: String) -> void:
	var extent := sprite.texture.get_size() * sprite.scale
	caption_at(sprite.get_parent(), meaning, sprite.position + Vector2(0, extent.y / 2 + 1), extent.x)

static func caption_at(parent: Node, meaning: String, top_center: Vector2, width: float) -> void:
	var caption := Label.new()
	caption.text = meaning
	caption.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 10)
	caption.add_theme_constant_override("outline_size", 3)
	caption.add_theme_color_override("font_outline_color", Color("10141c"))
	caption.size = Vector2(width, 16)
	caption.position = top_center - Vector2(width / 2, 0)
	parent.add_child(caption)
