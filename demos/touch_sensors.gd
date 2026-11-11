extends Control
## Multi-touch points, a pinch / rotate gesture on a card, and the motion sensors.

const COLORS := [Color("#ff6b6b"), Color("#339af0"), Color("#51cf66"), Color("#fcc419"), Color("#cc5de8")]

var _gallery
var _touches := {}
var _card_pos := Vector2.ZERO
var _card_scale := 1.0
var _card_angle := 0.0
var _info: Label
var _gravity := Vector3.ZERO
var _gyro := Vector3.ZERO
var _accel := Vector3.ZERO


func _ready() -> void:
	_gallery = get_meta("gallery")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_pos = get_viewport_rect().size * Vector2(0.5, 0.45)
	_info = Label.new()
	_info.position = Vector2(16, _gallery.header_height() + 10)
	_info.add_theme_font_size_override("font_size", 14)
	_info.add_theme_color_override("font_color", Color("#495057"))
	add_child(_info)


func _process(_delta: float) -> void:
	_gravity = Input.get_gravity()
	_gyro = Input.get_gyroscope()
	_accel = Input.get_accelerometer()
	_info.text = "Touches: %d    Scale: %.2f    Angle: %d°\nGravity  %s\nAccel    %s\nGyro     %s" % [
		_touches.size(), _card_scale, int(rad_to_deg(_card_angle)), _fmt(_gravity), _fmt(_accel), _fmt(_gyro)]
	queue_redraw()


func _fmt(v: Vector3) -> String:
	return "x %6.2f  y %6.2f  z %6.2f" % [v.x, v.y, v.z]


func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("#f1f3f5"))

	# The card follows a two-finger pinch / rotate.
	draw_set_transform(_card_pos, _card_angle, Vector2.ONE * _card_scale)
	var r := Rect2(Vector2(-90, -60), Vector2(180, 120))
	draw_rect(r, Color("#0a84ff"))
	draw_rect(r, Color("#0a64d0"), false, 4)
	draw_string(ThemeDB.fallback_font, Vector2(-62, 8), "Pinch & rotate", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	draw_set_transform(Vector2.ZERO)

	# A bubble level driven by gravity.
	var level_center := Vector2(size.x / 2, size.y - _gallery.bottom_inset() - 110)
	draw_circle(level_center, 80, Color("#dee2e6"))
	draw_arc(level_center, 80, 0, TAU, 64, Color("#adb5bd"), 3)
	draw_arc(level_center, 16, 0, TAU, 32, Color("#868e96"), 2)
	var g := Vector2(_gravity.x, -_gravity.y)
	if g.length() > 0.01:
		g = g.limit_length(9.8) / 9.8
	draw_circle(level_center + g * 64, 14, Color("#51cf66"))

	for idx in _touches:
		var p: Vector2 = _touches[idx]
		var c: Color = COLORS[idx % COLORS.size()]
		draw_circle(p, 44, Color(c, 0.35))
		draw_arc(p, 44, 0, TAU, 48, c, 3)
		draw_string(ThemeDB.fallback_font, p + Vector2(-6, -54), str(idx + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, c)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and event.position.y > _gallery.header_height():
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
	elif event is InputEventScreenDrag and _touches.has(event.index):
		if _touches.size() == 2:
			var other_idx: int = _touches.keys().filter(func(k): return k != event.index)[0]
			var other: Vector2 = _touches[other_idx]
			var before: Vector2 = _touches[event.index] - other
			var after: Vector2 = event.position - other
			if before.length() > 1:
				_card_scale = clamp(_card_scale * after.length() / before.length(), 0.4, 3.0)
				_card_angle += before.angle_to(after)
			_card_pos += event.relative / 2
		elif _touches.size() == 1:
			_card_pos += event.relative
		_touches[event.index] = event.position
	elif event is InputEventMagnifyGesture:
		_card_scale = clamp(_card_scale * event.factor, 0.4, 3.0)
