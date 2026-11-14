class_name RouteSave
extends RefCounted
## Save only checkpoint dictionaries. Never serialize live node references.
static var save_path := "user://route_checkpoint.json"

# Keep completion separate so checkpoint replacement never resets unlocked levels.
# Deriving the filename also isolates the progress of automated test saves.
static func completed_levels() -> Array[int]:
	var result: Array[int] = []
	var path := save_path + ".progress"
	if not FileAccess.file_exists(path): return result
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return result
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or data.get("version", 0) != 1: return result
	var levels: Variant = data.get("completed_levels", [])
	if not levels is Array: return result
	for value in levels:
		if typeof(value) in [TYPE_INT, TYPE_FLOAT] and value == int(value) and int(value) in range(1, 9) and not result.has(int(value)):
			result.append(int(value))
	return result

static func story_completed() -> bool:
	return completed_levels().size() == 8

static func can_continue() -> bool:
	var data := read_data()
	if data.is_empty() or data.get("campaign_finished",false): return false
	# Old completed saves retained the last checkpoint before boarding.
	if not data.has("run_active") and story_completed() and int(data.get("level",1))==8 and int(data.stage)==14: return false
	return true

static func finish_current_run() -> bool:
	var data := read_data()
	if data.is_empty(): return true
	data["campaign_finished"] = true
	return write_data(data)

static func mark_level_completed(number: int) -> bool:
	if number not in range(1, 9): return false
	var levels := completed_levels()
	if levels.has(number): return true
	levels.append(number)
	levels.sort()
	var path := save_path + ".progress"
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify({"version": 1, "completed_levels": levels}))
	file.close()
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

static func read_data() -> Dictionary:
	if not FileAccess.file_exists(save_path): return {}
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null: return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary: return {}
	if parsed.get("version", 0) != 1: return {}
	if not parsed.has_all(["stage", "x", "health", "kills", "damage", "elapsed"]): return {}
	for key in ["stage", "x", "health", "kills", "damage", "elapsed"]:
		if typeof(parsed[key]) not in [TYPE_INT, TYPE_FLOAT]: return {}
	if parsed.has("collected") and not parsed.collected is Array: return {}
	var level := int(parsed.get("level",1))
	if level not in [1,2,3,4,5,6,7,8]: return {}
	if int(parsed.stage) not in ([0,2,4,5,7,8,10,11,12,14] if level == 8 else [0,2,3,5,6,8,9,10,12,13,15] if level == 7 else [0,2,3,6,8,9,11,12,13,15,17] if level == 6 else [0,2,3,5,8,11] if level == 5 else [0,2,4,6] if level == 1 else [0,2,4,6,8] if level == 3 else [0,2,4,6,8,10]): return {}
	if level >= 2:
		for key in ["pickup_slot","magazine","reserve"]:
			if parsed.has(key) and typeof(parsed[key]) not in [TYPE_INT,TYPE_FLOAT]: return {}
		if parsed.has("ammo_taken") and not parsed.ammo_taken is Array: return {}
	if level == 3:
		if not parsed.get("metro_enemies",[]) is Array: return {}
		for enemy in parsed.get("metro_enemies",[]):
			if not enemy is Dictionary or not enemy.has_all(["x","y","health","resistant","awareness"]): return {}
			for key in ["x","y","health","awareness"]:
				if typeof(enemy[key]) not in [TYPE_INT,TYPE_FLOAT]: return {}
	if level in [4,5,6,7,8]:
		for key in ["shells","shell_reserve","weapon_slot"]:
			if parsed.has(key) and typeof(parsed[key]) not in [TYPE_INT,TYPE_FLOAT]: return {}
		if not parsed.get("document_read",[]) is Array: return {}
		var choices: Variant = parsed.get("route_choices",[-1,-1])
		if not choices is Array or choices.size()!=2: return {}
		for choice in choices:
			if typeof(choice) not in [TYPE_INT,TYPE_FLOAT] or int(choice) not in [-1,0,1]: return {}
	if level in [5,6,7,8] and not parsed.get("shells_collected",[]) is Array: return {}
	if level == 6:
		for key in ["access_card","records_copied","phone_finished"]:
			if not parsed.has(key) or typeof(parsed[key]) != TYPE_BOOL: return {}
		for index in parsed.get("document_read",[]):
			if typeof(index) not in [TYPE_INT,TYPE_FLOAT] or int(index) not in [0,1,2,3]: return {}
		# JSON numbers load as floats; normalize evidence IDs before membership checks.
		parsed.document_read = parsed.get("document_read",[]).map(func(value): return int(value))
		var stage_ := int(parsed.stage)
		if bool(parsed.access_card) != (stage_>=3): return {}
		if bool(parsed.phone_finished) != (stage_>=13): return {}
		if bool(parsed.records_copied) != (stage_>=15): return {}
		var required := 4 if stage_>=15 else 3 if stage_>=12 else 2 if stage_>=9 else 1 if stage_>=6 else 0
		for index in required:
			if not parsed.get("document_read",[]).has(index): return {}
	if level == 7:
		var stage_ := int(parsed.stage)
		for key in ["power_on","antenna_connected","files_sent","harbor_confirmed"]:
			if not parsed.has(key) or typeof(parsed[key]) != TYPE_BOOL: return {}
		if bool(parsed.power_on) != (stage_>=5): return {}
		if bool(parsed.antenna_connected) != (stage_>=9): return {}
		if bool(parsed.files_sent) != (stage_>=10): return {}
		if bool(parsed.harbor_confirmed) != (stage_>=13): return {}
		for index in parsed.get("document_read",[]):
			if typeof(index) not in [TYPE_INT,TYPE_FLOAT] or int(index)!=0: return {}
	if level == 8:
		for key in ["gate_open","chief_saved","boss_defeated"]:
			if not parsed.has(key) or typeof(parsed[key]) != TYPE_BOOL: return {}
		if bool(parsed.gate_open) != (int(parsed.stage)>=8): return {}
		if bool(parsed.chief_saved) != (int(parsed.stage)>=12): return {}
		if bool(parsed.boss_defeated) != (int(parsed.stage)>=14): return {}
	return parsed

static func write_data(data: Dictionary) -> bool:
	data["version"] = 1
	data["run_active"] = true
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data))
	file.close()
	return DirAccess.rename_absolute(save_path + ".tmp", save_path) == OK
