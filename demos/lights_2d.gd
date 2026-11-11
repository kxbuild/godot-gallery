extends Node2D
## PointLight2D with shadows from LightOccluder2D shapes; drag the white light around.

var _gallery
var _size := Vector2.ZERO
var _lights: Array[PointLight2D] = []
var _time := 0.0
var _drag := false


func _ready() -> void:
	_gallery = get_meta("gallery")
	_size = get_viewport_rect().size

	var modulate_node := CanvasModulate.new()
	modulate_node.color = Color(0.12, 0.12, 0.16)
	add_child(modulate_node)

	var floor_rect := ColorRect.new()
	floor_rect.color = Color("#dee2e6")
	floor_rect.size = _size
	add_child(floor_rect)

	# Pillars that cast shadows
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 9:
		var center := Vector2(rng.randf_range(50, _size.x - 50), rng.randf_range(_gallery.header_height() + 60, _size.y - 120))
		_pillar(center, rng.randf_range(16, 30), i % 3 == 0)

	var tex := _light_texture()
	_lights.append(_light(tex, Color("#fff4e0"), 0.9, _size / 2))
	_lights.append(_light(tex, Color("#ff6b6b"), 1.0, Vector2(80, 300)))
	_lights.append(_light(tex, Color("#4dabf7"), 1.0, Vector2(300, 600)))

	var hint := Label.new()
	hint.text = "Drag to move the white light"
	hint.position = Vector2(16, _gallery.header_height() + 10)
	hint.add_theme_color_override("font_color", Color.WHITE)
	var layer := CanvasLayer.new()
	layer.add_child(hint)
	add_child(layer)


func _pillar(center: Vector2, r: float, square: bool) -> void:
	var pts := PackedVector2Array()
	var sides := 4 if square else 12
	for i in sides:
		var a := TAU * i / sides + (PI / 4 if square else 0.0)
		pts.append(Vector2(cos(a), sin(a)) * r)
	var poly := Polygon2D.new()
	poly.polygon = pts
	poly.color = Color("#495057")
	poly.position = center
	add_child(poly)
	var occ := LightOccluder2D.new()
	var shape := OccluderPolygon2D.new()
	shape.polygon = pts
	occ.occluder = shape
	occ.position = center
	add_child(occ)


func _light(tex: Texture2D, color: Color, energy: float, at: Vector2) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = tex
	l.texture_scale = 2.4
	l.color = color
	l.energy = energy
	l.position = at
	l.shadow_enabled = true
	l.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	l.shadow_filter_smooth = 3.0
	add_child(l)
	return l


func _light_texture() -> Texture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1, 0.5)
	t.width = 256
	t.height = 256
	return t


func _process(delta: float) -> void:
	_time += delta
	_lights[1].position = _size / 2 + Vector2(cos(_time * 0.7), sin(_time * 1.1)) * Vector2(_size.x * 0.4, _size.y * 0.3)
	_lights[2].position = _size / 2 + Vector2(sin(_time * 0.5), cos(_time * 0.8)) * Vector2(_size.x * 0.35, _size.y * 0.35)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_drag = event.pressed and event.position.y > _gallery.header_height()
		if _drag:
			_lights[0].position = event.position
	elif event is InputEventScreenDrag and _drag:
		_lights[0].position = event.position
