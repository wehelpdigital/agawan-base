extends Control
## The first thing you see. The tap here is also what browsers need before they allow sound.

var root: UiRoot
var args: Dictionary
var screen_name: String
var _tap: Label
var _logo: TextureRect
var _clock := 0.0
var _left := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var view := size
	var col := UiKit.vbox(10)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	var logo_w := minf(view.x * 0.86, 760.0)
	var logo_h := minf(view.y * 0.62, logo_w * 0.6)
	_logo = UiKit.image("res://assets/brand/logo.png", Vector2(logo_w, logo_h))
	_logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(_logo)
	_tap = UiKit.title("TAP TO PLAY", 34 if not root.compact else 26)
	_tap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_tap)
	var note := UiKit.label("5 vs 5 tag, from the Filipino game of Agawan Base", 16 if root.phone_narrow else 18, Color(1, 1, 1, 0.85))
	note.add_theme_color_override("font_outline_color", UiKit.INK)
	note.add_theme_constant_override("outline_size", 5)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(note)
	_logo.pivot_offset = Vector2(logo_w, logo_h) * 0.5
	_logo.scale = Vector2.ONE * 0.6
	create_tween().tween_property(_logo, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_clock += delta
	if _tap:
		_tap.modulate.a = 0.65 + sin(_clock * 4.0) * 0.35
	if _logo:
		_logo.rotation = sin(_clock * 1.3) * 0.012


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_go()


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed) or (event is InputEventJoypadButton and event.pressed):
		_go()


func _go() -> void:
	if _left:
		return
	_left = true
	Audio.sfx("ui_confirm")
	Audio.music("menu")
	if not Profile.tutorial_done:
		root.show_screen("howto", {"first": true})
	else:
		root.show_screen("home")
