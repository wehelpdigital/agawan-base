class_name RosterChip
extends Control
## One player in the row under the score: their avatar and how many they've tagged, for everybody to see. Bars go across the
## face while they're in jail, the number jumps when it goes up, and whoever's tagged the most wears the crown.

const HEIGHT := 30.0

var _player: Sim.Player
var _is_me := false
var _color := Color.WHITE
var _jailed := false
var _tags := -1
var _pop := 0.0
var _leader := false
var _face: Texture2D
var _box: StyleBoxFlat


func setup(p: Sim.Player, is_me: bool) -> void:
	_player = p
	_is_me = is_me
	_color = ArenaBuilder.team_color(p.team)
	var path := Cosmetics.thumb_path("char", str(p.look.get("char", "kiko")))
	_face = load(path) if ResourceLoader.exists(path) else null
	_box = UiKit.style(UiKit.INK, 15, 3 if is_me else 2, Color.WHITE if is_me else _color)
	set_width(50.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_width(width: float) -> void:
	custom_minimum_size = Vector2(width, HEIGHT)
	queue_redraw()


## `best` is the most tags anyone has.
func refresh(best: int, delta: float) -> void:
	var jailed := _player.state == Sim.State.JAIL
	var leader := best > 0 and _player.tags >= best
	if _player.tags != _tags:
		if _tags >= 0 and _player.tags > _tags:
			_pop = 1.0
		_tags = _player.tags
		queue_redraw()
	if jailed != _jailed or leader != _leader:
		_jailed = jailed
		_leader = leader
		queue_redraw()
	if _pop > 0.0:
		_pop = move_toward(_pop, 0.0, delta * 2.6)
		queue_redraw()


func _draw() -> void:
	draw_style_box(_box, Rect2(Vector2.ZERO, size))
	var r := HEIGHT * 0.5 - 3.0
	var c := Vector2(HEIGHT * 0.5, HEIGHT * 0.5)
	draw_circle(c, r, UiKit.INK_SOFT if _jailed else _color, true, -1.0, true)
	if _face:
		# Just the head: it fills the middle of the picture of the whole avatar.
		var whole := _face.get_size()
		var side := r * 2.1
		var tint := Color(0.5, 0.5, 0.6) if _jailed else Color.WHITE
		draw_texture_rect_region(_face, Rect2(c - Vector2(side, side) * 0.5, Vector2(side, side)), Rect2(whole * Vector2(0.2, 0.16), whole * 0.6), tint)
	if _jailed:
		for x: float in [-5.0, 0.0, 5.0]:
			draw_line(c + Vector2(x, -r + 2.0), c + Vector2(x, r - 2.0), Color.WHITE, 2.0)
	var font := UiKit.font_title()
	var text := str(maxi(_tags, 0))
	var room := size.x - HEIGHT - 2.0
	var font_size := int(lerpf(15.0, 21.0, _pop)) if room >= 16.0 else int(lerpf(13.0, 18.0, _pop))
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if w > room and room > 0.0:
		font_size = maxi(int(font_size * room / w), 9)
		w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2(HEIGHT + (room - w) * 0.5 - 1.0, HEIGHT * 0.5 + font_size * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiKit.YELLOW if _leader else Color.WHITE)
	if _leader:
		var crown := 16.0
		draw_texture_rect(UiKit.icon_texture("crown"), Rect2(c + Vector2(-crown * 0.5, -HEIGHT * 0.5 - crown * 0.5), Vector2(crown, crown)), false)
