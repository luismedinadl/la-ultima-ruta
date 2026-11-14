extends SceneTree

const Language := preload("res://scripts/language.gd")
var failures := 0

func check(value: bool, description: String) -> void:
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var path := "user://language_test_%s.cfg" % OS.get_process_id()
	check(Language.system_language("en-US") == "en", "English regional locale")
	check(Language.system_language("es_MX") == "es", "Spanish regional locale")
	check(Language.system_language("fr_FR") == "es", "Unsupported locale fallback")
	Language.select("en", path)
	TranslationServer.set_locale("es")
	Language.initialize(path)
	check(TranslationServer.get_locale() == "en", "Persisted preference")
	var ui := RouteUI.new()
	root.add_child(ui)
	ui.mobile_layout(true)
	ui.menu(false)
	check(ui.tr("Nueva historia") == "New story", "Menu translation loaded")
	check(ui.tr("Gracias por jugar") == "Thank you for playing", "Ending credits")
	check(RoutePlan.objective(3) == "Survive · wave 2 / 3", "Dynamic level objective")
	ui.update_hud(80, "", 12, 3, "E / Enter · pick up package", false)
	check(ui.hint.text == "Tap the hand · pick up package", "Touch interaction")
	check(ui.stats.text == "3 infected  ·  00:12", "Combat counter")
	ui.start_dialogue([{"name":"NICO", "text":"Voy a entrar.", "portrait":0}])
	check(ui.dialog_text.text == "I'm going in.", "Translated typewriter line")
	Language.select("es", path)
	check(ui.tr("Nueva historia") == "Nueva historia", "Spanish restored")
	check(RoutePlan.objective(3) == "Sobrevive · oleada 2 / 3", "Spanish objective")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	ui.queue_free()
	await process_frame
	print("Language checks: ", failures, " failures")
	quit(failures)
