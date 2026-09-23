extends CharacterBody3D

@export var max_health: int = 3
@export var move_speed: float = 2.2
@export var stop_distance: float = 1.7
@export var rotation_speed: float = 10.0
@export var attack_cooldown: float = 1.2

var health: int
var player: CharacterBody3D
var attack_cooldown_timer := 0.0

@onready var hurt_sound: AudioStreamPlayer = $HurtSound


func _ready() -> void:
	health = max_health
	player = get_tree().get_first_node_in_group("player") as CharacterBody3D


func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as CharacterBody3D
		return

	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

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
		_attack_player()

	move_and_slide()


func _attack_player() -> void:
	if attack_cooldown_timer > 0.0:
		return

	attack_cooldown_timer = attack_cooldown
	player.take_damage(1)
	print("El enemigo atacó a Nico.")


func take_damage(amount: int) -> void:
	hurt_sound.play()
	health -= amount
	print("Enemigo golpeado. Vida restante: ", health)

	if health <= 0:
		print("Enemigo eliminado.")
		queue_free()
		
