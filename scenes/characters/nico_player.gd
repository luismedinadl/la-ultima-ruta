extends CharacterBody3D

@export_category("Movimiento")
@export var move_speed: float = 8.0
@export var acceleration: float = 32.0
@export var deceleration: float = 38.0
@export var rotation_speed: float = 18.0
@export var gravity: float = 24.0

@export_category("Ataque")
@export var attack_duration: float = 0.55
@export var attack_cooldown: float = 0.65

@export_category("Salud")
@export var max_health: int = 5

@onready var animation_player: AnimationPlayer = $Visual/AnimationPlayer
@onready var attack_area: Area3D = $AttackArea

var health: int
var is_attacking := false
var is_dead := false
var attack_timer := 0.0
var attack_cooldown_timer := 0.0


func _ready() -> void:
	add_to_group("player")
	health = max_health
	animation_player.play("Nico_Idle")


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1

	if attack_timer > 0.0:
		attack_timer -= delta
	else:
		is_attacking = false

	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

	if Input.is_action_just_pressed("attack"):
		_start_attack()

	if is_attacking:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
		move_and_slide()
		return

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


func _start_attack() -> void:
	if is_attacking or attack_cooldown_timer > 0.0:
		return

	is_attacking = true
	attack_timer = attack_duration
	attack_cooldown_timer = attack_cooldown
	animation_player.speed_scale = 1.0
	animation_player.play("Nico_Knife_Attack")
	_damage_enemies_in_range()


func _damage_enemies_in_range() -> void:
	for body in attack_area.get_overlapping_bodies():
		if body != self and body.has_method("take_damage"):
			body.take_damage(1)


func take_damage(amount: int) -> void:
	if is_dead:
		return

	health = max(health - amount, 0)
	print("Nico recibió daño. Vida restante: ", health)

	if health <= 0:
		is_dead = true
		velocity = Vector3.ZERO
		animation_player.speed_scale = 1.0
		animation_player.play("Nico_Death")


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
