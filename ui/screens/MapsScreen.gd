extends Control
## Pick a map: every arena, filterable by theme, or leave it to chance.

var root: UiRoot
var args: Dictionary
var screen_name: String
var _grid: GridContainer
var _filter := ""


func _ready() -> void:
	var col := UiKit.vbox(8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 10
	col.offset_right = -10
	col.offset_top = 4
	col.offset_bottom = -8
	add_child(col)
	var head := UiKit.hbox(8)
	var back := UiKit.button("", "ink", 18, "arrow_left")
	back.custom_minimum_size = Vector2(56, 48)
	back.pressed.connect(func() -> void: root.go_back())
	head.add_child(back)
	var heading := UiKit.title("MAPS" if root.phone_narrow else "MAPS (%d)" % Maps.all().size(), 28 if not root.compact else 22)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(heading)
	var random := UiKit.button("Random", "pink", 18, "star")
	random.pressed.connect(func() -> void: _pick(""))
	head.add_child(random)
	col.add_child(head)
	var chips_scroll := UiKit.scroller(true)
	chips_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	chips_scroll.custom_minimum_size.y = 52
	chips_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var chips := UiKit.hbox(6)
	chips_scroll.add_child(chips)
	col.add_child(chips_scroll)
	chips.add_child(_chip("All", ""))
	for theme_id: String in Maps.THEME_ORDER:
		chips.add_child(_chip(Maps.THEMES[theme_id]["name"], theme_id))
	var scroll := UiKit.scroller()
	col.add_child(scroll)
	_grid = GridContainer.new()
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_grid)
	_grid.columns = clampi(int(size.x / 214.0), 2, 6)
	_refill()


func _chip(text: String, theme_id: String) -> Control:
	var chip := UiKit.button(text, "teal" if theme_id != _filter else "yellow", 15)
	chip.custom_minimum_size.y = 44
	chip.pressed.connect(func() -> void:
		_filter = theme_id
		_refill())
	return chip


func _refill() -> void:
	for child in _grid.get_children():
		child.queue_free()
	for map: Dictionary in Maps.all():
		if _filter == "" or map["theme"] == _filter:
			_grid.add_child(_card(map))


func _card(map: Dictionary) -> Control:
	var id: String = map["id"]
	var card := Button.new()
	card.flat = true
	card.focus_mode = Control.FOCUS_ALL
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var width := (size.x - 20.0 - 8.0 * (_grid.columns - 1)) / _grid.columns
	card.custom_minimum_size = Vector2(0, width * 0.56 + 54.0)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.pressed.connect(func() -> void: _pick(id))
	var selected: bool = Profile.favorite_map == id
	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := UiKit.card_style(UiKit.YELLOW if selected else UiKit.CARD, 14, 3)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 8
	box.add_theme_stylebox_override("panel", style)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	var col := UiKit.vbox(4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(col)
	var pic := TextureRect.new()
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pic.clip_contents = true
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := Maps.thumb_path(id)
	if ResourceLoader.exists(path):
		pic.texture = load(path)
	col.add_child(pic)
	var name_label := UiKit.label(String(map["name"]), 14, UiKit.INK if selected else UiKit.WHITE, 0, true)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(name_label)
	return card


func _pick(id: String) -> void:
	if args.get("room", false):
		Net.room_config(id, float(Net.room.get("skill", 0.52)))
	else:
		Profile.favorite_map = id
		Profile.save()
	root.toast("Map: %s" % (String(Maps.by_id(id).get("name", "")) if id != "" else "Random"), UiKit.YELLOW)
	Audio.sfx("ui_confirm")
	root.go_back()
