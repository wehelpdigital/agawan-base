class_name PetBodies
extends RefCounted
## Pets that aren't animals with four feet: things from the sea, little bugs, and snacks that have come alive.


static func build(k: MeshKit, body: String, c: Color, c2: Color) -> bool:
	match body:
		"crab":
			k.ball(Vector3(0, 0.2, 0), Vector3(0.3, 0.16, 0.22), c, 10, 14)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.38, 0.22, 0.14), Vector3(0.11, 0.09, 0.1), c, 6, 9)
				k.ball(Vector3(s * 0.46, 0.27, 0.2), Vector3(0.06, 0.04, 0.06), c.lightened(0.14), 4, 6)
				for f: float in [-0.14, 0.0, 0.14]:
					k.tube(PackedVector3Array([Vector3(s * 0.24, 0.14, f), Vector3(s * 0.38, 0.1, f), Vector3(s * 0.44, 0.02, f)]), 0.018, c.darkened(0.1), false, 5)
				k.cyl(Vector3(s * 0.1, 0.3, 0.1), 0.1, 0.015, 0.015, c.darkened(0.12), 5)
				k.ball(Vector3(s * 0.1, 0.42, 0.1), Vector3(0.05, 0.05, 0.05), Color.WHITE, 4, 7)
				k.outline = 0.0
				k.ball(Vector3(s * 0.1, 0.42, 0.145), Vector3(0.024, 0.026, 0.01), Color("0a1426"), 2, 5)
				k.outline = 0.02
			Pet3D._smile(k, 0.17, 0.215, 0.05)
		"octopus":
			k.ball(Vector3(0, 0.34, 0), Vector3(0.26, 0.28, 0.25), c, 10, 14)
			for i in 6:
				var t := TAU * i / 6.0 + 0.5
				k.tube(PackedVector3Array([Vector3(cos(t) * 0.16, 0.16, sin(t) * 0.16), Vector3(cos(t) * 0.3, 0.06, sin(t) * 0.3), Vector3(cos(t) * 0.38, 0.04, sin(t) * 0.38)]), 0.06, c, false, 6, 0.024)
			Pet3D._eyes(k, 0.36, 0.235, 0.1, 0.05)
			Pet3D._smile(k, 0.27, 0.235, 0.04)
		"jellyfish":
			k.dome(Vector3(0, 0.4, 0), Vector3(0.26, 0.24, 0.26), c, 8, 16)
			for i in 6:
				var t := TAU * i / 6.0
				k.tube(PackedVector3Array([Vector3(cos(t) * 0.16, 0.4, sin(t) * 0.16), Vector3(cos(t) * 0.18, 0.26, sin(t) * 0.18), Vector3(cos(t) * 0.14, 0.12, sin(t) * 0.14)]), 0.02, c2, false, 4, 0.008)
			Pet3D._eyes(k, 0.46, 0.23, 0.1, 0.042)
			Pet3D._smile(k, 0.42, 0.24, 0.03)
		"koi":
			k.ball(Vector3(0, 0.3, 0), Vector3(0.17, 0.17, 0.32), c, 10, 14)
			k.outline = 0.0
			for at: Vector3 in [Vector3(0.0, 0.46, 0.02), Vector3(0.1, 0.4, -0.14), Vector3(-0.12, 0.38, 0.1)]:
				k.ball(at, Vector3(0.07, 0.03, 0.08), c2, 3, 8)
			k.outline = 0.02
			k.ball(Vector3(0, 0.3, -0.36), Vector3(0.022, 0.13, 0.1), c2, 5, 8)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.2, 0.22, 0.06), Vector3(0.09, 0.02, 0.06), c2, 4, 6)
			k.ball(Vector3(0, 0.46, -0.04), Vector3(0.02, 0.05, 0.12), c2, 4, 6)
			Pet3D._eyes(k, 0.34, 0.26, 0.09, 0.04)
			k.outline = 0.0
			k.ball(Vector3(0, 0.27, 0.315), Vector3(0.05, 0.035, 0.012), Color("c94f7a"), 3, 7)
			k.outline = 0.02
		"puffer":
			k.ball(Vector3(0, 0.3, 0), Vector3(0.26, 0.26, 0.26), c, 10, 14)
			k.outline = 0.0
			k.round_patch(Vector3(0, 0.3, 0), Vector3(0.26, 0.26, 0.26), 0.0, -0.1, 0.18, 0.13, c2, 0.006, 16)
			k.outline = 0.02
			for i in 12:
				var t := i * 2.399
				var y := 1.0 - (i + 0.5) / 6.0
				var r := sqrt(maxf(1.0 - y * y, 0.0))
				var dir := Vector3(cos(t) * r, y, sin(t) * r)
				k.push(Transform3D(Basis.looking_at(dir, Vector3.RIGHT if absf(dir.y) > 0.9 else Vector3.UP) * Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, 0.3, 0) + dir * 0.25))
				k.cone(Vector3.ZERO, 0.07, 0.024, c.darkened(0.22), 5)
				k.pop()
			Pet3D._eyes(k, 0.36, 0.24, 0.1, 0.05)
			k.ball(Vector3(0, 0.27, 0.25), Vector3(0.03, 0.03, 0.02), Color("ff9fa0"), 4, 6)
		"snail":
			k.ball(Vector3(0, 0.08, 0.04), Vector3(0.16, 0.07, 0.34), c2, 8, 12)
			k.ball(Vector3(0, 0.18, 0.26), Vector3(0.1, 0.12, 0.1), c2, 7, 9)
			k.ball(Vector3(0, 0.3, -0.04), Vector3(0.09, 0.22, 0.22), c, 10, 14)
			k.outline = 0.0
			var path := PackedVector3Array()
			for i in 17:
				var t := i * 0.6
				var r := 0.19 - i * 0.01
				path.append(Vector3(0.095, 0.3 + sin(t) * r, -0.04 + cos(t) * r))
			k.tube(path, 0.012, c.darkened(0.2), false, 4)
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				k.tube(PackedVector3Array([Vector3(s * 0.05, 0.27, 0.3), Vector3(s * 0.08, 0.42, 0.32)]), 0.014, c2, false, 4)
				k.ball(Vector3(s * 0.08, 0.44, 0.32), Vector3(0.03, 0.03, 0.03), Color("0a1426"), 3, 6)
			Pet3D._smile(k, 0.17, 0.36, 0.03)
		"bee":
			k.ball(Vector3(0, 0.34, 0), Vector3(0.2, 0.19, 0.24), c, 10, 14)
			k.outline = 0.0
			for z: float in [-0.1, 0.04]:
				k.ball(Vector3(0, 0.34, z), Vector3(0.205, 0.195, 0.035), Color("2a2438"), 4, 12)
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.5), Vector3(s * 0.12, 0.46, -0.02)))
				k.ball(Vector3(0, 0.14, 0), Vector3(0.1, 0.16, 0.018), Color(0.88, 0.96, 1.0), 5, 9)
				k.pop()
				k.tube(PackedVector3Array([Vector3(s * 0.05, 0.46, 0.14), Vector3(s * 0.08, 0.58, 0.16)]), 0.01, Color("2a2438"), false, 4)
				k.ball(Vector3(s * 0.08, 0.6, 0.16), Vector3(0.024, 0.024, 0.024), Color("2a2438"), 3, 5)
			Pet3D._eyes(k, 0.38, 0.215, 0.09, 0.045)
			Pet3D._smile(k, 0.3, 0.225, 0.03)
		"ladybug":
			k.dome(Vector3(0, 0.1, 0), Vector3(0.28, 0.24, 0.32), c, 8, 16)
			k.ball(Vector3(0, 0.15, 0.26), Vector3(0.14, 0.12, 0.1), Color("2a2438"), 7, 10)
			k.outline = 0.0
			k.ball(Vector3(0, 0.22, -0.02), Vector3(0.012, 0.13, 0.3), Color("2a2438"), 2, 6)
			for at: Vector3 in [Vector3(0.14, 0.24, 0.08), Vector3(-0.14, 0.24, 0.08), Vector3(0.17, 0.2, -0.12), Vector3(-0.17, 0.2, -0.12)]:
				k.ball(at, Vector3(0.05, 0.03, 0.05), Color("2a2438"), 3, 7)
			k.outline = 0.02
			Pet3D._eyes(k, 0.18, 0.36, 0.06, 0.03)
		"butterfly":
			k.ball(Vector3(0, 0.32, 0), Vector3(0.05, 0.05, 0.2), Color("2a2438"), 6, 9)
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.FORWARD, s * 0.5), Vector3(s * 0.03, 0.34, 0)))
				k.ball(Vector3(s * 0.2, 0.04, 0.08), Vector3(0.18, 0.016, 0.16), c, 5, 10)
				k.ball(Vector3(s * 0.15, 0.04, -0.12), Vector3(0.12, 0.016, 0.11), c2, 5, 9)
				k.outline = 0.0
				k.ball(Vector3(s * 0.22, 0.055, 0.08), Vector3(0.07, 0.006, 0.06), c2, 2, 7)
				k.outline = 0.02
				k.pop()
				k.tube(PackedVector3Array([Vector3(s * 0.02, 0.34, 0.18), Vector3(s * 0.08, 0.44, 0.26)]), 0.008, Color("2a2438"), false, 3)
			Pet3D._eyes(k, 0.34, 0.195, 0.035, 0.024)
		"shoot":  # A bamboo shoot, just up.
			k.cyl(Vector3(0, 0.02, 0), 0.26, 0.24, 0.2, c, 14)
			k.cone(Vector3(0, 0.27, 0), 0.34, 0.2, c, 14)
			k.outline = 0.0
			for y: float in [0.12, 0.26, 0.4]:
				k.torus(Vector3(0, y, 0), maxf(0.22 - (y - 0.1) * 0.5, 0.05), 0.012, c2, 14, 3)
			k.outline = 0.02
			k.push(Transform3D(Basis(Vector3.BACK, -0.6), Vector3(0.05, 0.56, 0)))
			k.ball(Vector3(0, 0.1, 0), Vector3(0.04, 0.12, 0.012), Color("4cbc5e"), 5, 7)
			k.pop()
			Pet3D._eyes(k, 0.2, 0.2, 0.08, 0.042)
			Pet3D._smile(k, 0.13, 0.205, 0.03)
		"dumpling":
			k.ball(Vector3(0, 0.2, 0), Vector3(0.3, 0.2, 0.26), c, 10, 14)
			k.cone(Vector3(0, 0.34, 0), 0.14, 0.1, c, 8)
			k.outline = 0.0
			for i in 6:
				var t := TAU * i / 6.0
				k.tube(PackedVector3Array([Vector3(cos(t) * 0.03, 0.47, sin(t) * 0.03), Vector3(cos(t) * 0.12, 0.34, sin(t) * 0.1)]), 0.007, c2, false, 3)
			k.outline = 0.02
			Pet3D._eyes(k, 0.2, 0.245, 0.09, 0.045)
			Pet3D._smile(k, 0.14, 0.25, 0.03)
		"nigiri":
			k.ball(Vector3(0, 0.15, 0), Vector3(0.26, 0.15, 0.2), c, 9, 12)
			k.soft_box(Vector3(0, 0.31, 0), Vector3(0.3, 0.07, 0.22), c2, 0.6, 5, 10)
			k.outline = 0.0
			for f: float in [-0.16, 0.0, 0.16]:
				k.ball(Vector3(f, 0.385, 0), Vector3(0.012, 0.008, 0.2), c2.lightened(0.5), 2, 5)
			k.outline = 0.02
			Pet3D._eyes(k, 0.16, 0.19, 0.09, 0.042)
			Pet3D._smile(k, 0.09, 0.19, 0.03)
		"boba":
			k.cyl(Vector3(0, 0.02, 0), 0.42, 0.18, 0.24, c, 14)
			k.outline = 0.0
			for at: Vector3 in [Vector3(-0.1, 0.08, 0.16), Vector3(0.06, 0.07, 0.18), Vector3(0.14, 0.12, 0.13), Vector3(-0.02, 0.15, 0.19)]:
				k.ball(at, Vector3(0.036, 0.036, 0.018), Color("3a2030"), 2, 6)
			k.outline = 0.02
			k.dome(Vector3(0, 0.44, 0), Vector3(0.23, 0.1, 0.23), Color("f4fcff"), 5, 12)
			k.cyl(Vector3(0.04, 0.46, 0), 0.26, 0.022, 0.022, c2, 6)
			Pet3D._eyes(k, 0.3, 0.215, 0.08, 0.042)
			Pet3D._smile(k, 0.23, 0.205, 0.028)
		"lantern":
			k.ball(Vector3(0, 0.3, 0), Vector3(0.24, 0.2, 0.22), c, 9, 14)
			k.cyl(Vector3(0, 0.08, 0), 0.04, 0.1, 0.12, c2, 10)
			k.cyl(Vector3(0, 0.49, 0), 0.04, 0.12, 0.1, c2, 10)
			k.cyl(Vector3(0, 0.0, 0), 0.08, 0.02, 0.012, c2, 5)
			k.outline = 0.0
			k.round_patch(Vector3(0, 0.3, 0), Vector3(0.24, 0.2, 0.22), 0.0, -0.01, 0.16, 0.13, Color("ffb86a"), 0.006, 16)
			k.outline = 0.02
			Pet3D._eyes(k, 0.32, 0.205, 0.08, 0.04)
			Pet3D._smile(k, 0.25, 0.21, 0.028)
		"doll":  # A little nesting doll.
			k.ball(Vector3(0, 0.2, 0), Vector3(0.22, 0.22, 0.2), c, 9, 13)
			k.ball(Vector3(0, 0.46, 0), Vector3(0.17, 0.16, 0.16), c, 8, 12)
			k.outline = 0.0
			k.round_patch(Vector3(0, 0.46, 0), Vector3(0.17, 0.16, 0.16), 0.0, -0.01, 0.12, 0.11, Color("ffe6c8"), 0.006, 14)
			k.round_patch(Vector3(0, 0.2, 0), Vector3(0.22, 0.22, 0.2), 0.0, -0.02, 0.13, 0.16, c2, 0.006, 14)
			k.outline = 0.02
			Pet3D._eyes(k, 0.47, 0.155, 0.06, 0.03)
			Pet3D._smile(k, 0.42, 0.158, 0.02)
		"squire":  # The smallest knight in the world.
			k.ball(Vector3(0, 0.18, 0), Vector3(0.18, 0.16, 0.16), c, 8, 12)
			k.ball(Vector3(0, 0.42, 0), Vector3(0.2, 0.18, 0.18), c, 9, 13)
			k.outline = 0.0
			k.round_patch(Vector3(0, 0.42, 0), Vector3(0.2, 0.18, 0.18), 0.0, -0.03, 0.14, 0.09, Color("ffe6c8"), 0.006, 14)
			k.round_patch(Vector3(0, 0.18, 0), Vector3(0.18, 0.16, 0.16), 0.0, 0.0, 0.1, 0.13, c2, 0.006, 12)
			k.outline = 0.02
			for i in 4:
				k.ball(Vector3(0, 0.6 + sin(i) * 0.02, -0.08 + i * 0.05), Vector3(0.03, 0.08, 0.04), c2, 4, 6)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.08, 0.04, 0.02), Vector3(0.06, 0.04, 0.08), c.darkened(0.2), 4, 6)
			k.soft_box(Vector3(0.22, 0.2, 0.04), Vector3(0.02, 0.14, 0.1), c2, 0.6, 3, 6)
			Pet3D._eyes(k, 0.41, 0.17, 0.07, 0.03)
		"teacup":
			k.cyl(Vector3(0, 0.05, 0), 0.3, 0.17, 0.27, c, 16)
			k.ball(Vector3(0, 0.34, 0), Vector3(0.25, 0.02, 0.25), Color("c98c4a"), 3, 14)
			k.torus(Vector3(0, 0.34, 0), 0.265, 0.014, c2, 18, 3)
			k.ball(Vector3(0, 0.03, 0), Vector3(0.22, 0.025, 0.22), c, 3, 14)
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.3, 0.2, 0)))
			k.torus(Vector3.ZERO, 0.075, 0.02, c, 12, 4)
			k.pop()
			Pet3D._eyes(k, 0.22, 0.225, 0.09, 0.042)
			Pet3D._smile(k, 0.15, 0.2, 0.028)
		"pineapple":
			k.ball(Vector3(0, 0.22, 0), Vector3(0.2, 0.22, 0.2), c, 9, 13)
			k.outline = 0.0
			for f: float in [-0.5, 0.0, 0.5]:
				var path := PackedVector3Array()
				for j in 9:
					var t := lerpf(-1.2, 1.2, j / 8.0)
					path.append(Vector3(sin(f + t * 0.5) * cos(t) * 0.205, sin(t) * 0.225 + 0.22, cos(f + t * 0.5) * cos(t) * 0.205))
				k.tube(path, 0.005, c.darkened(0.2), false, 3)
			k.outline = 0.02
			for i in 6:
				var t := TAU * i / 6.0
				k.push(Transform3D(Basis(Vector3(sin(t), 0, -cos(t)), 0.5), Vector3(0, 0.42, 0)))
				k.ball(Vector3(0, 0.1, 0), Vector3(0.03, 0.12, 0.014), c2, 4, 6)
				k.pop()
			Pet3D._eyes(k, 0.24, 0.19, 0.075, 0.038)
			Pet3D._smile(k, 0.17, 0.19, 0.024)
		"mochi":
			k.ball(Vector3(0, 0.18, 0), Vector3(0.28, 0.18, 0.26), c, 9, 14)
			Pet3D._eyes(k, 0.2, 0.235, 0.1, 0.04)
			Pet3D._smile(k, 0.14, 0.245, 0.024)
			k.outline = 0.0
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.16, 0.14, 0.215), Vector3(0.05, 0.026, 0.012), c2, 2, 7)
			k.outline = 0.02
		"scarab":
			k.ball(Vector3(0, 0.15, -0.02), Vector3(0.22, 0.14, 0.28), c, 9, 13)
			k.ball(Vector3(0, 0.14, 0.26), Vector3(0.13, 0.09, 0.08), c, 6, 9)
			k.outline = 0.0
			k.ball(Vector3(0, 0.285, -0.02), Vector3(0.008, 0.008, 0.25), c2, 2, 5)
			k.band(Vector3(0, 0.15, -0.02), Vector3(0.22, 0.14, 0.28), 0.03, 0.05, c2, 0.004, 16, 2)
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				for z: float in [-0.14, 0.04, 0.18]:
					k.tube(PackedVector3Array([Vector3(s * 0.14, 0.08, z), Vector3(s * 0.28, 0.08, z), Vector3(s * 0.32, 0.01, z + 0.03)]), 0.012, c.darkened(0.2), false, 4)
			Pet3D._eyes(k, 0.16, 0.33, 0.06, 0.026)
		"nessie":
			k.ball(Vector3(0, 0.16, -0.08), Vector3(0.2, 0.15, 0.28), c, 9, 13)
			k.tube(PackedVector3Array([Vector3(0, 0.24, 0.1), Vector3(0, 0.46, 0.14), Vector3(0, 0.66, 0.08)]), 0.08, c, false, 8, 0.06)
			k.ball(Vector3(0, 0.74, 0.12), Vector3(0.11, 0.09, 0.14), c, 7, 10)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.2, 0.06, 0.08), Vector3(0.1, 0.022, 0.07), c2, 3, 7)
				k.ball(Vector3(s * 0.18, 0.06, -0.24), Vector3(0.09, 0.02, 0.06), c2, 3, 7)
			k.tube(PackedVector3Array([Vector3(0, 0.16, -0.32), Vector3(0, 0.13, -0.46), Vector3(0.05, 0.1, -0.56)]), 0.06, c, false, 6, 0.018)
			Pet3D._eyes(k, 0.76, 0.24, 0.06, 0.03)
			Pet3D._smile(k, 0.7, 0.255, 0.025)
		"little_yeti":
			k.ball(Vector3(0, 0.26, 0), Vector3(0.28, 0.26, 0.25), c, 10, 14)
			for i in 8:
				var t := TAU * i / 8.0
				k.ball(Vector3(cos(t) * 0.26, 0.26 + sin(t) * 0.22, -0.06), Vector3(0.09, 0.09, 0.1), c, 5, 7)
			k.outline = 0.0
			k.round_patch(Vector3(0, 0.26, 0), Vector3(0.28, 0.26, 0.25), 0.0, 0.0, 0.19, 0.16, c2, 0.006, 16)
			k.outline = 0.02
			Pet3D._eyes(k, 0.29, 0.23, 0.08, 0.04)
			Pet3D._smile(k, 0.22, 0.235, 0.03)
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.45), Vector3(s * 0.13, 0.48, 0)))
				k.cone(Vector3.ZERO, 0.11, 0.035, c2, 6)
				k.pop()
		_:
			return false
	return true
