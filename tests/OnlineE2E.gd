extends Node
## Two real game clients playing each other through a real server. Start the server, then run both:
##   godot --headless --path . res://tests/OnlineE2E.tscn -- --role=host --profile=e2e_a --server=http://127.0.0.1:8787 --code-file=<file> [--scenario=migrate]
##   godot --headless --path . res://tests/OnlineE2E.tscn -- --role=guest --profile=e2e_b --server=http://127.0.0.1:8787 --code-file=<file> [--scenario=migrate]
## Scenario "finish": a Friend Room with both players on one team, then a full result.
## Scenario "migrate": the host walks away mid-match, and the guest must carry the match on.

var _role := "host"
var _code_file := ""
var _scenario := "finish"
var _main: Node
var _fails := 0
var _clock := 0.0
var _snapshots := 0
var _result: Dictionary = {}
var _guest_seat := -1


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--role="):
			_role = arg.trim_prefix("--role=")
		elif arg.begins_with("--code-file="):
			_code_file = arg.trim_prefix("--code-file=")
		elif arg.begins_with("--scenario="):
			_scenario = arg.trim_prefix("--scenario=")
	Profile.tutorial_done = true
	Profile.player_name = "E2E " + _role
	_main = load("res://scenes/Main.gd").new()
	add_child(_main)
	Net.match_snapshot.connect(func(_b: PackedByteArray) -> void: _snapshots += 1)
	Net.match_result.connect(func(data: Dictionary) -> void: _result = data)
	_run.call_deferred()


func _ok(cond: bool, what: String) -> void:
	print("  %s %s: %s" % [_role, "ok" if cond else "FAIL", what])
	if not cond:
		_fails += 1


func _wait_for(cond: Callable, seconds: float, what: String) -> bool:
	var left := seconds
	while left > 0.0:
		if cond.call():
			return true
		await get_tree().process_frame
		left -= get_process_delta_time()
	_ok(false, "timed out waiting for " + what)
	return false


func _finish() -> void:
	print("%s: %s" % [_role, "OK" if _fails == 0 else "%d FAILED" % _fails])
	get_tree().quit(1 if _fails > 0 else 0)


func _run() -> void:
	if not await _wait_for(func() -> bool: return Net.online, 12.0, "the server"):
		_finish()
		return
	if _role == "host":
		await _host_room()
	else:
		await _guest_room()
	if not await _wait_for(func() -> bool: return _main._runner != null, 12.0, "the match to start"):
		_finish()
		return
	var runner: MatchRunner = _main._runner
	_ok(runner.online, "the match is online")
	_ok(not runner.ranked, "a Friend Room match earns no trophies")
	_ok(runner.is_host == (_role == "host"), "the room's host runs the match")
	var me := runner.sim.player_by_id(runner.local_id)
	var humans := 0
	for p in runner.sim.players:
		if not p.bot:
			humans += 1
			if p != me:
				_guest_seat = p.id
				_ok(p.team == me.team, "both players are on one team, as chosen in the room")
	_ok(humans == 2, "two people and eight AI in the match")
	if _scenario == "migrate":
		await _migrate(runner)
	else:
		await _play_out(runner)
	_finish()


func _host_room() -> void:
	Net.room_create("barrio_plaza", 0.5)
	await _wait_for(func() -> bool: return not Net.room.is_empty(), 5.0, "a room")
	var code := str(Net.room.get("code", ""))
	_ok(code.length() == 4, "got a room code")
	var file := FileAccess.open(_code_file, FileAccess.WRITE)
	file.store_string(code)
	file.close()
	await _wait_for(func() -> bool: return (Net.room.get("seats", []) as Array).size() == 2, 20.0, "a friend")
	# Wait until the friend has picked this team.
	await _wait_for(func() -> bool:
		var seats: Array = Net.room.get("seats", [])
		return seats.size() == 2 and int(seats[0]["team"]) == int(seats[1]["team"]), 8.0, "the friend to join this team")
	Net.room_start()


func _guest_room() -> void:
	await _wait_for(func() -> bool: return FileAccess.file_exists(_code_file) and FileAccess.get_file_as_string(_code_file).length() == 4, 20.0, "the room code")
	Net.room_join(FileAccess.get_file_as_string(_code_file))
	await _wait_for(func() -> bool: return not Net.room.is_empty(), 5.0, "the room")
	var seats: Array = Net.room.get("seats", [])
	_ok(seats.size() == 2, "joined the friend's room")
	var host_team := 0
	for seat: Variant in seats:
		if int(seat["id"]) == int(Net.room.get("host", -1)):
			host_team = int(seat["team"])
	Net.room_team(host_team)


## Real play: the guest runs right for a few seconds. The host's Sim must see it, and the guest's copy must
## follow the host's clock.
func _play_out(runner: MatchRunner) -> void:
	var sim := runner.sim
	await _wait_for(func() -> bool: return sim.phase == Sim.Phase.PLAY, 8.0, "the countdown")
	if _role == "guest":
		var start := sim.players[runner.local_id].pos
		runner.hud._stick_vec = Vector2(1.0, 0.0)
		await get_tree().create_timer(0.5).timeout
		runner.hud.skill_pressed.emit(0, Vector2.ZERO)
		await get_tree().create_timer(1.0).timeout
		_ok(sim.players[runner.local_id].skill_cd[0] > 0.0, "the guest's skill goes off, and the host says so")
		await get_tree().create_timer(0.5).timeout
		runner.hud._stick_vec = Vector2.ZERO
		_ok(sim.players[runner.local_id].pos.distance_to(start) > 2.0, "the guest's own stick moves their avatar")
		_ok(_snapshots > 15, "snapshots arrive (%d)" % _snapshots)
		_ok(sim.t > 3.0, "the guest's copy follows the host's clock (%.1f)" % sim.t)
		_ok(sim.pickups.size() > 5, "the crystals come over too (%d)" % sim.pickups.size())
		_ok(sim.players[runner.local_id].skills.size() >= 1, "the guest brought a skill")
	else:
		var seat := sim.player_by_id(_guest_seat)
		_ok(seat.skills.size() >= 1, "the host knows the guest's skills")
		var moved := false
		var left := 4.0
		while left > 0.0 and not moved:
			moved = seat.mv.length() > 0.5
			await get_tree().process_frame
			left -= get_process_delta_time()
		_ok(moved, "the host's rules see the guest's stick")
		await get_tree().create_timer(2.0).timeout
		# Wrap up: this team wins, however the match stood.
		sim._finish(sim.player_by_id(runner.local_id).team, "capture")
	await _wait_for(func() -> bool: return not _result.is_empty(), 25.0, "the server's result")
	_ok(int(_result.get("delta", 99)) == 0, "no trophies changed hands in a Friend Room")
	_ok(int(_result.get("winner", -1)) == sim.player_by_id(runner.local_id).team, "both players got the win")
	await _wait_for(func() -> bool: return _main.ui.current_name == "results", 8.0, "the results screen")
	_ok(_main.ui.current_name == "results", "the results screen appears")
	_ok(Profile.stats["games"] > 0, "the match counts in the profile")


func _migrate(runner: MatchRunner) -> void:
	var sim := runner.sim
	await _wait_for(func() -> bool: return sim.phase == Sim.Phase.PLAY, 8.0, "the countdown")
	if _role == "host":
		await get_tree().create_timer(2.0).timeout
		print("  host walks away")
		get_tree().quit(0)
		await get_tree().create_timer(5.0).timeout
		return
	await _wait_for(func() -> bool: return runner.is_host, 12.0, "the host's job to reach the guest")
	_ok(runner.is_host, "the guest took over as host")
	var clock := sim.t
	var time_left := sim.time_left
	await get_tree().create_timer(2.0).timeout
	_ok(sim.t > clock + 1.0, "the match keeps running here (%.1f to %.1f)" % [clock, sim.t])
	_ok(sim.time_left < time_left, "the clock carries on from where it was")
	var left_player := false
	for p in sim.players:
		if p.id != runner.local_id and not p.bot and p.away:
			left_player = true
	_ok(left_player, "AI plays the seat of the player who left")
