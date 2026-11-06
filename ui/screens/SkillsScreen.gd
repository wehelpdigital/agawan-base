extends Control
## A hero's skill tree: their own skill at the top, the rest opening up as they level. You take two into a match, and each level
## gives you a point to learn one or rank it up.

var root: UiRoot
var args: Dictionary
var screen_name: String
var _hero := ""
var _summary: VBoxContainer
var _list: VBoxContainer


func _ready() -> void:
	_hero = str(args.get("hero", Profile.look.get("char", "kiko")))
	if not Skills.SIGNATURE.has(_hero):
		_hero = "kiko"
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
	var heading := UiKit.title("SKILLS", 26 if not root.compact else 21)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(heading)
	outer.add_child(head)
	_summary = UiKit.vbox(0)
	outer.add_child(_summary)
	var scroll := UiKit.scroller()
	outer.add_child(scroll)
	_list = UiKit.vbox(0)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_refresh()


func _refresh() -> void:
	for box: Control in [_summary, _list]:
		for child in box.get_children():
			child.queue_free()
	_summary.add_child(_summary_card())
	var nodes := Skills.tree(_hero)
	for i in nodes.size():
		_list.add_child(_node_row(nodes[i], i == nodes.size() - 1))


## Who it is, how far they've come, and what's in their hands.
func _summary_card() -> Control:
	var state := Profile.hero_state(_hero)
	var level := int(state["level"])
	var points := Profile.hero_points(_hero)
	var card := UiKit.panel(UiKit.CARD, 16, 3)
	var row := UiKit.hbox(10)
	card.add_child(row)
	var picture := UiKit.image(Cosmetics.thumb_path("char", _hero), Vector2(72, 72))
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(picture)
	var col := UiKit.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var top := UiKit.hbox(8)
	var name_line := UiKit.title(String(Cosmetics.item("char", _hero).get("name", "")), 22 if not root.phone_narrow else 19)
	name_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_line.clip_text = true
	name_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(name_line)
	top.add_child(UiKit.label("Level %d" % level, 17, UiKit.YELLOW, 3, true))
	col.add_child(top)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size.y = 14
	bar.max_value = Skills.xp_for_level(level)
	bar.value = int(state["xp"]) if level < Skills.MAX_LEVEL else bar.max_value
	col.add_child(bar)
	var words := "%d of %d skills chosen." % [(state["chosen"] as Array).size(), Skills.MAX_CHOSEN]
	if points > 0:
		words += " %d point%s to spend!" % [points, "s" if points != 1 else ""]
	elif level >= Skills.MAX_LEVEL:
		words += " Top level!"
	else:
		words += " %d XP to the next level." % (Skills.xp_for_level(level) - int(state["xp"]))
	col.add_child(UiKit.label(words, 14, UiKit.YELLOW if points > 0 else UiKit.INK))
	return card


## One skill in the tree, with a line down to the next.
func _node_row(node: Dictionary, last: bool) -> Control:
	var skill := String(node["skill"])
	var def := Skills.info(skill)
	var state := Profile.hero_state(_hero)
	var chosen: bool = (state["chosen"] as Array).has(skill)
	var open := int(state["level"]) >= int(node["level"])
	var rank := int(state["ranks"].get(skill, 0))
	var wrap := UiKit.vbox(0)
	var card_color: Color = Color("1fa35c") if chosen else (UiKit.CARD if open else UiKit.INK_SOFT)
	var card := UiKit.panel(card_color, 14, 3)
	wrap.add_child(card)
	var row := UiKit.hbox(8)
	card.add_child(row)
	var pic := TextureRect.new()
	pic.texture = UiKit.skill_icon(skill)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(60, 60)
	pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pic.modulate = Color.WHITE if open else Color(0.55, 0.58, 0.7)
	row.add_child(pic)
	var text := UiKit.vbox(0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var top := UiKit.hbox(6)
	var title := UiKit.title(String(def["name"]), 17)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	top.add_child(UiKit.icon(String(Skills.TYPES[def["type"]]["icon"]), 22))
	text.add_child(top)
	var line := "%s Comes back in %d seconds." % [String(def["desc"]), roundi(Skills.cooldown(skill, maxi(rank, 1)))]
	var desc := UiKit.body(line, 14, UiKit.WHITE if not open else UiKit.INK)
	text.add_child(desc)
	if chosen:
		text.add_child(_pips(rank))
	row.add_child(_buttons(skill, node, chosen, open, rank))
	if not last:
		var joint := Control.new()
		joint.custom_minimum_size = Vector2(0, 12)
		joint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		joint.draw.connect(func() -> void: joint.draw_rect(Rect2(36.0, 0.0, 8.0, joint.size.y), UiKit.WHITE))
		wrap.add_child(joint)
	return wrap


## How many of its five ranks a skill has.
func _pips(rank: int) -> Control:
	var row := UiKit.hbox(3)
	for i in Skills.MAX_RANK:
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(15, 15)
		pip.add_theme_stylebox_override("panel", UiKit.style(UiKit.YELLOW if i < rank else UiKit.INK, 8, 2, UiKit.WHITE))
		row.add_child(pip)
	return row


func _buttons(skill: String, node: Dictionary, chosen: bool, open: bool, rank: int) -> Control:
	var col := UiKit.vbox(4)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.custom_minimum_size.x = 96 if root.phone_narrow else 118
	if not open:
		var locked := UiKit.button("Level %d" % int(node["level"]), "black", 14)
		locked.disabled = true
		col.add_child(locked)
		return col
	var raise := UiKit.button("Rank up" if chosen else "Learn", "yellow" if Profile.can_raise_skill(_hero, skill) else "black", 15)
	raise.disabled = not Profile.can_raise_skill(_hero, skill)
	if chosen and rank >= Skills.MAX_RANK:
		raise.set_text("Top rank")
	elif not chosen and (Profile.hero_state(_hero)["chosen"] as Array).size() >= Skills.MAX_CHOSEN:
		raise.set_text("Two already")
	elif not chosen and Profile.hero_points(_hero) <= 0:
		raise.set_text("No points")
	raise.pressed.connect(func() -> void:
		if Profile.raise_skill(_hero, skill):
			Audio.sfx("powerup_good")
			_refresh())
	col.add_child(raise)
	if chosen:
		var drop := UiKit.button("Take out", "ink", 13)
		drop.pressed.connect(func() -> void:
			Profile.drop_skill(_hero, skill)
			Audio.sfx("ui_back")
			_refresh())
		col.add_child(drop)
	return col
