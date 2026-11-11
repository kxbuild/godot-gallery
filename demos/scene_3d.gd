extends Node3D
## PBR materials under a directional light with shadows, a procedural sky,
## glow and fog. Drag to orbit the camera, pinch or use two fingers to zoom.

var _gallery
var _pivot: Node3D
var _camera: Camera3D
var _yaw := 0.6
var _pitch := -0.35
var _distance := 12.0
var _torus: MeshInstance3D
var _touches := {}
var _env: Environment


func _ready() -> void:
	_gallery = get_meta("gallery")

	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#2f62b0")
	sky_mat.sky_horizon_color = Color("#9fc0e6")
	sky_mat.ground_horizon_color = Color("#9fc0e6")
	sky_mat.ground_bottom_color = Color("#4a4a52")
	sky.sky_material = sky_mat
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.glow_enabled = true
	_env.glow_intensity = 0.6
	_env.glow_bloom = 0.1
	_env.fog_enabled = true
	_env.fog_density = 0.004
	_env.fog_light_color = Color("#9fc0e6")
	var world_env := WorldEnvironment.new()
	world_env.environment = _env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(30), 0)
	sun.shadow_enabled = true
	sun.light_energy = 1.3
	add_child(sun)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 60)
	ground.mesh = plane
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color("#8d949e")
	ground_mat.roughness = 0.9
	ground.material_override = ground_mat
	add_child(ground)

	# A 4×3 grid: metallic increases left to right, roughness front to back.
	for row in 3:
		for col in 4:
			var s := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.5
			sphere.height = 1.0
			s.mesh = sphere
			var m := StandardMaterial3D.new()
			m.albedo_color = Color.from_hsv(0.58 - row * 0.12, 0.6, 0.95)
			m.metallic = col / 3.0
			m.roughness = 0.1 + row * 0.4
			s.material_override = m
			s.position = Vector3(-2.4 + col * 1.6, 0.5, -1.6 + row * 1.6)
			add_child(s)

	_torus = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.5
	torus.outer_radius = 0.9
	_torus.mesh = torus
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = Color("#ff922b")
	glow_mat.emission_enabled = true
	glow_mat.emission = Color("#ff922b")
	glow_mat.emission_energy_multiplier = 2.5
	_torus.material_override = glow_mat
	_torus.position = Vector3(0, 2.6, 0)
	add_child(_torus)

	var glass := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.2, 1.2, 1.2)
	glass.mesh = box
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.6, 0.9, 1.0, 0.35)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.metallic_specular = 1.0
	glass_mat.roughness = 0.05
	glass.material_override = glass_mat
	glass.position = Vector3(3.6, 0.6, 1.6)
	add_child(glass)

	_pivot = Node3D.new()
	add_child(_pivot)
	_camera = Camera3D.new()
	_camera.fov = 55
	_pivot.add_child(_camera)
	_update_camera()

	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := HBoxContainer.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.45)
	bg.set_corner_radius_all(10)
	var holder := PanelContainer.new()
	holder.add_theme_stylebox_override("panel", bg)
	holder.add_child(panel)
	holder.position = Vector2(12, get_viewport().get_visible_rect().size.y - _gallery.bottom_inset() - 56)
	for opt in [["Glow", "glow_enabled"], ["Fog", "fog_enabled"]]:
		var b := CheckButton.new()
		b.text = opt[0]
		b.button_pressed = true
		b.add_theme_color_override("font_color", Color.WHITE)
		b.add_theme_color_override("font_pressed_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
		b.add_theme_color_override("font_focus_color", Color.WHITE)
		b.toggled.connect(func(on: bool) -> void: _env.set(opt[1], on))
		panel.add_child(b)
	layer.add_child(holder)


func _process(delta: float) -> void:
	_torus.rotate_y(delta * 0.9)
	_torus.rotate_x(delta * 0.4)
	if _touches.is_empty():
		_yaw += delta * 0.08
		_update_camera()


func _update_camera() -> void:
	_pitch = clamp(_pitch, -1.3, -0.05)
	_distance = clamp(_distance, 4.0, 20.0)
	_pivot.rotation = Vector3(_pitch, _yaw, 0)
	_camera.position = Vector3(0, 0, _distance)
	_pivot.position = Vector3(0, 0.8, 0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
	elif event is InputEventScreenDrag:
		if _touches.size() == 1:
			_yaw -= event.relative.x * 0.008
			_pitch -= event.relative.y * 0.008
		elif _touches.size() == 2:
			var other: Vector2 = _touches[1 - event.index] if _touches.has(1 - event.index) else event.position
			var before: float = (_touches[event.index] as Vector2).distance_to(other)
			var after: float = event.position.distance_to(other)
			_distance *= before / max(after, 1.0)
		_touches[event.index] = event.position
		_update_camera()
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		_distance *= 0.9 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.1
		_update_camera()
