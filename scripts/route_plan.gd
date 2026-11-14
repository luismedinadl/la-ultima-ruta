class_name RoutePlan
extends RefCounted
## Data-only encounter/objective definitions. Wave spawning and HUD do not
## depend on UI labels or on an infinite enemy generator.
static func wave(number: int) -> Dictionary:
	assert(number >= 1 and number <= 3)
	return {
		"count": [3, 5, 6][number - 1],
		"resistant_index": 5 if number == 3 else -1,
		"entries": [Vector2(150, 220), Vector2(-150, 285), Vector2(225, 295), Vector2(-220, 210), Vector2(25, 205), Vector2(245, 253)]
	}

static func objective(stage: int) -> String:
	match stage:
		0: return "Dirígete al Local 24"
		1, 3, 5: return TranslationServer.translate("Sobrevive · oleada %d / 3") % floori((stage + 1) / 2.0)
		2: return "Avanza hasta el cruce"
		4: return "Lleva el paquete al edificio de entrega"
		6: return "Entrada desbloqueada · entrega el paquete"
		_: return "Entrega completada"
