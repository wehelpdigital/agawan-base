class_name Sim
extends RefCounted
## The rules of the game, with no scenes or rendering: the same code runs a practice match on your
## device and an online match on whichever player hosts it. Everything a viewer needs is plain data,
## so to_snapshot()/apply_snapshot() can copy a match to other players, or hand it to a new host.
##
## The rules come from the traditional game of Agawan Base (Prisoner's Base):
## - A line between the bases makes the safety zones. On your side you can tag any enemy, and over the line they can tag
##   you. It's the rule in the Philippine Department of Education's PE module. The other old rule, "whoever touched base
##   last", is still here underneath: being on your side keeps your clock fresh.
## - A tagged player goes to the jail beside the tagger's base. A free teammate who reaches that jail
##   frees everyone in it, and rescuers and freed players get a short "free walk": nobody can tag
##   them, and they can't tag or capture.
## - Stand on the enemy base long enough to capture it, or jail the whole enemy team at once: a point.
##   First to 3 points, or the most points when time runs out, then sudden death on a tie, and after
##   that the team that took the most prisoners.
## One rule is ours, because camping is no fun on a screen: stay on your own base for 5 seconds and the
## pad pops you off it.
##
## Then there's the world around them: map elements that run on a beat (see the constants below), and the weather
## (core/data/Weather.gd), which changes how far you can see, how well your feet grip and which way the wind shoves you.

const TICK := 1.0 / 30.0
const RADIUS := 0.62
const SPEED := 7.2
const DASH_SPEED := 19.0
const DASH_TIME := 0.17
const DASH_COOLDOWN := 3.2
const TAG_COOLDOWN := 0.35
const TAG_MARGIN := 0.2  ## Extra reach so a tag feels as generous as it looks.
const JAIL_TIME := 9.0
const MASH_SAVE := 0.2  ## Seconds off your sentence per tap while in jail.
const MASH_GAP := 0.12
const FREE_WALK := 4.0
const BASE_R := 4.2  ## Too wide to guard from one spot, with open ground all round it.
const JAIL_R := 2.6
const CAPTURE_TIME := 1.4
const CAMP_LIMIT := 5.0  ## Seconds on your own base before the pad pops you off it.
const MATCH_TIME := 180.0
const FIESTA_AT := 60.0  ## Seconds left when powerups start to rain faster.
const OVERTIME := 45.0
const WIN_POINTS := 3
const SPIN_TIME := 1.3  ## How long a new power spins before you can use it.
const MODE_MARGIN := 0.7  ## How far past the line you have to be for it to count, so running along it doesn't keep reshuffling your cards.
const START_CRYSTALS := 18
const SPAWN_GAP := Vector2(0.3, 0.55)  ## Seconds between new crystals.
const FIESTA_GAP := Vector2(0.15, 0.3)
const AREA_PER_CRYSTAL := 95.0  ## There's a crystal on the field for every this many square metres.
const ITCH_CYCLE := 1.25  ## Itchy: stops to scratch for the first ITCH_STOP seconds of every cycle.
const ITCH_STOP := 0.42
const FLOOR_DASH_TIME := 0.34  ## How long a dash floor shoots you.
const GATE_CYCLE := 11.0  ## A gate is shut for the first GATE_SHUT seconds of every cycle.
const GATE_SHUT := 4.5
const FOUNTAIN_REFILL := 16.0
const ALTAR_REGROW := 13.0
const BUMPER_KICK := 26.0
const BUSH_SIGHT := 3.5  ## Enemies this close can see you in a bush. Walk in too and you find each other.
const CHARGE_TIME := 6.0  ## How long a fountain or a Fresh card lets you tag anyone, on either side of the line.
const SPIKE_CYCLE := 6.0  ## Spikes are up for the last SPIKE_UP seconds of every cycle...
const SPIKE_UP := 1.7
const SPIKE_WARN := 1.0  ## ...and they start to tremble this long before.
const CRUMBLE_DELAY := 1.0  ## How long a crumbling floor lasts once you're on it...
const CRUMBLE_BACK := 8.0  ## ...and how long until it grows back.
const ARM_SPEED := 1.15  ## Radians a second.
const ARM_REACH := 4.6  ## Metres either side of the middle.
const LANE_SPEED := 15.0
const LANE_GAP := 30.0  ## Metres of empty road between one vehicle and the next.
const VEHICLE_HALF := 2.3
const GEYSER_CYCLE := 5.5
const GEYSER_BLOW := 0.55
const STONE_CYCLE := 9.0
const STONE_SUNK := 3.0
const TNT_BACK := 18.0
const TNT_R := 4.6
const WEB_BACK := 11.0
const TIDE_CYCLE := 16.0
const TIDE_HIGH := 6.0
const COUNTDOWN := 3.0
const SCORED_PAUSE := 3.2
const MAX_POWERS := 2
const TEAM_SIZE := 5

enum Phase { COUNTDOWN, PLAY, SCORED, END }
enum State { PLAY, JAIL }

## Statuses that stop you moving.
const HELD := ["stun", "freeze", "root", "dance", "sleep", "bubble", "charging"]
## Bad things Cheer Squad and Rewind shake off.
const SHAKEN_OFF := ["stun", "freeze", "root", "dance", "sleep", "bubble", "slow", "slip", "reverse", "fear", "blind", "stale", "chicken", "mini", "potato", "stink", "tickle", "itch"]
## Short names of statuses in snapshots (index -> name).
const STATUS_NAMES: Array[String] = ["speed", "speed2", "slow", "stun", "freeze", "root", "slip", "reverse", "fear",
	"blind", "shield", "ghost", "invis", "giant", "tiny", "overcharge", "stale", "chain", "mirror", "fastcap",
	"dashboost", "firetrail", "charging", "slam", "roll", "chicken", "dance", "sleep", "carpet", "mini", "bubble", "angel", "orbit", "moon", "turbo", "potato", "stink", "tickle", "itch", "farttrail"]


class Player:
	var id := 0
	var team := 0
	var name := ""
	var bot := false
	var skill := 0.6
	var look := {}  ## The avatar's cosmetics (Cosmetics.gd), for viewers.
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var kb := Vector2.ZERO  ## Knockback, on top of walking.
	var face := Vector2.RIGHT
	var mv := Vector2.ZERO  ## Input: where the stick points, length 0..1.
	var aim := Vector2.ZERO  ## Input: where to aim the next powerup; zero = auto-aim.
	var want_dash := false
	var want_use := false
	var want_mash := false
	var want_skill := -1  ## Input: which skill to use.
	var skills: Array = []  ## Up to two: [skill id, rank].
	var skill_cd: Array[float] = [0.0, 0.0]
	var skills_used := 0
	var attacking := false  ## Over the line: drawing from the attack deck.
	var swap_left := 0.0  ## Crossed the line: every card in hand is spinning into a new one.
	var fresh := 0.0  ## Match time when this player last stood on their own base.
	var on_base := false
	var state := State.PLAY
	var jail_left := 0.0
	var free_until := -1.0  ## Free walk: immune, and can't tag or capture.
	var tag_cd := 0.0
	var dash_cd := 0.0
	var dash_left := 0.0
	var dash_dir := Vector2.RIGHT
	var leap_from := Vector2.ZERO
	var leap_to := Vector2.ZERO
	var leap_t := -1.0  ## 0..1 while in the air, negative on the ground.
	var leap_dur := 0.6
	var pad_cd := 0.0
	var camp := 0.0  ## Seconds on the own base so far.
	var mash_cd := 0.0
	var trail_cd := 0.0
	var powers: Array[String] = []
	var status := {}  ## name -> match time when it ends.
	var fear_from := Vector2.ZERO
	var tags := 0
	var rescues := 0
	var captures := 0
	var times_jailed := 0
	var powers_used := 0
	var bump_cd := 0.0
	var spin_left := 0.0  ## The newest power, while its reel is still spinning.
	var brain := {}  ## The bot's memory (BotBrain.gd).
	var away := false  ## An online player whose connection dropped: a bot plays for them.
	var history: Array[Vector2] = []  ## Where they've been lately, for Rewind.
	var history_cd := 0.0
	var slam_r := 4.6
	var slam_push := 20.0
	var slam_stun := 1.2


var map_id := ""
var w := 0
var h := 0
var tiles := PackedByteArray()
var base: Array = [Vector2.ZERO, Vector2.ZERO]
var jail: Array = [Vector2.ZERO, Vector2.ZERO]
var tele := {}
var players: Array[Player] = []
var t := 0.0
var phase := Phase.COUNTDOWN
var phase_left := COUNTDOWN
var time_left := MATCH_TIME
var overtime := false
var fiesta := false
var score := [0, 0]
var cap := [0.0, 0.0]  ## How far each team's base has been captured, 0..1.
var capturing := [0, 0]  ## How many enemies are capturing each team's base now.
var base_lock := [0.0, 0.0]  ## Match time until which each team's base can't be captured.
var radar := [0.0, 0.0]  ## Match time until which each team sees hidden things.
var pickups: Array[Dictionary] = []  ## {uid, pw, pos, born}
var zones: Array[Dictionary] = []  ## {uid, fx, team, pos, r, until, drift, pw, armed}
var shots: Array[Dictionary] = []  ## {uid, pw, team, owner, pos, vel, r, life, bounces, homing, pierce, hit}
var ents: Array[Dictionary] = []  ## Decoys and sentries: {uid, type, team, owner, pos, vel, until, cd}
var walls := {}  ## Temporary walls: tile -> match time when it falls.
var events: Array = []  ## What happened since the last take_events(): [kind, a, b, x, y, extra].
var wave_until := [0.0, 0.0]  ## Bots: match time until which a team's attack wave runs.
var wave_next := [12.0, 16.0]  ## Bots: match time when each team's next attack wave starts.
var winner := -1  ## Team, or 2 for a draw, once phase is END.
var end_reason := ""
var difficulty := 0.6
var authoritative := true  ## False on online clients: only snapshots move the state.

var rng := RandomNumberGenerator.new()
var _uid := 1
var _spawn_timer := 0.5
var _crystals_wanted := 24
var _last_pickups := PackedFloat32Array()
var _snapshots_since_pickups := 0
var _spawn_side := 0
var _pickup_tiles := PackedInt32Array()
var _flow := {}
var _brain := BotBrain.new()
var _team_cache: Array = [[], []]
var jumps := {}  ## Jump pad tile -> landing box tile.
var fountains := {}  ## Fountain tile -> when it's full again.
var altars := {}  ## Altar tile -> when it grows its next crystal.
var _bumpers := PackedInt32Array()
var _vaulting := false  ## A dash is going over a low fence right now.
var _flying := false  ## A magic carpet is over whatever's below it right now.
var weather := "clear"
var weather_home := "clear"  ## What it goes back to after a Weather Machine.
var weather_until := -1.0
var wind := Vector2.ZERO
var sight_range := 0.0  ## From the weather: how far you can see. 0 is the whole field.
var _wind_goal := Vector2.ZERO
var _wind_left := 2.0
var _strike_left := 3.0
var _grip := 22.0
var _speed_factor := 1.0
var lanes: Array = []  ## Roads: {x, y0, y1, down}.
var arms: Array = []  ## Spinning arms: [{at, dir}].
var crumbles := {}  ## Tile -> when it falls (positive), or -(when it comes back) once it has.
var tnt := {}  ## Tile -> when a blown crate comes back.
var webs := {}  ## Tile -> when a used web grows back.
var last_power := ""  ## For Copycat.
var _potato_cd := 0.0


## seats: [{name, team?, bot, skill, look}], up to 10; missing seats become bots at `difficulty`.
func setup(p_map_id: String, seats: Array, seed_value := 0, p_difficulty := 0.6, p_weather := "") -> void:
	map_id = p_map_id
	difficulty = p_difficulty
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var grid := Maps.build_grid(map_id)
	w = grid["w"]
	h = grid["h"]
	tiles = grid["tiles"]
	base = grid["base"]
	jail = grid["jail"]
	tele = grid["tele"]
	jumps = grid["jumps"]
	lanes = grid["lanes"]
	fountains = {}
	altars = {}
	arms = []
	_bumpers = PackedInt32Array()
	for i in w * h:
		match tiles[i]:
			Maps.FOUNTAIN: fountains[i] = 0.0
			Maps.ALTAR: altars[i] = rng.randf_range(2.0, 8.0)
			Maps.BUMPER: _bumpers.append(i)
			Maps.ARM: arms.append({"at": tile_center(i), "dir": 1.0 if i % w < w / 2 else -1.0})
	set_weather(p_weather if p_weather != "" else Weather.roll(Maps.theme_info(Maps.by_id(map_id).get("theme", "")), rng))
	weather_home = weather
	_collect_pickup_tiles()
	wave_next = [rng.randf_range(10.0, 20.0), rng.randf_range(10.0, 20.0)]
	players.clear()
	for i in TEAM_SIZE * 2:
		var seat: Dictionary = seats[i] if i < seats.size() else {}
		var p := Player.new()
		p.id = i
		p.team = int(seat.get("team", i % 2))
		p.name = str(seat.get("name", "Bot %d" % i))
		p.bot = bool(seat.get("bot", true))
		p.skill = float(seat.get("skill", difficulty))
		p.look = seat.get("look", {})
		p.skills = Skills.from_look(p.look)
		if p.bot and p.skills.is_empty():
			p.skills = Skills.bot_loadout(rng, str(p.look.get("char", "kiko")), p.skill)
		players.append(p)
	_crystals_wanted = clampi(int(arena_size().x * arena_size().y / AREA_PER_CRYSTAL), 20, 44)
	_rebuild_teams()
	_reset_round(true)


## Clears everything off the field but the bases and jails: somewhere plain to show a skill off. Call it before anything's drawn.
func clear_field() -> void:
	for y in h:
		for x in w:
			if x > 0 and y > 0 and x < w - 1 and y < h - 1:
				tiles[y * w + x] = Maps.FLOOR
	fountains = {}
	altars = {}
	arms = []
	lanes = []
	jumps = {}
	tele = {}
	_bumpers = PackedInt32Array()
	_pickup_tiles = PackedInt32Array()
	_flow = {}
	pickups.clear()


func _rebuild_teams() -> void:
	_team_cache = [[], []]
	for p in players:
		_team_cache[p.team].append(p)


func team_of(team: int) -> Array:
	return _team_cache[team]


func player_by_id(id: int) -> Player:
	return players[id] if id >= 0 and id < players.size() else null


func _collect_pickup_tiles() -> void:
	_pickup_tiles = PackedInt32Array()
	for y in h:
		for x in w:
			var code := tiles[y * w + x]
			if code in [Maps.FLOOR, Maps.GRASS, Maps.ICE, Maps.MUD, Maps.LAND]:
				var at := tile_center(y * w + x)
				if at.distance_to(base[0]) > BASE_R + 3.0 and at.distance_to(base[1]) > BASE_R + 3.0 \
						and at.distance_to(jail[0]) > JAIL_R + 1.0 and at.distance_to(jail[1]) > JAIL_R + 1.0:
					_pickup_tiles.append(y * w + x)


func _reset_round(first := false) -> void:
	for team in 2:
		var mates: Array = team_of(team)
		for i in mates.size():
			var p: Player = mates[i]
			p.state = State.PLAY
			p.pos = _spawn_point(team, i, mates.size())
			p.vel = Vector2.ZERO
			p.kb = Vector2.ZERO
			p.face = Vector2.RIGHT if team == 0 else Vector2.LEFT
			p.fresh = t
			p.on_base = true
			p.free_until = -1.0
			p.dash_left = 0.0
			p.leap_t = -1.0
			p.tag_cd = 0.0
			p.dash_cd = 0.0
			p.attacking = false
			p.swap_left = 0.0
			p.skill_cd[0] = 0.0
			p.skill_cd[1] = 0.0
			p.status.clear()
			p.brain.clear()
			p.history.clear()
	cap = [0.0, 0.0]
	capturing = [0, 0]
	zones.clear()
	shots.clear()
	ents.clear()
	walls.clear()
	crumbles.clear()
	tnt.clear()
	webs.clear()
	if first:
		pickups.clear()
		for _i in START_CRYSTALS:
			_spawn_pickup()


func _spawn_point(team: int, i: int, count: int) -> Vector2:
	var angle := TAU * float(i) / maxf(count, 1)
	return base[team] + Vector2.RIGHT.rotated(angle) * 2.2


# --- Map queries ----------------------------------------------------------------------------------

func tile_center(i: int) -> Vector2:
	return Vector2((i % w + 0.5) * Maps.TILE, (i / w + 0.5) * Maps.TILE)


func tile_index(at: Vector2) -> int:
	var x := int(floor(at.x / Maps.TILE))
	var y := int(floor(at.y / Maps.TILE))
	if x < 0 or y < 0 or x >= w or y >= h:
		return -1
	return y * w + x


func tile_at(at: Vector2) -> int:
	var i := tile_index(at)
	return tiles[i] if i >= 0 else Maps.SOLID


func _blocks_feet(i: int) -> bool:
	match tiles[i]:
		Maps.SOLID, Maps.ARM:
			return true
		Maps.PIT, Maps.BUMPER:
			if not _flying:
				return true
		Maps.GATE:
			if gates_shut():
				return true
		Maps.FENCE:
			if not _vaulting and not _flying:
				return true
		Maps.TNT:
			if tnt_here(i):
				return true
		Maps.STONE:
			if not _flying and stone_sunk(i):
				return true
		Maps.CRUMBLE:
			if not _flying and crumble_gone(i):
				return true
	return walls.has(i) and walls[i] > t


func _blocks_shots(i: int) -> bool:
	match tiles[i]:
		Maps.SOLID, Maps.ARM:
			return true
		Maps.GATE:
			if gates_shut():
				return true
		Maps.TNT:
			if tnt_here(i):
				return true
	return walls.has(i) and walls[i] > t


func spikes_up() -> bool:
	return fmod(t, SPIKE_CYCLE) >= SPIKE_CYCLE - SPIKE_UP


func spikes_warning() -> bool:
	var at := fmod(t, SPIKE_CYCLE)
	return at >= SPIKE_CYCLE - SPIKE_UP - SPIKE_WARN and at < SPIKE_CYCLE - SPIKE_UP


func crumble_gone(i: int) -> bool:
	return float(crumbles.get(i, 0.0)) < 0.0


## 0 solid, up to 1 about to go.
func crumble_shake(i: int) -> float:
	var at := float(crumbles.get(i, 0.0))
	return clampf(1.0 - (at - t) / CRUMBLE_DELAY, 0.0, 1.0) if at > 0.0 else 0.0


func tnt_here(i: int) -> bool:
	return float(tnt.get(i, -1.0)) <= t


func web_here(i: int) -> bool:
	return float(webs.get(i, -1.0)) <= t


## Stones take it in turns: every other one is up.
func stone_sunk(i: int) -> bool:
	var turn := STONE_CYCLE * 0.5 if (i % w + i / w) % 2 == 0 else 0.0
	return fmod(t + turn, STONE_CYCLE) >= STONE_CYCLE - STONE_SUNK


func stone_warning(i: int) -> bool:
	var turn := STONE_CYCLE * 0.5 if (i % w + i / w) % 2 == 0 else 0.0
	var at := fmod(t + turn, STONE_CYCLE)
	return at >= STONE_CYCLE - STONE_SUNK - 1.0 and at < STONE_CYCLE - STONE_SUNK


func geyser_blowing(i: int) -> bool:
	return fmod(t + float(i % 3) * 1.7, GEYSER_CYCLE) < GEYSER_BLOW


func geyser_warning(i: int) -> bool:
	return fmod(t + float(i % 3) * 1.7, GEYSER_CYCLE) >= GEYSER_CYCLE - 1.2


func tide_high() -> bool:
	return fmod(t, TIDE_CYCLE) >= TIDE_CYCLE - TIDE_HIGH


## How far in the sea is, 0 to 1, for drawing: it comes in and goes out over a second or two.
func tide_level() -> float:
	var at := fmod(t, TIDE_CYCLE)
	var from := TIDE_CYCLE - TIDE_HIGH
	return clampf((at - from + 1.5) / 1.5, 0.0, 1.0) * clampf((TIDE_CYCLE - at + 0.0) / 1.2 + 0.0, 0.0, 1.0)


func arm_angle(arm: Dictionary) -> float:
	return t * ARM_SPEED * float(arm["dir"])


## Where the vehicle on this lane has got to, down the road.
func lane_at(lane: Dictionary) -> float:
	var span: float = float(lane["y1"]) - float(lane["y0"])
	var loop: float = span + LANE_GAP
	var run := fmod(t * LANE_SPEED + float(lane["x"]) * 3.0, loop) - VEHICLE_HALF
	return float(lane["y0"]) + run if lane["down"] else float(lane["y1"]) - run


func set_weather(id: String) -> void:
	weather = id if Weather.ALL.has(id) else "clear"
	var def := Weather.def(weather)
	sight_range = float(def["sight"])
	_grip = float(def["grip"])
	_speed_factor = float(def["speed"])
	if float(def["wind"]) <= 0.0:
		_wind_goal = Vector2.ZERO
	_wind_left = 0.0


## Every gate on the field moves together, so you can learn the beat.
func gates_shut() -> bool:
	return fmod(t, GATE_CYCLE) < GATE_SHUT


## Seconds until the gates next move.
func gates_change_in() -> float:
	var at := fmod(t, GATE_CYCLE)
	return GATE_SHUT - at if at < GATE_SHUT else GATE_CYCLE - at


func fountain_ready(i: int) -> bool:
	return float(fountains.get(i, INF)) <= t


func arena_size() -> Vector2:
	return Vector2(w, h) * Maps.TILE


## True when a straight line from a to b crosses nothing that stops feet.
func clear_line(a: Vector2, b: Vector2, for_shot := false) -> bool:
	var d := a.distance_to(b)
	var steps := int(ceil(d / (Maps.TILE * 0.45)))
	for s in range(1, steps + 1):
		var i := tile_index(a.lerp(b, float(s) / steps))
		if i < 0:
			return false
		if (for_shot and _blocks_shots(i)) or (not for_shot and _blocks_feet(i)):
			return false
	return true


## Bots go round all of this: what stops feet, and what they'd rather not step on unless they mean to.
const BOT_KEEPS_OFF := [Maps.SOLID, Maps.PIT, Maps.BUMPER, Maps.FENCE, Maps.DASH_R, Maps.DASH_L, Maps.DASH_U, Maps.DASH_D, Maps.JUMP,
	Maps.ARM, Maps.TNT, Maps.STONE, Maps.SPIKES, Maps.GEYSER, Maps.QUICKSAND, Maps.WEB]


## Distances (in tiles) from every tile to tile `target`, walking; cached for the whole match.
func flow_field(target: int) -> PackedInt32Array:
	if _flow.has(target):
		return _flow[target]
	var dist := PackedInt32Array()
	dist.resize(w * h)
	dist.fill(-1)
	if target < 0 or target >= w * h:
		return dist
	var queue := PackedInt32Array([target])
	dist[target] = 0
	var head := 0
	while head < queue.size():
		var i := queue[head]
		head += 1
		var x := i % w
		var y := i / w
		var next := dist[i] + 1
		for n in 4:
			var nx: int = x + (1 if n == 0 else -1 if n == 1 else 0)
			var ny: int = y + (1 if n == 2 else -1 if n == 3 else 0)
			if nx < 0 or ny < 0 or nx >= w or ny >= h:
				continue
			var ni := ny * w + nx
			if dist[ni] >= 0:
				continue
			var code := tiles[ni]
			# Bots walk round anything that throws them about; they choose to use those (see BotBrain).
			if code in BOT_KEEPS_OFF:
				continue
			dist[ni] = next
			queue.append(ni)
	_flow[target] = dist
	return dist


# --- Fresher rule ---------------------------------------------------------------------------------

## The line down the middle decides who tags who. On your own side your clock never runs, so you always out-fresh an
## invader: touch them and they go to jail. Cross the line and it starts: anyone at home can tag you.
func on_home_side(p: Player) -> bool:
	return (p.pos.x < arena_size().x * 0.5) == (p.team == 0)


## Charged by a fountain or a card: you can tag anyone, wherever you are.
func is_charged(p: Player) -> bool:
	return p.fresh > t


func has_status(p: Player, name: String) -> bool:
	return float(p.status.get(name, -1.0)) > t


func fresh_value(p: Player) -> float:
	if has_status(p, "overcharge"):
		return t + 100000.0
	if has_status(p, "stale"):
		return -100000.0 + p.fresh
	return p.fresh


func is_free_walking(p: Player) -> bool:
	return p.free_until > t


func is_airborne(p: Player) -> bool:
	return p.leap_t >= 0.0


## Can `a` tag `b` right now, if they touch?
func can_tag(a: Player, b: Player) -> bool:
	if a.team == b.team or a.state != State.PLAY or b.state != State.PLAY:
		return false
	if b.on_base or is_free_walking(a) or is_free_walking(b):
		return false
	if has_status(a, "ghost") or has_status(b, "ghost") or is_airborne(a) or is_airborne(b):
		return false
	if has_status(a, "chicken") or has_status(a, "roll") or has_status(b, "roll") or has_status(a, "bubble") or has_status(b, "bubble"):
		return false
	return fresh_value(a) > fresh_value(b)


func radius_of(p: Player) -> float:
	if has_status(p, "giant"):
		return RADIUS * 1.7
	if has_status(p, "tiny") or has_status(p, "mini"):
		return RADIUS * 0.6
	return RADIUS


func speed_of(p: Player) -> float:
	var s := SPEED * (0.9 + 0.1 * p.skill if p.bot else 1.0)
	if has_status(p, "speed"):
		s *= 1.6
	elif has_status(p, "speed2"):
		s *= 1.3
	if has_status(p, "tiny"):
		s *= 1.25
	if has_status(p, "giant"):
		s *= 0.92
	if has_status(p, "slow"):
		s *= 0.5
	if has_status(p, "stink"):
		s *= 0.85
	if has_status(p, "tickle"):
		s *= 0.5
	if has_status(p, "mini"):
		s *= 0.72
	if has_status(p, "turbo"):
		s *= 1.8
	if has_status(p, "roll"):
		s *= 1.7
	if has_status(p, "carpet"):
		s *= 1.25
	elif not has_status(p, "ghost"):
		match tile_at(p.pos):
			Maps.MUD:
				s *= 0.6
			Maps.QUICKSAND:
				s *= 0.46
			Maps.TIDE:
				if tide_high():
					s *= 0.55
	return s * _speed_factor


func is_held(p: Player) -> bool:
	for name: String in HELD:
		if has_status(p, name):
			return true
	return has_status(p, "itch") and fmod(t, ITCH_CYCLE) < ITCH_STOP


## Hidden from `team`'s eyes? (Invisible, or deep in tall grass with nobody close.)
func is_hidden_from(p: Player, team: int) -> bool:
	if p.team == team or radar[team] > t or p.state != State.PLAY:
		return false
	if has_status(p, "invis"):
		return true
	if has_status(p, "potato") or has_status(p, "stink") or _under_cloud(p):  # Nobody can hide with a hot potato, or their own personal cloud, or that smell.
		return false
	var nearest := INF
	for other: Player in team_of(team):
		if other.state == State.PLAY:
			nearest = minf(nearest, other.pos.distance_to(p.pos))
	if nearest >= BUSH_SIGHT and (tile_at(p.pos) == Maps.GRASS or _in_smoke(p)):
		return true
	return sight_range > 0.0 and nearest > sight_range


func _in_smoke(p: Player) -> bool:
	for z: Dictionary in zones:
		if z["fx"] == "smoke" and int(z["team"]) == p.team and p.pos.distance_to(z["pos"]) < float(z["r"]):
			return true
	return false


func _under_cloud(p: Player) -> bool:
	for z: Dictionary in zones:
		if z["fx"] == "cloud" and int(z.get("target", -1)) == p.id:
			return true
	return false


# --- The tick -------------------------------------------------------------------------------------

func step(dt: float = TICK) -> void:
	t += dt
	match phase:
		Phase.COUNTDOWN:
			phase_left -= dt
			for p in players:
				p.want_dash = false
				p.want_use = false
			if phase_left <= 0.0:
				phase = Phase.PLAY
				_event("go")
			return
		Phase.SCORED:
			phase_left -= dt
			if phase_left <= 0.0:
				_reset_round()
				phase = Phase.COUNTDOWN
				phase_left = 2.0
				_event("round")
			return
		Phase.END:
			return
	_tick_clock(dt)
	if phase != Phase.PLAY:
		return
	_tick_weather(dt)
	for p in players:
		if p.bot or p.away:
			_brain.think(self, p, dt)
	for p in players:
		_tick_player(p, dt)
	_separate_mates()
	_resolve_tags()
	_tick_rescues()
	if phase == Phase.PLAY:
		_tick_capture(dt)
	_tick_pickups(dt)
	_tick_shots(dt)
	_tick_zones(dt)
	_tick_ents(dt)
	_tick_walls()
	_tick_hazards(dt)
	if phase == Phase.PLAY:
		_check_wipeout()


func _tick_clock(dt: float) -> void:
	time_left -= dt
	if not fiesta and time_left <= FIESTA_AT and not overtime:
		fiesta = true
		_event("fiesta")
	if time_left > 0.0:
		return
	if score[0] != score[1]:
		_finish(0 if score[0] > score[1] else 1, "time")
	elif overtime:
		# As in the old game, more prisoners taken wins when time runs out.
		var tags := [0, 0]
		for p in players:
			tags[p.team] += p.tags
		if tags[0] == tags[1]:
			_finish(2, "draw")
		else:
			_finish(0 if tags[0] > tags[1] else 1, "tags")
	else:
		overtime = true
		fiesta = true
		time_left = OVERTIME
		_event("overtime")


func _finish(team: int, reason: String) -> void:
	winner = team
	end_reason = reason
	phase = Phase.END
	_event("end", team)


func _award_point(team: int, reason: String, who := -1) -> void:
	score[team] += 1
	_event("score", team, who, base[1 - team].x, base[1 - team].y, reason)
	if score[team] >= WIN_POINTS or overtime:
		_finish(team, reason)
	else:
		phase = Phase.SCORED
		phase_left = SCORED_PAUSE


func _event(kind: String, a := -1, b := -1, x := 0.0, y := 0.0, extra: Variant = "") -> void:
	events.append([kind, a, b, x, y, extra])


func take_events() -> Array:
	var out := events
	events = []
	return out


# --- Players --------------------------------------------------------------------------------------

func _tick_player(p: Player, dt: float) -> void:
	_expire_statuses(p)
	p.tag_cd = maxf(p.tag_cd - dt, 0.0)
	p.dash_cd = maxf(p.dash_cd - dt * (6.0 if has_status(p, "dashboost") else 1.0), 0.0)
	p.pad_cd = maxf(p.pad_cd - dt, 0.0)
	p.bump_cd = maxf(p.bump_cd - dt, 0.0)
	p.mash_cd = maxf(p.mash_cd - dt, 0.0)
	p.spin_left = maxf(p.spin_left - dt, 0.0)
	p.swap_left = maxf(p.swap_left - dt, 0.0)
	p.skill_cd[0] = maxf(p.skill_cd[0] - dt, 0.0)
	p.skill_cd[1] = maxf(p.skill_cd[1] - dt, 0.0)
	if p.state == State.JAIL:
		_tick_jailed(p, dt)
		return
	if p.want_dash and p.dash_cd <= 0.0 and not is_held(p) and not is_airborne(p) and not has_status(p, "chicken") and not has_status(p, "roll"):
		_start_dash(p)
	p.want_dash = false
	if p.want_use and can_use_power(p) and not is_held(p) and not is_airborne(p) and not has_status(p, "chicken"):
		_use_power(p)
	p.want_use = false
	if p.want_skill >= 0 and can_use_skill(p, p.want_skill) and not is_held(p) and not is_airborne(p) and not has_status(p, "chicken"):
		_use_skill(p, p.want_skill)
	p.want_skill = -1
	_move(p, dt)
	_check_mode(p)
	p.history_cd -= dt
	if p.history_cd <= 0.0:
		p.history_cd = 0.25
		p.history.append(p.pos)
		if p.history.size() > 16:
			p.history.remove_at(0)
	if on_home_side(p) and not is_airborne(p):
		p.fresh = maxf(p.fresh, t)
	var home_d: float = p.pos.distance_to(base[p.team])
	var was_on := p.on_base
	p.on_base = home_d < BASE_R and not is_airborne(p)
	if p.on_base:
		if p.free_until > t:
			p.free_until = -1.0
		if not was_on:
			_event("home", p.id)
		p.camp += dt
		if p.camp >= CAMP_LIMIT:
			_pop_off_base(p)
	else:
		p.camp = 0.0
	if has_status(p, "farttrail"):
		p.trail_cd -= dt
		if p.trail_cd <= 0.0:
			p.trail_cd = 0.3
			zones.append({"uid": _next_uid(), "fx": "fart", "team": p.team, "pos": p.pos, "r": 1.7, "until": t + 2.4, "drift": Vector2.ZERO, "pw": "bean_burrito", "armed": true})
	if has_status(p, "firetrail"):
		p.trail_cd -= dt
		if p.trail_cd <= 0.0:
			p.trail_cd = 0.22
			zones.append({"uid": _next_uid(), "fx": "fire", "team": p.team, "pos": p.pos, "r": 1.0, "until": t + 3.0, "drift": Vector2.ZERO, "pw": "hot_trail", "armed": true})


## Over the line you're attacking, and back on your side you're defending. Change over and your hand goes back in the deck:
## any card from the other deck spins into one from this one.
func _check_mode(p: Player) -> void:
	if is_airborne(p):
		return
	var past: float = (p.pos.x - arena_size().x * 0.5) * (1.0 if p.team == 0 else -1.0)
	var now := p.attacking
	if past > MODE_MARGIN:
		now = true
	elif past < -MODE_MARGIN:
		now = false
	if now == p.attacking:
		return
	p.attacking = now
	var changed := false
	for i in p.powers.size():
		if Powerups.side_of(p.powers[i]) != deck_of(p):
			p.powers[i] = Powerups.roll(rng, deck_of(p))
			changed = true
	if changed:
		p.swap_left = SPIN_TIME
		_event("reshuffle", p.id, -1, p.pos.x, p.pos.y)


func deck_of(p: Player) -> String:
	return Powerups.ATTACK if p.attacking else Powerups.DEFEND


## Campers get launched toward the middle of the field; they land fresh, just off the base.
func _pop_off_base(p: Player) -> void:
	p.camp = 0.0
	var home: Vector2 = base[p.team]
	var out := arena_size() * 0.5 - home
	out = out.normalized().rotated(rng.randf_range(-1.1, 1.1))
	var to := (home + out * (BASE_R + 4.0)).clamp(Vector2.ONE, arena_size() - Vector2.ONE)
	_launch(p, to, 0.55)
	p.on_base = false
	_event("pop", p.id, -1, p.pos.x, p.pos.y)


func _expire_statuses(p: Player) -> void:
	if p.status.is_empty():
		return
	for name: String in p.status.keys():
		if float(p.status[name]) <= t:
			p.status.erase(name)
			if name == "ghost" or name == "giant" or name == "carpet":
				_unstick(p)
			elif name == "potato":
				_potato_bang(p)


func _tick_jailed(p: Player, dt: float) -> void:
	p.jail_left -= dt
	if p.want_mash and p.mash_cd <= 0.0:
		p.mash_cd = MASH_GAP
		p.jail_left -= MASH_SAVE
	p.want_mash = false
	p.want_dash = false
	p.want_use = false
	p.want_skill = -1
	if p.jail_left <= 0.0:
		_send_home(p)


func _send_home(p: Player) -> void:
	p.state = State.PLAY
	p.pos = _spawn_point(p.team, p.id, TEAM_SIZE)
	p.vel = Vector2.ZERO
	p.kb = Vector2.ZERO
	p.fresh = t
	p.on_base = true
	p.free_until = -1.0
	p.status.clear()
	_event("respawn", p.id)


func _start_dash(p: Player) -> void:
	var dir := p.mv if p.mv.length() > 0.2 else p.face
	if has_status(p, "reverse"):
		dir = -dir
	p.dash_dir = dir.normalized()
	p.dash_cd = DASH_COOLDOWN * float(Weather.def(weather)["dash"])
	p.status.erase("invis")
	if has_status(p, "moon"):
		_launch(p, (p.pos + p.dash_dir * 8.0).clamp(Vector2.ONE, arena_size() - Vector2.ONE), 0.55)
		_event("jump", p.id, -1, p.pos.x, p.pos.y)
		return
	p.dash_left = DASH_TIME
	_event("dash", p.id, -1, p.pos.x, p.pos.y)


func _move(p: Player, dt: float) -> void:
	if is_airborne(p):
		p.leap_t += dt / maxf(p.leap_dur, 0.05)
		p.pos = p.leap_from.lerp(p.leap_to, minf(p.leap_t, 1.0))
		p.vel = Vector2.ZERO
		if p.leap_t >= 1.0:
			p.leap_t = -1.0
			p.pad_cd = 0.6
			_unstick(p)
			_event("land", p.id, -1, p.pos.x, p.pos.y)
			if has_status(p, "slam"):
				p.status.erase("slam")
				_blast(p.pos, p.slam_r, p.slam_push, p.slam_stun, p.team, p)
		return
	var input := p.mv.limit_length(1.0)
	if has_status(p, "reverse"):
		input = -input
	if has_status(p, "tickle"):
		input = input.rotated(sin(t * 9.0) * 1.1)
	if has_status(p, "fear"):
		input = (p.pos - p.fear_from).normalized()
	if is_held(p):
		input = Vector2.ZERO
	var code := tile_at(p.pos)
	var ghost := has_status(p, "ghost")
	var flying := has_status(p, "carpet")
	var slippery := (code == Maps.ICE or has_status(p, "slip") or has_status(p, "turbo")) and not ghost and not flying
	var desired := input * speed_of(p)
	if p.dash_left > 0.0:
		p.dash_left -= dt
		p.vel = p.dash_dir * DASH_SPEED
	else:
		p.vel = p.vel.lerp(desired, clampf((3.0 if slippery else _grip) * dt, 0.0, 1.0))
	if input.length() > 0.1 and not is_held(p):
		p.face = p.face.slerp(input.normalized(), clampf(16.0 * dt, 0.0, 1.0)).normalized()
	var total := p.vel + p.kb
	if not ghost and not flying:
		match code:
			Maps.CON_R: total.x += 5.0
			Maps.CON_L: total.x -= 5.0
			Maps.CON_U: total.y -= 5.0
			Maps.CON_D: total.y += 5.0
			Maps.QUICKSAND:  # It drags you to the middle of whichever bit you're in; a dash gets you out.
				total += (tile_center(tile_index(p.pos)) - p.pos).limit_length(1.0) * 4.5
	if not p.on_base:
		total += wind
	p.kb *= exp(-7.0 * dt)
	if p.kb.length() < 0.05:
		p.kb = Vector2.ZERO
	_vaulting = p.dash_left > 0.0
	_flying = flying
	p.pos = move_circle(p.pos, total * dt, radius_of(p), ghost)
	_flying = false
	_vaulting = false
	if p.dash_left > 0.0:
		_dash_into_crates(p)
	if ghost or flying:
		return
	_touch_bumpers(p)
	var here := tile_index(p.pos)
	if here < 0:
		return
	_touch_floor(p, here)
	if p.pad_cd > 0.0:
		return
	match tiles[here]:
		Maps.DASH_R: _floor_dash(p, Vector2.RIGHT)
		Maps.DASH_L: _floor_dash(p, Vector2.LEFT)
		Maps.DASH_U: _floor_dash(p, Vector2.UP)
		Maps.DASH_D: _floor_dash(p, Vector2.DOWN)
		Maps.JUMP:
			if jumps.has(here):
				var land := tile_center(jumps[here])
				_launch(p, land, clampf(p.pos.distance_to(land) / 15.0, 0.6, 1.2))
				_event("jump", p.id, -1, p.pos.x, p.pos.y)
		Maps.FOUNTAIN:
			if fountain_ready(here):
				fountains[here] = t + FOUNTAIN_REFILL
				p.fresh = t + CHARGE_TIME
				_event("fountain", p.id, -1, p.pos.x, p.pos.y)
	if tiles[here] == Maps.BOUNCE:
		_launch(p, tile_center(_mirror_tile(here)), 0.8)
		_event("bounce", p.id, -1, p.pos.x, p.pos.y)
	elif tiles[here] == Maps.TELE and tele.has(here):
		var out: int = tele[here]
		p.pos = tile_center(out)
		p.pad_cd = 1.0
		_event("warp", p.id, -1, p.pos.x, p.pos.y)


func _floor_dash(p: Player, dir: Vector2) -> void:
	p.dash_dir = dir
	p.dash_left = FLOOR_DASH_TIME
	p.pad_cd = 0.14
	p.status.erase("invis")
	_event("boost", p.id, -1, p.pos.x, p.pos.y)


## What the floor does to you just for being on it, however you got there.
func _touch_floor(p: Player, here: int) -> void:
	match tiles[here]:
		Maps.SPIKES:
			if spikes_up() and p.bump_cd <= 0.0 and not p.on_base:
				p.bump_cd = 0.8
				p.kb += p.vel.normalized() * -9.0
				_apply_cc(p, {"stun": 0.8}, null)
				_event("spiked", p.id, -1, p.pos.x, p.pos.y)
		Maps.CRUMBLE:
			if not crumbles.has(here):
				crumbles[here] = t + CRUMBLE_DELAY
				var at := tile_center(here)
				_event("crack", -1, -1, at.x, at.y)
		Maps.GEYSER:
			if geyser_blowing(here) and p.pad_cd <= 0.0:
				var to := _free_spot_near(p.pos, 6.0, 11.0)
				_launch(p, to, 0.8)
				_event("geyser", p.id, -1, p.pos.x, p.pos.y)
		Maps.WEB:
			if web_here(here):
				webs[here] = t + WEB_BACK
				_apply_cc(p, {"root": 1.3}, null)
				_event("webbed", p.id, -1, p.pos.x, p.pos.y)
		Maps.TOWER:
			if float(radar[p.team]) < t:
				_event("lookout", p.id, p.team, p.pos.x, p.pos.y)
			radar[p.team] = maxf(float(radar[p.team]), t + 1.0)


func _free_spot_near(at: Vector2, near: float, far: float) -> Vector2:
	for _try in 16:
		var spot: Vector2 = at + Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(near, far)
		var i := tile_index(spot)
		if i >= 0 and not _blocks_feet(i) and tiles[i] not in [Maps.GEYSER, Maps.SPIKES, Maps.CRUMBLE, Maps.ROAD]:
			return tile_center(i)
	return at


func _dash_into_crates(p: Player) -> void:
	var ahead := tile_index(p.pos + p.dash_dir * (radius_of(p) + 0.35))
	if ahead >= 0 and tiles[ahead] == Maps.TNT and tnt_here(ahead):
		_blow_crate(ahead)


## Up it goes, along with anyone next to it, on either team, and any other crate close enough.
func _blow_crate(tile: int) -> void:
	tnt[tile] = t + TNT_BACK
	var at := tile_center(tile)
	_event("boom", -1, -1, at.x, at.y)
	_blast(at, TNT_R, 20.0, 1.0, -1, null)
	for other in w * h:
		if tiles[other] == Maps.TNT and tnt_here(other) and tile_center(other).distance_to(at) < TNT_R:
			_blow_crate(other)


## Knocks away and stuns everyone in reach. `team` is who it's on the side of; -1 means nobody's safe.
func _blast(at: Vector2, reach: float, push: float, stun: float, team: int, from: Player) -> void:
	_event("boom", -1, -1, at.x, at.y)
	for e: Player in players:
		if e.team == team or e.state != State.PLAY or is_airborne(e) or e.on_base or has_status(e, "ghost") or is_free_walking(e):
			continue
		var d := e.pos.distance_to(at)
		if d < reach + radius_of(e) * 0.5:
			_apply_cc(e, {"stun": stun}, from)
			if not has_status(e, "mirror"):
				e.kb += (e.pos - at).normalized() * push


## Everything on the field that moves by itself.
func _tick_hazards(dt: float) -> void:
	_potato_cd = maxf(_potato_cd - dt, 0.0)
	for tile: int in crumbles.keys():
		var at := float(crumbles[tile])
		if at > 0.0 and t >= at:
			crumbles[tile] = -(t + CRUMBLE_BACK)
			var spot := tile_center(tile)
			_event("crumble", -1, -1, spot.x, spot.y)
		elif at < 0.0 and t >= -at:
			crumbles.erase(tile)
	for p: Player in players:
		if p.state != State.PLAY or is_airborne(p):
			continue
		var ghost := has_status(p, "ghost")
		var here := tile_index(p.pos)
		_flying = has_status(p, "carpet")
		if not ghost and here >= 0 and _blocks_feet(here) and tiles[here] in [Maps.STONE, Maps.CRUMBLE]:
			_unstick(p)
			_apply_cc(p, {"stun": 0.6}, null)
			_event("fell", p.id, -1, p.pos.x, p.pos.y)
		_flying = false
		if has_status(p, "roll"):
			_roll_over(p)
		if has_status(p, "orbit"):
			_orbit_shove(p)
		if has_status(p, "potato") and _potato_cd <= 0.0:
			_pass_potato(p)
		if ghost or p.on_base or is_free_walking(p) or p.bump_cd > 0.0:
			continue
		_touch_arms(p)
		_touch_traffic(p)


func _touch_arms(p: Player) -> void:
	for arm: Dictionary in arms:
		var center: Vector2 = arm["at"]
		var d := p.pos - center
		if d.length() > ARM_REACH + radius_of(p):
			continue
		var along := Vector2.RIGHT.rotated(arm_angle(arm))
		if absf(d.cross(along)) < radius_of(p) + 0.34:
			var way := along.orthogonal() * (1.0 if d.dot(along.orthogonal()) > 0.0 else -1.0)
			p.kb += way * 22.0
			p.bump_cd = 0.7
			_apply_cc(p, {"stun": 0.4}, null)
			_event("bonk", p.id, -1, p.pos.x, p.pos.y)
			return


func _touch_traffic(p: Player) -> void:
	for lane: Dictionary in lanes:
		if absf(p.pos.x - float(lane["x"])) > 1.1 + radius_of(p):
			continue
		if absf(p.pos.y - lane_at(lane)) < VEHICLE_HALF + radius_of(p):
			var side := 1.0 if p.pos.x >= float(lane["x"]) else -1.0
			p.kb += Vector2(side * 20.0, 12.0 if lane["down"] else -12.0)
			p.bump_cd = 1.2
			_apply_cc(p, {"stun": 1.0}, null)
			_event("run_over", p.id, -1, p.pos.x, p.pos.y)
			return


func _roll_over(p: Player) -> void:
	for e: Player in team_of(1 - p.team):
		if e.state != State.PLAY or is_airborne(e) or e.on_base or has_status(e, "ghost") or is_free_walking(e):
			continue
		if e.pos.distance_to(p.pos) < radius_of(p) + radius_of(e) + 0.25 and float(e.status.get("burnt", -1.0)) <= t:
			e.status["burnt"] = t + 1.0
			e.kb += (e.pos - p.pos).normalized() * 22.0
			_apply_cc(e, {"stun": 0.8}, p)
			_event("hit", e.id, p.id, e.pos.x, e.pos.y, "cannonball")


func _orbit_shove(p: Player) -> void:
	for e: Player in team_of(1 - p.team):
		if e.state != State.PLAY or is_airborne(e) or e.on_base or has_status(e, "ghost") or is_free_walking(e):
			continue
		if e.pos.distance_to(p.pos) < 2.5 and float(e.status.get("burnt", -1.0)) <= t:
			e.status["burnt"] = t + 0.9
			e.kb += (e.pos - p.pos).normalized() * 20.0
			_apply_cc(e, {"stun": 0.5}, p)
			_event("hit", e.id, p.id, e.pos.x, e.pos.y, "orbit_shields")


func _pass_potato(p: Player) -> void:
	for other: Player in players:
		if other == p or other.state != State.PLAY or is_airborne(other) or other.on_base or is_free_walking(other):
			continue
		if other.pos.distance_to(p.pos) < radius_of(p) + radius_of(other) + 0.3:
			other.status["potato"] = p.status["potato"]
			p.status.erase("potato")
			_potato_cd = 0.7
			_event("potato", other.id, p.id, other.pos.x, other.pos.y)
			return


func _potato_bang(p: Player) -> void:
	if p.state == State.PLAY:
		_blast(p.pos, 3.0, 18.0, 2.0, -1, null)
		_apply_cc(p, {"stun": 2.0}, null)


func _tick_weather(dt: float) -> void:
	if weather_until > 0.0 and t >= weather_until:
		weather_until = -1.0
		set_weather(weather_home)
		_event("weather", -1, -1, 0.0, 0.0, weather)
	var def := Weather.def(weather)
	var strength := float(def["wind"])
	_wind_left -= dt
	if strength > 0.0 and _wind_left <= 0.0:
		_wind_left = rng.randf_range(7.0, 13.0)
		_wind_goal = Vector2.RIGHT.rotated(rng.randf() * TAU) * strength
	wind = wind.lerp(_wind_goal, clampf(dt * 1.1, 0.0, 1.0))
	var every := float(def["strike"])
	if every > 0.0:
		_strike_left -= dt
		if _strike_left <= 0.0:
			_strike_left = every * rng.randf_range(0.7, 1.3)
			_weather_strike()


## Somewhere near someone, more often than not, so you do have to keep an eye on the sky.
func _weather_strike() -> void:
	var at := Vector2(rng.randf_range(2.0, arena_size().x - 2.0), rng.randf_range(2.0, arena_size().y - 2.0))
	if rng.randf() < 0.6:
		var p: Player = players[rng.randi_range(0, players.size() - 1)]
		if p.state == State.PLAY:
			at = p.pos + p.vel * 0.7 + Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(0.0, 2.2)
	at = at.clamp(Vector2.ONE, arena_size() - Vector2.ONE)
	zones.append({"uid": _next_uid(), "fx": "strike", "team": -1, "pos": at, "r": 2.4, "until": t + 1.35, "drift": Vector2.ZERO, "pw": "", "armed": true})


## A bumper knocks anyone who touches it flying, straight away from it.
func _touch_bumpers(p: Player) -> void:
	for i in _bumpers:
		var c := tile_center(i)
		var reach := Maps.TILE * 0.5 + radius_of(p) + 0.12
		var d := p.pos - c
		if absf(d.x) < reach and absf(d.y) < reach and d.length() < reach * 1.3 and p.bump_cd <= 0.0:
			p.kb = (d.normalized() if d.length() > 0.01 else Vector2.RIGHT) * BUMPER_KICK
			p.dash_left = 0.0
			p.bump_cd = 0.28
			_event("bump", p.id, -1, c.x, c.y)


func _mirror_tile(i: int) -> int:
	var x := i % w
	var y := i / w
	var rot: bool = Maps.LAYOUTS[Maps.by_id(map_id)["layout"]]["mirror"] == "rot"
	return (h - 1 - y if rot else y) * w + (w - 1 - x)


func _launch(p: Player, to: Vector2, duration: float) -> void:
	p.leap_from = p.pos
	p.leap_to = to
	p.leap_t = 0.0
	p.leap_dur = duration
	p.dash_left = 0.0


## Moves a circle by `delta`, sliding along walls; `ghost` ignores everything but the arena's edge.
func move_circle(at: Vector2, delta: Vector2, r: float, ghost := false) -> Vector2:
	var next := at + delta
	if not ghost:
		next = _push_out(next, r)
		next = _push_out(next, r)
	return next.clamp(Vector2(r, r), arena_size() - Vector2(r, r))


func _push_out(at: Vector2, r: float) -> Vector2:
	var x0 := int(floor((at.x - r) / Maps.TILE))
	var x1 := int(floor((at.x + r) / Maps.TILE))
	var y0 := int(floor((at.y - r) / Maps.TILE))
	var y1 := int(floor((at.y + r) / Maps.TILE))
	for y in range(y0, y1 + 1):
		if y < 0 or y >= h:
			continue
		for x in range(x0, x1 + 1):
			if x < 0 or x >= w:
				continue
			if not _blocks_feet(y * w + x):
				continue
			var lo := Vector2(x, y) * Maps.TILE
			var hi := lo + Vector2.ONE * Maps.TILE
			var near := at.clamp(lo, hi)
			var d := at - near
			var dist := d.length()
			if dist >= r:
				continue
			if dist > 0.0001:
				at = near + d / dist * r
			else:  # The centre is inside the tile: leave by the nearest side.
				var left := at.x - lo.x
				var right := hi.x - at.x
				var top := at.y - lo.y
				var bottom := hi.y - at.y
				var least := minf(minf(left, right), minf(top, bottom))
				if least == left:
					at.x = lo.x - r
				elif least == right:
					at.x = hi.x + r
				elif least == top:
					at.y = lo.y - r
				else:
					at.y = hi.y + r
	return at


## After a ghost or a leap ends inside something solid: walk out to the nearest free tile.
func _unstick(p: Player) -> void:
	var i := tile_index(p.pos)
	if i < 0 or not _blocks_feet(i):
		p.pos = move_circle(p.pos, Vector2.ZERO, radius_of(p))
		return
	var best := -1
	var best_d := INF
	for j in w * h:
		if _blocks_feet(j):
			continue
		var d := tile_center(j).distance_squared_to(p.pos)
		if d < best_d:
			best_d = d
			best = j
	if best >= 0:
		p.pos = tile_center(best)


## Teammates lean away from each other instead of stacking into one blob.
func _separate_mates() -> void:
	for team in 2:
		var mates: Array = team_of(team)
		for i in mates.size():
			var a: Player = mates[i]
			if a.state != State.PLAY or is_airborne(a):
				continue
			for j in range(i + 1, mates.size()):
				var b: Player = mates[j]
				if b.state != State.PLAY or is_airborne(b) or has_status(a, "carpet") or has_status(b, "carpet"):
					continue
				var d := a.pos - b.pos
				var want := (RADIUS * 1.6)
				var len2 := d.length_squared()
				if len2 < want * want and len2 > 0.0001:
					var push := d / sqrt(len2) * (want - sqrt(len2)) * 0.25
					a.pos = move_circle(a.pos, push, radius_of(a), has_status(a, "ghost"))
					b.pos = move_circle(b.pos, -push, radius_of(b), has_status(b, "ghost"))


# --- Tagging, jail and rescue ---------------------------------------------------------------------

func _resolve_tags() -> void:
	for a: Player in team_of(0):
		if a.state != State.PLAY:
			continue
		for b: Player in team_of(1):
			if b.state != State.PLAY or a.state != State.PLAY:
				continue
			var reach := radius_of(a) + radius_of(b) + TAG_MARGIN
			if a.pos.distance_squared_to(b.pos) > reach * reach:
				continue
			if can_tag(a, b) and not is_held(a) and a.tag_cd <= 0.0:
				_tag(a, b)
			elif can_tag(b, a) and not is_held(b) and b.tag_cd <= 0.0:
				_tag(b, a)


func _tag(a: Player, b: Player) -> void:
	a.tag_cd = TAG_COOLDOWN
	a.status.erase("invis")
	if has_status(b, "shield"):
		b.status.erase("shield")
		var push := (b.pos - a.pos).normalized()
		b.kb += push * 14.0
		a.kb -= push * 14.0
		_event("blocked", a.id, b.id, b.pos.x, b.pos.y)
		return
	if has_status(b, "angel"):  # Lifted clear, and set down at home.
		_event("angel", b.id, a.id, b.pos.x, b.pos.y)
		_send_home(b)
		return
	var chained := has_status(a, "chain")
	_jail(b, a)
	if chained:
		a.status.erase("chain")
		for other: Player in team_of(b.team):
			if other.state == State.PLAY and other.pos.distance_to(a.pos) < 7.0 and can_tag(a, other):
				_event("chain", a.id, other.id, other.pos.x, other.pos.y)
				_jail(other, a)


func _jail(b: Player, by: Player) -> void:
	var x := b.pos.x
	var y := b.pos.y
	b.state = State.JAIL
	b.jail_left = JAIL_TIME + (3.0 if overtime else 0.0)
	b.times_jailed += 1
	b.vel = Vector2.ZERO
	b.kb = Vector2.ZERO
	b.dash_left = 0.0
	b.leap_t = -1.0
	b.status.clear()
	var slot := 0
	for other: Player in team_of(b.team):
		if other.state == State.JAIL and other != b:
			slot += 1
	b.pos = jail[by.team] + Vector2.RIGHT.rotated(TAU * slot / float(TEAM_SIZE) + 0.4) * 1.05
	by.tags += 1
	_event("tag", by.id, b.id, x, y)


func _tick_rescues() -> void:
	for team in 2:
		var jail_at: Vector2 = jail[1 - team]
		var held := false
		for mate: Player in team_of(team):
			if mate.state == State.JAIL:
				held = true
				break
		if not held:
			continue
		for rescuer: Player in team_of(team):
			if rescuer.state != State.PLAY or is_airborne(rescuer) or has_status(rescuer, "ghost") or is_free_walking(rescuer):
				continue
			if rescuer.pos.distance_squared_to(jail_at) > JAIL_R * JAIL_R:
				continue
			var count := _free_team(team)
			rescuer.free_until = t + FREE_WALK
			rescuer.rescues += count
			_event("rescue", rescuer.id, count, jail_at.x, jail_at.y)
			break


func _free_team(team: int) -> int:
	var count := 0
	for mate: Player in team_of(team):
		if mate.state == State.JAIL:
			mate.state = State.PLAY
			mate.free_until = t + FREE_WALK
			mate.fresh = -1.0  # Stale until they're back on their own side.
			mate.on_base = false
			count += 1
			_event("freed", mate.id, -1, mate.pos.x, mate.pos.y)
	return count


func _tick_capture(dt: float) -> void:
	for team in 2:  # The base of `team`, being attacked by the other team.
		var at: Vector2 = base[team]
		var attackers := 0
		var boost := 1.0
		var last := -1
		for p: Player in team_of(1 - team):
			if p.state == State.PLAY and not is_airborne(p) and not is_free_walking(p) and not has_status(p, "ghost") and not has_status(p, "chicken") and not has_status(p, "bubble") \
					and p.pos.distance_squared_to(at) < BASE_R * BASE_R:
				attackers += 1
				last = p.id
				if has_status(p, "fastcap"):
					boost = 2.0
		var guards := 0
		for p: Player in team_of(team):
			if p.state == State.PLAY and p.pos.distance_squared_to(at) < BASE_R * BASE_R:
				guards += 1
		capturing[team] = attackers
		var rate := 0.0
		if attackers > 0 and base_lock[team] <= t:
			rate = (1.0 + 0.4 * (attackers - 1)) * boost / CAPTURE_TIME
			if overtime:
				rate *= 1.5
			if guards > 0:  # Defenders on the pad slow a capture; only a tag stops it.
				rate *= 0.5
		if rate > 0.0:
			cap[team] = minf(float(cap[team]) + rate * dt, 1.0)
			if float(cap[team]) >= 1.0:
				for p: Player in team_of(1 - team):
					if p.state == State.PLAY and p.pos.distance_squared_to(at) < BASE_R * BASE_R:
						p.captures += 1
				_award_point(1 - team, "capture", last)
				return
		elif attackers == 0:
			cap[team] = maxf(float(cap[team]) - 0.12 * dt, 0.0)


func _check_wipeout() -> void:
	for team in 2:
		var everyone_jailed := true
		for p: Player in team_of(team):
			if p.state != State.JAIL:
				everyone_jailed = false
				break
		if everyone_jailed:
			_award_point(1 - team, "wipeout")
			return


# --- Pickups --------------------------------------------------------------------------------------

func _tick_pickups(dt: float) -> void:
	for i in range(pickups.size() - 1, -1, -1):
		if pickups[i].has("gone") and float(pickups[i]["gone"]) <= t:
			pickups.remove_at(i)
	for tile: int in altars:
		if float(altars[tile]) <= t:
			altars[tile] = t + ALTAR_REGROW
			var at := tile_center(tile)
			var taken := false
			for item: Dictionary in pickups:
				if at.distance_squared_to(item["pos"]) < 1.0:
					taken = true
					break
			if not taken:
				pickups.append({"uid": _next_uid(), "pos": at, "born": t})
				_event("drop", -1, -1, at.x, at.y)
	_spawn_timer -= dt
	if _spawn_timer <= 0.0 and _pickup_tiles.size() > 0:
		var gap := FIESTA_GAP if fiesta else SPAWN_GAP
		_spawn_timer = rng.randf_range(gap.x, gap.y)
		if pickups.size() < int(_crystals_wanted * (1.4 if fiesta else 1.0)):
			_spawn_pickup()
	for p in players:
		if p.state != State.PLAY or p.powers.size() >= MAX_POWERS or is_airborne(p):
			continue
		for i in range(pickups.size() - 1, -1, -1):
			var item: Dictionary = pickups[i]
			if t < float(item["born"]) + 0.4:
				continue
			var reach := radius_of(p) + 0.75
			if p.pos.distance_squared_to(item["pos"]) <= reach * reach:
				if item.has("trap"):  # Not a real crystal. Your own team can tell.
					if int(item["trap"]) == p.team:
						continue
					_blast(item["pos"], 2.6, 16.0, 1.5, 1 - p.team, null)
					_event("poof", p.id, -1, p.pos.x, p.pos.y)
					pickups.remove_at(i)
					break
				p.powers.append(Powerups.roll(rng, deck_of(p)))
				p.spin_left = SPIN_TIME
				_event("pick", p.id, -1, p.pos.x, p.pos.y)
				pickups.remove_at(i)
				break


func _spawn_pickup(near := Vector2.INF) -> void:
	var at := Vector2.ZERO
	if near != Vector2.INF:
		for _try in 12:
			var candidate := near + Vector2.RIGHT.rotated(rng.randf() * TAU) * rng.randf_range(2.0, 7.0)
			var i := tile_index(candidate)
			if i >= 0 and not _blocks_feet(i):
				at = tile_center(i)
				break
	if at == Vector2.ZERO:
		# Every other drop lands on the other half, so neither team is favoured.
		_spawn_side = 1 - _spawn_side
		for _try in 20:
			var tile := _pickup_tiles[rng.randi_range(0, _pickup_tiles.size() - 1)]
			var candidate := tile_center(tile)
			if (candidate.x < arena_size().x * 0.5) == (_spawn_side == 0) and not _pickup_near(candidate):
				at = candidate
				break
	if at == Vector2.ZERO:
		return
	pickups.append({"uid": _next_uid(), "pos": at, "born": t})
	_event("drop", -1, -1, at.x, at.y)


func _pickup_near(at: Vector2) -> bool:
	for item: Dictionary in pickups:
		if at.distance_squared_to(item["pos"]) < 9.0:
			return true
	return false


func _next_uid() -> int:
	_uid += 1
	return _uid


# --- Using powerups -------------------------------------------------------------------------------

## The first power can be used unless it's the one still spinning: a second one spins behind it.
func can_use_power(p: Player) -> bool:
	return not p.powers.is_empty() and p.swap_left <= 0.0 and (p.spin_left <= 0.0 or p.powers.size() > 1)


func can_use_skill(p: Player, index: int) -> bool:
	return index >= 0 and index < p.skills.size() and p.skill_cd[index] <= 0.0


func _use_skill(p: Player, index: int) -> void:
	var skill: String = p.skills[index][0]
	var rank: int = p.skills[index][1]
	p.skill_cd[index] = Skills.cooldown(skill, rank)
	p.skills_used += 1
	var id := Skills.power_id(skill, rank)
	_event("use", p.id, -1, p.pos.x, p.pos.y, id)
	_play_power(p, id)


func _use_power(p: Player) -> void:
	var id: String = p.powers.pop_front()
	p.powers_used += 1
	_event("use", p.id, -1, p.pos.x, p.pos.y, id)
	if id == "copycat" and last_power != "":
		id = last_power
	elif id == "copycat":
		id = Powerups.roll(rng, deck_of(p))
	else:
		last_power = id
	_play_power(p, id)


func _play_power(p: Player, id: String) -> void:
	var def := Powerups.by_id(id)
	if def.is_empty():
		return
	var aim := _resolve_aim(p, def)
	p.aim = Vector2.ZERO
	if id != "invisi_cloak":
		p.status.erase("invis")
	match String(def["kind"]):
		"self":
			_give_statuses(p, def["status"])
		"team":
			for mate: Player in team_of(p.team):
				if mate.state == State.PLAY:
					_give_statuses(mate, def["status"])
		"aoe":
			_use_aoe(p, def)
		"shot":
			_fire(p, def, aim)
		"zone":
			_place_zone(p, def, aim)
		"blink":
			_blink(p, aim, float(def["dist"]))
		"hop":
			var to: Vector2 = (p.pos + aim * float(def["dist"])).clamp(Vector2.ONE, arena_size() - Vector2.ONE)
			_launch(p, to, float(def.get("dur", 0.65)))
		"grapple":
			_grapple(p, aim, float(def["range"]))
		"recall":
			p.pos = _spawn_point(p.team, p.id, TEAM_SIZE)
			p.vel = Vector2.ZERO
			p.kb = Vector2.ZERO
			p.fresh = t
			p.free_until = -1.0
		"zap":
			_zap(p, def)
		"storm":
			_storm(p, def)
		"quake":
			for e: Player in team_of(1 - p.team):
				if e.state == State.PLAY and not is_airborne(e):
					_apply_cc(e, def["status"], p)
			_event(String(def.get("event", "quake")), p.id)
		"meteors":
			_meteors(p, def)
		"wall":
			_build_wall(p, aim, int(def["len"]), float(def["dur"]))
		"baselock":
			base_lock[p.team] = t + float(def["dur"])
			_event("lock", p.team, -1, base[p.team].x, base[p.team].y)
		"sentry":
			ents.append({"uid": _next_uid(), "type": "sentry", "team": p.team, "owner": p.id, "pos": p.pos, "vel": Vector2.ZERO, "until": t + float(def["dur"]), "cd": 0.5, "follow": bool(def.get("follow", false))})
		"snares":
			_ring_of_traps(p.team, base[p.team], BASE_R + 1.3, int(def["count"]), "snare", float(def["dur"]), id)
		"mines":
			_ring_of_traps(p.team, p.pos, 2.4, int(def["count"]), String(def.get("trap", "mine")), float(def["dur"]), id)
		"hedge":
			zones.append({"uid": _next_uid(), "fx": "thorn", "team": p.team, "pos": base[p.team], "r": BASE_R + 1.6, "until": t + float(def["dur"]), "drift": Vector2.ZERO, "pw": id, "armed": true})
		"fresh":
			p.fresh = t + CHARGE_TIME
		"swap":
			_swap(p, float(def["range"]))
		"curse":
			var target := _nearest_enemy(p, float(def["range"]))
			if target:
				_give_statuses(target, def["status"])
				target.fear_from = p.pos
				_event("cc", target.id, p.id, target.pos.x, target.pos.y, "stale")
				if def.has("word"):
					_event("word", target.id, p.id, target.pos.x, target.pos.y, def["word"])
		"decoys":
			for i in int(def["count"]):
				var dir := Vector2.RIGHT.rotated(TAU * i / float(def["count"]) + rng.randf())
				ents.append({"uid": _next_uid(), "type": "decoy", "team": p.team, "owner": p.id, "pos": p.pos, "vel": dir * SPEED, "until": t + float(def["dur"]), "cd": 0.0})
		"jailbreak":
			var count := _free_team(p.team)
			p.rescues += count
			_event("rescue", p.id, count, jail[1 - p.team].x, jail[1 - p.team].y)
		"teamfresh":
			for mate: Player in team_of(p.team):
				if mate.state == State.PLAY:
					mate.fresh = t + CHARGE_TIME
					_event("refreshed", mate.id, -1, mate.pos.x, mate.pos.y)
		"radar":
			radar[p.team] = t + float(def["dur"])
		"rain":
			for _i in int(def["count"]):
				_spawn_pickup(p.pos)
		"beam":
			p.status["charging"] = t + float(def["charge"])
			zones.append({"uid": _next_uid(), "fx": "beam", "team": p.team, "owner": p.id, "pos": p.pos, "aim": aim, "r": float(def["r"]), "len": float(def["len"]),
				"fires": t + float(def["charge"]), "until": t + float(def["charge"]) + float(def["hold"]), "drift": Vector2.ZERO, "pw": id, "armed": true, "hit": []})
		"drop":
			var victim := _nearest_enemy(p, float(def["range"]))
			var spot: Vector2 = victim.pos if victim else (p.pos + aim * 8.0).clamp(Vector2.ONE, arena_size() - Vector2.ONE)
			zones.append({"uid": _next_uid(), "fx": "anvil", "team": p.team, "pos": spot, "r": float(def["r"]), "until": t + float(def["fall"]), "drift": Vector2.ZERO, "pw": id, "armed": true,
				"target": victim.id if victim else -1, "pace": 9.0})
		"chaser":
			var victim := _nearest_enemy(p, float(def["range"]))
			if victim:
				zones.append({"uid": _next_uid(), "fx": def["fx"], "team": p.team, "pos": p.pos if def["fx"] == "bees" else victim.pos, "r": float(def["r"]), "until": t + float(def["dur"]), "drift": Vector2.ZERO, "pw": id, "armed": true,
					"target": victim.id, "pace": float(def["pace"])})
		"wave":
			var dir := 1.0 if p.team == 0 else -1.0
			var start := Vector2(float(base[p.team].x) - dir * 4.0, arena_size().y * 0.5)
			zones.append({"uid": _next_uid(), "fx": "tide", "team": p.team, "pos": start, "r": float(def["r"]), "until": t + (arena_size().x + 8.0) / float(def["speed"]), "drift": Vector2(dir * float(def["speed"]), 0.0), "pw": id, "armed": true, "free": true})
		"fire_line":
			for i in int(def["count"]):
				var spot: Vector2 = p.pos + aim * float(def["gap"]) * (i + 1)
				var tile := tile_index(spot)
				if tile < 0 or _blocks_shots(tile):
					break
				zones.append({"uid": _next_uid(), "fx": "fire", "team": p.team, "pos": spot, "r": 1.25, "until": t + float(def["dur"]), "drift": Vector2.ZERO, "pw": id, "armed": true})
		"slam":
			var to: Vector2 = (p.pos + aim * float(def["dist"])).clamp(Vector2.ONE, arena_size() - Vector2.ONE)
			p.status["slam"] = t + 2.0
			p.slam_r = float(def["r"])
			p.slam_push = float(def["push"])
			p.slam_stun = float(def["stun"])
			_launch(p, to, 0.7)
		"chain_zap":
			var from := p.pos
			var left := int(def["count"])
			var hit: Array = []
			var reach := float(def["range"])
			while left > 0:
				var next: Player = null
				var best := reach * reach
				for e: Player in team_of(1 - p.team):
					if e.state == State.PLAY and not e.on_base and not hit.has(e.id) and not has_status(e, "ghost") and e.pos.distance_squared_to(from) < best:
						best = e.pos.distance_squared_to(from)
						next = e
				if next == null:
					break
				hit.append(next.id)
				_event("zap", next.id, p.id, next.pos.x, next.pos.y)
				_apply_cc(next, def["status"], p)
				from = next.pos
				reach = float(def["jump"])
				left -= 1
		"potato":
			var victim := _nearest_enemy(p, float(def["range"]))
			if victim:
				victim.status["potato"] = t + float(def["dur"])
				_event("potato", victim.id, p.id, victim.pos.x, victim.pos.y)
		"igloo":
			_build_igloo(p, float(def["dur"]))
		"smoke":
			zones.append({"uid": _next_uid(), "fx": "smoke", "team": p.team, "pos": p.pos, "r": float(def["r"]), "until": t + float(def["dur"]), "drift": Vector2.ZERO, "pw": id, "armed": true})
		"clones":
			var count := int(def["count"])
			for i in count:
				var offset := Vector2.RIGHT.rotated(TAU * i / float(count) + 0.6) * 2.4
				var at := move_circle(p.pos, offset, RADIUS)
				ents.append({"uid": _next_uid(), "type": "clone", "team": p.team, "owner": p.id, "pos": at, "vel": Vector2.ZERO, "until": t + float(def["dur"]), "cd": 0.0})
				_event("poof", -1, -1, at.x, at.y)
		"peels":
			for i in int(def["count"]):
				var spot := _spot_behind(p, 1.6 + i * 1.5, 0.7 if i % 2 == 0 else -0.7)
				zones.append({"uid": _next_uid(), "fx": "peel", "team": p.team, "pos": spot, "r": 0.8, "until": t + float(def["dur"]), "drift": Vector2.ZERO, "pw": id, "armed": true})
		"traps":
			for i in int(def["count"]):
				var spot := _spot_behind(p, 1.5 + i * 1.3, 0.6 if i % 2 == 0 else -0.6)
				zones.append({"uid": _next_uid(), "fx": def["fx"], "team": p.team, "pos": spot, "r": float(def["r"]), "until": t + float(def["dur"]), "drift": Vector2.ZERO, "pw": id, "armed": true})
		"peel_rain":
			var half := arena_size().x * 0.5
			for _i in int(def["count"]):
				var x: float = rng.randf_range(half + 1.0, half * 2.0 - 1.0) if p.team == 0 else rng.randf_range(1.0, half - 1.0)
				var spot := Vector2(x, rng.randf_range(1.0, arena_size().y - 1.0))
				var tile := tile_index(spot)
				if tile >= 0 and not _blocks_feet(tile):
					zones.append({"uid": _next_uid(), "fx": "peel", "team": p.team, "pos": spot, "r": 0.8, "until": t + float(def["dur"]), "drift": Vector2.ZERO, "pw": id, "armed": true})
		"volley":
			var spread := float(def["spread"])
			var count := int(def["count"])
			for i in count:
				_fire(p, def, aim.rotated(spread * (i - (count - 1) * 0.5)))
		"stalk":
			var victim := _nearest_enemy(p, float(def["range"]))
			if victim and not victim.on_base:
				p.pos = move_circle(victim.pos, -victim.face * 1.4, radius_of(p))
				p.vel = Vector2.ZERO
				_give_statuses(p, def["status"])
				_event("warp", p.id, -1, p.pos.x, p.pos.y)
			else:
				_event("poof", -1, -1, p.pos.x, p.pos.y)
		"cleanse":
			for name: String in SHAKEN_OFF:
				p.status.erase(name)
			p.dash_cd = 0.0
			_give_statuses(p, def["status"])
			_event("refreshed", p.id, -1, p.pos.x, p.pos.y)
		"portal":
			var far: Vector2 = p.pos
			for s in range(int(def["dist"]), 2, -1):
				var spot: Vector2 = p.pos + aim * s
				var tile := tile_index(spot)
				if tile >= 0 and not _blocks_feet(tile):
					far = tile_center(tile)
					break
			var a := _next_uid()
			var b := _next_uid()
			var until := t + float(def["dur"])
			zones.append({"uid": a, "fx": "portal", "team": p.team, "pos": p.pos - aim * 0.2, "r": 1.0, "until": until, "drift": Vector2.ZERO, "pw": id, "armed": true, "link": far})
			zones.append({"uid": b, "fx": "portal", "team": p.team, "pos": far, "r": 1.0, "until": until, "drift": Vector2.ZERO, "pw": id, "armed": true, "link": p.pos})
			p.pad_cd = maxf(p.pad_cd, 0.8)
		"fake":
			pickups.append({"uid": _next_uid(), "pos": p.pos - p.face * 1.4, "born": t, "trap": p.team, "gone": t + float(def["dur"])})
		"steal":
			var victim := _nearest_enemy(p, float(def["range"]))
			if victim and not victim.powers.is_empty():
				p.powers.append(victim.powers.pop_back())
				p.spin_left = SPIN_TIME
				_event("stolen", victim.id, p.id, victim.pos.x, victim.pos.y)
			else:
				_event("poof", -1, -1, p.pos.x, p.pos.y)
		"wild":
			for _i in int(def["count"]):
				if p.powers.size() < MAX_POWERS:
					p.powers.append(Powerups.roll(rng, deck_of(p)))
			p.spin_left = SPIN_TIME
			_event("pick", p.id, -1, p.pos.x, p.pos.y)
		"warp_mate":
			var best: Player = null
			var best_d := INF
			for mate: Player in team_of(p.team):
				if mate != p and mate.state == State.PLAY:
					var d: float = mate.pos.distance_to(base[1 - p.team])
					if d < best_d:
						best_d = d
						best = mate
			if best:
				p.pos = move_circle(best.pos, Vector2.RIGHT.rotated(rng.randf() * TAU) * 1.4, radius_of(p))
				_event("warp", p.id, -1, p.pos.x, p.pos.y)
		"rewind":
			if not p.history.is_empty():
				p.pos = p.history[0]
				p.vel = Vector2.ZERO
				p.kb = Vector2.ZERO
				for name: String in SHAKEN_OFF:
					p.status.erase(name)
				_unstick(p)
				_event("warp", p.id, -1, p.pos.x, p.pos.y)
		"rally":
			var count := 0
			for mate: Player in team_of(p.team):
				if mate != p and mate.state == State.PLAY:
					mate.pos = move_circle(p.pos, Vector2.RIGHT.rotated(TAU * count / 4.0) * 1.8, radius_of(mate))
					mate.vel = Vector2.ZERO
					mate.leap_t = -1.0
					mate.on_base = false
					count += 1
					_event("warp", mate.id, -1, mate.pos.x, mate.pos.y)
		"vacuum":
			var reach := float(def["r"])
			for item: Dictionary in pickups:
				if not item.has("trap") and p.pos.distance_to(item["pos"]) < reach:
					item["pos"] = move_circle(p.pos, Vector2.RIGHT.rotated(rng.randf() * TAU) * 1.5, 0.4)
					item["born"] = t + 0.2
			_event("burst", p.id, -1, p.pos.x, p.pos.y, id)
		"cheer":
			for mate: Player in team_of(p.team):
				if mate.state == State.PLAY:
					for name: String in SHAKEN_OFF:
						mate.status.erase(name)
					mate.dash_cd = 0.0
					_give_statuses(mate, def["status"])
					_event("refreshed", mate.id, -1, mate.pos.x, mate.pos.y)
		"weather":
			var kinds: Array = def["kinds"]
			var picked := String(kinds[rng.randi_range(0, kinds.size() - 1)])
			if picked == weather:
				picked = String(kinds[(kinds.find(picked) + 1) % kinds.size()])
			set_weather(picked)
			weather_until = t + float(def["dur"])
			_event("weather", p.id, -1, 0.0, 0.0, picked)


## A spot behind you to leave something on, or if there's a wall there, the first one round you that's open.
func _spot_behind(p: Player, back: float, side: float) -> Vector2:
	var offset := -p.face * back + p.face.orthogonal() * side
	for turn: float in [0.0, 1.2, -1.2, 2.4, -2.4, PI]:
		var at: Vector2 = p.pos + offset.rotated(turn)
		var tile := tile_index(at)
		if tile >= 0 and not _blocks_feet(tile):
			return at
	return p.pos


func _resolve_aim(p: Player, def: Dictionary) -> Vector2:
	if p.aim.length() > 0.2:
		return p.aim.normalized()
	if String(def["kind"]) in ["shot", "zone", "beam", "fire_line", "slam", "volley"]:
		var target := _nearest_enemy(p, float(def.get("range", def.get("len", 16.0))))
		if target and clear_line(p.pos, target.pos, true):
			return (target.pos - p.pos).normalized()
	return p.face


func _nearest_enemy(p: Player, within: float) -> Player:
	var best: Player = null
	var best_d := within * within
	for e: Player in team_of(1 - p.team):
		if e.state != State.PLAY or has_status(e, "ghost") or is_hidden_from(e, p.team):
			continue
		var d := e.pos.distance_squared_to(p.pos)
		if d < best_d:
			best_d = d
			best = e
	return best


func _give_statuses(p: Player, statuses: Dictionary) -> void:
	for name: String in statuses:
		p.status[name] = t + float(statuses[name])


## Stuns and the like, unless the target shrugs them off.
func _apply_cc(e: Player, statuses: Dictionary, from: Player = null) -> void:
	if has_status(e, "mirror") or is_free_walking(e) or e.on_base:
		return
	if has_status(e, "shield"):  # A bubble stops one hit as well as one tag.
		e.status.erase("shield")
		_event("reflect", e.id, -1, e.pos.x, e.pos.y)
		return
	var giant := has_status(e, "giant")
	for name: String in statuses:
		if giant and name in HELD:
			continue
		e.status[name] = t + float(statuses[name])
		if name == "fear" and from:
			e.fear_from = from.pos
		_event("cc", e.id, from.id if from else -1, e.pos.x, e.pos.y, name)
	e.status.erase("invis")


func _use_aoe(p: Player, def: Dictionary) -> void:
	var radius := float(def["r"])
	_event("burst", p.id, -1, p.pos.x, p.pos.y, def["id"])
	if def.has("word"):
		_event("word", p.id, -1, p.pos.x, p.pos.y, def["word"])
	if def.has("jokes"):
		var jokes: Array = def["jokes"]
		_event("word", p.id, -1, p.pos.x, p.pos.y, jokes[rng.randi_range(0, jokes.size() - 1)])
	for e: Player in team_of(1 - p.team):
		if e.state != State.PLAY or is_airborne(e) or has_status(e, "ghost"):
			continue
		var d := e.pos.distance_to(p.pos)
		if d > radius:
			continue
		if def.has("status"):
			_apply_cc(e, def["status"], p)
		if def.has("push") and not e.on_base and not has_status(e, "mirror") and not is_free_walking(e):
			var dir := (e.pos - p.pos).normalized() if d > 0.01 else Vector2.RIGHT
			# A pull stops short of the caster, so they meet instead of overshooting.
			var force := float(def["push"]) if float(def["push"]) > 0.0 else -minf(-float(def["push"]), d * 5.5)
			e.kb += dir * force


func _fire(p: Player, def: Dictionary, aim: Vector2) -> void:
	shots.append({"uid": _next_uid(), "pw": def["id"], "team": p.team, "owner": p.id,
		"pos": p.pos + aim * (radius_of(p) + 0.2), "vel": aim * float(def["speed"]), "r": float(def["r"]),
		"life": float(def["range"]) / float(def["speed"]), "bounces": int(def.get("bounces", 0)),
		"homing": bool(def.get("homing", false)), "pierce": bool(def.get("pierce", false)), "hit": [], "out": float(def["range"]) * 0.5 / float(def["speed"])})


func _place_zone(p: Player, def: Dictionary, aim: Vector2) -> void:
	var at: Vector2 = (p.pos + aim * float(def.get("at", 0.0))).clamp(Vector2.ONE, arena_size() - Vector2.ONE)
	zones.append({"uid": _next_uid(), "fx": def["fx"], "team": p.team, "pos": at, "r": float(def["r"]),
		"until": t + float(def["dur"]), "drift": aim * float(def.get("drift", 0.0)), "pw": def["id"], "armed": true})


func _blink(p: Player, aim: Vector2, dist: float) -> void:
	var from := p.pos
	var best := p.pos
	var steps := 24
	for s in range(1, steps + 1):
		var at := from + aim * dist * float(s) / steps
		var i := tile_index(at)
		if i < 0:
			break
		if not _blocks_feet(i):
			best = at
	p.pos = best
	p.vel = aim * SPEED
	_event("warp", p.id, -1, best.x, best.y)


func _grapple(p: Player, aim: Vector2, reach: float) -> void:
	var at := p.pos
	var steps := int(reach / 0.4)
	var last := p.pos
	for _s in steps:
		at += aim * 0.4
		var i := tile_index(at)
		if i < 0 or _blocks_shots(i):
			break
		if not _blocks_feet(i):
			last = at
	_event("grapple", p.id, -1, last.x, last.y)
	_launch(p, last, clampf(p.pos.distance_to(last) / 26.0, 0.12, 0.7))


func _zap(p: Player, def: Dictionary) -> void:
	var best: Player = null
	var best_d := INF
	for e: Player in team_of(1 - p.team):
		if e.state == State.PLAY and not e.on_base:
			var d: float = e.pos.distance_squared_to(base[p.team])
			if d < best_d:
				best_d = d
				best = e
	if best:
		_event("zap", best.id, p.id, best.pos.x, best.pos.y)
		_apply_cc(best, def["status"], p)


func _storm(p: Player, def: Dictionary) -> void:
	var list: Array = []
	for e: Player in team_of(1 - p.team):
		if e.state == State.PLAY and not e.on_base:
			list.append(e)
	for _i in int(def["count"]):
		if list.is_empty():
			return
		var e: Player = list.pop_at(rng.randi_range(0, list.size() - 1))
		_event("zap", e.id, p.id, e.pos.x, e.pos.y)
		_apply_cc(e, def["status"], p)


func _meteors(p: Player, def: Dictionary) -> void:
	var half := arena_size().x * 0.5
	for i in int(def["count"]):
		var x: float = rng.randf_range(half, half * 2.0 - 1.0) if p.team == 0 else rng.randf_range(1.0, half)
		var at := Vector2(x, rng.randf_range(1.0, arena_size().y - 1.0))
		zones.append({"uid": _next_uid(), "fx": "meteor", "team": p.team, "pos": at, "r": 2.2,
			"until": t + 0.8 + float(def["dur"]) * float(i) / float(def["count"]), "drift": Vector2.ZERO, "pw": def["id"], "armed": true})


## A ring of ice round you, on the eight tiles next to the one you're on.
func _build_igloo(p: Player, dur: float) -> void:
	var here := tile_index(p.pos)
	if here < 0:
		return
	var built := false
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var x := here % w + dx
			var y := here / w + dy
			if x < 0 or y < 0 or x >= w or y >= h:
				continue
			var i := y * w + x
			if _blocks_feet(i):
				continue
			var c := tile_center(i)
			if c.distance_to(base[0]) < BASE_R or c.distance_to(base[1]) < BASE_R or c.distance_to(jail[0]) < JAIL_R or c.distance_to(jail[1]) < JAIL_R:
				continue
			walls[i] = t + dur
			built = true
	if built:
		_event("wall", p.id, -1, p.pos.x, p.pos.y)
	p.pos = tile_center(here)
	for other in players:
		if other != p and other.state == State.PLAY and not has_status(other, "ghost") and not has_status(other, "carpet"):
			other.pos = move_circle(other.pos, Vector2.ZERO, radius_of(other))


func _build_wall(p: Player, aim: Vector2, length: int, dur: float) -> void:
	var center := p.pos + aim * 2.4
	var side := Vector2(-aim.y, aim.x)
	var built := 0
	for s in range(-length / 2, length / 2 + 1):
		var at := center + side * s * Maps.TILE
		var i := tile_index(at)
		if i < 0 or _blocks_feet(i):
			continue
		var c := tile_center(i)
		if c.distance_to(base[0]) < BASE_R or c.distance_to(base[1]) < BASE_R or c.distance_to(jail[0]) < JAIL_R or c.distance_to(jail[1]) < JAIL_R:
			continue
		walls[i] = t + dur
		built += 1
	if built > 0:
		_event("wall", p.id, -1, center.x, center.y)
	for other in players:  # Nobody stays stuck in the new wall.
		if other.state == State.PLAY and not has_status(other, "ghost") and not has_status(other, "carpet"):
			other.pos = move_circle(other.pos, Vector2.ZERO, radius_of(other))


func _ring_of_traps(team: int, center: Vector2, radius: float, count: int, fx: String, dur: float, pw: String) -> void:
	for i in count:
		var at: Vector2 = center + Vector2.RIGHT.rotated(TAU * i / float(count) + 0.3) * radius
		var tile := tile_index(at)
		if tile < 0 or _blocks_feet(tile):
			continue
		zones.append({"uid": _next_uid(), "fx": fx, "team": team, "pos": at, "r": 1.1, "until": t + dur, "drift": Vector2.ZERO, "pw": pw, "armed": true})


func _swap(p: Player, reach: float) -> void:
	var target := _nearest_enemy(p, reach)
	if target == null or target.on_base:
		return
	var here := p.pos
	p.pos = target.pos
	target.pos = here
	target.vel = Vector2.ZERO
	_event("swap", p.id, target.id, p.pos.x, p.pos.y)


# --- Shots, zones and things on the field ---------------------------------------------------------

func _tick_shots(dt: float) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var s: Dictionary = shots[i]
		s["life"] = float(s["life"]) - dt
		if bool(s["homing"]):
			_steer_homing(s, dt)
		var def := Powerups.by_id(s["pw"])
		var returning := false
		if def.get("returns", false) and float(s["life"]) < float(s["out"]):
			returning = true
			var thrower := player_by_id(int(s["owner"]))
			if thrower:
				s["vel"] = (thrower.pos - (s["pos"] as Vector2)).normalized() * (s["vel"] as Vector2).length()
				if thrower.pos.distance_to(s["pos"]) < 1.0:
					s["life"] = 0.0
			if float(s["life"]) >= float(s["out"]) * 0.98:
				s["hit"] = []
		if def.has("grow"):
			s["r"] = minf(float(s["r"]) + float(def["grow"]) * dt, float(def["grow_to"]))
		s["vel"] = (s["vel"] as Vector2) + wind * dt * 1.2
		var next: Vector2 = s["pos"] + s["vel"] * dt
		var tile := tile_index(next)
		var ended := float(s["life"]) <= 0.0
		if tile >= 0 and tiles[tile] == Maps.TNT and tnt_here(tile):
			_blow_crate(tile)
			ended = true
		elif returning:
			pass  # It finds its own way back, through anything.
		elif tile < 0 or _blocks_shots(tile):
			if int(s["bounces"]) > 0:
				s["bounces"] = int(s["bounces"]) - 1
				_bounce_shot(s, next)
				next = s["pos"]
				_event("ricochet", -1, -1, next.x, next.y, s["pw"])
			else:
				ended = true
		s["pos"] = next
		if not ended:
			ended = _shot_hits(s)
		if ended:
			_end_shot(s)
			shots.remove_at(i)


func _steer_homing(s: Dictionary, dt: float) -> void:
	var def := Powerups.by_id(s["pw"])
	var best: Player = null
	var seek := float(def.get("seek", 18.0))
	var best_d := seek * seek
	for e: Player in team_of(1 - int(s["team"])):
		if e.state != State.PLAY or has_status(e, "ghost") or is_airborne(e):
			continue
		var d: float = e.pos.distance_squared_to(s["pos"])
		if d < best_d:
			best_d = d
			best = e
	if best:
		var speed: float = (s["vel"] as Vector2).length()
		var want: Vector2 = (best.pos - s["pos"]).normalized() * speed
		s["vel"] = (s["vel"] as Vector2).lerp(want, clampf(float(def.get("turn", 5.0)) * dt, 0.0, 1.0)).normalized() * speed


func _bounce_shot(s: Dictionary, next: Vector2) -> void:
	var at: Vector2 = s["pos"]
	var v: Vector2 = s["vel"]
	var ix := tile_index(Vector2(next.x, at.y))
	var iy := tile_index(Vector2(at.x, next.y))
	if ix < 0 or _blocks_shots(ix):
		v.x = -v.x
	if iy < 0 or _blocks_shots(iy):
		v.y = -v.y
	if v == s["vel"]:
		v = -v
	s["vel"] = v


## True when the shot is used up.
func _shot_hits(s: Dictionary) -> bool:
	var def := Powerups.by_id(s["pw"])
	for ent_i in range(ents.size() - 1, -1, -1):
		var ent: Dictionary = ents[ent_i]
		if int(ent["team"]) != int(s["team"]) and String(ent["type"]) in ["decoy", "clone"] and (ent["pos"] as Vector2).distance_to(s["pos"]) < float(s["r"]) + RADIUS:
			_event("poof", -1, -1, ent["pos"].x, ent["pos"].y)
			ents.remove_at(ent_i)
			return not bool(s["pierce"])
	for e: Player in team_of(1 - int(s["team"])):
		if e.state != State.PLAY or has_status(e, "ghost") or is_airborne(e) or is_free_walking(e):
			continue
		if (s["hit"] as Array).has(e.id):
			continue
		var reach: float = float(s["r"]) + radius_of(e)
		if e.pos.distance_squared_to(s["pos"]) > reach * reach:
			continue
		if has_status(e, "orbit"):  # The orbs get it first.
			_event("reflect", e.id, -1, e.pos.x, e.pos.y)
			return true
		if has_status(e, "mirror"):  # Back it goes, now on the mirror's side.
			s["team"] = e.team
			s["vel"] = -(s["vel"] as Vector2)
			s["owner"] = e.id
			s["hit"] = []
			_event("reflect", e.id, -1, e.pos.x, e.pos.y)
			return false
		(s["hit"] as Array).append(e.id)
		var owner := player_by_id(int(s["owner"]))
		if def.get("jails", false):
			if owner and not e.on_base:
				_tag(owner, e)
			return true
		if def.has("status"):
			_apply_cc(e, def["status"], owner)
		if def.has("push") and not e.on_base:
			e.kb += (s["vel"] as Vector2).normalized() * float(def["push"])
		_event("hit", e.id, int(s["owner"]), e.pos.x, e.pos.y, s["pw"])
		return not bool(s["pierce"])
	return false


func _end_shot(s: Dictionary) -> void:
	var def := Powerups.by_id(s["pw"])
	_event("shot_end", -1, -1, s["pos"].x, s["pos"].y, s["pw"])
	if def.has("burst"):
		var burst: Dictionary = def["burst"]
		if burst["fx"] == "peel_ring":
			_ring_of_traps(int(s["team"]), s["pos"], float(burst["r"]), int(burst["count"]), "peel", float(burst["dur"]), s["pw"])
		else:
			zones.append({"uid": _next_uid(), "fx": burst["fx"], "team": s["team"], "pos": s["pos"], "r": float(burst["r"]),
				"until": t + float(burst["dur"]), "drift": Vector2.ZERO, "pw": s["pw"], "armed": true})
	if def.has("blast"):
		var bang: Dictionary = def["blast"]
		_blast(s["pos"], float(bang["r"]), float(bang["push"]), float(bang["stun"]), int(s["team"]), player_by_id(int(s["owner"])))


func _tick_zones(dt: float) -> void:
	for i in range(zones.size() - 1, -1, -1):
		var z: Dictionary = zones[i]
		if float(z["until"]) <= t:
			var ending: String = z["fx"]
			if ending == "meteor":
				_meteor_lands(z)
			elif ending == "strike":
				_strike_lands(z)
			elif ending == "anvil":
				_anvil_lands(z)
			elif ending == "cloud":
				_cloud_bursts(z)
			zones.remove_at(i)
			continue
		if z["drift"] != Vector2.ZERO:
			var drifted: Vector2 = z["pos"] + z["drift"] * dt
			var tile := tile_index(drifted)
			if z.get("free", false) or (tile >= 0 and not _blocks_shots(tile)):
				z["pos"] = drifted
			else:
				z["drift"] = -(z["drift"] as Vector2)
		if z.has("target"):
			_zone_chases(z, dt)
		if z["fx"] in ["meteor", "strike", "anvil"]:
			continue
		if z["fx"] == "portal":
			_tick_portal(z)
			continue
		if z["fx"] == "beam":
			if t >= float(z["fires"]):
				_beam_burns(z)
			continue
		if z["fx"] == "tide":
			_tide_sweeps(z, dt)
			continue
		if _zone_acts(z, dt):
			zones.remove_at(i)


## True when the zone is used up (a mine that went off).
func _zone_acts(z: Dictionary, dt: float) -> bool:
	var fx: String = z["fx"]
	var radius: float = z["r"]
	for e: Player in team_of(1 - int(z["team"])):
		if e.state != State.PLAY or is_airborne(e) or has_status(e, "ghost") or is_free_walking(e) or e.on_base:
			continue
		var d: float = e.pos.distance_to(z["pos"])
		if d > radius + radius_of(e) * 0.5:
			continue
		var toward: Vector2 = ((z["pos"] as Vector2) - e.pos).normalized() if d > 0.05 else Vector2.ZERO
		match fx:
			"slow":
				e.status["slow"] = t + 0.25
			"slip":
				e.status["slip"] = t + 0.5
			"pull":
				e.kb += toward * 34.0 * dt
			"drag":
				e.kb += (toward * 26.0 + toward.orthogonal() * 22.0) * dt
			"fire", "thorn":
				if float(e.status.get("burnt", -1.0)) <= t:
					e.status["burnt"] = t + 2.0
					_apply_cc(e, {"stun": 0.7}, null)
					_event("hit", e.id, -1, e.pos.x, e.pos.y, z["pw"])
			"mine":
				_apply_cc(e, {"stun": 1.0}, null)
				e.kb += -toward * 22.0
				_event("boom", e.id, -1, (z["pos"] as Vector2).x, (z["pos"] as Vector2).y)
				return true
			"snare":
				_apply_cc(e, {"root": 2.2}, null)
				_event("hit", e.id, -1, e.pos.x, e.pos.y, z["pw"])
				return true
			"peel":
				e.status["slip"] = t + 2.4
				e.kb += (e.vel.normalized() if e.vel.length() > 0.5 else Vector2.RIGHT) * 26.0
				_event("slipped", e.id, -1, e.pos.x, e.pos.y)
				return true
			"spring":
				var home_way: Vector2 = ((base[e.team] as Vector2) - e.pos).normalized()
				var to: Vector2 = (e.pos + home_way * 16.0).clamp(Vector2.ONE, arena_size() - Vector2.ONE)
				_launch(e, move_circle(to, Vector2.ZERO, radius_of(e)), 0.8)
				_event("sprung", e.id, -1, e.pos.x, e.pos.y)
				return true
			"poop":
				_apply_cc(e, {"root": 1.3, "stink": 7.0}, null)
				_event("splat", e.id, -1, e.pos.x, e.pos.y)
				return true
			"whoopee":
				var away := Vector2.RIGHT.rotated(rng.randf() * TAU)
				_launch(e, move_circle(e.pos, away * 5.0, radius_of(e)), 0.75)
				_event("toot", e.id, -1, e.pos.x, e.pos.y)
				return true
			"fart":
				e.status["slow"] = t + 0.25
				e.status["reverse"] = t + 0.25
				e.status["stink"] = t + 3.0
				if float(e.status.get("burnt", -1.0)) <= t:
					e.status["burnt"] = t + 1.5
					_event("cough", e.id, -1, e.pos.x, e.pos.y)
			"bees":
				e.status["slow"] = t + 0.25
				if float(e.status.get("burnt", -1.0)) <= t:
					e.status["burnt"] = t + 1.6
					_apply_cc(e, {"stun": 0.45}, null)
					_event("hit", e.id, -1, e.pos.x, e.pos.y, z["pw"])
			"cloud":
				if int(z["target"]) == e.id:
					e.status["slow"] = t + 0.25
	return false


## Bees, clouds and falling anvils go after whoever they were sent for, until there's nobody to go after.
func _zone_chases(z: Dictionary, dt: float) -> void:
	var who := player_by_id(int(z["target"]))
	if who == null or who.state != State.PLAY:
		if z["fx"] == "bees" or z["fx"] == "cloud":
			z["until"] = minf(float(z["until"]), t + 0.3)
		return
	if z["fx"] == "anvil" and float(z["until"]) - t < 0.32:
		return  # Too late to change where it lands.
	var to: Vector2 = who.pos - (z["pos"] as Vector2)
	z["pos"] = (z["pos"] as Vector2) + to.limit_length(float(z["pace"]) * dt)


func _tick_portal(z: Dictionary) -> void:
	for mate: Player in team_of(int(z["team"])):
		if mate.state != State.PLAY or is_airborne(mate) or mate.pad_cd > 0.0:
			continue
		if mate.pos.distance_to(z["pos"]) < float(z["r"]):
			mate.pos = z["link"]
			mate.pad_cd = 1.2
			_event("warp", mate.id, -1, mate.pos.x, mate.pos.y)


func _beam_burns(z: Dictionary) -> void:
	var def := Powerups.by_id(z["pw"])
	if not z.get("fired", false):
		z["fired"] = true
		_event("beam", int(z["owner"]), -1, (z["pos"] as Vector2).x, (z["pos"] as Vector2).y)
	var from: Vector2 = z["pos"]
	var aim: Vector2 = z["aim"]
	var owner := player_by_id(int(z["owner"]))
	for e: Player in team_of(1 - int(z["team"])):
		if e.state != State.PLAY or (z["hit"] as Array).has(e.id) or is_airborne(e) or has_status(e, "ghost"):
			continue
		var along := (e.pos - from).dot(aim)
		if along < 0.0 or along > float(z["len"]):
			continue
		if absf((e.pos - from).cross(aim)) < float(z["r"]) + radius_of(e) * 0.5:
			(z["hit"] as Array).append(e.id)
			_apply_cc(e, def["status"], owner)
			if not e.on_base and not has_status(e, "mirror") and not is_free_walking(e):
				e.kb += aim * float(def["push"])
			_event("hit", e.id, int(z["owner"]), e.pos.x, e.pos.y, z["pw"])


func _tide_sweeps(z: Dictionary, dt: float) -> void:
	var dir := signf((z["drift"] as Vector2).x)
	var x: float = (z["pos"] as Vector2).x
	for e: Player in team_of(1 - int(z["team"])):
		if e.state != State.PLAY or is_airborne(e) or e.on_base or has_status(e, "ghost") or is_free_walking(e):
			continue
		if absf(e.pos.x - x) < float(z["r"]) + radius_of(e):
			e.kb.x += dir * 70.0 * dt
			e.status["slip"] = t + 1.0


func _strike_lands(z: Dictionary) -> void:
	_event("strike", -1, -1, (z["pos"] as Vector2).x, (z["pos"] as Vector2).y)
	for e: Player in players:
		if e.state == State.PLAY and not is_airborne(e) and not e.on_base and not is_free_walking(e) and not has_status(e, "ghost") \
				and e.pos.distance_to(z["pos"]) < float(z["r"]) + radius_of(e) * 0.5:
			_apply_cc(e, {"stun": 1.1}, null)
			e.kb += (e.pos - (z["pos"] as Vector2)).normalized() * 10.0


func _anvil_lands(z: Dictionary) -> void:
	_event("anvil", -1, -1, (z["pos"] as Vector2).x, (z["pos"] as Vector2).y, z["pw"])
	var def := Powerups.by_id(z["pw"])
	for e: Player in team_of(1 - int(z["team"])):
		if e.state == State.PLAY and not is_airborne(e) and not e.on_base and e.pos.distance_to(z["pos"]) < float(z["r"]) + radius_of(e) * 0.5:
			_apply_cc(e, def["status"], null)


func _cloud_bursts(z: Dictionary) -> void:
	var who := player_by_id(int(z["target"]))
	if who and who.state == State.PLAY:
		_event("zap", who.id, -1, who.pos.x, who.pos.y)
		_apply_cc(who, {"stun": 1.0}, null)


func _meteor_lands(z: Dictionary) -> void:
	_event("boom", -1, -1, z["pos"].x, z["pos"].y)
	for e: Player in team_of(1 - int(z["team"])):
		if e.state == State.PLAY and not is_airborne(e) and not e.on_base and e.pos.distance_to(z["pos"]) < float(z["r"]) + radius_of(e) * 0.5:
			_apply_cc(e, {"stun": 1.2}, null)
			e.kb += (e.pos - z["pos"]).normalized() * 12.0


func _tick_ents(dt: float) -> void:
	for i in range(ents.size() - 1, -1, -1):
		var ent: Dictionary = ents[i]
		if float(ent["until"]) <= t:
			_event("poof", -1, -1, ent["pos"].x, ent["pos"].y)
			ents.remove_at(i)
			continue
		if ent["type"] == "decoy":
			if _tick_decoy(ent, dt):
				ents.remove_at(i)
		elif ent["type"] == "clone":
			if _tick_clone(ent, dt):
				ents.remove_at(i)
		else:
			if ent.get("follow", false):
				var owner := player_by_id(int(ent["owner"]))
				if owner and owner.state == State.PLAY:
					var goal: Vector2 = owner.pos - owner.face * 1.6
					ent["pos"] = (ent["pos"] as Vector2).lerp(goal, clampf(dt * 5.0, 0.0, 1.0))
			_tick_sentry(ent, dt)


## A clone copies its owner's every step, and goes up in smoke when anyone touches it, or the owner's caught.
func _tick_clone(ent: Dictionary, dt: float) -> bool:
	var owner := player_by_id(int(ent["owner"]))
	if owner == null or owner.state != State.PLAY:
		_event("poof", -1, -1, ent["pos"].x, ent["pos"].y)
		return true
	ent["vel"] = owner.vel
	ent["pos"] = move_circle(ent["pos"], owner.vel * dt, RADIUS)
	for e: Player in team_of(1 - int(ent["team"])):
		if e.state == State.PLAY and not has_status(e, "ghost") and not is_airborne(e) and e.pos.distance_to(ent["pos"]) < RADIUS * 2.0:
			_apply_cc(e, {"stun": 1.0}, null)
			_event("poof", e.id, -1, ent["pos"].x, ent["pos"].y)
			return true
	return false


## True when a decoy got caught.
func _tick_decoy(ent: Dictionary, dt: float) -> bool:
	ent["cd"] = float(ent["cd"]) - dt
	if float(ent["cd"]) <= 0.0:
		ent["cd"] = rng.randf_range(0.6, 1.4)
		ent["vel"] = Vector2.RIGHT.rotated(rng.randf() * TAU) * SPEED
	var before: Vector2 = ent["pos"]
	ent["pos"] = move_circle(before, ent["vel"] * dt, RADIUS)
	if (ent["pos"] as Vector2).distance_squared_to(before) < 0.0004:
		ent["cd"] = 0.0
	for e: Player in team_of(1 - int(ent["team"])):
		if e.state == State.PLAY and not has_status(e, "ghost") and not is_airborne(e) and e.pos.distance_to(ent["pos"]) < RADIUS * 2.0:
			_apply_cc(e, {"stun": 1.0}, null)
			_event("poof", e.id, -1, ent["pos"].x, ent["pos"].y)
			return true
	return false


func _tick_sentry(ent: Dictionary, dt: float) -> void:
	ent["cd"] = float(ent["cd"]) - dt
	if float(ent["cd"]) > 0.0:
		return
	var best: Player = null
	var best_d := 11.0 * 11.0
	for e: Player in team_of(1 - int(ent["team"])):
		if e.state != State.PLAY or has_status(e, "ghost") or e.on_base or is_hidden_from(e, int(ent["team"])):
			continue
		var d: float = e.pos.distance_squared_to(ent["pos"])
		if d < best_d and clear_line(ent["pos"], e.pos, true):
			best_d = d
			best = e
	if best == null:
		return
	ent["cd"] = 1.3
	var aim: Vector2 = (best.pos - ent["pos"]).normalized()
	shots.append({"uid": _next_uid(), "pw": "sentry_buddy", "team": ent["team"], "owner": ent["owner"], "pos": ent["pos"] + aim * 0.8,
		"vel": aim * 18.0, "r": 0.35, "life": 0.8, "bounces": 0, "homing": false, "pierce": false, "hit": []})
	_event("sentry_shot", -1, -1, ent["pos"].x, ent["pos"].y)


func _tick_walls() -> void:
	if walls.is_empty():
		return
	for i: int in walls.keys():
		if float(walls[i]) <= t:
			walls.erase(i)


# --- Results --------------------------------------------------------------------------------------

## A rough performance score: what the results screen ranks players by.
## How long the match has run, in seconds.
func played_seconds() -> float:
	return MATCH_TIME - time_left + (OVERTIME if overtime else 0.0)


func stats_score(p: Player) -> int:
	return p.tags * 30 + p.rescues * 25 + p.captures * 100 + p.powers_used * 3 - p.times_jailed * 5


func mvp() -> int:
	var best := -1
	var best_score := -999999
	for p in players:
		var s := stats_score(p)
		if s > best_score:
			best_score = s
			best = p.id
	return best


# --- Copying a match to other players ------------------------------------------------------------

const P_STRIDE := 18
const PICKUP_STRIDE := 6
const PICKUPS_EVERY := 45  ## Crystals are only sent when they change, or now and then just in case.

## Everything a viewer (or a new host) needs. Designed to stay small: about 1 KB, 15 times a second.
func to_snapshot() -> Dictionary:
	var floats := PackedFloat32Array()
	floats.resize(players.size() * P_STRIDE)
	var statuses: Array = []
	var powers: Array = []
	var stats: Array = []
	for i in players.size():
		var p := players[i]
		var o := i * P_STRIDE
		floats[o] = p.pos.x
		floats[o + 1] = p.pos.y
		floats[o + 2] = p.vel.x
		floats[o + 3] = p.vel.y
		floats[o + 4] = p.face.x
		floats[o + 5] = p.face.y
		floats[o + 6] = p.fresh
		floats[o + 7] = float(p.state)
		floats[o + 8] = p.jail_left
		floats[o + 9] = p.free_until
		floats[o + 10] = p.dash_cd
		floats[o + 11] = p.leap_t
		floats[o + 12] = p.leap_dur
		floats[o + 13] = 1.0 if p.on_base else 0.0
		floats[o + 14] = p.spin_left
		floats[o + 15] = p.swap_left
		floats[o + 16] = p.skill_cd[0]
		floats[o + 17] = p.skill_cd[1]
		var packed := PackedFloat32Array()
		for name: String in p.status:
			var index := STATUS_NAMES.find(name)
			if index >= 0:
				packed.append(index)
				packed.append(p.status[name])
		statuses.append(packed)
		var held := PackedInt32Array()
		for id: String in p.powers:
			held.append(Powerups.index_of(id))
		powers.append(held)
		stats.append(PackedInt32Array([p.tags, p.rescues, p.captures, p.times_jailed, p.powers_used, p.skills_used]))
	var snap := {"t": t, "ph": phase, "pl": phase_left, "tl": time_left, "ot": overtime, "fi": fiesta, "sc": score, "cap": cap, "cg": capturing,
		"lk": base_lock, "ra": radar, "w": winner, "er": end_reason, "p": floats, "st": statuses, "pw": powers, "ss": stats,
		"fo": fountains, "zn": zones, "sh": shots, "en": ents, "wl": walls, "ev": take_events(), "uid": _uid,
		"we": weather, "wn": wind, "cr": crumbles, "tn": tnt, "wb": webs}
	var packed_pickups := _pack_pickups()
	_snapshots_since_pickups += 1
	if packed_pickups != _last_pickups or _snapshots_since_pickups >= PICKUPS_EVERY:
		_last_pickups = packed_pickups
		_snapshots_since_pickups = 0
		snap["pk"] = packed_pickups
	return snap


func _pack_pickups() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(pickups.size() * PICKUP_STRIDE)
	for i in pickups.size():
		var item: Dictionary = pickups[i]
		var o := i * PICKUP_STRIDE
		out[o] = item["uid"]
		out[o + 1] = (item["pos"] as Vector2).x
		out[o + 2] = (item["pos"] as Vector2).y
		out[o + 3] = item["born"]
		out[o + 4] = float(item.get("trap", -1))
		out[o + 5] = float(item.get("gone", -1.0))
	return out


func _unpack_pickups(data: PackedFloat32Array) -> void:
	pickups.clear()
	for o in range(0, data.size(), PICKUP_STRIDE):
		var item := {"uid": int(data[o]), "pos": Vector2(data[o + 1], data[o + 2]), "born": data[o + 3]}
		if data[o + 4] >= 0.0:
			item["trap"] = int(data[o + 4])
		if data[o + 5] >= 0.0:
			item["gone"] = data[o + 5]
		pickups.append(item)


func apply_snapshot(snap: Dictionary) -> void:
	t = snap["t"]
	phase = snap["ph"]
	phase_left = snap["pl"]
	time_left = snap["tl"]
	overtime = snap["ot"]
	fiesta = snap["fi"]
	score = snap["sc"]
	cap = snap["cap"]
	capturing = snap["cg"]
	base_lock = snap["lk"]
	radar = snap["ra"]
	winner = snap["w"]
	end_reason = snap["er"]
	_uid = snap["uid"]
	var floats: PackedFloat32Array = snap["p"]
	var statuses: Array = snap["st"]
	var powers: Array = snap["pw"]
	var stats: Array = snap["ss"]
	for i in players.size():
		var p := players[i]
		var o := i * P_STRIDE
		p.pos = Vector2(floats[o], floats[o + 1])
		p.vel = Vector2(floats[o + 2], floats[o + 3])
		p.face = Vector2(floats[o + 4], floats[o + 5])
		p.fresh = floats[o + 6]
		p.state = int(floats[o + 7]) as State
		p.jail_left = floats[o + 8]
		p.free_until = floats[o + 9]
		p.dash_cd = floats[o + 10]
		p.leap_t = floats[o + 11]
		p.leap_dur = floats[o + 12]
		p.on_base = floats[o + 13] > 0.5
		p.spin_left = floats[o + 14]
		p.swap_left = floats[o + 15]
		p.skill_cd[0] = floats[o + 16]
		p.skill_cd[1] = floats[o + 17]
		p.status.clear()
		var packed: PackedFloat32Array = statuses[i]
		for s in range(0, packed.size(), 2):
			p.status[STATUS_NAMES[int(packed[s])]] = packed[s + 1]
		p.powers.clear()
		for index: int in (powers[i] as PackedInt32Array):
			p.powers.append(Powerups.id_at(index))
		var st: PackedInt32Array = stats[i]
		p.tags = st[0]
		p.rescues = st[1]
		p.captures = st[2]
		p.times_jailed = st[3]
		p.powers_used = st[4]
		p.skills_used = st[5]
	if snap.has("pk"):
		_unpack_pickups(snap["pk"])
	fountains = snap["fo"]
	zones.assign(snap["zn"])
	shots.assign(snap["sh"])
	ents.assign(snap["en"])
	walls = snap["wl"]
	events.append_array(snap["ev"])
	if snap["we"] != weather:
		set_weather(snap["we"])
	wind = snap["wn"]
	crumbles = snap["cr"]
	tnt = snap["tn"]
	webs = snap["wb"]
