extends Control
## Global chat, and your guild's chat if you're in one.

var root: UiRoot
var args: Dictionary
var screen_name: String
var _channel := "global"
var _holder: Control
var _tabs: HBoxContainer


func _ready() -> void:
	var col := UiKit.vbox(6)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 10
	col.offset_right = -10
	col.offset_top = 4
	col.offset_bottom = -6
	add_child(col)
	_tabs = UiKit.hbox(6)
	col.add_child(_tabs)
	_holder = UiKit.vbox(0)
	_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_holder)
	_show()


func _show() -> void:
	for child in _tabs.get_children():
		child.queue_free()
	for entry: Array in [["global", "Global"], ["guild", Profile.guild_name if Profile.guild_id != 0 else "Guild"]]:
		var id: String = entry[0]
		var b := UiKit.button(entry[1], "yellow" if id == _channel else "purple", 17)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 48
		b.pressed.connect(func() -> void:
			if id == "guild" and Profile.guild_id == 0:
				root.toast("Join a guild first!", UiKit.YELLOW)
				return
			_channel = id
			_show())
		_tabs.add_child(b)
	for child in _holder.get_children():
		child.queue_free()
	_holder.add_child(ChatPanel.new(_channel))
