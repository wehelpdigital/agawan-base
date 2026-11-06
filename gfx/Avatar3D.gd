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
## The head hats are made for: how far out the brim line is, how much shorter it is front to back, and how far the
## crown of the head rises above it. See _build_hat().
const HAT_R := 0.56
const HAT_DEPTH := 0.9
const HAT_RISE := 0.34
## These sit above the head or round it, so the hair and ears can stay. Everything else is pulled down over them.
const HATS_OVER_HAIR := ["headband", "flowers", "halo_ring", "ufo", "hachimaki", "laurel", "lei_hat", "cat_ears", "bunny_ears", "antlers", "sprout", "paper_crown", "bamboo_sprouts", "bamboo_flyer", "kokoshnik"]
signal gag_started(line: String)  ## With something to say about it, for whoever's listening.

static var _meshes := {}  # key -> ArrayMesh
static var _eye_info := {}  # Avatar key -> where its eyes are, for blinking.
static var _mat_normal: ShaderMaterial
static var _mat_ghost: ShaderMaterial
static var _mat_frozen: ShaderMaterial
static var _mat_flash: ShaderMaterial

var look: Dictionary = {}
var team_color := Color("ffffff")
var moving := 0.0  ## 0..1, how fast the legs go.
var state := "idle"  ## idle, run, dash, stun, freeze, root, jail, dance, sad, air, turning
var dance_id := ""
var run_id := ""
var calm := false  ## Holds still and keeps a straight face, so you can see the one you're trying on.

var _hips: Node3D
var _head: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _foot_l: Node3D
var _foot_r: Node3D
var _back: Node3D
var _hat: Node3D
var _flag_cloth: MeshInstance3D
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
var _face_hide := ""  ## What a mask hides of the face: "eyes" or "mouth".
var _rest_face := "normal"  ## The face this player chose to wear.
var _hero_id := ""
var _own_run := ""  ## The walk this character falls back on, with no run style of its own.
var _floaty := false
var _wiggles: Array[Dictionary] = []
var _kick := 0.0  ## Set everything flapping, after a jolt.
var _gag := ""
var _gag_left := 0.0
var _gag_total := 1.0
var _gag_wait := randf_range(3.0, 12.0)
var _glance_wait := randf_range(1.5, 5.0)
var _glance_left := 0.0
var _glance := "look_l"
var _state_seen := ""
var _state_face := ""
var _funny_wait := randf_range(4.0, 14.0)
var _arm_spread := 0.0  ## Big gloves hold the arms further out, so they don't sink into the body.


static var _flag_sheet: ArrayMesh
static var _flag_mats := {}


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
	var dressed_top: bool = str(look.get("top", "")) != ""
	var dressed_low: bool = str(look.get("pants", "")) != ""
	var has_back: bool = str(look.get("back", "")) != ""
	var body_key := "body|%s|%s|%s" % [skin_key, dressed_top, dressed_low]
	_add_part(_hips, _shared(body_key, _build_body.bind(hero, skin, dressed_top, dressed_low)), Vector3.ZERO)
	_hero_id = hero["id"]
	_own_run = String(Faces.person(_hero_id).get("run", ""))
	_gag = ""
	_floaty = hero.get("shape") == "ghost"
	_head = Node3D.new()
	_head.position = Vector3(0, HEAD_Y, 0)
	_head.scale = HEAD_SHAPE
	_hips.add_child(_head)
	var mask_id: String = look.get("mask", "")
	var hat_id: String = look.get("hat", "")
	if Cosmetics.wearing_clash(mask_id, hat_id):
		hat_id = ""
	var cover := String(Cosmetics.item("mask", mask_id).get("cover", "")) if mask_id != "" else ""
	var plain := _plain_head(hero, cover)
	var hat_level := _hat_level(hero, hat_id)
	# How much of the head shows depends on what's on it: under a hat there's no hair sticking up, and under
	# a mask there's no snout sticking out. A mask that replaces the head leaves nothing of it to draw.
	var head_key := "head|%s|%d|%s" % [skin_key, hat_level, cover]
	_rest_face = String(Cosmetics.item("face", str(look.get("face", ""))).get("expr", "normal"))
	_face = null
	_face_key = head_key
	_face_hide = "eyes" if cover == "eyes" else ("mouth" if cover == "low" else "")
	_shown_face = ""
	if cover != "whole":
		_eye_seen = {}
		_add_part(_head, _shared(head_key, _build_head.bind(hero, skin, hat_level, cover)), Vector3.ZERO)
		if not _eye_seen.is_empty():
			_eye_seen["shape"] = _face_surface(hero, plain)
			_eye_seen["hero"] = hero["id"]
			_eye_info[head_key] = _eye_seen
		if cover != "plate" and _eye_info.has(head_key):
			_face = MeshInstance3D.new()
			_face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_head.add_child(_face)
			_parts.append(_face)
			_show_face(_rest_face)
	var body_w := _clothes_width(hero)
	var top_id: String = look.get("top", "")
	if top_id != "":
		_add_part(_hips, _shared("top|%s|%.2f" % [top_id, body_w], AvatarParts.top.bind(top_id, body_w)), Vector3.ZERO)
	var pants_id: String = look.get("pants", "")
	if pants_id != "":
		_add_part(_hips, _shared("pants|%s|%.2f" % [pants_id, body_w], AvatarParts.pants.bind(pants_id, body_w)), Vector3.ZERO)
	if mask_id != "":
		var hatted := hat_level > 0
		var worn := _add_part(_head, _shared("mask|%s|%s" % [mask_id, hatted], AvatarParts.mask.bind(mask_id, hatted)), Vector3.ZERO)
		if cover != "whole":
			_fit_mask(worn, hero, cover, plain)
	_wiggles.clear()
	for row: Array in _wiggle_list(hero, hat_level, cover, plain, has_back):
		var wiggle := _add_part(_head if row[1] else _hips, _shared("wiggle|%s|%s" % [row[0], skin_key], _build_wiggle.bind(row[0], hero, skin)), row[2])
		if row[1] and hat_level > 0 and String(hero.get("animal", "")) == "tarsier":
			wiggle.scale = Vector3.ONE * 0.8
		_wiggles.append({"node": wiggle, "axis": row[3], "amp": row[4], "run": row[5], "slow": row[6], "fast": row[7], "phase": randf() * TAU, "flicker": row[0] == "flames"})
	var arm_x := _arm_x(hero, dressed_top)
	_arm_l = Node3D.new()
	_arm_l.position = Vector3(-arm_x, ARM_Y, 0)
	_hips.add_child(_arm_l)
	_arm_r = Node3D.new()
	_arm_r.position = Vector3(arm_x, ARM_Y, 0)
	_hips.add_child(_arm_r)
	var arm := _shared("arm|%s|%s" % [skin_key, dressed_top], _build_arm.bind(hero, skin, dressed_top))
	_add_part(_arm_l, arm, Vector3.ZERO)
	_add_part(_arm_r, arm, Vector3.ZERO)
	if top_id != "":
		var sleeve := _shared("sleeve|" + top_id, AvatarParts.sleeve.bind(top_id))
		_add_part(_arm_l, sleeve, Vector3.ZERO)
		_add_part(_arm_r, sleeve, Vector3.ZERO)
	var gloves_id: String = look.get("gloves", "")
	_arm_spread = 0.3 if Cosmetics.item("gloves", gloves_id).get("style", "") == "boxing" else 0.0
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
	_hat = null
	if hat_id != "":
		_hat = Node3D.new()
		var fit := _helmet_fit(hero) if hat_id == "astronaut" else _hat_fit(hero, mask_id, cover, plain)
		_hat.position = fit[0]
		_hat.scale = fit[1]
		_head.add_child(_hat)
		_add_part(_hat, _shared("hat|" + hat_id, _build_hat_or_helmet.bind(hat_id)), Vector3.ZERO)
	_back = null
	var back_id: String = look.get("back", "")
	if back_id != "":
		_back = Node3D.new()
		_back.position = Vector3(0, 0.56, -_back_depth(hero, dressed_top))
		_back.scale = Vector3.ONE * 0.82
		_hips.add_child(_back)
		var back_key := "back|%s|%s" % [back_id, team_color.to_html() if back_id == "flag" else ""]
		_add_part(_back, _shared(back_key, _build_back.bind(back_id, team_color)), Vector3.ZERO)
	_add_country_flag(str(look.get("flag", "")), hero, dressed_top)
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
		kit.shells = false
		kit.detail = 0.8 if Quality.is_low() else 1.0
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
	_kick = maxf(_kick, amount)


# --- Fitting what's worn to each head and body ------------------------------------------------------

## A mascot's head is a plain ball under a mask that covers its mouth: those heads come in shapes no mask could hug
## (a cup, a box, a flame, a crystal), and their faces are part of the shape.
static func _plain_head(hero: Dictionary, cover: String) -> bool:
	return hero.get("kind") == "mascot" and cover in ["low", "plate"]


## 0: the head stays as it is. 1: a hat, so what stands up off the head comes down. 2: a helmet round all of it.
static func _hat_level(hero: Dictionary, hat_id: String) -> int:
	if hat_id == "":
		return 0
	if hat_id == "astronaut":
		return 2
	if hat_id in ["headband", "flowers"]:
		return 0
	return 1 if hero.get("kind") == "mascot" or hat_id not in HATS_OVER_HAIR else 0


## The surface a face is drawn on, as an ellipsoid: its middle and its size. A flat screen has none.
static func _face_surface(hero: Dictionary, plain: bool) -> Array:
	if not plain:
		match String(hero.get("shape", "")):
			"cup": return [Vector3(0, -0.1, 0), Vector3(0.43, 0.9, 0.4)]
			"flame": return [Vector3(0, -0.12, 0.2), Vector3(0.36, 0.33, 0.28)]
			"crystal": return [Vector3(0, 0.12, 0), Vector3(0.46, 0.5, 0.46)]
			"robot": return []
	return _head_shape(hero, plain)


## This head as an ellipsoid: its middle, its size, and the height of its eyes.
static func _head_shape(hero: Dictionary, plain: bool) -> Array:
	if not plain:
		if hero.has("surf"):
			return hero["surf"]
		match String(hero.get("animal", "")):
			"tarsier": return [Vector3.ZERO, Vector3(0.48, 0.44, 0.44), 0.06]
			"rooster": return [Vector3.ZERO, Vector3(0.46, 0.46, 0.44), 0.06]
			"": pass
			_: return [Vector3.ZERO, AvatarParts.HEAD, 0.06]
		match String(hero.get("shape", "")):
			"coconut": return [Vector3.ZERO, Vector3(0.52, 0.5, 0.5), 0.0]
			"mango": return [Vector3.ZERO, Vector3(0.48, 0.54, 0.44), 0.0]
			"ghost": return [Vector3(0, -0.02, 0), Vector3(0.5, 0.5, 0.46), 0.05]
			"alien": return [Vector3(0, 0.08, 0), Vector3(0.56, 0.5, 0.48), 0.03]
			"cup": return [Vector3(0, -0.1, 0), Vector3(0.5, 0.46, 0.46), -0.12]
			"robot": return [Vector3(0, 0.06, -0.04), Vector3(0.5, 0.46, 0.46), 0.06]
			"flame": return [Vector3(0, -0.05, 0.02), Vector3(0.5, 0.46, 0.47), -0.05]
			"crystal": return [Vector3(0, -0.02, -0.03), Vector3(0.46, 0.46, 0.44), -0.04]
	return [Vector3.ZERO, AvatarParts.HEAD, -0.03]


## Masks are made for the standard head: this moves, stretches and turns one to fit the head it's on.
static func _fit_mask(part: MeshInstance3D, hero: Dictionary, cover: String, plain: bool) -> void:
	var shape := _head_shape(hero, plain)
	var center: Vector3 = shape[0]
	var r: Vector3 = shape[1]
	part.position = center
	part.scale = r / AvatarParts.HEAD
	if cover == "eyes":  # Eye masks also tip up or down to where the eyes are.
		part.rotation.x = -(asin((float(shape[2]) - center.y) / r.y) - AvatarParts.EYE_LAT)


## Where a hat's brim sits on this head: [height, front-to-back offset, half width, half depth, crown's rise].
static func _crown(hero: Dictionary, mask_id: String, cover: String, plain: bool) -> Array:
	if cover == "whole":
		match mask_id:
			"robot": return [0.3, 0.0, 0.54, 0.48, 0.16]
			"pumpkin": return [0.33, 0.0, 0.56, 0.52, 0.25]
			"higante": return [0.5, -0.06, 0.68, 0.6, 0.34]
			"tiki": return [0.3, 0.0, 0.43, 0.41, 0.22]
		return [0.25, 0.0, 0.46, 0.43, 0.23]
	if plain:
		return [0.24, 0.0, 0.453, 0.418, 0.235]
	if hero.get("kind") == "kid":
		return [0.19, -0.03, 0.57, 0.51, 0.33]
	match String(hero.get("animal", "")):
		"tarsier": return [0.33, 0.0, 0.33, 0.3, 0.11]
		"rooster": return [0.22, 0.0, 0.415, 0.395, 0.24]
		"": pass
		_: return [0.24, 0.0, 0.445, 0.41, 0.22]
	match String(hero.get("shape", "")):
		"coconut": return [0.2, 0.0, 0.49, 0.47, 0.3]
		"mango": return [0.2, 0.0, 0.46, 0.42, 0.34]
		"cup": return [0.2, 0.0, 0.51, 0.51, 0.38]
		"robot": return [0.26, 0.0, 0.5, 0.42, 0.12]
		"ghost": return [0.21, 0.0, 0.45, 0.415, 0.27]
		"alien": return [0.28, 0.0, 0.52, 0.45, 0.3]
		"flame": return [0.12, 0.0, 0.42, 0.385, 0.25]
		"crystal": return [0.14, 0.0, 0.43, 0.43, 0.23]
	return [0.24, 0.0, 0.445, 0.41, 0.22]


## Hats are made for one head; this says how to place and size one for this head: [position, scale].
static func _hat_fit(hero: Dictionary, mask_id: String, cover: String, plain: bool) -> Array:
	var c := _crown(hero, mask_id, cover, plain)
	var sx: float = c[2] / HAT_R
	var sz: float = c[3] / (HAT_R * HAT_DEPTH)
	var sy := maxf(float(c[4]) / HAT_RISE, (sx + sz) * 0.46)
	return [Vector3(0, c[0], c[1]), Vector3(sx, sy, sz)]


## The helmet goes round the whole head, so it fits to all of it, hair included.
static func _helmet_fit(hero: Dictionary) -> Array:
	if hero.get("kind") == "kid":
		return [Vector3(0, 0.05, -0.02), Vector3(0.56, 0.5, 0.52) / AvatarParts.HEAD]
	var shape := _head_shape(hero, false)
	var center: Vector3 = shape[0]
	var r: Vector3 = shape[1]
	match String(hero.get("shape", "")):
		"cup": return [Vector3(0, 0.06, 0), Vector3(1.12, 1.16, 1.14)]
		"robot": return [Vector3.ZERO, Vector3(1.14, 1.1, 1.14)]
		"flame": return [Vector3(0, -0.04, 0), Vector3(1.08, 1.1, 1.1)]
		"crystal": return [Vector3(0, -0.04, 0), Vector3(1.06, 1.06, 1.06)]
	return [center, r / AvatarParts.HEAD]


func _build_hat_or_helmet(k: MeshKit, id: String) -> void:
	if id == "astronaut":
		_helmet(k)
	else:
		_build_hat(k, id)


## How far back the middle of the back is, for whatever hangs on it.
static func _back_depth(hero: Dictionary, dressed: bool) -> float:
	if dressed:
		return 0.265 * _clothes_width(hero)
	if hero.get("kind") == "animal":
		return 0.3
	match String(hero.get("shape", "")):
		"ghost": return 0.36
		"robot": return 0.21
	return 0.26


## Where the shoulders are: out at the edge of the shirt when there's one, or of the body.
static func _arm_x(hero: Dictionary, dressed: bool) -> float:
	if dressed:
		return ARM_X * _clothes_width(hero)
	if hero.get("kind") == "animal":
		return 0.33
	if String(hero.get("shape", "")) == "ghost":
		return 0.4
	return ARM_X


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

## Clothes replace what's under them, so no avatar's body can poke through what it wears.
func _build_body(k: MeshKit, hero: Dictionary, skin: Dictionary, no_top := false, no_low := false) -> void:
	var w := _clothes_width(hero)
	var low_at := Vector3(0, 0.28, 0)
	var low_r := Vector3(0.3 * w, 0.15, 0.24 * w)
	match hero["kind"]:
		"kid":
			var top := _main(hero, skin, "top")
			var low := _second(hero, skin, "low")
			if not no_low:
				k.ball(low_at, low_r, low, 12, 18)
			var top_r := Vector3(0.31, 0.27, 0.25)
			var top_at := Vector3(0, 0.48, 0)
			if not no_top:
				k.ball(top_at, top_r, top, 12, 18)
				k.band(top_at, top_r, -0.235, -0.2, top.lightened(0.32))
				k.spot(top_at, top_r, 0.0, -0.06, 0.075, top.lightened(0.35))
		"animal":
			var fur := _main(hero, skin, "fur")
			var belly := _second(hero, skin, "belly")
			if no_top:
				if not no_low:
					k.ball(low_at, low_r, fur, 12, 18)
			else:
				k.ball(Vector3(0, 0.46, 0), Vector3(0.34, 0.33, 0.3), fur, 12, 18)
				k.round_patch(Vector3(0, 0.46, 0), Vector3(0.34, 0.33, 0.3), 0.0, -0.05, 0.215, 0.22, belly)
		_:
			var main := _main(hero, skin, "main")
			var shape: String = hero.get("shape", "")
			if shape == "ghost":
				if no_top and not no_low:  # A shirt, with the wispy hem showing below it.
					k.cyl(Vector3(0, 0.14, 0), 0.2, 0.42, 0.34, main, 18)
					_ghost_hem(k, main)
				elif no_low and not no_top:
					k.ball(Vector3(0, 0.5, 0), Vector3(0.4, 0.33, 0.34), main, 12, 18)
				elif not no_top:
					k.cyl(Vector3(0, 0.14, 0), 0.6, 0.42, 0.36, main, 18)
					_ghost_hem(k, main)
				return
			if no_top:
				if not no_low:
					k.ball(low_at, low_r, main.darkened(0.08), 12, 18)
				return
			match shape:
				"robot":
					var at := Vector3(0, 0.52, 0) if no_low else Vector3(0, 0.46, 0)
					var half := Vector3(0.28, 0.2, 0.21) if no_low else Vector3(0.28, 0.24, 0.21)
					k.soft_box(at, half, main.darkened(0.1), 0.6)
					k.spot(at, half + Vector3(0, 0, 0.005), -0.08, 0.0, 0.03, Color("ff4f6a"))
					k.spot(at, half + Vector3(0, 0, 0.005), 0.0, 0.0, 0.03, Color("35d07f"))
					k.spot(at, half + Vector3(0, 0, 0.005), 0.08, 0.0, 0.03, Color("3aa6ff"))
				"flame":
					k.ball(Vector3(0, 0.44, 0), Vector3(0.3, 0.3, 0.27), _second(hero, skin, "second"), 12, 18)
				"crystal":
					k.ball(Vector3(0, 0.44, 0), Vector3(0.28, 0.3, 0.26), _second(hero, skin, "second").darkened(0.08), 12, 18)
				"cup":
					k.ball(Vector3(0, 0.44, 0), Vector3(0.3, 0.3, 0.27), main.darkened(0.08), 12, 18)
				_:
					if not HeroParts.body(k, hero, main, _second(hero, skin, "second")):
						k.ball(Vector3(0, 0.46, 0), Vector3(0.31, 0.32, 0.28), main.lightened(0.05), 12, 18)


func _ghost_hem(k: MeshKit, main: Color) -> void:
	for i in 8:
		var a := TAU * i / 8.0
		k.ball(Vector3(cos(a) * 0.36, 0.14, sin(a) * 0.36), Vector3(0.125, 0.125, 0.125), main, 8, 10)


## A short round arm ending in an oblong mitten of a hand. No fingers: it's cuter.
func _build_arm(k: MeshKit, hero: Dictionary, skin: Dictionary, dressed := false) -> void:
	var arm := Color.WHITE
	var hand := Color.WHITE
	var sleeve := Color(0, 0, 0, 0)
	var cuff := Color(0, 0, 0, 0)
	match hero["kind"]:
		"kid":
			arm = Color(hero["skin"])
			hand = arm
			sleeve = _main(hero, skin, "top") if not dressed else Color(0, 0, 0, 0)
		"animal":
			arm = _main(hero, skin, "fur")
			hand = _second(hero, skin, "belly").lerp(arm, 0.3)
		_:
			arm = Color(hero["arm"]) if hero.has("arm") else _main(hero, skin, "main").darkened(0.08)
			hand = Color(hero["hand"]) if hero.has("hand") else Color("fbf7ff")
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
	if plain:  # Close enough together to look at you, and big enough to see from across the field.
		gap *= 1.05
		y -= 0.02
		size *= 1.2
	_eye_seen.merge({"y": y, "z": z, "gap": gap, "size": size, "white": white, "plain": plain, "solid": white.get_luminance() < 0.2}, true)


## Shows an expression: normal, blink, happy, sad, shock, dizzy or focus. Each is one small mesh, shared by
## every avatar with the same head, and swapping it costs nothing.
func _show_face(expression: String) -> void:
	if _face == null or expression == _shown_face or not _eye_info.has(_face_key):
		return
	_shown_face = expression
	_face.mesh = _shared("face|%s|%s" % [_face_key, expression], _build_face.bind(_eye_info[_face_key], expression, _face_hide))


func _build_face(k: MeshKit, info: Dictionary, expression: String, hide := "") -> void:
	var blinking := expression.ends_with("|b")
	var face_name := expression.trim_suffix("|b")
	var parts: Array = Faces.PARTS.get(face_name, Faces.PARTS["normal"])
	var who := Faces.person(String(info.get("hero", "")))
	k.outline = 0.0
	if hide != "mouth":
		_cheeks(k, info)
		if info.has("whiskers"):
			_whiskers(k, info)
	if hide != "eyes":
		for i in 2:
			var s := -1.0 if i == 0 else 1.0
			var kind := "shut" if blinking else String(parts[i])
			if kind == "dot" and face_name == "normal":
				kind = String(who.get("eyes", "dot"))
			k.push(_face_frame(info, _on_head(info, s * float(info["gap"]), float(info["y"]), 0.0)))
			_eye(k, info, kind, Vector3.ZERO, s)
			k.pop()
	if info.has("mouth_y") and hide != "mouth":
		_draw_mouth(k, info, String(parts[2]))
	for i in range(3, parts.size()):
		_face_extra(k, info, String(parts[i]), hide)
	k.outline = 0.02


## An eye's own frame: facing the way the head does at that spot, so it hugs the head however far round it is.
static func _face_frame(info: Dictionary, at: Vector3) -> Transform3D:
	var shape: Array = info["shape"]
	if shape.is_empty():
		return Transform3D(Basis.IDENTITY, at)
	var r: Vector3 = shape[1]
	var n := ((at - (shape[0] as Vector3)) / (r * r)).normalized()
	return Transform3D(Basis(Vector3.UP, atan2(n.x, n.z)) * Basis(Vector3.RIGHT, -asin(clampf(n.y, -1.0, 1.0))), at)


## An eye with its white showing, and a dark ring so it reads on any colour of head.
func _white_eye(k: MeshKit, at: Vector3, rx: float, ry: float, rz: float, ink: Color) -> void:
	k.ball(at, Vector3(rx * 1.13, ry * 1.1, rz * 0.9), ink, 8, 12)
	k.ball(at + Vector3(0, 0, rz * 0.12), Vector3(rx, ry, rz), Color.WHITE, 8, 12)


func _eye(k: MeshKit, info: Dictionary, kind: String, at: Vector3, s: float) -> void:
	var size: float = info["size"]
	var ink: Color = info.get("ink", Color("1a1030"))
	var flat := at.z + size * 0.22 + 0.006
	match kind:
		"dot", "dot_l", "dot_r":
			var look := -1.0 if kind == "dot_l" else (1.0 if kind == "dot_r" else 0.0)
			var moved := at + Vector3(look * size * 0.24, 0, 0)
			if info.has("ink"):  # A robot's lit-up eyes.
				k.ball(moved, Vector3(size * 0.92, size * 0.92, size * 0.36), ink, 10, 14)
			elif bool(info["plain"]) or bool(info["solid"]):
				k.ball(moved, Vector3(size * 0.76, size * 1.04, size * 0.42), ink, 10, 14)
			else:  # The tarsier's huge ringed eyes: only the pupil moves.
				k.ball(at, Vector3(size, size * 1.1, size * 0.42), info["white"], 10, 14)
				moved = at + Vector3(look * size * 0.34, -size * 0.05, size * 0.26)
				k.ball(moved, Vector3(size * 0.62, size * 0.74, size * 0.22), ink, 8, 12)
			# Big shiny glints: nothing looks friendlier.
			k.ball(moved + Vector3(-size * 0.22, size * 0.42, size * 0.36), Vector3(size * 0.27, size * 0.29, size * 0.07), Color.WHITE, 5, 8)
			k.ball(moved + Vector3(size * 0.26, -size * 0.36, size * 0.36), Vector3(size * 0.12, size * 0.12, size * 0.05), Color.WHITE, 4, 7)
		"shut":
			_arc(k, at, size, -0.22, ink)
		"up":
			_arc(k, at, size, 0.5, ink)
		"down":  # u u
			_arc(k, at, size, -0.62, ink)
		"squint":  # > <
			_line(k, at + Vector3(s * size * 0.62, size * 0.5, size * 0.34), at + Vector3(-s * size * 0.62, 0.0, size * 0.4), size * 0.17, ink)
			_line(k, at + Vector3(-s * size * 0.62, 0.0, size * 0.4), at + Vector3(s * size * 0.62, -size * 0.5, size * 0.34), size * 0.17, ink)
		"x":
			_line(k, at + Vector3(-size * 0.6, size * 0.6, size * 0.36), at + Vector3(size * 0.6, -size * 0.6, size * 0.36), size * 0.17, ink)
			_line(k, at + Vector3(-size * 0.6, -size * 0.6, size * 0.37), at + Vector3(size * 0.6, size * 0.6, size * 0.37), size * 0.17, ink)
		"wide":
			_white_eye(k, at, size * 0.82, size * 1.05, size * 0.36, ink)
			k.ball(at + Vector3(0, 0, size * 0.34), Vector3(size * 0.3, size * 0.36, size * 0.1), ink, 6, 9)
		"sad":
			k.ball(at + Vector3(0, -size * 0.1, 0), Vector3(size * 0.62, size * 0.84, size * 0.38), ink, 8, 12)
			k.ball(at + Vector3(-size * 0.16, size * 0.16, size * 0.3), Vector3(size * 0.2, size * 0.2, size * 0.06), Color.WHITE, 4, 6)
			_line(k, at + Vector3(s * size * 0.75, size * 0.8, size * 0.3), at + Vector3(-s * size * 0.5, size * 1.15, size * 0.3), size * 0.1, ink)
			k.ball(at + Vector3(s * size * 0.32, -size * 1.05, size * 0.3), Vector3(size * 0.2, size * 0.3, size * 0.1), Color("7fdcff"), 5, 8)
		"half":  # Half shut: unbothered, or half asleep.
			var lid := PackedVector3Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				lid.append(Vector3(at.x + cos(a) * size * 0.76, at.y + sin(a) * size * 0.8, flat))
			k.fan(lid, ink)
			_line(k, Vector3(at.x - size * 0.95, at.y + size * 0.02, flat + 0.002), Vector3(at.x + size * 0.95, at.y + size * 0.02, flat + 0.002), size * 0.14, ink)
			k.ball(Vector3(at.x - size * 0.2, at.y - size * 0.26, flat + 0.002), Vector3(size * 0.16, size * 0.16, size * 0.05), Color.WHITE, 4, 6)
		"side":  # Both eyes off to one side.
			_white_eye(k, at, size * 0.82, size * 0.98, size * 0.36, ink)
			k.ball(at + Vector3(size * 0.36, -size * 0.04, size * 0.34), Vector3(size * 0.36, size * 0.48, size * 0.1), ink, 6, 9)
		"heart":
			var heart := PackedVector3Array()
			for i in range(23, -1, -1):
				var t := TAU * i / 24.0
				var x := 16.0 * pow(sin(t), 3.0)
				var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
				heart.append(Vector3(at.x + x * size * 0.072, at.y + y * size * 0.072, flat))
			k.fan(heart, Color("ff3f6a"))
			k.ball(Vector3(at.x - size * 0.42, at.y + size * 0.36, flat + 0.004), Vector3(size * 0.16, size * 0.13, size * 0.05), Color.WHITE, 4, 6)
		"star":
			var star := PackedVector3Array()
			for i in 10:
				var a := PI * 0.5 + PI * i / 5.0
				var r := size * (1.08 if i % 2 == 0 else 0.5)
				star.append(Vector3(at.x + cos(a) * r, at.y + sin(a) * r, flat))
			k.fan(star, Color("ffc21f"))
			k.ball(Vector3(at.x, at.y, flat + 0.004), Vector3(size * 0.2, size * 0.2, size * 0.05), Color("fff6b0"), 4, 7)
		"coin":
			k.ball(at, Vector3(size * 0.92, size * 0.92, size * 0.36), Color("e89a10"), 8, 12)
			k.ball(at + Vector3(0, 0, size * 0.14), Vector3(size * 0.68, size * 0.68, size * 0.26), Color("ffd23f"), 8, 12)
			_line(k, Vector3(at.x, at.y + size * 0.42, at.z + size * 0.4), Vector3(at.x, at.y - size * 0.42, at.z + size * 0.4), size * 0.12, Color("e89a10"))
		"tiny":  # . .
			k.ball(at, Vector3(size * 0.28, size * 0.32, size * 0.16), ink, 5, 8)
		"big":
			_white_eye(k, at, size * 1.1, size * 1.25, size * 0.36, ink)
			k.ball(at + Vector3(-size * 0.3, size * 0.28, size * 0.34), Vector3(size * 0.34, size * 0.4, size * 0.1), ink, 6, 9)
		"small":
			_white_eye(k, at, size * 0.6, size * 0.66, size * 0.3, ink)
			k.ball(at + Vector3(size * 0.18, -size * 0.22, size * 0.28), Vector3(size * 0.2, size * 0.22, size * 0.07), ink, 5, 8)
		"line":  # - -
			_line(k, Vector3(at.x - size * 0.72, at.y, flat), Vector3(at.x + size * 0.72, at.y, flat), size * 0.14, ink)
		"mad":
			k.ball(at + Vector3(0, -size * 0.14, 0), Vector3(size * 0.56, size * 0.72, size * 0.4), ink, 8, 12)
			k.ball(at + Vector3(-size * 0.14, -size * 0.04, size * 0.33), Vector3(size * 0.14, size * 0.14, size * 0.05), Color.WHITE, 4, 6)
			_line(k, Vector3(at.x + s * size * 0.95, at.y + size * 1.02, flat + 0.004), Vector3(at.x - s * size * 0.95, at.y + size * 0.46, flat + 0.004), size * 0.2, ink)
		"puppy":  # Big, wet, begging eyes.
			k.ball(at, Vector3(size * 0.86, size * 1.15, size * 0.4), ink, 10, 14)
			k.ball(at + Vector3(-size * 0.26, size * 0.46, size * 0.36), Vector3(size * 0.28, size * 0.3, size * 0.08), Color.WHITE, 5, 8)
			k.ball(at + Vector3(size * 0.28, -size * 0.34, size * 0.36), Vector3(size * 0.16, size * 0.18, size * 0.06), Color.WHITE, 4, 7)
			k.ball(at + Vector3(0, -size * 0.74, size * 0.3), Vector3(size * 0.44, size * 0.16, size * 0.06), Color("7fdcff"), 4, 8)
		"swirl":  # @ @
			var turns := PackedVector3Array()
			for i in 25:
				var f := i / 24.0
				var a := f * TAU * 2.25 * s
				var r := size * lerpf(0.08, 0.92, f)
				turns.append(Vector3(at.x + cos(a) * r, at.y + sin(a) * r, flat))
			k.ribbon(turns, size * 0.13, ink)
		_:
			FaceParts.eye(self, k, info, kind, at, s)


# --- Painted on the face, following its curve ---------------------------------------------------------

## A point on the surface of this head, for what's drawn on it.
static func _on_head(info: Dictionary, x: float, y: float, lift := 0.012) -> Vector3:
	var shape: Array = info["shape"]
	if shape.is_empty():  # A flat screen.
		return Vector3(x, y, float(info["z"]) + lift)
	var c: Vector3 = shape[0]
	var r: Vector3 = shape[1]
	var q := 1.0 - pow((x - c.x) / r.x, 2.0) - pow((y - c.y) / r.y, 2.0)
	return Vector3(x, y, c.z + r.z * sqrt(maxf(q, 0.0)) + lift)


## A shape of paint, its points going counter-clockwise from the front, lying right on the surface of the face.
func _paint(k: MeshKit, info: Dictionary, points: PackedVector2Array, color: Color, lift := 0.006) -> void:
	color.a = 0.0
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= float(points.size())
	var rings := 3
	var n := Vector3.BACK
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		for ring in rings:
			var f0 := float(ring) / rings
			var f1 := float(ring + 1) / rings
			var p0 := _on_head(info, lerpf(center.x, a.x, f0), lerpf(center.y, a.y, f0), lift)
			var p1 := _on_head(info, lerpf(center.x, a.x, f1), lerpf(center.y, a.y, f1), lift)
			var p2 := _on_head(info, lerpf(center.x, b.x, f1), lerpf(center.y, b.y, f1), lift)
			var p3 := _on_head(info, lerpf(center.x, b.x, f0), lerpf(center.y, b.y, f0), lift)
			k._tri(p0, p1, p2, n, n, n, color, color, color, false)
			if ring > 0:
				k._tri(p0, p2, p3, n, n, n, color, color, color, false)


## A line of paint along a path, tapering at both ends.
func _stroke(k: MeshKit, info: Dictionary, path: PackedVector2Array, half: float, color: Color, lift := 0.012) -> void:
	color.a = 0.0
	var count := path.size()
	var upper := PackedVector3Array()
	var lower := PackedVector3Array()
	for i in count:
		var along := (path[mini(i + 1, count - 1)] - path[maxi(i - 1, 0)]).normalized()
		var side := Vector2(-along.y, along.x) * half * (0.3 + 0.7 * sin(PI * float(i) / (count - 1)))
		var a := path[i] + side
		var b := path[i] - side
		upper.append(_on_head(info, a.x, a.y, lift))
		lower.append(_on_head(info, b.x, b.y, lift))
	var n := Vector3.BACK
	for i in count - 1:
		k._quad(lower[i], lower[i + 1], upper[i + 1], upper[i], n, color, color, color, color, false)


static func _oval(at: Vector2, rx: float, ry: float, count := 18) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in count:
		var a := TAU * i / count
		out.append(at + Vector2(cos(a) * rx, sin(a) * ry))
	return out


func _cheeks(k: MeshKit, info: Dictionary, color: Variant = null) -> void:
	if not info.has("cheek") and color == null:
		return
	var size := minf(float(info["size"]), 0.15)
	var y: float = float(info["y"]) - size * 1.05
	var x: float = float(info["gap"]) + size * 0.72
	for s: float in [-1.0, 1.0]:
		_paint(k, info, _oval(Vector2(s * x, y), size * 0.66, size * 0.38), color if color != null else info["cheek"], 0.004)


func _whiskers(k: MeshKit, info: Dictionary) -> void:
	var ink := Color("3a2a1c")
	for s: float in [-1.0, 1.0]:
		for i in 2:
			var y := -0.1 - i * 0.055
			_stroke(k, info, PackedVector2Array([Vector2(s * 0.3, y), Vector2(s * 0.37, y + 0.008 - i * 0.012), Vector2(s * 0.44, y + 0.022 - i * 0.03)]), 0.012, ink)


## A D of an open smile.
static func _mouth_shape(y: float, width: float, turn := 1.0) -> PackedVector2Array:
	var steps := 14
	var out := PackedVector2Array()
	for i in steps + 1:  # The lower lip, left to right...
		var f := lerpf(-1.0, 1.0, i / float(steps))
		out.append(Vector2(f * width, y + turn * (0.012 * f * f - width * (1.0 - f * f))))
	for i in range(steps - 1, 0, -1):  # ...and the upper lip back.
		var f := lerpf(-1.0, 1.0, i / float(steps))
		out.append(Vector2(f * width, y + turn * (0.012 * f * f - width * 0.1 * (1.0 - f * f))))
	if turn < 0.0:
		out.reverse()
	return out


func _open_mouth(k: MeshKit, info: Dictionary, y: float, width: float, upside := false) -> void:
	var turn := -1.0 if upside else 1.0
	var base_y := y - width * 0.7 if upside else y
	_paint(k, info, _mouth_shape(base_y, width, turn), Color("8a1f3c"))
	_paint(k, info, _oval(Vector2(0, base_y - turn * width * 0.66), width * 0.52, width * 0.27), Color("ff8fa6"), 0.009)


## A row of top teeth along the inside of an open mouth, with a tooth missing if you like.
func _top_teeth(k: MeshKit, info: Dictionary, y: float, width: float, gap := false) -> void:
	var points := PackedVector2Array()
	for i in 13:
		var f := lerpf(-0.86, 0.86, i / 12.0)
		points.append(Vector2(f * width, y - width * 0.42 * (1.0 - f * f * 0.75)))
	for i in range(12, -1, -1):
		var f := lerpf(-0.86, 0.86, i / 12.0)
		points.append(Vector2(f * width, y + 0.012 * f * f - width * 0.1 * (1.0 - f * f)))
	_paint(k, info, points, Color.WHITE, 0.012)
	if gap:
		_paint(k, info, _oval(Vector2(width * 0.24, y - width * 0.27), width * 0.13, width * 0.18, 10), Color("8a1f3c"), 0.015)


## A wide grin of a shape: a stadium, with its corners turned up.
static func _grin_shape(y: float, width: float, height: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		var x := cos(a) * width
		out.append(Vector2(x, y + sin(a) * height + pow(x / width, 2.0) * height * 0.55))
	return out


func _draw_mouth(k: MeshKit, info: Dictionary, kind: String) -> void:
	var y: float = info["mouth_y"]
	var w: float = info["mouth_w"]
	var dark := Color("6a2038")
	if kind == "smile":
		kind = String(Faces.person(String(info.get("hero", ""))).get("mouth", "smile"))
	match kind:
		"none":
			pass
		"smile":
			_open_mouth(k, info, y, w)
		"big":
			_open_mouth(k, info, y, w * 1.3)
		"laugh":
			_open_mouth(k, info, y, w * 1.75)
			_top_teeth(k, info, y, w * 1.75)
		"gap":  # A big grin, with a tooth missing.
			_open_mouth(k, info, y, w * 1.35)
			_top_teeth(k, info, y, w * 1.35, true)
		"buck":  # A goofy smile and two big front teeth.
			var line := PackedVector2Array()
			for i in 13:
				var f := lerpf(-1.0, 1.0, i / 12.0)
				line.append(Vector2(f * w * 1.2, y - w * 0.3 * (1.0 - f * f)))
			var top := y - w * 0.27
			for s: float in [-1.0, 1.0]:
				var tooth := Vector2(s * w * 0.33, top - w * 0.36)
				_paint(k, info, _grin_shape(tooth.y, w * 0.36, w * 0.46), dark, 0.008)
				_paint(k, info, _grin_shape(tooth.y, w * 0.29, w * 0.38), Color.WHITE, 0.012)
			_stroke(k, info, line, w * 0.14, dark, 0.016)
		"sad":
			var pts := PackedVector2Array()
			for i in 9:
				var f := lerpf(-1.0, 1.0, i / 8.0)
				pts.append(Vector2(f * w * 0.85, y - w * 0.42 + w * 0.3 * (1.0 - f * f)))
			_stroke(k, info, pts, w * 0.14, dark)
		"shock":
			_paint(k, info, _oval(Vector2(0, y - w * 0.42), w * 0.46, w * 0.6), Color("7a1f3a"))
		"flat":
			_stroke(k, info, PackedVector2Array([Vector2(-w * 0.6, y - w * 0.3), Vector2(0, y - w * 0.3), Vector2(w * 0.6, y - w * 0.3)]), w * 0.14, dark)
		"tiny":
			_stroke(k, info, PackedVector2Array([Vector2(-w * 0.34, y - w * 0.3), Vector2(0, y - w * 0.3), Vector2(w * 0.34, y - w * 0.3)]), w * 0.15, dark)
		"o":
			_paint(k, info, _oval(Vector2(0, y - w * 0.3), w * 0.32, w * 0.4, 12), dark)
		"boo":
			_paint(k, info, _oval(Vector2(0, y - w * 0.4), w * 0.9, w * 1.2), UiKit.INK)
		"wavy":
			var pts := PackedVector2Array()
			for i in 11:
				var f := lerpf(-1.0, 1.0, i / 10.0)
				pts.append(Vector2(f * w, y - w * 0.35 + sin(f * 7.0) * w * 0.16))
			_stroke(k, info, pts, w * 0.13, dark)
		"smirk":  # Up at one side.
			var pts := PackedVector2Array()
			for i in 11:
				var f := lerpf(-0.6, 1.15, i / 10.0)
				pts.append(Vector2(f * w, y - w * 0.3 + pow(maxf(f, 0.0), 2.0) * w * 0.42))
			_stroke(k, info, pts, w * 0.16, dark)
		"cat":  # w
			var pts := PackedVector2Array()
			for i in 17:
				var f := lerpf(-1.0, 1.0, i / 16.0)
				pts.append(Vector2(f * w * 0.95, y - w * 0.12 - absf(sin(f * PI)) * w * 0.42))
			_stroke(k, info, pts, w * 0.17, dark)
		"pout":
			var pts := PackedVector2Array()
			for i in 9:
				var f := lerpf(-1.0, 1.0, i / 8.0)
				pts.append(Vector2(f * w * 0.42, y - w * 0.46 + (1.0 - f * f) * w * 0.3))
			_stroke(k, info, pts, w * 0.18, dark)
		"tongue":  # Blep.
			_paint(k, info, _grin_shape(y - w * 0.75, w * 0.45, w * 0.62), dark, 0.006)
			_paint(k, info, _grin_shape(y - w * 0.75, w * 0.36, w * 0.54), Color("ff8fa6"), 0.01)
			_stroke(k, info, PackedVector2Array([Vector2(0, y - w * 0.36), Vector2(0, y - w * 0.72), Vector2(0, y - w * 1.08)]), w * 0.06, Color("d65c78"), 0.014)
			var smile := PackedVector2Array()
			for i in 13:
				var f := lerpf(-1.0, 1.0, i / 12.0)
				smile.append(Vector2(f * w * 1.1, y - w * 0.32 * (1.0 - f * f)))
			_stroke(k, info, smile, w * 0.14, dark, 0.016)
		"teeth":
			_paint(k, info, _grin_shape(y - w * 0.4, w * 1.42, w * 0.56), dark, 0.006)
			_paint(k, info, _grin_shape(y - w * 0.4, w * 1.28, w * 0.44), Color.WHITE, 0.01)
			for f: float in [-0.5, 0.0, 0.5]:
				_stroke(k, info, PackedVector2Array([Vector2(f * w * 1.28, y - w * 0.06), Vector2(f * w * 1.28, y - w * 0.4), Vector2(f * w * 1.28, y - w * 0.8)]), w * 0.05, Color("c9b8d8"), 0.014)
		"gritted":
			_paint(k, info, _grin_shape(y - w * 0.42, w * 1.25, w * 0.5), dark, 0.006)
			_paint(k, info, _grin_shape(y - w * 0.42, w * 1.12, w * 0.39), Color.WHITE, 0.01)
			var pts := PackedVector2Array()
			for i in 13:
				var f := lerpf(-0.92, 0.92, i / 12.0)
				pts.append(Vector2(f * w * 1.12, y - w * 0.42 + f * f * w * 0.2 + (w * 0.1 if i % 2 == 0 else -w * 0.1)))
			_stroke(k, info, pts, w * 0.06, dark, 0.014)
		"wail":
			_open_mouth(k, info, y - w * 0.2, w * 1.4, true)
		"scream":
			_paint(k, info, _oval(Vector2(0, y - w * 0.85), w * 0.72, w * 1.15), Color("5a1730"))
			_paint(k, info, _oval(Vector2(0, y - w * 1.42), w * 0.42, w * 0.42), Color("ff8fa6"), 0.01)
		_:
			FaceParts.mouth(self, k, info, kind)


## Things drawn on the head round the eyes and mouth: blushes, tears, and comic marks.
func _face_extra(k: MeshKit, info: Dictionary, kind: String, hide: String) -> void:
	var y: float = info["y"]
	var gap: float = info["gap"]
	var size: float = info["size"]
	match kind:
		"blush":
			if hide != "mouth":
				_cheeks(k, info, Color("ff5f86"))
		"tears":
			if hide == "eyes":
				return
			for s: float in [-1.0, 1.0]:
				for i in 3:
					var drop_y := y - size * (1.05 + i * 0.72)
					var drop_r := size * (0.2 + 0.05 * i)
					k.ball(_on_head(info, s * gap, drop_y, 0.016), Vector3(drop_r, drop_r * 1.5, 0.012), Color("7fdcff"), 5, 8)
		"tear":
			if hide != "eyes":
				k.ball(_on_head(info, gap + size * 0.7, y - size * 0.7, 0.016), Vector3(size * 0.22, size * 0.36, 0.012), Color("7fdcff"), 5, 8)
		"sweat":
			k.ball(_on_head(info, gap + size * 0.9, y + size * 0.8, 0.016), Vector3(size * 0.3, size * 0.46, 0.014), Color("8fe3ff"), 5, 9)
			k.ball(_on_head(info, gap + size * 0.82, y + size * 0.92, 0.03), Vector3(size * 0.08, size * 0.12, 0.004), Color.WHITE, 3, 5)
		"vein":  # The little cross of comic-book anger.
			var at := Vector2(gap + size * 0.7, y + size * 1.25)
			var r := size * 0.42
			_stroke(k, info, PackedVector2Array([at + Vector2(-r, r * 0.3), at + Vector2(0, r * 0.3), at + Vector2(r, r * 0.3)]), size * 0.09, Color("e8282f"), 0.016)
			_stroke(k, info, PackedVector2Array([at + Vector2(-r, -r * 0.3), at + Vector2(0, -r * 0.3), at + Vector2(r, -r * 0.3)]), size * 0.09, Color("e8282f"), 0.016)
			_stroke(k, info, PackedVector2Array([at + Vector2(-r * 0.3, r), at + Vector2(-r * 0.3, 0), at + Vector2(-r * 0.3, -r)]), size * 0.09, Color("e8282f"), 0.016)
			_stroke(k, info, PackedVector2Array([at + Vector2(r * 0.3, r), at + Vector2(r * 0.3, 0), at + Vector2(r * 0.3, -r)]), size * 0.09, Color("e8282f"), 0.016)
		"sparkle":
			if hide == "eyes":
				return
			for offset: Vector2 in [Vector2(gap + size * 0.9, y + size * 0.86), Vector2(-gap - size * 0.9, y - size * 0.3)]:
				var at := _on_head(info, offset.x, offset.y, 0.016)
				var points := PackedVector3Array()
				for i in 8:
					var a := PI * i / 4.0
					var r := size * (0.42 if i % 2 == 0 else 0.1)
					points.append(at + Vector3(cos(a) * r, sin(a) * r, 0))
				k.fan(points, Color.WHITE)
		"zzz":
			for i in 2:
				var at := _on_head(info, gap + size * (0.5 + i * 0.5), y + size * (1.0 + i * 0.8), 0.02)
				var r := size * (0.26 + i * 0.1)
				_line(k, at + Vector3(-r, r, 0), at + Vector3(r, r, 0), size * 0.07, Color("3a6aff"))
				_line(k, at + Vector3(r, r, 0), at + Vector3(-r, -r, 0), size * 0.07, Color("3a6aff"))
				_line(k, at + Vector3(-r, -r, 0), at + Vector3(r, -r, 0), size * 0.07, Color("3a6aff"))
		"bubble":  # Asleep, with a bubble at the nose.
			if hide == "mouth":
				return
			var at := _on_head(info, size * 0.5, y - size * 0.76, 0.03)
			k.ball(at, Vector3(size * 0.46, size * 0.46, size * 0.16), Color("c9f1ff"), 6, 10)
			k.ball(at + Vector3(-size * 0.14, size * 0.16, size * 0.14), Vector3(size * 0.1, size * 0.1, size * 0.03), Color.WHITE, 3, 5)
		_:
			FaceParts.extra(self, k, info, kind, hide)


## One eye drawn as a curve: bent up for a happy ^, or down for a blink.
func _arc(k: MeshKit, at: Vector3, size: float, bend: float, color: Color) -> void:
	var pts := PackedVector3Array()
	for i in 11:
		var f := lerpf(-1.0, 1.0, i / 10.0)
		pts.append(at + Vector3(f * size * 0.8, size * bend * (1.0 - f * f) - size * 0.05, size * 0.38 * sqrt(maxf(1.0 - f * f * 0.72, 0.0)) + 0.012))
	k.ribbon(pts, size * 0.17, color)


func _line(k: MeshKit, a: Vector3, b: Vector3, half_width: float, color: Color) -> void:
	var pts := PackedVector3Array()
	for i in 7:
		pts.append(a.lerp(b, i / 6.0))
	k.ribbon(pts, half_width, color)


## A passing expression, for moments like a tag.
func react(expression: String, seconds := 1.2) -> void:
	_react = expression
	_react_left = seconds


## One from this list, for a passing moment.
func react_any(faces: Array, seconds := 1.2) -> void:
	react(String(faces[randi() % faces.size()]), seconds)


## What the face shows right now: a passing reaction, what's happening to the avatar, or the face they chose.
func _face_for_state() -> String:
	if _react_left > 0.0:
		return _react
	if state != _state_seen:  # Pick once for each time it happens, so the face doesn't flicker between them.
		_state_seen = state
		var faces: Array = Faces.DURING.get(state, [])
		_state_face = String(faces[randi() % faces.size()]) if not faces.is_empty() else ""
	return _state_face if _state_face != "" else _rest_face


func _tick_blink(delta: float) -> void:
	_react_left = maxf(_react_left - delta, 0.0)
	if _react_left <= 0.0 and state in ["idle", "run"]:  # Now and then, for no reason, a silly face.
		_funny_wait -= delta
		if _funny_wait <= 0.0 and not calm:
			_funny_wait = randf_range(7.0, 16.0)
			react(Faces.funny_for(_hero_id), 1.5)
	if _blink_left > 0.0:
		_blink_left -= delta
		if _blink_left <= 0.0:
			_blink_wait = randf_range(1.6, 4.5)
	else:
		_blink_wait -= delta
		if _blink_wait <= 0.0:
			_blink_left = 0.11
	var face := _face_for_state()
	# Now and then, a glance to the side.
	_glance_left = maxf(_glance_left - delta, 0.0)
	_glance_wait -= delta
	if _glance_wait <= 0.0:
		_glance_wait = randf_range(2.5, 6.5)
		_glance_left = randf_range(0.4, 0.9)
		_glance = "look_l" if randf() < 0.5 else "look_r"
	if face == "normal" and _glance_left > 0.0 and not calm and String(Faces.person(_hero_id).get("eyes", "dot")) == "dot":
		face = _glance
	if _blink_left > 0.0 and face in Faces.BLINKING:
		face += "|b"
	_show_face(face)


## Where the mouth goes on this head.
func _smile(_k: MeshKit, y: float, z: float, width: float, _c := Color("b23a55")) -> void:
	_eye_seen.merge({"mouth_y": y, "mouth_z": z, "mouth_w": width}, true)


## `hat`: how much has to come down for what's on the head (see _hat_level). `cover`: how much a mask hides.
func _build_head(k: MeshKit, hero: Dictionary, skin: Dictionary, hat := 0, cover := "") -> void:
	var base := Color.WHITE
	if _plain_head(hero, cover):
		base = _main(hero, skin, "main")
		k.ball(Vector3.ZERO, AvatarParts.HEAD, base, 16, 24)
		_eyes(k, -0.01, 0.395, 0.2, 0.115)
		_smile(k, -0.15, 0.44, 0.095)
	else:
		match hero["kind"]:
			"kid":
				base = Color(hero["skin"])
				_head_kid(k, hero, skin, hat, cover)
			"animal":
				base = _main(hero, skin, "fur")
				_head_animal(k, hero, skin, hat, cover)
			_:
				base = _second(hero, skin, "second") if hero["shape"] == "flame" else _main(hero, skin, "main")
				_head_mascot(k, hero, skin, hat, cover)
	if not _eye_seen.is_empty() and not _eye_seen.has("ink"):
		_eye_seen["cheek"] = Color(hero["cheek"]) if hero.has("cheek") and not _plain_head(hero, cover) else base.lerp(Color("ff5f86"), 0.5)


func _head_kid(k: MeshKit, hero: Dictionary, skin: Dictionary, hat: int, cover: String) -> void:
	var tone := Color(hero["skin"])
	var hair := Color(hero["hair"])
	var head := Vector3(0.5, 0.46, 0.46)
	k.ball(Vector3.ZERO, head, tone, 20, 32)
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.49, -0.04, 0), Vector3(0.08, 0.1, 0.075), tone, 8, 10)
	_eyes(k, -0.01, 0.395, 0.2, 0.115)
	_smile(k, -0.15, 0.44, 0.095)
	var id: String = hero["id"]
	if cover != "plate":  # Everyone has one little thing of their own.
		k.outline = 0.0
		match id:
			"lani", "fiona":  # Freckles.
				for s: float in [-1.0, 1.0]:
					for spot: Vector2 in [Vector2(0.1, -0.075), Vector2(0.14, -0.105), Vector2(0.07, -0.11)]:
						k.spot(Vector3.ZERO, head, s * spot.x, spot.y, 0.012, tone.darkened(0.28))
			"rafael":  # A plaster across the nose. It's from yesterday. There's a new one tomorrow.
				k.round_patch(Vector3.ZERO, head, 0.0, -0.06, 0.085, 0.026, Color("ffe6c2"), 0.008, 16)
				k.round_patch(Vector3.ZERO, head, 0.0, -0.06, 0.025, 0.02, Color("e8b98a"), 0.011, 12)
		k.outline = 0.02
	_hair(k, hair, String(hero.get("style")), cover)
	match String(hero.get("style")):
		"spiky":  # Soft little tufts; the big cowlick flops about on its own.
			if hat == 0:
				for i in 5:
					var a := TAU * i / 5.0 + 0.3
					k.ball(Vector3(cos(a) * 0.22, 0.47, sin(a) * 0.2 - 0.05), Vector3(0.1, 0.11, 0.1), hair, 8, 12)
		"long":
			if hat == 2:
				return
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.45, -0.18, 0.08), Vector3(0.1, 0.32, 0.13), hair, 8, 12)
			if id == "tala" and cover != "plate":  # A star, to go with the hair.
				k.ball(Vector3(0.36, 0.22, 0.28), Vector3(0.06, 0.06, 0.03), Color("ffd23f"), 6, 10)
				k.outline = 0.0
				for i in 5:
					var a := TAU * i / 5.0 + PI * 0.5
					k.ball(Vector3(0.36 + cos(a) * 0.07, 0.22 + sin(a) * 0.07, 0.29), Vector3(0.035, 0.035, 0.018), Color("ffd23f"), 4, 7)
				k.outline = 0.02
		_:
			HeroParts.hair(k, String(hero.get("style")), hair, hat)


## The hair: a shell that hugs the head, so its edge is one clean soft line, with a rounder shape over the top for volume.
## It comes up off the face under a mask that covers the forehead, and up off the neck under a bandana.
func _hair(k: MeshKit, hair: Color, style: String, cover: String) -> void:
	# Over a whole-face mask the hair sits back a little, so that it never cuts across the mask's edge.
	k.ball(Vector3(0, 0.15, -0.11 if cover == "plate" else -0.05), Vector3(0.53, 0.37, 0.47), hair, 20, 32)
	var reach := Vector2(1.5, 1.73)
	var tilt := 0.53
	var rim := 0.014
	k.cap_wave = Vector2(0.035, 12.0)
	match cover:
		"low":
			reach = Vector2(1.5, 1.515)
			tilt = 0.315
		"plate":
			reach = Vector2(1.56, 1.58)
			tilt = 0.68
			rim = 0.0
			k.cap_wave = Vector2.ZERO
		_:
			if style == "bowl" or style == "bob":  # A straight, thick edge all the way round.
				reach = Vector2(1.6, 1.57)
				tilt = 0.22
				rim = 0.032
				k.cap_wave = Vector2.ZERO
	k.push(Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO))
	k.cap(Vector3.ZERO, Vector3(0.51, 0.469, 0.469), hair, reach.x, reach.y, tilt, rim, hair)
	k.pop()
	k.cap_wave = Vector2.ZERO


func _head_animal(k: MeshKit, hero: Dictionary, skin: Dictionary, hat: int, cover: String) -> void:
	var fur := _main(hero, skin, "fur")
	var belly := _second(hero, skin, "belly")
	var accent := Color(hero["accent"])
	var animal: String = hero["animal"]
	var muzzle := cover not in ["low", "plate"]  # Under a mask there's no snout to stick out of it.
	var head := Vector3(0.5, 0.46, 0.46)
	if hero.has("look"):
		HeroParts.animal(self, k, hero, fur, belly, hat, muzzle)
		return
	match animal:
		"tarsier":
			k.ball(Vector3.ZERO, Vector3(0.48, 0.44, 0.44), fur, 16, 24)
			_eyes(k, 0.06, 0.32, 0.22, 0.24, Color("5a2b0e"), Color("ffcf56"))
			if muzzle:
				_smile(k, -0.19, 0.43, 0.06)
		"rooster":
			k.ball(Vector3.ZERO, Vector3(0.46, 0.46, 0.44), fur, 16, 24)
			_eyes(k, 0.1, 0.36, 0.2, 0.11)
			if muzzle:  # A stubby round beak.
				var beak_y := -0.1 if cover == "eyes" else -0.06
				k.ball(Vector3(0, beak_y - 0.05, 0.41), Vector3(0.09, 0.05, 0.09), Color("e8942a"), 8, 12)
				k.ball(Vector3(0, beak_y, 0.43), Vector3(0.13, 0.08, 0.12), Color("ffb52e"), 10, 14)
		"pig":
			k.ball(Vector3.ZERO, head, fur, 16, 24)
			_animal_features(k, animal, fur, belly, accent, hat, muzzle)
			_eyes(k, 0.1, 0.37, 0.22, 0.125)
			if muzzle:
				k.ball(Vector3(0, -0.08, 0.42), Vector3(0.17, 0.125, 0.1), belly, 10, 14)
				k.outline = 0.0
				for s: float in [-0.055, 0.055]:
					k.ball(Vector3(s, -0.08, 0.515), Vector3(0.028, 0.044, 0.015), Color("6a2038"), 4, 7)
				k.outline = 0.02
				_smile(k, -0.24, 0.4, 0.085)
		"buffalo":
			k.ball(Vector3.ZERO, head, fur, 16, 24)
			_animal_features(k, animal, fur, belly, accent, hat, muzzle)
			_eyes(k, 0.12, 0.37, 0.21, 0.115)
			if muzzle:  # A big soft nose, with room for the ring.
				k.round_patch(Vector3.ZERO, head, 0.0, -0.16, 0.27, 0.2, belly)
				k.outline = 0.0
				for s: float in [-0.095, 0.095]:
					k.round_patch(Vector3.ZERO, head, s, -0.07, 0.032, 0.024, Color("3a2438"), 0.012, 12)
				k.outline = 0.02
				_smile(k, -0.25, 0.42, 0.09)
		_:
			k.ball(Vector3.ZERO, head, fur, 16, 24)
			_animal_features(k, animal, fur, belly, accent, hat, muzzle)
			_eyes(k, 0.08, 0.37, 0.2, 0.125)
			if not muzzle:
				return
			k.round_patch(Vector3.ZERO, head, 0.0, -0.17, 0.17, 0.125, belly)
			k.outline = 0.0
			var nose := Color("ff8fa6") if animal == "cat" else Color("1a1030")
			var nose_size := Vector3(0.052, 0.036, 0.022) if animal == "dog" else Vector3(0.04, 0.028, 0.02)
			k.ball(Vector3(0, -0.105, 0.437), nose_size, nose, 6, 9)
			k.ball(Vector3(-nose_size.x * 0.3, -0.095, 0.452), Vector3(0.012, 0.008, 0.006), Color.WHITE, 3, 5)
			k.outline = 0.02
			_smile(k, -0.15, 0.445, 0.085)
			if animal == "cat":
				_eye_seen["whiskers"] = true


func _animal_features(k: MeshKit, animal: String, fur: Color, belly: Color, _accent: Color, hat: int, muzzle: bool) -> void:
	var head := Vector3(0.5, 0.46, 0.46)
	match animal:
		"dog":
			k.outline = 0.0  # A big patch round one eye.
			k.round_patch(Vector3.ZERO, head, -0.21, 0.06, 0.19, 0.22, fur.darkened(0.25))
			k.outline = 0.02
			k.torus(Vector3(0, -0.38, 0), 0.25, 0.045, _accent, 16, 6)
		"cat":
			if hat == 0:
				for s: float in [-1.0, 1.0]:
					k.push(Transform3D(Basis(Vector3.BACK, s * -0.3), Vector3(s * 0.3, 0.4, -0.02)))
					k.ball(Vector3.ZERO, Vector3(0.135, 0.19, 0.075), fur, 8, 12)
					k.outline = 0.0
					k.ball(Vector3(0, -0.02, 0.05), Vector3(0.08, 0.125, 0.04), Color("ffb3a8"), 6, 10)
					k.outline = 0.02
					k.pop()
			k.outline = 0.0  # Tabby stripes.
			for s: float in [-0.1, 0.0, 0.1]:
				k.round_patch(Vector3.ZERO, head, s, 0.31 - absf(s) * 0.35, 0.024, 0.075, fur.darkened(0.2), 0.006, 12)
			k.outline = 0.02
		"buffalo":
			if hat < 2:  # Horns come down and out from under a hat's brim.
				for s: float in [-1.0, 1.0]:
					var horn_y := 0.08 if hat == 1 else 0.22
					k.push(Transform3D(Basis(Vector3.BACK, s * (-1.25 if hat == 1 else -1.1)), Vector3(s * 0.4, horn_y, 0)))
					k.cone(Vector3.ZERO, 0.4, 0.105, Color("f4ecd2"), 12)
					k.pop()
					k.ball(Vector3(s * 0.5, -0.04, 0), Vector3(0.14, 0.08, 0.1), fur.darkened(0.15), 8, 10)
		"pig":
			if hat == 0:
				for s: float in [-1.0, 1.0]:
					k.push(Transform3D(Basis(Vector3.BACK, s * -0.55), Vector3(s * 0.33, 0.36, 0.03)))
					k.ball(Vector3.ZERO, Vector3(0.11, 0.13, 0.06), fur.darkened(0.06), 8, 12)
					k.pop()
		"monkey":
			if hat < 2:
				for s: float in [-1.0, 1.0]:
					k.ball(Vector3(s * 0.56, 0.02, 0), Vector3(0.16, 0.2, 0.08), belly, 8, 12)
					k.outline = 0.0
					k.ball(Vector3(s * 0.56, 0.02, 0.05), Vector3(0.09, 0.12, 0.04), Color("ffb3a8"), 6, 10)
					k.outline = 0.02
			if hat == 0:  # A few hairs that have never once lain flat.
				for a: float in [-0.35, 0.0, 0.35]:
					k.push(Transform3D(Basis(Vector3.BACK, a), Vector3(a * 0.3, 0.42, 0)))
					k.ball(Vector3(0, 0.08, 0), Vector3(0.04, 0.12, 0.04), fur, 8, 10)
					k.pop()
			if muzzle:
				k.round_patch(Vector3.ZERO, head, 0.0, -0.05, 0.36, 0.33, belly)


func _head_mascot(k: MeshKit, hero: Dictionary, skin: Dictionary, hat: int, cover: String) -> void:
	var main := _main(hero, skin, "main")
	var second := _second(hero, skin, "second")
	var bare := hat == 0  # What stands up off the head comes off under a hat.
	match String(hero["shape"]):
		"coconut":
			k.ball(Vector3.ZERO, Vector3(0.52, 0.5, 0.5), main, 16, 24)
			k.outline = 0.0
			k.ball(Vector3(0, 0.42, 0), Vector3(0.34, 0.1, 0.32), second, 6, 12)
			k.outline = 0.02
			_eyes(k, 0.04, 0.38, 0.2, 0.135)
			if cover == "":
				k.outline = 0.0
				k.round_patch(Vector3.ZERO, Vector3(0.52, 0.5, 0.5), 0.0, -0.22, 0.24, 0.16, second, 0.005, 24)
				k.outline = 0.02
			_smile(k, -0.2, 0.45, 0.115)
		"mango":
			k.ball(Vector3.ZERO, Vector3(0.48, 0.54, 0.44), main, 16, 24)
			k.outline = 0.0
			k.ball(Vector3(0.25, 0.18, 0.1), Vector3(0.28, 0.32, 0.36), second, 6, 12)
			k.outline = 0.02
			_eyes(k, 0.04, 0.36, 0.18, 0.13)
			_smile(k, -0.2, 0.42, 0.11)
		"cup":
			k.cyl(Vector3(0, -0.42, 0), 0.72, 0.36, 0.5, main, 16)
			k.outline = 0.0
			k.torus(Vector3(0, -0.38, 0), 0.37, 0.05, second, 16, 6)
			k.torus(Vector3(0, 0.04, 0), 0.47, 0.055, Color(hero["accent"]), 16, 6)
			k.outline = 0.02
			k.ball(Vector3(0, 0.3, 0), Vector3(0.48, 0.28, 0.48), Color("f6fcff"), 8, 14)
			if bare:
				k.ball(Vector3(0.1, 0.5, 0.06), Vector3(0.14, 0.1, 0.14), second, 6, 10)
				k.ball(Vector3(-0.2, 0.42, 0.14), Vector3(0.09, 0.07, 0.09), Color(hero["accent"]), 6, 10)
			_eyes(k, -0.1, 0.42, 0.18, 0.115)
			_smile(k, -0.25, 0.4, 0.085)
		"robot":
			k.box(Vector3.ZERO, Vector3(0.92, 0.76, 0.76), main, 0.1)
			if cover != "eyes":  # Its screen and eyes would only show round the edge of anything worn over them.
				k.outline = 0.0
				k.box(Vector3(0, 0.06, 0.385), Vector3(0.72, 0.34, 0.02), Color("0a1426"))
				k.outline = 0.02
				# Its eyes are lit up on the screen, so its faces are too.
				_eyes(k, 0.06, 0.392, 0.19, 0.115, Color(hero["accent"]), Color(hero["accent"]))
				_eye_seen["ink"] = Color(hero["accent"])
			for s: float in [-1.0, 1.0]:
				k.cyl(Vector3(s * 0.48, -0.08, 0), 0.2, 0.08, 0.08, second, 8)
			k.outline = 0.0
			for i in 4:
				k.box(Vector3(-0.21 + i * 0.14, -0.22, 0.385), Vector3(0.09, 0.08, 0.02), second)
			k.outline = 0.02
		"ghost":
			k.ball(Vector3(0, -0.02, 0), Vector3(0.5, 0.5, 0.46), main, 16, 24)
			_eyes(k, 0.05, 0.36, 0.18, 0.13, Color("1a1030"), Color("1a1030"))
			_smile(k, -0.17, 0.43, 0.085)
		"alien":
			k.ball(Vector3(0, 0.08, 0), Vector3(0.56, 0.5, 0.48), main, 16, 24)
			_eyes(k, 0.03, 0.34, 0.25, 0.22, Color("0c0626"), Color("0c0626"))
			_smile(k, -0.24, 0.42, 0.075)
			if bare:  # A third eye, for the buffet.
				k.ball(Vector3(0, 0.36, 0.4), Vector3(0.075, 0.08, 0.03), Color.WHITE, 8, 12)
				k.outline = 0.0
				k.ball(Vector3(0, 0.355, 0.43), Vector3(0.04, 0.045, 0.012), Color("0c0626"), 5, 8)
				k.ball(Vector3(-0.012, 0.37, 0.442), Vector3(0.012, 0.012, 0.004), Color.WHITE, 3, 5)
				k.outline = 0.02
		"flame":
			k.ball(Vector3(0, -0.12, 0), Vector3(0.5, 0.42, 0.46), main, 10, 16)
			if not bare:
				k.cone(Vector3(0, 0.05, 0), 0.32, 0.38, main, 12)
			k.outline = 0.0
			k.ball(Vector3(0, -0.12, 0.2), Vector3(0.36, 0.33, 0.28), second, 8, 14)
			k.outline = 0.02
			_eyes(k, -0.03, 0.43, 0.17, 0.12)
			_smile(k, -0.19, 0.48, 0.085)
		"crystal":
			k.cyl(Vector3(0, -0.35, 0), 0.42, 0.25, 0.48, main, 6, false)
			if bare:
				k.cyl(Vector3(0, 0.07, 0), 0.5, 0.48, 0.05, second, 6, false)
			else:
				k.cyl(Vector3(0, 0.07, 0), 0.3, 0.48, 0.2, second, 6, false)
				k.ball(Vector3(0, 0.37, 0), Vector3(0.2, 0.07, 0.2), second, 6, 12)
			_eyes(k, -0.02, 0.33, 0.18, 0.12)
			_smile(k, -0.2, 0.34, 0.08)
			if cover == "":  # A runny nose, frozen solid.
				k.ball(Vector3(0.015, -0.135, 0.355), Vector3(0.02, 0.055, 0.02), Color("e8fbff"), 6, 8)
		_:
			HeroParts.mascot(self, k, hero, main, second, bare, cover)


# --- What flops about ----------------------------------------------------------------------------

## The bits of each character that flop about as it moves. Each row: the part, whether it hangs off the head (or else the
## body), where it hangs from, the way it swings, how far standing and running, how fast standing and running.
func _wiggle_list(hero: Dictionary, hat: int, cover: String, plain: bool, has_back: bool) -> Array:
	var out: Array = []
	var head := cover != "whole" and not plain
	var bare := head and hat == 0
	var some := head and hat < 2
	var muzzle := head and cover not in ["low", "plate"]
	var side := Vector3.BACK
	var nod := Vector3.RIGHT
	var turn := Vector3.UP
	match String(hero["kind"]):
		"kid":
			match String(hero.get("style")):
				"spiky":
					if bare: out.append(["cowlick", true, Vector3(0, 0.5, -0.03), side, 0.1, 0.42, 3.2, 15.0])
				"ponytail":
					if some: out.append(["ponytail", true, Vector3(0, 0.08 if hat > 0 else 0.22, -0.48), nod, 0.07, 0.5, 2.4, 13.0])
				"bowl":
					if bare: out.append(["sprout", true, Vector3(0, 0.49, -0.03), side, 0.12, 0.5, 3.0, 15.0])
				"buns":
					if bare: out.append(["buns", true, Vector3(0, 0.4, -0.06), side, 0.04, 0.2, 2.5, 13.0])
				"mohawk":
					if bare: out.append(["mohawk", true, Vector3(0, 0.42, 0), side, 0.05, 0.34, 2.6, 14.0])
				"long":
					if some: out.append(["long_hair", true, Vector3(0, 0.2, -0.26), nod, 0.03, 0.17, 2.0, 12.0])
		"animal":
			var tail_ok := not has_back
			match String(hero["animal"]):
				"dog":
					if some:
						for part: String in ["ear_l", "ear_r"]:
							out.append([part, true, Vector3(-0.44 if part == "ear_l" else 0.44, 0.2 if hat > 0 else 0.3, -0.02), side, 0.05, 0.55, 2.6, 15.0])
					if tail_ok: out.append(["dog_tail", false, Vector3(0, 0.42, -0.28), turn, 0.55, 0.8, 10.0, 17.0])
				"cat":
					if tail_ok: out.append(["cat_tail", false, Vector3(0, 0.3, -0.28), side, 0.22, 0.5, 2.4, 11.0])
				"buffalo":
					if muzzle: out.append(["ring", true, Vector3(0, -0.085, 0.455), side, 0.12, 0.6, 3.0, 14.0])
					if tail_ok: out.append(["cow_tail", false, Vector3(0, 0.42, -0.3), side, 0.2, 0.6, 2.2, 12.0])
				"tarsier":
					if some:
						for part: String in ["big_ear_l", "big_ear_r"]:
							out.append([part, true, Vector3(-0.3 if part == "big_ear_l" else 0.3, 0.02 if hat > 0 else 0.2, -0.02), side, 0.05, 0.25, 4.0, 14.0])
				"rooster":
					if bare: out.append(["comb", true, Vector3(0, 0.42, 0), side, 0.08, 0.42, 3.0, 15.0])
					if muzzle: out.append(["wattle", true, Vector3(0, -0.13, 0.42), side, 0.1, 0.55, 3.0, 16.0])
					if tail_ok: out.append(["feathers", false, Vector3(0, 0.6, -0.32), nod, 0.05, 0.28, 2.4, 13.0])
				"pig":
					if tail_ok: out.append(["pig_tail", false, Vector3(0, 0.46, -0.33), side, 0.5, 1.2, 9.0, 18.0])
				"monkey":
					if tail_ok: out.append(["monkey_tail", false, Vector3(0, 0.3, -0.28), side, 0.15, 0.4, 2.2, 11.0])
		_:
			match String(hero["shape"]):
				"coconut":
					if bare: out.append(["straw", true, Vector3(0.1, 0.44, 0.02), side, 0.07, 0.34, 3.0, 14.0])
				"mango":
					if bare: out.append(["leaf", true, Vector3(0, 0.5, 0), side, 0.12, 0.42, 3.0, 14.0])
				"cup":
					if bare: out.append(["spoon", true, Vector3(0.26, 0.38, -0.08), side, 0.06, 0.3, 3.0, 14.0])
				"robot":
					if bare: out.append(["antenna", true, Vector3(0, 0.38, 0), side, 0.1, 0.6, 5.0, 18.0])
				"ghost":
					if bare: out.append(["curl", true, Vector3(0, 0.46, 0), side, 0.14, 0.42, 2.6, 12.0])
				"alien":
					if bare:
						for part: String in ["feeler_l", "feeler_r"]:
							out.append([part, true, Vector3(-0.2 if part == "feeler_l" else 0.2, 0.46, 0), side, 0.08, 0.42, 3.4, 15.0])
				"flame":
					if bare: out.append(["flames", true, Vector3(0, 0.05, 0), side, 0.05, 0.12, 8.0, 18.0])
	out.append_array(HeroParts.wiggles(hero, hat, cover, plain, has_back))
	return out


func _build_wiggle(k: MeshKit, part: String, hero: Dictionary, skin: Dictionary) -> void:
	var s := -1.0 if part.ends_with("_l") else 1.0
	match part:
		"cowlick":
			k.tube(PackedVector3Array([Vector3(0, -0.05, 0), Vector3(0, 0.1, 0.02), Vector3(0.04, 0.22, 0), Vector3(0.12, 0.29, -0.03), Vector3(0.21, 0.25, -0.05)]), 0.07, Color(hero["hair"]), false, 10, 0.022)
		"sprout":
			for a: float in [-0.55, 0.0, 0.55]:
				k.push(Transform3D(Basis(Vector3.BACK, a), Vector3.ZERO))
				k.ball(Vector3(0, 0.11, 0), Vector3(0.04, 0.13, 0.04), Color(hero["hair"]), 8, 10)
				k.pop()
		"ponytail":
			k.ball(Vector3.ZERO, Vector3(0.09, 0.09, 0.09), _main(hero, skin, "top"), 8, 10)
			k.ball(Vector3(0, -0.26, -0.12), Vector3(0.15, 0.29, 0.15), Color(hero["hair"]), 10, 14)
		"buns":
			for side: float in [-1.0, 1.0]:
				k.ball(Vector3(side * 0.33, 0.04, 0), Vector3(0.17, 0.17, 0.17), Color(hero["hair"]), 10, 14)
				k.torus(Vector3(side * 0.3, -0.08, 0.01), 0.09, 0.024, _main(hero, skin, "top"), 16, 6)
		"mohawk":
			for i in 5:
				k.ball(Vector3(0, 0.2 - absf(i - 2.0) * 0.05, -0.26 + i * 0.13), Vector3(0.07, 0.17, 0.08), _second(hero, skin, "top"), 8, 10)
		"long_hair":
			k.ball(Vector3(0, -0.35, 0), Vector3(0.48, 0.55, 0.26), Color(hero["hair"]), 12, 16)
		"ear_l", "ear_r":
			k.ball(Vector3(s * 0.07, -0.22, 0), Vector3(0.14, 0.3, 0.17), _main(hero, skin, "fur").darkened(0.25), 8, 12)
		"big_ear_l", "big_ear_r":
			k.ball(Vector3(s * 0.2, 0.08, 0), Vector3(0.28, 0.32, 0.1), _main(hero, skin, "fur").darkened(0.1), 8, 14)
			k.outline = 0.0
			k.ball(Vector3(s * 0.2, 0.08, 0.07), Vector3(0.18, 0.22, 0.05), Color("ffb3a8"), 6, 10)
			k.outline = 0.02
		"dog_tail":
			k.tube(PackedVector3Array([Vector3.ZERO, Vector3(0, 0.13, -0.12), Vector3(0, 0.31, -0.17)]), 0.08, _main(hero, skin, "fur"), false, 8, 0.05)
		"cat_tail":
			var fur := _main(hero, skin, "fur")
			k.tube(PackedVector3Array([Vector3.ZERO, Vector3(0, 0.1, -0.2), Vector3(0.06, 0.35, -0.28), Vector3(0.02, 0.6, -0.24), Vector3(-0.07, 0.72, -0.14)]), 0.07, fur, false, 8, 0.055)
			k.ball(Vector3(-0.07, 0.72, -0.14), Vector3(0.07, 0.07, 0.07), fur.darkened(0.2), 8, 10)
		"cow_tail":
			var fur := _main(hero, skin, "fur")
			k.tube(PackedVector3Array([Vector3.ZERO, Vector3(0, -0.12, -0.1), Vector3(0, -0.3, -0.12)]), 0.035, fur, false, 7, 0.03)
			k.ball(Vector3(0, -0.36, -0.12), Vector3(0.07, 0.1, 0.07), fur.darkened(0.25), 8, 10)
		"monkey_tail":
			k.tube(PackedVector3Array([Vector3.ZERO, Vector3(0, 0, -0.2), Vector3(0, 0.2, -0.38), Vector3(0, 0.45, -0.36), Vector3(0, 0.55, -0.2), Vector3(0, 0.45, -0.1), Vector3(0, 0.35, -0.16)]), 0.05, _main(hero, skin, "fur"), false, 8, 0.035)
		"pig_tail":
			var curl := PackedVector3Array()
			for i in 15:
				var a := i * 0.9
				var r := 0.075 - i * 0.003
				curl.append(Vector3(cos(a) * r, sin(a) * r, -i * 0.012))
			k.tube(curl, 0.028, _main(hero, skin, "fur"), false, 7)
		"ring":
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.05, 0.015)))
			k.torus(Vector3.ZERO, 0.052, 0.015, Color("ffd23f"), 16, 6)
			k.pop()
		"comb":
			var red := Color(hero["accent"])
			for i in 3:
				k.ball(Vector3(0, 0.05 + (1 - absf(i - 1)) * 0.07, -0.12 + i * 0.13), Vector3(0.075, 0.17, 0.09), red, 8, 10)
		"wattle":
			var red := Color(hero["accent"])
			k.ball(Vector3(-0.045, -0.1, 0), Vector3(0.06, 0.11, 0.045), red, 8, 10)
			k.ball(Vector3(0.05, -0.08, 0), Vector3(0.05, 0.09, 0.04), red, 8, 10)
		"feathers":
			for i in 3:
				var angle := -0.45 + i * 0.45
				k.push(Transform3D(Basis(Vector3.BACK, angle), Vector3.ZERO))
				k.ball(Vector3(0, 0.26, -0.05), Vector3(0.1, 0.27, 0.07), Color(hero["accent"]).lerp(Color("3a6aff"), i * 0.5), 8, 12)
				k.pop()
		"straw":
			var accent := Color(hero["accent"])
			k.tube(PackedVector3Array([Vector3(0, -0.04, 0), Vector3(0.02, 0.3, 0), Vector3(0.14, 0.42, 0)]), 0.032, accent, false, 8)
			# A tiny paper umbrella, because it's on holiday.
			k.tube(PackedVector3Array([Vector3(-0.2, -0.02, 0.06), Vector3(-0.27, 0.3, 0.06)]), 0.014, Color("f4ecd2"), false, 6)
			k.dome(Vector3(-0.27, 0.27, 0.06), Vector3(0.2, 0.1, 0.2), Color("ff6fb5"), 6, 16)
		"leaf":
			k.cyl(Vector3.ZERO, 0.14, 0.04, 0.03, Color("7a5230"), 8)
			k.push(Transform3D(Basis(Vector3.BACK, 0.2), Vector3(0, 0.14, 0)))
			k.ball(Vector3(0.18, 0, 0), Vector3(0.21, 0.05, 0.11), Color(hero["accent"]), 8, 12)
			k.pop()
		"spoon":
			var accent := Color(hero["accent"])
			k.tube(PackedVector3Array([Vector3(0, -0.04, 0), Vector3(0.09, 0.4, 0)]), 0.028, accent, false, 8)
			k.ball(Vector3(0.1, 0.48, 0), Vector3(0.09, 0.12, 0.035), accent, 8, 12)
		"antenna":
			var path := PackedVector3Array([Vector3(0, -0.04, 0), Vector3(0, 0.12, 0), Vector3(0, 0.27, 0)])
			k.tube(path, 0.03, Color("0a1426"), false, 7)
			k.ball(Vector3(0, 0.3, 0), Vector3(0.075, 0.075, 0.075), _second(hero, skin, "second"), 8, 10)
		"curl":
			var main := _main(hero, skin, "main")
			var spiral := PackedVector3Array()
			for i in 11:
				var f := i / 10.0
				spiral.append(Vector3(sin(f * 7.0) * 0.07 * f, -0.03 + f * 0.26, cos(f * 7.0) * 0.03 * f))
			k.tube(spiral, 0.06, main, false, 8, 0.016)
		"feeler_l", "feeler_r":
			k.push(Transform3D(Basis(Vector3.BACK, s * -0.4), Vector3.ZERO))
			k.tube(PackedVector3Array([Vector3.ZERO, Vector3(0, 0.15, 0), Vector3(0, 0.3, 0)]), 0.026, _main(hero, skin, "main").darkened(0.2), false, 7)
			k.ball(Vector3(0, 0.34, 0), Vector3(0.075, 0.075, 0.075), Color(hero["accent"]), 8, 10)
			k.pop()
		"flames":
			var main := _main(hero, skin, "main")
			k.tube(PackedVector3Array([Vector3(0, -0.12, -0.02), Vector3(-0.02, 0.1, -0.02), Vector3(0.03, 0.32, -0.03), Vector3(0.12, 0.54, -0.04)]), 0.36, main, false, 16, 0.03)
			k.tube(PackedVector3Array([Vector3(0.3, -0.16, 0.0), Vector3(0.36, 0.02, -0.01), Vector3(0.42, 0.18, -0.02), Vector3(0.52, 0.3, -0.02)]), 0.17, main.lightened(0.14), false, 12, 0.02)
			k.tube(PackedVector3Array([Vector3(-0.3, -0.16, 0.0), Vector3(-0.36, 0.0, -0.01), Vector3(-0.42, 0.12, -0.02), Vector3(-0.5, 0.2, -0.02)]), 0.15, main.lightened(0.14), false, 12, 0.02)
		_:
			HeroParts.wiggle(k, part, hero, skin)


func _tick_wiggles(delta: float) -> void:
	_kick = move_toward(_kick, 0.0, delta * 1.4)
	var amount := clampf(moving, 0.0, 1.0)
	if state in ["dash", "air", "stun"]:
		amount = 1.0
	for w: Dictionary in _wiggles:
		var phase: float = float(w["phase"]) + delta * lerpf(w["slow"], w["fast"], maxf(amount, _kick))
		w["phase"] = phase
		var node: Node3D = w["node"]
		node.rotation = (w["axis"] as Vector3) * sin(phase) * (lerpf(w["amp"], w["run"], amount) + _kick * float(w["run"]))
		if w["flicker"]:
			var lick := sin(phase * 1.7)
			node.scale = Vector3(1.0 - lick * 0.05, 1.0 + lick * 0.14, 1.0)


# --- Each character's own gag ------------------------------------------------------------------------

## Starts this character's own bit of silliness.
func play_gag() -> void:
	var who := Faces.person(_hero_id)
	var gag: String = who.get("gag", "wave")
	var info: Dictionary = Faces.GAGS.get(gag, Faces.GAGS["wave"])
	_gag = gag
	_gag_total = float(info["time"])
	_gag_left = _gag_total
	_gag_wait = randf_range(7.0, 15.0)
	react(String(info["face"]), _gag_total)
	_kick = maxf(_kick, 0.7)
	var lines: Array = who.get("lines", [])
	gag_started.emit(String(lines[randi() % lines.size()]) if not lines.is_empty() else "")


func _tick_gag(delta: float) -> void:
	if _gag != "":
		_gag_left -= delta
		if _gag_left <= 0.0 or state != "idle":
			_gag = ""
		return
	if calm or state != "idle":
		return
	_gag_wait -= delta
	if _gag_wait <= 0.0:
		play_gag()


## What the body does during a gag. Anything left out stays as it was.
func _gag_pose() -> Dictionary:
	var f := 1.0 - _gag_left / maxf(_gag_total, 0.01)
	var swell := sin(f * PI)  # Into it and out of it.
	match _gag:
		"flex":  # Kiko: look at these arms. Look at them.
			var pump := absf(sin(_t * 6.0))
			return {"arm_l": Vector3(-0.3, 0, 1.45 + pump * 0.4), "arm_r": Vector3(-0.3, 0, -1.45 - pump * 0.4), "y": pump * 0.06, "turn": sin(_t * 3.0) * 0.3, "head_tilt": -0.14 * swell}
		"wave":  # Lani: hi! hi! hi!
			return {"arm_r": Vector3(-0.2, 0, -1.8 + sin(_t * 11.0) * 0.45), "arm_l": Vector3(0, 0, 0.25), "head_roll": sin(_t * 4.0) * 0.12, "y": absf(sin(_t * 5.0)) * 0.05}
		"peek":  # Bong: was anyone watching?
			return {"y": -0.05 * swell, "head_turn": sin(f * TAU * 2.0) * 0.75 * swell, "arm_l": Vector3(-1.3, 0, 0.05), "arm_r": Vector3(-1.3, 0, -0.05), "tilt": 0.08 * swell}
		"hop":  # Maya: boing boing boing.
			var hop := absf(sin(f * PI * 3.0))
			return {"y": hop * 0.36, "stretch": 1.0 + hop * 0.12, "arm_l": Vector3(0, 0, 1.4 + hop * 0.5), "arm_r": Vector3(0, 0, -1.4 - hop * 0.5)}
		"shout":  # Rafael: sorry, was that loud?
			var lean := smoothstep(0.0, 0.25, f) * (1.0 - smoothstep(0.8, 1.0, f))
			return {"tilt": -0.2 * lean + sin(_t * 40.0) * 0.02 * lean, "head_tilt": -0.28 * lean, "stretch": 1.0 + 0.1 * lean, "arm_l": Vector3(0, 0, 0.3 + 1.4 * lean), "arm_r": Vector3(0, 0, -0.3 - 1.4 * lean)}
		"stargaze":  # Tala: ooh.
			return {"head_tilt": -0.42 * swell, "head_roll": sin(_t * 1.6) * 0.12, "turn": sin(_t * 1.2) * 0.2, "arm_l": Vector3(0, 0, 0.8), "arm_r": Vector3(0, 0, -0.8)}
		"chase_tail":  # Bantay: nearly had it.
			return {"turn": smoothstep(0.0, 1.0, f) * TAU * 3.0, "tilt": 0.12 * swell, "y": absf(sin(_t * 12.0)) * 0.06, "arm_l": Vector3(-0.7, 0, 0.5), "arm_r": Vector3(0.7, 0, -0.5)}
		"lick":  # Muning: mlem.
			return {"arm_r": Vector3(-2.3 + sin(_t * 14.0) * 0.14, 0, -0.55), "head_tilt": 0.16, "head_roll": -0.14 * swell, "arm_l": Vector3(0, 0, 0.2)}
		"yawn":  # Damulag: is it lunch?
			return {"arm_l": Vector3(0, 0, 0.3 + 1.6 * swell), "arm_r": Vector3(0, 0, -0.3 - 1.6 * swell), "head_tilt": -0.36 * swell, "stretch": 1.0 + 0.1 * swell, "turn": sin(_t * 0.9) * 0.08}
		"owl_turn":  # Tarsi: the head goes all the way round. The eyes stay on you as long as they can.
			return {"head_turn": smoothstep(0.08, 0.92, f) * TAU, "arm_l": Vector3(0, 0, 0.3), "arm_r": Vector3(0, 0, -0.3)}
		"crow":  # Tandang: it's four in the morning.
			var flap := sin(_t * 26.0)
			return {"head_tilt": -0.46 * swell, "stretch": 1.0 + 0.12 * swell, "y": swell * 0.12, "arm_l": Vector3(0, 0, 1.2 + flap * 0.6), "arm_r": Vector3(0, 0, -1.2 - flap * 0.6), "tilt": -0.1 * swell}
		"wiggle":  # Biik: that's the whole dance.
			return {"roll": sin(_t * 16.0) * 0.18 * swell, "turn": sin(_t * 8.0) * 0.25, "y": absf(sin(_t * 8.0)) * 0.06, "arm_l": Vector3(0, 0, 0.9), "arm_r": Vector3(0, 0, -0.9)}
		"scratch":  # Unggoy: itchy.
			return {"arm_r": Vector3(-0.7, 0, -2.15 + sin(_t * 18.0) * 0.16), "arm_l": Vector3(0.5, 0, 0.15), "head_roll": 0.2 * swell, "head_turn": -0.2 * swell, "y": absf(sin(_t * 7.0)) * 0.05}
		"wobble":  # Buko: a coconut doesn't have a lot of balance.
			var rock := sin(_t * 5.0) * 0.42 * swell
			return {"roll": rock, "head_roll": -rock * 0.5, "arm_l": Vector3(0, 0, 1.1 + rock), "arm_r": Vector3(0, 0, -1.1 + rock)}
		"shy_sway":  # Manga: oh, stop it.
			return {"turn": sin(_t * 2.4) * 0.35, "head_roll": sin(_t * 2.4) * 0.16, "head_tilt": 0.14 * swell, "arm_l": Vector3(-1.1, 0, 0.05), "arm_r": Vector3(-1.1, 0, -0.05)}
		"brain_freeze":  # Halo: worth it.
			return {"head_roll": sin(_t * 38.0) * 0.08 * swell, "arm_l": Vector3(-0.8, 0, 2.1), "arm_r": Vector3(-0.8, 0, -2.1), "stretch": 1.0 + sin(_t * 30.0) * 0.03, "y": absf(sin(_t * 19.0)) * 0.03}
		"glitch":  # Botbot: have you tried turning it off and on again?
			var step: float = floor(_t * 9.0)
			return {"head_turn": sin(step * 12.9) * 0.55, "head_roll": sin(step * 4.1) * 0.22, "arm_l": Vector3(sin(step * 7.3) * 1.3, 0, 0.2), "arm_r": Vector3(sin(step * 2.7) * 1.3, 0, -0.2)}
		"boo":  # Multo: BOO! ...sorry.
			var jump := smoothstep(0.0, 0.18, f) * (1.0 - smoothstep(0.7, 1.0, f))
			return {"arm_l": Vector3(-1.0 * jump, 0, 0.4 + 1.2 * jump), "arm_r": Vector3(-1.0 * jump, 0, -0.4 - 1.2 * jump), "tilt": 0.26 * jump, "y": 0.22 * jump, "stretch": 1.0 + 0.16 * jump}
		"hello":  # Kosmo: we come in peace.
			var wave := sin(_t * 10.0) * 0.4
			return {"y": 0.22 * swell, "arm_l": Vector3(0, 0, 1.75 + wave), "arm_r": Vector3(0, 0, -1.75 + wave), "head_roll": sin(_t * 5.0) * 0.1}
		"flare":  # Apoy: totally fine.
			var pulse := absf(sin(_t * 9.0))
			_kick = 1.0
			return {"stretch": 1.0 + pulse * 0.18 * swell, "arm_l": Vector3(0, 0, 1.6), "arm_r": Vector3(0, 0, -1.6), "y": pulse * 0.05}
		"shiver":  # Yelo: who left the door open?
			return {"turn": sin(_t * 44.0) * 0.07, "roll": sin(_t * 51.0) * 0.05, "arm_l": Vector3(-1.2, 0, 0.0), "arm_r": Vector3(-1.2, 0, 0.0), "y": -0.03 * swell}
		"salute":  # Sir Clank: at your service.
			return {"arm_r": Vector3(-0.5, 0, -2.5 * swell), "arm_l": Vector3(0, 0, 0.12), "stretch": 1.0 + 0.08 * swell, "head_tilt": -0.1 * swell}
		"bow":  # Bushi: excuse me. Tag.
			return {"tilt": 0.5 * swell, "head_tilt": 0.22 * swell, "arm_l": Vector3(0.1, 0, 0.1), "arm_r": Vector3(0.1, 0, -0.1), "y": -0.03 * swell}
		"spin":  # Zephyr: wheee.
			return {"turn": smoothstep(0.0, 1.0, f) * TAU * 2.0, "y": 0.26 * swell, "arm_l": Vector3(0, 0, 1.5), "arm_r": Vector3(0, 0, -1.5), "stretch": 1.0 + 0.08 * swell}
		"conduct":  # Merl: and now, the rabbit.
			return {"arm_r": Vector3(-1.2 + sin(_t * 7.0) * 0.5, 0, -1.7 + cos(_t * 7.0) * 0.4), "arm_l": Vector3(-0.7 + cos(_t * 5.0) * 0.3, 0, 1.2), "head_roll": sin(_t * 3.5) * 0.14, "turn": sin(_t * 2.0) * 0.15}
		"sip":  # Earl Grey: one moment, please.
			var lift := smoothstep(0.1, 0.4, f) * (1.0 - smoothstep(0.75, 1.0, f))
			return {"arm_r": Vector3(-2.4 * lift, 0, -0.5 * lift), "arm_l": Vector3(-0.8 * lift, 0, 0.1), "head_tilt": -0.3 * lift}
		"sway":  # Take: in the breeze.
			var lean := sin(_t * 2.1) * 0.2 * swell
			return {"roll": lean, "head_roll": -lean * 0.6, "arm_l": Vector3(0, 0, 1.3 + lean), "arm_r": Vector3(0, 0, -1.3 + lean)}
	return {}


# --- Hats and things on the back ------------------------------------------------------------------

## Every hat is made for one head: its origin is on the line where a brim sits, HAT_R out from the middle, with the
## crown of the head rising HAT_RISE above it. _hat_fit() then fits that to whichever head it's going on.
func _build_hat(k: MeshKit, id: String) -> void:
	k.push(Transform3D(Basis.from_scale(Vector3(1, 1, HAT_DEPTH)), Vector3.ZERO))
	match id:
		"cap":
			var red := Color("ff5a4e")
			k.dome(Vector3.ZERO, Vector3(0.585, 0.39, 0.585), red)
			k.torus(Vector3.ZERO, 0.585, 0.022, red.darkened(0.15), 24, 6)
			k.ball(Vector3(0, 0.39, 0), Vector3(0.055, 0.028, 0.055), red.darkened(0.15), 6, 10)
			k.outline = 0.0
			k.band(Vector3.ZERO, Vector3(0.585, 0.39, 0.585), 0.2, 0.25, Color.WHITE, 0.005)
			k.outline = 0.02
			k.ball(Vector3(0, 0.03, 0.5), Vector3(0.4, 0.05, 0.28), red.darkened(0.15), 8, 18)
		"salakot":
			var straw := Color("e0b868")
			k.dome(Vector3.ZERO, Vector3(0.88, 0.47, 0.88), straw, 12, 32)
			k.torus(Vector3.ZERO, 0.875, 0.026, straw.darkened(0.2), 32, 6)
			k.outline = 0.0
			for y: float in [0.16, 0.32]:
				k.band(Vector3.ZERO, Vector3(0.88, 0.47, 0.88), y, y + 0.024, straw.darkened(0.16), 0.005, 32)
			k.outline = 0.02
			k.ball(Vector3(0, 0.48, 0), Vector3(0.085, 0.06, 0.085), straw.darkened(0.2), 8, 12)
		"party":
			k.cone(Vector3(0, 0.17, 0), 0.74, 0.32, Color("ff6fb5"), 18)
			k.torus(Vector3(0, 0.2, 0), 0.305, 0.03, Color("ffd23f"), 22, 6)
			k.outline = 0.0
			k.torus(Vector3(0, 0.4, 0), 0.215, 0.022, Color("3aa6ff"), 20, 6)
			k.torus(Vector3(0, 0.6, 0), 0.125, 0.018, Color("ffd23f"), 16, 6)
			k.outline = 0.02
			k.ball(Vector3(0, 0.9, 0), Vector3(0.09, 0.09, 0.09), Color("ffd23f"), 8, 12)
		"headphones":
			# The band goes up over the head from ear to ear, the cups sit on the ears.
			var arch := PackedVector3Array()
			for i in 25:
				var a := lerpf(-1.42, 1.42, i / 24.0)
				arch.append(Vector3(sin(a) * 0.64, -0.2 + cos(a) * 0.59, 0.0))
			k.tube(arch, 0.036, Color("0a1426"))
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.62, -0.24, 0), Vector3(0.08, 0.17, 0.18), Color("ff4f8b"), 10, 14)
				k.ball(Vector3(s * 0.695, -0.24, 0), Vector3(0.03, 0.105, 0.11), Color("0a1426"), 8, 12)
		"bow":
			var pink := Color("ff5a9a")
			k.push(Transform3D(Basis(Vector3.UP, 0.5) * Basis(Vector3.RIGHT, -0.5), Vector3(0.25, 0.27, 0.26)))
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * 0.22), Vector3(s * 0.17, 0.0, 0.0)))
				k.ball(Vector3.ZERO, Vector3(0.17, 0.115, 0.06), pink, 8, 12)
				k.pop()
			k.ball(Vector3(0, 0, 0.02), Vector3(0.06, 0.06, 0.06), Color("d43a7a"), 8, 10)
			k.pop()
		"headband":
			var red := Color("ff5a4e")
			k.torus(Vector3(0, 0.05, 0), 0.565, 0.05, red, 32, 8)
			AvatarParts._knot(k, 0.05, -0.61, red)
		"beanie":
			var blue := Color("3aa6ff")
			k.dome(Vector3.ZERO, Vector3(0.59, 0.44, 0.59), blue)
			k.outline = 0.0
			k.band(Vector3.ZERO, Vector3(0.59, 0.44, 0.59), 0.2, 0.26, Color("bfe6ff"), 0.005)
			k.outline = 0.02
			k.torus(Vector3(0, 0.03, 0), 0.585, 0.075, Color.WHITE, 28, 8)
			k.ball(Vector3(0, 0.47, 0), Vector3(0.125, 0.125, 0.125), Color.WHITE, 8, 12)
		"flowers":
			k.torus(Vector3(0, 0.08, 0), 0.545, 0.026, Color("59c04f"), 28, 6)
			var colors := [Color("ff9fd0"), Color("ffffff"), Color("ffb347"), Color("ff7a9a"), Color("c49bff")]
			for i in 8:
				var a := TAU * i / 8.0
				var at := Vector3(cos(a) * 0.56, 0.09, sin(a) * 0.56)
				k.ball(at, Vector3(0.09, 0.055, 0.09), colors[i % 5], 6, 10)
				k.outline = 0.0
				k.ball(at + Vector3(0, 0.045, 0), Vector3(0.032, 0.018, 0.032), Color("ffd23f"), 4, 7)
				k.outline = 0.02
		"cowboy":
			var leather := Color("c98c4a")
			k.ball(Vector3(0, 0.03, 0), Vector3(0.9, 0.06, 0.84), leather, 8, 28)
			for s: float in [-1.0, 1.0]:  # The sides of the brim curl up.
				k.push(Transform3D(Basis(Vector3.BACK, s * 0.55), Vector3(s * 0.76, 0.1, 0)))
				k.ball(Vector3.ZERO, Vector3(0.18, 0.05, 0.54), leather, 8, 14)
				k.pop()
			k.dome(Vector3.ZERO, Vector3(0.6, 0.58, 0.58), leather)
			k.outline = 0.0
			k.ball(Vector3(0, 0.555, 0), Vector3(0.2, 0.03, 0.3), leather.darkened(0.16), 4, 10)
			k.outline = 0.02
			k.torus(Vector3(0, 0.1, 0), 0.59, 0.034, Color("0a1426"), 28, 6)
		"propeller":
			k.dome(Vector3.ZERO, Vector3(0.585, 0.39, 0.585), Color("ff5a4e"))
			k.torus(Vector3.ZERO, 0.585, 0.024, Color("ffd23f"), 24, 6)
			k.outline = 0.0
			k.band(Vector3.ZERO, Vector3(0.585, 0.39, 0.585), 0.12, 0.2, Color("3aa6ff"), 0.005)
			k.outline = 0.02
			k.cyl(Vector3(0, 0.38, 0), 0.13, 0.022, 0.022, Color("6a6a7a"), 8)
			k.ball(Vector3(0, 0.52, 0), Vector3(0.04, 0.03, 0.04), Color("ffd23f"), 6, 8)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.23, 0.52, 0), Vector3(0.22, 0.022, 0.065), Color("ffd23f") if s > 0.0 else Color("3aa6ff"), 6, 10)
		"chef":
			k.cyl(Vector3(0, -0.01, 0), 0.32, 0.585, 0.6, Color.WHITE, 28)
			k.torus(Vector3(0, 0.0, 0), 0.585, 0.024, Color("dfe4f4"), 28, 6)
			for i in 6:
				var a := TAU * i / 6.0
				k.ball(Vector3(cos(a) * 0.34, 0.4, sin(a) * 0.34), Vector3(0.32, 0.2, 0.32), Color.WHITE, 8, 14)
			k.ball(Vector3(0, 0.46, 0), Vector3(0.42, 0.22, 0.42), Color.WHITE, 10, 18)
		"tophat":
			var black := Color("2b2448")
			k.push(Transform3D(Basis(Vector3.BACK, -0.07), Vector3.ZERO))
			k.ball(Vector3(0, 0.27, 0), Vector3(0.64, 0.05, 0.6), black, 8, 26)
			k.cyl(Vector3(0, 0.27, 0), 0.52, 0.36, 0.4, black, 24)
			k.torus(Vector3(0, 0.79, 0), 0.385, 0.025, black, 24, 6)
			k.ball(Vector3(0, 0.79, 0), Vector3(0.385, 0.02, 0.385), black, 6, 20)
			k.torus(Vector3(0, 0.34, 0), 0.375, 0.035, Color("ff3f6a"), 24, 6)
			k.pop()
		"pirate":
			var black := Color("2b2448")
			k.dome(Vector3.ZERO, Vector3(0.59, 0.42, 0.59), black)
			for s: float in [-1.0, 1.0]:  # The brim folded up, front and back, edged in gold.
				k.push(Transform3D(Basis(Vector3.RIGHT, s * 0.28), Vector3(0, 0.2, s * 0.46)))
				k.ball(Vector3.ZERO, Vector3(0.74, 0.25, 0.055), black, 8, 18)
				var trim := PackedVector3Array()
				for i in 17:
					var a := lerpf(0.12, PI - 0.12, i / 16.0)
					trim.append(Vector3(cos(a) * 0.72, sin(a) * 0.24, s * 0.01))
				k.tube(trim, 0.02, Color("ffc21f"), false, 6)
				k.pop()
			k.push(Transform3D(Basis(Vector3.RIGHT, 0.28), Vector3(0, 0.22, 0.525)))
			k.ball(Vector3.ZERO, Vector3(0.085, 0.075, 0.012), Color.WHITE, 6, 10)
			k.outline = 0.0
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.03, 0.012, 0.012), Vector3(0.018, 0.022, 0.004), black, 3, 6)
			k.outline = 0.02
			k.pop()
		"sombrero":
			var straw := Color("ffcf6a")
			k.ball(Vector3(0, 0.03, 0), Vector3(1.02, 0.05, 1.02), straw, 8, 32)
			k.torus(Vector3(0, 0.05, 0), 0.99, 0.05, straw.lightened(0.15), 36, 6)
			k.outline = 0.0
			k.torus(Vector3(0, 0.062, 0), 0.8, 0.02, Color("35d07f"), 32, 5)
			k.torus(Vector3(0, 0.07, 0), 0.72, 0.016, Color("ff3f3f"), 32, 5)
			k.outline = 0.02
			k.dome(Vector3.ZERO, Vector3(0.59, 0.74, 0.59), straw)
			k.torus(Vector3(0, 0.12, 0), 0.578, 0.044, Color("ff3f3f"), 28, 6)
		"viking":
			var steel := Color("b8c0d8")
			k.dome(Vector3.ZERO, Vector3(0.59, 0.44, 0.59), steel)
			k.dome(Vector3.ZERO, Vector3(0.05, 0.455, 0.6), steel.darkened(0.14), 8, 18)
			k.torus(Vector3(0, 0.03, 0), 0.585, 0.05, Color("c98c4a"), 28, 8)
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.95), Vector3(s * 0.46, 0.16, 0)))
				k.cone(Vector3.ZERO, 0.56, 0.125, Color("f4e8c9"), 14)
				k.pop()
		"wizard":
			var purple := Color("5a2bd6")
			k.ball(Vector3(0, 0.02, 0), Vector3(0.86, 0.06, 0.86), purple, 8, 28)
			k.cyl(Vector3.ZERO, 0.62, 0.59, 0.25, purple, 24)
			var bend := PackedVector3Array()
			for i in 9:
				var f := i / 8.0
				bend.append(Vector3(0.26 * f * f, 0.56 + 0.5 * f, 0.0))
			k.tube(bend, 0.265, purple, false, 16, 0.025)
			k.torus(Vector3(0, 0.08, 0), 0.55, 0.028, Color("ffd23f"), 28, 6)
			k.outline = 0.0
			k.ball(Vector3(-0.14, 0.3, 0.42), Vector3(0.05, 0.05, 0.02), Color("ffd23f"), 4, 8)
			k.ball(Vector3(0.2, 0.2, 0.47), Vector3(0.034, 0.034, 0.016), Color("ffd23f"), 4, 7)
			k.ball(Vector3(0.05, 0.46, 0.3), Vector3(0.028, 0.028, 0.014), Color("ffd23f"), 4, 7)
			k.outline = 0.02
		"santa":
			var red := Color("ff3f3f")
			k.dome(Vector3.ZERO, Vector3(0.59, 0.5, 0.59), red)
			# It flops over to one side, from the top of the head down past the brim.
			var flop := PackedVector3Array()
			for i in 11:
				var f := i / 10.0
				flop.append(Vector3(0.62 * f, 0.34 + 0.2 * sin(f * PI * 0.8) - 0.1 * f, -0.04 * f))
			k.tube(flop, 0.27, red, false, 16, 0.06)
			k.ball(flop[10], Vector3(0.11, 0.11, 0.11), Color.WHITE, 8, 12)
			k.torus(Vector3(0, 0.03, 0), 0.585, 0.09, Color.WHITE, 28, 8)
		"halo_ring":
			k.push(Transform3D(Basis(Vector3.RIGHT, 0.14), Vector3(0, 0.66, 0)))
			k.torus(Vector3.ZERO, 0.36, 0.05, Color("fff176"), 28, 8)
			k.pop()
		"horns":
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.42), Vector3(s * 0.3, 0.2, 0.1)))
				k.cone(Vector3.ZERO, 0.38, 0.115, Color("ff3f3f"), 14)
				k.pop()
		"astronaut":
			pass  # A helmet round the whole head, so it has its own fit: see _helmet() below.
		"crown":
			var gold := Color("ffc21f")
			k.dome(Vector3(0, 0.22, 0), Vector3(0.4, 0.22, 0.4), Color("c9202f"), 8, 20)
			k.cyl(Vector3(0, 0.2, 0), 0.22, 0.42, 0.44, gold, 24)
			k.torus(Vector3(0, 0.24, 0), 0.43, 0.024, gold.darkened(0.14), 24, 6)
			for i in 6:
				var a := TAU * i / 6.0 + 0.26
				var at := Vector3(cos(a) * 0.43, 0.38, sin(a) * 0.43)
				k.cone(at, 0.17, 0.085, gold, 10)
				k.ball(at + Vector3(0, 0.175, 0), Vector3(0.044, 0.044, 0.044), [Color("ff3f6a"), Color("3aa6ff")][i % 2], 6, 9)
		"parol_hat":
			# A star-shaped Christmas lantern on a little stalk.
			var star := Vector3(0, 0.72, 0)
			k.tube(PackedVector3Array([Vector3(0, 0.26, 0), star]), 0.022, Color("8a5a34"))
			for i in 5:
				var a := TAU * i / 5.0
				k.push(Transform3D(Basis(Vector3.BACK, a), star))
				k.cone(Vector3.ZERO, 0.3, 0.115, Color("ffd23f") if i % 2 == 0 else Color("ff4f6a"), 12)
				k.pop()
			k.ball(star, Vector3(0.1, 0.1, 0.09), Color("fff8c4"), 8, 12)
		"ufo":
			k.ball(Vector3(0, 0.68, 0), Vector3(0.48, 0.07, 0.48), Color("b8c0d8"), 8, 24)
			k.dome(Vector3(0, 0.72, 0), Vector3(0.2, 0.17, 0.2), Color("6dffb0"), 8, 16)
			k.outline = 0.0
			for i in 6:
				var a := TAU * i / 6.0
				k.ball(Vector3(cos(a) * 0.36, 0.665, sin(a) * 0.36), Vector3(0.04, 0.02, 0.04), Color("ffd23f"), 4, 7)
			k.outline = 0.02
		_:
			WorldWear.hat(k, id)
	k.pop()


## An astronaut's helmet: round the whole head, open at the face, with a thick collar.
func _helmet(k: MeshKit) -> void:
	var white := Color("e8ecf9")
	var r := Vector3(0.61, 0.57, 0.59)
	var cut := -0.7
	k.cap(Vector3.ZERO, r * 0.985, Color("3a4a8a"), 0.98, 0.9, -0.1, 0.0, Color(0, 0, 0, 0), true, cut, true)
	k.cap(Vector3.ZERO, r, white, 0.98, 0.9, -0.1, 0.022, Color("ffb21f"), true, cut)
	k.push(Transform3D(Basis.from_scale(Vector3(r.x, 1.0, r.z)), Vector3(0, cut * r.y, 0)))
	k.torus(Vector3.ZERO, sqrt(1.0 - cut * cut), 0.09, white.darkened(0.1), 28, 8)
	k.pop()
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.6, 0.02, -0.02), Vector3(0.05, 0.13, 0.13), Color("c9d0e6"), 8, 12)
	k.tube(PackedVector3Array([Vector3(0.2, 0.5, -0.05), Vector3(0.24, 0.74, -0.05)]), 0.016, Color("6a6a7a"))
	k.ball(Vector3(0.24, 0.76, -0.05), Vector3(0.036, 0.036, 0.036), Color("ff5a4e"), 6, 9)


## The flag you fly: on a thin pole from the shoulder that isn't holding anything else, flapping in the breeze.
func _add_country_flag(id: String, hero: Dictionary, dressed: bool) -> void:
	_flag_cloth = null
	if id == "" or Cosmetics.item("flag", id).is_empty():
		return
	var mount := Node3D.new()
	mount.position = Vector3(0, 0.56, -_back_depth(hero, dressed))
	mount.scale = Vector3.ONE * 0.82
	_hips.add_child(mount)
	_add_part(mount, _shared("flagpole", _build_flagpole), Vector3.ZERO)
	_flag_cloth = MeshInstance3D.new()
	_flag_cloth.mesh = _flag_mesh()
	_flag_cloth.material_override = _flag_material(id)
	_flag_cloth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flag_cloth.position = Vector3(-0.32, 1.92, -0.52)
	mount.add_child(_flag_cloth)


func _build_flagpole(k: MeshKit) -> void:
	var end := Vector3(-0.3, -0.04, -0.52)
	k.tube(PackedVector3Array([Vector3(0, -0.04, 0.02), Vector3(-0.05, -0.04, -0.14), Vector3(-0.18, -0.04, -0.34), end]), 0.022, Color("6a6a7a"))
	k.cyl(end + Vector3(0, -0.14, 0), 2.16, 0.022, 0.018, Color("fff3d6"), 8)
	k.ball(end + Vector3(0, 2.05, 0), Vector3(0.05, 0.05, 0.05), Color("ffd23f"), 6, 9)


## A sheet of cloth 0.78 wide and 0.55 high, hanging down from its top corner at the pole, cut fine enough to ripple.
static func _flag_mesh() -> ArrayMesh:
	if _flag_sheet != null:
		return _flag_sheet
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var across := 12
	var down := 3
	for x in across:
		for y in down:
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(1, 0)]:
				var u := float(x + corner.x) / across
				var v := float(y + corner.y) / down
				st.set_uv(Vector2(1.0 - u, v))
				st.add_vertex(Vector3(-u * 0.78, -v * 0.55, 0))
	_flag_sheet = st.commit()
	return _flag_sheet


static func _flag_material(id: String) -> ShaderMaterial:
	if not _flag_mats.has(id):
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://gfx/shaders/flag.gdshader")
		mat.set_shader_parameter("picture", Flags.texture(id, true))
		_flag_mats[id] = mat
	return _flag_mats[id]


## Tall things go on a bracket that reaches back past the head, so nothing has to pass through it.
func _bracket(k: MeshKit) -> Vector3:
	var end := Vector3(0.3, -0.04, -0.52)
	k.tube(PackedVector3Array([Vector3(0, -0.04, 0.02), Vector3(0.05, -0.04, -0.14), Vector3(0.18, -0.04, -0.34), end]), 0.024, Color("6a6a7a"))
	return end


func _build_back(k: MeshKit, id: String, team: Color) -> void:
	match id:
		"backpack":
			var orange := Color("ff8a2b")
			k.soft_box(Vector3(0, -0.13, -0.1), Vector3(0.25, 0.27, 0.125), orange, 0.55, 10, 16)
			k.soft_box(Vector3(0, -0.2, -0.215), Vector3(0.17, 0.11, 0.035), Color("ffd23f"), 0.6, 6, 10)
			var handle := PackedVector3Array()
			for i in 7:
				var a := lerpf(0.0, PI, i / 6.0)
				handle.append(Vector3(cos(a) * 0.07, 0.13 + sin(a) * 0.05, -0.08))
			k.tube(handle, 0.016, orange.darkened(0.2))
		"cape_red", "cape_blue":
			var c := Color("ff3f3f") if id == "cape_red" else Color("3a6aff")
			# Hung from the shoulders, under the head, flaring out behind the legs.
			var cloth: Array[PackedVector3Array] = []
			for i in 11:
				var v := i / 10.0
				var row := PackedVector3Array()
				for j in 11:
					var u := lerpf(-1.0, 1.0, j / 10.0)
					var wave := sin(u * 7.0) * 0.022 * v
					row.append(Vector3(u * lerpf(0.26, 0.5, v), lerpf(0.13, -0.68, v) + pow(absf(u), 4.0) * v * 0.06, -0.03 - 0.26 * v - 0.05 * (1.0 - u * u) + wave))
				cloth.append(row)
			k.sheet(cloth, c)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.22, 0.11, 0.0), Vector3(0.055, 0.055, 0.04), Color("ffd23f"), 6, 9)
		"balloon":
			var end := _bracket(k)
			var string_path := PackedVector3Array()
			for i in 9:
				var f := i / 8.0
				string_path.append(end + Vector3(sin(f * 7.0) * 0.015, f * 1.72, 0))
			k.tube(string_path, 0.009, Color("fff8ea"), false, 5)
			var at := end + Vector3(0, 2.02, 0)
			k.ball(at, Vector3(0.28, 0.33, 0.28), Color("ff5a7a"), 12, 18)
			k.cone(at + Vector3(0, -0.36, 0), 0.05, 0.035, Color("ff5a7a"), 8)
			k.outline = 0.0
			k.ball(at + Vector3(-0.1, 0.13, 0.21), Vector3(0.05, 0.08, 0.02), Color("ffc2d0"), 4, 8)
			k.outline = 0.02
		"shell":
			var green := Color("4cbc5e")
			k.ball(Vector3(0, -0.16, -0.06), Vector3(0.39, 0.37, 0.22), green, 12, 18)
			k.outline = 0.0
			k.ball(Vector3(0, -0.16, -0.26), Vector3(0.18, 0.19, 0.03), Color("7ed957"), 6, 12)
			for i in 6:
				var a := TAU * i / 6.0 + PI / 6.0
				k.ball(Vector3(cos(a) * 0.26, -0.16 + sin(a) * 0.25, -0.2), Vector3(0.08, 0.08, 0.03), Color("7ed957"), 4, 8)
			k.outline = 0.02
		"flag":
			var end := _bracket(k)
			k.cyl(end + Vector3(0, -0.14, 0), 2.08, 0.024, 0.024, Color("8a5a34"), 8)
			k.ball(end + Vector3(0, 1.96, 0), Vector3(0.05, 0.05, 0.05), Color("ffd23f"), 6, 9)
			var cloth: Array[PackedVector3Array] = []
			for i in 5:
				var v := i / 4.0
				var row := PackedVector3Array()
				for j in 11:
					var u := j / 10.0
					row.append(end + Vector3(0.02 + u * 0.68, 1.84 - v * 0.44 - sin(u * 2.0) * 0.03, sin(u * 7.0) * 0.05 * u))
				cloth.append(row)
			k.sheet(cloth, team, 0.012)
			var mark := end + Vector3(0.36, 1.6, sin(0.34 * 7.0) * 0.05 * 0.5)
			k.outline = 0.0
			k.ball(mark, Vector3(0.09, 0.09, 0.05), Color.WHITE, 6, 12)
			k.outline = 0.02
		"guitar":
			# Slung low across the back, with the neck sticking out past the side of the body.
			k.push(Transform3D(Basis(Vector3.BACK, 1.12), Vector3(0, -0.14, -0.12)))
			k.ball(Vector3(0, -0.3, 0), Vector3(0.27, 0.31, 0.075), Color("c98c4a"), 10, 16)
			k.soft_box(Vector3(0, 0.3, 0), Vector3(0.042, 0.42, 0.028), Color("7a5230"), 0.7, 6, 10)
			k.soft_box(Vector3(0, 0.76, 0), Vector3(0.07, 0.08, 0.028), Color("5a3a20"), 0.7, 6, 10)
			k.outline = 0.0
			k.ball(Vector3(0, -0.26, -0.07), Vector3(0.095, 0.095, 0.012), Color("3a2315"), 4, 12)
			k.ball(Vector3(0, -0.26, 0.07), Vector3(0.095, 0.095, 0.012), Color("3a2315"), 4, 12)
			k.outline = 0.02
			k.pop()
		"butterfly":
			# Out to the sides and under the head, so the wings show from the front as well.
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.1), Vector3(0, 0, -0.08)))
				k.ball(Vector3(s * 0.54, 0.04, 0), Vector3(0.43, 0.31, 0.022), Color("ff9fd0"), 8, 18)
				k.ball(Vector3(s * 0.38, -0.33, 0), Vector3(0.25, 0.2, 0.022), Color("ffd23f"), 8, 14)
				k.outline = 0.0
				for side: float in [0.024, -0.024]:
					k.ball(Vector3(s * 0.58, 0.05, side), Vector3(0.16, 0.13, 0.006), Color("7f5cff"), 4, 12)
				k.outline = 0.02
				k.pop()
			k.ball(Vector3(0, -0.12, -0.05), Vector3(0.06, 0.26, 0.05), Color("3a2f5a"), 8, 10)
		"jetpack":
			for s: float in [-1.0, 1.0]:
				k.cyl(Vector3(s * 0.17, -0.5, -0.12), 0.46, 0.125, 0.125, Color("c9d0e6"), 14)
				k.cone(Vector3(s * 0.17, -0.04, -0.12), 0.16, 0.125, Color("ff5a4e"), 14)
				k.ball(Vector3(s * 0.17, -0.5, -0.12), Vector3(0.125, 0.05, 0.125), Color("6a6a7a"), 6, 12)
				k.outline = 0.0
				k.ball(Vector3(s * 0.17, -0.6, -0.12), Vector3(0.075, 0.1, 0.075), Color("ffb52e"), 6, 10)
				k.outline = 0.02
			k.soft_box(Vector3(0, -0.24, -0.06), Vector3(0.12, 0.17, 0.06), Color("6a6a7a"), 0.6, 6, 10)
		"angel", "bat", "dragon":
			var c: Color = {"angel": Color("ffffff"), "bat": Color("3a2f5a"), "dragon": Color("d43a2a")}[id]
			var tip: Color = {"angel": Color("e8f4ff"), "bat": Color("5a4a8a"), "dragon": Color("ffb52e")}[id]
			var size: float = {"angel": 1.0, "bat": 1.0, "dragon": 1.25}[id]
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.3).scaled(Vector3.ONE * size), Vector3(s * 0.12, -0.03, -0.06)))
				k.ball(Vector3(s * 0.34, 0.08, 0), Vector3(0.36, 0.18, 0.03), c, 8, 14)
				k.ball(Vector3(s * 0.62, 0.26, 0), Vector3(0.3, 0.12, 0.025), tip, 8, 12)
				k.ball(Vector3(s * 0.36, -0.14, 0), Vector3(0.24, 0.12, 0.025), tip, 8, 12)
				k.pop()
		"parol":
			var end := _bracket(k)
			var star := end + Vector3(0, 1.88, 0)
			k.cyl(end + Vector3(0, -0.14, 0), 2.02, 0.022, 0.022, Color("8a5a34"), 8)
			for i in 5:
				k.push(Transform3D(Basis(Vector3.BACK, TAU * i / 5.0), star))
				k.cone(Vector3.ZERO, 0.42, 0.15, [Color("ffd23f"), Color("ff4f6a"), Color("35d07f")][i % 3], 14)
				k.pop()
			k.ball(star, Vector3(0.13, 0.13, 0.12), Color("fff8c4"), 8, 12)
		_:
			WorldWear.back(k, id, _bracket(k) if id in ["banner", "kite", "hot_air"] or id in CultureWear.TALL else Vector3.ZERO)


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
	var head_turn := 0.0
	var head_roll := 0.0
	var roll := 0.0
	var stretch := 1.0
	_tick_gag(delta)
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
		"turning":  # Both hands out, turning a skipping rope.
			y = sin(_t * 2.6) * 0.018
			arm_l = Vector3(sin(_t * TAU) * 0.3, 0, 1.2)
			arm_r = Vector3(sin(_t * TAU) * 0.3, 0, -1.2)
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
			head_roll = sin(_t * 0.7) * 0.04
			if _floaty:
				y += 0.05 + sin(_t * 2.0) * 0.04
			if _gag != "":
				var pose := _gag_pose()
				y += float(pose.get("y", 0.0))
				tilt = pose.get("tilt", tilt)
				turn = pose.get("turn", turn)
				roll = pose.get("roll", roll)
				stretch = pose.get("stretch", stretch)
				head_tilt = pose.get("head_tilt", head_tilt)
				head_turn = pose.get("head_turn", head_turn)
				head_roll = pose.get("head_roll", head_roll)
				arm_l = pose.get("arm_l", arm_l)
				arm_r = pose.get("arm_r", arm_r)
	if state != "run":
		_hover_extra = 0.0
	_hips.position.y = y + _hover_extra
	arm_l.z += _arm_spread
	arm_r.z -= _arm_spread
	# Poses say "outward" with a plus on the left arm and a minus on the right; the hinges run the other way.
	arm_l.z = -arm_l.z
	arm_r.z = -arm_r.z
	_hips.rotation = Vector3(tilt, turn, roll)
	var sq := _squash
	_hips.scale = Vector3(1.0 + sq * 0.5, stretch * (1.0 - sq * 0.6), 1.0 + sq * 0.5)
	if _head:
		_head.rotation = Vector3(head_tilt, head_turn, head_roll)
	if _arm_l:
		_arm_l.rotation = _arm_l.rotation.lerp(arm_l, clampf(delta * 16.0, 0.0, 1.0))
		_arm_r.rotation = _arm_r.rotation.lerp(arm_r, clampf(delta * 16.0, 0.0, 1.0))
	if _foot_l:
		_foot_l.position = Vector3(-FOOT_X, FOOT_Y + foot_l.y, foot_l.z)
		_foot_r.position = Vector3(FOOT_X, FOOT_Y + foot_r.y, foot_r.z)
	if _back and (look.get("back", "") in ["angel", "bat", "dragon", "butterfly"]):
		_back.rotation.y = sin(_t * (9.0 if state == "run" else 3.0)) * 0.12
	_tick_wiggles(delta)
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
	match run_id if run_id != "" else _own_run:
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
		"ninja":
			out["tilt"] = 0.62 * m
			out["arm_l"] = Vector3(1.75, 0, 0.12)
			out["arm_r"] = Vector3(1.75, 0, -0.12)
			out["head"] = -0.48 * m
		"guard":
			var step: float = floor(_t * 5.5)
			var side: float = 1.0 if int(step) % 2 == 0 else -1.0
			out["tilt"] = -0.02
			out["y"] = 0.05 * absf(sin(_t * 17.0))
			out["arm_l"] = Vector3(-side * 1.1, 0, 0.1)
			out["arm_r"] = Vector3(side * 1.1, 0, -0.1)
			out["foot_l"] = Vector3(0, 0.24 if side > 0.0 else 0.0, side * 0.22) * m
			out["foot_r"] = Vector3(0, 0.24 if side < 0.0 else 0.0, -side * 0.22) * m
		"gallop":
			phase = _t * 10.0
			var gait := sin(phase)
			out["y"] = absf(gait) * 0.26 * m
			out["tilt"] = 0.16 + gait * 0.14
			out["arm_l"] = Vector3(-0.9, 0, 0.5)
			out["arm_r"] = Vector3(-0.9, 0, -0.5)
			out["foot_l"] = Vector3(0, maxf(gait, 0.0) * 0.2, gait * 0.22) * m
			out["foot_r"] = Vector3(0, maxf(sin(phase - 0.8), 0.0) * 0.2, sin(phase - 0.8) * 0.22) * m
		"kangaroo":
			phase = _t * 6.5
			var bounce := absf(sin(phase))
			out["y"] = bounce * 0.62 * m
			out["tilt"] = 0.3 - bounce * 0.2
			out["arm_l"] = Vector3(-1.5, 0, 0.1)
			out["arm_r"] = Vector3(-1.5, 0, -0.1)
			out["foot_l"] = Vector3(0, bounce * 0.42, -bounce * 0.1) * m
			out["foot_r"] = Vector3(0, bounce * 0.42, -bounce * 0.1) * m
		"clank":  # Full armour: stiff arms, no bend in the knees.
			out["tilt"] = -0.03
			out["turn"] = swing * 0.1 * m
			out["y"] = absf(swing) * 0.04 * m
			out["arm_l"] = Vector3(swing * 0.3 * m, 0, 0.5)
			out["arm_r"] = Vector3(-swing * 0.3 * m, 0, -0.5)
			out["foot_l"] = Vector3(0, maxf(cos(phase), 0.0) * 0.08, swing * 0.16) * m
			out["foot_r"] = Vector3(0, maxf(-cos(phase), 0.0) * 0.08, -swing * 0.16) * m
		"sneak":  # Low, wide, and very obvious.
			out["tilt"] = 0.3 * m
			out["y"] = -0.1 * m + absf(swing) * 0.02
			out["arm_l"] = Vector3(-1.2, 0, 1.0 + swing * 0.2)
			out["arm_r"] = Vector3(-1.2, 0, -1.0 + swing * 0.2)
			out["head"] = -0.2 * m
		"chicken":  # Bok bok bok.
			phase = _t * 15.0
			swing = sin(phase)
			out["tilt"] = 0.3 * m
			out["head"] = swing * 0.3 * m
			out["arm_l"] = Vector3(0, 0, 1.1 + swing * 0.6)
			out["arm_r"] = Vector3(0, 0, -1.1 - swing * 0.6)
			out["y"] = absf(swing) * 0.06 * m
		"sack":  # Both feet, all day.
			var boing := absf(sin(_t * 8.0))
			out["y"] = boing * 0.34 * m
			out["tilt"] = 0.06 * m
			out["arm_l"] = Vector3(-0.5, 0, 0.1)
			out["arm_r"] = Vector3(-0.5, 0, -0.1)
			out["foot_l"] = Vector3.ZERO
			out["foot_r"] = Vector3.ZERO
		"race_walk":  # Those hips.
			out["tilt"] = 0.05 * m
			out["turn"] = swing * 0.42 * m
			out["y"] = 0.0
			out["arm_l"] = Vector3(swing * 1.1 * m, 0, 0.3)
			out["arm_r"] = Vector3(-swing * 1.1 * m, 0, -0.3)
			out["foot_l"] = Vector3(0, maxf(cos(phase), 0.0) * 0.05, swing * 0.3) * m
			out["foot_r"] = Vector3(0, maxf(-cos(phase), 0.0) * 0.05, -swing * 0.3) * m
		"flying":  # One arm out. Basically flying.
			out["tilt"] = 0.7 * m
			out["head"] = -0.46 * m
			out["arm_r"] = Vector3(-2.7, 0, -0.1)
			out["arm_l"] = Vector3(0.7, 0, 0.3)
			out["foot_l"] = Vector3(0, 0.1, -0.2 + swing * 0.1) * m
			out["foot_r"] = Vector3(0, 0.1, -0.24 - swing * 0.1) * m
		"crab":
			out["turn"] = PI * 0.5 * m
			out["tilt"] = 0.0
			out["y"] = absf(swing) * 0.05 * m
			out["arm_l"] = Vector3(0, 0, 1.7 + swing * 0.3)
			out["arm_r"] = Vector3(0, 0, -1.7 + swing * 0.3)
			out["foot_l"] = Vector3(swing * 0.14, maxf(cos(phase), 0.0) * 0.08, 0) * m
			out["foot_r"] = Vector3(-swing * 0.14, maxf(-cos(phase), 0.0) * 0.08, 0) * m
		"moonwalk":
			phase = _t * 4.5
			var lift := absf(sin(phase))
			out["hover"] = lift * 0.55 * m
			out["y"] = 0.0
			out["tilt"] = 0.05
			out["arm_l"] = Vector3(sin(phase) * 0.5, 0, 0.9)
			out["arm_r"] = Vector3(-sin(phase) * 0.5, 0, -0.9)
			out["foot_l"] = Vector3(0, 0.05, sin(phase) * 0.3) * m
			out["foot_r"] = Vector3(0, 0.05, -sin(phase) * 0.3) * m
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
		"samba":
			var s := sin(_t * 12.0)
			out["y"] = absf(s) * 0.07
			out["turn"] = sin(_t * 3.0) * 0.5
			out["tilt"] = s * 0.06
			out["arm_l"] = Vector3(-0.6, 0, 1.3 + s * 0.4)
			out["arm_r"] = Vector3(-0.6, 0, -1.3 + s * 0.4)
			out["foot_l"] = Vector3(s * 0.12, maxf(s, 0.0) * 0.1, 0)
			out["foot_r"] = Vector3(-s * 0.12, maxf(-s, 0.0) * 0.1, 0)
		"flamenco":
			var stamp := absf(sin(_t * 9.0))
			out["turn"] = sin(_t * 2.2) * 0.9
			out["tilt"] = -0.1
			out["arm_l"] = Vector3(0, 0, 2.7)
			out["arm_r"] = Vector3(-1.1, 0, -0.9 + sin(_t * 4.5) * 0.4)
			out["foot_l"] = Vector3(0, stamp * 0.1, 0)
		"cancan":
			var beat := sin(_t * 6.0)
			out["y"] = absf(beat) * 0.1
			out["arm_l"] = Vector3(0, 0, 1.1)
			out["arm_r"] = Vector3(0, 0, -1.1)
			out["foot_l"] = Vector3(0, maxf(beat, 0.0) * 0.5, maxf(beat, 0.0) * 0.32)
			out["foot_r"] = Vector3(0, maxf(-beat, 0.0) * 0.5, maxf(-beat, 0.0) * 0.32)
		"jig":
			var beat := sin(_t * 12.0)
			out["y"] = absf(beat) * 0.18
			out["tilt"] = 0.0
			out["arm_l"] = Vector3(0, 0, 0.1)
			out["arm_r"] = Vector3(0, 0, -0.1)
			out["foot_l"] = Vector3(beat * 0.16, maxf(beat, 0.0) * 0.26, 0)
			out["foot_r"] = Vector3(-beat * 0.1, 0, 0)
		"squat":
			var beat := sin(_t * 8.0)
			out["y"] = -0.26 + absf(beat) * 0.1
			out["arm_l"] = Vector3(-1.5, 0.0, 0.5)
			out["arm_r"] = Vector3(-1.5, 0.0, -0.5)
			out["foot_l"] = Vector3(0, maxf(beat, 0.0) * 0.28, maxf(beat, 0.0) * 0.4)
			out["foot_r"] = Vector3(0, maxf(-beat, 0.0) * 0.28, maxf(-beat, 0.0) * 0.4)
		"bollywood":
			var beat := sin(_t * 7.0)
			out["y"] = absf(sin(_t * 3.5)) * 0.1
			out["turn"] = sin(_t * 1.75) * 0.8
			out["arm_l"] = Vector3(-0.5, 0, 2.4 + beat * 0.5)
			out["arm_r"] = Vector3(-0.5, 0, -0.9 - beat * 0.5)
			out["foot_l"] = Vector3(beat * 0.12, 0, 0)
			out["foot_r"] = Vector3(beat * 0.12, 0, 0)
		"kpop":
			var loop := fmod(_t, 2.0)
			var point := loop < 1.0
			out["turn"] = 0.5 if point else -0.5
			out["y"] = absf(sin(_t * 9.4)) * 0.07
			out["arm_r"] = Vector3(-1.4, 0, -2.3) if point else Vector3(0, 0, -0.5)
			out["arm_l"] = Vector3(0, 0, 0.5) if point else Vector3(-1.4, 0, 2.3)
		"sirtaki":  # Arms on shoulders, and faster and faster.
			var quick := 3.0 + fmod(_t, 8.0) * 1.2
			var s := sin(_t * quick)
			out["arm_l"] = Vector3(0, 0, 1.55)
			out["arm_r"] = Vector3(0, 0, -1.55)
			out["foot_l"] = Vector3(s * 0.16, maxf(s, 0.0) * 0.14, 0)
			out["foot_r"] = Vector3(s * 0.16, maxf(-s, 0.0) * 0.14, 0)
			out["y"] = absf(s) * 0.05
		"salsa":
			var s := sin(_t * 7.0)
			out["turn"] = s * 0.32
			out["arm_l"] = Vector3(-1.2, 0, 0.5 + s * 0.3)
			out["arm_r"] = Vector3(-1.2, 0, -0.5 + s * 0.3)
			out["foot_l"] = Vector3(0, 0, maxf(s, 0.0) * 0.18)
			out["foot_r"] = Vector3(0, 0, maxf(-s, 0.0) * 0.18)
			out["y"] = absf(s) * 0.03
		"tango":  # Very serious. Stop laughing.
			var step := fmod(_t, 3.0) / 3.0
			out["turn"] = (0.0 if step < 0.5 else PI) + sin(step * TAU * 2.0) * 0.2
			out["tilt"] = -0.2
			out["arm_r"] = Vector3(-0.2, 0, -1.6)
			out["arm_l"] = Vector3(-1.3, 0, 0.4)
			out["foot_l"] = Vector3(0, 0, sin(step * TAU * 2.0) * 0.24)
		"ballet":
			var loop := fmod(_t, 2.4) / 2.4
			out["turn"] = smoothstep(0.0, 1.0, loop) * TAU * 2.0
			out["y"] = 0.14 + sin(loop * PI) * 0.08
			out["arm_l"] = Vector3(-0.3, 0, 2.5)
			out["arm_r"] = Vector3(-0.3, 0, -2.5)
			out["foot_r"] = Vector3(0, 0.2, 0.06)
		"polka":
			var hop := absf(sin(_t * 8.0))
			out["y"] = hop * 0.22
			out["turn"] = sin(_t * 4.0) * 0.5
			out["arm_l"] = Vector3(0, 0, 0.9)
			out["arm_r"] = Vector3(0, 0, -0.9)
			out["foot_l"] = Vector3(0, hop * 0.1, 0.06)
		"charleston":
			var s := sin(_t * 8.0)
			out["arm_l"] = Vector3(s * 1.2, 0, 0.5)
			out["arm_r"] = Vector3(-s * 1.2, 0, -0.5)
			out["foot_l"] = Vector3(0, maxf(s, 0.0) * 0.14, s * 0.26)
			out["foot_r"] = Vector3(0, maxf(-s, 0.0) * 0.14, -s * 0.26)
			out["turn"] = s * 0.2
		"toprock":
			var s := sin(_t * 9.0)
			out["y"] = absf(s) * 0.1
			out["turn"] = sin(_t * 3.0) * 0.5
			out["tilt"] = 0.12
			out["arm_l"] = Vector3(s * 1.0, 0, 1.1)
			out["arm_r"] = Vector3(-s * 1.0, 0, -1.1)
			out["foot_l"] = Vector3(s * 0.16, 0, maxf(s, 0.0) * 0.14)
			out["foot_r"] = Vector3(-s * 0.16, 0, maxf(-s, 0.0) * 0.14)
		"bhangra":
			var s := absf(sin(_t * 7.0))
			out["y"] = s * 0.14
			out["arm_l"] = Vector3(0, 0, 2.3 + s * 0.3)
			out["arm_r"] = Vector3(0, 0, -2.3 - s * 0.3)
			out["foot_l"] = Vector3(0, s * 0.14, 0)
			out["turn"] = sin(_t * 3.5) * 0.2
		"hula":
			var sway := sin(_t * 4.0)
			out["turn"] = sway * 0.26
			out["tilt"] = 0.0
			out["y"] = absf(sway) * 0.03
			out["arm_l"] = Vector3(0, 0, 1.4 + sway * 0.3)
			out["arm_r"] = Vector3(0, 0, -1.4 + sway * 0.3)
			out["foot_l"] = Vector3(sway * 0.08, 0, 0)
			out["foot_r"] = Vector3(sway * 0.08, 0, 0)
		"lion_shake":
			var shake := sin(_t * 22.0)
			out["turn"] = sin(_t * 2.6) * 1.1
			out["y"] = absf(sin(_t * 5.0)) * 0.3
			out["tilt"] = shake * 0.08
			out["arm_l"] = Vector3(-1.9, 0, 0.6 + shake * 0.3)
			out["arm_r"] = Vector3(-1.9, 0, -0.6 - shake * 0.3)
		"gwara":
			var beat := sin(_t * 10.0)
			out["y"] = absf(beat) * 0.14
			out["turn"] = sin(_t * 5.0) * 0.5
			out["arm_l"] = Vector3(beat * 0.8, 0, 0.6)
			out["arm_r"] = Vector3(-beat * 0.8, 0, -0.6)
			out["foot_l"] = Vector3(0, maxf(beat, 0.0) * 0.2, beat * 0.14)
			out["foot_r"] = Vector3(0, maxf(-beat, 0.0) * 0.2, -beat * 0.14)
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
			return _shared("mask|%s|false" % id, AvatarParts.mask.bind(id, false))
		"hat":
			return _shared("hat|" + id, _build_hat_or_helmet.bind(id))
		"back":
			return _shared("back|%s|shop" % id, _build_back.bind(id, Color("ffb21f")))
		"top":
			return _shared("top_preview|" + id, AvatarParts.top_preview.bind(id))
		"pants":
			return _shared("pants|%s|%.2f" % [id, 1.0], AvatarParts.pants.bind(id, 1.0))
		"shoes":
			return _shared("shoes|" + id, AvatarParts.shoe.bind(id))
		"gloves":
			return _shared("gloves|" + id, AvatarParts.glove.bind(id))
		"pet":
			return Pet3D.mesh(id)
	return null
