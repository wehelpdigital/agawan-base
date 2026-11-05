extends Node
## Every item in one slot, worn by one avatar, with its name above it, to check how things fit:
##   godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1800x1000 res://tests/ItemAudit.tscn
##       -- --slot=mask --hero=kiko --out=<file.png> [--yaw=-0.4] [--columns=8] [--only=a,b,c] [--close] [--also=hat:cap]
## --heroes=a,b,c shows one item on each of those avatars instead: --slot=hat --only=cap --heroes=kiko,muning,botbot

var _out := "user://audit.png"
var _slot := "mask"
var _hero := "kiko"
var _yaw := -0.4
var _columns := 8
var _only: PackedStringArray = []
var _close := false
var _also: Dictionary = {}
var _heroes: PackedStringArray = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--slot="):
			_slot = arg.trim_prefix("--slot=")
		elif arg.begins_with("--hero="):
			_hero = arg.trim_prefix("--hero=")
		elif arg.begins_with("--yaw="):
			_yaw = float(arg.trim_prefix("--yaw="))
		elif arg.begins_with("--columns="):
			_columns = int(arg.trim_prefix("--columns="))
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",")
		elif arg == "--close":
			_close = true
		elif arg.begins_with("--also="):
			for pair in arg.trim_prefix("--also=").split(","):
				_also[pair.get_slice(":", 0)] = pair.get_slice(":", 1)
		elif arg.begins_with("--heroes="):
			_heroes = arg.trim_prefix("--heroes=").split(",")
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
	var items: Array[Dictionary] = []
	for entry: Dictionary in Cosmetics.list(_slot):
		if entry["id"] != "" and (_only.is_empty() or _only.has(entry["id"])):
			items.append(entry)
	var count := _heroes.size() if not _heroes.is_empty() else items.size()
	var columns := mini(_columns, count)
	var rows := ceili(count / float(columns))
	var cell := Vector2(2.3, 2.9) if not _close else Vector2(2.0, 2.05)
	for i in count:
		var look := Cosmetics.default_look()
		for slot_name: String in ["mask", "top", "pants", "shoes"]:
			look[slot_name] = ""
		look["face"] = ""
		look["char"] = _heroes[i] if not _heroes.is_empty() else _hero
		look[_slot] = String(items[0 if not _heroes.is_empty() else i]["id"]) if not items.is_empty() else ""
		look.merge(_also, true)
		var avatar := Avatar3D.new()
		avatar.set_process(false)
		world.add_child(avatar)
		avatar.setup(look, Color("ffb21f"))
		avatar.position = Vector3((i % columns) * cell.x, -(i / columns) * cell.y, 0)
		avatar.rotation.y = _yaw
		avatar.animate(0.3)
		var label := Label3D.new()
		label.text = _heroes[i] if not _heroes.is_empty() else String(items[i]["id"])
		label.font_size = 44
		label.outline_size = 10
		label.pixel_size = 0.0065
		label.modulate = Color.WHITE
		label.outline_modulate = Color("24135f")
		label.position = avatar.position + Vector3(0, 1.98 if _close else 2.2, 0)
		label.no_depth_test = true
		world.add_child(label)
	var view := get_viewport().get_visible_rect().size
	var aspect := view.x / view.y
	var span := Vector2((columns - 1) * cell.x + cell.x, rows * cell.y)
	var center := Vector3((columns - 1) * cell.x * 0.5, -(rows - 1) * cell.y * 0.5 + (1.05 if _close else 1.0), 0)
	var half := tan(deg_to_rad(camera.fov) * 0.5)
	var distance := maxf(span.y * 0.5 / half, span.x * 0.5 / (half * aspect)) * 1.02
	camera.position = center + Vector3(0, sin(0.14) * distance, cos(0.14) * distance)
	camera.look_at(center)
	await get_tree().create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out)
	get_tree().quit()
