extends Control
## After the match: who won, what you earned, how everyone did.

var root: UiRoot
var args: Dictionary
var screen_name: String
var _trophy_line: Label


func _ready() -> void:
	Audio.music("menu")
	var result: Dictionary = args.get("result", {})
	var rewards: Dictionary = args.get("rewards", {})
	var mine: Dictionary = result.get("mine", {})
	var won: bool = mine.get("won", false)
	var draw: bool = mine.get("draw", false)
	var outer := UiKit.vbox(8)
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 10
	outer.offset_right = -10
	outer.offset_top = 8
	outer.offset_bottom = -10
	add_child(outer)
	var banner_text := "DRAW!" if draw else ("VICTORY!" if won else "DEFEAT")
	var banner := UiKit.title(banner_text, 52 if not root.compact else 36, UiKit.YELLOW if won else (UiKit.WHITE if draw else Color("ff8a78")))
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(banner)
	banner.pivot_offset = Vector2(size.x * 0.5, 30.0)
	banner.scale = Vector2.ONE * 0.4
	create_tween().tween_property(banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var why := _reason_text(result)
	if why != "":
		var reason := UiKit.open_text(why, 17)
		reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		outer.add_child(reason)
	outer.add_child(_earned(rewards, result))
	var scroll := UiKit.scroller()
	outer.add_child(scroll)
	var teams: BoxContainer = VBoxContainer.new() if root.portrait or size.x < 720.0 else HBoxContainer.new()
	teams.add_theme_constant_override("separation", 8)
	teams.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(teams)
	var my_team := int(result.get("my_team", 0))
	teams.add_child(_team_list(result, my_team))
	teams.add_child(_team_list(result, 1 - my_team))
	var row := UiKit.hbox(8)
	var home := UiKit.button("Home", "ink", 22, "arrow_left")
	home.custom_minimum_size.y = 60
	home.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home.pressed.connect(func() -> void: root.show_screen("home", {"skip_daily": true}))
	row.add_child(home)
	var again := UiKit.button("PLAY AGAIN", "yellow", 24)
	again.custom_minimum_size.y = 60
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.size_flags_stretch_ratio = 1.5
	var online: bool = result.get("online", false)
	again.pressed.connect(func() -> void:
		if online:
			root.main.start_online()
		else:
			root.main.replay_practice())
	row.add_child(again)
	outer.add_child(row)
	Net.match_result.connect(_on_server_result)


func _reason_text(result: Dictionary) -> String:
	var score: Array = result.get("score", [0, 0])
	var my_team := int(result.get("my_team", 0))
	var line := "%d - %d" % [int(score[my_team]), int(score[1 - my_team])]
	match str(result.get("reason", "")):
		"capture": line += ", base captured"
		"wipeout": line += ", the whole team in jail"
		"tags": line += ", decided by prisoners taken"
		"time": line += ", at the final whistle"
	return line


func _earned(rewards: Dictionary, result: Dictionary) -> Control:
	var row := UiKit.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(UiKit.stat_pill("coin", "+%d" % int(rewards.get("coins", 0)), UiKit.COIN, 40))
	row.add_child(UiKit.stat_pill("star", "+%d XP" % int(rewards.get("xp", 0)), UiKit.AQUA, 40))
	if result.get("online", false) and result.get("ranked", true):
		var pill := UiKit.stat_pill("trophy", "...", UiKit.TROPHY, 40)
		_trophy_line = pill.find_child("Value", true, false) as Label
		row.add_child(pill)
		# The server may well have answered before this screen opened.
		if str(Net.last_result.get("match", "")) == str(result.get("match_id", "-")):
			_on_server_result(Net.last_result)
		return row
	var col := UiKit.vbox(2)
	col.add_child(row)
	var note := UiKit.open_text("No trophies in AI or Friend matches", 15)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(note)
	return col


func _on_server_result(data: Dictionary) -> void:
	if is_instance_valid(_trophy_line):
		var delta := int(data.get("delta", 0))
		_trophy_line.text = "%s%d" % ["+" if delta >= 0 else "", delta]


func _team_list(result: Dictionary, team: int) -> Control:
	var my_team := int(result.get("my_team", 0))
	var col := UiKit.vbox(4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := UiKit.title("Your team" if team == my_team else "Opponents", 18, ArenaBuilder.team_color(team).lightened(0.2))
	col.add_child(title)
	var rows: Array = []
	for row: Dictionary in result.get("players", []):
		if int(row["team"]) == team:
			rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["score"]) > int(b["score"]))
	for row: Dictionary in rows:
		col.add_child(_player_row(row, int(result.get("mvp", -1))))
	return col


func _player_row(row: Dictionary, mvp: int) -> Control:
	var card := UiKit.panel(UiKit.CARD if str(row["name"]) != Profile.player_name else Color("1fa35c"), 10, 2)
	var box := UiKit.hbox(6)
	card.add_child(box)
	if int(row["id"]) == mvp:
		box.add_child(UiKit.icon("crown", 20))
	if row.get("bot", false):
		box.add_child(UiKit.icon("robot", 16))
	var name_line := UiKit.label(str(row["name"]), 15, UiKit.WHITE, 3, true)
	name_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_line.clip_text = true
	name_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(name_line)
	box.add_child(_stat("Tags", row["tags"]))
	box.add_child(_stat("Saved", row["rescues"]))
	box.add_child(_stat("Caps", row["captures"]))
	return card


func _stat(caption: String, value: Variant) -> Control:
	var col := UiKit.vbox(-3)
	col.custom_minimum_size.x = 40
	var number := UiKit.label(str(value), 15, UiKit.YELLOW, 3, true)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(number)
	var text := UiKit.label(caption, 11, UiKit.MUTED)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(text)
	return col
