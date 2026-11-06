class_name PropKit
extends RefCounted
## Every prop on the maps, drawn with MeshKit. A prop stands on y = 0, is about 1.5 m wide (they're drawn bigger to fill a tile),
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
		_:
			if not WorldProps.draw(kit, prop, v, accent):
				kit.soft_box(Vector3(0, 0.6, 0), Vector3(0.65, 0.6, 0.65), accent, 0.5)
	kit.pop()


# --- Blocks: fill one wall tile -------------------------------------------------------------------

static func _crate(k: MeshKit, v: float) -> void:
	var wood := Color("e8b469").lerp(Color("d3954e"), v)
	var strap := wood.darkened(0.22)
	k.soft_box(Vector3(0, 0.66, 0), Vector3(0.7, 0.66, 0.7), wood, 0.5, 10, 16)
	k.soft_box(Vector3(0, 0.66, 0), Vector3(0.728, 0.12, 0.728), strap, 0.5, 6, 16)
	k.soft_box(Vector3(0, 0.66, 0), Vector3(0.12, 0.69, 0.728), strap, 0.5, 6, 10)
	if v > 0.65:
		k.soft_box(Vector3(0.1, 1.6, -0.05), Vector3(0.4, 0.3, 0.4), wood.lightened(0.08), 0.5, 8, 12)


static func _stall(k: MeshKit, accent: Color) -> void:
	k.soft_box(Vector3(0, 0.42, 0), Vector3(0.7, 0.42, 0.62), Color("c78c52"), 0.45, 8, 14)
	k.soft_box(Vector3(0, 0.7, 0), Vector3(0.73, 0.075, 0.65), accent, 0.5, 6, 14)
	for i in 3:
		k.ball(Vector3(-0.42 + i * 0.42, 0.98, 0.2), Vector3(0.17, 0.17, 0.17), [Color("ffb03b"), Color("7ed957"), Color("ff6b6b")][i], 8, 12)
	for s: float in [-0.62, 0.62]:
		k.cyl(Vector3(s, 0.6, -0.45), 1.15, 0.06, 0.06, Color("8a5a34"), 8)
	k.dome(Vector3(0, 1.62, -0.05), Vector3(0.94, 0.42, 0.8), accent)
	k.outline = 0.0
	k.dome(Vector3(0, 1.625, -0.05), Vector3(0.3, 0.428, 0.812), Color("fff6e0"))
	k.outline = 0.035


static func _hay(k: MeshKit) -> void:
	var straw := Color("f2cf63")
	k.soft_box(Vector3(0, 0.56, 0), Vector3(0.72, 0.56, 0.66), straw, 0.55, 10, 16)
	for s: float in [-0.34, 0.34]:
		k.soft_box(Vector3(s, 0.56, 0), Vector3(0.07, 0.59, 0.69), Color("c4923c"), 0.55, 6, 10)
	k.outline = 0.0
	for spot: Vector3 in [Vector3(-0.05, 0.92, 0.42), Vector3(0.1, 0.5, 0.6), Vector3(-0.1, 0.25, 0.58)]:
		k.ball(spot, Vector3(0.09, 0.035, 0.05), Color("ffe394"), 4, 7)
	k.outline = 0.035


static func _rock(k: MeshKit, v: float, tone: Color) -> void:
	var c := tone.lerp(tone.darkened(0.15), v)
	k.ball(Vector3(0, 0.52, 0), Vector3(0.72, 0.62, 0.66), c, 10, 14)
	k.ball(Vector3(0.38, 0.28, 0.3), Vector3(0.4, 0.32, 0.38), c.lightened(0.1), 8, 12)
	k.ball(Vector3(-0.4, 0.25, -0.12), Vector3(0.36, 0.27, 0.36), c.darkened(0.08), 8, 12)
	k.outline = 0.0
	k.ball(Vector3(-0.14, 0.92, 0.24), Vector3(0.2, 0.1, 0.14), c.lightened(0.24), 4, 8)
	k.outline = 0.035


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
	# A chunky little toy bus.
	var body: Color = [Color("ff5a4e"), Color("3aa6ff"), Color("ffc21f"), Color("35d07f")][int(v * 3.99)]
	for sx: float in [-0.52, 0.52]:
		for sz: float in [-0.46, 0.46]:
			k.ball(Vector3(sx, 0.21, sz), Vector3(0.14, 0.21, 0.21), Color("2c2848"), 8, 12)
	k.soft_box(Vector3(0, 0.52, 0), Vector3(0.62, 0.34, 0.72), body, 0.5, 8, 14)
	k.soft_box(Vector3(0, 1.02, -0.06), Vector3(0.56, 0.3, 0.56), Color("fff3d6"), 0.5, 8, 14)
	k.soft_box(Vector3(0, 1.05, -0.06), Vector3(0.585, 0.16, 0.585), Color("4a86c8"), 0.55, 6, 12)
	k.soft_box(Vector3(0, 1.36, -0.06), Vector3(0.66, 0.08, 0.66), accent, 0.5, 6, 14)
	k.outline = 0.0
	for s: float in [-0.36, 0.36]:
		k.ball(Vector3(s, 0.56, 0.71), Vector3(0.11, 0.11, 0.05), Color("fff3a8"), 6, 10)
	k.outline = 0.035


static func _cones(k: MeshKit) -> void:
	for p: Vector3 in [Vector3(-0.35, 0, -0.3), Vector3(0.38, 0, -0.1), Vector3(-0.05, 0, 0.38)]:
		k.box(p + Vector3(0, 0.04, 0), Vector3(0.62, 0.08, 0.62), Color("3a3a48"))
		k.cone(p + Vector3(0, 0.08, 0), 1.0, 0.28, Color("ff8a2b"), 8)


static func _crystal(k: MeshKit, accent: Color) -> void:
	k.ball(Vector3(0, 0.12, 0), Vector3(0.72, 0.2, 0.66), Color("8d86a8"), 8, 14)
	k.push(Transform3D(Basis(Vector3.BACK, -0.42), Vector3(0.3, 0.1, 0.12)))
	k.ball(Vector3(0, 0.5, 0), Vector3(0.2, 0.55, 0.2), accent, 8, 10)
	k.pop()
	k.push(Transform3D(Basis(Vector3.BACK, 0.46), Vector3(-0.32, 0.1, -0.08)))
	k.ball(Vector3(0, 0.42, 0), Vector3(0.18, 0.46, 0.18), accent.darkened(0.14), 8, 10)
	k.pop()
	k.ball(Vector3(0, 0.85, 0), Vector3(0.3, 0.85, 0.3), accent.lightened(0.15), 10, 12)
	k.outline = 0.0
	k.ball(Vector3(-0.09, 1.1, 0.22), Vector3(0.06, 0.24, 0.05), Color.WHITE, 4, 7)
	k.outline = 0.035


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
		k.decal_box(Vector3(s, 1.25, 0.34), Vector3(0.07, 0.07, 0.04), Color("0a1426"))


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
	k.soft_box(Vector3(0, 0.6, 0), Vector3(0.7, 0.6, 0.7), Color("2b2466"), 0.5, 8, 14)
	k.outline = 0.0
	k.soft_box(Vector3(0, 0.6, 0), Vector3(0.728, 0.07, 0.728), c, 0.5, 4, 14)
	k.ball(Vector3(0, 1.17, 0), Vector3(0.4, 0.035, 0.4), c, 4, 14)
	k.outline = 0.035


static func _pillar(k: MeshKit) -> void:
	var stone := Color("cfcfb0")
	k.cyl(Vector3.ZERO, 0.22, 0.72, 0.66, stone.darkened(0.12), 16)
	k.cyl(Vector3(0, 0.2, 0), 1.12, 0.46, 0.42, stone, 14)
	k.torus(Vector3(0, 0.34, 0), 0.47, 0.05, stone.lightened(0.1), 18, 6)
	k.torus(Vector3(0, 1.22, 0), 0.44, 0.05, stone.lightened(0.1), 18, 6)
	k.cyl(Vector3(0, 1.3, 0), 0.18, 0.5, 0.66, stone.lightened(0.06), 16)


static func _statue(k: MeshKit) -> void:
	var stone := Color("9fa08a")
	k.box(Vector3(0, 0.25, 0), Vector3(1.3, 0.5, 1.3), stone.darkened(0.1), 0.05)
	k.box(Vector3(0, 1.05, 0), Vector3(0.9, 1.1, 0.8), stone, 0.1)
	k.decal_box(Vector3(-0.2, 1.25, 0.41), Vector3(0.22, 0.12, 0.02), Color("3f3f35"))
	k.decal_box(Vector3(0.2, 1.25, 0.41), Vector3(0.22, 0.12, 0.02), Color("3f3f35"))
	k.decal_box(Vector3(0, 0.88, 0.41), Vector3(0.42, 0.1, 0.02), Color("3f3f35"))


static func _chest(k: MeshKit) -> void:
	var gold := Color("ffd23f")
	k.soft_box(Vector3(0, 0.38, 0), Vector3(0.66, 0.38, 0.5), Color("a36a3a"), 0.5, 8, 14)
	k.dome(Vector3(0, 0.72, 0), Vector3(0.68, 0.36, 0.52), Color("c98a4e"), 8, 18)
	k.soft_box(Vector3(0, 0.72, 0), Vector3(0.7, 0.06, 0.54), gold, 0.5, 4, 14)
	for s: float in [-0.42, 0.42]:
		k.soft_box(Vector3(s, 0.56, 0), Vector3(0.06, 0.54, 0.54), gold.darkened(0.08), 0.5, 4, 10)
	k.soft_box(Vector3(0, 0.66, 0.54), Vector3(0.12, 0.15, 0.04), gold, 0.6, 4, 8)


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
	var orange := Color("ff9d2e")
	for i in 5:
		var x := -0.46 + i * 0.23
		var edge := absf(x) / 0.46
		k.ball(Vector3(x, 0.54, 0), Vector3(0.3, 0.54 - edge * 0.07, 0.72 - edge * 0.16), orange if i % 2 == 0 else orange.lightened(0.08), 10, 14)
	k.cyl(Vector3(0, 1.0, 0), 0.26, 0.13, 0.09, Color("5e9b43"), 8)
	k.outline = 0.0
	var dark := Color("3a1c5a")
	for s: float in [-0.23, 0.23]:
		k.ball(Vector3(s, 0.8, 0.58), Vector3(0.11, 0.1, 0.05), dark, 6, 8)
	k.ball(Vector3(0, 0.62, 0.68), Vector3(0.24, 0.07, 0.04), dark, 5, 10)
	k.outline = 0.035


static func _tire(k: MeshKit, v: float) -> void:
	k.torus(Vector3(0, 0.22, 0), 0.45, 0.24, Color("3a3748"), 12, 6)
	k.torus(Vector3(0, 0.66, 0), 0.45, 0.24, [Color("ff5a4e"), Color("ffd23f"), Color("3aa6ff")][int(v * 2.99)], 12, 6)
	k.torus(Vector3(0, 1.1, 0), 0.45, 0.24, Color("3a3748"), 12, 6)


# --- Decoration outside the field -----------------------------------------------------------------

static func _hut(k: MeshKit) -> void:
	# A house on stilts with a thatched roof.
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			k.cyl(Vector3(sx, 0, sz), 1.1, 0.09, 0.08, Color("7a5230"), 8)
	k.soft_box(Vector3(0, 1.08, 0), Vector3(1.28, 0.09, 1.28), Color("a87a48"), 0.45, 6, 14)
	k.soft_box(Vector3(0, 1.72, 0), Vector3(1.04, 0.6, 1.04), Color("e4c185"), 0.35, 8, 14)
	k.soft_box(Vector3(0, 1.58, 1.03), Vector3(0.3, 0.45, 0.04), Color("8a5a34"), 0.55, 4, 8)
	for s: float in [-0.68, 0.68]:
		k.soft_box(Vector3(s, 1.85, 1.03), Vector3(0.2, 0.2, 0.04), Color("5a3a24"), 0.55, 4, 8)
	k.cone(Vector3(0, 2.22, 0), 1.6, 1.78, Color("d9b05a"), 18)
	k.torus(Vector3(0, 2.26, 0), 1.72, 0.09, Color("b98f42"), 24, 6)


static func _palm(k: MeshKit, v: float) -> void:
	var lean := lerpf(-0.5, 0.5, v)
	var top := Vector3(lean, 3.3, 0)
	k.tube(PackedVector3Array([Vector3.ZERO, Vector3(lean * 0.12, 1.1, 0), Vector3(lean * 0.45, 2.2, 0), top]), 0.26, Color("a97c4c"), false, 8, 0.13)
	for i in 8:
		var angle := TAU * i / 8.0 + v
		var green := Color("3cc25a") if i % 2 == 0 else Color("2fae4e")
		k.push(Transform3D(Basis(Vector3.UP, angle) * Basis(Vector3.BACK, 0.26), top))
		k.ball(Vector3(0.75, 0, 0), Vector3(0.85, 0.09, 0.3), green, 6, 12)
		k.pop()
		k.push(Transform3D(Basis(Vector3.UP, angle) * Basis(Vector3.BACK, -0.42), top + Basis(Vector3.UP, angle) * Vector3(1.35, 0.32, 0)))
		k.ball(Vector3(0.45, 0, 0), Vector3(0.6, 0.07, 0.22), green.lightened(0.08), 6, 10)
		k.pop()
	for s: float in [-0.18, 0.18]:
		k.ball(top + Vector3(s, -0.2, s * 0.6), Vector3(0.18, 0.18, 0.18), Color("7a5230"), 6, 9)


static func _banderitas(k: MeshKit) -> void:
	# Strings of little festival flags between two poles.
	var pole := Color("8a5a34")
	k.cyl(Vector3(-3, 0, 0), 3.3, 0.08, 0.07, pole, 8)
	k.cyl(Vector3(3, 0, 0), 3.3, 0.08, 0.07, pole, 8)
	var colors := [Color("ff5a7a"), Color("ffd23f"), Color("35d07f"), Color("3aa6ff"), Color("ffffff")]
	var saved := k.outline
	k.outline = 0.0
	var cord := PackedVector3Array()
	for i in 13:
		var x := -3.0 + i * 0.5
		cord.append(Vector3(x, 3.1 - 0.45 * (1.0 - pow(x / 3.0, 2.0)), 0))
	k.tube(cord, 0.02, Color("fff6e0"), false, 5)
	for i in 12:
		var x := -2.75 + i * 0.5
		var sag := 3.1 - 0.45 * (1.0 - pow(x / 3.0, 2.0))
		k.quad(Vector3(x - 0.2, sag, 0), Vector3(x, sag - 0.42, 0), Vector3(x + 0.2, sag, 0), Vector3(x + 0.2, sag, 0), colors[i % 5])
		k.quad(Vector3(x + 0.2, sag, 0), Vector3(x, sag - 0.42, 0), Vector3(x - 0.2, sag, 0), Vector3(x - 0.2, sag, 0), colors[i % 5])
	k.outline = saved


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
	k.cyl(Vector3.ZERO, 2.1, 0.06, 0.06, Color("f6f0e0"), 8)
	k.dome(Vector3(0, 1.85, 0), Vector3(1.35, 0.6, 1.35), accent)
	k.outline = 0.0
	k.dome(Vector3(0, 1.855, 0), Vector3(0.45, 0.61, 1.365), Color("fff6e0"))
	k.outline = 0.035
	k.soft_box(Vector3(0.95, 0.16, 0.2), Vector3(0.34, 0.09, 0.76), Color("fff3d6"), 0.5, 6, 12)


static func _boat(k: MeshKit, accent: Color) -> void:
	# An outrigger boat.
	k.ball(Vector3(0, 0.28, 0), Vector3(0.52, 0.32, 1.75), Color("f2ead2"), 8, 16)
	k.ball(Vector3(0, 0.46, 0), Vector3(0.54, 0.08, 1.78), accent, 6, 16)
	for s: float in [-1.5, 1.5]:
		k.ball(Vector3(s, 0.14, 0), Vector3(0.13, 0.12, 1.3), Color("c99b62"), 6, 10)
	for z: float in [-0.7, 0.7]:
		k.tube(PackedVector3Array([Vector3(-1.5, 0.2, z), Vector3(-0.7, 0.58, z), Vector3(0.7, 0.58, z), Vector3(1.5, 0.2, z)]), 0.045, Color("8a5a34"), false, 6)


static func _building(k: MeshKit, v: float) -> void:
	var wall: Color = [Color("ffd9a0"), Color("9fd8ff"), Color("ffb3c7"), Color("c7e8a6")][int(v * 3.99)]
	k.soft_box(Vector3(0, 1.75, 0), Vector3(1.6, 1.75, 1.4), wall, 0.3, 10, 16)
	k.soft_box(Vector3(0, 3.52, 0), Vector3(1.78, 0.2, 1.58), wall.darkened(0.3), 0.45, 6, 14)
	for row in 2:
		for col in 3:
			k.soft_box(Vector3(-1.0 + col, 1.55 + row * 1.15, 1.38), Vector3(0.27, 0.36, 0.05), Color("4a86c8"), 0.5, 4, 8)
	k.soft_box(Vector3(0, 0.58, 1.38), Vector3(0.38, 0.58, 0.05), Color("a8683a"), 0.5, 4, 8)


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
	k.cyl(Vector3.ZERO, 4.6, 1.0, 0.82, Color("1c174a"), 18)
	k.dome(Vector3(0, 4.6, 0), Vector3(0.82, 0.3, 0.82), Color("2b2466"))
	k.outline = 0.0
	for i in 5:
		k.torus(Vector3(0, 0.6 + i * 0.9, 0), 1.0 - i * 0.04, 0.05, accent if i % 2 == 0 else Color("27e9ff"), 26, 6)
	k.outline = 0.035


static func _ship(k: MeshKit, accent: Color) -> void:
	k.ball(Vector3(0, 0.95, 0), Vector3(1.35, 1.1, 3.1), Color("8f5a30"), 10, 18)
	k.ball(Vector3(0, 1.7, 0), Vector3(1.22, 0.2, 2.85), Color("c98f58"), 6, 18)
	k.soft_box(Vector3(0, 2.1, -2.0), Vector3(1.05, 0.42, 0.72), Color("7a4c2a"), 0.45, 8, 14)
	k.outline = 0.0
	k.ball(Vector3(0, 1.48, 0), Vector3(1.37, 0.07, 3.12), accent, 4, 18)
	k.outline = 0.035
	k.cyl(Vector3(0, 1.7, 0.5), 4.8, 0.12, 0.08, Color("5a3a24"), 8)
	var sail: Array[PackedVector3Array] = []
	for i in 6:
		var f := i / 5.0
		var row := PackedVector3Array()
		for j in 9:
			var u := lerpf(-1.0, 1.0, j / 8.0)
			row.append(Vector3(u * lerpf(1.45, 1.85, f), 6.0 - f * 2.5, 0.75 + 0.55 * (1.0 - u * u) * sin(f * PI)))
		sail.append(row)
	k.outline = 0.0
	k.sheet(sail, Color("fff3d6"), 0.03)
	k.outline = 0.035


static func _dish(k: MeshKit) -> void:
	k.cyl(Vector3.ZERO, 0.9, 0.55, 0.2, Color("c9c5dc"), 12)
	k.push(Transform3D(Basis(Vector3.RIGHT, 0.75), Vector3(0, 1.25, 0)))
	k.ball(Vector3.ZERO, Vector3(1.05, 0.22, 1.05), Color("efedf9"), 8, 18)
	k.outline = 0.0
	k.ball(Vector3(0, 0.08, 0), Vector3(0.82, 0.16, 0.82), Color("c4c2d8"), 6, 16)
	k.outline = 0.035
	k.cyl(Vector3(0, 0.1, 0), 0.75, 0.05, 0.03, Color("8a86a6"), 8)
	k.ball(Vector3(0, 0.88, 0), Vector3(0.1, 0.1, 0.1), Color("6dffb0"), 6, 9)
	k.pop()


static func _dead_tree(k: MeshKit) -> void:
	var bark := Color("4f4478")
	k.tube(PackedVector3Array([Vector3.ZERO, Vector3(0.04, 1.2, 0), Vector3(-0.08, 2.5, 0.05)]), 0.34, bark, false, 8, 0.09)
	for path: Array in [[Vector3(0.03, 1.2, 0), Vector3(0.6, 1.8, 0.3), Vector3(1.15, 1.95, 0.5)], [Vector3(0, 1.5, 0), Vector3(-0.6, 2.0, 0.15), Vector3(-1.15, 2.5, 0.2)], [Vector3(0, 1.0, 0), Vector3(0.1, 1.5, -0.55), Vector3(0.5, 1.8, -1.0)], [Vector3(0.55, 1.75, 0.28), Vector3(0.75, 2.25, 0.25), Vector3(0.7, 2.6, 0.1)]]:
		k.tube(PackedVector3Array(path), 0.11, bark.lightened(0.06), false, 7, 0.025)