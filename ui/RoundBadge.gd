class_name RoundBadge
extends Control
## A number in a true circle: it keeps its size whatever the row around it does, so it can never stretch into an oval.
## `progress` (0..1, or below zero for none) runs a bright ring round the edge: how far to the next level, say.

var value := "":
	set(v):
		value = v
		queue_redraw()
var progress := -1.0:
	set(v):
		progress = v
		queue_redraw()
var fill := UiKit.YELLOW
var text_color := UiKit.INK
var _side := 40.0


## `side` is the circle's width and height.
func setup(p_value: String, side: float, p_fill := UiKit.YELLOW, p_text := UiKit.INK) -> RoundBadge:
	value = p_value
	_side = side
	fill = p_fill
	text_color = p_text
	custom_minimum_size = Vector2(side, side)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


func _draw() -> void:
	var side := minf(size.x, size.y)
	var r := side * 0.5
	var c := size * 0.5
	draw_circle(c + Vector2(0, 2.0), r, Color(UiKit.INK, 0.3))
	draw_circle(c, r, UiKit.INK)
	var edge := maxf(side * 0.08, 2.5)
	draw_circle(c, r - edge, fill)
	# The shine across the top, as on the buttons.
	var shine := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		shine.append(c + Vector2(cos(a) * (r - edge * 1.7), sin(a) * (r - edge * 1.7) * 0.62 - r * 0.06))
	draw_colored_polygon(shine, Color(1, 1, 1, 0.34))
	if progress >= 0.0:
		draw_arc(c, r - edge * 0.5, -PI * 0.5, -PI * 0.5 + TAU * clampf(progress, 0.0, 1.0), 40, UiKit.MINT, edge, true)
	var font := UiKit.font_title()
	var font_size := int(side * (0.5 if value.length() < 2 else (0.44 if value.length() < 3 else 0.34)))
	var w := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var at := c + Vector2(-w.x * 0.5, font.get_ascent(font_size) * 0.5 - font.get_descent(font_size) * 0.15)
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
