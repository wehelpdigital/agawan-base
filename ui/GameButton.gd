class_name GameButton
extends BaseButton
## A glossy plastic toy of a button: a white rim, a thick lip below, and a shine across the top. It sinks into
## its lip when pressed, and works with mouse, touch, keyboard and controller focus.

const LIP := 7.0
const OUTLINE := 4.0

var kind := "yellow"
var radius := 18.0
var _row: HBoxContainer
var _label: Label
var _icon: TextureRect
var _colors: Dictionary = UiKit.BUTTON_COLORS["yellow"]
var _font_size := 24
var _bounce := 1.0
var _tween: Tween
var _text := ""
var _box_lip := StyleBoxFlat.new()
var _box_body := StyleBoxFlat.new()
var _box_gloss := StyleBoxFlat.new()
var _box_ink := StyleBoxFlat.new()
var _box_focus := StyleBoxFlat.new()


func setup(text: String, p_kind := "yellow", font_size := 24, icon_name := "") -> void:
	_font_size = font_size
	_text = text
	_row = UiKit.hbox(8)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	if icon_name != "":
		_icon = UiKit.icon(icon_name, font_size * 1.25)
		_row.add_child(_icon)
	if text != "":
		_make_label(text)
	set_kind(p_kind)
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_refresh_min()
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	pressed.connect(_on_pressed)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	resized.connect(_layout_row)
	toggled.connect(func(_on: bool) -> void: queue_redraw())
	_box_ink.corner_detail = 6
	_box_lip.corner_detail = 6
	_box_body.corner_detail = 6
	_box_gloss.corner_detail = 6
	_box_gloss.bg_color = Color(1, 1, 1, 0.28)
	_box_focus.draw_center = false
	_box_focus.border_color = Color.WHITE
	_box_focus.set_border_width_all(3)


func _make_label(text: String) -> void:
	_label = UiKit.label(text, _font_size, Color.WHITE, 0, true)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_row.add_child(_label)


func set_kind(p_kind: String) -> void:
	kind = p_kind
	_colors = UiKit.BUTTON_COLORS.get(kind, UiKit.BUTTON_COLORS["yellow"])
	var text_color: Color = _colors["text"]
	if _label:
		_label.add_theme_color_override("font_color", text_color)
		if text_color == UiKit.WHITE:
			_label.add_theme_color_override("font_outline_color", (_colors["lip"] as Color).darkened(0.15))
			_label.add_theme_constant_override("outline_size", maxi(int(_font_size * 0.28), 5))
		else:
			_label.add_theme_constant_override("outline_size", 0)
	queue_redraw()


func set_text(text: String) -> void:
	_text = text
	if _label:
		_label.text = text
	elif text != "":
		_make_label(text)
		set_kind(kind)
	_refresh_min()


func get_text() -> String:
	return _text


func _refresh_min() -> void:
	var text_size := Vector2.ZERO
	if _label:
		text_size = UiKit.font_title().get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size)
	var icon_w: float = _font_size * 1.25 + (8.0 if _label else 0.0) if _icon else 0.0
	custom_minimum_size = Vector2(text_size.x + icon_w + _font_size * 1.5, maxf(_font_size * 1.6 + LIP + OUTLINE * 2.0, 48.0))


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW:
		_paint()
	elif what == NOTIFICATION_READY:
		_layout_row()


func _layout_row() -> void:
	if _row:
		var sink := LIP if button_pressed_look() else 0.0
		_row.position = Vector2(0, sink)
		_row.size = Vector2(size.x, size.y - LIP)


func button_pressed_look() -> bool:
	return get_draw_mode() == DRAW_PRESSED or get_draw_mode() == DRAW_HOVER_PRESSED


func _paint() -> void:
	var w := size.x
	var h := size.y
	var pressed_now := button_pressed_look()
	var sink := LIP - 2.0 if pressed_now else 0.0
	var body_top := sink
	var body_h := h - LIP
	var r := int(minf(radius, h * 0.45))
	var grey := disabled
	var low: Color = _colors["low"]
	var top: Color = _colors["top"]
	var lip: Color = _colors["lip"]
	if grey:
		low = Color("a9b8c8")
		top = Color("c6d2de")
		lip = Color("7f91a5")
	if is_hovered() and not grey and not pressed_now:
		top = top.lightened(0.08)
		low = low.lightened(0.08)
	# A soft shadow on the ground, then the white rim.
	_box_ink.bg_color = Color(UiKit.INK, 0.3)
	_box_ink.set_corner_radius_all(r + 2)
	draw_style_box(_box_ink, Rect2(0, body_top + 3.0, w, h - body_top))
	_box_ink.bg_color = Color("f3f9ff") if not grey else Color("dfe7ef")
	draw_style_box(_box_ink, Rect2(0, body_top, w, h - body_top))
	_box_lip.bg_color = lip
	_box_lip.set_corner_radius_all(r)
	draw_style_box(_box_lip, Rect2(OUTLINE, body_top + OUTLINE, w - OUTLINE * 2.0, h - body_top - OUTLINE * 2.0))
	_box_body.bg_color = low
	_box_body.set_corner_radius_all(r)
	var body_rect := Rect2(OUTLINE, body_top + OUTLINE, w - OUTLINE * 2.0, body_h - OUTLINE * 2.0 + 2.0 - (0.0 if not pressed_now else 0.0))
	draw_style_box(_box_body, body_rect)
	_box_gloss.bg_color = top
	_box_gloss.set_corner_radius_all(r)
	_box_gloss.corner_radius_bottom_left = int(r * 0.6)
	_box_gloss.corner_radius_bottom_right = int(r * 0.6)
	draw_style_box(_box_gloss, Rect2(body_rect.position, Vector2(body_rect.size.x, body_rect.size.y * 0.52)))
	# The shine: a soft bright bar along the top edge.
	if not grey and body_rect.size.y > 26.0:
		_box_gloss.bg_color = Color(1, 1, 1, 0.42)
		_box_gloss.set_corner_radius_all(int(r * 0.6))
		var inset := minf(r * 0.7, body_rect.size.x * 0.12)
		draw_style_box(_box_gloss, Rect2(body_rect.position + Vector2(inset, 3.0), Vector2(body_rect.size.x - inset * 2.0, maxf(body_rect.size.y * 0.15, 3.0))))
	if has_focus() and focus_mode != Control.FOCUS_NONE and Input.get_connected_joypads().size() > 0:
		_box_focus.set_corner_radius_all(r + 3)
		draw_style_box(_box_focus, Rect2(-3, body_top - 3, w + 6, h - body_top + 6))
	if _row:
		_row.position.y = sink
		_row.modulate = Color(1, 1, 1, 0.55) if grey else Color.WHITE


func _on_down() -> void:
	queue_redraw()
	_layout_row()
	_animate(0.96)


func _on_up() -> void:
	queue_redraw()
	_layout_row()
	_animate(1.0)


func _on_pressed() -> void:
	Audio.sfx("ui_click")


func _animate(to: float) -> void:
	pivot_offset = size * 0.5
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE * to, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
