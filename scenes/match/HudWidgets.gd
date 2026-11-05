class_name HudButton
extends Control
## A big round action button in the match: an icon or powerup, and a cooldown sweep around it.

var _icon: Texture2D
var _power: Texture2D
var _label_text := ""
var _color := Color.WHITE
var _cooldown := 0.0
var _down := false
var _power_id := ""
var _pulse := 0.0


func setup(icon_name: String, color: Color, label_text: String) -> void:
	_icon = UiKit.icon_texture(icon_name)
	_color = color
	_label_text = label_text
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_cooldown(fraction: float) -> void:
	if not is_equal_approx(fraction, _cooldown):
		_cooldown = fraction
		queue_redraw()


func set_pressed_look(on: bool) -> void:
	_down = on
	queue_redraw()


func set_power(id: String) -> void:
	if id == _power_id:
		return
	_power_id = id
	_power = load(Powerups.icon_path(id)) if id != "" else null
	if id != "":
		_pulse = 1.0
		var tween := create_tween()
		tween.tween_method(func(v: float) -> void:
			_pulse = v
			queue_redraw(), 1.0, 0.0, 0.3)
	queue_redraw()


func _draw() -> void:
	var r := size.x * 0.5
	var c := Vector2(r, r + (3.0 if _down else 0.0))
	var scale_now := 1.0 + _pulse * 0.16 - (0.04 if _down else 0.0)
	if _power != null:
		var side := size.x * scale_now
		draw_circle(c + Vector2(0, 5), r * 0.98, Color(UiKit.INK, 0.5))
		draw_texture_rect(_power, Rect2(c - Vector2(side, side) * 0.5, Vector2(side, side)), false)
		return
	var ready := _cooldown <= 0.0
	draw_circle(c + Vector2(0, 5), r, UiKit.INK)
	draw_circle(c, r, UiKit.INK)
	var fill := _color if ready else _color.darkened(0.5)
	if _label_text == "":
		fill = Color(UiKit.INK_SOFT, 0.9)  # An empty power slot.
	draw_circle(c, r - 5.0, fill)
	if ready and _label_text != "":
		draw_arc(c + Vector2(0, -2), r - 12.0, PI * 1.15, PI * 1.85, 16, Color(1, 1, 1, 0.5), 5.0, true)
	var icon_side := r * (1.05 if _label_text != "" else 0.9)
	draw_texture_rect(_icon, Rect2(c - Vector2(icon_side, icon_side) * 0.5 - Vector2(0, 4 if _label_text != "" else 0), Vector2(icon_side, icon_side)), false, Color(1, 1, 1, 0.95 if _label_text != "" else 0.32))
	if _cooldown > 0.0:
		var steps := 32
		var pts := PackedVector2Array([c])
		for i in steps + 1:
			var a := -PI * 0.5 + TAU * _cooldown * float(i) / steps
			pts.append(c + Vector2(cos(a), sin(a)) * (r - 5.0))
		if pts.size() >= 3:
			draw_colored_polygon(pts, Color(UiKit.INK, 0.55))
	if _label_text != "":
		var font := UiKit.font_title()
		var font_size := int(r * 0.32)
		var w := font.get_string_size(_label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var at := c + Vector2(-w * 0.5, r * 0.62)
		draw_string_outline(font, at, _label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, UiKit.INK)
		draw_string(font, at, _label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
