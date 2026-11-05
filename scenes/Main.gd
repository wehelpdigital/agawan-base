extends Node
## The game's entry point: holds the menus and the current match, and moves between them.

const QUEUE_WAIT_FALLBACK := 15.0  ## If the server stays silent this long, play against the AI instead.

var ui: UiRoot
var _world: Node3D
var _ui_layer: CanvasLayer
var _hud_layer: CanvasLayer
var _hud_root: Control
var _runner: MatchRunner
var _match_col: VBoxContainer
var _last_skill := 0.52
var _last_map := ""
var _search_popup: VBoxContainer
var _search_label: Label
var _search_started := 0
var _searching := false
var _pause_col: VBoxContainer
var _slow_frames := 0.0
var _slow_clock := 0.0
var _pending_room := ""


func _ready() -> void:
	get_window().min_size = Vector2i(360, 360)
	UiScale.apply(get_tree())
	Quality.apply(get_tree())
	_world = Node3D.new()
	add_child(_world)
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 1
	add_child(_hud_layer)
	_hud_root = Control.new()
	_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_root.theme = UiKit.theme()
	_hud_layer.add_child(_hud_root)
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 2
	add_child(_ui_layer)
	ui = UiRoot.new()
	ui.main = self
	_ui_layer.add_child(ui)
	if OS.has_feature("web") and DisplayServer.is_touchscreen_available():
		var text_input := WebTextInput.new()
		add_child(text_input)
	Net.match_found.connect(_on_match_found)
	_room_from_link()
	Net.queue_update.connect(_on_queue_update)
	_notify_page_ready()
	ui.show_screen("title")
	_run_test_args()


## A link like /?room=ABCD (from a friend's invite) opens that room once connected.
func _room_from_link() -> void:
	if not OS.has_feature("web"):
		return
	var code: Variant = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('room') || ''", true)
	if code is String and String(code) != "":
		_pending_room = String(code).to_upper().left(6)
		Net.status_changed.connect(_on_net_for_link)


func _on_net_for_link(on: bool) -> void:
	if on and _pending_room != "" and ui.current_name != "title":
		_open_pending_room()


func _open_pending_room() -> void:
	var code := _pending_room
	_pending_room = ""
	Profile.tutorial_done = true
	ui.show_screen("room", {"join": code})


## The web page's loading screen stays up until the first frame is drawn.
func _notify_page_ready() -> void:
	if OS.has_feature("web"):
		await get_tree().process_frame
		await get_tree().process_frame
		JavaScriptBridge.eval("window.ctbGameReady && window.ctbGameReady();", true)


func _run_test_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--practice":
			Profile.tutorial_done = true
			start_practice(0.6)


# --- Starting matches -----------------------------------------------------------------------------

func _pick_map() -> String:
	if Profile.favorite_map != "" and not Maps.by_id(Profile.favorite_map).is_empty():
		return Profile.favorite_map
	return Maps.random_id()


func _my_seat(team: int) -> Dictionary:
	return {"name": Profile.player_name, "bot": false, "team": team, "look": Profile.look}


func _bot_seats(rng: RandomNumberGenerator, skill: float) -> Array:
	var seats: Array = []
	var taken := {Profile.player_name: true}
	for i in 10:
		var bot_name := Names.bot_name(rng)
		while taken.has(bot_name):
			bot_name = Names.bot_name(rng)
		taken[bot_name] = true
		seats.append({"name": bot_name, "bot": true, "team": i % 2, "skill": clampf(skill + rng.randf_range(-0.1, 0.1), 0.05, 1.0), "look": Cosmetics.random_look(rng, 0.25 + skill * 0.6)})
	return seats


func start_practice(skill: float) -> void:
	_last_skill = skill
	_last_map = _pick_map()
	_begin_practice(_last_map, skill)


func replay_practice() -> void:
	_last_map = Profile.favorite_map if Profile.favorite_map != "" else Maps.random_id()
	_begin_practice(_last_map, _last_skill)


func _begin_practice(map_id: String, skill: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var seats := _bot_seats(rng, skill)
	var my_team := rng.randi_range(0, 1)
	seats[my_team] = _my_seat(my_team)  # Seats alternate teams, so seat 0 or 1 is on that team.
	_start_match(map_id, seats, my_team, skill, false, true, "")


func _start_match(map_id: String, seats: Array, local_id: int, skill: float, online: bool, host: bool, match_id: String, seed_value := 0) -> void:
	_end_search()
	ui.hide_all()
	_ui_layer.visible = false
	_runner = MatchRunner.new()
	_runner.match_id = match_id
	add_child(_runner)
	_runner.finished.connect(_on_match_finished)
	_runner.start(map_id, seats, local_id, skill, _world, _hud_root, online, host, seed_value)
	_runner.hud.pause_pressed.connect(_on_pause)


func _on_match_finished(result: Dictionary) -> void:
	var rewards := Profile.apply_match(result.get("mine", {}), bool(result.get("online", false)))
	if _runner:
		_runner.queue_free()
		_runner = null
	_ui_layer.visible = true
	ui.show_all()
	ui.show_screen("results", {"result": result, "rewards": rewards})


# --- Online ---------------------------------------------------------------------------------------

## Looks for players. Whoever's waiting gets matched; the server fills empty seats with bots, and if
## the server can't be reached the game simply says so and starts against the AI.
func start_online() -> void:
	if not Net.online:
		ui.toast("Can't reach the game server. Playing with AI instead.", UiKit.YELLOW)
		start_practice(Ranks.bot_skill(Profile.trophies))
		return
	_searching = true
	_search_started = Time.get_ticks_msec()
	_search_popup = ui.popup("Finding Players")
	_search_label = UiKit.body("Looking for players. AI fills any empty seats.", 18)
	_search_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_search_popup.add_child(_search_label)
	var cancel := UiKit.button("Cancel", "ink", 20)
	cancel.pressed.connect(func() -> void:
		Net.queue_leave()
		_end_search())
	_search_popup.add_child(cancel)
	Net.queue_join(Profile.favorite_map)


func _end_search() -> void:
	_searching = false
	if is_instance_valid(_search_popup):
		ui.close_popup(_search_popup)
	_search_popup = null


func _on_queue_update(found: int, needed: int, waited: float, wait_total: float) -> void:
	if is_instance_valid(_search_label):
		var left := maxi(int(ceil(wait_total - waited)), 0)
		_search_label.text = "%d of %d players found. Starting in %d seconds. AI fills any empty seats." % [found, needed, left]


func _process(delta: float) -> void:
	if _pending_room != "" and Net.online and ui.current_name != "title":
		_open_pending_room()
	if _searching and Time.get_ticks_msec() - _search_started > int(QUEUE_WAIT_FALLBACK * 1000.0) + 8000:
		Net.queue_leave()
		_end_search()
		ui.toast("Nobody's around. Playing with AI.", UiKit.YELLOW)
		start_practice(Ranks.bot_skill(Profile.trophies))
	_watch_performance(delta)


func _on_match_found(data: Dictionary) -> void:
	var seats_data: Array = data.get("seats", [])
	var me := int(data.get("you", 0))
	var host := int(data.get("host", 0))
	# Bots dress the same on every device: their outfits come from the match's seed.
	var dresser := RandomNumberGenerator.new()
	dresser.seed = int(data.get("seed", 1))
	var seats: Array = []
	for seat: Variant in seats_data:
		var entry: Dictionary = seat
		var outfit := Cosmetics.random_look(dresser, 0.25 + float(entry.get("skill", 0.5)) * 0.6)
		if entry.get("bot", false):
			entry["look"] = outfit
		seats.append(entry)
	if ui.current_name == "room":
		Net.room = {}
	_start_match(str(data.get("map", Maps.random_id())), seats, me, float(data.get("skill", 0.6)), true, me == host, str(data.get("match", "")), int(data.get("seed", 1)))
	_runner.ranked = bool(data.get("ranked", true))


# --- Pause ----------------------------------------------------------------------------------------

func _on_pause() -> void:
	if _runner == null or is_instance_valid(_pause_col):
		return
	_ui_layer.visible = true
	ui.show_all()
	_runner.set_paused(true)
	if not _runner.online:
		get_tree().paused = false
	_pause_col = ui.popup("Paused" if not _runner.online else "Menu")
	var resume := UiKit.button("Back to the Game", "green", 22)
	resume.pressed.connect(_close_pause)
	_pause_col.add_child(resume)
	var music_row := UiKit.hbox(8)
	var sound := UiKit.button("Sound: %s" % ("On" if Settings.sfx_volume > 0.0 else "Off"), "purple", 17)
	sound.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sound.pressed.connect(func() -> void:
		var on := Settings.sfx_volume <= 0.0
		Settings.sfx_volume = 0.9 if on else 0.0
		Settings.music_volume = 0.7 if on else 0.0
		Settings.save()
		sound.set_text("Sound: %s" % ("On" if on else "Off")))
	music_row.add_child(sound)
	_pause_col.add_child(music_row)
	var quit := UiKit.button("Leave Match", "coral", 20)
	quit.pressed.connect(func() -> void:
		ui.confirm("Leave Match?", "You won't earn anything for this match.", "Leave", _leave_match, "Stay", "coral"))
	_pause_col.add_child(quit)


func _close_pause() -> void:
	if is_instance_valid(_pause_col):
		ui.close_popup(_pause_col)
	_pause_col = null
	if _runner:
		_runner.set_paused(false)
	ui.hide_all()
	_ui_layer.visible = false


func _leave_match() -> void:
	if is_instance_valid(_pause_col):
		ui.close_popup(_pause_col)
	_pause_col = null
	if _runner:
		if _runner.online:
			Net.leave_match()
		_runner.queue_free()
		_runner = null
	_ui_layer.visible = true
	ui.show_all()
	ui.show_screen("home", {"skip_daily": true})


# --- Keeping it smooth ----------------------------------------------------------------------------

## If frames are slow for a while on the Auto setting, step down the graphics once and say so.
func _watch_performance(delta: float) -> void:
	if Settings.quality != "auto" or Quality.auto_lowered or Quality.is_low() or _runner == null:
		return
	_slow_clock += delta
	if delta > 1.0 / 24.0:
		_slow_frames += delta
	if _slow_clock >= 8.0:
		if _slow_frames > 4.0:
			Quality.auto_lowered = true
			Quality.apply(get_tree())
		_slow_clock = 0.0
		_slow_frames = 0.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _runner and not _runner.online and not is_instance_valid(_pause_col):
		_on_pause()
