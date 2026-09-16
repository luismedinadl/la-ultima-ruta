extends Node3D

@export var follow_speed: float = 6.0
@export var camera_offset := Vector3(8.0, 10.0, 11.0)

@onready var player: CharacterBody3D = $NicoPlayer
@onready var camera: Camera3D = $Camera3D
@onready var health_bar: ProgressBar = $HUD/HealthBar


func _ready() -> void:
	camera.global_position = player.global_position + camera_offset
	camera.look_at(player.global_position + Vector3(0.0, 2.0, 0.0))

	health_bar.max_value = player.max_health
	health_bar.value = player.health


func _process(delta: float) -> void:
	var target_position := player.global_position + camera_offset

	camera.global_position = camera.global_position.lerp(
		target_position,
		min(follow_speed * delta, 1.0)
	)

	camera.look_at(player.global_position + Vector3(0.0, 2.0, 0.0))
	health_bar.value = player.health
