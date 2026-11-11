extends Control
## A two-octave keyboard that synthesizes its sound with AudioStreamGenerator.

const WAVES := ["Sine", "Square", "Saw", "Triangle"]
const WHITE_KEYS := [0, 2, 4, 5, 7, 9, 11]
const BLACK_KEYS := {1: 0, 3: 1, 6: 3, 8: 4, 10: 5}  # semitone → white key it sits after
const BASE_MIDI := 60  # middle C
const RATE := 44100.0

var _gallery
var _player: AudioStreamPlayer
var _playback: AudioStreamGeneratorPlayback
var _voices := {}  # midi note → {phase, amp, held}
var _wave := 0
var _keys_rect := Rect2()
var _pointer_note := {}  # touch index → midi note
var _scope := PackedFloat32Array()


func _ready() -> void:
	_gallery = get_meta("gallery")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.06
	_player = AudioStreamPlayer.new()
	_player.stream = gen
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()

	var waves := HBoxContainer.new()
	waves.position = Vector2(16, _gallery.header_height() + 12)
	var group := ButtonGroup.new()
	for i in WAVES.size():
		var b := Button.new()
		b.text = WAVES[i]
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = i == 0
		b.pressed.connect(func() -> void: _wave = i)
		waves.add_child(b)
	add_child(waves)
	_scope.resize(256)


func _process(_delta: float) -> void:
	_fill_buffer()
	var size := get_viewport_rect().size
	var h := 260.0
	_keys_rect = Rect2(Vector2(8, size.y - _gallery.bottom_inset() - h - 12), Vector2(size.x - 16, h))
	queue_redraw()


func _fill_buffer() -> void:
	var frames := _playback.get_frames_available()
	for f in frames:
		var s := 0.0
		for note in _voices.keys():
			var v: Dictionary = _voices[note]
			var target: float = 0.22 if v.held else 0.0
			v.amp = lerp(v.amp, target, 0.004 if v.held else 0.0015)
			var freq: float = 440.0 * pow(2.0, (note - 69) / 12.0)
			v.phase = fmod(v.phase + freq / RATE, 1.0)
			s += _osc(v.phase) * v.amp
			if not v.held and v.amp < 0.0005:
				_voices.erase(note)
		s = clamp(s, -1.0, 1.0)
		_playback.push_frame(Vector2(s, s))
		if f < _scope.size():
			_scope[f] = s


func _osc(p: float) -> float:
	match _wave:
		1:
			return 1.0 if p < 0.5 else -1.0
		2:
			return 2.0 * p - 1.0
		3:
			return 4.0 * abs(p - 0.5) - 1.0
	return sin(p * TAU)


func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("#1c1c1e"))

	# Oscilloscope of the most recent samples.
	var scope_rect := Rect2(16, _gallery.header_height() + 70, size.x - 32, 160)
	draw_rect(scope_rect, Color("#2c2c2e"))
	var pts := PackedVector2Array()
	for i in _scope.size():
		pts.append(scope_rect.position + Vector2(scope_rect.size.x * i / (_scope.size() - 1), scope_rect.size.y * (0.5 - _scope[i] * 1.6)))
	draw_polyline(pts, Color("#51cf66"), 2)
	draw_string(ThemeDB.fallback_font, scope_rect.position + Vector2(8, 20), "%d voice%s" % [_voices.size(), "" if _voices.size() == 1 else "s"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#adb5bd"))

	var whites := 14
	var w := _keys_rect.size.x / whites
	for i in whites:
		var note: int = BASE_MIDI + 12 * (i / 7) + WHITE_KEYS[i % 7]
		var r := Rect2(_keys_rect.position + Vector2(i * w, 0), Vector2(w - 2, _keys_rect.size.y))
		draw_rect(r, Color("#74c0fc") if _is_down(note) else Color.WHITE)
	for octave in 2:
		for semitone in BLACK_KEYS:
			var note: int = BASE_MIDI + 12 * octave + semitone
			var x: float = _keys_rect.position.x + (octave * 7 + BLACK_KEYS[semitone] + 1) * w - w * 0.3
			var r := Rect2(Vector2(x, _keys_rect.position.y), Vector2(w * 0.6, _keys_rect.size.y * 0.6))
			draw_rect(r, Color("#339af0") if _is_down(note) else Color("#212529"))


func _is_down(note: int) -> bool:
	return _voices.has(note) and _voices[note].held


func _note_at(p: Vector2) -> int:
	if not _keys_rect.has_point(p):
		return -1
	var w := _keys_rect.size.x / 14
	var local := p - _keys_rect.position
	if local.y < _keys_rect.size.y * 0.6:
		for octave in 2:
			for semitone in BLACK_KEYS:
				var x: float = (octave * 7 + BLACK_KEYS[semitone] + 1) * w - w * 0.3
				if local.x >= x and local.x <= x + w * 0.6:
					return BASE_MIDI + 12 * octave + semitone
	var i := int(local.x / w)
	return BASE_MIDI + 12 * (i / 7) + WHITE_KEYS[i % 7]


func _press(idx: int, p: Vector2) -> void:
	var note := _note_at(p)
	if _pointer_note.get(idx, -1) == note:
		return
	_release(idx)
	if note < 0:
		return
	_pointer_note[idx] = note
	if _voices.has(note):
		_voices[note].held = true
	else:
		_voices[note] = {"phase": 0.0, "amp": 0.0, "held": true}


func _release(idx: int) -> void:
	if _pointer_note.has(idx):
		var note: int = _pointer_note[idx]
		_pointer_note.erase(idx)
		if _voices.has(note) and not _pointer_note.values().has(note):
			_voices[note].held = false


func _unhandled_input(event: InputEvent) -> void:
	_handle(event)


func _handle(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event.index, event.position)
		else:
			_release(event.index)
	elif event is InputEventScreenDrag:
		_press(event.index, event.position)
