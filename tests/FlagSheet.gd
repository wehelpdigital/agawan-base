extends SceneTree
## Every flag on one sheet, to check them by eye. No window needed:
##   godot --headless --path . --script res://tests/FlagSheet.gd -- --out=<file.png>

const COLUMNS := 12


func _init() -> void:
	var out := "user://flags.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	var flags: Array = Flags.ALL.filter(func(entry: Dictionary) -> bool: return entry["id"] != "")
	var cell := Vector2i(144, 112)
	var rows := (flags.size() + COLUMNS - 1) / COLUMNS
	var sheet := Image.create(cell.x * COLUMNS, cell.y * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("3aa6ff"))
	for i in flags.size():
		var image := Image.new()
		image.load_svg_from_string(Flags.svg(flags[i]["id"], true), 1.0)
		image.convert(Image.FORMAT_RGBA8)
		sheet.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(i % COLUMNS * cell.x + 6, i / COLUMNS * cell.y + 8))
	sheet.save_png(out)
	print("%d flags on %s" % [flags.size(), out])
	quit()
