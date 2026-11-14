extends RefCounted
## Six distinct poses per step cycle. Opposite directions share mirrored art.
## Regions and pivots keep the head steady without moving the collision body.
static var cached_frames: Dictionary = {}
static var regions: Array = []
const SHEET := "characters/nico/nico_lateral_walk_v03.png"
const POSES := [1, 2, 0, 4, 5, 3]
# Passing poses last longer; extended contact poses are brief transitions.
const WEIGHTS := [1.6, 0.65, 0.65, 1.6, 0.65, 0.65]
const CYCLE_DISTANCE := 44.0

static func sample(distance: float) -> Vector2:
	var phase := fposmod(distance, CYCLE_DISTANCE) / CYCLE_DISTANCE * 5.8
	for index in 6:
		if phase < WEIGHTS[index]: return Vector2(index, phase / WEIGHTS[index])
		phase -= WEIGHTS[index]
	return Vector2.ZERO

static func supports(direction: int) -> bool:
	return direction in [1, 2, 3, 5, 6, 7]

static func row_for(direction: int, armed: bool) -> int:
	var row := 0 if direction in [2, 6] else 1 if direction in [1, 7] else 2
	return row + (3 if armed else 0)

static func flipped(direction: int, armed: bool) -> bool:
	# The rear knife row faces NE; all other source rows face left.
	if not armed and direction in [3, 5]: return direction == 3
	return direction > 4

static func data() -> Array:
	if regions.is_empty():
		regions = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/nico/nico_lateral_walk_v03.json"))
	return regions

static func scale_for(direction: int, armed: bool) -> float:
	return 55.0 / float(data()[row_for(direction, armed) * 6].height)

static func ground(direction: int, armed: bool) -> float:
	return (40.0 + float(data()[row_for(direction, armed) * 6].height) - 128.0) * scale_for(direction, armed)

static func frames(armed: bool) -> SpriteFrames:
	if cached_frames.has(armed): return cached_frames[armed]
	var result := SpriteFrames.new()
	result.remove_animation("default")
	for direction in [1, 2, 3, 5, 6, 7]:
		for action in ["walk", "idle"]:
			var key: String = action + "_" + str(direction)
			result.add_animation(key)
			result.set_animation_loop(key, action == "walk")
			result.set_animation_speed(key, 12.0)
			for frame in (6 if action == "walk" else 1):
				var item: Dictionary = data()[row_for(direction, armed) * 6 + POSES[frame]]
				var r: Array = item.rect
				var atlas := RouteArt.region(SHEET, Rect2(r[0], r[1], r[2], r[3]))
				atlas.margin = Rect2(Vector2(128.0 - float(item.head_x), 40.0), Vector2(256-r[2], 256-r[3]))
				result.add_frame(key, atlas, WEIGHTS[frame])
	cached_frames[armed] = result
	return result
