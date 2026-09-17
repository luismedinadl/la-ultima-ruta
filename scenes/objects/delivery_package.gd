extends Area3D

signal collected


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		print("Paquete recogido.")
		collected.emit()
		queue_free()
