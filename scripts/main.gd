extends Node
## Application controller: screens, pauses and route lifetime.
const Language := preload("res://scripts/language.gd")
var ui: RouteUI
var audio: RouteAudio
var level: RouteLevel
var mode := "menu"
var awaiting_end := false
var reading_document := false
var awaiting_pistol_scene := false
var showing_harbor_breach := false
var touch: Control

func _ready() -> void:
	Language.initialize()
	if OS.has_feature("mobile") or "--responsive" in OS.get_cmdline_user_args():
		get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		get_window().content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	process_mode = Node.PROCESS_MODE_ALWAYS
	RouteControls.setup()
	ui = RouteUI.new()
	add_child(ui)
	audio = RouteAudio.new()
	add_child(audio)
	ui.command.connect(handle_command)
	ui.dialogue_finished.connect(dialogue_finished)
	touch = preload("res://scripts/touch_controls.gd").new()
	touch.app = self
	ui.root.add_child(touch)
	if RouteControls.touch_only:
		Input.emulate_touch_from_mouse = false
	elif "--touch" in OS.get_cmdline_user_args():
		Input.emulate_touch_from_mouse = true
	if OS.has_feature("mobile"):
		get_window().content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
		get_tree().auto_accept_quit = false
	ui.menu(RouteSave.can_continue())
	var layout := preload("res://scripts/responsive_layout.gd").new()
	layout.app = self
	add_child(layout)

func handle_command(action: String) -> void:
	if action in ["survival", "select_level", "level1", "level2", "level3", "level4", "level5", "level6", "level7", "level8"] and not RouteSave.story_completed():
		return
	audio.cue("ui", -17)
	match action:
		"settings": ui.settings_menu(audio)
		"privacy": ui.privacy_menu()
		"privacy_web": OS.shell_open("https://trockenstudio.blogspot.com/p/politica-de-privacidad-de-last-route.html")
		"terms_web": OS.shell_open("https://trockenstudio.blogspot.com/p/terms-of-service-for-last-route.html")
		"language":
			Language.select("es" if TranslationServer.get_locale() == "en" else "en")
			ui.menu(RouteSave.can_continue())
			ui.settings_menu(audio)
		"new": start_intro()
		"survival": start_survival()
		"select_level": ui.route_select()
		"level1": start_intro()
		"level2": start_route(false,2)
		"level3": start_route(false,3)
		"level4": start_route(false,4)
		"level5": start_route(false,5)
		"level6": start_route(false,6)
		"level7": start_route(false,7)
		"level8": start_route(false,8)
		"retry_checkpoint": start_route(true,8)
		"documents":
			if mode == "playing" and (level is DistributionLevel or level is BroadcastLevel) and not get_tree().paused:
				level.review_documents()
		"next_level": start_route(false,mini(8,level.level_number+1))
		"retry":
			if level is SurvivalLevel: start_survival()
			else: start_route(false,level.level_number if is_instance_valid(level) else 1)
		"continue":
			if RouteSave.can_continue(): start_route(true)
		"quit": get_tree().quit()
		"controls": ui.controls(false)
		"controls_pause": ui.controls(true)
		"back_pause": ui.pause_menu()
		"back_menu": ui.close_pause()
		"resume": resume_route()
		"menu": show_menu()

func start_survival() -> void:
	if not RouteSave.story_completed(): return
	touch.reset()
	get_tree().paused = false
	ui.close_pause()
	ui.clear_screen()
	ui.dialog.hide()
	ui.dialogue_active = false
	if is_instance_valid(level):
		remove_child(level)
		level.queue_free()
	reading_document = false
	awaiting_end = false
	awaiting_pistol_scene = false
	showing_harbor_breach = false
	level = SurvivalLevel.new()
	level.audio = audio
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
	level.announcement.connect(ui.announce)
	level.player_died.connect(on_player_died)
	add_child(level)
	mode = "playing"
	ui.hud.show()

func start_intro() -> void:
	touch.reset()
	if mode == "intro": return
	get_tree().paused = false
	ui.close_pause()
	ui.clear_screen()
	ui.hud.hide()
	ui.dialog.hide()
	ui.dialogue_active = false
	if is_instance_valid(level):
		remove_child(level)
		level.queue_free()
		level = null
	mode = "intro"
	audio.set_route_ambience(0)
	var intro := preload("res://scripts/intro.gd").new()
	intro.ui = ui
	ui.screen = intro
	ui.root.add_child(intro)
	intro.finished.connect(func():
		if mode == "intro": start_route(false,1))

func start_route(resume_checkpoint: bool, requested_level: int = 1) -> void:
	touch.reset()
	var saved := RouteSave.read_data() if resume_checkpoint else {}
	var number := int(saved.get("level",requested_level))
	get_tree().paused = false
	ui.close_pause()
	ui.clear_screen()
	if is_instance_valid(level):
		remove_child(level)
		level.queue_free()
	level = load("res://scenes/level_%02d.tscn" % number).instantiate() as RouteLevel
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
	level.audio = audio
	add_child(level)
	level.announcement.connect(ui.announce)
	level.player_died.connect(on_player_died)
	level.delivered.connect(on_delivered)
	level.checkpoint.connect(save_checkpoint)
	reading_document = false
	awaiting_pistol_scene = false
	showing_harbor_breach = false
	if level is ContainmentLevel:
		(level as ContainmentLevel).document_requested.connect(func(content: Array):
			reading_document = true
			if level is HarborLevel and level.pending_read=="breakout":
				showing_harbor_breach = true
				ui.clear_screen()
				ui.screen = ui.image_rect(ui.root,load("res://assets/harbor/breach.png"),Rect2(0,0,576,324))
				ui.root.move_child(ui.screen,0)
				ui.hud.hide()
			ui.start_dialogue(content))
	audio.set_route_ambience(number)
	mode = "playing"
	awaiting_end = false
	ui.hud.show()
	ui.dialog.hide()
	ui.dialogue_active = false
	if not saved.is_empty():
		level.restore(saved)
		ui.announce("PUNTO SEGURO RECUPERADO")
	elif number == 8:
		ui.start_dialogue(HarborArt.dialogue("opening"))
	elif number == 7:
		ui.start_dialogue(BroadcastArt.dialogue("opening"))
	elif number == 6:
		ui.start_dialogue(DistributionArt.dialogue("opening"))
	elif number == 5:
		show_radio_scene()
	elif number == 4:
		ui.start_dialogue(ContainmentArt.opening())
	elif number == 3:
		ui.start_dialogue(MetroArt.opening())
	elif number == 2:
		awaiting_pistol_scene = true
		ui.start_dialogue(RouteLevelTwo.opening())
	else:
		ui.start_dialogue([
			{"name": "JEFE", "portrait": 3, "text": "Nico, toma la ruta del este. El Local 24 tiene un paquete que debes entregar."},
			{"name": "NICO", "portrait": 0, "text": "No lo sé. Hay personas moviéndose raro, cubiertas de sangre. Parecen... zombis."},
			{"name": "JEFE", "portrait": 3, "text": "Que no te atormenten. Recoge el paquete. Si cumples la entrega, tu pago se duplica."},
			{"name": "NICO", "portrait": 0, "text": "¿Pago doble? Eso me agrada. Lo haré solo porque realmente necesito el dinero."}
		])

func dialogue_finished() -> void:
	if not is_instance_valid(level): return
	if awaiting_pistol_scene:
		awaiting_pistol_scene = false
		show_pistol_scene()
		return
	if reading_document:
		reading_document = false
		if showing_harbor_breach:
			showing_harbor_breach = false
			ui.clear_screen()
			ui.hud.show()
		(level as ContainmentLevel).document_closed()
		return
	if awaiting_end and level.level_number == 8:
		show_finale()
	elif awaiting_end:
		mode = "result"
		ui.result_screen(true, level.kills, level.damage_received, level.elapsed, level.level_number)
	else:
		level.blocked = false
		ui.announce("01  /  COMERCIO EN SILENCIO" if level.level_number == 1 else "02  /  DISTRITO DE CARGA" if level.level_number == 2 else "03 / BAJO LA CIUDAD" if level.level_number == 3 else "04 / ZONA DE CONTENCIÓN" if level.level_number == 4 else "05 / LOS QUE QUEDARON" if level.level_number == 5 else "06 / EL REGISTRO DE LAS ENTREGAS" if level.level_number == 6 else "08 / LA ÚLTIMA RUTA" if level.level_number == 8 else "07 / QUE SE SEPA")
		save_checkpoint(level.snapshot())

func save_checkpoint(data: Dictionary) -> void:
	if not RouteSave.write_data(data):
		ui.announce("No se pudo guardar el punto seguro")

func show_pistol_scene() -> void:
	# The level is already blocked. This scene never grants extra ammo or advances time.
	mode = "pistol_scene"
	ui.hud.hide()
	ui.clear_screen()
	var scene := preload("res://scripts/intro.gd").new()
	scene.ui = ui
	scene.folder = "res://assets/ui/connections/"
	scene.skip_text = "Saltar escena · Esc"
	ui.screen = scene
	ui.root.add_child(scene)
	scene.finished.connect(func():
		if mode != "pistol_scene": return
		ui.clear_screen()
		ui.hud.show()
		mode = "playing"
		dialogue_finished())

func show_radio_scene() -> void:
	# Discovery precedes Mara's first transmission; the route stays frozen.
	mode = "radio_scene"
	level.blocked = true
	ui.hud.hide()
	ui.clear_screen()
	var scene := preload("res://scripts/intro.gd").new()
	scene.ui = ui
	scene.folder = "res://assets/ui/radio/"
	scene.skip_text = "Saltar escena · Esc"
	ui.screen = scene
	ui.root.add_child(scene)
	scene.finished.connect(func():
		if mode != "radio_scene": return
		ui.clear_screen()
		ui.hud.show()
		mode = "playing"
		ui.start_dialogue(RescueArt.dialogue("opening")))

func on_delivered() -> void:
	# Completion is independent of the current checkpoint and survives a new story.
	if not RouteSave.mark_level_completed(level.level_number):
		ui.announce("No se pudo guardar el nivel completado")
	awaiting_end = true
	if level.level_number == 8:
		if not RouteSave.finish_current_run(): ui.announce("No se pudo guardar el final de la historia")
		ui.start_dialogue(HarborArt.dialogue("ending"))
		return
	if level.level_number == 7:
		ui.start_dialogue(BroadcastArt.dialogue("ending"))
		return
	if level.level_number == 6:
		ui.start_dialogue(DistributionArt.dialogue("ending"))
		return
	if level.level_number == 5:
		ui.start_dialogue(RescueArt.dialogue("ending"))
		return
	if level.level_number == 4:
		ui.start_dialogue(RouteStory.camp_ending((level as ContainmentLevel).document_read.has(1)))
		return
	if level.level_number in [2,3]:
		ui.start_dialogue(RouteStory.dialogue("level%d_end" % level.level_number))
		return
	ui.start_dialogue([
		{"name": "JEFE", "portrait": 3, "text": "Entrega confirmada. Buen trabajo, Nico."},
		{"name": "NICO", "portrait": 1, "text": "No sé cuánto tiempo más podré seguir haciendo esto."}
	])

func on_player_died() -> void:
	level.blocked = true
	mode = "result"
	if level is SurvivalLevel:
		ui.survival_result(level.completed_waves,level.kills,level.elapsed)
		return
	ui.result_screen(false, level.kills, level.damage_received, level.elapsed, level.level_number)

func show_menu() -> void:
	touch.reset()
	get_tree().paused = false
	ui.close_pause()
	if is_instance_valid(level):
		remove_child(level)
		level.queue_free()
		level = null
	mode = "menu"
	awaiting_end = false
	audio.set_route_ambience(-1)
	ui.menu(RouteSave.can_continue())

func pause_route() -> void:
	if mode != "playing": return
	touch.reset()
	get_tree().paused = true
	ui.pause_menu()

func resume_route() -> void:
	touch.reset()
	ui.close_pause()
	get_tree().paused = false

func toggle_touch_controls() -> void:
	touch.set_enabled(not touch.enabled)
	if not OS.has_feature("mobile"): Input.emulate_touch_from_mouse = touch.enabled

func _unhandled_input(event: InputEvent) -> void:
	# F8 belongs to the editor's Stop command, including embedded play mode.
	if event is InputEventKey and event.pressed and not event.echo and not event.ctrl_pressed and not event.alt_pressed and not event.meta_pressed and event.physical_keycode == KEY_T and not OS.has_feature("mobile"):
		toggle_touch_controls()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		handle_command("documents")
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("route_pause"):
		if mode == "playing":
			if get_tree().paused: resume_route()
			else: pause_route()
		elif is_instance_valid(ui.pause_panel):
			if ui.pause_panel.get_meta("privacy", false): ui.settings_menu(audio)
			else: ui.close_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("route_interact") and mode == "playing" and not get_tree().paused:
		if ui.dialogue_active: ui.advance_dialogue()
		elif is_instance_valid(level): level.interact()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if mode == "playing" and is_instance_valid(level):
		var attack_tutorial := level.level_number == 1 and not (level is SurvivalLevel) and level.stage in [1, 3]
		ui.update_hud(level.player.health, level.goal, level.elapsed, level.remaining(), "" if ui.dialogue_active else level.interaction_hint(), attack_tutorial)

		ui.update_weapon(level.player)
		ui.documents_button.visible = not RouteControls.touch_mode and (level is DistributionLevel or level is BroadcastLevel) and not ui.dialogue_active
		ui.documents_button.text = "Instrucciones · Tab" if level.level_number == 7 else "Documentos · Tab"
		ui.documents_button.disabled = level.blocked or level.player.dead

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_instance_valid(touch):
		if mode == "menu" and is_instance_valid(ui.pause_panel):
			if ui.pause_panel.get_meta("privacy", false): ui.settings_menu(audio)
			else: ui.close_pause()
		if mode == "playing":
			if get_tree().paused: resume_route()
			else: pause_route()

func show_finale() -> void:
	mode = "finale"
	level.blocked = true
	ui.dialog.hide()
	ui.hud.hide()
	ui.clear_screen()
	var sequence := preload("res://scripts/intro.gd").new()
	sequence.ui = ui
	sequence.folder = "res://assets/harbor/ending/"
	sequence.skip_text = "Saltar final · Esc"
	ui.screen = sequence
	ui.root.add_child(sequence)
	sequence.finished.connect(func():
		if mode != "finale": return
		mode = "result"
		ui.result_screen(true,level.kills,level.damage_received,level.elapsed,8))
