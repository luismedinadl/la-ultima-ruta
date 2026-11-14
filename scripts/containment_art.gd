class_name ContainmentArt
extends RefCounted
## Original sheets remain intact; measured per-pose crops prevent neighbouring sprites leaking.
static var metadata: Dictionary = {}
static var caches: Dictionary = {}
static func records(folder: String) -> Dictionary:
	if not metadata.has(folder):
		metadata[folder] = JSON.parse_string(FileAccess.get_file_as_string("res://assets/"+folder+"/regions.json"))
	return metadata[folder]
static func row(direction: int) -> int:
	return [0,1,2,3,4,3,2,1][direction]
static func size_scale(folder: String) -> float:
	return float(records(folder).scale)
static func ground(folder: String, direction: int) -> float:
	var pose: Dictionary = records(folder).walk[row(direction)*6]
	return (float(pose.rect[3])-float(pose.anchor[1]))*size_scale(folder)
static func item(index: int) -> AtlasTexture:
	var pose: Dictionary = records("containment").props[index]
	var r: Array = pose.rect
	var texture := RouteArt.region("containment/props.png",Rect2(r[0],r[1],r[2],r[3]))
	texture.set_meta("exclude",pose.get("exclude",[]))
	return texture
static func cutout(sprite: Sprite2D) -> void:
	MetroArt.cutout(sprite)
	var excluded: Array = sprite.texture.get_meta("exclude",[])
	var rectangles: Array[Vector4] = []
	rectangles.resize(256)
	rectangles.fill(Vector4.ZERO)
	for i in excluded.size():
		var r: Array = excluded[i]
		rectangles[i] = Vector4(r[0],r[1],r[2],r[3])
	(sprite.material as ShaderMaterial).set_shader_parameter("excluded_count",excluded.size())
	(sprite.material as ShaderMaterial).set_shader_parameter("excluded_rects",rectangles)
static func frames(folder: String, armed: bool = false) -> SpriteFrames:
	if caches.has(folder): return caches[folder]
	var result := SpriteFrames.new()
	result.remove_animation("default")
	var actions := ["idle","walk","shoot","reload","equip","pickup_package","delivery","hurt","death"] if armed else ["idle","walk","attack","hurt","death"]
	for action in actions:
		var sheet: String = "walk" if action in ["idle","walk"] else "hurt_death" if action in ["hurt","death"] else "shoot_reload" if armed else "attack"
		var count := 3 if sheet != "walk" and sheet != "attack" else 6
		var column := 3 if action in ["death","reload","equip","pickup_package","delivery"] else 0
		for direction in 8:
			var name_: String = action+"_"+str(direction)
			result.add_animation(name_)
			result.set_animation_loop(name_,action in ["idle","walk"])
			result.set_animation_speed(name_,12 if action == "walk" else 8 if action == "attack" else 4 if action == "death" else 5)
			for frame in count:
				var p: Dictionary = records(folder)[sheet][row(direction)*6+column+frame]
				var r: Array = p.rect
				var texture := RouteArt.region(folder+"/"+str(p.get("sheet",sheet))+".png",Rect2(r[0],r[1],r[2],r[3]))
				texture.set_meta("exclude",p.get("exclude",[]))
				var pivot := Vector2(256-float(p.anchor[0]),400-float(r[3]) if action == "death" else 256-float(p.anchor[1]))
				texture.margin = Rect2(pivot,Vector2(512-r[2],512-r[3]))
				result.add_frame(name_,texture)
	caches[folder] = result
	return result
static func opening() -> Array:
	return [
		{"name":"JEFE","portrait":3,"text":"Ve a recepción y espera allí. No entres en las zonas del personal."},
		{"name":"NICO","portrait":1,"text":"No hay nadie. Solo veo cajas y jaulas. Dijiste que aquí evacuaban gente."},
		{"name":"JEFE","portrait":3,"text":"Debería haber personal en recepción. Quédate ahí. Voy a consultar qué pasó."},
		{"name":"NICO","portrait":1,"text":"Hay infectados entrando por donde vine. No puedo quedarme aquí."},
		{"name":"NICO","portrait":1,"text":"Veo un letrero de salida de emergencia. Voy a buscar cómo abrirla."},
		{"name":"NICO","portrait":1,"text":"¿Qué llevaban los paquetes que entregué?"},
		{"name":"JEFE","portrait":3,"text":"Aparatos electrónicos de la empresa. Tú espera en recepción."},
		{"name":"JEFE","portrait":3,"text":"Nico, espera mis instrucciones."},
		{"name":"NICO","portrait":2,"text":"Ya esperé bastante. Voy a buscar otra salida."}]
static func document(index: int) -> Dictionary:
	return [
		{"name":"REGISTRO DE TRASLADO · 04:18","document":true,"text":"No permitan que los inspectores sanitarios abran los paquetes de la ruta este.\n\nSi algo se mueve dentro de una caja al escuchar ruido, detengan el traslado y avisen al supervisor.\n\nNo informen al repartidor ni escriban lo ocurrido en su registro de entrega."},
		{"name":"ORDEN DE EVACUACIÓN · ANEXO C","document":true,"text":"Se cancela la evacuación de los civiles. Los vehículos solo llevarán las muestras y a los responsables del proyecto.\n\nDigan a los repartidores que todavía hay lugares para ellos, aunque no sea cierto, para que completen las entregas.\n\nMantengan cerradas las jaulas. Los infectados que están dentro son peligrosos."}][index]
