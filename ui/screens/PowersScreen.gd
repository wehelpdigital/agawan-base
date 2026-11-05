extends Control
## Every power card in the game, by category.

var root: UiRoot
var args: Dictionary
var screen_name: String
var _grid: GridContainer
var _chips: HBoxContainer
var _cat := ""


func _ready() -> void:
	var outer := UiKit.vbox(8)
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 10
	outer.offset_right = -10
	outer.offset_top = 4
	outer.offset_bottom = -8
	add_child(outer)
	var head := UiKit.hbox(8)
	var back := UiKit.button("", "ink", 18, "arrow_left")
	back.custom_minimum_size = Vector2(56, 48)
	back.pressed.connect(func() -> void: root.go_back())
	head.add_child(back)
	var heading := UiKit.title("POWER CARDS (%d)" % Powerups.ALL.size(), 26 if not root.compact else 21)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(heading)
	outer.add_child(head)
	var chips_scroll := UiKit.scroller(true)
	chips_scroll.custom_minimum_size.y = 52
	chips_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	chips_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_chips = UiKit.hbox(6)
	chips_scroll.add_child(_chips)
	outer.add_child(chips_scroll)
	var scroll := UiKit.scroller()
	outer.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = clampi(int(size.x / 340.0), 1, 4)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_grid)
	_refresh()


func _refresh() -> void:
	for child in _chips.get_children():
		child.queue_free()
	_chips.add_child(_chip("All", ""))
	for cat: String in Powerups.CATS:
		_chips.add_child(_chip(Powerups.CATS[cat]["name"], cat))
	for child in _grid.get_children():
		child.queue_free()
	for def: Dictionary in Powerups.ALL:
		if _cat == "" or def["cat"] == _cat:
			_grid.add_child(_card(def))


func _chip(text: String, cat: String) -> Control:
	var b := UiKit.button(text, "yellow" if cat == _cat else "purple", 15)
	b.custom_minimum_size.y = 44
	b.pressed.connect(func() -> void:
		_cat = cat
		_refresh())
	return b


func _card(def: Dictionary) -> Control:
	var card := UiKit.panel(UiKit.CARD, 14, 3)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := UiKit.hbox(10)
	card.add_child(row)
	var pic := PowerCard.new().setup(String(def["id"]))
	pic.custom_minimum_size = Vector2(96, 128)
	pic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(pic)
	var text := UiKit.vbox(0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head := UiKit.hbox(6)
	var title := UiKit.title(String(def["name"]), 17)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	text.add_child(head)
	var tier := UiKit.label("%s %s" % [Powerups.TIER_NAMES[int(def["tier"])], Powerups.CATS[def["cat"]]["name"]], 13, (Powerups.CATS[def["cat"]]["color"] as Color).lightened(0.3))
	text.add_child(tier)
	text.add_child(UiKit.body(String(def["desc"]), 15))
	row.add_child(text)
	return card
