class_name WorldProps
extends RefCounted
## Toy models of places around the world, for the world maps. Same rules as PropKit: each stands on y = 0, and blocks
## are about 1.5 m wide. Landmarks stand well outside the field, so they're big and simple, and cheap on triangles.

const WOOD := Color("a8743c")
const DARK_WOOD := Color("7a4a26")
const WHITE := Color("fbf8ef")
const STONE := Color("cfc6b0")
const INK := Color("0a1426")
const GOLD := Color("ffc21f")
const RED := Color("e8483f")
const GLASS := Color("7fc4f0")
const LEAF := Color("4cbc5e")


## False when the name isn't one of these.
static func draw(k: MeshKit, prop: String, v: float, accent: Color) -> bool:
	match prop:
		"torii": _torii(k)
		"pagoda": _pagoda(k, v)
		"sakura": _blossom_tree(k, v)
		"stone_lantern": _stone_lantern(k)
		"bamboo": _bamboo(k, v)
		"vending": _vending(k, v)
		"billboard": _billboard(k, accent, v)
		"tokyo_tower": _tokyo_tower(k)
		"skyscraper": _skyscraper(k, v)
		"bullet_train": _bullet_train(k)
		"cafe": _cafe(k, v)
		"flower_box": _flower_box(k, v)
		"kiosk": _kiosk(k, accent)
		"eiffel": _eiffel(k)
		"townhouse": _townhouse(k, v)
		"paris_lamp": _street_lamp(k)
		"taxi": _car(k, Color("ffc21f"), true)
		"red_bus": _red_bus(k)
		"phone_box": _phone_box(k)
		"mailbox": _mailbox(k)
		"big_clock": _big_clock(k)
		"hydrant": _hydrant(k)
		"liberty": _liberty(k)
		"water_tower": _water_tower(k)
		"drums": _drums(k, accent)
		"float": _carnival_float(k, accent)
		"sugarloaf": _sugarloaf(k)
		"toucan_tree": _toucan_tree(k)
		"sandstone": _sandstone(k, v)
		"pottery": _pottery(k, v)
		"obelisk": _obelisk(k)
		"pyramid": _pyramid(k, v)
		"sphinx": _sphinx(k)
		"camel": _camel(k)
		"rugs": _rugs(k, v)
		"spices": _spices(k)
		"riad": _riad(k, v)
		"tent": _tent(k, accent)
		"lantern_post": _lantern_post(k)
		"planter": _planter(k)
		"marble": _marble(k)
		"taj": _taj(k)
		"cypress": _cypress(k)
		"elephant": _elephant(k)
		"tuk_tuk": _tuk_tuk(k, v)
		"wall_block": _wall_block(k)
		"wall_tower": _wall_tower(k)
		"mountain": _mountain(k, v)
		"white_house": _white_house(k, v)
		"column": _column(k)
		"amphora": _amphora(k)
		"blue_dome": _blue_dome(k)
		"greek_mill": _windmill(k, WHITE, Color("c9702f"), 3.2)
		"mooring": _mooring(k)
		"gondola": _gondola(k)
		"palazzo": _palazzo(k, v)
		"bell_tower": _bell_tower(k)
		"colosseum": _colosseum(k)
		"tulip_pot": _tulip_pot(k, v)
		"clog_pair": _clogs(k)
		"windmill": _windmill(k, Color("8a5f3a"), Color("fff6dd"), 4.4)
		"canal_house": _canal_house(k, v)
		"tulip_row": _tulip_row(k, v)
		"stone_wall": _stone_wall(k)
		"castle": _castle(k)
		"sheep": _sheep(k)
		"log_stack": _log_stack(k)
		"viking_ship": _viking_ship(k)
		"stave_hut": _stave_hut(k)
		"igloo": _igloo(k)
		"termite": _termite(k, Color("c98a4a"))
		"acacia": _acacia(k)
		"giraffe": _giraffe(k)
		"red_rock": _red_rock(k, v)
		"road_sign": _road_sign(k)
		"red_mesa": _red_mesa(k)
		"gum_tree": _gum_tree(k)
		"kangaroo": _kangaroo(k)
		"wind_pump": _wind_pump(k)
		"carved": _carved(k)
		"cactus": _cactus(k)
		"step_pyramid": _step_pyramid(k)
		"llama": _llama(k)
		"terrace": _terrace(k)
		"chimney_small": _fairy_chimney(k, 0.8)
		"chimney": _fairy_chimney(k, 2.2)
		"hot_balloon": _hot_balloon(k, v)
		"surf_rack": _surf_rack(k)
		"tiki": _tiki(k)
		"volcano_far": _volcano(k)
		"moose": _moose(k)
		"log_cabin": _log_cabin(k)
		"stupa": _stupa(k)
		"long_boat": _long_boat(k)
		"cart": _cart(k)
		_: return false
	return true


static func _b(k: MeshKit, center: Vector3, half: Vector3, color: Color, e := 0.5) -> void:
	k.soft_box(center, half, color, e, 4, 8)


# --- Japan ---------------------------------------------------------------------------------------------

static func _torii(k: MeshKit) -> void:
	var red := Color("e8483f")
	for s: float in [-1.4, 1.4]:
		k.cyl(Vector3(s, 0, 0), 3.2, 0.2, 0.16, red, 10)
	_b(k, Vector3(0, 3.3, 0), Vector3(2.2, 0.15, 0.2), red)
	_b(k, Vector3(0, 3.55, 0), Vector3(2.5, 0.12, 0.26), Color("2b2448"))
	_b(k, Vector3(0, 2.6, 0), Vector3(1.7, 0.1, 0.13), red)


static func _pagoda(k: MeshKit, v: float) -> void:
	var roof := Color("3f5a88") if v > 0.5 else Color("6a4a3a")
	var wall := Color("e8483f") if v > 0.5 else Color("fbf8ef")
	k.cyl(Vector3.ZERO, 0.3, 1.8, 1.8, STONE, 8)
	for i in 4:
		var s := 1.0 - i * 0.2
		var y := 0.3 + i * 1.2
		_b(k, Vector3(0, y + 0.45, 0), Vector3(1.1, 0.5, 1.1) * s, wall)
		k.cyl(Vector3(0, y + 0.92, 0), 0.34, 1.9 * s, 0.7 * s, roof, 8)
	k.cone(Vector3(0, 5.1, 0), 1.0, 0.12, GOLD, 8)


static func _blossom_tree(k: MeshKit, v: float) -> void:
	var pink := Color("ffb3d4") if v > 0.5 else Color("ff9fc8")
	k.tube(PackedVector3Array([Vector3.ZERO, Vector3(0.1, 1.0, 0), Vector3(-0.1, 1.9, 0.1)]), 0.28, Color("6a4a3a"), false, 7, 0.14)
	k.ball(Vector3(0, 2.6, 0), Vector3(1.5, 1.05, 1.5), pink, 6, 10)
	k.ball(Vector3(0.9, 2.1, 0.5), Vector3(0.85, 0.65, 0.85), pink.lightened(0.14), 6, 10)
	k.ball(Vector3(-0.9, 2.2, -0.3), Vector3(0.9, 0.7, 0.9), pink.darkened(0.06), 6, 10)


static func _stone_lantern(k: MeshKit) -> void:
	k.cyl(Vector3.ZERO, 0.2, 0.68, 0.58, STONE.darkened(0.08), 12)
	k.cyl(Vector3(0, 0.2, 0), 0.72, 0.2, 0.17, STONE, 10)
	_b(k, Vector3(0, 1.1, 0), Vector3(0.38, 0.26, 0.38), STONE.lightened(0.1))
	k.outline = 0.0
	_b(k, Vector3(0, 1.1, 0.34), Vector3(0.2, 0.15, 0.05), Color("fff3a8"))
	_b(k, Vector3(0, 1.1, -0.34), Vector3(0.2, 0.15, 0.05), Color("fff3a8"))
	k.outline = 0.02
	k.cone(Vector3(0, 1.36, 0), 0.5, 0.68, STONE.darkened(0.06), 10)


static func _bamboo(k: MeshKit, v: float) -> void:
	var green := Color("6ccf5a")
	for spot: Vector3 in [Vector3(-0.35, 0, -0.2), Vector3(0.3, 0, -0.28), Vector3(0.0, 0, 0.3), Vector3(-0.42, 0, 0.36), Vector3(0.45, 0, 0.32)]:
		var h := 1.5 + fmod(spot.x * 7.0 + v, 0.6)
		k.cyl(spot, h, 0.11, 0.09, green, 8)
		k.outline = 0.0
		for f: float in [0.3, 0.62, 0.9]:
			k.torus(spot + Vector3(0, h * f, 0), 0.11, 0.022, green.darkened(0.22), 8, 3)
		k.outline = 0.02
		k.ball(spot + Vector3(0.14, h, 0), Vector3(0.2, 0.05, 0.08), LEAF, 4, 8)


# --- Cities ---------------------------------------------------------------------------------------------

static func _vending(k: MeshKit, v: float) -> void:
	var body: Color = [Color("e8483f"), Color("3aa6ff"), Color("35d07f")][int(v * 2.99)]
	_b(k, Vector3(0, 0.95, 0), Vector3(0.62, 0.95, 0.5), body, 0.35)
	k.outline = 0.0
	_b(k, Vector3(0, 1.22, 0.47), Vector3(0.46, 0.45, 0.04), Color("eaf6ff"))
	for row in 2:
		for col in 4:
			k.ball(Vector3(-0.33 + col * 0.22, 1.0 + row * 0.42, 0.52), Vector3(0.07, 0.15, 0.03), [RED, GOLD, LEAF, Color("3aa6ff")][(row + col) % 4], 3, 6)
	_b(k, Vector3(0, 0.32, 0.47), Vector3(0.4, 0.12, 0.04), INK)
	k.outline = 0.02


static func _billboard(k: MeshKit, accent: Color, v: float) -> void:
	for s: float in [-1.3, 1.3]:
		k.cyl(Vector3(s, 0, 0), 3.0, 0.12, 0.12, Color("4a4a60"), 8)
	_b(k, Vector3(0, 3.8, 0), Vector3(2.2, 1.0, 0.14), INK.lightened(0.1), 0.3)
	k.outline = 0.0
	_b(k, Vector3(0, 3.8, 0.13), Vector3(2.0, 0.84, 0.03), accent)
	k.ball(Vector3(-0.9 if v > 0.5 else 0.9, 3.8, 0.17), Vector3(0.6, 0.6, 0.02), Color("fff176"), 3, 12)
	k.outline = 0.02


static func _tokyo_tower(k: MeshKit) -> void:
	var red := Color("ff5a2e")
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			k.tube(PackedVector3Array([Vector3(x * 1.5, 0, z * 1.5), Vector3(x * 0.8, 2.4, z * 0.8), Vector3(x * 0.3, 5.2, z * 0.3)]), 0.16, red, false, 6, 0.08)
	k.cyl(Vector3(0, 2.4, 0), 0.5, 1.2, 1.2, WHITE, 12)
	k.cyl(Vector3(0, 4.6, 0), 0.34, 0.68, 0.68, WHITE, 12)
	k.cyl(Vector3(0, 5.2, 0), 3.0, 0.3, 0.04, red, 8)


static func _skyscraper(k: MeshKit, v: float) -> void:
	var body: Color = [Color("6f8fc4"), Color("8fa6c8"), Color("4a6aa8"), Color("c9b89a")][int(v * 3.99)]
	var tall := 5.0 + v * 4.0
	_b(k, Vector3(0, tall * 0.5, 0), Vector3(1.4, tall * 0.5, 1.4), body, 0.2)
	_b(k, Vector3(0, tall + 0.6, 0), Vector3(0.9, 0.8, 0.9), body.lightened(0.1), 0.25)
	k.cyl(Vector3(0, tall + 1.3, 0), 1.2, 0.08, 0.04, INK.lightened(0.2), 6)
	k.outline = 0.0
	for row in int(tall / 1.1):
		_b(k, Vector3(0, 0.8 + row * 1.1, 1.36), Vector3(1.05, 0.26, 0.04), Color("fff3a8") if (row + int(v * 9.0)) % 3 == 0 else GLASS)
		_b(k, Vector3(1.36, 0.8 + row * 1.1, 0), Vector3(0.04, 0.26, 1.05), GLASS)
	k.outline = 0.02


static func _bullet_train(k: MeshKit) -> void:
	# Long and white, with a pointed blue nose at each end. Faces along z.
	_b(k, Vector3(0, 0.82, 0), Vector3(0.84, 0.72, 2.6), WHITE, 0.45)
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(0, 0.68, s * 2.6), Vector3(0.82, 0.62, 1.4), WHITE, 6, 12)
	k.outline = 0.0
	for s: float in [-1.0, 1.0]:
		_b(k, Vector3(s * 0.8, 0.5, 0), Vector3(0.06, 0.12, 2.8), Color("1f6fd0"))
		_b(k, Vector3(s * 0.8, 1.08, 0), Vector3(0.05, 0.14, 2.4), Color("2b3a5a"))
		k.ball(Vector3(0, 1.0, s * 3.1), Vector3(0.5, 0.2, 0.5), Color("2b3a5a"), 3, 8)
	k.outline = 0.02


static func _cafe(k: MeshKit, v: float) -> void:
	var cloth := RED if v > 0.5 else Color("3aa6ff")
	k.cyl(Vector3.ZERO, 0.78, 0.08, 0.08, Color("3a3748"), 8)
	k.cyl(Vector3(0, 0.76, 0), 0.08, 0.6, 0.62, WHITE, 16)
	for a: float in [0.6, 2.7, 4.8]:
		var at := Vector3(cos(a), 0, sin(a)) * 0.62
		k.cyl(at, 0.42, 0.05, 0.05, Color("3a3748"), 6)
		k.cyl(at + Vector3(0, 0.42, 0), 0.06, 0.2, 0.2, cloth, 10)
	k.cyl(Vector3(0, 0.8, 0), 1.3, 0.04, 0.04, Color("3a3748"), 6)
	k.dome(Vector3(0, 1.8, 0), Vector3(0.95, 0.42, 0.95), cloth, 4, 12)


static func _flower_box(k: MeshKit, v: float) -> void:
	_b(k, Vector3(0, 0.36, 0), Vector3(0.7, 0.36, 0.5), Color("a8683a"), 0.4)
	var colours := [RED, GOLD, Color("ff6fb5"), Color("b768ff")]
	k.ball(Vector3(0, 0.78, 0), Vector3(0.66, 0.2, 0.46), LEAF, 5, 10)
	for i in 6:
		k.ball(Vector3(-0.5 + i * 0.2, 0.96, sin(i * 2.0 + v) * 0.25), Vector3(0.13, 0.12, 0.13), colours[(i + int(v * 4.0)) % 4], 4, 7)


static func _kiosk(k: MeshKit, accent: Color) -> void:
	k.cyl(Vector3.ZERO, 1.2, 0.62, 0.62, Color("2f6a4a"), 12)
	k.cone(Vector3(0, 1.2, 0), 0.62, 0.86, accent, 12)
	k.ball(Vector3(0, 1.86, 0), Vector3(0.1, 0.1, 0.1), GOLD, 4, 7)
	k.outline = 0.0
	k.cyl(Vector3(0, 0.5, 0), 0.48, 0.635, 0.635, WHITE, 12)
	k.outline = 0.02


static func _eiffel(k: MeshKit) -> void:
	var iron := Color("9a7a5a")
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			k.tube(PackedVector3Array([Vector3(x * 2.2, 0, z * 2.2), Vector3(x * 1.2, 2.2, z * 1.2), Vector3(x * 0.55, 4.8, z * 0.55), Vector3(x * 0.14, 9.6, z * 0.14)]), 0.3, iron, false, 6, 0.06)
	_b(k, Vector3(0, 2.2, 0), Vector3(1.6, 0.16, 1.6), iron.darkened(0.14), 0.4)
	_b(k, Vector3(0, 4.8, 0), Vector3(0.84, 0.13, 0.84), iron.darkened(0.14), 0.4)
	_b(k, Vector3(0, 8.0, 0), Vector3(0.38, 0.14, 0.38), iron.darkened(0.14), 0.4)
	k.cyl(Vector3(0, 9.2, 0), 1.3, 0.12, 0.02, iron, 6)
	k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.1, 0)))
	k.outline = 0.0
	k.torus(Vector3.ZERO, 0.9, 0.09, iron.darkened(0.1), 14, 4)
	k.outline = 0.02
	k.pop()


static func _townhouse(k: MeshKit, v: float) -> void:
	var wall: Color = [Color("f4e6c8"), Color("e8cfa0"), Color("f0d8c8"), Color("d9c4a0")][int(v * 3.99)]
	_b(k, Vector3(0, 2.1, 0), Vector3(1.5, 2.1, 1.2), wall, 0.2)
	k.cyl(Vector3(0, 4.2, 0), 0.9, 1.8, 1.1, Color("5a6a8a"), 4)
	k.outline = 0.0
	for row in 3:
		for col in 3:
			_b(k, Vector3(-0.95 + col * 0.95, 1.1 + row * 1.15, 1.17), Vector3(0.26, 0.36, 0.04), Color("4a6a8a"))
			_b(k, Vector3(-0.95 + col * 0.95, 0.72 + row * 1.15, 1.2), Vector3(0.3, 0.05, 0.06), INK.lightened(0.2))
	k.outline = 0.02


static func _street_lamp(k: MeshKit) -> void:
	var iron := Color("2b3a4a")
	k.cyl(Vector3.ZERO, 0.3, 0.2, 0.09, iron, 8)
	k.cyl(Vector3(0, 0.3, 0), 2.7, 0.07, 0.05, iron, 8)
	k.ball(Vector3(0, 3.2, 0), Vector3(0.24, 0.3, 0.24), Color("fff3a8"), 5, 9)
	k.cone(Vector3(0, 3.46, 0), 0.26, 0.26, iron, 8)


static func _car(k: MeshKit, body: Color, sign: bool) -> void:
	for x: float in [-0.68, 0.68]:
		for z: float in [-1.0, 1.0]:
			k.ball(Vector3(x, 0.26, z), Vector3(0.18, 0.26, 0.26), Color("2b2448"), 5, 9)
	_b(k, Vector3(0, 0.56, 0), Vector3(0.84, 0.3, 1.6), body, 0.5)
	_b(k, Vector3(0, 1.04, -0.1), Vector3(0.7, 0.3, 0.9), body.lightened(0.08), 0.5)
	k.outline = 0.0
	_b(k, Vector3(0, 1.06, -0.1), Vector3(0.72, 0.17, 0.92), Color("7fc4f0"))
	for s: float in [-0.5, 0.5]:
		k.ball(Vector3(s, 0.6, 1.58), Vector3(0.14, 0.11, 0.05), Color("fff3a8"), 3, 7)
	k.outline = 0.02
	if sign:
		_b(k, Vector3(0, 1.44, -0.1), Vector3(0.24, 0.1, 0.14), WHITE)


static func _red_bus(k: MeshKit) -> void:
	var red := Color("e8282f")
	for x: float in [-0.76, 0.76]:
		for z: float in [-1.3, 1.3]:
			k.ball(Vector3(x, 0.3, z), Vector3(0.18, 0.3, 0.3), Color("2b2448"), 5, 9)
	_b(k, Vector3(0, 1.0, 0), Vector3(0.94, 0.66, 2.1), red, 0.3)
	_b(k, Vector3(0, 2.1, 0), Vector3(0.9, 0.48, 2.0), red.lightened(0.05), 0.3)
	k.outline = 0.0
	_b(k, Vector3(0, 1.1, 0), Vector3(0.96, 0.24, 1.9), Color("9fd8ff"))
	_b(k, Vector3(0, 2.14, 0), Vector3(0.92, 0.24, 1.85), Color("9fd8ff"))
	_b(k, Vector3(0, 1.58, 0), Vector3(0.95, 0.06, 2.1), WHITE)
	k.outline = 0.02


static func _phone_box(k: MeshKit) -> void:
	var red := Color("e8282f")
	_b(k, Vector3(0, 0.95, 0), Vector3(0.55, 0.95, 0.55), red, 0.3)
	k.dome(Vector3(0, 1.9, 0), Vector3(0.58, 0.24, 0.58), red.lightened(0.05), 4, 12)
	k.outline = 0.0
	for row in 4:
		_b(k, Vector3(0, 0.6 + row * 0.3, 0.53), Vector3(0.36, 0.11, 0.03), Color("cfeaff"))
	_b(k, Vector3(0, 1.74, 0.55), Vector3(0.36, 0.08, 0.02), WHITE)
	k.outline = 0.02


static func _mailbox(k: MeshKit) -> void:
	var red := Color("d8282f")
	k.cyl(Vector3.ZERO, 1.3, 0.42, 0.42, red, 14)
	k.dome(Vector3(0, 1.3, 0), Vector3(0.46, 0.2, 0.46), red.darkened(0.08), 4, 14)
	k.outline = 0.0
	_b(k, Vector3(0, 1.0, 0.41), Vector3(0.2, 0.04, 0.02), INK)
	_b(k, Vector3(0, 0.56, 0.42), Vector3(0.13, 0.1, 0.01), WHITE)
	k.outline = 0.02


static func _big_clock(k: MeshKit) -> void:
	var stone := Color("e0c98c")
	_b(k, Vector3(0, 3.2, 0), Vector3(1.1, 3.2, 1.1), stone, 0.15)
	_b(k, Vector3(0, 7.0, 0), Vector3(1.3, 0.9, 1.3), stone.lightened(0.1), 0.15)
	k.cone(Vector3(0, 7.9, 0), 2.3, 1.18, Color("4a6a5a"), 8)
	k.ball(Vector3(0, 10.2, 0), Vector3(0.12, 0.12, 0.12), GOLD, 4, 7)
	k.outline = 0.0
	for s: Vector3 in [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
		var at := Vector3(0, 7.0, 0) + s * 1.32
		k.ball(at, Vector3(0.82, 0.82, 0.82) * (Vector3.ONE - s.abs()) + s.abs() * 0.05, WHITE, 4, 14)
		k.ball(at + s * 0.06, Vector3(0.1, 0.1, 0.1), INK, 3, 6)
		_b(k, at + s * 0.05 + Vector3(0, 0.3, 0), (Vector3(0.05, 0.34, 0.05)), INK)
	for row in 5:
		_b(k, Vector3(0, 1.0 + row * 1.0, 1.08), Vector3(0.6, 0.3, 0.04), stone.darkened(0.25))
	k.outline = 0.02


static func _hydrant(k: MeshKit) -> void:
	var red := Color("e8483f")
	k.cyl(Vector3.ZERO, 0.14, 0.42, 0.42, red.darkened(0.1), 12)
	k.cyl(Vector3(0, 0.14, 0), 0.92, 0.3, 0.28, red, 12)
	k.dome(Vector3(0, 1.06, 0), Vector3(0.3, 0.26, 0.3), red, 4, 12)
	k.ball(Vector3(0, 1.32, 0), Vector3(0.08, 0.08, 0.08), GOLD, 4, 7)
	for s: float in [-1.0, 1.0]:
		k.push(Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(s * 0.26, 0.74, 0)))
		k.cyl(Vector3(0, -0.14, 0), 0.28, 0.1, 0.1, GOLD, 8)
		k.pop()


static func _liberty(k: MeshKit) -> void:
	var green := Color("7fcfb0")
	_b(k, Vector3(0, 1.1, 0), Vector3(1.5, 1.1, 1.5), STONE, 0.25)
	_b(k, Vector3(0, 2.7, 0), Vector3(0.9, 0.6, 0.9), STONE.lightened(0.1), 0.25)
	k.cyl(Vector3(0, 3.3, 0), 2.6, 0.82, 0.42, green, 12)
	k.ball(Vector3(0, 6.2, 0), Vector3(0.44, 0.46, 0.42), green.lightened(0.05), 6, 10)
	for i in 7:
		var a := lerpf(-1.2, 1.2, i / 6.0)
		k.push(Transform3D(Basis(Vector3.BACK, -a), Vector3(0, 6.42, 0)))
		k.cone(Vector3.ZERO, 0.62, 0.08, green, 6)
		k.pop()
	k.tube(PackedVector3Array([Vector3(0.42, 5.5, 0), Vector3(0.78, 6.3, 0), Vector3(0.82, 7.2, 0)]), 0.16, green, false, 7, 0.13)
	k.cyl(Vector3(0.82, 7.2, 0), 0.34, 0.14, 0.2, GOLD, 8)
	k.ball(Vector3(0.82, 7.72, 0), Vector3(0.18, 0.28, 0.18), Color("ffb52e"), 5, 8)


static func _water_tower(k: MeshKit) -> void:
	for a: float in [0.7, 2.3, 3.9, 5.5]:
		k.cyl(Vector3(cos(a) * 0.8, 0, sin(a) * 0.8), 2.4, 0.07, 0.07, DARK_WOOD, 6)
	k.cyl(Vector3(0, 2.4, 0), 1.6, 1.0, 1.0, WOOD, 12)
	k.cone(Vector3(0, 4.0, 0), 0.8, 1.14, DARK_WOOD, 12)


# --- South America -------------------------------------------------------------------------------------

static func _drums(k: MeshKit, accent: Color) -> void:
	for spot: Vector3 in [Vector3(-0.38, 0, -0.3), Vector3(0.38, 0, -0.3), Vector3(0, 0, 0.34)]:
		k.cyl(spot, 0.9, 0.36, 0.36, accent, 12)
		k.outline = 0.0
		k.cyl(spot + Vector3(0, 0.9, 0), 0.01, 0.34, 0.34, WHITE, 12)
		k.torus(spot + Vector3(0, 0.08, 0), 0.36, 0.03, GOLD, 12, 3)
		k.torus(spot + Vector3(0, 0.82, 0), 0.36, 0.03, GOLD, 12, 3)
		k.outline = 0.02


static func _carnival_float(k: MeshKit, accent: Color) -> void:
	_b(k, Vector3(0, 0.6, 0), Vector3(1.0, 0.6, 1.8), accent, 0.5)
	k.ball(Vector3(0, 1.5, 0.2), Vector3(0.82, 0.82, 0.82), Color("ffd23f"), 6, 10)
	var colours := [Color("35d07f"), Color("ff6fb5"), Color("3aa6ff"), RED]
	for i in 7:
		var a := lerpf(-1.1, 1.1, i / 6.0)
		k.push(Transform3D(Basis(Vector3.BACK, -a), Vector3(0, 1.9, 0.2)))
		k.ball(Vector3(0, 0.9, 0), Vector3(0.18, 0.85, 0.05), colours[i % 4], 5, 8)
		k.pop()
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.3, 1.6, 0.92), Vector3(0.13, 0.14, 0.05), INK, 3, 7)


static func _sugarloaf(k: MeshKit) -> void:
	k.ball(Vector3(0, 2.4, 0), Vector3(2.6, 3.8, 2.6), Color("8a8a7a"), 7, 12)
	k.ball(Vector3(2.6, 1.0, 1.0), Vector3(1.8, 1.8, 1.8), Color("5cb860"), 5, 9)
	k.ball(Vector3(-2.2, 0.8, 0.4), Vector3(1.8, 1.5, 1.8), Color("5cb860"), 5, 9)
	k.outline = 0.0
	k.ball(Vector3(-0.6, 4.6, 1.8), Vector3(0.9, 1.0, 0.5), Color("a8a898"), 4, 8)
	k.outline = 0.02


static func _toucan_tree(k: MeshKit) -> void:
	k.cyl(Vector3.ZERO, 2.2, 0.28, 0.2, Color("8a5f3a"), 8)
	k.ball(Vector3(0, 3.1, 0), Vector3(1.5, 1.2, 1.5), Color("2fae4e"), 6, 10)
	var bird := Vector3(1.2, 2.3, 0.4)
	k.ball(bird, Vector3(0.3, 0.36, 0.3), INK.lightened(0.15), 5, 8)
	k.ball(bird + Vector3(0, 0.1, 0.26), Vector3(0.18, 0.15, 0.08), Color("fff6dd"), 3, 7)
	k.ball(bird + Vector3(0, 0.08, 0.5), Vector3(0.13, 0.13, 0.28), Color("ff9d2e"), 4, 8)


# --- Egypt and North Africa ------------------------------------------------------------------------------

static func _sandstone(k: MeshKit, v: float) -> void:
	var c := Color("e6c387").lerp(Color("d9b070"), v)
	_b(k, Vector3(0, 0.5, 0), Vector3(0.72, 0.5, 0.66), c, 0.4)
	_b(k, Vector3(0.05, 1.16, 0), Vector3(0.48, 0.2, 0.46), c.lightened(0.08), 0.5)
	k.outline = 0.0
	_b(k, Vector3(0, 0.5, 0.64), Vector3(0.45, 0.05, 0.03), c.darkened(0.2))
	_b(k, Vector3(0, 0.76, 0.64), Vector3(0.3, 0.1, 0.03), Color("3a6ad0"))
	k.outline = 0.02


static func _pottery(k: MeshKit, v: float) -> void:
	var tones := [Color("d9703f"), Color("e8a050"), Color("3a8fb5")]
	for spot: Array in [[Vector3(-0.32, 0, -0.26), 1.0], [Vector3(0.36, 0, -0.14), 0.8], [Vector3(-0.02, 0, 0.36), 0.66]]:
		var at: Vector3 = spot[0]
		var s: float = spot[1]
		var c: Color = tones[(int(at.x * 9.0 + v * 3.0) % 3 + 3) % 3]
		k.ball(at + Vector3(0, 0.5, 0) * s, Vector3(0.38, 0.5, 0.38) * s, c, 6, 10)
		k.cyl(at + Vector3(0, 0.95, 0) * s, 0.28 * s, 0.16 * s, 0.22 * s, c.darkened(0.08), 8)


static func _obelisk(k: MeshKit) -> void:
	k.cyl(Vector3.ZERO, 0.2, 0.7, 0.62, Color("cfa868"), 4)
	k.cyl(Vector3(0, 0.2, 0), 1.7, 0.42, 0.26, Color("e6c387"), 4)
	k.cone(Vector3(0, 1.9, 0), 0.4, 0.26, GOLD, 4)


static func _pyramid(k: MeshKit, v: float) -> void:
	var s := 3.2 + v * 1.8
	var tone := Color("e6c387")
	var top := Vector3(0, s * 1.05, 0)
	var corners := [Vector3(s, 0, s), Vector3(s, 0, -s), Vector3(-s, 0, -s), Vector3(-s, 0, s)]
	k.outline = 0.0
	for i in 4:
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i + 1) % 4]
		var shade := [tone, tone.darkened(0.12), tone.darkened(0.2), tone.lightened(0.05)][i] as Color
		k.quad(a, b, top, top, shade)
		for row in 3:
			var f := 0.25 + row * 0.25
			var mid_a := a.lerp(top, f)
			var mid_b := b.lerp(top, f)
			var up := Vector3(0, 0.06, 0)
			k.quad(mid_a + (top - a).normalized() * 0.06, mid_b + (top - b).normalized() * 0.06, mid_b + up * 2.0, mid_a + up * 2.0, shade.darkened(0.1))
	k.outline = 0.02


static func _sphinx(k: MeshKit) -> void:
	var sand := Color("e0b878")
	_b(k, Vector3(0, 0.5, -0.8), Vector3(1.2, 0.5, 2.2), sand.darkened(0.08), 0.4)
	_b(k, Vector3(0, 1.1, -1.3), Vector3(1.0, 0.7, 1.4), sand, 0.6)
	for s: float in [-0.76, 0.76]:
		_b(k, Vector3(s, 0.3, 1.4), Vector3(0.34, 0.3, 1.1), sand.darkened(0.04), 0.6)
	k.ball(Vector3(0, 2.4, 0.3), Vector3(0.7, 0.8, 0.7), sand, 6, 10)
	k.outline = 0.0
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.3, 2.5, 0.92), Vector3(0.12, 0.08, 0.05), INK, 3, 6)
		k.ball(Vector3(s * 0.74, 2.2, 0.2), Vector3(0.22, 0.6, 0.45), Color("3a6ad0"), 4, 8)
	k.outline = 0.02


static func _camel(k: MeshKit) -> void:
	var tan := Color("e0b878")
	for x: float in [-0.3, 0.3]:
		for z: float in [-0.8, 0.8]:
			k.cyl(Vector3(x, 0, z), 1.2, 0.11, 0.13, tan.darkened(0.08), 7)
	k.ball(Vector3(0, 1.42, 0), Vector3(0.52, 0.42, 1.1), tan, 6, 10)
	k.ball(Vector3(0, 1.98, -0.1), Vector3(0.38, 0.42, 0.5), tan.lightened(0.04), 5, 9)
	k.tube(PackedVector3Array([Vector3(0, 1.5, 0.9), Vector3(0, 1.9, 1.3), Vector3(0, 2.3, 1.45)]), 0.2, tan, false, 7, 0.16)
	k.ball(Vector3(0, 2.46, 1.6), Vector3(0.22, 0.2, 0.36), tan.lightened(0.05), 5, 8)
	k.outline = 0.0
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.17, 2.54, 1.75), Vector3(0.05, 0.05, 0.03), INK, 3, 5)
	k.outline = 0.02


static func _rugs(k: MeshKit, v: float) -> void:
	var colours := [RED, Color("3a6ad0"), GOLD, Color("1a9c58"), Color("ff6fb5")]
	for i in 5:
		var c: Color = colours[(i + int(v * 5.0)) % 5]
		k.soft_box(Vector3(sin(i * 2.4) * 0.06, 0.13 + i * 0.25, cos(i * 1.7) * 0.05), Vector3(0.7, 0.115, 0.56), c, 0.5, 4, 8)
		k.outline = 0.0
		k.soft_box(Vector3(sin(i * 2.4) * 0.06, 0.13 + i * 0.25, cos(i * 1.7) * 0.05 + 0.5), Vector3(0.5, 0.12, 0.08), c.lightened(0.24), 0.5, 3, 6)
		k.outline = 0.02


static func _spices(k: MeshKit) -> void:
	var colours := [Color("e8483f"), Color("ffb21f"), Color("c9702f"), Color("6ccf5a")]
	var spots := [Vector2(-0.36, -0.36), Vector2(0.36, -0.36), Vector2(-0.36, 0.36), Vector2(0.36, 0.36)]
	for i in 4:
		var at := Vector3(spots[i].x, 0, spots[i].y)
		k.cyl(at, 0.5, 0.3, 0.34, Color("c9985e"), 10)
		k.dome(at + Vector3(0, 0.5, 0), Vector3(0.32, 0.34, 0.32), colours[i], 4, 10)


static func _riad(k: MeshKit, v: float) -> void:
	var wall := Color("d9703f") if v > 0.5 else Color("e8945a")
	_b(k, Vector3(0, 2.0, 0), Vector3(1.8, 2.0, 1.6), wall, 0.2)
	k.outline = 0.0
	for x: float in [-1.0, 0.0, 1.0]:
		k.ball(Vector3(x, 1.2, 1.58), Vector3(0.3, 0.6, 0.03), Color("2a7f9a"), 3, 9)
		k.ball(Vector3(x, 2.9, 1.58), Vector3(0.22, 0.4, 0.03), Color("fff6dd"), 3, 8)
	k.outline = 0.02
	for x: float in [-1.5, -0.5, 0.5, 1.5]:
		_b(k, Vector3(x, 4.2, 1.42), Vector3(0.24, 0.24, 0.16), wall.lightened(0.1))
		_b(k, Vector3(x, 4.2, -1.42), Vector3(0.24, 0.24, 0.16), wall.lightened(0.1))


static func _tent(k: MeshKit, accent: Color) -> void:
	k.cone(Vector3.ZERO, 2.4, 1.9, accent, 10)
	k.outline = 0.0
	k.cone(Vector3(0, 0.02, 0.02), 1.6, 1.28, WHITE, 10)
	k.outline = 0.02
	k.ball(Vector3(0, 2.5, 0), Vector3(0.12, 0.12, 0.12), GOLD, 3, 7)


static func _lantern_post(k: MeshKit) -> void:
	k.cyl(Vector3.ZERO, 0.22, 0.62, 0.5, Color("6a4a3a"), 12)
	k.cyl(Vector3(0, 0.2, 0), 1.3, 0.09, 0.08, Color("6a4a3a"), 8)
	var red := Color("ee3b34")
	k.ball(Vector3(0, 1.55, 0), Vector3(0.42, 0.36, 0.42), red, 7, 12)
	k.cyl(Vector3(0, 1.84, 0), 0.08, 0.2, 0.2, GOLD, 10)
	k.cyl(Vector3(0, 1.17, 0), 0.08, 0.2, 0.2, GOLD, 10)


# --- India, China, Thailand -----------------------------------------------------------------------------

static func _planter(k: MeshKit) -> void:
	k.cyl(Vector3.ZERO, 0.75, 0.5, 0.72, WHITE, 14)
	k.torus(Vector3(0, 0.72, 0), 0.72, 0.05, GOLD, 16, 4)
	k.ball(Vector3(0, 1.25, 0), Vector3(0.68, 0.62, 0.68), LEAF, 6, 10)
	for a: float in [0.5, 2.3, 4.2]:
		k.ball(Vector3(cos(a) * 0.46, 1.42, sin(a) * 0.46), Vector3(0.13, 0.12, 0.13), Color("ff6fb5"), 3, 7)


static func _marble(k: MeshKit) -> void:
	_b(k, Vector3(0, 0.15, 0), Vector3(0.72, 0.15, 0.72), WHITE, 0.3)
	_b(k, Vector3(0, 0.78, 0), Vector3(0.5, 0.5, 0.5), Color("f4f0e6"), 0.3)
	k.dome(Vector3(0, 1.28, 0), Vector3(0.46, 0.42, 0.46), WHITE, 4, 12)
	k.cone(Vector3(0, 1.68, 0), 0.24, 0.05, GOLD, 6)


static func _taj(k: MeshKit) -> void:
	_b(k, Vector3(0, 0.3, 0), Vector3(3.8, 0.3, 3.8), Color("f0e8da"), 0.2)
	_b(k, Vector3(0, 1.9, 0), Vector3(2.2, 1.4, 2.2), WHITE, 0.3)
	k.ball(Vector3(0, 4.0, 0), Vector3(1.5, 1.7, 1.5), WHITE, 8, 12)
	k.cone(Vector3(0, 5.5, 0), 1.0, 0.14, GOLD, 6)
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			k.cyl(Vector3(x * 3.4, 0.6, z * 3.4), 3.6, 0.28, 0.2, WHITE, 8)
			k.ball(Vector3(x * 3.4, 4.3, z * 3.4), Vector3(0.36, 0.42, 0.36), WHITE, 4, 8)
			k.ball(Vector3(x * 1.5, 3.5, z * 1.5), Vector3(0.5, 0.56, 0.5), WHITE, 4, 8)
	k.outline = 0.0
	k.ball(Vector3(0, 1.8, 2.22), Vector3(1.0, 1.25, 0.05), Color("c9d6ea"), 3, 10)
	k.outline = 0.02


static func _cypress(k: MeshKit) -> void:
	k.cyl(Vector3.ZERO, 0.6, 0.16, 0.14, DARK_WOOD, 7)
	k.ball(Vector3(0, 2.3, 0), Vector3(0.62, 2.0, 0.62), Color("2f8a4e"), 7, 9)


static func _elephant(k: MeshKit) -> void:
	var c := Color("a9bdf0")
	for x: float in [-0.56, 0.56]:
		for z: float in [-0.8, 0.8]:
			k.cyl(Vector3(x, 0, z), 0.9, 0.3, 0.3, c.darkened(0.08), 8)
	k.ball(Vector3(0, 1.45, -0.1), Vector3(1.0, 0.92, 1.4), c, 7, 11)
	k.ball(Vector3(0, 1.85, 1.3), Vector3(0.68, 0.68, 0.62), c.lightened(0.04), 6, 10)
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.84, 1.95, 1.06), Vector3(0.5, 0.62, 0.1), c.darkened(0.06), 5, 9)
	k.tube(PackedVector3Array([Vector3(0, 1.75, 1.8), Vector3(0, 1.3, 2.1), Vector3(0, 0.7, 2.25), Vector3(0, 0.45, 2.45)]), 0.24, c, false, 8, 0.12)
	k.outline = 0.0
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.28, 2.0, 1.86), Vector3(0.08, 0.09, 0.04), INK, 3, 6)
	k.outline = 0.02
	_b(k, Vector3(0, 2.34, -0.1), Vector3(0.7, 0.1, 0.8), RED, 0.5)


static func _tuk_tuk(k: MeshKit, v: float) -> void:
	var c: Color = [Color("ffc21f"), Color("1a9c58"), Color("3aa6ff")][int(v * 2.99)]
	k.ball(Vector3(0, 0.25, 1.0), Vector3(0.13, 0.25, 0.25), Color("2b2448"), 5, 8)
	for s: float in [-0.68, 0.68]:
		k.ball(Vector3(s, 0.25, -0.7), Vector3(0.13, 0.25, 0.25), Color("2b2448"), 5, 8)
	_b(k, Vector3(0, 0.6, -0.1), Vector3(0.72, 0.28, 1.1), c, 0.45)
	_b(k, Vector3(0, 1.62, -0.1), Vector3(0.78, 0.1, 1.2), c.darkened(0.2), 0.5)
	for x: float in [-0.66, 0.66]:
		for z: float in [-1.0, 0.9]:
			k.cyl(Vector3(x, 0.8, z), 0.8, 0.04, 0.04, INK.lightened(0.2), 6)


static func _wall_block(k: MeshKit) -> void:
	var c := Color("b8ae96")
	_b(k, Vector3(0, 0.62, 0), Vector3(0.72, 0.62, 0.72), c, 0.3)
	k.outline = 0.0
	for z: float in [-0.74, 0.74]:
		for y: float in [0.34, 0.86]:
			_b(k, Vector3(0, y, z), Vector3(0.68, 0.015, 0.012), c.darkened(0.2))
	k.outline = 0.02
	for x: float in [-0.46, 0.46]:
		_b(k, Vector3(x, 1.4, 0), Vector3(0.2, 0.18, 0.66), c.lightened(0.08), 0.4)


static func _wall_tower(k: MeshKit) -> void:
	var c := Color("b8ae96")
	_b(k, Vector3(0, 1.8, 0), Vector3(1.5, 1.8, 1.5), c, 0.2)
	for x: float in [-1.1, 0.0, 1.1]:
		for z: float in [-1.28, 1.28]:
			_b(k, Vector3(x, 3.85, z), Vector3(0.34, 0.26, 0.2), c.lightened(0.08), 0.4)
	_b(k, Vector3(0, 4.5, 0), Vector3(1.0, 0.7, 1.0), Color("e8483f"), 0.3)
	k.cyl(Vector3(0, 5.1, 0), 0.7, 1.7, 0.3, Color("3f5a88"), 4)


static func _mountain(k: MeshKit, v: float) -> void:
	var rock := Color("8d9ab8").lerp(Color("7a8aa8"), v)
	var h := 6.0 + v * 4.0
	k.cyl(Vector3.ZERO, h, 5.0, 0.3, rock, 8, false)
	k.outline = 0.0
	k.cyl(Vector3(0, h * 0.62, 0), h * 0.38, 5.0 * 0.385, 0.32, Color("f4faff"), 8, false)
	k.outline = 0.02


static func _stupa(k: MeshKit) -> void:
	k.cyl(Vector3.ZERO, 0.6, 2.6, 2.3, WHITE, 12)
	k.cyl(Vector3(0, 0.6, 0), 0.5, 2.0, 1.6, GOLD, 12)
	k.ball(Vector3(0, 2.0, 0), Vector3(1.3, 1.2, 1.3), GOLD, 6, 10)
	k.cone(Vector3(0, 3.0, 0), 2.7, 0.56, GOLD.lightened(0.1), 10)


static func _long_boat(k: MeshKit) -> void:
	k.ball(Vector3(0, 0.3, 0), Vector3(0.62, 0.34, 2.4), Color("a8683a"), 5, 12)
	k.tube(PackedVector3Array([Vector3(0, 0.46, 2.1), Vector3(0, 0.9, 2.6), Vector3(0, 1.4, 2.7)]), 0.14, Color("a8683a"), false, 7, 0.06)
	k.outline = 0.0
	k.ball(Vector3(0, 0.56, 0), Vector3(0.52, 0.06, 2.1), RED, 3, 10)
	k.outline = 0.02
	k.dome(Vector3(0, 0.6, -0.5), Vector3(0.55, 0.55, 0.9), Color("ffc21f"), 4, 10)


static func _cart(k: MeshKit) -> void:
	for x: float in [-0.7, 0.7]:
		k.push(Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(x, 0.42, -0.1)))
		k.cyl(Vector3(0, -0.06, 0), 0.12, 0.42, 0.42, DARK_WOOD, 10)
		k.pop()
	_b(k, Vector3(0, 0.82, 0), Vector3(0.74, 0.3, 1.2), WOOD, 0.4)
	k.ball(Vector3(0, 1.2, 0), Vector3(0.62, 0.3, 1.0), Color("ffd98a"), 4, 9)
	for x: float in [-0.3, 0.3]:
		k.tube(PackedVector3Array([Vector3(x, 0.7, 1.1), Vector3(x, 0.52, 2.1)]), 0.04, DARK_WOOD, false, 5)


# --- Greece, Rome, Italy --------------------------------------------------------------------------------

static func _white_house(k: MeshKit, v: float) -> void:
	_b(k, Vector3(0, 0.66, 0), Vector3(0.72, 0.66, 0.72), WHITE, 0.3)
	if v > 0.5:
		k.dome(Vector3(0, 1.32, 0), Vector3(0.54, 0.46, 0.54), Color("2a7fd0"), 4, 12)
	else:
		_b(k, Vector3(0, 1.38, 0), Vector3(0.74, 0.07, 0.74), Color("f0e8da"), 0.5)
	k.outline = 0.0
	k.ball(Vector3(0, 0.42, 0.7), Vector3(0.2, 0.42, 0.02), Color("2a7fd0"), 3, 8)
	k.outline = 0.02


static func _column(k: MeshKit) -> void:
	var c := Color("f0e8da")
	k.cyl(Vector3.ZERO, 0.2, 0.66, 0.6, c.darkened(0.08), 10)
	k.cyl(Vector3(0, 0.2, 0), 1.18, 0.4, 0.34, c, 10)
	k.outline = 0.0
	for a: float in [0.0, 1.05, 2.1, 3.15, 4.2, 5.25]:
		k.cyl(Vector3(cos(a) * 0.36, 0.2, sin(a) * 0.36), 1.18, 0.03, 0.03, c.darkened(0.14), 4)
	k.outline = 0.02
	k.cyl(Vector3(0, 1.38, 0), 0.18, 0.38, 0.58, c.lightened(0.1), 10)


static func _amphora(k: MeshKit) -> void:
	var c := Color("d9703f")
	k.ball(Vector3(0, 0.76, 0), Vector3(0.48, 0.6, 0.48), c, 7, 10)
	k.cyl(Vector3(0, 1.2, 0), 0.44, 0.18, 0.2, c, 8)
	k.torus(Vector3(0, 1.64, 0), 0.2, 0.03, c.darkened(0.2), 12, 3)
	k.cyl(Vector3.ZERO, 0.24, 0.24, 0.16, c.darkened(0.14), 8)
	for s: float in [-1.0, 1.0]:
		k.tube(PackedVector3Array([Vector3(s * 0.2, 1.5, 0), Vector3(s * 0.5, 1.46, 0), Vector3(s * 0.42, 1.08, 0)]), 0.04, c.darkened(0.1), false, 5)
	k.outline = 0.0
	k.torus(Vector3(0, 0.82, 0), 0.47, 0.08, INK.lightened(0.1), 14, 3)
	k.outline = 0.02


static func _blue_dome(k: MeshKit) -> void:
	_b(k, Vector3(0, 1.3, 0), Vector3(1.5, 1.3, 1.5), WHITE, 0.25)
	k.dome(Vector3(0, 2.6, 0), Vector3(1.3, 1.25, 1.3), Color("2a7fd0"), 5, 12)
	k.cone(Vector3(0, 3.8, 0), 0.6, 0.1, WHITE, 6)
	k.outline = 0.0
	for s: float in [-0.7, 0.7]:
		k.ball(Vector3(s, 1.0, 1.48), Vector3(0.28, 0.6, 0.02), Color("2a7fd0"), 3, 8)
	k.outline = 0.02


static func _windmill(k: MeshKit, body: Color, sail: Color, tall: float) -> void:
	k.cyl(Vector3.ZERO, tall, 1.4, 0.9, body, 10)
	k.cone(Vector3(0, tall, 0), 1.1, 1.05, Color("5a6a8a"), 10)
	for i in 4:
		k.push(Transform3D(Basis(Vector3.BACK, PI * 0.5 * i + 0.5), Vector3(0, tall - 0.3, 1.05)))
		k.cyl(Vector3.ZERO, 3.0, 0.05, 0.03, DARK_WOOD, 6)
		_b(k, Vector3(0.28, 1.9, 0), Vector3(0.3, 1.0, 0.03), sail, 0.3)
		k.pop()
	k.ball(Vector3(0, tall - 0.3, 1.06), Vector3(0.2, 0.2, 0.2), RED, 4, 7)


static func _mooring(k: MeshKit) -> void:
	for at: Vector3 in [Vector3(-0.42, 0, -0.34), Vector3(0.44, 0, -0.2), Vector3(0.0, 0, 0.42)]:
		k.cyl(at, 1.5, 0.15, 0.13, Color("3a6ad0"), 8)
		k.outline = 0.0
		for y: float in [0.3, 0.8, 1.3]:
			k.torus(at + Vector3(0, y, 0), 0.14, 0.05, WHITE, 8, 3)
		k.outline = 0.02
		k.ball(at + Vector3(0, 1.5, 0), Vector3(0.15, 0.12, 0.15), GOLD, 3, 7)


static func _gondola(k: MeshKit) -> void:
	var black := Color("1d1a30")
	k.ball(Vector3(0, 0.3, 0), Vector3(0.5, 0.3, 2.6), black, 5, 12)
	k.tube(PackedVector3Array([Vector3(0, 0.34, 2.3), Vector3(0, 0.84, 2.84), Vector3(0, 1.5, 2.9)]), 0.13, black, false, 7, 0.05)
	k.tube(PackedVector3Array([Vector3(0, 0.34, -2.3), Vector3(0, 0.66, -2.7)]), 0.1, black, false, 6, 0.05)
	_b(k, Vector3(0, 0.62, 0), Vector3(0.36, 0.1, 0.44), Color("e8483f"), 0.5)


static func _palazzo(k: MeshKit, v: float) -> void:
	var wall := Color("f0b8a0") if v > 0.5 else Color("f4d8a8")
	_b(k, Vector3(0, 2.2, 0), Vector3(1.9, 2.2, 1.4), wall, 0.15)
	_b(k, Vector3(0, 4.46, 0), Vector3(2.0, 0.1, 1.5), wall.darkened(0.2), 0.4)
	k.outline = 0.0
	for x: float in [-1.2, -0.4, 0.4, 1.2]:
		for y: float in [1.2, 3.0]:
			k.ball(Vector3(x, y, 1.38), Vector3(0.24, 0.56, 0.02), Color("3a6a8a"), 3, 8)
	k.outline = 0.02


static func _bell_tower(k: MeshKit) -> void:
	var brick := Color("c9604a")
	_b(k, Vector3(0, 3.2, 0), Vector3(0.9, 3.2, 0.9), brick, 0.12)
	_b(k, Vector3(0, 7.0, 0), Vector3(1.0, 0.6, 1.0), WHITE, 0.3)
	k.cone(Vector3(0, 7.6, 0), 2.2, 1.0, Color("5ab88a"), 4)
	k.ball(Vector3(0, 9.8, 0), Vector3(0.14, 0.14, 0.14), GOLD, 3, 7)


static func _colosseum(k: MeshKit) -> void:
	var c := Color("e6d6b0")
	k.cyl(Vector3.ZERO, 3.6, 4.2, 4.0, c, 16)
	k.outline = 0.0
	for tier in 2:
		for i in 16:
			var a := TAU * i / 16.0
			k.push(Transform3D(Basis(Vector3.UP, PI * 0.5 - a), Vector3(cos(a) * 4.14, 1.0 + tier * 1.5, sin(a) * 4.14)))
			k.ball(Vector3.ZERO, Vector3(0.42, 0.62, 0.03), c.darkened(0.3), 3, 8)
			k.pop()
	k.cyl(Vector3(0, 3.6, 0), 0.01, 3.4, 3.4, c.darkened(0.2), 16)
	k.outline = 0.02


# --- The Netherlands and Scotland -----------------------------------------------------------------------

static func _tulip_pot(k: MeshKit, v: float) -> void:
	k.cyl(Vector3.ZERO, 0.62, 0.56, 0.72, Color("d9703f"), 14)
	k.outline = 0.0
	k.cyl(Vector3(0, 0.62, 0), 0.02, 0.68, 0.68, Color("6a4a2a"), 14)
	k.outline = 0.02
	var colours := [Color("ff4f6a"), Color("ffd23f"), Color("ff9d2e"), Color("ff6fb5")]
	for i in 5:
		var a := TAU * i / 5.0
		var at := Vector3(cos(a) * 0.34, 0.62, sin(a) * 0.34)
		k.cyl(at, 0.5, 0.03, 0.03, LEAF, 5)
		k.ball(at + Vector3(0, 0.64, 0), Vector3(0.14, 0.18, 0.14), colours[(i + int(v * 4.0)) % 4], 4, 7)


static func _clogs(k: MeshKit) -> void:
	for s: float in [-0.36, 0.36]:
		k.ball(Vector3(s, 0.34, 0.1), Vector3(0.32, 0.34, 0.66), Color("ffc21f"), 7, 10)
		k.ball(Vector3(s, 0.52, -0.2), Vector3(0.22, 0.14, 0.26), Color("7a4a26"), 4, 8)


static func _canal_house(k: MeshKit, v: float) -> void:
	var wall: Color = [Color("c9604a"), Color("8a5f3a"), Color("6a8a9a"), Color("e8d0a0")][int(v * 3.99)]
	_b(k, Vector3(0, 2.0, 0), Vector3(1.0, 2.0, 1.1), wall, 0.15)
	for step in 3:
		_b(k, Vector3(0, 4.1 + step * 0.34, 1.0), Vector3(0.9 - step * 0.28, 0.17, 0.08), wall.lightened(0.05), 0.3)
	k.cyl(Vector3(0, 4.0, 0), 1.0, 1.3, 0.2, Color("5a4a48"), 4)
	k.outline = 0.0
	for x: float in [-0.46, 0.46]:
		for y: float in [1.0, 2.2, 3.3]:
			_b(k, Vector3(x, y, 1.08), Vector3(0.24, 0.34, 0.02), WHITE)
			_b(k, Vector3(x, y, 1.1), Vector3(0.16, 0.26, 0.02), Color("4a6a8a"))
	k.outline = 0.02


static func _tulip_row(k: MeshKit, v: float) -> void:
	var colours := [Color("ff4f6a"), Color("ffd23f"), Color("ff9d2e"), Color("ff6fb5"), Color("ffffff")]
	var c: Color = colours[int(v * 4.99)]
	k.outline = 0.0
	k.ground(Rect2(-2.6, -0.9, 5.2, 1.8), 0.02, LEAF.darkened(0.2))
	k.outline = 0.02
	for x in 7:
		for z in 2:
			var at := Vector3(-2.2 + x * 0.74, 0, -0.42 + z * 0.84)
			k.cyl(at, 0.42, 0.04, 0.04, LEAF, 5)
			k.ball(at + Vector3(0, 0.56, 0), Vector3(0.18, 0.22, 0.18), c, 4, 7)


static func _stone_wall(k: MeshKit) -> void:
	var c := Color("9a9a8a")
	for spot: Array in [[Vector3(-0.36, 0.3, 0), Vector3(0.38, 0.3, 0.6)], [Vector3(0.38, 0.26, 0), Vector3(0.36, 0.26, 0.56)], [Vector3(0.0, 0.8, 0), Vector3(0.52, 0.28, 0.5)], [Vector3(-0.42, 1.2, 0), Vector3(0.3, 0.2, 0.44)], [Vector3(0.36, 1.18, 0), Vector3(0.34, 0.22, 0.46)]]:
		k.soft_box(spot[0], spot[1], c.lerp(Color("b8b8a8"), fmod(float(spot[0].x) * 7.0 + 1.0, 1.0)), 0.6, 4, 8)


static func _castle(k: MeshKit) -> void:
	var c := Color("a8a8a0")
	_b(k, Vector3(0, 2.0, 0), Vector3(3.0, 2.0, 2.4), c, 0.15)
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			k.cyl(Vector3(x * 3.0, 0, z * 2.4), 5.0, 1.0, 0.92, c.lightened(0.05), 10)
			k.cone(Vector3(x * 3.0, 5.0, z * 2.4), 2.0, 1.16, Color("3f5a88"), 10)
	k.outline = 0.0
	k.ball(Vector3(0, 1.1, 2.42), Vector3(0.9, 1.3, 0.03), INK.lightened(0.15), 3, 9)
	k.outline = 0.02
	for i in 5:
		_b(k, Vector3(-2.0 + i, 4.3, 2.3), Vector3(0.26, 0.3, 0.16), c.lightened(0.08), 0.4)


static func _sheep(k: MeshKit) -> void:
	var wool := Color("fffdf4")
	for x: float in [-0.3, 0.3]:
		for z: float in [-0.36, 0.42]:
			k.cyl(Vector3(x, 0, z), 0.4, 0.06, 0.07, INK.lightened(0.15), 5)
	k.ball(Vector3(0, 0.74, 0), Vector3(0.56, 0.46, 0.72), wool, 5, 9)
	for at: Vector3 in [Vector3(0.3, 0.98, 0.3), Vector3(-0.3, 0.98, 0.1), Vector3(0.0, 1.06, -0.26)]:
		k.ball(at, Vector3(0.26, 0.2, 0.26), wool, 4, 7)
	k.ball(Vector3(0, 0.9, 0.78), Vector3(0.22, 0.24, 0.24), INK.lightened(0.15), 4, 8)
	k.outline = 0.0
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.1, 0.98, 0.98), Vector3(0.05, 0.05, 0.02), WHITE, 3, 5)
	k.outline = 0.02


# --- The North ---------------------------------------------------------------------------------------------

static func _log_stack(k: MeshKit) -> void:
	for row: Array in [[Vector3(-0.46, 0.27, 0), 0], [Vector3(0.46, 0.27, 0), 0], [Vector3(0, 0.7, 0), 1], [Vector3(-0.46, 1.13, 0), 2], [Vector3(0.46, 1.13, 0), 2]]:
		k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), row[0]))
		k.cyl(Vector3(0, -0.72, 0), 1.44, 0.28, 0.28, Color("a8743c"), 10)
		k.outline = 0.0
		k.cyl(Vector3(0, 0.72, 0), 0.01, 0.2, 0.2, Color("f0d8a8"), 10)
		k.outline = 0.02
		k.pop()


static func _viking_ship(k: MeshKit) -> void:
	k.ball(Vector3(0, 0.6, 0), Vector3(1.0, 0.72, 3.4), Color("8a5f3a"), 6, 12)
	k.tube(PackedVector3Array([Vector3(0, 0.9, 3.0), Vector3(0, 1.6, 3.5), Vector3(0, 2.4, 3.3)]), 0.24, Color("8a5f3a"), false, 7, 0.1)
	k.ball(Vector3(0, 2.5, 3.3), Vector3(0.22, 0.22, 0.28), GOLD, 3, 7)
	for i in 5:
		var z := -2.0 + i
		for s: float in [-1.0, 1.0]:
			k.ball(Vector3(s * 0.96, 0.9, z), Vector3(0.05, 0.3, 0.3), RED if i % 2 == 0 else Color("3aa6ff"), 3, 8)
	k.cyl(Vector3(0, 0.9, 0), 3.8, 0.1, 0.07, DARK_WOOD, 7)
	_b(k, Vector3(0, 3.2, 0), Vector3(1.6, 1.3, 0.05), Color("fff6dd"), 0.4)
	k.outline = 0.0
	for x: float in [-1.0, 0.0, 1.0]:
		_b(k, Vector3(x, 3.2, 0.05), Vector3(0.24, 1.26, 0.02), RED)
	k.outline = 0.02


static func _stave_hut(k: MeshKit) -> void:
	var dark := Color("6a4a3a")
	_b(k, Vector3(0, 1.1, 0), Vector3(1.3, 1.1, 1.3), dark, 0.2)
	k.cone(Vector3(0, 2.2, 0), 1.6, 1.7, dark.darkened(0.15), 4)
	_b(k, Vector3(0, 3.4, 0), Vector3(0.5, 0.4, 0.5), dark, 0.25)
	k.cone(Vector3(0, 3.8, 0), 1.2, 0.68, dark.darkened(0.15), 4)
	k.outline = 0.0
	k.ball(Vector3(0, 2.3, 1.2), Vector3(0.9, 0.2, 0.2), Color("f4faff"), 3, 8)
	k.outline = 0.02


static func _igloo(k: MeshKit) -> void:
	var ice := Color("eaf6ff")
	k.dome(Vector3.ZERO, Vector3(1.9, 1.5, 1.9), ice, 6, 14)
	k.outline = 0.0
	for y: float in [0.45, 0.85, 1.2]:
		k.band(Vector3.ZERO, Vector3(1.9, 1.5, 1.9), y, y + 0.03, Color("b8dcf2"), 0.005, 18, 1)
	k.outline = 0.02
	k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.6, 1.5)))
	k.cyl(Vector3(0, -0.2, 0), 0.8, 0.72, 0.72, ice.darkened(0.05), 12)
	k.pop()
	k.outline = 0.0
	k.ball(Vector3(0, 0.55, 2.3), Vector3(0.5, 0.5, 0.02), Color("26304a"), 3, 10)
	k.outline = 0.02


# --- Africa and Australia -----------------------------------------------------------------------------------

static func _termite(k: MeshKit, c: Color) -> void:
	k.cone(Vector3.ZERO, 2.0, 0.72, c, 10)
	k.cone(Vector3(0.3, 0, 0.2), 1.3, 0.42, c.darkened(0.08), 8)
	k.cone(Vector3(-0.3, 0, -0.1), 1.05, 0.4, c.lightened(0.06), 8)


static func _acacia(k: MeshKit) -> void:
	var bark := Color("8a5f3a")
	k.tube(PackedVector3Array([Vector3.ZERO, Vector3(0.05, 1.4, 0), Vector3(0.05, 2.4, 0)]), 0.26, bark, false, 7, 0.18)
	for path: Array in [[Vector3(0, 2.2, 0), Vector3(1.0, 2.9, 0.3)], [Vector3(0, 2.2, 0), Vector3(-1.1, 2.9, -0.2)], [Vector3(0, 2.2, 0), Vector3(0.2, 3.0, -0.9)]]:
		k.tube(PackedVector3Array(path), 0.12, bark, false, 6, 0.07)
	k.ball(Vector3(0, 3.2, 0), Vector3(2.5, 0.5, 2.0), Color("7fb84a"), 5, 10)
	k.ball(Vector3(-0.9, 3.5, 0.2), Vector3(1.3, 0.34, 1.1), Color("93c85a"), 4, 8)


static func _giraffe(k: MeshKit) -> void:
	var c := Color("ffc55c")
	for x: float in [-0.26, 0.26]:
		for z: float in [-0.5, 0.5]:
			k.cyl(Vector3(x, 0, z), 1.3, 0.08, 0.11, c.darkened(0.08), 6)
	k.ball(Vector3(0, 1.5, 0), Vector3(0.42, 0.42, 0.72), c, 6, 9)
	k.tube(PackedVector3Array([Vector3(0, 1.7, 0.5), Vector3(0, 2.8, 0.8), Vector3(0, 3.8, 0.96)]), 0.18, c, false, 7, 0.12)
	k.ball(Vector3(0, 4.0, 1.1), Vector3(0.2, 0.2, 0.34), c, 5, 8)
	for s: float in [-0.1, 0.1]:
		k.cyl(Vector3(s, 4.14, 1.0), 0.28, 0.025, 0.025, Color("8a5f3a"), 5)
	k.outline = 0.0
	for at: Vector3 in [Vector3(0.4, 1.6, 0.2), Vector3(-0.4, 1.5, -0.1), Vector3(0.39, 1.4, -0.3), Vector3(-0.38, 1.7, 0.3), Vector3(0.15, 2.5, 0.8), Vector3(-0.14, 3.1, 0.9)]:
		k.ball(at, Vector3(0.1, 0.1, 0.1), Color("b5763c"), 3, 6)
	k.outline = 0.02


static func _red_rock(k: MeshKit, v: float) -> void:
	var c := Color("d9603a").lerp(Color("c9502f"), v)
	k.ball(Vector3(0, 0.6, 0), Vector3(0.76, 0.66, 0.7), c, 6, 10)
	k.ball(Vector3(0.36, 0.3, 0.34), Vector3(0.38, 0.32, 0.34), c.lightened(0.1), 5, 8)
	k.ball(Vector3(-0.4, 0.26, -0.2), Vector3(0.36, 0.3, 0.36), c.darkened(0.1), 5, 8)


static func _road_sign(k: MeshKit) -> void:
	k.cyl(Vector3.ZERO, 1.2, 0.06, 0.06, Color("c9c5dc"), 6)
	k.push(Transform3D(Basis(Vector3.BACK, PI * 0.25), Vector3(0, 1.5, 0)))
	_b(k, Vector3.ZERO, Vector3(0.48, 0.48, 0.04), Color("ffc21f"), 0.3)
	k.pop()
	k.outline = 0.0
	k.ball(Vector3(0, 1.52, 0.05), Vector3(0.22, 0.2, 0.02), INK, 3, 8)
	k.ball(Vector3(0.2, 1.72, 0.05), Vector3(0.1, 0.1, 0.02), INK, 3, 6)
	k.outline = 0.02


static func _red_mesa(k: MeshKit) -> void:
	var c := Color("d9603a")
	k.cyl(Vector3.ZERO, 3.4, 6.0, 4.6, c, 12)
	k.cyl(Vector3(0, 3.4, 0), 0.3, 4.6, 4.2, c.lightened(0.1), 12)
	k.outline = 0.0
	for y: float in [1.0, 2.2]:
		k.torus(Vector3(0, y, 0), 5.6 - y * 0.42, 0.08, c.darkened(0.18), 14, 3)
	k.outline = 0.02


static func _gum_tree(k: MeshKit) -> void:
	k.tube(PackedVector3Array([Vector3.ZERO, Vector3(0.2, 1.6, 0), Vector3(-0.1, 3.0, 0.1)]), 0.28, Color("f0e8da"), false, 7, 0.1)
	k.tube(PackedVector3Array([Vector3(0.1, 1.8, 0), Vector3(0.9, 2.8, 0.1)]), 0.1, Color("f0e8da"), false, 6, 0.05)
	k.ball(Vector3(-0.1, 3.4, 0.1), Vector3(1.1, 0.7, 1.1), Color("7fae7a"), 5, 9)
	k.ball(Vector3(0.95, 3.0, 0.1), Vector3(0.74, 0.52, 0.74), Color("93bf8a"), 4, 8)


static func _kangaroo(k: MeshKit) -> void:
	var c := Color("d98a4a")
	k.ball(Vector3(0, 0.84, -0.1), Vector3(0.42, 0.6, 0.42), c, 6, 9)
	k.ball(Vector3(0, 1.62, 0.12), Vector3(0.25, 0.27, 0.3), c.lightened(0.05), 5, 8)
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.15, 2.0, 0.08), Vector3(0.07, 0.2, 0.05), c, 4, 6)
		k.ball(Vector3(s * 0.28, 0.14, 0.26), Vector3(0.1, 0.1, 0.4), c.darkened(0.1), 4, 7)
		k.tube(PackedVector3Array([Vector3(s * 0.26, 1.2, 0.26), Vector3(s * 0.26, 0.96, 0.46)]), 0.05, c.darkened(0.06), false, 5)
	k.tube(PackedVector3Array([Vector3(0, 0.45, -0.4), Vector3(0, 0.14, -0.9), Vector3(0, 0.1, -1.5)]), 0.14, c, false, 7, 0.04)
	k.outline = 0.0
	k.ball(Vector3(0, 0.7, 0.3), Vector3(0.26, 0.3, 0.05), c.lightened(0.3), 3, 8)
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.11, 1.68, 0.38), Vector3(0.04, 0.05, 0.02), INK, 3, 5)
	k.outline = 0.02


static func _wind_pump(k: MeshKit) -> void:
	var steel := Color("c9c5dc")
	for a: float in [0.8, 2.4, 3.9, 5.5]:
		k.tube(PackedVector3Array([Vector3(cos(a) * 0.9, 0, sin(a) * 0.9), Vector3(0, 4.2, 0)]), 0.05, steel, false, 5)
	for i in 8:
		k.push(Transform3D(Basis(Vector3.BACK, TAU * i / 8.0), Vector3(0, 4.3, 0.22)))
		_b(k, Vector3(0, 0.7, 0), Vector3(0.12, 0.6, 0.02), RED if i % 2 == 0 else WHITE, 0.4)
		k.pop()
	_b(k, Vector3(0, 4.3, -0.5), Vector3(0.03, 0.4, 0.55), RED, 0.5)


# --- Central and South America ----------------------------------------------------------------------------

static func _carved(k: MeshKit) -> void:
	var c := Color("9a9a78")
	_b(k, Vector3(0, 0.66, 0), Vector3(0.72, 0.66, 0.66), c, 0.3)
	k.outline = 0.0
	for s: float in [-0.3, 0.3]:
		k.ball(Vector3(s, 0.86, 0.66), Vector3(0.18, 0.14, 0.03), c.darkened(0.3), 3, 7)
	_b(k, Vector3(0, 0.42, 0.66), Vector3(0.4, 0.1, 0.03), c.darkened(0.3))
	_b(k, Vector3(0, 1.14, 0.66), Vector3(0.5, 0.05, 0.02), Color("3fbfae"))
	k.outline = 0.02


static func _cactus(k: MeshKit) -> void:
	var c := Color("4cbc5e")
	k.ball(Vector3(0, 0.82, 0), Vector3(0.32, 0.82, 0.32), c, 7, 10)
	for s: float in [-1.0, 1.0]:
		k.tube(PackedVector3Array([Vector3(s * 0.26, 0.74, 0), Vector3(s * 0.62, 0.78, 0), Vector3(s * 0.62, 1.2, 0)]), 0.13, c, false, 7, 0.11)
	k.ball(Vector3(0, 1.66, 0), Vector3(0.12, 0.1, 0.12), Color("ff6fb5"), 3, 7)


static func _step_pyramid(k: MeshKit) -> void:
	var c := Color("a8a888")
	for i in 5:
		var s := 4.0 - i * 0.68
		_b(k, Vector3(0, 0.5 + i * 1.0, 0), Vector3(s, 0.5, s), c.lerp(c.lightened(0.15), i * 0.2), 0.15)
	_b(k, Vector3(0, 5.4, 0), Vector3(0.9, 0.5, 0.9), c.lightened(0.2), 0.2)
	k.outline = 0.0
	for i in 5:
		_b(k, Vector3(0, 0.3 + i * 1.0, 4.04 - i * 0.68), Vector3(0.8, 0.3, 0.04), c.darkened(0.25))
	k.outline = 0.02


static func _llama(k: MeshKit) -> void:
	var c := Color("fff1d6")
	for x: float in [-0.2, 0.2]:
		for z: float in [-0.4, 0.4]:
			k.cyl(Vector3(x, 0, z), 0.74, 0.07, 0.08, c.darkened(0.1), 6)
	k.ball(Vector3(0, 0.96, 0), Vector3(0.34, 0.32, 0.6), c, 6, 9)
	k.tube(PackedVector3Array([Vector3(0, 1.1, 0.42), Vector3(0, 1.7, 0.55)]), 0.15, c, false, 7, 0.12)
	k.ball(Vector3(0, 1.84, 0.62), Vector3(0.16, 0.16, 0.24), c, 5, 8)
	for s: float in [-0.08, 0.08]:
		k.ball(Vector3(s, 2.06, 0.54), Vector3(0.04, 0.12, 0.03), c, 3, 5)
	k.outline = 0.0
	k.band(Vector3(0, 0.96, 0), Vector3(0.345, 0.325, 0.605), 0.08, 0.28, Color("e8483f"), 0.004, 14, 2)
	k.outline = 0.02


static func _terrace(k: MeshKit) -> void:
	var green := Color("6ccf5a")
	for i in 5:
		k.cyl(Vector3(0, i * 0.8, 0), 0.8, 5.0 - i * 0.95, 4.9 - i * 0.95, green if i % 2 == 0 else green.darkened(0.12), 14)
		k.outline = 0.0
		k.torus(Vector3(0, i * 0.8 + 0.08, 0), 5.0 - i * 0.95, 0.1, Color("9a9a8a"), 14, 3)
		k.outline = 0.02


# --- Turkiye, Hawaii, Canada -----------------------------------------------------------------------------------

static func _fairy_chimney(k: MeshKit, s: float) -> void:
	var c := Color("e0c098")
	k.ball(Vector3(0, 0.85 * s, 0), Vector3(0.62, 0.92, 0.62) * s, c, 6, 10)
	k.cone(Vector3(0, 1.4 * s, 0), 0.72 * s, 0.56 * s, Color("8a6a4a"), 10)
	k.outline = 0.0
	k.ball(Vector3(0, 1.0 * s, 0.6 * s), Vector3(0.1, 0.16, 0.03) * s, INK.lightened(0.15), 3, 6)
	k.outline = 0.02


static func _hot_balloon(k: MeshKit, v: float) -> void:
	var c: Color = [RED, Color("3aa6ff"), Color("ffc21f"), Color("ff6fb5")][int(v * 3.99)]
	var y := 5.0 + v * 3.0
	k.ball(Vector3(0, y + 2.0, 0), Vector3(1.8, 2.2, 1.8), c, 8, 12)
	k.outline = 0.0
	for up: float in [-0.5, 0.5]:
		k.band(Vector3(0, y + 2.0, 0), Vector3(1.81, 2.21, 1.81), up, up + 0.5, WHITE if int(v * 8.0) % 2 == 0 else GOLD, 0.008, 14, 2)
	k.outline = 0.02
	_b(k, Vector3(0, y - 0.8, 0), Vector3(0.45, 0.32, 0.45), WOOD, 0.4)
	for x: float in [-0.36, 0.36]:
		k.tube(PackedVector3Array([Vector3(x, y - 0.5, x), Vector3(x * 1.8, y + 0.4, x * 1.8)]), 0.018, DARK_WOOD, false, 4)


static func _surf_rack(k: MeshKit) -> void:
	var colours := [Color("19b8d6"), Color("ff6fb5"), Color("ffc21f")]
	for i in 3:
		k.push(Transform3D(Basis(Vector3.RIGHT, -0.22), Vector3(-0.44 + i * 0.44, 0.92, -0.02)))
		k.ball(Vector3.ZERO, Vector3(0.22, 0.92, 0.05), colours[i], 6, 10)
		k.pop()
	_b(k, Vector3(0, 0.56, -0.2), Vector3(0.74, 0.06, 0.1), WOOD, 0.5)


static func _tiki(k: MeshKit) -> void:
	var wood := Color("a06a3a")
	_b(k, Vector3(0, 0.82, 0), Vector3(0.5, 0.82, 0.46), wood, 0.45)
	k.outline = 0.0
	for s: float in [-0.22, 0.22]:
		k.ball(Vector3(s, 1.14, 0.44), Vector3(0.16, 0.14, 0.03), Color("fff3d6"), 3, 7)
		k.ball(Vector3(s, 1.14, 0.47), Vector3(0.08, 0.08, 0.02), INK, 3, 6)
	_b(k, Vector3(0, 0.6, 0.44), Vector3(0.32, 0.12, 0.03), INK.lightened(0.15))
	for x: float in [-0.2, 0.0, 0.2]:
		_b(k, Vector3(x, 0.6, 0.47), Vector3(0.06, 0.1, 0.01), Color("fff3d6"))
	k.outline = 0.02
	k.ball(Vector3(0, 1.72, 0), Vector3(0.6, 0.12, 0.54), wood.darkened(0.15), 4, 9)


static func _volcano(k: MeshKit) -> void:
	var c := Color("6b4a44")
	k.cyl(Vector3.ZERO, 5.0, 7.0, 1.6, c, 12)
	k.outline = 0.0
	k.cyl(Vector3(0, 5.0, 0), 0.02, 1.5, 1.5, Color("ff7a1f"), 12)
	for a: float in [0.4, 2.2, 4.4]:
		k.push(Transform3D(Basis(Vector3.UP, -a) * Basis(Vector3.BACK, -0.95), Vector3(cos(a) * 3.2, 2.8, sin(a) * 3.2)))
		k.ball(Vector3.ZERO, Vector3(0.28, 2.0, 0.12), Color("ff7a1f"), 3, 7)
		k.pop()
	k.outline = 0.02
	k.ball(Vector3(-2.0, 0.5, 3.0), Vector3(2.4, 1.2, 2.0), Color("35a659"), 4, 8)


static func _moose(k: MeshKit) -> void:
	var c := Color("7a5230")
	for x: float in [-0.3, 0.3]:
		for z: float in [-0.56, 0.56]:
			k.cyl(Vector3(x, 0, z), 1.2, 0.09, 0.1, c.darkened(0.1), 6)
	k.ball(Vector3(0, 1.5, 0), Vector3(0.52, 0.56, 0.95), c, 6, 9)
	k.ball(Vector3(0, 1.8, 1.05), Vector3(0.26, 0.28, 0.46), c.lightened(0.05), 5, 8)
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.46, 2.32, 0.8), Vector3(0.42, 0.08, 0.28), Color("c9a878"), 4, 8)
		k.tube(PackedVector3Array([Vector3(s * 0.12, 2.0, 0.85), Vector3(s * 0.34, 2.28, 0.8)]), 0.05, Color("c9a878"), false, 5)


static func _log_cabin(k: MeshKit) -> void:
	var wood := Color("a8743c")
	for y in 5:
		k.soft_box(Vector3(0, 0.25 + y * 0.46, 0), Vector3(1.8, 0.24, 1.5), wood if y % 2 == 0 else wood.darkened(0.1), 0.6, 4, 8)
	k.cyl(Vector3(0, 2.5, 0), 1.4, 2.5, 0.2, Color("f4faff"), 4)
	k.outline = 0.0
	_b(k, Vector3(0, 0.8, 1.52), Vector3(0.36, 0.72, 0.02), DARK_WOOD)
	k.outline = 0.02
	k.cyl(Vector3(1.0, 2.6, 0.4), 1.4, 0.2, 0.2, STONE, 7)
