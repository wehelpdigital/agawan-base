class_name AvatarParts
extends RefCounted
## What an avatar wears: tops, pants, shoes, gloves and masks, drawn with MeshKit. Each fits any avatar:
## clothes are scaled sideways by `w` (see Avatar3D), masks sit over the front of the head.


static func top(k: MeshKit, id: String, w: float) -> void:
	var def := Cosmetics.item("top", id)
	var c := Color(def.get("c", "ffffff"))
	var c2 := Color(def.get("c2", "ffffff"))
	var style: String = def.get("style", "tee")
	k.push(Transform3D(Basis.IDENTITY.scaled(Vector3(w, 1.0, w)), Vector3.ZERO))
	var front := 0.275
	k.soft_box(Vector3(0, 0.66, 0), Vector3(0.36, 0.28, 0.27), c)
	if style not in ["tank", "armor"]:
		for s: float in [-1.0, 1.0]:
			k.ball(Vector3(s * 0.36 / w, 0.8, 0), Vector3(0.14, 0.16, 0.14), c, 7, 10)
	match style:
		"tee":
			k.decal_box(Vector3(0, 0.72, front), Vector3(0.3, 0.2, 0.01), c2)
		"tank":
			k.decal_box(Vector3(0, 0.88, front), Vector3(0.34, 0.1, 0.01), c2)
			k.decal_box(Vector3(0, 0.45, front), Vector3(0.68, 0.06, 0.01), c2)
		"stripes":
			for i in 4:
				k.decal_box(Vector3(0, 0.48 + i * 0.13, front), Vector3(0.68, 0.06, 0.01), c2)
				k.decal_box(Vector3(0, 0.48 + i * 0.13, -front), Vector3(0.68, 0.06, 0.01), c2)
		"hoodie":
			k.ball(Vector3(0, 0.9, -0.25), Vector3(0.3, 0.2, 0.17), c2, 6, 10)
			k.decal_box(Vector3(0, 0.53, front), Vector3(0.44, 0.17, 0.01), c2)
			for s: float in [-0.08, 0.08]:
				k.decal_box(Vector3(s, 0.78, front), Vector3(0.025, 0.2, 0.01), Color.WHITE)
		"dots":
			k.outline = 0.0
			for spot: Vector2 in [Vector2(-0.2, 0.55), Vector2(0.18, 0.5), Vector2(0.0, 0.7), Vector2(-0.24, 0.82), Vector2(0.22, 0.8)]:
				k.ball(Vector3(spot.x, spot.y, front - 0.01), Vector3(0.055, 0.055, 0.015), c2, 3, 8)
			k.outline = 0.03
		"jersey":
			k.decal_box(Vector3(0, 0.88, front), Vector3(0.3, 0.09, 0.01), c2)
			k.decal_box(Vector3(0, 0.67, front), Vector3(0.07, 0.3, 0.01), c2)
			k.decal_box(Vector3(-0.32, 0.67, front), Vector3(0.05, 0.5, 0.01), c2)
			k.decal_box(Vector3(0.32, 0.67, front), Vector3(0.05, 0.5, 0.01), c2)
		"barong":
			k.outline = 0.0
			k.box(Vector3(0, 0.67, front), Vector3(0.05, 0.48, 0.01), c2)
			for i in 5:
				for s: float in [-0.11, 0.11]:
					k.ball(Vector3(s, 0.47 + i * 0.1, front), Vector3(0.03, 0.03, 0.012), c2, 2, 6)
			k.box(Vector3(0, 0.9, front), Vector3(0.36, 0.05, 0.01), c2)
			k.outline = 0.03
		"floral":
			k.outline = 0.0
			for spot: Vector2 in [Vector2(-0.2, 0.52), Vector2(0.2, 0.56), Vector2(-0.06, 0.74), Vector2(0.24, 0.82), Vector2(-0.26, 0.84)]:
				for i in 5:
					var a := TAU * i / 5.0
					k.ball(Vector3(spot.x + cos(a) * 0.05, spot.y + sin(a) * 0.05, front), Vector3(0.04, 0.04, 0.012), c2, 2, 6)
				k.ball(Vector3(spot.x, spot.y, front + 0.005), Vector3(0.03, 0.03, 0.012), Color("ff5a4e"), 2, 6)
			k.outline = 0.03
		"varsity":
			k.decal_box(Vector3(0, 0.67, front), Vector3(0.07, 0.52, 0.01), c2)
			k.decal_box(Vector3(0, 0.43, front), Vector3(0.7, 0.06, 0.01), c2)
			k.decal_box(Vector3(-0.2, 0.74, front), Vector3(0.16, 0.2, 0.01), c2)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.36 / w, 0.8, 0), Vector3(0.145, 0.165, 0.145), c2, 7, 10)
		"overalls":
			k.decal_box(Vector3(0, 0.53, front), Vector3(0.7, 0.26, 0.01), c)
			k.decal_box(Vector3(0, 0.77, front), Vector3(0.68, 0.24, 0.01), c2)
			for s: float in [-0.2, 0.2]:
				k.decal_box(Vector3(s, 0.78, front + 0.005), Vector3(0.08, 0.24, 0.01), c)
			k.decal_box(Vector3(0, 0.56, front + 0.005), Vector3(0.24, 0.12, 0.01), c.lightened(0.2))
		"gi":
			k.decal_box(Vector3(0, 0.44, front), Vector3(0.72, 0.08, 0.01), c2)
			k.push(Transform3D(Basis(Vector3.BACK, 0.5), Vector3(0.04, 0.72, front)))
			k.decal_box(Vector3.ZERO, Vector3(0.06, 0.44, 0.01), c2)
			k.pop()
		"coat":
			k.decal_box(Vector3(0, 0.67, front), Vector3(0.28, 0.52, 0.01), Color("fff6dd"))
			k.outline = 0.0
			for i in 3:
				for s: float in [-0.2, 0.2]:
					k.ball(Vector3(s, 0.5 + i * 0.15, front + 0.005), Vector3(0.03, 0.03, 0.01), c2, 2, 6)
			k.outline = 0.03
			k.box(Vector3(0, 0.33, 0), Vector3(0.76, 0.2, 0.56), c, 0.05)
		"tux":
			k.decal_box(Vector3(0, 0.7, front), Vector3(0.24, 0.46, 0.01), c2)
			k.decal_box(Vector3(0, 0.86, front + 0.005), Vector3(0.16, 0.07, 0.01), Color("e8282f"))
			k.outline = 0.0
			for i in 3:
				k.ball(Vector3(0, 0.56 + i * 0.09, front + 0.006), Vector3(0.018, 0.018, 0.01), Color("1d1a30"), 2, 5)
			k.outline = 0.03
		"space":
			k.decal_box(Vector3(0, 0.67, front), Vector3(0.36, 0.26, 0.01), Color("3a4a8a"))
			k.decal_box(Vector3(-0.1, 0.7, front + 0.005), Vector3(0.07, 0.07, 0.01), c2)
			k.decal_box(Vector3(0.1, 0.7, front + 0.005), Vector3(0.07, 0.07, 0.01), Color("35d07f"))
			k.decal_box(Vector3(0, 0.44, front), Vector3(0.7, 0.06, 0.01), c2)
		"armor":
			k.decal_box(Vector3(0, 0.67, front), Vector3(0.06, 0.5, 0.01), c2)
			k.decal_box(Vector3(0, 0.62, front), Vector3(0.6, 0.05, 0.01), c2)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.4 / w, 0.88, 0), Vector3(0.2, 0.15, 0.2), c2, 6, 9)
		"galaxy":
			k.outline = 0.0
			for spot: Vector2 in [Vector2(-0.22, 0.5), Vector2(0.24, 0.6), Vector2(-0.1, 0.8), Vector2(0.14, 0.84), Vector2(0.0, 0.62)]:
				k.ball(Vector3(spot.x, spot.y, front), Vector3(0.022, 0.022, 0.01), Color.WHITE, 2, 5)
			k.ball(Vector3(0.0, 0.67, front - 0.005), Vector3(0.2, 0.09, 0.012), c2, 3, 9)
			k.outline = 0.03
	k.pop()


static func pants(k: MeshKit, id: String, w: float) -> void:
	var def := Cosmetics.item("pants", id)
	var c := Color(def.get("c", "2f5fd0"))
	var c2 := Color(def.get("c2", "ffffff"))
	var style: String = def.get("style", "shorts")
	k.push(Transform3D(Basis.IDENTITY.scaled(Vector3(w, 1.0, w)), Vector3.ZERO))
	var front := 0.26
	k.soft_box(Vector3(0, 0.36, 0), Vector3(0.34, 0.16, 0.255), c)
	var long: bool = style in ["long", "track", "cargo", "checks", "dots", "armor", "galaxy"]
	if style not in ["tutu", "kilt", "grass"]:
		for s: float in [-1.0, 1.0]:
			if long:
				k.soft_box(Vector3(s * 0.2 / w, 0.2, 0), Vector3(0.135, 0.13, 0.15), c, 0.5, 8, 12)
			else:
				k.soft_box(Vector3(s * 0.2 / w, 0.25, 0), Vector3(0.135, 0.08, 0.15), c, 0.5, 8, 12)
	match style:
		"shorts", "long":
			k.decal_box(Vector3(0, 0.48, front), Vector3(0.66, 0.05, 0.01), c2 if style == "shorts" else c.darkened(0.25))
			if style == "long":
				k.decal_box(Vector3(0.18, 0.38, front), Vector3(0.16, 0.1, 0.01), c.lightened(0.18))
				k.decal_box(Vector3(-0.18, 0.38, front), Vector3(0.16, 0.1, 0.01), c.lightened(0.18))
		"track":
			for s: float in [-1.0, 1.0]:
				k.decal_box(Vector3(s * 0.345, 0.34, 0), Vector3(0.012, 0.28, 0.08), c2)
				k.decal_box(Vector3(s * 0.345 / w, 0.2, 0), Vector3(0.012, 0.2, 0.08), c2)
		"cargo":
			for s: float in [-1.0, 1.0]:
				k.box(Vector3(s * 0.33, 0.25, 0.1), Vector3(0.08, 0.16, 0.16), c2, 0.02)
		"stripes":
			for i in 3:
				k.decal_box(Vector3(0, 0.27 + i * 0.09, front), Vector3(0.66, 0.04, 0.01), c2)
		"checks":
			for ix in 3:
				for iy in 2:
					if (ix + iy) % 2 == 0:
						k.decal_box(Vector3(-0.22 + ix * 0.22, 0.3 + iy * 0.13, front), Vector3(0.18, 0.11, 0.01), c2)
		"floral", "dots":
			k.outline = 0.0
			for spot: Vector2 in [Vector2(-0.22, 0.42), Vector2(0.2, 0.44), Vector2(0.0, 0.32), Vector2(-0.14, 0.26), Vector2(0.22, 0.28)]:
				k.ball(Vector3(spot.x, spot.y, front), Vector3(0.042, 0.042, 0.012), c2, 3, 7)
			k.outline = 0.03
		"tutu":
			k.cyl(Vector3(0, 0.3, 0), 0.14, 0.62, 0.36, c, 14)
			k.cyl(Vector3(0, 0.27, 0), 0.08, 0.7, 0.6, c2, 14)
		"kilt":
			k.cyl(Vector3(0, 0.14, 0), 0.34, 0.5, 0.36, c, 12, false)
			k.outline = 0.0
			for i in 4:
				k.torus(Vector3(0, 0.2 + i * 0.07, 0), 0.47 - i * 0.03, 0.012, c2, 12, 3)
			k.outline = 0.03
		"grass":
			for i in 18:
				var a := TAU * i / 18.0
				var d := Vector3(cos(a), 0, sin(a))
				var side := d.cross(Vector3.UP) * 0.09
				k.blade(d * 0.3 + Vector3(0, 0.48, 0) + side, d * 0.3 + Vector3(0, 0.48, 0) - side, d * 0.42 + Vector3(0, 0.1, 0), c if i % 2 == 0 else c2)
		"armor":
			k.decal_box(Vector3(0, 0.46, front), Vector3(0.66, 0.06, 0.01), c2)
			for s: float in [-0.19, 0.19]:
				k.decal_box(Vector3(s, 0.22, 0.19), Vector3(0.2, 0.08, 0.01), c2)
		"galaxy":
			k.outline = 0.0
			for spot: Vector2 in [Vector2(-0.2, 0.42), Vector2(0.14, 0.3), Vector2(0.24, 0.44), Vector2(-0.08, 0.26)]:
				k.ball(Vector3(spot.x, spot.y, front), Vector3(0.02, 0.02, 0.01), Color.WHITE, 2, 5)
			k.ball(Vector3(0.0, 0.36, front - 0.005), Vector3(0.18, 0.07, 0.01), c2, 3, 8)
			k.outline = 0.03
	k.pop()


static func shoe(k: MeshKit, id: String) -> void:
	var def := Cosmetics.item("shoes", id)
	var c := Color(def.get("c", "ffffff"))
	var c2 := Color(def.get("c2", "ff5a4e"))
	match String(def.get("style", "sneaker")):
		"sneaker":
			k.box(Vector3(0, 0.02, 0.06), Vector3(0.3, 0.2, 0.46), c, 0.08)
			k.box(Vector3(0, -0.07, 0.06), Vector3(0.32, 0.07, 0.48), c2, 0.02)
			k.decal_box(Vector3(0, 0.125, 0.14), Vector3(0.16, 0.012, 0.08), c2)
		"slipper":
			k.box(Vector3(0, -0.08, 0.06), Vector3(0.3, 0.06, 0.48), c, 0.02)
			k.outline = 0.02
			k.ball(Vector3(0, 0.0, 0.08), Vector3(0.13, 0.09, 0.2), Color("e0a874"), 5, 8)
			k.torus(Vector3(0, -0.02, 0.1), 0.13, 0.022, c2, 12, 4)
			k.outline = 0.03
		"hitop":
			k.box(Vector3(0, 0.0, 0.08), Vector3(0.3, 0.16, 0.46), c, 0.07)
			k.box(Vector3(0, 0.13, -0.03), Vector3(0.28, 0.2, 0.26), c, 0.05)
			k.box(Vector3(0, -0.08, 0.08), Vector3(0.32, 0.06, 0.48), c2, 0.02)
			k.decal_box(Vector3(0, 0.14, 0.1), Vector3(0.14, 0.14, 0.01), c2)
		"boot":
			k.box(Vector3(0, -0.02, 0.08), Vector3(0.3, 0.16, 0.44), c, 0.07)
			k.box(Vector3(0, 0.15, -0.03), Vector3(0.28, 0.3, 0.26), c, 0.05)
			k.box(Vector3(0, -0.09, 0.08), Vector3(0.32, 0.05, 0.46), c2, 0.01)
			k.box(Vector3(0, 0.29, -0.03), Vector3(0.3, 0.05, 0.28), c2, 0.01)
		"clown":
			k.ball(Vector3(0, -0.01, 0.2), Vector3(0.22, 0.14, 0.34), c, 6, 10)
			k.box(Vector3(0, -0.05, -0.05), Vector3(0.26, 0.16, 0.22), c2, 0.05)
			k.ball(Vector3(0, 0.12, 0.05), Vector3(0.07, 0.05, 0.07), c2, 3, 7)
		"bunny":
			k.ball(Vector3(0, 0.0, 0.08), Vector3(0.18, 0.13, 0.26), c, 6, 10)
			for s: float in [-0.08, 0.08]:
				k.ball(Vector3(s, 0.17, 0.12), Vector3(0.04, 0.14, 0.05), c, 4, 7)
				k.outline = 0.0
				k.ball(Vector3(s, 0.17, 0.155), Vector3(0.02, 0.1, 0.02), c2, 3, 6)
				k.outline = 0.03
			k.outline = 0.0
			k.ball(Vector3(0, 0.04, 0.32), Vector3(0.025, 0.02, 0.015), c2, 2, 6)
			k.outline = 0.03
		"flipper":
			k.box(Vector3(0, 0.0, -0.02), Vector3(0.28, 0.16, 0.3), c2, 0.05)
			k.box(Vector3(0, -0.08, 0.3), Vector3(0.36, 0.04, 0.56), c, 0.01)
		"roller":
			k.box(Vector3(0, 0.08, 0.05), Vector3(0.28, 0.2, 0.42), c, 0.07)
			k.box(Vector3(0, -0.04, 0.05), Vector3(0.24, 0.05, 0.42), Color("3a3748"), 0.01)
			for z: float in [-0.08, 0.2]:
				k.ball(Vector3(0.1, -0.09, z), Vector3(0.05, 0.05, 0.05), c2, 3, 7)
				k.ball(Vector3(-0.1, -0.09, z), Vector3(0.05, 0.05, 0.05), c2, 3, 7)
		"rocket":
			k.box(Vector3(0, 0.0, 0.08), Vector3(0.3, 0.18, 0.44), c, 0.08)
			k.box(Vector3(0, 0.15, -0.02), Vector3(0.28, 0.2, 0.26), c, 0.05)
			k.cyl(Vector3(0, 0.0, -0.2), 0.2, 0.09, 0.09, Color("6a6a7a"), 7)
			k.outline = 0.0
			k.ball(Vector3(0, -0.07, -0.2), Vector3(0.07, 0.11, 0.07), c2, 3, 7)
			k.outline = 0.03


static func glove(k: MeshKit, id: String) -> void:
	var def := Cosmetics.item("gloves", id)
	var c := Color(def.get("c", "ffffff"))
	var c2 := Color(def.get("c2", "ffffff"))
	var hand := Vector3(0, -0.4, 0)
	match String(def.get("style", "band")):
		"band":
			k.torus(Vector3(0, -0.27, 0), 0.085, 0.04, c, 10, 5)
		"mitten":
			k.ball(hand + Vector3(0, -0.04, 0), Vector3(0.155, 0.185, 0.13), c, 8, 11)
			k.ball(hand + Vector3(0, 0.0, 0.13), Vector3(0.06, 0.07, 0.075), c, 4, 7)
			k.cyl(Vector3(0, -0.3, 0), 0.08, 0.115, 0.115, c2, 9)
		"boxing":
			k.ball(hand + Vector3(0, -0.04, 0), Vector3(0.21, 0.23, 0.22), c, 9, 12)
			k.ball(hand + Vector3(0, 0.02, 0.2), Vector3(0.08, 0.09, 0.09), c, 5, 8)
			k.cyl(Vector3(0, -0.32, 0), 0.1, 0.13, 0.13, c2, 9)
		"foam":
			k.soft_box(hand + Vector3(0, -0.04, 0), Vector3(0.15, 0.13, 0.09), c)
			k.box(hand + Vector3(0, -0.02, 0.2), Vector3(0.08, 0.08, 0.34), c, 0.03)
			k.decal_box(hand + Vector3(0, -0.04, 0.085), Vector3(0.18, 0.1, 0.01), c2)
		"crab":
			k.ball(hand + Vector3(0, -0.04, 0), Vector3(0.18, 0.15, 0.15), c, 5, 8)
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5 + 0.4), hand + Vector3(0, -0.04, 0.08)))
			k.cone(Vector3.ZERO, 0.3, 0.1, c2, 5)
			k.pop()
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5 - 0.4), hand + Vector3(0, -0.04, 0.08)))
			k.cone(Vector3.ZERO, 0.3, 0.1, c, 5)
			k.pop()
		"claw":
			k.ball(hand, Vector3(0.16, 0.17, 0.16), c, 6, 9)
			for s: float in [-0.09, 0.0, 0.09]:
				k.push(Transform3D(Basis(Vector3.RIGHT, PI), hand + Vector3(s, -0.13, 0.08)))
				k.cone(Vector3.ZERO, 0.17, 0.04, c2, 4)
				k.pop()
		"robot":
			k.box(hand, Vector3(0.24, 0.22, 0.24), c, 0.04)
			k.box(hand + Vector3(0, -0.15, 0.06), Vector3(0.2, 0.09, 0.05), c2, 0.01)
			k.box(hand + Vector3(0, -0.15, -0.06), Vector3(0.2, 0.09, 0.05), c2, 0.01)
		"flame":
			k.ball(hand, Vector3(0.16, 0.17, 0.16), c, 6, 9)
			k.cone(hand + Vector3(0, 0.03, 0), 0.34, 0.14, c2, 7)
			k.cone(hand + Vector3(0.1, 0.02, 0.04), 0.22, 0.08, c, 6)


static func _eyes(k: MeshKit, y: float, z: float, gap: float, r: float, color := Color("140a33")) -> void:
	k.outline = 0.0
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * gap, y, z), Vector3(r, r * 1.05, r * 0.3), color, 5, 9)
		k.ball(Vector3(s * gap + r * 0.22, y + r * 0.3, z + r * 0.22), Vector3(r * 0.22, r * 0.22, r * 0.06), Color.WHITE, 2, 5)
	k.outline = 0.03


## The plate of a face mask: a shell over the front of the head. Returns the z of its front.
static func _plate(k: MeshKit, c: Color, rx := 0.47, ry := 0.45, depth := 0.34, z := 0.2) -> float:
	k.ball(Vector3(0, 0, z), Vector3(rx, ry, depth), c, 10, 16)
	return z + depth


static func mask(k: MeshKit, id: String) -> void:
	match id:
		"shades":
			k.box(Vector3(0, 0.05, 0.46), Vector3(0.72, 0.05, 0.05), Color("1d1a30"))
			for s: float in [-0.19, 0.19]:
				k.box(Vector3(s, 0.02, 0.47), Vector3(0.28, 0.17, 0.04), Color("1d1a30"), 0.03)
				k.decal_box(Vector3(s - 0.05, 0.05, 0.492), Vector3(0.07, 0.03, 0.006), Color("7ee8ff"))
			for s: float in [-1.0, 1.0]:
				k.box(Vector3(s * 0.38, 0.05, 0.27), Vector3(0.03, 0.04, 0.4), Color("1d1a30"))
		"bandana":
			k.ball(Vector3(0, -0.2, 0.17), Vector3(0.47, 0.26, 0.34), Color("e8282f"), 8, 14)
			k.outline = 0.0
			for spot: Vector2 in [Vector2(-0.18, -0.17), Vector2(0.18, -0.2), Vector2(0.0, -0.3), Vector2(-0.08, -0.08), Vector2(0.1, -0.06)]:
				k.ball(Vector3(spot.x, spot.y, 0.48), Vector3(0.024, 0.024, 0.012), Color.WHITE, 2, 5)
			k.outline = 0.03
		"domino":
			k.ball(Vector3(0, 0.05, 0.3), Vector3(0.42, 0.14, 0.2), Color("e8282f"), 6, 14)
			_eyes(k, 0.05, 0.49, 0.19, 0.08, Color("fff8ea"))
		"ninja":
			var z := _plate(k, Color("2b2448"))
			k.ball(Vector3(0, 0.2, 0.1), Vector3(0.5, 0.32, 0.42), Color("2b2448"), 8, 14)
			k.outline = 0.0
			k.box(Vector3(0, 0.03, z - 0.04), Vector3(0.56, 0.14, 0.03), Color("e0b080"))
			k.outline = 0.03
			_eyes(k, 0.03, z - 0.02, 0.15, 0.05)
			k.box(Vector3(0, 0.26, 0.42), Vector3(0.74, 0.07, 0.08), Color("e8282f"), 0.01)
		"snorkel":
			k.box(Vector3(0, 0.03, 0.44), Vector3(0.6, 0.26, 0.1), Color("24135f"), 0.04)
			k.outline = 0.0
			k.box(Vector3(0, 0.03, 0.49), Vector3(0.52, 0.2, 0.02), Color("7ee8ff"))
			k.outline = 0.03
			_eyes(k, 0.03, 0.5, 0.15, 0.05)
			k.cyl(Vector3(0.32, -0.25, 0.3), 0.85, 0.035, 0.035, Color("ffd23f"), 6)
			k.ball(Vector3(0.32, 0.6, 0.3), Vector3(0.05, 0.05, 0.05), Color("ff5a4e"), 3, 6)
		"panda":
			var z := _plate(k, Color("f8f8fb"))
			k.outline = 0.0
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.19, 0.04, z - 0.04), Vector3(0.11, 0.13, 0.03), Color("241e33"), 4, 9)
			k.ball(Vector3(0, -0.13, z - 0.005), Vector3(0.05, 0.035, 0.02), Color("241e33"), 3, 7)
			k.outline = 0.03
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
			k.outline = 0.03
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
			k.outline = 0.03
			_eyes(k, 0.05, 0.47, 0.2, 0.065)
			k.outline = 0.0
			k.ball(Vector3(0, -0.2, 0.47), Vector3(0.09, 0.04, 0.02), Color("6a2038"), 2, 7)
			k.outline = 0.03
		"clown":
			var z := _plate(k, Color("fbf7ff"))
			k.outline = 0.0
			k.ball(Vector3(0, -0.18, z - 0.06), Vector3(0.22, 0.07, 0.03), Color("e8282f"), 3, 9)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.19, 0.08, z - 0.05), Vector3(0.09, 0.14, 0.02), Color("3a6aff"), 4, 8)
			k.outline = 0.03
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
			k.outline = 0.03
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
			k.outline = 0.03
			for s: float in [-1.0, 1.0]:
				k.cone(Vector3(s * 0.3, 0.3, 0.1), 0.34, 0.13, Color("fbf7ff"), 4)
				k.outline = 0.0
				k.cone(Vector3(s * 0.3, 0.32, 0.16), 0.22, 0.06, Color("e8282f"), 4)
				k.outline = 0.03
		"pixel":
			k.box(Vector3(0, 0.04, 0.45), Vector3(0.74, 0.24, 0.12), Color("1d1a30"), 0.02)
			k.outline = 0.0
			var colors := [Color("27e9ff"), Color("ff2fc0"), Color("6dff8c")]
			for i in 6:
				k.box(Vector3(-0.28 + i * 0.112, 0.04, 0.513), Vector3(0.09, 0.15, 0.01), colors[i % 3])
			k.outline = 0.03
		"oni":
			var z := _plate(k, Color("d43a2a"))
			k.outline = 0.0
			k.box(Vector3(0, -0.22, z - 0.05), Vector3(0.46, 0.12, 0.03), Color("3a0f12"))
			for s: float in [-1.0, 1.0]:
				k.box(Vector3(s * 0.2, 0.2, z - 0.09), Vector3(0.2, 0.05, 0.03), Color("3a0f12"))
			k.outline = 0.03
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
			k.outline = 0.03
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
			k.outline = 0.03
		"robot":
			k.box(Vector3(0, 0, 0.26), Vector3(0.78, 0.74, 0.36), Color("9aa8d6"), 0.08)
			k.outline = 0.0
			k.box(Vector3(0, 0.08, 0.445), Vector3(0.62, 0.26, 0.02), Color("140a33"))
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.16, 0.08, 0.46), Vector3(0.09, 0.09, 0.015), Color("27e9ff"), 3, 8)
			for i in 4:
				k.box(Vector3(-0.18 + i * 0.12, -0.22, 0.445), Vector3(0.08, 0.08, 0.02), Color("ffd23f"))
			k.outline = 0.03
		"pumpkin":
			k.ball(Vector3(0, 0.04, 0), Vector3(0.64, 0.56, 0.6), Color("ff9d2e"), 10, 16)
			k.outline = 0.0
			k.ball(Vector3(0, 0.04, 0), Vector3(0.36, 0.57, 0.61), Color("ffb04d"), 8, 14)
			for s: float in [-1.0, 1.0]:
				k.cone(Vector3(s * 0.22, 0.07, 0.56), 0.16, 0.09, Color("3a1c5a"), 3)
			k.box(Vector3(0, -0.15, 0.58), Vector3(0.48, 0.09, 0.03), Color("3a1c5a"))
			k.box(Vector3(-0.11, -0.11, 0.59), Vector3(0.07, 0.06, 0.02), Color("ffb04d"))
			k.box(Vector3(0.12, -0.19, 0.59), Vector3(0.07, 0.06, 0.02), Color("ffb04d"))
			k.outline = 0.03
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
			k.outline = 0.03
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
			k.outline = 0.03
			k.ball(Vector3(0, -0.03, 0.63), Vector3(0.09, 0.08, 0.08), Color("eaa880"), 4, 8)
		"moriones":
			k.ball(Vector3.ZERO, Vector3(0.54, 0.52, 0.5), Color("e8c9a0"), 10, 16)
			k.outline = 0.0
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.19, 0.03, 0.44), Vector3(0.07, 0.05, 0.03), Color.WHITE, 3, 7)
				k.ball(Vector3(s * 0.19, 0.03, 0.465), Vector3(0.035, 0.04, 0.012), Color("241e33"), 2, 6)
				k.box(Vector3(s * 0.19, 0.13, 0.43), Vector3(0.18, 0.04, 0.03), Color("3a2230"))
			k.box(Vector3(0, -0.24, 0.44), Vector3(0.34, 0.2, 0.05), Color("3a2230"))
			k.outline = 0.03
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
			k.outline = 0.03
			_eyes(k, 0.05, z - 0.02, 0.19, 0.075)
			k.cone(Vector3(0, 0.36, 0.2), 0.26, 0.12, Color("ffc21f"), 4)
		"galaxy":
			var z := _plate(k, Color("2a1a6e"))
			k.outline = 0.0
			k.ball(Vector3(0, -0.02, z - 0.03), Vector3(0.34, 0.14, 0.03), Color("7f4dff"), 3, 11)
			k.ball(Vector3(0, -0.02, z - 0.015), Vector3(0.18, 0.07, 0.02), Color("ff6fb5"), 3, 9)
			for spot: Vector2 in [Vector2(-0.28, 0.2), Vector2(0.24, 0.26), Vector2(0.3, -0.16), Vector2(-0.2, -0.26), Vector2(0.04, 0.32), Vector2(0.1, -0.3)]:
				k.ball(Vector3(spot.x, spot.y, z - 0.09), Vector3(0.02, 0.02, 0.012), Color.WHITE, 2, 5)
			k.outline = 0.03
			_eyes(k, 0.1, z - 0.03, 0.19, 0.06, Color("27e9ff"))
