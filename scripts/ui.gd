class_name RouteUI
extends CanvasLayer
## Screens share one visual theme. Dialogues own input until the last line.
signal command(action: String)
signal dialogue_finished

const INK := Color("111a2b")
const PAPER := Color("eee5d7")
const CYAN := Color("83b9bb")
const ORANGE := Color("d68a49")
var root: Control
var screen: Control
var hud: Control
var objective: Label
var health: ProgressBar
var health_text: Label
var stats: Label
var ammo_panel: Panel
var ammo_text: Label
var weapon_icon: TextureRect
var documents_button: Button
var hint: Label
var zone_text: Label
var dialog: Panel
var dialog_name: Label
var dialog_text: Label
var dialog_face: TextureRect
var dialog_next: Label
var pause_panel: Control
var dialogue_active := false
var lines: Array = []
var line_index := 0
var reveal := 0.0
var zone_timeout := 0.0
var mobile := false
var hint_finger := -1
var hint_target: Button
var header: Panel

func mobile_layout(value: bool) -> void:
	mobile = value
	header.size.y = 44 if value else 34
	objective.size.x = 226 if value else 316
	objective.add_theme_font_size_override("font_size", 11 if value else 12)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if value else TextServer.AUTOWRAP_OFF
	objective.size.y = 32 if value else 20
	objective.position.y = 10 if value else 14
	stats.position = Vector2(345,15) if value else Vector2(448,15)
	stats.size.x = 105 if value else 110
	stats.add_theme_font_size_override("font_size",9 if value else 10)
	ammo_panel.position = Vector2(438,127) if value else Vector2(8,263)
	hint.position = Vector2(125,299) if value else Vector2(100,297)
	hint.size.x = 290 if value else 376
	hint.add_theme_font_size_override("font_size",10 if value else 11)
	if value: documents_button.hide()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme := Theme.new()
	theme.default_font_size = 13
	theme.set_color("font_color", "Label", PAPER)
	root.theme = theme
	build_hud()
	build_dialog()

func panel(parent: Node, rect: Rect2, color: Color = INK) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("425263")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	p.add_theme_stylebox_override("panel", style)
	parent.add_child(p)
	return p

func label(parent: Node, text: String, rect: Rect2, font_size: int = 13, color: Color = PAPER) -> Label:
	var l := Label.new()
	l.text = text
	l.position = rect.position
	l.size = rect.size
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

func button(parent: Node, text: String, rect: Rect2, action: String) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 14)
	var mouse_highlight := not mobile and not OS.has_feature("android") and not OS.has_feature("ios")
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.04, 0.06, 0.09, 0.85)
		style.border_color = ORANGE if state=="hover" and mouse_highlight else Color("33414c")
		style.set_border_width_all(1)
		style.set_corner_radius_all(2)
		b.add_theme_stylebox_override(state, style)
	# Keep keyboard activation, but focus must not draw a persistent orange frame.
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(func(): command.emit(action))
	parent.add_child(b)
	return b

func image_rect(parent: Node, texture_: Texture2D, rect: Rect2) -> TextureRect:
	var img := TextureRect.new()
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.texture = texture_
	img.position = rect.position
	img.size = rect.size
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if rect == Rect2(0,0,576,324): img.set_meta("full_bleed",true)
	parent.add_child(img)
	return img

func clear_screen() -> void:
	hint_finger = -1
	hint_target = null
	if is_instance_valid(screen):
		screen.queue_free()
		screen = null

func menu(can_continue: bool) -> void:
	clear_screen()
	hud.hide()
	dialog.hide()
	dialogue_active = false
	screen = Control.new()
	screen.set_meta("main_menu", true)
	root.add_child(screen)
	screen.size = Vector2(576, 324)
	# Use a clean capture of the level 1 city, with crisp pixels and readable foreground UI.
	var bg := image_rect(screen, load("res://assets/ui/menu_city.png"), Rect2(0, 0, 576, 324))
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.modulate = Color(0.80, 0.80, 0.85, 1.0)
	var title := label(screen, "THE LAST ROUTE", Rect2(0, 18 if mobile else 35, 576, 48), 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_y", 2)
	var start := button(screen, "Nueva historia", Rect2(178, 74 if mobile else 110, 220, 44 if mobile else 32), "new")
	var continue_btn := button(screen, "Continuar historia", Rect2(178, 122 if mobile else 148, 220, 44 if mobile else 32), "continue")
	continue_btn.disabled = not can_continue
	continue_btn.tooltip_text = "Empieza una nueva historia para guardar tu progreso." if not can_continue else "Continúa desde el último punto seguro."
	var select_btn := button(screen, "Seleccionar nivel", Rect2(178, 170 if mobile else 186, 220, 44 if mobile else 32), "select_level")
	select_btn.disabled = not RouteSave.story_completed()
	select_btn.tooltip_text = "Completa la campaña para desbloquearlo." if select_btn.disabled else "Vuelve a jugar cualquier nivel."
	var survival := button(screen, "Supervivencia", Rect2(178, 218 if mobile else 224, 220, 44 if mobile else 32), "survival")
	survival.disabled = not RouteSave.story_completed()
	survival.tooltip_text = "Completa la campaña para desbloquearlo." if survival.disabled else "Sobrevive a oleadas sin límite."
	button(screen, "Salir", Rect2(178, 266 if mobile else 262, 220, 44 if mobile else 32), "quit")
	start.grab_focus()

func locked_button_at(point: Vector2) -> Button:
	for child in screen.get_children():
		if child is Button and child.disabled and not child.tooltip_text.is_empty():
			var local_point: Vector2 = child.get_global_transform_with_canvas().affine_inverse()*point
			if Rect2(Vector2.ZERO,child.size).has_point(local_point):
				return child
	return null

func _input(event: InputEvent) -> void:
	# Godot uses mouse events synthesized from touches to activate GUI buttons.
	if RouteControls.touch_only:
		var physical_mouse := event is InputEventMouse and event.device != InputEvent.DEVICE_ID_EMULATION
		if physical_mouse or event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
			get_viewport().set_input_as_handled()
			return
	if not is_instance_valid(screen) or not screen.get_meta("main_menu", false): return
	if is_instance_valid(pause_panel): return
	if event is InputEventScreenTouch:
		var target := locked_button_at(event.position)
		if event.pressed and not event.canceled:
			if target == null: return
			if hint_finger == -1:
				hint_finger = event.index
				hint_target = target
		elif event.index == hint_finger:
			var open_hint: bool = not event.canceled and is_instance_valid(target) and target == hint_target
			hint_finger = -1
			hint_target = null
			if open_hint:
				show_menu_hint(target.text,target.tooltip_text)
		else:
			return
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var target := locked_button_at(event.position)
		if target == null: return
		# Android can deliver a mouse click for the same finger gesture.
		if event.device != InputEvent.DEVICE_ID_EMULATION and event.pressed and hint_finger == -1:
			show_menu_hint(target.text,target.tooltip_text)
		get_viewport().set_input_as_handled()

func show_menu_hint(title_text: String, message: String) -> void:
	close_pause()
	pause_panel = panel(root,Rect2(0,0,576,324),Color(0.0,0.0,0.0,0.72))
	pause_panel.set_meta("full_bleed",true)
	var box := panel(pause_panel,Rect2(108,78,360,168),INK)
	var heading := label(box,title_text,Rect2(20,14,320,26),19,ORANGE)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Enable wrapping before setting text so its minimum width cannot grow past the panel.
	var explanation := label(box,"",Rect2(20,48,320,52),14)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explanation.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	explanation.text = message
	button(box,"Entendido",Rect2(78,110,204,44),"back_menu").grab_focus()

func build_hud() -> void:
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	header = panel(hud, Rect2(8, 8, 560, 34), Color(0.04, 0.07, 0.11, 0.92))
	label(hud, "NICO", Rect2(16, 10, 40, 14), 9, ORANGE)
	health = ProgressBar.new()
	health.show_percentage = false
	health.max_value = 100
	health.value = 100
	var fill := StyleBoxFlat.new()
	fill.bg_color = ORANGE
	health.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("303c49")
	health.add_theme_stylebox_override("background", background)
	health.add_theme_font_size_override("font_size", 1)
	hud.add_child(health)
	health.position = Vector2(16, 27)
	health.size = Vector2(78, 6)
	health_text = label(hud, "100", Rect2(65, 10, 33, 14), 9)
	objective = label(hud, "Dirígete al Local 24", Rect2(112, 14, 316, 20), 12)
	stats = label(hud, "00:00", Rect2(448, 15, 110, 20), 10, CYAN)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint = label(hud, "", Rect2(100, 297, 376, 20), 11)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_shadow_color", Color.BLACK)
	hint.add_theme_constant_override("shadow_offset_x", 1)
	hint.add_theme_constant_override("shadow_offset_y", 1)
	ammo_panel = panel(hud,Rect2(8,263,130,29),Color(0.04,0.07,0.11,0.90))
	weapon_icon = image_rect(ammo_panel,RouteArt.weapon_item(2),Rect2(6,5,30,18))
	ammo_text = label(ammo_panel,"12 / 60",Rect2(43,5,84,19),11)
	ammo_panel.hide()
	documents_button = button(hud,"Documentos · Tab",Rect2(432,266,136,24),"documents")
	documents_button.add_theme_font_size_override("font_size",10)
	documents_button.hide()
	zone_text = label(hud, "", Rect2(18, 62, 450, 40), 18, PAPER)
	zone_text.add_theme_color_override("font_shadow_color", Color.BLACK)
	hud.hide()

func build_dialog() -> void:
	dialog = panel(root, Rect2(8, 201, 560, 115), Color(0.035, 0.05, 0.09, 0.98))
	dialog_face = image_rect(dialog, RouteArt.portrait(3), Rect2(10, 12, 80, 91))
	dialog_name = label(dialog, "JEFE", Rect2(101, 10, 420, 20), 14, ORANGE)
	dialog_text = label(dialog, "", Rect2(101, 35, 442, 54), 13)
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_next = label(dialog, "E / Enter  ·  continuar", Rect2(365, 94, 181, 15), 9, CYAN)
	dialog_next.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dialog.hide()

func start_dialogue(content: Array) -> void:
	RouteControls.release_touch()
	lines = content
	line_index = 0
	dialogue_active = true
	dialog.show()
	show_line()

func show_line() -> void:
	var entry: Dictionary = lines[line_index]
	dialog_name.text = entry.name
	dialog_text.text = entry.text
	dialog_face.texture = CorporateGuardArt.portrait() if bool(entry.get("corporate_guard",false)) else HarborArt.portrait(int(entry.portrait)-7) if int(entry.get("portrait",3))>=7 else load(BroadcastArt.FOLDER+"operator.png") if int(entry.get("portrait",3))==6 else RescueArt.portrait(int(entry.get("portrait",4))-4) if int(entry.get("portrait",3))>=4 else RouteArt.portrait(int(entry.get("portrait",3)))
	dialog_text.visible_characters = 0
	reveal = 0.0
	var document := bool(entry.get("document",false))
	dialog.position = Vector2(48,52) if document else Vector2(8,201)
	dialog.size = Vector2(480,222) if document else Vector2(560,115)
	dialog_face.visible = not document
	dialog_name.position = Vector2(20,15) if document else Vector2(101,10)
	dialog_text.position = Vector2(20,52) if document else Vector2(101,35)
	dialog_text.size = Vector2(440,140) if document else Vector2(442,54)
	dialog_next.position = Vector2(279,197) if document else Vector2(365,94)
	dialog_next.text = ("E / Enter · continuar" if line_index<lines.size()-1 else "E / Enter · cerrar documento") if document else "E / Enter · continuar"
	if document:
		reveal = dialog_text.text.length()
		dialog_text.visible_characters = -1
	if mobile:
		dialog_next.text = "Toca para continuar" if not document or line_index<lines.size()-1 else "Toca para cerrar"

func advance_dialogue() -> void:
	if not dialogue_active: return
	if dialog_text.visible_characters >= 0 and dialog_text.visible_characters < dialog_text.text.length():
		dialog_text.visible_characters = dialog_text.text.length()
		reveal = dialog_text.text.length()
		return
	line_index += 1
	if line_index >= lines.size():
		dialogue_active = false
		dialog.hide()
		dialogue_finished.emit()
	else:
		show_line()

func _process(delta: float) -> void:
	if get_tree().paused: return
	if dialogue_active:
		reveal += delta * 42.0
		dialog_text.visible_characters = mini(int(reveal), dialog_text.text.length())
	if zone_timeout > 0:
		zone_timeout -= delta
		zone_text.modulate.a = minf(1.0, zone_timeout)

func announce(text: String) -> void:
	zone_text.text = text
	zone_timeout = 4.0
	zone_text.modulate.a = 1.0

func update_hud(hp: int, goal: String, elapsed: float, remaining: int, prompt: String, attack_tutorial: bool) -> void:
	health.value = hp
	health_text.text = str(hp)
	objective.text = goal
	stats.text = ("%02d:%02d" % [floori(elapsed / 60.0), int(elapsed) % 60])
	if remaining > 0: stats.text = str(remaining) + " infectados  ·  " + stats.text
	hint.text = prompt
	if mobile:
		hint.text = prompt.replace("E / Enter · ","Toca la mano · ").replace("   Tab · documentos", "").replace("   Tab · instrucciones", "")
		if prompt.contains("Espacio"): hint.text = "Mantén pulsado para atacar" if attack_tutorial else ""

func close_pause() -> void:
	if is_instance_valid(pause_panel):
		pause_panel.queue_free()
		pause_panel = null

func pause_menu() -> void:
	close_pause()
	if mobile:
		pause_panel = panel(root,Rect2(135,35,306,254),Color(0.035,0.05,0.09,0.98))
		label(pause_panel,"RUTA EN PAUSA",Rect2(20,16,266,30),20)
		button(pause_panel,"Reanudar",Rect2(20,62,266,44),"resume")
		button(pause_panel,"Controles",Rect2(20,112,266,44),"controls_pause")
		button(pause_panel,"Menú principal",Rect2(20,162,266,44),"menu")
		return
	pause_panel = panel(root, Rect2(151, 56, 274, 212), Color(0.035, 0.05, 0.09, 0.98))
	label(pause_panel, "RUTA EN PAUSA", Rect2(20, 16, 240, 30), 20)
	button(pause_panel, "Reanudar", Rect2(20, 62, 234, 30), "resume").grab_focus()
	button(pause_panel, "Controles", Rect2(20, 102, 234, 30), "controls_pause")
	button(pause_panel, "Menú principal", Rect2(20, 142, 234, 30), "menu")

func controls(from_pause: bool) -> void:
	close_pause()
	pause_panel = panel(root, Rect2(91, 43, 394, 238), Color(0.035, 0.05, 0.09, 0.99))
	label(pause_panel, "CONTROLES", Rect2(22, 14, 350, 30), 22)
	var instructions := "Joystick: moverte. Arma: mantén para atacar.\nCargador: recargar. Flechas: cambiar arma.\nMano: interactuar con objetos cercanos.\nToca los diálogos para leer y continuar.\n\nLas armas ayudan a apuntar a enemigos cercanos.\nMunición y botiquines se recogen al pasar." if mobile else "WASD / flechas      Moverse\nEspacio / clic             Atacar / disparar\nE / Enter                   Interactuar / diálogo\nR: recargar    Q: cambiar arma    Esc: pausa\n\nClic apunta al cursor; Espacio ayuda a apuntar.\nRecoge munición pasando sobre las cajas."
	label(pause_panel, instructions, Rect2(22, 55, 352, 126), 12)
	button(pause_panel, "Volver", Rect2(22, 188, 350, 40), "back_pause" if from_pause else "back_menu").grab_focus()

func survival_result(waves: int, kills: int, elapsed: float) -> void:
	clear_screen()
	hud.hide()
	screen = panel(root,Rect2(103,36,370,253),INK)
	label(screen,"FIN DE SUPERVIVENCIA",Rect2(24,17,330,34),21,ORANGE)
	label(screen,"Oleadas superadas     %d\nEnemigos eliminados   %d\nTiempo sobrevivido     %02d:%02d" % [waves,kills,floori(elapsed/60.0),int(elapsed)%60],Rect2(24,82,320,90),14)
	button(screen,"Reintentar",Rect2(24,190,150,44),"retry").grab_focus()
	button(screen,"Menú principal",Rect2(187,190,160,44),"menu")

func result_screen(won: bool, kills: int, damage: int, elapsed: float, level_number: int = 1) -> void:
	clear_screen()
	hud.hide()
	screen = panel(root, Rect2(103, 36, 370, 253), Color(0.035, 0.05, 0.09, 0.98))
	label(screen, ("A SALVO" if level_number == 8 else "PRUEBAS ENVIADAS" if level_number == 7 else "REGISTROS RECUPERADOS" if level_number == 6 else "RESCATE COMPLETADO" if level_number == 5 else "PRUEBAS RECUPERADAS" if level_number == 4 else "ESTACIÓN COMPLETADA" if level_number == 3 else "ENTREGA COMPLETADA") if won else "LA RUTA TERMINÓ", Rect2(24, 17, 330, 34), 22, ORANGE)
	label(screen, "NIVEL %02d  /  INFORME DE RUTA" % level_number, Rect2(24, 55, 330, 20), 10, CYAN)
	label(screen, "Zombis eliminados     %d\nDaño recibido             %d\nTiempo de ruta            %02d:%02d" % [kills, damage, floori(elapsed / 60.0), int(elapsed) % 60], Rect2(24, 87, 320, 89), 14)
	if won and level_number == 8:
		button(screen, "Menú principal", Rect2(105, 190, 160, 34), "menu").grab_focus()
	else:
		button(screen, "Reintentar", Rect2(24, 190, 150, 34), "retry").grab_focus()
		button(screen, "Menú principal", Rect2(187, 190, 160, 34), "menu")
	if not won and level_number == 8:
		button(screen,"Reanudar desde el punto seguro",Rect2(24,150,323,30),"retry_checkpoint").grab_focus()
	if won and level_number < 8:
		button(screen,"Continuar al Nivel %d" % (level_number+1),Rect2(24,150,323,30),"next_level").grab_focus()
	if mobile:
		screen.position = Vector2(103,8)
		screen.size.y = 308
		for child in screen.get_children():
			if child is Button:
				child.position.y = 238 if child.position.y >= 190 else 185
				child.size.y = 44

func route_select() -> void:
	# UI and controller both enforce the campaign unlock.
	if not RouteSave.story_completed(): return
	clear_screen()
	if mobile:
		mobile_route_select()
		return
	screen = panel(root,Rect2(118,10,340,304),Color(0.035,0.05,0.09,0.98))
	label(screen,"ELIGE LA RUTA",Rect2(22,10,300,28),22)
	var names := ["Distrito comercial","Distrito de carga","Bajo la ciudad","Zona de contención","Los que quedaron","El registro de las entregas","Que se sepa","La última ruta"]
	for i in 8:
		var entry := button(screen,"Nivel %d · %s" % [i+1,names[i]],Rect2(22,39+i*27,296,24),"level%d" % (i+1))
		entry.add_theme_font_size_override("font_size",13)
		if i==0: entry.grab_focus()
	button(screen,"Volver",Rect2(22,268,296,27),"menu")

func mobile_route_select() -> void:
	screen = panel(root,Rect2(76,12,424,300),Color(0.035,0.05,0.09,0.98))
	label(screen,"ELIGE LA RUTA",Rect2(16,8,390,32),22)
	var scroll := preload("res://scripts/touch_route_list.gd").new()
	scroll.position = Vector2(16,48)
	scroll.size = Vector2(392,194)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	screen.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",6)
	scroll.add_child(list)
	var names := ["Distrito comercial","Distrito de carga","Bajo la ciudad","Zona de contención","Los que quedaron","El registro de las entregas","Que se sepa","La última ruta"]
	for i in 8:
		var entry := button(list,"Nivel %d · %s" % [i+1,names[i]],Rect2(0,0,370,42),"level%d" % (i+1))
		entry.custom_minimum_size = Vector2(370,44)
	button(screen,"Volver",Rect2(16,250,392,40),"menu")

func update_weapon(player: RoutePlayer) -> void:
	ammo_panel.visible = player.has_pistol and not dialogue_active
	if not player.has_pistol: return
	weapon_icon.visible = player.pistol_equipped
	weapon_icon.texture = ContainmentArt.item(7) if player is ShotgunPlayer and player.weapon_slot == 2 else RouteArt.weapon_item(2)
	if player is ShotgunPlayer and player.weapon_slot == 2:
		ammo_text.text = "RECARGANDO" if player.action == "reload" else "%d / %d" % [player.shells,player.shell_reserve]
		ammo_text.modulate = Color("e8776b") if player.shells == 0 else PAPER
		return
	ammo_text.text = ("CUCHILLO" if mobile else "CUCHILLO · Q") if not player.pistol_equipped else "RECARGANDO" if player.action == "reload" else "%d / %d" % [player.magazine,player.reserve]
	ammo_text.modulate = Color("e8776b") if player.pistol_equipped and player.magazine == 0 else PAPER
