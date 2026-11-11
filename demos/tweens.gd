extends Control
## Tween transitions side by side, plus a chained / parallel sequence.

const TRANSITIONS := {
	"LINEAR": Tween.TRANS_LINEAR, "SINE": Tween.TRANS_SINE, "QUAD": Tween.TRANS_QUAD, "CUBIC": Tween.TRANS_CUBIC,
	"EXPO": Tween.TRANS_EXPO, "BACK": Tween.TRANS_BACK, "ELASTIC": Tween.TRANS_ELASTIC, "BOUNCE": Tween.TRANS_BOUNCE,
	"SPRING": Tween.TRANS_SPRING, "CIRC": Tween.TRANS_CIRC,
}
const COLORS := ["#ff6b6b", "#ff922b", "#fcc419", "#51cf66", "#20c997", "#22b8cf", "#339af0", "#5c7cfa", "#845ef7", "#cc5de8"]

var _dots: Array[ColorRect] = []
var _track_w := 0.0
var _ease := Tween.EASE_IN_OUT
var _ease_label: Label
var _hero: ColorRect


func _ready() -> void:
	var gallery = get_meta("gallery")
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_top = gallery.header_height() + 12
	col.offset_left = 16
	col.offset_right = -16
	col.offset_bottom = -gallery.bottom_inset() - 12
	col.add_theme_constant_override("separation", 6)
	add_child(col)

	var i := 0
	for name in TRANSITIONS:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = name
		label.custom_minimum_size.x = 76
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color("#6c6c70"))
		row.add_child(label)
		var track := Panel.new()
		track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		track.custom_minimum_size.y = 26
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#e5e5ea")
		sb.set_corner_radius_all(13)
		track.add_theme_stylebox_override("panel", sb)
		row.add_child(track)
		var dot := ColorRect.new()
		dot.color = Color(COLORS[i])
		dot.size = Vector2(22, 22)
		dot.position = Vector2(2, 2)
		track.add_child(dot)
		_dots.append(dot)
		col.add_child(row)
		i += 1

	_ease_label = Label.new()
	_ease_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_ease_label)
	var buttons := HFlowContainer.new()
	buttons.alignment = FlowContainer.ALIGNMENT_CENTER
	for e in [["Ease in", Tween.EASE_IN], ["Ease out", Tween.EASE_OUT], ["In-out", Tween.EASE_IN_OUT]]:
		var b := Button.new()
		b.text = e[0]
		b.pressed.connect(func() -> void:
			_ease = e[1]
			_play())
		buttons.add_child(b)
	col.add_child(buttons)

	var stage := Control.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.custom_minimum_size.y = 160
	col.add_child(stage)
	_hero = ColorRect.new()
	_hero.color = Color("#0a84ff")
	_hero.size = Vector2(70, 70)
	_hero.pivot_offset = Vector2(35, 35)
	stage.add_child(_hero)
	var seq := Button.new()
	seq.text = "Play sequence"
	seq.pressed.connect(_sequence.bind(stage))
	col.add_child(seq)

	await get_tree().process_frame
	_track_w = _dots[0].get_parent().size.x
	_hero.position = Vector2((stage.size.x - 70) / 2, (stage.size.y - 70) / 2)
	_play()


func _play() -> void:
	_ease_label.text = ["Ease in", "Ease out", "Ease in-out", "Ease out-in"][_ease]
	var keys := TRANSITIONS.keys()
	for i in _dots.size():
		var dot := _dots[i]
		dot.position.x = 2
		var t := create_tween()
		t.tween_property(dot, "position:x", _track_w - 24, 1.4).set_trans(TRANSITIONS[keys[i]]).set_ease(_ease)
		t.tween_interval(0.4)
		t.tween_property(dot, "position:x", 2.0, 1.4).set_trans(TRANSITIONS[keys[i]]).set_ease(_ease)


func _sequence(stage: Control) -> void:
	var center := Vector2((stage.size.x - 70) / 2, (stage.size.y - 70) / 2)
	var t := create_tween()
	t.tween_property(_hero, "position", Vector2(0, 0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_hero, "position", Vector2(stage.size.x - 70, 0), 0.5).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(_hero, "rotation", PI, 0.5)
	t.tween_property(_hero, "color", Color("#ff6b6b"), 0.3)
	t.tween_property(_hero, "position", Vector2(stage.size.x - 70, stage.size.y - 70), 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_property(_hero, "scale", Vector2(1.6, 1.6), 0.3)
	t.tween_property(_hero, "scale", Vector2.ONE, 0.3)
	t.tween_property(_hero, "position", center, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(_hero, "rotation", 0.0, 0.6)
	t.parallel().tween_property(_hero, "color", Color("#0a84ff"), 0.6)
