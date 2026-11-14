extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(RouteLevel.LOCAL - RouteLevel.START_X == 50 * RouteLevel.METRE)
	assert(RouteLevel.CROSSING - RouteLevel.LOCAL == 50 * RouteLevel.METRE)
	assert(RouteLevel.DELIVERY - RouteLevel.CROSSING == 50 * RouteLevel.METRE)
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	app.start_route(false)
	assert("50 m" in app.level.interaction_hint())
	app.level.restore({"stage":2,"x":4525,"health":85,"kills":3,"damage":15,"elapsed":90,"collected":["2300"]})
	assert(is_equal_approx(app.level.player.position.x,1660))
	assert(app.level.kills == 3 and app.level.player.health == 85)
	assert(app.level.collected.has("610"))
	assert(not app.level.medkits["610"].visible)
	assert(app.level.snapshot().layout_version == 3)
	app.level.restore({"layout_version":2,"stage":2,"x":1060,"health":85,"kills":3,"damage":15,"elapsed":90,"collected":["1570"]})
	assert(is_equal_approx(app.level.player.position.x,1660))
	assert(app.level.collected.has("2510"))
	assert(not app.level.medkits["2510"].visible)
	app.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.2).timeout
	RouteArt.frame_cache.clear()
	RouteArt.textures.clear()
	RouteArt.anchor_cache.clear()
	RouteArt.character_regions.clear()
	await create_timer(0.15).timeout
	print("SHORT_ROUTE: PASS distances, HUD, checkpoint migration and collected medkits")
	quit()
