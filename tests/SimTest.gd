extends SceneTree
## Rules and balance checks, no window needed:
##   godot --headless --path . --script res://tests/SimTest.gd

var _fails := 0


func _init() -> void:
	_test_fresher_rule()
	_test_jail_and_rescue()
	_test_capture()
	_test_wipeout()
	_test_every_power()
	_test_crystals()
	_test_faces()
	_test_tricks()
	_test_maps()
	_test_snapshot()
	_test_full_matches()
	print("SimTest: ", "OK" if _fails == 0 else "%d FAILED" % _fails)
	quit(1 if _fails > 0 else 0)


func _ok(cond: bool, what: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: ", what)


func _new_sim(map := "barrio_plaza") -> Sim:
	var sim := Sim.new()
	var seats: Array = []
	for i in 10:
		seats.append({"name": "P%d" % i, "bot": false})
	sim.setup(map, seats, 7)
	sim.phase = Sim.Phase.PLAY
	# Nobody near a pickup or a base unless a test puts them there.
	for p in sim.players:
		p.pos = sim.jail[p.team] + Vector2(0, 30)
		p.pos = p.pos.clamp(Vector2.ONE, sim.arena_size() - Vector2.ONE)
		p.on_base = false
	return sim


func _park_others(sim: Sim, keep: Array) -> void:
	var size := sim.arena_size()
	var i := 0
	for p in sim.players:
		if keep.has(p.id):
			continue
		# Parked in far corners, spread so nobody touches.
		p.pos = Vector2(1.0 + (i % 4) * 2.0, 1.0 + (i / 4) * 2.0) if p.team == 0 else Vector2(size.x - 1.0 - (i % 4) * 2.0, size.y - 1.0 - (i / 4) * 2.0)
		p.fresh = -50.0
		i += 1


func _test_fresher_rule() -> void:
	var sim := _new_sim()
	var a: Sim.Player = sim.players[0]  # team 0
	var b: Sim.Player = sim.players[1]  # team 1
	_park_others(sim, [0, 1])
	var mid := sim.arena_size() * 0.5
	a.pos = mid
	b.pos = mid + Vector2(0.5, 0)
	a.fresh = 10.0
	b.fresh = 5.0
	sim.t = 20.0
	_ok(sim.can_tag(a, b), "fresher player can tag")
	_ok(not sim.can_tag(b, a), "staler player can't tag")
	sim.step()
	_ok(b.state == Sim.State.JAIL, "touching the fresher player jails you")
	_ok(a.state == Sim.State.PLAY, "the fresher player stays free")
	_ok(a.tags == 1, "the tag is counted")
	_ok(b.pos.distance_to(sim.jail[a.team]) < Sim.JAIL_R, "prisoner stands in the tagger's jail")

	# Your own base is safe, and makes you fresh.
	sim = _new_sim()
	a = sim.players[0]
	b = sim.players[1]
	_park_others(sim, [0, 1])
	sim.t = 30.0
	a.fresh = 1.0
	b.fresh = 5.0
	a.pos = sim.base[0]
	b.pos = sim.base[0] + Vector2(0.6, 0)
	sim.step()
	_ok(a.state == Sim.State.PLAY, "safe on your own base")
	_ok(a.fresh > 29.0, "standing on base makes you fresh")
	_ok(b.state == Sim.State.JAIL, "a fresh defender tags the intruder")

	# A shield eats one tag.
	sim = _new_sim()
	a = sim.players[0]
	b = sim.players[1]
	_park_others(sim, [0, 1])
	var mid2 := sim.arena_size() * 0.5
	a.pos = mid2
	b.pos = mid2 + Vector2(0.4, 0)
	a.fresh = 10.0
	b.fresh = 5.0
	sim.t = 20.0
	b.status["shield"] = 30.0
	sim.step()
	_ok(b.state == Sim.State.PLAY, "shield blocks the tag")
	_ok(not sim.has_status(b, "shield"), "shield is used up")


func _test_jail_and_rescue() -> void:
	var sim := _new_sim()
	var prisoner: Sim.Player = sim.players[1]  # team 1, jailed by team 0
	var rescuer: Sim.Player = sim.players[3]  # team 1
	_park_others(sim, [1, 3])
	sim.t = 20.0
	prisoner.state = Sim.State.JAIL
	prisoner.jail_left = 10.0
	prisoner.pos = sim.jail[0]
	rescuer.fresh = 19.0
	rescuer.pos = sim.jail[0] + Vector2(0.5, 0)
	sim.step()
	_ok(prisoner.state == Sim.State.PLAY, "a teammate at the jail frees prisoners")
	_ok(sim.is_free_walking(prisoner), "freed players get a free walk")
	_ok(sim.is_free_walking(rescuer), "the rescuer gets a free walk")
	_ok(rescuer.rescues == 1, "rescue is counted")

	# Jail runs out on its own, faster when you mash.
	sim = _new_sim()
	var p: Sim.Player = sim.players[0]
	_park_others(sim, [0])
	p.state = Sim.State.JAIL
	p.jail_left = 0.5
	p.pos = sim.jail[1]
	p.want_mash = true
	sim.step()
	_ok(p.jail_left < 0.5 - Sim.MASH_SAVE + 0.01, "mashing shortens jail")
	for _i in 30:
		sim.step()
	_ok(p.state == Sim.State.PLAY and p.on_base, "jail ends at home")


## Crystals hold nothing until they're grabbed, and a new power can't be used until its spin is over.
func _test_crystals() -> void:
	var sim := _new_sim()
	var a: Sim.Player = sim.players[0]
	_park_others(sim, [0])
	sim.pickups.clear()
	sim._spawn_pickup(a.pos)
	var crystal: Dictionary = sim.pickups[0]
	_ok(not crystal.has("pw"), "nothing on the field says what's in a crystal")
	sim.t = float(crystal["born"]) + 1.0
	a.pos = crystal["pos"]
	sim.step()
	_ok(a.powers.size() == 1, "walking into a crystal gives a power")
	_ok(a.spin_left > Sim.SPIN_TIME - 0.1, "and it starts to spin")
	a.want_use = true
	sim.step()
	_ok(a.powers.size() == 1 and a.powers_used == 0, "a spinning power can't be used")
	var copy := _new_sim()
	copy.apply_snapshot(sim.to_snapshot())
	_ok(is_equal_approx(copy.players[0].spin_left, a.spin_left), "the spin goes over the network")
	sim.pickups.clear()
	a.powers = ["rocket_slippers", "tailwind"] as Array[String]
	a.spin_left = Sim.SPIN_TIME
	a.want_use = true
	sim.step()
	_ok(a.powers == (["tailwind"] as Array[String]), "the card before it can be, while the second one spins")
	a.want_use = true
	sim.step()
	_ok(a.powers.size() == 1, "but then the second has to finish first")
	for _i in int(Sim.SPIN_TIME / Sim.TICK) + 2:
		sim.step()
	a.want_use = true
	sim.step()
	_ok(a.powers.is_empty(), "once it stops, it can be used")


## A bare sim with one tile of a kind just ahead of player 0, and everyone else out of the way.
func _trick_sim(code: int) -> Array:
	var sim := _new_sim()
	var a: Sim.Player = sim.players[0]
	_park_others(sim, [0])
	sim.pickups.clear()
	var x := sim.w / 2 - 3
	var y := sim.h - 2
	var tile := y * sim.w + x
	sim.tiles[tile] = code
	sim.tiles[y * sim.w + x + 1] = Maps.FLOOR
	sim.tiles[y * sim.w + x - 1] = Maps.FLOOR
	a.pos = sim.tile_center(tile - 1)
	a.on_base = false
	a.mv = Vector2.ZERO
	a.fresh = 0.0
	return [sim, a, tile]


func _test_tricks() -> void:
	# Dash floors shoot you the way they point, even standing still.
	var parts := _trick_sim(Maps.DASH_L)
	var sim: Sim = parts[0]
	var a: Sim.Player = parts[1]
	var tile: int = parts[2]
	a.pos = sim.tile_center(tile)
	var from_x := a.pos.x
	for _i in 10:
		sim.step()
	_ok(a.pos.x < from_x - 3.0, "a dash floor shoots you along it")
	# Jump pads land you exactly on their landing box, untouchable on the way.
	parts = _trick_sim(Maps.JUMP)
	sim = parts[0]
	a = parts[1]
	tile = parts[2]
	var land := tile - sim.w * 6
	sim.tiles[land] = Maps.LAND
	sim.jumps = {tile: land}
	a.pos = sim.tile_center(tile)
	sim.step()
	_ok(sim.is_airborne(a), "a jump pad throws you in the air")
	for _i in 60:
		sim.step()
	_ok(not sim.is_airborne(a) and sim.tile_index(a.pos) == land, "and you land on its box")
	# A low fence stops a walk and not a dash.
	parts = _trick_sim(Maps.FENCE)
	sim = parts[0]
	a = parts[1]
	tile = parts[2]
	a.mv = Vector2.RIGHT
	for _i in 40:
		a.mv = Vector2.RIGHT
		sim.step()
	_ok(a.pos.x < sim.tile_center(tile).x, "you can't walk through a low fence")
	a.mv = Vector2.RIGHT
	a.dash_cd = 0.0
	a.want_dash = true
	for _i in 16:
		a.mv = Vector2.RIGHT
		sim.step()
	_ok(a.pos.x > sim.tile_center(tile).x + 0.5, "but a dash goes over it")
	# Gates open and shut, and a gate shutting on you moves you out.
	parts = _trick_sim(Maps.GATE)
	sim = parts[0]
	a = parts[1]
	tile = parts[2]
	sim.t = Sim.GATE_SHUT + 0.5
	_ok(not sim._blocks_feet(tile), "an open gate lets you through")
	a.pos = sim.tile_center(tile)
	sim.t = Sim.GATE_CYCLE - 0.01
	for _i in 3:
		sim.step()
	_ok(sim._blocks_feet(tile), "then it shuts")
	_ok(sim.tile_index(a.pos) != tile, "and it moves you out of the way")
	# A fountain makes you fresh once, then needs refilling.
	parts = _trick_sim(Maps.FOUNTAIN)
	sim = parts[0]
	a = parts[1]
	tile = parts[2]
	sim.fountains = {tile: 0.0}
	sim.t = 50.0
	a.pos = sim.tile_center(tile)
	sim.step()
	_ok(a.fresh >= 50.0, "a fountain makes you fresh")
	_ok(not sim.fountain_ready(tile), "and then it's empty")
	var copy := _new_sim()
	copy.apply_snapshot(sim.to_snapshot())
	_ok(not copy.fountain_ready(tile), "which goes over the network")
	# Altars grow crystals, but only one at a time.
	parts = _trick_sim(Maps.ALTAR)
	sim = parts[0]
	a = parts[1]
	tile = parts[2]
	sim.altars = {tile: 0.0}
	sim._spawn_timer = 999.0
	a.pos = sim.tile_center(tile) + Vector2(0, 12)
	a.pos = a.pos.clamp(Vector2.ONE, sim.arena_size() - Vector2.ONE)
	sim.step()
	_ok(sim.pickups.size() == 1, "an altar grows a crystal")
	sim.altars[tile] = 0.0
	sim.step()
	_ok(sim.pickups.size() == 1, "but not a second on top of it")
	# Bumpers knock you away.
	parts = _trick_sim(Maps.BUMPER)
	sim = parts[0]
	a = parts[1]
	tile = parts[2]
	sim._bumpers = PackedInt32Array([tile])
	a.mv = Vector2.RIGHT
	var start := a.pos.x
	for _i in 6:
		a.mv = Vector2.RIGHT
		sim.step()
	for _i in 10:
		a.mv = Vector2.ZERO
		sim.step()
	_ok(a.pos.x < start - 1.0, "a bumper knocks you flying")
	# Every map's jump pads lead to real landing boxes, and every map has some tricks in it.
	for id: String in Maps.LAYOUT_ORDER:
		var whole := Sim.new()
		var map_id := ""
		for map: Dictionary in Maps.all():
			if map["layout"] == id:
				map_id = map["id"]
				break
		whole.setup(map_id, [], 1)
		for pad: int in whole.jumps:
			_ok(whole.tiles[pad] == Maps.JUMP and whole.tiles[whole.jumps[pad]] == Maps.LAND, "%s: jump pad and box" % id)
		_ok(not whole.fountains.is_empty() or not whole.altars.is_empty(), "%s has things to fight over" % id)
		# Both bases can still reach each other on foot, for anyone.
		var field := whole.flow_field(whole.tile_index(whole.base[1]))
		_ok(field[whole.tile_index(whole.base[0])] >= 0, "%s: you can walk from base to base" % id)
		_ok(field[whole.tile_index(whole.jail[0])] >= 0, "%s: you can walk to the jail" % id)


## Everything the game asks an avatar's face to do has to exist.
func _test_faces() -> void:
	for entry: Dictionary in Cosmetics.FACES:
		_ok(Faces.PARTS.has(entry["expr"]), "%s is a face" % entry["expr"])
	for list: Array in [Faces.FUNNY, Faces.TAGGING, Faces.TAGGED, Faces.CHEERING, Faces.BOOING, Faces.GOT_CRYSTAL]:
		for face: String in list:
			_ok(Faces.PARTS.has(face), "%s is a face" % face)
	for state: String in Faces.DURING:
		for face: String in Faces.DURING[state]:
			_ok(Faces.PARTS.has(face), "%s is a face" % face)


func _test_capture() -> void:
	var sim := _new_sim()
	var a: Sim.Player = sim.players[0]
	_park_others(sim, [0])
	sim.pickups.clear()
	a.pos = sim.base[1]
	a.fresh = 0.0
	var ticks := 0
	while sim.phase == Sim.Phase.PLAY and ticks < 300:
		a.pos = sim.base[1]
		sim.step()
		ticks += 1
	_ok(sim.score[0] == 1, "standing on the enemy base scores")
	_ok(ticks < int((Sim.CAPTURE_TIME + 0.5) / Sim.TICK), "capture takes about CAPTURE_TIME (%d ticks)" % ticks)

	# A locked base can't be captured.
	sim = _new_sim()
	a = sim.players[0]
	_park_others(sim, [0])
	sim.base_lock[1] = 999.0
	for _i in 200:
		a.pos = sim.base[1]
		sim.step()
	_ok(sim.score[0] == 0, "base lock stops a capture")

	# A defender on the base slows a capture down.
	sim = _new_sim()
	a = sim.players[0]
	var d: Sim.Player = sim.players[1]
	_park_others(sim, [0, 1])
	for _i in int(Sim.CAPTURE_TIME * 1.5 / Sim.TICK):
		a.pos = sim.base[1] + Vector2(2.0, 0)
		d.pos = sim.base[1] + Vector2(-2.0, 0)
		d.camp = 0.0
		sim.step()
	_ok(sim.score[0] == 0 and float(sim.cap[1]) > 0.3, "a defender on the base slows a capture")

	# Camp too long and the pad pops you off.
	sim = _new_sim()
	d = sim.players[0]
	_park_others(sim, [0])
	var popped := false
	for _i in int((Sim.CAMP_LIMIT + 0.5) / Sim.TICK):
		if d.leap_t < 0.0:
			d.pos = sim.base[0]
		sim.step()
		popped = popped or d.leap_t >= 0.0
	_ok(popped, "the pad pops off campers")


func _test_wipeout() -> void:
	var sim := _new_sim()
	for p: Sim.Player in sim.team_of(1):
		p.state = Sim.State.JAIL
		p.jail_left = 50.0
		p.pos = sim.jail[0]
	for p: Sim.Player in sim.team_of(0):
		p.pos = sim.base[0]
	sim.step()
	_ok(sim.score[0] == 1, "jailing the whole team scores")


## Every powerup runs, for a human and a bot, on a map with hazards, without errors.
func _test_every_power() -> void:
	_ok(Powerups.ALL.size() >= 50, "there are plenty of powerups (%d)" % Powerups.ALL.size())
	for def: Dictionary in Powerups.ALL:
		var id: String = def["id"]
		for key: String in ["name", "desc", "cat", "tier", "kind", "ai", "sfx"]:
			_ok(def.has(key), "%s has %s" % [id, key])
		_ok(FileAccess.file_exists(Powerups.icon_path(id)), "%s has an icon" % id)
		var sim := _new_sim("volcano_conveyors" if Maps.by_id("volcano_conveyors") else "barrio_plaza")
		var a: Sim.Player = sim.players[0]
		var e: Sim.Player = sim.players[1]
		var mid := sim.arena_size() * 0.5
		a.pos = mid + Vector2(-3, 0)
		e.pos = mid
		e.fresh = 100.0
		a.powers = [id] as Array[String]
		a.want_use = true
		a.mv = Vector2.RIGHT
		for _i in 90:
			sim.step()
		_ok(a.powers_used == 1, "%s was used" % id)
		_ok(a.pos.x >= 0.0 and a.pos.y >= 0.0 and a.pos.x <= sim.arena_size().x, "%s keeps the player in the arena" % id)


func _test_maps() -> void:
	var all := Maps.all()
	_ok(all.size() >= 40, "there are plenty of maps (%d)" % all.size())
	var names := {}
	for map: Dictionary in all:
		_ok(not names.has(map["name"]), "map names are unique: %s" % map["name"])
		names[map["name"]] = true
	for layout: String in Maps.LAYOUT_ORDER:
		var rows: Array = Maps.LAYOUTS[layout]["rows"]
		_ok(rows.size() == 15, "%s has 15 rows" % layout)
		var saw := {}
		for row: String in rows:
			_ok(row.length() == 14, "%s rows are 14 wide: '%s'" % [layout, row])
			for c in row:
				saw[c] = true
		_ok(saw.has("A") and saw.has("J"), "%s has a base and a jail" % layout)
	for map: Dictionary in all:
		var sim := Sim.new()
		sim.setup(map["id"], [], 3)
		# Both bases, both jails and most of the field are reachable on foot.
		var field := sim.flow_field(sim.tile_index(sim.base[0]))
		var id: String = map["id"]
		var pads_help: bool = Maps.LAYOUTS[map["layout"]]["rows"].any(func(r: String) -> bool: return "b" in r or "t" in r)
		_ok(field[sim.tile_index(sim.base[1])] >= 0 or pads_help, "%s: base to base on foot" % id)
		_ok(field[sim.tile_index(sim.jail[0])] >= 0, "%s: own jail reachable" % id)
		_ok(field[sim.tile_index(sim.jail[1])] >= 0 or pads_help, "%s: enemy jail reachable" % id)
		_ok(sim.base[0].x < sim.base[1].x, "%s: team 0 is on the left" % id)
		_ok(sim._pickup_tiles.size() > 30, "%s: room for powerups" % id)
		# Fair ground: every tile matches its mirror.
		for i in sim.w * sim.h:
			var code := sim.tiles[i]
			var other := sim.tiles[sim._mirror_tile(i)]
			var same := code == other or (code >= Maps.CON_R and other >= Maps.CON_R)
			if not same:
				_ok(false, "%s: tile %d is not mirrored" % [id, i])
				break


func _test_snapshot() -> void:
	var host := _new_sim()
	host.players[0].powers = ["freeze_ray"] as Array[String]
	host.players[0].want_use = true
	host.players[2].status["speed"] = 50.0
	for _i in 60:
		host.step()
	var bytes := var_to_bytes(host.to_snapshot())
	_ok(bytes.size() < 4000, "a snapshot is small (%d bytes)" % bytes.size())
	var client := _new_sim()
	client.authoritative = false
	client.apply_snapshot(bytes_to_var(bytes))
	_ok(is_equal_approx(client.t, host.t), "snapshot copies the clock")
	for i in 10:
		_ok(client.players[i].pos.distance_to(host.players[i].pos) < 0.001, "snapshot copies position %d" % i)
	_ok(client.has_status(client.players[2], "speed"), "snapshot copies statuses")


## Bots play real matches on every layout: they must finish, score and tag, without getting stuck.
func _test_full_matches() -> void:
	var total_score := 0
	var total_tags := 0
	var total_rescues := 0
	var total_used := 0
	var wins := [0, 0, 0]
	var started := Time.get_ticks_msec()
	var ticks := 0
	for layout: String in Maps.LAYOUT_ORDER:
		var map_id := ""
		for map: Dictionary in Maps.all():
			if map["layout"] == layout:
				map_id = map["id"]
				break
		var sim := Sim.new()
		sim.setup(map_id, [], 100 + total_tags, 0.7)
		var guard := 0
		while sim.phase != Sim.Phase.END and guard < 30 * 260:
			sim.step()
			sim.take_events()
			guard += 1
		ticks += guard
		_ok(sim.phase == Sim.Phase.END, "%s: the match ends" % map_id)
		wins[sim.winner] += 1
		var tags := 0
		for p in sim.players:
			tags += p.tags
			total_rescues += p.rescues
			total_used += p.powers_used
		print("  %-24s %d-%d  winner %d  %-8s tags %d  %.0fs left" % [map_id, sim.score[0], sim.score[1], sim.winner, sim.end_reason, tags, sim.time_left])
		_ok(tags >= 5, "%s: bots actually tag (%d)" % [map_id, tags])
		total_tags += tags
		total_score += sim.score[0] + sim.score[1]
	var ms := Time.get_ticks_msec() - started
	print("  total: points %d, tags %d, rescues %d, powers used %d, wins %s, %.3f ms/tick" % [total_score, total_tags, total_rescues, total_used, wins, float(ms) / maxi(ticks, 1)])
	_ok(total_rescues > 0, "bots rescue")
	_ok(total_used > 50, "bots use powerups")
	_ok(total_score * 2 >= Maps.LAYOUT_ORDER.size() * 3, "matches have enough points (%d)" % total_score)
	_ok(int(wins[2]) <= 3, "few draws (%d)" % int(wins[2]))
	_ok(float(ms) / maxi(ticks, 1) < 2.0, "a tick with 10 bots is cheap")
