class_name RouteControls
extends RefCounted
## All gameplay reads actions through this adapter. A future touch UI can feed
## virtual_move / virtual_attack without altering actors or wave rules.
static var virtual_move := Vector2.ZERO
static var virtual_attack := false
static var touch_mode := false
static var touch_only := OS.has_feature("android")

static func release_touch() -> void:
	virtual_move = Vector2.ZERO
	virtual_attack = false

static func setup() -> void:
	var keys := {
		"route_left": [KEY_A, KEY_LEFT], "route_right": [KEY_D, KEY_RIGHT],
		"route_up": [KEY_W, KEY_UP], "route_down": [KEY_S, KEY_DOWN],
		"route_attack": [KEY_SPACE], "route_interact": [KEY_E, KEY_ENTER],
		"route_pause": [KEY_ESCAPE], "route_reload": [KEY_R], "route_switch": [KEY_Q]
	}
	for action in keys:
		if not InputMap.has_action(action): InputMap.add_action(action)
		if touch_only:
			InputMap.action_erase_events(action)
			continue
		for key in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

	if not InputMap.has_action("route_shoot"): InputMap.add_action("route_shoot")
	if touch_only:
		InputMap.action_erase_events("route_shoot")
		return
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("route_shoot",mouse)

static func movement() -> Vector2:
	return (Input.get_vector("route_left", "route_right", "route_up", "route_down") + virtual_move).limit_length()

static func attacking() -> bool:
	# A touch may emulate a mouse click for menus, but must never fire a weapon.
	return Input.is_action_just_pressed("route_attack") or (not touch_mode and Input.is_action_just_pressed("route_shoot")) or virtual_attack

static func direction_index(vector: Vector2) -> int:
	# Sprite row order S, SW, W, NW, N, NE, E, SE.
	return posmod(int(round((vector.angle() - PI / 2.0) / (PI / 4.0))), 8)
