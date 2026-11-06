class_name BotBrain
extends RefCounted
## How computer players think. They only use what a human could see: enemies hidden in grass or under a
## cloak don't exist for them, and they read "who is fresher" with some mistakes at low skill.
##
## Skill (0..1) sets reaction time, how far a bot looks, how often it misjudges, and how well it uses
## powerups. It does not give them extra speed: slower bots are a little slower, top bots are not faster
## than a human.

const THINK_MIN := 0.1
const THINK_MAX := 0.5


func think(sim: Sim, p: Sim.Player, dt: float) -> void:
	var mem := p.brain
	if p.state == Sim.State.JAIL:
		# Mash to break out, at a human-looking rate.
		mem["mash"] = float(mem.get("mash", 0.0)) - dt
		if float(mem["mash"]) <= 0.0:
			mem["mash"] = lerpf(0.5, 0.18, p.skill) * sim.rng.randf_range(0.8, 1.2)
			p.want_mash = true
		p.mv = Vector2.ZERO
		return
	mem["t"] = float(mem.get("t", 0.0)) - dt
	if float(mem["t"]) > 0.0:
		_steer(sim, p, mem)
		return
	mem["t"] = lerpf(THINK_MAX, THINK_MIN, p.skill) * sim.rng.randf_range(0.85, 1.15)
	_decide(sim, p, mem)
	_steer(sim, p, mem)


## Every so often a team pushes together: one bot alone only feeds the jail.
func _tick_wave(sim: Sim, team: int) -> void:
	if sim.t >= float(sim.wave_next[team]):
		sim.wave_until[team] = sim.t + sim.rng.randf_range(14.0, 20.0)
		sim.wave_next[team] = sim.t + sim.rng.randf_range(24.0, 34.0)


func _decide(sim: Sim, p: Sim.Player, mem: Dictionary) -> void:
	_tick_wave(sim, p.team)
	var sight := lerpf(12.0, 22.0, p.skill)
	var threats: Array[Sim.Player] = []
	var prey: Array[Sim.Player] = []
	var enemies_near := 0
	for e: Sim.Player in sim.team_of(1 - p.team):
		if e.state != Sim.State.PLAY or sim.is_hidden_from(e, p.team):
			continue
		var d := e.pos.distance_to(p.pos)
		if d > sight:
			continue
		enemies_near += 1
		var fresh_gap := sim.fresh_value(e) - sim.fresh_value(p)
		if sim.has_status(e, "ghost") or sim.is_free_walking(e):
			continue
		if fresh_gap > 0.01 and not sim.is_held(e) and not p.on_base:
			threats.append(e)
		elif fresh_gap < -0.01 and not e.on_base:
			prey.append(e)
	var threat := _closest(p, threats)
	var target := _closest(p, prey)
	var threat_d := threat.pos.distance_to(p.pos) if threat else INF
	var target_d := target.pos.distance_to(p.pos) if target else INF
	_use_powers(sim, p, threat, target, threat_d, target_d, enemies_near)
	var home: Vector2 = sim.base[p.team]
	var home_d := p.pos.distance_to(home)
	var jailed_mates := 0
	for mate: Sim.Player in sim.team_of(p.team):
		if mate.state == Sim.State.JAIL:
			jailed_mates += 1
	var intruders := _intruders(sim, p.team)
	var goal := p.pos
	var mode := "roam"
	# On a final run at the enemy base it's too late to turn back: a capture is worth a trip to jail.
	var enemy_base_d: float = p.pos.distance_to(sim.base[1 - p.team])
	var all_in := enemy_base_d < 16.0 and not sim.is_free_walking(p) 			and (float(sim.wave_until[p.team]) > sim.t or float(sim.cap[1 - p.team]) > 0.25 or enemy_base_d < Sim.BASE_R + 1.0)
	if all_in:
		mode = "capture"
		goal = sim.base[1 - p.team]
		if enemy_base_d > Sim.BASE_R and p.dash_cd <= 0.0:
			p.want_dash = true
	# Otherwise running for your life beats everything: home makes you safe and fresh again.
	elif threat and threat_d < lerpf(4.0, 8.5, p.skill) and not sim.is_free_walking(p):
		mode = "flee"
		goal = _flee_point(sim, p, threat, _nearest_safety(sim, p))
		if threat_d < 3.2 and p.dash_cd <= 0.0 and sim.rng.randf() < p.skill:
			p.want_dash = true
	elif sim.is_free_walking(p):
		mode = "home"
		goal = home
	elif target and target_d < _chase_range(sim, p) and _safe_chase(sim, p, target) and _chasers_on(sim, p, target) < 2:
		mode = "chase"
		mem["prey"] = target.id
		goal = target.pos + target.vel * minf(target_d / Sim.SPEED, 0.5) * p.skill
		if target_d < 4.0 and target_d > 1.2 and p.dash_cd <= 0.0 and sim.rng.randf() < p.skill * 0.9:
			p.want_dash = true
	else:
		var job := _job(sim, p, jailed_mates, intruders)
		mode = job
		match job:
			"guard":
				goal = _guard_point(sim, p, intruders)
			"rescue":
				goal = sim.jail[1 - p.team]
			"attack":
				goal = _attack_point(sim, p)
			"pickup":
				goal = _nearest_pickup(sim, p)
			"refresh":
				goal = _nearest_refresh(sim, p, home)
			_:
				goal = _roam_point(sim, p, mem)
	if mode in ["attack", "home", "refresh", "rescue", "guard", "pickup"]:
		goal = _shortcut(sim, p, goal)
	mem["goal"] = goal
	mem["mode"] = mode
	# A blocked goal (a target across water) falls back on walking round by the flow field.
	mem["direct"] = sim.clear_line(p.pos, goal)
	mem["flow_at"] = sim.tile_index(goal)


## A jump pad or dash floor nearby that really does get a bot closer to where it's going, or else the goal itself.
func _shortcut(sim: Sim, p: Sim.Player, goal: Vector2) -> Vector2:
	if sim.rng.randf() > lerpf(0.2, 0.9, p.skill):
		return goal
	var straight := p.pos.distance_to(goal)
	var best := goal
	var best_saved := 6.0
	for pad: int in sim.jumps:
		var at := sim.tile_center(pad)
		var to_pad := p.pos.distance_to(at)
		if to_pad > 12.0:
			continue
		var saved := straight - (to_pad + sim.tile_center(sim.jumps[pad]).distance_to(goal))
		if saved > best_saved:
			best_saved = saved
			best = at
	return best


## Safety is just over the line. Across the field that's nearer than the base; deep in enemy ground, it still is.
func _nearest_safety(sim: Sim, p: Sim.Player) -> Vector2:
	var mid := sim.arena_size().x * 0.5
	return Vector2(mid + (-2.5 if p.team == 0 else 2.5), p.pos.y)


## Back over the line, or a full fountain if one's closer.
func _nearest_refresh(sim: Sim, p: Sim.Player, _home: Vector2) -> Vector2:
	var best := _nearest_safety(sim, p)
	var best_d := p.pos.distance_to(best)
	for tile: int in sim.fountains:
		if sim.fountain_ready(tile):
			var at := sim.tile_center(tile)
			if at.distance_to(p.pos) < best_d:
				best_d = at.distance_to(p.pos)
				best = at
	return best


## How far a bot will go after someone: not far while its team is pushing on the enemy base.
func _chase_range(sim: Sim, p: Sim.Player) -> float:
	if float(sim.wave_until[p.team]) > sim.t:
		return 4.0
	return lerpf(6.0, 13.0, p.skill)


## Two chasers are enough; the rest of the team has better things to do.
func _chasers_on(sim: Sim, p: Sim.Player, target: Sim.Player) -> int:
	var count := 0
	for mate: Sim.Player in sim.team_of(p.team):
		if mate != p and String(mate.brain.get("mode", "")) == "chase" and int(mate.brain.get("prey", -1)) == target.id:
			count += 1
	return count


## What this bot does when nobody is close. Roles rotate with its seat, so a team spreads out.
func _job(sim: Sim, p: Sim.Player, jailed: int, intruders: int) -> String:
	var role := p.id % Sim.TEAM_SIZE
	var mates: Array = sim.team_of(p.team)
	var seat := mates.find(p)
	role = seat
	var stale_for := sim.t - p.fresh
	var waving := float(sim.wave_until[p.team]) > sim.t
	if intruders > 0 and (role == 0 or p.pos.distance_to(sim.base[p.team]) < 11.0):
		return "guard"
	if jailed >= 1 and (role == 2 or role == 3 or jailed >= 2) and stale_for < 22.0:
		return "rescue"
	if waving and role > 0:
		return "attack"
	if p.powers.size() < Sim.MAX_POWERS and not sim.pickups.is_empty():
		var near := _nearest_pickup(sim, p)
		if near.distance_to(p.pos) < lerpf(10.0, 19.0, p.skill):
			return "pickup"
	if stale_for > lerpf(26.0, 14.0, p.skill) and sim.rng.randf() < 0.5:
		return "refresh"
	if role == 0:
		return "guard"
	if role == 1 and sim.rng.randf() < 0.5:
		return "roam"
	return "attack"


func _intruders(sim: Sim, team: int) -> int:
	var count := 0
	for e: Sim.Player in sim.team_of(1 - team):
		if e.state == Sim.State.PLAY and not sim.is_hidden_from(e, team) and e.pos.distance_to(sim.base[team]) < Sim.BASE_R + 7.0:
			count += 1
	return count


func _guard_point(sim: Sim, p: Sim.Player, intruders: int) -> Vector2:
	var home: Vector2 = sim.base[p.team]
	if intruders == 0:
		var mates: Array = sim.team_of(p.team)
		var angle := TAU * float(mates.find(p)) / mates.size() + sim.t * 0.2
		# Hover at the edge of the pad: it pops off anyone who camps on it. Step on it now and then.
		var dip := sin(sim.t * 0.5 + p.id) > 0.7
		return home + Vector2.RIGHT.rotated(angle) * (Sim.BASE_R - 0.8 if dip else Sim.BASE_R + 1.6)
	var closest: Sim.Player = null
	var best := INF
	for e: Sim.Player in sim.team_of(1 - p.team):
		if e.state == Sim.State.PLAY and not sim.is_hidden_from(e, p.team):
			var d: float = e.pos.distance_to(home)
			if d < best:
				best = d
				closest = e
	return closest.pos if closest else home


func _attack_point(sim: Sim, p: Sim.Player) -> Vector2:
	var enemy_base: Vector2 = sim.base[1 - p.team]
	# Fresh enemies on or beside their base would tag us on arrival: hang back and bait them out,
	# unless the team is pushing together or the enemy is short of people.
	var guards := 0
	var free_enemies := 0
	for e: Sim.Player in sim.team_of(1 - p.team):
		if e.state != Sim.State.PLAY:
			continue
		free_enemies += 1
		if e.pos.distance_to(enemy_base) < Sim.BASE_R + 3.0 and sim.fresh_value(e) > sim.fresh_value(p):
			guards += 1
	if guards == 0 or free_enemies <= 2 or float(sim.wave_until[p.team]) > sim.t 			or sim.has_status(p, "ghost") or sim.has_status(p, "overcharge") or sim.has_status(p, "shield"):
		return enemy_base
	var wobble := sin(sim.t * 0.9 + p.id * 1.7) * 7.0
	var at_line := _nearest_safety(sim, p)
	return Vector2(at_line.x, clampf(enemy_base.y + wobble, 1.5, sim.arena_size().y - 1.5))


func _nearest_pickup(sim: Sim, p: Sim.Player) -> Vector2:
	var best: Vector2 = p.pos
	var best_d := INF
	for item: Dictionary in sim.pickups:
		var d: float = p.pos.distance_squared_to(item["pos"])
		if d < best_d:
			best_d = d
			best = item["pos"]
	return best


func _roam_point(sim: Sim, p: Sim.Player, mem: Dictionary) -> Vector2:
	if not mem.has("roam") or (mem["roam"] as Vector2).distance_to(p.pos) < 2.0 or sim.rng.randf() < 0.02:
		var size := sim.arena_size()
		var own_side: float = sim.base[p.team].x
		var x := lerpf(own_side, size.x * 0.5, sim.rng.randf_range(0.3, 1.1))
		mem["roam"] = Vector2(x, sim.rng.randf_range(2.0, size.y - 2.0))
	return mem["roam"]


## Don't chase someone onto their own doorstep, where fresh defenders wait.
func _safe_chase(sim: Sim, p: Sim.Player, target: Sim.Player) -> bool:
	var their_base: Vector2 = sim.base[target.team]
	if target.pos.distance_to(their_base) > Sim.BASE_R + 4.0 or sim.has_status(p, "overcharge"):
		return true
	for e: Sim.Player in sim.team_of(target.team):
		if e != target and e.state == Sim.State.PLAY and e.pos.distance_to(their_base) < Sim.BASE_R + 2.0:
			return false
	return true


func _flee_point(sim: Sim, p: Sim.Player, threat: Sim.Player, home: Vector2) -> Vector2:
	var away := (p.pos - threat.pos).normalized()
	var to_home := (home - p.pos).normalized()
	# Run home if that doesn't mean running through the chaser; otherwise run straight away.
	if to_home.dot(away) > -0.2 or p.pos.distance_to(home) < 6.0:
		return home
	return p.pos + (away + away.orthogonal() * sin(sim.t * 2.0 + p.id) * 0.5).normalized() * 7.0


## Sets the stick for this tick: straight at the goal if the way is clear, else by the flow field.
func _steer(sim: Sim, p: Sim.Player, mem: Dictionary) -> void:
	var goal: Vector2 = mem.get("goal", p.pos)
	if p.pos.distance_to(goal) < 0.25:
		p.mv = Vector2.ZERO
		return
	var dir := Vector2.ZERO
	if bool(mem.get("direct", true)) and not _pad_ahead(sim, p, goal):
		dir = (goal - p.pos).normalized()
	else:
		dir = _flow_dir(sim, p, int(mem.get("flow_at", -1)), goal)
	# Avoid walking into a pit edge or wall head-on when pushed off course.
	if sim.has_status(p, "blind"):
		dir = dir.rotated(sin(sim.t * 3.0 + p.id) * 0.9)
	if _road_busy(sim, p, dir):
		dir = Vector2.ZERO
	p.mv = dir
	p.aim = Vector2.ZERO


## Good bots wait at the kerb when something's coming. Worse ones don't look.
func _road_busy(sim: Sim, p: Sim.Player, dir: Vector2) -> bool:
	if sim.lanes.is_empty() or p.skill < 0.35:
		return false
	var ahead := p.pos + dir * 1.8
	if sim.tile_at(ahead) != Maps.ROAD or sim.tile_at(p.pos) == Maps.ROAD:
		return false
	for lane: Dictionary in sim.lanes:
		if absf(ahead.x - float(lane["x"])) < 1.4 and absf(ahead.y - sim.lane_at(lane)) < 7.0:
			return true
	return false


## Is there a pad just ahead that the bot didn't mean to step on, and that would throw it away from its goal?
func _pad_ahead(sim: Sim, p: Sim.Player, goal: Vector2) -> bool:
	var to_goal := goal - p.pos
	var length := to_goal.length()
	if length < 0.01:
		return false
	var dir := to_goal / length
	for step: float in [1.0, 2.2]:
		if step > length:
			break
		var i := sim.tile_index(p.pos + dir * step)
		if i < 0 or sim.tile_center(i).distance_to(goal) < 1.0:
			continue
		match sim.tiles[i]:
			Maps.JUMP, Maps.SPIKES, Maps.GEYSER, Maps.QUICKSAND, Maps.WEB:
				return true
			Maps.DASH_R:
				if dir.x < 0.2: return true
			Maps.DASH_L:
				if dir.x > -0.2: return true
			Maps.DASH_U:
				if dir.y > -0.2: return true
			Maps.DASH_D:
				if dir.y < 0.2: return true
	return false


func _flow_dir(sim: Sim, p: Sim.Player, target: int, goal: Vector2) -> Vector2:
	if target < 0:
		return (goal - p.pos).normalized()
	var field := sim.flow_field(target)
	var here := sim.tile_index(p.pos)
	if here < 0 or (field[here] < 0):
		return (goal - p.pos).normalized()
	var x := here % sim.w
	var y := here / sim.w
	var best := here
	var best_d := field[here]
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx := x + dx
			var ny := y + dy
			if nx < 0 or ny < 0 or nx >= sim.w or ny >= sim.h:
				continue
			var ni := ny * sim.w + nx
			if field[ni] < 0 or field[ni] >= best_d:
				continue
			# No cutting a corner through a wall.
			if dx != 0 and dy != 0:
				if field[y * sim.w + nx] < 0 or field[ny * sim.w + x] < 0:
					continue
			best_d = field[ni]
			best = ni
	if best == here:
		return (goal - p.pos).normalized()
	return (sim.tile_center(best) - p.pos).normalized()


func _closest(p: Sim.Player, list: Array[Sim.Player]) -> Sim.Player:
	var best: Sim.Player = null
	var best_d := INF
	for e in list:
		var d := e.pos.distance_squared_to(p.pos)
		if d < best_d:
			best_d = d
			best = e
	return best


func _use_powers(sim: Sim, p: Sim.Player, threat: Sim.Player, target: Sim.Player, threat_d: float, target_d: float, near: int) -> void:
	if not sim.can_use_power(p) or sim.rng.randf() > lerpf(0.25, 0.8, p.skill):
		return
	var def := Powerups.by_id(p.powers[0])
	var hint: String = def.get("ai", "any")
	var use := false
	var aim_at: Sim.Player = null
	match hint:
		"chase":
			use = target != null and target_d < 11.0
			aim_at = target
		"flee":
			use = threat != null and threat_d < 7.0
			aim_at = threat
		"attack":
			var to_base: float = p.pos.distance_to(sim.base[1 - p.team])
			use = to_base < 14.0 or String(p.brain.get("mode", "")) == "attack"
		"guard":
			use = _intruders(sim, p.team) > 0
		"jail":
			var jailed := 0
			for mate: Sim.Player in sim.team_of(p.team):
				if mate.state == Sim.State.JAIL:
					jailed += 1
			use = jailed >= 2
		_:
			use = true
	# Holding two means the first has waited long enough.
	if not use and p.powers.size() >= Sim.MAX_POWERS and sim.rng.randf() < 0.15:
		use = true
	if near == 0 and hint in ["chase", "flee"]:
		use = false
	if not use:
		return
	if aim_at:
		p.aim = (aim_at.pos - p.pos).normalized()
	elif String(def.get("kind", "")) in ["hop", "blink", "grapple", "portal", "slam"]:
		var goal: Vector2 = p.brain.get("goal", sim.base[1 - p.team])
		p.aim = (goal - p.pos).normalized()
	p.want_use = true
