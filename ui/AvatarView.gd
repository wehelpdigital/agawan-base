class_name AvatarView
extends Control
## A 3D avatar on the menus, with live particles, in its own little world. It renders at the screen's real
## resolution, whatever the interface's scale, so it stays sharp on high-density phones.

## Where the camera goes for each kind of item, so you see what you're choosing: distance, height.
## Zooming moves between these and WHOLE, the whole avatar.
const WHOLE := [6.2, 0.82]
const FACE := [3.7, 1.1]
const ZOOM_OUT_MOST := -0.6  ## Past the whole avatar, for the widest hats and wings.
const FOCUS := {
	"face": [3.1, 1.08], "mask": [3.7, 1.1], "hat": [4.6, 1.42], "top": [3.6, 0.5], "gloves": [3.8, 0.45], "pants": [3.1, 0.28],
	"shoes": [2.7, 0.14], "back": [5.4, 0.8], "flag": [6.6, 1.1], "pet": [6.4, 0.8],
}
const MAX_SIDE := 1400.0
const PLANET_RADIUS := 3.4
const FACE_WIDTH := 0.7  ## How far an avatar's head goes out to each side.
const FOV := 26.0

var avatar: Avatar3D
var friends: PlayFriends  ## Only on the little world.
var pet: Pet3D
var fx: FxField
var preview_slot := ""
var zoomable := false  ## Shows zoom buttons, and lets the wheel and a pinch zoom too.
var planet := false  ## Stands on a little turning world, not a patch of grass. Set before it's added.
## If set, the picture is drawn here, behind the rest of the screen and wider than this view, so a big planet doesn't
## end in a straight line. Set before it's added.
var backdrop: Control
var _drawn := Rect2()
var _viewport: SubViewport
var _picture: TextureRect
var _camera: Camera3D
var _pad: MeshInstance3D
var _dragging := false
var _burst_timer := 0.0
var _look: Dictionary = {}
var _emote: Label3D
var _yaw := 0.3
var _distance := 6.2
var _height := 0.82
var _auto_yaw := true
var _want_distance := 6.2
var _want_height := 0.82
var _want_yaw := 0.3
var _yaw_locked := false
var _focus: Array = FACE
var _zoom := -2.0  ## From ZOOM_OUT_MOST to 1, whole avatar at 0 and close up at 1. Until it's used, it follows the item.
var _touches := {}
var _pinch := 0.0
var _turned := false
var _bubble: PanelContainer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip_contents = true


func _ready() -> void:
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_viewport)
	_picture = TextureRect.new()
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_SCALE
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picture.texture = _viewport.get_texture()
	if backdrop:
		backdrop.add_child(_picture)
	else:
		_picture.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_picture)
	var world := Node3D.new()
	_viewport.add_child(world)
	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.position = Vector3(0, 1.75, _distance + 0.5)
	world.add_child(_camera)
	_camera.look_at(Vector3(0, _height, 0))
	var kit := MeshKit.new()
	kit.soften = true
	kit.shells = false
	kit.outline = 0.0
	kit.ball(Vector3(0, -0.14, 0), Vector3(1.32, 0.16, 1.32), Color("5cc94f"), 12, 40)
	kit.ball(Vector3(0, 0.0, 0), Vector3(1.04, 0.022, 1.04), Color("9be36a"), 8, 40)
	if planet:
		var stage := WorldStage.new()
		world.add_child(stage)
		stage.setup(PLANET_RADIUS)
		stage.spin_speed = 0.11
	else:
		_pad = MeshInstance3D.new()
		_pad.mesh = kit.to_mesh()
		_pad.material_override = Avatar3D._material("normal")
		world.add_child(_pad)
	avatar = Avatar3D.new()
	world.add_child(avatar)
	avatar.gag_started.connect(_say)
	pet = Pet3D.new()
	pet.position = Vector3(0.82, 0, 0.28)
	pet.rotation.y = -0.55
	world.add_child(pet)
	avatar.calm = preview_slot == "face"
	fx = FxField.new(120)
	fx.density = 0.6 if Quality.is_low() else 1.0
	world.add_child(fx)
	if planet:
		friends = PlayFriends.new()
		world.add_child(friends)
		friends.setup(PLANET_RADIUS, fx, avatar)
		friends.said.connect(_say_at)
		avatar.gag_started.connect(func(_line: String) -> void: friends.cheer())
	if not _look.is_empty():
		avatar.setup(_look, ArenaBuilder.team_color(0))
		pet.setup(str(_look.get("pet", "")))
	avatar.rotation.y = _yaw
	resized.connect(_fit_viewport)
	resized.connect(_apply_zoom)
	get_viewport().size_changed.connect(_fit_viewport)
	_fit_viewport()
	if zoomable:
		_add_zoom_buttons()
	_apply_zoom()


## One picture pixel per screen pixel: the interface's scale must not make the avatar blurry.
func _fit_viewport() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	_drawn = _drawn_rect()
	if backdrop:
		_picture.position = _drawn.position
		_picture.size = _drawn.size
	var scale_now := get_viewport().get_final_transform().get_scale()
	var wanted := _drawn.size * scale_now
	var longest := maxf(wanted.x, wanted.y)
	if longest > MAX_SIDE:
		wanted *= MAX_SIDE / longest
	_viewport.size = Vector2i(ceili(wanted.x), ceili(wanted.y))


## Where the picture goes: over this view or, on a backdrop, centred on it and reaching out to the edge of the screen or
## the end of the planet, whichever comes first. The camera keeps its height, so a wider picture only shows more.
func _drawn_rect() -> Rect2:
	if backdrop == null:
		return Rect2(Vector2.ZERO, size)
	var at: Vector2 = backdrop.get_global_transform().affine_inverse() * get_global_position()
	var reach := maxf(at.x, backdrop.size.x - at.x - size.x)
	reach = clampf(reach, 0.0, maxf(size.y * 1.4 - size.x * 0.5, 0.0))
	return Rect2(at.x - reach, at.y, size.x + reach * 2.0, size.y)


func set_look(look: Dictionary, slot := "") -> void:
	var same := look == _look
	_look = look.duplicate()
	var same_slot := slot == preview_slot
	preview_slot = slot
	_focus = FOCUS.get(slot, FACE)
	_apply_zoom()
	if not (same_slot and _turned):  # Having turned the avatar to look at something, you keep that view.
		_turned = false
		_yaw_locked = slot in ["face", "mask", "hat", "back", "flag", "shoes", "pants", "top", "gloves"]
		_want_yaw = PI + 0.5 if slot == "back" else (PI - 0.7 if slot == "flag" else 0.42)
		if slot != "":
			_auto_yaw = not _yaw_locked
	if avatar == null:
		return
	avatar.calm = slot == "face"
	if not same:
		avatar.setup(_look, ArenaBuilder.team_color(0))
		pet.setup(str(_look.get("pet", "")))
		if slot == "pet":
			pet.cheer(0.9)
	_apply_preview()


func _apply_preview() -> void:
	avatar.state = "idle"
	avatar.moving = 0.0
	match preview_slot:
		"trail", "run":
			avatar.state = "run"
			avatar.moving = 1.0
			avatar.run_id = _look.get("run", "")
		"dance":
			avatar.state = "dance"
			avatar.dance_id = _look.get("dance", "")
	_burst_timer = 0.2
	if _emote:
		_emote.queue_free()
		_emote = null


## A speech bubble for someone out on the world, over their head.
func _say_at(line: String, at: Vector3) -> void:
	if _viewport.size.x > 0 and not _camera.is_position_behind(at):
		var seen := _camera.unproject_position(at) / Vector2(_viewport.size)
		_say(line, seen * _drawn.size - Vector2((_drawn.size.x - size.x) * 0.5, 0))


## A little speech bubble for a moment: at the top of the picture, or with its bottom middle on this spot.
func _say(line: String, spot := Vector2(-1, -1)) -> void:
	if line == "" or not is_inside_tree() or size.x < 80.0:
		return
	if is_instance_valid(_bubble):
		_bubble.queue_free()
	_bubble = PanelContainer.new()
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := UiKit.style(UiKit.PAPER, 12, 3, UiKit.INK)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 3
	box.content_margin_bottom = 4
	_bubble.add_theme_stylebox_override("panel", box)
	var text := UiKit.label(line, 15, UiKit.INK, 0, true)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if UiKit.font_title().get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 26.0 > size.x:
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size.x = size.x - 26.0
	_bubble.add_child(text)
	add_child(_bubble)
	_bubble.reset_size()
	var wide := _bubble.get_combined_minimum_size()
	_bubble.size = wide
	_bubble.position = Vector2((size.x - wide.x) * 0.5, 6.0)
	if spot.y >= 0.0:  # Over their head if that keeps it off your avatar's face; if not, up at the top after all.
		var face := FACE_WIDTH * size.y / (2.0 * (_want_distance + 0.5) * tan(deg_to_rad(FOV * 0.5)))
		if size.x * 0.5 - face >= wide.x:
			var left := spot.x - wide.x * 0.5
			var x := maxf(left, size.x * 0.5 + face) if spot.x > size.x * 0.5 else minf(left, size.x * 0.5 - face - wide.x)
			_bubble.position = Vector2(clampf(x, 0.0, size.x - wide.x), maxf(spot.y - wide.y, 0.0))
	_bubble.pivot_offset = wide * 0.5
	_bubble.scale = Vector2.ONE * 0.6
	var shown := _bubble
	var tween := create_tween()
	tween.tween_property(shown, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.7)
	tween.tween_property(shown, "modulate:a", 0.0, 0.25)
	tween.tween_callback(shown.queue_free)


func show_emote(text: String) -> void:
	avatar.react(Faces.funny(), 2.0)
	if _emote:
		_emote.queue_free()
	_emote = Label3D.new()
	_emote.text = text
	_emote.font = UiKit.font_title()
	_emote.font_size = 64
	_emote.outline_size = 18
	_emote.pixel_size = 0.008
	_emote.outline_modulate = UiKit.INK
	_emote.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_emote.position = Vector3(0, 2.25, 0)
	avatar.get_parent().add_child(_emote)


func _process(delta: float) -> void:
	if backdrop and not _drawn_rect().is_equal_approx(_drawn):
		_fit_viewport()
	if avatar == null:
		return
	if _dragging:
		pass
	elif _yaw_locked:
		_yaw = lerp_angle(_yaw, _want_yaw + sin(Time.get_ticks_msec() * 0.0012) * 0.22, clampf(delta * 5.0, 0.0, 1.0))
	elif _auto_yaw and preview_slot in ["trail", "run"]:
		_yaw += delta * 1.4
	elif _auto_yaw:  # Left alone, it sways a little and keeps looking at you.
		_yaw = lerp_angle(_yaw, sin(Time.get_ticks_msec() * 0.00045) * 0.38, clampf(delta * 3.0, 0.0, 1.0))
	avatar.rotation.y = _yaw
	pet.idle(delta)
	_distance = lerpf(_distance, _want_distance, clampf(delta * 5.0, 0.0, 1.0))
	_height = lerpf(_height, _want_height, clampf(delta * 5.0, 0.0, 1.0))
	_camera.position = Vector3(0, _height + 0.14 * _distance, _distance + 0.5)
	_camera.look_at(Vector3(0, _height, 0))
	avatar.emit_effects(fx, delta, preview_slot in ["trail", "run"])
	if preview_slot == "burst":
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_burst_timer = 1.4
			var def := Cosmetics.item("burst", _look.get("burst", ""))
			if not def.is_empty():
				fx.burst(Vector3(0, 1.0, 0.4), 22, 3.0, 0.7, 0.26, int(def["fx"]), def["c"], 3.0)


## How close the camera is right now: what you zoomed to, or else what suits the item.
func zoom_level() -> float:
	if _zoom >= ZOOM_OUT_MOST:
		return _zoom
	return 1.0 if FOCUS.has(preview_slot) else 0.0


func zoom_by(amount: float) -> void:
	_zoom = clampf(zoom_level() + amount, ZOOM_OUT_MOST, 1.0)
	_apply_zoom()


func _apply_zoom() -> void:
	var t := zoom_level()
	# A narrow picture needs the camera further back to get the whole width across it.
	var fit: float = maxf(0.95 / maxf(size.x / maxf(size.y, 1.0), 0.1), 1.0) if size.y > 0.0 else 1.0
	var whole: float = WHOLE[0] * fit * (1.22 if planet else 1.0)
	if t >= 0.0:
		_want_distance = lerpf(whole, float(_focus[0]) * fit, t)
		_want_height = lerpf(WHOLE[1], _focus[1], t)
	else:
		_want_distance = whole * (1.0 - t)
		_want_height = WHOLE[1]
	# How much of the world shows to each side of the avatar. The picture may go wider, but that part's under the buttons.
	if friends and size.y > 0.0:
		friends.set_room(size.x / size.y * (_want_distance + 0.5) * tan(deg_to_rad(FOV * 0.5)))


func _add_zoom_buttons() -> void:
	var row := UiKit.hbox(6)
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	row.offset_right = -4
	row.offset_bottom = -4
	add_child(row)
	for step: Dictionary in [{"text": "-", "by": -0.34, "name": "ZoomOut"}, {"text": "+", "by": 0.34, "name": "ZoomIn"}]:
		var b := UiKit.button(step["text"], "ink", 24)
		b.name = step["name"]
		b.custom_minimum_size = Vector2(44, 44)
		b.tooltip_text = "Zoom out" if step["by"] < 0.0 else "Zoom in"
		var by: float = step["by"]
		b.pressed.connect(func() -> void: zoom_by(by))
		row.add_child(b)


## Drag to turn the avatar round; a tap sets off its own gag. The wheel or two fingers zoom.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if zoomable and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_by(0.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -0.12)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			_auto_yaw = false
			if event.pressed and avatar:
				avatar.play_gag()
	elif event is InputEventMouseMotion and _dragging:
		if _touches.size() < 2:
			_turn(event.relative.x)
	elif event is InputEventMagnifyGesture:
		if zoomable:
			zoom_by((event.factor - 1.0) * 1.2)
			accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		_pinch = _touch_gap()
		_dragging = event.pressed
		_auto_yaw = false
		if event.pressed and avatar:
			avatar.play_gag()
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() >= 2:
			var gap := _touch_gap()
			if zoomable and _pinch > 0.0:
				zoom_by((gap - _pinch) * 0.006)
			_pinch = gap
		else:
			_turn(event.relative.x)


func _turn(pixels: float) -> void:
	_yaw += pixels * 0.012
	if absf(pixels) > 0.5:
		_turned = true
		_yaw_locked = false
		_auto_yaw = false


func _touch_gap() -> float:
	if _touches.size() < 2:
		return 0.0
	var points: Array = _touches.values()
	return (points[0] as Vector2).distance_to(points[1])
