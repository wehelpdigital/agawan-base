extends Node
## A lineup of heroes on a plain background, to check how they look close up:
##   godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1500x620 res://tests/AvatarShot.tscn -- --out=<file.png>

var _out := "user://avatars.png"
var _slot := ""
var _only: PackedStringArray = []
var _faces := ""  ## An avatar to show in every expression.


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--slot="):
			_slot = arg.trim_prefix("--slot=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",")
		elif arg.begins_with("--faces="):
			_faces = arg.trim_prefix("--faces=")
	var world := Node3D.new()
	add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("9fe3a8")
	var holder := WorldEnvironment.new()
	holder.environment = env
	world.add_child(holder)
	var camera := Camera3D.new()
	camera.fov = 22.0
	world.add_child(camera)
	var list := Cosmetics.list(_slot if _slot != "" else "char").duplicate()
	if not _only.is_empty():
		list = list.filter(func(entry: Dictionary) -> bool: return _only.has(entry["id"]))
	var columns := mini(7, list.size())
	var rows := ceili(list.size() / float(columns))
	for i in list.size():
		var look := Cosmetics.default_look()
		if _slot == "":
			for slot_name: String in ["mask", "top", "pants", "shoes"]:
				look[slot_name] = ""
		look[_slot if _slot != "" else "char"] = String(list[i]["id"])
		var avatar := Avatar3D.new()
		world.add_child(avatar)
		avatar.setup(look, Color("ffb21f"))
		avatar.position = Vector3((i % columns) * 2.0, -(i / columns) * 2.6, 0)
		avatar.rotation.y = -0.4 if _slot != "back" else PI - 0.4
	if _faces != "":
		await _show_faces(world, camera)
		return
	var center := Vector3((columns - 1) * 1.0, -(rows - 1) * 1.3 + 1.0, 0)
	camera.position = center + Vector3(0, 1.8, 2.0 + maxf(columns * 1.6, rows * 5.5))
	camera.look_at(center)
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out)
	get_tree().quit()


func _show_faces(world: Node3D, camera: Camera3D) -> void:
	for child in world.get_children():
		if child is Avatar3D:
			child.free()
	var names: Array = Faces.PARTS.keys()
	var columns := 10
	for i in names.size():
		var look := Cosmetics.default_look()
		for slot_name: String in ["mask", "top", "pants", "shoes"]:
			look[slot_name] = ""
		look["char"] = _faces
		var avatar := Avatar3D.new()
		world.add_child(avatar)
		avatar.setup(look, Color("ffb21f"))
		avatar.position = Vector3((i % columns) * 1.5, -(i / columns) * 1.5, 0)
		avatar.rotation.y = -0.1
		avatar.calm = true
		avatar.react(names[i], 999.0)
	var rows := ceili(names.size() / float(columns))
	var center := Vector3((columns - 1) * 0.75, 1.1 - (rows - 1) * 0.75, 0)
	camera.position = center + Vector3(0, 0.3, 4.0 + rows * 3.7)
	camera.look_at(center)
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out)
	get_tree().quit()
