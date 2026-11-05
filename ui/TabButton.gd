class_name TabButton
extends BaseButton
## One tab in the bottom bar: an icon with its name; the selected tab pops up in a coloured plate.

var _icon: Texture2D
var _text := ""
var _on := false
var _compact := false
var _big := false


func setup(text: String, icon_name: String, on: bool, compact: bool, big := false) -> void:
	_text = text
	_icon = UiKit.icon_texture(icon_name)
	_on = on
	_compact = compact
	_big = big
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _draw() -> void:
	var font := UiKit.font_title()
	var font_size := 13 if _compact else 15
	var rect := Rect2(Vector2.ZERO, size)
	if _on:
		draw_style_box(UiKit.style(UiKit.YELLOW, 14, 3, UiKit.ORANGE), rect)
	elif is_hovered() or has_focus():
		draw_style_box(UiKit.style(Color(UiKit.SKY_LIGHT, 0.22), 14), rect)
	var label_room := float(font_size) + 4.0
	var side := minf(size.y - label_room - 6.0, 38.0)
	var at := Vector2((size.x - side) * 0.5, 4.0)
	draw_texture_rect(_icon, Rect2(at, Vector2(side, side)), false)
	var w := font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var text_at := Vector2((size.x - w) * 0.5, size.y - 6.0)
	draw_string(font, text_at, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiKit.INK)
