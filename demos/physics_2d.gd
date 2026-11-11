extends Node2D
## RigidBody2D playground: tap to drop balls and boxes, drag to fling them.

const COLORS := ["#ff6b6b", "#ff922b", "#fcc419", "#51cf66", "#22b8cf", "#339af0", "#845ef7", "#f06595"]

var _gallery
var _size := Vector2.ZERO
var _count := 0
var _label: Label
var _held: RigidBody2D
var _held_offset := Vector2.ZERO


class Shape2DBody extends RigidBody2D:
	var color := Color.WHITE
	var radius := 0.0
	var extents := Vector2.ZERO

	func _draw() -> void:
		if radius > 0:
			draw_circle(Vector2.ZERO, radius, color)
			draw_line(Vector2.ZERO, Vector2(radius, 0), color.darkened(0.4), 3)
		else:
			draw_rect(Rect2(-extents, extents * 2), color)
			draw_rect(Rect2(-extents, extents * 2), color.darkened(0.3), false, 3)


func _ready() -> void:
	_gallery = get_meta("gallery")
	_size = get_viewport_rect().size
	var bg := ColorRect.new()
	bg.color = Color("#f8f9fa")
	bg.size = _size
	add_child(bg)

	var floor_y: float = _size.y - _gallery.bottom_inset() - 20
	_wall(Vector2(_size.x / 2, floor_y + 20), Vector2(_size.x, 40))
	_wall(Vector2(-20, _size.y / 2), Vector2(40, _size.y * 2))
	_wall(Vector2(_size.x + 20, _size.y / 2), Vector2(40, _size.y * 2))
	# Two angled shelves
	_wall(Vector2(_size.x * 0.32, _size.y * 0.45), Vector2(_size.x * 0.5, 14), 0.22)
	_wall(Vector2(_size.x * 0.7, _size.y * 0.65), Vector2(_size.x * 0.5, 14), -0.22)

	_label = Label.new()
	_label.position = Vector2(16, _gallery.header_height() + 10)
	_label.add_theme_color_override("font_color", Color("#495057"))
	add_child(_label)
	_update_label()
	for i in 6:
		_spawn(Vector2(randf_range(60, _size.x - 60), _gallery.header_height() + 60 + i * 30))


func _wall(center: Vector2, size: Vector2, angle := 0.0) -> void:
	var body := StaticBody2D.new()
	body.position = center
	body.rotation = angle
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	var vis := ColorRect.new()
	vis.color = Color("#adb5bd")
	vis.size = size
	vis.position = -size / 2
	body.add_child(vis)
	add_child(body)


func _spawn(at: Vector2) -> void:
	var body := Shape2DBody.new()
	body.position = at
	body.color = Color(COLORS[_count % COLORS.size()])
	var shape := CollisionShape2D.new()
	var mat := PhysicsMaterial.new()
	if randf() < 0.5:
		body.radius = randf_range(14, 28)
		var c := CircleShape2D.new()
		c.radius = body.radius
		shape.shape = c
		mat.bounce = 0.55
	else:
		body.extents = Vector2(randf_range(14, 30), randf_range(14, 30))
		var r := RectangleShape2D.new()
		r.size = body.extents * 2
		shape.shape = r
		mat.friction = 0.8
		mat.bounce = 0.1
	body.physics_material_override = mat
	body.add_child(shape)
	add_child(body)
	_count += 1
	_update_label()
	if _count > 120:
		for child in get_children():
			if child is Shape2DBody:
				child.queue_free()
				_count -= 1
				break


func _update_label() -> void:
	_label.text = "%d bodies — tap to drop, drag to throw" % _count


func _unhandled_input(event: InputEvent) -> void:
	var pressed: bool = event is InputEventScreenTouch and event.pressed
	var released: bool = event is InputEventScreenTouch and not event.pressed
	if pressed and event.position.y > _gallery.header_height():
		_held = _body_at(event.position)
		if _held:
			_held_offset = _held.position - event.position
			_held.freeze = true
		else:
			_spawn(event.position)
	elif event is InputEventScreenDrag and _held:
		_held.position = event.position + _held_offset
		_held.set_meta("velocity", event.relative * 60)
	elif released and _held:
		_held.freeze = false
		_held.linear_velocity = _held.get_meta("velocity", Vector2.ZERO)
		_held = null


func _body_at(p: Vector2) -> RigidBody2D:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = p
	for hit in get_world_2d().direct_space_state.intersect_point(query, 1):
		if hit.collider is RigidBody2D:
			return hit.collider
	return null
