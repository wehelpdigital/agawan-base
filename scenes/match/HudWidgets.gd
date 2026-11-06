class_name HudButton
extends Control
## A big round action button in the match: an icon, a name, and a cooldown sweep around it.

var _icon: Texture2D
var _label_text := ""
var _color := Color.WHITE
var _cooldown := 0.0
var _down := false
var _seconds := 0


func setup(icon_name: String, color: Color, label_text: String) -> void:
	_icon = UiKit.icon_texture(icon_name)
	_color = color
	_label_text = label_text
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## For a skill: the picture comes from the skill, and its time left shows on it while it's coming back.
func setup_skill(skill: String) -> void:
	_icon = UiKit.skill_icon(skill)
	_color = Skills.color(skill)
	_label_text = String(Skills.info(skill).get("name", ""))
	_seconds = 0
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_seconds(seconds: int) -> void:
	if seconds != _seconds:
		_seconds = seconds
		queue_redraw()


func set_cooldown(fraction: float) -> void:
	if not is_equal_approx(fraction, _cooldown):
		_cooldown = fraction
		queue_redraw()


func set_pressed_look(on: bool) -> void:
	_down = on
	queue_redraw()


func _draw() -> void:
	var r := size.x * 0.5
	var c := Vector2(r, r + (3.0 if _down else 0.0))
	var ready := _cooldown <= 0.0
	draw_circle(c + Vector2(0, 5), r, UiKit.INK)
	draw_circle(c, r, UiKit.INK)
	draw_circle(c, r - 5.0, _color if ready else _color.darkened(0.5))
	if ready:
		draw_arc(c + Vector2(0, -2), r - 12.0, PI * 1.15, PI * 1.85, 16, Color(1, 1, 1, 0.5), 5.0, true)
	var icon_side := r * 1.28
	draw_texture_rect(_icon, Rect2(c - Vector2(icon_side, icon_side) * 0.5 - Vector2(0, r * 0.12), Vector2(icon_side, icon_side)), false)
	if _cooldown > 0.01:
		var steps := 32
		var pts := PackedVector2Array([c])
		for i in steps + 1:
			var a := -PI * 0.5 + TAU * minf(_cooldown, 0.995) * float(i) / steps  # A full circle would meet itself, and can't be drawn.
			pts.append(c + Vector2(cos(a), sin(a)) * (r - 5.0))
		if pts.size() >= 3:
			draw_colored_polygon(pts, Color(UiKit.INK, 0.82))
	if _label_text != "":
		var font := UiKit.font_title()
		var font_size := int(r * 0.32)
		var w := font.get_string_size(_label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var widest := size.x * 1.14
		if w > widest:  # Long names go smaller, and may run a little past the edge of the button.
			font_size = maxi(int(font_size * widest / w), 9)
			w = font.get_string_size(_label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var at := c + Vector2(-w * 0.5, r * 0.62)
		draw_string_outline(font, at, _label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, UiKit.INK)
		draw_string(font, at, _label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	if _seconds > 0:
		var font := UiKit.font_title()
		var text := str(_seconds)
		var font_size := int(r * 0.7)
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var at := c + Vector2(-w * 0.5, r * 0.2)
		draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 8, UiKit.INK)
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
