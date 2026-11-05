class_name Maps
extends RefCounted
## Every arena. A map is a theme (how it looks) plus a layout (where the walls, water and pads are).
## Layouts are drawn as the left half of the field and mirrored, so both teams always get the same
## ground: "x" mirrors left to right, "rot" turns the half 180 degrees.
##
## Tiles: . floor   # wall   ~ water/lava/void (blocks feet, not shots)   g bushes (hide you)
##        i ice     m mud    b bounce pad (flies you to its mirror)    t teleporter (joined to its mirror)
##        > < ^ v conveyor   A your base      J the jail where you keep prisoners
##        R L U D dash floor: shoots you that way
##        1 2     jump pad: throws you to the landing box with the same number ! @
##        =       gate: rises and falls on a timer
##        f       fountain: makes whoever touches it fresh, then needs time to refill
##        * crystal altar: always grows a new crystal
##        %       low fence: stops a walk, but a dash goes over it
##        o       bumper: knocks you flying

const TILE := 2.0  ## Metres per tile.
const CLEAR_BASE := 5.8  ## Nothing stands this close to the middle of a base...
const CLEAR_JAIL := 3.2  ## ...or of a jail.

enum { FLOOR, SOLID, PIT, GRASS, ICE, MUD, BOUNCE, TELE, CON_R, CON_L, CON_U, CON_D, DASH_R, DASH_L, DASH_U, DASH_D, JUMP, LAND, GATE, FOUNTAIN, ALTAR, FENCE, BUMPER }

const JUMP_PADS := {"1": "!", "2": "@"}

const LAYOUTS := {
	"plaza": {"name": "Plaza", "mirror": "x", "blurb": "Wide open. Good for your first game.", "rows": [
		"..............",
		"..J...RR...*..",
		"..............",
		"......##......",
		"......##..ggg.",
		"..........ggg.",
		"..............",
		"..A....1..##!f",
		"..............",
		"..........ggg.",
		"......##..ggg.",
		"......##......",
		"..............",
		".....RR....*..",
		"..............",
	]},
	"crossroads": {"name": "Crossroads", "mirror": "x", "blurb": "Four walled blocks and a busy junction.", "rows": [
		"..............",
		"..J.........*.",
		"......####....",
		"......####..gg",
		"......##....gg",
		"..........=...",
		"..........#...",
		"..A.......#.of",
		"..........#...",
		"..........=...",
		"......##....gg",
		"......####..gg",
		"......####....",
		".......RRR....",
		"............*.",
	]},
	"twin_ponds": {"name": "Twin Ponds", "mirror": "x", "blurb": "Two ponds squeeze the middle of the field.", "rows": [
		"..............",
		"..J......gg...",
		"......1..gg...",
		"......~~~~....",
		".....~~~~~~.*.",
		"......~~~~....",
		"........!.....",
		"..A.....RRR..f",
		"........@.....",
		"......~~~~....",
		".....~~~~~~.*.",
		"......~~~~....",
		"......2..gg...",
		".........gg...",
		"..............",
	]},
	"zigzag": {"name": "Zigzag", "mirror": "rot", "blurb": "Slanted walls that bend every chase.", "rows": [
		"..............",
		"..J.....##....",
		"........##..f.",
		"......##..D...",
		"......##...gg.",
		"....##.....gg.",
		"....##.%....o.",
		"..A....%..##.*",
		".......%..##..",
		"........##.U..",
		".gg.....##....",
		".gg...##......",
		"......##......",
		"....##.R......",
		"....##.R......",
	]},
	"fortress": {"name": "Fortress", "mirror": "x", "blurb": "Your base sits behind walls with two gates.", "rows": [
		"..............",
		"..J.....*.RR..",
		"..............",
		"#####.........",
		"....#.....gg..",
		"....#.....gg..",
		".....=........",
		"..A..=....##.f",
		".....=........",
		"....#.....gg..",
		"....#.....gg..",
		"#####.........",
		"..............",
		"........*RR...",
		"..............",
	]},
	"conveyors": {"name": "Conveyor Alley", "mirror": "x", "blurb": "Belts carry you to the front or sweep you home.", "rows": [
		"..............",
		"..J...........",
		"....>>>>>>>>>>",
		"..............",
		"......##.gg.*.",
		"......##.gg...",
		"..............",
		"..A.....o..o.f",
		"..............",
		"......##.gg...",
		"......##.gg.*.",
		"..............",
		"....<<<<<<<<<<",
		"..............",
		"..............",
	]},
	"bouncy": {"name": "Bounce Canal", "mirror": "x", "blurb": "A canal down the middle. Bounce pads fly you over it.", "rows": [
		"...........~~~",
		"..J....gg..~~~",
		".......gg..~~~",
		".........b.~~~",
		"...........~~~",
		".........*.~~~",
		"..............",
		"..A.....RR...f",
		"..............",
		".........*.~~~",
		"...........~~~",
		".........b.~~~",
		".......gg..~~~",
		".......gg..~~~",
		"...........~~~",
	]},
	"teleports": {"name": "Warp Yard", "mirror": "x", "blurb": "Step in a warp and step out on the far side.", "rows": [
		"..............",
		"..J.....##....",
		"........##....",
		".....t......*.",
		"..............",
		"......==..gg..",
		"......##..gg..",
		"..A...##..o..f",
		"......##..gg..",
		"......==..gg..",
		"..............",
		".....t......*.",
		"........##....",
		"........##....",
		"..............",
	]},
	"rink": {"name": "Skating Rink", "mirror": "x", "blurb": "The whole middle is slippery. Mind the turns.", "rows": [
		".........R....",
		"..J.......*...",
		".......iiiiiii",
		"......iiiiiioi",
		".....iii##iiii",
		".....iii##iiii",
		".....iiiiiiiii",
		"..A..iiiioiiif",
		".....iiiiiiiii",
		".....iii##iiii",
		".....iii##iiii",
		"......iiiiiioi",
		".......iiiiiii",
		"..........*...",
		".........R....",
	]},
	"mudflats": {"name": "Mud Flats", "mirror": "x", "blurb": "Sticky patches slow you down. The dry lanes are worth it.", "rows": [
		"...........*..",
		"..J......mmmmm",
		".........mmmmm",
		"......##.mmmmm",
		"......##.RRR..",
		"..............",
		"........mmmm..",
		"..A...1.mmmm!f",
		"........mmmm..",
		"..............",
		"......##.RRR..",
		"......##.mmmmm",
		".........mmmmm",
		".........mmmmm",
		"...........*..",
	]},
	"hideout": {"name": "Hide & Seek", "mirror": "x", "blurb": "Tall grass everywhere. Who's in there?", "rows": [
		".......gggggg.",
		"..J....gggggg.",
		"......ggg..gg.",
		"......gg..*.!.",
		"....ggg..##...",
		"....gg...##.gg",
		".........gggg.",
		"..A...1..ggggf",
		".........gggg.",
		"....gg...##.gg",
		"....ggg..##...",
		"......gg..*...",
		"......ggg..gg.",
		".......gggggg.",
		".......gggggg.",
	]},
	"pillars": {"name": "Pillars", "mirror": "x", "blurb": "A forest of pillars. Perfect for shaking off a chaser.", "rows": [
		"..............",
		"..J...#...#...",
		".....%....*...",
		"....#%..#...#.",
		"..............",
		"......#.o.#...",
		"..............",
		"..A.#...#...#f",
		"..............",
		"......#.o.#...",
		"..............",
		"....#%..#...#.",
		".....%....*...",
		"......#...#...",
		"..............",
	]},
	"bridges": {"name": "Three Bridges", "mirror": "x", "blurb": "A river cuts the field. Hold the bridges.", "rows": [
		"..........~~~~",
		"..J.....*.~~~~",
		"..........~~~~",
		"...........=..",
		"..........~~~~",
		"........b.~~~~",
		"..........~~~~",
		"..A..........f",
		"..........~~~~",
		"........b.~~~~",
		"..........~~~~",
		"...........=..",
		"..........~~~~",
		"........*.~~~~",
		"..........~~~~",
	]},
	"ringroad": {"name": "Ring Road", "mirror": "x", "blurb": "A great block in the centre. Go round, left or right.", "rows": [
		"..............",
		"..J.....RRR..f",
		"..............",
		".......*.#####",
		".........#####",
		".........#####",
		"...gg....#####",
		"..A.gg.b.#####",
		"...gg....#####",
		".........#####",
		".........#####",
		".......*.#####",
		"..............",
		"........RRR..f",
		"..............",
	]},
	"pinwheel": {"name": "Pinwheel", "mirror": "rot", "blurb": "Walls spin around the centre. No two lanes are the same.", "rows": [
		"..............",
		"..J.......####",
		"..........#...",
		"...gg.....#.*.",
		"...gg...D.....",
		".......###....",
		".......#......",
		"..A....#.....f",
		".......#......",
		"....####......",
		"...........U..",
		".....o...gg...",
		".........gg...",
		"........RR....",
		"..............",
	]},
	"gauntlet": {"name": "The Gauntlet", "mirror": "x", "blurb": "Long corridors, tight corners, nowhere to hide.", "rows": [
		"........gg....",
		"..J...........",
		"....##########",
		"......RRR....*",
		"..............",
		"....########..",
		"..............",
		"..A.....%....f",
		"..............",
		"....########..",
		"..............",
		"......RRR....*",
		"....##########",
		"..............",
		"........gg....",
	]},
}

## Look of a map. `pit` names what the ~ tiles are, `blocks` and `decor` are PropKit prop names.
const THEMES := {
	"barrio": {"name": "Barrio", "floor": ["7fd65a", "71c94f"], "edge": "58b048", "bg": "4aa03f", "sky": "8fe3ff",
		"pit": "water", "pit_c": "2ec4e8", "wall": "d99a5b", "accent": "ff5a7a", "grass": "2ea84a", "blocks": ["crate", "stall", "hay"], "decor": ["hut", "palm", "banderitas", "palm", "bush"], "music": "tropical_island"},
	"terraces": {"name": "Terraces", "floor": ["a6db5c", "96cf4e"], "edge": "6fae3c", "bg": "5c9c37", "sky": "b7ecff",
		"pit": "water", "pit_c": "6edff2", "wall": "9b7a54", "accent": "f7d154", "grass": "48b23f", "blocks": ["rock", "stump", "hay"], "decor": ["pine", "hut", "rock", "bush"], "music": "tropical_tiki"},
	"beach": {"name": "Coconut Beach", "floor": ["ffe39c", "fbd98a"], "edge": "f2c675", "bg": "2ec4e8", "sky": "9ff0ff",
		"pit": "water", "pit_c": "2ad3e6", "wall": "c98d55", "accent": "ff7a59", "grass": "6ccf5a", "blocks": ["barrel", "crate", "rock"], "decor": ["palm", "umbrella", "palm", "boat", "rock"], "music": "tropical_beach"},
	"terminal": {"name": "Jeepney Terminal", "floor": ["8f93a8", "85899e"], "edge": "6d7186", "bg": "5a5e74", "sky": "a8d8ff",
		"pit": "void", "pit_c": "3a3d52", "wall": "e8574a", "accent": "ffd23f", "grass": "4bb56b", "blocks": ["jeep", "cone_stack", "crate"], "decor": ["building", "lamp", "building", "tree"], "music": "funk"},
	"volcano": {"name": "Volcano", "floor": ["6b4a44", "5f403b"], "edge": "4a312d", "bg": "3a2522", "sky": "ffb27a",
		"pit": "lava", "pit_c": "ff6a1f", "wall": "3d2a32", "accent": "ffa51f", "grass": "a34a2e", "blocks": ["rock", "crystal", "rock"], "decor": ["spire", "rock", "spire"], "music": "gamer_hard"},
	"mangrove": {"name": "Mangrove", "floor": ["6cc2a0", "60b694"], "edge": "4b9d80", "bg": "2c8f8a", "sky": "c4f2d8",
		"pit": "water", "pit_c": "33b7a6", "wall": "7a5a3c", "accent": "ffcb47", "grass": "2f9c59", "blocks": ["stump", "rock", "barrel"], "decor": ["mangrove", "mushroom", "mangrove", "lily"], "music": "tropical_tiki"},
	"glacier": {"name": "Glacier", "floor": ["e4f6ff", "d4edfb"], "edge": "b6dcf2", "bg": "9ad0ee", "sky": "d9f3ff",
		"pit": "water", "pit_c": "4fb0e8", "wall": "8fc7ee", "accent": "ff6fb5", "grass": "b5e3f5", "blocks": ["ice_block", "crystal", "snowman"], "decor": ["pine_snow", "ice_block", "snowman", "pine_snow"], "music": "kids_polka"},
	"halo": {"name": "Halo-Halo Land", "floor": ["ffc9ea", "ffbde3"], "edge": "f09fd2", "bg": "b57cff", "sky": "ffe3f6",
		"pit": "syrup", "pit_c": "9d5cff", "wall": "ff7ab8", "accent": "6fe7ff", "grass": "7be0b5", "blocks": ["cake", "gumdrop", "donut"], "decor": ["lollipop", "cone", "lollipop", "gumdrop"], "music": "kids_polka"},
	"arcade": {"name": "Neon Arcade", "floor": ["2b2466", "251f5b"], "edge": "1c174a", "bg": "120e36", "sky": "3a2d8a",
		"pit": "void", "pit_c": "0b0826", "wall": "ff3fb4", "accent": "27e9ff", "grass": "27e9ff", "blocks": ["cabinet", "neon_block", "neon_block"], "decor": ["neon_tower", "cabinet", "neon_tower"], "music": "gamer_final"},
	"ruins": {"name": "Jungle Ruins", "floor": ["b9b98a", "acac7e"], "edge": "8a8a60", "bg": "3f8f4a", "sky": "bff0c6",
		"pit": "water", "pit_c": "3fbfae", "wall": "8e8e74", "accent": "f4b942", "grass": "3aa04a", "blocks": ["pillar", "rock", "statue"], "decor": ["jungle_tree", "pillar", "statue", "jungle_tree"], "music": "latin_samba"},
	"cove": {"name": "Pirate Cove", "floor": ["e6c387", "dcb878"], "edge": "b98f57", "bg": "1f8fc4", "sky": "a5e5ff",
		"pit": "water", "pit_c": "1fa9d6", "wall": "8a5a34", "accent": "e8483f", "grass": "63b84e", "blocks": ["barrel", "chest", "crate"], "decor": ["ship", "palm", "rock", "barrel"], "music": "rock_sock"},
	"moon": {"name": "Moon Base", "floor": ["b8b4cc", "aca8c2"], "edge": "8c88a6", "bg": "2a2750", "sky": "4a4590",
		"pit": "void", "pit_c": "1a1838", "wall": "6f6ad0", "accent": "6dffb0", "grass": "6dffb0", "blocks": ["pod", "crystal", "neon_block"], "decor": ["dish", "pod", "rock"], "music": "gamer_coins"},
	"spooky": {"name": "Spooky Hollow", "floor": ["6d6490", "625a85"], "edge": "4c4470", "bg": "2c2750", "sky": "6a5aa8",
		"pit": "syrup", "pit_c": "62e0a0", "wall": "4a3f6b", "accent": "ff9d2e", "grass": "4aa58a", "blocks": ["tomb", "pumpkin", "stump"], "decor": ["dead_tree", "tomb", "dead_tree", "pumpkin"], "music": "cartoon_snitch"},
	"schoolyard": {"name": "Schoolyard", "floor": ["d9b98a", "cfae7e"], "edge": "b4935f", "bg": "76c35c", "sky": "bdeaff",
		"pit": "water", "pit_c": "4cc7ee", "wall": "e4574f", "accent": "ffd23f", "grass": "59c04f", "blocks": ["crate", "tire", "hay"], "decor": ["tree", "building", "tree", "bush"], "music": "cartoon_jaunty"},
}

const THEME_ORDER := ["barrio", "beach", "schoolyard", "terraces", "terminal", "mangrove", "halo", "glacier", "ruins", "cove", "volcano", "spooky", "arcade", "moon"]
## The ground behind each base, added to the far edge of every layout, with a clear row above and below the field:
## room to come round the back of a base, and hedges, cover and crystals to bring you there.
const YARDS := [
	[".....", ".ggg.", ".ggg.", ".....", ".....", ".....", "..#..", "..#..", ".*...", "..#..", "..#..", ".....", ".....", ".....", ".ggg.", ".ggg.", "....."],
	[".....", "..#..", "..#..", ".....", ".....", ".gg..", ".gg..", ".gg..", ".gg..", ".gg..", ".gg..", ".gg..", ".....", ".....", "..#..", "..#..", "....."],
	[".....", ".....", ".#.#.", ".....", ".....", ".#.#.", ".....", ".....", ".....", ".....", ".....", ".#.#.", ".....", ".....", ".#.#.", ".....", "....."],
	[".....", ".~~..", ".~~..", ".....", ".....", "..gg.", "..gg.", ".....", ".....", ".....", "..gg.", "..gg.", ".....", ".....", ".~~..", ".~~..", "....."],
]
const LAYOUT_ORDER := ["plaza", "crossroads", "twin_ponds", "zigzag", "fortress", "conveyors", "bouncy", "teleports", "rink", "mudflats", "hideout", "pillars", "bridges", "ringroad", "pinwheel", "gauntlet"]
const MAPS_PER_THEME := 4

static var _maps: Array[Dictionary] = []
static var _by_id := {}


## Every map: {id, name, theme, layout}. Themes step through the layouts so every layout appears in
## several looks.
static func all() -> Array[Dictionary]:
	if _maps.is_empty():
		var n := 0
		for theme: String in THEME_ORDER:
			for i in MAPS_PER_THEME:
				var layout: String = LAYOUT_ORDER[n % LAYOUT_ORDER.size()]
				n += 1
				var map := {"id": "%s_%s" % [theme, layout], "theme": theme, "layout": layout,
					"name": "%s %s" % [THEMES[theme]["name"], LAYOUTS[layout]["name"]]}
				_maps.append(map)
				_by_id[map["id"]] = map
	return _maps


static func by_id(id: String) -> Dictionary:
	all()
	return _by_id.get(id, {})


static func random_id(rng: RandomNumberGenerator = null) -> String:
	var list := all()
	var i := rng.randi_range(0, list.size() - 1) if rng else randi_range(0, list.size() - 1)
	return String(list[i]["id"])


static func thumb_path(id: String) -> String:
	return "res://assets/maps/%s.webp" % id


## Expands a map's layout to the whole field:
## {w, h, tiles: PackedByteArray, base: [Vector2, Vector2], jail: [Vector2, Vector2], tele: {tile: tile}}.
## Team 0 starts on the left, team 1 on the right; base and jail positions are in metres.
static func build_grid(map_id: String) -> Dictionary:
	var map := by_id(map_id)
	if map.is_empty():
		map = all()[0]
	var layout: Dictionary = LAYOUTS[map["layout"]]
	var rows := _with_yard(layout["rows"], YARDS[LAYOUT_ORDER.find(map["layout"]) % YARDS.size()])
	var half_w: int = String(rows[0]).length()
	var h: int = rows.size()
	var w := half_w * 2
	var tiles := PackedByteArray()
	tiles.resize(w * h)
	var rot: bool = layout["mirror"] == "rot"
	var base := [Vector2.ZERO, Vector2.ZERO]
	var jail := [Vector2.ZERO, Vector2.ZERO]
	var tele_half: Array[Vector2i] = []
	var pads := {}
	var landings := {}
	for y in h:
		var row: String = rows[y]
		for x in half_w:
			var c := row[x]
			var mx := w - 1 - x
			var my := h - 1 - y if rot else y
			if c == "A":
				base[0] = _center(x, y)
				base[1] = _center(mx, my)
				c = "."
			elif c == "J":
				jail[0] = _center(x, y)
				jail[1] = _center(mx, my)
				c = "."
			elif c == "t":
				tele_half.append(Vector2i(x, y))
			elif JUMP_PADS.has(c):
				pads[c] = Vector2i(x, y)
			elif JUMP_PADS.values().has(c):
				landings[c] = Vector2i(x, y)
			tiles[y * w + x] = _code(c)
			tiles[my * w + mx] = _mirror_code(_code(c), rot)
	# Bases and jails always stand on clear ground.
	for team in 2:
		_clear(tiles, w, h, base[team], CLEAR_BASE)
		_clear(tiles, w, h, jail[team], CLEAR_JAIL)
	var tele := {}
	for t: Vector2i in tele_half:
		var a := t.y * w + t.x
		var b := (h - 1 - t.y if rot else t.y) * w + (w - 1 - t.x)
		tele[a] = b
		tele[b] = a
	# A jump pad and its landing box, on each half of the field.
	var jumps := {}
	for c: String in pads:
		var from: Vector2i = pads[c]
		var to: Vector2i = landings[JUMP_PADS[c]]
		jumps[from.y * w + from.x] = to.y * w + to.x
		jumps[(h - 1 - from.y if rot else from.y) * w + (w - 1 - from.x)] = (h - 1 - to.y if rot else to.y) * w + (w - 1 - to.x)
	return {"w": w, "h": h, "tiles": tiles, "base": base, "jail": jail, "tele": tele, "jumps": jumps}


static func _with_yard(rows: Array, yard: Array) -> Array:
	var out: Array = []
	var width := String(rows[0]).length()
	out.append(String(yard[0]) + ".".repeat(width))
	for i in rows.size():
		out.append(String(yard[i + 1]) + String(rows[i]))
	out.append(String(yard[rows.size() + 1]) + ".".repeat(width))
	return out


static func _center(x: int, y: int) -> Vector2:
	return Vector2((x + 0.5) * TILE, (y + 0.5) * TILE)


static func _clear(tiles: PackedByteArray, w: int, h: int, at: Vector2, radius: float) -> void:
	for y in h:
		for x in w:
			if _center(x, y).distance_to(at) <= radius:
				tiles[y * w + x] = FLOOR


static func _code(c: String) -> int:
	match c:
		"#": return SOLID
		"~": return PIT
		"g": return GRASS
		"i": return ICE
		"m": return MUD
		"b": return BOUNCE
		"t": return TELE
		">": return CON_R
		"<": return CON_L
		"^": return CON_U
		"v": return CON_D
		"R": return DASH_R
		"L": return DASH_L
		"U": return DASH_U
		"D": return DASH_D
		"1", "2": return JUMP
		"!", "@": return LAND
		"=": return GATE
		"f": return FOUNTAIN
		"*": return ALTAR
		"%": return FENCE
		"o": return BUMPER
	return FLOOR


static func _mirror_code(code: int, rot: bool) -> int:
	match code:
		CON_R: return CON_L
		CON_L: return CON_R
		CON_U: return CON_D if rot else CON_U
		CON_D: return CON_U if rot else CON_D
		DASH_R: return DASH_L
		DASH_L: return DASH_R
		DASH_U: return DASH_D if rot else DASH_U
		DASH_D: return DASH_U if rot else DASH_D
	return code
