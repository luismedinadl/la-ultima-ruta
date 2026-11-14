extends SceneTree
var failures := 0
func _initialize(): call_deferred("run")
func run():
 var ui := RouteUI.new()
 root.add_child(ui)
 for mobile in [false,true]:
  ui.mobile_layout(mobile)
  ui.menu(false)
  ui.root.scale = Vector2(0.8,0.8)
  ui.root.position = Vector2(20,12)
  for child in ui.screen.get_children():
   if child is Button and child.disabled:
    var event: InputEvent
    if mobile:
     event = InputEventScreenTouch.new()
     event.index = 0
    else:
     event = InputEventMouseButton.new()
     event.button_index = MOUSE_BUTTON_LEFT
    event.pressed = true
    event.position = child.get_global_transform_with_canvas()*(child.size/2)
    ui._input(event)
    if not is_instance_valid(ui.pause_panel) or not child.disabled: failures += 1
    else: print("PASS hint: ",child.text," touch=",mobile)
    ui.close_pause()
    await process_frame
 ui.queue_free()
 await process_frame
 print("MENU_HINT_FAILURES=",failures)
 quit(failures)
