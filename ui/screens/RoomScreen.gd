extends Control
## Friend Rooms: play with friends, against friends, or any mix, with AI in every empty seat. Make a room,
## share its code, and everyone picks a team. Private matches earn coins but no trophies.

const AI_LEVELS := [
	{"name": "Easy AI", "skill": 0.28},
	{"name": "Normal AI", "skill": 0.52},
	{"name": "Hard AI", "skill": 0.75},
	{"name": "Insane AI", "skill": 0.98},
]

var root: UiRoot
var args: Dictionary
var screen_name: String
var _body: VBoxContainer
var _level := 1


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
	back.pressed.connect(func() -> void:
		Net.room_leave()
		root.go_back())
	head.add_child(back)
	var heading := UiKit.title("FRIEND ROOM", 26 if not root.compact else 22)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(heading)
	outer.add_child(head)
	var scroll := UiKit.scroller()
	outer.add_child(scroll)
	_body = UiKit.vbox(10)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	Net.room_updated.connect(_on_room)
	Net.room_error.connect(_on_error)
	Net.status_changed.connect(func(_on: bool) -> void: _refresh())
	var code: String = args.get("join", "")
	if code != "" and Net.online:
		Net.room_join(code)
	_refresh()


func _refresh() -> void:
	if not is_instance_valid(_body):
		return
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	if not Net.online:
		_note("Friend Rooms need the game server. You're offline right now.\nYou can still play against the AI from the main menu.")
	elif Net.room.is_empty():
		_build_start()
	else:
		_build_room(Net.room)


func _note(text: String) -> void:
	var line := UiKit.body(text, 18)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.add_theme_color_override("font_outline_color", UiKit.INK)
	line.add_theme_constant_override("outline_size", 5)
	var box := UiKit.margin(20, 50, 20, 20)
	box.add_child(line)
	_body.add_child(box)


func _on_room(_room: Dictionary) -> void:
	_refresh()


func _on_error(message: String) -> void:
	Audio.sfx("ui_error")
	root.toast(message, UiKit.CORAL)
	_refresh()


# --- No room yet ----------------------------------------------------------------------------------

func _build_start() -> void:
	var make := UiKit.panel(UiKit.CARD, 18, 4)
	var col := UiKit.vbox(8)
	make.add_child(col)
	col.add_child(UiKit.title("Make a room", 22, UiKit.YELLOW))
	col.add_child(UiKit.body("Get a code, share it, and pick teams. Team up against the AI, or take each other on with AI teammates.", 16))
	var create := UiKit.button("CREATE ROOM", "yellow", 22, "plus")
	create.custom_minimum_size.y = 60
	create.pressed.connect(func() -> void: Net.room_create(Profile.favorite_map, AI_LEVELS[_level]["skill"]))
	col.add_child(create)
	_body.add_child(make)
	var join := UiKit.panel(UiKit.CARD, 18, 4)
	var col2 := UiKit.vbox(8)
	join.add_child(col2)
	col2.add_child(UiKit.title("Join a friend", 22, UiKit.YELLOW))
	var row := UiKit.hbox(8)
	var field := LineEdit.new()
	field.placeholder_text = "Room code"
	field.max_length = 6
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.custom_minimum_size.y = 54
	field.text_submitted.connect(func(text: String) -> void: Net.room_join(text.strip_edges().to_upper()))
	row.add_child(field)
	var go := UiKit.button("JOIN", "green", 20)
	go.custom_minimum_size = Vector2(100, 54)
	go.pressed.connect(func() -> void: Net.room_join(field.text.strip_edges().to_upper()))
	row.add_child(go)
	col2.add_child(row)
	_body.add_child(join)


# --- In a room ------------------------------------------------------------------------------------

func _build_room(room: Dictionary) -> void:
	var seats: Array = room.get("seats", [])
	var me := int(room.get("you", -1))
	var is_host := me == int(room.get("host", -2))
	var code: String = str(room.get("code", ""))
	var top := UiKit.panel(UiKit.CARD_LIGHT, 18, 4)
	var top_row := UiKit.hbox(10)
	top.add_child(top_row)
	var code_col := UiKit.vbox(0)
	code_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_col.add_child(UiKit.label("ROOM CODE", 14, UiKit.MUTED, 3, true))
	code_col.add_child(UiKit.title(code, 38, UiKit.YELLOW))
	top_row.add_child(code_col)
	var share := UiKit.button("Copy", "blue", 17)
	share.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(_share_text(code))
		root.toast("Invite copied. Send it to a friend!", UiKit.MINT))
	top_row.add_child(share)
	var post := UiKit.button("To Chat", "purple", 17)
	post.pressed.connect(func() -> void:
		Net.send_chat("guild" if Profile.guild_id != 0 else "global", "Join my room! Code: %s" % code)
		root.toast("Posted in %s chat." % ("guild" if Profile.guild_id != 0 else "global"), UiKit.MINT))
	top_row.add_child(post)
	_body.add_child(top)
	var teams: BoxContainer = VBoxContainer.new() if root.phone_narrow else HBoxContainer.new()
	teams.add_theme_constant_override("separation", 8)
	_body.add_child(teams)
	teams.add_child(_team_column(0, seats, me))
	teams.add_child(_team_column(1, seats, me))
	if is_host:
		_body.add_child(_host_controls(room))
	var row := UiKit.hbox(8)
	var leave := UiKit.button("Leave", "ink", 20)
	leave.custom_minimum_size.y = 60
	leave.pressed.connect(func() -> void: Net.room_leave())
	row.add_child(leave)
	if is_host:
		var start := UiKit.button("START MATCH", "yellow", 24, "swords")
		start.custom_minimum_size.y = 60
		start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		start.pressed.connect(func() -> void: Net.room_start())
		row.add_child(start)
	else:
		var wait := UiKit.body("Waiting for the host to start...", 17)
		wait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wait.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		wait.add_theme_color_override("font_outline_color", UiKit.INK)
		wait.add_theme_constant_override("outline_size", 5)
		row.add_child(wait)
	_body.add_child(row)


func _share_text(code: String) -> String:
	if OS.has_feature("web"):
		var origin: Variant = JavaScriptBridge.eval("window.location.origin", true)
		if origin is String:
			return "Join my Capture the Base room: %s/?room=%s" % [origin, code]
	return "Join my Capture the Base room! Code: %s" % code


func _team_column(team: int, seats: Array, me: int) -> Control:
	var color := ArenaBuilder.team_color(team)
	var card := UiKit.panel(UiKit.CARD, 16, 4)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := UiKit.vbox(5)
	card.add_child(col)
	var head := UiKit.hbox(6)
	var title := UiKit.title("Team %s" % ArenaBuilder.TEAM_NAMES[team], 19, color.lightened(0.2))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var my_team := -1
	var count := 0
	for seat: Variant in seats:
		if int(seat["team"]) == team:
			count += 1
		if int(seat["id"]) == me:
			my_team = int(seat["team"])
	if my_team != team and count < Sim.TEAM_SIZE:
		var switch_btn := UiKit.button("Join", "green", 15)
		switch_btn.custom_minimum_size.y = 40
		switch_btn.pressed.connect(func() -> void: Net.room_team(team))
		head.add_child(switch_btn)
	col.add_child(head)
	var shown := 0
	for seat: Variant in seats:
		if int(seat["team"]) != team:
			continue
		shown += 1
		var row := UiKit.hbox(6)
		row.add_child(UiKit.icon("avatar", 20))
		var line := UiKit.label(str(seat["name"]), 16, UiKit.YELLOW if int(seat["id"]) == me else UiKit.WHITE, 3, true)
		line.clip_text = true
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(line)
		col.add_child(row)
	for _i in Sim.TEAM_SIZE - shown:
		var row := UiKit.hbox(6)
		row.add_child(UiKit.icon("robot", 20))
		row.add_child(UiKit.label("AI", 15, UiKit.MUTED))
		col.add_child(row)
	return card


func _host_controls(room: Dictionary) -> Control:
	var card := UiKit.panel(UiKit.CARD, 16, 4)
	var row := UiKit.hbox(8)
	card.add_child(row)
	var map_id := str(room.get("map", ""))
	var map_name := String(Maps.by_id(map_id).get("name", "Random Map"))
	var map_btn := UiKit.button(map_name, "purple", 15, "map")
	map_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_btn.pressed.connect(func() -> void:
		root.show_screen("maps", {"room": true}, true))
	row.add_child(map_btn)
	var skill := float(room.get("skill", 0.52))
	var best := 0
	for i in AI_LEVELS.size():
		if absf(float(AI_LEVELS[i]["skill"]) - skill) < absf(float(AI_LEVELS[best]["skill"]) - skill):
			best = i
	_level = best
	var ai := UiKit.button(AI_LEVELS[best]["name"], "blue", 15, "robot")
	ai.pressed.connect(func() -> void:
		_level = (_level + 1) % AI_LEVELS.size()
		Net.room_config(str(room.get("map", "")), AI_LEVELS[_level]["skill"]))
	row.add_child(ai)
	return card
