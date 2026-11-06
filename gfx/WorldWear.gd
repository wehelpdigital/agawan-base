class_name WorldWear
extends RefCounted
## Hats, masks and backs from the world collection and the silly shelf. Same rules as the others: a hat is made to sit
## on the standard head with its rim at y = 0 and radius about 0.585; a mask lies on AvatarParts.M; a back hangs from
## the shoulders, with its top at y = 0.13 and its depth going toward -z.

const CREAM := Color("fff6dd")
const GOLD := Color("ffc21f")
const INK := Color("0a1426")


static func hat(k: MeshKit, id: String) -> void:
	match id:
		"beret":
			var navy := Color("2f3f9c")
			k.push(Transform3D(Basis(Vector3.BACK, -0.14), Vector3(0.02, 0.0, 0)))
			k.torus(Vector3(0, 0.03, 0), 0.56, 0.04, navy.darkened(0.2), 28, 6)
			k.ball(Vector3(0.05, 0.2, 0), Vector3(0.7, 0.17, 0.66), navy, 10, 26)
			k.cyl(Vector3(0.05, 0.34, 0), 0.08, 0.03, 0.02, navy.darkened(0.2), 8)
			k.pop()
		"fez":
			var red := Color("d42a2a")
			k.cyl(Vector3.ZERO, 0.46, 0.53, 0.37, red, 24)
			k.torus(Vector3(0, 0.02, 0), 0.53, 0.025, red.darkened(0.2), 24, 6)
			k.ball(Vector3(0, 0.46, 0), Vector3(0.37, 0.025, 0.37), red, 6, 20)
			k.tube(PackedVector3Array([Vector3(0, 0.48, 0), Vector3(0.2, 0.47, 0.05), Vector3(0.34, 0.34, 0.1), Vector3(0.39, 0.18, 0.12)]), 0.012, INK, false, 5)
			k.ball(Vector3(0.39, 0.13, 0.12), Vector3(0.05, 0.08, 0.05), INK, 6, 8)
		"nonla":
			var straw := Color("f0d27a")
			k.cone(Vector3(0, 0.0, 0), 0.72, 0.98, straw, 32)
			k.torus(Vector3(0, 0.0, 0), 0.98, 0.022, straw.darkened(0.2), 36, 6)
			k.outline = 0.0
			for f: float in [0.28, 0.52, 0.76]:
				k.torus(Vector3(0, 0.72 * (1.0 - f), 0), 0.98 * f, 0.008, straw.darkened(0.2), 28, 4)
			k.outline = 0.02
		"hachimaki":
			var white := Color("fffdf4")
			k.torus(Vector3(0, 0.08, 0), 0.565, 0.05, white, 32, 8)
			AvatarParts._knot(k, 0.08, -0.61, white)
			k.outline = 0.0
			k.ball(Vector3(0, 0.08, 0.6), Vector3(0.09, 0.09, 0.03), Color("e8282f"), 6, 14)
			k.outline = 0.02
		"kabuto":
			var navy := Color("283a7a")
			k.dome(Vector3.ZERO, Vector3(0.6, 0.46, 0.6), navy)
			for i in 5:  # The neck guard, in stepped plates.
				k.ball(Vector3(0, -0.02 - i * 0.08, -0.32 - i * 0.03), Vector3(0.64 + i * 0.03, 0.05, 0.36), navy.lightened(0.05 * (i % 2)), 6, 18)
			k.torus(Vector3(0, 0.06, 0), 0.6, 0.035, GOLD, 28, 6)
			k.ball(Vector3(0, 0.52, 0), Vector3(0.08, 0.05, 0.08), GOLD, 6, 10)
			for s: float in [-1.0, 1.0]:  # Two great gold horns.
				k.tube(PackedVector3Array([Vector3(s * 0.08, 0.22, 0.56), Vector3(s * 0.28, 0.42, 0.6), Vector3(s * 0.44, 0.72, 0.56), Vector3(s * 0.4, 0.98, 0.5)]), 0.05, GOLD, false, 8, 0.015)
			k.ball(Vector3(0, 0.22, 0.58), Vector3(0.09, 0.09, 0.03), Color("e8282f"), 6, 12)
		"gat":
			var black := Color("1d1a30")
			k.ball(Vector3(0, 0.02, 0), Vector3(1.0, 0.025, 1.0), black, 6, 32)
			k.torus(Vector3(0, 0.02, 0), 0.98, 0.02, black.lightened(0.15), 36, 5)
			k.cyl(Vector3.ZERO, 0.56, 0.42, 0.34, black, 24)
			k.ball(Vector3(0, 0.56, 0), Vector3(0.34, 0.02, 0.34), black, 5, 20)
			k.torus(Vector3(0, 0.1, 0), 0.41, 0.02, GOLD, 22, 5)
		"lantern":
			var red := Color("ee3b34")
			k.cyl(Vector3.ZERO, 0.32, 0.03, 0.03, INK, 6)
			k.ball(Vector3(0, 0.62, 0), Vector3(0.42, 0.34, 0.42), red, 10, 18)
			k.outline = 0.0
			for a: float in [0.0, 0.8, 1.6, 2.4]:
				k.push(Transform3D(Basis(Vector3.UP, a), Vector3(0, 0.62, 0)))
				k.ball(Vector3.ZERO, Vector3(0.43, 0.345, 0.03), red.lightened(0.14), 8, 16)
				k.pop()
			k.outline = 0.02
			for y: float in [0.3, 0.94]:
				k.cyl(Vector3(0, y - 0.03, 0), 0.06, 0.2, 0.2, GOLD, 16)
			k.tube(PackedVector3Array([Vector3(0, 0.28, 0.22), Vector3(0.02, 0.1, 0.3), Vector3(0, -0.04, 0.34)]), 0.02, GOLD, false, 5)
		"nemes":
			var blue := Color("2f5fd0")
			k.dome(Vector3.ZERO, Vector3(0.61, 0.44, 0.61), GOLD)
			k.outline = 0.0
			for y: float in [0.08, 0.2, 0.32]:
				k.band(Vector3.ZERO, Vector3(0.61, 0.44, 0.61), y, y + 0.06, blue, 0.005, 32)
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.56, -0.28, 0.14), Vector3(0.14, 0.42, 0.14), GOLD, 10, 12)
				k.outline = 0.0
				for y: float in [-0.5, -0.32, -0.14]:
					k.ball(Vector3(s * 0.6, y, 0.16), Vector3(0.115, 0.04, 0.115), blue, 4, 10)
				k.outline = 0.02
			k.ball(Vector3(0, -0.22, -0.34), Vector3(0.34, 0.34, 0.2), GOLD, 8, 14)
			k.ball(Vector3(0, 0.3, 0.52), Vector3(0.05, 0.09, 0.05), GOLD.lightened(0.2), 6, 8)
		"ushanka":
			var fur := Color("8a5f3a")
			var fluff := Color("e8d2a8")
			k.dome(Vector3.ZERO, Vector3(0.6, 0.48, 0.6), fur)
			k.torus(Vector3(0, 0.02, 0), 0.6, 0.11, fluff, 28, 8)
			k.ball(Vector3(0, 0.22, 0.54), Vector3(0.34, 0.16, 0.1), fluff, 8, 14)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.56, -0.24, 0.0), Vector3(0.12, 0.26, 0.2), fluff, 10, 12)
		"leprechaun":
			var green := Color("1fa35c")
			k.ball(Vector3(0, 0.12, 0), Vector3(0.74, 0.05, 0.7), green, 8, 26)
			k.cyl(Vector3(0, 0.12, 0), 0.5, 0.4, 0.46, green, 24)
			k.ball(Vector3(0, 0.62, 0), Vector3(0.46, 0.025, 0.46), green, 6, 22)
			k.cyl(Vector3(0, 0.15, 0), 0.12, 0.42, 0.43, INK, 24)
			k.soft_box(Vector3(0, 0.21, 0.42), Vector3(0.09, 0.08, 0.02), GOLD, 0.6, 6, 8)
			for a: float in [0.0, 2.09, 4.19]:  # A clover in the band.
				k.ball(Vector3(0.26, 0.44, 0.36) + Vector3(cos(a), sin(a), 0) * 0.05, Vector3(0.05, 0.05, 0.02), Color("7ed957"), 4, 8)
		"bearskin":
			k.ball(Vector3(0, 0.44, 0), Vector3(0.6, 0.86, 0.6), Color("1d1a30"), 14, 22)
			k.outline = 0.0
			for spot: Vector3 in [Vector3(-0.3, 0.7, 0.42), Vector3(0.2, 0.92, 0.36), Vector3(0.36, 0.42, 0.4), Vector3(-0.1, 0.34, 0.56)]:
				k.ball(spot, Vector3(0.12, 0.18, 0.05), Color("2f2a48"), 4, 8)
			k.outline = 0.02
			k.ball(Vector3(0.48, 0.42, 0.26), Vector3(0.05, 0.18, 0.05), Color("e8282f"), 6, 8)
		"bobby":
			var navy := Color("1f2f6a")
			k.ball(Vector3(0, 0.3, 0), Vector3(0.58, 0.6, 0.58), navy, 12, 22)
			k.torus(Vector3(0, 0.02, 0), 0.6, 0.04, navy.darkened(0.3), 28, 6)
			k.ball(Vector3(0, 0.92, 0), Vector3(0.07, 0.06, 0.07), Color("f0f4ff"), 6, 10)
			k.ball(Vector3(0, 0.34, 0.55), Vector3(0.11, 0.14, 0.03), Color("f0f4ff"), 6, 10)
		"tyrolean":
			var green := Color("3f7a4a")
			k.ball(Vector3(0, 0.05, 0), Vector3(0.8, 0.05, 0.76), green, 8, 26)
			k.dome(Vector3.ZERO, Vector3(0.56, 0.56, 0.56), green)
			k.torus(Vector3(0, 0.08, 0), 0.545, 0.03, Color("c98c4a"), 26, 6)
			k.push(Transform3D(Basis(Vector3.BACK, -0.36), Vector3(0.45, 0.2, 0.18)))
			k.ball(Vector3(0, 0.3, 0), Vector3(0.06, 0.34, 0.02), Color("e8282f"), 8, 10)
			k.pop()
		"laurel":
			var leaf := Color("e0b83a")
			k.torus(Vector3(0, 0.08, 0), 0.565, 0.018, leaf.darkened(0.2), 28, 5)
			for i in 18:
				var a := TAU * i / 18.0
				if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.34:
					continue  # An open front.
				for up: float in [-1.0, 1.0]:
					k.push(Transform3D(Basis(Vector3.UP, PI * 0.5 - a) * Basis(Vector3.BACK, up * 0.6), Vector3(cos(a) * 0.57, 0.08 + up * 0.035, sin(a) * 0.57)))
					k.ball(Vector3(0, 0, 0), Vector3(0.09, 0.03, 0.05), leaf if int(up) > 0 else leaf.lightened(0.14), 4, 7)
					k.pop()
		"tulip":
			var red := Color("ff4f6a")
			k.torus(Vector3(0, 0.04, 0), 0.55, 0.03, Color("35d07f"), 26, 6)
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.5), Vector3(s * 0.22, 0.1, 0)))
				k.ball(Vector3(0, 0.2, 0), Vector3(0.09, 0.3, 0.05), Color("35d07f"), 8, 10)
				k.pop()
			k.cyl(Vector3(0, 0.1, 0), 0.26, 0.04, 0.04, Color("35d07f"), 8)
			for i in 5:
				var a := TAU * i / 5.0
				k.push(Transform3D(Basis(Vector3.UP, -a) * Basis(Vector3.BACK, -0.2), Vector3(cos(a) * 0.14, 0.36, sin(a) * 0.14)))
				k.ball(Vector3(0, 0.2, 0), Vector3(0.15, 0.27, 0.1), red if i % 2 == 0 else red.lightened(0.12), 8, 10)
				k.pop()
		"gaucho":
			var black := Color("2b2448")
			k.ball(Vector3(0, 0.05, 0), Vector3(0.92, 0.04, 0.9), black, 8, 28)
			k.cyl(Vector3(0, 0.05, 0), 0.4, 0.48, 0.44, black, 24)
			k.ball(Vector3(0, 0.45, 0), Vector3(0.44, 0.02, 0.44), black, 5, 22)
			k.cyl(Vector3(0, 0.07, 0), 0.1, 0.49, 0.49, Color("e8c34a"), 24)
		"chullo":
			var colors := [Color("e8483f"), Color("ffd23f"), Color("3aa6ff"), Color("35d07f")]
			k.dome(Vector3.ZERO, Vector3(0.59, 0.5, 0.59), colors[0])
			k.outline = 0.0
			for i in 3:
				k.band(Vector3.ZERO, Vector3(0.59, 0.5, 0.59), 0.06 + i * 0.13, 0.13 + i * 0.13, colors[i + 1], 0.005, 32)
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.54, -0.2, 0.02), Vector3(0.13, 0.26, 0.17), colors[0], 8, 10)
				k.tube(PackedVector3Array([Vector3(s * 0.56, -0.42, 0.02), Vector3(s * 0.56, -0.68, 0.02)]), 0.018, colors[1], false, 5)
				k.ball(Vector3(s * 0.56, -0.72, 0.02), Vector3(0.05, 0.05, 0.05), colors[2], 6, 8)
			k.ball(Vector3(0, 0.52, 0), Vector3(0.11, 0.11, 0.11), colors[1], 8, 10)
		"plume":
			k.torus(Vector3(0, 0.08, 0), 0.565, 0.05, GOLD, 28, 6)
			var colors := [Color("35d07f"), Color("ffd23f"), Color("ff6fb5"), Color("3aa6ff"), Color("ff5a4e")]
			for i in 9:
				var a := lerpf(-1.05, 1.05, i / 8.0)
				k.push(Transform3D(Basis(Vector3.BACK, -a), Vector3(sin(a) * 0.3, 0.2, 0.05)))
				k.ball(Vector3(0, 0.46, 0), Vector3(0.1, 0.5, 0.03), colors[i % 5], 10, 12)
				k.pop()
			k.ball(Vector3(0, 0.16, 0.5), Vector3(0.13, 0.13, 0.05), Color("ff3fb4"), 8, 12)
			k.ball(Vector3(0, 0.16, 0.54), Vector3(0.06, 0.06, 0.03), GOLD, 6, 8)
		"mountie":
			var tan := Color("c9985e")
			k.ball(Vector3(0, 0.04, 0), Vector3(0.94, 0.03, 0.94), tan, 8, 32)
			k.dome(Vector3.ZERO, Vector3(0.54, 0.6, 0.54), tan)
			k.outline = 0.0
			for a: float in [0.0, PI * 0.5, PI, PI * 1.5]:
				k.ball(Vector3(cos(a), 0, sin(a)) * 0.22 + Vector3(0, 0.5, 0), Vector3(0.12, 0.09, 0.12), tan.darkened(0.18), 4, 8)
			k.outline = 0.02
			k.torus(Vector3(0, 0.08, 0), 0.53, 0.03, Color("6a4a2a"), 28, 6)
			k.ball(Vector3(0, 0.1, 0.53), Vector3(0.05, 0.06, 0.02), GOLD, 4, 8)
		"akubra":
			var tan := Color("b5915a")
			k.ball(Vector3(0, 0.05, 0), Vector3(0.94, 0.04, 0.9), tan, 8, 30)
			k.dome(Vector3.ZERO, Vector3(0.56, 0.48, 0.56), tan)
			k.torus(Vector3(0, 0.08, 0), 0.55, 0.03, Color("6a4a2a"), 28, 6)
			for i in 7:
				var a := TAU * i / 7.0 + 0.2
				var at := Vector3(cos(a) * 0.88, 0.03, sin(a) * 0.84)
				k.tube(PackedVector3Array([at, at + Vector3(0, -0.2, 0)]), 0.006, INK, false, 4)
				k.ball(at + Vector3(0, -0.24, 0), Vector3(0.035, 0.055, 0.035), Color("e0c08a"), 4, 7)
		"lei_hat":
			var colors := [Color("ff6fb5"), Color("ffd23f"), Color("ff9d2e"), Color("ffffff")]
			for i in 14:
				var a := TAU * i / 14.0
				k.ball(Vector3(cos(a) * 0.58, 0.08, sin(a) * 0.58), Vector3(0.095, 0.07, 0.095), colors[i % 4], 6, 10)
			k.ball(Vector3(0.42, 0.24, 0.36), Vector3(0.14, 0.12, 0.05), Color("ff5a7a"), 6, 10)
			k.ball(Vector3(0.42, 0.24, 0.4), Vector3(0.05, 0.05, 0.03), Color("ffd23f"), 4, 7)
		"cat_ears", "bunny_ears":
			var cat: bool = id == "cat_ears"
			var fur := Color("ff9d2e") if cat else Color("fffdf4")
			var pink := Color("ffc2d0")
			var arch := PackedVector3Array()
			for i in 17:
				var a := lerpf(-1.45, 1.45, i / 16.0)
				arch.append(Vector3(sin(a) * 0.6, -0.14 + cos(a) * 0.56, 0.0))
			k.tube(arch, 0.024, fur.darkened(0.1))
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.24), Vector3(s * 0.33, 0.27, 0)))
				if cat:
					k.cone(Vector3.ZERO, 0.32, 0.17, fur, 12)
					k.outline = 0.0
					k.push(Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.05)))
					k.cone(Vector3(0, 0.02, 0), 0.22, 0.09, pink, 10)
					k.pop()
					k.outline = 0.02
				else:
					k.ball(Vector3(0, 0.36, 0), Vector3(0.1, 0.4, 0.06), fur, 10, 12)
					k.outline = 0.0
					k.ball(Vector3(0, 0.36, 0.05), Vector3(0.05, 0.3, 0.02), pink, 6, 10)
					k.outline = 0.02
				k.pop()
		"sprout":
			var green := Color("6ccf5a")
			k.tube(PackedVector3Array([Vector3(0, 0.34, 0), Vector3(0.01, 0.46, 0), Vector3(0, 0.56, 0)]), 0.022, green.darkened(0.15), false, 6)
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.5), Vector3(s * 0.05, 0.57, 0)))
				k.ball(Vector3(s * 0.13, 0.03, 0), Vector3(0.14, 0.07, 0.09), green, 8, 12)
				k.pop()
		"traffic_cone":
			var orange := Color("ff7a1f")
			k.soft_box(Vector3(0, 0.3, 0), Vector3(0.44, 0.03, 0.44), INK.lightened(0.2), 0.6, 4, 12)
			k.cone(Vector3(0, 0.32, 0), 0.88, 0.32, orange, 18)
			k.outline = 0.0
			for f: float in [0.28, 0.56]:
				k.cyl(Vector3(0, 0.32 + 0.88 * f, 0), 0.1, 0.32 * (1.0 - f) + 0.006, 0.32 * (1.0 - f - 0.114) + 0.006, Color.WHITE, 18)
			k.outline = 0.02
		"hardhat", "fire_helmet":
			var hard: bool = id == "hardhat"
			var c := Color("ffc21f") if hard else Color("e8282f")
			k.dome(Vector3.ZERO, Vector3(0.6, 0.46, 0.6), c)
			k.ball(Vector3(0, 0.03, 0), Vector3(0.72, 0.04, 0.72), c, 8, 28)
			k.ball(Vector3(0, 0.3, 0), Vector3(0.09, 0.2, 0.46), c.lightened(0.12), 8, 12)
			if not hard:
				k.ball(Vector3(0, 0.02, -0.5), Vector3(0.56, 0.05, 0.42), c.darkened(0.12), 6, 18)
				k.soft_box(Vector3(0, 0.3, 0.58), Vector3(0.14, 0.16, 0.02), GOLD, 0.55, 6, 10)
		"grad_cap":
			var black := Color("1d1a30")
			k.dome(Vector3.ZERO, Vector3(0.56, 0.32, 0.56), black)
			k.soft_box(Vector3(0, 0.34, 0), Vector3(0.72, 0.025, 0.72), black, 0.7, 4, 12)
			k.ball(Vector3(0, 0.37, 0), Vector3(0.05, 0.02, 0.05), GOLD, 4, 8)
			k.tube(PackedVector3Array([Vector3(0, 0.37, 0), Vector3(0.36, 0.37, 0.3), Vector3(0.6, 0.34, 0.5), Vector3(0.62, 0.06, 0.52)]), 0.012, GOLD, false, 5)
			k.ball(Vector3(0.62, 0.02, 0.52), Vector3(0.04, 0.08, 0.04), GOLD, 6, 8)
		"mushroom":
			var red := Color("ff5a4e")
			k.ball(Vector3(0, 0.1, 0), Vector3(0.72, 0.06, 0.72), CREAM, 8, 28)
			k.dome(Vector3(0, 0.1, 0), Vector3(0.76, 0.58, 0.76), red, 12, 28)
			k.outline = 0.0
			for spot: Vector3 in [Vector3(0, 0.66, 0), Vector3(0.42, 0.42, 0.26), Vector3(-0.44, 0.4, 0.2), Vector3(0.05, 0.36, 0.62), Vector3(-0.2, 0.42, -0.5), Vector3(0.36, 0.34, -0.48)]:
				k.ball(spot, Vector3(0.13, 0.08, 0.13), CREAM, 4, 9)
			k.outline = 0.02
		"burger":
			k.ball(Vector3(0, 0.08, 0), Vector3(0.6, 0.08, 0.6), Color("e8b469"), 8, 24)
			k.cyl(Vector3(0, 0.13, 0), 0.1, 0.56, 0.56, Color("7a4a26"), 22)
			k.ball(Vector3(0, 0.25, 0), Vector3(0.64, 0.035, 0.64), Color("7ed957"), 6, 22)
			k.ball(Vector3(0, 0.28, 0), Vector3(0.6, 0.03, 0.6), Color("ffd23f"), 6, 22)
			k.dome(Vector3(0, 0.3, 0), Vector3(0.6, 0.38, 0.6), Color("f0b860"), 10, 24)
			k.outline = 0.0
			for i in 7:
				var a := TAU * i / 7.0
				k.ball(Vector3(cos(a) * 0.3, 0.6, sin(a) * 0.3), Vector3(0.05, 0.02, 0.03), CREAM, 3, 6)
			k.outline = 0.02
		"sushi":
			k.soft_box(Vector3(0, 0.14, 0), Vector3(0.42, 0.14, 0.26), Color("fffdf4"), 0.65, 8, 14)
			k.soft_box(Vector3(0, 0.34, 0), Vector3(0.5, 0.08, 0.3), Color("ff8a6a"), 0.75, 6, 14)
			k.outline = 0.0
			for x: float in [-0.28, -0.08, 0.12, 0.32]:
				k.push(Transform3D(Basis(Vector3.UP, 0.5), Vector3(x, 0.415, 0)))
				k.ball(Vector3.ZERO, Vector3(0.03, 0.01, 0.2), Color("ffc4a8"), 3, 6)
				k.pop()
			k.outline = 0.02
			k.soft_box(Vector3(0, 0.26, 0), Vector3(0.09, 0.17, 0.32), Color("1d2a2a"), 0.8, 6, 10)
		"pizza_hat":
			k.push(Transform3D(Basis(Vector3.RIGHT, 0.25), Vector3(0, 0.34, 0)))
			var pts := PackedVector3Array([Vector3(0, 0, 0.72), Vector3(0.55, 0, -0.4), Vector3(-0.55, 0, -0.4)])
			k.fan(PackedVector3Array([pts[2], pts[0], pts[1]]), Color("ffd23f"), Vector3.UP)
			k.tube(PackedVector3Array([Vector3(-0.58, 0, -0.38), Vector3(-0.3, 0.03, -0.48), Vector3(0, 0.04, -0.52), Vector3(0.3, 0.03, -0.48), Vector3(0.58, 0, -0.38)]), 0.07, Color("d99a4e"), false, 8)
			for at: Vector3 in [Vector3(0.05, 0.02, 0.32), Vector3(-0.2, 0.02, -0.12), Vector3(0.22, 0.02, -0.16)]:
				k.ball(at, Vector3(0.12, 0.022, 0.12), Color("e8483f"), 4, 10)
			k.pop()
			k.ball(Vector3(0, 0.16, 0), Vector3(0.28, 0.17, 0.28), Color("ffd23f"), 6, 12)
		"duck":
			var yellow := Color("ffe05c")
			k.ball(Vector3(0, 0.46, -0.02), Vector3(0.34, 0.24, 0.42), yellow, 10, 16)
			k.ball(Vector3(0, 0.78, 0.2), Vector3(0.22, 0.22, 0.22), yellow, 10, 14)
			k.ball(Vector3(0, 0.76, 0.42), Vector3(0.11, 0.05, 0.1), Color("ff9d2e"), 6, 10)
			k.outline = 0.0
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.1, 0.84, 0.385), Vector3(0.028, 0.034, 0.016), INK, 4, 7)
			k.outline = 0.02
			k.ball(Vector3(0, 0.56, -0.42), Vector3(0.08, 0.1, 0.08), yellow.darkened(0.08), 6, 8)
		"cactus_hat":
			var green := Color("4cbc5e")
			k.cyl(Vector3(0, 0.28, 0), 0.14, 0.2, 0.24, Color("d9703f"), 14)
			k.ball(Vector3(0, 0.64, 0), Vector3(0.16, 0.3, 0.16), green, 10, 12)
			for s: float in [-1.0, 1.0]:
				k.tube(PackedVector3Array([Vector3(s * 0.12, 0.6, 0), Vector3(s * 0.28, 0.62, 0), Vector3(s * 0.28, 0.8, 0)]), 0.06, green, false, 8, 0.045)
			k.ball(Vector3(0, 0.96, 0), Vector3(0.08, 0.06, 0.08), Color("ff6fb5"), 6, 8)
		"antlers":
			var horn := Color("a8743c")
			var arch := PackedVector3Array()
			for i in 17:
				var a := lerpf(-1.42, 1.42, i / 16.0)
				arch.append(Vector3(sin(a) * 0.6, -0.14 + cos(a) * 0.56, 0.0))
			k.tube(arch, 0.024, Color("e8282f"))
			for s: float in [-1.0, 1.0]:
				k.tube(PackedVector3Array([Vector3(s * 0.34, 0.3, 0), Vector3(s * 0.46, 0.56, 0), Vector3(s * 0.66, 0.82, 0)]), 0.05, horn, false, 8, 0.024)
				k.tube(PackedVector3Array([Vector3(s * 0.46, 0.56, 0), Vector3(s * 0.28, 0.76, 0), Vector3(s * 0.24, 0.92, 0)]), 0.035, horn, false, 6, 0.018)
				k.tube(PackedVector3Array([Vector3(s * 0.56, 0.68, 0), Vector3(s * 0.8, 0.64, 0), Vector3(s * 0.94, 0.7, 0)]), 0.032, horn, false, 6, 0.016)
		"shark":
			var blue := Color("6f95c8")
			k.dome(Vector3.ZERO, Vector3(0.6, 0.46, 0.6), blue)
			k.push(Transform3D(Basis(Vector3.RIGHT, -0.32), Vector3(0, 0.36, -0.06)))
			k.ball(Vector3(0, 0.26, 0), Vector3(0.05, 0.34, 0.24), blue.darkened(0.1), 10, 12)
			k.pop()
			k.outline = 0.0
			for i in 11:
				var a := lerpf(-0.9, 0.9, i / 10.0) + PI * 0.5
				k.push(Transform3D(Basis(Vector3.RIGHT, PI), Vector3(cos(a) * 0.61, 0.03, sin(a) * 0.61)))
				k.cone(Vector3.ZERO, 0.13, 0.05, Color.WHITE, 6)
				k.pop()
			k.outline = 0.02
		"dino":
			var green := Color("6ccf5a")
			k.dome(Vector3.ZERO, Vector3(0.6, 0.46, 0.6), green)
			for i in 7:  # A crest over the head from ear to ear, so you see it from the front as well as the side.
				var a := lerpf(-1.05, 1.05, i / 6.0)
				k.push(Transform3D(Basis(Vector3.BACK, -a), Vector3(sin(a) * 0.56, cos(a) * 0.44 - 0.02, 0.04)))
				k.cone(Vector3.ZERO, 0.3 - absf(a) * 0.08, 0.1, Color("ffb21f"), 10)
				k.pop()
		"disco":
			k.cyl(Vector3(0, 0.3, 0), 0.26, 0.012, 0.012, INK, 5)
			k.ball(Vector3(0, 0.8, 0), Vector3(0.3, 0.3, 0.3), Color("cfe0ff"), 10, 18)
			k.outline = 0.0
			var colours := [Color("ff6fb5"), Color("7ee8ff"), Color("ffd23f"), Color("ffffff"), Color("b768ff")]
			for lat in 5:
				for lon in 10:
					var a := TAU * (lon + 0.5 * (lat % 2)) / 10.0
					var e := lerpf(-1.0, 1.0, lat / 4.0)
					var at := Vector3(cos(a) * cos(e), sin(e), sin(a) * cos(e)) * 0.3
					k.ball(Vector3(0, 0.8, 0) + at, Vector3.ONE * 0.042, colours[(lat * 3 + lon) % 5], 2, 5)
			k.outline = 0.02
		"rainbow_hat":
			var colours := [Color("ff5a5a"), Color("ffb52e"), Color("fff176"), Color("5be36a"), Color("3aa6ff"), Color("b768ff")]
			for i in 6:
				var r := 0.62 - i * 0.075
				var arc := PackedVector3Array()
				for j in 17:
					var a := lerpf(0.0, PI, j / 16.0)
					arc.append(Vector3(cos(a) * r, 0.32 + sin(a) * r * 0.9, 0.0))
				k.tube(arc, 0.042, colours[i], false, 6)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.46, 0.32, 0), Vector3(0.24, 0.14, 0.16), Color.WHITE, 8, 12)
		_:
			CultureWear.hat(k, id)


static func mask(k: MeshKit, id: String, hatted := false) -> void:
	var M := AvatarParts.M
	var W := AvatarParts.W
	match id:
		"carnival", "samba":
			var venice: bool = id == "carnival"
			var c := Color("2f4fd0") if venice else Color("35d07f")
			var trim := GOLD if venice else Color("ff6fb5")
			k.cap(Vector3.ZERO, M, c, 0.98, 0.34, AvatarParts.EYE_LAT, 0.02, trim)
			for s: float in [-1.0, 1.0]:
				AvatarParts._paint(k, s * 0.2, -0.03, 0.095, 0.08, Color("fff8ea"), M, 0.004)
				AvatarParts._paint(k, s * 0.36, 0.06, 0.05, 0.05, trim, M, 0.006)
			AvatarParts._eyes_on(k, -0.03, 0.2, 0.06, AvatarParts.DARK, M, 0.006)
			if not hatted:
				var plumes := [Color("ff6fb5"), GOLD, Color("7ee8ff")] if venice else [Color("ffd23f"), Color("ff6fb5"), Color("3aa6ff")]
				for i in 3:
					k.push(Transform3D(Basis(Vector3.BACK, -0.45 + i * 0.25), Vector3(0.3 + i * 0.03, 0.16, 0.3)))
					k.ball(Vector3(0, 0.28, 0), Vector3(0.06, 0.32, 0.02), plumes[i], 8, 10)
					k.pop()
		"sugar_skull":
			var bone := Color("fbf7ff")
			var dark := AvatarParts.DARK
			AvatarParts._plate(k, bone)
			var colours := [Color("ff6fb5"), Color("3aa6ff"), Color("ffd23f"), Color("35d07f")]
			for s: float in [-1.0, 1.0]:
				AvatarParts._paint(k, s * 0.19, 0.05, 0.125, 0.135, dark, M)
				for i in 7:  # Petals round each eye.
					var a := TAU * i / 7.0
					AvatarParts._paint(k, s * 0.19 + cos(a) * 0.145, 0.05 + sin(a) * 0.155, 0.03, 0.03, colours[i % 4], M, 0.008)
				AvatarParts._paint(k, s * 0.19, 0.05, 0.05, 0.05, colours[1 if s > 0.0 else 0], M, 0.01)
			AvatarParts._paint(k, 0.0, -0.1, 0.04, 0.055, dark, M)
			AvatarParts._paint(k, 0.0, 0.28, 0.06, 0.05, Color("ff5a4e"), M, 0.008)
			for i in 5:
				var a := TAU * i / 5.0
				AvatarParts._paint(k, cos(a) * 0.075, 0.28 + sin(a) * 0.07, 0.034, 0.034, Color("ffd23f"), M, 0.006)
			AvatarParts._smile(k, -0.25, 0.26, 0.04, 0.014, dark, M)
			for i in 7:
				var x := -0.21 + i * 0.07
				AvatarParts._stroke(k, PackedVector2Array([Vector2(x, -0.22 - 0.03 * (1.0 - pow(x / 0.26, 2.0))), Vector2(x, -0.27), Vector2(x, -0.33 - 0.03 * (1.0 - pow(x / 0.26, 2.0)))]), 0.014, dark, M)
		"lion_dance":
			var red := Color("e8282f")
			k.ball(Vector3.ZERO, W * 1.12, red, 18, 28)
			if not hatted:
				k.ball(Vector3(0, 0.52, 0.0), Vector3(0.34, 0.2, 0.32), GOLD, 10, 16)
				k.cone(Vector3(0, 0.66, 0.0), 0.26, 0.1, Color("ff9d2e"), 10)
			var white := Color("fffdf4")
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.25, 0.14, 0.42), Vector3(0.18, 0.18, 0.13), white, 8, 12)
				k.ball(Vector3(s * 0.25, 0.14, 0.53), Vector3(0.09, 0.11, 0.04), INK, 6, 10)
				k.ball(Vector3(s * 0.46, 0.34, 0.24), Vector3(0.2, 0.09, 0.14), Color.WHITE, 8, 10)
				k.ball(Vector3(s * 0.6, 0.02, 0.05), Vector3(0.1, 0.22, 0.2), GOLD, 8, 10)
				k.ball(Vector3(s * 0.36, -0.42, 0.26), Vector3(0.14, 0.12, 0.12), Color.WHITE, 6, 10)
			k.ball(Vector3(0, -0.06, 0.52), Vector3(0.18, 0.13, 0.13), Color("ff9d2e"), 8, 12)
			k.ball(Vector3(0, -0.34, 0.42), Vector3(0.32, 0.12, 0.17), Color("7a1020"), 8, 14)
			k.ball(Vector3(0, -0.32, 0.5), Vector3(0.22, 0.05, 0.09), Color("fffdf4"), 6, 12)
			k.tube(PackedVector3Array([Vector3(-0.36, -0.2, 0.34), Vector3(0, -0.14, 0.5), Vector3(0.36, -0.2, 0.34)]), 0.05, GOLD, false, 8)
		"hahoe":
			var wood := Color("e0b98a")
			AvatarParts._plate(k, wood)
			for s: float in [-1.0, 1.0]:
				AvatarParts._smile(k, 0.13, 0.13, -0.09, 0.03, Color("3a2315"))  # Laughing brows.
				var eye := PackedVector2Array()
				for i in 9:
					var f := lerpf(-1.0, 1.0, i / 8.0)
					eye.append(Vector2(s * 0.2 + f * 0.11, 0.0 + 0.045 * (1.0 - f * f)))
				AvatarParts._stroke(k, eye, 0.028, Color("3a2315"))
				AvatarParts._paint(k, s * 0.33, -0.14, 0.09, 0.07, Color("ff9a8a"), M)
			k.ball(Vector3(0, -0.08, AvatarParts._z(0, -0.08)), Vector3(0.07, 0.09, 0.06), wood.darkened(0.08), 8, 10)
			AvatarParts._smile(k, -0.24, 0.26, 0.09, 0.05, Color("3a2315"))
		"tengu":
			var red := Color("d43a2a")
			AvatarParts._plate(k, red)
			for s: float in [-1.0, 1.0]:
				var brow := PackedVector2Array()
				for i in 7:
					var f := i / 6.0
					brow.append(Vector2(s * lerpf(0.07, 0.36, f), 0.13 + f * 0.1))
				AvatarParts._stroke(k, brow, 0.04, Color("fffdf4"))
			AvatarParts._eyes_on(k, 0.04, 0.2, 0.07, Color("fff176"), M, 0.004)
			AvatarParts._eyes_on(k, 0.04, 0.2, 0.035, AvatarParts.DARK, M, 0.01)
			var nose := PackedVector3Array()
			for i in 7:
				var f := i / 6.0
				nose.append(Vector3(0, -0.02 - 0.03 * f, AvatarParts._z(0, -0.02) - 0.03 + 0.46 * f))
			k.tube(nose, 0.085, red.lightened(0.08), false, 12, 0.05)
			AvatarParts._smile(k, -0.25, 0.2, 0.05, 0.02, Color("3a0f12"))
			AvatarParts._smile(k, -0.34, 0.14, 0.03, 0.03, Color("fffdf4"))
		"comedy":
			var white := Color("fbf7ff")
			AvatarParts._plate(k, white)
			for s: float in [-1.0, 1.0]:
				var eye := PackedVector2Array()
				for i in 9:
					var f := lerpf(-1.0, 1.0, i / 8.0)
					eye.append(Vector2(s * 0.2 + f * 0.1, 0.03 + 0.05 * (1.0 - f * f)))
				AvatarParts._stroke(k, eye, 0.035, AvatarParts.DARK)
				AvatarParts._paint(k, s * 0.33, -0.1, 0.07, 0.05, Color("ffb3c7"), M)
			var mouth := PackedVector2Array()
			for i in 17:
				var a := PI + PI * i / 16.0
				mouth.append(Vector2(cos(a) * 0.2, -0.17 + sin(a) * 0.14))
			var pts := PackedVector3Array()
			for point: Vector2 in mouth:
				pts.append(Vector3(point.x, point.y, AvatarParts._z(point.x, point.y) + 0.012))
			k.outline = 0.0
			k.fan(pts, AvatarParts.DARK)
			k.outline = 0.02
		"pharaoh":
			var blue := Color("2f5fd0")
			k.ball(Vector3.ZERO, W, GOLD, 18, 28)
			k.outline = 0.0
			for y: float in [0.34, 0.26, 0.18]:
				k.band(Vector3.ZERO, W, y, y + 0.04, blue, 0.004, 32)
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.46, -0.18, 0.05), Vector3(0.12, 0.34, 0.13), GOLD, 10, 12)
				AvatarParts._paint(k, s * 0.2, 0.03, 0.12, 0.06, INK, W)
				AvatarParts._paint(k, s * 0.2, 0.03, 0.09, 0.04, Color.WHITE, W, 0.008)
			AvatarParts._eyes_on(k, 0.03, 0.2, 0.04, AvatarParts.DARK, W, 0.012)
			k.ball(Vector3(0, -0.04, AvatarParts._z(0, -0.04, W)), Vector3(0.05, 0.08, 0.05), GOLD.lightened(0.14), 6, 10)
			AvatarParts._smile(k, -0.19, 0.11, 0.02, 0.018, Color("a86a0a"), W)
			k.ball(Vector3(0, -0.5, 0.2), Vector3(0.05, 0.14, 0.05), blue, 6, 10)
			if not hatted:
				k.ball(Vector3(0, 0.46, 0.2), Vector3(0.05, 0.11, 0.05), GOLD.lightened(0.2), 6, 8)
		"aviator":
			var strap := Color("7a4a26")
			var ring := PackedVector3Array()
			for i in 29:
				var a := lerpf(PI * 0.5 + 0.8, PI * 2.5 - 0.8, i / 28.0)
				ring.append(Vector3(cos(a) * M.x * 1.012, 0.0, sin(a) * M.z * 1.012))
			k.tube(ring, 0.024, strap)
			for s: float in [-1.0, 1.0]:
				var x := s * 0.2
				k.push(Transform3D(Basis(Vector3.UP, s * 0.42), Vector3(x, -0.01, AvatarParts._z(x, -0.01) + 0.03)))
				k.ball(Vector3.ZERO, Vector3(0.15, 0.15, 0.03), Color("c98c4a"), 6, 14)
				k.ball(Vector3(0, 0, 0.012), Vector3(0.115, 0.115, 0.03), Color("9fe6ff"), 6, 14)
				k.outline = 0.0
				k.ball(Vector3(-0.04, 0.05, 0.04), Vector3(0.03, 0.02, 0.006), Color.WHITE, 3, 6)
				k.outline = 0.02
				k.pop()
		"vr":
			var white := Color("f4f6ff")
			k.cap(Vector3.ZERO, M * 1.01, white, 0.92, 0.36, AvatarParts.EYE_LAT, 0.024, INK)
			k.soft_box(Vector3(0, -0.03, AvatarParts._z(0, 0) + 0.05), Vector3(0.36, 0.17, 0.09), white, 0.6, 8, 14)
			k.outline = 0.0
			k.soft_box(Vector3(0, -0.03, AvatarParts._z(0, 0) + 0.135), Vector3(0.28, 0.11, 0.012), INK, 0.6, 4, 10)
			k.ball(Vector3(-0.15, 0.0, AvatarParts._z(0, 0) + 0.15), Vector3(0.04, 0.02, 0.006), Color("27e9ff"), 3, 7)
			k.outline = 0.02
		"disguise":
			var frame := Color("1d1a30")
			for s: float in [-1.0, 1.0]:
				var x := s * 0.2
				k.push(Transform3D(Basis(Vector3.UP, s * 0.42) * Basis(Vector3.RIGHT, PI * 0.5), Vector3(x, 0.0, AvatarParts._z(x, 0.0) + 0.02)))
				k.torus(Vector3.ZERO, 0.125, 0.022, frame, 18, 6)
				k.pop()
				var arm := PackedVector3Array()
				for i in 7:
					var a := lerpf(0.72, 1.55, i / 6.0)
					arm.append(Vector3(s * M.x * 1.012 * sin(a), 0.01, M.z * 1.012 * cos(a)))
				k.tube(arm, 0.015, frame)
				k.ball(Vector3(s * 0.2, 0.16, AvatarParts._z(s * 0.2, 0.16) + 0.015), Vector3(0.13, 0.035, 0.03), frame, 6, 10)
			k.ball(Vector3(0, -0.08, AvatarParts._z(0, -0.08) + 0.08), Vector3(0.1, 0.11, 0.12), Color("ffb08a"), 8, 12)
			var tash := PackedVector2Array()
			for i in 11:
				var f := lerpf(-1.0, 1.0, i / 10.0)
				tash.append(Vector2(f * 0.17, -0.2 - f * f * 0.035))
			AvatarParts._stroke(k, tash, 0.05, frame)
		"moustache":
			var brown := Color("3a2315")
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.22), Vector3(s * 0.13, -0.19, AvatarParts._z(s * 0.13, -0.19) + 0.02)))
				k.ball(Vector3.ZERO, Vector3(0.14, 0.05, 0.03), brown, 8, 12)
				k.pop()
				k.ball(Vector3(s * 0.27, -0.14, AvatarParts._z(s * 0.27, -0.14) + 0.02), Vector3(0.035, 0.035, 0.02), brown, 4, 8)
		"duck_bill":
			var orange := Color("ff9d2e")
			var z := AvatarParts._z(0, -0.18)
			k.ball(Vector3(0, -0.14, z + 0.1), Vector3(0.28, 0.06, 0.2), orange, 8, 14)
			k.ball(Vector3(0, -0.23, z + 0.07), Vector3(0.24, 0.045, 0.16), orange.darkened(0.14), 8, 14)
			k.outline = 0.0
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.06, -0.09, z + 0.2), Vector3(0.018, 0.012, 0.015), INK, 3, 5)
			k.outline = 0.02
			var strap := PackedVector3Array()
			for i in 27:
				var a := lerpf(PI * 0.5 + 0.5, PI * 2.5 - 0.5, i / 26.0)
				strap.append(Vector3(cos(a) * M.x * 1.012, -0.17, sin(a) * M.z * 1.012))
			k.tube(strap, 0.012, INK)
		"frog":
			var green := Color("6ccf5a")
			k.ball(Vector3.ZERO, W, green, 18, 28)
			k.band(Vector3.ZERO, W, -0.47, -0.2, Color("d8f6a8"), 0.004, 32, 6)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.24, 0.4, 0.2), Vector3(0.17, 0.17, 0.15), green, 10, 12)
				k.ball(Vector3(s * 0.24, 0.42, 0.31), Vector3(0.12, 0.12, 0.05), Color.WHITE, 6, 10)
				k.ball(Vector3(s * 0.24, 0.42, 0.355), Vector3(0.07, 0.075, 0.02), INK, 4, 8)
				AvatarParts._paint(k, s * 0.34, -0.1, 0.07, 0.05, Color("ff9fb5"), W)
			AvatarParts._smile(k, -0.16, 0.37, 0.09, 0.016, INK, W)
		"bear":
			var fur := Color("b5763c")
			k.ball(Vector3.ZERO, W, fur, 18, 28)
			if not hatted:
				for s: float in [-1.0, 1.0]:
					k.ball(Vector3(s * 0.37, 0.4, 0), Vector3(0.15, 0.15, 0.08), fur, 8, 12)
					k.outline = 0.0
					k.ball(Vector3(s * 0.37, 0.4, 0.05), Vector3(0.08, 0.08, 0.05), Color("e6c9a0"), 6, 10)
					k.outline = 0.02
			k.ball(Vector3(0, -0.14, 0.38), Vector3(0.22, 0.17, 0.15), Color("f0dcc0"), 8, 14)
			k.ball(Vector3(0, -0.08, 0.5), Vector3(0.075, 0.055, 0.05), INK, 6, 9)
			AvatarParts._smile(k, -0.22, 0.09, 0.03, 0.012, INK, W, 0.1)
			AvatarParts._eyes_on(k, 0.09, 0.2, 0.07, AvatarParts.DARK, W, 0.006)
		"alien_mask":
			var green := Color("8fffc0")
			k.ball(Vector3(0, 0.05, 0), Vector3(0.58, 0.56, 0.5), green, 18, 28)
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.4), Vector3(s * 0.22, 0.04, AvatarParts._z(s * 0.22, 0.04, W) + 0.02)))
				k.ball(Vector3.ZERO, Vector3(0.14, 0.21, 0.04), INK, 8, 12)
				k.outline = 0.0
				k.ball(Vector3(-0.05, 0.08, 0.035), Vector3(0.03, 0.05, 0.01), Color.WHITE, 3, 6)
				k.outline = 0.02
				k.pop()
				if not hatted:
					k.tube(PackedVector3Array([Vector3(s * 0.16, 0.48, 0.05), Vector3(s * 0.24, 0.66, 0.05), Vector3(s * 0.3, 0.8, 0.05)]), 0.02, green.darkened(0.1), false, 6)
					k.ball(Vector3(s * 0.3, 0.82, 0.05), Vector3(0.05, 0.05, 0.05), Color("ff6fb5"), 6, 8)
			AvatarParts._smile(k, -0.27, 0.05, 0.015, 0.012, INK, W)
		_:
			CultureWear.mask(k, id, hatted)


## Backs. `end` for anything tall comes from the same bracket the balloon and team flag hang from.
static func back(k: MeshKit, id: String, bracket: Vector3) -> void:
	match id:
		"fan":
			var paper := Color("fffdf4")
			var colours := [Color("ff5a4e"), paper]
			k.push(Transform3D(Basis.IDENTITY, Vector3(0, -0.2, -0.1)))
			for i in 9:
				var a := lerpf(-1.25, 1.25, i / 8.0)
				k.push(Transform3D(Basis(Vector3.BACK, -a), Vector3.ZERO))
				k.ball(Vector3(0, 0.34, 0), Vector3(0.1, 0.36, 0.012), colours[i % 2], 6, 10)
				k.pop()
			k.ball(Vector3.ZERO, Vector3(0.05, 0.05, 0.04), GOLD, 6, 8)
			k.pop()
		"banner", "windmill_pack", "hot_air", "kite":
			_tall(k, id, bracket)
		"panda_pack", "koala_hug":
			var panda: bool = id == "panda_pack"
			var fur := Color("fffdf4") if panda else Color("b8c2d8")
			var dark := INK.lightened(0.1) if panda else Color("f4f6ff")
			var y := -0.18
			k.ball(Vector3(0, y, -0.16), Vector3(0.26, 0.28, 0.17), fur, 10, 14)
			k.ball(Vector3(0, y + 0.3, -0.2), Vector3(0.24, 0.21, 0.19), fur, 10, 14)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * (0.2 if panda else 0.25), y + 0.47, -0.2), Vector3(0.09, 0.09, 0.05) * (1.0 if panda else 1.5), dark if panda else fur, 6, 9)
				if panda:
					k.ball(Vector3(s * 0.09, y + 0.3, -0.37), Vector3(0.055, 0.065, 0.02), dark, 4, 7)
				k.ball(Vector3(s * 0.26, y - 0.02, 0.0), Vector3(0.06, 0.06, 0.16), dark if panda else fur, 6, 8)
			k.outline = 0.0
			if not panda:
				for s: float in [-1.0, 1.0]:
					k.ball(Vector3(s * 0.09, y + 0.32, -0.37), Vector3(0.022, 0.022, 0.01), INK, 3, 6)
			k.ball(Vector3(0, y + 0.24, -0.385), Vector3(0.05 if panda else 0.07, 0.035 if panda else 0.08, 0.014), INK, 4, 7)
			k.outline = 0.02
		"baguette":
			k.soft_box(Vector3(0, -0.2, -0.1), Vector3(0.22, 0.24, 0.1), Color("f0f4ff"), 0.6, 8, 12)
			k.outline = 0.0
			k.soft_box(Vector3(0, -0.24, -0.2), Vector3(0.15, 0.1, 0.012), Color("3aa6ff"), 0.6, 4, 8)
			k.outline = 0.02
			for s: float in [-0.1, 0.03, 0.14]:
				k.push(Transform3D(Basis(Vector3.BACK, s * 1.4), Vector3(s, 0.16, -0.12)))
				k.ball(Vector3.ZERO, Vector3(0.05, 0.42, 0.05), Color("e8b469"), 8, 10)
				k.outline = 0.0
				for f: float in [0.15, -0.08]:
					k.ball(Vector3(0, f + 0.08, 0.04), Vector3(0.03, 0.03, 0.012), Color("fff1c9"), 3, 5)
				k.outline = 0.02
				k.pop()
		"bagpipes":
			var tartan := Color("c9302a")
			k.ball(Vector3(0.05, -0.18, -0.16), Vector3(0.26, 0.24, 0.13), tartan, 10, 14)
			k.outline = 0.0
			k.ball(Vector3(0.05, -0.18, -0.28), Vector3(0.18, 0.04, 0.015), Color("1d3f9a"), 3, 8)
			k.ball(Vector3(0.05, -0.18, -0.28), Vector3(0.04, 0.17, 0.015), Color("1d3f9a"), 3, 8)
			k.outline = 0.02
			for i in 3:
				var x := -0.12 + i * 0.13
				k.cyl(Vector3(x, 0.0, -0.2), 0.58 - i * 0.06, 0.028, 0.024, Color("3a2315"), 8)
				k.ball(Vector3(x, 0.59 - i * 0.06, -0.2), Vector3(0.042, 0.042, 0.042), CREAM, 6, 8)
		"viking_shield":
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.2, -0.17)))
			k.cyl(Vector3(0, -0.02, 0), 0.04, 0.4, 0.4, Color("c9302a"), 26)
			k.torus(Vector3.ZERO, 0.4, 0.025, Color("b8c0d8"), 28, 6)
			k.outline = 0.0
			k.cyl(Vector3(0, 0.02, 0), 0.01, 0.4, 0.4, Color("fff6dd"), 4)
			k.outline = 0.02
			k.ball(Vector3(0, 0.03, 0), Vector3(0.11, 0.05, 0.11), Color("b8c0d8"), 6, 10)
			k.pop()
		"carnival_wings":
			var colours := [Color("ffd23f"), Color("35d07f"), Color("ff6fb5"), Color("3aa6ff"), Color("ff5a4e")]
			for s: float in [-1.0, 1.0]:
				for i in 7:
					var a := lerpf(0.2, 1.5, i / 6.0)
					k.push(Transform3D(Basis(Vector3.BACK, s * -a), Vector3(s * 0.1, -0.12, -0.1 - i * 0.008)))
					k.ball(Vector3(0, 0.66 - i * 0.03, 0), Vector3(0.12, 0.66 - i * 0.03, 0.02), colours[i % 5], 8, 10)
					k.outline = 0.0
					k.ball(Vector3(0, 1.1 - i * 0.04, 0.022), Vector3(0.05, 0.06, 0.006), colours[(i + 2) % 5], 3, 7)
					k.outline = 0.02
					k.pop()
		"taco":
			k.push(Transform3D(Basis(Vector3.BACK, 0.18), Vector3(0, -0.14, -0.16)))
			k.ball(Vector3(0, 0.06, 0.03), Vector3(0.5, 0.09, 0.05), Color("7ed957"), 6, 16)
			k.ball(Vector3(0.05, 0.13, 0.03), Vector3(0.42, 0.06, 0.05), Color("ff5a4e"), 6, 14)
			k.ball(Vector3(-0.1, 0.1, 0.03), Vector3(0.3, 0.07, 0.05), Color("ffd23f"), 6, 14)
			k.dome(Vector3(0, -0.14, 0), Vector3(0.52, 0.42, 0.075), Color("f0b860"), 8, 22)
			k.outline = 0.0
			for at: Vector2 in [Vector2(-0.25, 0.0), Vector2(0.1, 0.08), Vector2(0.28, -0.05), Vector2(-0.06, -0.07)]:
				k.ball(Vector3(at.x, at.y, -0.066), Vector3(0.03, 0.03, 0.006), Color("c98c4a"), 3, 6)
			k.outline = 0.02
			k.pop()
		"maple_cape":
			var red := Color("e8282f")
			var cloth: Array[PackedVector3Array] = []
			for i in 11:
				var v := i / 10.0
				var row := PackedVector3Array()
				for j in 11:
					var u := lerpf(-1.0, 1.0, j / 10.0)
					row.append(Vector3(u * lerpf(0.26, 0.5, v), lerpf(0.13, -0.68, v) + pow(absf(u), 4.0) * v * 0.06, -0.03 - 0.26 * v - 0.05 * (1.0 - u * u) + sin(u * 7.0) * 0.022 * v))
				cloth.append(row)
			k.sheet(cloth, red)
			k.outline = 0.0
			var mid: Vector3 = cloth[6][5] + Vector3(0, 0, -0.012)
			for i in 5:
				var a := -PI * 0.5 + (i - 2) * 0.72
				k.push(Transform3D(Basis(Vector3.BACK, a + PI * 0.5), mid))
				k.ball(Vector3(0, 0.1, 0), Vector3(0.05, 0.1, 0.006), Color.WHITE, 3, 7)
				k.pop()
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.22, 0.11, 0.0), Vector3(0.055, 0.055, 0.04), Color.WHITE, 6, 9)
		"surfboard":
			k.push(Transform3D(Basis(Vector3.BACK, -0.32), Vector3(0, -0.1, -0.16)))
			k.ball(Vector3.ZERO, Vector3(0.2, 0.78, 0.035), Color("19b8d6"), 10, 16)
			k.outline = 0.0
			k.ball(Vector3(0, 0, -0.033), Vector3(0.07, 0.74, 0.006), Color("fff6dd"), 4, 12)
			k.ball(Vector3(0, 0.3, -0.036), Vector3(0.14, 0.1, 0.004), Color("ff7a3c"), 4, 12)
			k.outline = 0.02
			k.ball(Vector3(0, -0.6, -0.07), Vector3(0.015, 0.09, 0.05), Color("ff7a3c"), 5, 8)
			k.pop()
		"rocket_pack":
			k.ball(Vector3(0, -0.04, -0.16), Vector3(0.16, 0.42, 0.16), Color("f4f6ff"), 12, 16)
			k.cone(Vector3(0, 0.3, -0.16), 0.24, 0.12, Color("ff5a4e"), 14)
			k.ball(Vector3(0, 0.02, -0.31), Vector3(0.075, 0.075, 0.02), Color("7ee8ff"), 6, 10)
			for a: float in [0.0, 2.09, 4.19]:
				k.push(Transform3D(Basis(Vector3.UP, a), Vector3(0, -0.34, -0.16)))
				k.ball(Vector3(0.17, -0.02, 0), Vector3(0.09, 0.14, 0.02), Color("ff5a4e"), 6, 8)
				k.pop()
			k.outline = 0.0
			k.ball(Vector3(0, -0.5, -0.16), Vector3(0.08, 0.14, 0.08), Color("ffb52e"), 6, 8)
			k.outline = 0.02
		"treasure":
			k.push(Transform3D(Basis.IDENTITY, Vector3(0, -0.5, -0.2)))
			PropKit.draw(k, "chest", Vector3.ZERO, 0.0, 0.5)
			k.pop()
		_:
			CultureWear.back(k, id, bracket)


static func _tall(k: MeshKit, id: String, end: Vector3) -> void:
	var wood := Color("8a5a34")
	match id:
		"banner":
			var red := Color("e8282f")
			k.cyl(end + Vector3(0, -0.14, 0), 2.1, 0.024, 0.024, wood, 8)
			k.tube(PackedVector3Array([end + Vector3(0, 1.94, 0), end + Vector3(0.52, 1.94, 0)]), 0.016, wood, false, 6)
			var cloth: Array[PackedVector3Array] = []
			for i in 7:
				var v := i / 6.0
				var row := PackedVector3Array()
				for j in 6:
					var u := j / 5.0
					row.append(end + Vector3(0.02 + u * 0.5, 1.92 - v * 1.02, sin(v * 6.0) * 0.02))
				cloth.append(row)
			k.sheet(cloth, red, 0.012)
			k.outline = 0.0
			k.ball(end + Vector3(0.27, 1.5, 0.026), Vector3(0.15, 0.15, 0.012), Color("fffdf4"), 4, 16)
			k.ball(end + Vector3(0.27, 1.5, -0.026), Vector3(0.15, 0.15, 0.012), Color("fffdf4"), 4, 16)
			k.outline = 0.02
		"kite":
			var string_path := PackedVector3Array()
			for i in 9:
				var f := i / 8.0
				string_path.append(end + Vector3(sin(f * 5.0) * 0.03, f * 1.6, 0))
			k.tube(string_path, 0.008, Color("fff8ea"), false, 5)
			var at := end + Vector3(0, 2.0, 0)
			k.outline = 0.0
			var pts := PackedVector3Array([at + Vector3(0, 0.42, 0), at + Vector3(0.36, 0, 0), at + Vector3(0, -0.42, 0), at + Vector3(-0.36, 0, 0)])
			k.fan(pts, Color("ff6fb5"), Vector3.BACK)
			k.fan(PackedVector3Array([pts[3], pts[2], pts[1], pts[0]]), Color("ff6fb5"), Vector3.FORWARD)
			var mid := PackedVector3Array([at + Vector3(0, 0.2, 0.002), at + Vector3(0.17, 0, 0.002), at + Vector3(0, -0.2, 0.002), at + Vector3(-0.17, 0, 0.002)])
			k.fan(mid, Color("ffd23f"), Vector3.BACK)
			k.outline = 0.02
			var tail := PackedVector3Array()
			for i in 7:
				var f := i / 6.0
				tail.append(at + Vector3(sin(f * 7.0) * 0.08, -0.42 - f * 0.6, 0))
			k.tube(tail, 0.012, Color("3aa6ff"), false, 5)
		"windmill_pack":
			k.cyl(Vector3(0, -0.5, -0.17), 0.7, 0.2, 0.14, Color("c98c4a"), 12)
			k.cone(Vector3(0, 0.2, -0.17), 0.22, 0.17, Color("8a5f3a"), 12)
			for i in 4:
				k.push(Transform3D(Basis(Vector3.BACK, PI * 0.5 * i + 0.4), Vector3(0, 0.06, -0.33)))
				k.soft_box(Vector3(0, 0.3, 0), Vector3(0.075, 0.27, 0.012), Color("fffdf4"), 0.7, 4, 8)
				k.pop()
			k.ball(Vector3(0, 0.06, -0.34), Vector3(0.04, 0.04, 0.04), Color("e8483f"), 6, 8)
		"hot_air":
			var string_path := PackedVector3Array([end, end + Vector3(0, 1.0, 0)])
			k.tube(string_path, 0.008, Color("fff8ea"), false, 5)
			k.soft_box(end + Vector3(0, 1.1, 0), Vector3(0.1, 0.08, 0.1), Color("c98c4a"), 0.6, 6, 8)
			var top := end + Vector3(0, 1.72, 0)
			k.ball(top, Vector3(0.42, 0.48, 0.42), Color("ff5a4e"), 12, 18)
			k.outline = 0.0
			for y: float in [-0.14, 0.14]:
				k.band(top, Vector3(0.42, 0.48, 0.42), y, y + 0.1, Color("ffd23f"), 0.005, 22)
			k.outline = 0.02
			k.cone(top + Vector3(0, -0.56, 0), 0.14, 0.14, Color("ff5a4e"), 12)
