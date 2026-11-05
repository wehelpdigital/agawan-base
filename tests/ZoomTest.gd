extends Node
## Opens the shop, tries items on, and zooms with real clicks, the wheel and a two-finger pinch:
##   godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1280x720 res://tests/ZoomTest.tscn
##       -- --out=<dir> --tag=desktop [--device=phone_portrait]

var _out := "user://zoom"
var _tag := "zoom"
var _main: Node
var _failed := 0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
	DirAccess.make_dir_recursive_absolute(_out)
	Profile.tutorial_done = true
	Profile.daily_day = Time.get_date_string_from_system()
	_main = load("res://scenes/Main.gd").new()
	add_child(_main)
	_run.call_deferred()


func _run() -> void:
	await _wait(0.6)
	var ui: UiRoot = _main.ui
	ui.show_screen("shop", {})
	await _wait(0.8)
	var shop: Control = ui.find_children("*", "Control", true, false).filter(func(c: Node) -> bool: return c.has_method("_on_card"))[0]
	var view: AvatarView = shop._avatar
	_check("starts on the whole avatar", is_equal_approx(view.zoom_level(), 0.0))
	shop._on_card("mask", "bandana")
	await _wait(0.9)
	await _shot("1_worn_close")
	_check("trying a mask on goes in close", is_equal_approx(view.zoom_level(), 1.0))
	var close: float = view._want_distance
	var out_button: Control = view.find_child("ZoomOut", true, false)
	var in_button: Control = view.find_child("ZoomIn", true, false)
	_check("zoom buttons exist", out_button != null and in_button != null)
	for i in 3:
		await _click(out_button)
	await _wait(0.9)
	await _shot("2_zoomed_out")
	_check("the zoom out button zooms out", view._want_distance > close * 1.5 and view.zoom_level() <= 0.0)
	var chosen: float = view.zoom_level()
	shop._on_card("mask", "panda")
	await _wait(0.5)
	_check("wearing something else stays zoomed out", is_equal_approx(view.zoom_level(), chosen))
	shop._on_card("hat", "sombrero")
	await _wait(0.9)
	await _shot("3_still_out_with_a_hat")
	_check("so does changing to another kind of item", is_equal_approx(view.zoom_level(), chosen))
	var whole: float = view._want_distance
	var before_click := view.zoom_level()
	await _click(out_button)
	print("  zoom %.2f -> %.2f, distance %.2f -> %.2f, view %s" % [before_click, view.zoom_level(), whole, view._want_distance, view.size])
	_check("it can go past the whole avatar, for the widest things", view.zoom_level() < before_click and view._want_distance > whole)
	var far: float = view._want_distance
	await _click(in_button)
	await _click(in_button)
	_check("the zoom in button zooms in", view._want_distance < far)
	await _wheel(view, MOUSE_BUTTON_WHEEL_DOWN)
	var after_wheel: float = view._want_distance
	await _wheel(view, MOUSE_BUTTON_WHEEL_UP)
	_check("the wheel zooms", view._want_distance < after_wheel)
	_pinch(view, 120.0, 260.0)
	var after_pinch_in: float = view.zoom_level()
	_pinch(view, 260.0, 120.0)
	_check("two fingers zoom", view.zoom_level() < after_pinch_in)
	_check("two fingers don't also turn the avatar", absf(view._yaw - view.avatar.rotation.y) < 0.2)
	# Turning the avatar by hand keeps that view instead of swinging back.
	shop._on_card("hat", "tophat")
	await _wait(0.4)
	var at := view.get_global_rect().get_center() + Vector2(0, -40)
	_send_button(at, true, MOUSE_BUTTON_LEFT)
	var motion := InputEventMouseMotion.new()
	var scale_now := get_viewport().get_final_transform().get_scale().x
	motion.position = get_viewport().get_final_transform() * (at + Vector2(150, 0))
	motion.global_position = motion.position
	motion.relative = Vector2(150, 0) * scale_now
	Input.parse_input_event(motion)
	await get_tree().process_frame
	_send_button(at + Vector2(150, 0), false, MOUSE_BUTTON_LEFT)
	await _wait(0.2)
	var turned: float = view._yaw
	await _wait(1.0)
	await _shot("4_turned")
	_check("a turned avatar stays turned", absf(view._yaw - turned) < 0.01)
	# A mask and a hat that can't go together: trying one on takes the other off.
	Profile.owned[Cosmetics.key("hat", "astronaut")] = true
	Profile.owned[Cosmetics.key("mask", "panda")] = true
	Profile.equip("mask", "panda")
	shop._on_card("hat", "astronaut")
	await _wait(0.3)
	_check("trying on a helmet takes the mask off in the preview", shop._preview["mask"] == "")
	shop._on_action()
	_check("wearing it takes the mask off for real", Profile.look["hat"] == "astronaut" and Profile.look["mask"] == "")
	# A mask would hide the face you're trying on, so wearing a face takes it off.
	Profile.equip("hat", "")
	Profile.equip("mask", "shades")
	shop._group = "wear"
	shop._slot = "face"
	shop._after_tab()
	await _wait(0.5)
	Profile.owned[Cosmetics.key("face", "love")] = true
	shop._on_card("face", "love")
	await _wait(0.2)
	_check("trying on a face takes the mask off in the preview", shop._preview["mask"] == "")
	await _wait(0.8)
	await _shot("5_faces")
	shop._on_action()
	_check("wearing a face takes the mask off for real", Profile.look["face"] == "love" and Profile.look["mask"] == "")
	var tapped: String = view.avatar._face_for_state()
	_send_button(view.get_global_rect().get_center() + Vector2(0, -40), true, MOUSE_BUTTON_LEFT)
	await get_tree().process_frame
	_send_button(view.get_global_rect().get_center() + Vector2(0, -40), false, MOUSE_BUTTON_LEFT)
	await get_tree().process_frame
	_check("tapping the avatar pulls a silly face", view.avatar._face_for_state() != tapped)
	for file in DirAccess.get_files_at("user://"):
		if file.begins_with("profile"):
			DirAccess.remove_absolute("user://" + file)
	print("zoom test: %s" % ("PASS" if _failed == 0 else "%d FAILED" % _failed))
	get_tree().quit(1 if _failed > 0 else 0)


func _check(what: String, ok: bool) -> void:
	print("  %s %s" % ["ok  " if ok else "FAIL", what])
	if not ok:
		_failed += 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	await RenderingServer.frame_post_draw


func _shot(label: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [_out, _tag, label])


func _click(control: Control) -> void:
	var at := control.get_global_rect().get_center()
	_send_button(at, true, MOUSE_BUTTON_LEFT)
	await get_tree().process_frame
	_send_button(at, false, MOUSE_BUTTON_LEFT)
	await get_tree().process_frame
	await get_tree().process_frame


func _wheel(control: Control, button: MouseButton) -> void:
	var at := control.get_global_rect().get_center()
	_send_button(at, true, button)
	await get_tree().process_frame
	_send_button(at, false, button)
	await get_tree().process_frame


## Takes a position in the interface's own coordinates, and sends it the way a real click arrives: in the window's.
func _send_button(at: Vector2, pressed: bool, button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.position = get_viewport().get_final_transform() * at
	event.global_position = event.position
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


## Two fingers moving apart or together, as the view receives them.
func _pinch(view: AvatarView, from_gap: float, to_gap: float) -> void:
	var center := view.size * 0.5
	for index in 2:
		var touch := InputEventScreenTouch.new()
		touch.index = index
		touch.pressed = true
		touch.position = center + Vector2(-from_gap * 0.5 if index == 0 else from_gap * 0.5, 0)
		view._gui_input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.position = center + Vector2(to_gap - from_gap * 0.5, 0)
	drag.relative = Vector2(to_gap - from_gap, 0)
	view._gui_input(drag)
	for index in 2:
		var touch := InputEventScreenTouch.new()
		touch.index = index
		touch.pressed = false
		view._gui_input(touch)
