class_name SkillTreeView
extends Control
## A hero's skills as a real tree: their own at the root, branches opening up as they level, and the last one at the very top.
## Tap one to see it. Everything's placed by proportion, so the same tree fits a phone and a desktop.

signal picked(skill: String)

const SPOTS: Array[Vector2] = [Vector2(0.5, 0.875), Vector2(0.17, 0.62), Vector2(0.83, 0.62), Vector2(0.28, 0.33), Vector2(0.72, 0.33), Vector2(0.5, 0.115)]
const FORK_LOW := 0.73  ## Where the first pair of branches leave the trunk...
const FORK_HIGH := 0.47  ## ...and the second.
## The leaves: where, and how far out across and up, by proportion.
const LEAVES: Array[Rect2] = [Rect2(0.5, 0.17, 0.3, 0.19), Rect2(0.27, 0.3, 0.26, 0.21), Rect2(0.73, 0.3, 0.26, 0.21), Rect2(0.5, 0.42, 0.34, 0.22),
	Rect2(0.15, 0.56, 0.17, 0.15), Rect2(0.85, 0.56, 0.17, 0.15), Rect2(0.33, 0.6, 0.22, 0.13), Rect2(0.67, 0.6, 0.22, 0.13)]
const BARK := Color("9c6a35")
const LIT := Color("ffd23f")
const LEAF := Color("4fb04a")
const LEAF_LIGHT := Color("7ed957")
const HILL := Color("5cc94f")

var _hero := ""
var _level := 1
var _orbs: Array[SkillOrb] = []
var _names: Array[PanelContainer] = []


func setup(hero_id: String) -> SkillTreeView:
	_hero = hero_id
	mouse_filter = Control.MOUSE_FILTER_PASS
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip_contents = true
	var nodes := Skills.tree(hero_id)
	for i in nodes.size():
		var orb := SkillOrb.new()
		orb.setup(String(nodes[i]["skill"]), int(nodes[i]["level"]))
		orb.pressed.connect(func() -> void:
			Audio.sfx("ui_click")
			picked.emit(orb.skill))
		add_child(orb)
		_orbs.append(orb)
		var tag := PanelContainer.new()
		var box := UiKit.style(UiKit.INK, 9, 2, UiKit.WHITE)
		box.content_margin_left = 7
		box.content_margin_right = 7
		box.content_margin_top = 1
		box.content_margin_bottom = 2
		tag.add_theme_stylebox_override("panel", box)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.add_child(UiKit.label(String(Skills.info(orb.skill).get("name", "")), 13, UiKit.WHITE))
		add_child(tag)
		_names.append(tag)
	resized.connect(_arrange)
	return self


## How everything looks right now, after a skill's changed.
func refresh(selected: String) -> void:
	var state := Profile.hero_state(_hero)
	_level = int(state["level"])
	for i in _orbs.size():
		var orb := _orbs[i]
		var chosen: bool = (state["chosen"] as Array).has(orb.skill)
		orb.show_state(_level >= orb.opens_at, chosen, int(state["ranks"].get(orb.skill, 0)), orb.skill == selected, Profile.can_raise_skill(_hero, orb.skill))
		var label := _names[i].get_child(0) as Label
		label.add_theme_color_override("font_color", UiKit.YELLOW if orb.skill == selected else UiKit.WHITE)
	queue_redraw()


func _orb_side() -> float:
	return clampf(minf(size.x * 0.2, size.y * 0.18), 44.0, 96.0)


func _arrange() -> void:
	if size.x < 10.0 or size.y < 10.0:
		return
	var side := _orb_side()
	var font_size := 13 if side >= 66.0 else 11
	for i in _orbs.size():
		var at := SPOTS[i] * size
		_orbs[i].size = Vector2(side, side)
		_orbs[i].position = at - Vector2(side, side) * 0.5
		var tag := _names[i]
		(tag.get_child(0) as Label).add_theme_font_size_override("font_size", font_size)
		tag.reset_size()
		var wide := tag.get_combined_minimum_size()
		tag.size = wide
		tag.position = Vector2(clampf(at.x - wide.x * 0.5, 2.0, maxf(size.x - wide.x - 2.0, 2.0)), minf(at.y + side * 0.5 - 2.0, size.y - wide.y - 1.0))
	queue_redraw()


func _draw() -> void:
	if size.x < 10.0 or size.y < 10.0:
		return
	_draw_hill()
	_draw_leaves()
	var thick := clampf(_orb_side() * 0.3, 12.0, 28.0)
	var mid := size.x * 0.5
	# The trunk, thinner as it goes up, lit as far as you've come.
	_branch(PackedVector2Array([Vector2(mid, size.y), Vector2(mid, size.y * FORK_LOW)]), thick, _level >= 1)
	_branch(PackedVector2Array([Vector2(mid, size.y * FORK_LOW), Vector2(mid, size.y * FORK_HIGH)]), thick * 0.82, _level >= 5)
	_branch(PackedVector2Array([Vector2(mid, size.y * FORK_HIGH), SPOTS[5] * size]), thick * 0.66, _level >= 10)
	_bough(Vector2(mid, size.y * FORK_LOW), SPOTS[1] * size, thick * 0.66, _level >= 2)
	_bough(Vector2(mid, size.y * FORK_LOW), SPOTS[2] * size, thick * 0.66, _level >= 3)
	_bough(Vector2(mid, size.y * FORK_HIGH), SPOTS[3] * size, thick * 0.54, _level >= 5)
	_bough(Vector2(mid, size.y * FORK_HIGH), SPOTS[4] * size, thick * 0.54, _level >= 7)


func _draw_hill() -> void:
	var at := Vector2(size.x * 0.5, size.y * 1.02)
	var across := Vector2(size.x * 0.62, size.y * 0.15)
	_blob(at, across + Vector2(3, 3), UiKit.INK)
	_blob(at, across, HILL)


func _draw_leaves() -> void:
	for leaf in LEAVES:
		_blob(leaf.position * size, leaf.size * size + Vector2(3, 3), UiKit.INK)
	for leaf in LEAVES:
		_blob(leaf.position * size, leaf.size * size, LEAF)
	for leaf in LEAVES:
		_blob(leaf.position * size - Vector2(0, leaf.size.y * size.y * 0.16), leaf.size * size * 0.72, LEAF_LIGHT)


func _blob(at: Vector2, across: Vector2, color: Color) -> void:
	draw_set_transform(at, 0.0, across)
	draw_circle(Vector2.ZERO, 1.0, color, true, -1.0, false)
	draw_set_transform(Vector2.ZERO)


## A branch, curving up and out.
func _bough(from: Vector2, to: Vector2, thick: float, lit: bool) -> void:
	var bend := Vector2(lerpf(from.x, to.x, 0.72), lerpf(from.y, to.y, 0.05))
	var path := PackedVector2Array()
	for i in 17:
		var t := i / 16.0
		path.append(from.lerp(bend, t).lerp(bend.lerp(to, t), t))
	_branch(path, thick, lit)


func _branch(path: PackedVector2Array, thick: float, lit: bool) -> void:
	draw_polyline(path, UiKit.INK, thick + 6.0, true)
	draw_polyline(path, BARK, thick, true)
	if lit:
		draw_polyline(path, LIT, maxf(thick * 0.34, 3.0), true)


## One skill on the tree.
class SkillOrb extends Button:
	var skill := ""
	var opens_at := 1
	var _picture: Texture2D
	var _ring := Color.WHITE
	var _open := false
	var _chosen := false
	var _rank := 0
	var _selected := false
	var _ready_to_raise := false
	var _clock := 0.0

	func setup(p_skill: String, level: int) -> void:
		skill = p_skill
		opens_at = level
		_picture = UiKit.skill_icon(p_skill)
		_ring = Skills.color(p_skill)
		flat = true
		focus_mode = Control.FOCUS_ALL
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tooltip_text = String(Skills.info(p_skill).get("name", ""))

	func show_state(open: bool, chosen: bool, rank: int, selected: bool, can_raise: bool) -> void:
		_open = open
		_chosen = chosen
		_rank = rank
		_selected = selected
		_ready_to_raise = can_raise
		queue_redraw()

	func _process(delta: float) -> void:
		if _selected or _ready_to_raise:
			_clock += delta
			queue_redraw()

	func _draw() -> void:
		var r := size.x * 0.5
		var c := Vector2(r, r)
		if _selected:
			draw_arc(c, r - 1.0 + sin(_clock * 5.0) * 1.5, 0.0, TAU, 48, Color.WHITE, 5.0, true)
		draw_circle(c + Vector2(0, 3), r - 3.0, UiKit.INK, true, -1.0, true)
		draw_circle(c, r - 3.0, UiKit.INK, true, -1.0, true)
		var edge: Color = UiKit.YELLOW if _chosen else (_ring if _open else UiKit.INK_SOFT)
		draw_circle(c, r - 6.0, edge, true, -1.0, true)
		draw_circle(c, r - 11.0, UiKit.PAPER if _open else UiKit.INK_SOFT, true, -1.0, true)
		var side := (r - 11.0) * 1.56
		var tint := Color.WHITE if _open else Color(0.5, 0.54, 0.68)
		var spot := Rect2(c - Vector2(side, side) * 0.5, Vector2(side, side))
		if Skills.info(skill).has("hero"):  # The hero's own skill shows their head.
			var whole := _picture.get_size()
			draw_texture_rect_region(_picture, spot, Rect2(whole * Vector2(0.2, 0.16), whole * 0.6), tint)
		else:
			draw_texture_rect(_picture, spot, false, tint)
		if _chosen:
			var dot := maxf(r * 0.1, 3.0)
			for i in Skills.MAX_RANK:
				var a := PI * 0.5 + (i - 2.0) * 0.38
				var at := c + Vector2(cos(a), sin(a)) * (r - 5.0)
				draw_circle(at, dot + 1.5, UiKit.INK, true, -1.0, true)
				draw_circle(at, dot, UiKit.YELLOW if i < _rank else UiKit.WHITE, true, -1.0, true)
		if not _open:
			_badge(c + Vector2(-r * 0.62, -r * 0.62), r * 0.36, str(opens_at))
			var lock := r * 0.62
			draw_texture_rect(UiKit.icon_texture("lock"), Rect2(c + Vector2(r * 0.74 - lock * 0.5, r * 0.62 - lock * 0.5), Vector2(lock, lock)), false)
		elif _ready_to_raise:
			var grow := 1.0 + sin(_clock * 6.0) * 0.1
			_badge(c + Vector2(r * 0.66, -r * 0.66), r * 0.34 * grow, "+")

	func _badge(at: Vector2, radius: float, text: String) -> void:
		draw_circle(at, radius + 2.0, UiKit.INK, true, -1.0, true)
		draw_circle(at, radius, UiKit.YELLOW, true, -1.0, true)
		var font := UiKit.font_title()
		var font_size := maxi(int(radius * 1.25), 9)
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, at + Vector2(-w * 0.5, font_size * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiKit.INK)
