class_name HeroParts
extends RefCounted
## The heads and bodies of the world's characters: knights, ninjas, folk tales, street food. Avatar3D calls in here for anything
## it doesn't draw itself. Most heads are the standard head with something on it, so masks and hats still fit them; those that
## aren't say so with a `surf` in their row in Culture.HEROES.

const HEAD := Vector3(0.5, 0.46, 0.46)
const BODY_AT := Vector3(0, 0.46, 0)
const BODY_R := Vector3(0.31, 0.32, 0.28)
const GOLD := Color("ffc21f")
const STEEL := Color("c4cedc")


## A point on the standard head.
static func _on(x: float, y: float, lift := 0.012) -> Vector3:
	var q := 1.0 - pow(x / HEAD.x, 2.0) - pow(y / HEAD.y, 2.0)
	return Vector3(x, y, HEAD.z * sqrt(maxf(q, 0.0)) + lift)


## The face showing through a helmet or a hood, with a neat edge round it.
static func _opening(k: MeshKit, tone: Color, rx: float, ry: float, cy: float, rim: Color) -> void:
	k.outline = 0.0
	k.round_patch(Vector3.ZERO, HEAD, 0.0, cy, rx, ry, tone, 0.006, 32)
	var path := PackedVector3Array()
	for i in 29:
		var t := TAU * i / 28.0
		path.append(_on(cos(t) * rx, cy + sin(t) * ry, 0.012))
	k.tube(path, 0.02, rim, false, 5)
	k.outline = 0.02


static func _std_face(a: Avatar3D, k: MeshKit) -> void:
	a._eyes(k, -0.01, 0.395, 0.2, 0.115)
	a._smile(k, -0.15, 0.44, 0.095)


## A plain bare head with ears, for the characters who are people.
static func _person(k: MeshKit, tone: Color) -> void:
	k.ball(Vector3.ZERO, HEAD, tone, 16, 24)
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.49, -0.04, 0), Vector3(0.08, 0.1, 0.075), tone, 6, 8)


static func _beard(k: MeshKit, c: Color, long := false) -> void:
	k.ball(Vector3(0, -0.3, 0.14), Vector3(0.42, 0.24, 0.32), c, 8, 14)
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.34, -0.14, 0.2), Vector3(0.14, 0.2, 0.18), c, 6, 10)
	if long:
		k.ball(Vector3(0, -0.56, 0.2), Vector3(0.26, 0.3, 0.2), c, 8, 12)
		k.ball(Vector3(0, -0.8, 0.2), Vector3(0.13, 0.17, 0.12), c, 6, 10)


static func _star(k: MeshKit, at: Vector3, big: float, color: Color) -> void:
	k.fan(FaceParts._star_ring(at, big, big * 0.42, 5), color)


## One of the world's characters: draws the head and says where its face goes.
static func mascot(a: Avatar3D, k: MeshKit, hero: Dictionary, main: Color, second: Color, bare: bool, cover: String) -> void:
	var accent := Color(hero.get("accent", "ffffff"))
	var tone := Color(hero.get("tone", "f0c090"))
	match String(hero["shape"]):
		"knight":
			k.ball(Vector3.ZERO, HEAD, main, 16, 24)
			_opening(k, tone, 0.36, 0.28, -0.07, main.darkened(0.3))
			k.ball(Vector3(0, 0.24, 0.32), Vector3(0.38, 0.15, 0.16), main.lightened(0.14), 8, 14)  # The visor, pushed up.
			k.outline = 0.0
			k.ball(Vector3(0, 0.25, 0.46), Vector3(0.24, 0.012, 0.012), main.darkened(0.5), 3, 8)
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.49, 0.02, 0.0), Vector3(0.05, 0.09, 0.09), accent, 5, 8)
			_std_face(a, k)
		"samurai":
			k.ball(Vector3.ZERO, HEAD, main, 16, 24)
			_opening(k, tone, 0.36, 0.3, -0.06, GOLD)
			k.ball(Vector3(0, -0.2, -0.2), Vector3(0.58, 0.24, 0.38), main.darkened(0.2), 8, 14)  # The guard at the neck.
			if bare:
				k.tube(PackedVector3Array([Vector3(-0.36, 0.56, 0.2), Vector3(-0.2, 0.36, 0.38), Vector3(0, 0.27, 0.46), Vector3(0.2, 0.36, 0.38), Vector3(0.36, 0.56, 0.2)]), 0.035, GOLD, false, 6, 0.012)
			k.ball(Vector3(0, 0.3, 0.42), Vector3(0.06, 0.06, 0.03), accent, 5, 8)
			_std_face(a, k)
		"ninja":
			k.ball(Vector3.ZERO, HEAD, main, 16, 24)
			_opening(k, tone, 0.44, 0.18, -0.02, main.darkened(0.45))
			k.torus(Vector3(0, 0.18, 0), 0.5, 0.03, accent, 24, 5)
			_std_face(a, k)
		"viking":
			_person(k, tone)
			_beard(k, second)
			k.dome(Vector3(0, 0.12, 0), Vector3(0.53, 0.42, 0.49), main, 8, 20)
			k.torus(Vector3(0, 0.13, 0), 0.51, 0.04, GOLD, 24, 5)
			k.soft_box(Vector3(0, 0.08, 0.5), Vector3(0.03, 0.09, 0.02), main.darkened(0.2), 0.7, 4, 6)
			if bare:
				for s: float in [-1.0, 1.0]:
					k.tube(PackedVector3Array([Vector3(s * 0.46, 0.2, 0), Vector3(s * 0.66, 0.26, 0), Vector3(s * 0.74, 0.46, 0), Vector3(s * 0.7, 0.62, 0)]), 0.075, Color("fff6dd"), false, 7, 0.012)
			a._eyes(k, -0.03, 0.395, 0.2, 0.115)
			a._smile(k, -0.15, 0.44, 0.095)
		"pirate":
			_person(k, tone)
			_beard(k, second)
			k.dome(Vector3(0, 0.14, 0), Vector3(0.53, 0.38, 0.49), main, 8, 20)
			k.outline = 0.0
			for f: float in [-0.3, 0.0, 0.3]:
				k.spot(Vector3(0, 0.14, 0), Vector3(0.53, 0.38, 0.49), f, 0.2, 0.05, Color.WHITE)
			k.outline = 0.02
			k.torus(Vector3(0.5, -0.17, 0.02), 0.05, 0.015, GOLD, 12, 4)
			_std_face(a, k)
		"pharaoh":
			_person(k, tone)
			k.ball(Vector3(0, 0.1, -0.04), Vector3(0.56, 0.42, 0.5), main, 10, 18)
			for f: float in [0.16, 0.26, 0.36, 0.46]:
				k.band(Vector3(0, 0.1, -0.04), Vector3(0.56, 0.42, 0.5), f - 0.1, f - 0.05, second, 0.006, 24, 2)
			for s: float in [-1.0, 1.0]:
				k.soft_box(Vector3(s * 0.46, -0.22, 0.08), Vector3(0.12, 0.28, 0.14), main, 0.6, 6, 10)
				k.outline = 0.0
				for y: float in [-0.12, -0.26, -0.4]:
					k.ball(Vector3(s * 0.46, y, 0.21), Vector3(0.1, 0.03, 0.012), second, 2, 7)
				k.outline = 0.02
			_opening(k, tone, 0.34, 0.27, -0.09, GOLD)
			k.ball(Vector3(0, 0.27, 0.44), Vector3(0.06, 0.06, 0.03), Color("e8282f"), 5, 8)
			_std_face(a, k)
		"mummy":
			k.ball(Vector3.ZERO, HEAD, main, 16, 24)
			k.outline = 0.0
			for f: float in [0.34, 0.2, -0.28, -0.38]:
				var path := PackedVector3Array()
				for i in 13:
					var x := lerpf(-0.48, 0.48, i / 12.0)
					var y := f + x * 0.28
					if pow(x / HEAD.x, 2.0) + pow(y / HEAD.y, 2.0) < 0.93:
						path.append(_on(x, y, 0.006))
				if path.size() > 2:
					k.tube(path, 0.016, second, false, 4)
			k.outline = 0.02
			_std_face(a, k)
		"gladiator":
			_person(k, tone)
			k.dome(Vector3(0, 0.1, 0), Vector3(0.53, 0.44, 0.49), main, 8, 20)
			k.torus(Vector3(0, 0.11, 0), 0.51, 0.035, main.darkened(0.25), 24, 5)
			for s: float in [-1.0, 1.0]:
				k.soft_box(Vector3(s * 0.42, -0.14, 0.2), Vector3(0.09, 0.22, 0.11), main, 0.7, 5, 8)
			_std_face(a, k)
		"terracotta":
			k.ball(Vector3.ZERO, HEAD, main, 16, 24)
			k.dome(Vector3(0, 0.1, -0.03), Vector3(0.52, 0.38, 0.47), second, 8, 20)
			if bare:
				k.ball(Vector3(0.14, 0.5, -0.04), Vector3(0.13, 0.13, 0.13), second, 8, 10)
				k.torus(Vector3(0.14, 0.43, -0.04), 0.09, 0.022, accent, 12, 4)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.49, -0.04, 0), Vector3(0.08, 0.1, 0.075), main, 6, 8)
			_std_face(a, k)
		"matryoshka":
			k.ball(Vector3.ZERO, Vector3(0.52, 0.48, 0.48), main, 16, 24)
			k.outline = 0.0
			k.round_patch(Vector3.ZERO, Vector3(0.52, 0.48, 0.48), 0.0, -0.05, 0.38, 0.34, tone, 0.006, 32)
			k.round_patch(Vector3.ZERO, Vector3(0.52, 0.48, 0.48), 0.0, 0.24, 0.26, 0.05, second, 0.009, 18)
			for f: float in [-0.2, 0.0, 0.2]:
				k.round_patch(Vector3.ZERO, Vector3(0.52, 0.48, 0.48), f, 0.25 - absf(f) * 0.12, 0.05, 0.05, Color("fff6dd"), 0.012, 12)
			k.outline = 0.02
			_std_face(a, k)
		"nutcracker":
			_person(k, tone)
			k.soft_box(Vector3(0, -0.28, 0.14), Vector3(0.36, 0.2, 0.3), Color("fffdf4"), 0.5, 6, 10)  # A jaw for cracking things.
			if bare:
				k.cyl(Vector3(0, 0.14, -0.02), 0.56, 0.47, 0.52, main, 18)
				k.torus(Vector3(0, 0.16, -0.02), 0.48, 0.035, GOLD, 22, 5)
				k.torus(Vector3(0, 0.66, -0.02), 0.52, 0.035, GOLD, 22, 5)
				k.ball(Vector3(0, 0.42, 0.5), Vector3(0.08, 0.1, 0.03), GOLD, 5, 8)
				k.ball(Vector3(0, 0.82, 0.0), Vector3(0.09, 0.14, 0.09), Color("fffdf4"), 6, 8)
			else:
				k.dome(Vector3(0, 0.14, -0.02), Vector3(0.52, 0.34, 0.48), main, 8, 18)
			_std_face(a, k)
		"kokeshi":
			k.ball(Vector3.ZERO, HEAD, main, 16, 24)
			k.dome(Vector3(0, 0.04, -0.06), Vector3(0.53, 0.46, 0.46), second, 8, 20)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.4, -0.08, 0.02), Vector3(0.14, 0.26, 0.24), second, 6, 10)
			k.ball(Vector3(0.28, 0.36, 0.26), Vector3(0.09, 0.09, 0.05), Color("e8483f"), 6, 10)
			k.ball(Vector3(0.18, 0.4, 0.28), Vector3(0.07, 0.07, 0.04), Color("ff8fa6"), 5, 8)
			_std_face(a, k)
		"jester":
			_person(k, tone)
			k.dome(Vector3(0, 0.12, -0.01), Vector3(0.53, 0.4, 0.49), main, 8, 20)
			k.outline = 0.0
			k.band(Vector3(0, 0.12, -0.01), Vector3(0.53, 0.4, 0.49), 0.0, 0.05, GOLD, 0.006, 24, 2)
			for s: float in [-1.0, 1.0]:  # Painted diamonds.
				var at := _on(s * 0.22, 0.12, 0.012)
				k.fan(PackedVector3Array([at + Vector3(0, 0.07, 0), at + Vector3(-0.035, 0, 0), at + Vector3(0, -0.07, 0), at + Vector3(0.035, 0, 0)]), second)
			k.outline = 0.02
			_std_face(a, k)
		"wizard":
			_person(k, tone)
			_beard(k, second, true)
			if bare:
				k.torus(Vector3(0, 0.16, -0.01), 0.58, 0.05, main.darkened(0.2), 28, 6)
				k.tube(PackedVector3Array([Vector3(0, 0.1, -0.01), Vector3(0, 0.4, -0.04), Vector3(0.05, 0.7, -0.08), Vector3(0.22, 0.98, -0.14)]), 0.46, main, false, 16, 0.03)
				k.outline = 0.0
				_star(k, Vector3(-0.1, 0.42, 0.3), 0.08, GOLD)
				_star(k, Vector3(0.15, 0.56, 0.19), 0.06, Color("fff6c9"))
				k.outline = 0.02
			else:
				k.dome(Vector3(0, 0.14, -0.02), Vector3(0.52, 0.34, 0.48), second, 8, 18)
			a._eyes(k, -0.02, 0.395, 0.2, 0.115)
			a._smile(k, -0.15, 0.44, 0.095)
		"druid":
			_person(k, tone)
			_beard(k, second)
			k.dome(Vector3(0, 0.14, -0.02), Vector3(0.53, 0.38, 0.49), main, 8, 20)
			if bare:
				k.torus(Vector3(0, 0.17, -0.01), 0.5, 0.05, accent, 24, 5)
				for i in 9:
					var turn := -1.3 + i * 0.325
					k.ball(Vector3(sin(turn) * 0.5, 0.23, cos(turn) * 0.46), Vector3(0.11, 0.06, 0.06), Color("7ed957"), 4, 6)
				for s: float in [-1.0, 1.0]:
					k.tube(PackedVector3Array([Vector3(s * 0.26, 0.34, 0.0), Vector3(s * 0.34, 0.56, 0.0), Vector3(s * 0.5, 0.74, 0.0)]), 0.045, Color("b5763c"), false, 6, 0.016)
					k.tube(PackedVector3Array([Vector3(s * 0.33, 0.52, 0.0), Vector3(s * 0.2, 0.68, 0.0)]), 0.032, Color("b5763c"), false, 5, 0.012)
			a._eyes(k, -0.03, 0.395, 0.2, 0.115)
			a._smile(k, -0.15, 0.44, 0.095)
		"witch":
			_person(k, tone)
			k.dome(Vector3(0, 0.04 if bare else 0.1, -0.03), Vector3(0.54, 0.3 if bare else 0.42, 0.5), second, 8, 20)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.44, -0.2, -0.04), Vector3(0.13, 0.3, 0.15), second, 6, 10)
			if bare:
				_pointy_hat(k, main, accent)
				k.soft_box(Vector3(0, 0.27, 0.41), Vector3(0.07, 0.06, 0.02), GOLD, 0.5, 3, 6)
			_std_face(a, k)
		"paladin":
			k.ball(Vector3.ZERO, HEAD, main, 16, 24)
			_opening(k, tone, 0.36, 0.28, -0.07, second)
			k.ball(Vector3(0, 0.24, 0.32), Vector3(0.38, 0.15, 0.16), main.lightened(0.2), 8, 14)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.54, 0.14, -0.08), Vector3(0.05, 0.22, 0.17), Color.WHITE, 6, 10)
				k.ball(Vector3(s * 0.58, 0.32, -0.14), Vector3(0.04, 0.16, 0.12), Color.WHITE, 5, 8)
			if bare:
				k.soft_box(Vector3(0, 0.47, -0.02), Vector3(0.05, 0.11, 0.22), accent, 0.6, 4, 8)
			_std_face(a, k)
		"ranger":
			k.ball(Vector3.ZERO, HEAD, main, 16, 24)
			_opening(k, tone, 0.38, 0.3, -0.06, main.darkened(0.3))
			if bare:
				k.tube(PackedVector3Array([Vector3(0, 0.3, -0.26), Vector3(0, 0.3, -0.5), Vector3(0, 0.2, -0.7)]), 0.2, main, false, 10, 0.02)
				k.tube(PackedVector3Array([Vector3(0.36, 0.26, 0.1), Vector3(0.5, 0.48, 0.04), Vector3(0.58, 0.72, 0.0)]), 0.05, accent, false, 6, 0.012)
			_std_face(a, k)
		"barbarian":
			_person(k, tone)
			_beard(k, second)
			k.dome(Vector3(0, 0.12, -0.04), Vector3(0.56, 0.42, 0.5), second, 8, 20)
			if bare:
				for i in 7:
					var turn := -1.5 + i * 0.5
					k.ball(Vector3(sin(turn) * 0.34, 0.42, cos(turn) * 0.24 - 0.06), Vector3.ONE * 0.17, second, 5, 8)
				k.torus(Vector3(0, 0.17, 0), 0.51, 0.04, accent, 24, 5)
			a._eyes(k, -0.03, 0.395, 0.2, 0.115)
			a._smile(k, -0.15, 0.44, 0.095)
		"bard":
			_person(k, tone)
			k.dome(Vector3(0, 0.1, -0.03), Vector3(0.53, 0.4, 0.49), Color("7a4a26"), 8, 20)
			if bare:
				k.ball(Vector3(-0.05, 0.28, -0.02), Vector3(0.62, 0.16, 0.56), main, 8, 18)
				k.torus(Vector3(0, 0.2, -0.01), 0.51, 0.035, second, 24, 5)
				k.tube(PackedVector3Array([Vector3(0.34, 0.3, 0.1), Vector3(0.56, 0.52, 0.0), Vector3(0.72, 0.84, -0.1)]), 0.06, accent, false, 7, 0.012)
			_std_face(a, k)
		"alchemist":
			_person(k, tone)
			k.dome(Vector3(0, 0.1, -0.03), Vector3(0.53, 0.42, 0.49), second, 8, 20)
			if bare:
				for i in 6:
					var turn := -1.2 + i * 0.48
					k.ball(Vector3(sin(turn) * 0.42, 0.34, cos(turn) * 0.2 - 0.1), Vector3.ONE * 0.13, second, 4, 7)
				k.torus(Vector3(0, 0.2, 0), 0.5, 0.025, Color("3a2a1c"), 24, 4)
				for s: float in [-1.0, 1.0]:
					k.ball(Vector3(s * 0.16, 0.24, 0.42), Vector3(0.1, 0.1, 0.05), accent, 6, 10)
					k.torus(Vector3(s * 0.16, 0.24, 0.42), 0.1, 0.022, GOLD, 12, 4)
			_std_face(a, k)
		"rogue":
			k.ball(Vector3.ZERO, HEAD, main, 16, 24)
			_opening(k, tone, 0.42, 0.2, -0.01, second)
			if bare:
				k.tube(PackedVector3Array([Vector3(0, 0.32, -0.2), Vector3(0.02, 0.42, -0.46), Vector3(0.1, 0.34, -0.72)]), 0.2, main, false, 10, 0.02)
			k.torus(Vector3(0.5, -0.2, 0.04), 0.05, 0.015, accent, 12, 4)
			_std_face(a, k)
		"mage":
			_person(k, tone)
			k.dome(Vector3(0, 0.04 if bare else 0.1, -0.03), Vector3(0.54, 0.3 if bare else 0.42, 0.5), second, 8, 20)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.45, -0.1, -0.02), Vector3(0.11, 0.2, 0.13), second, 6, 10)
			if bare:
				_pointy_hat(k, main, accent)
				k.outline = 0.0
				_star(k, Vector3(-0.1, 0.44, 0.31), 0.085, accent)
				_star(k, Vector3(0.14, 0.58, 0.2), 0.06, Color("fff6c9"))
				k.outline = 0.02
			_std_face(a, k)
		"elf":
			_person(k, tone)
			k.dome(Vector3(0, 0.1, -0.03), Vector3(0.54, 0.42, 0.5), second, 8, 20)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.43, -0.22, -0.08), Vector3(0.12, 0.3, 0.14), second, 6, 10)
				k.tube(PackedVector3Array([Vector3(s * 0.46, -0.02, 0.0), Vector3(s * 0.66, 0.1, -0.02), Vector3(s * 0.86, 0.28, -0.05)]), 0.08, tone, false, 7, 0.012)
			if bare:
				k.torus(Vector3(0, 0.2, 0), 0.5, 0.025, accent, 24, 4)
				k.ball(Vector3(0, 0.25, 0.43), Vector3(0.06, 0.08, 0.025), main, 4, 8)
			_std_face(a, k)
		"dwarf":
			_person(k, tone)
			_beard(k, second, true)
			if bare:
				k.dome(Vector3(0, 0.14, -0.01), Vector3(0.54, 0.4, 0.5), main, 8, 20)
				k.torus(Vector3(0, 0.15, 0), 0.52, 0.05, accent, 24, 5)
				k.soft_box(Vector3(0, 0.1, 0.5), Vector3(0.035, 0.1, 0.02), main.darkened(0.2), 0.7, 4, 6)
			else:
				k.dome(Vector3(0, 0.14, -0.02), Vector3(0.52, 0.34, 0.48), second, 8, 18)
			a._eyes(k, -0.03, 0.395, 0.2, 0.115)
			a._smile(k, -0.15, 0.44, 0.095)
		"goblin":
			k.ball(Vector3.ZERO, HEAD, main, 16, 24)
			for s: float in [-1.0, 1.0]:
				k.tube(PackedVector3Array([Vector3(s * 0.42, 0.04, -0.02), Vector3(s * 0.72, 0.08, -0.04), Vector3(s * 0.96, 0.0, -0.06)]), 0.17, main, false, 8, 0.02)
				k.tube(PackedVector3Array([Vector3(s * 0.5, 0.05, 0.03), Vector3(s * 0.74, 0.08, 0.02)]), 0.08, main.darkened(0.16), false, 6, 0.02)
			k.ball(Vector3(0, -0.05, 0.47), Vector3(0.05, 0.06, 0.05), main.darkened(0.12), 4, 7)
			_std_face(a, k)
		"orc":
			k.ball(Vector3.ZERO, Vector3(0.53, 0.46, 0.47), main, 16, 24)
			k.ball(Vector3(0, 0.16, 0.36), Vector3(0.36, 0.07, 0.1), main.darkened(0.14), 6, 12)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.5, 0.0, 0.0), Vector3(0.08, 0.11, 0.07), main, 6, 8)
				k.cone(Vector3(s * 0.2, -0.3, 0.38), 0.17, 0.05, accent, 7)
			if bare:
				k.ball(Vector3(0, 0.42, -0.14), Vector3(0.16, 0.14, 0.16), second, 6, 10)
				k.tube(PackedVector3Array([Vector3(0, 0.5, -0.16), Vector3(0, 0.66, -0.26), Vector3(0, 0.56, -0.44)]), 0.08, second, false, 7, 0.02)
			_std_face(a, k)
		"fairy":
			_person(k, tone)
			k.dome(Vector3(0, 0.1, -0.03), Vector3(0.53, 0.42, 0.49), Color("ffd26a"), 8, 20)
			if bare:
				for i in 7:
					var turn := -1.3 + i * 0.43
					var at := Vector3(sin(turn) * 0.46, 0.27, cos(turn) * 0.42)
					k.ball(at, Vector3.ONE * 0.075, main if i % 2 == 0 else accent, 4, 7)
				for s: float in [-1.0, 1.0]:
					k.tube(PackedVector3Array([Vector3(s * 0.12, 0.42, 0.0), Vector3(s * 0.2, 0.62, 0.02), Vector3(s * 0.3, 0.72, 0.04)]), 0.018, Color("3a2a1c"), false, 4)
					k.ball(Vector3(s * 0.3, 0.73, 0.04), Vector3.ONE * 0.05, accent, 4, 6)
			_std_face(a, k)
		"skeleton":
			k.ball(Vector3(0, 0.04, 0), Vector3(0.5, 0.44, 0.46), main, 16, 24)
			k.ball(Vector3(0, -0.28, 0.14), Vector3(0.27, 0.15, 0.24), main, 8, 14)
			k.outline = 0.0
			k.fan(PackedVector3Array([_on(0.0, -0.05, 0.012), _on(-0.04, -0.11, 0.012), _on(0.04, -0.11, 0.012)]), second)
			k.spot(Vector3(0, 0.04, 0), Vector3(0.5, 0.44, 0.46), 0.22, 0.34, 0.05, Color("d8d4c0"))
			k.outline = 0.02
			_std_face(a, k)
		"dragon":
			k.ball(Vector3.ZERO, HEAD, main, 16, 24)
			_opening(k, tone, 0.37, 0.3, -0.07, main.darkened(0.25))
			if bare:
				for s: float in [-1.0, 1.0]:
					k.cone(Vector3(s * 0.26, 0.32, -0.08), 0.32, 0.09, second, 8)
					k.ball(Vector3(s * 0.54, 0.04, -0.06), Vector3(0.05, 0.16, 0.16), accent, 5, 8)
				for i in 4:
					k.cone(Vector3(0, 0.42 - i * 0.05, -0.1 - i * 0.16), 0.2, 0.07, accent, 6)
			_std_face(a, k)
		"genie":
			k.ball(Vector3.ZERO, HEAD, main, 16, 24)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.5, -0.02, 0), Vector3(0.09, 0.12, 0.05), main, 6, 8)
				k.torus(Vector3(s * 0.54, -0.16, 0.02), 0.05, 0.016, GOLD, 12, 4)
			k.ball(Vector3(0, -0.42, 0.24), Vector3(0.05, 0.08, 0.05), second, 5, 8)
			_std_face(a, k)
		"leprechaun":
			_person(k, tone)
			_beard(k, second)
			if bare:
				k.ball(Vector3(0, 0.2, -0.01), Vector3(0.64, 0.03, 0.6), main, 4, 22)
				k.cyl(Vector3(0, 0.2, -0.01), 0.38, 0.44, 0.5, main, 20)
				k.torus(Vector3(0, 0.24, -0.01), 0.45, 0.045, Color("1a1030"), 22, 4)
				k.soft_box(Vector3(0, 0.24, 0.44), Vector3(0.09, 0.08, 0.02), GOLD, 0.5, 3, 6)
			else:
				k.dome(Vector3(0, 0.14, -0.02), Vector3(0.52, 0.34, 0.48), second, 8, 18)
			_std_face(a, k)
		"vampire":
			_person(k, tone)
			k.dome(Vector3(0, 0.07, -0.03), Vector3(0.53, 0.42, 0.48), second, 8, 20)
			k.outline = 0.0
			var peak := _on(0, 0.14, 0.012)
			k.fan(PackedVector3Array([peak + Vector3(0.3, 0.1, -0.1), peak + Vector3(-0.3, 0.1, -0.1), peak + Vector3(0, -0.14, 0)]), second)
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.9), Vector3(s * 0.46, 0.0, 0)))
				k.cone(Vector3.ZERO, 0.2, 0.08, main, 8)
				k.pop()
			_std_face(a, k)
		"yeti":
			k.ball(Vector3.ZERO, HEAD, main, 16, 24)
			for i in 10:
				var t := TAU * i / 10.0
				k.ball(Vector3(cos(t) * 0.46, sin(t) * 0.42 + 0.02, -0.08), Vector3(0.15, 0.15, 0.17), main, 6, 8)
			if bare:
				for s: float in [-1.0, 1.0]:
					k.push(Transform3D(Basis(Vector3.BACK, s * -0.5), Vector3(s * 0.28, 0.4, 0)))
					k.cone(Vector3.ZERO, 0.24, 0.07, Color("9fc8ff"), 8)
					k.pop()
			_opening(k, second, 0.36, 0.32, -0.05, second)
			_std_face(a, k)
		"kappa":
			k.ball(Vector3.ZERO, HEAD, main, 16, 24)
			k.ball(Vector3(0, -0.12, 0.42), Vector3(0.17, 0.09, 0.12), second, 8, 12)  # The beak.
			if bare:
				k.cyl(Vector3(0, 0.4, 0), 0.04, 0.3, 0.3, Color("f4f8ff"), 18)
				k.ball(Vector3(0, 0.45, 0), Vector3(0.26, 0.022, 0.26), Color("5ac8ff"), 4, 14)
				for i in 14:
					var t := TAU * i / 14.0
					k.push(Transform3D(Basis(Vector3(sin(t), 0, -cos(t)), 0.8), Vector3(cos(t) * 0.33, 0.36, sin(t) * 0.33)))
					k.cone(Vector3.ZERO, 0.11, 0.04, Color("2f7a4a"), 6)
					k.pop()
			a._eyes(k, 0.06, 0.395, 0.2, 0.115)
			a._smile(k, -0.26, 0.4, 0.075)
		"troll":
			k.ball(Vector3.ZERO, HEAD, main, 16, 24)
			if bare:
				for i in 9:
					var t := lerpf(0.3, PI - 0.3, i / 8.0)
					k.push(Transform3D(Basis(Vector3.BACK, t - PI * 0.5), Vector3(cos(t) * 0.42, sin(t) * 0.42, -0.06)))
					k.ball(Vector3(0, 0.2, 0), Vector3(0.09, 0.27, 0.09), second, 6, 8)
					k.pop()
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.52, 0.02, 0), Vector3(0.1, 0.13, 0.05), main, 6, 8)
				k.push(Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(s * 0.14, -0.3, 0.38)))
				k.cone(Vector3.ZERO, 0.12, 0.04, Color("fff6dd"), 6)
				k.pop()
			k.ball(Vector3(0, -0.07, 0.47), Vector3(0.13, 0.13, 0.14), main.lightened(0.14), 8, 12)  # The nose.
			a._eyes(k, 0.06, 0.395, 0.22, 0.115)
			a._smile(k, -0.22, 0.42, 0.095)
		"bamboo":
			k.cyl(Vector3(0, -0.48, 0), 0.98, 0.42, 0.42, main, 22)
			k.ball(Vector3(0, 0.5, 0), Vector3(0.42, 0.05, 0.42), second, 4, 16)
			k.outline = 0.0
			k.ball(Vector3(0, 0.53, 0), Vector3(0.3, 0.015, 0.3), Color("fff6dd"), 3, 14)
			k.outline = 0.02
			for y: float in [-0.34, 0.26]:
				k.torus(Vector3(0, y, 0), 0.42, 0.038, main.darkened(0.2), 24, 5)
			a._eyes(k, 0.0, 0.39, 0.18, 0.115)
			a._smile(k, -0.14, 0.42, 0.09)
		"lantern":
			k.ball(Vector3.ZERO, Vector3(0.54, 0.44, 0.5), main, 14, 24)
			k.outline = 0.0
			k.round_patch(Vector3.ZERO, Vector3(0.54, 0.44, 0.5), 0.0, -0.02, 0.38, 0.31, Color("ffb86a"), 0.004, 28)
			for i in 7:
				var t := lerpf(-1.2, 1.2, i / 6.0)
				var path := PackedVector3Array()
				for j in 11:
					var v := lerpf(-1.2, 1.2, j / 10.0)
					path.append(Vector3(sin(t) * cos(v) * 0.55, sin(v) * 0.45, cos(t) * cos(v) * 0.51))
				k.tube(path, 0.009, main.darkened(0.2), false, 4)
			k.outline = 0.02
			k.cyl(Vector3(0, -0.5, 0), 0.1, 0.24, 0.28, GOLD, 16)
			if bare:
				k.cyl(Vector3(0, 0.41, 0), 0.08, 0.28, 0.2, GOLD, 16)
			a._eyes(k, 0.0, 0.42, 0.2, 0.115)
			a._smile(k, -0.14, 0.46, 0.095)
		"sushi":
			k.ball(Vector3.ZERO, HEAD, main, 16, 24)
			k.outline = 0.0
			for spot: Vector2 in [Vector2(-0.3, 0.1), Vector2(0.3, 0.04), Vector2(-0.34, -0.2), Vector2(0.36, -0.22), Vector2(0.0, -0.32)]:
				k.spot(Vector3.ZERO, HEAD, spot.x, spot.y, 0.028, Color("efe8d6"))
			k.outline = 0.02
			k.soft_box(Vector3(0, 0.36, 0), Vector3(0.58, 0.14, 0.5), second, 0.6, 6, 12)
			k.outline = 0.0
			for f: float in [-0.34, -0.11, 0.12, 0.35]:
				k.ball(Vector3(f, 0.49, 0), Vector3(0.018, 0.012, 0.44), second.lightened(0.5), 3, 6)
			k.outline = 0.02
			_std_face(a, k)
		"bao":
			k.ball(Vector3(0, -0.04, 0), Vector3(0.54, 0.44, 0.5), main, 16, 24)
			if bare:
				k.cone(Vector3(0, 0.3, 0), 0.22, 0.17, main, 12)
				k.outline = 0.0
				for i in 8:
					var t := TAU * i / 8.0
					k.tube(PackedVector3Array([Vector3(cos(t) * 0.04, 0.47, sin(t) * 0.04), Vector3(cos(t) * 0.17, 0.32, sin(t) * 0.17), Vector3(cos(t) * 0.3, 0.2, sin(t) * 0.3)]), 0.01, main.darkened(0.14), false, 3)
				k.outline = 0.02
			a._eyes(k, -0.06, 0.4, 0.22, 0.115)
			a._smile(k, -0.2, 0.43, 0.095)
		"boba":
			k.cyl(Vector3(0, -0.5, 0), 0.82, 0.36, 0.46, main, 22)
			k.outline = 0.0
			for spot: Vector3 in [Vector3(-0.2, -0.44, 0.31), Vector3(0.0, -0.46, 0.35), Vector3(0.2, -0.44, 0.31), Vector3(-0.3, -0.34, 0.27), Vector3(0.3, -0.34, 0.27), Vector3(-0.1, -0.36, 0.37), Vector3(0.1, -0.36, 0.37)]:
				k.ball(spot, Vector3(0.065, 0.065, 0.03), Color("3a2030"), 4, 8)
			k.outline = 0.02
			k.torus(Vector3(0, 0.32, 0), 0.46, 0.04, second, 22, 5)
			k.dome(Vector3(0, 0.33, 0), Vector3(0.45, 0.2, 0.45), Color("f4fcff"), 6, 18)
			if bare:
				k.push(Transform3D(Basis(Vector3.BACK, -0.2), Vector3(0.08, 0.34, 0)))
				k.cyl(Vector3.ZERO, 0.46, 0.05, 0.05, Color(hero["accent"]), 10)
				k.pop()
			a._eyes(k, -0.02, 0.4, 0.18, 0.115)
			a._smile(k, -0.15, 0.42, 0.085)
		"taco":
			k.ball(Vector3(0, -0.06, 0), Vector3(0.62, 0.52, 0.32), main, 16, 24)
			if bare:
				for i in 9:
					var t := lerpf(0.42, PI - 0.42, i / 8.0)
					k.ball(Vector3(cos(t) * 0.53, sin(t) * 0.46 - 0.05, -0.08), Vector3(0.16, 0.13, 0.17), second if i % 3 != 1 else Color(hero["accent"]), 6, 8)
			k.ball(Vector3(0, -0.06, 0.02), Vector3(0.6, 0.5, 0.32), main, 16, 24)
			k.outline = 0.0
			for spot: Vector2 in [Vector2(-0.4, 0.1), Vector2(0.42, 0.14), Vector2(-0.3, -0.3), Vector2(0.34, -0.28)]:
				k.spot(Vector3(0, -0.06, 0.02), Vector3(0.6, 0.5, 0.32), spot.x, spot.y, 0.028, main.darkened(0.2))
			k.outline = 0.02
			a._eyes(k, 0.0, 0.26, 0.21, 0.115)
			a._smile(k, -0.14, 0.31, 0.095)
		"croissant":
			k.ball(Vector3.ZERO, Vector3(0.48, 0.44, 0.44), main, 14, 22)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.48, -0.04, 0.0), Vector3(0.22, 0.26, 0.24), main, 8, 12)
				k.ball(Vector3(s * 0.62, -0.24, 0.04), Vector3(0.15, 0.19, 0.17), main, 7, 10)
				k.ball(Vector3(s * 0.66, -0.42, 0.08), Vector3(0.09, 0.12, 0.1), main.darkened(0.06), 6, 8)
				k.outline = 0.0
				k.push(Transform3D(Basis(Vector3.BACK, s * 0.3), Vector3(s * 0.54, -0.14, 0.2)))
				k.ball(Vector3.ZERO, Vector3(0.14, 0.018, 0.05), main.darkened(0.2), 3, 7)
				k.pop()
				k.outline = 0.02
			k.outline = 0.0
			for f: float in [-0.26, 0.26]:
				k.ball(Vector3(f, 0.28, 0.32), Vector3(0.02, 0.14, 0.06), main.darkened(0.18), 3, 6)
			k.outline = 0.02
			_std_face(a, k)
		"pizza":
			var slice := Vector3(0.5, 0.46, 0.27)
			k.ball(Vector3.ZERO, slice, main, 14, 22)
			k.push(Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, -0.2, 0)))
			k.cone(Vector3.ZERO, 0.42, 0.36, main, 14)
			k.pop()
			k.outline = 0.0
			for spot: Vector2 in [Vector2(-0.3, 0.14), Vector2(0.32, 0.12), Vector2(-0.24, -0.25), Vector2(0.26, -0.27)]:
				k.round_patch(Vector3.ZERO, slice, spot.x, spot.y, 0.085, 0.085, Color(hero["accent"]), 0.006, 14)
			k.outline = 0.02
			var crust := PackedVector3Array()
			for i in 15:
				var t := lerpf(0.1, PI - 0.1, i / 14.0)
				crust.append(Vector3(cos(t) * 0.5, sin(t) * 0.46, 0.0))
			k.tube(crust, 0.11, second, false, 8)
			a._eyes(k, 0.0, 0.22, 0.19, 0.11)
			a._smile(k, -0.14, 0.25, 0.09)
		"burger":
			k.dome(Vector3(0, 0.03, 0), Vector3(0.54, 0.44, 0.5), main, 10, 22)
			k.outline = 0.0
			for spot: Vector2 in [Vector2(-0.18, 0.28), Vector2(0.06, 0.32), Vector2(0.24, 0.26), Vector2(-0.3, 0.2), Vector2(0.32, 0.18)]:
				var y := 0.03 + spot.y
				var z := 0.5 * sqrt(maxf(1.0 - pow(spot.x / 0.54, 2.0) - pow(spot.y / 0.44, 2.0), 0.0))
				k.ball(Vector3(spot.x, y, z + 0.005), Vector3(0.028, 0.016, 0.01), Color("fff6dd"), 3, 6)
			k.outline = 0.02
			k.ball(Vector3(0, 0.0, 0), Vector3(0.58, 0.05, 0.54), Color("7ed957"), 4, 18)
			k.ball(Vector3(0, -0.08, 0), Vector3(0.53, 0.08, 0.49), second, 5, 18)
			k.ball(Vector3(0, -0.13, 0), Vector3(0.56, 0.03, 0.52), Color("ffd23f"), 3, 18)
			k.ball(Vector3(0, -0.26, 0), Vector3(0.52, 0.13, 0.48), main.darkened(0.04), 6, 18)
			a._eyes(k, 0.2, 0.34, 0.2, 0.11)
			a._smile(k, 0.09, 0.42, 0.09)
		"donut":
			k.ball(Vector3.ZERO, Vector3(0.54, 0.46, 0.5), second, 14, 22)
			k.ball(Vector3(0, 0.08, 0), Vector3(0.55, 0.39, 0.51), main, 14, 22)
			k.outline = 0.0
			var colours := [Color("ffd23f"), Color("3aa6ff"), Color("35d07f"), Color("fffdf4")]
			for i in 26:
				var t := i * 2.399
				var v := 0.1 + fmod(i * 0.37, 1.0) * 1.0
				var dir := Vector3(cos(t) * cos(v) * 0.56, sin(v) * 0.395 + 0.08, sin(t) * cos(v) * 0.52)
				if absf(dir.x) > 0.34 or dir.y > 0.2:
					k.ball(dir, Vector3(0.04, 0.02, 0.02), colours[i % 4], 2, 5)
			k.round_patch(Vector3(0, 0.08, 0), Vector3(0.55, 0.39, 0.51), 0.0, 0.25, 0.14, 0.055, second.darkened(0.25), 0.008, 16)
			k.outline = 0.02
			_std_face(a, k)
		"teapot":
			k.ball(Vector3.ZERO, Vector3(0.52, 0.46, 0.48), main, 14, 24)
			k.outline = 0.0
			k.band(Vector3.ZERO, Vector3(0.52, 0.46, 0.48), 0.26, 0.31, second, 0.006, 24, 2)
			k.band(Vector3.ZERO, Vector3(0.52, 0.46, 0.48), -0.33, -0.28, second, 0.006, 24, 2)
			k.outline = 0.02
			k.tube(PackedVector3Array([Vector3(0.42, -0.1, 0.02), Vector3(0.62, -0.06, 0.04), Vector3(0.72, 0.14, 0.05), Vector3(0.8, 0.24, 0.05)]), 0.11, main, false, 10, 0.05)
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.56, 0.02, 0)))
			k.torus(Vector3.ZERO, 0.17, 0.04, second, 16, 6)
			k.pop()
			if bare:
				k.dome(Vector3(0, 0.38, 0), Vector3(0.3, 0.12, 0.28), second, 6, 16)
				k.ball(Vector3(0, 0.54, 0), Vector3(0.07, 0.07, 0.07), Color(hero["accent"]), 6, 8)
			_std_face(a, k)
		"avocado":
			k.ball(Vector3(0, -0.03, 0), Vector3(0.48, 0.52, 0.44), main, 16, 24)
			k.outline = 0.0
			k.round_patch(Vector3(0, -0.03, 0), Vector3(0.48, 0.52, 0.44), 0.0, 0.0, 0.42, 0.46, second, 0.014, 40)
			k.outline = 0.02
			a._eyes(k, 0.02, 0.38, 0.19, 0.115)
			a._smile(k, -0.15, 0.42, 0.09)
		"pineapple":
			k.ball(Vector3(0, -0.03, 0), Vector3(0.48, 0.5, 0.44), main, 16, 24)
			k.outline = 0.0
			for i in 9:
				for s: float in [-1.0, 1.0]:
					var path := PackedVector3Array()
					for j in 13:
						var t := lerpf(-1.2, 1.2, j / 12.0)
						var lon := (i - 4) * 0.34 + s * t * 0.6
						if absf(lon) < 1.3:
							path.append(Vector3(sin(lon) * cos(t) * 0.485, sin(t) * 0.505 - 0.03, cos(lon) * cos(t) * 0.445))
					if path.size() > 2:
						k.tube(path, 0.007, main.darkened(0.2), false, 3)
			k.outline = 0.02
			a._eyes(k, 0.0, 0.38, 0.19, 0.115)
			a._smile(k, -0.15, 0.42, 0.09)
		"mushroom":
			k.ball(Vector3(0, -0.04, 0), Vector3(0.46, 0.44, 0.42), second, 14, 22)
			k.dome(Vector3(0, 0.12, 0), Vector3(0.74, 0.5, 0.68), main, 12, 26)
			k.ball(Vector3(0, 0.11, 0), Vector3(0.74, 0.05, 0.68), second.darkened(0.1), 4, 24)
			k.outline = 0.0
			for spot: Vector3 in [Vector3(-0.34, 0.42, 0.34), Vector3(0.36, 0.38, 0.36), Vector3(0.0, 0.54, 0.26), Vector3(-0.56, 0.26, 0.1), Vector3(0.58, 0.24, 0.08), Vector3(0.0, 0.3, 0.59)]:
				k.ball(spot, Vector3(0.1, 0.075, 0.1), Color("fffdf4"), 4, 10)
			k.outline = 0.02
			a._eyes(k, -0.1, 0.36, 0.18, 0.11)
			a._smile(k, -0.25, 0.37, 0.085)
		"snowman":
			k.ball(Vector3.ZERO, HEAD, main, 16, 24)
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, -0.07, 0.42)))
			k.cone(Vector3.ZERO, 0.28, 0.075, Color("ff8a1f"), 8)
			k.pop()
			if bare:
				k.cyl(Vector3(0, 0.3, -0.02), 0.34, 0.34, 0.3, Color("2a2438"), 16)
				k.torus(Vector3(0, 0.33, -0.02), 0.35, 0.04, Color(hero["accent"]), 18, 5)
			a._eyes(k, 0.02, 0.395, 0.2, 0.115)
			a._smile(k, -0.22, 0.4, 0.095)
		"sun":
			for i in 12:
				var t := TAU * i / 12.0 + 0.26
				if bare or sin(t) < 0.4:
					k.push(Transform3D(Basis(Vector3.BACK, t - PI * 0.5), Vector3(cos(t) * 0.42, sin(t) * 0.42, -0.1)))
					k.cone(Vector3.ZERO, 0.3, 0.1, second, 6)
					k.pop()
			k.ball(Vector3.ZERO, HEAD, main, 16, 24)
			_std_face(a, k)
		"cactus":
			k.ball(Vector3(0, -0.02, 0), Vector3(0.44, 0.52, 0.42), main, 16, 24)
			k.outline = 0.0
			for f: float in [-0.74, -0.36, 0.36, 0.74]:
				var path := PackedVector3Array()
				for j in 11:
					var v := lerpf(-1.3, 1.3, j / 10.0)
					path.append(Vector3(sin(f) * cos(v) * 0.445, sin(v) * 0.525 - 0.02, cos(f) * cos(v) * 0.425))
				k.tube(path, 0.009, main.darkened(0.16), false, 3)
			k.outline = 0.02
			if bare:
				for i in 5:
					var t := TAU * i / 5.0
					k.ball(Vector3(cos(t) * 0.1, 0.52, sin(t) * 0.1), Vector3(0.09, 0.06, 0.09), second, 5, 8)
				k.ball(Vector3(0, 0.56, 0), Vector3(0.05, 0.05, 0.05), GOLD, 4, 7)
			a._eyes(k, 0.02, 0.38, 0.18, 0.115)
			a._smile(k, -0.14, 0.41, 0.09)
		"tulip":
			for t: float in [-1.4, 1.4]:
				k.push(Transform3D(Basis(Vector3.UP, t), Vector3.ZERO))
				k.ball(Vector3(0, 0.08, 0.1), Vector3(0.36, 0.56, 0.3), main.darkened(0.08), 8, 14)
				k.pop()
			k.ball(Vector3(0, 0.04, -0.14), Vector3(0.36, 0.56, 0.3), main.darkened(0.14), 8, 14)
			k.ball(Vector3.ZERO, Vector3(0.46, 0.46, 0.42), main, 14, 22)
			if bare:
				for x: float in [-0.3, 0.0, 0.3]:
					k.cone(Vector3(x, 0.28 - absf(x) * 0.2, 0.1), 0.34, 0.2, main, 10)
			a._eyes(k, 0.0, 0.38, 0.18, 0.115)
			a._smile(k, -0.14, 0.41, 0.09)
		"pumpkin":
			k.ball(Vector3.ZERO, Vector3(0.54, 0.46, 0.5), main, 16, 26)
			k.outline = 0.0
			for f: float in [-1.1, -0.72, -0.34, 0.34, 0.72, 1.1]:
				var path := PackedVector3Array()
				for j in 11:
					var v := lerpf(-1.3, 1.3, j / 10.0)
					path.append(Vector3(sin(f) * cos(v) * 0.545, sin(v) * 0.465, cos(f) * cos(v) * 0.505))
				k.tube(path, 0.012, main.darkened(0.2), false, 3)
			k.outline = 0.02
			if bare:
				k.tube(PackedVector3Array([Vector3(0, 0.4, 0), Vector3(0.03, 0.54, 0), Vector3(0.12, 0.62, 0)]), 0.08, Color("3a9c4e"), false, 7, 0.04)
			_std_face(a, k)


## A tall hat with a bend at the tip, as worn by people who know what they're doing.
static func _pointy_hat(k: MeshKit, main: Color, band: Color) -> void:
	k.ball(Vector3(0, 0.2, -0.01), Vector3(0.72, 0.035, 0.68), main, 4, 24)
	k.tube(PackedVector3Array([Vector3(0, 0.14, -0.01), Vector3(0, 0.42, -0.04), Vector3(0.05, 0.72, -0.08), Vector3(0.24, 0.98, -0.14)]), 0.45, main, false, 16, 0.03)
	k.torus(Vector3(0, 0.27, -0.02), 0.41, 0.045, band, 24, 5)


## Their bodies, where the plain round one won't do.
static func body(k: MeshKit, hero: Dictionary, main: Color, second: Color) -> bool:
	var accent := Color(hero.get("accent", "ffffff"))
	match String(hero.get("shape", "")):
		"knight":
			k.ball(BODY_AT, BODY_R, main, 12, 18)
			k.outline = 0.0
			k.round_patch(BODY_AT, BODY_R, 0.0, -0.02, 0.2, 0.25, accent, 0.006, 20)
			k.band(BODY_AT, BODY_R, -0.2, -0.17, GOLD)
			k.spot(BODY_AT, BODY_R, 0.0, 0.0, 0.05, GOLD)
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.28, 0.66, 0), Vector3(0.14, 0.09, 0.14), main.lightened(0.1), 6, 10)
		"samurai":
			k.ball(BODY_AT, BODY_R, main, 12, 18)
			k.outline = 0.0
			for y: float in [-0.14, -0.04, 0.06, 0.16]:
				k.band(BODY_AT, BODY_R, y, y + 0.03, accent)
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.3, 0.63, 0), Vector3(0.16, 0.08, 0.16), main.darkened(0.2), 6, 10)
		"gladiator":
			k.ball(BODY_AT, BODY_R, second, 12, 18)
			k.outline = 0.0
			k.round_patch(BODY_AT, BODY_R, 0.0, 0.03, 0.2, 0.18, main, 0.006, 20)
			k.band(BODY_AT, BODY_R, -0.2, -0.16, main)
			k.outline = 0.02
		"ninja":
			k.ball(BODY_AT, BODY_R, main, 12, 18)
			k.outline = 0.0
			k.band(BODY_AT, BODY_R, -0.12, -0.07, accent)
			k.outline = 0.02
		"witch", "ranger", "bard", "rogue", "mage", "elf":
			k.ball(BODY_AT, BODY_R, main, 12, 18)
			k.outline = 0.0
			k.band(BODY_AT, BODY_R, -0.18, -0.13, accent if hero["shape"] == "bard" else Color("7a4a26") if hero["shape"] == "ranger" else GOLD)
			k.spot(BODY_AT, BODY_R, 0.0, -0.15, 0.045, GOLD)
			if hero["shape"] == "bard":
				for f: float in [-0.3, 0.0, 0.3]:
					k.round_patch(BODY_AT, BODY_R, f, 0.06, 0.05, 0.14, second, 0.006, 12)
			k.outline = 0.02
		"druid":
			k.ball(BODY_AT, BODY_R, main, 12, 18)
			k.outline = 0.0
			k.band(BODY_AT, BODY_R, -0.17, -0.12, accent)
			for f: Vector2 in [Vector2(-0.14, 0.1), Vector2(0.14, 0.04), Vector2(0.0, 0.16), Vector2(-0.2, -0.04), Vector2(0.2, -0.06)]:
				k.spot(BODY_AT, BODY_R, f.x, f.y, 0.05, Color("7ed957"))
			k.outline = 0.02
		"paladin":
			k.ball(BODY_AT, BODY_R, main, 12, 18)
			k.outline = 0.0
			k.round_patch(BODY_AT, BODY_R, 0.0, -0.02, 0.2, 0.25, accent, 0.006, 20)
			k.band(BODY_AT, BODY_R, -0.2, -0.17, second)
			k.spot(BODY_AT, BODY_R, 0.0, 0.02, 0.06, GOLD)
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.29, 0.66, 0), Vector3(0.16, 0.1, 0.16), main.lightened(0.15), 6, 10)
		"barbarian":
			k.ball(BODY_AT, BODY_R, Color(hero.get("tone", "e8ae7c")), 12, 18)
			k.outline = 0.0
			k.band(BODY_AT, BODY_R, -0.2, -0.13, main)
			k.spot(BODY_AT, BODY_R, 0.0, -0.17, 0.05, accent)
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.27, 0.66, 0), Vector3(0.17, 0.11, 0.17), main, 6, 10)
		"alchemist":
			k.ball(BODY_AT, BODY_R, main, 12, 18)
			k.outline = 0.0
			k.band(BODY_AT, BODY_R, -0.17, -0.13, Color("7a4a26"))
			for f: float in [-0.2, 0.0, 0.2]:
				k.spot(BODY_AT, BODY_R, f, -0.15, 0.045, accent if f != 0.0 else Color("ff6fb5"))
			k.outline = 0.02
		"dwarf":
			k.ball(BODY_AT, BODY_R, Color("8a5a2b"), 12, 18)
			k.outline = 0.0
			k.band(BODY_AT, BODY_R, -0.2, -0.12, Color("3a2a1c"))
			k.spot(BODY_AT, BODY_R, 0.0, -0.16, 0.07, accent)
			k.outline = 0.02
		"goblin", "orc":
			k.ball(BODY_AT, BODY_R, second, 12, 18)
			k.outline = 0.0
			k.band(BODY_AT, BODY_R, -0.2, -0.15, accent if hero["shape"] == "goblin" else Color("7a4a26"))
			k.outline = 0.02
		"fairy":
			k.ball(BODY_AT, BODY_R, main, 12, 18)
			k.outline = 0.0
			k.band(BODY_AT, BODY_R, -0.17, -0.12, second)
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.28, 0.62, -0.3), Vector3(0.3, 0.3, 0.035), Color("cdf6ff"), 6, 12)
				k.ball(Vector3(s * 0.22, 0.34, -0.28), Vector3(0.2, 0.2, 0.03), Color("eafbff"), 6, 10)
		"skeleton":
			k.ball(BODY_AT, BODY_R, second, 12, 18)
			k.outline = 0.0
			for f: float in [-0.14, -0.04, 0.06, 0.16]:
				k.band(BODY_AT, BODY_R, f, f + 0.045, main)
			k.outline = 0.02
		"dragon":
			k.ball(BODY_AT, BODY_R, main, 12, 18)
			k.outline = 0.0
			k.round_patch(BODY_AT, BODY_R, 0.0, -0.02, 0.2, 0.27, second, 0.006, 20)
			k.outline = 0.02
			for i in 3:
				k.cone(Vector3(0, 0.66 - i * 0.2, -0.27 + absf(i - 1.0) * 0.02), 0.18, 0.06, Color(hero.get("accent", "ff9d2e")), 6)
		"viking", "pirate", "leprechaun", "wizard", "jester":
			var coat := Color(hero.get("coat", String(main.to_html(false))))
			k.ball(BODY_AT, BODY_R, coat, 12, 18)
			k.outline = 0.0
			k.band(BODY_AT, BODY_R, -0.18, -0.13, GOLD if hero["shape"] != "viking" else Color("6a4a2a"))
			k.spot(BODY_AT, BODY_R, 0.0, -0.15, 0.045, GOLD)
			k.outline = 0.02
		"pharaoh":
			k.ball(BODY_AT, BODY_R, Color("fff6dd"), 12, 18)
			k.ball(Vector3(0, 0.66, 0), Vector3(0.28, 0.1, 0.25), GOLD, 6, 12)
			k.outline = 0.0
			k.band(Vector3(0, 0.66, 0), Vector3(0.28, 0.1, 0.25), -0.02, 0.012, second)
			k.band(BODY_AT, BODY_R, -0.2, -0.16, GOLD)
			k.outline = 0.02
		"mummy":
			k.ball(BODY_AT, BODY_R, main, 12, 18)
			k.outline = 0.0
			for f: float in [-0.18, -0.06, 0.06, 0.18]:
				k.band(BODY_AT, BODY_R, f, f + 0.018, second)
			k.outline = 0.02
		"terracotta":
			k.ball(BODY_AT, BODY_R, main, 12, 18)
			k.outline = 0.0
			for row in 4:
				for col in 5:
					var x := (col - 2) * 0.095 + (0.047 if row % 2 == 1 else 0.0)
					k.spot(BODY_AT, BODY_R, x, 0.14 - row * 0.09, 0.03, second)
			k.outline = 0.02
		"matryoshka":
			k.ball(BODY_AT, Vector3(0.36, 0.34, 0.32), main, 12, 18)
			k.outline = 0.0
			k.round_patch(BODY_AT, Vector3(0.36, 0.34, 0.32), 0.0, -0.03, 0.22, 0.26, Color("fff6dd"), 0.006, 20)
			for spot: Vector2 in [Vector2(0.0, 0.05), Vector2(-0.08, -0.06), Vector2(0.08, -0.06), Vector2(0.0, -0.16)]:
				k.spot(BODY_AT, Vector3(0.36, 0.34, 0.32), spot.x, spot.y, 0.05, second)
			k.outline = 0.02
		"nutcracker":
			k.ball(BODY_AT, BODY_R, main, 12, 18)
			k.outline = 0.0
			k.band(BODY_AT, BODY_R, -0.2, -0.14, Color("1a1030"))
			for y: float in [0.1, 0.0, -0.1]:
				k.spot(BODY_AT, BODY_R, 0.0, y, 0.03, GOLD)
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.28, 0.66, 0), Vector3(0.12, 0.05, 0.12), GOLD, 4, 10)
		"kokeshi":
			k.cyl(Vector3(0, 0.16, 0), 0.54, 0.31, 0.25, main.lightened(0.1), 18)
			k.outline = 0.0
			for y: float in [0.26, 0.42, 0.56]:
				k.torus(Vector3(0, y, 0), 0.29 - (y - 0.26) * 0.14, 0.02, accent, 18, 3)
			k.outline = 0.02
		"genie":
			k.ball(BODY_AT, BODY_R, main, 12, 18)
			k.outline = 0.0
			k.round_patch(BODY_AT, BODY_R, 0.0, 0.02, 0.15, 0.25, Color(hero.get("coat", "7f5cff")), 0.006, 20)
			k.band(BODY_AT, BODY_R, -0.2, -0.15, GOLD)
			k.outline = 0.02
		"vampire":
			k.ball(BODY_AT, BODY_R, Color("141026"), 12, 18)
			k.outline = 0.0
			k.round_patch(BODY_AT, BODY_R, 0.0, 0.08, 0.1, 0.17, Color("fffdf4"), 0.006, 16)
			k.spot(BODY_AT, BODY_R, 0.0, 0.06, 0.03, accent)
			k.outline = 0.02
			for s: float in [-1.0, 1.0]:  # The collar, standing up.
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.35), Vector3(s * 0.19, 0.76, -0.1)))
				k.ball(Vector3(0, 0.05, 0), Vector3(0.16, 0.2, 0.03), accent, 6, 10)
				k.pop()
		"yeti":
			k.ball(BODY_AT, BODY_R, main, 12, 18)
			k.outline = 0.0
			k.round_patch(BODY_AT, BODY_R, 0.0, -0.03, 0.17, 0.2, second, 0.006, 18)
			k.outline = 0.02
		"kappa":
			k.ball(BODY_AT, BODY_R, main, 12, 18)
			k.outline = 0.0
			k.round_patch(BODY_AT, BODY_R, 0.0, -0.03, 0.17, 0.22, Color("f0f4c8"), 0.006, 18)
			k.outline = 0.02
			k.ball(Vector3(0, 0.48, -0.17), Vector3(0.3, 0.3, 0.16), Color("7a5a3c"), 8, 14)
		"troll":
			k.ball(BODY_AT, BODY_R, main, 12, 18)
			k.outline = 0.0
			k.band(BODY_AT, BODY_R, -0.2, -0.05, Color("7a5a3c"))
			k.outline = 0.02
		"bamboo":
			k.cyl(Vector3(0, 0.14, 0), 0.56, 0.3, 0.3, main.darkened(0.04), 18)
			k.torus(Vector3(0, 0.42, 0), 0.3, 0.03, main.darkened(0.2), 18, 5)
		"lantern":
			k.ball(BODY_AT, BODY_R, accent, 12, 18)
			k.outline = 0.0
			k.band(BODY_AT, BODY_R, -0.18, -0.13, GOLD)
			k.outline = 0.02
		"sushi":
			k.ball(BODY_AT, BODY_R, Color("26304a"), 12, 18)
		"boba":
			k.ball(BODY_AT, BODY_R, second, 12, 18)
		"taco":
			k.ball(BODY_AT, BODY_R, second.lightened(0.1), 12, 18)
		"pizza":
			k.ball(BODY_AT, BODY_R, main.darkened(0.08), 12, 18)
		"burger":
			k.ball(BODY_AT, BODY_R, main, 12, 18)
		"teapot":
			k.ball(BODY_AT, BODY_R, second, 12, 18)
		"avocado":
			k.ball(BODY_AT, BODY_R, second, 12, 18)
			k.outline = 0.0
			k.ball(Vector3(0, 0.42, 0.21), Vector3(0.2, 0.2, 0.1), Color("7a4a26"), 8, 14)
			k.ball(Vector3(-0.06, 0.5, 0.3), Vector3(0.05, 0.05, 0.012), Color("b57a4a"), 3, 6)
			k.outline = 0.02
		"pineapple":
			k.ball(BODY_AT, BODY_R, main.darkened(0.06), 12, 18)
		"mushroom":
			k.ball(BODY_AT, BODY_R, second, 12, 18)
		"snowman":
			k.ball(BODY_AT, Vector3(0.36, 0.34, 0.32), main, 12, 18)
			k.outline = 0.0
			for y: float in [0.08, -0.02, -0.12]:
				k.spot(BODY_AT, Vector3(0.36, 0.34, 0.32), 0.0, y, 0.03, Color("2a2438"))
			k.outline = 0.02
			k.torus(Vector3(0, 0.72, 0), 0.25, 0.06, accent, 18, 6)
			k.ball(Vector3(0.16, 0.6, 0.2), Vector3(0.06, 0.12, 0.04), accent, 5, 8)
		"cactus":
			k.ball(BODY_AT, BODY_R, main.darkened(0.06), 12, 18)
			k.outline = 0.0
			for spot: Vector2 in [Vector2(-0.14, 0.1), Vector2(0.14, 0.08), Vector2(0.0, -0.08), Vector2(-0.16, -0.12), Vector2(0.16, -0.14)]:
				k.spot(BODY_AT, BODY_R, spot.x, spot.y, 0.02, Color("fffdf4"))
			k.outline = 0.02
		"tulip":
			k.ball(BODY_AT, BODY_R, second, 12, 18)
			for s: float in [-1.0, 1.0]:
				k.push(Transform3D(Basis(Vector3.BACK, s * -0.55), Vector3(s * 0.2, 0.32, 0.14)))
				k.ball(Vector3(0, 0.1, 0), Vector3(0.09, 0.26, 0.05), second.lightened(0.16), 6, 8)
				k.pop()
		"pumpkin":
			k.ball(BODY_AT, BODY_R, second, 12, 18)
			k.outline = 0.0
			k.band(BODY_AT, BODY_R, -0.18, -0.12, Color(hero.get("accent", "ffffff")))
			k.outline = 0.02
		_:
			return false
	return true


# --- Animals from the data ------------------------------------------------------------------------------

## Any animal whose row says what it's made of: `ears`, `muzzle` and `marks`.
static func animal(a: Avatar3D, k: MeshKit, hero: Dictionary, fur: Color, belly: Color, hat: int, muzzle: bool) -> void:
	var marks: Array = hero.get("marks", [])
	var bare := hat == 0
	k.ball(Vector3.ZERO, HEAD, fur, 16, 24)
	if marks.has("mane") and hat < 2:
		for i in 12:
			var t := TAU * i / 12.0
			if bare or sin(t) < 0.3:
				k.ball(Vector3(cos(t) * 0.48, sin(t) * 0.44, -0.1), Vector3(0.17, 0.17, 0.18), Color(hero["accent"]), 6, 9)
	if hat < 2:
		_animal_ears(k, String(hero.get("ears", "none")), fur, belly, Color(hero.get("accent", "ffffff")), hat)
	k.outline = 0.0
	if marks.has("stripes"):
		for s: float in [-0.13, 0.0, 0.13]:
			k.round_patch(Vector3.ZERO, HEAD, s, 0.31 - absf(s) * 0.3, 0.026, 0.09, Color("2a2438"), 0.006, 12)
		for s: float in [-1.0, 1.0]:
			for y: float in [-0.02, -0.14]:
				k.round_patch(Vector3.ZERO, HEAD, s * 0.42, y, 0.075, 0.022, Color("2a2438"), 0.006, 12)
	if marks.has("eye_patches"):
		for s: float in [-1.0, 1.0]:
			k.round_patch(Vector3.ZERO, HEAD, s * 0.21, 0.04, 0.15, 0.16, Color("2b2448"), 0.005, 20)
	if marks.has("eye_mask"):
		k.round_patch(Vector3.ZERO, HEAD, 0.0, -0.06, 0.34, 0.2, belly, 0.002, 24)
	if marks.has("cheeks_white"):
		for s: float in [-1.0, 1.0]:
			k.round_patch(Vector3.ZERO, HEAD, s * 0.24, -0.16, 0.2, 0.18, belly, 0.002, 20)
	if marks.has("patches"):
		k.round_patch(Vector3.ZERO, HEAD, 0.14, 0.34, 0.16, 0.08, Color("2b2448"), 0.002, 18)
		k.round_patch(Vector3.ZERO, HEAD, -0.42, 0.02, 0.06, 0.14, Color("2b2448"), 0.002, 16)
	if marks.has("mask_brown"):
		for s: float in [-1.0, 1.0]:
			k.push(Transform3D(Basis(Vector3.BACK, s * 0.28), Vector3.ZERO))
			k.round_patch(Vector3.ZERO, HEAD, s * 0.22, 0.02, 0.12, 0.17, Color(hero.get("accent", "7a4a26")), 0.005, 18)
			k.pop()
	if marks.has("spots"):
		for spot: Vector2 in [Vector2(-0.3, 0.2), Vector2(0.3, 0.26), Vector2(0.0, 0.34), Vector2(0.38, -0.1), Vector2(-0.38, -0.08)]:
			k.round_patch(Vector3.ZERO, HEAD, spot.x, spot.y, 0.05, 0.05, Color(hero.get("accent", "7a4a26")), 0.005, 12)
	k.outline = 0.02
	if marks.has("horns") and bare:
		for s: float in [-1.0, 1.0]:
			k.push(Transform3D(Basis(Vector3.BACK, s * -0.7), Vector3(s * 0.32, 0.34, 0)))
			k.cone(Vector3.ZERO, 0.2, 0.06, Color("fff6dd"), 8)
			k.pop()
	if marks.has("tuft") and bare:
		for a2: float in [-0.4, 0.0, 0.4]:
			k.push(Transform3D(Basis(Vector3.BACK, a2), Vector3(a2 * 0.24, 0.42, 0.06)))
			k.ball(Vector3(0, 0.06, 0), Vector3(0.08, 0.13, 0.08), belly, 6, 8)
			k.pop()
	var top_eyes: bool = marks.has("top_eyes")
	if top_eyes and hat < 2:
		for s: float in [-1.0, 1.0]:
			k.ball(Vector3(s * 0.23, 0.3, 0.14), Vector3(0.17, 0.17, 0.16), fur, 8, 10)
	if marks.has("big_eyes"):
		a._eyes(k, 0.06, 0.34, 0.22, 0.23, Color("3a2008"), Color("ffcf56"))
	elif top_eyes:
		a._eyes(k, 0.25, 0.38, 0.22, 0.115)
	else:
		a._eyes(k, 0.08, 0.37, 0.2, 0.125)
	if not muzzle:
		return
	match String(hero.get("muzzle", "patch")):
		"patch":
			k.round_patch(Vector3.ZERO, HEAD, 0.0, -0.17, 0.17, 0.125, belly)
			k.outline = 0.0
			k.ball(Vector3(0, -0.105, 0.437), Vector3(0.045, 0.03, 0.02), Color("1a1030"), 6, 9)
			k.outline = 0.02
			a._smile(k, -0.15, 0.445, 0.085)
		"long":  # Comes to a point.
			k.ball(Vector3(0, -0.12, 0.38), Vector3(0.17, 0.11, 0.17), belly, 8, 12)
			k.ball(Vector3(0, -0.09, 0.545), Vector3(0.045, 0.035, 0.03), Color("1a1030"), 5, 8)
			a._smile(k, -0.16, 0.45, 0.075)
		"snoot":  # Big and soft, nostrils well apart.
			k.round_patch(Vector3.ZERO, HEAD, 0.0, -0.17, 0.27, 0.2, belly)
			k.outline = 0.0
			for s: float in [-0.095, 0.095]:
				k.round_patch(Vector3.ZERO, HEAD, s, -0.09, 0.03, 0.024, Color("3a2438"), 0.012, 12)
			k.outline = 0.02
			a._smile(k, -0.25, 0.42, 0.09)
		"beak":
			k.ball(Vector3(0, -0.12, 0.42), Vector3(0.13, 0.08, 0.12), Color("ffb52e"), 8, 12)
			a._smile(k, -0.25, 0.4, 0.07)
		"wide":  # All mouth.
			k.round_patch(Vector3.ZERO, HEAD, 0.0, -0.18, 0.3, 0.17, belly)
			a._smile(k, -0.17, 0.43, 0.12)
		"long_jaw":  # A big wide mouth, with teeth that don't quite fit in.
			k.round_patch(Vector3.ZERO, HEAD, 0.0, -0.16, 0.32, 0.18, belly)
			k.outline = 0.0
			for s: float in [-0.09, 0.09]:
				k.round_patch(Vector3.ZERO, HEAD, s, -0.05, 0.024, 0.018, Color("1a1030"), 0.012, 10)
			k.outline = 0.02
			for s: float in [-0.24, 0.24]:
				k.push(Transform3D(Basis(Vector3.RIGHT, PI), _on(s, -0.17, 0.0)))
				k.cone(Vector3.ZERO, 0.08, 0.035, Color("fffdf4"), 6)
				k.pop()
			a._smile(k, -0.15, 0.44, 0.11)
		"trunk":
			k.tube(PackedVector3Array([Vector3(0, -0.04, 0.38), Vector3(0, -0.12, 0.5), Vector3(0, -0.28, 0.54), Vector3(0.04, -0.44, 0.52)]), 0.1, fur.darkened(0.04), false, 10, 0.06)
			a._smile(k, -0.3, 0.33, 0.07)


static func _animal_ears(k: MeshKit, kind: String, fur: Color, belly: Color, _accent: Color, hat: int) -> void:
	var some := hat == 0
	for s: float in [-1.0, 1.0]:
		match kind:
			"pointy":
				if some:
					k.push(Transform3D(Basis(Vector3.BACK, s * -0.3), Vector3(s * 0.3, 0.34, 0)))
					k.cone(Vector3.ZERO, 0.28, 0.13, fur, 8)
					k.outline = 0.0
					k.cone(Vector3(0, 0.0, 0.045), 0.2, 0.08, belly, 6)
					k.outline = 0.02
					k.pop()
			"round", "round_dark":
				if some:
					var c := Color("2b2448") if kind == "round_dark" else fur
					k.ball(Vector3(s * 0.33, 0.36, -0.02), Vector3(0.13, 0.13, 0.08), c, 8, 10)
					if kind == "round":
						k.outline = 0.0
						k.ball(Vector3(s * 0.33, 0.36, 0.04), Vector3(0.075, 0.075, 0.04), belly, 5, 8)
						k.outline = 0.02
			"long":
				if some:
					k.push(Transform3D(Basis(Vector3.BACK, s * -0.14), Vector3(s * 0.24, 0.36, -0.02)))
					k.ball(Vector3(0, 0.24, 0), Vector3(0.09, 0.3, 0.06), fur, 8, 10)
					k.outline = 0.0
					k.ball(Vector3(0, 0.24, 0.045), Vector3(0.045, 0.22, 0.02), belly, 4, 8)
					k.outline = 0.02
					k.pop()
			"fan":
				k.ball(Vector3(s * 0.66, 0.06, -0.08), Vector3(0.3, 0.34, 0.05), fur, 8, 14)
				k.outline = 0.0
				k.ball(Vector3(s * 0.66, 0.06, -0.03), Vector3(0.2, 0.24, 0.02), Color("ffc2d0"), 4, 10)
				k.outline = 0.02
			"small":
				k.ball(Vector3(s * 0.46, 0.24, -0.04), Vector3(0.1, 0.07, 0.07), fur.darkened(0.1), 6, 8)
			"fluffy":
				k.ball(Vector3(s * 0.52, 0.2, -0.03), Vector3(0.2, 0.2, 0.08), fur, 8, 12)
				k.outline = 0.0
				k.ball(Vector3(s * 0.52, 0.2, 0.04), Vector3(0.12, 0.12, 0.04), belly, 5, 8)
				k.outline = 0.02
			"tufts":
				if some:
					k.push(Transform3D(Basis(Vector3.BACK, s * -0.55), Vector3(s * 0.32, 0.32, 0)))
					k.cone(Vector3.ZERO, 0.22, 0.09, fur.darkened(0.16), 7)
					k.pop()


# --- Kids' hair -------------------------------------------------------------------------------------------

static func hair(k: MeshKit, style: String, c: Color, hat: int) -> void:
	match style:
		"curly":
			if hat == 0:
				for i in 9:
					var t := TAU * i / 9.0
					k.ball(Vector3(cos(t) * 0.32, 0.42, sin(t) * 0.28 - 0.05), Vector3(0.15, 0.13, 0.15), c, 6, 9)
				k.ball(Vector3(0, 0.5, -0.04), Vector3(0.16, 0.12, 0.16), c, 6, 9)
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.48, 0.1, 0.0), Vector3(0.1, 0.14, 0.14), c, 6, 8)
		"afro":
			if hat == 0:
				k.ball(Vector3(0, 0.3, -0.2), Vector3(0.68, 0.5, 0.56), c, 12, 18)
		"bob":
			for s: float in [-1.0, 1.0]:
				k.ball(Vector3(s * 0.45, -0.1, 0.04), Vector3(0.12, 0.28, 0.2), c, 8, 10)
		"wavy":
			if hat < 2:
				for s: float in [-1.0, 1.0]:
					k.ball(Vector3(s * 0.46, -0.05, 0.02), Vector3(0.13, 0.2, 0.17), c, 6, 9)
					k.ball(Vector3(s * 0.5, -0.3, 0.0), Vector3(0.14, 0.2, 0.15), c, 6, 9)
				k.ball(Vector3(0, -0.22, -0.26), Vector3(0.44, 0.34, 0.22), c, 8, 12)


# --- What flops about -------------------------------------------------------------------------------------

## The extra bits that flop, in the same rows as Avatar3D._wiggle_list.
static func wiggles(hero: Dictionary, hat: int, cover: String, plain: bool, has_back: bool) -> Array:
	var out: Array = []
	var head := cover != "whole" and not plain
	var bare := head and hat == 0
	var some := head and hat < 2
	var side := Vector3.BACK
	var nod := Vector3.RIGHT
	var turn := Vector3.UP
	match String(hero["kind"]):
		"kid":
			match String(hero.get("style")):
				"braids":
					if some:
						for part: String in ["braid_l", "braid_r"]:
							out.append([part, true, Vector3(-0.42 if part == "braid_l" else 0.42, -0.02, -0.06), nod, 0.06, 0.45, 2.4, 13.0])
				"pigtails":
					if bare:
						for part: String in ["pigtail_l", "pigtail_r"]:
							out.append([part, true, Vector3(-0.46 if part == "pigtail_l" else 0.46, 0.24, -0.04), side, 0.08, 0.5, 2.6, 13.0])
				"topknot":
					if bare: out.append(["topknot", true, Vector3(0, 0.48, -0.03), side, 0.05, 0.26, 2.5, 13.0])
		"animal":
			if not has_back and hero.has("tail"):
				var tail := String(hero["tail"])
				match tail:
					"bushy": out.append(["tail_bushy", false, Vector3(0, 0.3, -0.28), side, 0.2, 0.5, 2.4, 11.0])
					"striped": out.append(["tail_striped", false, Vector3(0, 0.3, -0.28), side, 0.22, 0.5, 2.4, 11.0])
					"tuft": out.append(["tail_tuft", false, Vector3(0, 0.38, -0.3), side, 0.2, 0.6, 2.2, 12.0])
					"stub": out.append(["tail_stub", false, Vector3(0, 0.34, -0.3), turn, 0.3, 0.7, 6.0, 15.0])
					"thick": out.append(["tail_thick", false, Vector3(0, 0.3, -0.26), side, 0.14, 0.4, 2.0, 10.0])
					"croc": out.append(["tail_croc", false, Vector3(0, 0.26, -0.26), side, 0.18, 0.5, 2.0, 10.0])
		_:
			match String(hero["shape"]):
				"knight", "gladiator":
					if bare: out.append(["plume", true, Vector3(0, 0.42, -0.06), side, 0.05, 0.36, 2.6, 14.0])
				"ninja":
					if some: out.append(["bandana_tail", true, Vector3(0.0, 0.18, -0.48), side, 0.14, 0.7, 2.6, 15.0])
				"pirate":
					if some: out.append(["bandana_tail", true, Vector3(0.0, 0.2, -0.46), side, 0.14, 0.6, 2.6, 15.0])
				"mummy":
					if head: out.append(["wrap_end", true, Vector3(0.38, 0.14, 0.2), side, 0.1, 0.55, 2.4, 13.0])
				"jester":
					if bare:
						for part: String in ["cap_l", "cap_r", "cap_m"]:
							var x := -0.28 if part == "cap_l" else (0.28 if part == "cap_r" else 0.0)
							out.append([part, true, Vector3(x, 0.4, -0.02), side, 0.08, 0.42, 3.0, 15.0])
				"genie":
					if bare: out.append(["topknot_genie", true, Vector3(0, 0.44, -0.02), side, 0.1, 0.5, 2.4, 13.0])
				"bamboo":
					if bare: out.append(["bamboo_leaves", true, Vector3(0, 0.5, 0), side, 0.08, 0.34, 2.4, 13.0])
				"lantern":
					if head: out.append(["tassel", true, Vector3(0, -0.56, 0), side, 0.14, 0.6, 2.6, 14.0])
				"pineapple":
					if bare: out.append(["crown_leaves", true, Vector3(0, 0.44, 0), side, 0.05, 0.22, 2.6, 13.0])
	return out


static func wiggle(k: MeshKit, part: String, hero: Dictionary, skin: Dictionary) -> void:
	var s := -1.0 if part.ends_with("_l") else 1.0
	var accent := Color(hero.get("accent", "ffffff"))
	match part:
		"braid_l", "braid_r":
			var hair_c := Color(hero["hair"])
			k.ball(Vector3(0, -0.1, -0.02), Vector3(0.1, 0.11, 0.1), hair_c, 6, 8)
			k.ball(Vector3(s * 0.02, -0.26, 0.0), Vector3(0.085, 0.1, 0.085), hair_c, 6, 8)
			k.ball(Vector3(s * 0.03, -0.41, 0.01), Vector3(0.07, 0.085, 0.07), hair_c, 6, 8)
			k.torus(Vector3(s * 0.03, -0.49, 0.01), 0.045, 0.018, Avatar3D._main(hero, skin, "top"), 10, 4)
		"pigtail_l", "pigtail_r":
			var hair_c := Color(hero["hair"])
			k.ball(Vector3(s * 0.05, -0.02, 0), Vector3(0.06, 0.06, 0.06), Avatar3D._main(hero, skin, "top"), 5, 8)
			k.ball(Vector3(s * 0.15, -0.2, 0), Vector3(0.14, 0.26, 0.14), hair_c, 8, 10)
		"topknot":
			var hair_c := Color(hero["hair"])
			k.ball(Vector3(0, 0.08, 0), Vector3(0.17, 0.15, 0.17), hair_c, 8, 10)
			k.torus(Vector3(0, -0.02, 0), 0.11, 0.024, Avatar3D._main(hero, skin, "top"), 12, 4)
		"tail_bushy":
			var fur := Avatar3D._main(hero, skin, "fur")
			var tip := Avatar3D._second(hero, skin, "belly")
			k.ball(Vector3(0, 0.06, -0.14), Vector3(0.13, 0.15, 0.16), fur, 6, 10)
			k.ball(Vector3(0, 0.26, -0.24), Vector3(0.18, 0.22, 0.17), fur, 8, 10)
			k.ball(Vector3(0, 0.46, -0.24), Vector3(0.14, 0.15, 0.13), tip, 6, 9)
		"tail_striped":
			var fur := Avatar3D._main(hero, skin, "fur")
			k.tube(PackedVector3Array([Vector3.ZERO, Vector3(0, 0.1, -0.2), Vector3(0.06, 0.35, -0.28), Vector3(0.02, 0.6, -0.24)]), 0.08, fur, false, 8, 0.065)
			k.outline = 0.0
			for at: Vector3 in [Vector3(0.0, 0.1, -0.2), Vector3(0.04, 0.28, -0.26), Vector3(0.05, 0.46, -0.27)]:
				k.ball(at, Vector3(0.09, 0.024, 0.09), Color(hero.get("mark_c", "2a2438")), 3, 8)
			k.outline = 0.02
			k.ball(Vector3(0.02, 0.62, -0.24), Vector3(0.08, 0.08, 0.08), Color(hero.get("mark_c", "2a2438")), 6, 8)
		"tail_tuft":
			var fur := Avatar3D._main(hero, skin, "fur")
			k.tube(PackedVector3Array([Vector3.ZERO, Vector3(0, -0.1, -0.1), Vector3(0, -0.28, -0.14)]), 0.035, fur, false, 7, 0.03)
			k.ball(Vector3(0, -0.36, -0.14), Vector3(0.08, 0.11, 0.08), Color(hero["accent"]), 6, 8)
		"tail_stub":
			k.ball(Vector3(0, 0.0, -0.06), Vector3(0.08, 0.08, 0.1), Avatar3D._main(hero, skin, "fur").darkened(0.1), 6, 8)
		"tail_thick":
			var fur := Avatar3D._main(hero, skin, "fur")
			k.tube(PackedVector3Array([Vector3.ZERO, Vector3(0, -0.18, -0.22), Vector3(0, -0.26, -0.5)]), 0.16, fur, false, 10, 0.05)
		"tail_croc":
			var fur := Avatar3D._main(hero, skin, "fur")
			k.tube(PackedVector3Array([Vector3.ZERO, Vector3(0, -0.14, -0.22), Vector3(0, -0.2, -0.5)]), 0.14, fur, false, 8, 0.03)
			for f: float in [0.2, 0.42]:
				k.cone(Vector3(0, -0.04 - f * 0.26, -f * 1.0), 0.09, 0.04, fur.darkened(0.2), 5)
		"plume":
			var c := accent
			for i in 5:
				var t := i / 4.0
				k.ball(Vector3(0, 0.16 + sin(t * PI) * 0.1, -0.16 + t * 0.32 - 0.14), Vector3(0.075, 0.16, 0.09), c.lightened(0.1 * (i % 2)), 6, 8)
		"bandana_tail":
			var path := PackedVector3Array([Vector3.ZERO, Vector3(0.1, -0.08, -0.1), Vector3(0.22, -0.2, -0.14)])
			k.tube(path, 0.05, accent, false, 5, 0.02)
			k.tube(PackedVector3Array([Vector3.ZERO, Vector3(-0.1, -0.1, -0.1), Vector3(-0.2, -0.26, -0.12)]), 0.05, accent, false, 5, 0.02)
		"wrap_end":
			var c := Avatar3D._second(hero, skin, "second")
			k.tube(PackedVector3Array([Vector3.ZERO, Vector3(0.1, -0.08, 0.02), Vector3(0.18, -0.24, 0.02)]), 0.03, c, false, 4, 0.02)
		"cap_l", "cap_r", "cap_m":
			var main := Avatar3D._main(hero, skin, "main")
			var second := Avatar3D._second(hero, skin, "second")
			var x := -1.0 if part == "cap_l" else (1.0 if part == "cap_r" else 0.0)
			var c := second if part == "cap_m" else main
			k.tube(PackedVector3Array([Vector3(0, -0.06, 0), Vector3(x * 0.16, 0.2, 0), Vector3(x * 0.38, 0.28, 0), Vector3(x * 0.46, 0.14, 0)]), 0.16, c, false, 8, 0.03)
			k.ball(Vector3(x * 0.46, 0.08, 0), Vector3(0.06, 0.06, 0.06), GOLD, 5, 7)
		"topknot_genie":
			k.ball(Vector3(0, 0.04, 0), Vector3(0.08, 0.06, 0.08), GOLD, 5, 8)
			k.tube(PackedVector3Array([Vector3(0, 0.04, 0), Vector3(0.02, 0.22, 0), Vector3(0.16, 0.34, 0), Vector3(0.26, 0.24, 0)]), 0.075, Color("141026"), false, 7, 0.02)
		"bamboo_leaves":
			var leaf := Color("6ccf5a")
			k.tube(PackedVector3Array([Vector3(0.1, -0.04, 0), Vector3(0.12, 0.12, 0), Vector3(0.16, 0.26, 0)]), 0.02, Color("3f9c4e"), false, 5)
			for at: Array in [[Vector3(0.16, 0.26, 0), 0.5], [Vector3(0.14, 0.18, 0), 2.0], [Vector3(0.14, 0.12, 0), 0.7]]:
				k.push(Transform3D(Basis(Vector3.BACK, -float(at[1])), at[0]))
				k.ball(Vector3(0, 0.17, 0), Vector3(0.055, 0.2, 0.014), leaf, 6, 8)
				k.pop()
		"tassel":
			k.cyl(Vector3(0, -0.1, 0), 0.1, 0.02, 0.02, GOLD, 6)
			k.ball(Vector3(0, -0.13, 0), Vector3(0.045, 0.045, 0.045), GOLD, 4, 7)
			k.cyl(Vector3(0, -0.38, 0), 0.24, 0.07, 0.03, Color("e8282f"), 8)
		"crown_leaves":
			var leaf := Color("35b05a")
			for i in 8:
				var t := TAU * i / 8.0
				k.push(Transform3D(Basis(Vector3(sin(t), 0, -cos(t)), 0.55), Vector3(cos(t) * 0.08, 0.0, sin(t) * 0.08)))
				k.ball(Vector3(0, 0.2, 0), Vector3(0.06, 0.25, 0.024), leaf, 6, 8)
				k.pop()
			k.ball(Vector3(0, 0.26, 0), Vector3(0.05, 0.3, 0.05), leaf.lightened(0.1), 6, 8)
