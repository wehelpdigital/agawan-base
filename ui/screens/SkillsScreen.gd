extends Control
## A hero's skill tree. Tap a skill and the window beside it shows that skill being used, even one that hasn't opened yet. You
## take two into a match, and each level gives you a point to learn one or rank it up.

var root: UiRoot
var args: Dictionary
var screen_name: String
var _hero := ""
var _selected := ""
var _tree: SkillTreeView
var _film: SkillPreview
var _level_label: Label
var _xp_bar: ProgressBar
var _points_label: Label
var _slots: HBoxContainer
var _skill_name: Label
var _type_icon: TextureRect
var _desc: Label
var _pips: HBoxContainer
var _raise: GameButton
var _drop: GameButton


func _ready() -> void:
	_hero = str(args.get("hero", Profile.look.get("char", "kiko")))
	if not Skills.SIGNATURE.has(_hero):
		_hero = "kiko"
	var outer := UiKit.vbox(6)
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 10
	outer.offset_right = -10
	outer.offset_top = 4
	outer.offset_bottom = -8
	add_child(outer)
	_tree = SkillTreeView.new().setup(_hero)
	_tree.picked.connect(_pick)
	if root.portrait:
		outer.add_child(_head())
		outer.add_child(_summary())
		var frame := _film_frame()
		frame.custom_minimum_size.y = minf((size.x - 20.0) * 0.46, size.y * 0.24)
		frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		outer.add_child(frame)
		outer.add_child(_details())
		outer.add_child(_tree)
	else:
		var top := UiKit.hbox(8)
		top.add_child(_head())
		var line := _summary()
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(line)
		outer.add_child(top)
		var body := UiKit.hbox(10)
		body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		outer.add_child(body)
		body.add_child(_tree)
		var side := UiKit.vbox(6)
		side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		side.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body.add_child(side)
		side.add_child(_film_frame())
		side.add_child(_details())
	var state := Profile.hero_state(_hero)
	_selected = String(state["chosen"][0]) if not (state["chosen"] as Array).is_empty() else Skills.own_skill(_hero)
	_show_all.call_deferred()


func _head() -> Control:
	var head := UiKit.hbox(8)
	var back := UiKit.button("", "ink", 18, "arrow_left")
	back.custom_minimum_size = Vector2(56, 48)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: root.go_back())
	head.add_child(back)
	var heading := UiKit.title("SKILLS", 26 if not root.compact else 21)
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(heading)
	return head


## Who it is, how far they've come, and the two skills they're carrying.
func _summary() -> Control:
	var card := UiKit.panel(UiKit.CARD, 14, 3)
	var row := UiKit.hbox(8)
	card.add_child(row)
	var picture := UiKit.image(Cosmetics.thumb_path("char", _hero), Vector2(44, 44))
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(picture)
	var col := UiKit.vbox(1)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(col)
	var top := UiKit.hbox(8)
	var name_line := UiKit.title(String(Cosmetics.item("char", _hero).get("name", "")), 18)
	name_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_line.clip_text = true
	name_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top.add_child(name_line)
	_level_label = UiKit.label("", 16, UiKit.YELLOW, 3, true)
	top.add_child(_level_label)
	col.add_child(top)
	_xp_bar = ProgressBar.new()
	_xp_bar.show_percentage = false
	_xp_bar.custom_minimum_size.y = 10
	col.add_child(_xp_bar)
	_points_label = UiKit.label("", 13, UiKit.INK)
	col.add_child(_points_label)
	_slots = UiKit.hbox(4)
	_slots.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_slots)
	return card


func _film_frame() -> Control:
	var frame := PanelContainer.new()
	var edge := UiKit.style(UiKit.INK, 14, 3)
	edge.content_margin_left = 4
	edge.content_margin_right = 4
	edge.content_margin_top = 4
	edge.content_margin_bottom = 4
	frame.add_theme_stylebox_override("panel", edge)
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_film = SkillPreview.new()
	frame.add_child(_film)
	return frame


## What the skill you've tapped does, and what you can do about it.
func _details() -> Control:
	var card := UiKit.panel(UiKit.CARD, 14, 3)
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var row := UiKit.hbox(8)
	card.add_child(row)
	var text := UiKit.vbox(2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var top := UiKit.hbox(6)
	_type_icon = UiKit.icon("mode_attack", 22)
	top.add_child(_type_icon)
	_skill_name = UiKit.title("", 18)
	_skill_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skill_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(_skill_name)
	_pips = UiKit.hbox(3)
	_pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in Skills.MAX_RANK:
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(13, 13)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pips.add_child(pip)
	top.add_child(_pips)
	text.add_child(top)
	_desc = UiKit.body("", 14, UiKit.INK)
	text.add_child(_desc)
	var buttons := UiKit.vbox(4)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.custom_minimum_size.x = 104 if root.phone_narrow else 122
	row.add_child(buttons)
	_raise = UiKit.button("Learn", "yellow", 16)
	_raise.pressed.connect(_on_raise)
	buttons.add_child(_raise)
	_drop = UiKit.button("Take out", "ink", 13)
	_drop.pressed.connect(_on_drop)
	buttons.add_child(_drop)
	return card


func _pick(skill: String) -> void:
	_selected = skill
	_show_all()


func _on_raise() -> void:
	if Profile.raise_skill(_hero, _selected):
		Audio.sfx("powerup_good")
		_show_all()


func _on_drop() -> void:
	Profile.drop_skill(_hero, _selected)
	Audio.sfx("ui_back")
	_show_all()


func _show_all() -> void:
	var state := Profile.hero_state(_hero)
	var level := int(state["level"])
	var points := Profile.hero_points(_hero)
	var chosen: Array = state["chosen"]
	_level_label.text = "Level %d" % level
	_xp_bar.max_value = Skills.xp_for_level(level)
	_xp_bar.value = int(state["xp"]) if level < Skills.MAX_LEVEL else _xp_bar.max_value
	if points > 0:
		_points_label.text = "%d point%s to spend! Look for the +" % [points, "s" if points != 1 else ""]
	elif level >= Skills.MAX_LEVEL:
		_points_label.text = "Top level!"
	else:
		_points_label.text = "%d XP to the next level" % (Skills.xp_for_level(level) - int(state["xp"]))
	_points_label.add_theme_color_override("font_color", UiKit.YELLOW if points > 0 else UiKit.INK)
	for child in _slots.get_children():
		child.queue_free()
	for i in Skills.MAX_CHOSEN:
		_slots.add_child(_slot(String(chosen[i]) if i < chosen.size() else ""))
	_tree.refresh(_selected)
	_show_selected(state, level)


## One of the two places for a skill you're taking into a match.
func _slot(skill: String) -> Control:
	var ring := PanelContainer.new()
	ring.custom_minimum_size = Vector2(44, 44)
	ring.add_theme_stylebox_override("panel", UiKit.style(UiKit.PAPER if skill != "" else UiKit.INK, 22, 3, UiKit.YELLOW if skill != "" else UiKit.WHITE))
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if skill != "":
		var pic := TextureRect.new()
		pic.texture = UiKit.skill_icon(skill)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.add_child(pic)
	return ring


func _show_selected(state: Dictionary, level: int) -> void:
	var def := Skills.info(_selected)
	var chosen: bool = (state["chosen"] as Array).has(_selected)
	var rank := int(state["ranks"].get(_selected, 0))
	var opens_at := 1
	for node: Dictionary in Skills.tree(_hero):
		if node["skill"] == _selected:
			opens_at = int(node["level"])
	_skill_name.text = String(def["name"])
	_type_icon.texture = UiKit.icon_texture(String(Skills.TYPES[def["type"]]["icon"]))
	_desc.text = "%s Comes back in %d seconds." % [String(def["desc"]), roundi(Skills.cooldown(_selected, maxi(rank, 1)))]
	for i in _pips.get_child_count():
		(_pips.get_child(i) as Panel).add_theme_stylebox_override("panel", UiKit.style(UiKit.YELLOW if i < rank else UiKit.INK, 7, 2, UiKit.WHITE))
	_pips.visible = chosen
	_drop.visible = chosen
	var can_raise := Profile.can_raise_skill(_hero, _selected)
	_raise.disabled = not can_raise
	_raise.set_kind("yellow" if can_raise else "black")
	if level < opens_at:
		_raise.set_text("Level %d" % opens_at)
	elif chosen and rank >= Skills.MAX_RANK:
		_raise.set_text("Top rank")
	elif chosen:
		_raise.set_text("Rank up")
	elif (state["chosen"] as Array).size() >= Skills.MAX_CHOSEN:
		_raise.set_text("Two already")
	elif Profile.hero_points(_hero) <= 0:
		_raise.set_text("No points")
	else:
		_raise.set_text("Learn")
	_film.play(_hero, _selected, maxi(rank, 1))
