class_name ArenaBuilder
extends RefCounted
## Turns a map (theme + tiles) into a 3D world: a handful of merged meshes, so a whole arena is only a
## few draw calls. Coordinates: sim (x, y) is world (x, 0, y).

const TEAM_COLORS := [Color("ffb21f"), Color("23a7ff")]
const TEAM_NAMES := ["Sun", "Wave"]
const WALL_H := 0.9


static func team_color(team: int) -> Color:
	return TEAM_COLORS[clampi(team, 0, 1)]


## Builds the whole arena under a new Node3D. `sim` only supplies the grid; nothing here changes in play.
static func build(sim: Sim, low_detail := false) -> Node3D:
	var map := Maps.by_id(sim.map_id)
	var theme: Dictionary = Maps.THEMES[map["theme"]]
	var root := Node3D.new()
	root.name = "Arena"
	var toon := ShaderMaterial.new()
	toon.shader = preload("res://gfx/shaders/toon.gdshader")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sim.map_id)

	var floor_kit := MeshKit.new()
	floor_kit.outline = 0.0
	_draw_background(floor_kit, sim, theme)
	_draw_floor(floor_kit, sim, theme, rng)
	_draw_pads(floor_kit, sim)
	_add(root, floor_kit, toon, "Floor")

	var pit := _draw_pits(sim, theme)
	if pit:
		root.add_child(pit)
	var belts := _draw_conveyors(sim)
	if belts:
		root.add_child(belts)
	var shadows := _draw_shadows(sim)
	if shadows:
		root.add_child(shadows)

	var solid := MeshKit.new()
	_draw_border(solid, sim, theme)
	_draw_blocks(solid, sim, theme, rng)
	_draw_bases(solid, sim)
	_draw_jails(solid, sim)
	_add(root, solid, toon, "Solid")

	var deco := MeshKit.new()
	_draw_decor(deco, sim, theme, rng, low_detail)
	_add(root, deco, toon, "Decor")

	var grass := _draw_grass(sim, theme, rng, low_detail)
	if grass:
		root.add_child(grass)
	return root


static func _add(root: Node3D, kit: MeshKit, mat: Material, node_name: String) -> void:
	if kit.is_empty():
		return
	var inst := MeshInstance3D.new()
	inst.name = node_name
	inst.mesh = kit.to_mesh()
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(inst)


static func _draw_background(k: MeshKit, sim: Sim, theme: Dictionary) -> void:
	var size := sim.arena_size()
	var far := 60.0
	k.ground(Rect2(-far, -far, size.x + far * 2.0, size.y + far * 2.0), -0.35, Color(theme["bg"]))


static func _draw_floor(k: MeshKit, sim: Sim, theme: Dictionary, rng: RandomNumberGenerator) -> void:
	var a := Color(theme["floor"][0])
	var b := Color(theme["floor"][1])
	var t := Maps.TILE
	for y in sim.h:
		for x in sim.w:
			var code := sim.tiles[y * sim.w + x]
			if code == Maps.PIT or (code >= Maps.CON_R and code <= Maps.CON_D):
				continue
			var c := a if (x + y) % 2 == 0 else b
			if code == Maps.ICE:
				c = Color("d8f6ff") if (x + y) % 2 == 0 else Color("c6eefb")
			elif code == Maps.MUD:
				c = Color("8a6240") if (x + y) % 2 == 0 else Color("7d5737")
			k.ground(Rect2(x * t, y * t, t, t), 0.0, c)
			# Small details break up the checks.
			if code == Maps.FLOOR and rng.randf() < 0.1:
				var px := (x + rng.randf_range(0.2, 0.8)) * t
				var py := (y + rng.randf_range(0.2, 0.8)) * t
				k.ground(Rect2(px, py, rng.randf_range(0.1, 0.2), rng.randf_range(0.08, 0.14)), 0.005, c.darkened(0.1))
			if code == Maps.ICE and rng.randf() < 0.25:
				var px := (x + rng.randf_range(0.2, 0.7)) * t
				var py := (y + rng.randf_range(0.2, 0.8)) * t
				k.ground(Rect2(px, py, 0.5, 0.05), 0.005, Color("f6fdff"))
			if code == Maps.MUD and rng.randf() < 0.35:
				var px := (x + rng.randf_range(0.2, 0.7)) * t
				var py := (y + rng.randf_range(0.2, 0.7)) * t
				k.ground(Rect2(px, py, 0.26, 0.2), 0.005, Color("6a4830"))
			if code == Maps.BOUNCE:
				k.ground(Rect2(x * t + 0.15, y * t + 0.15, t - 0.3, t - 0.3), 0.01, Color("ff4f8b"))
				k.ground(Rect2(x * t + 0.35, y * t + 0.35, t - 0.7, t - 0.7), 0.012, Color("ffd23f"))
			if code == Maps.TELE:
				k.ground(Rect2(x * t + 0.1, y * t + 0.1, t - 0.2, t - 0.2), 0.01, Color("24135f"))
				k.ground(Rect2(x * t + 0.28, y * t + 0.28, t - 0.56, t - 0.56), 0.012, Color("b768ff"))
				k.ground(Rect2(x * t + 0.5, y * t + 0.5, t - 1.0, t - 1.0), 0.014, Color("27e9ff"))


## Team-coloured ground under each base and jail; markers on top come from the match view.
static func _draw_pads(k: MeshKit, sim: Sim) -> void:
	for team in 2:
		var c: Color = team_color(team)
		_disc(k, sim.jail[team], Sim.JAIL_R + 0.16, 0.012, Color("24135f"))
		_disc(k, sim.jail[team], Sim.JAIL_R, 0.014, c.lerp(Color("3a3058"), 0.68))
		_disc(k, sim.base[team], Sim.BASE_R + 0.18, 0.012, Color("24135f"))
		_disc(k, sim.base[team], Sim.BASE_R, 0.014, c)
		_disc(k, sim.base[team], Sim.BASE_R * 0.76, 0.016, c.lightened(0.42))
		_disc(k, sim.base[team], Sim.BASE_R * 0.52, 0.018, c)


static func _disc(k: MeshKit, at: Vector2, r: float, y: float, color: Color, segs := 28) -> void:
	var col := color
	var c := Vector3(at.x, y, at.y)
	for i in segs:
		var a0 := TAU * float(i) / segs
		var a1 := TAU * float(i + 1) / segs
		var p0 := c + Vector3(cos(a0), 0, sin(a0)) * r
		var p1 := c + Vector3(cos(a1), 0, sin(a1)) * r
		k._tri(c, p1, p0, Vector3.UP, Vector3.UP, Vector3.UP, col, col, col, false)


static func _draw_pits(sim: Sim, theme: Dictionary) -> MeshInstance3D:
	var k := MeshKit.new()
	k.outline = 0.0
	var t := Maps.TILE
	var col := Color(theme["pit_c"])
	for y in sim.h:
		for x in sim.w:
			if sim.tiles[y * sim.w + x] == Maps.PIT:
				k.ground(Rect2(x * t, y * t, t, t), -0.14, col)
	if k.is_empty():
		return null
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://gfx/shaders/water.gdshader")
	mat.set_shader_parameter("base_color", col)
	var kind: String = theme["pit"]
	match kind:
		"lava":
			mat.set_shader_parameter("foam_color", Color("ffd23f"))
			mat.set_shader_parameter("glow", 0.25)
			mat.set_shader_parameter("speed", 0.25)
		"syrup":
			mat.set_shader_parameter("foam_color", col.lightened(0.5))
			mat.set_shader_parameter("speed", 0.2)
		"void":
			mat.set_shader_parameter("foam_color", col.lightened(0.2))
			mat.set_shader_parameter("speed", 0.15)
		_:
			mat.set_shader_parameter("foam_color", Color("f2fdff"))
	var inst := MeshInstance3D.new()
	inst.name = "Pits"
	inst.mesh = k.to_mesh()
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return inst


static func _draw_conveyors(sim: Sim) -> MeshInstance3D:
	var k := MeshKit.new()
	k.outline = 0.0
	var t := Maps.TILE
	for y in sim.h:
		for x in sim.w:
			var code := sim.tiles[y * sim.w + x]
			if code < Maps.CON_R or code > Maps.CON_D:
				continue
			# Direction goes in the vertex colour, as 0..1 without the sRGB conversion.
			var dir := Vector2.RIGHT
			match code:
				Maps.CON_L: dir = Vector2.LEFT
				Maps.CON_U: dir = Vector2.UP
				Maps.CON_D: dir = Vector2.DOWN
			var c := Color(dir.x * 0.5 + 0.5, dir.y * 0.5 + 0.5, 0.0)
			var a := Vector3(x * t, 0.0, y * t)
			var b := Vector3(x * t, 0.0, (y + 1) * t)
			var e := Vector3((x + 1) * t, 0.0, (y + 1) * t)
			var d := Vector3((x + 1) * t, 0.0, y * t)
			k._quad(a, b, e, d, Vector3.UP, c, c, c, c, false)
	if k.is_empty():
		return null
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://gfx/shaders/conveyor.gdshader")
	var inst := MeshInstance3D.new()
	inst.name = "Conveyors"
	inst.mesh = k.to_mesh()
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return inst


## Soft dark shapes on the floor where walls would cast a shadow: it's what makes the blocks stand up.
static func _draw_shadows(sim: Sim) -> MeshInstance3D:
	var k := MeshKit.new()
	k.outline = 0.0
	var t := Maps.TILE
	var reach := 0.75
	var dark := Color(0.09, 0.04, 0.25, 0.32)
	for y in sim.h:
		for x in sim.w:
			if sim.tiles[y * sim.w + x] != Maps.SOLID:
				continue
			k.verts.append_array(_shadow_quad(x * t + t, y * t, reach, t))
			for _i in 6:
				k.norms.append(Vector3.UP)
				k.cols.append(dark)
			k.verts.append_array(_shadow_quad(x * t + reach * 0.4, y * t + t, t - reach * 0.4 + reach, reach))
			for _i in 6:
				k.norms.append(Vector3.UP)
				k.cols.append(dark)
	if k.is_empty():
		return null
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	var inst := MeshInstance3D.new()
	inst.name = "Shadows"
	inst.mesh = k.to_mesh()
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return inst


static func _shadow_quad(x: float, y: float, w: float, h: float) -> PackedVector3Array:
	var a := Vector3(x, 0.02, y)
	var b := Vector3(x, 0.02, y + h)
	var c := Vector3(x + w, 0.02, y + h)
	var d := Vector3(x + w, 0.02, y)
	return PackedVector3Array([a, d, c, a, c, b])


static func _draw_border(k: MeshKit, sim: Sim, theme: Dictionary) -> void:
	var size := sim.arena_size()
	var wall := Color(theme["wall"])
	var edge := Color(theme["edge"])
	var accent := Color(theme["accent"])
	var w := 0.7
	var h := WALL_H
	var step := Maps.TILE * 2.0
	# The wall is cut into chunky lengths, alternating colours, around the whole field.
	var x := -w
	var i := 0
	while x < size.x + w:
		var l := minf(step, size.x + w - x)
		var c: Color = wall if i % 2 == 0 else wall.darkened(0.12)
		k.box(Vector3(x + l * 0.5, h * 0.5, -w * 0.5), Vector3(l, h, w), c, 0.07)
		k.box(Vector3(x + l * 0.5, h * 0.5, size.y + w * 0.5), Vector3(l, h, w), c, 0.07)
		if i % 2 == 0:
			k.decal_box(Vector3(x + l * 0.5, h + 0.005, -w * 0.5), Vector3(l - 0.4, 0.015, w * 0.45), accent)
			k.decal_box(Vector3(x + l * 0.5, h + 0.005, size.y + w * 0.5), Vector3(l - 0.4, 0.015, w * 0.45), accent)
		x += l
		i += 1
	var y := 0.0
	i = 0
	while y < size.y:
		var l := minf(step, size.y - y)
		var c: Color = wall if i % 2 == 1 else wall.darkened(0.12)
		k.box(Vector3(-w * 0.5, h * 0.5, y + l * 0.5), Vector3(w, h, l), c, 0.07)
		k.box(Vector3(size.x + w * 0.5, h * 0.5, y + l * 0.5), Vector3(w, h, l), c, 0.07)
		y += l
		i += 1
	# A ledge of the theme's edge colour beyond the wall.
	k.outline = 0.0
	k.ground(Rect2(-w - 1.2, -w - 1.2, size.x + (w + 1.2) * 2.0, size.y + (w + 1.2) * 2.0), -0.3, edge)
	k.outline = 0.035


static func _draw_blocks(k: MeshKit, sim: Sim, theme: Dictionary, rng: RandomNumberGenerator) -> void:
	var blocks: Array = theme["blocks"]
	var accent := Color(theme["accent"])
	var t := Maps.TILE
	for y in sim.h:
		for x in sim.w:
			if sim.tiles[y * sim.w + x] != Maps.SOLID:
				continue
			var at := Vector3((x + 0.5) * t, 0.0, (y + 0.5) * t)
			# Neighbouring tiles share a prop, so a wall reads as one thing.
			var cluster := absi(hash(Vector2i(x / 3, y / 3))) % blocks.size()
			var v := rng.randf()
			PropKit.draw(k, blocks[cluster], at, 0.0 if v < 0.75 else PI * 0.5, 1.0, v, accent)


static func _draw_bases(k: MeshKit, sim: Sim) -> void:
	for team in 2:
		var at: Vector2 = sim.base[team]
		var c: Color = team_color(team)
		var p := Vector3(at.x, 0.0, at.y)
		# A short post stands on the rim of the pad, so nobody hides behind it.
		var pole := p + Vector3(0, 0, -(Sim.BASE_R + 0.2))
		k.cyl(pole, 0.26, 0.3, 0.24, Color("fff3d6"), 10)
		k.cyl(pole, 3.2, 0.07, 0.07, Color("fff3d6"), 6)
		k.ball(pole + Vector3(0, 3.28, 0), Vector3(0.14, 0.14, 0.14), Color("ffd23f"), 3, 7)
		var dir := 1.0 if team == 0 else -1.0
		var top := pole + Vector3(0, 3.1, 0)
		k.outline = 0.0
		k.quad(top, top + Vector3(0, -0.95, 0), top + Vector3(dir * 1.5, -0.48, 0), top + Vector3(dir * 1.5, -0.48, 0), c if dir > 0 else c)
		k.quad(top + Vector3(dir * 1.5, -0.48, 0), top + Vector3(0, -0.95, 0), top, top, c)
		k.outline = 0.035
		# Rim stones around the pad.
		for i in 16:
			var a := TAU * i / 16.0
			if absf(sin(a) + 1.0) < 0.05:
				continue
			var stone := p + Vector3(cos(a), 0, sin(a)) * (Sim.BASE_R + 0.32)
			k.ball(stone + Vector3(0, 0.05, 0), Vector3(0.18, 0.11, 0.18), Color("fff3d6") if i % 2 == 0 else c, 2, 6)


static func _draw_jails(k: MeshKit, sim: Sim) -> void:
	for team in 2:
		var at: Vector2 = sim.jail[team]
		var p := Vector3(at.x, 0.0, at.y)
		var bamboo := Color("c9b95c")
		var count := 14
		for i in count:
			var a := TAU * i / float(count)
			var bar := p + Vector3(cos(a), 0, sin(a)) * Sim.JAIL_R
			k.cyl(bar, 1.2, 0.09, 0.08, bamboo if i % 2 == 0 else bamboo.darkened(0.1), 5)
		k.torus(p + Vector3(0, 1.1, 0), Sim.JAIL_R, 0.06, Color("8a7a3a"), 18, 4)
		k.torus(p + Vector3(0, 0.55, 0), Sim.JAIL_R, 0.05, Color("8a7a3a"), 18, 4)
		# A small roof, off to the back, so the prisoners stay visible.
		var sign := p + Vector3(0, 0, -Sim.JAIL_R - 0.2)
		k.box(sign + Vector3(0, 1.3, 0), Vector3(1.5, 0.5, 0.1), team_color(team), 0.02)
		for s: float in [-0.5, 0.5]:
			k.decal_box(sign + Vector3(s, 1.3, 0.06), Vector3(0.09, 0.42, 0.02), Color("24135f"))
		k.decal_box(sign + Vector3(0, 1.3, 0.06), Vector3(0.09, 0.42, 0.02), Color("24135f"))


static func _draw_decor(k: MeshKit, sim: Sim, theme: Dictionary, rng: RandomNumberGenerator, low_detail: bool) -> void:
	var decor: Array = theme["decor"]
	var accent := Color(theme["accent"])
	var size := sim.arena_size()
	var margin := 3.2
	var count := 28 if low_detail else 46
	var placed: Array[Vector2] = []
	var tries := 0
	while placed.size() < count and tries < 400:
		tries += 1
		var side := rng.randi_range(0, 3)
		var depth := rng.randf_range(margin, margin + 11.0)
		var at := Vector2.ZERO
		match side:
			0: at = Vector2(rng.randf_range(-10.0, size.x + 10.0), -depth)
			1: at = Vector2(rng.randf_range(-10.0, size.x + 10.0), size.y + depth)
			2: at = Vector2(-depth, rng.randf_range(-10.0, size.y + 10.0))
			_: at = Vector2(size.x + depth, rng.randf_range(-10.0, size.y + 10.0))
		var close := false
		for other: Vector2 in placed:
			if other.distance_to(at) < 4.0:
				close = true
				break
		if close:
			continue
		placed.append(at)
		var prop: String = decor[rng.randi_range(0, decor.size() - 1)]
		var yaw := rng.randf() * TAU
		if prop == "banderitas":
			yaw = rng.randf_range(-0.3, 0.3)
		elif prop == "building" or prop == "hut":
			yaw = (PI if side == 1 else 0.0) + rng.randf_range(-0.2, 0.2)
		PropKit.draw(k, prop, Vector3(at.x, -0.3, at.y), yaw, rng.randf_range(0.9, 1.25), rng.randf(), accent)


static func _draw_grass(sim: Sim, theme: Dictionary, rng: RandomNumberGenerator, low_detail: bool) -> MeshInstance3D:
	var k := MeshKit.new()
	k.outline = 0.0
	var c := Color(theme["grass"])
	var t := Maps.TILE
	var tufts := 4 if low_detail else 7
	for y in sim.h:
		for x in sim.w:
			if sim.tiles[y * sim.w + x] != Maps.GRASS:
				continue
			k.ground(Rect2(x * t, y * t, t, t), 0.004, c.darkened(0.22))
			for _i in tufts:
				var px := (x + rng.randf_range(0.1, 0.9)) * t
				var pz := (y + rng.randf_range(0.1, 0.9)) * t
				var h := rng.randf_range(1.0, 1.6)
				var wide := rng.randf_range(0.22, 0.34)
				var yaw := rng.randf() * TAU
				var side := Vector3(cos(yaw), 0, sin(yaw)) * wide
				var tone := c.lightened(rng.randf_range(-0.08, 0.16))
				var lean := Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))
				k.blade(Vector3(px, 0, pz) - side, Vector3(px, 0, pz) + side, Vector3(px, h, pz) + lean, tone, 1.0)
				k.blade(Vector3(px, 0, pz) - side.cross(Vector3.UP), Vector3(px, 0, pz) + side.cross(Vector3.UP), Vector3(px, h * 0.85, pz) - lean, tone.darkened(0.1), 1.0)
	if k.is_empty():
		return null
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://gfx/shaders/grass.gdshader")
	var inst := MeshInstance3D.new()
	inst.name = "Grass"
	inst.mesh = k.to_mesh()
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return inst


## Temporary wall segment (Pop-Up Wall), one tile.
static func wall_mesh(theme_id: String) -> ArrayMesh:
	var theme: Dictionary = Maps.THEMES.get(theme_id, Maps.THEMES["barrio"])
	var k := MeshKit.new()
	k.box(Vector3(0, 0.7, 0), Vector3(Maps.TILE - 0.06, 1.4, Maps.TILE - 0.06), Color(theme["accent"]), 0.1)
	k.decal_box(Vector3(0, 1.41, 0), Vector3(0.9, 0.02, 0.9), Color(theme["accent"]).lightened(0.3))
	return k.to_mesh()
