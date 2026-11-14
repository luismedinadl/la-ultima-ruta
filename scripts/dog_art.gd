class_name DogArt
extends RefCounted
## Original PNGs stay intact; each pose has an independently measured crop/pivot.
const SCALE := 0.32
static var data: Dictionary = {}
static var cache: SpriteFrames
static func records() -> Dictionary:
	if data.is_empty(): data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/enemies/infected_dog/regions.json"))
	return data
static func row(direction: int) -> int:
	return [0,1,2,3,4,3,2,1][direction]
static func ground_offset(direction: int) -> float:
	var pose: Dictionary = records().walk[row(direction)*6]
	return (float(pose.rect[3])-float(pose.anchor[1]))*SCALE
static func frames() -> SpriteFrames:
	if cache != null: return cache
	cache = SpriteFrames.new()
	cache.remove_animation("default")
	for action in ["idle","walk","attack","hurt","death"]:
		var sheet: String = "walk" if action == "idle" else "hurt_death" if action in ["hurt","death"] else action
		var count := 3 if action in ["hurt","death"] else 6
		for direction in 8:
			var name_: String = action+"_"+str(direction)
			cache.add_animation(name_)
			cache.set_animation_loop(name_,action in ["idle","walk"])
			cache.set_animation_speed(name_,14 if action == "walk" else 10 if action == "attack" else 12 if action == "hurt" else 5)
			for frame in count:
				var pose: Dictionary = records()[sheet][row(direction)*6+frame+(3 if action == "death" else 0)]
				var r: Array = pose.rect
				var texture := RouteArt.region("enemies/infected_dog/"+sheet+".png",Rect2(r[0],r[1],r[2],r[3]))
				var pivot := Vector2(160-float(pose.anchor[0]),288-float(r[3]) if action == "death" else 160-float(pose.anchor[1]))
				texture.margin = Rect2(pivot,Vector2(320-r[2],320-r[3]))
				cache.add_frame(name_,texture)
	return cache
