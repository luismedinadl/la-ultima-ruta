class_name DistributionArt
extends RefCounted
## Final PNG atlases use measured alpha bounds, not assumed sprite spacing.
const FOLDER := "res://assets/distribution/"
static var metadata: Dictionary = {}
static var story: Dictionary = {}
static func data() -> Dictionary:
	if metadata.is_empty(): metadata = JSON.parse_string(FileAccess.get_file_as_string(FOLDER+"regions.json"))
	return metadata
static func item(index: int, sheet: String = "interactives") -> Texture2D:
	var r: Array = data()[sheet][index]
	var atlas := AtlasTexture.new()
	atlas.atlas = load(FOLDER+sheet+".png")
	atlas.region = Rect2(r[0],r[1],r[2],r[3])
	atlas.filter_clip = true
	return atlas

static func center_plate_label(label: Label, plate: Sprite2D) -> void:
	# The painted metal starts 40% down the fixture texture.
	var extent := plate.texture.get_size() * plate.scale
	label.size = Vector2(extent.x, extent.y * 0.6)
	label.position = plate.position + Vector2(-extent.x * 0.5, -extent.y * 0.1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

static func script_data() -> Dictionary:
	if story.is_empty(): story = JSON.parse_string(FileAccess.get_file_as_string(FOLDER+"story.json"))
	return story
static func dialogue(key: String) -> Array:
	return script_data().dialogues[key].duplicate(true)
static func document(index: int) -> Array:
	return script_data().documents[index].duplicate(true)
