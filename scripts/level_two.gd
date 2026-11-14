class_name RouteLevelTwo
extends RefCounted
## Five authored encounters. Resistant enemies become increasingly common.
static func wave(number: int) -> Dictionary:
	return {"count": [5,7,8,9,10][number-1], "resistant_count": [1,2,3,4,5][number-1],
		"entries": [Vector2(170,220),Vector2(-185,286),Vector2(235,300),Vector2(-245,210),Vector2(95,205),Vector2(255,253),Vector2(-100,302),Vector2(205,276),Vector2(-210,244),Vector2(130,290)]}
static func opening() -> Array:
	return RouteStory.dialogue("level2_open")
