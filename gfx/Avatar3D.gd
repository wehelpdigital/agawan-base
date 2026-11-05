class_name Avatar3D
extends Node3D
## A player's character: chunky toy proportions, drawn in code from Cosmetics.gd, animated in code
## (no skeleton, so it stays cheap on phones). Faces +Z. Meshes are shared between avatars that look
## the same, so ten players cost about sixty draw calls and no extra memory.

const HEAD_Y := 1.12
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
var _lids: MeshInstance3D
var _blink_wait := randf_range(1.0, 4.0)
var _blink_left := 0.0
var _eye_seen := {}


static func _material(kind: String) -> ShaderMaterial:
	if _mat_normal == null:
		_mat_normal = ShaderMaterial.new()
		_mat_normal.shader = preload("res://gfx/shaders/toon.gdshader")
		_mat_ghost = ShaderMaterial.new()
		_mat_ghost.shader = preload("res://gfx/shaders/ghost.gdshader")
		_mat_frozen = ShaderMaterial.new()
		_mat_frozen.shader = preload("res://gfx/shaders/toon.gdshader")
		_mat_frozen.set_shader_parameter("tint", Color(0.55, 0.85, 1.25))
		_mat_flash = ShaderMaterial.new()
		_mat_flash.shader = preload("res://gfx/shaders/toon.gdshader")
		_mat_flash.set_shader_parameter("flash", 0.75)
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
	_hips.add_child(_head)
	_eye_seen = {}
	_add_part(_head, _shared("head|" + skin_key, _build_head.bind(hero, skin)), Vector3.ZERO)
	if not _eye_seen.is_empty():
		_eye_info[skin_key] = _eye_seen
	_lids = null
	if _eye_info.has(skin_key):
		_lids = _add_part(_head, _shared("lids|" + skin_key, _build_lids.bind(_eye_info[skin_key], _lid_color(hero, skin))), Vector3.ZERO)
		_lids.visible = false
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
	_arm_l.position = Vector3(-0.36, 0.84, 0)
	_hips.add_child(_arm_l)
	_arm_r = Node3D.new()
	_arm_r.position = Vector3(0.36, 0.84, 0)
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
	_foot_l.position = Vector3(-0.2, 0.12, 0)
	add_child(_foot_l)
	_foot_r = Node3D.new()
	_foot_r.position = Vector3(0.2, 0.12, 0)
	add_child(_foot_r)
	var shoes_id: String = look.get("shoes", "")
	var foot := _shared("shoes|" + shoes_id, AvatarParts.shoe.bind(shoes_id)) if shoes_id != "" else _shared("foot|" + skin_key, _build_foot.bind(hero, skin))
	_add_part(_foot_l, foot, Vector3.ZERO)
	_add_part(_foot_r, foot, Vector3.ZERO)
	if String(hero.get("shape", "")) != "ghost":
		var leg := _shared("leg|" + skin_key, _build_leg.bind(hero, skin))
		_add_part(_foot_l, leg, Vector3.ZERO)
		_add_part(_foot_r, leg, Vector3.ZERO)
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
		_back.position = Vector3(0, 0.74, -0.27)
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
		kit.outline = 0.03
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
			k.soft_box(Vector3(0, 0.36, 0), Vector3(0.31, 0.15, 0.23), low)
			k.soft_box(Vector3(0, 0.66, 0), Vector3(0.33, 0.27, 0.25), top)
			# A little collar, a pocket and a hem: small things that make it clothing.
			k.outline = 0.0
			k.torus(Vector3(0, 0.89, 0.02), 0.2, 0.035, top.lightened(0.3), 14, 4)
			k.box(Vector3(0.14, 0.72, 0.253), Vector3(0.14, 0.13, 0.01), top.lightened(0.28))
			k.box(Vector3(0.14, 0.775, 0.258), Vector3(0.14, 0.022, 0.01), top.darkened(0.2))
			k.box(Vector3(0, 0.455, 0.235), Vector3(0.56, 0.035, 0.01), low.darkened(0.22))
			k.box(Vector3(-0.15, 0.29, 0.235), Vector3(0.012, 0.13, 0.01), low.darkened(0.22))
			k.box(Vector3(0.15, 0.29, 0.235), Vector3(0.012, 0.13, 0.01), low.darkened(0.22))
			k.outline = 0.03
		"animal":
			var fur := _main(hero, skin, "fur")
			var belly := _second(hero, skin, "belly")
			k.ball(Vector3(0, 0.54, 0), Vector3(0.36, 0.38, 0.32), fur, 12, 16)
			k.outline = 0.0
			k.ball(Vector3(0, 0.5, 0.14), Vector3(0.26, 0.28, 0.21), belly, 10, 14)
			k.outline = 0.03
			_tail(k, hero, fur)
		_:
			var main := _main(hero, skin, "main")
			var shape: String = hero.get("shape", "")
			if shape == "robot":
				k.soft_box(Vector3(0, 0.56, 0), Vector3(0.29, 0.25, 0.22), main.darkened(0.1))
				k.decal_box(Vector3(0, 0.6, 0.222), Vector3(0.3, 0.2, 0.01), _second(hero, skin, "second"))
				k.outline = 0.0
				k.ball(Vector3(-0.08, 0.6, 0.232), Vector3(0.03, 0.03, 0.01), Color("ff4f6a"), 3, 7)
				k.ball(Vector3(0.0, 0.6, 0.232), Vector3(0.03, 0.03, 0.01), Color("35d07f"), 3, 7)
				k.ball(Vector3(0.08, 0.6, 0.232), Vector3(0.03, 0.03, 0.01), Color("3aa6ff"), 3, 7)
				k.outline = 0.03
			elif shape == "ghost":
				k.cyl(Vector3(0, 0.22, 0), 0.7, 0.44, 0.38, main, 14)
				for i in 7:
					var a := TAU * i / 7.0
					k.ball(Vector3(cos(a) * 0.38, 0.2, sin(a) * 0.38), Vector3(0.13, 0.13, 0.13), main, 6, 9)
			elif shape == "flame":
				k.cyl(Vector3(0, 0.26, 0), 0.62, 0.34, 0.26, _second(hero, skin, "second"), 10)
			elif shape == "crystal":
				k.cyl(Vector3(0, 0.26, 0), 0.62, 0.22, 0.34, _second(hero, skin, "second").darkened(0.08), 6, false)
			elif shape == "cup":
				k.cyl(Vector3(0, 0.22, 0), 0.62, 0.24, 0.36, main.darkened(0.08), 12)
			else:
				k.ball(Vector3(0, 0.54, 0), Vector3(0.33, 0.36, 0.3), main.lightened(0.05), 10, 14)


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


## An arm with a proper hand: a chubby palm, three stubby fingers and a thumb. Kids' hands are bare,
## animals have paws, and mascots wear white cartoon gloves.
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
			hand = _second(hero, skin, "belly").lerp(arm, 0.25)
		_:
			arm = _main(hero, skin, "main").darkened(0.08)
			hand = Color("fbf7ff")
			cuff = Color(hero.get("accent", "ffffff"))
	k.cyl(Vector3(0, -0.3, 0), 0.3, 0.068, 0.086, arm, 8)
	if sleeve.a > 0.0:
		k.ball(Vector3(0, -0.06, 0), Vector3(0.115, 0.13, 0.115), sleeve, 7, 10)
		k.outline = 0.0
		k.torus(Vector3(0, -0.15, 0), 0.098, 0.018, sleeve.lightened(0.3), 10, 4)
		k.outline = 0.03
	if cuff.a > 0.0:
		k.torus(Vector3(0, -0.285, 0), 0.08, 0.03, cuff, 10, 5)
	var palm := Vector3(0, -0.38, 0)
	k.outline = 0.016
	for f: float in [-1.0, 0.0, 1.0]:
		k.ball(palm + Vector3(f * 0.078, -0.105 - (1.0 - absf(f)) * 0.018, 0), Vector3(0.046, 0.07, 0.046), hand, 6, 8)
	k.ball(palm + Vector3(0, -0.01, 0.105), Vector3(0.05, 0.052, 0.066), hand, 6, 8)
	k.outline = 0.024
	k.ball(palm, Vector3(0.125, 0.115, 0.095), hand, 9, 12)
	k.outline = 0.03


## A short chubby leg, moving with the foot. It stands in the foot's own space, ankle at y = 0.
func _build_leg(k: MeshKit, hero: Dictionary, skin: Dictionary) -> void:
	var c := Color.WHITE
	match hero["kind"]:
		"kid":
			c = Color(hero["skin"])
		"animal":
			c = _main(hero, skin, "fur")
		_:
			c = _main(hero, skin, "main").darkened(0.12)
	k.cyl(Vector3(0, 0.02, -0.01), 0.24, 0.085, 0.1, c, 8)


func _build_foot(k: MeshKit, hero: Dictionary, skin: Dictionary) -> void:
	match hero["kind"]:
		"kid":
			var c := Color(hero["shoe"])
			k.soft_box(Vector3(0, 0.02, 0.06), Vector3(0.14, 0.095, 0.21), c)
			k.soft_box(Vector3(0, -0.075, 0.065), Vector3(0.15, 0.035, 0.225), Color("fff8ea"))
			k.outline = 0.0
			k.ball(Vector3(0, 0.03, 0.2), Vector3(0.1, 0.06, 0.07), c.lightened(0.3), 5, 8)
			for i in 3:
				k.box(Vector3(0, 0.115 - i * 0.012, 0.0 + i * 0.05), Vector3(0.12, 0.016, 0.022), Color("fff8ea"))
			k.outline = 0.03
		"animal":
			var c := _main(hero, skin, "fur").darkened(0.12)
			k.ball(Vector3(0, 0.0, 0.07), Vector3(0.15, 0.1, 0.2), c, 8, 11)
			k.outline = 0.0
			for f: float in [-1.0, 0.0, 1.0]:
				k.ball(Vector3(f * 0.075, -0.015, 0.25), Vector3(0.036, 0.042, 0.03), c.lightened(0.35), 3, 6)
			k.outline = 0.03
		_:
			var c := Color(hero.get("accent", "ffffff"))
			k.soft_box(Vector3(0, 0.0, 0.06), Vector3(0.14, 0.1, 0.21), c)
			k.outline = 0.0
			k.ball(Vector3(0, 0.02, 0.2), Vector3(0.09, 0.055, 0.065), c.lightened(0.35), 5, 8)
			k.outline = 0.03


## Big glossy eyes: white, coloured iris, dark pupil, two sparkles and a soft lash line. A dark `white`
## makes all-black alien eyes, with the sparkles only.
func _eyes(k: MeshKit, y: float, z: float, gap: float, size: float, iris := Color("7a4522"), white := Color("ffffff")) -> void:
	_eye_seen = {"y": y, "z": z, "gap": gap, "size": size}
	var solid := white.get_luminance() < 0.2
	for s: float in [-1.0, 1.0]:
		k.outline = 0.018
		k.ball(Vector3(s * gap, y, z), Vector3(size, size * 1.22, size * 0.5), white, 8, 12)
		k.outline = 0.0
		if not solid:
			k.ball(Vector3(s * gap, y - size * 0.1, z + size * 0.32), Vector3(size * 0.72, size * 0.88, size * 0.25), iris, 7, 11)
			k.ball(Vector3(s * gap, y - size * 0.1, z + size * 0.42), Vector3(size * 0.42, size * 0.54, size * 0.2), Color("1c0f3a"), 6, 9)
		k.ball(Vector3(s * gap + size * 0.26, y + size * 0.32, z + size * 0.52), Vector3(size * 0.26, size * 0.28, size * 0.08), Color.WHITE, 4, 7)
		k.ball(Vector3(s * gap - size * 0.24, y - size * 0.34, z + size * 0.5), Vector3(size * 0.12, size * 0.12, size * 0.05), Color(1, 1, 1, 1), 3, 5)
		var lash := PackedVector3Array()
		for i in 11:
			var a := lerpf(PI * 0.98, PI * 0.02, i / 10.0)
			var bulge := sqrt(maxf(1.0 - pow(cos(a) * 0.97, 2.0) - pow(sin(a) * 0.97, 2.0), 0.0))
			lash.append(Vector3(s * gap + cos(a) * size * 1.0, y + sin(a) * size * 1.2, z + size * 0.5 * bulge + 0.012))
		k.ribbon(lash, size * 0.14, Color("1c0f3a"))
	k.outline = 0.03


## Closed eyes, shown for a blink.
func _build_lids(k: MeshKit, info: Dictionary, color: Color) -> void:
	k.outline = 0.0
	var size: float = info["size"]
	for s: float in [-1.0, 1.0]:
		var at := Vector3(s * float(info["gap"]), float(info["y"]), float(info["z"]))
		k.ball(at + Vector3(0, 0, 0.012), Vector3(size * 1.08, size * 1.3, size * 0.56), color, 7, 11)
		var line := PackedVector3Array()
		for i in 11:
			var f := lerpf(-1.0, 1.0, i / 10.0)
			line.append(at + Vector3(f * size * 0.85, -size * 0.35 * (1.0 - f * f), size * 0.57 * sqrt(maxf(1.0 - f * f * 0.72, 0.0)) + 0.01))
		k.ribbon(line, size * 0.13, Color("1c0f3a"))


func _lid_color(hero: Dictionary, skin: Dictionary) -> Color:
	match hero["kind"]:
		"kid":
			return Color(hero["skin"])
		"animal":
			return _main(hero, skin, "fur")
	return _main(hero, skin, "main")


func _tick_blink(delta: float) -> void:
	if _lids == null or not is_instance_valid(_lids):
		return
	if _blink_left > 0.0:
		_blink_left -= delta
		if _blink_left <= 0.0:
			_lids.visible = false
			_blink_wait = randf_range(1.6, 4.5)
		return
	_blink_wait -= delta
	if _blink_wait <= 0.0:
		_blink_left = 0.11
		_lids.visible = true


## A happy open mouth: a smooth D shape following the curve of the face, with a little tongue.
func _smile(k: MeshKit, y: float, z: float, width: float, c := Color("7a1f3a")) -> void:
	k.outline = 0.0
	var steps := 12
	var mouth := PackedVector3Array()
	var depth := width * 1.05
	for i in steps + 1:  # The lower lip, left to right...
		var f := lerpf(-1.0, 1.0, i / float(steps))
		mouth.append(Vector3(f * width, y + 0.02 * f * f - depth * (1.0 - f * f), z - f * f * width * 0.28 + 0.004))
	for i in range(steps - 1, 0, -1):  # ...and the upper lip back, smiling at the corners.
		var f := lerpf(-1.0, 1.0, i / float(steps))
		mouth.append(Vector3(f * width, y + 0.02 * f * f - width * 0.12 * (1.0 - f * f), z - f * f * width * 0.28 + 0.004))
	k.fan(mouth, c)
	var tongue := PackedVector3Array()
	for i in steps + 1:
		var a := PI + PI * i / float(steps)
		tongue.append(Vector3(cos(a) * width * 0.48, y - depth * 0.6 + sin(a) * width * 0.3, z + 0.008))
	k.fan(tongue, Color("ff7f96"))
	k.outline = 0.03


func _build_head(k: MeshKit, hero: Dictionary, skin: Dictionary) -> void:
	match hero["kind"]:
		"kid": _head_kid(k, hero, skin)
		"animal": _head_animal(k, hero, skin)
		_: _head_mascot(k, hero, skin)


func _head_kid(k: MeshKit, hero: Dictionary, skin: Dictionary) -> void:
	var tone := Color(hero["skin"])
	var hair := Color(hero["hair"])
	k.ball(Vector3.ZERO, Vector3(0.5, 0.46, 0.46), tone, 12, 18)
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.49, -0.03, 0), Vector3(0.085, 0.115, 0.085), tone, 5, 8)
		k.outline = 0.0
		k.ball(Vector3(s * 0.52, -0.03, 0.02), Vector3(0.045, 0.07, 0.05), tone.darkened(0.14), 4, 6)
		k.outline = 0.03
	_eyes(k, 0.0, 0.37, 0.2, 0.135)
	k.outline = 0.0
	# Eyebrows, a button nose and rosy cheeks.
	for s: float in [-1.0, 1.0]:
		var brow := PackedVector3Array()
		for i in 7:
			var f := lerpf(-1.0, 1.0, i / 6.0)
			brow.append(Vector3(s * 0.2 + f * 0.085, 0.235 - f * f * 0.022 + s * f * -0.006, 0.4 - pow(s * 0.2 + f * 0.085, 2.0) * 0.45))
		k.ribbon(brow, 0.017, hair)
		k.ball(Vector3(s * 0.33, -0.13, 0.306), Vector3(0.08, 0.05, 0.03), tone.lerp(Color("ff6f8a"), 0.6), 5, 9)
	k.ball(Vector3(0, -0.105, 0.44), Vector3(0.032, 0.024, 0.02), tone.darkened(0.2), 3, 6)
	k.outline = 0.03
	_smile(k, -0.17, 0.42, 0.1)
	# Hair: a cap over the top and back of the head, a fringe, then the style.
	k.ball(Vector3(0, 0.15, -0.05), Vector3(0.53, 0.37, 0.47), hair, 10, 16)
	k.outline = 0.0
	for i in 5:
		var f := lerpf(-1.0, 1.0, i / 4.0)
		k.ball(Vector3(f * 0.32, 0.29 - (1.0 - absf(f)) * 0.03, 0.31 - absf(f) * 0.12), Vector3(0.11, 0.1, 0.09), hair, 6, 9)
	k.outline = 0.03
	match String(hero.get("style")):
		"spiky":
			for i in 7:
				var a := TAU * i / 7.0
				k.cone(Vector3(cos(a) * 0.28, 0.33, sin(a) * 0.26 - 0.06), 0.25, 0.11, hair, 6)
			k.cone(Vector3(0, 0.42, -0.02), 0.27, 0.13, hair, 6)
		"ponytail":
			k.ball(Vector3(0, 0.22, -0.48), Vector3(0.1, 0.1, 0.1), _main(hero, skin, "top"), 5, 8)
			k.ball(Vector3(0, -0.04, -0.6), Vector3(0.15, 0.3, 0.15), hair, 7, 10)
			k.ball(Vector3(0, -0.28, -0.62), Vector3(0.09, 0.12, 0.09), hair, 5, 8)
		"bowl":
			k.ball(Vector3(0, 0.12, 0.02), Vector3(0.56, 0.28, 0.5), hair, 8, 14)
		"buns":
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.33, 0.44, -0.06), Vector3(0.17, 0.17, 0.17), hair, 7, 10)
				k.torus(Vector3(s * 0.3, 0.32, -0.05), 0.09, 0.025, _main(hero, skin, "top"), 10, 4)
		"mohawk":
			for i in 6:
				k.soft_box(Vector3(0, 0.45 - absf(i - 2.5) * 0.035, -0.32 + i * 0.13), Vector3(0.055, 0.15, 0.065), _second(hero, skin, "top"), 0.6, 6, 8)
		"long":
			k.ball(Vector3(0, -0.15, -0.26), Vector3(0.48, 0.55, 0.26), hair, 9, 14)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.43, -0.2, 0.1), Vector3(0.11, 0.33, 0.14), hair, 6, 9)


func _head_animal(k: MeshKit, hero: Dictionary, skin: Dictionary) -> void:
	var fur := _main(hero, skin, "fur")
	var belly := _second(hero, skin, "belly")
	var accent := Color(hero["accent"])
	var animal: String = hero["animal"]
	match animal:
		"tarsier":
			k.ball(Vector3.ZERO, Vector3(0.48, 0.44, 0.44), fur, 12, 18)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.48, 0.28, -0.02), Vector3(0.28, 0.32, 0.1), fur.darkened(0.1), 4, 9)
				k.outline = 0.0
				k.ball(Vector3(s * 0.48, 0.28, 0.05), Vector3(0.18, 0.22, 0.05), Color("ffb3a8"), 3, 8)
				k.outline = 0.03
			_eyes(k, 0.06, 0.32, 0.22, 0.24, Color("5a2b0e"), Color("ffcf56"))
			k.outline = 0.0
			k.ball(Vector3(0, -0.16, 0.43), Vector3(0.05, 0.04, 0.03), Color("6a2038"), 2, 6)
			k.outline = 0.03
		"rooster":
			k.ball(Vector3.ZERO, Vector3(0.46, 0.46, 0.44), fur, 12, 18)
			for i in 3:
				k.ball(Vector3(0, 0.46 + (1 - absf(i - 1)) * 0.06, -0.12 + i * 0.13), Vector3(0.07, 0.16, 0.09), accent, 3, 6)
			_eyes(k, 0.08, 0.36, 0.2, 0.11)
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.05, 0.38)))
			k.cone(Vector3.ZERO, 0.28, 0.13, Color("ffb52e"), 7)
			k.pop()
			k.ball(Vector3(0, -0.24, 0.32), Vector3(0.07, 0.12, 0.05), accent, 3, 6)
		_:
			k.ball(Vector3.ZERO, Vector3(0.5, 0.46, 0.46), fur, 12, 18)
			_animal_features(k, animal, fur, belly, accent)
			_eyes(k, 0.08, 0.37, 0.2, 0.125)
			if animal == "pig":
				k.ball(Vector3(0, -0.1, 0.42), Vector3(0.16, 0.12, 0.1), belly, 3, 8)
				k.outline = 0.0
				for s: float in [-0.05, 0.05]:
					k.ball(Vector3(s, -0.1, 0.5), Vector3(0.025, 0.04, 0.02), Color("6a2038"), 2, 5)
				k.outline = 0.03
			else:
				k.ball(Vector3(0, -0.13, 0.38), Vector3(0.21, 0.15, 0.13), belly, 3, 8)
				k.outline = 0.0
				k.ball(Vector3(0, -0.07, 0.5), Vector3(0.065, 0.05, 0.03), Color("24135f"), 2, 6)
				k.outline = 0.03
				_smile(k, -0.2, 0.49, 0.08)


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
				k.outline = 0.03
			k.outline = 0.0
			for s: float in [-1.0, 1.0]:
				k.box(Vector3(s * 0.34, -0.1, 0.34), Vector3(0.22, 0.015, 0.015), Color("24135f"))
			k.outline = 0.03
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
			k.outline = 0.0
			k.ball(Vector3(0, 0.0, 0.2), Vector3(0.38, 0.36, 0.3), belly, 4, 9)
			k.outline = 0.03


func _head_mascot(k: MeshKit, hero: Dictionary, skin: Dictionary) -> void:
	var main := _main(hero, skin, "main")
	var second := _second(hero, skin, "second")
	var accent := Color(hero["accent"])
	match String(hero["shape"]):
		"coconut":
			k.ball(Vector3.ZERO, Vector3(0.52, 0.5, 0.5), main, 12, 18)
			k.outline = 0.0
			k.ball(Vector3(0, 0.42, 0), Vector3(0.34, 0.1, 0.32), second, 3, 10)
			k.outline = 0.03
			k.cyl(Vector3(0.16, 0.42, 0.05), 0.42, 0.03, 0.03, accent, 5)
			_eyes(k, 0.02, 0.38, 0.2, 0.14)
			_smile(k, -0.22, 0.45, 0.12)
		"mango":
			k.ball(Vector3.ZERO, Vector3(0.48, 0.54, 0.44), main, 12, 18)
			k.outline = 0.0
			k.ball(Vector3(0.25, 0.18, 0.1), Vector3(0.28, 0.32, 0.36), second, 4, 9)
			k.outline = 0.03
			k.cyl(Vector3(0, 0.5, 0), 0.16, 0.04, 0.03, Color("7a5230"), 5)
			k.ball(Vector3(0.16, 0.62, 0), Vector3(0.2, 0.05, 0.1), accent, 3, 7)
			_eyes(k, 0.02, 0.36, 0.18, 0.13)
			_smile(k, -0.2, 0.42, 0.12)
		"cup":
			k.cyl(Vector3(0, -0.42, 0), 0.72, 0.36, 0.5, main, 12)
			k.outline = 0.0
			k.torus(Vector3(0, -0.22, 0), 0.41, 0.06, second, 12, 4)
			k.torus(Vector3(0, -0.02, 0), 0.45, 0.06, accent, 12, 4)
			k.outline = 0.03
			k.ball(Vector3(0, 0.3, 0), Vector3(0.48, 0.28, 0.48), Color("f6fcff"), 5, 12)
			k.ball(Vector3(0.1, 0.5, 0.06), Vector3(0.14, 0.1, 0.14), second, 3, 7)
			k.ball(Vector3(-0.2, 0.42, 0.14), Vector3(0.09, 0.07, 0.09), accent, 3, 6)
			_eyes(k, -0.12, 0.38, 0.2, 0.13)
			_smile(k, -0.3, 0.38, 0.1)
		"robot":
			k.box(Vector3.ZERO, Vector3(0.92, 0.76, 0.76), main, 0.1)
			k.outline = 0.0
			k.box(Vector3(0, 0.06, 0.385), Vector3(0.72, 0.34, 0.02), Color("1c174a"))
			k.outline = 0.03
			for s: float in [-1.0, 1.0]:
				k.outline = 0.0
				k.ball(Vector3(s * 0.19, 0.06, 0.4), Vector3(0.11, 0.11, 0.03), accent, 3, 8)
				k.outline = 0.03
				k.cyl(Vector3(s * 0.48, -0.08, 0), 0.2, 0.08, 0.08, second, 6)
			k.cyl(Vector3(0, 0.38, 0), 0.26, 0.03, 0.03, Color("6a6a7a"), 5)
			k.ball(Vector3(0, 0.66, 0), Vector3(0.07, 0.07, 0.07), second, 3, 6)
			k.outline = 0.0
			for i in 4:
				k.box(Vector3(-0.21 + i * 0.14, -0.22, 0.385), Vector3(0.09, 0.08, 0.02), second)
			k.outline = 0.03
		"ghost":
			k.ball(Vector3(0, -0.02, 0), Vector3(0.5, 0.5, 0.46), main, 12, 18)
			_eyes(k, 0.05, 0.36, 0.18, 0.13, Color("24135f"), Color("24135f"))
			k.outline = 0.0
			k.ball(Vector3(0, -0.2, 0.42), Vector3(0.07, 0.09, 0.04), Color("24135f"), 3, 6)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.3, -0.11, 0.35), Vector3(0.08, 0.05, 0.03), second, 2, 6)
			k.outline = 0.03
		"alien":
			k.ball(Vector3(0, 0.08, 0), Vector3(0.56, 0.5, 0.48), main, 12, 18)
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
			k.outline = 0.03
			_eyes(k, -0.06, 0.38, 0.17, 0.12)
			_smile(k, -0.26, 0.44, 0.09)
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
			k.outline = 0.03
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
			k.outline = 0.03
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
			k.outline = 0.03
		"pirate":
			k.ball(Vector3(0, -0.04, 0), Vector3(0.62, 0.22, 0.4), Color("2b2448"), 4, 10)
			k.ball(Vector3(0, 0.12, 0), Vector3(0.36, 0.2, 0.3), Color("2b2448"), 4, 9)
			k.outline = 0.0
			k.ball(Vector3(0, 0.1, 0.32), Vector3(0.09, 0.09, 0.03), Color("ffffff"), 3, 7)
			k.outline = 0.03
		"sombrero":
			k.cyl(Vector3(0, -0.13, 0), 0.06, 0.92, 0.84, Color("ffcf6a"), 14)
			k.cyl(Vector3(0, -0.08, 0), 0.42, 0.34, 0.16, Color("ffcf6a"), 10)
			k.outline = 0.0
			k.torus(Vector3(0, -0.04, 0), 0.32, 0.04, Color("ff3f3f"), 12, 4)
			k.torus(Vector3(0, -0.09, 0), 0.82, 0.03, Color("35d07f"), 16, 4)
			k.outline = 0.03
		"viking":
			k.ball(Vector3(0, -0.08, 0), Vector3(0.5, 0.36, 0.48), Color("b8c0d8"), 4, 10)
			k.outline = 0.0
			k.torus(Vector3(0, -0.16, 0), 0.49, 0.05, Color("c98c4a"), 12, 4)
			k.outline = 0.03
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
			k.outline = 0.03
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
			k.outline = 0.03
			k.torus(Vector3(0, -0.72, 0), 0.5, 0.07, Color("e8ecf9"), 14, 5)
			k.outline = 0.0
			k.ball(Vector3(0, -0.34, 0), Vector3(0.66, 0.66, 0.66), Color("a8e6ff"), 3, 8)
			k.outline = 0.03
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
			k.outline = 0.03
		"flag":
			k.cyl(Vector3(0.1, -0.4, -0.08), 1.75, 0.03, 0.03, Color("8a5a34"), 5)
			k.box(Vector3(0.46, 1.08, -0.08), Vector3(0.68, 0.42, 0.02), team)
			k.outline = 0.0
			k.box(Vector3(0.46, 1.08, -0.09), Vector3(0.18, 0.18, 0.04), Color("ffffff"))
			k.outline = 0.03
		"guitar":
			k.push(Transform3D(Basis(Vector3.BACK, 0.7), Vector3(0, 0, -0.1)))
			k.ball(Vector3(0, -0.3, 0), Vector3(0.28, 0.32, 0.08), Color("c98c4a"), 3, 9)
			k.box(Vector3(0, 0.3, 0), Vector3(0.09, 0.75, 0.05), Color("7a5230"))
			k.outline = 0.0
			k.ball(Vector3(0, -0.28, -0.08), Vector3(0.1, 0.1, 0.02), Color("3a2315"), 2, 7)
			k.outline = 0.03
			k.pop()
		"butterfly":
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.45, 0.16, -0.05), Vector3(0.4, 0.36, 0.03), Color("ff9fd0"), 3, 9)
				k.ball(Vector3(s * 0.34, -0.26, -0.05), Vector3(0.26, 0.24, 0.03), Color("ffd23f"), 3, 8)
				k.outline = 0.0
				k.ball(Vector3(s * 0.46, 0.18, -0.08), Vector3(0.15, 0.14, 0.02), Color("7f5cff"), 2, 7)
				k.outline = 0.03
		"jetpack":
			for s: float in [-1.0, 1.0]:
				k.cyl(Vector3(s * 0.17, -0.34, -0.1), 0.62, 0.13, 0.13, Color("c9d0e6"), 8)
				k.cone(Vector3(s * 0.17, 0.28, -0.1), 0.16, 0.13, Color("ff5a4e"), 8)
				k.outline = 0.0
				k.ball(Vector3(s * 0.17, -0.46, -0.1), Vector3(0.08, 0.14, 0.08), Color("ffb52e"), 3, 6)
				k.outline = 0.03
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
		_foot_l.position = Vector3(-0.2, 0.12 + foot_l.y, foot_l.z)
		_foot_r.position = Vector3(0.2, 0.12 + foot_r.y, foot_r.z)
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
