extends Control
## After the match: who won, what you earned, the match in numbers, who did what, and how everyone did.

var root: UiRoot
var args: Dictionary
var screen_name: String
var _trophy_line: Label

## What's given out at the end: the stat, its name, and what it's counted in.
const AWARDS := [["tags", "Top Tagger", "tags"], ["rescues", "Jail Breaker", "freed"], ["captures", "Base Raider", "captures"], ["powers", "Card Shark", "cards"], ["skills", "Show-Off", "skills"], ["jailed", "Jailbird", "times"]]


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
		var reason := UiKit.note(why, 16, false)
		reason.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		outer.add_child(reason)
	outer.add_child(_earned(rewards, result))
	var scroll := UiKit.scroller()
	outer.add_child(scroll)
	var teams: BoxContainer = VBoxContainer.new() if root.portrait or size.x < 720.0 else HBoxContainer.new()
	teams.add_theme_constant_override("separation", 8)
	teams.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var my_team := int(result.get("my_team", 0))
	var report := UiKit.vbox(8)
	report.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	report.add_child(_match_numbers(result))
	report.add_child(_awards(result))
	report.add_child(teams)
	scroll.add_child(report)
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
	if rewards.get("hero_leveled", false):
		_level_up.call_deferred(String(rewards["hero"]), int(rewards["hero_level"]))


## A hero went up a level: pick something to spend the point on, now or later.
func _level_up(hero_id: String, level: int) -> void:
	Audio.sfx("achievement")
	var col := root.popup("%s reached level %d!" % [String(Cosmetics.item("char", hero_id).get("name", "")), level])
	var options := Profile.skill_options(hero_id)
	var note := UiKit.body("Pick a skill to learn or level up." if not options.is_empty() else "Nothing to spend it on just yet.", 17)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(note)
	for skill: String in options:
		var state := Profile.hero_state(hero_id)
		var rank := int(state["ranks"].get(skill, 0))
		var def := Skills.info(skill)
		var b := UiKit.button("%s: rank %d" % [def["name"], rank + 1] if rank > 0 else "Learn %s" % def["name"], "green" if rank > 0 else "yellow", 18)
		b.pressed.connect(func() -> void:
			Profile.raise_skill(hero_id, skill)
			Audio.sfx("powerup_good")
			root.close_popup(col))
		col.add_child(b)
	var row := UiKit.hbox(8)
	var later := UiKit.button("Later", "ink", 18)
	later.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	later.pressed.connect(func() -> void: root.close_popup(col))
	row.add_child(later)
	var tree := UiKit.button("See the tree", "teal", 18, "skills")
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree.pressed.connect(func() -> void:
		root.close_popup(col)
		root.show_screen("skills", {"hero": hero_id}, true))
	row.add_child(tree)
	col.add_child(row)


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
	var note := UiKit.note("No trophies in AI or Friend matches", 14, false)
	note.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(note)
	return col


func _on_server_result(data: Dictionary) -> void:
	if is_instance_valid(_trophy_line):
		var delta := int(data.get("delta", 0))
		_trophy_line.text = "%s%d" % ["+" if delta >= 0 else "", delta]


## This match, in numbers: yours, and the whole game's.
func _match_numbers(result: Dictionary) -> Control:
	var mine: Dictionary = result.get("mine", {})
	var card := UiKit.panel(UiKit.CARD, 16, 3)
	var col := UiKit.vbox(6)
	card.add_child(col)
	var top := UiKit.hbox(8)
	var heading := UiKit.title("YOUR MATCH", 18, UiKit.YELLOW)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(heading)
	var ever := int(Profile.stats.get("tags", 0))
	top.add_child(UiKit.label("%s tags all time" % UiKit.format_number(ever), 15, UiKit.WHITE, 3, true))
	col.add_child(top)
	var row := UiKit.hbox(4)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for entry: Array in [["Tags", mine.get("tags", 0)], ["Freed", mine.get("rescues", 0)], ["Captures", mine.get("captures", 0)], ["Jailed", mine.get("jailed", 0)], ["Cards", mine.get("powers", 0)], ["Skills", mine.get("skills", 0)]]:
		row.add_child(_big_stat(String(entry[0]), int(entry[1])))
	col.add_child(row)
	var map := Maps.by_id(str(result.get("map", "")))
	var seconds := int(result.get("seconds", 0.0))
	var all_tags := 0
	var all_cards := 0
	for player: Dictionary in result.get("players", []):
		all_tags += int(player.get("tags", 0))
		all_cards += int(player.get("powers", 0))
	var line := "%s. %d:%02d. %d tags and %d cards in all." % [String(map.get("name", "")), seconds / 60, seconds % 60, all_tags, all_cards]
	col.add_child(UiKit.body(line, 14, UiKit.INK))
	return card


func _big_stat(caption: String, value: int) -> Control:
	var col := UiKit.vbox(-2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var number := UiKit.title(str(value), 26, UiKit.WHITE)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(number)
	var text := UiKit.label(caption, 12, UiKit.INK)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(text)
	return col


## Who was best at what, and who was best at getting caught.
func _awards(result: Dictionary) -> Control:
	var players: Array = result.get("players", [])
	var row := UiKit.hbox(6)
	for award: Array in AWARDS:
		var best: Dictionary = {}
		for player: Dictionary in players:
			if int(player.get(award[0], 0)) > int(best.get(award[0], 0)):
				best = player
		if not best.is_empty():
			row.add_child(_award_card(String(award[1]), best, int(best[award[0]]), String(award[2])))
	var scroll := UiKit.scroller(true)
	scroll.custom_minimum_size.y = 118
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll.add_child(row)
	return scroll


func _award_card(title: String, player: Dictionary, value: int, unit: String) -> Control:
	var card := UiKit.panel(UiKit.INK, 14, 3)
	card.custom_minimum_size = Vector2(148, 0)
	var col := UiKit.vbox(0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(col)
	var heading := UiKit.label(title, 14, UiKit.YELLOW, 3, true)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(heading)
	var middle := UiKit.hbox(4)
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_child(_avatar_icon(player, 42.0))
	var number := UiKit.title(str(value), 28, UiKit.WHITE)
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	middle.add_child(number)
	var what := UiKit.label(unit, 12, UiKit.WHITE)
	what.size_flags_vertical = Control.SIZE_SHRINK_END
	middle.add_child(what)
	col.add_child(middle)
	var who := UiKit.label(str(player["name"]), 13, UiKit.WHITE)
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	who.clip_text = true
	who.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	who.custom_minimum_size.x = 130
	col.add_child(who)
	return card


func _avatar_icon(player: Dictionary, side: float) -> TextureRect:
	var look: Dictionary = player.get("look", {})
	return UiKit.image(Cosmetics.thumb_path("char", str(look.get("char", "kiko"))), Vector2(side, side))


func _team_list(result: Dictionary, team: int) -> Control:
	var my_team := int(result.get("my_team", 0))
	var col := UiKit.vbox(4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head_row := UiKit.hbox(6)
	var title := UiKit.title("Your team" if team == my_team else "Opponents", 18, ArenaBuilder.team_color(team).lightened(0.2))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_row.add_child(title)
	var team_tags := 0
	for row: Dictionary in result.get("players", []):
		if int(row["team"]) == team:
			team_tags += int(row["tags"])
	head_row.add_child(UiKit.note("%d tags" % team_tags, 13, false))
	col.add_child(head_row)
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
	box.add_child(_avatar_icon(row, 34.0))
	if int(row["id"]) == mvp:
		box.add_child(UiKit.icon("crown", 20))
	if row.get("bot", false):
		box.add_child(UiKit.icon("robot", 16))
	var flag_id := str((row.get("look", {}) as Dictionary).get("flag", ""))
	if flag_id != "" and not Cosmetics.item("flag", flag_id).is_empty():
		var flag := TextureRect.new()
		flag.texture = Flags.texture(flag_id)
		flag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flag.custom_minimum_size = Vector2(28, 20)
		flag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		box.add_child(flag)
	var names := UiKit.vbox(-2)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_line := UiKit.label(str(row["name"]), 15, UiKit.WHITE, 3, true)
	name_line.clip_text = true
	name_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	names.add_child(name_line)
	var look: Dictionary = row.get("look", {})
	if not row.get("bot", false) and look.has("tags_ever"):  # What they've got to brag about.
		names.add_child(UiKit.label("%s tags all time" % UiKit.format_number(int(look["tags_ever"]) + int(row["tags"])), 11, UiKit.INK))
	box.add_child(names)
	box.add_child(_stat("Tags", row["tags"]))
	box.add_child(_stat("Saved", row["rescues"]))
	box.add_child(_stat("Caps", row["captures"]))
	if not root.phone_narrow:
		box.add_child(_stat("Jailed", row.get("jailed", 0)))
		box.add_child(_stat("Cards", row.get("powers", 0)))
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
