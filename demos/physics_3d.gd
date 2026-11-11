extends Node3D
## A tower of RigidBody3D boxes; tap to throw a heavy ball at the tap point.

var _gallery
var _camera: Camera3D
var _label: Label
var _thrown := 0


func _ready() -> void:
	_gallery = get_meta("gallery")
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#20232a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8899aa")
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-55), deg_to_rad(-35), 0)
	sun.shadow_enabled = true
	add_child(sun)

	_camera = Camera3D.new()
	_camera.position = Vector3(0, 5, 13)
	_camera.look_at_from_position(_camera.position, Vector3(0, 2.5, 0))
	add_child(_camera)

	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(40, 1, 40)
	floor_shape.shape = box_shape
	floor_shape.position.y = -0.5
	floor_body.add_child(floor_shape)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("#495057")
	floor_mesh.material_override = floor_mat
	floor_body.add_child(floor_mesh)
	add_child(floor_body)

	_build_tower()

	var layer := CanvasLayer.new()
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(16, _gallery.header_height() + 10)
	_label.add_theme_color_override("font_color", Color.WHITE)
	layer.add_child(_label)
	var reset := Button.new()
	reset.text = "Rebuild tower"
	reset.position = Vector2(16, get_viewport().get_visible_rect().size.y - _gallery.bottom_inset() - 56)
	reset.pressed.connect(func() -> void:
		for c in get_children():
			if c is RigidBody3D:
				c.queue_free()
		_thrown = 0
		_build_tower())
	layer.add_child(reset)
	_update_label()


func _build_tower() -> void:
	var colors := [Color("#ff6b6b"), Color("#fcc419"), Color("#51cf66"), Color("#339af0"), Color("#cc5de8")]
	for level in 8:
		for i in 3:
			var offset := (i - 1) * 1.05
			var pos := Vector3(offset, 0.5 + level * 1.0, 0) if level % 2 == 0 else Vector3(0, 0.5 + level * 1.0, offset)
			_box(pos, colors[level % colors.size()])


func _box(pos: Vector3, color: Color) -> void:
	var body := RigidBody3D.new()
	body.position = pos
	body.mass = 0.6
	var shape := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = Vector3(1, 1, 1)
	shape.shape = s
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.98, 0.98, 0.98)
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	mesh.material_override = mat
	body.add_child(mesh)
	add_child(body)


func _throw(screen_pos: Vector2) -> void:
	var origin := _camera.project_ray_origin(screen_pos)
	var dir := _camera.project_ray_normal(screen_pos)
	var ball := RigidBody3D.new()
	ball.mass = 6.0
	ball.position = origin + dir * 1.5
	ball.continuous_cd = true
	var shape := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.45
	shape.shape = s
	ball.add_child(shape)
	var mesh := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.45
	sm.height = 0.9
	mesh.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#e9ecef")
	mat.metallic = 0.9
	mat.roughness = 0.2
	mesh.material_override = mat
	ball.add_child(mesh)
	add_child(ball)
	ball.linear_velocity = dir * 28.0
	_thrown += 1
	_update_label()


func _update_label() -> void:
	_label.text = "Tap to throw a ball (%d thrown)" % _thrown


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if event.position.y > _gallery.header_height():
			_throw(event.position)
