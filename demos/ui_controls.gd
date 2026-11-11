extends Control
## Built-in Control nodes, grouped into cards.

var _status: Label


func _ready() -> void:
	var gallery = get_meta("gallery")
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(scroll)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 16)
	scroll.add_child(col)
	var top := Control.new()
	top.custom_minimum_size.y = gallery.header_height()
	col.add_child(top)

	_status = Label.new()
	_status.text = "Interact with any control."
	_status.add_theme_color_override("font_color", Color("#6c6c70"))
	_status.add_theme_font_size_override("font_size", 14)
	_card(col, "Status", [_status])

	# Buttons
	var buttons := HFlowContainer.new()
	for t in ["Button", "Disabled", "Toggle"]:
		var b := Button.new()
		b.text = t
		b.disabled = t == "Disabled"
		b.toggle_mode = t == "Toggle"
		b.pressed.connect(func() -> void: _say("%s pressed%s" % [t, " (on)" if b.button_pressed else ""]))
		buttons.add_child(b)
	var menu := MenuButton.new()
	menu.text = "Menu ▾"
	for item in ["New", "Open", "Save"]:
		menu.get_popup().add_item(item)
	menu.get_popup().id_pressed.connect(func(id: int) -> void: _say("Menu: " + menu.get_popup().get_item_text(id)))
	buttons.add_child(menu)
	_card(col, "Buttons", [buttons])

	# Toggles
	var check := CheckBox.new()
	check.text = "CheckBox"
	check.toggled.connect(func(on: bool) -> void: _say("CheckBox " + ("on" if on else "off")))
	var sw := CheckButton.new()
	sw.text = "CheckButton (switch)"
	sw.button_pressed = true
	sw.toggled.connect(func(on: bool) -> void: _say("Switch " + ("on" if on else "off")))
	var radios := HBoxContainer.new()
	var group := ButtonGroup.new()
	for r in ["Small", "Medium", "Large"]:
		var rb := CheckBox.new()
		rb.text = r
		rb.button_group = group
		rb.button_pressed = r == "Medium"
		rb.pressed.connect(func() -> void: _say("Size: " + r))
		radios.add_child(rb)
	_card(col, "Toggles", [check, sw, radios])

	# Ranges
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.value = 40
	slider.custom_minimum_size.y = 32
	var bar := ProgressBar.new()
	bar.value = 40
	slider.value_changed.connect(func(v: float) -> void:
		bar.value = v
		_say("Slider %d" % v))
	var spin := SpinBox.new()
	spin.min_value = 0
	spin.max_value = 10
	spin.value = 3
	spin.value_changed.connect(func(v: float) -> void: _say("SpinBox %d" % v))
	_card(col, "HSlider, ProgressBar, SpinBox", [slider, bar, spin])

	# Text
	var line := LineEdit.new()
	line.placeholder_text = "LineEdit — type here"
	line.clear_button_enabled = true
	line.text_submitted.connect(func(s: String) -> void: _say("Submitted: " + s))
	var text := TextEdit.new()
	text.placeholder_text = "TextEdit — several lines"
	text.custom_minimum_size.y = 90
	text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	var rich := RichTextLabel.new()
	rich.bbcode_enabled = true
	rich.fit_content = true
	rich.text = "[b]RichTextLabel[/b] with [color=#0a84ff]colors[/color], [i]italics[/i], [u]underline[/u] and [wave amp=30 freq=4]animated text[/wave]."
	_card(col, "Text", [line, text, rich])

	# Pickers
	var option := OptionButton.new()
	for o in ["Apple", "Banana", "Cherry"]:
		option.add_item(o)
	option.item_selected.connect(func(i: int) -> void: _say("Option: " + option.get_item_text(i)))
	var color := ColorPickerButton.new()
	color.color = Color("#ff6b6b")
	color.custom_minimum_size = Vector2(0, 40)
	color.color_changed.connect(func(c: Color) -> void: _say("Color #" + c.to_html(false)))
	_card(col, "OptionButton, ColorPickerButton", [option, color])

	# Lists
	var items := ItemList.new()
	items.custom_minimum_size.y = 130
	for i in 8:
		items.add_item("Item %d" % (i + 1))
	items.item_selected.connect(func(i: int) -> void: _say("ItemList: " + items.get_item_text(i)))
	var tree := Tree.new()
	tree.custom_minimum_size.y = 150
	var root := tree.create_item()
	tree.hide_root = true
	for folder in ["Documents", "Pictures"]:
		var f := tree.create_item(root)
		f.set_text(0, folder)
		for n in 3:
			tree.create_item(f).set_text(0, "%s file %d" % [folder.substr(0, 3), n + 1])
	tree.item_selected.connect(func() -> void: _say("Tree: " + tree.get_selected().get_text(0)))
	_card(col, "ItemList, Tree", [items, tree])

	# Tabs
	var tabs := TabContainer.new()
	tabs.custom_minimum_size.y = 110
	for t in ["First", "Second", "Third"]:
		var page := Label.new()
		page.name = t
		page.text = "Content of the %s tab." % t.to_lower()
		page.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		page.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tabs.add_child(page)
	_card(col, "TabContainer", [tabs])

	var bottom := Control.new()
	bottom.custom_minimum_size.y = gallery.bottom_inset() + 24
	col.add_child(bottom)


func _card(parent: Control, title: String, children: Array) -> void:
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 16)
	parent.add_child(m)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	m.add_child(box)
	var heading := Label.new()
	heading.text = title.to_upper()
	heading.add_theme_font_size_override("font_size", 13)
	heading.add_theme_color_override("font_color", Color("#6c6c70"))
	box.add_child(heading)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", sb)
	box.add_child(panel)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	panel.add_child(inner)
	for c in children:
		inner.add_child(c)


func _say(s: String) -> void:
	_status.text = s
