class_name AvatarView
extends SubViewportContainer
## A 3D hero on the menus, with live particles, in its own little world. Used on Home and in the shop.

var avatar: Avatar3D
var fx: FxField
var preview_slot := ""
var _viewport: SubViewport
var _camera: Camera3D
var _pad: MeshInstance3D
var _spin := 0.0
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


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func _ready() -> void:
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_DISABLED if Quality.is_low() else Viewport.MSAA_2X
	_viewport.handle_input_locally = false
	add_child(_viewport)
	var world := Node3D.new()
	_viewport.add_child(world)
	_camera = Camera3D.new()
	_camera.fov = 26.0
	_camera.position = Vector3(0, 1.75, _distance + 0.5)
	world.add_child(_camera)
	_camera.look_at(Vector3(0, _height, 0))
	var kit := MeshKit.new()
	kit.outline = 0.05
	kit.cyl(Vector3(0, -0.3, 0), 0.3, 1.3, 1.25, Color("ffd23f"), 24)
	kit.outline = 0.0
	kit.cyl(Vector3(0, 0.002, 0), 0.01, 1.05, 1.05, Color("ff9d2e"), 24)
	_pad = MeshInstance3D.new()
	_pad.mesh = kit.to_mesh()
	_pad.material_override = Avatar3D._material("normal")
	world.add_child(_pad)
	avatar = Avatar3D.new()
	world.add_child(avatar)
	fx = FxField.new(120)
	fx.density = 0.6 if Quality.is_low() else 1.0
	world.add_child(fx)
	if not _look.is_empty():
		avatar.setup(_look, ArenaBuilder.team_color(0))
	avatar.rotation.y = _yaw


## Where the camera goes for each kind of item, so you see what you're choosing: distance, height.
const FOCUS := {
	"mask": [3.0, 1.2], "hat": [3.5, 1.42], "top": [3.9, 0.72], "gloves": [3.9, 0.7], "pants": [3.3, 0.36],
	"shoes": [2.8, 0.2], "back": [4.6, 0.85],
}


func set_look(look: Dictionary, slot := "") -> void:
	var same := look == _look
	_look = look.duplicate()
	preview_slot = slot
	var focus: Array = FOCUS.get(slot, [6.2, 0.82])
	_want_distance = focus[0]
	_want_height = focus[1]
	_yaw_locked = slot in ["mask", "hat", "back", "shoes", "pants", "top", "gloves"]
	_want_yaw = PI + 0.5 if slot == "back" else 0.42
	if slot != "":
		_auto_yaw = not _yaw_locked
	if avatar == null:
		return
	if not same:
		avatar.setup(_look, ArenaBuilder.team_color(0))
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


func show_emote(text: String) -> void:
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
	if avatar == null:
		return
	if _dragging:
		pass
	elif _yaw_locked:
		_yaw = lerp_angle(_yaw, _want_yaw + sin(Time.get_ticks_msec() * 0.0012) * 0.22, clampf(delta * 5.0, 0.0, 1.0))
	elif _auto_yaw:
		_yaw += delta * (1.4 if preview_slot in ["trail", "run"] else 0.35)
	avatar.rotation.y = _yaw
	_distance = lerpf(_distance, _want_distance, clampf(delta * 5.0, 0.0, 1.0))
	_height = lerpf(_height, _want_height, clampf(delta * 5.0, 0.0, 1.0))
	_camera.position = Vector3(0, _height + 0.14 * _distance, _distance + 0.5)
	_camera.look_at(Vector3(0, _height, 0))
	var moving := preview_slot in ["trail", "run"]
	avatar.emit_effects(fx, delta, moving)
	if preview_slot == "burst":
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_burst_timer = 1.4
			var def := Cosmetics.item("burst", _look.get("burst", ""))
			if not def.is_empty():
				fx.burst(Vector3(0, 1.0, 0.4), 22, 3.0, 0.7, 0.26, int(def["fx"]), def["c"], 3.0)


## Drag to turn the hero round.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		_auto_yaw = false
	elif event is InputEventMouseMotion and _dragging:
		_yaw += event.relative.x * 0.012
	elif event is InputEventScreenTouch:
		_dragging = event.pressed
		_auto_yaw = false
	elif event is InputEventScreenDrag:
		_yaw += event.relative.x * 0.012
