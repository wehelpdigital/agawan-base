extends Control
## Rankings: your league, the leagues above it with their rewards, the world's top players and top guilds.

var root: UiRoot
var args: Dictionary
var screen_name: String
var _tab := "leagues"
var _body: VBoxContainer
var _tabs_row: HBoxContainer
var _request_id := 0


func _ready() -> void:
	var col := UiKit.vbox(8)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 10
	col.offset_right = -10
	col.offset_top = 4
	col.offset_bottom = -6
	add_child(col)
	col.add_child(_my_card())
	_tabs_row = UiKit.hbox(6)
	col.add_child(_tabs_row)
	var scroll := UiKit.scroller()
	col.add_child(scroll)
	_body = UiKit.vbox(6)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	_build_tabs()
	_refill()


func _my_card() -> Control:
	var card := UiKit.panel(UiKit.CARD, 18, 4)
	var row := UiKit.hbox(12)
	card.add_child(row)
	var league := Ranks.league_for(Profile.trophies)
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UiKit.style(league["color"], 18, 4))
	badge.custom_minimum_size = Vector2(56, 56)
	var icon := UiKit.icon("trophy", 40)
	badge.add_child(icon)
	row.add_child(badge)
	var text := UiKit.vbox(2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(UiKit.title("%s League" % league["name"], 22))
	var progress := Ranks.progress(Profile.trophies)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 16)
	bar.max_value = 1.0
	bar.value = progress["fraction"]
	bar.add_theme_stylebox_override("background", UiKit.style(UiKit.INK, 8))
	bar.add_theme_stylebox_override("fill", UiKit.style(league["color"], 8))
	text.add_child(bar)
	var next: Dictionary = progress["next"]
	var line := "%s trophies" % UiKit.format_number(Profile.trophies)
	if not next.is_empty():
		line += ", %d more to %s" % [int(progress["need"]), next["name"]]
	text.add_child(UiKit.label(line, 15, UiKit.MUTED))
	row.add_child(text)
	return card


func _build_tabs() -> void:
	for child in _tabs_row.get_children():
		child.queue_free()
	for entry: Array in [["leagues", "Leagues"], ["players", "Top Players"], ["guilds", "Top Guilds"]]:
		var id: String = entry[0]
		var b := UiKit.button(entry[1], "yellow" if id == _tab else "teal", 16)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 48
		b.pressed.connect(func() -> void:
			_tab = id
			_build_tabs()
			_refill())
		_tabs_row.add_child(b)


func _refill() -> void:
	_request_id += 1
	for child in _body.get_children():
		child.queue_free()
	match _tab:
		"leagues":
			_fill_leagues()
		"players":
			_fill_board("players")
		"guilds":
			_fill_board("guilds")


func _fill_leagues() -> void:
	var mine := Ranks.league_index(Profile.trophies)
	for i in range(Ranks.LEAGUES.size() - 1, -1, -1):
		var league: Dictionary = Ranks.LEAGUES[i]
		var reached: bool = Profile.best_trophies >= int(league["min"])
		var card := UiKit.panel(Color("1fa35c") if i == mine else UiKit.CARD, 14, 3)
		var row := UiKit.hbox(10)
		card.add_child(row)
		var dot := RoundBadge.new().setup("", 40.0, league["color"] if reached else UiKit.INK)
		var cup := UiKit.icon("trophy", 26)
		cup.position = Vector2(7, 7)
		dot.add_child(cup)
		row.add_child(dot)
		var text := UiKit.vbox(0)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_child(UiKit.title(String(league["name"]), 18))
		text.add_child(UiKit.label("%s trophies" % UiKit.format_number(int(league["min"])), 14, UiKit.MUTED))
		row.add_child(text)
		var gems := int(league["reward_gems"])
		if gems > 0:
			if Profile.claimed_leagues.has(league["id"]):
				row.add_child(UiKit.icon("check", 28))
			elif reached:
				var claim := UiKit.button("+%d" % gems, "yellow", 16, "gem")
				var id: String = league["id"]
				claim.pressed.connect(func() -> void:
					var got := Profile.claim_league(id)
					if got > 0:
						Audio.sfx("rank_up")
						root.toast("+%d gems!" % got, UiKit.GEM)
					_refill())
				row.add_child(claim)
			else:
				var reward := UiKit.hbox(3)
				reward.add_child(UiKit.icon("gem", 20))
				reward.add_child(UiKit.label(str(gems), 16, UiKit.WHITE, 3, true))
				row.add_child(reward)
		_body.add_child(card)


func _fill_board(scope: String) -> void:
	if not Net.online:
		_note("Rankings need the game server. You're offline right now, but your trophies are safe once you connect.")
		return
	_note("Loading...")
	var my_request := _request_id
	var result := await Net.leaderboard(scope)
	if my_request != _request_id or not is_instance_valid(_body):
		return
	for child in _body.get_children():
		child.queue_free()
	if not result["ok"]:
		_note("Couldn't load the rankings. Try again soon.")
		return
	var rows: Array = (result["data"] as Dictionary).get("rows", [])
	if rows.is_empty():
		_note("Nobody here yet. Be the first!")
		return
	for i in rows.size():
		_body.add_child(_board_row(i + 1, rows[i], scope))
	var me: Variant = (result["data"] as Dictionary).get("me")
	if me is Dictionary and int((me as Dictionary).get("rank", 0)) > rows.size():
		_body.add_child(_board_row(int(me["rank"]), me, scope))


func _board_row(rank: int, row: Dictionary, scope: String) -> Control:
	var mine: bool = (scope == "players" and str(row.get("name", "")) == Profile.player_name) or (scope == "guilds" and int(row.get("id", 0)) == Profile.guild_id)
	var card := UiKit.panel(Color("1fa35c") if mine else UiKit.CARD, 12, 3)
	var box := UiKit.hbox(10)
	card.add_child(box)
	var medal_color: Color = [UiKit.YELLOW, Color("e6eef8"), Color("f0a868")][rank - 1] if rank <= 3 else UiKit.WHITE
	box.add_child(RoundBadge.new().setup(str(rank), 40.0, medal_color))
	var text := UiKit.vbox(0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title_line := UiKit.title(str(row.get("name", "?")), 17)
	title_line.clip_text = true
	title_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text.add_child(title_line)
	var sub := ""
	if scope == "players":
		var league := Ranks.league_for(int(row.get("trophies", 0)))
		sub = String(league["name"])
		if str(row.get("guild", "")) != "":
			sub += " · %s" % str(row["guild"])
	else:
		sub = "[%s] · %d members" % [str(row.get("tag", "")), int(row.get("members", 0))]
	text.add_child(UiKit.label(sub, 14, UiKit.MUTED))
	box.add_child(text)
	box.add_child(UiKit.icon("trophy", 22))
	box.add_child(UiKit.label(UiKit.format_number(int(row.get("trophies", 0))), 18, UiKit.WHITE, 3, true))
	return card


func _note(text: String) -> void:
	var box := UiKit.margin(20, 40, 20, 20)
	box.add_child(UiKit.note(text, 18))
	_body.add_child(box)
