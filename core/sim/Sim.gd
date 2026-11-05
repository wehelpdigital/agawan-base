class_name Sim
extends RefCounted
## The rules of the game, with no scenes or rendering: the same code runs a practice match on your
## device and an online match on whichever player hosts it. Everything a viewer needs is plain data,
## so to_snapshot()/apply_snapshot() can copy a match to other players, or hand it to a new host.
##
## The rules come from the traditional game of Agawan Base (Prisoner's Base):
## - Whoever left their base most recently is "fresher". When two opponents touch, the fresher one
##   tags the other. Touching your own base makes you fresh again, and you are safe on it.
## - A tagged player goes to the jail beside the tagger's base. A free teammate who reaches that jail
##   frees everyone in it, and rescuers and freed players get a short "free walk": nobody can tag
##   them, and they can't tag or capture.
## - Stand on the enemy base long enough to capture it, or jail the whole enemy team at once: a point.
##   First to 3 points, or the most points when time runs out, then sudden death on a tie, and after
##   that the team that took the most prisoners.
## One rule is ours, because camping is no fun on a screen: stay on your own base for 5 seconds and the
## pad pops you off it.

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
const BASE_R := 2.8
const JAIL_R := 2.2
const CAPTURE_TIME := 1.4
const CAMP_LIMIT := 5.0  ## Seconds on your own base before the pad pops you off it.
const MATCH_TIME := 180.0
const FIESTA_AT := 60.0  ## Seconds left when powerups start to rain faster.
const OVERTIME := 45.0
const WIN_POINTS := 3
const COUNTDOWN := 3.0
const SCORED_PAUSE := 3.2
const MAX_POWERS := 2
const TEAM_SIZE := 5

enum Phase { COUNTDOWN, PLAY, SCORED, END }
enum State { PLAY, JAIL }

## Statuses that stop you moving.
const HELD := ["stun", "freeze", "root"]
## Short names of statuses in snapshots (index -> name).
const STATUS_NAMES: Array[String] = ["speed", "speed2", "slow", "stun", "freeze", "root", "slip", "reverse", "fear",
	"blind", "shield", "ghost", "invis", "giant", "tiny", "overcharge", "stale", "chain", "mirror", "fastcap",
	"dashboost", "firetrail"]


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
	var brain := {}  ## The bot's memory (BotBrain.gd).
	var away := false  ## An online player whose connection dropped: a bot plays for them.


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
var _spawn_timer := 3.0
var _spawn_side := 0
var _pickup_tiles := PackedInt32Array()
var _flow := {}
var _brain := BotBrain.new()
var _team_cache: Array = [[], []]


## seats: [{name, team?, bot, skill, look}], up to 10; missing seats become bots at `difficulty`.
func setup(p_map_id: String, seats: Array, seed_value := 0, p_difficulty := 0.6) -> void:
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
		players.append(p)
	_rebuild_teams()
	_reset_round(true)


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
			if code in [Maps.FLOOR, Maps.GRASS, Maps.ICE, Maps.MUD]:
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
			p.status.clear()
			p.brain.clear()
	cap = [0.0, 0.0]
	capturing = [0, 0]
	zones.clear()
	shots.clear()
	ents.clear()
	walls.clear()
	if first:
		pickups.clear()


func _spawn_point(team: int, i: int, count: int) -> Vector2:
	var angle := TAU * float(i) / maxf(count, 1)
	return base[team] + Vector2.RIGHT.rotated(angle) * 1.3


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
	var code := tiles[i]
	return code == Maps.SOLID or code == Maps.PIT or (walls.has(i) and walls[i] > t)


func _blocks_shots(i: int) -> bool:
	return tiles[i] == Maps.SOLID or (walls.has(i) and walls[i] > t)


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
			if code == Maps.SOLID or code == Maps.PIT:
				continue
			dist[ni] = next
			queue.append(ni)
	_flow[target] = dist
	return dist


# --- Fresher rule ---------------------------------------------------------------------------------

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
	return fresh_value(a) > fresh_value(b)


func radius_of(p: Player) -> float:
	if has_status(p, "giant"):
		return RADIUS * 1.7
	if has_status(p, "tiny"):
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
	if tile_at(p.pos) == Maps.MUD and not has_status(p, "ghost"):
		s *= 0.6
	return s


func is_held(p: Player) -> bool:
	for name: String in HELD:
		if has_status(p, name):
			return true
	return false


## Hidden from `team`'s eyes? (Invisible, or deep in tall grass with nobody close.)
func is_hidden_from(p: Player, team: int) -> bool:
	if p.team == team or radar[team] > t:
		return false
	if has_status(p, "invis"):
		return true
	if tile_at(p.pos) != Maps.GRASS:
		return false
	for other: Player in team_of(team):
		if other.state == State.PLAY and other.pos.distance_to(p.pos) < 3.5:
			return false
	return true


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
	p.mash_cd = maxf(p.mash_cd - dt, 0.0)
	if p.state == State.JAIL:
		_tick_jailed(p, dt)
		return
	if p.want_dash and p.dash_cd <= 0.0 and not is_held(p) and not is_airborne(p):
		_start_dash(p)
	p.want_dash = false
	if p.want_use and not p.powers.is_empty() and not is_held(p) and not is_airborne(p):
		_use_power(p)
	p.want_use = false
	_move(p, dt)
	var home_d: float = p.pos.distance_to(base[p.team])
	var was_on := p.on_base
	p.on_base = home_d < BASE_R and not is_airborne(p)
	if p.on_base:
		p.fresh = t
		if p.free_until > t:
			p.free_until = -1.0
		if not was_on:
			_event("home", p.id)
		p.camp += dt
		if p.camp >= CAMP_LIMIT:
			_pop_off_base(p)
	else:
		p.camp = 0.0
	if has_status(p, "firetrail"):
		p.trail_cd -= dt
		if p.trail_cd <= 0.0:
			p.trail_cd = 0.22
			zones.append({"uid": _next_uid(), "fx": "fire", "team": p.team, "pos": p.pos, "r": 1.0, "until": t + 3.0, "drift": Vector2.ZERO, "pw": "hot_trail", "armed": true})


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
			if name == "ghost" or name == "giant":
				_unstick(p)


func _tick_jailed(p: Player, dt: float) -> void:
	p.jail_left -= dt
	if p.want_mash and p.mash_cd <= 0.0:
		p.mash_cd = MASH_GAP
		p.jail_left -= MASH_SAVE
	p.want_mash = false
	p.want_dash = false
	p.want_use = false
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
	p.dash_left = DASH_TIME
	p.dash_cd = DASH_COOLDOWN
	p.status.erase("invis")
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
		return
	var input := p.mv.limit_length(1.0)
	if has_status(p, "reverse"):
		input = -input
	if has_status(p, "fear"):
		input = (p.pos - p.fear_from).normalized()
	if is_held(p):
		input = Vector2.ZERO
	var code := tile_at(p.pos)
	var ghost := has_status(p, "ghost")
	var slippery := (code == Maps.ICE or has_status(p, "slip")) and not ghost
	var desired := input * speed_of(p)
	if p.dash_left > 0.0:
		p.dash_left -= dt
		p.vel = p.dash_dir * DASH_SPEED
	else:
		p.vel = p.vel.lerp(desired, clampf((3.0 if slippery else 22.0) * dt, 0.0, 1.0))
	if input.length() > 0.1 and not is_held(p):
		p.face = p.face.slerp(input.normalized(), clampf(16.0 * dt, 0.0, 1.0)).normalized()
	var total := p.vel + p.kb
	if not ghost:
		match code:
			Maps.CON_R: total.x += 5.0
			Maps.CON_L: total.x -= 5.0
			Maps.CON_U: total.y -= 5.0
			Maps.CON_D: total.y += 5.0
	p.kb *= exp(-7.0 * dt)
	if p.kb.length() < 0.05:
		p.kb = Vector2.ZERO
	p.pos = move_circle(p.pos, total * dt, radius_of(p), ghost)
	if ghost or p.pad_cd > 0.0:
		return
	var here := tile_index(p.pos)
	if here < 0:
		return
	if tiles[here] == Maps.BOUNCE:
		_launch(p, tile_center(_mirror_tile(here)), 0.8)
		_event("bounce", p.id, -1, p.pos.x, p.pos.y)
	elif tiles[here] == Maps.TELE and tele.has(here):
		var out: int = tele[here]
		p.pos = tile_center(out)
		p.pad_cd = 1.0
		_event("warp", p.id, -1, p.pos.x, p.pos.y)


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
				if b.state != State.PLAY or is_airborne(b):
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
			mate.fresh = -1.0  # Stale until they touch home again.
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
			if p.state == State.PLAY and not is_airborne(p) and not is_free_walking(p) and not has_status(p, "ghost") \
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
	_spawn_timer -= dt
	if _spawn_timer <= 0.0 and _pickup_tiles.size() > 0:
		_spawn_timer = rng.randf_range(1.5, 3.0) if fiesta else rng.randf_range(3.0, 5.5)
		if pickups.size() < (12 if fiesta else 8):
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
				p.powers.append(String(item["pw"]))
				_event("pick", p.id, -1, p.pos.x, p.pos.y, item["pw"])
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
	var pw := Powerups.roll(rng)
	pickups.append({"uid": _next_uid(), "pw": pw, "pos": at, "born": t})
	_event("drop", -1, -1, at.x, at.y, pw)


func _pickup_near(at: Vector2) -> bool:
	for item: Dictionary in pickups:
		if at.distance_squared_to(item["pos"]) < 9.0:
			return true
	return false


func _next_uid() -> int:
	_uid += 1
	return _uid


# --- Using powerups -------------------------------------------------------------------------------

func _use_power(p: Player) -> void:
	var id: String = p.powers.pop_front()
	var def := Powerups.by_id(id)
	if def.is_empty():
		return
	p.powers_used += 1
	var aim := _resolve_aim(p, def)
	p.aim = Vector2.ZERO
	if id != "invisi_cloak":
		p.status.erase("invis")
	_event("use", p.id, -1, p.pos.x, p.pos.y, id)
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
			_launch(p, to, 0.65)
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
			_event("quake", p.id)
		"meteors":
			_meteors(p, def)
		"wall":
			_build_wall(p, aim, int(def["len"]), float(def["dur"]))
		"baselock":
			base_lock[p.team] = t + float(def["dur"])
			_event("lock", p.team, -1, base[p.team].x, base[p.team].y)
		"sentry":
			ents.append({"uid": _next_uid(), "type": "sentry", "team": p.team, "owner": p.id, "pos": p.pos, "vel": Vector2.ZERO, "until": t + float(def["dur"]), "cd": 0.5})
		"snares":
			_ring_of_traps(p.team, base[p.team], BASE_R + 1.3, int(def["count"]), "snare", float(def["dur"]), id)
		"mines":
			_ring_of_traps(p.team, p.pos, 2.4, int(def["count"]), "mine", float(def["dur"]), id)
		"hedge":
			zones.append({"uid": _next_uid(), "fx": "thorn", "team": p.team, "pos": base[p.team], "r": BASE_R + 1.6, "until": t + float(def["dur"]), "drift": Vector2.ZERO, "pw": id, "armed": true})
		"fresh":
			p.fresh = t
		"swap":
			_swap(p, float(def["range"]))
		"curse":
			var target := _nearest_enemy(p, float(def["range"]))
			if target:
				_give_statuses(target, def["status"])
				_event("cc", target.id, p.id, target.pos.x, target.pos.y, "stale")
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
					mate.fresh = t
					_event("refreshed", mate.id, -1, mate.pos.x, mate.pos.y)
		"radar":
			radar[p.team] = t + float(def["dur"])
		"rain":
			for _i in int(def["count"]):
				_spawn_pickup(p.pos)


func _resolve_aim(p: Player, def: Dictionary) -> Vector2:
	if p.aim.length() > 0.2:
		return p.aim.normalized()
	if String(def["kind"]) == "shot" or String(def["kind"]) == "zone":
		var target := _nearest_enemy(p, float(def.get("range", 16.0)))
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
		"homing": bool(def.get("homing", false)), "pierce": bool(def.get("pierce", false)), "hit": []})


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
		if other.state == State.PLAY and not has_status(other, "ghost"):
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
		var next: Vector2 = s["pos"] + s["vel"] * dt
		var tile := tile_index(next)
		var ended := float(s["life"]) <= 0.0
		if tile < 0 or _blocks_shots(tile):
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
	var best: Player = null
	var best_d := 18.0 * 18.0
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
		s["vel"] = (s["vel"] as Vector2).lerp(want, clampf(5.0 * dt, 0.0, 1.0)).normalized() * speed


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
		if int(ent["team"]) != int(s["team"]) and String(ent["type"]) == "decoy" and (ent["pos"] as Vector2).distance_to(s["pos"]) < float(s["r"]) + RADIUS:
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
		if has_status(e, "mirror"):  # Back it goes, now on the mirror's side.
			s["team"] = e.team
			s["vel"] = -(s["vel"] as Vector2)
			s["owner"] = e.id
			s["hit"] = []
			_event("reflect", e.id, -1, e.pos.x, e.pos.y)
			return false
		(s["hit"] as Array).append(e.id)
		var owner := player_by_id(int(s["owner"]))
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
		zones.append({"uid": _next_uid(), "fx": burst["fx"], "team": s["team"], "pos": s["pos"], "r": float(burst["r"]),
			"until": t + float(burst["dur"]), "drift": Vector2.ZERO, "pw": s["pw"], "armed": true})


func _tick_zones(dt: float) -> void:
	for i in range(zones.size() - 1, -1, -1):
		var z: Dictionary = zones[i]
		if float(z["until"]) <= t:
			if z["fx"] == "meteor":
				_meteor_lands(z)
			zones.remove_at(i)
			continue
		if z["drift"] != Vector2.ZERO:
			var drifted: Vector2 = z["pos"] + z["drift"] * dt
			var tile := tile_index(drifted)
			if tile >= 0 and not _blocks_shots(tile):
				z["pos"] = drifted
			else:
				z["drift"] = -(z["drift"] as Vector2)
		if z["fx"] == "meteor":
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
	return false


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
		else:
			_tick_sentry(ent, dt)


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

const P_STRIDE := 14

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
		stats.append(PackedInt32Array([p.tags, p.rescues, p.captures, p.times_jailed, p.powers_used]))
	return {"t": t, "ph": phase, "pl": phase_left, "tl": time_left, "ot": overtime, "fi": fiesta, "sc": score, "cap": cap, "cg": capturing,
		"lk": base_lock, "ra": radar, "w": winner, "er": end_reason, "p": floats, "st": statuses, "pw": powers, "ss": stats,
		"pk": pickups, "zn": zones, "sh": _pack_shots(), "en": ents, "wl": walls, "ev": take_events(), "uid": _uid}


func _pack_shots() -> Array:
	var out: Array = []
	for s: Dictionary in shots:
		out.append({"uid": s["uid"], "pw": s["pw"], "team": s["team"], "owner": s["owner"], "pos": s["pos"], "vel": s["vel"], "r": s["r"],
			"life": s["life"], "bounces": s["bounces"], "homing": s["homing"], "pierce": s["pierce"], "hit": s["hit"]})
	return out


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
	pickups.assign(snap["pk"])
	zones.assign(snap["zn"])
	shots.assign(snap["sh"])
	ents.assign(snap["en"])
	walls = snap["wl"]
	events.append_array(snap["ev"])
