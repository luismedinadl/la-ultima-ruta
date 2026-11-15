class_name RouteArt
extends RefCounted
## Atlas access keeps approved source PNGs unchanged. Pixel filtering is Nearest.

static var textures: Dictionary = {}
static var frame_cache: Dictionary = {}
static var anchor_cache: Dictionary = {}
static var character_regions: Dictionary = {}

static func texture(path: String) -> Texture2D:
	if not textures.has(path):
		textures[path] = load("res://assets/" + path)
	return textures[path]

static func region(path: String, rect: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture(path)
	atlas.region = rect
	atlas.filter_clip = true
	return atlas

static func cell(path: String, columns: int, rows: int, column: int, row: int, inset: float = 0.0) -> AtlasTexture:
	var tex := texture(path)
	var size := Vector2(tex.get_width(), tex.get_height()) / Vector2(columns, rows)
	return region(path, Rect2(Vector2(column, row) * size + Vector2.ONE * inset, size - Vector2.ONE * inset * 2.0))

static func character_data(path: String, column: int, row: int) -> Dictionary:
	if character_regions.is_empty():
		character_regions = JSON.parse_string(FileAccess.get_file_as_string("res://assets/character_regions.json"))
	return character_regions[path][row * 6 + column]

static func character_frame(path: String, column: int, row: int) -> AtlasTexture:
	var data := character_data(path, column, row)
	var r: Array = data.rect
	var atlas := region(path, Rect2(r[0], r[1], r[2], r[3]))
	# Keep the original cell pivot while cropping each irregularly spaced figure.
	atlas.margin = Rect2(Vector2(r[0] - data.origin[0] + 64, r[1] - data.origin[1] + 64), Vector2(data.canvas[0] + 128 - r[2], data.canvas[1] + 128 - r[3]))
	atlas.set_meta("exclude", data.exclude)
	return atlas

static func bind_character_clip(sprite: AnimatedSprite2D) -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/character_clip.gdshader")
	sprite.material = material
	var refresh := func() -> void:
		if not sprite.sprite_frames.has_animation(sprite.animation): return
		var frame_texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
		var exclusions: Array = frame_texture.get_meta("exclude", [])
		var rectangles: Array[Vector4] = []
		rectangles.resize(256)
		rectangles.fill(Vector4.ZERO)
		for i in exclusions.size():
			var r: Array = exclusions[i]
			rectangles[i] = Vector4(r[0], r[1], r[2], r[3])
		material.set_shader_parameter("excluded_count", exclusions.size())
		material.set_shader_parameter("excluded_rects", rectangles)
	sprite.frame_changed.connect(refresh)
	sprite.animation_changed.connect(refresh)

static func frames(kind: String) -> SpriteFrames:
	if frame_cache.has(kind):
		return frame_cache[kind]
	var result := SpriteFrames.new()
	result.remove_animation("default")
	var actions: Array[String] = ["idle", "walk", "hurt", "death"]
	if kind == "nico":
		actions.append_array(["knife_attack", "pickup_package", "delivery"])
	else:
		actions.append("attack")
	for action in actions:
		var folder := "characters/nico/" if kind == "nico" else "enemies/zombie/"
		var file := kind + "_" + action + ("_v02" if action == "walk" else "") + ".png"
		# Idle uses the walk contact pose so starting movement cannot swap
		# to a differently leaning body from the separate concept sheet.
		if action == "idle": file = kind + "_walk_v02.png"
		for direction in range(8):
			var key: String = action + "_" + str(direction)
			result.add_animation(key)
			result.set_animation_loop(key, action in ["idle", "walk"])
			var fps := 10.0
			if action == "idle": fps = 5.0
			elif action == "walk": fps = 15.0 if kind == "nico" else 7.5
			elif action == "hurt": fps = 16.0
			elif action in ["death", "pickup_package", "delivery"]: fps = 8.0
			elif action in ["knife_attack", "attack"]: fps = 14.0 if kind == "nico" else 8.0
			result.set_animation_speed(key, fps)
			# Nico's NW reference faces NE: use the NE row and flip at the sprite.
			var source_direction := 5 if kind == "nico" and direction == 3 else direction
			for frame in range(6):
				var duration := 1.0
				if action == "knife_attack": duration = [1.4, 1.1, 0.7, 0.8, 1.2, 1.6][frame]
				result.add_frame(key, character_frame(folder + file, frame, source_direction), duration)
	frame_cache[kind] = result
	return result

static func nico_anchor(action: String, direction: int, frame: int) -> Vector2:
	if action == "idle": action = "walk"
	var row := 5 if direction == 3 else direction
	var suffix := "_v02" if action == "walk" else ""
	var data := character_data("characters/nico/nico_" + action + suffix + ".png", frame, row)
	return Vector2(data.head[0], data.head[1])

static func zombie_walk_anchor(direction: int, frame: int) -> Vector2:
	var data := character_data("enemies/zombie/zombie_walk_v02.png", frame, direction)
	return Vector2(data.head[0], data.head[1])

static func prop(index: int) -> AtlasTexture:
	if index == 8:
		# The barricade straddles two grid cells. Center it over its collider
		# and retain the original cell scale and distance from the ground.
		var barricade := region("props/props.png", Rect2(790, 328, 243, 214))
		barricade.margin = Rect2(16, 45, 32, 61)
		return barricade
	# The car is wider than a nominal grid cell; include the full bumper,
	# wheels and ground shadow, without the adjacent police barrier.
	if index == 9:
		return region("props/props.png", Rect2(1034, 296, 360, 260))
	return cell("props/props.png", 5, 4, index % 5, floori(index / 5.0), 3.0)

static func fx(row: int, frame: int) -> AtlasTexture:
	return cell("effects/effects_v02.png", 6, 10, frame, row, 5.0)

static func portrait(index: int) -> AtlasTexture:
	return cell("ui/portraits.png", 4, 1, index, 0)

static var pistol_regions: Dictionary = {}
static func pistol_data() -> Dictionary:
	if pistol_regions.is_empty(): pistol_regions = JSON.parse_string(FileAccess.get_file_as_string("res://assets/pistol_regions.json"))
	return pistol_regions

static func weapon_item(index: int) -> AtlasTexture:
	var r: Array = pistol_data().items[index]
	return region("weapons/pistol_kit.png",Rect2(r[0],r[1],r[2],r[3]))

static func pistol_row(action: String, direction: int) -> int:
	if action == "walk": return [0,1,2,3,4,3,5,6][direction]
	if action == "shoot": return [0,1,2,5,4,5,6,1][direction]
	return 3 if direction == 5 else direction

static func pistol_flip(action: String, direction: int) -> bool:
	if action == "walk": return direction == 5
	if action == "shoot": return direction in [3,7]
	return direction == 5

static func pistol_height(action: String, direction: int) -> float:
	return float(pistol_data()[action][pistol_row(action,direction)*6].height)

static func pistol_frames() -> SpriteFrames:
	if frame_cache.has("pistol"): return frame_cache.pistol
	var result := SpriteFrames.new()
	result.remove_animation("default")
	for action in ["idle","walk","shoot","reload","equip","hurt","death","pickup_package","delivery"]:
		var source: String = "walk" if action == "idle" else "reload" if action in ["pickup_package","delivery","equip"] else action
		for direction in 8:
			var key: String = action + "_" + str(direction)
			result.add_animation(key)
			result.set_animation_loop(key,action in ["idle","walk"])
			result.set_animation_speed(key,15 if action == "walk" else 24 if action == "shoot" else 20 if action == "equip" else 5 if action == "reload" else 20 if action == "hurt" else 8)
			var row := pistol_row(source,direction)
			var ref_height := pistol_height(source,direction)
			for frame in 6:
				var data: Dictionary = pistol_data()[source][row*6+frame]
				var r: Array = data.rect
				var atlas := region("characters/nico_pistol/"+source+".png",Rect2(r[0],r[1],r[2],r[3]))
				# Fixed canvas with a stable top anchor; death instead rests on the floor.
				atlas.margin = Rect2(Vector2(256-data.head[0],338-(r[3] if source == "death" else ref_height+data.head[1])),Vector2(512-r[2],512-r[3]))
				result.add_frame(key,atlas)
	frame_cache.pistol = result
	return result

static func freight_facade(index: int) -> AtlasTexture:
	var rects := [Rect2(18,98,508,387),Rect2(544,65,514,419),Rect2(1080,89,437,396),Rect2(15,595,547,343),Rect2(573,540,474,398),Rect2(1062,541,457,397)]
	return region("tiles/freight_facades.png",rects[index])
