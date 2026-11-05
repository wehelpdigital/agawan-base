extends Control
## Guilds: find one or start one, then see your members, your guild's trophies and its private chat.

const CREATE_COST := 500
const BADGES := ["flag", "crown", "skull", "shield", "star", "swords", "trophy", "gem"]
const BADGE_COLORS := [Color("ffb21f"), Color("23a7ff"), Color("ff4f6b"), Color("35d07f"), Color("b768ff"), Color("ff6fb5"), Color("19d3e6"), Color("c5d0e6")]

var root: UiRoot
var args: Dictionary
var screen_name: String
var _body: VBoxContainer
var _request := 0


func _ready() -> void:
	_body = UiKit.vbox(8)
	_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_body.offset_left = 10
	_body.offset_right = -10
	_body.offset_top = 4
	_body.offset_bottom = -6
	add_child(_body)
	Net.status_changed.connect(_on_status)
	_refresh()


func _on_status(_on: bool) -> void:
	if is_instance_valid(_body):
		_refresh()


func _clear() -> void:
	_request += 1
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()


func _refresh() -> void:
	_clear()
	if not Net.online:
		_message("Guilds need the game server. You're offline right now.")
		return
	if Profile.guild_id != 0:
		_show_my_guild()
	else:
		_show_browser("")


func _message(text: String) -> void:
	var line := UiKit.body(text, 18)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.add_theme_color_override("font_outline_color", UiKit.INK)
	line.add_theme_constant_override("outline_size", 5)
	var box := UiKit.margin(20, 50, 20, 20)
	box.add_child(line)
	_body.add_child(box)


# --- Finding a guild ------------------------------------------------------------------------------

func _show_browser(search: String) -> void:
	_clear()
	var head := UiKit.hbox(8)
	var field := LineEdit.new()
	field.placeholder_text = "Search guilds"
	field.text = search
	field.max_length = 24
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.custom_minimum_size.y = 50
	field.text_submitted.connect(func(text: String) -> void: _show_browser(text))
	head.add_child(field)
	var find := UiKit.button("", "blue", 18, "search")
	find.custom_minimum_size = Vector2(56, 50)
	find.pressed.connect(func() -> void: _show_browser(field.text))
	head.add_child(find)
	var create := UiKit.button("Create", "yellow", 18, "plus")
	create.custom_minimum_size.y = 50
	create.pressed.connect(_create_popup)
	head.add_child(create)
	_body.add_child(head)
	var scroll := UiKit.scroller()
	_body.add_child(scroll)
	var list := UiKit.vbox(6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var request := _request
	var result := await Net.guild_list(search)
	if request != _request or not is_instance_valid(list):
		return
	var rows: Array = (result["data"] as Dictionary).get("guilds", []) if result["ok"] else []
	if rows.is_empty():
		var empty := UiKit.body("No guilds found. Start your own!" if result["ok"] else "Couldn't load guilds. Try again soon.", 18)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(empty)
		return
	for row: Variant in rows:
		if row is Dictionary:
			list.add_child(_guild_row(row))


func _guild_row(row: Dictionary) -> Control:
	var card := UiKit.panel(UiKit.CARD, 14, 3)
	var box := UiKit.hbox(10)
	card.add_child(box)
	box.add_child(_badge(int(row.get("badge", 0)), 48))
	var text := UiKit.vbox(0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_line := UiKit.title("%s [%s]" % [str(row.get("name", "?")), str(row.get("tag", ""))], 17)
	name_line.clip_text = true
	name_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text.add_child(name_line)
	text.add_child(UiKit.label("%d/%d members · %s trophies" % [int(row.get("members", 0)), int(row.get("max", 30)), UiKit.format_number(int(row.get("trophies", 0)))], 14, UiKit.MUTED))
	var about := str(row.get("about", ""))
	if about != "":
		var about_line := UiKit.label(about, 14, UiKit.WHITE)
		about_line.clip_text = true
		about_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		text.add_child(about_line)
	box.add_child(text)
	var join := UiKit.button("Join", "green", 18)
	join.disabled = int(row.get("members", 0)) >= int(row.get("max", 30))
	var id := int(row.get("id", 0))
	join.pressed.connect(func() -> void: _join(id))
	box.add_child(join)
	return card


func _badge(index: int, side: float) -> Control:
	var i := absi(index) % BADGES.size()
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", UiKit.style(BADGE_COLORS[i], int(side * 0.3), 3))
	plate.custom_minimum_size = Vector2(side, side)
	plate.add_child(UiKit.icon(BADGES[i], side * 0.68))
	return plate


func _join(id: int) -> void:
	var result := await Net.guild_join(id)
	if result["ok"]:
		Audio.sfx("achievement")
		root.toast("Welcome to %s!" % Profile.guild_name, UiKit.MINT)
		_refresh()
	else:
		Audio.sfx("ui_error")
		root.toast(str((result["data"] as Dictionary).get("error", "Couldn't join.")), UiKit.CORAL)


func _create_popup() -> void:
	var col := root.popup("Start a Guild")
	var name_field := LineEdit.new()
	name_field.placeholder_text = "Guild name"
	name_field.max_length = 20
	name_field.custom_minimum_size.y = 50
	col.add_child(name_field)
	var tag_field := LineEdit.new()
	tag_field.placeholder_text = "Tag (2-4 letters)"
	tag_field.max_length = 4
	tag_field.custom_minimum_size.y = 50
	col.add_child(tag_field)
	var about_field := LineEdit.new()
	about_field.placeholder_text = "What's your guild about?"
	about_field.max_length = 80
	about_field.custom_minimum_size.y = 50
	col.add_child(about_field)
	var badge_row := UiKit.hbox(4)
	badge_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var chosen := [0]
	var plates: Array[Button] = []
	for i in BADGES.size():
		var pick := Button.new()
		pick.flat = true
		pick.focus_mode = Control.FOCUS_NONE
		pick.custom_minimum_size = Vector2(42, 42)
		var plate := _badge(i, 40)
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pick.add_child(plate)
		pick.pressed.connect(func() -> void:
			chosen[0] = i
			for j in plates.size():
				plates[j].modulate.a = 1.0 if j == i else 0.45)
		pick.modulate.a = 1.0 if i == 0 else 0.45
		plates.append(pick)
		badge_row.add_child(pick)
	col.add_child(badge_row)
	var cost := UiKit.hbox(4)
	cost.alignment = BoxContainer.ALIGNMENT_CENTER
	cost.add_child(UiKit.label("Costs", 17))
	cost.add_child(UiKit.icon("coin", 20))
	cost.add_child(UiKit.label(str(CREATE_COST), 18, UiKit.WHITE, 3, true))
	col.add_child(cost)
	var row := UiKit.hbox(8)
	var cancel := UiKit.button("Cancel", "ink", 19)
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(func() -> void: root.close_popup(col))
	row.add_child(cancel)
	var make := UiKit.button("Create", "yellow", 19)
	make.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	make.disabled = Profile.coins < CREATE_COST
	make.pressed.connect(func() -> void:
		var result := await Net.guild_create(name_field.text.strip_edges(), tag_field.text.strip_edges().to_upper(), about_field.text.strip_edges(), chosen[0])
		if result["ok"]:
			Profile.coins -= CREATE_COST
			Profile.notify_changed()
			Audio.sfx("achievement")
			root.close_popup(col)
			root.toast("%s is born!" % Profile.guild_name, UiKit.MINT)
			_refresh()
		else:
			Audio.sfx("ui_error")
			root.toast(str((result["data"] as Dictionary).get("error", "Couldn't create it.")), UiKit.CORAL))
	row.add_child(make)
	col.add_child(row)


# --- My guild -------------------------------------------------------------------------------------

func _show_my_guild() -> void:
	var loading := UiKit.body("Loading your guild...", 18)
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_child(loading)
	var request := _request
	var result := await Net.guild_get(Profile.guild_id)
	if request != _request or not is_instance_valid(_body):
		return
	_clear()
	if not result["ok"]:
		Profile.guild_id = 0
		Profile.guild_name = ""
		_show_browser("")
		return
	var guild: Dictionary = (result["data"] as Dictionary).get("guild", {})
	var members: Array = (result["data"] as Dictionary).get("members", [])
	_body.add_child(_guild_header(guild, members.size()))
	var split: BoxContainer = VBoxContainer.new() if root.portrait else HBoxContainer.new()
	split.add_theme_constant_override("separation", 8)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(split)
	var scroll := UiKit.scroller()
	scroll.size_flags_stretch_ratio = 0.8
	split.add_child(scroll)
	var list := UiKit.vbox(5)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var leader_id := int(guild.get("leader_id", 0))
	var me_id := int((result["data"] as Dictionary).get("me_id", 0))
	for i in members.size():
		list.add_child(_member_row(i + 1, members[i], leader_id, me_id))
	split.add_child(ChatPanel.new("guild"))


func _guild_header(guild: Dictionary, count: int) -> Control:
	var card := UiKit.panel(UiKit.CARD_LIGHT, 18, 4)
	var row := UiKit.hbox(10)
	card.add_child(row)
	row.add_child(_badge(int(guild.get("badge", 0)), 54))
	var text := UiKit.vbox(0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_line := UiKit.title("%s [%s]" % [str(guild.get("name", "")), str(guild.get("tag", ""))], 21)
	name_line.clip_text = true
	name_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text.add_child(name_line)
	text.add_child(UiKit.label("%d members · %s trophies" % [count, UiKit.format_number(int(guild.get("trophies", 0)))], 15, UiKit.MUTED))
	row.add_child(text)
	var leave := UiKit.button("Leave", "coral", 16)
	leave.pressed.connect(func() -> void:
		root.confirm("Leave Guild?", "You can join another guild any time.", "Leave", func() -> void:
			await Net.guild_leave()
			root.toast("You left the guild.")
			_refresh(), "Stay", "coral"))
	row.add_child(leave)
	return card


func _member_row(rank: int, member: Dictionary, leader_id: int, me_id: int) -> Control:
	var card := UiKit.panel(UiKit.CARD, 12, 3)
	var box := UiKit.hbox(8)
	card.add_child(box)
	var number := UiKit.title(str(rank), 16, UiKit.MUTED)
	number.custom_minimum_size.x = 26
	box.add_child(number)
	var id := int(member.get("id", 0))
	if id == leader_id:
		box.add_child(UiKit.icon("crown", 22))
	var name_line := UiKit.label(str(member.get("name", "?")), 16, UiKit.YELLOW if id == me_id else UiKit.WHITE, 3, true)
	name_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_line.clip_text = true
	name_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(name_line)
	box.add_child(UiKit.icon("trophy", 18))
	box.add_child(UiKit.label(UiKit.format_number(int(member.get("trophies", 0))), 15, UiKit.WHITE, 3, true))
	if me_id == leader_id and id != me_id:
		var kick := UiKit.button("", "coral", 12, "close")
		kick.custom_minimum_size = Vector2(38, 36)
		kick.pressed.connect(func() -> void:
			root.confirm("Remove Member?", "Remove %s from the guild?" % str(member.get("name", "")), "Remove", func() -> void:
				await Net.guild_kick(id)
				_refresh(), "Keep", "coral"))
		box.add_child(kick)
	return card
