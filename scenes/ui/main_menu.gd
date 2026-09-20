extends Control

@onready var button_sound: AudioStreamPlayer = $ButtonSound

func _ready() -> void:
	$PlayButton.pressed.connect(_on_play_button_pressed)
	$QuitButton.pressed.connect(_on_quit_button_pressed)

func _on_play_button_pressed() -> void:
	button_sound.play()
	await button_sound.finished
	get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
