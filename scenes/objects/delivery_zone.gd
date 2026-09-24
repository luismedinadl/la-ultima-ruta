extends Area3D

signal player_entered

@onready var complete_sound: AudioStreamPlayer = $CompleteSound


func _ready() -> void:
	complete_sound.process_mode = Node.PROCESS_MODE_ALWAYS
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		complete_sound.play()
		player_entered.emit()
