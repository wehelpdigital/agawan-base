extends Control
## Every icon, or every power card, on one sheet, to check them after running tools/gen_icons.py:
##   godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1800x1000 res://tests/IconSheet.tscn
##       -- --set=ui --out=<file.png>        (--set=power for the cards, --from=N to start later in the list)

var _set := "ui"
var _out := "user://icons.png"
var _from := 0
var _files: Array[String] = []
var _keep: Array[Texture2D] = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--set="):
			_set = arg.trim_prefix("--set=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--from="):
			_from = int(arg.trim_prefix("--from="))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for file in DirAccess.get_files_at("res://assets/icons/%s" % _set):
		if file.ends_with(".svg"):
			_files.append(file)
	_files = _files.slice(_from)
	queue_redraw()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out)
	get_tree().quit()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("4a2bb0"))
	var cards := _set == "power"
	var cell := Vector2(150, 210) if cards else Vector2(128, 132)
	var columns := int(size.x / cell.x)
	var font := ThemeDB.fallback_font
	for i in _files.size():
		var at := Vector2((i % columns) * cell.x + 8.0, (i / columns) * cell.y + 6.0)
		var texture: Texture2D = load("res://assets/icons/%s/%s" % [_set, _files[i]])
		_keep.append(texture)  # Drawing happens later: a texture nothing holds on to would be gone by then.
		var id := _files[i].get_basename()
		if cards:
			if id == "_back":
				draw_texture_rect(texture, Rect2(at, Vector2(138, 184)), false)
			else:
				PowerCard.paint(self, Rect2(at, Vector2(138, 184)), id)
		else:
			# On the colours buttons really have, to see how each reads on them.
			draw_rect(Rect2(at, Vector2(58, 100)), Color("2b2466"))
			draw_rect(Rect2(at + Vector2(58, 0), Vector2(58, 100)), Color("ffd23f"))
			draw_texture_rect(texture, Rect2(at + Vector2(8, 4), Vector2(100, 100)), false)
			draw_string(font, at + Vector2(0, 118), id, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
