extends SceneTree
var app
var failures := 0
var out := "res://docs/screenshots/"
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
 if not ok: failures += 1
 print("PASS " if ok else "FAIL ",message)
func settle() -> void:
 for i in 4: await process_frame
func screenshot(label: String) -> void:
 if DisplayServer.get_name() == "headless" or "--capture-responsive" not in OS.get_cmdline_user_args(): return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+"responsive-"+label+".png")
func run() -> void:
 RouteSave.save_path = "res://tests/responsive_save.json"
 app = load("res://scenes/main.tscn").instantiate()
 root.add_child(app)
 await settle()
 for dims in [Vector2i(1152,648),Vector2i(1560,720),Vector2i(1600,720),Vector2i(1600,1200)]:
  root.size = dims
  await settle()
  var view := root.get_visible_rect().size
  check(absf(view.x/view.y-float(dims.x)/dims.y)<0.01,"viewport fills "+str(dims))
  app.show_menu()
  await settle()
  var bg = app.ui.screen.get_child(0)
  var bg_rect: Rect2 = bg.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,bg.size)
  check(bg_rect.grow(1).encloses(root.get_visible_rect()),"menu background fills viewport")
  await screenshot(str(dims.x)+"x"+str(dims.y)+"-menu")
  app.ui.show_menu_hint("Continuar historia","Empieza una nueva historia para guardar tu progreso.")
  await settle()
  await screenshot(str(dims.x)+"x"+str(dims.y)+"-hint")
  app.ui.close_pause()
  for n in range(1,9):
   app.start_route(false,n)
   await settle()
   var level = app.level
   for x in [160.0,level.world_length-50]:
    level.player.position.x=x
    level.update_camera()
    var half: float = view.x/level.camera.zoom.x/2.0
    check(level.camera.position.x-half>=-0.1 and level.camera.position.x+half<=level.world_length+0.1,"camera bounds "+str(n)+" "+str(dims))
   if true:
    app.ui.dialog.hide()
    app.ui.dialogue_active=false
    level.blocked=false
    app.touch.refresh()
    await settle()
    await screenshot(str(dims.x)+"x"+str(dims.y)+"-level"+str(n))
   app.show_menu()
   await settle()
  app.start_route(false,2)
  await settle()
  app.ui.dialogue_active=false
  app.ui.dialog.hide()
  app.level.blocked=false
  app.touch.refresh()
  var layout=app.get_node("ResponsiveLayout")
  var safe=Rect2(20,4,view.x-40,view.y-8)
  layout.apply_safe_area(safe)
  for key in app.touch.areas:
   var hit: Rect2 = app.touch.get_global_transform_with_canvas()*app.touch.areas[key]
   check(safe.grow(1).encloses(hit),"safe touch "+key)
  check(app.touch.press_finger(10,app.touch.joystick_center),"joystick uses adapted coordinates")
  app.touch.move_stick(app.touch.joystick_center+Vector2(30,0))
  check(RouteControls.virtual_move.x>0.8,"joystick moves right")
  app.touch.release_finger(10)
  layout.refresh_layout(true)
  app.start_intro()
  await settle()
  await screenshot(str(dims.x)+"x"+str(dims.y)+"-intro")
  app.show_menu()
  await settle()
 for number in range(1,9): RouteSave.mark_level_completed(number)
 app.start_survival()
 await settle()
 check(app.level is SurvivalLevel,"survival starts with responsive layout")
 for scenery in range(8):
  app.level.set_scenery(scenery)
  app.level.update_camera(0.0)
  await settle()
  await screenshot("survival-"+str(scenery))
 app.pause_route()
 await settle()
 check(paused,"pause works in responsive survival")
 await screenshot("pause")
 app.resume_route()
 app.queue_free()
 await settle()
 for suffix in ["", ".tmp", ".progress", ".progress.tmp"]:
  if FileAccess.file_exists(RouteSave.save_path+suffix): DirAccess.remove_absolute(RouteSave.save_path+suffix)
 print("RESPONSIVE_FAILURES=",failures)
 quit(failures)
