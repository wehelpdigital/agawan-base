class_name AvatarParts
extends RefCounted
## What an avatar wears: tops, pants, shoes, gloves and masks, drawn with MeshKit. Each fits any avatar:
## clothes are scaled sideways by `w` (see Avatar3D), masks sit over the front of the head.


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
			k.cyl(Vector3(0, 0.12, 0), 0.26, 0.38 * w, 0.33 * w, c, 20)
			k.outline = 0.0
			for i in 3:
				k.torus(Vector3(0, 0.17 + i * 0.07, 0), (0.37 - i * 0.015) * w, 0.012, c2, 20, 6)
			k.outline = 0.02
		"grass":
			for i in 18:
				var a := TAU * i / 18.0
				var d := Vector3(cos(a), 0, sin(a))
				var side := d.cross(Vector3.UP) * 0.08
				k.blade(d * 0.26 * w + Vector3(0, 0.36, 0) + side, d * 0.26 * w + Vector3(0, 0.36, 0) - side, d * 0.36 * w + Vector3(0, 0.1, 0), c if i % 2 == 0 else c2)
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
			k.ball(hand, Vector3(0.12, 0.135, 0.09), c, 10, 14)
			k.cyl(hand + Vector3(0, -0.34, 0.0), 0.26, 0.05, 0.065, c, 14)
			k.ball(hand + Vector3(0, -0.34, 0.0), Vector3(0.05, 0.05, 0.05), c, 6, 9)
		"crab":
			k.ball(hand + Vector3(0, -0.03, 0), Vector3(0.14, 0.12, 0.12), c, 10, 14)
			k.push(Transform3D(Basis(Vector3.RIGHT, PI + 0.42), hand + Vector3(0, -0.08, 0.03)))
			k.cone(Vector3.ZERO, 0.22, 0.085, c2, 12)
			k.pop()
			k.push(Transform3D(Basis(Vector3.RIGHT, PI - 0.42), hand + Vector3(0, -0.08, -0.03)))
			k.cone(Vector3.ZERO, 0.22, 0.085, c, 12)
			k.pop()
		"claw":
			k.ball(hand, Vector3(0.115, 0.14, 0.108), c, 10, 14)
			for s: float in [-0.065, 0.0, 0.065]:
				k.push(Transform3D(Basis(Vector3.RIGHT, PI), hand + Vector3(s, -0.11, 0.05)))
				k.cone(Vector3.ZERO, 0.11, 0.03, c2, 10)
				k.pop()
		"robot":
			k.soft_box(hand, Vector3(0.115, 0.13, 0.105), c, 0.6)
			k.torus(wrist, 0.08, 0.026, c2, 18, 8)
		"flame":
			k.ball(hand, Vector3(0.11, 0.14, 0.105), c, 10, 14)
			k.cone(hand + Vector3(0, 0.0, 0), 0.26, 0.09, c2, 14)


static func _eyes(k: MeshKit, y: float, z: float, gap: float, r: float, color := Color("140a33")) -> void:
	k.outline = 0.0
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * gap, y, z), Vector3(r, r * 1.05, r * 0.3), color, 5, 9)
		k.ball(Vector3(s * gap + r * 0.22, y + r * 0.3, z + r * 0.22), Vector3(r * 0.22, r * 0.22, r * 0.06), Color.WHITE, 2, 5)
	k.outline = 0.02


## The plate of a face mask: a shell over the front of the head. Returns the z of its front.
static func _plate(k: MeshKit, c: Color, rx := 0.47, ry := 0.45, depth := 0.34, z := 0.2) -> float:
	k.ball(Vector3(0, 0, z), Vector3(rx, ry, depth), c, 10, 16)
	return z + depth


static func mask(k: MeshKit, id: String) -> void:
	match id:
		"shades":
			for side: float in [-0.225, 0.225]:
				k.soft_box(Vector3(side, -0.045, 0.455), Vector3(0.14, 0.11, 0.035), Color("1d1a30"), 0.6, 8, 12)
				k.outline = 0.0
				k.round_patch(Vector3(side, -0.045, 0.455), Vector3(0.14, 0.11, 0.035), -0.05, 0.03, 0.04, 0.022, Color("7ee8ff"), 0.003, 12)
				k.outline = 0.02
			k.soft_box(Vector3(0, -0.02, 0.45), Vector3(0.08, 0.02, 0.02), Color("1d1a30"), 0.7, 6, 8)
			for side: float in [-1.0, 1.0]:
				k.soft_box(Vector3(side * 0.37, -0.02, 0.26), Vector3(0.018, 0.022, 0.2), Color("1d1a30"), 0.7, 6, 8)
		"bandana":
			var band_at := Vector3(0, -0.32, 0.14)
			var band_r := Vector3(0.45, 0.2, 0.33)
			k.ball(band_at, band_r, Color("e8282f"), 10, 16)
			for spot_at: Vector2 in [Vector2(-0.18, 0.0), Vector2(0.18, -0.02), Vector2(0.0, -0.08), Vector2(-0.08, 0.1), Vector2(0.1, 0.1)]:
				k.spot(band_at, band_r, spot_at.x, spot_at.y, 0.024, Color.WHITE)
		"domino":
			k.ball(Vector3(0, -0.04, 0.3), Vector3(0.43, 0.15, 0.2), Color("e8282f"), 8, 14)
			_eyes(k, -0.04, 0.49, 0.2, 0.075, Color("fff8ea"))
		"ninja":
			var z := _plate(k, Color("2b2448"))
			k.ball(Vector3(0, 0.2, 0.1), Vector3(0.5, 0.32, 0.42), Color("2b2448"), 8, 14)
			k.outline = 0.0
			k.box(Vector3(0, 0.03, z - 0.04), Vector3(0.56, 0.14, 0.03), Color("e0b080"))
			k.outline = 0.02
			_eyes(k, 0.03, z - 0.02, 0.15, 0.05)
			k.box(Vector3(0, 0.26, 0.42), Vector3(0.74, 0.07, 0.08), Color("e8282f"), 0.01)
		"snorkel":
			k.soft_box(Vector3(0, -0.04, 0.44), Vector3(0.31, 0.14, 0.05), Color("24135f"), 0.6, 8, 12)
			k.outline = 0.0
			k.round_patch(Vector3(0, -0.04, 0.44), Vector3(0.31, 0.14, 0.05), 0.0, 0.0, 0.255, 0.1, Color("7ee8ff"), 0.003)
			k.outline = 0.02
			_eyes(k, -0.04, 0.49, 0.15, 0.05)
			k.cyl(Vector3(0.36, -0.28, 0.28), 0.85, 0.035, 0.035, Color("ffd23f"), 8)
			k.ball(Vector3(0.36, 0.58, 0.28), Vector3(0.05, 0.05, 0.05), Color("ff5a4e"), 6, 8)
		"panda":
			var z := _plate(k, Color("f8f8fb"))
			k.outline = 0.0
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.19, 0.04, z - 0.04), Vector3(0.11, 0.13, 0.03), Color("241e33"), 4, 9)
			k.ball(Vector3(0, -0.13, z - 0.005), Vector3(0.05, 0.035, 0.02), Color("241e33"), 3, 7)
			k.outline = 0.02
			_eyes(k, 0.05, z - 0.02, 0.19, 0.04, Color("fff8ea"))
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.32, 0.38, 0.1), Vector3(0.13, 0.13, 0.08), Color("241e33"), 5, 9)
		"tiger":
			var z := _plate(k, Color("ff9d2e"))
			k.outline = 0.0
			k.ball(Vector3(0, -0.14, z - 0.04), Vector3(0.22, 0.17, 0.05), Color("fff6dd"), 4, 9)
			k.ball(Vector3(0, -0.07, z), Vector3(0.05, 0.035, 0.02), Color("241e33"), 3, 7)
			for s: float in [-1.0, 1.0]:
				for i in 3:
					k.box(Vector3(s * (0.33 - i * 0.02), 0.14 - i * 0.12, z - 0.14), Vector3(0.14, 0.035, 0.03), Color("241e33"))
			k.box(Vector3(0, 0.28, z - 0.08), Vector3(0.05, 0.14, 0.03), Color("241e33"))
			k.outline = 0.02
			_eyes(k, 0.06, z - 0.03, 0.18, 0.065)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.33, 0.37, 0.1), Vector3(0.11, 0.11, 0.06), Color("ff9d2e"), 4, 8)
		"luchador":
			k.ball(Vector3.ZERO, Vector3(0.52, 0.49, 0.5), Color("3a6aff"), 10, 16)
			k.outline = 0.0
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.2, 0.05, 0.42), Vector3(0.13, 0.11, 0.06), Color("ffd23f"), 4, 9)
			k.ball(Vector3(0, -0.2, 0.44), Vector3(0.16, 0.08, 0.04), Color("ffd23f"), 3, 9)
			k.box(Vector3(0, 0.32, 0.3), Vector3(0.08, 0.26, 0.1), Color("ffd23f"))
			k.outline = 0.02
			_eyes(k, 0.05, 0.47, 0.2, 0.065)
			k.outline = 0.0
			k.ball(Vector3(0, -0.2, 0.47), Vector3(0.09, 0.04, 0.02), Color("6a2038"), 2, 7)
			k.outline = 0.02
		"clown":
			var z := _plate(k, Color("fbf7ff"))
			k.outline = 0.0
			k.ball(Vector3(0, -0.18, z - 0.06), Vector3(0.22, 0.07, 0.03), Color("e8282f"), 3, 9)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.19, 0.08, z - 0.05), Vector3(0.09, 0.14, 0.02), Color("3a6aff"), 4, 8)
			k.outline = 0.02
			k.ball(Vector3(0, -0.03, z), Vector3(0.08, 0.08, 0.08), Color("ff3f3f"), 4, 8)
			_eyes(k, 0.08, z - 0.03, 0.19, 0.05)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.46, 0.15, 0.1), Vector3(0.14, 0.17, 0.16), Color("ff8a2b"), 5, 8)
		"tiki":
			k.box(Vector3(0, 0, 0.3), Vector3(0.76, 1.0, 0.3), Color("a06a3a"), 0.08)
			k.outline = 0.0
			for s: float in [-1.0, 1.0]:
				k.box(Vector3(s * 0.2, 0.14, 0.455), Vector3(0.22, 0.1, 0.02), Color("3a2315"))
				k.box(Vector3(s * 0.2, 0.28, 0.455), Vector3(0.28, 0.05, 0.02), Color("3a2315"))
				k.box(Vector3(s * 0.12, -0.08, 0.455), Vector3(0.06, 0.2, 0.02), Color("c98c4a"))
			k.box(Vector3(0, -0.28, 0.455), Vector3(0.5, 0.14, 0.02), Color("3a2315"))
			for i in 4:
				k.box(Vector3(-0.15 + i * 0.1, -0.28, 0.468), Vector3(0.05, 0.1, 0.01), Color("fff3d6"))
			k.outline = 0.02
			for i in 5:
				var a := -0.8 + i * 0.4
				k.cone(Vector3(sin(a) * 0.36, 0.46, 0.25), 0.3, 0.09, Color("35d07f") if i % 2 == 0 else Color("ff5a4e"), 4)
		"kitsune":
			var z := _plate(k, Color("fbf7ff"), 0.46, 0.42)
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.08, z - 0.12)))
			k.cone(Vector3.ZERO, 0.3, 0.14, Color("fbf7ff"), 8)
			k.pop()
			k.outline = 0.0
			k.ball(Vector3(0, -0.08, z + 0.17), Vector3(0.03, 0.03, 0.02), Color("241e33"), 2, 6)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.2, 0.08, z - 0.04), Vector3(0.1, 0.03, 0.02), Color("241e33"), 3, 7)
				k.ball(Vector3(s * 0.3, -0.1, z - 0.1), Vector3(0.09, 0.03, 0.02), Color("e8282f"), 3, 7)
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				k.cone(Vector3(s * 0.3, 0.3, 0.1), 0.34, 0.13, Color("fbf7ff"), 4)
				k.outline = 0.0
				k.cone(Vector3(s * 0.3, 0.32, 0.16), 0.22, 0.06, Color("e8282f"), 4)
				k.outline = 0.02
		"pixel":
			k.soft_box(Vector3(0, -0.04, 0.45), Vector3(0.39, 0.13, 0.06), Color("1d1a30"), 0.55, 8, 12)
			k.outline = 0.0
			var colors := [Color("27e9ff"), Color("ff2fc0"), Color("6dff8c")]
			for i in 6:
				k.box(Vector3(-0.28 + i * 0.112, -0.04, 0.513), Vector3(0.09, 0.15, 0.01), colors[i % 3])
			k.outline = 0.02
		"oni":
			var z := _plate(k, Color("d43a2a"))
			k.outline = 0.0
			k.box(Vector3(0, -0.22, z - 0.05), Vector3(0.46, 0.12, 0.03), Color("3a0f12"))
			for s: float in [-1.0, 1.0]:
				k.box(Vector3(s * 0.2, 0.2, z - 0.09), Vector3(0.2, 0.05, 0.03), Color("3a0f12"))
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.RIGHT, PI), Vector3(s * 0.17, -0.16, z - 0.03)))
				k.cone(Vector3.ZERO, 0.1, 0.05, Color("fff3d6"), 5)
				k.pop()
				k.cone(Vector3(s * 0.26, 0.32, 0.18), 0.34, 0.09, Color("f4e8c9"), 6)
			k.ball(Vector3(0, -0.04, z), Vector3(0.07, 0.05, 0.05), Color("a82a20"), 3, 7)
			_eyes(k, 0.07, z - 0.02, 0.19, 0.07, Color("fff176"))
		"skull":
			var z := _plate(k, Color("f4f0e6"))
			k.outline = 0.0
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.19, 0.05, z - 0.03), Vector3(0.12, 0.13, 0.03), Color("140a33"), 4, 9)
			k.ball(Vector3(0, -0.1, z - 0.015), Vector3(0.045, 0.06, 0.02), Color("140a33"), 3, 6)
			for i in 5:
				k.box(Vector3(-0.14 + i * 0.07, -0.25, z - 0.06), Vector3(0.04, 0.09, 0.03), Color("140a33"))
			k.outline = 0.02
		"plague":
			var z := _plate(k, Color("e8dcc0"), 0.46, 0.44, 0.3, 0.16)
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5 + 0.2), Vector3(0, -0.06, z - 0.12)))
			k.cone(Vector3.ZERO, 0.62, 0.17, Color("e8dcc0"), 8)
			k.pop()
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.2, 0.12, z - 0.04), Vector3(0.1, 0.1, 0.05), Color("7a4a2a"), 4, 8)
			_eyes(k, 0.12, z, 0.2, 0.07, Color("7ee8ff"))
		"knight":
			k.ball(Vector3.ZERO, Vector3(0.53, 0.5, 0.5), Color("c5d0e6"), 10, 16)
			k.outline = 0.0
			k.box(Vector3(0, 0.06, 0.45), Vector3(0.62, 0.05, 0.06), Color("1d1a30"))
			for i in 3:
				k.box(Vector3(0, -0.14 - i * 0.07, 0.45), Vector3(0.36 - i * 0.05, 0.025, 0.05), Color("3a3a58"))
			k.box(Vector3(0, 0.3, 0.38), Vector3(0.05, 0.3, 0.12), Color("8f97b0"))
			k.outline = 0.02
		"robot":
			k.box(Vector3(0, 0, 0.26), Vector3(0.78, 0.74, 0.36), Color("9aa8d6"), 0.08)
			k.outline = 0.0
			k.box(Vector3(0, 0.08, 0.445), Vector3(0.62, 0.26, 0.02), Color("140a33"))
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.16, 0.08, 0.46), Vector3(0.09, 0.09, 0.015), Color("27e9ff"), 3, 8)
			for i in 4:
				k.box(Vector3(-0.18 + i * 0.12, -0.22, 0.445), Vector3(0.08, 0.08, 0.02), Color("ffd23f"))
			k.outline = 0.02
		"pumpkin":
			k.ball(Vector3(0, 0.04, 0), Vector3(0.64, 0.56, 0.6), Color("ff9d2e"), 10, 16)
			k.outline = 0.0
			k.ball(Vector3(0, 0.04, 0), Vector3(0.36, 0.57, 0.61), Color("ffb04d"), 8, 14)
			for s: float in [-1.0, 1.0]:
				k.cone(Vector3(s * 0.22, 0.07, 0.56), 0.16, 0.09, Color("3a1c5a"), 3)
			k.box(Vector3(0, -0.15, 0.58), Vector3(0.48, 0.09, 0.03), Color("3a1c5a"))
			k.box(Vector3(-0.11, -0.11, 0.59), Vector3(0.07, 0.06, 0.02), Color("ffb04d"))
			k.box(Vector3(0.12, -0.19, 0.59), Vector3(0.07, 0.06, 0.02), Color("ffb04d"))
			k.outline = 0.02
			k.cyl(Vector3(0, 0.56, 0), 0.2, 0.09, 0.06, Color("5e9b43"), 6)
		"masskara":
			var z := _plate(k, Color("ffd23f"))
			k.outline = 0.0
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.2, 0.1, z - 0.04), Vector3(0.14, 0.1, 0.03), Color("ff3f8f"), 4, 9)
				k.ball(Vector3(s * 0.3, -0.12, z - 0.1), Vector3(0.09, 0.07, 0.03), Color("ff7a3c"), 3, 8)
				for i in 5:
					k.ball(Vector3(s * (0.1 + i * 0.05), 0.24, z - 0.09 - i * 0.012), Vector3(0.025, 0.025, 0.015), Color("3a6aff"), 2, 5)
			# The huge smile that made the festival famous.
			for i in 13:
				var f := lerpf(-1.0, 1.0, i / 12.0)
				k.ball(Vector3(f * 0.27, -0.14 - 0.1 * (1.0 - f * f), z - 0.05 - absf(f) * 0.08), Vector3(0.042, 0.042, 0.02), Color("c9202f"), 3, 6)
			k.outline = 0.02
			_eyes(k, 0.1, z - 0.02, 0.2, 0.06)
			var plumes := [Color("ff3f8f"), Color("35d07f"), Color("3a6aff"), Color("ff7a3c"), Color("b768ff")]
			for i in 5:
				var a := -0.9 + i * 0.45
				k.push(Transform3D(Basis(Vector3.BACK, -a), Vector3(sin(a) * 0.32, 0.34, 0.1)))
				k.ball(Vector3(0, 0.28, 0), Vector3(0.07, 0.3, 0.03), plumes[i], 4, 7)
				k.pop()
		"higante":
			k.ball(Vector3(0, 0.08, 0.02), Vector3(0.68, 0.64, 0.62), Color("f0b990"), 12, 18)
			k.ball(Vector3(0, 0.34, -0.1), Vector3(0.72, 0.46, 0.58), Color("3a2230"), 10, 16)
			k.outline = 0.0
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.26, 0.12, 0.58), Vector3(0.14, 0.15, 0.04), Color.WHITE, 5, 9)
				k.ball(Vector3(s * 0.26, 0.11, 0.615), Vector3(0.075, 0.09, 0.02), Color("140a33"), 3, 7)
				k.ball(Vector3(s * 0.4, -0.08, 0.5), Vector3(0.12, 0.08, 0.03), Color("ff8a8a"), 3, 7)
				k.box(Vector3(s * 0.26, 0.32, 0.54), Vector3(0.24, 0.05, 0.03), Color("3a2230"))
			for i in 13:
				var f := lerpf(-1.0, 1.0, i / 12.0)
				k.ball(Vector3(f * 0.3, -0.2 - 0.09 * (1.0 - f * f), 0.56 - absf(f) * 0.1), Vector3(0.035, 0.035, 0.02), Color("a02030"), 3, 6)
			k.outline = 0.02
			k.ball(Vector3(0, -0.03, 0.63), Vector3(0.09, 0.08, 0.08), Color("eaa880"), 4, 8)
		"moriones":
			k.ball(Vector3.ZERO, Vector3(0.54, 0.52, 0.5), Color("e8c9a0"), 10, 16)
			k.outline = 0.0
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.19, 0.03, 0.44), Vector3(0.07, 0.05, 0.03), Color.WHITE, 3, 7)
				k.ball(Vector3(s * 0.19, 0.03, 0.465), Vector3(0.035, 0.04, 0.012), Color("241e33"), 2, 6)
				k.box(Vector3(s * 0.19, 0.13, 0.43), Vector3(0.18, 0.04, 0.03), Color("3a2230"))
			k.box(Vector3(0, -0.24, 0.44), Vector3(0.34, 0.2, 0.05), Color("3a2230"))
			k.outline = 0.02
			k.ball(Vector3(0, 0.26, -0.02), Vector3(0.58, 0.32, 0.56), Color("c5a02f"), 8, 14)
			k.cone(Vector3(0, 0.52, -0.02), 0.26, 0.12, Color("c5a02f"), 8)
			for i in 6:
				var a := -1.0 + i * 0.4
				k.push(Transform3D(Basis(Vector3.BACK, -a * 0.8), Vector3(sin(a) * 0.3, 0.72, -0.02)))
				k.ball(Vector3(0, 0.22, 0), Vector3(0.06, 0.25, 0.03), Color("e8282f") if i % 2 == 0 else Color("ffd23f"), 4, 7)
				k.pop()
		"golden":
			var z := _plate(k, Color("ffc21f"))
			k.outline = 0.0
			k.ball(Vector3(-0.14, 0.26, z - 0.06), Vector3(0.1, 0.05, 0.02), Color("fff0a8"), 3, 7)
			k.ball(Vector3(0, -0.2, z - 0.05), Vector3(0.14, 0.04, 0.02), Color("a86a0a"), 3, 8)
			k.outline = 0.02
			_eyes(k, 0.05, z - 0.02, 0.19, 0.075)
			k.cone(Vector3(0, 0.36, 0.2), 0.26, 0.12, Color("ffc21f"), 4)
		"galaxy":
			var z := _plate(k, Color("2a1a6e"))
			k.outline = 0.0
			k.ball(Vector3(0, -0.02, z - 0.03), Vector3(0.34, 0.14, 0.03), Color("7f4dff"), 3, 11)
			k.ball(Vector3(0, -0.02, z - 0.015), Vector3(0.18, 0.07, 0.02), Color("ff6fb5"), 3, 9)
			for spot: Vector2 in [Vector2(-0.28, 0.2), Vector2(0.24, 0.26), Vector2(0.3, -0.16), Vector2(-0.2, -0.26), Vector2(0.04, 0.32), Vector2(0.1, -0.3)]:
				k.ball(Vector3(spot.x, spot.y, z - 0.09), Vector3(0.02, 0.02, 0.012), Color.WHITE, 2, 5)
			k.outline = 0.02
			_eyes(k, 0.1, z - 0.03, 0.19, 0.06, Color("27e9ff"))
