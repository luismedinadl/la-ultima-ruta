extends Node3D

@export var enemy_scene: PackedScene = preload(
	"res://scenes/enemies/enemy_dummy.tscn"
)
@export var enemies_per_wave: int = 3
@export var spawn_interval: float = 1.0
@export var spawn_radius: float = 8.0

var spawn_timer := 0.0
var enemies_spawned := 0
var wave_complete := false


func _ready() -> void:
	randomize()


func _process(delta: float) -> void:
	if wave_complete:
		return

	if enemies_spawned < enemies_per_wave:
		spawn_timer -= delta

		if spawn_timer <= 0.0:
			spawn_enemy()
			enemies_spawned += 1
			spawn_timer = spawn_interval
	elif get_child_count() == 0:
		wave_complete = true
		print("Oleada completada.")


func spawn_enemy() -> void:
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
