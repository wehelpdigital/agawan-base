extends Node
## Measures whether what's written on a button sits in the middle of its face, by looking at the pixels:
##   godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1280x900 res://tests/ButtonShot.tscn -- --out=<file.png>
## Prints how far off each one is, across and down. Tight buttons have to shrink their words to fit.

var _out := "user://buttons.png"
var _buttons: Array[GameButton] = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	var layer := Control.new()
	layer.theme = UiKit.theme()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var back := ColorRect.new()
	back.color = Color("2f8bf0")
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(back)
	var y := 16.0
	for font_size: int in [13, 14, 15, 16, 18, 20, 22, 24, 28, 34]:
		var x := 16.0
		for entry: Array in [["Rank up", "yellow", ""], ["PLAY ONLINE", "yellow", ""], ["Take out", "yellow", ""], ["agg", "yellow", ""], ["HAND", "yellow", "star"], ["Shop", "yellow", "star"]]:
			var b := UiKit.button(String(entry[0]), String(entry[1]), font_size, String(entry[2]))
			layer.add_child(b)
			b.position = Vector2(x, y)
			b.size = b.custom_minimum_size
			x += b.size.x + 14.0
			_buttons.append(b)
		y += maxf(font_size * 1.6 + 16.0, 48.0) + 14.0
	# Far too small for what's on them.
	var x2 := 16.0
	for entry: Array in [["Two already", 70.0, ""], ["Normal", 44.0, ""], ["Sky: Surprise", 90.0, "star"], ["BIG WORDS HERE", 100.0, ""]]:
		var tight := UiKit.button(String(entry[0]), "yellow", 18, String(entry[2]))
		tight.custom_minimum_size = Vector2(float(entry[1]), 48.0)
		layer.add_child(tight)
		tight.position = Vector2(x2, y)
		tight.size = tight.custom_minimum_size
		x2 += tight.size.x + 20.0
		_buttons.append(tight)
	_measure.call_deferred()


func _measure() -> void:
	for _i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(_out)
	var worst_x := 0.0
	var worst_y := 0.0
	var total_y := 0.0
	var count := 0
	for b: GameButton in _buttons:
		if b._icon != null:
			continue
		# Dark letters on a yellow face.
		var on_screen: Transform2D = get_viewport().get_final_transform()
		var ui_face := Rect2(b.position + Vector2.ONE * GameButton.OUTLINE, b.size - Vector2(GameButton.OUTLINE * 2.0, GameButton.OUTLINE * 2.0 + GameButton.LIP - 2.0))
		var scale_now := on_screen.get_scale().x
		var drawn := on_screen * ui_face
		var face := Rect2i(Vector2i(drawn.position), Vector2i(drawn.size))
		var low := Vector2i(100000, 100000)
		var high := Vector2i(-1, -1)
		for py in range(face.position.y, face.end.y):
			for px in range(face.position.x, face.end.x):
				var c := image.get_pixel(px, py)
				if c.r + c.g + c.b < 0.7:
					low = Vector2i(mini(low.x, px), mini(low.y, py))
					high = Vector2i(maxi(high.x, px), maxi(high.y, py))
		if high.x < 0:
			continue
		var off_x := ((low.x + high.x + 1) * 0.5 - (face.position.x + face.size.x * 0.5)) / scale_now
		var off_y := ((low.y + high.y + 1) * 0.5 - (face.position.y + face.size.y * 0.5)) / scale_now
		var fits := low.x > face.position.x + 1 and high.x < face.end.x - 2 and low.y > face.position.y and high.y < face.end.y - 1
		print("%-16s size %2d: %4.1f across, %4.1f down%s" % [b.get_text(), b._font_size, off_x, off_y, "" if fits else "  DOESN'T FIT"])
		if b.get_text() != "agg":
			total_y += off_y / b._font_size
			count += 1
		worst_x = maxf(worst_x, absf(off_x))
		worst_y = maxf(worst_y, absf(off_y))
	print("worst: %.1f across, %.1f down. Average %.3f of the font size down." % [worst_x, worst_y, total_y / maxi(count, 1)])
	get_tree().quit()
