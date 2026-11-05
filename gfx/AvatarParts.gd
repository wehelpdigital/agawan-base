class_name AvatarParts
extends RefCounted
## What an avatar wears: tops, pants, shoes, gloves and masks, drawn with MeshKit. Each fits any avatar:
## clothes are scaled sideways by `w`, and masks are made for one head and fitted to the others (see Avatar3D).


static func top(k: MeshKit, id: String, w: float) -> void:
	var def := Cosmetics.item("top", id)
	var c := Color(def.get("c", "ffffff"))
	var c2 := Color(def.get("c2", "ffffff"))
	var style: String = def.get("style", "tee")
	var at := Vector3(0, 0.48, 0)
	var r := Vector3(0.33 * w, 0.285, 0.265 * w)
	var hem := -0.245
	k.ball(at, r, c, 12, 18)
	match style:
		"tee":
			k.spot(at, r, 0.0, -0.05, 0.085, c2)
			k.band(at, r, hem, hem + 0.03, c2)
		"tank":
			k.band(at, r, hem, hem + 0.05, c2)
			k.patch(at, r, -0.1, 0.1, -0.12, 0.02, c2)
		"stripes":
			for i in 4:
				k.band(at, r, -0.215 + i * 0.1, -0.175 + i * 0.1, c2)
		"hoodie":
			k.ball(Vector3(0, 0.66, -0.2), Vector3(0.26, 0.16, 0.15), c2, 8, 12)
			k.patch(at, r, -0.15, 0.15, -0.22, -0.07, c2)
		"dots":
			for spot_at: Vector2 in [Vector2(-0.18, -0.1), Vector2(0.17, -0.14), Vector2(0.0, -0.02), Vector2(-0.07, -0.2), Vector2(0.2, 0.0), Vector2(-0.22, 0.04)]:
				k.spot(at, r, spot_at.x, spot_at.y, 0.05, c2)
		"jersey":
			k.band(at, r, hem, hem + 0.03, c2)
			k.patch(at, r, -0.035, 0.035, -0.15, 0.06, c2)
			k.patch(at, r, -0.13, -0.08, -0.15, -0.1, c2)
			k.patch(at, r, 0.08, 0.13, -0.15, -0.1, c2)
		"barong":
			k.patch(at, r, -0.02, 0.02, -0.25, 0.12, c2)
			for i in 4:
				for s: float in [-0.1, 0.1]:
					k.spot(at, r, s, -0.2 + i * 0.09, 0.022, c2)
			k.band(at, r, hem, hem + 0.025, c2)
		"floral":
			for flower: Vector2 in [Vector2(-0.18, -0.14), Vector2(0.18, -0.1), Vector2(-0.04, 0.0), Vector2(0.06, -0.2)]:
				for i in 5:
					var a := TAU * i / 5.0
					k.spot(at, r, flower.x + cos(a) * 0.04, flower.y + sin(a) * 0.04, 0.03, c2)
				k.spot(at, r, flower.x, flower.y, 0.02, Color("ff5a4e"))
		"varsity":
			k.patch(at, r, -0.025, 0.025, -0.28, 0.12, c2)
			k.band(at, r, hem, hem + 0.04, c2)
			k.patch(at, r, -0.2, -0.08, -0.1, 0.04, c2)
		"overalls":
			k.band(at, r, -0.28, -0.05, c2.lerp(c, 1.0))
			k.patch(at, r, -0.16, 0.16, -0.05, 0.1, c)
			k.patch(at, r, -0.09, 0.09, -0.17, -0.09, c.lightened(0.22))
		"gi":
			k.band(at, r, -0.16, -0.1, c2)
			k.patch(at, r, -0.09, -0.05, -0.1, 0.13, c2)
			k.patch(at, r, 0.05, 0.09, -0.1, 0.13, c2)
		"coat":
			k.ball(Vector3(0, 0.27, 0), Vector3(0.36 * w, 0.1, 0.3 * w), c, 8, 14)
			k.patch(at, r, -0.1, 0.1, -0.22, 0.13, Color("fff6dd"))
			for i in 3:
				for s: float in [-0.15, 0.15]:
					k.spot(at, r, s, -0.18 + i * 0.1, 0.024, c2)
		"tux":
			k.patch(at, r, -0.09, 0.09, -0.18, 0.13, c2)
			k.spot(at, r, -0.035, 0.07, 0.035, Color("e8282f"))
			k.spot(at, r, 0.035, 0.07, 0.035, Color("e8282f"))
			for i in 3:
				k.spot(at, r, 0.0, -0.13 + i * 0.07, 0.014, Color("1d1a30"))
		"space":
			k.patch(at, r, -0.16, 0.16, -0.14, 0.03, Color("3a4a8a"))
			k.spot(at, r, -0.07, -0.05, 0.03, c2)
			k.spot(at, r, 0.07, -0.05, 0.03, Color("35d07f"))
			k.band(at, r, hem, hem + 0.04, c2)
		"armor":
			k.patch(at, r, -0.03, 0.03, -0.26, 0.13, c2)
			k.band(at, r, -0.08, -0.05, c2)
		"galaxy":
			k.spot(at, r, 0.0, -0.06, 0.13, c2)
			for star: Vector2 in [Vector2(-0.22, -0.13), Vector2(0.22, -0.05), Vector2(-0.12, 0.06), Vector2(0.13, 0.08), Vector2(0.1, -0.2)]:
				k.spot(at, r, star.x, star.y, 0.018, Color.WHITE)


## The sleeve on each arm, which moves with it. Tank tops have none; armour has a shoulder plate.
static func sleeve(k: MeshKit, id: String) -> void:
	var def := Cosmetics.item("top", id)
	var style: String = def.get("style", "tee")
	var c := Color(def.get("c", "ffffff"))
	var c2 := Color(def.get("c2", "ffffff"))
	match style:
		"tank":
			pass
		"armor":
			k.ball(Vector3(0, -0.01, 0), Vector3(0.14, 0.115, 0.14), c2, 8, 12)
		"varsity", "overalls":
			k.ball(Vector3(0, -0.035, 0), Vector3(0.105, 0.125, 0.105), c2, 8, 12)
		_:
			k.ball(Vector3(0, -0.035, 0), Vector3(0.105, 0.125, 0.105), c, 8, 12)


## A top on its own, with its sleeves in place: the picture on its shop card.
static func top_preview(k: MeshKit, id: String) -> void:
	top(k, id, 1.0)
	for s: float in [-1.0, 1.0]:
		k.push(Transform3D(Basis(Vector3.BACK, s * 0.42), Vector3(s * Avatar3D.ARM_X, Avatar3D.ARM_Y, 0)))
		sleeve(k, id)
		k.pop()


static func pants(k: MeshKit, id: String, w: float) -> void:
	var def := Cosmetics.item("pants", id)
	var c := Color(def.get("c", "2f5fd0"))
	var c2 := Color(def.get("c2", "ffffff"))
	var style: String = def.get("style", "shorts")
	var at := Vector3(0, 0.28, 0)
	var r := Vector3(0.315 * w, 0.165, 0.255 * w)
	k.ball(at, r, c, 12, 18)
	var long: bool = style in ["long", "track", "cargo", "checks", "dots", "armor", "galaxy"]
	if style not in ["tutu", "kilt", "grass"]:
		for s: float in [-1.0, 1.0]:
			if long:
				k.ball(Vector3(s * Avatar3D.FOOT_X, 0.15, 0), Vector3(0.125, 0.1, 0.13), c, 8, 12)
			else:
				k.ball(Vector3(s * Avatar3D.FOOT_X, 0.19, 0), Vector3(0.12, 0.07, 0.125), c, 8, 12)
	match style:
		"shorts":
			k.band(at, r, 0.09, 0.12, c2)
		"long":
			k.band(at, r, 0.09, 0.12, c.darkened(0.25))
			k.patch(at, r, -0.2, -0.08, -0.06, 0.05, c.lightened(0.18))
			k.patch(at, r, 0.08, 0.2, -0.06, 0.05, c.lightened(0.18))
		"track":
			k.band(at, r, 0.09, 0.12, c2)
			k.patch(at, r, -0.22, -0.18, -0.14, 0.09, c2)
			k.patch(at, r, 0.18, 0.22, -0.14, 0.09, c2)
		"cargo":
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.29 * w, 0.24, 0.08), Vector3(0.055, 0.07, 0.075), c2, 6, 9)
		"stripes":
			for i in 3:
				k.band(at, r, -0.1 + i * 0.08, -0.07 + i * 0.08, c2)
		"checks":
			for ix in 4:
				for iy in 2:
					if (ix + iy) % 2 == 0:
						k.patch(at, r, -0.22 + ix * 0.11, -0.12 + ix * 0.11, -0.1 + iy * 0.09, -0.02 + iy * 0.09, c2, false, 0.006, 3)
		"floral", "dots":
			for spot_at: Vector2 in [Vector2(-0.2, 0.02), Vector2(0.18, 0.04), Vector2(0.0, -0.05), Vector2(-0.1, -0.1), Vector2(0.14, -0.09)]:
				k.spot(at, r, spot_at.x, spot_at.y, 0.038, c2)
		"tutu":
			k.torus(Vector3(0, 0.24, 0), 0.34 * w, 0.075, c, 24, 8)
			k.torus(Vector3(0, 0.3, 0), 0.31 * w, 0.06, c2, 24, 8)
		"kilt":
			k.cyl(Vector3(0, 0.17, 0), 0.2, 0.37 * w, 0.29 * w, c, 22)
			k.torus(Vector3(0, 0.17, 0), 0.365 * w, 0.02, c, 22, 6)
			k.outline = 0.0
			for i in 2:
				k.torus(Vector3(0, 0.22 + i * 0.07, 0), (0.36 - i * 0.03 - 0.005) * w, 0.012, c2, 22, 6)
			k.outline = 0.02
		"grass":
			for i in 12:  # Soft round blades, not spikes.
				var a := TAU * i / 12.0
				var d := Vector3(cos(a), 0, sin(a))
				k.push(Transform3D(Basis(Vector3.UP, PI * 0.5 - a) * Basis(Vector3.RIGHT, 0.22), d * 0.285 * w + Vector3(0, 0.26, 0)))
				k.ball(Vector3.ZERO, Vector3(0.082, 0.125, 0.03), c if i % 2 == 0 else c2, 6, 10)
				k.pop()
		"armor":
			k.band(at, r, 0.08, 0.12, c2)
			k.patch(at, r, -0.03, 0.03, -0.14, 0.08, c2)
		"galaxy":
			k.spot(at, r, 0.0, -0.02, 0.09, c2)
			for star: Vector2 in [Vector2(-0.2, 0.03), Vector2(0.15, -0.08), Vector2(0.22, 0.04), Vector2(-0.1, -0.1)]:
				k.spot(at, r, star.x, star.y, 0.016, Color.WHITE)


## Every shoe starts from the same little bean of a foot.
static func shoe(k: MeshKit, id: String) -> void:
	var def := Cosmetics.item("shoes", id)
	var c := Color(def.get("c", "ffffff"))
	var c2 := Color(def.get("c2", "ff5a4e"))
	var at := Vector3(0, 0.0, 0.045)
	var r := Vector3(0.125, 0.09, 0.175)
	match String(def.get("style", "sneaker")):
		"sneaker":
			k.ball(at, r, c, 10, 14)
			k.band(at, r, -0.075, -0.03, c2)
		"slipper":
			k.ball(Vector3(0, -0.065, 0.05), Vector3(0.135, 0.03, 0.19), c, 8, 14)
			k.ball(Vector3(0, -0.02, 0.05), Vector3(0.1, 0.06, 0.15), Color("e0a874"), 8, 12)
			k.torus(Vector3(0, -0.015, 0.09), 0.1, 0.018, c2, 18, 6)
		"hitop":
			k.ball(at, r, c, 10, 14)
			k.ball(Vector3(0, 0.09, -0.02), Vector3(0.1, 0.095, 0.105), c, 8, 12)
			k.band(at, r, -0.075, -0.03, c2)
		"boot":
			k.ball(at, r, c, 10, 14)
			k.cyl(Vector3(0, 0.0, -0.02), 0.24, 0.1, 0.105, c, 14)
			k.torus(Vector3(0, 0.24, -0.02), 0.1, 0.022, c2, 18, 6)
			k.band(at, r, -0.08, -0.05, c2)
		"clown":
			k.ball(Vector3(0, 0.0, 0.14), Vector3(0.17, 0.11, 0.28), c, 10, 14)
			k.ball(Vector3(0, -0.01, -0.06), Vector3(0.11, 0.08, 0.1), c2, 8, 12)
			k.ball(Vector3(0, 0.11, 0.08), Vector3(0.06, 0.05, 0.06), c2, 6, 9)
		"bunny":
			k.ball(at, Vector3(0.14, 0.1, 0.19), c, 10, 14)
			for s: float in [-0.07, 0.07]:
				k.ball(Vector3(s, 0.14, 0.03), Vector3(0.04, 0.12, 0.05), c, 6, 9)
			k.outline = 0.0
			k.ball(Vector3(0, 0.03, 0.225), Vector3(0.025, 0.02, 0.012), c2, 4, 6)
			k.outline = 0.02
		"flipper":
			k.ball(Vector3(0, -0.065, 0.2), Vector3(0.16, 0.028, 0.3), c, 8, 14)
			k.ball(at + Vector3(0, 0, -0.03), Vector3(0.12, 0.085, 0.14), c2, 10, 14)
		"roller":
			k.ball(Vector3(0, 0.035, 0.045), Vector3(0.125, 0.08, 0.17), c, 10, 14)
			for z: float in [-0.07, 0.15]:
				for s: float in [-0.08, 0.08]:
					k.ball(Vector3(s, -0.055, z), Vector3(0.04, 0.04, 0.04), c2, 6, 9)
		"rocket":
			k.ball(at, r, c, 10, 14)
			k.cyl(Vector3(0, 0.0, -0.02), 0.16, 0.098, 0.1, c, 14)
			k.ball(Vector3(0, 0.0, -0.15), Vector3(0.06, 0.06, 0.05), Color("6a6a7a"), 6, 9)
			k.outline = 0.0
			k.ball(Vector3(0, -0.01, -0.21), Vector3(0.05, 0.05, 0.08), c2, 6, 9)
			k.outline = 0.02


static func glove(k: MeshKit, id: String) -> void:
	var def := Cosmetics.item("gloves", id)
	var c := Color(def.get("c", "ffffff"))
	var c2 := Color(def.get("c2", "ffffff"))
	var hand := Vector3(0, -0.27, 0)
	var wrist := Vector3(0, -0.17, 0)
	match String(def.get("style", "band")):
		"band":
			k.torus(wrist, 0.075, 0.034, c, 18, 8)
		"mitten":
			k.ball(hand, Vector3(0.112, 0.15, 0.104), c, 10, 14)
			k.torus(wrist, 0.082, 0.03, c2, 18, 8)
		"boxing":
			k.ball(hand + Vector3(0, -0.02, 0), Vector3(0.175, 0.19, 0.18), c, 12, 16)
			k.torus(wrist, 0.09, 0.038, c2, 18, 8)
		"foam":
			k.ball(hand, Vector3(0.125, 0.14, 0.11), c, 10, 14)
			# The big pointing finger, held up and out in front, clear of the body and the ground.
			k.tube(PackedVector3Array([hand + Vector3(0, -0.02, 0.06), hand + Vector3(0, 0.1, 0.16), hand + Vector3(0, 0.24, 0.24)]), 0.08, c, false, 12, 0.062)
			k.ball(hand + Vector3(0.09, 0.0, 0.04), Vector3(0.04, 0.06, 0.04), c, 6, 9)
		"crab":
			k.ball(hand + Vector3(0, -0.02, 0), Vector3(0.125, 0.11, 0.115), c, 10, 14)
			for bend: float in [0.34, -0.34]:  # Two plump pincers, a little apart.
				k.push(Transform3D(Basis(Vector3.RIGHT, PI + bend), hand + Vector3(0, -0.06, 0)))
				k.ball(Vector3(0, 0.1, 0), Vector3(0.07, 0.11, 0.045), c if bend > 0.0 else c2, 8, 12)
				k.pop()
		"claw":
			k.ball(hand, Vector3(0.115, 0.14, 0.108), c, 10, 14)
			for s: float in [-0.065, 0.0, 0.065]:
				k.ball(hand + Vector3(s, -0.125, 0.045), Vector3(0.03, 0.05, 0.03), c2, 6, 9)
		"robot":
			k.soft_box(hand, Vector3(0.115, 0.13, 0.105), c, 0.6)
			k.torus(wrist, 0.08, 0.026, c2, 18, 8)
		"flame":
			k.ball(hand, Vector3(0.11, 0.14, 0.105), c, 10, 14)
			for i in 5:  # A cuff of little flames round the wrist.
				var a := TAU * i / 5.0
				k.ball(wrist + Vector3(cos(a) * 0.075, 0.015, sin(a) * 0.075), Vector3(0.035, 0.07, 0.035), c2, 6, 9)


## The head every mask is made for. Avatar3D fits them to the other heads.
const HEAD := Vector3(0.5, 0.46, 0.46)
## Just outside that head: the surface a mask lies on, so it hugs the face instead of floating in front of it.
const M := Vector3(0.515, 0.475, 0.475)
## Masks that replace the whole head are this size.
const W := Vector3(0.52, 0.48, 0.48)
const PUMPKIN := Vector3(0.66, 0.58, 0.615)
const TIKI := Vector3(0.5, 0.52, 0.48)
const GIANT := Vector3(0.68, 0.64, 0.62)
## How far below level a kid's eyes are, in radians. Eye masks are centred on it.
const EYE_LAT := -0.065
const DARK := Color("241338")


## How far forward a mask's surface is at this spot.
static func _z(x: float, y: float, s := M) -> float:
	return s.z * sqrt(maxf(1.0 - pow(x / s.x, 2.0) - pow(y / s.y, 2.0), 0.0))


## An oval of paint on the mask, following its curve.
static func _paint(k: MeshKit, x: float, y: float, w: float, h: float, c: Color, s := M, lift := 0.006) -> void:
	k.outline = 0.0
	k.round_patch(Vector3.ZERO, s, x, y, w, h, c, lift, 20)
	k.outline = 0.02


## A pair of eyes turned to face the way the surface does, each with a glint.
static func _eyes_on(k: MeshKit, y: float, gap: float, size: float, c := DARK, s := M, proud := 0.0) -> void:
	k.outline = 0.0
	for side: float in [-1.0, 1.0]:
		var x := side * gap
		var z := _z(x, y, s)
		k.push(Transform3D(Basis(Vector3.UP, atan2(x / (s.x * s.x), z / (s.z * s.z))), Vector3(x, y, z + proud)))
		k.ball(Vector3.ZERO, Vector3(size * 0.74, size, size * 0.26), c, 8, 12)
		k.ball(Vector3(-size * 0.22, size * 0.38, size * 0.2), Vector3(size * 0.22, size * 0.24, size * 0.07), Color.WHITE, 4, 7)
		k.pop()
	k.outline = 0.02


## A stroke of paint along a path, tapering at both ends. Both its edges follow the surface, so it never breaks up.
static func _stroke(k: MeshKit, path: PackedVector2Array, half: float, c: Color, s := M, lift := 0.01) -> void:
	var col := c
	col.a = 0.0
	var count := path.size()
	var upper := PackedVector3Array()
	var lower := PackedVector3Array()
	for i in count:
		var along := (path[mini(i + 1, count - 1)] - path[maxi(i - 1, 0)]).normalized()
		var side := Vector2(-along.y, along.x) * half * (0.2 + 0.8 * sin(PI * float(i) / (count - 1)))
		var a := path[i] + side
		var b := path[i] - side
		upper.append(Vector3(a.x, a.y, _z(a.x, a.y, s) + lift))
		lower.append(Vector3(b.x, b.y, _z(b.x, b.y, s) + lift))
	for i in count - 1:
		k.quad(lower[i], lower[i + 1], upper[i + 1], upper[i], col)


## A curved line on the mask: a smile, or with a negative `curve`, a frown.
static func _smile(k: MeshKit, y: float, width: float, curve: float, half: float, c: Color, s := M, lift := 0.01) -> void:
	var path := PackedVector2Array()
	for i in 17:
		var f := lerpf(-1.0, 1.0, i / 16.0)
		path.append(Vector2(f * width, y - curve * (1.0 - f * f)))
	_stroke(k, path, half, c, s, lift)


## A round-cornered triangle of paint: a jack-o'-lantern's eye.
static func _triangle(k: MeshKit, cx: float, cy: float, size: float, c: Color, s: Vector3) -> void:
	var pts := PackedVector3Array()
	for i in 18:
		var a := TAU * i / 18.0
		var reach := size * (1.0 + 0.24 * cos(3.0 * a))
		var x := cx + sin(a) * reach
		var y := cy + cos(a) * reach
		pts.append(Vector3(x, y, _z(x, y, s) + 0.012))
	pts.reverse()
	k.fan(pts, c)


## The points of a ring round an ellipsoid at height y.
static func _ring(y: float, s: Vector3, count := 40) -> PackedVector3Array:
	var ring := sqrt(maxf(1.0 - pow(y / s.y, 2.0), 0.0))
	var pts := PackedVector3Array()
	for i in count:
		var a := TAU * i / count
		pts.append(Vector3(cos(a) * s.x * ring, y, sin(a) * s.z * ring))
	return pts


## A knot at the back of the head with two tails: bandanas and headbands.
static func _knot(k: MeshKit, y: float, z: float, c: Color) -> void:
	k.ball(Vector3(0, y, z), Vector3(0.06, 0.06, 0.04), c, 8, 12)
	for s: float in [-1.0, 1.0]:
		k.push(Transform3D(Basis(Vector3.BACK, s * 0.3), Vector3(s * 0.07, y - 0.13, z - 0.015)))
		k.ball(Vector3.ZERO, Vector3(0.05, 0.13, 0.022), c, 6, 10)
		k.pop()


## The whole face: from the hairline to under the chin, and round to the ears.
static func _plate(k: MeshKit, c: Color) -> void:
	k.cap(Vector3.ZERO, M, c, 1.16, 1.02, -0.3, 0.02)


## `hatted`: something's going on top, so anything that stands up off the mask (ears, horns, plumes) stays off.
static func mask(k: MeshKit, id: String, hatted := false) -> void:
	match id:
		"shades":
			var black := Color("1d1a30")
			var y := -0.03
			for s: float in [-1.0, 1.0]:
				var x := s * 0.215
				k.push(Transform3D(Basis(Vector3.UP, s * 0.42), Vector3(x, y, _z(x, y) + 0.025)))
				k.soft_box(Vector3.ZERO, Vector3(0.155, 0.115, 0.026), black, 0.6, 8, 12)
				k.outline = 0.0
				k.ball(Vector3(-0.055, 0.04, 0.024), Vector3(0.05, 0.02, 0.006), Color("7ee8ff"), 4, 8)
				k.outline = 0.02
				k.pop()
			var bridge := PackedVector3Array()
			for i in 5:
				var x := lerpf(-0.08, 0.08, i / 4.0)
				bridge.append(Vector3(x, y + 0.02 + 0.02 * (1.0 - pow(x / 0.08, 2.0)), _z(x, y) + 0.02))
			k.tube(bridge, 0.016, black)
			for s: float in [-1.0, 1.0]:  # The arms run back along the head to the ears.
				var arm := PackedVector3Array()
				for i in 7:
					var a := lerpf(0.72, 1.55, i / 6.0)
					arm.append(Vector3(s * M.x * 1.012 * sin(a), y + 0.015, M.z * 1.012 * cos(a)))
				k.tube(arm, 0.015, black)
		"bandana":
			# Up over the nose, down under the chin, round the whole head, and tied at the back.
			var red := Color("e8282f")
			var top := -0.17
			k.band(Vector3.ZERO, M, -0.474, top, red, 0.0, 32, 8)
			k.outline = 0.0
			k.tube(_ring(top, M * 1.004), 0.016, red.darkened(0.14), true)
			k.outline = 0.02
			for spot_at: Vector2 in [Vector2(-0.3, -0.27), Vector2(-0.14, -0.22), Vector2(0.0, -0.3), Vector2(0.14, -0.22), Vector2(0.3, -0.27), Vector2(-0.17, -0.37), Vector2(0.17, -0.37)]:
				k.spot(Vector3.ZERO, M, spot_at.x, spot_at.y, 0.024, Color.WHITE)
			# The point that hangs below the chin.
			var flap: Array[PackedVector3Array] = []
			for i in 9:
				var v := i / 8.0
				var row := PackedVector3Array()
				for j in 9:
					var u := lerpf(-1.0, 1.0, j / 8.0)
					var x := u * lerpf(0.31, 0.012, pow(v, 0.9))
					var y := lerpf(-0.3, -0.62, v)
					var skin_z := _z(x, -0.3) + 0.012
					row.append(Vector3(x, y, lerpf(skin_z, 0.32, smoothstep(0.0, 0.7, v))))
				flap.append(row)
			k.sheet(flap, red, 0.012)
			k.outline = 0.0
			for dot: Vector2i in [Vector2i(1, 2), Vector2i(1, 6), Vector2i(3, 4), Vector2i(5, 4)]:
				k.ball(flap[dot.x][dot.y] + Vector3(0, 0, 0.008), Vector3(0.024, 0.024, 0.006), Color.WHITE, 4, 7)
			k.outline = 0.02
			_knot(k, -0.2, -0.43, red)
		"domino":
			var red := Color("e8282f")
			k.cap(Vector3.ZERO, M, red, 1.02, 0.31, EYE_LAT, 0.016)
			for s: float in [-1.0, 1.0]:
				_paint(k, s * 0.21, -0.03, 0.09, 0.08, Color("fff8ea"), M * 1.0, 0.004)
			_eyes_on(k, -0.03, 0.21, 0.06, DARK, M, 0.006)
		"snorkel":
			var frame := Color("24135f")
			var strap := PackedVector3Array()
			for i in 29:
				var a := lerpf(PI * 0.5 + 0.8, PI * 2.5 - 0.8, i / 28.0)
				strap.append(Vector3(cos(a) * M.x * 1.012, -0.03, sin(a) * M.z * 1.012))
			k.tube(strap, 0.018, frame)
			k.cap(Vector3.ZERO, M * 1.01, frame, 0.86, 0.36, EYE_LAT, 0.024)
			k.cap(Vector3.ZERO, M * 1.022, Color("7ee8ff"), 0.72, 0.27, EYE_LAT)
			_eyes_on(k, -0.03, 0.17, 0.075, DARK, M * 1.022, 0.004)
			# The breathing tube, up the side of the head, from the mouth.
			var pipe := PackedVector3Array()
			var points: Array[Vector3] = [Vector3(0.12, -0.25, 0.42), Vector3(0.3, -0.25, 0.36), Vector3(0.46, -0.17, 0.24), Vector3(0.535, 0.0, 0.14), Vector3(0.565, 0.16, 0.08)]
			if not hatted:
				points.append(Vector3(0.575, 0.36, 0.05))
				points.append(Vector3(0.58, 0.54, 0.04))
			for point in points:
				pipe.append(point)
			k.tube(pipe, 0.032, Color("ffd23f"))
			k.ball(pipe[pipe.size() - 1], Vector3(0.05, 0.05, 0.05), Color("ff5a4e"), 8, 12)
			k.ball(Vector3(0.05, -0.25, 0.43), Vector3(0.1, 0.05, 0.03), Color("ff5a4e"), 6, 10)
		"pixel":
			var skin := M * 1.012
			k.cap(Vector3.ZERO, skin, Color("1d1a30"), 1.0, 0.29, EYE_LAT, 0.02)
			var colors := [Color("27e9ff"), Color("ff2fc0"), Color("6dff8c")]
			k.outline = 0.0
			for i in 6:
				var x := -0.31 + i * 0.105
				k.patch(Vector3.ZERO, skin, x, x + 0.08, -0.09, 0.03, colors[i % 3], false, 0.006, 3)
			k.outline = 0.02
		"ninja":
			var wrap := Color("2b2448")
			k.ball(Vector3.ZERO, W, wrap, 18, 28)
			k.cap(Vector3.ZERO, W * 1.006, Color("e8b07a"), 0.98, 0.3, 0.02, 0.022, wrap)
			_eyes_on(k, 0.01, 0.2, 0.1, DARK, W * 1.006)
			if not hatted:
				var band := Color("e8282f")
				k.tube(_ring(0.26, W * 1.02), 0.038, band, true)
				_knot(k, 0.26, -0.44, band)
		"panda":
			var white := Color("f8f8fb")
			var black := Color("2a2438")
			k.ball(Vector3.ZERO, W, white, 18, 28)
			if not hatted:
				for s: float in [-1.0, 1.0]:
					k.ball(Vector3(s * 0.37, 0.42, -0.02), Vector3(0.15, 0.15, 0.09), black, 8, 12)
			for s: float in [-1.0, 1.0]:
				_paint(k, s * 0.2, 0.03, 0.125, 0.145, black, W)
				_paint(k, s * 0.33, -0.12, 0.08, 0.05, Color("ffc2d0"), W)
			_eyes_on(k, 0.04, 0.2, 0.062, Color("fff8ea"), W, 0.006)
			_eyes_on(k, 0.035, 0.2, 0.038, DARK, W, 0.012)
			_paint(k, 0.0, -0.12, 0.055, 0.04, black, W)
			_smile(k, -0.18, 0.07, 0.035, 0.012, black, W)
		"tiger":
			var fur := Color("ff9d2e")
			var ink := Color("2a2438")
			var cream := Color("fff6dd")
			k.ball(Vector3.ZERO, W, fur, 18, 28)
			if not hatted:
				for s: float in [-1.0, 1.0]:
					k.ball(Vector3(s * 0.37, 0.41, -0.02), Vector3(0.14, 0.14, 0.08), fur, 8, 12)
					k.outline = 0.0
					k.ball(Vector3(s * 0.37, 0.41, 0.045), Vector3(0.08, 0.08, 0.03), cream, 6, 10)
					k.outline = 0.02
			_paint(k, 0.0, 0.31, 0.028, 0.1, ink, W)
			for s: float in [-1.0, 1.0]:
				_paint(k, s * 0.1, 0.29, 0.022, 0.075, ink, W)
				for i in 3:
					_paint(k, s * (0.4 - absf(i - 1.0) * 0.03), 0.15 - i * 0.14, 0.085, 0.022, ink, W)
			_paint(k, 0.0, -0.17, 0.25, 0.19, cream, W)
			_eyes_on(k, 0.08, 0.2, 0.095, DARK, W)
			_paint(k, 0.0, -0.09, 0.055, 0.036, ink, W, 0.012)
			_smile(k, -0.15, 0.09, 0.05, 0.012, ink, W, 0.014)
		"luchador":
			var gold := Color("ffd23f")
			k.ball(Vector3.ZERO, Vector3(0.52, 0.49, 0.5), Color("3a6aff"), 18, 28)
			var s2 := Vector3(0.52, 0.49, 0.5)
			k.outline = 0.0
			k.patch(Vector3.ZERO, s2, -0.05, 0.05, 0.18, 0.47, gold, false, 0.006, 6)
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				_paint(k, s * 0.2, 0.05, 0.145, 0.125, gold, s2)
				_paint(k, s * 0.36, -0.12, 0.09, 0.05, Color("e8282f"), s2)
			_eyes_on(k, 0.05, 0.2, 0.08, DARK, s2, 0.008)
			_paint(k, 0.0, -0.2, 0.17, 0.09, gold, s2)
			_smile(k, -0.2, 0.09, 0.04, 0.022, Color("6a2038"), s2, 0.014)
		"knight":
			var steel := Color("c5d0e6")
			var s2 := Vector3(0.53, 0.5, 0.5)
			k.ball(Vector3.ZERO, s2, steel, 18, 28)
			k.ball(Vector3(0, 0.0, -0.005), Vector3(0.05, 0.515, 0.515), Color("8f97b0"), 12, 22)
			k.cap(Vector3.ZERO, s2 * 1.006, Color("1d1a30"), 1.0, 0.1, 0.12, 0.014, Color("8f97b0"))
			for row in 3:
				for s: float in [-1.0, 1.0]:
					for i in 3:
						k.spot(Vector3.ZERO, s2, s * (0.12 + i * 0.075), -0.14 - row * 0.075, 0.016, Color("3a3a58"))
			if not hatted:
				k.push(Transform3D(Basis(Vector3.RIGHT, -0.35), Vector3(0, 0.62, -0.1)))
				k.ball(Vector3.ZERO, Vector3(0.07, 0.2, 0.26), Color("e8282f"), 8, 12)
				k.pop()
		"robot":
			var plate := Color("9aa8d6")
			k.soft_box(Vector3.ZERO, Vector3(0.5, 0.46, 0.44), plate, 0.55, 12, 20)
			k.soft_box(Vector3(0, 0.07, 0.4), Vector3(0.38, 0.19, 0.05), Color("140a33"), 0.6, 8, 14)
			k.outline = 0.0
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.17, 0.07, 0.448), Vector3(0.095, 0.095, 0.012), Color("27e9ff"), 6, 12)
				k.ball(Vector3(s * 0.17 - 0.03, 0.105, 0.46), Vector3(0.024, 0.024, 0.006), Color.WHITE, 4, 7)
			k.outline = 0.02
			for i in 4:
				k.soft_box(Vector3(-0.18 + i * 0.12, -0.25, 0.42), Vector3(0.042, 0.042, 0.03), Color("ffd23f"), 0.7, 6, 8)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.52, -0.02, 0), Vector3(0.05, 0.1, 0.1), Color("ffd23f"), 8, 12)
			if not hatted:
				k.cyl(Vector3(0, 0.42, 0), 0.2, 0.024, 0.024, Color("6a6a7a"), 8)
				k.ball(Vector3(0, 0.66, 0), Vector3(0.07, 0.07, 0.07), Color("ffd23f"), 8, 10)
		"pumpkin":
			var orange := Color("ff9d2e")
			for i in 5:
				var x := -0.42 + i * 0.21
				var edge := absf(x) / 0.42
				k.ball(Vector3(x, 0, 0), Vector3(0.26, 0.56 - edge * 0.06, 0.6 - edge * 0.14), orange if i % 2 == 0 else orange.lightened(0.07), 14, 20)
			var purple := Color("3a1c5a")
			for s: float in [-1.0, 1.0]:
				_triangle(k, s * 0.23, 0.13, 0.095, purple, PUMPKIN)
			_smile(k, -0.14, 0.34, 0.13, 0.062, purple, PUMPKIN, 0.014)
			if not hatted:
				k.cyl(Vector3(0, 0.5, 0), 0.2, 0.09, 0.06, Color("5e9b43"), 12)
				k.ball(Vector3(0, 0.7, 0), Vector3(0.06, 0.03, 0.06), Color("5e9b43"), 6, 10)
				k.push(Transform3D(Basis(Vector3.BACK, -0.35), Vector3(0.15, 0.59, 0.02)))
				k.ball(Vector3.ZERO, Vector3(0.14, 0.025, 0.07), Color("7fc25c"), 6, 10)
				k.pop()
		"masskara":
			var yellow := Color("ffd23f")
			_plate(k, yellow)
			for s: float in [-1.0, 1.0]:
				_paint(k, s * 0.2, 0.08, 0.14, 0.105, Color("ff3f8f"))
				_paint(k, s * 0.33, -0.12, 0.08, 0.06, Color("ff7a3c"))
				for i in 5:
					var x := s * (0.08 + i * 0.05)
					_paint(k, x, 0.235 - i * 0.008, 0.016, 0.016, Color("3a6aff"))
			_eyes_on(k, 0.08, 0.2, 0.078, DARK, M, 0.008)
			_smile(k, -0.14, 0.27, 0.12, 0.042, Color("c9202f"))
			if not hatted:
				var plumes := [Color("ff3f8f"), Color("35d07f"), Color("3a6aff"), Color("ff7a3c"), Color("b768ff")]
				for i in 5:
					var a := -0.9 + i * 0.45
					k.push(Transform3D(Basis(Vector3.BACK, -a), Vector3(sin(a) * 0.3, 0.3, 0.14)))
					k.ball(Vector3(0, 0.3, 0), Vector3(0.075, 0.28, 0.03), plumes[i], 8, 12)
					k.pop()
		"kitsune":
			var white := Color("fbf7ff")
			var red := Color("e8282f")
			_plate(k, white)
			if not hatted:
				for s: float in [-1.0, 1.0]:
					k.push(Transform3D(Basis(Vector3.BACK, s * -0.28), Vector3(s * 0.3, 0.44, 0.2)))
					k.ball(Vector3.ZERO, Vector3(0.115, 0.24, 0.05), white, 8, 12)
					k.outline = 0.0
					k.ball(Vector3(0, 0.02, 0.04), Vector3(0.06, 0.16, 0.02), red, 6, 10)
					k.outline = 0.02
					k.pop()
			_paint(k, 0.0, 0.2, 0.045, 0.07, red)
			for s: float in [-1.0, 1.0]:
				_paint(k, s * 0.32, -0.08, 0.075, 0.03, red)
				var line := PackedVector2Array()
				for i in 9:
					var f := i / 8.0
					line.append(Vector2(s * lerpf(0.1, 0.31, f), 0.06 + f * 0.05 + 0.035 * sin(f * PI)))
				_stroke(k, line, 0.024, DARK)
			# The snout comes forward, with a little black nose.
			var snout_z := _z(0, -0.06)
			var snout := PackedVector3Array()
			for i in 6:
				var f := i / 5.0
				snout.append(Vector3(0, lerpf(-0.05, -0.15, f), snout_z - 0.09 + 0.26 * f))
			k.tube(snout, 0.135, white, false, 12, 0.05)
			k.outline = 0.0
			k.ball(snout[5] + Vector3(0, 0.012, 0.03), Vector3(0.042, 0.032, 0.026), DARK, 6, 9)
			k.outline = 0.02
		"clown":
			_plate(k, Color("fbf7ff"))
			for s: float in [-1.0, 1.0]:
				_paint(k, s * 0.2, 0.08, 0.09, 0.135, Color("3a6aff"))
				k.ball(Vector3(s * 0.52, 0.12, 0.05), Vector3(0.15, 0.17, 0.18), Color("ff8a2b"), 10, 14)
			_eyes_on(k, 0.08, 0.2, 0.08, DARK, M, 0.008)
			_smile(k, -0.14, 0.27, 0.12, 0.045, Color("e8282f"))
			k.ball(Vector3(0, -0.03, _z(0, -0.03)), Vector3(0.085, 0.085, 0.085), Color("ff3f3f"), 8, 12)
		"oni":
			var red := Color("d43a2a")
			_plate(k, red)
			if not hatted:
				for s: float in [-1.0, 1.0]:
					k.push(Transform3D(Basis(Vector3.BACK, s * -0.28), Vector3(s * 0.26, 0.27, _z(0.26, 0.27) - 0.05)))
					k.cone(Vector3.ZERO, 0.36, 0.1, Color("f4e8c9"), 12)
					k.pop()
			for s: float in [-1.0, 1.0]:
				var brow := PackedVector2Array()
				for i in 7:
					var f := i / 6.0
					brow.append(Vector2(s * lerpf(0.07, 0.34, f), 0.13 + f * 0.1))
				_stroke(k, brow, 0.038, Color("3a0f12"))
			_eyes_on(k, 0.05, 0.2, 0.08, Color("fff176"), M, 0.004)
			_eyes_on(k, 0.045, 0.2, 0.04, DARK, M, 0.01)
			k.ball(Vector3(0, -0.07, _z(0, -0.07)), Vector3(0.075, 0.055, 0.05), Color("a82a20"), 8, 12)
			_paint(k, 0.0, -0.25, 0.24, 0.085, Color("3a0f12"))
			for s: float in [-1.0, 1.0]:
				k.cone(Vector3(s * 0.14, -0.31, _z(0.14, -0.3) + 0.015), 0.12, 0.05, Color("fff3d6"), 10)
		"skull":
			var bone := Color("f4f0e6")
			var hole := Color("241338")
			_plate(k, bone)
			for s: float in [-1.0, 1.0]:
				_paint(k, s * 0.19, 0.04, 0.12, 0.135, hole)
			_paint(k, 0.0, -0.1, 0.042, 0.06, hole)
			k.outline = 0.0
			for i in 5:
				var x := -0.17 + i * 0.07
				k.patch(Vector3.ZERO, M, x, x + 0.05, -0.3, -0.21, hole, false, 0.006, 2)
			k.outline = 0.02
		"plague":
			var cream := Color("e8dcc0")
			_plate(k, cream)
			for s: float in [-1.0, 1.0]:
				_eyes_on(k, 0.11, 0.2, 0.11, Color("7a4a2a"), M, 0.002)
				_eyes_on(k, 0.11, 0.2, 0.07, Color("7ee8ff"), M, 0.01)
			# The long beak, curving down.
			var beak := PackedVector3Array()
			for i in 8:
				var f := i / 7.0
				beak.append(Vector3(0, -0.04 - 0.28 * f * f, _z(0, -0.04) - 0.04 + 0.34 * f))
			k.tube(beak, 0.145, cream.darkened(0.08), false, 12, 0.03)
		"golden":
			var gold := Color("ffc21f")
			_plate(k, gold)
			if not hatted:
				k.push(Transform3D(Basis.IDENTITY, Vector3(0, 0.26, _z(0, 0.26) - 0.1)))
				k.ball(Vector3(0, 0.15, 0), Vector3(0.1, 0.22, 0.06), gold, 8, 12)
				k.pop()
			_paint(k, -0.14, 0.24, 0.09, 0.03, Color("fff0a8"))
			_eyes_on(k, 0.05, 0.19, 0.095, DARK, M, 0.002)
			_smile(k, -0.2, 0.13, 0.04, 0.02, Color("a86a0a"))
		"galaxy":
			var space := Color("2a1a6e")
			_plate(k, space)
			_paint(k, 0.0, -0.03, 0.34, 0.14, Color("7f4dff"))
			_paint(k, 0.0, -0.03, 0.18, 0.07, Color("ff6fb5"), M, 0.012)
			for spot: Vector2 in [Vector2(-0.28, 0.17), Vector2(0.24, 0.2), Vector2(0.3, -0.17), Vector2(-0.2, -0.26), Vector2(0.04, 0.24), Vector2(0.1, -0.3), Vector2(-0.36, -0.08)]:
				_paint(k, spot.x, spot.y, 0.016, 0.016, Color.WHITE)
			_eyes_on(k, 0.09, 0.19, 0.075, Color("27e9ff"), M, 0.014)
		"tiki":
			var wood := Color("a06a3a")
			var dark_wood := Color("3a2315")
			var cream := Color("fff3d6")
			k.ball(Vector3.ZERO, TIKI, wood, 16, 26)
			if not hatted:
				for i in 5:
					var a := -0.8 + i * 0.4
					k.push(Transform3D(Basis(Vector3.BACK, -a * 0.8), Vector3(sin(a) * 0.32, 0.42, 0.05)))
					k.ball(Vector3(0, 0.18, 0), Vector3(0.075, 0.24, 0.035), Color("35d07f") if i % 2 == 0 else Color("ff5a4e"), 8, 12)
					k.pop()
			k.ball(Vector3(0, 0.2, _z(0, 0.2, TIKI) - 0.1), Vector3(0.38, 0.07, 0.13), wood.darkened(0.14), 8, 16)
			for s: float in [-1.0, 1.0]:
				_paint(k, s * 0.2, 0.06, 0.125, 0.1, cream, TIKI)
				_paint(k, s * 0.2, 0.05, 0.075, 0.065, dark_wood, TIKI, 0.012)
				_paint(k, s * 0.35, -0.14, 0.05, 0.1, Color("ff7a3c"), TIKI)
			k.ball(Vector3(0, -0.07, _z(0, -0.07, TIKI)), Vector3(0.075, 0.12, 0.06), wood.lightened(0.14), 8, 12)
			_paint(k, 0.0, -0.3, 0.26, 0.09, dark_wood, TIKI)
			k.outline = 0.0
			for i in 4:
				var x := -0.17 + i * 0.09
				k.patch(Vector3.ZERO, TIKI, x, x + 0.07, -0.34, -0.25, cream, false, 0.012, 2)
			k.outline = 0.02
		"higante":
			k.push(Transform3D(Basis.IDENTITY, Vector3(0, 0.1, 0)))
			var skin := Color("f0b990")
			var hair := Color("3a2230")
			k.ball(Vector3.ZERO, GIANT, skin, 18, 28)
			k.ball(Vector3(0, 0.24, -0.08), Vector3(0.71, 0.46, 0.58), hair, 16, 26)
			for s: float in [-1.0, 1.0]:
				_paint(k, s * 0.26, 0.03, 0.15, 0.165, Color.WHITE, GIANT)
				_paint(k, s * 0.42, -0.2, 0.11, 0.07, Color("ff8a8a"), GIANT)
				var brow := PackedVector2Array()
				for i in 7:
					var f := lerpf(-1.0, 1.0, i / 6.0)
					brow.append(Vector2(s * 0.26 + f * 0.13, 0.235 - f * f * 0.03))
				_stroke(k, brow, 0.026, hair, GIANT)
			_eyes_on(k, 0.02, 0.26, 0.105, DARK, GIANT, 0.008)
			_smile(k, -0.27, 0.27, 0.09, 0.028, Color("a02030"), GIANT)
			k.ball(Vector3(0, -0.1, _z(0, -0.1, GIANT)), Vector3(0.09, 0.08, 0.075), skin.darkened(0.08), 8, 12)
			k.pop()
		"moriones":
			var skin := Color("e8c9a0")
			var gold := Color("c5a02f")
			var beard := Color("3a2230")
			k.ball(Vector3.ZERO, W, skin, 16, 26)
			_smile(k, -0.2, 0.32, 0.17, 0.075, beard, W)
			_smile(k, -0.17, 0.13, 0.03, 0.02, Color("8a3030"), W, 0.012)
			for s: float in [-1.0, 1.0]:
				_paint(k, s * 0.2, 0.0, 0.085, 0.06, Color.WHITE, W)
				var brow := PackedVector2Array()
				for i in 7:
					var f := lerpf(-1.0, 1.0, i / 6.0)
					brow.append(Vector2(s * 0.2 + f * 0.1, 0.095 - s * f * 0.015))
				_stroke(k, brow, 0.02, beard, W)
			_eyes_on(k, 0.0, 0.2, 0.05, DARK, W, 0.01)
			k.ball(Vector3(0, -0.06, _z(0, -0.06, W)), Vector3(0.05, 0.08, 0.05), skin.darkened(0.06), 8, 10)
			k.dome(Vector3(0, 0.13, 0), Vector3(0.575, 0.44, 0.54), gold)
			k.tube(_ring(0.13, Vector3(0.575, 1.0, 0.54)), 0.03, gold.lightened(0.15), true)
			k.cone(Vector3(0, 0.5, 0), 0.26, 0.13, gold, 12)
			for i in 5:
				var a := -0.8 + i * 0.4
				k.push(Transform3D(Basis(Vector3.BACK, -a), Vector3(0, 0.72, 0)))
				k.ball(Vector3(0, 0.22, 0), Vector3(0.065, 0.24, 0.03), Color("e8282f") if i % 2 == 0 else Color("ffd23f"), 8, 12)
				k.pop()
