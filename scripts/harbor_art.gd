class_name HarborArt
extends RefCounted
## Production atlases: measured alpha bounds and shared ground anchors prevent frame drift.
const FOLDER := "res://assets/harbor/"
static var metadata: Dictionary = {}
static var cache: Dictionary = {}
static func data() -> Dictionary:
	if metadata.is_empty(): metadata = JSON.parse_string(FileAccess.get_file_as_string(FOLDER+"regions.json"))
	return metadata
static func item(index: int, sheet: String = "props") -> AtlasTexture:
	var r: Array = data()[sheet][index]
	var tex := AtlasTexture.new()
	tex.atlas = load(FOLDER+sheet+".png")
	tex.region = Rect2(r[0],r[1],r[2],r[3])
	tex.filter_clip = true
	var cuts := PackedVector4Array()
	for cut in data().get(sheet+"_exclusions",[])[index] if data().has(sheet+"_exclusions") else []:
		cuts.append(Vector4(float(cut[0])/tex.atlas.get_width(),float(cut[1])/tex.atlas.get_height(),float(cut[0]+cut[2])/tex.atlas.get_width(),float(cut[1]+cut[3])/tex.atlas.get_height()))
	tex.set_meta("harbor_exclusions",cuts)
	return tex
static func frames(sheet: String) -> SpriteFrames:
	if cache.has(sheet): return cache[sheet]
	var result := SpriteFrames.new()
	result.remove_animation("default")
	var sequences := {"walk":[0,1,2,3,4,5],"idle":[6],"charge_ready":[6,7,8],"charge":[9,10],"rest":[11,17],"sweep_ready":[12,13],"sweep":[14,17],"slam_ready":[15],"slam":[16,17],"phase":[18,19],"hurt":[20],"death":[20,21,22,23]} if sheet.begins_with("boss") else {"walk":[0,1,2,3,4,5],"idle":[6],"talk":[6,7],"fear":[8,9],"seated":[10],"rescuer":[12,13,14],"guard":[15,16,17]}
	for action in sequences:
		result.add_animation(action)
		result.set_animation_loop(action,action in ["walk","idle","talk","rescuer","guard","rest"])
		result.set_animation_speed(action,8 if action=="walk" else 6)
		for index in sequences[action]:
			var tex := item(index,sheet)
			var r: Array = data()[sheet][index]
			# Fixed canvas dimensions retain original relative pose sizes. Feet share one baseline.
			var canvas: Array = data()[sheet+"_canvas"]
			tex.margin = Rect2((float(canvas[0])-float(r[2]))/2,float(canvas[1])-float(r[3]),float(canvas[0])-float(r[2]),float(canvas[1])-float(r[3]))
			result.add_frame(action,tex)
	cache[sheet] = result
	return result
static func npc(parent: Node, pos: Vector2, animation: String = "idle") -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames("npcs")
	sprite.position = pos
	var canvas: Array = data().npcs_canvas
	sprite.scale = Vector2.ONE*(62.0/float(canvas[1]))
	sprite.offset.y = -float(canvas[1])/2
	parent.add_child(sprite)
	MetroArt.cutout(sprite)
	sprite.play(animation)
	return sprite
static func dialogue(key: String) -> Array:
	var story: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FOLDER+"story.json"))
	return story[key].duplicate(true)

static func portrait(index: int) -> Texture2D:
	var texture: Texture2D = load(FOLDER+"portraits.png")
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(index*texture.get_width()/3.0,0,texture.get_width()/3.0,texture.get_height())
	atlas.filter_clip = true
	return atlas
static func boss_frames(phase_two: bool = false) -> SpriteFrames:
	var key := "boss_all_2" if phase_two else "boss_all"
	if cache.has(key): return cache[key]
	var sheet := "boss_phase2" if phase_two else "boss"
	var walk_sheet := "boss_walk_phase2" if phase_two else "boss_walk"
	var result := frames(sheet).duplicate() as SpriteFrames
	var canvas: Array = data().boss_canvas
	for d in 8:
		var row := d if d<=4 else 8-d
		var name_ := "walk_"+str(d)
		result.add_animation(name_)
		result.set_animation_loop(name_,true)
		result.set_animation_speed(name_,7)
		for i in 6:
			var index: int = row*6+i
			if phase_two and row==3: index = [21,22,23,22,21,22][i]
			var tex := item(index,walk_sheet)
			var r: Array = data()[walk_sheet][index]
			tex.margin = Rect2((float(canvas[0])-float(r[2]))/2,float(canvas[1])-float(r[3]),float(canvas[0])-float(r[2]),float(canvas[1])-float(r[3]))
			result.add_frame(name_,tex)
	cache[key] = result
	return result


