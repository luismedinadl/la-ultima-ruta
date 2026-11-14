extends RefCounted

const SETTINGS_PATH := "user://language.cfg"

static func system_language(locale: String) -> String:
	return "en" if TranslationServer.standardize_locale(locale).get_slice("_", 0) == "en" else "es"

static func initialize(path: String = SETTINGS_PATH) -> void:
	var settings := ConfigFile.new()
	var language := system_language(OS.get_locale())
	if settings.load(path) == OK:
		var saved = settings.get_value("display", "language", "")
		if saved in ["en", "es"]:
			language = saved
	TranslationServer.set_locale(language)

static func select(language: String, path: String = SETTINGS_PATH) -> void:
	if language not in ["en", "es"]: return
	TranslationServer.set_locale(language)
	var settings := ConfigFile.new()
	settings.set_value("display", "language", language)
	if settings.save(path) != OK:
		push_warning("Could not save language preference")
