extends Control
## Sound, graphics, controls, and where to find the rules and credits.

var root: UiRoot
var args: Dictionary
var screen_name: String


func _ready() -> void:
	var outer := UiKit.vbox(8)
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 10
	outer.offset_right = -10
	outer.offset_top = 4
	outer.offset_bottom = -8
	add_child(outer)
	var head := UiKit.hbox(8)
	var back := UiKit.button("", "ink", 18, "arrow_left")
	back.custom_minimum_size = Vector2(56, 48)
	back.pressed.connect(func() -> void: root.go_back())
	head.add_child(back)
	var heading := UiKit.title("SETTINGS", 28)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(heading)
	outer.add_child(head)
	var scroll := UiKit.scroller()
	outer.add_child(scroll)
	var body := UiKit.vbox(10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	var sound := _section("Sound")
	body.add_child(sound)
	sound.get_child(0).add_child(_slider("Music", Settings.music_volume, func(v: float) -> void:
		Settings.music_volume = v
		Settings.save()))
	sound.get_child(0).add_child(_slider("Effects", Settings.sfx_volume, func(v: float) -> void:
		Settings.sfx_volume = v
		Settings.save()
		Audio.sfx("ui_click")))
	var video := _section("Display")
	body.add_child(video)
	video.get_child(0).add_child(_choice("Graphics", [["auto", "Auto"], ["low", "Fast"], ["high", "Pretty"]], Settings.quality, func(v: String) -> void:
		Settings.quality = v
		Quality.auto_lowered = false
		Settings.save()
		Quality.apply(get_tree())))
	video.get_child(0).add_child(_choice("Text size", [["small", "Small"], ["normal", "Normal"], ["large", "Large"]], Settings.text_size, func(v: String) -> void:
		Settings.text_size = v
		Settings.save()
		UiScale.apply(get_tree())
		root.show_screen("settings")))
	video.get_child(0).add_child(_toggle("Show FPS", Settings.fps_counter, func(on: bool) -> void:
		Settings.fps_counter = on
		Settings.save()))
	var game := _section("Game")
	body.add_child(game)
	game.get_child(0).add_child(_toggle("Vibration", Settings.vibration, func(on: bool) -> void:
		Settings.vibration = on
		Settings.save()))
	game.get_child(0).add_child(_toggle("Camera shake", Settings.camera_shake, func(on: bool) -> void:
		Settings.camera_shake = on
		Settings.save()))
	game.get_child(0).add_child(_toggle("Left-handed buttons", Settings.left_handed, func(on: bool) -> void:
		Settings.left_handed = on
		Settings.save()))
	game.get_child(0).add_child(_toggle("Teaching tips", Settings.hints, func(on: bool) -> void:
		Settings.hints = on
		Settings.save()))
	var info := _section("More")
	body.add_child(info)
	var row := UiKit.hbox(8)
	var how := UiKit.button("Rules", "teal", 17)
	how.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	how.pressed.connect(func() -> void: root.show_screen("howto", {}, true))
	row.add_child(how)
	var credits := UiKit.button("Credits", "teal", 17)
	credits.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	credits.pressed.connect(func() -> void: root.show_screen("credits", {}, true))
	row.add_child(credits)
	info.get_child(0).add_child(row)
	if not OS.has_feature("web"):
		var server_row := UiKit.hbox(8)
		var field := LineEdit.new()
		field.text = Net.server_url()
		field.placeholder_text = "Game server address"
		field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		field.custom_minimum_size.y = 50
		server_row.add_child(field)
		var connect_btn := UiKit.button("Connect", "blue", 16)
		connect_btn.pressed.connect(func() -> void:
			Net.set_server(field.text)
			root.toast("Connecting..."))
		server_row.add_child(connect_btn)
		info.get_child(0).add_child(server_row)


func _section(title: String) -> PanelContainer:
	var card := UiKit.panel(UiKit.CARD, 18, 4)
	var col := UiKit.vbox(8)
	card.add_child(col)
	col.add_child(UiKit.title(title, 20, UiKit.YELLOW))
	return card


func _slider(title: String, value: float, on_change: Callable) -> Control:
	var row := UiKit.hbox(10)
	var caption := UiKit.label(title, 18, UiKit.INK)
	caption.custom_minimum_size.x = 92
	row.add_child(caption)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size.y = 40
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	return row


func _toggle(title: String, value: bool, on_change: Callable) -> Control:
	var row := UiKit.hbox(10)
	var caption := UiKit.label(title, 18, UiKit.INK)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(caption)
	var b := UiKit.button("ON" if value else "OFF", "green" if value else "black", 16)
	b.custom_minimum_size = Vector2(84, 46)
	var state := [value]
	b.pressed.connect(func() -> void:
		state[0] = not state[0]
		b.set_text("ON" if state[0] else "OFF")
		b.set_kind("green" if state[0] else "black")
		on_change.call(state[0]))
	row.add_child(b)
	return row


func _choice(title: String, options: Array, current: String, on_change: Callable) -> Control:
	var col := UiKit.vbox(4)
	col.add_child(UiKit.label(title, 18, UiKit.INK))
	var row := UiKit.hbox(6)
	var buttons: Array[GameButton] = []
	for option: Array in options:
		var id: String = option[0]
		var b := UiKit.button(option[1], "yellow" if id == current else "ink", 16)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 46
		b.pressed.connect(func() -> void:
			for other in buttons:
				other.set_kind("ink")
			b.set_kind("yellow")
			on_change.call(id))
		buttons.append(b)
		row.add_child(b)
	col.add_child(row)
	return col
