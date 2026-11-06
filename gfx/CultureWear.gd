class_name CultureWear
extends RefCounted
## The last of the wardrobe: knights' helms and bamboo, instruments and kitchenware, little landmarks to wear on your head.
## WorldWear hands over to this for anything it doesn't know, and AvatarParts for new styles of top.

const GOLD := Color("ffc21f")
const STEEL := Color("c4cedc")
const WOOD := Color("8a5a34")
const INK := Color("0a1426")
const CREAM := Color("fff6dd")
const BAMBOO := Color("6ccf5a")
## Things on the back that stand on a pole from the bracket, like the banner.
const TALL := ["lance", "bamboo_pole", "koi_streamer", "gondola_oar"]


## A point on the front of a mask.
static func _on_mask(x: float, y: float, lift := 0.03) -> Vector3:
	return Vector3(x, y, AvatarParts._z(x, y, AvatarParts.M) + lift)


static func _plume(k: MeshKit, y: float, c: Color, sideways := false) -> void:
	for i in 7:
		var f := lerpf(-1.0, 1.0, i / 6.0)
		var at := Vector3(f * 0.32, y + (1.0 - f * f) * 0.16, 0.0) if sideways else Vector3(0, y + (1.0 - f * f) * 0.16, f * 0.34)
		k.ball(at, Vector3(0.1, 0.16, 0.05) if sideways else Vector3(0.05, 0.16, 0.1), c.lightened(0.1 * (i % 2)), 6, 8)


static func _stalk(k: MeshKit, base: Vector3, height: float, r: float, c := BAMBOO) -> void:
	k.cyl(base, height, r, r * 0.92, c, 10)
	var nodes := int(height / 0.26)
	for i in nodes:
		k.torus(base + Vector3(0, 0.2 + i * 0.26, 0), r, r * 0.2, c.darkened(0.22), 10, 4)


static func _leaf(k: MeshKit, at: Vector3, turn: float, size := 0.2) -> void:
	k.push(Transform3D(Basis(Vector3.BACK, turn), at))
	k.ball(Vector3(0, size, 0), Vector3(size * 0.24, size, size * 0.06), Color("4cbc5e"), 6, 8)
	k.pop()


static func hat(k: MeshKit, id: String) -> void:
	match id:
		"knight_helm":
			k.dome(Vector3(0, -0.02, 0), Vector3(0.6, 0.56, 0.6), STEEL, 10, 26)
			k.torus(Vector3.ZERO, 0.6, 0.035, STEEL.darkened(0.25), 28, 5)
			k.ball(Vector3(0, 0.16, 0.5), Vector3(0.4, 0.16, 0.12), STEEL.lightened(0.14), 7, 14)
			k.outline = 0.0
			k.ball(Vector3(0, 0.17, 0.62), Vector3(0.28, 0.012, 0.008), INK, 3, 8)
			k.outline = 0.02
			_plume(k, 0.56, Color("e8283f"))
		"joust_helm":
			k.cyl(Vector3(0, -0.04, 0), 0.62, 0.6, 0.56, STEEL, 24)
			k.ball(Vector3(0, 0.58, 0), Vector3(0.56, 0.04, 0.56), STEEL.darkened(0.1), 4, 22)
			k.outline = 0.0
			k.decal_box(Vector3(0, 0.3, 0.6), Vector3(0.6, 0.05, 0.02), INK)
			k.decal_box(Vector3(0, 0.08, 0.6), Vector3(0.05, 0.3, 0.02), INK)
			k.outline = 0.02
			k.torus(Vector3(0, 0.0, 0), 0.6, 0.03, GOLD, 26, 5)
			k.torus(Vector3(0, 0.56, 0), 0.56, 0.03, GOLD, 26, 5)
			k.ball(Vector3(0, 0.76, 0), Vector3(0.1, 0.22, 0.16), Color("3a6aff"), 6, 9)
			k.ball(Vector3(0.1, 0.86, -0.08), Vector3(0.1, 0.2, 0.12), Color("3aa6ff"), 6, 9)
		"paper_crown":
			var c := Color("ffd23f")
			k.cyl(Vector3.ZERO, 0.14, 0.58, 0.58, c, 24)
			for i in 8:
				var t := TAU * i / 8.0
				k.cone(Vector3(cos(t) * 0.56, 0.13, sin(t) * 0.56), 0.2, 0.15, c if i % 2 == 0 else Color("ff8fbf"), 6)
		"jester_cap":
			var purple := Color("7f5cff")
			var yellow := Color("ffd23f")
			k.dome(Vector3.ZERO, Vector3(0.58, 0.42, 0.58), purple, 8, 22)
			k.torus(Vector3.ZERO, 0.58, 0.04, yellow, 24, 5)
			for x: float in [-1.0, 0.0, 1.0]:
				k.tube(PackedVector3Array([Vector3(x * 0.3, 0.3, 0), Vector3(x * 0.48, 0.54, 0), Vector3(x * 0.72, 0.62, 0), Vector3(x * 0.84, 0.46, 0)]) if x != 0.0 else PackedVector3Array([Vector3(0, 0.3, 0), Vector3(0, 0.56, 0), Vector3(0, 0.78, 0)]), 0.17, yellow if x == 0.0 else purple, false, 8, 0.03)
				k.ball(Vector3(x * 0.84, 0.42, 0) if x != 0.0 else Vector3(0, 0.82, 0), Vector3(0.07, 0.07, 0.07), Color("ff6fb5"), 5, 8)
		"bamboo_sprouts":
			k.torus(Vector3(0, 0.04, 0), 0.57, 0.05, Color("3f9c4e"), 24, 6)
			_stalk(k, Vector3(-0.22, 0.04, 0.06), 0.72, 0.075)
			_stalk(k, Vector3(0.06, 0.04, -0.06), 0.98, 0.085)
			_stalk(k, Vector3(0.28, 0.04, 0.08), 0.58, 0.07)
			_leaf(k, Vector3(0.06, 0.9, -0.06), -0.7)
			_leaf(k, Vector3(0.06, 0.78, -0.06), 0.9)
			_leaf(k, Vector3(-0.22, 0.68, 0.06), 0.8)
			_leaf(k, Vector3(0.28, 0.54, 0.08), -0.9)
		"bamboo_flyer":
			k.cyl(Vector3(0, 0.2, 0), 0.34, 0.03, 0.03, BAMBOO.darkened(0.14), 8)
			k.ball(Vector3(0, 0.16, 0), Vector3(0.12, 0.06, 0.12), Color("e8483f"), 6, 10)
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.RIGHT, s * 0.32), Vector3(s * 0.32, 0.56, 0)))
				k.soft_box(Vector3.ZERO, Vector3(0.32, 0.016, 0.07), Color("e8c070"), 0.7, 3, 8)
				k.pop()
		"kasa":
			var straw := Color("e0be6a")
			k.dome(Vector3(0, 0.0, 0), Vector3(1.0, 0.4, 1.0), straw, 8, 30)
			k.torus(Vector3.ZERO, 1.0, 0.025, straw.darkened(0.2), 34, 5)
			k.outline = 0.0
			for f: float in [0.3, 0.55, 0.8]:
				k.torus(Vector3(0, sqrt(1.0 - f * f) * 0.4, 0), f, 0.008, straw.darkened(0.2), 26, 3)
			k.outline = 0.02
		"bicorne":
			var navy := Color("1d2a5c")
			k.ball(Vector3(0, 0.22, 0), Vector3(0.88, 0.34, 0.22), navy, 8, 20)
			k.ball(Vector3(0, 0.02, 0), Vector3(0.6, 0.12, 0.54), navy.darkened(0.14), 6, 18)
			k.outline = 0.0
			var path := PackedVector3Array()
			for i in 17:
				var t := lerpf(0.12, PI - 0.12, i / 16.0)
				path.append(Vector3(cos(t) * 0.86, 0.22 + sin(t) * 0.32, 0.17))
			k.tube(path, 0.018, GOLD, false, 4)
			k.outline = 0.02
			k.ball(Vector3(0.28, 0.3, 0.22), Vector3(0.08, 0.08, 0.03), Color("e8283f"), 5, 8)
			k.ball(Vector3(0.28, 0.3, 0.25), Vector3(0.04, 0.04, 0.02), CREAM, 4, 7)
		"flatcap":
			var tweed := Color("8a7a5a")
			k.ball(Vector3(0, 0.1, 0.06), Vector3(0.64, 0.2, 0.68), tweed, 8, 22)
			k.ball(Vector3(0, 0.02, 0.62), Vector3(0.36, 0.035, 0.16), tweed.darkened(0.14), 4, 14)
			k.outline = 0.0
			for f: float in [-0.3, 0.0, 0.3]:
				k.ball(Vector3(f, 0.29, 0.08), Vector3(0.01, 0.012, 0.5), tweed.darkened(0.2), 2, 5)
			k.outline = 0.02
		"deerstalker":
			var tweed := Color("a88a5a")
			k.dome(Vector3.ZERO, Vector3(0.58, 0.42, 0.58), tweed, 8, 22)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(0, 0.04, s * 0.62), Vector3(0.3, 0.035, 0.18), tweed.darkened(0.12), 4, 12)
				k.ball(Vector3(s * 0.56, 0.1, 0), Vector3(0.05, 0.18, 0.2), tweed.darkened(0.08), 5, 10)
			k.ball(Vector3(0, 0.42, 0), Vector3(0.07, 0.05, 0.07), tweed.darkened(0.22), 4, 8)
			k.outline = 0.0
			for f: float in [0.14, 0.26]:
				k.torus(Vector3(0, f, 0), sqrt(1.0 - pow(f / 0.42, 2.0)) * 0.58, 0.006, Color("5a4a30"), 22, 3)
			k.outline = 0.02
		"tam":
			var c := Color("c9302a")
			k.torus(Vector3(0, 0.04, 0), 0.58, 0.05, Color("1d3f9a"), 26, 6)
			k.ball(Vector3(0.04, 0.2, 0), Vector3(0.76, 0.16, 0.72), c, 8, 24)
			k.outline = 0.0
			for f: float in [-0.4, 0.0, 0.4]:
				k.ball(Vector3(f, 0.34, 0), Vector3(0.012, 0.012, 0.5), Color("1d3f9a"), 2, 6)
				k.ball(Vector3(0, 0.34, f), Vector3(0.5, 0.012, 0.012), Color("1d3f9a"), 2, 6)
			k.outline = 0.02
			k.ball(Vector3(0.04, 0.38, 0), Vector3(0.1, 0.08, 0.1), Color("ffd23f"), 6, 9)
		"lace_cap":
			var white := Color("fffdf4")
			k.dome(Vector3.ZERO, Vector3(0.58, 0.48, 0.58), white, 8, 22)
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.5), Vector3(s * 0.56, 0.14, 0.06)))
				k.ball(Vector3(0, 0.2, 0), Vector3(0.24, 0.28, 0.03), white, 6, 12)
				k.pop()
			k.torus(Vector3(0, 0.02, 0), 0.58, 0.025, Color("3a6aff"), 24, 4)
		"kokoshnik":
			var red := Color("d42a3f")
			k.ball(Vector3(0, 0.2, 0.06), Vector3(0.66, 0.64, 0.08), red, 8, 22)
			k.torus(Vector3(0, 0.02, 0), 0.57, 0.04, GOLD, 26, 5)
			k.outline = 0.0
			for i in 11:
				var t := lerpf(0.2, PI - 0.2, i / 10.0)
				k.ball(Vector3(cos(t) * 0.56, 0.2 + sin(t) * 0.54, 0.13), Vector3(0.035, 0.035, 0.02), Color("fffdf4"), 3, 7)
			k.ball(Vector3(0, 0.34, 0.13), Vector3(0.11, 0.11, 0.02), GOLD, 3, 10)
			for t: float in [0.6, 1.57, 2.54]:
				k.ball(Vector3(cos(t) * 0.3, 0.16 + sin(t) * 0.28, 0.13), Vector3(0.05, 0.05, 0.015), Color("ff9fc0"), 3, 8)
			k.outline = 0.02
		"centurion", "hoplite":
			var bronze := Color("e0a64a")
			k.dome(Vector3(0, -0.02, 0), Vector3(0.6, 0.56, 0.6), bronze, 10, 24)
			k.torus(Vector3.ZERO, 0.6, 0.04, bronze.darkened(0.22), 26, 5)
			if id == "centurion":
				k.ball(Vector3(0, 0.02, 0.56), Vector3(0.5, 0.05, 0.14), bronze.darkened(0.08), 4, 12)
				_plume(k, 0.54, Color("e8283f"), true)
			else:
				for s: float in [-1.0, 1.0]:
					k.outline = 0.0
					k.ball(Vector3(s * 0.2, 0.14, 0.53), Vector3(0.15, 0.1, 0.05), INK, 4, 10)
					k.outline = 0.02
				_plume(k, 0.56, Color("3a6aff"))
		"boater":
			var straw := Color("f0d27a")
			k.cyl(Vector3.ZERO, 0.26, 0.56, 0.54, straw, 24)
			k.ball(Vector3(0, 0.26, 0), Vector3(0.54, 0.02, 0.54), straw.lightened(0.08), 3, 20)
			k.ball(Vector3(0, 0.0, 0), Vector3(0.88, 0.022, 0.88), straw, 4, 28)
			k.torus(Vector3(0, 0.1, 0), 0.56, 0.04, Color("e8283f"), 24, 4)
			k.ball(Vector3(-0.54, 0.08, 0.16), Vector3(0.03, 0.12, 0.05), Color("e8283f"), 4, 6)
		"montera":
			var black := Color("1a1a2a")
			k.ball(Vector3(0, 0.14, -0.02), Vector3(0.62, 0.3, 0.58), black, 8, 22)
			k.torus(Vector3(0, 0.02, 0), 0.58, 0.035, GOLD, 24, 4)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.6, 0.18, 0.0), Vector3(0.17, 0.2, 0.2), black, 6, 10)
				k.ball(Vector3(s * 0.74, 0.14, 0.0), Vector3(0.05, 0.05, 0.05), Color("e8283f"), 4, 7)
		"panama":
			var cream := Color("f6e8c4")
			k.ball(Vector3(0, 0.0, 0), Vector3(0.94, 0.035, 0.94), cream, 4, 30)
			k.cyl(Vector3.ZERO, 0.34, 0.56, 0.5, cream, 24)
			k.ball(Vector3(0, 0.33, 0), Vector3(0.5, 0.12, 0.5), cream, 6, 20)
			k.torus(Vector3(0, 0.08, 0), 0.56, 0.05, INK, 24, 4)
		"bowler":
			var dark := Color("2a2438")
			k.ball(Vector3(0, 0.0, 0), Vector3(0.74, 0.03, 0.74), dark, 4, 24)
			k.dome(Vector3.ZERO, Vector3(0.54, 0.54, 0.54), dark, 8, 22)
			k.torus(Vector3(0, 0.05, 0), 0.54, 0.035, Color("e8483f"), 22, 4)
		"safari":
			var khaki := Color("d8c088")
			k.ball(Vector3(0, 0.0, 0), Vector3(0.88, 0.05, 0.88), khaki, 4, 26)
			k.dome(Vector3.ZERO, Vector3(0.56, 0.48, 0.56), khaki, 8, 22)
			k.torus(Vector3(0, 0.05, 0), 0.56, 0.035, Color("7a5a3c"), 22, 4)
		"steppe":
			var red := Color("d42a3f")
			k.cone(Vector3(0, 0.0, 0), 0.74, 0.54, red, 22)
			k.torus(Vector3(0, 0.03, 0), 0.58, 0.14, Color("6a4a2a"), 24, 8)
			k.cyl(Vector3(0, 0.72, 0), 0.14, 0.02, 0.03, GOLD, 6)
			k.ball(Vector3(0, 0.88, 0), Vector3(0.05, 0.05, 0.05), GOLD, 4, 7)
		"sun_hat":
			var straw := Color("f6dc8a")
			k.ball(Vector3(0, 0.0, 0), Vector3(1.05, 0.04, 1.05), straw, 4, 32)
			k.dome(Vector3.ZERO, Vector3(0.54, 0.4, 0.54), straw, 8, 22)
			k.torus(Vector3(0, 0.05, 0), 0.54, 0.05, Color("ff6fb5"), 22, 4)
			for i in 5:
				var t := TAU * i / 5.0
				k.ball(Vector3(0.42 + cos(t) * 0.09, 0.14 + sin(t) * 0.09, 0.42), Vector3(0.09, 0.09, 0.04), Color("ff6fb5"), 5, 8)
			k.ball(Vector3(0.42, 0.14, 0.44), Vector3(0.05, 0.05, 0.03), GOLD, 4, 7)
		"witch":
			var dark := Color("2a2448")
			k.ball(Vector3(0, 0.0, 0), Vector3(0.96, 0.03, 0.96), dark, 4, 28)
			k.tube(PackedVector3Array([Vector3(0, -0.02, 0), Vector3(0, 0.32, -0.02), Vector3(0.06, 0.66, -0.05), Vector3(0.28, 0.94, -0.1)]), 0.52, dark, false, 16, 0.03)
			k.torus(Vector3(0, 0.08, 0), 0.5, 0.05, Color("7f5cff"), 22, 4)
			k.soft_box(Vector3(0, 0.08, 0.5), Vector3(0.09, 0.08, 0.02), GOLD, 0.5, 3, 6)
		"foil":
			var silver := Color("d8e0ee")
			k.cone(Vector3.ZERO, 0.9, 0.6, silver, 7)
			k.outline = 0.0
			for a: float in [0.4, 1.8, 3.2, 4.6]:
				k.ball(Vector3(cos(a) * 0.32, 0.26, sin(a) * 0.32), Vector3(0.13, 0.13, 0.13), silver.lightened(0.4), 2, 5)
			k.outline = 0.02
		"pretzel_hat":
			var brown := Color("b5702c")
			k.torus(Vector3(0, 0.1, 0), 0.56, 0.1, brown, 26, 8)
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.36, 0)))
			for s: float in [-1.0, 1.0]:
				k.torus(Vector3(s * 0.2, 0.0, 0), 0.2, 0.06, brown, 16, 6)
			k.pop()
			k.outline = 0.0
			for t: float in [0.3, 1.2, 2.1, 3.3, 4.2, 5.4]:
				k.ball(Vector3(cos(t) * 0.56, 0.21, sin(t) * 0.56), Vector3(0.03, 0.016, 0.02), CREAM, 2, 5)
			k.outline = 0.02
		"teapot_hat":
			var china := Color("f4f8ff")
			var blue := Color("3a6aff")
			k.ball(Vector3(0, 0.28, 0), Vector3(0.42, 0.32, 0.42), china, 10, 18)
			k.outline = 0.0
			k.band(Vector3(0, 0.28, 0), Vector3(0.42, 0.32, 0.42), -0.02, 0.04, blue)
			k.outline = 0.02
			k.dome(Vector3(0, 0.54, 0), Vector3(0.22, 0.1, 0.22), blue, 5, 12)
			k.ball(Vector3(0, 0.67, 0), Vector3(0.05, 0.05, 0.05), GOLD, 4, 7)
			k.tube(PackedVector3Array([Vector3(0.36, 0.2, 0), Vector3(0.54, 0.28, 0), Vector3(0.62, 0.44, 0)]), 0.08, china, false, 8, 0.04)
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.44, 0.3, 0)))
			k.torus(Vector3.ZERO, 0.13, 0.03, blue, 14, 5)
			k.pop()
		"boba_hat":
			k.cyl(Vector3.ZERO, 0.56, 0.36, 0.44, Color("e0b890"), 20)
			k.outline = 0.0
			for i in 9:
				var t := i * 0.7
				k.ball(Vector3(cos(t) * 0.36, 0.09 + (i % 3) * 0.05, sin(t) * 0.36), Vector3(0.05, 0.05, 0.05), Color("3a2030"), 3, 6)
			k.outline = 0.02
			k.dome(Vector3(0, 0.56, 0), Vector3(0.43, 0.16, 0.43), Color("f4fcff"), 5, 16)
			k.push(Transform3D(Basis(Vector3.BACK, -0.2), Vector3(0.08, 0.56, 0)))
			k.cyl(Vector3.ZERO, 0.42, 0.04, 0.04, Color("ff6fb5"), 8)
			k.pop()
		"steamer":  # Three dumplings, in a real bamboo basket.
			var bam := Color("d8b070")
			k.cyl(Vector3.ZERO, 0.26, 0.62, 0.62, bam, 26)
			k.torus(Vector3(0, 0.04, 0), 0.62, 0.025, bam.darkened(0.2), 26, 4)
			k.torus(Vector3(0, 0.23, 0), 0.62, 0.025, bam.darkened(0.2), 26, 4)
			for i in 3:
				var t := TAU * i / 3.0 + 0.5
				var at := Vector3(cos(t) * 0.28, 0.32, sin(t) * 0.28)
				k.ball(at, Vector3(0.2, 0.15, 0.2), Color("fffaf0"), 7, 12)
				k.cone(at + Vector3(0, 0.1, 0), 0.08, 0.06, Color("fffaf0"), 6)
		"croissant_hat":
			var c := Color("e8b469")
			k.ball(Vector3(0, 0.3, 0), Vector3(0.3, 0.24, 0.3), c, 9, 14)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.34, 0.2, 0.0), Vector3(0.2, 0.2, 0.24), c, 8, 12)
				k.ball(Vector3(s * 0.58, 0.08, 0.02), Vector3(0.14, 0.15, 0.17), c, 7, 10)
				k.ball(Vector3(s * 0.72, 0.0, 0.04), Vector3(0.08, 0.09, 0.1), c.darkened(0.06), 6, 8)
			k.outline = 0.0
			for f: float in [-0.46, -0.22, 0.22, 0.46]:
				k.push(Transform3D(Basis(Vector3.BACK, f * 0.9), Vector3(f, 0.32 - absf(f) * 0.28, 0.24)))
				k.ball(Vector3.ZERO, Vector3(0.018, 0.13, 0.05), c.darkened(0.2), 3, 6)
				k.pop()
			k.outline = 0.02
		"taco_hat":
			var shell := Color("f0b860")
			for i in 7:
				var t := lerpf(0.2, PI - 0.2, i / 6.0)
				k.ball(Vector3(cos(t) * 0.52, 0.18 + sin(t) * 0.42, -0.02), Vector3(0.15, 0.12, 0.14), Color("7ed957") if i % 3 != 1 else Color("ff5a4e"), 5, 8)
			k.ball(Vector3(0, 0.16, 0.05), Vector3(0.62, 0.54, 0.14), shell, 10, 20)
		"tiny_pyramid":
			var sand := Color("e6c387")
			k.cone(Vector3(0, 0.0, 0), 0.78, 0.74, sand, 4)
			k.outline = 0.0
			for f: float in [0.22, 0.44, 0.66]:
				k.torus(Vector3(0, f * 0.78, 0), (1.0 - f) * 0.76, 0.012, sand.darkened(0.2), 4, 3)
			k.outline = 0.02
		"little_pagoda":
			var red := Color("d42a2a")
			var green := Color("3a9c6e")
			for i in 3:
				var y := i * 0.28
				var r := 0.42 - i * 0.1
				k.cyl(Vector3(0, y, 0), 0.2, r, r, red, 12)
				k.cone(Vector3(0, y + 0.18, 0), 0.16, r + 0.2, green, 12)
			k.cyl(Vector3(0, 0.98, 0), 0.16, 0.025, 0.012, GOLD, 6)
		"little_eiffel":
			var iron := Color("6a6a7a")
			k.cyl(Vector3.ZERO, 0.34, 0.42, 0.2, iron, 4)
			k.cyl(Vector3(0, 0.3, 0), 0.04, 0.26, 0.26, iron.darkened(0.14), 4)
			k.cyl(Vector3(0, 0.34, 0), 0.34, 0.18, 0.09, iron, 4)
			k.cyl(Vector3(0, 0.66, 0), 0.03, 0.13, 0.13, iron.darkened(0.14), 4)
			k.cyl(Vector3(0, 0.69, 0), 0.42, 0.075, 0.02, iron, 4)
		"dragon_hood":
			var green := Color("3ab06a")
			k.dome(Vector3(0, -0.02, 0), Vector3(0.6, 0.5, 0.6), green, 10, 24)
			k.torus(Vector3.ZERO, 0.6, 0.04, Color("ffd23f"), 26, 5)
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.55), Vector3(s * 0.3, 0.36, -0.1)))
				k.cone(Vector3.ZERO, 0.3, 0.07, Color("fff6dd"), 7)
				k.pop()
				k.ball(Vector3(s * 0.26, 0.34, 0.42), Vector3(0.11, 0.11, 0.08), Color.WHITE, 6, 9)
				k.outline = 0.0
				k.ball(Vector3(s * 0.26, 0.34, 0.5), Vector3(0.05, 0.06, 0.02), INK, 3, 7)
				k.outline = 0.02
			for i in 4:
				k.cone(Vector3(0, 0.44 - i * 0.1, -0.08 - i * 0.14), 0.16, 0.06, Color("ffd23f"), 5)
		"beehive":
			var yellow := Color("ffc21f")
			for i in 5:
				var r := 0.54 - i * 0.09
				k.torus(Vector3(0, 0.08 + i * 0.15, 0), r, 0.09, yellow if i % 2 == 0 else yellow.darkened(0.08), 22, 6)
			k.outline = 0.0
			for at: Vector3 in [Vector3(0.5, 0.4, 0.36), Vector3(-0.56, 0.54, 0.16)]:
				k.ball(at, Vector3(0.05, 0.04, 0.035), Color("ffe05c"), 3, 6)
				k.ball(at, Vector3(0.016, 0.04, 0.036), INK, 2, 5)
			k.outline = 0.02
		"little_castle":
			var stone := Color("c4c8d4")
			k.soft_box(Vector3(0, 0.2, 0), Vector3(0.44, 0.22, 0.34), stone, 0.3, 4, 8)
			for x: float in [-0.44, 0.44]:
				k.cyl(Vector3(x, 0.0, 0.3), 0.62, 0.12, 0.12, stone.lightened(0.08), 10)
				k.cone(Vector3(x, 0.6, 0.3), 0.26, 0.15, Color("3a6aff"), 10)
			k.cyl(Vector3(0, 0.38, -0.06), 0.42, 0.14, 0.14, stone, 10)
			k.cone(Vector3(0, 0.78, -0.06), 0.34, 0.18, Color("e8483f"), 10)
			k.outline = 0.0
			k.decal_box(Vector3(0, 0.12, 0.34), Vector3(0.14, 0.2, 0.02), Color("5a3a24"))
			k.outline = 0.02
		"hennin":
			var pink := Color("ff8fc2")
			k.cone(Vector3.ZERO, 1.05, 0.46, pink, 20)
			k.torus(Vector3(0, 0.03, 0), 0.46, 0.03, GOLD, 22, 4)
			var veil: Array[PackedVector3Array] = []
			for i in 7:
				var v := i / 6.0
				var row := PackedVector3Array()
				for j in 5:
					var u := lerpf(-1.0, 1.0, j / 4.0)
					row.append(Vector3(u * lerpf(0.02, 0.24, v), lerpf(1.02, 0.28, v), -lerpf(0.02, 0.5, v) + sin(v * 8.0 + u) * 0.02))
				veil.append(row)
			k.sheet(veil, Color("fff6ff"))


static func mask(k: MeshKit, id: String, hatted := false) -> void:
	var M := AvatarParts.M
	var GOLD_LINE := GOLD
	match id:
		"kabuki":
			var red := Color("e8283f")
			AvatarParts._plate(k, Color("fbf9f4"))
			for s: float in [-1.0, 1.0]:
				AvatarParts._stroke(k, PackedVector2Array([Vector2(s * 0.08, 0.02), Vector2(s * 0.2, 0.12), Vector2(s * 0.36, 0.22)]), 0.028, red, M)
				AvatarParts._stroke(k, PackedVector2Array([Vector2(s * 0.08, 0.14), Vector2(s * 0.24, 0.22), Vector2(s * 0.34, 0.3)]), 0.02, INK, M)
				AvatarParts._stroke(k, PackedVector2Array([Vector2(s * 0.14, -0.1), Vector2(s * 0.28, -0.14), Vector2(s * 0.38, -0.08)]), 0.02, red, M)
			AvatarParts._eyes_on(k, 0.02, 0.19, 0.06, AvatarParts.DARK, M, 0.006)
			AvatarParts._smile(k, -0.25, 0.14, -0.03, 0.022, red, M)
		"opera":
			var red := Color("d42a3f")
			AvatarParts._plate(k, red)
			AvatarParts._paint(k, 0.0, 0.2, 0.09, 0.2, Color("fffdf4"), M, 0.006)
			AvatarParts._paint(k, 0.0, -0.08, 0.1, 0.08, AvatarParts.DARK, M, 0.006)
			for s: float in [-1.0, 1.0]:
				AvatarParts._paint(k, s * 0.2, 0.03, 0.14, 0.11, AvatarParts.DARK, M, 0.006)
				AvatarParts._paint(k, s * 0.2, 0.03, 0.08, 0.06, Color("fffdf4"), M, 0.009)
				AvatarParts._paint(k, s * 0.2, 0.03, 0.035, 0.035, AvatarParts.DARK, M, 0.012)
				AvatarParts._stroke(k, PackedVector2Array([Vector2(s * 0.06, 0.16), Vector2(s * 0.22, 0.26), Vector2(s * 0.38, 0.2)]), 0.03, GOLD_LINE, M)
				AvatarParts._stroke(k, PackedVector2Array([Vector2(s * 0.16, -0.16), Vector2(s * 0.3, -0.2), Vector2(s * 0.36, -0.08)]), 0.024, GOLD_LINE, M)
			AvatarParts._smile(k, -0.28, 0.14, 0.03, 0.022, AvatarParts.DARK, M)
		"mime":
			AvatarParts._plate(k, Color("fbfcff"))
			for s: float in [-1.0, 1.0]:
				AvatarParts._paint(k, s * 0.19, 0.03, 0.06, 0.08, AvatarParts.DARK, M, 0.006)
				AvatarParts._stroke(k, PackedVector2Array([Vector2(s * 0.12, 0.17), Vector2(s * 0.2, 0.22), Vector2(s * 0.28, 0.17)]), 0.016, AvatarParts.DARK, M)
			AvatarParts._stroke(k, PackedVector2Array([Vector2(0.19, -0.07), Vector2(0.19, -0.14), Vector2(0.19, -0.22)]), 0.018, AvatarParts.DARK, M)
			AvatarParts._paint(k, 0.0, -0.25, 0.08, 0.035, Color("d42a3f"), M, 0.006)
		"viking_beard", "wizard_beard":
			var long: bool = id == "wizard_beard"
			var c := Color("f4f6ff") if long else Color("e8933a")
			k.ball(Vector3(0, -0.3, 0.16), Vector3(0.44, 0.24, 0.34), c, 8, 14)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.36, -0.14, 0.2), Vector3(0.14, 0.2, 0.2), c, 6, 10)
				k.ball(Vector3(s * 0.11, -0.13, 0.43), Vector3(0.14, 0.05, 0.07), c.darkened(0.08), 5, 9)
			if long:
				k.ball(Vector3(0, -0.56, 0.2), Vector3(0.26, 0.3, 0.2), c, 8, 12)
				k.ball(Vector3(0, -0.8, 0.2), Vector3(0.13, 0.17, 0.12), c, 6, 10)
		"walrus":
			var c := Color("6a4a2a")
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.14, -0.16, 0.42), Vector3(0.18, 0.08, 0.08), c, 6, 10)
				k.ball(Vector3(s * 0.27, -0.24, 0.36), Vector3(0.09, 0.11, 0.07), c, 6, 9)
			k.ball(Vector3(0, -0.1, 0.46), Vector3(0.065, 0.055, 0.05), Color("ff9fa0"), 5, 8)
		"eyepatch":
			k.tube(AvatarParts._ring(0.04, M), 0.012, INK, true, 4)
			k.ball(_on_mask(-0.2, -0.02, 0.0), Vector3(0.12, 0.13, 0.03), INK, 6, 10)
		"monocle":
			var at := _on_mask(0.2, -0.03)
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), at))
			k.torus(Vector3.ZERO, 0.13, 0.016, GOLD, 18, 5)
			k.pop()
			k.outline = 0.0
			k.ball(at, Vector3(0.12, 0.12, 0.005), Color(0.82, 0.94, 1.0), 3, 12)
			k.outline = 0.02
			k.tube(PackedVector3Array([at + Vector3(0.1, -0.09, 0), at + Vector3(0.2, -0.28, -0.08), at + Vector3(0.24, -0.46, -0.22)]), 0.008, GOLD, false, 4)
		"star_shades":
			var pink := Color("ff4fa8")
			k.tube(AvatarParts._ring(0.03, M), 0.012, pink, true, 4)
			for s: float in [-1.0, 1.0]:
				var at := _on_mask(s * 0.2, -0.03)
				k.outline = 0.0
				k.fan(FaceParts._star_ring(at + Vector3(0, 0, 0.008), 0.19, 0.09, 5), INK)
				k.fan(FaceParts._star_ring(at + Vector3(0, 0, 0.016), 0.16, 0.07, 5), pink)
				k.outline = 0.02
		"cat_face":
			k.ball(Vector3.ZERO, AvatarParts.W, Color("ffb04d"), 18, 28)
			if not hatted:
				for s: float in [-1.0, 1.0]:
					k.push(Transform3D(Basis(Vector3.BACK, s * -0.3), Vector3(s * 0.3, 0.38, -0.02)))
					k.cone(Vector3.ZERO, 0.28, 0.14, Color("ffb04d"), 8)
					k.pop()
			var w := AvatarParts.W
			for s: float in [-1.0, 1.0]:
				AvatarParts._paint(k, s * 0.2, 0.03, 0.09, 0.11, AvatarParts.DARK, w, 0.006)
				AvatarParts._paint(k, s * 0.23, 0.07, 0.03, 0.035, Color.WHITE, w, 0.009)
				for dy: float in [0.0, -0.05]:
					AvatarParts._stroke(k, PackedVector2Array([Vector2(s * 0.22, -0.12 + dy), Vector2(s * 0.32, -0.13 + dy), Vector2(s * 0.44, -0.11 + dy)]), 0.008, AvatarParts.DARK, w)
			AvatarParts._paint(k, 0.0, -0.1, 0.035, 0.024, Color("ff8fa6"), w, 0.008)
			AvatarParts._smile(k, -0.17, 0.09, 0.03, 0.012, AvatarParts.DARK, w)
			for f: float in [-0.1, 0.0, 0.1]:
				AvatarParts._paint(k, f, 0.32 - absf(f) * 0.3, 0.018, 0.06, Color("c9702f"), w, 0.006)


static func top(k: MeshKit, style: String, at: Vector3, r: Vector3, hem: float, c: Color, c2: Color) -> void:
	match style:
		"tabard":  # A long panel down the front, with a chevron, over armour.
			k.patch(at, r, -0.15, 0.15, -0.27, 0.2, c2)
			k.band(at, r, hem, hem + 0.03, GOLD)
			k.spot(at, r, 0.0, -0.02, 0.05, GOLD)
		"chainmail":
			k.outline = 0.0
			for row in 4:
				for col in 5:
					var x := (col - 2) * 0.12 + (0.06 if row % 2 == 1 else 0.0)
					var y := 0.15 - row * 0.11
					if pow(x / r.x, 2.0) + pow(y / r.y, 2.0) < 0.72:
						k.spot(at, r, x, y, 0.03, c2)
			k.outline = 0.02
			k.band(at, r, hem, hem + 0.04, c2.darkened(0.2))
		"plates":
			for y: float in [-0.2, -0.11, -0.02, 0.07, 0.16]:
				k.band(at, r, y, y + 0.05, c2)
		"tartan":
			for f: float in [-0.2, -0.07, 0.07, 0.2]:
				k.patch(at, r, f - 0.018, f + 0.018, -0.27, 0.22, c2)
			for y: float in [-0.18, -0.06, 0.06, 0.16]:
				k.band(at, r, y, y + 0.03, c2)
		"vest":  # A shirt with a waistcoat open down the front.
			k.patch(at, r, -0.2, -0.05, -0.24, 0.18, c2)
			k.patch(at, r, 0.05, 0.2, -0.24, 0.18, c2)
			for y: float in [0.08, -0.04, -0.15]:
				k.spot(at, r, 0.075, y, 0.018, GOLD)
		"sailor":
			k.patch(at, r, -0.14, 0.14, 0.09, 0.22, c2)
			k.band(at, r, hem, hem + 0.04, c2)
			k.spot(at, r, 0.0, 0.03, 0.05, Color("e8283f"))
		"dirndl":
			k.patch(at, r, -0.17, 0.17, 0.05, 0.22, Color("fffdf4"))
			k.patch(at, r, -0.14, 0.14, -0.27, -0.03, Color("fffdf4"))
			k.band(at, r, -0.03, 0.02, c2)
			for x: float in [-0.11, 0.11]:
				k.patch(at, r, x - 0.022, x + 0.022, 0.02, 0.22, c2)
		"embroidered":
			k.patch(at, r, -0.06, 0.06, -0.14, 0.22, c2)
			k.band(at, r, hem, hem + 0.05, c2)
			k.outline = 0.0
			for y: float in [0.13, 0.04, -0.05]:
				k.spot(at, r, 0.0, y, 0.022, c)
			k.outline = 0.02
		"robe":
			k.patch(at, r, -0.05, 0.05, -0.27, 0.22, c2)
			k.band(at, r, hem, hem + 0.05, c2)
			k.outline = 0.0
			for spot: Vector2 in [Vector2(-0.18, 0.03), Vector2(0.18, -0.08), Vector2(-0.14, -0.15), Vector2(0.17, 0.12)]:
				k.spot(at, r, spot.x, spot.y, 0.03, c2)
			k.outline = 0.02
		"collar":
			k.ball(at + Vector3(0, 0.18, 0), Vector3(r.x * 0.9, 0.11, r.z * 0.92), c2, 6, 14)
			k.outline = 0.0
			k.band(at + Vector3(0, 0.18, 0), Vector3(r.x * 0.9, 0.11, r.z * 0.92), -0.03, 0.0, Color("2f4fd0"))
			k.outline = 0.02
			k.band(at, r, hem, hem + 0.04, c2)
		"motley":
			k.patch(at, r, -0.3, 0.0, -0.27, 0.22, c2)
			k.band(at, r, hem, hem + 0.03, Color("ff6fb5"))


static func _pole_end(k: MeshKit, end: Vector3, height: float, c: Color, r := 0.024) -> void:
	k.cyl(end + Vector3(0, -0.14, 0), height, r, r, c, 8)


static func back(k: MeshKit, id: String, end: Vector3) -> void:
	match id:
		"sword_shield":
			k.push(Transform3D(Basis(Vector3.BACK, 0.65), Vector3(0, -0.14, -0.14)))
			k.soft_box(Vector3(0, 0.34, 0), Vector3(0.05, 0.62, 0.016), Color("e8eef8"), 0.5, 3, 8)
			k.soft_box(Vector3(0, -0.28, 0), Vector3(0.19, 0.04, 0.03), GOLD, 0.6, 3, 8)
			k.cyl(Vector3(0, -0.46, 0), 0.18, 0.03, 0.03, Color("5a3a24"), 8)
			k.ball(Vector3(0, -0.5, 0), Vector3(0.05, 0.05, 0.05), GOLD, 4, 8)
			k.pop()
			k.push(Transform3D(Basis.IDENTITY, Vector3(0, -0.14, -0.22)))
			k.soft_box(Vector3(0, 0.1, 0), Vector3(0.32, 0.2, 0.045), Color("e8483f"), 0.55, 6, 12)
			k.ball(Vector3(0, -0.1, 0), Vector3(0.3, 0.36, 0.045), Color("e8483f"), 8, 16)
			k.outline = 0.0
			k.ball(Vector3(0, 0.08, -0.05), Vector3(0.3, 0.05, 0.006), GOLD, 3, 12)
			k.ball(Vector3(0, -0.06, -0.05), Vector3(0.24, 0.05, 0.006), GOLD, 3, 12)
			k.ball(Vector3(0, -0.2, -0.05), Vector3(0.14, 0.04, 0.006), GOLD, 3, 10)
			k.outline = 0.02
			k.ball(Vector3(0, 0.22, -0.05), Vector3(0.05, 0.05, 0.02), GOLD, 4, 7)
			k.pop()
		"lance":
			k.cyl(end + Vector3(0, -0.14, 0), 2.1, 0.03, 0.018, Color("e8eef8"), 8)
			k.cone(end + Vector3(0, -0.12, 0), 0.34, 0.1, Color("e8483f"), 10)
			k.cone(end + Vector3(0, 1.94, 0), 0.26, 0.04, STEEL, 8)
			var cloth: Array[PackedVector3Array] = []
			for i in 5:
				var v := i / 4.0
				var row := PackedVector3Array()
				for j in 6:
					var u := j / 5.0
					row.append(end + Vector3(0.02 + u * 0.56, 1.84 - v * 0.34 * (1.0 - u), sin(u * 6.0) * 0.025))
				cloth.append(row)
			k.sheet(cloth, Color("3a6aff"), 0.01)
		"bamboo_pole":
			_stalk(k, end + Vector3(-0.07, -0.14, 0), 1.5, 0.05)
			_stalk(k, end + Vector3(0.05, -0.14, 0.02), 2.1, 0.06)
			_leaf(k, end + Vector3(0.05, 1.9, 0.02), -0.7, 0.24)
			_leaf(k, end + Vector3(0.05, 1.78, 0.02), 0.9, 0.24)
			_leaf(k, end + Vector3(0.05, 1.5, 0.02), -1.1, 0.2)
			_leaf(k, end + Vector3(-0.07, 1.3, 0), 0.8, 0.2)
		"bamboo_basket":
			var bam := Color("d8b070")
			k.cyl(Vector3(0, -0.36, -0.2), 0.56, 0.2, 0.28, bam, 16)
			k.outline = 0.0
			for f: float in [0.1, 0.24, 0.38, 0.52]:
				k.torus(Vector3(0, -0.36 + f, -0.2), lerpf(0.2, 0.28, f / 0.56), 0.012, bam.darkened(0.26), 16, 3)
			k.outline = 0.02
			k.torus(Vector3(0, 0.2, -0.2), 0.28, 0.03, bam.darkened(0.18), 18, 4)
			for at: Vector2 in [Vector2(-0.1, 0.0), Vector2(0.08, -0.08), Vector2(0.1, 0.08)]:
				_stalk(k, Vector3(at.x, 0.1, -0.2 + at.y), 0.5, 0.036)
			_leaf(k, Vector3(-0.1, 0.56, -0.2), 0.8, 0.14)
			_leaf(k, Vector3(0.08, 0.56, -0.28), -0.8, 0.14)
		"wood_sword":
			var path_c := Color("c98c4a")
			k.push(Transform3D(Basis(Vector3.BACK, -0.7), Vector3(0, -0.12, -0.14)))
			k.soft_box(Vector3(0, 0.26, 0), Vector3(0.04, 0.68, 0.022), path_c, 0.7, 3, 8)
			k.torus(Vector3(0, -0.38, 0), 0.07, 0.016, Color("1a1a2a"), 12, 3)
			k.cyl(Vector3(0, -0.64, 0), 0.24, 0.03, 0.03, Color("e8483f"), 8)
			k.pop()
		"bow_quiver":
			var path := PackedVector3Array()
			for i in 13:
				var t := lerpf(-1.1, 1.1, i / 12.0)
				path.append(Vector3(sin(t) * 0.1, sin(t) * 0.7, -0.26 - cos(t) * 0.12))
			k.tube(path, 0.025, WOOD, false, 6)
			k.tube(PackedVector3Array([path[0], path[12]]), 0.006, CREAM, false, 3)
			k.push(Transform3D(Basis(Vector3.BACK, 0.3), Vector3(0.1, -0.16, -0.14)))
			k.cyl(Vector3(0, -0.2, 0), 0.5, 0.08, 0.1, Color("7a4a26"), 10)
			for x: float in [-0.04, 0.0, 0.04]:
				k.cyl(Vector3(x, 0.3, x), 0.28, 0.01, 0.01, CREAM, 5)
				k.ball(Vector3(x, 0.58, x), Vector3(0.022, 0.05, 0.03), Color("e8483f"), 4, 6)
			k.pop()
		"lute":
			k.push(Transform3D(Basis(Vector3.BACK, -0.4), Vector3(0, -0.2, -0.17)))
			k.ball(Vector3.ZERO, Vector3(0.24, 0.3, 0.09), Color("c98c4a"), 10, 14)
			k.outline = 0.0
			k.ball(Vector3(0, 0.02, -0.088), Vector3(0.05, 0.05, 0.006), Color("3a2315"), 3, 8)
			k.outline = 0.02
			k.soft_box(Vector3(0, 0.46, 0), Vector3(0.035, 0.26, 0.018), WOOD, 0.7, 3, 6)
			k.push(Transform3D(Basis(Vector3.RIGHT, -0.9), Vector3(0, 0.72, 0)))
			k.soft_box(Vector3(0, 0.05, 0), Vector3(0.04, 0.08, 0.018), WOOD.darkened(0.2), 0.7, 3, 6)
			k.pop()
			k.pop()
		"accordion":
			var red := Color("d42a3f")
			k.soft_box(Vector3(0, -0.16, -0.22), Vector3(0.1, 0.24, 0.1), red, 0.5, 4, 8)
			for x: float in [-0.16, 0.16]:
				k.soft_box(Vector3(x, -0.16, -0.22), Vector3(0.09, 0.26, 0.11), Color("1a1a2a"), 0.5, 4, 8)
			k.outline = 0.0
			for f: float in [-0.14, -0.06, 0.02, 0.1]:
				k.ball(Vector3(-0.17, -0.16 + f, -0.335), Vector3(0.018, 0.018, 0.006), Color("fffdf4"), 2, 5)
				k.ball(Vector3(0.17, -0.16 + f, -0.335), Vector3(0.018, 0.018, 0.006), GOLD, 2, 5)
			k.outline = 0.02
		"violin":
			k.push(Transform3D(Basis(Vector3.BACK, -0.3), Vector3(0.02, -0.14, -0.15)))
			k.ball(Vector3(0, -0.12, 0), Vector3(0.18, 0.18, 0.05), Color("a8542a"), 8, 14)
			k.ball(Vector3(0, 0.1, 0), Vector3(0.13, 0.13, 0.05), Color("a8542a"), 8, 14)
			k.soft_box(Vector3(0, 0.38, 0), Vector3(0.024, 0.18, 0.016), Color("2a1c18"), 0.7, 3, 6)
			k.ball(Vector3(0, 0.6, 0), Vector3(0.04, 0.05, 0.03), Color("a8542a"), 5, 7)
			k.pop()
			k.push(Transform3D(Basis(Vector3.BACK, 0.4), Vector3(-0.02, -0.1, -0.22)))
			k.cyl(Vector3(0, -0.34, 0), 0.76, 0.008, 0.008, WOOD, 5)
			k.pop()
		"djembe":
			var wood := Color("8a5a34")
			k.cyl(Vector3(0, -0.52, -0.2), 0.3, 0.1, 0.14, wood, 14)
			k.cyl(Vector3(0, -0.22, -0.2), 0.42, 0.14, 0.27, wood, 14)
			k.ball(Vector3(0, 0.2, -0.2), Vector3(0.27, 0.03, 0.27), Color("f4e6c4"), 3, 14)
			k.outline = 0.0
			for i in 8:
				var t := TAU * i / 8.0
				k.tube(PackedVector3Array([Vector3(cos(t) * 0.27, 0.18, -0.2 + sin(t) * 0.27), Vector3(cos(t + 0.4) * 0.15, -0.2, -0.2 + sin(t + 0.4) * 0.15)]), 0.006, Color("e8483f"), false, 3)
			k.outline = 0.02
		"steel_drum":
			k.cyl(Vector3(0, -0.34, -0.2), 0.32, 0.32, 0.32, STEEL, 18)
			k.push(Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(0, -0.02, -0.22)))
			k.ball(Vector3.ZERO, Vector3(0.32, 0.03, 0.32), Color("e8eef8"), 3, 18)
			k.outline = 0.0
			for at: Vector2 in [Vector2(0.14, 0.0), Vector2(-0.14, 0.06), Vector2(0.0, -0.17), Vector2(-0.04, 0.17)]:
				k.ball(Vector3(at.x, 0.03, at.y), Vector3(0.07, 0.008, 0.07), Color("8a98ac"), 2, 8)
			k.outline = 0.02
			k.pop()
			k.torus(Vector3(0, -0.34, -0.2), 0.32, 0.02, Color("3a6aff"), 18, 4)
			k.torus(Vector3(0, -0.14, -0.2), 0.32, 0.02, Color("ffd23f"), 18, 4)
		"sitar":
			k.push(Transform3D(Basis(Vector3.BACK, -0.26), Vector3(0, -0.32, -0.16)))
			k.ball(Vector3.ZERO, Vector3(0.24, 0.26, 0.14), Color("c98c4a"), 10, 14)
			k.outline = 0.0
			k.ball(Vector3(0, 0, -0.135), Vector3(0.14, 0.15, 0.01), Color("e8483f"), 3, 12)
			k.outline = 0.02
			k.soft_box(Vector3(0, 0.72, 0), Vector3(0.04, 0.54, 0.024), WOOD, 0.7, 3, 6)
			k.ball(Vector3(0, 1.0, -0.07), Vector3(0.09, 0.1, 0.07), Color("c98c4a"), 6, 9)
			for f: float in [0.4, 0.6, 0.8, 1.0]:
				k.ball(Vector3(0.05, f, 0), Vector3(0.016, 0.016, 0.03), GOLD, 2, 5)
			k.pop()
		"koi_streamer":
			_pole_end(k, end, 2.0, Color("c98c4a"))
			k.ball(end + Vector3(0, 1.9, 0), Vector3(0.05, 0.05, 0.05), GOLD, 4, 7)
			var at := end + Vector3(0.04, 1.62, 0)
			var red := Color("e8483f")
			k.ball(at + Vector3(0.26, 0, 0), Vector3(0.3, 0.17, 0.15), red, 8, 12)
			k.ball(at + Vector3(0.62, -0.02, 0), Vector3(0.24, 0.13, 0.11), Color("fff6dd"), 7, 10)
			k.ball(at + Vector3(0.9, -0.05, 0), Vector3(0.16, 0.09, 0.07), red, 6, 9)
			k.outline = 0.0
			for z: float in [0.13, -0.13]:
				k.ball(at + Vector3(0.1, 0.03, z), Vector3(0.05, 0.05, 0.02), Color.WHITE, 3, 7)
				k.ball(at + Vector3(0.08, 0.03, z * 1.1), Vector3(0.022, 0.022, 0.012), INK, 2, 6)
			k.outline = 0.02
			k.cone(at + Vector3(1.0, -0.05, 0), 0.2, 0.1, red, 6)
		"parasol":
			var pink := Color("ff6fb5")
			k.push(Transform3D(Basis(Vector3.BACK, 0.3) * Basis(Vector3.RIGHT, -0.5), Vector3(0.0, 0.14, -0.2)))
			k.cyl(Vector3(0, -0.6, 0), 1.2, 0.015, 0.015, WOOD, 6)
			k.dome(Vector3(0, 0.3, 0), Vector3(0.86, 0.3, 0.86), pink, 8, 16)
			k.outline = 0.0
			for i in 8:
				var t := TAU * i / 8.0
				k.tube(PackedVector3Array([Vector3(0, 0.605, 0), Vector3(cos(t) * 0.48, 0.555, sin(t) * 0.48), Vector3(cos(t) * 0.84, 0.36, sin(t) * 0.84)]), 0.012, Color("ffd23f"), false, 3)
				k.ball(Vector3(cos(t + 0.39) * 0.5, 0.56, sin(t + 0.39) * 0.5), Vector3(0.07, 0.03, 0.07), Color("fff176"), 2, 6)
			k.outline = 0.02
			k.ball(Vector3(0, 0.62, 0), Vector3(0.04, 0.05, 0.04), GOLD, 4, 6)
			k.pop()
		"wok":
			var iron := Color("2a2438")
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.14, -0.2)))
			k.dome(Vector3.ZERO, Vector3(0.42, 0.15, 0.42), iron, 7, 20)
			k.torus(Vector3.ZERO, 0.42, 0.025, iron.lightened(0.24), 22, 4)
			k.pop()
			k.cyl(Vector3(0, -0.72, -0.2), 0.34, 0.022, 0.03, iron, 7)
			k.cyl(Vector3(0, -0.96, -0.2), 0.26, 0.03, 0.03, WOOD, 7)
		"paella":
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.14, -0.2)))
			k.cyl(Vector3(0, -0.04, 0), 0.06, 0.46, 0.46, Color("6a6a7a"), 22)
			k.ball(Vector3(0, -0.01, 0), Vector3(0.43, 0.02, 0.43), Color("ffc84a"), 3, 20)
			k.outline = 0.0
			for at: Vector3 in [Vector3(0.2, -0.04, 0.1), Vector3(-0.2, -0.04, 0.14), Vector3(0.0, -0.04, -0.22), Vector3(-0.26, -0.04, -0.08), Vector3(0.28, -0.04, -0.12)]:
				k.ball(at, Vector3(0.05, 0.015, 0.07), Color("ff7a6a"), 2, 6)
			for at: Vector3 in [Vector3(0.06, -0.04, 0.26), Vector3(-0.08, -0.04, -0.02), Vector3(0.14, -0.04, -0.24)]:
				k.ball(at, Vector3(0.045, 0.015, 0.03), Color("35b05a"), 2, 6)
			k.outline = 0.02
			k.pop()
			for s: float in [-1.0, 1.0]:
				k.torus(Vector3(s * 0.52, -0.14, -0.2), 0.07, 0.016, Color("6a6a7a"), 10, 3)
		"cuckoo":
			var wood := Color("7a4a26")
			k.soft_box(Vector3(0, -0.18, -0.2), Vector3(0.24, 0.3, 0.1), wood, 0.4, 4, 8)
			k.push(Transform3D(Basis(Vector3.BACK, 0.62), Vector3(-0.14, 0.2, -0.2)))
			k.soft_box(Vector3.ZERO, Vector3(0.26, 0.03, 0.14), wood.darkened(0.2), 0.4, 3, 6)
			k.pop()
			k.push(Transform3D(Basis(Vector3.BACK, -0.62), Vector3(0.14, 0.2, -0.2)))
			k.soft_box(Vector3.ZERO, Vector3(0.26, 0.03, 0.14), wood.darkened(0.2), 0.4, 3, 6)
			k.pop()
			k.ball(Vector3(0, -0.24, -0.31), Vector3(0.14, 0.14, 0.012), Color("fffdf4"), 3, 12)
			k.outline = 0.0
			k.ball(Vector3(0, 0.0, -0.31), Vector3(0.07, 0.07, 0.006), INK, 2, 8)
			k.outline = 0.02
			k.ball(Vector3(0, 0.0, -0.36), Vector3(0.055, 0.055, 0.055), Color("ffd23f"), 4, 7)
			for x: float in [-0.08, 0.08]:
				k.cyl(Vector3(x, -0.72, -0.2), 0.22, 0.008, 0.008, GOLD, 4)
				k.ball(Vector3(x, -0.76, -0.2), Vector3(0.035, 0.07, 0.035), GOLD, 4, 6)
		"nesting_dolls":
			for i in 3:
				var size := 1.0 - i * 0.24
				var x := -0.24 + i * 0.25
				var y := -0.3 - i * 0.05
				var red := Color("e8283f").lerp(Color("3a6aff"), i * 0.5)
				k.ball(Vector3(x, y, -0.2), Vector3(0.16, 0.26, 0.14) * size, red, 8, 10)
				k.ball(Vector3(x, y + 0.24 * size, -0.2), Vector3(0.12, 0.12, 0.12) * size, red, 6, 8)
				k.outline = 0.0
				k.ball(Vector3(x, y + 0.24 * size, -0.2 - 0.11 * size), Vector3(0.08, 0.075, 0.02) * size, Color("ffe6c8"), 3, 7)
				k.ball(Vector3(x, y - 0.06 * size, -0.2 - 0.13 * size), Vector3(0.09, 0.14, 0.012) * size, Color("fff6dd"), 3, 7)
				k.outline = 0.02
		"gondola_oar":
			k.cyl(end + Vector3(0, -0.14, 0), 2.0, 0.022, 0.022, Color("3a2315"), 7)
			k.ball(end + Vector3(0, 1.98, 0), Vector3(0.09, 0.28, 0.018), Color("3a2315"), 5, 9)
			k.outline = 0.0
			for f: float in [0.2, 0.7, 1.2]:
				k.torus(end + Vector3(0, f, 0), 0.024, 0.008, Color("e8283f"), 8, 3)
			k.outline = 0.02
		"lasso":
			var rope := Color("c9985e")
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.14, -0.18)))
			for f: float in [0.0, 0.02, 0.04]:
				k.torus(Vector3(0, -f, 0), 0.3 - f, 0.024, rope, 22, 4)
			k.pop()
		"hockey":
			var stick := Color("f0d8a8")
			k.push(Transform3D(Basis(Vector3.BACK, -0.4), Vector3(0, -0.16, -0.15)))
			k.soft_box(Vector3(0, 0.3, 0), Vector3(0.028, 0.78, 0.018), stick, 0.6, 3, 8)
			k.soft_box(Vector3(0.14, -0.46, 0), Vector3(0.17, 0.05, 0.016), Color("1a1a2a"), 0.6, 3, 6)
			k.pop()
		"cricket":
			k.push(Transform3D(Basis(Vector3.BACK, 0.42), Vector3(0, -0.16, -0.15)))
			k.soft_box(Vector3(0, -0.06, 0), Vector3(0.1, 0.44, 0.04), Color("f0d8a8"), 0.6, 4, 8)
			k.cyl(Vector3(0, 0.36, 0), 0.34, 0.028, 0.028, Color("e8483f"), 7)
			k.pop()
		"skis":
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.08), Vector3(s * 0.12, -0.1, -0.16)))
				k.soft_box(Vector3.ZERO, Vector3(0.05, 0.8, 0.012), Color("e8483f") if s < 0.0 else Color("3a6aff"), 0.7, 3, 8)
				k.push(Transform3D(Basis(Vector3.RIGHT, 0.4), Vector3(0, 0.78, 0)))
				k.soft_box(Vector3(0, 0.06, 0), Vector3(0.05, 0.08, 0.012), Color("e8483f") if s < 0.0 else Color("3a6aff"), 0.7, 3, 6)
				k.pop()
				k.pop()
		"football":
			k.ball(Vector3(0, -0.24, -0.26), Vector3(0.24, 0.24, 0.24), Color("fbfdff"), 10, 16)
			k.outline = 0.0
			for at: Vector3 in [Vector3(0, -0.14, -0.49), Vector3(0.16, -0.32, -0.42), Vector3(-0.16, -0.32, -0.42), Vector3(0.22, -0.1, -0.33), Vector3(-0.22, -0.1, -0.33)]:
				k.ball(at, Vector3(0.05, 0.05, 0.016), Color("1a1a2a"), 3, 6)
			k.outline = 0.02
		"boomerang":
			k.push(Transform3D(Basis(Vector3.BACK, 0.4), Vector3(0, -0.14, -0.17)))
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.75), Vector3.ZERO))
				k.soft_box(Vector3(0, 0.3, 0), Vector3(0.07, 0.34, 0.02), Color("e8933a"), 0.7, 3, 8)
				k.pop()
			k.outline = 0.0
			for f: float in [0.16, 0.34, 0.5]:
				k.ball(Vector3(sin(0.75) * f, cos(0.75) * f, -0.024), Vector3(0.024, 0.024, 0.006), Color("fff6dd"), 2, 5)
			k.outline = 0.02
			k.pop()
		"scroll":
			k.push(Transform3D(Basis(Vector3.BACK, 0.22), Vector3(0, -0.14, -0.19)))
			k.ball(Vector3(0, 0.0, 0), Vector3(0.1, 0.5, 0.1), Color("f4e6c4"), 8, 12)
			k.torus(Vector3(0, 0.0, 0), 0.1, 0.022, Color("e8283f"), 12, 4)
			for y: float in [-0.5, 0.5]:
				k.ball(Vector3(0, y, 0), Vector3(0.05, 0.05, 0.05), WOOD, 4, 7)
			k.pop()
		"explorer_map":
			k.ball(Vector3(0.1, -0.12, -0.17), Vector3(0.08, 0.42, 0.08), Color("f4e6c4"), 8, 10)
			k.ball(Vector3(-0.14, -0.22, -0.2), Vector3(0.18, 0.18, 0.05), GOLD, 7, 14)
			k.outline = 0.0
			k.ball(Vector3(-0.14, -0.22, -0.248), Vector3(0.14, 0.14, 0.006), Color("fffdf4"), 3, 12)
			k.fan(PackedVector3Array([Vector3(-0.14, -0.1, -0.256), Vector3(-0.17, -0.22, -0.256), Vector3(-0.11, -0.22, -0.256)]), Color("e8283f"), Vector3.FORWARD)
			k.fan(PackedVector3Array([Vector3(-0.14, -0.34, -0.256), Vector3(-0.11, -0.22, -0.256), Vector3(-0.17, -0.22, -0.256)]), Color("2a2438"), Vector3.FORWARD)
			k.outline = 0.02
