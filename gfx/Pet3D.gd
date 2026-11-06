class_name Pet3D
extends Node3D
## A little companion: a soft round blob with big eyes, built from the parts its row in WorldItems.PETS names. It trots after
## its owner, hops as it goes, stops to look round, and has feelings about how the match is going. Purely for show.

const REACH := 1.5  ## How far behind its owner it likes to stay.
const SPEED := 9.5

static var _meshes := {}

var pet_id := ""
var _body: MeshInstance3D
var _t := randf() * 10.0
var _hop := 0.0
var _side := 1.0
var _mood_left := 0.0
var _spin := 0.0
var _floaty := false


## The whole pet as one mesh, standing on y = 0 and facing +z. Shared by every copy of it.
static func mesh(id: String) -> ArrayMesh:
	if not _meshes.has(id):
		var k := MeshKit.new()
		k.outline = 0.02
		k.soften = true
		k.shells = false
		k.detail = 0.8 if Quality.is_low() else 1.0
		_build(k, Cosmetics.item("pet", id))
		_meshes[id] = k.to_mesh()
	return _meshes[id]


func setup(id: String) -> void:
	pet_id = id
	_side = 1.0 if randf() < 0.5 else -1.0
	for child in get_children():
		child.queue_free()
	_body = null
	if id == "" or Cosmetics.item("pet", id).is_empty():
		return
	_body = MeshInstance3D.new()
	_body.mesh = mesh(id)
	_body.material_override = Avatar3D._material("normal")
	_body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_body)
	var body_kind := String(Cosmetics.item("pet", id).get("body", ""))
	_floaty = body_kind in ["ghost", "ufo", "cloud"]


## Heads for a spot just behind its owner. `owner_pos` is on the ground; `facing` is the way the owner looks.
func follow(delta: float, owner_pos: Vector3, facing: Vector3, owner_moving: bool, fx: FxField = null) -> void:
	if _body == null:
		return
	var goal := owner_pos - facing * REACH * 0.6 + facing.cross(Vector3.UP) * _side * REACH * 0.6
	goal.y = 0.0
	var to_goal := goal - Vector3(position.x, 0, position.z)
	var far := to_goal.length()
	if far > 12.0:  # Left behind by a warp: it pops along after you.
		position = goal
		if fx:
			fx.burst(goal + Vector3(0, 0.4, 0), 6, 2.5, 0.3, 0.26, Cosmetics.Fx.PUFF, ["ffffff"], 0.0)
		far = 0.0
	var moving := far > 0.35
	if moving:
		var step := minf(SPEED * delta * clampf(far * 0.8, 0.5, 1.6), far)
		position += to_goal / far * step
		_look_along(to_goal / far, delta)
	elif owner_moving:
		_look_along(facing, delta)
	_animate(delta, moving)


func _look_along(dir: Vector3, delta: float) -> void:
	if dir.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), clampf(delta * 10.0, 0.0, 1.0))


## Runs on the spot, for someone else to move about: the title screen.
func follow_in_place(delta: float) -> void:
	if _body:
		_animate(delta, true)


## Stands where it's put and potters about: for the menus.
func idle(delta: float) -> void:
	if _body == null:
		return
	_animate(delta, false)


## A little jump for joy, or a spin when something's gone wrong.
func cheer(seconds := 1.2) -> void:
	_mood_left = seconds


func dizzy() -> void:
	_spin = 1.0


func _animate(delta: float, moving: bool) -> void:
	_t += delta
	_mood_left = maxf(_mood_left - delta, 0.0)
	_spin = maxf(_spin - delta * 1.4, 0.0)
	var happy := _mood_left > 0.0
	var pace := 13.0 if moving else (10.0 if happy else 2.2)
	var height := 0.2 if moving else (0.34 if happy else 0.015)
	_hop = absf(sin(_t * pace)) * height
	if _floaty:
		_body.position.y = 0.3 + sin(_t * 2.6) * 0.07
		_body.rotation.z = sin(_t * 1.8) * 0.08
	else:
		_body.position.y = _hop
		var squash := 1.0 + (0.08 if moving or happy else 0.03) * cos(_t * pace * 2.0)
		_body.scale = Vector3(1.0 / sqrt(squash), squash, 1.0 / sqrt(squash))
		_body.rotation.z = sin(_t * pace) * (0.14 if moving else 0.03)
	_body.rotation.y = _spin * TAU * 2.0


# --- Building one --------------------------------------------------------------------------------------

static func _build(k: MeshKit, def: Dictionary) -> void:
	var c := Color(def.get("c", "ffffff"))
	var c2 := Color(def.get("c2", "ffffff"))
	match String(def.get("body", "")):
		"slime": _slime(k, c, c2)
		"rock": _rock(k, c, c2)
		"ghost": _ghost(k, c, c2)
		"robot": _robot(k, c, c2)
		"toast": _toast(k, c, c2)
		"onigiri": _onigiri(k, c, c2)
		"cactus": _cactus(k, c, c2)
		"cloud": _cloud(k, c, c2)
		"ufo": _ufo(k, c, c2)
		_: _animal(k, def, c, c2)


## Dark dot eyes with a glint, well apart and low on the face: most of what makes it cute.
static func _eyes(k: MeshKit, y: float, z: float, gap: float, size := 0.05) -> void:
	k.outline = 0.0
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * gap, y, z), Vector3(size * 0.9, size * 1.1, size * 0.4), Color("0a1426"), 6, 10)
		k.ball(Vector3(s * gap - size * 0.25, y + size * 0.4, z + size * 0.28), Vector3(size * 0.28, size * 0.3, size * 0.14), Color.WHITE, 3, 6)
	k.outline = 0.02


static func _smile(k: MeshKit, y: float, z: float, width := 0.05) -> void:
	k.outline = 0.0
	var path := PackedVector3Array()
	for i in 7:
		var f := lerpf(-1.0, 1.0, i / 6.0)
		path.append(Vector3(f * width, y - (1.0 - f * f) * width * 0.5, z - absf(f) * 0.012))
	k.tube(path, 0.009, Color("0a1426"), false, 4)
	k.outline = 0.02


static func _feet(k: MeshKit, color: Color, wide := 0.14, long := 0.13) -> void:
	for s: float in [-1.0, 1.0]:
		for z: float in [long, -long]:
			k.ball(Vector3(s * wide, 0.045, z), Vector3(0.062, 0.05, 0.075), color, 6, 8)


static func _animal(k: MeshKit, def: Dictionary, c: Color, c2: Color) -> void:
	var extra: Array = def.get("extra", [])
	var has := func(part: String) -> bool: return extra.has(part)
	var long_body: bool = has.call("long_body")
	var tall: bool = has.call("tall")
	var short: bool = has.call("short")
	var r := Vector3(0.27, 0.25, 0.25)
	var body_y := 0.26
	if short:
		body_y = 0.22
		r = Vector3(0.28, 0.21, 0.25)
	if tall:
		r = Vector3(0.21, 0.31, 0.2)
		body_y = 0.32
	var back := Vector3(0, body_y, 0)
	var feet_color: Color = Color("2b2448") if has.call("dark_legs") else c.darkened(0.1)
	if long_body:
		k.ball(Vector3(0, 0.2, -0.28), Vector3(0.2, 0.17, 0.42), c, 10, 14)
		_feet(k, c.darkened(0.14), 0.13, 0.0)
		for s: float in [-1.0, 1.0]:
			k.ball(Vector3(s * 0.13, 0.045, -0.5), Vector3(0.06, 0.05, 0.07), c.darkened(0.14), 6, 8)
	else:
		_feet(k, feet_color, 0.16 if not short else 0.17, 0.13)
	# Neck and head stand up on the long-necked ones.
	var head := back
	var head_r := r
	if has.call("neck"):
		k.ball(back + Vector3(0, -0.03, -0.04), Vector3(0.21, 0.2, 0.24), c, 10, 14)
		k.tube(PackedVector3Array([back + Vector3(0, 0.05, 0.05), back + Vector3(0, 0.25, 0.08), back + Vector3(0, 0.42, 0.1)]), 0.09, c, false, 10, 0.08)
		head = back + Vector3(0, 0.5, 0.12)
		head_r = Vector3(0.17, 0.14, 0.16)
	k.ball(head, head_r, c, 12, 16)
	if has.call("hump"):
		k.ball(back + Vector3(0, 0.2, -0.1), Vector3(0.16, 0.14, 0.15), c.lightened(0.05), 8, 10)
	if has.call("blanket"):
		k.band(back + Vector3(0, -0.03, -0.04), Vector3(0.215, 0.205, 0.245), 0.0, 0.16, Color("e8483f"), 0.004, 20, 4)
	var face_z := head.z + head_r.z * 0.92
	var face_y := head.y - head_r.y * 0.04
	var belly: bool = not has.call("neck") and not has.call("shell")
	k.outline = 0.0
	if belly:
		var size := Vector3(r.x * 0.72, r.y * 0.72, 0.1) if not has.call("belly_big") else Vector3(r.x * 0.86, r.y * 0.84, 0.1)
		k.ball(Vector3(0, body_y - r.y * 0.28, r.z - 0.085), size, c2, 8, 12)
	if has.call("face_patch"):
		k.ball(Vector3(0, face_y - 0.03, face_z - 0.05), Vector3(head_r.x * 0.72, head_r.y * 0.6, 0.08), c2, 8, 12)
	if has.call("dark_face"):
		k.ball(Vector3(0, face_y, face_z - 0.05), Vector3(head_r.x * 0.72, head_r.y * 0.72, 0.08), Color("2b2448"), 8, 12)
	if has.call("eye_patches") or has.call("eye_patches_brown"):
		var patch := Color("2b2448") if has.call("eye_patches") else Color("7a4a26")
		for s: float in [-1.0, 1.0]:
			k.push(Transform3D(Basis(Vector3.BACK, s * 0.3), Vector3(s * head_r.x * 0.42, face_y + 0.03, face_z - 0.025)))
			k.ball(Vector3.ZERO, Vector3(0.065, 0.08, 0.03), patch, 4, 10)
			k.pop()
	if has.call("stripes") or has.call("stripes_dark"):
		var line := Color("2a2438")
		for i in 3:
			var a := -0.6 + i * 0.6
			k.push(Transform3D(Basis(Vector3.BACK, a), head + Vector3(sin(a) * head_r.x * 0.55, head_r.y * 0.84 * cos(a), head_r.z * 0.32)))
			k.ball(Vector3.ZERO, Vector3(0.018, 0.05, 0.03), line, 3, 6)
			k.pop()
		for s: float in [-1.0, 1.0]:
			for y: float in [0.05, -0.05]:
				k.ball(Vector3(s * r.x * 0.97, body_y + y, 0.03), Vector3(0.012, 0.018, 0.07), line, 3, 6)
	if has.call("spots"):
		for at: Vector3 in [Vector3(0.14, 0.24, 0.14), Vector3(-0.13, 0.3, 0.13), Vector3(-0.17, 0.16, -0.08), Vector3(0.18, 0.12, -0.04), Vector3(0.08, 0.56, 0.17), Vector3(-0.07, 0.48, 0.16)]:
			k.ball(at, Vector3(0.042, 0.042, 0.03), Color("c98a4a"), 3, 7)
	k.outline = 0.02
	# Eyes up top, or the ordinary kind.
	if has.call("top_eyes"):
		for s: float in [-1.0, 1.0]:
			k.ball(head + Vector3(s * 0.13, head_r.y * 0.95, 0.06), Vector3(0.085, 0.085, 0.08), c, 8, 10)
		_eyes(k, head.y + head_r.y * 0.98, head.z + 0.135, 0.13, 0.05)
	elif has.call("big_eyes"):
		for s: float in [-1.0, 1.0]:
			k.outline = 0.0
			k.ball(Vector3(s * 0.11, face_y + 0.04, face_z - 0.03), Vector3(0.095, 0.095, 0.03), Color.WHITE, 4, 12)
			k.outline = 0.02
		_eyes(k, face_y + 0.04, face_z, 0.11, 0.058)
	else:
		_eyes(k, face_y + 0.04, face_z - 0.015, head_r.x * 0.5, 0.048)
	if has.call("wide_mouth"):
		_smile(k, face_y - 0.05, face_z - 0.005, 0.11)
	if has.call("cheeks"):
		for s: float in [-1.0, 1.0]:
			k.ball(Vector3(s * head_r.x * 0.82, face_y - 0.06, head.z + head_r.z * 0.5), Vector3(0.1, 0.09, 0.09), c.lightened(0.14), 6, 10)
	else:
		k.outline = 0.0
		for s: float in [-1.0, 1.0]:
			k.ball(Vector3(s * head_r.x * 0.72, face_y - 0.035, face_z - 0.09), Vector3(0.045, 0.028, 0.02), Color(1.0, 0.55, 0.6), 3, 7)
		k.outline = 0.02
	_nose(k, String(def.get("nose", "none")), Vector3(0, face_y - 0.025, face_z), c)
	_ears(k, String(def.get("ears", "none")), head, head_r, c, c2)
	_tail(k, String(def.get("tail", "none")), Vector3(0, body_y, -r.z - (0.5 if long_body else 0.0)), c, c2)
	if has.call("whiskers"):
		k.outline = 0.0
		for s: float in [-1.0, 1.0]:
			for dy: float in [0.012, -0.018]:
				k.tube(PackedVector3Array([Vector3(s * 0.1, face_y - 0.03, face_z - 0.03), Vector3(s * 0.25, face_y - 0.03 + dy * 3.0, face_z - 0.05)]), 0.004, Color("0a1426"), false, 3)
		k.outline = 0.02
	if has.call("wings"):
		for s: float in [-1.0, 1.0]:
			k.push(Transform3D(Basis(Vector3.BACK, s * -0.3), Vector3(s * (r.x + 0.01), body_y, -0.02)))
			k.ball(Vector3.ZERO, Vector3(0.05, 0.13, 0.1), c.darkened(0.07), 6, 8)
			k.pop()
	if has.call("wings_big"):
		for s: float in [-1.0, 1.0]:
			k.push(Transform3D(Basis(Vector3.BACK, s * -0.7), Vector3(s * 0.2, body_y + 0.14, -0.12)))
			k.ball(Vector3(0, 0.15, 0), Vector3(0.14, 0.2, 0.018), c2, 6, 10)
			k.pop()
	if has.call("comb"):
		for i in 3:
			k.ball(head + Vector3(0, head_r.y + 0.02, 0.06 - i * 0.07), Vector3(0.036, 0.06, 0.036), Color("ff3f3f"), 5, 7)
	if has.call("horn"):
		k.cone(head + Vector3(0, head_r.y * 0.84, head_r.z * 0.4), 0.2, 0.038, Color("ffd23f"), 8)
	if has.call("horns"):
		for s: float in [-1.0, 1.0]:
			k.cone(head + Vector3(s * 0.08, head_r.y * 0.82, 0.0), 0.11, 0.032, Color("fff6dd"), 7)
	if has.call("ossicones"):
		for s: float in [-1.0, 1.0]:
			k.cyl(head + Vector3(s * 0.06, head_r.y * 0.8, 0.0), 0.09, 0.016, 0.016, Color("c98a4a"), 6)
			k.ball(head + Vector3(s * 0.06, head_r.y * 0.8 + 0.1, 0.0), Vector3(0.028, 0.028, 0.028), Color("7a4a26"), 4, 6)
	if has.call("antlers") or has.call("moose_antlers"):
		var horn := Color("c9985e")
		for s: float in [-1.0, 1.0]:
			if has.call("moose_antlers"):
				k.ball(head + Vector3(s * 0.2, head_r.y * 0.95, 0.0), Vector3(0.13, 0.05, 0.09), horn, 6, 10)
			else:
				k.tube(PackedVector3Array([head + Vector3(s * 0.09, head_r.y * 0.8, 0.0), head + Vector3(s * 0.15, head_r.y + 0.1, 0.0), head + Vector3(s * 0.24, head_r.y + 0.18, 0.0)]), 0.018, horn, false, 6, 0.01)
				k.tube(PackedVector3Array([head + Vector3(s * 0.14, head_r.y + 0.06, 0.0), head + Vector3(s * 0.08, head_r.y + 0.16, 0.0)]), 0.012, horn, false, 5, 0.008)
	if has.call("mane"):
		for i in 10:
			var a := TAU * i / 10.0
			k.ball(head + Vector3(cos(a) * head_r.x * 0.98, sin(a) * head_r.y * 0.98, -0.03), Vector3(0.095, 0.095, 0.08), Color("c9702f"), 6, 8)
		# The face goes back on over it.
		k.outline = 0.0
		k.ball(Vector3(0, face_y, face_z - 0.1), Vector3(head_r.x * 0.72, head_r.y * 0.72, 0.09), c, 6, 10)
		k.outline = 0.02
		_eyes(k, face_y + 0.04, face_z - 0.015, head_r.x * 0.42, 0.048)
		_nose(k, "dot", Vector3(0, face_y - 0.025, face_z), c)
	if has.call("mane_rainbow"):
		var colours := [Color("ff8fbf"), Color("ffd23f"), Color("7ee8ff"), Color("b768ff")]
		for i in 5:
			k.ball(head + Vector3(0, head_r.y * 0.9 - i * 0.075, -0.06 - i * 0.04), Vector3(0.06, 0.07, 0.06), colours[i % 4], 5, 7)
	if has.call("shell"):
		k.dome(Vector3(0, body_y - 0.06, -0.02), Vector3(0.3, 0.28, 0.27), Color("3a9c4e"), 8, 16)
		k.outline = 0.0
		for at: Vector3 in [Vector3(0, 0.46, -0.05), Vector3(0.14, 0.38, 0.06), Vector3(-0.14, 0.38, 0.06), Vector3(0.14, 0.36, -0.14), Vector3(-0.14, 0.36, -0.14)]:
			k.ball(at, Vector3(0.05, 0.03, 0.05), Color("7ed957"), 3, 7)
		k.outline = 0.02
	if has.call("wool"):
		for i in 11:
			var a := TAU * i / 11.0
			k.ball(head + Vector3(cos(a) * r.x * 0.85, sin(a) * r.y * 0.85 + 0.02, -0.05), Vector3(0.09, 0.09, 0.1), c, 5, 7)
		for z: float in [-0.12, 0.0]:
			k.ball(head + Vector3(0, r.y * 0.9, z), Vector3(0.1, 0.07, 0.09), c, 5, 7)
		k.outline = 0.0
		k.ball(Vector3(0, face_y, face_z - 0.055), Vector3(head_r.x * 0.62, head_r.y * 0.66, 0.05), Color("2b2448"), 6, 10)
		k.outline = 0.02
		_eyes(k, face_y + 0.04, face_z - 0.018, head_r.x * 0.32, 0.038)
	if has.call("spines") or has.call("spines_small"):
		var spine := Color("7a5a3c") if has.call("spines") else Color("ffd23f")
		var count := 14 if has.call("spines") else 5
		for i in count:
			var a := lerpf(-1.3, 1.3, float(i % 5) / 4.0) if has.call("spines") else 0.0
			var e := float(i / 5) * 0.5 + 0.45 if has.call("spines") else 0.3 + i * 0.28
			var dir := Vector3(sin(a) * cos(e), sin(e), -cos(a) * cos(e) - 0.2).normalized() if has.call("spines") else Vector3(0, sin(e), -cos(e))
			k.push(Transform3D(Basis.looking_at(dir, Vector3.RIGHT) * Basis(Vector3.RIGHT, -PI * 0.5), back + dir * Vector3(r.x, r.y, r.z)))
			k.cone(Vector3.ZERO, 0.1 if has.call("spines") else 0.09, 0.034, spine, 6)
			k.pop()
	if has.call("teeth"):
		k.outline = 0.0
		k.soft_box(Vector3(0, face_y - 0.075, face_z - 0.005), Vector3(0.035, 0.03, 0.012), Color.WHITE, 0.7, 3, 6)
		k.outline = 0.02
	if has.call("gills"):
		for s: float in [-1.0, 1.0]:
			for a: float in [0.5, 0.0, -0.5]:
				k.push(Transform3D(Basis(Vector3.BACK, s * (a - PI * 0.5)), head + Vector3(s * head_r.x * 0.85, 0.06 + a * 0.1, 0.02)))
				k.ball(Vector3(0, 0.08, 0), Vector3(0.022, 0.09, 0.022), Color("ff5aa5"), 4, 6)
				k.pop()
	if has.call("pouch"):
		k.outline = 0.0
		k.ball(Vector3(0, body_y - 0.11, r.z - 0.015), Vector3(0.11, 0.07, 0.03), c, 4, 10)
		k.ball(Vector3(0, body_y - 0.07, r.z + 0.0), Vector3(0.055, 0.05, 0.02), Color("ffb08a"), 3, 8)
		k.outline = 0.02
	if has.call("collar"):
		k.torus(Vector3(0, body_y - 0.12, 0), r.x * 0.86, 0.02, Color("e8282f"), 18, 5)
		k.ball(Vector3(0, body_y - 0.14, r.z * 0.86), Vector3(0.04, 0.04, 0.04), Color("ffd23f"), 4, 7)
	if has.call("paw_up"):
		k.ball(Vector3(0.24, body_y + 0.1, 0.1), Vector3(0.07, 0.11, 0.07), c, 6, 8)


static func _nose(k: MeshKit, kind: String, at: Vector3, c: Color) -> void:
	k.outline = 0.0
	match kind:
		"dot":
			k.ball(at, Vector3(0.024, 0.018, 0.012), Color("0a1426"), 3, 7)
			_smile(k, at.y - 0.03, at.z - 0.005, 0.03)
		"pink":
			k.ball(at, Vector3(0.024, 0.018, 0.012), Color("ff7fa8"), 3, 7)
			_smile(k, at.y - 0.03, at.z - 0.005, 0.03)
		"red":
			k.ball(at + Vector3(0, 0, 0.012), Vector3(0.042, 0.036, 0.03), Color("ff3f3f"), 4, 8)
			_smile(k, at.y - 0.05, at.z - 0.004, 0.03)
		"big_dark":
			k.ball(at + Vector3(0, -0.005, 0.008), Vector3(0.05, 0.04, 0.02), Color("2b2448"), 4, 9)
			_smile(k, at.y - 0.05, at.z - 0.005, 0.03)
		"snout":
			k.outline = 0.02
			k.ball(at + Vector3(0, -0.01, 0.02), Vector3(0.07, 0.05, 0.04), c.lightened(0.14), 6, 10)
			k.outline = 0.0
			for s: float in [-1.0, 1.0]:
				k.ball(at + Vector3(s * 0.024, -0.01, 0.055), Vector3(0.012, 0.016, 0.008), Color("c94f7a"), 3, 6)
		"beak":
			k.outline = 0.02
			k.ball(at + Vector3(0, -0.01, 0.025), Vector3(0.05, 0.03, 0.05), Color("ff9d2e"), 6, 8)
		"bill":
			k.outline = 0.02
			k.ball(at + Vector3(0, -0.015, 0.03), Vector3(0.08, 0.026, 0.07), Color("ff9d2e"), 6, 10)
		"big_beak":
			k.outline = 0.02
			k.ball(at + Vector3(0, -0.03, 0.1), Vector3(0.075, 0.08, 0.16), Color("ff9d2e"), 8, 10)
			k.outline = 0.0
			k.ball(at + Vector3(0, 0.0, 0.2), Vector3(0.04, 0.035, 0.06), Color("e8282f"), 4, 7)
		"long_beak":
			k.outline = 0.02
			k.push(Transform3D(Basis(Vector3.RIGHT, 1.25), at + Vector3(0, -0.02, 0.0)))
			k.cone(Vector3.ZERO, 0.24, 0.024, Color("fff1c9"), 7)
			k.pop()
		"trunk":
			k.outline = 0.02
			k.tube(PackedVector3Array([at + Vector3(0, 0.01, -0.03), at + Vector3(0, -0.04, 0.06), at + Vector3(0, -0.13, 0.1), at + Vector3(0, -0.22, 0.17)]), 0.045, c, false, 8, 0.028)
	k.outline = 0.02


static func _ears(k: MeshKit, kind: String, head: Vector3, r: Vector3, c: Color, c2: Color) -> void:
	for s: float in [-1.0, 1.0]:
		var top := head + Vector3(s * r.x * 0.58, r.y * 0.8, 0.0)
		match kind:
			"pointy":
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.24), top - Vector3(0, 0.03, 0)))
				k.cone(Vector3.ZERO, 0.15, 0.08, c, 8)
				k.pop()
			"floppy":
				k.push(Transform3D(Basis(Vector3.BACK, s * -1.1), head + Vector3(s * r.x * 0.75, r.y * 0.55, 0.0)))
				k.ball(Vector3(0, 0.06, 0), Vector3(0.06, 0.13, 0.05), c.darkened(0.16), 6, 8)
				k.pop()
			"round", "round_dark":
				k.ball(top, Vector3(0.07, 0.07, 0.045), Color("2b2448") if kind == "round_dark" else c, 6, 9)
			"long":
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.14), top - Vector3(0, 0.02, 0)))
				k.ball(Vector3(0, 0.15, 0), Vector3(0.05, 0.18, 0.038), c, 8, 10)
				k.outline = 0.0
				k.ball(Vector3(0, 0.15, 0.03), Vector3(0.024, 0.13, 0.012), c2 if c2 != Color.WHITE else Color("ffd0e0"), 3, 7)
				k.outline = 0.02
				k.pop()
			"big":
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.26), top - Vector3(0, 0.02, 0)))
				k.ball(Vector3(0, 0.08, 0), Vector3(0.09, 0.13, 0.04), c, 8, 10)
				k.pop()
			"small", "small_dark":
				k.ball(head + Vector3(s * r.x * 0.82, r.y * 0.5, 0.0), Vector3(0.05, 0.035, 0.035), Color("2b2448") if kind == "small_dark" else c.darkened(0.1), 5, 7)
			"fan":
				k.ball(head + Vector3(s * (r.x + 0.1), 0.03, -0.03), Vector3(0.14, 0.17, 0.03), c, 8, 12)
				k.outline = 0.0
				k.ball(head + Vector3(s * (r.x + 0.1), 0.03, -0.0), Vector3(0.09, 0.11, 0.012), Color("ffc2d0"), 4, 9)
				k.outline = 0.02
			"fluffy":
				k.ball(head + Vector3(s * (r.x + 0.03), r.y * 0.45, -0.01), Vector3(0.11, 0.11, 0.05), c, 8, 10)
				k.outline = 0.0
				k.ball(head + Vector3(s * (r.x + 0.03), r.y * 0.45, 0.03), Vector3(0.06, 0.06, 0.024), c2, 4, 8)
				k.outline = 0.02
			"tufts":
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.5), top - Vector3(0, 0.03, 0)))
				k.cone(Vector3.ZERO, 0.12, 0.05, c.darkened(0.14), 6)
				k.pop()


static func _tail(k: MeshKit, kind: String, at: Vector3, c: Color, c2: Color) -> void:
	match kind:
		"up":
			k.tube(PackedVector3Array([at, at + Vector3(0, 0.1, -0.05), at + Vector3(0, 0.2, -0.04)]), 0.036, c, false, 6, 0.02)
		"long":
			k.tube(PackedVector3Array([at, at + Vector3(0.03, 0.03, -0.1), at + Vector3(0.08, 0.14, -0.14), at + Vector3(0.06, 0.26, -0.12)]), 0.034, c, false, 7, 0.02)
		"curl":
			var path := PackedVector3Array()
			for i in 9:
				var a := i * 0.85
				path.append(at + Vector3(sin(a) * 0.05, 0.04 + cos(a) * 0.05 + i * 0.008, -0.05 - i * 0.004))
			k.tube(path, 0.02, c, false, 6)
		"puff":
			k.ball(at + Vector3(0, 0.0, -0.03), Vector3(0.07, 0.07, 0.07), c.lightened(0.2), 6, 8)
		"stub":
			k.ball(at + Vector3(0, 0.02, -0.02), Vector3(0.04, 0.05, 0.05), c.darkened(0.08), 5, 7)
		"flat":
			k.ball(at + Vector3(0, -0.13, -0.14), Vector3(0.1, 0.022, 0.15), Color("5a3a24"), 5, 9)
		"striped":
			k.tube(PackedVector3Array([at, at + Vector3(0.04, 0.04, -0.12), at + Vector3(0.08, 0.16, -0.18), at + Vector3(0.06, 0.28, -0.16)]), 0.066, c, false, 8, 0.03)
			k.outline = 0.0
			for f in [Vector3(0.05, 0.08, -0.15), Vector3(0.08, 0.18, -0.18)]:
				k.ball(at + f, Vector3(0.056, 0.016, 0.056), c2, 3, 8)
			k.outline = 0.02
		"fan":
			var colours := [c, c2, c.lightened(0.14)]
			for i in 5:
				var a := lerpf(-0.8, 0.8, i / 4.0)
				k.push(Transform3D(Basis(Vector3.BACK, -a), at + Vector3(0, 0.0, -0.03)))
				k.ball(Vector3(0, 0.13, 0), Vector3(0.036, 0.15, 0.022), colours[i % 3], 5, 7)
				k.pop()


static func _slime(k: MeshKit, c: Color, c2: Color) -> void:
	k.ball(Vector3(0, 0.2, 0), Vector3(0.32, 0.22, 0.3), c, 12, 16)
	k.ball(Vector3(0, 0.36, 0), Vector3(0.14, 0.13, 0.14), c, 8, 10)
	k.outline = 0.0
	k.ball(Vector3(-0.13, 0.33, 0.18), Vector3(0.06, 0.035, 0.03), c2, 3, 7)
	k.outline = 0.02
	_eyes(k, 0.25, 0.27, 0.11, 0.05)
	_smile(k, 0.16, 0.285, 0.05)


static func _rock(k: MeshKit, c: Color, c2: Color) -> void:
	k.ball(Vector3(0, 0.17, 0), Vector3(0.28, 0.2, 0.25), c, 8, 10)
	k.ball(Vector3(0.14, 0.09, 0.09), Vector3(0.14, 0.1, 0.12), c.darkened(0.08), 6, 8)
	k.outline = 0.0
	k.ball(Vector3(-0.08, 0.28, 0.1), Vector3(0.09, 0.05, 0.06), c2, 3, 7)
	k.outline = 0.02
	_eyes(k, 0.2, 0.225, 0.09, 0.038)
	_smile(k, 0.13, 0.235, 0.035)


static func _ghost(k: MeshKit, c: Color, c2: Color) -> void:
	k.ball(Vector3(0, 0.25, 0), Vector3(0.24, 0.27, 0.22), c, 12, 14)
	for i in 7:
		var a := TAU * i / 7.0
		k.ball(Vector3(cos(a) * 0.16, 0.05, sin(a) * 0.15), Vector3(0.08, 0.1, 0.08), c, 5, 7)
	k.outline = 0.0
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.14, 0.2, 0.17), Vector3(0.04, 0.025, 0.012), c2, 3, 6)
	k.outline = 0.02
	_eyes(k, 0.29, 0.2, 0.085, 0.048)
	k.outline = 0.0
	k.ball(Vector3(0, 0.2, 0.215), Vector3(0.03, 0.04, 0.012), Color("0a1426"), 3, 7)
	k.outline = 0.02


static func _robot(k: MeshKit, c: Color, c2: Color) -> void:
	k.soft_box(Vector3(0, 0.24, 0), Vector3(0.24, 0.17, 0.22), c, 0.6, 8, 12)
	k.soft_box(Vector3(0, 0.5, 0.03), Vector3(0.17, 0.13, 0.15), c.lightened(0.14), 0.6, 8, 10)
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.16, 0.05, 0.1), Vector3(0.06, 0.05, 0.08), c.darkened(0.2), 5, 7)
		k.ball(Vector3(s * 0.16, 0.05, -0.1), Vector3(0.06, 0.05, 0.08), c.darkened(0.2), 5, 7)
		k.ball(Vector3(s * 0.19, 0.53, 0.03), Vector3(0.025, 0.05, 0.05), c2, 4, 6)
	k.tube(PackedVector3Array([Vector3(0, 0.62, 0.03), Vector3(0, 0.74, 0.03)]), 0.012, Color("0a1426"), false, 4)
	k.ball(Vector3(0, 0.76, 0.03), Vector3(0.03, 0.03, 0.03), c2, 4, 6)
	k.tube(PackedVector3Array([Vector3(0, 0.3, -0.22), Vector3(0, 0.4, -0.3)]), 0.018, c, false, 5)
	k.outline = 0.0
	k.soft_box(Vector3(0, 0.5, 0.18), Vector3(0.13, 0.08, 0.008), Color("0a1426"), 0.7, 3, 7)
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.06, 0.51, 0.19), Vector3(0.024, 0.03, 0.006), Color("7ee8ff"), 3, 6)
	k.outline = 0.02


static func _toast(k: MeshKit, c: Color, c2: Color) -> void:
	k.soft_box(Vector3(0, 0.26, 0), Vector3(0.24, 0.24, 0.09), c, 0.65, 8, 12)
	k.ball(Vector3(0, 0.46, 0), Vector3(0.28, 0.1, 0.095), c, 6, 10)
	k.outline = 0.0
	k.soft_box(Vector3(0, 0.27, 0.085), Vector3(0.2, 0.19, 0.008), c2, 0.65, 4, 10)
	k.soft_box(Vector3(0.05, 0.24, 0.096), Vector3(0.06, 0.05, 0.006), Color("ffd23f"), 0.6, 3, 7)
	k.outline = 0.02
	_eyes(k, 0.33, 0.1, 0.09, 0.038)
	_smile(k, 0.26, 0.104, 0.03)
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.11, 0.03, 0), Vector3(0.05, 0.04, 0.06), Color("0a1426"), 4, 6)


static func _onigiri(k: MeshKit, c: Color, c2: Color) -> void:
	k.ball(Vector3(0, 0.2, 0), Vector3(0.28, 0.2, 0.17), c, 10, 14)
	k.ball(Vector3(0, 0.38, 0), Vector3(0.14, 0.12, 0.12), c, 8, 10)
	k.soft_box(Vector3(0, 0.1, 0.0), Vector3(0.19, 0.1, 0.18), c2, 0.65, 6, 10)
	_eyes(k, 0.28, 0.15, 0.09, 0.038)
	_smile(k, 0.215, 0.165, 0.03)


static func _cactus(k: MeshKit, c: Color, c2: Color) -> void:
	k.ball(Vector3(0, 0.34, 0), Vector3(0.16, 0.33, 0.16), c, 12, 12)
	for s: float in [-1.0, 1.0]:
		k.tube(PackedVector3Array([Vector3(s * 0.13, 0.3, 0), Vector3(s * 0.27, 0.31, 0), Vector3(s * 0.28, 0.47, 0)]), 0.055, c, false, 7, 0.042)
		k.ball(Vector3(s * 0.08, 0.04, 0.04), Vector3(0.06, 0.04, 0.08), Color("d9703f"), 4, 6)
	k.ball(Vector3(0, 0.68, 0), Vector3(0.06, 0.05, 0.06), c2, 5, 7)
	_eyes(k, 0.42, 0.145, 0.07, 0.032)
	_smile(k, 0.36, 0.15, 0.025)


static func _cloud(k: MeshKit, c: Color, c2: Color) -> void:
	for at: Vector3 in [Vector3(-0.17, 0.05, 0), Vector3(0.17, 0.04, 0), Vector3(0, 0.1, 0), Vector3(-0.07, 0.17, -0.02), Vector3(0.09, 0.16, 0.0)]:
		k.ball(at + Vector3(0, 0.16, 0), Vector3(0.17, 0.14, 0.15), c, 7, 9)
	k.outline = 0.0
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.15, 0.17, 0.16), Vector3(0.05, 0.028, 0.014), Color("ffc2d0"), 3, 6)
	k.outline = 0.02
	_eyes(k, 0.25, 0.16, 0.08, 0.038)
	_smile(k, 0.19, 0.17, 0.028)
	for x: float in [-0.14, 0.02, 0.15]:
		k.ball(Vector3(x, -0.04 - absf(x) * 0.3, 0.03), Vector3(0.022, 0.04, 0.022), c2, 3, 5)


static func _ufo(k: MeshKit, c: Color, c2: Color) -> void:
	k.ball(Vector3(0, 0.16, 0), Vector3(0.32, 0.06, 0.32), c, 8, 18)
	k.dome(Vector3(0, 0.19, 0), Vector3(0.17, 0.17, 0.17), c2, 8, 14)
	_eyes(k, 0.27, 0.15, 0.06, 0.03)
	k.outline = 0.0
	for i in 6:
		var a := TAU * i / 6.0
		k.ball(Vector3(cos(a) * 0.24, 0.135, sin(a) * 0.24), Vector3(0.03, 0.016, 0.03), Color("ffd23f"), 3, 6)
	k.outline = 0.02
