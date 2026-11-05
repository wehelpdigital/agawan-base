extends Control
## The main menu: your hero in 3D, the map you've picked, and the big buttons. Daily reward, quests,
## powerup list and how-to are one tap away.

const DIFFICULTIES := [
	{"name": "Easy", "skill": 0.28},
	{"name": "Normal", "skill": 0.52},
	{"name": "Hard", "skill": 0.75},
	{"name": "Insane", "skill": 0.98},
]

var root: UiRoot
var args: Dictionary
var screen_name: String
var _avatar: AvatarView
var _difficulty_btn: GameButton
var _map_rect: TextureRect
var _map_label: Label
var _online_btn: GameButton


func _ready() -> void:
	Audio.music("menu")
	var view_w := size.x
	if root.portrait:
		_build_portrait()
	else:
		_build_landscape()
	_refresh_map()
	_update_look()
	Profile.changed.connect(_update_look)
	# A new player's first tap should start a match, not open a pop-up.
	if view_w > 0.0 and Profile.daily_ready() and Profile.matches_played > 0 and not args.get("skip_daily", false):
		_daily_popup.call_deferred()


func _update_look() -> void:
	if is_instance_valid(_avatar):
		_avatar.set_look(Profile.look)


func _build_landscape() -> void:
	var row := UiKit.hbox(12)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12
	row.offset_right = -12
	row.offset_top = 6
	row.offset_bottom = -6
	add_child(row)
	row.add_child(_side_buttons())
	var center := UiKit.vbox(0)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_stretch_ratio = 1.15
	row.add_child(center)
	if not root.compact:
		var logo := UiKit.image("res://assets/brand/logo.png", Vector2(0, minf(size.y * 0.3, 160.0)))
		logo.size_flags_horizontal = Control.SIZE_FILL
		center.add_child(logo)
	_avatar = AvatarView.new()
	center.add_child(_avatar)
	var column := UiKit.vbox(10)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(column)
	column.add_child(_map_card(Vector2(0, 0)))
	column.add_child(_play_buttons())


func _build_portrait() -> void:
	var col := UiKit.vbox(8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 10
	col.offset_right = -10
	col.offset_top = 4
	col.offset_bottom = -6
	add_child(col)
	var logo := UiKit.image("res://assets/brand/logo.png", Vector2(0, minf(size.y * 0.2, 150.0)))
	logo.size_flags_horizontal = Control.SIZE_FILL
	col.add_child(logo)
	var mid := UiKit.hbox(6)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(mid)
	_avatar = AvatarView.new()
	mid.add_child(_avatar)
	mid.add_child(_side_buttons())
	col.add_child(_map_card(Vector2(0, 0)))
	col.add_child(_play_buttons())


func _side_buttons() -> Control:
	var col := UiKit.vbox(8)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var entries := [
		{"icon": "gift", "text": "Daily", "action": _daily_popup, "dot": Profile.daily_ready()},
		{"icon": "star", "text": "Quests", "action": _quests_popup, "dot": Profile.quest_ready_count() > 0},
		{"icon": "power", "text": "Powers", "action": func() -> void: root.show_screen("powers", {}, true), "dot": false},
		{"icon": "help", "text": "Rules", "action": func() -> void: root.show_screen("howto", {}, true), "dot": false},
	]
	var small: bool = root.compact
	for entry: Dictionary in entries:
		var b := UiKit.button(entry["text"] if not (small or root.phone_narrow) else "", "purple", 16, entry["icon"])
		b.custom_minimum_size = Vector2(66, 48) if small or root.phone_narrow else Vector2(132, 50)
		b.pressed.connect(entry["action"])
		if entry["dot"]:
			var dot := Panel.new()
			dot.add_theme_stylebox_override("panel", UiKit.style(UiKit.CORAL, 8, 3))
			dot.custom_minimum_size = Vector2(16, 16)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dot.position = Vector2(-4, -4)
			b.add_child(dot)
		col.add_child(b)
	return col


func _map_card(_min: Vector2) -> Control:
	var card := Button.new()
	card.flat = true
	card.focus_mode = Control.FOCUS_ALL
	card.custom_minimum_size = Vector2(0, 74 if root.compact else 118)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.pressed.connect(func() -> void:
		Audio.sfx("ui_click")
		root.show_screen("maps", {}, true))
	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_theme_stylebox_override("panel", UiKit.card_style(UiKit.CARD, 18, 4))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	var row := UiKit.hbox(10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	_map_rect = TextureRect.new()
	_map_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_map_rect.custom_minimum_size = Vector2(92 if root.compact else 150, 0)
	_map_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_rect.clip_contents = true
	row.add_child(_map_rect)
	var text := UiKit.vbox(0)
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var small := UiKit.label("MAP: tap to change", 14, UiKit.YELLOW, 0, true)
	text.add_child(small)
	_map_label = UiKit.title("", 19 if root.compact else 22)
	_map_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(_map_label)
	row.add_child(text)
	return card


func _refresh_map() -> void:
	var id := _current_map()
	var map := Maps.by_id(id)
	if _map_label:
		_map_label.text = String(map.get("name", "Random Map")) if Profile.favorite_map != "" else "Random Map"
	if _map_rect:
		var path := Maps.thumb_path(id)
		_map_rect.texture = load(path) if ResourceLoader.exists(path) else null


func _current_map() -> String:
	if Profile.favorite_map != "" and not Maps.by_id(Profile.favorite_map).is_empty():
		return Profile.favorite_map
	return String(Maps.all()[0]["id"])


func _play_buttons() -> Control:
	var col := UiKit.vbox(8)
	_online_btn = UiKit.button("PLAY ONLINE", "yellow", 30 if not root.compact else 24, "swords")
	_online_btn.custom_minimum_size.y = 70 if not root.compact else 58
	_online_btn.pressed.connect(func() -> void: root.main.start_online())
	col.add_child(_online_btn)
	var row := UiKit.hbox(6)
	var text_size := 20 if not root.compact and not root.phone_narrow else 17
	var friends := UiKit.button("FRIENDS", "pink", text_size, "people")
	friends.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	friends.custom_minimum_size.y = 56 if not root.compact else 50
	friends.pressed.connect(func() -> void: root.show_screen("room", {}, true))
	row.add_child(friends)
	var ai := UiKit.button("VS AI", "green", text_size, "robot")
	ai.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ai.custom_minimum_size.y = 56 if not root.compact else 50
	ai.pressed.connect(func() -> void: root.main.start_practice(DIFFICULTIES[Profile.difficulty]["skill"]))
	row.add_child(ai)
	_difficulty_btn = UiKit.button(DIFFICULTIES[clampi(Profile.difficulty, 0, 3)]["name"], "blue", 15)
	_difficulty_btn.custom_minimum_size = Vector2(78, 56 if not root.compact else 50)
	_difficulty_btn.pressed.connect(_next_difficulty)
	row.add_child(_difficulty_btn)
	col.add_child(row)
	return col


func _next_difficulty() -> void:
	Profile.difficulty = (Profile.difficulty + 1) % DIFFICULTIES.size()
	_difficulty_btn.set_text(DIFFICULTIES[Profile.difficulty]["name"])
	Profile.save()


func _daily_popup() -> void:
	var col := root.popup("Daily Reward")
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var today := int(Profile.daily_next()["day"])
	var ready := Profile.daily_ready()
	for i in Profile.DAILY_REWARDS.size():
		var reward: Dictionary = Profile.DAILY_REWARDS[i]
		var done := i < today or (i == today and not ready)
		var is_today := i == today and ready
		var cell := UiKit.panel(UiKit.YELLOW.darkened(0.1) if is_today else (UiKit.CARD if not done else Color("2e2478")), 12, 3)
		cell.custom_minimum_size = Vector2(0, 72)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var inner := UiKit.vbox(0)
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		var day := UiKit.label("Day %d" % (i + 1), 13, UiKit.INK if is_today else UiKit.MUTED, 0, true)
		day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(day)
		var gems := int(reward.get("gems", 0))
		var coins := int(reward.get("coins", 0))
		if coins > 0:
			var amount := UiKit.hbox(3)
			amount.alignment = BoxContainer.ALIGNMENT_CENTER
			amount.add_child(UiKit.icon("coin", 18, UiKit.COIN if not is_today else UiKit.INK))
			amount.add_child(UiKit.label(str(coins), 16, UiKit.INK if is_today else UiKit.WHITE, 0, true))
			inner.add_child(amount)
		if gems > 0:
			var amount := UiKit.hbox(3)
			amount.alignment = BoxContainer.ALIGNMENT_CENTER
			amount.add_child(UiKit.icon("gem", 18, UiKit.GEM if not is_today else UiKit.INK))
			amount.add_child(UiKit.label(str(gems), 16, UiKit.INK if is_today else UiKit.WHITE, 0, true))
			inner.add_child(amount)
		if done:
			inner.modulate.a = 0.5
		cell.add_child(inner)
		grid.add_child(cell)
	col.add_child(grid)
	var row := UiKit.hbox(8)
	var close := UiKit.button("Later" if ready else "Close", "ink", 20)
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close.pressed.connect(func() -> void: root.close_popup(col))
	row.add_child(close)
	if ready:
		var claim := UiKit.button("CLAIM!", "yellow", 22)
		claim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		claim.pressed.connect(func() -> void:
			var got := Profile.claim_daily()
			Audio.sfx("daily_reward")
			root.close_popup(col)
			root.toast(_reward_text(got), UiKit.YELLOW)
			root.show_screen("home", {"skip_daily": true}))
		row.add_child(claim)
	col.add_child(row)


func _reward_text(reward: Dictionary) -> String:
	var parts: Array[String] = []
	if int(reward.get("coins", 0)) > 0:
		parts.append("+%d coins" % int(reward["coins"]))
	if int(reward.get("gems", 0)) > 0:
		parts.append("+%d gems" % int(reward["gems"]))
	return ", ".join(parts)


func _quests_popup() -> void:
	var col := root.popup("Today's Quests")
	for id in Profile.quest_ids:
		var def := Profile.quest_def(id)
		if def.is_empty():
			continue
		var goal := int(def["goal"])
		var progress := int(Profile.quest_progress.get(id, 0))
		var claimed := Profile.quest_claimed.has(id)
		var card := UiKit.panel(UiKit.CARD, 14, 3)
		var row := UiKit.hbox(10)
		var text := UiKit.vbox(2)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_child(UiKit.body(String(def["name"]) % goal, 17))
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 14)
		bar.max_value = goal
		bar.value = progress
		bar.add_theme_stylebox_override("background", UiKit.style(Color(UiKit.INK, 0.8), 7))
		bar.add_theme_stylebox_override("fill", UiKit.style(UiKit.MINT, 7))
		text.add_child(bar)
		row.add_child(text)
		if claimed:
			row.add_child(UiKit.icon("check", 32, UiKit.MINT))
		elif progress >= goal:
			var claim := UiKit.button("Claim", "yellow", 18)
			claim.pressed.connect(func() -> void:
				Profile.claim_quest(id)
				Audio.sfx("achievement")
				root.close_popup(col)
				_quests_popup())
			row.add_child(claim)
		else:
			var reward := UiKit.hbox(3)
			if int(def.get("coins", 0)) > 0:
				reward.add_child(UiKit.icon("coin", 20, UiKit.COIN))
				reward.add_child(UiKit.label(str(def["coins"]), 17, UiKit.WHITE, 0, true))
			else:
				reward.add_child(UiKit.icon("gem", 20, UiKit.GEM))
				reward.add_child(UiKit.label(str(def["gems"]), 17, UiKit.WHITE, 0, true))
			row.add_child(reward)
		card.add_child(row)
		col.add_child(card)
	var close := UiKit.button("Close", "ink", 20)
	close.pressed.connect(func() -> void: root.close_popup(col))
	col.add_child(close)
