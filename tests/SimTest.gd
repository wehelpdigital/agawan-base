extends SceneTree
## Rules and balance checks, no window needed:
##   godot --headless --path . --script res://tests/SimTest.gd

var _fails := 0


func _init() -> void:
	_test_side_rule()
	_test_jail_and_rescue()
	_test_capture()
	_test_wipeout()
	_test_every_power()
	_test_crystals()
	_test_faces()
	_test_tricks()
	_test_world_elements()
	_test_weather()
	_test_new_powers()
	_test_shop_items()
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
	sim.setup(map, seats, 7, 0.6, "clear")
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


func _test_side_rule() -> void:
	var sim := _new_sim()
	var a: Sim.Player = sim.players[0]  # team 0, on the left
	var b: Sim.Player = sim.players[1]  # team 1, on the right
	_park_others(sim, [0, 1])
	var mid := sim.arena_size() * 0.5
	sim.t = 20.0
	a.pos = mid - Vector2(4.0, 0)
	b.pos = mid - Vector2(3.5, 0)
	b.fresh = 19.0
	sim.step()
	_ok(b.state == Sim.State.JAIL, "on your side, you tag an invader")
	_ok(a.state == Sim.State.PLAY, "and you stay free")
	_ok(a.tags == 1, "the tag is counted")
	_ok(b.pos.distance_to(sim.jail[a.team]) < Sim.JAIL_R, "prisoner stands in the tagger's jail")

	# And the other way round, over on their side.
	sim = _new_sim()
	a = sim.players[0]
	b = sim.players[1]
	_park_others(sim, [0, 1])
	mid = sim.arena_size() * 0.5
	sim.t = 20.0
	a.pos = mid + Vector2(3.5, 0)
	b.pos = mid + Vector2(4.0, 0)
	a.fresh = 19.0
	sim.step()
	_ok(a.state == Sim.State.JAIL, "over the line, they tag you")
	_ok(b.tags == 1, "and they get the tag")

	# Either side of the line, nose to nose, nobody can touch anybody.
	sim = _new_sim()
	a = sim.players[0]
	b = sim.players[1]
	_park_others(sim, [0, 1])
	mid = sim.arena_size() * 0.5
	sim.t = 20.0
	a.pos = mid - Vector2(0.25, 0)
	b.pos = mid + Vector2(0.25, 0)
	for _i in 5:
		sim.step()
		_ok(a.state == Sim.State.PLAY and b.state == Sim.State.PLAY, "no tags across the line")

	# Going home makes you safe again.
	sim = _new_sim()
	a = sim.players[0]
	_park_others(sim, [0])
	mid = sim.arena_size() * 0.5
	sim.t = 20.0
	a.pos = mid + Vector2(6.0, 0)
	a.fresh = 10.0
	sim.step()
	_ok(not sim.on_home_side(a) and a.fresh < sim.t, "over the line, your clock runs")
	a.pos = mid - Vector2(6.0, 0)
	sim.step()
	_ok(sim.on_home_side(a) and a.fresh >= sim.t - Sim.TICK, "back on your side, it stops")

	# Charged by a fountain or a card, you can tag on their side too.
	sim = _new_sim()
	a = sim.players[0]
	b = sim.players[1]
	_park_others(sim, [0, 1])
	mid = sim.arena_size() * 0.5
	sim.t = 20.0
	a.pos = mid + Vector2(3.5, 0)
	b.pos = mid + Vector2(4.0, 0)
	a.fresh = sim.t + Sim.CHARGE_TIME
	_ok(sim.is_charged(a), "a charge shows")
	sim.step()
	_ok(b.state == Sim.State.JAIL and a.state == Sim.State.PLAY, "charged, you tag them on their own side")

	# Your own base is safe.
	sim = _new_sim()
	a = sim.players[0]
	b = sim.players[1]
	_park_others(sim, [0, 1])
	sim.t = 30.0
	a.pos = sim.base[0]
	b.pos = sim.base[0] + Vector2(0.6, 0)
	b.fresh = sim.t + Sim.CHARGE_TIME
	sim.step()
	_ok(a.state == Sim.State.PLAY, "safe on your own base, even from a charged enemy")

	# A shield eats one tag.
	sim = _new_sim()
	a = sim.players[0]
	b = sim.players[1]
	_park_others(sim, [0, 1])
	mid = sim.arena_size() * 0.5
	a.pos = mid - Vector2(4.0, 0)
	b.pos = mid - Vector2(3.6, 0)
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
	_ok(sim.is_charged(a), "a fountain charges you")
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
	var run_ids := {}
	for run: Dictionary in Cosmetics.list("run"):
		run_ids[run["id"]] = true
	for hero: Dictionary in Cosmetics.list("char"):
		var who := Faces.person(hero["id"])
		_ok(not who.is_empty(), "%s has a personality" % hero["id"])
		_ok(Faces.GAGS.has(who.get("gag", "")), "%s has a gag" % hero["id"])
		_ok(run_ids.has(who.get("run", "")), "%s has a real walk" % hero["id"])
		_ok((who.get("lines", []) as Array).size() == 3, "%s has things to say" % hero["id"])
		_ok((who.get("likes", []) as Array).size() >= 3, "%s has favourite faces" % hero["id"])
		for face: String in who.get("likes", []):
			_ok(Faces.PARTS.has(face), "%s is a face" % face)
	for gag: String in Faces.GAGS:
		_ok(Faces.PARTS.has(Faces.GAGS[gag]["face"]), "%s has a real face" % gag)
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


func _step_until(sim: Sim, cond: Callable, most := 900) -> bool:
	for _i in most:
		if cond.call():
			return true
		sim.step()
		sim.take_events()
	return cond.call()


## Each thing on the world maps does what it says.
func _test_world_elements() -> void:
	# Spikes: harmless until they come up.
	var parts := _trick_sim(Maps.SPIKES)
	var sim: Sim = parts[0]
	var a: Sim.Player = parts[1]
	var tile: int = parts[2]
	a.pos = sim.tile_center(tile)
	_ok(not sim.spikes_up(), "spikes start down")
	_ok(_step_until(sim, func() -> bool: return sim.has_status(a, "stun")), "spikes stun whoever's on them when they come up")
	# Crumbling floor: goes after a moment, drops you off it, and grows back.
	parts = _trick_sim(Maps.CRUMBLE)
	sim = parts[0]
	a = parts[1]
	tile = parts[2]
	a.pos = sim.tile_center(tile)
	sim.step()
	_ok(sim.crumbles.has(tile) and not sim.crumble_gone(tile), "a crumbling floor starts to go when you stand on it")
	_ok(_step_until(sim, func() -> bool: return sim.crumble_gone(tile), 60), "and falls")
	sim.step()
	_ok(sim.tile_index(a.pos) != tile, "nobody's left standing where it was")
	_ok(_step_until(sim, func() -> bool: return not sim.crumbles.has(tile), 400), "and it grows back")
	# Powder crates: a wall, until a dash sets it off; then gone, and later back.
	parts = _trick_sim(Maps.TNT)
	sim = parts[0]
	a = parts[1]
	tile = parts[2]
	var other: Sim.Player = sim.players[1]
	other.on_base = false
	other.pos = sim.tile_center(tile) + Vector2(2.0, 0)
	a.mv = Vector2.RIGHT
	for _i in 20:
		a.mv = Vector2.RIGHT
		sim.step()
	_ok(a.pos.x < sim.tile_center(tile).x and sim.tnt_here(tile), "a crate stops a walk")
	a.dash_cd = 0.0
	a.want_dash = true
	for _i in 8:
		a.mv = Vector2.RIGHT
		sim.step()
	_ok(not sim.tnt_here(tile), "a dash blows it up")
	_ok(sim.has_status(other, "stun"), "and it stuns whoever's nearby, on either team")
	_ok(_step_until(sim, func() -> bool: return sim.tnt_here(tile), 700), "and it comes back")
	# Web and lookout tower.
	parts = _trick_sim(Maps.WEB)
	sim = parts[0]
	a = parts[1]
	tile = parts[2]
	a.pos = sim.tile_center(tile)
	sim.step()
	_ok(sim.has_status(a, "root") and not sim.web_here(tile), "a web catches you once")
	parts = _trick_sim(Maps.TOWER)
	sim = parts[0]
	a = parts[1]
	tile = parts[2]
	a.pos = sim.tile_center(tile)
	sim.step()
	_ok(float(sim.radar[a.team]) > sim.t, "a lookout shows your team everyone")
	# Quicksand holds you back, and a geyser throws you.
	parts = _trick_sim(Maps.QUICKSAND)
	sim = parts[0]
	a = parts[1]
	tile = parts[2]
	var dry := sim.speed_of(a)
	a.pos = sim.tile_center(tile)
	_ok(sim.speed_of(a) < dry * 0.6, "quicksand slows you right down")
	parts = _trick_sim(Maps.GEYSER)
	sim = parts[0]
	a = parts[1]
	tile = parts[2]
	a.pos = sim.tile_center(tile)
	_ok(_step_until(sim, func() -> bool: return sim.is_airborne(a), 240), "a geyser blows you into the air")
	# Stepping stones take turns.
	parts = _trick_sim(Maps.STONE)
	sim = parts[0]
	tile = parts[2]
	var sunk_seen := false
	var up_seen := false
	for _i in 300:
		sim.step()
		sim.take_events()
		sim.players[0].pos = sim.tile_center(tile - 1)
		if sim.stone_sunk(tile):
			sunk_seen = sunk_seen or sim._blocks_feet(tile)
		else:
			up_seen = up_seen or not sim._blocks_feet(tile)
	_ok(sunk_seen and up_seen, "a stepping stone sinks and rises")
	# The tide comes in.
	parts = _trick_sim(Maps.TIDE)
	sim = parts[0]
	a = parts[1]
	tile = parts[2]
	a.pos = sim.tile_center(tile)
	dry = sim.speed_of(a)
	_ok(_step_until(sim, func() -> bool:
		a.pos = sim.tile_center(tile)
		return sim.tide_high(), 600), "the tide comes in")
	_ok(sim.speed_of(a) < dry * 0.7, "and wades you down")
	# A spinning arm knocks you away.
	var map_sim := _new_sim("rome_gladiator")
	_ok(not map_sim.arms.is_empty(), "the gladiator pit has spinning arms")
	_park_others(map_sim, [0])
	var hit := map_sim.players[0]
	var arm: Dictionary = map_sim.arms[0]
	hit.on_base = false
	hit.pos = (arm["at"] as Vector2) + Vector2(0, 2.4)
	var hit_at := hit.pos
	_ok(_step_until(map_sim, func() -> bool:
		hit.pos = hit_at
		hit.kb = Vector2.ZERO if not map_sim.has_status(hit, "stun") else hit.kb
		return map_sim.has_status(hit, "stun"), 200), "a spinning arm hits you as it comes round")
	# Traffic doesn't stop.
	var road_sim := _new_sim("tokyo_rush_hour")
	_ok(not road_sim.lanes.is_empty(), "rush hour has roads")
	_park_others(road_sim, [0])
	var walker := road_sim.players[0]
	var lane: Dictionary = road_sim.lanes[0]
	walker.on_base = false
	var kerb := Vector2(float(lane["x"]), (float(lane["y0"]) + float(lane["y1"])) * 0.5)
	_ok(_step_until(road_sim, func() -> bool:
		walker.pos = kerb
		return road_sim.has_status(walker, "stun"), 400), "traffic runs you over if you stand in the road")


func _test_weather() -> void:
	for id: String in Weather.ALL:
		var def := Weather.def(id)
		for key: String in ["name", "icon", "hint", "sight", "grip", "speed", "wind", "strike", "dash"]:
			_ok(def.has(key), "%s has %s" % [id, key])
		_ok(FileAccess.file_exists("res://assets/icons/ui/%s.svg" % def["icon"]), "%s has an icon" % id)
	for theme_id: String in Maps.THEME_ORDER:
		var info := Maps.theme_info(theme_id)
		_ok(info.has("region") and info.has("place"), "%s says where it is" % theme_id)
		for kind: String in info.get("weather", []):
			_ok(Weather.ALL.has(kind), "%s: %s is real weather" % [theme_id, kind])
		_ok(not (info.get("weather", []) as Array).is_empty(), "%s has weather" % theme_id)
	# Fog hides who's far away, not who's close.
	var sim := _new_sim()
	sim.set_weather("fog")
	_park_others(sim, [0, 1])
	var me: Sim.Player = sim.players[0]
	var them: Sim.Player = sim.players[1]
	for p: Sim.Player in sim.team_of(0):
		if p != me:
			p.state = Sim.State.JAIL
	me.pos = sim.arena_size() * 0.5
	them.pos = me.pos + Vector2(sim.sight_range + 4.0, 0)
	_ok(sim.is_hidden_from(them, 0), "fog hides someone far off")
	them.pos = me.pos + Vector2(sim.sight_range - 3.0, 0)
	_ok(not sim.is_hidden_from(them, 0), "but not someone close")
	# Rain makes you slide, wind shoves you, heat slows your dash.
	var dry := _new_sim()
	var wet := _new_sim()
	wet.set_weather("rain")
	for s: Sim in [dry, wet]:
		_park_others(s, [0])
		var p: Sim.Player = s.players[0]
		p.on_base = false
		p.pos = s.arena_size() * 0.5
		p.vel = Vector2.RIGHT * Sim.SPEED
		p.mv = Vector2.LEFT
		for _i in 6:
			p.mv = Vector2.LEFT
			s.step()
	_ok(wet.players[0].vel.x > dry.players[0].vel.x + 1.0, "rain makes you slide when you turn")
	var windy := _new_sim()
	windy.set_weather("wind")
	_park_others(windy, [0])
	var leaf: Sim.Player = windy.players[0]
	leaf.on_base = false
	leaf.pos = windy.arena_size() * 0.5
	var was := leaf.pos
	for _i in 90:
		leaf.mv = Vector2.ZERO
		windy.step()
	_ok(leaf.pos.distance_to(was) > 1.5, "wind pushes you along (%.1f m)" % leaf.pos.distance_to(was))
	var hot := _new_sim()
	hot.set_weather("heat")
	hot.players[0].want_dash = true
	hot.players[0].mv = Vector2.RIGHT
	hot.step()
	_ok(hot.players[0].dash_cd > Sim.DASH_COOLDOWN * 1.2, "heat makes your dash slower to come back")
	# Storms come down on marked spots.
	var stormy := _new_sim()
	stormy.set_weather("storm")
	_ok(_step_until(stormy, func() -> bool:
		for z: Dictionary in stormy.zones:
			if z["fx"] == "strike":
				return true
		return false, 300), "storms mark where they'll strike")
	# A match in every kind of weather runs to the end.
	for id: String in Weather.ORDER:
		var game := Sim.new()
		game.setup("tokyo_rush_hour", [], 9, 0.7, id)
		_ok(game.weather == id, "you can ask for %s" % id)
		for _i in 30 * 40:
			game.step()
			game.take_events()
			if game.phase == Sim.Phase.END:
				break


func _power_sim(id: String, map := "barrio_plaza") -> Array:
	var sim := _new_sim(map)
	_park_others(sim, [0, 1])
	sim.pickups.clear()
	var a: Sim.Player = sim.players[0]
	var e: Sim.Player = sim.players[1]
	a.on_base = false
	e.on_base = false
	a.pos = sim.arena_size() * 0.5 + Vector2(-4.0, 0)
	e.pos = sim.arena_size() * 0.5 + Vector2(4.0, 0)
	a.powers = [id] as Array[String]
	a.want_use = true
	a.mv = Vector2.ZERO
	e.mv = Vector2.ZERO
	return [sim, a, e]


## The new cards do what they say on them.
func _test_new_powers() -> void:
	var parts := _power_sim("mega_wave")
	var sim: Sim = parts[0]
	var a: Sim.Player = parts[1]
	var e: Sim.Player = parts[2]
	sim.step()
	_ok(sim.has_status(a, "charging"), "Mega Wave makes you stand and charge")
	_ok(not sim.has_status(e, "stun"), "and doesn't hit until it's charged")
	_ok(_step_until(sim, func() -> bool: return sim.has_status(e, "stun"), 40), "then it hits")
	parts = _power_sim("homing_missile")
	sim = parts[0]
	e = parts[2]
	e.pos += Vector2(0, 7.0)
	_ok(_step_until(sim, func() -> bool: return sim.has_status(e, "stun"), 120), "Homing Missile finds its target")
	parts = _power_sim("ninja_clones")
	sim = parts[0]
	a = parts[1]
	sim.step()
	var clones := sim.ents.filter(func(ent: Dictionary) -> bool: return ent["type"] == "clone")
	_ok(clones.size() == 4, "Ninja Clones makes four clones")
	var clone_was: Vector2 = clones[0]["pos"]
	a.mv = Vector2.LEFT
	for _i in 10:
		a.mv = Vector2.LEFT
		sim.step()
	_ok((clones[0]["pos"] as Vector2).x < clone_was.x - 0.5, "and they copy your steps")
	parts = _power_sim("chicken_curse")
	sim = parts[0]
	a = parts[1]
	e = parts[2]
	sim.step()
	_ok(sim.has_status(e, "chicken"), "Chicken Curse lands")
	e.fresh = sim.t + 100.0
	_ok(not sim.can_tag(e, a), "and chickens can't tag")
	parts = _power_sim("rewind")
	sim = parts[0]
	a = parts[1]
	a.powers.clear()
	a.want_use = false
	var start := a.pos
	for _i in 60:
		a.mv = Vector2.UP
		sim.step()
	_ok(a.pos.distance_to(start) > 2.0, "(walked off)")
	a.powers = ["rewind"] as Array[String]
	a.want_use = true
	a.mv = Vector2.ZERO
	sim.step()
	_ok(a.pos.distance_to(start) < a.pos.distance_to(start + Vector2(0, -14.0)), "Rewind takes you back")
	parts = _power_sim("guardian_angel")
	sim = parts[0]
	a = parts[1]
	e = parts[2]
	sim.step()
	sim._tag(e, a)
	_ok(a.state == Sim.State.PLAY and a.pos.distance_to(sim.base[a.team]) < 4.0, "Guardian Angel sends you home instead of to jail")
	parts = _power_sim("fake_crystal")
	sim = parts[0]
	a = parts[1]
	e = parts[2]
	sim.step()
	_ok(sim.pickups.size() == 1 and sim.pickups[0].has("trap"), "Fake Crystal plants a fake")
	sim.pickups[0]["born"] = -9.0
	e.pos = sim.pickups[0]["pos"]
	sim.step()
	_ok(e.powers.is_empty() and sim.has_status(e, "stun"), "and it stuns the enemy who grabs it")
	parts = _power_sim("pickpocket")
	sim = parts[0]
	a = parts[1]
	e = parts[2]
	e.powers = ["freeze_ray"] as Array[String]
	sim.step()
	_ok(e.powers.is_empty() and a.powers.has("freeze_ray"), "Pickpocket steals a card")
	parts = _power_sim("wild_card")
	sim = parts[0]
	a = parts[1]
	sim.step()
	_ok(a.powers.size() == 2, "Wild Card draws two")
	parts = _power_sim("instant_igloo")
	sim = parts[0]
	sim.step()
	_ok(sim.walls.size() >= 6, "Instant Igloo builds a ring")
	parts = _power_sim("weather_machine")
	sim = parts[0]
	sim.set_weather("clear")
	sim.weather_home = "clear"
	sim.step()
	_ok(sim.weather != "clear", "Weather Machine changes the sky")
	_ok(_step_until(sim, func() -> bool: return sim.weather == "clear", 30 * 30), "and it goes back afterwards")
	parts = _power_sim("magic_carpet", "barrio_twin_ponds")
	sim = parts[0]
	a = parts[1]
	var pit := -1
	for i in sim.w * sim.h:
		if sim.tiles[i] == Maps.PIT:
			pit = i
			break
	sim.step()
	a.pos = sim.tile_center(pit)
	a.mv = Vector2.ZERO
	sim.step()
	_ok(sim.tile_index(a.pos) == pit, "a Magic Carpet stays up over water")
	parts = _power_sim("hot_potato")
	sim = parts[0]
	a = parts[1]
	e = parts[2]
	sim.step()
	_ok(sim.has_status(e, "potato"), "Hot Potato lands on someone")
	var buddy: Sim.Player = sim.players[3]
	buddy.state = Sim.State.PLAY
	buddy.on_base = false
	buddy.pos = e.pos + Vector2(1.0, 0)
	sim.step()
	_ok(sim.has_status(buddy, "potato") and not sim.has_status(e, "potato"), "and passes to whoever they touch")
	parts = _power_sim("portal_pair")
	sim = parts[0]
	a = parts[1]
	sim.step()
	var portals := sim.zones.filter(func(z: Dictionary) -> bool: return z["fx"] == "portal")
	_ok(portals.size() == 2, "Portal Pair opens two portals")
	var copy := _power_sim("freeze_ray")
	sim = copy[0]
	sim.step()
	_ok(sim.last_power == "freeze_ray", "the last card played is remembered")
	var cat: Sim.Player = sim.players[2]
	cat.state = Sim.State.PLAY
	cat.powers = ["copycat"] as Array[String]
	cat.want_use = true
	cat.on_base = false
	sim.step()
	_ok(cat.powers_used == 1 and sim.last_power == "freeze_ray", "Copycat plays it again")


func _test_shop_items() -> void:
	var regions := {"asia": true, "europe": true, "americas": true, "africa": true, "oceania": true, "fun": true}
	for slot: String in Cosmetics.SLOTS:
		var seen := {}
		for entry: Dictionary in Cosmetics.list(slot):
			var id: String = entry["id"]
			_ok(not seen.has(id), "%s: %s isn't listed twice" % [slot, id])
			seen[id] = true
			_ok(Cosmetics.RARITY.has(entry.get("rarity", "")), "%s: %s has a rarity" % [slot, id])
			if entry.has("region"):
				_ok(regions.has(entry["region"]), "%s: %s is from somewhere real" % [slot, id])
	_ok(Cosmetics.list("flag").size() > 70, "plenty of flags")
	_ok(Cosmetics.list("pet").size() > 40, "plenty of pets")
	for region: Dictionary in Cosmetics.REGIONS:
		_ok(Cosmetics.from_region(region["id"]).size() > 20, "the %s shelf has plenty on it" % region["id"])
	for entry: Dictionary in Cosmetics.list("flag"):
		if entry["id"] != "":
			_ok(Flags.svg(entry["id"]).length() > 100, "%s has a flag to draw" % entry["id"])
			if entry.get("region", "") != "fun":
				_ok(entry["rarity"] == "free", "%s is free" % entry["id"])
	_ok(Flags.from_locale("en_PH") == "ph" and Flags.from_locale("xx") == "", "a device's country finds its flag")
	# Every prop a theme asks for really exists.
	var plain := MeshKit.new()
	PropKit.draw(plain, "no such prop", Vector3.ZERO)
	for theme_id: String in Maps.THEME_ORDER:
		var theme: Dictionary = Maps.THEMES[theme_id]
		var names: Array = (theme["blocks"] as Array) + (theme["decor"] as Array)
		if Maps.theme_info(theme_id).has("lane"):
			names.append(Maps.theme_info(theme_id)["lane"])
		for prop: String in names:
			var k := MeshKit.new()
			PropKit.draw(k, prop, Vector3.ZERO, 0.0, 1.0, 0.5, Color.RED)
			_ok(k.verts.size() != plain.verts.size(), "%s: there's a prop called %s" % [theme_id, prop])
		for layout: String in theme.get("layouts", []):
			_ok(Maps.LAYOUTS.has(layout), "%s: there's a layout called %s" % [theme_id, layout])
		_ok(ArenaBuilder.FLOOR_STYLES.has(theme.get("style", "grass")), "%s: there's a floor called %s" % [theme_id, theme.get("style", "")])


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
		_ok(tags >= 3, "%s: bots actually tag (%d)" % [map_id, tags])
		total_tags += tags
		total_score += sim.score[0] + sim.score[1]
	var ms := Time.get_ticks_msec() - started
	print("  total: points %d, tags %d, rescues %d, powers used %d, wins %s, %.3f ms/tick" % [total_score, total_tags, total_rescues, total_used, wins, float(ms) / maxi(ticks, 1)])
	_ok(total_rescues > 0, "bots rescue")
	_ok(total_used > 50, "bots use powerups")
	_ok(total_score * 2 >= Maps.LAYOUT_ORDER.size() * 3, "matches have enough points (%d)" % total_score)
	_ok(int(wins[2]) <= 3, "few draws (%d)" % int(wins[2]))
	_ok(float(ms) / maxi(ticks, 1) < 2.0, "a tick with 10 bots is cheap")
