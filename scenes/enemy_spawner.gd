extends Node3D

@export var enemy_scene: PackedScene = preload(
	"res://scenes/enemies/enemy_dummy.tscn"
)
@export var max_enemies: int = 3
@export var spawn_interval: float = 2.5
@export var spawn_radius: float = 8.0

var spawn_timer := 0.0


func _ready() -> void:
	randomize()
	spawn_enemy()
	spawn_timer = spawn_interval


func _process(delta: float) -> void:
	spawn_timer -= delta

	if spawn_timer <= 0.0 and get_child_count() < max_enemies:
		spawn_enemy()
		spawn_timer = spawn_interval


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
