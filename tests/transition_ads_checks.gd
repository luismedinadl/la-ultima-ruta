extends SceneTree

var transitions := 0

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var ads := preload("res://scripts/transition_ads.gd").new()
	root.add_child(ads)
	ads.transition(func(): transitions += 1)
	ads.presenting = true
	ads.transition(func(): transitions += 1)
	var passed := transitions == 1 and not ads.privacy_required()
	ads.free()
	print("Ad-free transition and duplicate input guard: ", passed)
	quit(0 if passed else 1)
