extends Control
## One owner per finger. Movement/attack may be held; other actions fire once.
## Rendering uses the approved raster atlas, never procedural icon drawing.
var app: Node
var fingers: Dictionary = {}
var buttons: Dictionary = {}
var areas: Dictionary = {}
var icons: Dictionary = {}
var textures: Dictionary = {}
var stick: TextureRect
var cap: TextureRect
var enabled := false
var combat := false
var top_active := false
var input_context := ""
var joystick_center := Vector2(60, 266)
var atlas: Texture2D
var base_areas: Dictionary = {}
var left_extension := 0.0
var bottom_extension := 0.0
const FOLDER := "res://assets/ui/touch/"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(576, 324)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	atlas = load(FOLDER + "controls_atlas.png")
	stick = picture(region(Rect2(28,640,220,215)), Rect2(16,222,88,88))
	cap = picture(region(Rect2(289,682,126,123)), Rect2(44,250,32,32))
	add_button("attack", 0, Rect2(480,238,64,64))
	add_button("reload", 3, Rect2(422,207,44,44))
	add_button("switch", 4, Rect2(422,268,44,44))
	add_button("interact", 5, Rect2(496,174,48,48))
	add_button("pause", 6, Rect2(520,2,48,44),32)
	add_button("documents", 7, Rect2(468,2,48,44),32)
	base_areas = areas.duplicate(true)
	for key in buttons: buttons[key].set_meta("base_position",buttons[key].position)
	set_enabled(OS.has_feature("mobile") or DisplayServer.is_touchscreen_available() or "--touch" in OS.get_cmdline_user_args())
	get_viewport().size_changed.connect(update_safe_area)

func region(rect: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = rect
	texture.filter_clip = true
	return texture

func icon(column: int, state: int) -> Texture2D:
	var key := Vector2i(column,state)
	if not textures.has(key):
		var xs := [40,256,470,686,900,1112,1328,1543]
		var ys := [52,250,444]
		textures[key] = region(Rect2(xs[column],ys[state],192,182))
	return textures[key]

func picture(texture: Texture2D, rect: Rect2) -> TextureRect:
	return app.ui.image_rect(self,texture,rect)

func add_button(key: String, column: int, rect: Rect2, visual_size: float = 0) -> void:
	var hit_size := Vector2(maxf(48,rect.size.x),maxf(48,rect.size.y))
	areas[key] = Rect2(rect.get_center()-hit_size/2,hit_size)
	icons[key] = column
	var visual := rect
	if visual_size > 0: visual = Rect2(rect.get_center()-Vector2.ONE*visual_size/2,Vector2.ONE*visual_size)
	buttons[key] = picture(icon(column,0),visual)

func set_enabled(value: bool) -> void:
	enabled = value or RouteControls.touch_only
	RouteControls.touch_mode = enabled
	reset()
	visible = enabled
	app.ui.mobile_layout(enabled)
	update_safe_area()
	if app.mode == "menu" and is_instance_valid(app.ui.screen):
		app.ui.menu(not RouteSave.read_data().is_empty())

func update_safe_area() -> void:
	# The shared layout owns the safe area for HUD, menus and touch controls.
	if app.has_node("ResponsiveLayout"): app.get_node("ResponsiveLayout").refresh_layout(true)

func fit_safe_area(rect: Rect2) -> void:
	if app.has_node("ResponsiveLayout"): app.get_node("ResponsiveLayout").apply_safe_area(rect)

func layout_controls(extension: float, extra_y: float = 0.0) -> void:
	if not is_instance_valid(stick): return
	left_extension = extension
	bottom_extension = extra_y
	joystick_center = Vector2(60-extension,266+extra_y)
	stick.position = Vector2(16-extension,222+extra_y)
	for key in buttons:
		var offset := Vector2(extension,-extra_y if key in ["pause","documents"] else extra_y)
		buttons[key].position = buttons[key].get_meta("base_position") + offset
		areas[key] = Rect2(base_areas[key].position+offset,base_areas[key].size)
	reset()

func reset() -> void:
	fingers.clear()
	RouteControls.release_touch()
	if is_instance_valid(cap): cap.position = joystick_center-cap.size/2

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		reset()
		# Notifications traverse the UI tree with its children locked. Wait until
		# traversal ends before pause_route adds the pause panel to that tree.
		pause_after_focus_loss.call_deferred()

func pause_after_focus_loss() -> void:
	# A queued focus event may arrive after returning to the menu or exiting.
	if not is_inside_tree() or not is_instance_valid(app) or not app.is_inside_tree(): return
	if app.mode == "playing" and not get_tree().paused:
		app.pause_route()

func _exit_tree() -> void: reset()

func refresh() -> void:
	if not enabled: return
	var live: bool = app.mode == "playing" and is_instance_valid(app.level)
	var playing: bool = live and not get_tree().paused and not app.ui.dialogue_active and not app.level.blocked and not app.level.player.dead
	var context: String = app.mode+str(get_tree().paused)+str(app.ui.dialogue_active)+str(playing)+str(is_instance_valid(app.ui.pause_panel))
	if context != input_context:
		reset()
		input_context = context
	combat = playing
	top_active = live and not get_tree().paused and not is_instance_valid(app.ui.pause_panel)
	stick.visible = combat
	cap.visible = combat
	stick.modulate.a = 0.75 if not fingers.values().has("move") else 0.95
	for key in buttons: buttons[key].visible = combat
	buttons.pause.visible = top_active
	buttons.documents.visible = combat and (app.level is DistributionLevel or app.level is BroadcastLevel)
	if not combat: return
	var player: RoutePlayer = app.level.player
	icons.attack = 2 if player is ShotgunPlayer and player.weapon_slot == 2 else 1 if player.pistol_equipped else 0
	buttons.switch.visible = player.has_pistol
	buttons.reload.visible = player.has_pistol and player.pistol_equipped
	buttons.interact.visible = not app.level.interaction_action().is_empty()
	for key in buttons:
		var disabled := not available(key)
		buttons[key].texture = icon(icons[key],2 if disabled else 1 if fingers.values().has(key) else 0)
		buttons[key].modulate.a = 1.0 if fingers.values().has(key) else 0.86
	# If the finger slides off or the contextual action disappears, release it.
	for id in fingers.keys():
		var action: String = fingers[id]
		if action != "move" and not buttons[action].visible: release_finger(id)

func available(key: String) -> bool:
	if key == "pause": return top_active
	if not combat: return false
	var player: RoutePlayer = app.level.player
	if key == "reload":
		if player.action_time > 0: return false
		if player is ShotgunPlayer and player.weapon_slot == 2:
			return player.shells < player.SHELL_CAPACITY and player.shell_reserve > 0
		return player.magazine < 12 and player.reserve > 0
	if key in ["switch","interact"]: return player.action_time <= 0
	return true

func _process(_delta: float) -> void: refresh()

func move_stick(point: Vector2) -> void:
	var offset := (point-joystick_center).limit_length(32)
	RouteControls.virtual_move = Vector2.ZERO if offset.length()<6 else offset.normalized()*minf((offset.length()-6)/22,1)
	cap.position = joystick_center+offset-cap.size/2

func release_finger(id: int) -> void:
	var action: String = fingers.get(id,"")
	fingers.erase(id)
	if action == "move":
		RouteControls.virtual_move = Vector2.ZERO
		cap.position = joystick_center-cap.size/2
	if action == "attack": RouteControls.virtual_attack = false

func press_finger(id: int, point: Vector2) -> bool:
	refresh()
	if app.ui.dialogue_active and not get_tree().paused and app.ui.dialog.get_rect().has_point(point):
		reset()
		app.ui.advance_dialogue()
		return true
	for key in buttons:
		if buttons[key].visible and areas[key].has_point(point):
			if not available(key) or fingers.values().has(key): return true
			fingers[id] = key
			match key:
				"attack": RouteControls.virtual_attack = true
				"reload": app.level.player.begin_reload()
				"switch": app.level.player.switch_weapon()
				"interact": app.level.interact()
				"pause": app.pause_route()
				"documents": app.handle_command("documents")
			return true
	if combat and Rect2(8-left_extension,210+bottom_extension,110,106).has_point(point) and not fingers.values().has("move"):
		fingers[id] = "move"
		move_stick(point)
		return true
	return false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and not enabled:
		set_enabled(true)
	if not enabled: return
	var consumed := false
	if event is InputEventScreenTouch:
		var point: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
		if not event.pressed or event.canceled:
			consumed = fingers.has(event.index)
			release_finger(event.index)
		else: consumed = press_finger(event.index,point)
	elif event is InputEventScreenDrag and fingers.has(event.index):
		var point: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
		var action: String = fingers[event.index]
		if action == "move": move_stick(point)
		elif not areas[action].grow(6).has_point(point): release_finger(event.index)
		consumed = true
	if consumed: get_viewport().set_input_as_handled()
