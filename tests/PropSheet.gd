extends Node
## Every map object in a grid, seen from the match camera's angle, on a floor like the real one:
##   godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1800x1100 res://tests/PropSheet.tscn
##       -- --out=<file.png> [--set=blocks|decor|all] [--only=a,b,c] [--columns=9]

const CAM_PITCH := 0.96

var _out := "user://props.png"
var _set := "all"
var _columns := 9
var _only: PackedStringArray = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--set="):
			_set = arg.trim_prefix("--set=")
		elif arg.begins_with("--columns="):
			_columns = int(arg.trim_prefix("--columns="))
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",")
	var names: Array[String] = []
	for theme: String in Maps.THEME_ORDER:
		var lists: Array = []
		if _set != "decor":
			lists.append(Maps.THEMES[theme]["blocks"])
		if _set != "blocks":
			lists.append(Maps.THEMES[theme]["decor"])
		for list: Array in lists:
			for prop: String in list:
				if not names.has(prop) and (_only.is_empty() or _only.has(prop)):
					names.append(prop)
	var world := Node3D.new()
	add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("7fd65a")
	var holder := WorldEnvironment.new()
	holder.environment = env
	world.add_child(holder)
	var kit := ArenaBuilder.prop_kit(false)
	var cell := Vector2(4.2, 4.6)
	var columns := mini(_columns, names.size())
	var rows := ceili(names.size() / float(columns))
	for i in names.size():
		var at := Vector3((i % columns) * cell.x, 0, (i / columns) * cell.y)
		PropKit.draw(kit, names[i], at, 0.0, Maps.TILE / 1.5, 0.3, Color("ff5a7a"))
		var label := Label3D.new()
		label.text = names[i]
		label.font_size = 40
		label.outline_size = 10
		label.pixel_size = 0.012
		label.outline_modulate = Color("0a1426")
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.position = at + Vector3(0, 0.1, 1.75)
		world.add_child(label)
	var inst := MeshInstance3D.new()
	inst.mesh = kit.to_mesh()
	inst.material_override = ArenaBuilder.prop_material()
	world.add_child(inst)
	var camera := Camera3D.new()
	camera.fov = 30.0
	world.add_child(camera)
	var center := Vector3((columns - 1) * cell.x * 0.5, 0.4, (rows - 1) * cell.y * 0.5)
	var view := get_viewport().get_visible_rect().size
	var half := tan(deg_to_rad(camera.fov) * 0.5)
	var distance := maxf((columns * cell.x) * 0.5 / (half * view.x / view.y), (rows * cell.y) * 0.5 * sin(CAM_PITCH) / half) * 1.04
	camera.position = center + Vector3(0, sin(CAM_PITCH), cos(CAM_PITCH)) * distance
	camera.look_at(center)
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out)
	get_tree().quit()
