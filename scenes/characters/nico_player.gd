extends CharacterBody3D

@export_category("Movimiento")
@export var move_speed: float = 6.0
@export var acceleration: float = 18.0
@export var rotation_speed: float = 12.0
@export var gravity: float = 24.0

@onready var animation_player: AnimationPlayer = $Visual/AnimationPlayer


func _ready() -> void:
	animation_player.play("Nico_Idle")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1

	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)

	var direction := Vector3(input_direction.x, 0.0, input_direction.y)

	if direction.length() > 0.0:
		direction = direction.normalized()

		velocity.x = move_toward(
			velocity.x,
			direction.x * move_speed,
			acceleration * delta
		)
		velocity.z = move_toward(
			velocity.z,
			direction.z * move_speed,
			acceleration * delta
		)

		rotation.y = lerp_angle(
			rotation.y,
			atan2(direction.x, direction.z),
			rotation_speed * delta
		)

		_play_animation("Nico_Walk")
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

		_play_animation("Nico_Idle")

	move_and_slide()


func _play_animation(animation_name: StringName) -> void:
	if animation_player.current_animation != animation_name:
		animation_player.play(animation_name)
