extends Control
## Pick a map: every arena, sorted by where in the world it is, or leave it to chance. And pick the weather, or leave
## that to chance as well.

var root: UiRoot
var args: Dictionary
var screen_name: String
var _grid: GridContainer
var _region := ""
var _theme := ""
var _regions: HBoxContainer
var _themes: HBoxContainer
var _themes_scroll: ScrollContainer
var _weather_button: GameButton


func _ready() -> void:
	var col := UiKit.vbox(6)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 10
	col.offset_right = -10
	col.offset_top = 4
	col.offset_bottom = -8
	add_child(col)
	var head := UiKit.hbox(8)
	var back := UiKit.button("", "ink", 18, "arrow_left")
	back.custom_minimum_size = Vector2(48 if root.phone_narrow else 56, 48)
	back.pressed.connect(func() -> void: root.go_back())
	head.add_child(back)
	var heading := UiKit.title("MAPS" if root.phone_narrow else "MAPS (%d)" % Maps.all().size(), 28 if not (root.compact or root.phone_narrow) else 22)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(heading)
	if not args.get("room", false):
		_weather_button = UiKit.button("", "blue", 15, "w_storm")
		_weather_button.pressed.connect(_weather_popup)
		head.add_child(_weather_button)
		_show_weather()
	var random := UiKit.button("Random", "pink", 14 if root.phone_narrow else 18, "star")
	random.pressed.connect(func() -> void: _pick(""))
	head.add_child(random)
	col.add_child(head)
	var regions_scroll := _row_scroller()
	_regions = UiKit.hbox(6)
	regions_scroll.add_child(_regions)
	col.add_child(regions_scroll)
	_themes_scroll = _row_scroller()
	_themes = UiKit.hbox(6)
	_themes_scroll.add_child(_themes)
	col.add_child(_themes_scroll)
	var scroll := UiKit.scroller()
	col.add_child(scroll)
	_grid = GridContainer.new()
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_grid)
	_grid.columns = clampi(int(size.x / 214.0), 2, 6)
	_refresh_chips()
	_refill()


func _row_scroller() -> ScrollContainer:
	var scroll := UiKit.scroller(true)
	scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll.custom_minimum_size.y = 52
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return scroll


func _refresh_chips() -> void:
	for child in _regions.get_children():
		child.queue_free()
	for child in _themes.get_children():
		child.queue_free()
	_regions.add_child(_region_chip("Everywhere", ""))
	for region: Dictionary in Maps.REGIONS:
		_regions.add_child(_region_chip(region["name"], region["id"]))
	_themes_scroll.visible = _region != ""
	if _region == "":
		return
	_themes.add_child(_theme_chip("All", ""))
	for theme_id: String in Maps.THEME_ORDER:
		if Maps.theme_info(theme_id).get("region", "") == _region:
			_themes.add_child(_theme_chip(Maps.THEMES[theme_id]["name"], theme_id))


func _region_chip(text: String, id: String) -> Control:
	var chip := UiKit.button(text, "yellow" if id == _region else "teal", 15, "globe" if id == "" else "")
	chip.custom_minimum_size.y = 44
	chip.pressed.connect(func() -> void:
		_region = id
		_theme = ""
		_refresh_chips()
		_refill())
	return chip


func _theme_chip(text: String, theme_id: String) -> Control:
	var chip := UiKit.button(text, "blue" if theme_id == _theme else "ink", 14)
	chip.custom_minimum_size.y = 44
	chip.pressed.connect(func() -> void:
		_theme = theme_id
		_refresh_chips()
		_refill())
	return chip


func _refill() -> void:
	for child in _grid.get_children():
		child.queue_free()
	for map: Dictionary in Maps.all():
		var info := Maps.theme_info(map["theme"])
		if (_region == "" or info.get("region", "") == _region) and (_theme == "" or map["theme"] == _theme):
			_grid.add_child(_card(map, info))


func _card(map: Dictionary, info: Dictionary) -> Control:
	var id: String = map["id"]
	var card := Button.new()
	card.flat = true
	card.focus_mode = Control.FOCUS_ALL
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var width := (size.x - 20.0 - 8.0 * (_grid.columns - 1)) / _grid.columns
	card.custom_minimum_size = Vector2(0, width * 0.56 + 78.0)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.tooltip_text = String(Maps.LAYOUTS[map["layout"]]["blurb"])
	card.pressed.connect(func() -> void: _pick(id))
	var selected: bool = Profile.favorite_map == id
	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := UiKit.card_style(UiKit.YELLOW if selected else UiKit.CARD, 14, 3)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	box.add_theme_stylebox_override("panel", style)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	var col := UiKit.vbox(2)
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
	var name_label := UiKit.label(String(map["name"]), 14, UiKit.INK if selected else UiKit.WHITE, 0 if selected else 4, true)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(name_label)
	var foot := UiKit.hbox(3)
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.add_child(UiKit.label(String(info.get("place", "")), 12, UiKit.INK))
	for kind: String in info.get("weather", []):
		foot.add_child(UiKit.icon(String(Weather.def(kind)["icon"]), 18))
	col.add_child(foot)
	return card


func _show_weather() -> void:
	var chosen := Profile.favorite_weather
	if _weather_button:
		_weather_button.set_text("Sky: " + (String(Weather.def(chosen)["name"]) if chosen != "" else "Surprise") if not root.phone_narrow else "")


## Choose what the sky does in your AI matches. Online, it's whatever the map feels like.
func _weather_popup() -> void:
	var popup := root.popup("What's the Weather?", true)
	var scroll := UiKit.scroller()
	scroll.custom_minimum_size.y = minf(root.get_viewport_rect().size.y * 0.62, 420.0)
	popup.add_child(scroll)
	var list := UiKit.vbox(6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	list.add_child(_weather_row(popup, "", "w_storm", "Surprise Me", "Whatever the map's sky feels like. Different every game."))
	for kind: String in Weather.ORDER:
		var def := Weather.def(kind)
		list.add_child(_weather_row(popup, kind, def["icon"], def["name"], def["hint"]))
	var close := UiKit.button("Close", "ink", 20)
	close.pressed.connect(func() -> void: root.close_popup(popup))
	popup.add_child(close)


func _weather_row(popup: Control, kind: String, icon_name: String, title: String, hint: String) -> Control:
	var row := Button.new()
	row.flat = true
	row.focus_mode = Control.FOCUS_ALL
	row.custom_minimum_size = Vector2(0, 62)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := UiKit.card_style(UiKit.YELLOW if kind == Profile.favorite_weather else UiKit.PAPER, 12, 3)
	style.border_color = UiKit.INK
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	box.add_theme_stylebox_override("panel", style)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(box)
	var line := UiKit.hbox(8)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(line)
	line.add_child(UiKit.icon(icon_name, 40))
	var text := UiKit.vbox(0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(UiKit.label(title, 16, UiKit.INK, 0, true))
	var words := UiKit.body(hint, 13, UiKit.INK)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(words)
	line.add_child(text)
	row.pressed.connect(func() -> void:
		Profile.favorite_weather = kind
		Profile.save()
		Audio.sfx("ui_confirm")
		root.close_popup(popup)
		_show_weather())
	return row


func _pick(id: String) -> void:
	if args.get("room", false):
		Net.room_config(id, float(Net.room.get("skill", 0.52)))
	else:
		Profile.favorite_map = id
		Profile.save()
	root.toast("Map: %s" % (String(Maps.by_id(id).get("name", "")) if id != "" else "Random"), UiKit.YELLOW)
	Audio.sfx("ui_confirm")
	root.go_back()
