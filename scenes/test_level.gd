extends Node3D

@export var follow_speed: float = 6.0
@export var camera_offset := Vector3(8.0, 10.0, 11.0)

@onready var player: CharacterBody3D = $NicoPlayer
@onready var camera: Camera3D = $Camera3D
@onready var health_bar: ProgressBar = $HUD/HealthBar
@onready var game_over_label: Label = $HUD/GameOverLabel
@onready var wave_label: Label = $HUD/WaveLabel
@onready var objective_label: Label = $HUD/ObjectiveLabel
@onready var delivery_complete_label: Label = $HUD/DeliveryCompleteLabel
@onready var enemy_spawner = $EnemySpawner
@onready var delivery_package = $DeliveryPackage
@onready var delivery_zone = $DeliveryZone

@onready var pause_panel: Panel = $HUD/PausePanel
@onready var resume_button: Button = $HUD/PausePanel/ResumeButton
@onready var restart_button: Button = $HUD/PausePanel/RestartButton
@onready var menu_button: Button = $HUD/PausePanel/MenuButton
@onready var victory_panel: Panel = $HUD/VictoryPanel
@onready var play_again_button: Button = $HUD/VictoryPanel/PlayAgainButton
@onready var victory_menu_button: Button = $HUD/VictoryPanel/VictoryMenuButton

var has_package := false
var delivery_complete := false


func _ready() -> void:
	get_tree().paused = false
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	victory_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	camera.global_position = player.global_position + camera_offset
	camera.look_at(player.global_position + Vector3(0.0, 2.0, 0.0))

	health_bar.max_value = player.max_health
	health_bar.value = player.health

	game_over_label.hide()
	delivery_complete_label.hide()
	pause_panel.hide()
	victory_panel.hide()

	delivery_package.connect("collected", _on_package_collected)
	delivery_zone.connect("player_entered", _on_delivery_zone_entered)

	resume_button.pressed.connect(_resume_game)
	restart_button.pressed.connect(_restart_game)
	menu_button.pressed.connect(_go_to_main_menu)
	play_again_button.pressed.connect(_play_again)
	victory_menu_button.pressed.connect(_go_to_main_menu)

	_update_objective()


func _process(delta: float) -> void:
	var target_position := player.global_position + camera_offset
	camera.global_position = camera.global_position.lerp(
		target_position,
		min(follow_speed * delta, 1.0)
	)
	camera.look_at(player.global_position + Vector3(0.0, 2.0, 0.0))

	health_bar.value = player.health
	wave_label.text = "Oleada: %d | Enemigos: %d" % [
		enemy_spawner.current_wave,
		enemy_spawner.get_child_count()
	]

	if delivery_complete:
		delivery_complete_label.show()
		game_over_label.hide()

		if Input.is_key_pressed(KEY_R):
			get_tree().reload_current_scene()
		return

	if player.is_dead:
		game_over_label.show()

		if Input.is_key_pressed(KEY_R):
			get_tree().reload_current_scene()
	else:
		game_over_label.hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not player.is_dead and not delivery_complete:
			_set_paused(not get_tree().paused)
			get_viewport().set_input_as_handled()


func _set_paused(is_paused: bool) -> void:
	get_tree().paused = is_paused
	pause_panel.visible = is_paused


func _resume_game() -> void:
	_set_paused(false)


func _restart_game() -> void:
	_set_paused(false)
	get_tree().reload_current_scene()


func _go_to_main_menu() -> void:
	_set_paused(false)
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_package_collected() -> void:
	has_package = true
	print("Objetivo actualizado: lleva el paquete a la zona verde.")
	_update_objective()


func _on_delivery_zone_entered() -> void:
	if has_package and not delivery_complete:
		delivery_complete = true
		print("Entrega completada.")

		delivery_complete_label.hide()
		victory_panel.show()
		get_tree().paused = true


func _update_objective() -> void:
	if delivery_complete:
		objective_label.text = "Objetivo: Entrega completada"
	elif has_package:
		objective_label.text = "Objetivo: Lleva el paquete a la zona verde"
	else:
		objective_label.text = "Objetivo: Recoge el paquete"

func _play_again() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
