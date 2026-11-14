extends Node
## One shared safe frame for menus; HUD and controls reach the safe screen edges.
var app: Node
var last_safe := Rect2()
var last_view := Vector2.ZERO
var last_mobile := false
var vertical_extension := 0.0

func _ready() -> void:
	name = "ResponsiveLayout"
	process_mode = Node.PROCESS_MODE_ALWAYS
	refresh_layout(true)

func _process(_delta: float) -> void:
	refresh_layout()
	# New menu/cutscene nodes are also fitted, without rebuilding their state.
	fit_backgrounds(app.ui.root)
	if app.ui.dialogue_active and not bool(app.ui.lines[app.ui.line_index].get("document",false)):
		app.ui.dialog.position.y = 201+vertical_extension

func refresh_layout(force: bool = false) -> void:
	var view := get_viewport().get_visible_rect().size
	var safe := Rect2(Vector2.ZERO,view)
	if OS.has_feature("mobile"):
		var physical := Rect2(DisplayServer.get_display_safe_area())
		if physical.has_area():
			safe = (get_viewport().get_screen_transform().affine_inverse()*physical).intersection(safe)
	if not force and view == last_view and safe == last_safe and last_mobile == app.ui.mobile: return
	last_view = view
	last_safe = safe
	last_mobile = app.ui.mobile
	apply_safe_area(safe)

func apply_safe_area(safe: Rect2) -> void:
	if not safe.has_area(): return
	var ui: RouteUI = app.ui
	var factor := minf(safe.size.x/576.0,safe.size.y/324.0)
	ui.root.scale = Vector2.ONE*factor
	ui.root.position = safe.position+(safe.size-Vector2(576,324)*factor)/2.0
	var extra := maxf(0,(safe.size.x/factor-576)/2.0)
	vertical_extension = maxf(0,(safe.size.y/factor-324)/2.0)
	ui.mobile_layout(ui.mobile)
	ui.header.position.x = 8-extra
	ui.header.size.x = 560+2*extra
	ui.health.position.x = 16-extra
	ui.health_text.position.x = 65-extra
	for child in ui.hud.get_children():
		if child is Label and child.text == "NICO": child.position.x = 16-extra
	ui.objective.position.x = 112-extra
	ui.objective.size.x = (226 if ui.mobile else 316)+2*extra
	ui.stats.position.x = (345 if ui.mobile else 448)+extra
	ui.zone_text.position.x = 18-extra
	ui.ammo_panel.position.x = 438+extra if ui.mobile else 8-extra
	ui.documents_button.position.x = 432+extra
	ui.header.position.y = 8-vertical_extension
	ui.health.position.y = 27-vertical_extension
	ui.health_text.position.y = 10-vertical_extension
	for child in ui.hud.get_children():
		if child is Label and child.text == "NICO": child.position.y = 10-vertical_extension
	ui.objective.position.y -= vertical_extension
	ui.stats.position.y -= vertical_extension
	ui.zone_text.position.y = 62-vertical_extension
	ui.ammo_panel.position.y += -vertical_extension if ui.mobile else vertical_extension
	ui.documents_button.position.y = 266+vertical_extension
	ui.hint.position.y += vertical_extension
	app.touch.layout_controls(extra,vertical_extension)
	fit_backgrounds(ui.root)

func fit_backgrounds(node: Node) -> void:
	for child in node.get_children():
		if child is Control and child.get_meta("full_bleed",false):
			var parent_transform: Transform2D = child.get_parent().get_global_transform_with_canvas()
			var bounds: Rect2 = parent_transform.affine_inverse()*get_viewport().get_visible_rect()
			if child is Panel:
				for content in child.get_children():
					if content is Control:
						if not content.has_meta("centered_position"): content.set_meta("centered_position",content.position)
						content.position = content.get_meta("centered_position")-bounds.position
			child.position = bounds.position
			child.size = bounds.size
			if child is TextureRect: child.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		fit_backgrounds(child)
	# The notice belongs to the phone drawn inside the cinematic image.
	if node.get_script() == preload("res://scripts/intro.gd") and is_instance_valid(node.background):
		var bg: TextureRect = node.background
		var cover := maxf(bg.size.x/576.0,bg.size.y/324.0)
		node.phone_notice.position = bg.position+(bg.size-Vector2(576,324)*cover)/2.0+Vector2(336,105)*cover
		node.phone_notice.scale = Vector2.ONE*cover
