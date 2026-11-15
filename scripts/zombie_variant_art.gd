extends RefCounted
## Appearance only. A shuffled group keeps all basic designs present without
## changing wave composition, difficulty, hit boxes, perception or attack timing.
static var bag: Array[int] = []
static var cache: Dictionary = {}
static var metadata: Dictionary = {}
const ROOT := "enemies/zombie_variants/"
const RESISTANT := 4
const ICON_ZOMBIE := 5
const BASIC_DESIGNS := [0, 1, 2, 3, ICON_ZOMBIE]

static func folder(variant: int) -> String:
	return "enemies/resistant/" if variant == RESISTANT else ROOT+str(variant)+"/"

static func choose() -> int:
	if bag.is_empty():
		bag.assign(BASIC_DESIGNS)
		bag.shuffle()
	return bag.pop_back()

static func data(variant: int) -> Dictionary:
	if not metadata.has(variant):
		metadata[variant] = JSON.parse_string(FileAccess.get_file_as_string("res://assets/"+folder(variant)+"regions.json"))
	return metadata[variant]

static func scale_for(variant: int, action: String, direction: int) -> float:
	var source := "walk" if action == "idle" else action
	# The young man's slimmer silhouette needs a slightly taller visual scale.
	return (64.0 if variant == RESISTANT else 58.0 if variant == 3 else 52.0) / float(data(variant)[source][direction*6].reference_height)

static func flipped(variant: int, action: String, direction: int, frame: int = 0) -> bool:
	var source := "walk" if action == "idle" else action
	return bool(data(variant)[source][direction*6+frame].get("flip_h",false))

static func ground(variant: int, action: String, direction: int) -> float:
	var source := "walk" if action == "idle" else action
	var frame_height: float = data(variant)[source][direction*6].reference_height
	return (40.0+frame_height-128.0 if source == "walk" else 96.0)*scale_for(variant, action, direction)

static func frames(variant: int) -> SpriteFrames:
	if cache.has(variant): return cache[variant]
	var result := SpriteFrames.new()
	result.remove_animation("default")
	for action in ["idle", "walk", "attack", "hurt", "death"]:
		var source: String = "walk" if action == "idle" else action
		for direction in 8:
			var key: String = action+"_"+str(direction)
			result.add_animation(key)
			result.set_animation_loop(key, action == "walk")
			result.set_animation_speed(key, 7.5 if action == "walk" else 24.0 if action == "hurt" else 8.0)
			for frame in (1 if action == "idle" else 6):
				var item: Dictionary = data(variant)[source][direction*6+frame]
				var r: Array = item.rect
				var atlas := RouteArt.region(folder(variant)+source+".png",Rect2(r[0],r[1],r[2],r[3]))
				var pivot: Array = item.pivot
				atlas.margin = Rect2(Vector2(pivot[0],pivot[1]),Vector2(256-r[2],256-r[3]))
				atlas.set_meta("exclude",item.exclude)
				result.add_frame(key,atlas)
	cache[variant] = result
	return result
