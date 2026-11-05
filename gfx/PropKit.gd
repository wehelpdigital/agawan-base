class_name PropKit
extends RefCounted
## Every prop on the maps, drawn with MeshKit. A prop stands on y = 0, is about one tile (1.5 m) wide,
## and may vary a little with `v` (0..1).


static func draw(kit: MeshKit, prop: String, at: Vector3, yaw := 0.0, scale := 1.0, v := 0.5, accent := Color("ff5a7a")) -> void:
	kit.push(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * scale), at))
	match prop:
		"crate": _crate(kit, v)
		"stall": _stall(kit, accent)
		"hay": _hay(kit)
		"rock": _rock(kit, v, Color("9a93a8"))
		"stump": _stump(kit)
		"barrel": _barrel(kit)
		"jeep": _jeep(kit, accent, v)
		"cone_stack": _cones(kit)
		"crystal": _crystal(kit, accent)
		"ice_block": _ice(kit)
		"snowman": _snowman(kit, accent)
		"cake": _cake(kit, v)
		"gumdrop": _gumdrop(kit, v)
		"donut": _donut(kit, v)
		"cabinet": _cabinet(kit, accent)
		"neon_block": _neon(kit, accent, v)
		"pillar": _pillar(kit)
		"statue": _statue(kit)
		"chest": _chest(kit)
		"pod": _pod(kit, accent)
		"tomb": _tomb(kit)
		"pumpkin": _pumpkin(kit)
		"tire": _tire(kit, v)
		"hut": _hut(kit)
		"palm": _palm(kit, v)
		"banderitas": _banderitas(kit)
		"bush": _bush(kit, v)
		"pine": _pine(kit, Color("2f9a4e"))
		"pine_snow": _pine(kit, Color("eaf8ff"))
		"umbrella": _umbrella(kit, accent)
		"boat": _boat(kit, accent)
		"building": _building(kit, v)
		"lamp": _lamp(kit)
		"tree": _tree(kit, Color("53b94b"))
		"jungle_tree": _tree(kit, Color("2f8f4a"), 1.5)
		"spire": _spire(kit)
		"mangrove": _mangrove(kit)
		"mushroom": _mushroom(kit, accent)
		"lily": _lily(kit)
		"lollipop": _lollipop(kit, v)
		"cone": _icecream(kit, v)
		"neon_tower": _neon_tower(kit, accent)
		"ship": _ship(kit, accent)
		"dish": _dish(kit)
		"dead_tree": _dead_tree(kit)
		_: kit.box(Vector3(0, 0.6, 0), Vector3(1.3, 1.2, 1.3), accent, 0.08)
	kit.pop()


# --- Blocks: fill one wall tile -------------------------------------------------------------------

static func _crate(k: MeshKit, v: float) -> void:
	var wood := Color("e0a860").lerp(Color("c98c4a"), v)
	k.box(Vector3(0, 0.65, 0), Vector3(1.4, 1.3, 1.4), wood, 0.08)
	var strap := wood.darkened(0.25)
	k.decal_box(Vector3(0, 0.65, 0.71), Vector3(1.24, 0.16, 0.02), strap)
	k.decal_box(Vector3(0, 0.65, -0.71), Vector3(1.24, 0.16, 0.02), strap)
	k.decal_box(Vector3(0.71, 0.65, 0), Vector3(0.02, 0.16, 1.24), strap)
	k.decal_box(Vector3(-0.71, 0.65, 0), Vector3(0.02, 0.16, 1.24), strap)
	k.decal_box(Vector3(0, 1.31, 0), Vector3(1.0, 0.02, 0.16), strap)
	if v > 0.65:
		k.box(Vector3(0.1, 1.6, -0.05), Vector3(0.8, 0.6, 0.8), wood.lightened(0.08), 0.06)


static func _stall(k: MeshKit, accent: Color) -> void:
	k.box(Vector3(0, 0.45, 0), Vector3(1.4, 0.9, 1.3), Color("c78c52"), 0.05)
	k.decal_box(Vector3(0, 0.75, 0.66), Vector3(1.2, 0.1, 0.02), accent)
	for i in 3:
		k.ball(Vector3(-0.42 + i * 0.42, 1.02, 0.2), Vector3(0.17, 0.17, 0.17), [Color("ffb03b"), Color("7ed957"), Color("ff6b6b")][i], 4, 7)
	for s: float in [-0.62, 0.62]:
		k.box(Vector3(s, 1.15, -0.4), Vector3(0.09, 1.3, 0.09), Color("8a5a34"))
	k.box(Vector3(0, 1.84, -0.1), Vector3(1.6, 0.14, 1.1), accent, 0.03)


static func _hay(k: MeshKit) -> void:
	var straw := Color("f2cf63")
	k.box(Vector3(0, 0.55, 0), Vector3(1.4, 1.1, 1.3), straw, 0.12)
	k.decal_box(Vector3(-0.34, 0.55, 0.66), Vector3(0.1, 1.04, 0.02), Color("b98c3a"))
	k.decal_box(Vector3(0.34, 0.55, 0.66), Vector3(0.1, 1.04, 0.02), Color("b98c3a"))
	k.decal_box(Vector3(-0.34, 1.11, 0), Vector3(0.1, 0.02, 1.2), Color("b98c3a"))
	k.decal_box(Vector3(0.34, 1.11, 0), Vector3(0.1, 0.02, 1.2), Color("b98c3a"))


static func _rock(k: MeshKit, v: float, tone: Color) -> void:
	var c := tone.lerp(tone.darkened(0.15), v)
	k.ball(Vector3(0, 0.6, 0), Vector3(0.78, 0.72, 0.74), c, 4, 7)
	k.ball(Vector3(0.35, 0.28, 0.35), Vector3(0.36, 0.3, 0.34), c.lightened(0.1), 3, 6)
	k.ball(Vector3(-0.38, 0.22, -0.2), Vector3(0.3, 0.24, 0.3), c.darkened(0.08), 3, 6)


static func _stump(k: MeshKit) -> void:
	k.cyl(Vector3.ZERO, 1.05, 0.72, 0.6, Color("9a6a3d"), 9)
	k.outline = 0.0
	k.cyl(Vector3(0, 1.055, 0), 0.01, 0.52, 0.52, Color("e8c98c"), 9)
	k.outline = 0.035


static func _barrel(k: MeshKit) -> void:
	k.cyl(Vector3.ZERO, 0.65, 0.5, 0.66, Color("c17f45"), 10)
	k.cyl(Vector3(0, 0.65, 0), 0.65, 0.66, 0.5, Color("c17f45"), 10)
	k.outline = 0.0
	k.torus(Vector3(0, 0.3, 0), 0.6, 0.05, Color("6a6a7a"), 12, 4)
	k.torus(Vector3(0, 1.0, 0), 0.6, 0.05, Color("6a6a7a"), 12, 4)
	k.outline = 0.035


static func _jeep(k: MeshKit, accent: Color, v: float) -> void:
	# A chunky parked bus in the spirit of a decorated jeepney, seen from above.
	var body: Color = [Color("ff5a4e"), Color("3aa6ff"), Color("ffc21f"), Color("35d07f")][int(v * 3.99)]
	k.box(Vector3(0, 0.55, 0), Vector3(1.28, 0.7, 1.42), body, 0.08)
	k.box(Vector3(0, 1.2, -0.08), Vector3(1.2, 0.62, 1.2), Color("fff3d6"), 0.05)
	k.box(Vector3(0, 1.58, -0.08), Vector3(1.36, 0.14, 1.32), accent, 0.04)
	k.decal_box(Vector3(0, 1.22, 0.53), Vector3(0.98, 0.38, 0.02), Color("3a2f7a"))
	k.decal_box(Vector3(0, 0.62, 0.72), Vector3(1.0, 0.16, 0.02), Color("fff3d6"))
	for s: float in [-0.46, 0.46]:
		k.ball(Vector3(s, 0.24, 0.56), Vector3(0.2, 0.2, 0.2), Color("2c2848"), 4, 7)
		k.ball(Vector3(s, 0.24, -0.56), Vector3(0.2, 0.2, 0.2), Color("2c2848"), 4, 7)


static func _cones(k: MeshKit) -> void:
	for p: Vector3 in [Vector3(-0.35, 0, -0.3), Vector3(0.38, 0, -0.1), Vector3(-0.05, 0, 0.38)]:
		k.box(p + Vector3(0, 0.04, 0), Vector3(0.62, 0.08, 0.62), Color("3a3a48"))
		k.cone(p + Vector3(0, 0.08, 0), 1.0, 0.28, Color("ff8a2b"), 8)


static func _crystal(k: MeshKit, accent: Color) -> void:
	k.cyl(Vector3(0, 0, 0), 1.5, 0.42, 0.05, accent.lightened(0.15), 5, false)
	k.push(Transform3D(Basis(Vector3.FORWARD, 0.45), Vector3(0.28, 0, 0.1)))
	k.cyl(Vector3.ZERO, 1.0, 0.28, 0.04, accent, 5, false)
	k.pop()
	k.push(Transform3D(Basis(Vector3.FORWARD, -0.5), Vector3(-0.28, 0, -0.1)))
	k.cyl(Vector3.ZERO, 0.8, 0.26, 0.04, accent.darkened(0.15), 5, false)
	k.pop()


static func _ice(k: MeshKit) -> void:
	k.box(Vector3(0, 0.62, 0), Vector3(1.4, 1.24, 1.4), Color("bdeaff"), 0.14)
	k.decal_box(Vector3(-0.2, 0.9, 0.71), Vector3(0.3, 0.1, 0.02), Color("f4fdff"))
	k.decal_box(Vector3(0.3, 0.5, 0.71), Vector3(0.16, 0.08, 0.02), Color("f4fdff"))


static func _snowman(k: MeshKit, accent: Color) -> void:
	k.ball(Vector3(0, 0.45, 0), Vector3(0.58, 0.52, 0.58), Color("f6fcff"), 5, 9)
	k.ball(Vector3(0, 1.15, 0), Vector3(0.38, 0.38, 0.38), Color("f6fcff"), 5, 9)
	k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.17, 0.34)))
	k.cone(Vector3.ZERO, 0.3, 0.07, Color("ff8a2b"), 6)
	k.pop()
	k.torus(Vector3(0, 0.88, 0), 0.32, 0.08, accent, 10, 4)
	for s: float in [-0.13, 0.13]:
		k.decal_box(Vector3(s, 1.25, 0.34), Vector3(0.07, 0.07, 0.04), Color("24135f"))


static func _cake(k: MeshKit, v: float) -> void:
	var body := Color("fff0c9").lerp(Color("ffd0e8"), v)
	k.cyl(Vector3.ZERO, 0.7, 0.72, 0.72, body, 12)
	k.cyl(Vector3(0, 0.7, 0), 0.5, 0.48, 0.48, Color("ff8ac2"), 12)
	k.ball(Vector3(0, 1.32, 0), Vector3(0.16, 0.16, 0.16), Color("ff3f6a"), 4, 7)
	k.outline = 0.0
	k.torus(Vector3(0, 0.7, 0), 0.68, 0.07, Color("ffffff"), 12, 4)
	k.outline = 0.035


static func _gumdrop(k: MeshKit, v: float) -> void:
	var c: Color = [Color("ff6fb5"), Color("6fe7ff"), Color("ffd23f"), Color("9d6bff")][int(v * 3.99)]
	k.cyl(Vector3.ZERO, 0.75, 0.72, 0.42, c, 10)
	k.ball(Vector3(0, 0.75, 0), Vector3(0.42, 0.4, 0.42), c.lightened(0.05), 4, 10)


static func _donut(k: MeshKit, v: float) -> void:
	k.torus(Vector3(0, 0.34, 0), 0.46, 0.3, Color("e8b070"), 14, 7)
	k.outline = 0.0
	k.torus(Vector3(0, 0.46, 0), 0.46, 0.25, [Color("ff7ab8"), Color("8fe3ff"), Color("ffe36b")][int(v * 2.99)], 14, 7)
	k.outline = 0.035


static func _cabinet(k: MeshKit, accent: Color) -> void:
	k.box(Vector3(0, 0.85, 0), Vector3(1.2, 1.7, 1.1), Color("3a2f8a"), 0.05)
	k.decal_box(Vector3(0, 1.2, 0.56), Vector3(0.84, 0.62, 0.02), accent)
	k.decal_box(Vector3(0, 1.2, 0.57), Vector3(0.6, 0.42, 0.02), Color("0f0a33"))
	k.box(Vector3(0, 0.72, 0.68), Vector3(1.06, 0.12, 0.3), Color("2b2466"), 0.03)
	k.ball(Vector3(-0.2, 0.84, 0.72), Vector3(0.07, 0.07, 0.07), Color("ff4f6a"), 3, 6)
	k.ball(Vector3(0.2, 0.84, 0.72), Vector3(0.07, 0.07, 0.07), Color("ffd23f"), 3, 6)


static func _neon(k: MeshKit, accent: Color, v: float) -> void:
	var c := accent if v > 0.5 else Color("27e9ff")
	k.box(Vector3(0, 0.6, 0), Vector3(1.4, 1.2, 1.4), Color("2b2466"), 0.05)
	k.outline = 0.0
	k.box(Vector3(0, 1.21, 0), Vector3(1.1, 0.02, 1.1), c)
	k.box(Vector3(0, 0.6, 0.71), Vector3(1.1, 0.1, 0.02), c)
	k.box(Vector3(0.71, 0.6, 0), Vector3(0.02, 0.1, 1.1), c)
	k.outline = 0.035


static func _pillar(k: MeshKit) -> void:
	var stone := Color("b8b89c")
	k.box(Vector3(0, 0.12, 0), Vector3(1.4, 0.24, 1.4), stone.darkened(0.08), 0.05)
	k.cyl(Vector3(0, 0.24, 0), 1.2, 0.5, 0.44, stone, 10)
	k.box(Vector3(0, 1.52, 0), Vector3(1.2, 0.2, 1.2), stone.lightened(0.05), 0.05)


static func _statue(k: MeshKit) -> void:
	var stone := Color("9fa08a")
	k.box(Vector3(0, 0.25, 0), Vector3(1.3, 0.5, 1.3), stone.darkened(0.1), 0.05)
	k.box(Vector3(0, 1.05, 0), Vector3(0.9, 1.1, 0.8), stone, 0.1)
	k.decal_box(Vector3(-0.2, 1.25, 0.41), Vector3(0.22, 0.12, 0.02), Color("3f3f35"))
	k.decal_box(Vector3(0.2, 1.25, 0.41), Vector3(0.22, 0.12, 0.02), Color("3f3f35"))
	k.decal_box(Vector3(0, 0.88, 0.41), Vector3(0.42, 0.1, 0.02), Color("3f3f35"))


static func _chest(k: MeshKit) -> void:
	k.box(Vector3(0, 0.4, 0), Vector3(1.3, 0.8, 1.0), Color("a36a3a"), 0.06)
	k.box(Vector3(0, 0.92, 0), Vector3(1.34, 0.32, 1.04), Color("bf8148"), 0.1)
	k.decal_box(Vector3(0, 0.74, 0.53), Vector3(0.24, 0.3, 0.02), Color("ffd23f"))
	k.decal_box(Vector3(-0.55, 0.6, 0.51), Vector3(0.1, 1.0, 0.02), Color("ffd23f"))
	k.decal_box(Vector3(0.55, 0.6, 0.51), Vector3(0.1, 1.0, 0.02), Color("ffd23f"))


static func _pod(k: MeshKit, accent: Color) -> void:
	k.cyl(Vector3.ZERO, 0.8, 0.72, 0.66, Color("dcdcef"), 12)
	k.ball(Vector3(0, 0.8, 0), Vector3(0.66, 0.5, 0.66), Color("a8e6ff"), 5, 12)
	k.outline = 0.0
	k.torus(Vector3(0, 0.4, 0), 0.72, 0.05, accent, 12, 4)
	k.outline = 0.035


static func _tomb(k: MeshKit) -> void:
	var stone := Color("9c93b8")
	k.box(Vector3(0, 0.12, 0), Vector3(1.3, 0.24, 1.1), stone.darkened(0.2), 0.03)
	k.box(Vector3(0, 0.75, 0), Vector3(0.95, 1.1, 0.34), stone, 0.05)
	k.ball(Vector3(0, 1.3, 0), Vector3(0.48, 0.3, 0.17), stone, 4, 9)
	k.decal_box(Vector3(0, 0.95, 0.18), Vector3(0.14, 0.5, 0.02), Color("5c5478"))
	k.decal_box(Vector3(0, 1.03, 0.18), Vector3(0.42, 0.13, 0.02), Color("5c5478"))


static func _pumpkin(k: MeshKit) -> void:
	k.ball(Vector3(0, 0.55, 0), Vector3(0.74, 0.56, 0.74), Color("ff9d2e"), 5, 12)
	k.outline = 0.0
	k.ball(Vector3(0, 0.55, 0), Vector3(0.42, 0.57, 0.75), Color("ffb04d"), 5, 12)
	k.outline = 0.035
	k.cyl(Vector3(0, 1.05, 0), 0.26, 0.13, 0.09, Color("5e9b43"), 6)
	for s: float in [-0.25, 0.25]:
		k.decal_box(Vector3(s, 0.68, 0.7), Vector3(0.18, 0.16, 0.04), Color("3a1c5a"))
	k.decal_box(Vector3(0, 0.36, 0.69), Vector3(0.5, 0.11, 0.04), Color("3a1c5a"))


static func _tire(k: MeshKit, v: float) -> void:
	k.torus(Vector3(0, 0.22, 0), 0.45, 0.24, Color("3a3748"), 12, 6)
	k.torus(Vector3(0, 0.66, 0), 0.45, 0.24, [Color("ff5a4e"), Color("ffd23f"), Color("3aa6ff")][int(v * 2.99)], 12, 6)
	k.torus(Vector3(0, 1.1, 0), 0.45, 0.24, Color("3a3748"), 12, 6)


# --- Decoration outside the field -----------------------------------------------------------------

static func _hut(k: MeshKit) -> void:
	# A house on stilts with a thatched roof.
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			k.box(Vector3(sx, 0.5, sz), Vector3(0.16, 1.0, 0.16), Color("7a5230"))
	k.box(Vector3(0, 1.08, 0), Vector3(2.5, 0.16, 2.5), Color("a87a48"))
	k.box(Vector3(0, 1.75, 0), Vector3(2.1, 1.2, 2.1), Color("e4c185"), 0.03)
	k.decal_box(Vector3(0, 1.62, 1.06), Vector3(0.6, 0.94, 0.02), Color("8a5a34"))
	k.decal_box(Vector3(-0.72, 1.85, 1.06), Vector3(0.42, 0.42, 0.02), Color("5a3a24"))
	k.decal_box(Vector3(0.72, 1.85, 1.06), Vector3(0.42, 0.42, 0.02), Color("5a3a24"))
	k.cyl(Vector3(0, 2.3, 0), 1.45, 2.05, 0.1, Color("c9a050"), 4, false)


static func _palm(k: MeshKit, v: float) -> void:
	var lean := lerpf(-0.22, 0.22, v)
	k.push(Transform3D(Basis(Vector3.FORWARD, lean), Vector3.ZERO))
	k.cyl(Vector3.ZERO, 3.2, 0.26, 0.15, Color("a97c4c"), 7)
	for i in 7:
		var angle := TAU * i / 7.0 + v
		var d := Vector3(cos(angle), 0, sin(angle))
		var side := d.cross(Vector3.UP) * 0.42
		var top := Vector3(0, 3.3, 0)
		k.quad(top - side * 0.2, top + d * 1.3 + Vector3(0, 0.3, 0) - side, top + d * 2.3 - Vector3(0, 0.6, 0), top + d * 1.3 + Vector3(0, 0.3, 0) + side, Color("3cc25a"))
		k.quad(top + d * 1.3 + Vector3(0, 0.3, 0) + side, top + d * 2.3 - Vector3(0, 0.6, 0), top + d * 1.3 + Vector3(0, 0.3, 0) - side, top + side * 0.2, Color("2a9f49"))
	k.ball(Vector3(0.18, 3.1, 0.1), Vector3(0.2, 0.2, 0.2), Color("7a5230"), 3, 6)
	k.ball(Vector3(-0.18, 3.08, -0.05), Vector3(0.2, 0.2, 0.2), Color("7a5230"), 3, 6)
	k.pop()


static func _banderitas(k: MeshKit) -> void:
	# Strings of little festival flags between two poles.
	var pole := Color("8a5a34")
	k.box(Vector3(-3, 1.6, 0), Vector3(0.14, 3.2, 0.14), pole)
	k.box(Vector3(3, 1.6, 0), Vector3(0.14, 3.2, 0.14), pole)
	var colors := [Color("ff5a7a"), Color("ffd23f"), Color("35d07f"), Color("3aa6ff"), Color("b768ff")]
	for i in 12:
		var x := -2.75 + i * 0.5
		var sag := 3.05 - 0.45 * (1.0 - pow((x / 3.0), 2.0))
		k.quad(Vector3(x - 0.2, sag, 0), Vector3(x, sag - 0.42, 0), Vector3(x + 0.2, sag, 0), Vector3(x + 0.2, sag, 0), colors[i % 5])
		k.quad(Vector3(x + 0.2, sag, 0), Vector3(x, sag - 0.42, 0), Vector3(x - 0.2, sag, 0), Vector3(x - 0.2, sag, 0), colors[i % 5])


static func _bush(k: MeshKit, v: float) -> void:
	var c := Color("46b957").lerp(Color("3aa24c"), v)
	k.ball(Vector3(0, 0.45, 0), Vector3(0.7, 0.55, 0.7), c, 4, 8)
	k.ball(Vector3(0.55, 0.3, 0.2), Vector3(0.42, 0.34, 0.42), c.lightened(0.08), 3, 7)
	k.ball(Vector3(-0.5, 0.32, -0.15), Vector3(0.46, 0.38, 0.46), c.darkened(0.06), 3, 7)


static func _pine(k: MeshKit, leaves: Color) -> void:
	k.cyl(Vector3.ZERO, 0.8, 0.22, 0.18, Color("7a5230"), 6)
	k.cone(Vector3(0, 0.6, 0), 1.4, 1.15, leaves, 8)
	k.cone(Vector3(0, 1.4, 0), 1.2, 0.9, leaves.lightened(0.06), 8)
	k.cone(Vector3(0, 2.2, 0), 1.0, 0.62, leaves.lightened(0.12), 8)


static func _umbrella(k: MeshKit, accent: Color) -> void:
	k.cyl(Vector3.ZERO, 2.1, 0.06, 0.06, Color("f6f0e0"), 5)
	k.cyl(Vector3(0, 1.8, 0), 0.65, 1.35, 0.05, accent, 8, false)
	k.box(Vector3(0.9, 0.14, 0.2), Vector3(0.7, 0.14, 1.5), Color("fff3d6"), 0.03)


static func _boat(k: MeshKit, accent: Color) -> void:
	# An outrigger boat.
	k.box(Vector3(0, 0.3, 0), Vector3(0.9, 0.5, 3.2), Color("f2ead2"), 0.12)
	k.box(Vector3(0, 0.56, 0), Vector3(1.0, 0.1, 3.3), accent, 0.03)
	k.box(Vector3(1.5, 0.15, 0), Vector3(0.22, 0.2, 2.6), Color("c99b62"), 0.04)
	k.box(Vector3(-1.5, 0.15, 0), Vector3(0.22, 0.2, 2.6), Color("c99b62"), 0.04)
	k.box(Vector3(0, 0.6, 0.7), Vector3(3.2, 0.08, 0.1), Color("8a5a34"))
	k.box(Vector3(0, 0.6, -0.7), Vector3(3.2, 0.08, 0.1), Color("8a5a34"))


static func _building(k: MeshKit, v: float) -> void:
	var wall: Color = [Color("ffd9a0"), Color("9fd8ff"), Color("ffb3c7"), Color("c7e8a6")][int(v * 3.99)]
	k.box(Vector3(0, 1.9, 0), Vector3(3.2, 3.8, 2.8), wall, 0.06)
	k.box(Vector3(0, 3.92, 0), Vector3(3.4, 0.2, 3.0), wall.darkened(0.25), 0.03)
	for row in 2:
		for col in 3:
			k.decal_box(Vector3(-1.0 + col, 1.5 + row * 1.3, 1.41), Vector3(0.56, 0.72, 0.02), Color("3a4a8a"))
			k.decal_box(Vector3(-1.0 + col, 1.72 + row * 1.3, 1.42), Vector3(0.56, 0.12, 0.02), Color("9fd8ff"))
	k.decal_box(Vector3(0, 0.55, 1.41), Vector3(0.8, 1.1, 0.02), Color("6a4a30"))


static func _lamp(k: MeshKit) -> void:
	k.cyl(Vector3.ZERO, 3.0, 0.1, 0.07, Color("4a4a60"), 6)
	k.box(Vector3(0.45, 3.0, 0), Vector3(1.0, 0.1, 0.12), Color("4a4a60"))
	k.ball(Vector3(0.85, 2.86, 0), Vector3(0.2, 0.14, 0.2), Color("fff3a8"), 3, 6)


static func _tree(k: MeshKit, leaves: Color, scale := 1.0) -> void:
	k.cyl(Vector3.ZERO, 1.5 * scale, 0.3 * scale, 0.22 * scale, Color("8a5f3a"), 7)
	k.ball(Vector3(0, 2.2 * scale, 0), Vector3(1.15, 1.0, 1.15) * scale, leaves, 5, 9)
	k.ball(Vector3(0.65, 1.75 * scale, 0.3), Vector3(0.7, 0.62, 0.7) * scale, leaves.lightened(0.1), 4, 8)
	k.ball(Vector3(-0.6, 1.8 * scale, -0.25), Vector3(0.75, 0.66, 0.75) * scale, leaves.darkened(0.08), 4, 8)


static func _spire(k: MeshKit) -> void:
	k.cyl(Vector3.ZERO, 3.4, 1.0, 0.18, Color("4a312d"), 6, false)
	k.push(Transform3D(Basis(Vector3.FORWARD, 0.35), Vector3(0.75, 0, 0.1)))
	k.cyl(Vector3.ZERO, 1.8, 0.55, 0.1, Color("5f403b"), 5, false)
	k.pop()
	k.outline = 0.0
	k.ball(Vector3(0, 3.45, 0), Vector3(0.28, 0.2, 0.28), Color("ffa51f"), 3, 6)
	k.outline = 0.035


static func _mangrove(k: MeshKit) -> void:
	for i in 5:
		var angle := TAU * i / 5.0
		var foot := Vector3(cos(angle), 0, sin(angle)) * 0.95
		k.push(Transform3D(Basis.looking_at((Vector3(0, 1.4, 0) - foot).normalized(), Vector3.RIGHT if i % 2 == 0 else Vector3.BACK) * Basis(Vector3.RIGHT, -PI * 0.5), foot))
		k.cyl(Vector3.ZERO, 1.75, 0.09, 0.08, Color("6a4a30"), 4)
		k.pop()
	k.cyl(Vector3(0, 1.3, 0), 1.0, 0.24, 0.2, Color("7a5a3c"), 6)
	k.ball(Vector3(0, 2.7, 0), Vector3(1.4, 0.95, 1.4), Color("35a659"), 5, 9)
	k.ball(Vector3(0.7, 2.3, 0.4), Vector3(0.8, 0.6, 0.8), Color("48bd6b"), 4, 8)


static func _mushroom(k: MeshKit, accent: Color) -> void:
	k.cyl(Vector3.ZERO, 0.8, 0.26, 0.2, Color("fff1d6"), 8)
	k.ball(Vector3(0, 0.95, 0), Vector3(0.74, 0.46, 0.74), accent, 5, 10)
	k.outline = 0.0
	k.ball(Vector3(0.28, 1.25, 0.2), Vector3(0.14, 0.09, 0.14), Color("fff8e6"), 3, 6)
	k.ball(Vector3(-0.3, 1.2, 0.08), Vector3(0.11, 0.08, 0.11), Color("fff8e6"), 3, 6)
	k.outline = 0.035


static func _lily(k: MeshKit) -> void:
	k.cyl(Vector3.ZERO, 0.08, 0.75, 0.72, Color("4cbc5e"), 10)
	k.ball(Vector3(0.05, 0.2, 0), Vector3(0.2, 0.15, 0.2), Color("ff9fd0"), 4, 7)


static func _lollipop(k: MeshKit, v: float) -> void:
	var c: Color = [Color("ff5a9a"), Color("6fe7ff"), Color("ffd23f")][int(v * 2.99)]
	k.cyl(Vector3.ZERO, 2.4, 0.08, 0.08, Color("fff8ee"), 5)
	k.ball(Vector3(0, 2.9, 0), Vector3(0.75, 0.75, 0.24), c, 5, 12)
	k.outline = 0.0
	k.ball(Vector3(0, 2.9, 0.03), Vector3(0.42, 0.42, 0.23), Color("fff8ee"), 4, 10)
	k.ball(Vector3(0, 2.9, 0.05), Vector3(0.2, 0.2, 0.23), c, 3, 8)
	k.outline = 0.035


static func _icecream(k: MeshKit, v: float) -> void:
	k.push(Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, 1.5, 0)))
	k.cone(Vector3.ZERO, 1.5, 0.55, Color("e8b070"), 9)
	k.pop()
	var c: Color = [Color("ffb3dc"), Color("c4f3ff"), Color("b39bff")][int(v * 2.99)]
	k.ball(Vector3(0, 1.8, 0), Vector3(0.68, 0.6, 0.68), c, 5, 10)
	k.ball(Vector3(0, 2.45, 0), Vector3(0.5, 0.45, 0.5), c.lightened(0.15), 4, 9)


static func _neon_tower(k: MeshKit, accent: Color) -> void:
	k.box(Vector3(0, 2.4, 0), Vector3(1.8, 4.8, 1.8), Color("1c174a"), 0.05)
	k.outline = 0.0
	for i in 5:
		k.box(Vector3(0, 0.7 + i * 0.9, 0.91), Vector3(1.5, 0.12, 0.02), accent if i % 2 == 0 else Color("27e9ff"))
		k.box(Vector3(0.91, 0.7 + i * 0.9, 0), Vector3(0.02, 0.12, 1.5), accent if i % 2 == 1 else Color("27e9ff"))
	k.outline = 0.035


static func _ship(k: MeshKit, accent: Color) -> void:
	k.box(Vector3(0, 0.85, 0), Vector3(2.6, 1.5, 6.0), Color("7a4c2a"), 0.2)
	k.box(Vector3(0, 1.75, -2.2), Vector3(2.5, 0.8, 1.6), Color("8f5c34"), 0.08)
	k.decal_box(Vector3(0, 1.0, 3.01), Vector3(2.0, 0.2, 0.02), accent)
	k.cyl(Vector3(0, 1.6, 0.4), 5.0, 0.13, 0.09, Color("5a3a24"), 6)
	k.quad(Vector3(-1.8, 5.5, 0.4), Vector3(-1.8, 3.1, 0.75), Vector3(1.8, 3.1, 0.75), Vector3(1.8, 5.5, 0.4), Color("fff3d6"))
	k.quad(Vector3(1.8, 5.5, 0.4), Vector3(1.8, 3.1, 0.75), Vector3(-1.8, 3.1, 0.75), Vector3(-1.8, 5.5, 0.4), Color("f0e3bf"))


static func _dish(k: MeshKit) -> void:
	k.cyl(Vector3.ZERO, 1.4, 0.5, 0.18, Color("c9c5dc"), 8)
	k.push(Transform3D(Basis(Vector3.RIGHT, 0.7), Vector3(0, 1.6, 0)))
	k.cyl(Vector3.ZERO, 0.6, 0.2, 1.4, Color("efedf9"), 12)
	k.cone(Vector3(0, 0.1, 0), 1.1, 0.07, Color("6dffb0"), 5)
	k.pop()


static func _dead_tree(k: MeshKit) -> void:
	var bark := Color("3f3560")
	k.cyl(Vector3.ZERO, 2.4, 0.34, 0.12, bark, 6)
	for b: Vector3 in [Vector3(0.7, 1.0, 0.5), Vector3(-0.8, 0.9, 0.2), Vector3(0.3, 0.8, -0.8)]:
		k.push(Transform3D(Basis(b.cross(Vector3.UP).normalized(), -0.95), Vector3(0, 1.3 + b.y * 0.6, 0)))
		k.cyl(Vector3.ZERO, 1.4, 0.11, 0.03, bark.lightened(0.05), 5)
		k.pop()
