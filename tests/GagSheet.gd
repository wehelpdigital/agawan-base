extends Node
## All the characters on one sheet, either as they stand or caught in the middle of their gags:
##   godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1800x1000 res://tests/GagSheet.tscn
##       -- --out=<file.png> [--gag=0.45] [--yaw=-0.2] [--also=hat:cap,mask:shades] [--back]
## --gag is how far through the gag to stop. Without it, you see each one at rest.

var _out := "user://gags.png"
var _gag := -1.0
var _yaw := -0.2
var _also := {}


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--gag="):
			_gag = float(arg.trim_prefix("--gag="))
		elif arg.begins_with("--yaw="):
			_yaw = float(arg.trim_prefix("--yaw="))
		elif arg.begins_with("--also="):
			for pair in arg.trim_prefix("--also=").split(","):
				_also[pair.get_slice(":", 0)] = pair.get_slice(":", 1)
	var world := Node3D.new()
	add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("9fe3a8")
	var holder := WorldEnvironment.new()
	holder.environment = env
	world.add_child(holder)
	var camera := Camera3D.new()
	camera.fov = 20.0
	world.add_child(camera)
	var columns := 7
	var cell := Vector2(2.35, 2.75)
	var heroes := Cosmetics.HEROES
	for i in heroes.size():
		var look := Cosmetics.default_look()
		for slot_name: String in ["mask", "top", "pants", "shoes"]:
			look[slot_name] = ""
		look["face"] = ""
		look["char"] = heroes[i]["id"]
		look.merge(_also, true)
		var avatar := Avatar3D.new()
		avatar.set_process(false)
		world.add_child(avatar)
		avatar.setup(look, Color("ffb21f"))
		avatar.position = Vector3((i % columns) * cell.x, -(i / columns) * cell.y, 0)
		avatar.rotation.y = _yaw
		if _gag >= 0.0:
			avatar.play_gag()
			var steps := 30
			for _s in steps:
				avatar.animate(avatar._gag_total * _gag / steps)
		else:
			avatar.animate(0.3)
		var label := Label3D.new()
		label.text = String(heroes[i]["name"])
		label.font_size = 40
		label.outline_size = 10
		label.pixel_size = 0.0065
		label.outline_modulate = Color("0a1426")
		label.no_depth_test = true
		label.position = avatar.position + Vector3(0, 2.3, 0)
		world.add_child(label)
	var rows := ceili(heroes.size() / float(columns))
	var view := get_viewport().get_visible_rect().size
	var half := tan(deg_to_rad(camera.fov) * 0.5)
	var center := Vector3((columns - 1) * cell.x * 0.5, -(rows - 1) * cell.y * 0.5 + 1.1, 0)
	var distance := maxf(rows * cell.y * 0.5 / half, columns * cell.x * 0.5 / (half * view.x / view.y)) * 1.02
	camera.position = center + Vector3(0, sin(0.1) * distance, cos(0.1) * distance)
	camera.look_at(center)
	await get_tree().create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out)
	get_tree().quit()
