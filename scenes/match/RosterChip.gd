class_name RosterChip
extends Control
## One player in the row under the score: a coloured round chip, crossed by bars while in jail.

const SIZE := 24.0

var _player: Sim.Player
var _is_me := false
var _color := Color.WHITE
var _jailed := false
var _letter := ""


func setup(p: Sim.Player, is_me: bool) -> void:
	_player = p
	_is_me = is_me
	_color = ArenaBuilder.team_color(p.team)
	_letter = p.name.left(1).to_upper()
	custom_minimum_size = Vector2(SIZE, SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func refresh(_sim: Sim) -> void:
	var jailed := _player.state == Sim.State.JAIL
	if jailed != _jailed:
		_jailed = jailed
		queue_redraw()


func _draw() -> void:
	var r := SIZE * 0.5
	var c := Vector2(r, r)
	draw_circle(c, r, UiKit.INK)
	draw_circle(c, r - 2.5, _color.darkened(0.5) if _jailed else _color)
	if _is_me:
		draw_arc(c, r - 1.0, 0.0, TAU, 20, Color.WHITE, 2.5, true)
	var font := UiKit.font_title()
	var w := font.get_string_size(_letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(font, c + Vector2(-w * 0.5, 5.0), _letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE if not _jailed else Color(1, 1, 1, 0.5))
	if _jailed:
		for x: float in [-5.5, 0.0, 5.5]:
			draw_line(c + Vector2(x, -r + 2.0), c + Vector2(x, r - 2.0), UiKit.INK, 2.5)
