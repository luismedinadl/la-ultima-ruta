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
static func script_data() -> Dictionary:
	if story.is_empty(): story = JSON.parse_string(FileAccess.get_file_as_string(FOLDER+"story.json"))
	return story
static func dialogue(key: String) -> Array:
	return script_data().dialogues[key].duplicate(true)
static func document(index: int) -> Array:
	return script_data().documents[index].duplicate(true)
