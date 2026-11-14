extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
 if not ok: failures+=1
 print("PASS " if ok else "FAIL ",label)
func settle() -> void:
 for i in 4: await process_frame
func touch_at(control: Control, local: Vector2, id: int, down: bool) -> void:
 var ev := InputEventScreenTouch.new()
 ev.index=id
 ev.pressed=down
 ev.position=control.get_global_transform_with_canvas()*local
 root.push_input(ev,true)
func run() -> void:
 RouteSave.save_path="res://tests/responsive_input_save.json"
 var app=load("res://scenes/main.tscn").instantiate()
 root.add_child(app)
 await settle()
 check(not app.touch.enabled,"PC keeps keyboard and mouse by default")
 check(root.content_scale_aspect==Window.CONTENT_SCALE_ASPECT_KEEP,"PC keeps original 16 by 9")
 root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
 root.content_scale_stretch=Window.CONTENT_SCALE_STRETCH_FRACTIONAL
 root.size=Vector2i(1560,720)
 app.touch.set_enabled(true)
 app.start_route(false,8)
 await settle()
 if app.mode=="pistol_scene": app.ui.screen.finish()
 await settle()
 while app.ui.dialogue_active:
  app.ui.dialog_text.visible_characters=-1
  app.ui.advance_dialogue()
 app.level.blocked=false
 app.touch.refresh()
 app.level.player.action_time=0
 touch_at(app.touch,app.touch.joystick_center+Vector2(25,0),1,true)
 touch_at(app.touch,app.touch.areas.attack.get_center(),2,true)
 check(RouteControls.virtual_move.x>0.7 and RouteControls.virtual_attack,"transformed multitouch move plus attack")
 touch_at(app.touch,app.touch.areas.attack.get_center(),2,false)
 touch_at(app.touch,app.touch.joystick_center,1,false)
 check(RouteControls.virtual_move==Vector2.ZERO and not RouteControls.virtual_attack,"release clears transformed inputs")
 app.ui.start_dialogue([{"name":"NICO","portrait":1,"text":"La salida está cerca."}])
 app.ui.dialog_text.visible_characters=-1
 touch_at(app.ui.dialog,Vector2(200,50),3,true)
 touch_at(app.ui.dialog,Vector2(200,50),3,false)
 check(not app.ui.dialogue_active,"tap advances responsive dialogue")
 app.touch.refresh()
 touch_at(app.touch,app.touch.areas.pause.get_center(),4,true)
 touch_at(app.touch,app.touch.areas.pause.get_center(),4,false)
 check(paused,"tap pauses from screen edge")
 app.resume_route()
 app.show_menu()
 for n in range(1,9): RouteSave.mark_level_completed(n)
 app.ui.route_select()
 await settle()
 var scroll=app.ui.screen.find_children("*","ScrollContainer",true,false)
 check(scroll.size()==1,"mobile level list remains scrollable")
 app.queue_free()
 await settle()
 for suffix in ["", ".tmp", ".progress", ".progress.tmp"]:
  if FileAccess.file_exists(RouteSave.save_path+suffix): DirAccess.remove_absolute(RouteSave.save_path+suffix)
 print("RESPONSIVE_INPUT_FAILURES=",failures)
 quit(failures)

