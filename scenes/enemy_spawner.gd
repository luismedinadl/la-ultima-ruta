extends Node3D

@export var enemy_scene: PackedScene = preload(
	"res://scenes/enemies/enemy_dummy.tscn"
)
@export var first_wave_enemies: int = 3
@export var enemies_added_per_wave: int = 1
@export var spawn_interval: float = 1.0
@export var time_between_waves: float = 4.0
@export var spawn_radius: float = 8.0

var current_wave := 1
var enemies_to_spawn := 0
var enemies_spawned := 0
var spawn_timer := 0.0
var next_wave_timer := 0.0
var waiting_for_next_wave := false


func _ready() -> void:
	randomize()
	_start_wave()


func _process(delta: float) -> void:
	if waiting_for_next_wave:
		next_wave_timer -= delta

		if next_wave_timer <= 0.0:
			waiting_for_next_wave = false
			_start_wave()

		return

	if enemies_spawned < enemies_to_spawn:
		spawn_timer -= delta

		if spawn_timer <= 0.0:
			_spawn_enemy()
			enemies_spawned += 1
			spawn_timer = spawn_interval
	elif get_child_count() == 0:
		print("Oleada ", current_wave, " completada.")

		current_wave += 1
		waiting_for_next_wave = true
		next_wave_timer = time_between_waves


func _start_wave() -> void:
	enemies_spawned = 0
	enemies_to_spawn = first_wave_enemies + (
		(current_wave - 1) * enemies_added_per_wave
	)
	spawn_timer = 0.0

	print("Comienza la oleada ", current_wave, ".")


func _spawn_enemy() -> void:
	var enemy := enemy_scene.instantiate() as CharacterBody3D

	var direction := Vector3(
		randf_range(-1.0, 1.0),
		0.0,
		randf_range(-1.0, 1.0)
	)

	if direction.length_squared() < 0.01:
		direction = Vector3.FORWARD

	direction = direction.normalized()
	enemy.position = direction * spawn_radius
	enemy.position.y = 1.0

	add_child(enemy)
