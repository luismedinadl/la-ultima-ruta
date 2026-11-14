extends ScrollContainer
## Native buttons remain clickable; dragging cancels their pending press.
var finger := -1
var origin := Vector2.ZERO
var last := Vector2.ZERO
var dragging := false
var disabled_buttons: Array[Button] = []

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventScreenTouch:
		var point: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
		if event.pressed and finger == -1 and Rect2(Vector2.ZERO,size).has_point(point):
			finger = event.index
			origin = point
			last = point
			dragging = false
		elif not event.pressed and event.index == finger:
			finger = -1
			if dragging: get_viewport().set_input_as_handled()
			dragging = false
			restore_buttons.call_deferred()
	elif event is InputEventScreenDrag and event.index == finger:
		var point: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
		if not dragging and point.distance_to(origin) > 8:
			dragging = true
			for child in find_children("*","Button",true,false):
				if not child.disabled:
					disabled_buttons.append(child)
					child.disabled = true
		if dragging:
			scroll_vertical += roundi(last.y-point.y)
			get_viewport().set_input_as_handled()
		last = point

func restore_buttons() -> void:
	for button in disabled_buttons:
		if is_instance_valid(button): button.disabled = false
	disabled_buttons.clear()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]:
		finger = -1
		dragging = false
		restore_buttons()
