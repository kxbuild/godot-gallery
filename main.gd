extends Control
## Godot Gallery: a menu of self-contained demos. Each demo is a script under
## res://demos/ that builds its own nodes in _ready(), so nothing depends on
## scenes edited by hand.

const DEMOS := [
	{"id": "controls", "title": "UI Controls", "summary": "Buttons, toggles, sliders, inputs, lists, trees, tabs", "color": Color("#4dabf7"), "script": "res://demos/ui_controls.gd"},
	{"id": "tweens", "title": "Tweens", "summary": "Transition and easing curves, chained and parallel tweens", "color": Color("#ff922b"), "script": "res://demos/tweens.gd"},
	{"id": "particles", "title": "Particles", "summary": "Fountain, fire and tap-to-burst fireworks", "color": Color("#f06595"), "script": "res://demos/particles.gd"},
	{"id": "physics2d", "title": "2D Physics", "summary": "Rigid bodies, bounce and friction; tap to drop shapes", "color": Color("#51cf66"), "script": "res://demos/physics_2d.gd"},
	{"id": "lights2d", "title": "2D Lights", "summary": "Point lights and occluders casting soft shadows", "color": Color("#fcc419"), "script": "res://demos/lights_2d.gd"},
	{"id": "shaders", "title": "Shaders", "summary": "Animated canvas_item shaders with live uniforms", "color": Color("#cc5de8"), "script": "res://demos/shaders.gd"},
	{"id": "scene3d", "title": "3D Materials", "summary": "PBR materials, shadows, sky, glow and fog", "color": Color("#339af0"), "script": "res://demos/scene_3d.gd"},
	{"id": "physics3d", "title": "3D Physics", "summary": "A tower of boxes; tap to throw a ball", "color": Color("#20c997"), "script": "res://demos/physics_3d.gd"},
	{"id": "input", "title": "Touch & Sensors", "summary": "Multi-touch, pinch and rotate, accelerometer, gyroscope", "color": Color("#ff6b6b"), "script": "res://demos/touch_sensors.gd"},
	{"id": "audio", "title": "Audio Synth", "summary": "A playable keyboard generating sine, square and saw waves", "color": Color("#845ef7"), "script": "res://demos/audio_synth.gd"},
]

const BG := Color("#f2f2f7")
const CARD := Color("#ffffff")
const TEXT := Color("#1c1c1e")
const SUBTEXT := Color("#6c6c70")
const ACCENT := Color("#0a84ff")

var _menu: Control
var _bg: ColorRect
var _stage: Control
var _demo_holder: Node
var _title: Label
var _bar_layer: CanvasLayer
var _top_inset := 0.0
var _bottom_inset := 0.0
var _shot_path := ""
var _shot_frames := 0


func _ready() -> void:
	_compute_safe_area()
	theme = _make_theme()
	_bg = ColorRect.new()
	_bg.color = BG
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_build_menu()
	_build_stage()

	var demo_id := _arg_value("demo")
	_shot_path = _arg_value("shot")
	if demo_id != "":
		for d in DEMOS:
			if d.id == demo_id:
				_open(d)
	if _shot_path != "":
		_shot_frames = int(_arg_value("frames", "90"))


func _process(_delta: float) -> void:
	# --shot=<png> [--frames=N]: save the screen after N frames and quit (used for README screenshots).
	if _shot_path == "":
		return
	_shot_frames -= 1
	if _shot_frames == 0:
		get_viewport().get_texture().get_image().save_png(_shot_path)
		get_tree().quit()


func _arg_value(key: String, fallback := "") -> String:
	var args := OS.get_cmdline_user_args() + OS.get_cmdline_args()
	for i in args.size():
		var a: String = args[i]
		if a.begins_with("--%s=" % key):
			return a.get_slice("=", 1)
		if (a == "-" + key or a == "--" + key) and i + 1 < args.size():
			return args[i + 1]
	return fallback


func _compute_safe_area() -> void:
	var screen := DisplayServer.screen_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if screen.y <= 0 or safe.size.y <= 0:
		return
	var scale := get_viewport_rect().size.y / float(screen.y)
	_top_inset = safe.position.y * scale
	_bottom_inset = (screen.y - safe.end.y) * scale


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 17
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_color", "Button", ACCENT)
	t.set_color("font_hover_color", "Button", ACCENT)
	t.set_color("font_pressed_color", "Button", ACCENT.darkened(0.3))
	t.set_color("font_focus_color", "Button", ACCENT)
	t.set_color("font_disabled_color", "Button", SUBTEXT.lerp(Color.WHITE, 0.4))
	for type in ["CheckBox", "CheckButton"]:
		t.set_color("font_color", type, TEXT)
		t.set_color("font_pressed_color", type, TEXT)
		t.set_color("font_hover_color", type, TEXT)
		t.set_color("font_hover_pressed_color", type, TEXT)
		t.set_color("font_focus_color", type, TEXT)
		for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
			t.set_stylebox(state, type, StyleBoxEmpty.new())
	var field := StyleBoxFlat.new()
	field.bg_color = Color("#f2f2f7")
	field.set_corner_radius_all(8)
	field.set_content_margin_all(8)
	for type in ["LineEdit", "TextEdit"]:
		t.set_stylebox("normal", type, field)
		t.set_stylebox("focus", type, field)
		t.set_color("font_color", type, TEXT)
		t.set_color("font_placeholder_color", type, SUBTEXT)
		t.set_color("caret_color", type, ACCENT)
	for type in ["ItemList", "Tree"]:
		t.set_stylebox("panel", type, field)
		t.set_color("font_color", type, TEXT)
		t.set_color("font_selected_color", type, Color.WHITE)
	var sel := StyleBoxFlat.new()
	sel.bg_color = ACCENT
	sel.set_corner_radius_all(6)
	t.set_stylebox("selected", "ItemList", sel)
	t.set_stylebox("selected_focus", "ItemList", sel)
	t.set_stylebox("selected", "Tree", sel)
	t.set_stylebox("selected_focus", "Tree", sel)
	var track := StyleBoxFlat.new()
	track.bg_color = Color("#e5e5ea")
	track.set_corner_radius_all(6)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ACCENT
	fill.set_corner_radius_all(6)
	t.set_stylebox("background", "ProgressBar", track)
	t.set_stylebox("fill", "ProgressBar", fill)
	t.set_color("font_color", "ProgressBar", TEXT)
	t.set_color("font_color", "TabContainer", SUBTEXT)
	t.set_color("font_selected_color", "TabContainer", ACCENT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = ACCENT.lerp(Color.WHITE, 0.85 if state != "pressed" else 0.7)
		if state == "focus":
			sb.draw_center = false
		sb.set_corner_radius_all(10)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		t.set_stylebox(state, "Button", sb)
	return t


func _build_menu() -> void:
	_menu = MarginContainer.new()
	_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_menu)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_menu.add_child(scroll)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	scroll.add_child(col)

	var top := Control.new()
	top.custom_minimum_size.y = _top_inset + 16
	col.add_child(top)

	var title := Label.new()
	title.text = "Godot Gallery"
	title.add_theme_font_size_override("font_size", 34)
	_pad(col, title)
	var sub := Label.new()
	sub.text = "%d demos of Godot %s on this device" % [DEMOS.size(), Engine.get_version_info().string.get_slice("-", 0).get_slice(".stable", 0)]
	sub.add_theme_color_override("font_color", SUBTEXT)
	sub.add_theme_font_size_override("font_size", 15)
	_pad(col, sub)

	for d in DEMOS:
		_pad(col, _menu_row(d))

	var bottom := Control.new()
	bottom.custom_minimum_size.y = _bottom_inset + 24
	col.add_child(bottom)


func _pad(parent: Node, child: Control) -> void:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_child(child)
	parent.add_child(m)


func _menu_row(d: Dictionary) -> Control:
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", sb)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)

	var swatch := Panel.new()
	swatch.custom_minimum_size = Vector2(36, 36)
	var ss := StyleBoxFlat.new()
	ss.bg_color = d.color
	ss.set_corner_radius_all(8)
	swatch.add_theme_stylebox_override("panel", ss)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(swatch)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 2)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(texts)
	var name_label := Label.new()
	name_label.text = d.title
	texts.add_child(name_label)
	var summary := Label.new()
	summary.text = d.summary
	summary.add_theme_color_override("font_color", SUBTEXT)
	summary.add_theme_font_size_override("font_size", 13)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(summary)

	var chevron := Label.new()
	chevron.text = "›"
	chevron.add_theme_color_override("font_color", SUBTEXT)
	chevron.add_theme_font_size_override("font_size", 24)
	row.add_child(chevron)

	# A tap opens the demo; a drag still scrolls the list.
	card.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			if e.position.distance_to(card.get_meta("down", e.position)) < 12:
				_open(d)
		elif e is InputEventMouseButton and e.pressed:
			card.set_meta("down", e.position))
	return card


func _build_stage() -> void:
	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.visible = false
	add_child(_stage)

	var bar := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.92)
	sb.content_margin_top = _top_inset + 6
	sb.content_margin_bottom = 8
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.border_width_bottom = 1
	sb.border_color = Color("#d1d1d6")
	bar.add_theme_stylebox_override("panel", sb)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	# Its own canvas layer keeps the bar on top of every demo and out of a demo's CanvasModulate.
	_bar_layer = CanvasLayer.new()
	_bar_layer.layer = 5
	_bar_layer.visible = false
	bar.theme = theme  # a CanvasLayer does not inherit the theme of the Control above it
	_bar_layer.add_child(bar)
	add_child(_bar_layer)

	var row := HBoxContainer.new()
	bar.add_child(row)
	var back := Button.new()
	back.text = "‹ Gallery"
	back.flat = true
	back.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	back.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	back.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	back.custom_minimum_size.x = 100
	back.alignment = HORIZONTAL_ALIGNMENT_LEFT
	back.pressed.connect(_close)
	row.add_child(back)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_font_size_override("font_size", 17)
	row.add_child(_title)
	var spacer := Control.new()
	spacer.custom_minimum_size.x = 100
	row.add_child(spacer)


## Height of the navigation bar, so demos can keep their content below it.
func header_height() -> float:
	return _top_inset + 52.0


func bottom_inset() -> float:
	return _bottom_inset


func _open(d: Dictionary) -> void:
	_close()
	var demo: Node = load(d.script).new()
	demo.set_meta("gallery", self)
	_demo_holder = demo
	if demo is Control:
		(demo as Control).set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(demo)
	_stage.move_child(demo, 0)
	_title.text = d.title
	# 2D and 3D demos draw their own background; the menu's would cover a 3D scene.
	_bg.visible = demo is Control
	_menu.visible = false
	_stage.visible = true
	_bar_layer.visible = true


func _close() -> void:
	if _demo_holder:
		_demo_holder.queue_free()
		_demo_holder = null
	_stage.visible = false
	_bar_layer.visible = false
	_bg.visible = true
	_menu.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _stage.visible:
		_close()
