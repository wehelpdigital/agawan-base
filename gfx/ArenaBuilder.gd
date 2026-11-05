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
	var props := prop_material()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sim.map_id)

	var floor_kit := MeshKit.new()
	floor_kit.outline = 0.0
	_draw_background(floor_kit, sim, theme)
	_draw_floor(floor_kit, sim, theme, rng)
	_draw_midline(floor_kit, sim)
	_draw_pads(floor_kit, sim)
	_add(root, floor_kit, toon, "Floor")

	var pit := _draw_pits(sim, theme)
	if pit:
		root.add_child(pit)
	var belts := _draw_belts(sim, Maps.CON_R, Maps.CON_D, Color("3f5a88"), Color("9fd8ff"), 3.3)
	if belts:
		root.add_child(belts)
	var dash_floors := _draw_belts(sim, Maps.DASH_R, Maps.DASH_D, Color("ff7a1f"), Color("fff176"), 9.0)
	if dash_floors:
		root.add_child(dash_floors)
	var shadows := _draw_shadows(sim)
	if shadows:
		root.add_child(shadows)

	# Everything on the field is soft and rounded, to match the players.
	var solid := prop_kit(low_detail)
	_draw_border(solid, sim, theme)
	_draw_blocks(solid, sim, theme, rng)
	_draw_bases(solid, sim)
	_draw_jails(solid, sim)
	_draw_tricks(solid, sim)
	_draw_line_posts(solid, sim)
	_add(root, solid, props, "Solid")

	var deco := prop_kit(low_detail)
	deco.detail = 0.6 if low_detail else 0.85
	_draw_decor(deco, sim, theme, rng, low_detail)
	_add(root, deco, props, "Decor")

	var grass := _draw_grass(sim, theme, rng, low_detail)
	if grass:
		root.add_child(grass)
	return root


static func prop_kit(low_detail: bool) -> MeshKit:
	var kit := MeshKit.new()
	kit.soften = true
	kit.shells = false
	kit.outline = 0.02
	kit.detail = 0.7 if low_detail else 1.0
	return kit


static func prop_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://gfx/shaders/toon.gdshader")
	mat.set_shader_parameter("soft", 1.0)
	return mat


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


## Lush ground, no checkerboard: two colours drift into each other in big soft patches, with a worn path between the bases.
static func _draw_floor(k: MeshKit, sim: Sim, theme: Dictionary, rng: RandomNumberGenerator) -> void:
	var t := Maps.TILE
	var light := Color(theme["floor"][0]).lightened(0.05)
	var dark := Color(theme["floor"][1]).darkened(0.07)
	var worn := light.lerp(Color(theme["edge"]), 0.32).lightened(0.14)
	var noise := FastNoiseLite.new()
	noise.seed = absi(hash(sim.map_id)) % 100000
	noise.frequency = 0.075
	noise.fractal_octaves = 2
	var leafy: bool = String(Maps.by_id(sim.map_id)["theme"]) in ["barrio", "terraces", "mangrove", "schoolyard", "ruins"]
	var accent := Color(theme["accent"])
	var mid_y: float = (sim.base[0].y + sim.base[1].y) * 0.5
	var mid_x: float = sim.w * t * 0.5
	var shade := func(px: float, py: float, side: Color) -> Color:
		var n := clampf(noise.get_noise_2d(px, py) * 1.9 + 0.5, 0.0, 1.0)
		var c := light.lerp(dark, smoothstep(0.34, 0.66, n))
		# The path wanders a little, and it fades out as it gets to the sides.
		var wander := sin(px * 0.18 + float(noise.seed)) * 1.0
		var on_path := 1.0 - smoothstep(0.7, 1.7, absf(py - mid_y - wander))
		c = c.lerp(worn, on_path * 0.62)
		# Each team's ground takes on its colour, most of all along the line, so you always know whose side you're on.
		return c.lerp(side, 0.13 + 0.2 * (1.0 - smoothstep(0.0, 6.0, absf(px - mid_x))))
	var cols := sim.w * 2
	var rows := sim.h * 2
	var cell := t * 0.5
	for gy in rows:
		for gx in cols:
			var under := sim.tiles[(gy / 2) * sim.w + gx / 2]
			if under == Maps.PIT or (under >= Maps.CON_R and under <= Maps.DASH_D):
				continue
			var x0 := gx * cell
			var y0 := gy * cell
			var x1 := x0 + cell
			var y1 := y0 + cell
			var side: Color = team_color(0 if gx < cols / 2 else 1)
			k._quad(Vector3(x0, 0, y0), Vector3(x0, 0, y1), Vector3(x1, 0, y1), Vector3(x1, 0, y0), Vector3.UP,
				shade.call(x0, y0, side), shade.call(x0, y1, side), shade.call(x1, y1, side), shade.call(x1, y0, side), false)
	for y in sim.h:
		for x in sim.w:
			var code := sim.tiles[y * sim.w + x]
			var center := Vector2((x + 0.5) * t, (y + 0.5) * t)
			match code:
				Maps.ICE:
					_blob_tile(k, sim, x, y, Maps.ICE, 0.006, Color("d8f6ff"))
					if rng.randf() < 0.3:
						k.ground(Rect2(center.x - 0.4, center.y + rng.randf_range(-0.5, 0.5), 0.8, 0.06), 0.012, Color("f6fdff"))
				Maps.MUD:
					_blob_tile(k, sim, x, y, Maps.MUD, 0.006, Color("8a6240"))
					if rng.randf() < 0.45:
						_disc(k, center + Vector2(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5)), rng.randf_range(0.14, 0.26), 0.012, Color("6a4830"), 10)
				Maps.FLOOR:
					if rng.randf() < 0.3:
						_floor_detail(k, center + Vector2(rng.randf_range(-0.8, 0.8), rng.randf_range(-0.8, 0.8)), light, leafy, accent, rng)
				Maps.BOUNCE:
					_disc(k, center, t * 0.46, 0.01, Color("ff4f8b"), 20)
					_disc(k, center, t * 0.3, 0.012, Color("ffd23f"), 18)
					_disc(k, center, t * 0.14, 0.014, Color("ff4f8b"), 12)
				Maps.TELE:
					_disc(k, center, t * 0.48, 0.01, Color("123a6b"), 20)
					_disc(k, center, t * 0.38, 0.012, Color("b768ff"), 20)
					_disc(k, center, t * 0.2, 0.014, Color("27e9ff"), 16)
				Maps.LAND:
					_landing_box(k, center)
				Maps.GATE:
					_gate_track(k, center)


## The line that decides who can tag who: bold, straight across the field, in both teams' colours.
static func _draw_midline(k: MeshKit, sim: Sim) -> void:
	var size := sim.arena_size()
	var mid := size.x * 0.5
	k.ground(Rect2(mid - 0.62, 0, 0.3, size.y), 0.018, team_color(0))
	k.ground(Rect2(mid + 0.32, 0, 0.3, size.y), 0.018, team_color(1))
	k.ground(Rect2(mid - 0.34, 0, 0.68, size.y), 0.02, Color("fffdf4"))


## A tall post at each end of the line, flying both teams' flags.
static func _draw_line_posts(k: MeshKit, sim: Sim) -> void:
	var size := sim.arena_size()
	var mid := size.x * 0.5
	for z: float in [-0.35, size.y + 0.35]:
		var post := Vector3(mid, 0, z)
		k.cyl(post, 0.5, 0.42, 0.3, Color("fff3d6"), 12)
		k.cyl(post, 4.6, 0.1, 0.09, Color("fff3d6"), 8)
		k.ball(post + Vector3(0, 4.7, 0), Vector3(0.2, 0.2, 0.2), Color("ffd23f"), 6, 10)
		_pennant(k, post + Vector3(0, 4.5, 0), -1.0, 2.0, 1.2, team_color(0))
		_pennant(k, post + Vector3(0, 4.5, 0), 1.0, 2.0, 1.2, team_color(1))


## A tile of ice or mud with its corners rounded off, joining smoothly on to any neighbour of the same kind.
static func _blob_tile(k: MeshKit, sim: Sim, x: int, y: int, code: int, lift: float, color: Color) -> void:
	var t := Maps.TILE
	var center := Vector2((x + 0.5) * t, (y + 0.5) * t)
	var r := t * 0.3
	k.ground(Rect2(center.x - t * 0.5, center.y - t * 0.5 + r, t, t - r * 2.0), lift, color)
	k.ground(Rect2(center.x - t * 0.5 + r, center.y - t * 0.5, t - r * 2.0, t), lift, color)
	for s: Vector2i in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		var side := _tile_code(sim, x + s.x, y) == code
		var over := _tile_code(sim, x, y + s.y) == code
		var corner := center + Vector2(s) * (t * 0.5 - r)
		_disc(k, corner, r, lift, color, 10)
		if side or over:
			var fill := Rect2(center.x + (0.0 if s.x > 0 else -t * 0.5), center.y + (0.0 if s.y > 0 else -t * 0.5), t * 0.5, t * 0.5)
			if side and over:
				k.ground(fill, lift, color)


static func _tile_code(sim: Sim, x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= sim.w or y >= sim.h:
		return Maps.SOLID
	return sim.tiles[y * sim.w + x]


## Where a jump pad lands you: a bold dashed box with a target in it.
static func _landing_box(k: MeshKit, center: Vector2) -> void:
	var half := Maps.TILE * 0.47
	var yellow := Color("ffd23f")
	var white := Color("fff6e0")
	_disc(k, center, half * 0.72, 0.012, Color(0.0, 0.0, 0.0, 0.0).lerp(Color("ff5a4e"), 1.0), 24)
	_disc(k, center, half * 0.48, 0.014, white, 22)
	_disc(k, center, half * 0.24, 0.016, Color("ff5a4e"), 16)
	var long := half * 0.62
	var thick := 0.13
	for s: float in [-1.0, 1.0]:  # Corners of the box.
		for u: float in [-1.0, 1.0]:
			var corner := center + Vector2(s, u) * half
			k.ground(Rect2(minf(corner.x, corner.x - s * long), minf(corner.y, corner.y - u * thick), long, thick), 0.012, yellow)
			k.ground(Rect2(minf(corner.x, corner.x - s * thick), minf(corner.y, corner.y - u * long), thick, long), 0.012, yellow)


## The slot in the ground that a gate comes up out of: warning stripes.
static func _gate_track(k: MeshKit, center: Vector2) -> void:
	var half := Maps.TILE * 0.5
	k.ground(Rect2(center - Vector2(half, half), Vector2(half, half) * 2.0), 0.008, Color("3a3a58"))
	for i in 4:
		var at := center.x - half + 0.08 + i * (half * 2.0 - 0.16) / 4.0
		k.ground(Rect2(at, center.y - half + 0.1, 0.25, half * 2.0 - 0.2), 0.012, Color("ffc21f"))


## What stands on the field and does something: jump pads, fountains, altars, fences and bumpers.
static func _draw_tricks(k: MeshKit, sim: Sim) -> void:
	var t := Maps.TILE
	for y in sim.h:
		for x in sim.w:
			var i := y * sim.w + x
			var at := Vector3((x + 0.5) * t, 0.0, (y + 0.5) * t)
			match sim.tiles[i]:
				Maps.JUMP:
					_jump_pad(k, at, sim.tile_center(sim.jumps.get(i, i)))
				Maps.FOUNTAIN:
					_fountain(k, at)
				Maps.ALTAR:
					_altar(k, at)
				Maps.FENCE:
					_fence(k, at, _tile_code(sim, x, y - 1) == Maps.FENCE or _tile_code(sim, x, y + 1) == Maps.FENCE)
				Maps.BUMPER:
					_bumper(k, at)


## A big spring, with a dotted line through the air to the box it lands you on.
static func _jump_pad(k: MeshKit, at: Vector3, land: Vector2) -> void:
	var red := Color("ff5a4e")
	k.ball(at + Vector3(0, 0.05, 0), Vector3(0.85, 0.08, 0.85), Color("3a3a58"), 6, 16)
	for i in 3:
		k.torus(at + Vector3(0, 0.12 + i * 0.13, 0), 0.54, 0.075, Color("dfe4f4"), 18, 6)
	k.ball(at + Vector3(0, 0.5, 0), Vector3(0.78, 0.13, 0.78), red, 8, 18)
	k.outline = 0.0
	k.ball(at + Vector3(0, 0.6, 0), Vector3(0.42, 0.05, 0.42), Color("ffd23f"), 4, 14)
	var to := Vector3(land.x, 0.0, land.y)
	var length := at.distance_to(to)
	var high := clampf(length * 0.45, 1.0, 4.0)
	var dots := clampi(int(length / 1.1), 4, 12)
	for i in range(1, dots):
		var f := float(i) / dots
		var spot := at.lerp(to, f) + Vector3(0, sin(f * PI) * high + 0.2, 0)
		k.ball(spot, Vector3.ONE * 0.085, Color("fff6e0"), 3, 6)
	k.outline = 0.02


static func _fountain(k: MeshKit, at: Vector3) -> void:
	var stone := Color("f4ecd8")
	k.cyl(at, 0.2, 0.92, 0.86, stone, 22)
	k.torus(at + Vector3(0, 0.2, 0), 0.82, 0.09, stone.lightened(0.3), 24, 6)
	k.outline = 0.0
	k.ball(at + Vector3(0, 0.215, 0), Vector3(0.74, 0.02, 0.74), Color("4fc8f4"), 4, 20)
	k.outline = 0.02
	k.cyl(at, 0.5, 0.17, 0.11, stone, 12)


static func _altar(k: MeshKit, at: Vector3) -> void:
	k.cyl(at, 0.1, 0.9, 0.84, Color("7a6ad8"), 20)
	k.cyl(at + Vector3(0, 0.1, 0), 0.12, 0.62, 0.54, Color("a697ff"), 18)
	k.outline = 0.0
	for i in 6:
		var a := TAU * i / 6.0
		k.ball(at + Vector3(cos(a) * 0.74, 0.105, sin(a) * 0.74), Vector3(0.09, 0.012, 0.09), Color("ffd23f"), 3, 8)
	k.outline = 0.02


## A low picket fence, along whichever way its neighbours run.
static func _fence(k: MeshKit, at: Vector3, upright: bool) -> void:
	var half := Maps.TILE * 0.5
	var white := Color("fff6e0")
	var along := Vector3(0, 0, 1) if upright else Vector3(1, 0, 0)
	for i in 5:
		var f := lerpf(-0.85, 0.85, i / 4.0)
		k.soft_box(at + along * half * f + Vector3(0, 0.3, 0), Vector3(0.09, 0.3, 0.09), white, 0.6, 5, 8)
	var rail_half := Vector3(0.05, 0.05, half) if upright else Vector3(half, 0.05, 0.05)
	k.soft_box(at + Vector3(0, 0.38, 0), rail_half, Color("ff9d2e"), 0.6, 4, 8)
	k.soft_box(at + Vector3(0, 0.2, 0), rail_half, Color("ff9d2e"), 0.6, 4, 8)


## A big bouncy mushroom. It looks like it would hurt, and it does.
static func _bumper(k: MeshKit, at: Vector3) -> void:
	k.cyl(at, 0.5, 0.5, 0.42, Color("fff1d6"), 14)
	k.ball(at + Vector3(0, 0.75, 0), Vector3(0.98, 0.5, 0.98), Color("ff5a4e"), 10, 18)
	k.outline = 0.0
	k.ball(at + Vector3(0, 1.2, 0), Vector3(0.26, 0.05, 0.26), Color("fff6e0"), 4, 10)
	for i in 5:
		var a := TAU * i / 5.0
		k.push(Transform3D(Basis(Vector3.UP, -a) * Basis(Vector3.BACK, -0.72), at + Vector3(cos(a) * 0.68, 1.0, sin(a) * 0.68)))
		k.ball(Vector3.ZERO, Vector3(0.17, 0.03, 0.17), Color("fff6e0"), 4, 9)
		k.pop()
	k.outline = 0.02


## Team-coloured ground under each base and jail; markers on top come from the match view.
static func _draw_pads(k: MeshKit, sim: Sim) -> void:
	for team in 2:
		var c: Color = team_color(team)
		_disc(k, sim.jail[team], Sim.JAIL_R + 0.18, 0.012, Color("123a6b"), 36)
		_disc(k, sim.jail[team], Sim.JAIL_R, 0.014, c.lerp(Color("3a3058"), 0.68), 36)
		_disc(k, sim.base[team], Sim.BASE_R + 0.22, 0.012, Color("123a6b"), 64)
		_disc(k, sim.base[team], Sim.BASE_R, 0.014, c, 64)
		_rays(k, sim.base[team], Sim.BASE_R * 0.32, Sim.BASE_R * 0.86, 0.016, c.lightened(0.34), 14)
		_disc(k, sim.base[team], Sim.BASE_R * 0.36, 0.018, c.darkened(0.08), 40)
		_disc(k, sim.base[team], Sim.BASE_R * 0.24, 0.02, c.lightened(0.52), 32)


## Sun rays round a base, so it reads as a place, not a target.
static func _rays(k: MeshKit, at: Vector2, inner: float, outer: float, y: float, color: Color, count: int) -> void:
	var c := Vector3(at.x, y, at.y)
	for i in count:
		var mid := TAU * i / count
		var half := TAU / count * 0.26
		var a := c + Vector3(cos(mid - half), 0, sin(mid - half)) * inner
		var b := c + Vector3(cos(mid + half), 0, sin(mid + half)) * inner
		var d := c + Vector3(cos(mid + half * 0.72), 0, sin(mid + half * 0.72)) * outer
		var e := c + Vector3(cos(mid - half * 0.72), 0, sin(mid - half * 0.72)) * outer
		k._tri(a, d, e, Vector3.UP, Vector3.UP, Vector3.UP, color, color, color, false)
		k._tri(a, b, d, Vector3.UP, Vector3.UP, Vector3.UP, color, color, color, false)


## Something small on the ground to break up the checks: on green maps a flower or a tuft, otherwise a few pebbles.
static func _floor_detail(k: MeshKit, at: Vector2, floor_colour: Color, leafy: bool, accent: Color, rng: RandomNumberGenerator) -> void:
	var kind := rng.randf()
	if leafy and kind < 0.3:
		for i in 5:
			var a := TAU * i / 5.0
			_disc(k, at + Vector2(cos(a), sin(a)) * 0.075, 0.06, 0.006, Color.WHITE if rng.randf() < 0.6 else accent.lightened(0.3), 6)
		_disc(k, at, 0.045, 0.008, Color("ffd23f"), 6)
	elif leafy and kind < 0.75:
		var tone := floor_colour.darkened(0.2)
		for i in 3:
			_disc(k, at + Vector2(i * 0.13 - 0.13, -absf(i - 1.0) * -0.05), 0.075, 0.006, tone, 6)
	else:
		var tone := floor_colour.darkened(0.13)
		_disc(k, at, rng.randf_range(0.06, 0.11), 0.006, tone, 7)
		_disc(k, at + Vector2(0.2, 0.07), rng.randf_range(0.04, 0.07), 0.006, tone, 6)


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


## Strips of moving arrows: conveyor belts, and much faster, dash floors.
static func _draw_belts(sim: Sim, first_code: int, last_code: int, belt: Color, mark: Color, speed: float) -> MeshInstance3D:
	var k := MeshKit.new()
	k.outline = 0.0
	var t := Maps.TILE
	for y in sim.h:
		for x in sim.w:
			var code := sim.tiles[y * sim.w + x]
			if code < first_code or code > last_code:
				continue
			# Direction goes in the vertex colour, as 0..1 without the sRGB conversion.
			var dir := Vector2.RIGHT
			match code - first_code:
				1: dir = Vector2.LEFT
				2: dir = Vector2.UP
				3: dir = Vector2.DOWN
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
	mat.set_shader_parameter("belt", belt)
	mat.set_shader_parameter("mark", mark)
	mat.set_shader_parameter("speed", speed)
	mat.set_shader_parameter("tile", t)
	var inst := MeshInstance3D.new()
	inst.name = "Belts"
	inst.mesh = k.to_mesh()
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return inst


## A soft dark pool on the floor under each wall tile, fading out at its edge: it's what makes the blocks stand up.
static func _draw_shadows(sim: Sim) -> MeshInstance3D:
	var k := MeshKit.new()
	k.outline = 0.0
	var t := Maps.TILE
	var dark := Color(0.09, 0.04, 0.25, 0.34)
	var clear := Color(0.09, 0.04, 0.25, 0.0)
	var segs := 14
	for y in sim.h:
		for x in sim.w:
			if sim.tiles[y * sim.w + x] != Maps.SOLID:
				continue
			var c := Vector3((x + 0.5) * t + 0.22, 0.022, (y + 0.5) * t + 0.3)
			var r := t * 0.86
			for i in segs:
				var a0 := TAU * i / segs
				var a1 := TAU * (i + 1) / segs
				k.verts.append_array(PackedVector3Array([c, c + Vector3(cos(a0), 0, sin(a0)) * r, c + Vector3(cos(a1), 0, sin(a1)) * r]))
				k.norms.append_array(PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP]))
				k.cols.append_array(PackedColorArray([dark, clear, clear]))
	if k.is_empty():
		return null
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var inst := MeshInstance3D.new()
	inst.name = "Shadows"
	inst.mesh = k.to_mesh()
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return inst


static func _draw_border(k: MeshKit, sim: Sim, theme: Dictionary) -> void:
	var size := sim.arena_size()
	var wall := Color(theme["wall"])
	var edge := Color(theme["edge"])
	var w := 0.7
	var h := WALL_H
	var step := 3.0
	# The wall is cut into chunky lengths, alternating colours, around the whole field.
	var x := -w
	var i := 0
	while x < size.x + w:
		var l := minf(step, size.x + w - x)
		var c: Color = wall if i % 2 == 0 else team_color(0 if x + l * 0.5 < size.x * 0.5 else 1)
		k.soft_box(Vector3(x + l * 0.5, h * 0.5, -w * 0.5), Vector3(l, h, w) * 0.5, c, 0.42, 6, 10)
		k.soft_box(Vector3(x + l * 0.5, h * 0.5, size.y + w * 0.5), Vector3(l, h, w) * 0.5, c, 0.42, 6, 10)
		x += l
		i += 1
	var y := 0.0
	i = 0
	while y < size.y:
		var l := minf(step, size.y - y)
		k.soft_box(Vector3(-w * 0.5, h * 0.5, y + l * 0.5), Vector3(w, h, l) * 0.5, wall if i % 2 == 1 else team_color(0), 0.42, 6, 10)
		k.soft_box(Vector3(size.x + w * 0.5, h * 0.5, y + l * 0.5), Vector3(w, h, l) * 0.5, wall if i % 2 == 1 else team_color(1), 0.42, 6, 10)
		y += l
		i += 1
	# A ledge of the theme's edge colour beyond the wall.
	k.outline = 0.0
	k.ground(Rect2(-w - 1.2, -w - 1.2, size.x + (w + 1.2) * 2.0, size.y + (w + 1.2) * 2.0), -0.3, edge)
	k.outline = 0.02


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
			PropKit.draw(k, blocks[cluster], at, 0.0 if v < 0.75 else PI * 0.5, t / 1.5, v, accent)


static func _draw_bases(k: MeshKit, sim: Sim) -> void:
	for team in 2:
		var at: Vector2 = sim.base[team]
		var c: Color = team_color(team)
		var p := Vector3(at.x, 0.0, at.y)
		var dir := 1.0 if team == 0 else -1.0
		# A low round kerb all the way round, in the team's colour, with a cream stone every so often.
		k.torus(p + Vector3(0, 0.04, 0), Sim.BASE_R + 0.1, 0.13, c.darkened(0.14), 40, 6)
		for i in 12:
			var a := TAU * i / 12.0 + TAU / 24.0
			k.ball(p + Vector3(cos(a), 0, sin(a)) * (Sim.BASE_R + 0.1) + Vector3(0, 0.1, 0), Vector3(0.22, 0.13, 0.22), Color("fff3d6"), 2, 6)
		# A big flag behind the base, and four small ones on the rim, so it's clear from anywhere how far it reaches.
		var pole := p + Vector3(-dir * (Sim.BASE_R + 0.45), 0, 0)
		k.cyl(pole, 0.34, 0.34, 0.26, Color("fff3d6"), 10)
		k.cyl(pole, 4.4, 0.085, 0.085, Color("fff3d6"), 6)
		k.ball(pole + Vector3(0, 4.46, 0), Vector3(0.17, 0.17, 0.17), Color("ffd23f"), 3, 7)
		_pennant(k, pole + Vector3(0, 4.3, 0), dir, 2.0, 1.25, c)
		for s: Vector2 in [Vector2(0.72, 0.7), Vector2(0.72, -0.7), Vector2(-0.72, 0.7), Vector2(-0.72, -0.7)]:
			var post := p + Vector3(s.x, 0, s.y) * (Sim.BASE_R + 0.32)
			k.cyl(post, 1.5, 0.06, 0.06, Color("fff3d6"), 6)
			_pennant(k, post + Vector3(0, 1.48, 0), dir, 0.72, 0.46, c.lightened(0.14))


## A flag: two-sided, so it shows from either side, hanging off the top of its pole.
static func _pennant(k: MeshKit, top: Vector3, dir: float, length: float, drop: float, c: Color) -> void:
	var saved := k.outline
	k.outline = 0.0
	var tip := top + Vector3(dir * length, -drop * 0.5, 0)
	var foot := top + Vector3(0, -drop, 0)
	k.quad(top, foot, tip, tip, c)
	k.quad(tip, foot, top, top, c)
	k.outline = saved


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
			k.decal_box(sign + Vector3(s, 1.3, 0.06), Vector3(0.09, 0.42, 0.02), Color("123a6b"))
		k.decal_box(sign + Vector3(0, 1.3, 0.06), Vector3(0.09, 0.42, 0.02), Color("123a6b"))


static func _draw_decor(k: MeshKit, sim: Sim, theme: Dictionary, rng: RandomNumberGenerator, low_detail: bool) -> void:
	var decor: Array = theme["decor"]
	var accent := Color(theme["accent"])
	var size := sim.arena_size()
	var margin := 3.2
	var count := 36 if low_detail else 64
	var placed: Array[Vector2] = []
	var tries := 0
	while placed.size() < count and tries < 600:
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


## Tall grass is a soft hedge: round puffs, fuller where tiles of it meet, with lighter ones on top and the odd flower.
static func _draw_grass(sim: Sim, theme: Dictionary, rng: RandomNumberGenerator, low_detail: bool) -> MeshInstance3D:
	var k := MeshKit.new()
	k.outline = 0.0
	var c := Color(theme["grass"])
	var accent := Color(theme["accent"])
	var t := Maps.TILE
	var rings := 3 if low_detail else 4
	var segs := 7 if low_detail else 10
	var spots: Array[Vector2] = [Vector2(0.25, 0.25), Vector2(0.75, 0.3), Vector2(0.3, 0.75), Vector2(0.72, 0.72)]
	for y in sim.h:
		for x in sim.w:
			if sim.tiles[y * sim.w + x] != Maps.GRASS:
				continue
			_disc(k, Vector2((x + 0.5) * t, (y + 0.5) * t), t * 0.66, 0.004, c.darkened(0.3), 14)
			for spot in spots:
				var at := Vector2((x + spot.x + rng.randf_range(-0.07, 0.07)) * t, (y + spot.y + rng.randf_range(-0.07, 0.07)) * t)
				var wide := rng.randf_range(0.62, 0.8) * t * 0.72
				var tall := rng.randf_range(1.05, 1.38)
				var tone := c.lightened(rng.randf_range(-0.05, 0.1))
				k.puff(Vector3(at.x, 0.0, at.y), Vector3(wide, tall, wide), tone, tone.darkened(0.42), rings, segs)
			# Smaller, lighter puffs on top: the leaves catching the sun.
			for _i in 2 if low_detail else 4:
				var at := Vector2((x + rng.randf_range(0.15, 0.85)) * t, (y + rng.randf_range(0.15, 0.85)) * t)
				var wide := rng.randf_range(0.2, 0.34)
				var tone := c.lightened(rng.randf_range(0.14, 0.3))
				k.puff(Vector3(at.x, rng.randf_range(0.82, 1.06), at.y), Vector3(wide, wide * 0.92, wide), tone, tone.darkened(0.2), 2, 7 if low_detail else 8)
			if rng.randf() < 0.3:
				var at := Vector2((x + rng.randf_range(0.2, 0.8)) * t, (y + rng.randf_range(0.2, 0.8)) * t)
				k.puff(Vector3(at.x, 1.16, at.y), Vector3(0.13, 0.11, 0.13), accent.lightened(0.25), accent, 2, 6)
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
	return block_mesh(Color(theme["accent"]), 1.4)


## A tile-sized rounded block: Pop-Up Walls and gates.
static func block_mesh(color: Color, height: float, stripes := false) -> ArrayMesh:
	var k := MeshKit.new()
	k.soften = true
	k.shells = false
	k.outline = 0.02
	var half := Vector3(Maps.TILE * 0.5 - 0.03, height * 0.5, Maps.TILE * 0.5 - 0.03)
	k.soft_box(Vector3(0, height * 0.5, 0), half, color, 0.42, 8, 14)
	if stripes:
		for y: float in [0.3, 0.7]:
			k.soft_box(Vector3(0, height * y, 0), Vector3(half.x + 0.015, height * 0.09, half.z + 0.015), Color("ffc21f"), 0.42, 4, 14)
	else:
		k.outline = 0.0
		k.ball(Vector3(0, height - 0.01, 0), Vector3(half.x * 0.6, 0.03, half.z * 0.6), color.lightened(0.3), 4, 12)
	return k.to_mesh()
