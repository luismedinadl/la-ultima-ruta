extends CharacterBody3D

@export var max_health: int = 3

var health: int


func _ready() -> void:
	health = max_health


func take_damage(amount: int) -> void:
	health -= amount
	print("Enemigo golpeado. Vida restante: ", health)

	if health <= 0:
		print("Enemigo eliminado.")
		queue_free()
