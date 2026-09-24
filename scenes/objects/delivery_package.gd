extends Area3D

signal collected

@onready var pickup_sound: AudioStreamPlayer = $PickupSound

var is_collected := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not is_collected:
		is_collected = true
		monitoring = false

		print("Paquete recogido.")
		pickup_sound.play()
		collected.emit()

		await pickup_sound.finished
		queue_free()
