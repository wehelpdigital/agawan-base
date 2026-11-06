class_name Hud
extends Control
## Everything drawn over a match: score, clock, teams, joystick, buttons, messages. Reads like a poster,
## because at 5v5 there is a lot going on. Works with touch, mouse and keyboard, and controllers.

signal dash_pressed
signal use_pressed(aim: Vector2)
signal skill_pressed(index: int, aim: Vector2)
signal mash_pressed
signal emote_pressed(id: String)
signal pause_pressed

const STICK_R := 62.0
const AIM_DEADZONE := 30.0
const ROSTER_GAP := 10.0

var runner: MatchRunner
var sim: Sim
var view: MatchView

var _insets := Vector4.ZERO
var _portrait := false
var _touch := false

var _time_label: Label
var _score_pips: Array = [[], []]
var _attack_label: Label
var _roster: Array[Control] = []
var _roster_box: HBoxContainer
var _announce: Label
var _announce_big: Label
var _feed_box: VBoxContainer
var _status_label: Label
var _weather_chip: PanelContainer
var _weather_icon: TextureRect
var _wind_arrow: Control
var _weather_shown := ""
var _side_pill: PanelContainer
var _side_text: Label
var _side_icon: TextureRect
var _side_shown := ""
var _side_line_y := 0.0
var _mini: Minimap
var _dash_btn: HudButton
var _use_btn: PowerSlot
var _next_slot: PowerSlot
var _skill_btns: Array[HudButton] = []
var _jail_panel: Control
var _jail_time: Label
var _jail_bar: ProgressBar
var _mash_btn: GameButton
var _hint: PanelContainer
var _hint_label: Label
var _hint_index := 0
var _hint_time := 0.0
var _ink: Array[TextureRect] = []
var _reverse_flash: Label
var _emote_box: VBoxContainer
var _emote_open := false
var _countdown: Label
var _top: Control
var _last_count := -1
var _fps: Label

var _stick_touch := -1
var _stick_center := Vector2.ZERO
var _stick_now := Vector2.ZERO
var _stick_vec := Vector2.ZERO
var _aim_touch := -1
var _aim_start := Vector2.ZERO
var _aim_now := Vector2.ZERO
var _dash_touch := -1
var _mouse_aiming := false
var _pad_used := false

const HINTS: Array[String] = [
	"The line is everything! On your side, you can tag them. Over the line, they can tag you.",
	"A green arrow means you can tag them. A red sign means they can tag you. Run back over the line to be safe!",
	"Stand on the enemy base to capture it. First team to 3 captures wins!",
	"In jail? Tap to break out. Or a free teammate can touch the jail and spring everyone.",
	"Grab the crystals! Each one spins up a random power card. Tap the card to use it, or drag to aim.",
	"On your side you draw shield cards. Over the line you draw target cards. Cross the line and your hand reshuffles!",
	"Your hero has a skill of their own: tap the round button above DASH. It comes back on its own.",
	"Hide in the bushes to ambush someone. Arrow floors, jump pads and fountains are all there to be used!",
]


func setup(p_runner: MatchRunner) -> void:
	runner = p_runner
	sim = runner.sim
	view = runner.view
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_touch = Quality.is_handheld() or DisplayServer.is_touchscreen_available()
	_build()
	get_viewport().size_changed.connect(_relayout)
	_relayout()
	var me := sim.player_by_id(runner.local_id)
	if me:
		show_announcement("You're on Team %s!" % ArenaBuilder.TEAM_NAMES[me.team], ArenaBuilder.team_color(me.team).lightened(0.25), false)


func _build() -> void:
	# Screen-wide effects go first, so everything else draws on top of them.
	for i in 5:
		var splat := TextureRect.new()
		splat.texture = UiKit.ink_splat_texture()
		splat.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		splat.mouse_filter = Control.MOUSE_FILTER_IGNORE
		splat.visible = false
		add_child(splat)
		_ink.append(splat)
	_top = Control.new()
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top)
	_build_scoreboard()
	_mini = Minimap.new()
	_mini.setup(sim, runner.local_id)
	add_child(_mini)
	_feed_box = UiKit.vbox(4)
	_feed_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_feed_box)
	_announce_big = UiKit.title("", 56, UiKit.YELLOW)
	_announce_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announce_big.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_announce_big.visible = false
	add_child(_announce_big)
	_announce = UiKit.title("", 26, UiKit.WHITE)
	_announce.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announce.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_announce.visible = false
	add_child(_announce)
	_attack_label = UiKit.title("OUR BASE IS UNDER ATTACK!", 20, Color("ff8a78"))
	_attack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_attack_label.visible = false
	add_child(_attack_label)
	_status_label = UiKit.title("", 18, Color("c9f1ff"))
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_status_label)
	_side_pill = PanelContainer.new()
	_side_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_side_pill.visible = false
	add_child(_side_pill)
	_build_weather_chip()
	var side_row := UiKit.hbox(5)
	side_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_side_pill.add_child(side_row)
	_side_icon = UiKit.icon("mode_defend", 26)
	side_row.add_child(_side_icon)
	_side_text = UiKit.title("", 17)
	_side_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_side_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	side_row.add_child(_side_text)
	_countdown = UiKit.title("", 110, UiKit.YELLOW)
	_countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown.visible = false
	add_child(_countdown)
	_dash_btn = HudButton.new()
	_dash_btn.setup("dash", Color("3aa6ff"), "DASH")
	add_child(_dash_btn)
	PowerSlot.prepare_deck()
	_next_slot = PowerSlot.new()
	_next_slot.compact = true
	add_child(_next_slot)
	_use_btn = PowerSlot.new()
	add_child(_use_btn)
	var me := sim.player_by_id(runner.local_id)
	if me:
		for entry: Array in me.skills:
			var button := HudButton.new()
			button.setup_skill(String(entry[0]))
			add_child(button)
			_skill_btns.append(button)
	_build_emotes()
	_build_jail_panel()
	_build_hint()
	_reverse_flash = UiKit.title("CONTROLS FLIPPED!", 22, UiKit.PURPLE)
	_reverse_flash.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reverse_flash.visible = false
	add_child(_reverse_flash)
	_fps = UiKit.label("", 14)
	_fps.visible = Settings.fps_counter
	add_child(_fps)


func _build_scoreboard() -> void:
	var board := PanelContainer.new()
	board.name = "Board"
	board.add_theme_stylebox_override("panel", UiKit.card_style(UiKit.INK, 20, 3))
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top.add_child(board)
	var row := UiKit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	board.add_child(row)
	row.add_child(_score_side(0))
	_time_label = UiKit.title("3:00", 34)
	_time_label.custom_minimum_size = Vector2(98, 0)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(_time_label)
	row.add_child(_score_side(1))
	_roster_box = UiKit.hbox(3)
	_roster_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_roster_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top.add_child(_roster_box)
	# My team on the left, always; the enemy on the right.
	var me := sim.player_by_id(runner.local_id)
	var mine: int = me.team if me else 0
	for team: int in [mine, 1 - mine]:
		for p: Sim.Player in sim.team_of(team):
			var chip := RosterChip.new()
			chip.setup(p, p.id == runner.local_id)
			_roster_box.add_child(chip)
			_roster.append(chip)
		if team == mine:
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(ROSTER_GAP, 1)
			_roster_box.add_child(gap)


func _score_side(team: int) -> Control:
	var me := sim.player_by_id(runner.local_id)
	var mine: int = me.team if me else 0
	var shown := mine if team == 0 else 1 - mine
	var color := ArenaBuilder.team_color(shown)
	var row := UiKit.hbox(5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pips: Array = []
	for i in Sim.WIN_POINTS:
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(24, 24)
		pip.add_theme_stylebox_override("panel", UiKit.style(UiKit.INK, 12, 3, UiKit.RIM))
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(pip)
		pips.append(pip)
	if team == 0:
		pips.reverse()
	_score_pips[shown] = pips
	row.set_meta("color", color)
	return row


## A small round chip under the map: what the sky is doing, and which way the wind is pushing.
func _build_weather_chip() -> void:
	_weather_chip = PanelContainer.new()
	_weather_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := UiKit.style(UiKit.PAPER, 18, 3, UiKit.INK)
	box.content_margin_left = 6
	box.content_margin_right = 8
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	_weather_chip.add_theme_stylebox_override("panel", box)
	var row := UiKit.hbox(4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_weather_chip.add_child(row)
	_weather_icon = UiKit.icon("w_sun", 26)
	row.add_child(_weather_icon)
	_wind_arrow = WindArrow.new()
	_wind_arrow.custom_minimum_size = Vector2(26, 26)
	row.add_child(_wind_arrow)
	add_child(_weather_chip)


func _update_weather_chip() -> void:
	if sim.weather != _weather_shown:
		_weather_shown = sim.weather
		_weather_icon.texture = UiKit.icon_texture(String(Weather.def(sim.weather)["icon"]))
		_weather_chip.visible = sim.weather != "clear"
	_wind_arrow.visible = sim.wind.length() > 0.3
	if _wind_arrow.visible:
		(_wind_arrow as WindArrow).way = sim.wind.rotated(view.view_yaw())
	_weather_chip.reset_size()
	var chip_size := _weather_chip.get_combined_minimum_size()
	_weather_chip.position = _mini.global_position - global_position + _mini.size - chip_size + Vector2(6.0, 6.0)


func _build_emotes() -> void:
	_emote_box = UiKit.vbox(6)
	_emote_box.visible = false
	add_child(_emote_box)
	for id in Profile.equipped_emotes():
		var def := Cosmetics.item("emote", id)
		var b := UiKit.button(String(def["text"]), "white", 18)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func() -> void:
			emote_pressed.emit(id)
			_toggle_emotes())
		_emote_box.add_child(b)
	var open := UiKit.button("", "white", 18, "emote")
	open.name = "EmoteOpen"
	open.custom_minimum_size = Vector2(54, 50)
	open.focus_mode = Control.FOCUS_NONE
	open.pressed.connect(_toggle_emotes)
	add_child(open)
	var pause := UiKit.button("", "ink", 18, "pause")
	pause.name = "Pause"
	pause.custom_minimum_size = Vector2(54, 50)
	pause.focus_mode = Control.FOCUS_NONE
	pause.pressed.connect(func() -> void: pause_pressed.emit())
	add_child(pause)


func _toggle_emotes() -> void:
	_emote_open = not _emote_open
	_emote_box.visible = _emote_open


func _build_jail_panel() -> void:
	_jail_panel = UiKit.vbox(6)
	_jail_panel.visible = false
	add_child(_jail_panel)
	var title := UiKit.title("IN JAIL", 34, Color("ff8a78"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_jail_panel.add_child(title)
	_jail_time = UiKit.body("", 18, UiKit.WHITE)
	_jail_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_jail_time.autowrap_mode = TextServer.AUTOWRAP_OFF
	_jail_time.add_theme_color_override("font_outline_color", UiKit.INK)
	_jail_time.add_theme_constant_override("outline_size", 6)
	_jail_panel.add_child(_jail_time)
	_jail_bar = ProgressBar.new()
	_jail_bar.show_percentage = false
	_jail_bar.custom_minimum_size = Vector2(260, 22)
	_jail_bar.add_theme_stylebox_override("background", UiKit.style(UiKit.INK, 11, 3))
	_jail_bar.add_theme_stylebox_override("fill", UiKit.style(UiKit.CORAL, 9))
	_jail_panel.add_child(_jail_bar)
	_mash_btn = UiKit.button("TAP TO BREAK OUT!", "coral", 26)
	_mash_btn.custom_minimum_size = Vector2(320, 84)
	_mash_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_mash_btn.focus_mode = Control.FOCUS_NONE
	_mash_btn.pressed.connect(func() -> void: mash_pressed.emit())
	_jail_panel.add_child(_mash_btn)


func _build_hint() -> void:
	_hint = PanelContainer.new()
	_hint.add_theme_stylebox_override("panel", UiKit.card_style(Color(UiKit.PAPER, 0.96), 16, 4))
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.visible = false
	_hint_label = UiKit.body("", 18, UiKit.INK)
	_hint.add_child(_hint_label)
	add_child(_hint)


func _relayout() -> void:
	var view_size := get_viewport_rect().size
	_insets = SafeInsets.get_insets(get_tree())
	_portrait = view_size.y > view_size.x * 1.05
	var left := _insets.x + 10.0
	var right := view_size.x - _insets.z - 10.0
	var top := _insets.y + 8.0
	var bottom := view_size.y - _insets.w - 10.0
	var short := minf(view_size.x, view_size.y)
	var tiny := short < 430.0
	var board: Control = _top.get_node("Board")
	board.reset_size()
	var board_size := board.get_combined_minimum_size()
	board.position = Vector2((view_size.x - board_size.x) * 0.5, top)
	board.size = board_size
	var roster_y := top + board_size.y + 2.0
	# Everybody's face and how many they've tagged, in as much room as there is. On an upright phone it goes under the buttons
	# in the corner; on a wide screen, between the minimap and those.
	var mini_w := clampf(short * (0.6 if _portrait else 0.5), 150.0, 320.0)
	if not _portrait:  # Never under the scoreboard.
		mini_w = minf(mini_w, board.position.x - left - Minimap.FRAME * 2.0 - 8.0)
	var roster_room := view_size.x - 20.0 if _portrait else view_size.x - 2.0 * (left + Minimap.FRAME * 2.0 + mini_w) - 8.0
	if _portrait:
		roster_y = maxf(roster_y, top + 110.0)
	for chip: Control in _roster:
		(chip as RosterChip).set_width(clampf((roster_room - ROSTER_GAP - 27.0) / 10.0, 32.0, 56.0))
	_roster_box.reset_size()
	var roster_size := _roster_box.get_combined_minimum_size()
	_roster_box.position = Vector2((view_size.x - roster_size.x) * 0.5, roster_y)
	_roster_box.size = roster_size
	var below := roster_y + roster_size.y + 4.0
	# Minimap: in the corner on wide screens; below the roster on upright ones.
	var aspect := sim.arena_size().y / sim.arena_size().x
	_mini.custom_minimum_size = Vector2.ZERO
	_mini.size = Vector2(mini_w, mini_w * aspect)
	if _portrait:  # Under the pill that says which side you're on.
		_mini.set_rotated(true)
		_mini.size = Vector2(mini_w * aspect, mini_w)
		_mini.position = Vector2(left + Minimap.FRAME, below + 36.0 + Minimap.FRAME)
	else:
		_mini.set_rotated(false)
		_mini.position = Vector2(left + Minimap.FRAME, top + Minimap.FRAME)
	# Feed: under the minimap on wide screens; opposite it on upright ones.
	_feed_box.custom_minimum_size = Vector2(minf(280.0, view_size.x * 0.46), 0)
	if _portrait:
		_feed_box.position = Vector2(right - _feed_box.custom_minimum_size.x, below + 40.0)
	else:
		_feed_box.position = Vector2(left, top + _mini.size.y + 16.0)
	_feed_box.size = _feed_box.custom_minimum_size
	var center_w := minf(view_size.x - 40.0, 760.0)
	var mid_y := view_size.y * (0.3 if _portrait else 0.26)
	_announce_big.add_theme_font_size_override("font_size", 34 if tiny and view_size.x < 500.0 else (44 if tiny else 56))
	_announce_big.position = Vector2((view_size.x - center_w) * 0.5, mid_y)
	_announce_big.size = Vector2(center_w, 0)
	_announce.position = Vector2((view_size.x - center_w) * 0.5, mid_y + (66.0 if tiny else 84.0))
	_announce.size = Vector2(center_w, 0)
	_side_line_y = below
	_place_side_pill()
	_attack_label.position = Vector2(0, below + 36.0)
	_attack_label.size = Vector2(view_size.x, 0)
	_status_label.position = Vector2(0, below + 62.0)
	_status_label.size = Vector2(view_size.x, 0)
	_countdown.position = Vector2(0, view_size.y * 0.32 - 60.0)
	_countdown.size = Vector2(view_size.x, 0)
	_reverse_flash.position = Vector2(0, below + 88.0)
	_reverse_flash.size = Vector2(view_size.x, 0)
	# Buttons: thumb reach, bigger on phones.
	var big := clampf(short * 0.3, 104.0, 150.0)
	var mid := big * 0.72
	var flip := Settings.left_handed
	var card := Vector2(big * 0.9, big * 1.2)
	var use_x := right - card.x - 4.0 if not flip else left + 4.0
	var use_pos := Vector2(use_x, bottom - card.y - 2.0)
	_use_btn.position = use_pos
	_use_btn.size = card
	var dash_x := use_pos.x - mid - 8.0 if not flip else use_pos.x + card.x + 8.0
	_dash_btn.position = Vector2(dash_x, bottom - mid - 2.0)
	_dash_btn.size = Vector2(mid, mid)
	# The next card waits just above the one in your hand.
	var next := card * 0.46
	_next_slot.size = next
	_next_slot.position = Vector2(use_pos.x + (card.x - next.x) * 0.5, use_pos.y - next.y - 6.0)
	# Skills stand on top of the dash button.
	var small := mid * 0.84
	for i in _skill_btns.size():
		_skill_btns[i].size = Vector2(small, small)
		_skill_btns[i].position = Vector2(dash_x + (mid - small) * 0.5, bottom - mid - 2.0 - (small + 16.0) * (i + 1))
	# Top-right buttons.
	var pause: Control = get_node("Pause")
	pause.position = Vector2(right - 54.0, top)
	pause.size = Vector2(54, 50)
	var emote: Control = get_node("EmoteOpen")
	emote.position = Vector2(right - 54.0, top + 56.0)
	emote.size = Vector2(54, 50)
	_emote_box.position = Vector2(right - 54.0 - 150.0, top + 56.0)
	_emote_box.custom_minimum_size = Vector2(142, 0)
	_jail_panel.reset_size()
	var jail_size := _jail_panel.get_combined_minimum_size()
	_jail_panel.position = Vector2((view_size.x - jail_size.x) * 0.5, view_size.y - _insets.w - jail_size.y - 26.0)
	_jail_panel.size = jail_size
	var hint_w := minf(view_size.x - 32.0, 480.0)
	_hint.size = Vector2(hint_w, 0)
	if _portrait:
		var buttons_up := mid + (small + 16.0) * _skill_btns.size()
		_hint.position = Vector2((view_size.x - hint_w) * 0.5, bottom - maxf(big, buttons_up) - 130.0)
	else:
		_hint.position = Vector2((view_size.x - hint_w) * 0.5, bottom - 98.0)
	_hint_label.custom_minimum_size = Vector2(hint_w - 34.0, 0)
	_fps.position = Vector2(left + 2.0, bottom - 18.0)
	var s := minf(view_size.x, view_size.y) * 0.9
	for i in _ink.size():
		_ink[i].size = Vector2(s, s) * (0.8 + i * 0.1)
		_ink[i].pivot_offset = _ink[i].size * 0.5
		_ink[i].rotation = i * 1.3
	_ink[0].position = Vector2(view_size.x * 0.05, view_size.y * 0.0)
	_ink[1].position = Vector2(view_size.x * 0.5, view_size.y * 0.1)
	_ink[2].position = Vector2(view_size.x * 0.2, view_size.y * 0.42)
	_ink[3].position = Vector2(view_size.x * 0.62, view_size.y * 0.5)
	_ink[4].position = Vector2(view_size.x * 0.32, view_size.y * 0.12)


# --- Every frame ----------------------------------------------------------------------------------

func refresh() -> void:
	var delta := get_process_delta_time()
	var me := sim.player_by_id(runner.local_id)
	_refresh_top()
	_refresh_buttons(me)
	_refresh_jail(me)
	_refresh_status(me)
	_refresh_side(me)
	_refresh_hints(delta, me)
	_refresh_countdown()
	_update_weather_chip()
	_mini.view_rect = view.ground_view()
	_mini.queue_redraw()
	if Settings.fps_counter:
		_fps.text = "%d fps" % Engine.get_frames_per_second()


func _refresh_top() -> void:
	var secs := maxi(int(ceil(sim.time_left)), 0)
	_time_label.text = "%d:%02d" % [secs / 60, secs % 60]
	var urgent := secs <= 10 and sim.phase == Sim.Phase.PLAY
	_time_label.add_theme_color_override("font_color", Color("ff8a78") if urgent or sim.overtime else UiKit.WHITE)
	for team in 2:
		var pips: Array = _score_pips[team]
		var color := ArenaBuilder.team_color(team)
		for i in pips.size():
			var on: bool = i < int(sim.score[team])
			(pips[i] as Panel).add_theme_stylebox_override("panel", UiKit.style(color if on else UiKit.INK, 12, 3, UiKit.RIM))
	var best := 0
	for p: Sim.Player in sim.players:
		best = maxi(best, p.tags)
	for chip: Control in _roster:
		(chip as RosterChip).refresh(best, get_process_delta_time())


func _refresh_buttons(me: Sim.Player) -> void:
	var alive := me != null and me.state == Sim.State.PLAY and sim.phase != Sim.Phase.END
	_dash_btn.visible = alive
	_use_btn.visible = alive
	_next_slot.visible = alive and me != null and me.powers.size() > 1
	if me == null:
		return
	_dash_btn.set_cooldown(me.dash_cd / Sim.DASH_COOLDOWN)
	for i in _skill_btns.size():
		_skill_btns[i].visible = alive
		var left: float = me.skill_cd[i]
		_skill_btns[i].set_cooldown(left / Skills.cooldown(me.skills[i][0], me.skills[i][1]))
		_skill_btns[i].set_seconds(ceili(left))
	# The newest card is the one spinning: the second if there are two, or else the first. Crossing the line spins them all.
	var held := me.powers
	_use_btn.show_state(held[0] if held.size() > 0 else "", maxf(me.spin_left if held.size() == 1 else 0.0, me.swap_left))
	_next_slot.show_state(held[1] if held.size() > 1 else "", maxf(me.spin_left if held.size() > 1 else 0.0, me.swap_left))


func _refresh_jail(me: Sim.Player) -> void:
	var jailed := me != null and me.state == Sim.State.JAIL and sim.phase != Sim.Phase.END
	_jail_panel.visible = jailed
	if jailed:
		_jail_time.text = "Out in %d seconds, or sooner if a teammate frees you" % ceili(me.jail_left)
		_jail_bar.max_value = Sim.JAIL_TIME
		_jail_bar.value = Sim.JAIL_TIME - me.jail_left


## Always on screen: which side of the line you're on, and so whether you're the hunter or the hunted.
func _refresh_side(me: Sim.Player) -> void:
	var show_it := me != null and me.state == Sim.State.PLAY and sim.phase == Sim.Phase.PLAY
	_side_pill.visible = show_it
	if not show_it:
		_side_shown = ""
		return
	var state := "enemy"
	if sim.is_free_walking(me):
		state = "free"
	elif sim.is_charged(me):
		state = "charged"
	elif sim.on_home_side(me):
		state = "home"
	if state == _side_shown:
		return
	var first := _side_shown == ""
	_side_shown = state
	var look: Array = {"home": ["DEFEND: TAG THEM!", Color("22b85c"), "mode_defend"], "enemy": ["ATTACK: DON'T GET CAUGHT!", Color("f0413a"), "mode_attack"],
		"charged": ["CHARGED: TAG ANYONE!", Color("ffb31f"), "mode_attack"], "free": ["FREE WALK HOME", Color("3f8fe8"), "mode_defend"]}[state]
	_side_text.text = look[0]
	_side_icon.texture = UiKit.icon_texture(look[2])
	var box := UiKit.style(look[1], 18, 3, UiKit.RIM)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 3
	box.content_margin_bottom = 5
	box.shadow_color = Color(UiKit.INK, 0.3)
	box.shadow_size = 2
	box.shadow_offset = Vector2(0, 3)
	_side_pill.add_theme_stylebox_override("panel", box)
	_place_side_pill()
	if first:
		return
	Audio.sfx("topper_chime" if state != "enemy" else "timer_urgent", 0.6)
	_side_pill.scale = Vector2.ONE * 1.35
	create_tween().tween_property(_side_pill, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _place_side_pill() -> void:
	_side_pill.reset_size()
	var size_now := _side_pill.get_combined_minimum_size()
	_side_pill.size = size_now
	_side_pill.pivot_offset = size_now * 0.5
	_side_pill.position = Vector2((get_viewport_rect().size.x - size_now.x) * 0.5, _side_line_y)


func _refresh_status(me: Sim.Player) -> void:
	var mine: int = me.team if me else 0
	var under_attack: bool = sim.phase == Sim.Phase.PLAY and (int(sim.capturing[mine]) > 0 or float(sim.cap[mine]) > 0.02)
	_attack_label.visible = under_attack and fmod(Time.get_ticks_msec() * 0.001, 0.5) < 0.34
	if me == null or sim.phase != Sim.Phase.PLAY:
		_status_label.text = ""
		_set_blind(false)
		_reverse_flash.visible = false
		return
	var text := ""
	if me.state == Sim.State.PLAY:
		var their_base: Vector2 = sim.base[1 - me.team]
		if me.pos.distance_to(their_base) < Sim.BASE_R:
			text = "CAPTURING %d%%" % int(float(sim.cap[1 - me.team]) * 100.0)
		elif me.camp > 3.0:
			text = "THE PAD IS ABOUT TO POP YOU!"
		elif sim.tile_at(me.pos) == Maps.GRASS:
			text = "HIDDEN! Stay still, or the leaves give you away."
		elif sim.has_status(me, "chicken"):
			text = "BAWK! You're a chicken! No tagging, no cards!"
		elif sim.has_status(me, "dance"):
			text = "DANCE FEVER! You can't stop!"
		elif sim.has_status(me, "sleep"):
			text = "Zzz..."
		elif sim.has_status(me, "bubble"):
			text = "STUCK IN A BUBBLE!"
		elif sim.has_status(me, "tickle"):
			text = "HA HA HA! IT TICKLES!"
		elif sim.has_status(me, "itch"):
			text = "SO ITCHY! Scratch, scratch."
		elif sim.has_status(me, "stink"):
			text = "EWW! You stink. Everyone can find you."
		elif sim.has_status(me, "potato"):
			text = "HOT POTATO! Touch someone to pass it on!"
		elif sim.has_status(me, "charging"):
			text = "CHARGING UP..."
		elif sim.has_status(me, "carpet"):
			text = "FLYING! Mind where you land."
		elif sim.has_status(me, "turbo"):
			text = "TURBO! No brakes!"
		else:
			match sim.tile_at(me.pos):
				Maps.QUICKSAND:
					text = "SINKING! Dash out!"
				Maps.TOWER:
					text = "LOOKOUT: your team sees everyone."
				Maps.TIDE:
					if sim.tide_high():
						text = "The tide's in! Wade to dry land."
	_status_label.text = text
	_set_blind(sim.has_status(me, "blind"))
	_reverse_flash.visible = sim.has_status(me, "reverse")


func _set_blind(on: bool) -> void:
	for splat in _ink:
		splat.visible = on
		splat.modulate.a = 0.86


func _refresh_hints(delta: float, me: Sim.Player) -> void:
	if not Settings.hints or Profile.matches_played >= 3 or me == null or _hint_index >= HINTS.size():
		_hint.visible = false
		return
	_hint_time -= delta
	if _hint_time <= 0.0 and sim.phase == Sim.Phase.PLAY:
		_hint_label.text = HINTS[_hint_index]
		_hint.visible = true
		_hint_index += 1
		_hint_time = 8.5
	elif _hint_time <= 1.5:
		_hint.visible = false


func _refresh_countdown() -> void:
	if sim.phase != Sim.Phase.COUNTDOWN:
		_countdown.visible = false
		_last_count = -1
		return
	var n := ceili(sim.phase_left)
	_countdown.visible = true
	_countdown.text = str(n)
	if n != _last_count:
		_last_count = n
		Audio.sfx("timer_tick")
		_countdown.pivot_offset = Vector2(get_viewport_rect().size.x * 0.5, 60.0)
		_countdown.scale = Vector2.ONE * 1.5
		create_tween().tween_property(_countdown, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# --- Messages -------------------------------------------------------------------------------------

func show_announcement(text: String, color: Color, big: bool) -> void:
	var label := _announce_big if big else _announce
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.visible = true
	label.modulate.a = 1.0
	var width := get_viewport_rect().size.x
	label.pivot_offset = Vector2(label.size.x * 0.5, 20.0)
	label.position.x = (width - label.size.x) * 0.5
	label.scale = Vector2.ONE * 0.5
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.6 if big else 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void: label.visible = false)


func show_feed(text: String, color: Color) -> void:
	var line := UiKit.body(text, 15, color)
	line.custom_minimum_size.x = _feed_box.custom_minimum_size.x
	line.add_theme_color_override("font_outline_color", UiKit.INK)
	line.add_theme_constant_override("outline_size", 5)
	_feed_box.add_child(line)
	while _feed_box.get_child_count() > 4:
		_feed_box.get_child(0).queue_free()
		_feed_box.remove_child(_feed_box.get_child(0))
	var tween := create_tween()
	tween.tween_interval(3.0 + text.length() * 0.05)
	tween.tween_property(line, "modulate:a", 0.0, 0.4)
	tween.tween_callback(line.queue_free)


func on_stat_flash(kind: String) -> void:
	if kind == "capture":
		Haptics.buzz("capture")


# --- Controls -------------------------------------------------------------------------------------

## The stick, in sim space (x, y on the ground).
func move_vector() -> Vector2:
	var raw := _stick_vec
	if raw == Vector2.ZERO:
		raw = Vector2(Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
			Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up"))
		raw += _keyboard_vec()
		var pad := _pad_vec()
		if pad != Vector2.ZERO:
			raw = pad
	return _screen_to_world(raw.limit_length(1.0))


func _keyboard_vec() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		v.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		v.x += 1.0
	return v


func _pad_vec() -> Vector2:
	for pad in Input.get_connected_joypads():
		var v := Vector2(Input.get_joy_axis(pad, JOY_AXIS_LEFT_X), Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y))
		if v.length() > 0.2:
			return v
	return Vector2.ZERO


func _screen_to_world(v: Vector2) -> Vector2:
	var yaw := view.view_yaw()
	var right := Vector2(cos(yaw), -sin(yaw))
	var down := Vector2(sin(yaw), cos(yaw))
	return right * v.x + down * v.y


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)
	elif event is InputEventMouseButton and not _touch:
		_on_mouse_button(event)
	elif event is InputEventMouseMotion and _mouse_aiming:
		_aim_now = event.position
	elif event is InputEventKey and event.pressed and not event.echo:
		_on_key(event)
	elif event is InputEventJoypadButton and event.pressed:
		_on_pad(event)


func _hit(btn: Control, at: Vector2, grow := 14.0) -> bool:
	return btn.visible and Rect2(btn.position, btn.size).grow(grow).has_point(at)


func _is_top_button(at: Vector2) -> bool:
	for node_name: String in ["Pause", "EmoteOpen"]:
		var c: Control = get_node(node_name)
		if Rect2(c.position, c.size).grow(6.0).has_point(at):
			return true
	if _emote_open and Rect2(_emote_box.position, _emote_box.size).has_point(at):
		return true
	return _jail_panel.visible and Rect2(_jail_panel.position, _jail_panel.size).has_point(at)


func _on_touch(event: InputEventScreenTouch) -> void:
	var at := event.position
	if event.pressed:
		if _is_top_button(at):
			return
		if _hit(_use_btn, at):
			_aim_touch = event.index
			_aim_start = at
			_aim_now = at
			_use_btn.set_pressed_look(true)
			return
		if _hit(_dash_btn, at):
			_dash_touch = event.index
			_dash_btn.set_pressed_look(true)
			dash_pressed.emit()
			return
		for i in _skill_btns.size():
			if _hit(_skill_btns[i], at, 6.0):
				_press_skill(i, Vector2.ZERO)
				return
		var mine := at.x < get_viewport_rect().size.x * 0.5 if not Settings.left_handed else at.x > get_viewport_rect().size.x * 0.5
		if _stick_touch < 0 and mine:
			_stick_touch = event.index
			_stick_center = at
			_stick_now = at
			_stick_vec = Vector2.ZERO
			queue_redraw()
	else:
		if event.index == _stick_touch:
			_stick_touch = -1
			_stick_vec = Vector2.ZERO
			queue_redraw()
		elif event.index == _dash_touch:
			_dash_touch = -1
			_dash_btn.set_pressed_look(false)
		elif event.index == _aim_touch:
			_release_power()


func _on_drag(event: InputEventScreenDrag) -> void:
	if event.index == _stick_touch:
		_stick_now = event.position
		var delta := _stick_now - _stick_center
		if delta.length() > STICK_R:  # The stick follows the thumb, so it never runs out of travel.
			_stick_center = _stick_now - delta.normalized() * STICK_R
			delta = _stick_now - _stick_center
		_stick_vec = delta / STICK_R if delta.length() > 6.0 else Vector2.ZERO
		queue_redraw()
	elif event.index == _aim_touch:
		_aim_now = event.position
		queue_redraw()


func _release_power() -> void:
	_use_btn.set_pressed_look(false)
	var drag := _aim_now - _aim_start
	var aim := Vector2.ZERO
	if drag.length() > AIM_DEADZONE:
		aim = _screen_to_world(drag.normalized())
	_aim_touch = -1
	queue_redraw()
	Haptics.buzz("power")
	use_pressed.emit(aim)


func _on_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT and event.button_index != MOUSE_BUTTON_RIGHT:
		return
	var at := event.position
	if event.pressed:
		if _hit(_use_btn, at, 0.0):
			_mouse_aiming = true
			_aim_start = at
			_aim_now = at
			_use_btn.set_pressed_look(true)
		elif _hit(_dash_btn, at, 0.0):
			_dash_btn.set_pressed_look(true)
			dash_pressed.emit()
		elif _skill_at(at) >= 0:
			_press_skill(_skill_at(at), Vector2.ZERO)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			use_pressed.emit(_mouse_world_aim(at))
	else:
		if _mouse_aiming:
			_mouse_aiming = false
			_release_power()
		_dash_btn.set_pressed_look(false)


func _skill_at(at: Vector2) -> int:
	for i in _skill_btns.size():
		if _hit(_skill_btns[i], at, 0.0):
			return i
	return -1


func _press_skill(index: int, aim: Vector2) -> void:
	if index >= _skill_btns.size():
		return
	Haptics.buzz("power")
	skill_pressed.emit(index, aim)


## Right-click aims a powerup at the spot under the mouse.
func _mouse_world_aim(at: Vector2) -> Vector2:
	var me := sim.player_by_id(runner.local_id)
	var cam := view.camera
	if me == null or cam == null:
		return Vector2.ZERO
	var from := cam.project_ray_origin(at)
	var dir := cam.project_ray_normal(at)
	if absf(dir.y) < 0.001:
		return Vector2.ZERO
	var hit := from + dir * (-from.y / dir.y)
	var ground := Vector2(hit.x, hit.z) - me.pos
	return ground.normalized() if ground.length() > 0.5 else Vector2.ZERO


func _on_key(event: InputEventKey) -> void:
	match event.physical_keycode:
		KEY_SPACE, KEY_SHIFT:
			_press_action(true)
		KEY_E, KEY_ENTER, KEY_F:
			_press_action(false)
		KEY_Q:
			_press_skill(0, _mouse_world_aim(get_viewport().get_mouse_position()))
		KEY_R:
			_press_skill(1, _mouse_world_aim(get_viewport().get_mouse_position()))
		KEY_ESCAPE, KEY_P:
			pause_pressed.emit()
		KEY_1, KEY_2, KEY_3, KEY_4:
			var list := Profile.equipped_emotes()
			var i: int = event.physical_keycode - KEY_1
			if i < list.size():
				emote_pressed.emit(list[i])


func _on_pad(event: InputEventJoypadButton) -> void:
	match event.button_index:
		JOY_BUTTON_A:
			_press_action(true)
		JOY_BUTTON_X, JOY_BUTTON_B:
			_press_action(false)
		JOY_BUTTON_LEFT_SHOULDER:
			_press_skill(0, Vector2.ZERO)
		JOY_BUTTON_RIGHT_SHOULDER:
			_press_skill(1, Vector2.ZERO)
		JOY_BUTTON_START:
			pause_pressed.emit()
		JOY_BUTTON_Y:
			_toggle_emotes()


func _press_action(dash: bool) -> void:
	var me := sim.player_by_id(runner.local_id)
	if me and me.state == Sim.State.JAIL:
		mash_pressed.emit()
	elif dash:
		dash_pressed.emit()
	else:
		var pad := _pad_right_vec()
		use_pressed.emit(_screen_to_world(pad.normalized()) if pad != Vector2.ZERO else Vector2.ZERO)
		Haptics.buzz("power")


func _pad_right_vec() -> Vector2:
	for pad in Input.get_connected_joypads():
		var v := Vector2(Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X), Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y))
		if v.length() > 0.3:
			return v
	return Vector2.ZERO


func _draw() -> void:
	if _stick_touch >= 0:
		draw_circle(_stick_center, STICK_R + 6.0, Color(UiKit.INK, 0.6))
		draw_arc(_stick_center, STICK_R + 6.0, 0.0, TAU, 48, Color(1, 1, 1, 0.5), 4.0, true)
		var knob := _stick_center + _stick_vec * STICK_R
		draw_circle(knob, 34.0, UiKit.INK)
		draw_circle(knob, 28.0, Color(1, 1, 1, 0.9))
	if _aim_touch >= 0:
		var drag := _aim_now - _aim_start
		if drag.length() > AIM_DEADZONE:
			# The aim, from the player on the screen, in the direction of the drag.
			var me := sim.player_by_id(runner.local_id)
			if me:
				var world := view.avatar_of(me.id).global_position + Vector3(0, 0.1, 0)
				var at: Variant = view.screen_of(world)
				if at is Vector2:
					var from: Vector2 = at
					var dir := drag.normalized()
					var end := from + dir * 180.0
					draw_line(from, end, Color(UiKit.INK, 0.7), 12.0, true)
					draw_line(from, end, UiKit.YELLOW, 6.0, true)
					draw_circle(end, 12.0, UiKit.INK)
					draw_circle(end, 8.0, UiKit.YELLOW)


func _process(_delta: float) -> void:
	if not _touch and _mouse_aiming:
		queue_redraw()
