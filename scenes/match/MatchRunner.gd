class_name MatchRunner
extends Node
## Runs one match from start to finish. Three ways to play, same rules:
## - practice: the Sim runs here, with bots in every other seat.
## - online host: the Sim runs here, and this device streams snapshots to the others through the server.
## - online client: sends its stick to the host, shows the snapshots, and moves its own avatar right away
##   so controls feel instant.
##
## If the host's connection drops, the server names another player as host, who carries on from the last
## snapshot.

signal finished(result: Dictionary)

const SNAPSHOT_EVERY := 2  ## Physics ticks between snapshots: 15 per second.
const INPUT_EVERY := 2
const SNAPSHOT_MOST := 1 << 20  ## The most a snapshot can unpack to. It's about 5 KB, and goes over the wire at about 1 KB.

var sim := Sim.new()
var view: MatchView
var hud: Hud
var local_id := 0
var online := false
var is_host := true
var match_id := ""
var _tick := 0
var _ended := false
var _end_wait := 3.2
var _dash_pressed := false
var _use_pressed := false
var _mash_pressed := false
var _skill_pressed := -1
var _aim := Vector2.ZERO
var _client_pos := Vector2.ZERO
var _last_snapshot_at := 0
var _paused := false
var _report_sent := false
var ranked := true


## seats: as in Sim.setup. `p_online` needs a match dictionary from the server (see Net.gd).
func start(map_id: String, seats: Array, p_local_id: int, difficulty: float, parent_3d: Node3D, parent_ui: Control, p_online := false, host := true, seed_value := 0, weather := "") -> void:
	local_id = p_local_id
	online = p_online
	is_host = host
	sim.setup(map_id, seats, seed_value, difficulty, weather)
	sim.authoritative = is_host
	view = MatchView.new()
	view.tag_bots = online
	parent_3d.add_child(view)
	view.setup(sim, local_id)
	hud = Hud.new()
	parent_ui.add_child(hud)
	hud.setup(self)
	hud.dash_pressed.connect(func() -> void: _dash_pressed = true)
	hud.use_pressed.connect(func(aim: Vector2) -> void:
		_use_pressed = true
		_aim = aim)
	hud.skill_pressed.connect(func(index: int, aim: Vector2) -> void:
		_skill_pressed = index
		_aim = aim)
	hud.mash_pressed.connect(func() -> void: _mash_pressed = true)
	hud.emote_pressed.connect(send_emote)
	view.announce.connect(hud.show_announcement)
	view.feed.connect(hud.show_feed)
	view.stat_flash.connect(hud.on_stat_flash)
	_client_pos = sim.players[local_id].pos if local_id >= 0 else Vector2.ZERO
	var theme: Dictionary = Maps.THEMES[Maps.by_id(map_id)["theme"]]
	Audio.music(theme["music"])
	Audio.sfx("ready")
	if online:
		Net.match_snapshot.connect(_on_snapshot)
		Net.match_input.connect(_on_remote_input)
		Net.match_emote.connect(_on_remote_emote)
		Net.match_host_changed.connect(_on_host_changed)
		Net.match_player_left.connect(_on_player_left)
		Net.status_changed.connect(_on_net_status)


func _exit_tree() -> void:
	if online:
		for pair: Array in [[Net.match_snapshot, _on_snapshot], [Net.match_input, _on_remote_input], [Net.match_emote, _on_remote_emote],
				[Net.match_host_changed, _on_host_changed], [Net.match_player_left, _on_player_left], [Net.status_changed, _on_net_status]]:
			if (pair[0] as Signal).is_connected(pair[1]):
				(pair[0] as Signal).disconnect(pair[1])
	if view:
		view.queue_free()
	if hud:
		hud.queue_free()


func set_paused(value: bool) -> void:
	_paused = value and not online


func _physics_process(_delta: float) -> void:
	if view == null or _paused:
		return
	_tick += 1
	var me := sim.player_by_id(local_id)
	if is_host:
		if me:
			_apply_local_input(me)
		sim.step(Sim.TICK)
		if online and _tick % SNAPSHOT_EVERY == 0:
			Net.send_match_binary(Net.BIN_SNAPSHOT, var_to_bytes(sim.to_snapshot()).compress(FileAccess.COMPRESSION_DEFLATE))
	elif me:
		_predict_client(me)
		if _tick % INPUT_EVERY == 0 or _dash_pressed or _use_pressed or _mash_pressed or _skill_pressed >= 0:
			_send_input(me)
	if sim.phase == Sim.Phase.END:
		_on_end(Sim.TICK)


func _process(_delta: float) -> void:
	if hud:
		hud.refresh()


func _apply_local_input(me: Sim.Player) -> void:
	me.mv = hud.move_vector()
	if _dash_pressed:
		me.want_dash = true
	if _use_pressed:
		me.want_use = true
		me.aim = _aim
	if _mash_pressed:
		me.want_mash = true
	if _skill_pressed >= 0:
		me.want_skill = _skill_pressed
		me.aim = _aim
	_dash_pressed = false
	_use_pressed = false
	_mash_pressed = false
	_skill_pressed = -1


## An online client moves itself at once, using the same movement code, and drifts toward what the host
## says, so what it shows is never far from the truth.
func _predict_client(me: Sim.Player) -> void:
	if me.state != Sim.State.PLAY or sim.phase != Sim.Phase.PLAY or sim.is_airborne(me) or sim.is_held(me):
		_client_pos = me.pos
		return
	var input := hud.move_vector().limit_length(1.0)
	if sim.has_status(me, "reverse"):
		input = -input
	var step := input * sim.speed_of(me) * Sim.TICK
	_client_pos = sim.move_circle(_client_pos, step, sim.radius_of(me), sim.has_status(me, "ghost"))
	if _client_pos.distance_to(me.pos) > 4.0:
		_client_pos = me.pos
	else:
		_client_pos = _client_pos.lerp(me.pos, 0.08)
	me.pos = _client_pos
	if input.length() > 0.1:
		me.face = input.normalized()
		me.vel = input * sim.speed_of(me)


func _send_input(me: Sim.Player) -> void:
	var data := PackedFloat32Array([me.id, hud.move_vector().x, hud.move_vector().y, _aim.x, _aim.y,
		1.0 if _dash_pressed else 0.0, 1.0 if _use_pressed else 0.0, 1.0 if _mash_pressed else 0.0, float(_skill_pressed)])
	Net.send_match_binary(Net.BIN_INPUT, data.to_byte_array())
	_dash_pressed = false
	_use_pressed = false
	_mash_pressed = false
	_skill_pressed = -1


func _on_snapshot(bytes: PackedByteArray) -> void:
	if is_host:
		return
	var opened := bytes.decompress_dynamic(SNAPSHOT_MOST, FileAccess.COMPRESSION_DEFLATE)
	if opened.is_empty():
		return
	var snap: Variant = bytes_to_var(opened)
	if snap is Dictionary:
		var me := sim.player_by_id(local_id)
		var predicted := _client_pos
		sim.apply_snapshot(snap)
		_last_snapshot_at = Time.get_ticks_msec()
		if me and me.state == Sim.State.PLAY and predicted.distance_to(me.pos) < 4.0:
			_client_pos = predicted
		elif me:
			_client_pos = me.pos


func _on_remote_input(bytes: PackedByteArray) -> void:
	if not is_host:
		return
	var data := bytes.to_float32_array()
	if data.size() < 8:
		return
	var p := sim.player_by_id(int(data[0]))
	if p == null or p.bot or p.id == local_id:
		return
	p.mv = Vector2(data[1], data[2]).limit_length(1.0)
	if data[5] > 0.5:
		p.want_dash = true
	if data[6] > 0.5:
		p.want_use = true
		p.aim = Vector2(data[3], data[4])
	if data[7] > 0.5:
		p.want_mash = true
	if data.size() >= 9 and data[8] >= 0.0:
		p.want_skill = int(data[8])
		p.aim = Vector2(data[3], data[4])


func _on_host_changed(new_host: int) -> void:
	is_host = new_host == local_id
	sim.authoritative = is_host
	if is_host:
		hud.show_feed("Connection moved to your device", Color("c9f1ff"))


func _on_player_left(player_id: int) -> void:
	var p := sim.player_by_id(player_id)
	if p:
		p.away = true  # A bot plays their seat until the match ends.
		hud.show_feed("%s left. A bot steps in." % p.name, Color("c9f1ff"))


## Lost the server mid-match? Nobody's left to play with, but the match needn't end: this device has
## everything it needs, so it carries on here with bots in the other seats. No trophies for this one.
func _on_net_status(is_online: bool) -> void:
	if is_online or not online:
		return
	online = false
	ranked = false
	is_host = true
	sim.authoritative = true
	for p in sim.players:
		if p.id != local_id:
			p.away = true
	hud.show_feed("Connection lost. Playing on with AI.", Color("ffd23f"))


func send_emote(id: String) -> void:
	var def := Cosmetics.item("emote", id)
	if def.is_empty():
		return
	view.show_emote(local_id, def["text"])
	if online:
		Net.send_match_emote(local_id, id)


func _on_remote_emote(player_id: int, id: String) -> void:
	var def := Cosmetics.item("emote", id)
	if not def.is_empty():
		view.show_emote(player_id, def["text"])


func _on_end(dt: float) -> void:
	if not _ended:
		_ended = true
		var me := sim.player_by_id(local_id)
		var won := me != null and sim.winner == me.team
		Audio.music_duck(-6.0)
		Audio.sfx("victory" if won else ("timeout" if sim.winner == 2 else "defeat"))
		Haptics.buzz("win" if won else "jailed")
		if online:
			_report_result()
	_end_wait -= dt
	if _end_wait <= 0.0 and view != null:
		set_physics_process(false)
		Audio.music_duck(0.0)
		finished.emit(build_result())


func _report_result() -> void:
	if _report_sent:
		return
	_report_sent = true
	Net.send_match_result(match_id, sim.winner, sim.mvp())


## Everything the results screen shows.
func build_result() -> Dictionary:
	var me := sim.player_by_id(local_id)
	var mvp_id := sim.mvp()
	var mine := {}
	if me:
		mine = {"tags": me.tags, "rescues": me.rescues, "captures": me.captures, "powers": me.powers_used, "skills": me.skills_used, "jailed": me.times_jailed,
			"won": sim.winner == me.team, "draw": sim.winner == 2, "mvp": mvp_id == me.id}
	var rows: Array = []
	for p in sim.players:
		rows.append({"id": p.id, "name": p.name, "team": p.team, "bot": p.bot, "look": p.look, "tags": p.tags, "rescues": p.rescues,
			"captures": p.captures, "jailed": p.times_jailed, "powers": p.powers_used, "skills": p.skills_used, "score": sim.stats_score(p)})
	return {"winner": sim.winner, "my_team": me.team if me else 0, "score": sim.score, "mine": mine, "players": rows, "mvp": mvp_id,
		"reason": sim.end_reason, "online": online, "ranked": ranked, "map": sim.map_id, "match_id": match_id, "seconds": sim.played_seconds(), "weather": sim.weather_home, "me": me.id if me else -1}
