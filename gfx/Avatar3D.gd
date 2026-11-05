class_name Avatar3D
extends Node3D
## A player's character: chunky toy proportions, drawn in code from Cosmetics.gd, animated in code
## (no skeleton, so it stays cheap on phones). Faces +Z. Meshes are shared between avatars that look
## the same, so ten players cost about sixty draw calls and no extra memory.

const HEAD_Y := 1.06
const HEAD_SHAPE := Vector3(1.3, 1.06, 1.12)  ## Big and wide on a tiny body: most of the cuteness. Masks and hats follow it.
const ARM_X := 0.31
const ARM_Y := 0.62
const FOOT_X := 0.16
const FOOT_Y := 0.09
static var _meshes := {}  # key -> ArrayMesh
static var _eye_info := {}  # Avatar key -> where its eyes are, for blinking.
static var _mat_normal: ShaderMaterial
static var _mat_ghost: ShaderMaterial
static var _mat_frozen: ShaderMaterial
static var _mat_flash: ShaderMaterial

var look: Dictionary = {}
var team_color := Color("ffffff")
var moving := 0.0  ## 0..1, how fast the legs go.
var state := "idle"  ## idle, run, dash, stun, freeze, root, jail, dance, sad, air
var dance_id := ""
var run_id := ""

var _hips: Node3D
var _head: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _foot_l: Node3D
var _foot_r: Node3D
var _back: Node3D
var _hat: Node3D
var _parts: Array[MeshInstance3D] = []
var _t := randf() * 10.0
var _emit := 0.0
var _orbit := randf() * TAU
var _flash := 0.0
var _squash := 0.0
var _material_kind := ""
var _trail: Dictionary = {}
var _aura: Dictionary = {}
var _trail_i := 0
var _hover_extra := 0.0
var _face: MeshInstance3D
var _face_key := ""
var _shown_face := ""
var _react := ""  ## A passing expression: a happy face after a tag, say.
var _react_left := 0.0
var _blink_wait := randf_range(1.0, 4.0)
var _blink_left := 0.0
var _eye_seen := {}


static func _material(kind: String) -> ShaderMaterial:
	if _mat_normal == null:
		_mat_normal = ShaderMaterial.new()
		_mat_normal.shader = preload("res://gfx/shaders/toon.gdshader")
		_mat_normal.set_shader_parameter("soft", 1.0)
		_mat_ghost = ShaderMaterial.new()
		_mat_ghost.shader = preload("res://gfx/shaders/ghost.gdshader")
		_mat_frozen = ShaderMaterial.new()
		_mat_frozen.shader = preload("res://gfx/shaders/toon.gdshader")
		_mat_frozen.set_shader_parameter("tint", Color(0.55, 0.85, 1.25))
		_mat_frozen.set_shader_parameter("soft", 1.0)
		_mat_flash = ShaderMaterial.new()
		_mat_flash.shader = preload("res://gfx/shaders/toon.gdshader")
		_mat_flash.set_shader_parameter("flash", 0.75)
		_mat_flash.set_shader_parameter("soft", 1.0)
	match kind:
		"ghost": return _mat_ghost
		"frozen": return _mat_frozen
		"flash": return _mat_flash
	return _mat_normal


func setup(p_look: Dictionary, p_team_color := Color("ffffff")) -> void:
	look = p_look
	team_color = p_team_color
	for child in get_children():
		child.queue_free()
	_parts.clear()
	_hips = Node3D.new()
	add_child(_hips)
	var hero := Cosmetics.item("char", look.get("char", "kiko"))
	if hero.is_empty():
		hero = Cosmetics.HEROES[0]
	var skin := Cosmetics.item("skin", look.get("skin", ""))
	var skin_key := "%s|%s" % [hero["id"], look.get("skin", "")]
	_add_part(_hips, _shared("body|" + skin_key, _build_body.bind(hero, skin)), Vector3.ZERO)
	_head = Node3D.new()
	_head.position = Vector3(0, HEAD_Y, 0)
	_head.scale = HEAD_SHAPE
	_hips.add_child(_head)
	_eye_seen = {}
	_add_part(_head, _shared("head|" + skin_key, _build_head.bind(hero, skin)), Vector3.ZERO)
	if not _eye_seen.is_empty():
		_eye_info[skin_key] = _eye_seen
	_face = null
	_face_key = skin_key
	_shown_face = ""
	if _eye_info.has(skin_key):
		_face = MeshInstance3D.new()
		_face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_head.add_child(_face)
		_parts.append(_face)
		_show_face("normal")
	var body_w := _clothes_width(hero)
	var top_id: String = look.get("top", "")
	if top_id != "":
		_add_part(_hips, _shared("top|%s|%.2f" % [top_id, body_w], AvatarParts.top.bind(top_id, body_w)), Vector3.ZERO)
	var pants_id: String = look.get("pants", "")
	if pants_id != "":
		_add_part(_hips, _shared("pants|%s|%.2f" % [pants_id, body_w], AvatarParts.pants.bind(pants_id, body_w)), Vector3.ZERO)
	var mask_id: String = look.get("mask", "")
	if mask_id != "":
		_add_part(_head, _shared("mask|" + mask_id, AvatarParts.mask.bind(mask_id)), Vector3.ZERO)
	_arm_l = Node3D.new()
	_arm_l.position = Vector3(-ARM_X, ARM_Y, 0)
	_hips.add_child(_arm_l)
	_arm_r = Node3D.new()
	_arm_r.position = Vector3(ARM_X, ARM_Y, 0)
	_hips.add_child(_arm_r)
	var arm := _shared("arm|" + skin_key, _build_arm.bind(hero, skin))
	_add_part(_arm_l, arm, Vector3.ZERO)
	_add_part(_arm_r, arm, Vector3.ZERO)
	var gloves_id: String = look.get("gloves", "")
	if gloves_id != "":
		var hand_glove := _shared("gloves|" + gloves_id, AvatarParts.glove.bind(gloves_id))
		_add_part(_arm_l, hand_glove, Vector3.ZERO)
		_add_part(_arm_r, hand_glove, Vector3.ZERO)
	_foot_l = Node3D.new()
	_foot_l.position = Vector3(-FOOT_X, FOOT_Y, 0)
	add_child(_foot_l)
	_foot_r = Node3D.new()
	_foot_r.position = Vector3(FOOT_X, FOOT_Y, 0)
	add_child(_foot_r)
	var shoes_id: String = look.get("shoes", "")
	var foot := _shared("shoes|" + shoes_id, AvatarParts.shoe.bind(shoes_id)) if shoes_id != "" else _shared("foot|" + skin_key, _build_foot.bind(hero, skin))
	_add_part(_foot_l, foot, Vector3.ZERO)
	_add_part(_foot_r, foot, Vector3.ZERO)
	var hat_id: String = look.get("hat", "")
	if hat_id != "":
		_hat = Node3D.new()
		var lift := 0.14 if Cosmetics.item("mask", mask_id).get("tall", false) else 0.0
		_hat.position = Vector3(0, _head_top(hero) + lift, 0)
		_head.add_child(_hat)
		_add_part(_hat, _shared("hat|" + hat_id, _build_hat.bind(hat_id)), Vector3.ZERO)
	var back_id: String = look.get("back", "")
	if back_id != "":
		_back = Node3D.new()
		_back.position = Vector3(0, 0.56, -0.25)
		_back.scale = Vector3.ONE * 0.82
		_hips.add_child(_back)
		_add_part(_back, _shared("back|" + back_id, _build_back.bind(back_id, team_color)), Vector3.ZERO)
	_trail = Cosmetics.item("trail", look.get("trail", ""))
	_aura = Cosmetics.item("aura", look.get("aura", ""))
	dance_id = look.get("dance", "")
	run_id = look.get("run", "")
	_material_kind = ""
	set_material_kind("normal")


func _add_part(parent: Node3D, mesh: ArrayMesh, at: Vector3) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = at
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)
	_parts.append(part)
	return part


func _shared(key: String, builder: Callable) -> ArrayMesh:
	if not _meshes.has(key):
		var kit := MeshKit.new()
		kit.outline = 0.02
		kit.soften = true
		kit.detail = 0.55 if Quality.is_low() else 1.0
		builder.call(kit)
		_meshes[key] = kit.to_mesh()
	return _meshes[key]


func set_material_kind(kind: String) -> void:
	if kind == _material_kind:
		return
	_material_kind = kind
	var mat := _material(kind)
	for part in _parts:
		if is_instance_valid(part):
			part.material_override = mat


func flash() -> void:
	_flash = 0.12


func squash(amount := 0.35) -> void:
	_squash = amount


## Top of the head above the head pivot, for hats and name tags.
static func _head_top(hero: Dictionary) -> float:
	if hero.get("kind") == "mascot":
		match hero.get("shape"):
			"cup": return 0.52
			"robot": return 0.48
			"flame": return 0.62
			"crystal": return 0.62
		return 0.5
	if hero.get("animal") == "buffalo":
		return 0.46
	return 0.48


# --- Colours --------------------------------------------------------------------------------------

static func _main(hero: Dictionary, skin: Dictionary, key: String) -> Color:
	if String(skin.get("a", "")) != "":
		return Color(skin["a"])
	return Color(hero.get(key, "ffffff"))


static func _second(hero: Dictionary, skin: Dictionary, key: String) -> Color:
	if String(skin.get("b", "")) != "":
		return Color(skin["b"])
	return Color(hero.get(key, "ffffff"))


# --- Body parts -----------------------------------------------------------------------------------

func _build_body(k: MeshKit, hero: Dictionary, skin: Dictionary) -> void:
	match hero["kind"]:
		"kid":
			var top := _main(hero, skin, "top")
			var low := _second(hero, skin, "low")
			var pants_r := Vector3(0.3, 0.15, 0.24)
			var pants_at := Vector3(0, 0.28, 0)
			k.ball(pants_at, pants_r, low, 12, 18)
			var top_r := Vector3(0.31, 0.27, 0.25)
			var top_at := Vector3(0, 0.48, 0)
			k.ball(top_at, top_r, top, 12, 18)
			k.band(top_at, top_r, -0.235, -0.2, top.lightened(0.32))
			k.spot(top_at, top_r, 0.0, -0.06, 0.075, top.lightened(0.35))
		"animal":
			var fur := _main(hero, skin, "fur")
			var belly := _second(hero, skin, "belly")
			k.ball(Vector3(0, 0.46, 0), Vector3(0.34, 0.33, 0.3), fur, 12, 18)
			k.round_patch(Vector3(0, 0.46, 0), Vector3(0.34, 0.33, 0.3), 0.0, -0.05, 0.215, 0.22, belly)
			_tail(k, hero, fur)
		_:
			var main := _main(hero, skin, "main")
			var shape: String = hero.get("shape", "")
			if shape == "robot":
				k.soft_box(Vector3(0, 0.46, 0), Vector3(0.28, 0.24, 0.21), main.darkened(0.1), 0.6)
				k.spot(Vector3(0, 0.46, 0), Vector3(0.28, 0.24, 0.215), -0.08, 0.0, 0.03, Color("ff4f6a"))
				k.spot(Vector3(0, 0.46, 0), Vector3(0.28, 0.24, 0.215), 0.0, 0.0, 0.03, Color("35d07f"))
				k.spot(Vector3(0, 0.46, 0), Vector3(0.28, 0.24, 0.215), 0.08, 0.0, 0.03, Color("3aa6ff"))
			elif shape == "ghost":
				k.cyl(Vector3(0, 0.14, 0), 0.6, 0.42, 0.36, main, 18)
				for i in 8:
					var a := TAU * i / 8.0
					k.ball(Vector3(cos(a) * 0.36, 0.14, sin(a) * 0.36), Vector3(0.125, 0.125, 0.125), main, 8, 10)
			elif shape == "flame":
				k.ball(Vector3(0, 0.44, 0), Vector3(0.3, 0.3, 0.27), _second(hero, skin, "second"), 12, 18)
			elif shape == "crystal":
				k.ball(Vector3(0, 0.44, 0), Vector3(0.28, 0.3, 0.26), _second(hero, skin, "second").darkened(0.08), 12, 18)
			elif shape == "cup":
				k.ball(Vector3(0, 0.44, 0), Vector3(0.3, 0.3, 0.27), main.darkened(0.08), 12, 18)
			else:
				k.ball(Vector3(0, 0.46, 0), Vector3(0.31, 0.32, 0.28), main.lightened(0.05), 12, 18)


func _tail(k: MeshKit, hero: Dictionary, fur: Color) -> void:
	match hero.get("animal"):
		"dog", "cat", "monkey":
			k.push(Transform3D(Basis(Vector3.RIGHT, -0.7), Vector3(0, 0.45, -0.3)))
			k.cyl(Vector3.ZERO, 0.42, 0.08, 0.05, fur, 5)
			k.pop()
		"pig":
			k.torus(Vector3(0, 0.5, -0.38), 0.07, 0.03, fur, 8, 4)
		"rooster":
			for i in 3:
				var angle := -0.4 + i * 0.4
				k.push(Transform3D(Basis(Vector3.BACK, angle), Vector3(0, 0.6, -0.32)))
				k.ball(Vector3(0, 0.26, -0.05), Vector3(0.1, 0.26, 0.07), Color(hero["accent"]).lerp(Color("3a6aff"), i * 0.5), 3, 6)
				k.pop()


## A short round arm ending in an oblong mitten of a hand. No fingers: it's cuter.
func _build_arm(k: MeshKit, hero: Dictionary, skin: Dictionary) -> void:
	var arm := Color.WHITE
	var hand := Color.WHITE
	var sleeve := Color(0, 0, 0, 0)
	var cuff := Color(0, 0, 0, 0)
	match hero["kind"]:
		"kid":
			arm = Color(hero["skin"])
			hand = arm
			sleeve = _main(hero, skin, "top")
		"animal":
			arm = _main(hero, skin, "fur")
			hand = _second(hero, skin, "belly").lerp(arm, 0.3)
		_:
			arm = _main(hero, skin, "main").darkened(0.08)
			hand = Color("fbf7ff")
			cuff = Color(hero.get("accent", "ffffff"))
	k.cyl(Vector3(0, -0.2, 0), 0.2, 0.06, 0.07, arm, 12)
	if sleeve.a > 0.0:
		k.ball(Vector3(0, -0.035, 0), Vector3(0.1, 0.115, 0.1), sleeve, 8, 12)
	if cuff.a > 0.0:
		k.torus(Vector3(0, -0.17, 0), 0.066, 0.024, cuff, 16, 6)
	k.ball(Vector3(0, -0.27, 0), Vector3(0.092, 0.128, 0.086), hand, 10, 14)


## A little bean of a foot.
func _build_foot(k: MeshKit, hero: Dictionary, skin: Dictionary) -> void:
	var at := Vector3(0, 0.0, 0.045)
	var r := Vector3(0.125, 0.09, 0.175)
	match hero["kind"]:
		"kid":
			var c := Color(hero["shoe"])
			k.ball(at, r, c, 10, 14)
			k.band(at, r, -0.075, -0.035, Color("fff8ea"))
		"animal":
			k.ball(at, r, _main(hero, skin, "fur").darkened(0.12), 10, 14)
		_:
			k.ball(at, r, Color(hero.get("accent", "ffffff")), 10, 14)


## Where the eyes go on this head. The eyes and mouth are drawn separately from the head (see _build_face),
## so the face can change. A coloured `white` makes a ringed eye (the tarsier's); a dark one makes the alien's
## and ghost's solid black eyes.
func _eyes(_k: MeshKit, y: float, z: float, gap: float, size: float, _iris := Color("6a3a7a"), white := Color("ffffff")) -> void:
	var plain := white == Color("ffffff")
	if plain:
		gap *= 1.18
		y -= 0.02
		z -= 0.012
	_eye_seen.merge({"y": y, "z": z, "gap": gap, "size": size, "white": white, "plain": plain, "solid": white.get_luminance() < 0.2}, true)


## Shows an expression: normal, blink, happy, sad, shock, dizzy or focus. Each is one small mesh, shared by
## every avatar with the same head, and swapping it costs nothing.
func _show_face(expression: String) -> void:
	if _face == null or expression == _shown_face or not _eye_info.has(_face_key):
		return
	_shown_face = expression
	_face.mesh = _shared("face|%s|%s" % [_face_key, expression], _build_face.bind(_eye_info[_face_key], expression))


func _build_face(k: MeshKit, info: Dictionary, expression: String) -> void:
	k.outline = 0.0
	var size: float = info["size"]
	var dark := Color("241338")
	for s: float in [-1.0, 1.0]:
		var at := Vector3(s * float(info["gap"]), float(info["y"]), float(info["z"]))
		match expression:
			"blink":
				_arc(k, at, size, -0.22, dark)
			"happy":
				_arc(k, at, size, 0.5, dark)
			"focus":  # > <
				var lean := -s
				_line(k, at + Vector3(lean * size * 0.62, size * 0.5, size * 0.34), at + Vector3(-lean * size * 0.62, 0.0, size * 0.4), size * 0.17, dark)
				_line(k, at + Vector3(-lean * size * 0.62, 0.0, size * 0.4), at + Vector3(lean * size * 0.62, -size * 0.5, size * 0.34), size * 0.17, dark)
			"dizzy":  # x x
				_line(k, at + Vector3(-size * 0.6, size * 0.6, size * 0.36), at + Vector3(size * 0.6, -size * 0.6, size * 0.36), size * 0.17, dark)
				_line(k, at + Vector3(-size * 0.6, -size * 0.6, size * 0.37), at + Vector3(size * 0.6, size * 0.6, size * 0.37), size * 0.17, dark)
			"shock":
				k.ball(at, Vector3(size * 0.82, size * 1.05, size * 0.36), Color.WHITE, 8, 12)
				k.ball(at + Vector3(0, 0, size * 0.3), Vector3(size * 0.3, size * 0.36, size * 0.1), dark, 6, 9)
			"sad":
				k.ball(at + Vector3(0, -size * 0.1, 0), Vector3(size * 0.58, size * 0.8, size * 0.38), dark, 8, 12)
				k.ball(at + Vector3(-size * 0.16, size * 0.16, size * 0.3), Vector3(size * 0.16, size * 0.16, size * 0.06), Color.WHITE, 4, 6)
				_line(k, at + Vector3(s * size * 0.75, size * 0.8, size * 0.3), at + Vector3(-s * size * 0.5, size * 1.15, size * 0.3), size * 0.1, dark)
				k.ball(at + Vector3(s * size * 0.32, -size * 1.05, size * 0.3), Vector3(size * 0.2, size * 0.3, size * 0.1), Color("7fdcff"), 5, 8)
			_:
				if bool(info["plain"]) or bool(info["solid"]):
					k.ball(at, Vector3(size * 0.66, size * 0.98, size * 0.42), dark, 10, 14)
				else:  # The tarsier's huge ringed eyes.
					k.ball(at, Vector3(size, size * 1.1, size * 0.42), info["white"], 10, 14)
					k.ball(at + Vector3(0, -size * 0.05, size * 0.26), Vector3(size * 0.62, size * 0.74, size * 0.22), dark, 8, 12)
				k.ball(at + Vector3(-size * 0.2, size * 0.38, size * 0.36), Vector3(size * 0.2, size * 0.22, size * 0.07), Color.WHITE, 5, 8)
	if info.has("mouth_y"):
		_mouth(k, info, expression)
	k.outline = 0.02


## One eye drawn as a curve: bent up for a happy ^, or down for a blink.
func _arc(k: MeshKit, at: Vector3, size: float, bend: float, color: Color) -> void:
	var pts := PackedVector3Array()
	for i in 11:
		var f := lerpf(-1.0, 1.0, i / 10.0)
		pts.append(at + Vector3(f * size * 0.8, size * bend * (1.0 - f * f) - size * 0.05, size * 0.38 * sqrt(maxf(1.0 - f * f * 0.72, 0.0)) + 0.012))
	k.ribbon(pts, size * 0.15, color)


func _line(k: MeshKit, a: Vector3, b: Vector3, half_width: float, color: Color) -> void:
	var pts := PackedVector3Array()
	for i in 7:
		pts.append(a.lerp(b, i / 6.0))
	k.ribbon(pts, half_width, color)


func _mouth(k: MeshKit, info: Dictionary, expression: String) -> void:
	var y: float = info["mouth_y"]
	var z: float = info["mouth_z"]
	var width: float = info["mouth_w"]
	var dark := Color("6a2038")
	match expression:
		"sad":
			var pts := PackedVector3Array()
			for i in 9:
				var f := lerpf(-1.0, 1.0, i / 8.0)
				pts.append(Vector3(f * width * 0.85, y - width * 0.42 + width * 0.3 * (1.0 - f * f), z - f * f * width * 0.28 + 0.006))
			k.ribbon(pts, width * 0.13, dark)
		"shock":
			k.ball(Vector3(0, y - width * 0.42, z - 0.004), Vector3(width * 0.42, width * 0.56, 0.016), Color("7a1f3a"), 6, 10)
		"focus":
			_line(k, Vector3(-width * 0.6, y - width * 0.3, z + 0.004), Vector3(width * 0.6, y - width * 0.3, z + 0.004), width * 0.12, dark)
		"dizzy":
			var pts := PackedVector3Array()
			for i in 11:
				var f := lerpf(-1.0, 1.0, i / 10.0)
				pts.append(Vector3(f * width, y - width * 0.35 + sin(f * 7.0) * width * 0.16, z - f * f * width * 0.28 + 0.006))
			k.ribbon(pts, width * 0.11, dark)
		_:
			var big := 1.45 if expression == "happy" else 1.0
			_open_mouth(k, y, z, width * big)


## A little open D of a mouth with a tongue, following the curve of the face.
func _open_mouth(k: MeshKit, y: float, z: float, width: float) -> void:
	var steps := 14
	var mouth := PackedVector3Array()
	var depth := width
	for i in steps + 1:  # The lower lip, left to right...
		var f := lerpf(-1.0, 1.0, i / float(steps))
		mouth.append(Vector3(f * width, y + 0.012 * f * f - depth * (1.0 - f * f), z - f * f * width * 0.28 + 0.004))
	for i in range(steps - 1, 0, -1):  # ...and the upper lip back.
		var f := lerpf(-1.0, 1.0, i / float(steps))
		mouth.append(Vector3(f * width, y + 0.012 * f * f - width * 0.1 * (1.0 - f * f), z - f * f * width * 0.28 + 0.004))
	k.fan(mouth, Color("b23a55"))
	var tongue := PackedVector3Array()
	for i in steps + 1:
		var a := PI + PI * i / float(steps)
		tongue.append(Vector3(cos(a) * width * 0.5, y - depth * 0.56 + sin(a) * width * 0.28, z + 0.008))
	k.fan(tongue, Color("ff8fa6"))


## A passing expression, for moments like a tag.
func react(expression: String, seconds := 1.2) -> void:
	_react = expression
	_react_left = seconds


## What the face shows right now: what's happening to the avatar, a passing reaction, or a blink.
func _face_for_state() -> String:
	if _react_left > 0.0:
		return _react
	match state:
		"stun":
			return "dizzy"
		"freeze", "root":
			return "shock"
		"jail", "sad":
			return "sad"
		"dance", "air":
			return "happy"
		"dash":
			return "focus"
	return "blink" if _blink_left > 0.0 else "normal"


func _tick_blink(delta: float) -> void:
	_react_left = maxf(_react_left - delta, 0.0)
	if _blink_left > 0.0:
		_blink_left -= delta
		if _blink_left <= 0.0:
			_blink_wait = randf_range(1.6, 4.5)
	else:
		_blink_wait -= delta
		if _blink_wait <= 0.0:
			_blink_left = 0.11
	_show_face(_face_for_state())


## Where the mouth goes on this head.
func _smile(_k: MeshKit, y: float, z: float, width: float, _c := Color("b23a55")) -> void:
	_eye_seen.merge({"mouth_y": y, "mouth_z": z, "mouth_w": width}, true)


func _build_head(k: MeshKit, hero: Dictionary, skin: Dictionary) -> void:
	match hero["kind"]:
		"kid": _head_kid(k, hero, skin)
		"animal": _head_animal(k, hero, skin)
		_: _head_mascot(k, hero, skin)


func _head_kid(k: MeshKit, hero: Dictionary, skin: Dictionary) -> void:
	var tone := Color(hero["skin"])
	var hair := Color(hero["hair"])
	k.ball(Vector3.ZERO, Vector3(0.5, 0.46, 0.46), tone, 20, 32)
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.49, -0.04, 0), Vector3(0.08, 0.1, 0.075), tone, 8, 10)
	_eyes(k, -0.01, 0.395, 0.2, 0.115)
	k.outline = 0.0
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.335, -0.135, 0.305), Vector3(0.085, 0.05, 0.03), tone.lerp(Color("ff7f9a"), 0.55), 6, 10)
	k.outline = 0.02
	_smile(k, -0.145, 0.44, 0.08)
	# Hair: one smooth shape over the top and back of the head, a soft fringe, then the style.
	k.ball(Vector3(0, 0.15, -0.05), Vector3(0.53, 0.37, 0.47), hair, 20, 32)
	k.outline = 0.0
	for i in 5:
		var f := lerpf(-1.0, 1.0, i / 4.0)
		k.ball(Vector3(f * 0.33, 0.28 - (1.0 - absf(f)) * 0.025, 0.31 - absf(f) * 0.12), Vector3(0.12, 0.105, 0.09), hair, 8, 12)
	k.outline = 0.02
	match String(hero.get("style")):
		"spiky":  # Soft little tufts.
			for i in 5:
				var a := TAU * i / 5.0 + 0.3
				k.ball(Vector3(cos(a) * 0.22, 0.47, sin(a) * 0.2 - 0.05), Vector3(0.1, 0.13, 0.1), hair, 8, 12)
			k.ball(Vector3(0, 0.55, -0.04), Vector3(0.11, 0.13, 0.11), hair, 8, 12)
		"ponytail":
			k.ball(Vector3(0, 0.22, -0.48), Vector3(0.09, 0.09, 0.09), _main(hero, skin, "top"), 8, 10)
			k.ball(Vector3(0, -0.04, -0.6), Vector3(0.15, 0.29, 0.15), hair, 10, 14)
		"bowl":
			k.ball(Vector3(0, 0.12, 0.02), Vector3(0.56, 0.28, 0.5), hair, 10, 16)
		"buns":
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.33, 0.44, -0.06), Vector3(0.17, 0.17, 0.17), hair, 10, 14)
				k.torus(Vector3(s * 0.3, 0.32, -0.05), 0.09, 0.024, _main(hero, skin, "top"), 16, 6)
		"mohawk":
			for i in 5:
				k.ball(Vector3(0, 0.5 - absf(i - 2.0) * 0.045, -0.26 + i * 0.13), Vector3(0.06, 0.13, 0.07), _second(hero, skin, "top"), 8, 10)
		"long":
			k.ball(Vector3(0, -0.15, -0.26), Vector3(0.48, 0.55, 0.26), hair, 12, 16)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.45, -0.18, 0.08), Vector3(0.1, 0.32, 0.13), hair, 8, 12)


func _head_animal(k: MeshKit, hero: Dictionary, skin: Dictionary) -> void:
	var fur := _main(hero, skin, "fur")
	var belly := _second(hero, skin, "belly")
	var accent := Color(hero["accent"])
	var animal: String = hero["animal"]
	match animal:
		"tarsier":
			k.ball(Vector3.ZERO, Vector3(0.48, 0.44, 0.44), fur, 16, 24)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.48, 0.28, -0.02), Vector3(0.28, 0.32, 0.1), fur.darkened(0.1), 4, 9)
				k.outline = 0.0
				k.ball(Vector3(s * 0.48, 0.28, 0.05), Vector3(0.18, 0.22, 0.05), Color("ffb3a8"), 3, 8)
				k.outline = 0.02
			_eyes(k, 0.06, 0.32, 0.22, 0.24, Color("5a2b0e"), Color("ffcf56"))
			k.outline = 0.0
			k.ball(Vector3(0, -0.16, 0.43), Vector3(0.05, 0.04, 0.03), Color("6a2038"), 2, 6)
			k.outline = 0.02
		"rooster":
			k.ball(Vector3.ZERO, Vector3(0.46, 0.46, 0.44), fur, 16, 24)
			for i in 3:
				k.ball(Vector3(0, 0.46 + (1 - absf(i - 1)) * 0.06, -0.12 + i * 0.13), Vector3(0.07, 0.16, 0.09), accent, 3, 6)
			_eyes(k, 0.08, 0.36, 0.2, 0.11)
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.05, 0.38)))
			k.cone(Vector3.ZERO, 0.28, 0.13, Color("ffb52e"), 7)
			k.pop()
			k.ball(Vector3(0, -0.24, 0.32), Vector3(0.07, 0.12, 0.05), accent, 3, 6)
		_:
			k.ball(Vector3.ZERO, Vector3(0.5, 0.46, 0.46), fur, 16, 24)
			_animal_features(k, animal, fur, belly, accent)
			_eyes(k, 0.08, 0.37, 0.2, 0.125)
			if animal == "pig":
				k.ball(Vector3(0, -0.1, 0.42), Vector3(0.16, 0.12, 0.1), belly, 3, 8)
				k.outline = 0.0
				for s: float in [-0.05, 0.05]:
					k.ball(Vector3(s, -0.1, 0.5), Vector3(0.025, 0.04, 0.02), Color("6a2038"), 2, 5)
				k.outline = 0.02
			else:
				k.round_patch(Vector3.ZERO, Vector3(0.5, 0.46, 0.46), 0.0, -0.17, 0.16, 0.115, belly)
				k.outline = 0.0
				k.ball(Vector3(0, -0.11, 0.436), Vector3(0.038, 0.028, 0.02), Color("24135f"), 2, 6)
				k.outline = 0.02
				_smile(k, -0.15, 0.445, 0.07)


func _animal_features(k: MeshKit, animal: String, fur: Color, belly: Color, accent: Color) -> void:
	match animal:
		"dog":
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.48, 0.08, -0.02), Vector3(0.14, 0.32, 0.17), fur.darkened(0.25), 4, 7)
			k.torus(Vector3(0, -0.34, 0), 0.26, 0.04, accent, 10, 4)
		"cat":
			for s: float in [-1.0, 1.0]:
				k.cone(Vector3(s * 0.28, 0.32, -0.03), 0.34, 0.15, fur, 4)
				k.outline = 0.0
				k.cone(Vector3(s * 0.28, 0.32, 0.03), 0.24, 0.08, Color("ffb3a8"), 4)
				k.outline = 0.02
			k.outline = 0.0
			for s: float in [-1.0, 1.0]:
				k.box(Vector3(s * 0.34, -0.1, 0.34), Vector3(0.22, 0.015, 0.015), Color("24135f"))
			k.outline = 0.02
		"buffalo":
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -1.1), Vector3(s * 0.4, 0.22, 0)))
				k.cone(Vector3.ZERO, 0.62, 0.11, Color("e9e0c6"), 6)
				k.pop()
				k.ball(Vector3(s * 0.5, -0.02, 0), Vector3(0.14, 0.08, 0.1), fur.darkened(0.15), 3, 6)
		"pig":
			for s: float in [-1.0, 1.0]:
				k.cone(Vector3(s * 0.28, 0.32, 0.05), 0.2, 0.13, fur.darkened(0.08), 4)
		"monkey":
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.54, 0.04, 0), Vector3(0.14, 0.18, 0.08), belly, 3, 7)
			k.round_patch(Vector3.ZERO, Vector3(0.5, 0.46, 0.46), 0.0, -0.05, 0.36, 0.33, belly)


func _head_mascot(k: MeshKit, hero: Dictionary, skin: Dictionary) -> void:
	var main := _main(hero, skin, "main")
	var second := _second(hero, skin, "second")
	var accent := Color(hero["accent"])
	match String(hero["shape"]):
		"coconut":
			k.ball(Vector3.ZERO, Vector3(0.52, 0.5, 0.5), main, 16, 24)
			k.outline = 0.0
			k.ball(Vector3(0, 0.42, 0), Vector3(0.34, 0.1, 0.32), second, 3, 10)
			k.outline = 0.02
			k.cyl(Vector3(0.16, 0.42, 0.05), 0.42, 0.03, 0.03, accent, 5)
			_eyes(k, 0.02, 0.38, 0.2, 0.14)
			_smile(k, -0.22, 0.45, 0.12)
		"mango":
			k.ball(Vector3.ZERO, Vector3(0.48, 0.54, 0.44), main, 16, 24)
			k.outline = 0.0
			k.ball(Vector3(0.25, 0.18, 0.1), Vector3(0.28, 0.32, 0.36), second, 4, 9)
			k.outline = 0.02
			k.cyl(Vector3(0, 0.5, 0), 0.16, 0.04, 0.03, Color("7a5230"), 5)
			k.ball(Vector3(0.16, 0.62, 0), Vector3(0.2, 0.05, 0.1), accent, 3, 7)
			_eyes(k, 0.02, 0.36, 0.18, 0.13)
			_smile(k, -0.2, 0.42, 0.12)
		"cup":
			k.cyl(Vector3(0, -0.42, 0), 0.72, 0.36, 0.5, main, 12)
			k.outline = 0.0
			k.torus(Vector3(0, -0.38, 0), 0.37, 0.05, second, 12, 4)
			k.torus(Vector3(0, 0.04, 0), 0.47, 0.055, accent, 12, 4)
			k.outline = 0.02
			k.ball(Vector3(0, 0.3, 0), Vector3(0.48, 0.28, 0.48), Color("f6fcff"), 5, 12)
			k.ball(Vector3(0.1, 0.5, 0.06), Vector3(0.14, 0.1, 0.14), second, 3, 7)
			k.ball(Vector3(-0.2, 0.42, 0.14), Vector3(0.09, 0.07, 0.09), accent, 3, 6)
			_eyes(k, -0.1, 0.42, 0.18, 0.115)
			_smile(k, -0.26, 0.4, 0.075)
		"robot":
			k.box(Vector3.ZERO, Vector3(0.92, 0.76, 0.76), main, 0.1)
			k.outline = 0.0
			k.box(Vector3(0, 0.06, 0.385), Vector3(0.72, 0.34, 0.02), Color("1c174a"))
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				k.outline = 0.0
				k.ball(Vector3(s * 0.19, 0.06, 0.4), Vector3(0.11, 0.11, 0.03), accent, 3, 8)
				k.outline = 0.02
				k.cyl(Vector3(s * 0.48, -0.08, 0), 0.2, 0.08, 0.08, second, 6)
			k.cyl(Vector3(0, 0.38, 0), 0.26, 0.03, 0.03, Color("6a6a7a"), 5)
			k.ball(Vector3(0, 0.66, 0), Vector3(0.07, 0.07, 0.07), second, 3, 6)
			k.outline = 0.0
			for i in 4:
				k.box(Vector3(-0.21 + i * 0.14, -0.22, 0.385), Vector3(0.09, 0.08, 0.02), second)
			k.outline = 0.02
		"ghost":
			k.ball(Vector3(0, -0.02, 0), Vector3(0.5, 0.5, 0.46), main, 16, 24)
			_eyes(k, 0.05, 0.36, 0.18, 0.13, Color("24135f"), Color("24135f"))
			k.outline = 0.0
			k.ball(Vector3(0, -0.2, 0.42), Vector3(0.07, 0.09, 0.04), Color("24135f"), 3, 6)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.3, -0.11, 0.35), Vector3(0.08, 0.05, 0.03), second, 2, 6)
			k.outline = 0.02
		"alien":
			k.ball(Vector3(0, 0.08, 0), Vector3(0.56, 0.5, 0.48), main, 16, 24)
			_eyes(k, 0.03, 0.34, 0.25, 0.22, Color("0c0626"), Color("0c0626"))
			_smile(k, -0.24, 0.42, 0.06)
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.4), Vector3(s * 0.2, 0.46, 0)))
				k.cyl(Vector3.ZERO, 0.3, 0.025, 0.025, main.darkened(0.2), 4)
				k.ball(Vector3(0, 0.34, 0), Vector3(0.07, 0.07, 0.07), accent, 3, 6)
				k.pop()
		"flame":
			k.ball(Vector3(0, -0.12, 0), Vector3(0.5, 0.42, 0.46), main, 10, 16)
			k.cone(Vector3(0, 0.05, 0), 0.68, 0.44, main, 8)
			k.cone(Vector3(0.28, -0.05, 0), 0.5, 0.2, main.lightened(0.1), 6)
			k.cone(Vector3(-0.28, -0.05, 0), 0.42, 0.18, main.darkened(0.05), 6)
			k.outline = 0.0
			k.ball(Vector3(0, -0.14, 0.2), Vector3(0.32, 0.3, 0.28), second, 4, 9)
			k.outline = 0.02
			_eyes(k, -0.03, 0.43, 0.16, 0.12)
			_smile(k, -0.22, 0.48, 0.09)
		"crystal":
			k.cyl(Vector3(0, -0.35, 0), 0.42, 0.25, 0.48, main, 6, false)
			k.cyl(Vector3(0, 0.07, 0), 0.5, 0.48, 0.05, second, 6, false)
			_eyes(k, -0.02, 0.33, 0.18, 0.12)
			_smile(k, -0.22, 0.34, 0.08)


# --- Hats and things on the back ------------------------------------------------------------------

func _build_hat(k: MeshKit, id: String) -> void:
	match id:
		"cap":
			k.ball(Vector3(0, -0.02, 0), Vector3(0.48, 0.25, 0.46), Color("ff5a4e"), 4, 10)
			k.box(Vector3(0, -0.07, 0.44), Vector3(0.5, 0.05, 0.42), Color("d23a30"), 0.02)
		"salakot":
			k.cyl(Vector3(0, -0.08, 0), 0.28, 0.72, 0.12, Color("e0b868"), 12)
			k.ball(Vector3(0, 0.22, 0), Vector3(0.1, 0.07, 0.1), Color("c99b4a"), 3, 6)
		"party":
			k.cone(Vector3(0, -0.06, 0), 0.62, 0.26, Color("ff6fb5"), 9)
			k.outline = 0.0
			k.torus(Vector3(0, 0.1, 0), 0.19, 0.03, Color("ffd23f"), 9, 4)
			k.torus(Vector3(0, 0.3, 0), 0.1, 0.02, Color("3aa6ff"), 8, 4)
			k.outline = 0.02
			k.ball(Vector3(0, 0.6, 0), Vector3(0.08, 0.08, 0.08), Color("ffd23f"), 3, 6)
		"headphones":
			k.torus(Vector3(0, -0.12, 0), 0.47, 0.035, Color("24135f"), 12, 4)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.52, -0.42, 0), Vector3(0.1, 0.17, 0.17), Color("ff4f8b"), 3, 8)
		"bow":
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.2, 0.0, 0.1), Vector3(0.2, 0.14, 0.08), Color("ff5a9a"), 3, 8)
			k.ball(Vector3(0, 0.0, 0.12), Vector3(0.07, 0.07, 0.07), Color("d43a7a"), 3, 6)
		"headband":
			k.outline = 0.02
			k.torus(Vector3(0, -0.2, -0.02), 0.47, 0.05, Color("ff5a4e"), 14, 4)
			k.box(Vector3(0.12, -0.28, -0.52), Vector3(0.1, 0.22, 0.03), Color("ff5a4e"))
		"beanie":
			k.ball(Vector3(0, -0.1, -0.02), Vector3(0.5, 0.38, 0.47), Color("3aa6ff"), 4, 10)
			k.torus(Vector3(0, -0.16, -0.02), 0.48, 0.07, Color("ffffff"), 12, 4)
			k.ball(Vector3(0, 0.3, -0.02), Vector3(0.13, 0.13, 0.13), Color("ffffff"), 3, 7)
		"flowers":
			k.outline = 0.02
			k.torus(Vector3(0, -0.14, -0.01), 0.45, 0.035, Color("59c04f"), 12, 4)
			var colors := [Color("ff9fd0"), Color("ffffff"), Color("ffd23f"), Color("ff7a9a"), Color("c49bff")]
			for i in 8:
				var a := TAU * i / 8.0
				k.ball(Vector3(cos(a) * 0.45, -0.1, sin(a) * 0.45), Vector3(0.09, 0.07, 0.09), colors[i % 5], 2, 6)
		"cowboy":
			k.cyl(Vector3(0, -0.14, 0), 0.05, 0.74, 0.7, Color("c98c4a"), 12)
			k.cyl(Vector3(0, -0.1, 0), 0.3, 0.36, 0.3, Color("c98c4a"), 10)
			k.outline = 0.0
			k.torus(Vector3(0, -0.06, 0), 0.36, 0.03, Color("24135f"), 12, 4)
			k.outline = 0.02
		"propeller":
			k.ball(Vector3(0, -0.04, 0), Vector3(0.46, 0.24, 0.44), Color("ff5a4e"), 3, 10)
			k.cyl(Vector3(0, 0.18, 0), 0.14, 0.02, 0.02, Color("6a6a7a"), 4)
			k.box(Vector3(0, 0.33, 0), Vector3(0.78, 0.03, 0.12), Color("ffd23f"))
			k.box(Vector3(0, 0.34, 0), Vector3(0.12, 0.03, 0.78), Color("3aa6ff"))
		"chef":
			k.cyl(Vector3(0, -0.12, 0), 0.26, 0.37, 0.39, Color("ffffff"), 10)
			k.ball(Vector3(0, 0.26, 0), Vector3(0.44, 0.24, 0.44), Color("ffffff"), 4, 10)
		"tophat":
			k.cyl(Vector3(0, -0.12, 0), 0.04, 0.52, 0.5, Color("2b2448"), 12)
			k.cyl(Vector3(0, -0.08, 0), 0.5, 0.31, 0.33, Color("2b2448"), 10)
			k.outline = 0.0
			k.torus(Vector3(0, -0.02, 0), 0.32, 0.03, Color("ff3f6a"), 12, 4)
			k.outline = 0.02
		"pirate":
			k.ball(Vector3(0, -0.04, 0), Vector3(0.62, 0.22, 0.4), Color("2b2448"), 4, 10)
			k.ball(Vector3(0, 0.12, 0), Vector3(0.36, 0.2, 0.3), Color("2b2448"), 4, 9)
			k.outline = 0.0
			k.ball(Vector3(0, 0.1, 0.32), Vector3(0.09, 0.09, 0.03), Color("ffffff"), 3, 7)
			k.outline = 0.02
		"sombrero":
			k.cyl(Vector3(0, -0.13, 0), 0.06, 0.92, 0.84, Color("ffcf6a"), 14)
			k.cyl(Vector3(0, -0.08, 0), 0.42, 0.34, 0.16, Color("ffcf6a"), 10)
			k.outline = 0.0
			k.torus(Vector3(0, -0.04, 0), 0.32, 0.04, Color("ff3f3f"), 12, 4)
			k.torus(Vector3(0, -0.09, 0), 0.82, 0.03, Color("35d07f"), 16, 4)
			k.outline = 0.02
		"viking":
			k.ball(Vector3(0, -0.08, 0), Vector3(0.5, 0.36, 0.48), Color("b8c0d8"), 4, 10)
			k.outline = 0.0
			k.torus(Vector3(0, -0.16, 0), 0.49, 0.05, Color("c98c4a"), 12, 4)
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -1.0), Vector3(s * 0.42, 0.0, 0)))
				k.cone(Vector3.ZERO, 0.52, 0.11, Color("f4e8c9"), 6)
				k.pop()
		"wizard":
			k.cyl(Vector3(0, -0.12, 0), 0.04, 0.68, 0.64, Color("5a2bd6"), 12)
			k.push(Transform3D(Basis(Vector3.BACK, 0.15), Vector3(0, -0.08, 0)))
			k.cone(Vector3.ZERO, 0.92, 0.38, Color("5a2bd6"), 9)
			k.pop()
			k.outline = 0.0
			k.ball(Vector3(-0.08, 0.2, 0.26), Vector3(0.07, 0.07, 0.03), Color("ffd23f"), 2, 6)
			k.ball(Vector3(0.12, 0.05, 0.3), Vector3(0.05, 0.05, 0.02), Color("ffd23f"), 2, 6)
			k.outline = 0.02
		"santa":
			k.push(Transform3D(Basis(Vector3.BACK, -0.5), Vector3(0, -0.1, 0)))
			k.cone(Vector3.ZERO, 0.66, 0.42, Color("ff3f3f"), 9)
			k.ball(Vector3(0, 0.68, 0), Vector3(0.11, 0.11, 0.11), Color("ffffff"), 3, 6)
			k.pop()
			k.torus(Vector3(0, -0.1, 0), 0.43, 0.09, Color("ffffff"), 12, 5)
		"halo_ring":
			k.outline = 0.02
			k.torus(Vector3(0, 0.3, 0), 0.32, 0.05, Color("fff176"), 14, 5)
		"horns":
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.35), Vector3(s * 0.26, -0.05, 0.06)))
				k.cone(Vector3.ZERO, 0.32, 0.09, Color("ff3f3f"), 6)
				k.pop()
		"astronaut":
			k.outline = 0.02
			k.torus(Vector3(0, -0.72, 0), 0.5, 0.07, Color("e8ecf9"), 14, 5)
			k.outline = 0.0
			k.ball(Vector3(0, -0.34, 0), Vector3(0.66, 0.66, 0.66), Color("a8e6ff"), 3, 8)
			k.outline = 0.02
		"crown":
			k.cyl(Vector3(0, -0.1, 0), 0.22, 0.36, 0.38, Color("ffc21f"), 8, false)
			for i in 6:
				var a := TAU * i / 6.0
				k.cone(Vector3(cos(a) * 0.32, 0.1, sin(a) * 0.32), 0.2, 0.08, Color("ffc21f"), 4)
				k.ball(Vector3(cos(a) * 0.32, 0.32, sin(a) * 0.32), Vector3(0.05, 0.05, 0.05), [Color("ff3f6a"), Color("3aa6ff")][i % 2], 2, 5)
		"parol_hat":
			# A star-shaped Christmas lantern, worn with pride.
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.26, 0)))
			for i in 5:
				var a := TAU * i / 5.0 + PI * 0.5
				k.push(Transform3D(Basis(Vector3.BACK, a - PI * 0.5), Vector3.ZERO))
				k.cone(Vector3(0, 0.05, 0), 0.3, 0.13, Color("ffd23f") if i % 2 == 0 else Color("ff4f6a"), 4)
				k.pop()
			k.pop()
			k.ball(Vector3(0, 0.26, 0), Vector3(0.1, 0.1, 0.1), Color("fff8c4"), 3, 7)
		"ufo":
			k.cyl(Vector3(0, 0.18, 0), 0.08, 0.1, 0.46, Color("b8c0d8"), 12)
			k.cyl(Vector3(0, 0.26, 0), 0.06, 0.46, 0.2, Color("dfe4f4"), 12)
			k.ball(Vector3(0, 0.32, 0), Vector3(0.18, 0.15, 0.18), Color("6dffb0"), 3, 9)


func _build_back(k: MeshKit, id: String, team: Color) -> void:
	match id:
		"backpack":
			k.box(Vector3(0, -0.08, -0.08), Vector3(0.5, 0.56, 0.24), Color("ff8a2b"), 0.08)
			k.decal_box(Vector3(0, -0.2, -0.205), Vector3(0.34, 0.2, 0.01), Color("ffd23f"))
		"cape_red", "cape_blue":
			var c := Color("ff3f3f") if id == "cape_red" else Color("3a6aff")
			k.push(Transform3D(Basis(Vector3.RIGHT, 0.32), Vector3(0, 0.1, -0.05)))
			k.box(Vector3(0, -0.42, -0.03), Vector3(0.66, 0.92, 0.04), c)
			k.pop()
		"balloon":
			k.cyl(Vector3(0, 0.0, -0.05), 1.2, 0.008, 0.008, Color("ffffff"), 3)
			k.ball(Vector3(0, 1.45, -0.05), Vector3(0.28, 0.34, 0.28), Color("ff5a7a"), 5, 10)
		"shell":
			k.ball(Vector3(0, -0.1, -0.08), Vector3(0.42, 0.46, 0.26), Color("4cbc5e"), 4, 10)
			k.outline = 0.0
			k.ball(Vector3(0, -0.1, -0.26), Vector3(0.22, 0.25, 0.1), Color("7ed957"), 3, 6)
			k.outline = 0.02
		"flag":
			k.cyl(Vector3(0.1, -0.4, -0.08), 1.75, 0.03, 0.03, Color("8a5a34"), 5)
			k.box(Vector3(0.46, 1.08, -0.08), Vector3(0.68, 0.42, 0.02), team)
			k.outline = 0.0
			k.box(Vector3(0.46, 1.08, -0.09), Vector3(0.18, 0.18, 0.04), Color("ffffff"))
			k.outline = 0.02
		"guitar":
			k.push(Transform3D(Basis(Vector3.BACK, 0.7), Vector3(0, 0, -0.1)))
			k.ball(Vector3(0, -0.3, 0), Vector3(0.28, 0.32, 0.08), Color("c98c4a"), 3, 9)
			k.box(Vector3(0, 0.3, 0), Vector3(0.09, 0.75, 0.05), Color("7a5230"))
			k.outline = 0.0
			k.ball(Vector3(0, -0.28, -0.08), Vector3(0.1, 0.1, 0.02), Color("3a2315"), 2, 7)
			k.outline = 0.02
			k.pop()
		"butterfly":
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.45, 0.16, -0.05), Vector3(0.4, 0.36, 0.03), Color("ff9fd0"), 3, 9)
				k.ball(Vector3(s * 0.34, -0.26, -0.05), Vector3(0.26, 0.24, 0.03), Color("ffd23f"), 3, 8)
				k.outline = 0.0
				k.ball(Vector3(s * 0.46, 0.18, -0.08), Vector3(0.15, 0.14, 0.02), Color("7f5cff"), 2, 7)
				k.outline = 0.02
		"jetpack":
			for s: float in [-1.0, 1.0]:
				k.cyl(Vector3(s * 0.17, -0.34, -0.1), 0.62, 0.13, 0.13, Color("c9d0e6"), 8)
				k.cone(Vector3(s * 0.17, 0.28, -0.1), 0.16, 0.13, Color("ff5a4e"), 8)
				k.outline = 0.0
				k.ball(Vector3(s * 0.17, -0.46, -0.1), Vector3(0.08, 0.14, 0.08), Color("ffb52e"), 3, 6)
				k.outline = 0.02
			k.box(Vector3(0, -0.02, -0.06), Vector3(0.22, 0.34, 0.12), Color("6a6a7a"))
		"angel", "bat", "dragon":
			var c: Color = {"angel": Color("ffffff"), "bat": Color("3a2f5a"), "dragon": Color("d43a2a")}[id]
			var tip: Color = {"angel": Color("e8f4ff"), "bat": Color("5a4a8a"), "dragon": Color("ffb52e")}[id]
			var size: float = {"angel": 1.0, "bat": 1.0, "dragon": 1.25}[id]
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.3).scaled(Vector3.ONE * size), Vector3(s * 0.12, 0.05, -0.04)))
				k.ball(Vector3(s * 0.34, 0.1, 0), Vector3(0.36, 0.2, 0.03), c, 3, 8)
				k.ball(Vector3(s * 0.62, 0.28, 0), Vector3(0.3, 0.13, 0.025), tip, 3, 7)
				k.ball(Vector3(s * 0.36, -0.14, 0), Vector3(0.24, 0.13, 0.025), tip, 3, 7)
				k.pop()
		"parol":
			k.cyl(Vector3(0, 0, -0.08), 0.9, 0.02, 0.02, Color("8a5a34"), 4)
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.05, -0.08)))
			for i in 5:
				k.push(Transform3D(Basis(Vector3.BACK, TAU * i / 5.0), Vector3.ZERO))
				k.cone(Vector3(0, 0.1, 0), 0.34, 0.15, [Color("ffd23f"), Color("ff4f6a"), Color("35d07f")][i % 3], 4)
				k.pop()
			k.pop()
			k.ball(Vector3(0, 1.05, -0.08), Vector3(0.13, 0.13, 0.13), Color("fff8c4"), 3, 7)


# --- Animation ------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	animate(delta)


func animate(delta: float) -> void:
	if _hips == null:
		return
	_t += delta
	_flash = maxf(_flash - delta, 0.0)
	_squash = move_toward(_squash, 0.0, delta * 1.6)
	var y := 0.0
	var tilt := 0.0
	var turn := 0.0
	var arm_l := Vector3.ZERO
	var arm_r := Vector3.ZERO
	var foot_l := Vector3(0, 0, 0)
	var foot_r := Vector3(0, 0, 0)
	var head_tilt := 0.0
	var stretch := 1.0
	match state:
		"run":
			var r := _run_pose()
			y = r["y"]
			tilt = r["tilt"]
			turn = r["turn"]
			arm_l = r["arm_l"]
			arm_r = r["arm_r"]
			foot_l = r["foot_l"]
			foot_r = r["foot_r"]
			head_tilt = r["head"]
			_hover_extra = r["hover"]
		"dash":
			tilt = 0.7
			y = 0.1
			arm_l = Vector3(-1.5, 0, 0.3)
			arm_r = Vector3(-1.5, 0, -0.3)
			foot_l = Vector3(0, 0.08, -0.2)
			foot_r = Vector3(0, 0.08, -0.2)
			stretch = 1.1
		"air":
			y = 0.0
			arm_l = Vector3(0, 0, 2.3)
			arm_r = Vector3(0, 0, -2.3)
			foot_l = Vector3(0, 0.12, 0.1)
			foot_r = Vector3(0, 0.12, -0.1)
		"stun":
			turn = sin(_t * 6.0) * 0.25
			tilt = sin(_t * 9.0) * 0.14
			arm_l = Vector3(0, 0, 0.7)
			arm_r = Vector3(0, 0, -0.7)
			head_tilt = sin(_t * 10.0) * 0.2
		"freeze":
			arm_l = Vector3(-0.4, 0, 0.5)
			arm_r = Vector3(0.4, 0, -0.5)
		"root":
			y = sin(_t * 18.0) * 0.015
			arm_l = Vector3(sin(_t * 12.0) * 0.5, 0, 0.3)
			arm_r = Vector3(-sin(_t * 12.0) * 0.5, 0, -0.3)
		"jail":
			y = -0.1
			head_tilt = 0.22
			arm_l = Vector3(-0.2 + sin(_t * 3.0) * 0.2, 0, -1.9)
			arm_r = Vector3(-0.2 - sin(_t * 3.0) * 0.2, 0, 1.9)
		"sad":
			y = -0.12
			head_tilt = 0.34
			arm_l = Vector3(0.1, 0, 0.1)
			arm_r = Vector3(0.1, 0, -0.1)
		"dance":
			var d := _dance()
			y = d["y"]
			turn = d["turn"]
			tilt = d["tilt"]
			arm_l = d["arm_l"]
			arm_r = d["arm_r"]
			foot_l = d["foot_l"]
			foot_r = d["foot_r"]
		_:  # idle: breathing, with a little look around, hands held out where you can see them.
			y = sin(_t * 2.6) * 0.018
			arm_l = Vector3(sin(_t * 2.6) * 0.08, 0, 0.42 + sin(_t * 2.6) * 0.05)
			arm_r = Vector3(-sin(_t * 2.6) * 0.08, 0, -0.42 - sin(_t * 2.6) * 0.05)
			head_tilt = sin(_t * 0.9) * 0.05
	if state != "run":
		_hover_extra = 0.0
	_hips.position.y = y + _hover_extra
	# Poses say "outward" with a plus on the left arm and a minus on the right; the hinges run the other way.
	arm_l.z = -arm_l.z
	arm_r.z = -arm_r.z
	_hips.rotation = Vector3(tilt, turn, 0)
	var sq := _squash
	_hips.scale = Vector3(1.0 + sq * 0.5, stretch * (1.0 - sq * 0.6), 1.0 + sq * 0.5)
	if _head:
		_head.rotation.x = head_tilt
	if _arm_l:
		_arm_l.rotation = _arm_l.rotation.lerp(arm_l, clampf(delta * 16.0, 0.0, 1.0))
		_arm_r.rotation = _arm_r.rotation.lerp(arm_r, clampf(delta * 16.0, 0.0, 1.0))
	if _foot_l:
		_foot_l.position = Vector3(-FOOT_X, FOOT_Y + foot_l.y, foot_l.z)
		_foot_r.position = Vector3(FOOT_X, FOOT_Y + foot_r.y, foot_r.z)
	if _back and (look.get("back", "") in ["angel", "bat", "dragon", "butterfly"]):
		_back.rotation.y = sin(_t * (9.0 if state == "run" else 3.0)) * 0.12
	if _hat and look.get("hat", "") == "propeller":
		_hat.rotation.y = 0.0
	_tick_blink(delta)
	if _flash > 0.0:
		set_material_kind("flash")
	elif _material_kind == "flash":
		set_material_kind("normal")


## The run cycle, by the player's run style.
func _run_pose() -> Dictionary:
	var m := moving
	var phase := _t * 13.0
	var swing := sin(phase)
	var out := {"y": absf(swing) * 0.09 * m, "tilt": 0.2 * m, "turn": 0.0, "head": -0.08 * m, "hover": 0.0,
		"arm_l": Vector3(swing * 0.9 * m, 0, 0.32), "arm_r": Vector3(-swing * 0.9 * m, 0, -0.32),
		"foot_l": Vector3(0, maxf(cos(phase), 0.0) * 0.16, swing * 0.26) * m,
		"foot_r": Vector3(0, maxf(-cos(phase), 0.0) * 0.16, -swing * 0.26) * m}
	match run_id:
		"strut":
			out["turn"] = swing * 0.28 * m
			out["tilt"] = -0.04
			out["arm_l"] = Vector3(swing * 0.5 * m, 0, 0.45)
			out["arm_r"] = Vector3(-swing * 0.5 * m, 0, -0.45)
		"skip":
			phase = _t * 9.0
			swing = sin(phase)
			out["y"] = absf(sin(phase)) * 0.3 * m
			out["arm_l"] = Vector3(0, 0, 1.1 + swing * 0.8)
			out["arm_r"] = Vector3(0, 0, -1.1 + swing * 0.8)
		"waddle":
			out["tilt"] = 0.0
			out["turn"] = swing * 0.14 * m
			out["y"] = absf(swing) * 0.05 * m
			out["arm_l"] = Vector3(0, 0, 0.7 + swing * 0.2)
			out["arm_r"] = Vector3(0, 0, -0.7 + swing * 0.2)
			out["head"] = swing * 0.12
		"tiptoe":
			phase = _t * 17.0
			swing = sin(phase)
			out["y"] = 0.14 + absf(swing) * 0.03
			out["tilt"] = 0.05
			out["arm_l"] = Vector3(-1.2, 0, 0.35)
			out["arm_r"] = Vector3(-1.2, 0, -0.35)
			out["foot_l"] = Vector3(0, maxf(cos(phase), 0.0) * 0.08, swing * 0.1) * m
			out["foot_r"] = Vector3(0, maxf(-cos(phase), 0.0) * 0.08, -swing * 0.1) * m
		"robot":
			var step: float = floor(_t * 7.0)
			var side: float = 1.0 if int(step) % 2 == 0 else -1.0
			out["y"] = 0.04
			out["tilt"] = 0.0
			out["arm_l"] = Vector3(side * 0.9, 0, 0.05)
			out["arm_r"] = Vector3(-side * 0.9, 0, -0.05)
			out["foot_l"] = Vector3(0, 0.1 if side > 0.0 else 0.0, side * 0.2) * m
			out["foot_r"] = Vector3(0, 0.1 if side < 0.0 else 0.0, -side * 0.2) * m
		"zombie":
			out["tilt"] = 0.3
			out["turn"] = sin(_t * 3.0) * 0.14
			out["arm_l"] = Vector3(-1.5, 0, 0.1)
			out["arm_r"] = Vector3(-1.5, 0, -0.1)
			out["head"] = 0.25
		"hop":
			phase = _t * 8.0
			out["y"] = absf(sin(phase)) * 0.46 * m
			out["arm_l"] = Vector3(-0.9, 0, 0.2)
			out["arm_r"] = Vector3(-0.9, 0, -0.2)
			out["foot_l"] = Vector3(0, absf(sin(phase)) * 0.4, 0) * m
			out["foot_r"] = Vector3(0, absf(sin(phase)) * 0.4, 0) * m
		"arms_back":
			out["tilt"] = 0.55 * m
			out["arm_l"] = Vector3(1.5, 0, 0.3)
			out["arm_r"] = Vector3(1.5, 0, -0.3)
			out["head"] = -0.4 * m
		"spin":
			out["turn"] = _t * 14.0
			out["tilt"] = 0.0
			out["arm_l"] = Vector3(0, 0, 1.5)
			out["arm_r"] = Vector3(0, 0, -1.5)
		"float":
			out["hover"] = 0.3 + sin(_t * 4.0) * 0.06
			out["y"] = 0.0
			out["tilt"] = 0.14 * m
			out["arm_l"] = Vector3(0.2, 0, 0.5)
			out["arm_r"] = Vector3(0.2, 0, -0.5)
			out["foot_l"] = Vector3(0, 0.3, -0.1)
			out["foot_r"] = Vector3(0, 0.3, -0.1)
	return out


func _dance() -> Dictionary:
	var out := {"y": 0.0, "turn": 0.0, "tilt": 0.0, "arm_l": Vector3(0, 0, 0.3), "arm_r": Vector3(0, 0, -0.3), "foot_l": Vector3.ZERO, "foot_r": Vector3.ZERO}
	match dance_id:
		"wave":
			out["y"] = absf(sin(_t * 3.0)) * 0.05
			out["arm_r"] = Vector3(0, 0, -2.6 + sin(_t * 11.0) * 0.5)
			out["arm_l"] = Vector3(0, 0, 0.2)
		"spin":
			out["y"] = absf(sin(_t * 5.0)) * 0.12
			out["turn"] = _t * 9.0
			out["arm_l"] = Vector3(0, 0, 1.5)
			out["arm_r"] = Vector3(0, 0, -1.5)
		"twist":
			var s := sin(_t * 7.0)
			out["turn"] = s * 0.8
			out["y"] = absf(s) * 0.04
			out["arm_l"] = Vector3(s * 0.8, 0, 0.8)
			out["arm_r"] = Vector3(-s * 0.8, 0, -0.8)
			out["foot_l"] = Vector3(0, 0, s * 0.12)
			out["foot_r"] = Vector3(0, 0, -s * 0.12)
		"robot":
			var step: float = floor(_t * 4.0)
			var a: float = -1.5 if int(step) % 2 == 0 else 0.0
			out["arm_l"] = Vector3(a, 0, 0.1)
			out["arm_r"] = Vector3(-1.5 - a, 0, -0.1)
			out["turn"] = 0.3 if int(step) % 4 < 2 else -0.3
			out["y"] = 0.03 if int(step) % 2 == 0 else 0.0
		"tinikling":
			var s := sin(_t * 8.0)
			out["y"] = absf(s) * 0.2
			out["foot_l"] = Vector3(s * 0.2, absf(s) * 0.12, 0)
			out["foot_r"] = Vector3(-s * 0.2, absf(s) * 0.12, 0)
			out["arm_l"] = Vector3(0, 0, 1.2 + s * 0.3)
			out["arm_r"] = Vector3(0, 0, -1.2 + s * 0.3)
		"flip":
			var loop := fmod(_t, 1.6) / 1.6
			var air := clampf((loop - 0.2) / 0.6, 0.0, 1.0)
			out["y"] = sin(air * PI) * 1.0
			out["tilt"] = -air * TAU
			out["arm_l"] = Vector3(0, 0, 2.2)
			out["arm_r"] = Vector3(0, 0, -2.2)
		"superstar":
			var loop := sin(_t * 6.0)
			out["y"] = absf(loop) * 0.28
			out["turn"] = _t * 3.5
			out["arm_l"] = Vector3(0, 0, 2.5 + loop * 0.4)
			out["arm_r"] = Vector3(0, 0, -2.5 + loop * 0.4)
		_:
			var hop := absf(sin(_t * 5.5))
			out["y"] = hop * 0.28
			out["arm_l"] = Vector3(0, 0, 2.4 + hop * 0.3)
			out["arm_r"] = Vector3(0, 0, -2.4 - hop * 0.3)
	return out


## Sends trail and aura particles to `fx`. Called by whoever owns the avatar.
func emit_effects(fx: FxField, delta: float, is_moving: bool) -> void:
	if not visible:
		return
	if is_moving and not _trail.is_empty():
		_emit += delta * float(_trail.get("rate", 10.0)) * fx.density
		while _emit >= 1.0:
			_emit -= 1.0
			_trail_i += 1
			var colors: Array = _trail["c"]
			var c := Color(colors[_trail_i % colors.size()])
			var at := global_position + Vector3(randf_range(-0.2, 0.2), 0.15 + randf() * 0.2, randf_range(-0.2, 0.2))
			fx.spawn(at, Vector3(randf_range(-0.3, 0.3), float(_trail.get("rise", 0.5)), randf_range(-0.3, 0.3)), 0.7, float(_trail["size"]), int(_trail["fx"]), c, randf_range(-3.0, 3.0))
	if _aura.has("c"):
		_orbit += delta * 2.4
		_emit += delta * 12.0 * fx.density
		while _emit >= 1.0:
			_emit -= 1.0
			_trail_i += 1
			var colors: Array = _aura["c"]
			var c := Color(colors[_trail_i % colors.size()])
			var a := _orbit + _trail_i * 2.4
			var at := global_position + Vector3(cos(a) * 0.8, 0.2 + fmod(_trail_i * 0.37, 1.5), sin(a) * 0.8)
			fx.spawn(at, Vector3(0, 0.55, 0), 0.6, 0.26, int(_aura["fx"]), c, 0.8)


func aura_ring_color() -> Color:
	return Color(_aura["ring"]) if _aura.has("ring") else Color(0, 0, 0, 0)


## How much wider clothes are than a kid's body, so they fit over any avatar.
static func _clothes_width(hero: Dictionary) -> float:
	if hero.get("kind") == "kid":
		return 1.0
	if hero.get("kind") == "animal":
		return 1.24
	match String(hero.get("shape")):
		"robot", "crystal", "flame":
			return 1.06
		"ghost":
			return 1.34
	return 1.16


## One accessory's mesh on its own, for shop pictures. Kid-sized.
func accessory_mesh(slot: String, id: String) -> ArrayMesh:
	match slot:
		"mask":
			return _shared("mask|" + id, AvatarParts.mask.bind(id))
		"hat":
			return _shared("hat|" + id, _build_hat.bind(id))
		"back":
			return _shared("back|" + id, _build_back.bind(id, Color("ffb21f")))
		"top":
			return _shared("top|%s|%.2f" % [id, 1.0], AvatarParts.top.bind(id, 1.0))
		"pants":
			return _shared("pants|%s|%.2f" % [id, 1.0], AvatarParts.pants.bind(id, 1.0))
		"shoes":
			return _shared("shoes|" + id, AvatarParts.shoe.bind(id))
		"gloves":
			return _shared("gloves|" + id, AvatarParts.glove.bind(id))
	return null
