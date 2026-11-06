class_name TopBar
extends Control
## The strip along the top of every menu: who you are, your league, coins, gems, and settings.

var _name_label: Label
var _level_badge: RoundBadge
var _trophy_pill: PanelContainer
var _coin_pill: PanelContainer
var _gem_pill: PanelContainer
var _status_dot: Panel
var _row: HBoxContainer
var _compact := false
var _narrow := false
var _built := false


func _ready() -> void:
	Profile.changed.connect(refresh)
	Net.status_changed.connect(func(_on: bool) -> void: refresh())
	_build()


func layout_for(compact: bool, narrow: bool) -> void:
	if compact == _compact and narrow == _narrow and _built:
		return
	_compact = compact
	_narrow = narrow
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	_built = true
	var height := 40.0 if _compact else 46.0
	_row = UiKit.hbox(4 if _narrow else 8)
	_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	_row.offset_left = 8
	_row.offset_right = -8
	_row.offset_top = 6
	_row.offset_bottom = -4
	add_child(_row)
	var me := Button.new()
	me.flat = true
	me.focus_mode = Control.FOCUS_NONE
	me.custom_minimum_size = Vector2(height + 4.0, height)
	me.size_flags_horizontal = Control.SIZE_EXPAND_FILL if not _narrow else Control.SIZE_SHRINK_BEGIN
	me.clip_contents = true
	me.pressed.connect(func() -> void:
		Audio.sfx("ui_click")
		UiRoot.instance.show_screen("profile", {}, true))
	_row.add_child(me)
	var inner := UiKit.hbox(8)
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	me.add_child(inner)
	_level_badge = RoundBadge.new().setup("1", height)
	inner.add_child(_level_badge)
	var col := UiKit.vbox(-2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label = UiKit.title("", 19 if not _compact else 16)
	_name_label.clip_text = true
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(_name_label)
	var status := UiKit.hbox(4)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_dot = Panel.new()
	_status_dot.custom_minimum_size = Vector2(10, 10)
	_status_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status.add_child(_status_dot)
	var state := UiKit.label("", 13, UiKit.MUTED)
	state.name = "State"
	status.add_child(state)
	col.add_child(status)
	col.visible = not _narrow
	inner.add_child(col)
	if _narrow:
		var gap := UiKit.spacer()
		_row.add_child(gap)
	var pill_h := height - (10.0 if _narrow else 4.0)
	_trophy_pill = UiKit.stat_pill("trophy", "0", UiKit.TROPHY, pill_h)
	_row.add_child(_trophy_pill)
	_coin_pill = UiKit.stat_pill("coin", "0", UiKit.COIN, pill_h)
	_row.add_child(_coin_pill)
	_gem_pill = UiKit.stat_pill("gem", "0", UiKit.GEM, pill_h)
	_row.add_child(_gem_pill)
	var gear := UiKit.button("", "ink", 16, "gear")
	gear.custom_minimum_size = Vector2(height - 2.0 if _narrow else height + 4.0, height)
	gear.pressed.connect(func() -> void: UiRoot.instance.show_screen("settings", {}, true))
	_row.add_child(gear)
	refresh()


func _set_value(pill: PanelContainer, text: String) -> void:
	var value := pill.find_child("Value", true, false) as Label
	if value:
		value.text = text


## 12,400 is 12.4K on a phone, where there isn't room for all of it.
func _amount(value: int) -> String:
	if not _narrow or value < 1000:
		return UiKit.format_number(value)
	if value >= 1000000:
		return "%.1fM" % (value / 1000000.0)
	if value >= 100000:
		return "%dK" % (value / 1000)
	return "%.1fK" % (value / 1000.0)


func refresh() -> void:
	if _name_label == null or not is_instance_valid(_name_label):
		return
	_name_label.text = Profile.player_name
	_level_badge.value = str(Profile.level)
	_level_badge.progress = float(Profile.xp) / maxf(Ranks.xp_for_level(Profile.level), 1.0)
	_set_value(_trophy_pill, _amount(Profile.trophies))
	_set_value(_coin_pill, _amount(Profile.coins))
	_set_value(_gem_pill, _amount(Profile.gems))
	var on := Net.online
	_status_dot.add_theme_stylebox_override("panel", UiKit.style(UiKit.MINT if on else UiKit.INK, 5, 2))
	var state := find_child("State", true, false) as Label
	if state:
		if on:
			state.text = "%d online" % Net.players_online if Net.players_online > 0 else "Online"
		else:
			state.text = "Offline"
