class_name ChatPanel
extends VBoxContainer
## Live chat for one channel: "global" or "guild". Used by the Chat tab and on the guild page.

const MAX_LINES := 80
const QUICK := ["Hi!", "GG!", "Anyone up for a match?", "Nice one!", "Join my guild!", "Salamat!"]

var channel := "global"
var _list: VBoxContainer
var _scroll: ScrollContainer
var _field: LineEdit
var _send_btn: GameButton
var _note: Label


func _init(p_channel := "global") -> void:
	channel = p_channel
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)


func _ready() -> void:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiKit.card_style(Color(UiKit.INK, 0.72), 14, 3))
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(frame)
	_scroll = UiKit.scroller()
	frame.add_child(_scroll)
	_list = UiKit.vbox(5)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)
	_note = UiKit.body("", 17, UiKit.MUTED)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_list.add_child(_note)
	var quick_scroll := UiKit.scroller(true)
	quick_scroll.custom_minimum_size.y = 46
	quick_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	quick_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var quick := UiKit.hbox(6)
	quick_scroll.add_child(quick)
	for text: String in QUICK:
		var b := UiKit.button(text, "teal", 14)
		b.custom_minimum_size.y = 42
		b.pressed.connect(func() -> void: _send(text))
		quick.add_child(b)
	add_child(quick_scroll)
	var row := UiKit.hbox(6)
	_field = LineEdit.new()
	_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field.placeholder_text = "Say something..."
	_field.max_length = 140
	_field.custom_minimum_size.y = 50
	_field.text_submitted.connect(func(text: String) -> void: _send(text))
	row.add_child(_field)
	_send_btn = UiKit.button("Send", "green", 18)
	_send_btn.custom_minimum_size = Vector2(84, 50)
	_send_btn.pressed.connect(func() -> void: _send(_field.text))
	row.add_child(_send_btn)
	add_child(row)
	Net.chat_received.connect(_on_chat)
	Net.chat_history.connect(_on_history)
	Net.status_changed.connect(func(_on: bool) -> void: _refresh_state())
	_refresh_state()


func _refresh_state() -> void:
	var can_talk := Net.online and (channel != "guild" or Profile.guild_id != 0)
	_field.editable = can_talk
	_send_btn.disabled = not can_talk
	if not Net.online:
		_note.text = "Chat needs the game server. You're offline right now."
		_note.visible = true
	else:
		_note.text = "Be nice out there. Say hi!"
		_note.visible = _list.get_child_count() <= 1
		Net.request_chat_history(channel)


func _send(text: String) -> void:
	var clean := text.strip_edges()
	if clean == "" or not Net.online:
		return
	Net.send_chat(channel, clean)
	_field.text = ""


func _on_history(from_channel: String, messages: Array) -> void:
	if from_channel != channel:
		return
	for child in _list.get_children():
		if child != _note:
			child.queue_free()
	_note.visible = messages.is_empty()
	for message: Variant in messages:
		if message is Dictionary:
			_add_line(message)
	_to_bottom()


func _on_chat(from_channel: String, message: Dictionary) -> void:
	if from_channel != channel:
		return
	_note.visible = false
	_add_line(message)
	if _list.get_child_count() > MAX_LINES:
		var oldest := _list.get_child(1)
		_list.remove_child(oldest)
		oldest.queue_free()
	_to_bottom()
	if str(message.get("name", "")) != Profile.player_name:
		Audio.sfx("chat_message", 0.5)


func _add_line(message: Dictionary) -> void:
	var sender := str(message.get("name", "?"))
	var is_me := sender == Profile.player_name
	var line := UiKit.vbox(0)
	var head := UiKit.hbox(6)
	var who := UiKit.label(sender, 15, UiKit.YELLOW if is_me else Color("9fe6ff"), 3, true)
	head.add_child(who)
	var league := Ranks.league_for(int(message.get("trophies", 0)))
	var rank := UiKit.label(String(league["name"]), 12, league["color"])
	head.add_child(rank)
	if str(message.get("guild", "")) != "":
		head.add_child(UiKit.label("[%s]" % str(message["guild"]), 12, UiKit.MUTED))
	line.add_child(head)
	var text := UiKit.body(str(message.get("text", "")), 17)
	line.add_child(text)
	_list.add_child(line)


func _to_bottom() -> void:
	await get_tree().process_frame
	if is_instance_valid(_scroll):
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)
