extends Control
## Illustrated prologue. Text is editable in assets/ui/intro/story.json.
## No level exists during playback: inputs, combat and route timer cannot advance.
signal finished

var folder := "res://assets/ui/intro/"
var skip_text := "Saltar intro · Esc"
var pages: Array = []
var page := 0
var closing := false
var transitioning := false
var ui: RouteUI
var background: TextureRect
var caption: Panel
var speaker: Label
var body: Label
var counter: Label
var phone_notice: Label
var fade: ColorRect
var transition: Tween
var textures: Dictionary = {}

func _ready() -> void:
	size = Vector2(576,324)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pages = JSON.parse_string(FileAccess.get_file_as_string(folder+"story.json"))
	var black := ColorRect.new()
	black.set_meta("full_bleed",true)
	black.color = Color.BLACK
	black.size = size
	add_child(black)
	background = ui.image_rect(self,null,Rect2(0,0,576,324))
	background.stretch_mode = TextureRect.STRETCH_SCALE
	for entry in pages:
		if not entry.image.is_empty() and not textures.has(entry.image):
			textures[entry.image] = load(folder+entry.image)
	# Short sender notice on the illustrated screen; full message stays readable below.
	phone_notice = ui.label(self,"",Rect2(336,105,65,88),10,RouteUI.CYAN)
	phone_notice.rotation = 0.14
	phone_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption = ui.panel(self,Rect2(16,229,544,70),Color(0.025,0.04,0.065,0.96))
	speaker = ui.label(caption,"",Rect2(12,6,516,17),10,RouteUI.ORANGE)
	body = ui.label(caption,"",Rect2(12,26,516,40),13)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	counter = ui.label(self,"",Rect2(17,8,90,18),10,RouteUI.CYAN)
	var skip := make_button("Saltar escena" if ui.mobile else skip_text,Rect2(427,8,133,44 if ui.mobile else 24))
	skip.pressed.connect(finish)
	var next := make_button("Continuar" if ui.mobile else "Continuar · E / Enter",Rect2(381,276 if ui.mobile else 300,179,44 if ui.mobile else 23))
	next.pressed.connect(advance)
	ui.label(self,"THE LAST ROUTE",Rect2(17,303,200,14),9,RouteUI.CYAN)
	fade = ColorRect.new()
	fade.set_meta("full_bleed",true)
	fade.color = Color.BLACK
	fade.size = size
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	show_page()
	transitioning = true
	transition = create_tween()
	transition.tween_property(fade,"modulate:a",0.0,0.3)
	transition.tween_callback(func(): transitioning = false)

func make_button(text: String, rect: Rect2) -> Button:
	# Use the common button style without routing these local actions to the app.
	var button := ui.button(self,text,rect,"")
	button.add_theme_font_size_override("font_size",10)
	button.focus_mode = Control.FOCUS_NONE
	return button

func show_page() -> void:
	var entry: Dictionary = pages[page]
	background.texture = textures.get(entry.image)
	background.visible = not entry.image.is_empty()
	speaker.text = entry.name
	body.text = entry.text
	phone_notice.visible = entry.image == "02_telefono.png"
	phone_notice.text = ("MAMÁ" if page == 2 else "VÉRTICE")+"\n\n1 mensaje\nnuevo"
	counter.text = "%02d / %02d" % [page+1,pages.size()]
	var title_card: bool = entry.image.is_empty()
	caption.position = Vector2(16,126) if title_card else Vector2(16,198 if ui.mobile else 229)
	speaker.visible = not title_card
	body.position.y = 15 if title_card else 26
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if title_card else HORIZONTAL_ALIGNMENT_LEFT

func advance() -> void:
	if closing or transitioning: return
	if page == pages.size()-1:
		finish()
		return
	transitioning = true
	transition = create_tween()
	transition.tween_property(fade,"modulate:a",1.0,0.16)
	transition.tween_callback(func():
		page += 1
		show_page())
	transition.tween_property(fade,"modulate:a",0.0,0.2)
	transition.tween_callback(func(): transitioning = false)

func finish() -> void:
	if closing: return
	closing = true
	if transition: transition.kill()
	transition = create_tween()
	transition.tween_property(fade,"modulate:a",1.0,0.2)
	transition.tween_callback(func(): finished.emit())

func _input(event: InputEvent) -> void:
	if ui.mobile and event is InputEventScreenTouch and event.pressed and caption.get_global_rect().has_point(event.position):
		get_viewport().set_input_as_handled()
		advance()
		return
	if event is InputEventKey and event.echo: return
	if event.is_action_pressed("route_pause"):
		get_viewport().set_input_as_handled()
		finish()
	elif event.is_action_pressed("route_interact"):
		get_viewport().set_input_as_handled()
		advance()
