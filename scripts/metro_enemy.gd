class_name MetroEnemy
extends RouteEnemy
## Perception is exclusive to the metro. Once alerted, silence never resets pursuit.
var awareness := 0 # 0 distracted, 1 investigating, 2 alerted
var watch_direction := Vector2.RIGHT
var heard_position := Vector2.ZERO
var suspicion_time := 0.0
var sight_time := 0.0
var alert_icon: Sprite2D
var alert_time := 0.0
var panel_attacker := false
# Only initially distracted groups need visual perception indicators.
var show_awareness_icon := true

func _ready() -> void:
	super._ready()
	alert_icon = Sprite2D.new()
	alert_icon.position = Vector2(0,-67)
	alert_icon.visible = false
	add_child(alert_icon)
	MetroArt.cutout(alert_icon)

func hear_noise(origin: Vector2, loud: bool) -> void:
	if dead or awareness == 2: return
	heard_position = origin
	suspicion_time = 3.0
	awareness = 2 if loud else 1
	alert_time = 1.0

func movement_target() -> Vector2:
	if panel_attacker and level.stage == 7 and position.distance_to(level.player.position) > 65:
		return level.panel_position
	return level.player.position

func _physics_process(delta: float) -> void:
	if dead:
		alert_icon.hide()
		return
	if level.blocked or level.freeze_time > 0: return
	alert_time = maxf(0,alert_time-delta)
	alert_icon.visible = show_awareness_icon and (awareness == 1 or alert_time > 0)
	if alert_icon.visible:
		var icon := MetroArt.item("signals",(4 if awareness == 2 else 0) + int(level.ambient_time*8)%4)
		alert_icon.texture = icon
		alert_icon.scale = Vector2(12,16)/icon.get_size()
	if awareness < 2:
		var offset: Vector2 = level.player.position-position
		var has_line_of_sight: bool = level.clear_sight(position,level.player.position)
		var sees: bool = has_line_of_sight and (offset.length() < 42 or (offset.length() < 155 and offset.normalized().dot(watch_direction) > 0.35))
		sight_time = sight_time+delta if sees else 0.0
		if sight_time > 0.2:
			awareness = 2
			alert_time = 1.0
		elif awareness == 1:
			suspicion_time -= delta
			var to_sound: Vector2 = heard_position-position
			watch_direction = to_sound.normalized()
			if to_sound.length() > 14:
				direction = RouteControls.direction_index(to_sound)
				velocity = to_sound.normalized()*14
				move_and_slide()
				position = level.clamp_enemy(position)
				animate("walk")
			else: animate("idle")
			if suspicion_time <= 0:
				awareness = 0
				animate("idle")
			return
		else:
			animate("idle")
			return
	super._physics_process(delta)

func take_damage(amount: int, source: Vector2) -> void:
	if not dead:
		awareness = 2
		alert_time = 1.0
	super.take_damage(amount,source)
