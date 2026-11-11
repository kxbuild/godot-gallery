extends Control
## canvas_item shaders with uniforms driven by the controls below them.

const PLASMA := """
shader_type canvas_item;
uniform float speed = 1.0;
uniform float scale = 6.0;
void fragment() {
	vec2 p = UV * scale;
	float t = TIME * speed;
	float v = sin(p.x + t) + sin(p.y + t * 1.3) + sin(p.x + p.y + t * 0.7) + sin(length(p - scale * 0.5) * 1.5 - t);
	COLOR = vec4(0.5 + 0.5 * sin(v * 3.1416 + vec3(0.0, 2.0, 4.0)), 1.0);
}
"""

const RIPPLE := """
shader_type canvas_item;
uniform vec2 center = vec2(0.5, 0.5);
uniform float strength = 0.03;
uniform vec4 tint : source_color = vec4(0.2, 0.5, 1.0, 1.0);
void fragment() {
	vec2 d = UV - center;
	float r = length(d);
	float wave = sin(r * 60.0 - TIME * 6.0) * strength / (1.0 + r * 20.0);
	vec2 uv = UV + normalize(d + 1e-5) * wave;
	float checker = mod(floor(uv.x * 12.0) + floor(uv.y * 12.0), 2.0);
	COLOR = mix(tint, vec4(1.0), 0.35 + 0.4 * checker);
}
"""

const DISSOLVE := """
shader_type canvas_item;
uniform float amount : hint_range(0.0, 1.0) = 0.4;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
void fragment() {
	float n = noise(UV * 8.0) * 0.6 + noise(UV * 20.0) * 0.4;
	vec4 base = vec4(mix(vec3(1.0, 0.42, 0.42), vec3(0.52, 0.37, 0.97), UV.y), 1.0);
	float edge = smoothstep(amount, amount + 0.06, n);
	vec3 glow = vec3(1.0, 0.75, 0.2) * (1.0 - smoothstep(0.0, 0.06, abs(n - amount)));
	COLOR = vec4(base.rgb * edge + glow, max(edge, length(glow)));
}
"""

var _ripple: ShaderMaterial
var _ripple_rect: ColorRect


func _ready() -> void:
	var gallery = get_meta("gallery")
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	scroll.add_child(col)
	var top := Control.new()
	top.custom_minimum_size.y = gallery.header_height()
	col.add_child(top)

	var plasma := _shader_rect(col, "Plasma", PLASMA)
	_slider(col, "Speed", 0.0, 4.0, 1.0, func(v: float) -> void: plasma.set_shader_parameter("speed", v))
	_slider(col, "Scale", 2.0, 16.0, 6.0, func(v: float) -> void: plasma.set_shader_parameter("scale", v))

	_ripple = _shader_rect(col, "Ripple — tap the image", RIPPLE)
	_ripple_rect = col.get_child(col.get_child_count() - 1).get_child(0)
	_ripple_rect.gui_input.connect(_on_ripple_input)
	_slider(col, "Strength", 0.0, 0.1, 0.03, func(v: float) -> void: _ripple.set_shader_parameter("strength", v))

	var dissolve := _shader_rect(col, "Dissolve", DISSOLVE)
	_slider(col, "Amount", 0.0, 1.0, 0.4, func(v: float) -> void: dissolve.set_shader_parameter("amount", v))

	var bottom := Control.new()
	bottom.custom_minimum_size.y = gallery.bottom_inset() + 24
	col.add_child(bottom)


func _shader_rect(col: Control, title: String, code: String) -> ShaderMaterial:
	var label := Label.new()
	label.text = title.to_upper()
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("#6c6c70"))
	_padded(col, label)
	var rect := ColorRect.new()
	rect.custom_minimum_size.y = 170
	var shader := Shader.new()
	shader.code = code
	var mat := ShaderMaterial.new()
	mat.shader = shader
	rect.material = mat
	_padded(col, rect)
	return mat


func _slider(col: Control, title: String, lo: float, hi: float, value: float, on_change: Callable) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 80
	label.add_theme_font_size_override("font_size", 14)
	row.add_child(label)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = (hi - lo) / 100.0
	s.value = value
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size.y = 32
	s.value_changed.connect(on_change)
	row.add_child(s)
	_padded(col, row)


func _padded(col: Control, c: Control) -> void:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_child(c)
	col.add_child(m)


func _on_ripple_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or event is InputEventMouseMotion and event.button_mask != 0:
		_ripple.set_shader_parameter("center", event.position / _ripple_rect.size)
