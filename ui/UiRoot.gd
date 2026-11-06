class_name UiRoot
extends Control
## Screen manager: the background, the top bar and bottom tabs, toasts and pop-ups. Every screen is built
## from code and rebuilt when the window changes shape (upright to sideways, phone to desktop).

signal screen_shown(screen_name: String)

const TABS := [
	{"id": "shop", "name": "Shop", "icon": "shop"},
	{"id": "locker", "name": "Locker", "icon": "mask"},
	{"id": "home", "name": "Play", "icon": "play"},
	{"id": "ranks", "name": "Ranks", "icon": "rank"},
	{"id": "guild", "name": "Guild", "icon": "guild"},
	{"id": "chat", "name": "Chat", "icon": "chat"},
]
const SCREENS := {
	"title": "res://ui/screens/TitleScreen.gd",
	"home": "res://ui/screens/HomeScreen.gd",
	"shop": "res://ui/screens/ShopScreen.gd",
	"locker": "res://ui/screens/ShopScreen.gd",
	"maps": "res://ui/screens/MapsScreen.gd",
	"room": "res://ui/screens/RoomScreen.gd",
	"ranks": "res://ui/screens/RanksScreen.gd",
	"guild": "res://ui/screens/GuildScreen.gd",
	"chat": "res://ui/screens/ChatScreen.gd",
	"profile": "res://ui/screens/ProfileScreen.gd",
	"settings": "res://ui/screens/SettingsScreen.gd",
	"howto": "res://ui/screens/HowToScreen.gd",
	"powers": "res://ui/screens/PowersScreen.gd",
	"results": "res://ui/screens/ResultsScreen.gd",
	"credits": "res://ui/screens/CreditsScreen.gd",
}
const WITH_TABS := ["home", "shop", "locker", "ranks", "guild", "chat"]

static var instance: UiRoot

var main: Node
var current_name := ""
var current_args: Dictionary = {}
var portrait := false
var compact := false
var phone_narrow := false

var _bg: ColorRect
var _bg_mat: ShaderMaterial
var _content: Control
var _screen: Control
var _top_bar: TopBar
var _tabs: Control
var _toasts: VBoxContainer
var _overlay: Control
var _back_stack: Array[Dictionary] = []
var _insets := Vector4.ZERO
var _chat_dot: Panel
var _shape_key := ""


func _init() -> void:
	instance = self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	_bg = ColorRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_mat = ShaderMaterial.new()
	_bg_mat.shader = preload("res://gfx/shaders/sky.gdshader")
	_bg.material = _bg_mat
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_content = Control.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	_top_bar = TopBar.new()
	add_child(_top_bar)
	_tabs = Control.new()
	_tabs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tabs)
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	_toasts = UiKit.vbox(6)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.alignment = BoxContainer.ALIGNMENT_END
	add_child(_toasts)
	get_viewport().size_changed.connect(_on_resize)
	_on_resize()


func _on_resize() -> void:
	UiScale.apply(get_tree())
	Quality.apply(get_tree())
	var view := get_viewport_rect().size
	_insets = SafeInsets.get_insets(get_tree())
	portrait = view.y > view.x * 1.05
	compact = view.y < 560.0
	phone_narrow = view.x < 520.0
	_bg_mat.set_shader_parameter("aspect", view.x / maxf(view.y, 1.0))
	var key := "%s|%s|%s" % [portrait, compact, phone_narrow]
	var changed := key != _shape_key
	_shape_key = key
	_layout_frame()
	if changed and current_name != "":
		_rebuild_current()


func _layout_frame() -> void:
	var view := get_viewport_rect().size
	var with_tabs := WITH_TABS.has(current_name)
	var with_top := current_name != "title" and current_name != "results"
	var top_h := (56.0 if compact else 66.0) if with_top else 0.0
	var tab_h := (56.0 if compact else 76.0) if with_tabs else 0.0
	var left := _insets.x
	var right := view.x - _insets.z
	var top := _insets.y
	var bottom := view.y - _insets.w
	_top_bar.visible = with_top
	_top_bar.position = Vector2(left, top)
	_top_bar.size = Vector2(right - left, top_h)
	_tabs.visible = with_tabs
	_tabs.position = Vector2(left, bottom - tab_h)
	_tabs.size = Vector2(right - left, tab_h)
	_content.position = Vector2(left, top + top_h)
	_content.size = Vector2(right - left, bottom - top - top_h - tab_h)
	if _screen:
		_screen.size = _content.size
	_toasts.position = Vector2((view.x - minf(view.x - 20.0, 520.0)) * 0.5, top + top_h + 6.0)
	_toasts.size = Vector2(minf(view.x - 20.0, 520.0), 0)
	if with_tabs:
		_build_tabs()
	if with_top:
		_top_bar.layout_for(compact, phone_narrow)


func _build_tabs() -> void:
	for child in _tabs.get_children():
		child.queue_free()
	var bar := Panel.new()
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := UiKit.style(UiKit.PAPER, 0)
	box.border_width_top = 4
	box.border_color = Color("a9d6ff")
	box.shadow_color = Color(UiKit.INK, 0.25)
	box.shadow_size = 6
	box.shadow_offset = Vector2(0, -2)
	bar.add_theme_stylebox_override("panel", box)
	_tabs.add_child(bar)
	var row := UiKit.hbox(4)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 4
	row.offset_right = -4
	row.offset_top = 6
	row.offset_bottom = -4
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_tabs.add_child(row)
	var max_w := 110.0
	for tab: Dictionary in TABS:
		var id: String = tab["id"]
		var on := id == current_name
		var b := TabButton.new()
		b.setup(tab["name"], tab["icon"], on, compact, id == "home")
		b.custom_minimum_size = Vector2(0, 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL if phone_narrow else Control.SIZE_SHRINK_CENTER
		if not phone_narrow:
			b.custom_minimum_size.x = max_w
		b.pressed.connect(func() -> void: open_tab(id))
		row.add_child(b)


func open_tab(id: String) -> void:
	if id == current_name:
		return
	Audio.sfx("ui_tab")
	_back_stack.clear()
	show_screen(id)


## Shows a screen. `remember` puts the current one on the back stack, so go_back() can return to it.
func show_screen(screen_name: String, args := {}, remember := false) -> void:
	if remember and current_name != "":
		_back_stack.append({"name": current_name, "args": current_args})
	current_name = screen_name
	current_args = args
	_rebuild_current()
	screen_shown.emit(screen_name)


func go_back() -> void:
	Audio.sfx("ui_back")
	if _back_stack.is_empty():
		show_screen("home")
		return
	var entry: Dictionary = _back_stack.pop_back()
	show_screen(entry["name"], entry["args"])


func _rebuild_current() -> void:
	_layout_frame()
	if _screen:
		_screen.queue_free()
		_screen = null
	var script: GDScript = load(SCREENS[current_name])
	_screen = script.new()
	_screen.set("root", self)
	_screen.set("args", current_args)
	_screen.set("screen_name", current_name)
	_screen.size = _content.size
	_content.add_child(_screen)
	_top_bar.refresh()
	_screen.modulate.a = 0.0
	_screen.scale = Vector2(0.985, 0.985)
	var tween := create_tween().set_parallel()
	tween.tween_property(_screen, "modulate:a", 1.0, 0.12)
	tween.tween_property(_screen, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func hide_all() -> void:
	visible = false


func show_all() -> void:
	visible = true


# --- Toasts and pop-ups ---------------------------------------------------------------------------

func toast(text: String, color := UiKit.WHITE) -> void:
	var pill := PanelContainer.new()
	var box := UiKit.card_style(UiKit.INK, 16, 3)
	pill.add_theme_stylebox_override("panel", box)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := UiKit.body(text, 18, color)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(line)
	_toasts.add_child(pill)
	pill.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(pill, "modulate:a", 1.0, 0.12)
	tween.tween_interval(2.4)
	tween.tween_property(pill, "modulate:a", 0.0, 0.25)
	tween.tween_callback(pill.queue_free)


## A pop-up with a dimmed background. Returns its content box; add what you need, then call close_popup.
func popup(title_text: String, wide := false) -> VBoxContainer:
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.02, 0.18, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(dim)
	var view := get_viewport_rect().size
	var width := minf(view.x - 24.0, 720.0 if wide else 460.0)
	var holder := CenterContainer.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(holder)
	var card := UiKit.panel(UiKit.SKY, 26, 5)
	card.custom_minimum_size = Vector2(width, 0)
	holder.add_child(card)
	var col := UiKit.vbox(12)
	card.add_child(col)
	if title_text != "":
		var t := UiKit.title(title_text, 30 if not compact else 24, UiKit.YELLOW)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(t)
	card.pivot_offset = Vector2(width * 0.5, 120.0)
	card.scale = Vector2.ONE * 0.86
	create_tween().tween_property(card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.sfx("ui_open")
	col.set_meta("dim", dim)
	return col


func close_popup(col: Control) -> void:
	if col.has_meta("dim"):
		(col.get_meta("dim") as Node).queue_free()


func confirm(title_text: String, body_text: String, yes_text: String, on_yes: Callable, no_text := "Cancel", yes_kind := "green") -> void:
	var col := popup(title_text)
	var text := UiKit.body(body_text, 19)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(text)
	var row := UiKit.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if no_text != "":
		var no := UiKit.button(no_text, "ink", 20)
		no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		no.pressed.connect(func() -> void: close_popup(col))
		row.add_child(no)
	var yes := UiKit.button(yes_text, yes_kind, 20)
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(func() -> void:
		close_popup(col)
		on_yes.call())
	row.add_child(yes)
	col.add_child(row)


func _input(event: InputEvent) -> void:
	if not visible or _screen == null:
		return
	if (event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5)) and get_viewport().gui_get_focus_owner() == null:
		var first: Control = _screen.find_next_valid_focus()
		if first:
			first.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") and current_name not in ["home", "title", "results"]:
		go_back()
		get_viewport().set_input_as_handled()
