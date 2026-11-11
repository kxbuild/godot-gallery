extends Node2D
## CPUParticles2D effects: a fountain, a flame, and fireworks where you tap.

var _gallery
var _size := Vector2.ZERO


func _ready() -> void:
	_gallery = get_meta("gallery")
	_size = get_viewport_rect().size
	var bg := ColorRect.new()
	bg.color = Color("#0b1020")
	bg.size = _size
	add_child(bg)

	var hint := Label.new()
	hint.text = "Tap anywhere for fireworks"
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	hint.position = Vector2(16, _gallery.header_height() + 12)
	add_child(hint)

	# Fountain
	var fountain := CPUParticles2D.new()
	fountain.position = Vector2(_size.x * 0.3, _size.y - _gallery.bottom_inset() - 40)
	fountain.amount = 220
	fountain.lifetime = 2.2
	fountain.direction = Vector2.UP
	fountain.spread = 12
	fountain.initial_velocity_min = 420
	fountain.initial_velocity_max = 520
	fountain.gravity = Vector2(0, 520)
	fountain.scale_amount_min = 3
	fountain.scale_amount_max = 6
	fountain.color_ramp = _gradient([Color("#74c0fc"), Color("#4dabf7"), Color(0.3, 0.6, 1, 0)])
	add_child(fountain)

	# Flame
	var flame := CPUParticles2D.new()
	flame.position = Vector2(_size.x * 0.72, _size.y - _gallery.bottom_inset() - 60)
	flame.amount = 160
	flame.lifetime = 1.1
	flame.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	flame.emission_sphere_radius = 18
	flame.direction = Vector2.UP
	flame.spread = 20
	flame.initial_velocity_min = 80
	flame.initial_velocity_max = 160
	flame.gravity = Vector2(0, -60)
	flame.scale_amount_min = 10
	flame.scale_amount_max = 22
	flame.scale_amount_curve = _curve([1.0, 0.2])
	flame.color_ramp = _gradient([Color("#fff3bf"), Color("#ffa94d"), Color("#f03e3e"), Color(0.3, 0.05, 0.05, 0)])
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	flame.material = mat
	add_child(flame)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if event.position.y > _gallery.header_height():
			_burst(event.position)


func _burst(at: Vector2) -> void:
	var hue := randf()
	var p := CPUParticles2D.new()
	p.position = at
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 140
	p.lifetime = 1.6
	p.spread = 180
	p.initial_velocity_min = 120
	p.initial_velocity_max = 320
	p.gravity = Vector2(0, 180)
	p.damping_min = 40
	p.damping_max = 80
	p.scale_amount_min = 3
	p.scale_amount_max = 5
	p.color_ramp = _gradient([Color.from_hsv(hue, 0.3, 1), Color.from_hsv(hue, 0.8, 1), Color.from_hsv(fmod(hue + 0.1, 1), 0.9, 0.8, 0)])
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func _gradient(colors: Array) -> Gradient:
	var g := Gradient.new()
	g.colors = PackedColorArray(colors)
	var offsets := PackedFloat32Array()
	for i in colors.size():
		offsets.append(float(i) / (colors.size() - 1))
	g.offsets = offsets
	return g


func _curve(points: Array) -> Curve:
	var c := Curve.new()
	for i in points.size():
		c.add_point(Vector2(float(i) / (points.size() - 1), points[i]))
	return c
