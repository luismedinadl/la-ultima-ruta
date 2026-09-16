extends CharacterBody3D

@export_category("Movimiento")
@export var move_speed: float = 8.0
@export var acceleration: float = 32.0
@export var deceleration: float = 38.0
@export var rotation_speed: float = 18.0
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

	var direction := _get_camera_relative_direction(input_direction)

	if direction != Vector3.ZERO:
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
			min(rotation_speed * delta, 1.0)
		)

		_play_animation("Nico_Walk", 1.25)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)

		_play_animation("Nico_Idle", 1.0)

	move_and_slide()


func _get_camera_relative_direction(input_direction: Vector2) -> Vector3:
	var camera := get_viewport().get_camera_3d()

	if camera == null:
		return Vector3(input_direction.x, 0.0, input_direction.y).normalized()

	var camera_forward := -camera.global_transform.basis.z
	var camera_right := camera.global_transform.basis.x

	camera_forward.y = 0.0
	camera_right.y = 0.0

	camera_forward = camera_forward.normalized()
	camera_right = camera_right.normalized()

	return (
		camera_right * input_direction.x
		+ camera_forward * -input_direction.y
	).normalized()


func _play_animation(animation_name: StringName, playback_speed: float) -> void:
	animation_player.speed_scale = playback_speed

	if animation_player.current_animation != animation_name:
		animation_player.play(animation_name)
