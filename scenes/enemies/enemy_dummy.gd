extends CharacterBody3D

@export var max_health: int = 3
@export var move_speed: float = 2.2
@export var stop_distance: float = 1.7
@export var rotation_speed: float = 10.0

var health: int
var player: CharacterBody3D


func _ready() -> void:
	health = max_health
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D


func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as CharacterBody3D
		return

	var direction := player.global_position - global_position
	direction.y = 0.0

	if direction.length() > stop_distance:
		direction = direction.normalized()

		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed

		rotation.y = lerp_angle(
			rotation.y,
			atan2(direction.x, direction.z),
			min(rotation_speed * delta, 1.0)
		)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 8.0 * delta)

	move_and_slide()


func take_damage(amount: int) -> void:
	health -= amount
	print("Enemigo golpeado. Vida restante: ", health)

	if health <= 0:
		print("Enemigo eliminado.")
		queue_free()
