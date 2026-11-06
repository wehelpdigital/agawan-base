extends Control
## The main menu: your hero in 3D, the map you've picked, and the big buttons. Daily reward, quests,
## powerup list and how-to are one tap away.

const NEWS := [
	"NEW: Your friends are out playing. Tap your hero and they all cheer.",
	"NEW: Knights, ninjas, pharaohs and a slice of pizza. 105 heroes!",
	"NEW: Watch any map being played before you pick it. Tap Maps.",
	"Eighty silly faces. Your hero pulls them all as the game goes on.",
	"Pets! They follow you everywhere and do nothing useful.",
	"Fly your flag: every country's flag is free in the World shop.",
	"Try the Mega Wave, the Ninja Clones and the Chicken Curse!",
	"Fog, storms, sandstorms and more: check the sky before you run.",
	"Tokyo, Paris, Cairo, Rio: pick a map from anywhere in the world.",
	"Tap your hero to say hello.",
]
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
var _weather_label: Label
var _weather_icon: TextureRect
var _deal_pic: VBoxContainer
var _deal_name: Label
var _deal_price: Label
var _deals: Array[Dictionary] = []
var _deal_index := -1
var _news_label: Label
var _news_at := 0


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
	var behind := _backdrop()
	add_child(FlagBunting.new().setup(3, 18.0, 28.0))
	add_child(row)
	var left := UiKit.vbox(8)
	left.custom_minimum_size.x = 72.0 if root.compact else 224.0
	row.add_child(left)
	if not root.compact:
		left.add_child(_league_card())
	left.add_child(_side_buttons(not root.compact))
	if not root.compact and size.y > 520.0:
		left.add_child(_deal_card())
	var center := UiKit.vbox(0)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_stretch_ratio = 1.1
	row.add_child(center)
	if not root.compact:
		var logo := UiKit.image("res://assets/brand/logo.png", Vector2(0, minf(size.y * 0.3, 170.0)))
		logo.size_flags_horizontal = Control.SIZE_FILL
		center.add_child(logo)
	_avatar = AvatarView.new()
	_avatar.planet = true
	_avatar.backdrop = behind
	center.add_child(_avatar)
	if not root.compact:
		center.add_child(_news_strip())
	var column := UiKit.vbox(8)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(column)
	if not root.compact:
		column.add_child(_quest_card())
	column.add_child(_map_card(Vector2(0, 0)))
	column.add_child(_play_buttons())


func _build_portrait() -> void:
	var col := UiKit.vbox(6)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 10
	col.offset_right = -10
	col.offset_top = 4
	col.offset_bottom = -6
	var behind := _backdrop()
	add_child(FlagBunting.new().setup(2, 14.0, 24.0))
	add_child(col)
	var logo := UiKit.image("res://assets/brand/logo.png", Vector2(0, minf(size.y * 0.2, 150.0)))
	logo.size_flags_horizontal = Control.SIZE_FILL
	col.add_child(logo)
	var mid := UiKit.hbox(6)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(mid)
	_avatar = AvatarView.new()
	_avatar.planet = true
	_avatar.backdrop = behind
	mid.add_child(_avatar)
	mid.add_child(_side_buttons(false))
	if size.y > 640.0:
		col.add_child(_quest_card())
	col.add_child(_map_card(Vector2(0, 0)))
	col.add_child(_play_buttons())


## A layer behind everything, for the planet to run under the buttons and off the screen.
func _backdrop() -> Control:
	var behind := Control.new()
	behind.name = "Backdrop"
	behind.set_anchors_preset(Control.PRESET_FULL_RECT)
	behind.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(behind)
	return behind


## Your league, and how far to the next: a little trophy road.
func _league_card() -> Control:
	var league := Ranks.league_for(Profile.trophies)
	var card := _small_card(func() -> void: root.open_tab("ranks"))
	var col := UiKit.vbox(2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.get_child(0).add_child(col)
	var top := UiKit.hbox(6)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var flag_id := str(Profile.look.get("flag", ""))
	if flag_id != "":
		var flag := TextureRect.new()
		flag.texture = Flags.texture(flag_id)
		flag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flag.custom_minimum_size = Vector2(34, 24)
		flag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(flag)
	else:
		top.add_child(UiKit.icon("trophy", 24))
	var name_line := UiKit.label(String(league["name"]) + " League", 15, UiKit.WHITE, 4, true)
	name_line.clip_text = true
	name_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_line)
	col.add_child(top)
	var progress := Ranks.progress(Profile.trophies)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 12)
	bar.max_value = 1.0
	bar.value = progress["fraction"]
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", UiKit.style(UiKit.INK, 6))
	bar.add_theme_stylebox_override("fill", UiKit.style(league["color"], 6))
	col.add_child(bar)
	var next: Dictionary = progress["next"]
	col.add_child(UiKit.label("%d more to %s" % [int(progress["need"]), next["name"]] if not next.is_empty() else "Top of the world!", 13, UiKit.INK))
	return card


## A small plastic panel you can tap. Its content goes in its PanelContainer, child 0.
func _small_card(on_press: Callable, height := 64.0) -> Button:
	var card := Button.new()
	card.flat = true
	card.focus_mode = Control.FOCUS_ALL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.custom_minimum_size = Vector2(0, height)
	card.pressed.connect(func() -> void:
		Audio.sfx("ui_click")
		on_press.call())
	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := UiKit.card_style(UiKit.CARD, 14, 3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	box.add_theme_stylebox_override("panel", style)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	return card


## Something from today's half-price shelf, a different one every few seconds.
func _deal_card() -> Control:
	var card := _small_card(func() -> void: root.open_tab("shop"), 112.0)
	var row := UiKit.hbox(6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.get_child(0).add_child(row)
	_deal_pic = UiKit.vbox(0)
	_deal_pic.custom_minimum_size = Vector2(84, 84)
	_deal_pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_deal_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_deal_pic)
	var text := UiKit.vbox(0)
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_child(UiKit.label("HALF PRICE!", 13, UiKit.YELLOW, 4, true))
	_deal_name = UiKit.label("", 13, UiKit.WHITE, 3, true)
	_deal_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(_deal_name)
	_deal_price = UiKit.label("", 14, UiKit.YELLOW, 3, true)
	text.add_child(_deal_price)
	row.add_child(text)
	_deals = Cosmetics.todays_deals(6)
	_next_deal.call_deferred()
	var timer := Timer.new()
	timer.wait_time = 3.6
	timer.autostart = true
	timer.timeout.connect(_next_deal)
	add_child(timer)
	return card


func _next_deal() -> void:
	if _deals.is_empty() or not is_instance_valid(_deal_pic):
		return
	_deal_index = (_deal_index + 1) % _deals.size()
	var deal: Dictionary = _deals[_deal_index]
	var entry := Cosmetics.item(deal["slot"], deal["id"])
	for child in _deal_pic.get_children():
		child.queue_free()
	var pic := ItemIcon.new()
	pic.setup(deal["slot"], deal["id"])
	pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_deal_pic.add_child(pic)
	_deal_name.text = String(entry["name"])
	var price := Cosmetics.price(deal["slot"], deal["id"])
	var gems := int(price["gems"]) / 2
	_deal_price.text = "%d gems" % gems if gems > 0 else "%d coins" % (int(price["coins"]) / 2)


## Today's next quest, and how far along it is.
func _quest_card() -> Control:
	var card := _small_card(_quests_popup, 58.0)
	var col := UiKit.vbox(2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.get_child(0).add_child(col)
	var chosen := {}
	var progress := 0
	for id in Profile.quest_ids:
		if not Profile.quest_claimed.has(id):
			chosen = Profile.quest_def(id)
			progress = int(Profile.quest_progress.get(id, 0))
			break
	var line := UiKit.hbox(6)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(UiKit.icon("star", 22))
	var text := "All today's quests done!" if chosen.is_empty() else String(chosen["name"]) % int(chosen["goal"])
	var words := UiKit.label(text, 15, UiKit.WHITE, 4, true)
	words.clip_text = true
	words.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(words)
	if not chosen.is_empty():
		line.add_child(UiKit.label("%d/%d" % [mini(progress, int(chosen["goal"])), int(chosen["goal"])], 15, UiKit.YELLOW, 4, true))
	col.add_child(line)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 12)
	bar.max_value = 1.0
	bar.value = 1.0 if chosen.is_empty() else float(progress) / maxf(float(chosen["goal"]), 1.0)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", UiKit.style(UiKit.INK, 6))
	bar.add_theme_stylebox_override("fill", UiKit.style(UiKit.MINT, 6))
	col.add_child(bar)
	return card


## A strip of news under your hero, changing every few seconds.
func _news_strip() -> Control:
	var strip := PanelContainer.new()
	var box := UiKit.style(UiKit.INK, 14, 3, UiKit.WHITE)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 3
	box.content_margin_bottom = 4
	strip.add_theme_stylebox_override("panel", box)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_news_label = UiKit.label(NEWS[0], 15, UiKit.WHITE)
	_news_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_news_label.clip_text = true
	_news_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	strip.add_child(_news_label)
	var timer := Timer.new()
	timer.wait_time = 4.5
	timer.autostart = true
	timer.timeout.connect(func() -> void:
		_news_at = (_news_at + 1) % NEWS.size()
		_news_label.text = NEWS[_news_at]
		_news_label.modulate.a = 0.0
		create_tween().tween_property(_news_label, "modulate:a", 1.0, 0.3))
	add_child(timer)
	return strip


func _side_buttons(wide := true) -> Control:
	var col := UiKit.vbox(6)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var entries := [
		{"icon": "gift", "text": "Daily", "action": _daily_popup, "dot": Profile.daily_ready()},
		{"icon": "star", "text": "Quests", "action": _quests_popup, "dot": Profile.quest_ready_count() > 0},
		{"icon": "power", "text": "Cards", "action": func() -> void: root.show_screen("powers", {}, true), "dot": false},
		{"icon": "help", "text": "Rules", "action": func() -> void: root.show_screen("howto", {}, true), "dot": false},
	]
	var grid := GridContainer.new()
	grid.columns = 2 if wide else 1
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	col.add_child(grid)
	for entry: Dictionary in entries:
		var b := UiKit.button(entry["text"] if wide else "", "teal", 14, entry["icon"])
		b.custom_minimum_size = Vector2(66, 48) if not wide else Vector2(104, 46)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(entry["action"])
		if entry["dot"]:
			var dot := Panel.new()
			dot.add_theme_stylebox_override("panel", UiKit.style(UiKit.CORAL, 8, 3))
			dot.custom_minimum_size = Vector2(16, 16)
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dot.position = Vector2(-4, -4)
			b.add_child(dot)
		grid.add_child(b)
	return col


func _map_card(_min: Vector2) -> Control:
	var card := Button.new()
	card.flat = true
	card.focus_mode = Control.FOCUS_ALL
	card.custom_minimum_size = Vector2(0, 78 if root.compact else 112)
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
	var small := UiKit.label("MAP: tap to change", 14, UiKit.YELLOW, 3, true)
	text.add_child(small)
	_map_label = UiKit.title("", 17 if root.compact else 20)
	_map_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(_map_label)
	var sky := UiKit.hbox(4)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_weather_icon = UiKit.icon("w_sun", 22)
	sky.add_child(_weather_icon)
	_weather_label = UiKit.label("", 13, UiKit.WHITE, 3, true)
	sky.add_child(_weather_label)
	text.add_child(sky)
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
	if _weather_label:
		var chosen := Profile.favorite_weather
		_weather_label.text = String(Weather.def(chosen)["name"]) if chosen != "" else "Surprise weather"
		_weather_icon.texture = UiKit.icon_texture(String(Weather.def(chosen)["icon"]) if chosen != "" else "w_storm")


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
	_difficulty_btn.custom_minimum_size = Vector2(98, 56 if not root.compact else 50)
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
		var cell := UiKit.panel(UiKit.YELLOW if is_today else (UiKit.CARD if not done else UiKit.INK), 12, 3)
		cell.custom_minimum_size = Vector2(0, 72)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var inner := UiKit.vbox(0)
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		var day := UiKit.label("Day %d" % (i + 1), 13, UiKit.INK if is_today else UiKit.WHITE, 0 if is_today else 3, true)
		day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(day)
		var gems := int(reward.get("gems", 0))
		var coins := int(reward.get("coins", 0))
		if coins > 0:
			var amount := UiKit.hbox(3)
			amount.alignment = BoxContainer.ALIGNMENT_CENTER
			amount.add_child(UiKit.icon("coin", 18))
			amount.add_child(UiKit.label(str(coins), 16, UiKit.INK if is_today else UiKit.WHITE, 0, true))
			inner.add_child(amount)
		if gems > 0:
			var amount := UiKit.hbox(3)
			amount.alignment = BoxContainer.ALIGNMENT_CENTER
			amount.add_child(UiKit.icon("gem", 18))
			amount.add_child(UiKit.label(str(gems), 16, UiKit.INK if is_today else UiKit.WHITE, 0, true))
			inner.add_child(amount)
		if done:
			inner.add_child(UiKit.icon("check", 18))
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
		bar.add_theme_stylebox_override("background", UiKit.style(UiKit.INK, 7))
		bar.add_theme_stylebox_override("fill", UiKit.style(UiKit.MINT, 7))
		text.add_child(bar)
		row.add_child(text)
		if claimed:
			row.add_child(UiKit.icon("check", 32))
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
				reward.add_child(UiKit.icon("coin", 20))
				reward.add_child(UiKit.label(str(def["coins"]), 17, UiKit.WHITE, 0, true))
			else:
				reward.add_child(UiKit.icon("gem", 20))
				reward.add_child(UiKit.label(str(def["gems"]), 17, UiKit.WHITE, 0, true))
			row.add_child(reward)
		card.add_child(row)
		col.add_child(card)
	var close := UiKit.button("Close", "ink", 20)
	close.pressed.connect(func() -> void: root.close_popup(col))
	col.add_child(close)
