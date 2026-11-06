extends Node
## Renders the pictures the menus use: a shop card of every wearable thing on its own, every avatar, and a
## small view of every map. Run it after changing how those look:
##   godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 400x400 res://tests/ThumbBaker.tscn
## Add -- --only=shop or --only=maps to do just one set, and --slots=hat,pet or --ids=a,b to redo just those.

const SHOP_SIZE := 320
const MAP_SIZE := Vector2i(384, 216)
const SHARPEN := 3  ## Drawn this many times too big, then shrunk: the cleanest edges there are.

var _viewport: SubViewport
var _only := ""
var _slots: PackedStringArray = []
var _ids: PackedStringArray = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
		elif arg.begins_with("--slots="):
			_slots = arg.trim_prefix("--slots=").split(",")
		elif arg.begins_with("--ids="):
			_ids = arg.trim_prefix("--ids=").split(",")
	DirAccess.make_dir_recursive_absolute("res://assets/shop")
	DirAccess.make_dir_recursive_absolute("res://assets/maps")
	_run.call_deferred()


func _run() -> void:
	if _only != "maps":
		await _bake_shop()
	if _only != "shop":
		await _bake_maps()
	print("thumbnails done")
	get_tree().quit()


func _bake_shop() -> void:
	if _slots.is_empty() and _ids.is_empty():
		for old in DirAccess.get_files_at("res://assets/shop"):
			if old.ends_with(".webp"):  # Their .import files say how to pack them small; those stay.
				DirAccess.remove_absolute("res://assets/shop/" + old)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(SHOP_SIZE, SHOP_SIZE) * SHARPEN
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_DISABLED
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	var world := Node3D.new()
	_viewport.add_child(world)
	var camera := Camera3D.new()
	camera.fov = 24.0
	world.add_child(camera)
	var holder := Node3D.new()
	world.add_child(holder)
	var avatar := Avatar3D.new()
	avatar.set_process(false)
	world.add_child(avatar)
	var helper := Avatar3D.new()
	for slot: String in Cosmetics.BAKED_SLOTS:
		if not _slots.is_empty() and not _slots.has(slot):
			continue
		for entry: Dictionary in Cosmetics.list(slot):
			var id: String = entry["id"]
			if id == "" and slot != "face":  # The plain face is a face too; the other empty slots are nothing.
				continue
			if not _ids.is_empty() and not _ids.has(id):
				continue
			for child in holder.get_children():
				holder.remove_child(child)
				child.free()
			var box := AABB()
			if slot == "char" or slot == "face":
				var look := Cosmetics.default_look()
				for slot_name: String in ["mask", "top", "pants", "shoes"]:
					look[slot_name] = ""
				if slot == "char":
					look["char"] = id
				else:
					look["face"] = id
				avatar.visible = true
				avatar.setup(look, Color("ffb21f"))
				avatar.rotation.y = -0.35 if slot == "char" else -0.15
				avatar.animate(0.0)
				box = AABB(Vector3(-0.8, 0.0, -0.5), Vector3(1.6, 2.0, 1.0)) if slot == "char" else AABB(Vector3(-0.7, 0.62, -0.3), Vector3(1.4, 1.1, 0.6))
			else:
				avatar.visible = false
				box = _place_accessory(holder, helper, slot, id)
			_frame(camera, box)
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var image := _shrink_clean(_viewport.get_texture().get_image(), SHOP_SIZE)
			image.save_webp(ProjectSettings.globalize_path(Cosmetics.thumb_path(slot, id)), true, 0.95)
	_viewport.queue_free()
	helper.free()


## Puts the item in the picture; shoes and gloves come as a pair. Returns its bounds.
func _place_accessory(holder: Node3D, helper: Avatar3D, slot: String, id: String) -> AABB:
	var mesh := helper.accessory_mesh(slot, id)
	var mat := Avatar3D._material("normal")
	var yaw := PI - 0.45 if slot == "back" else -0.45
	var offsets: Array[Vector3] = [Vector3.ZERO]
	if slot == "shoes":
		offsets = [Vector3(-0.2, 0, 0), Vector3(0.2, 0, -0.05)]
	elif slot == "gloves":
		offsets = [Vector3(-0.27, 0, 0), Vector3(0.27, 0, 0)]
	var box := AABB()
	var first := true
	holder.rotation = Vector3(0, yaw, 0)
	for offset in offsets:
		var inst := MeshInstance3D.new()
		inst.mesh = mesh
		inst.material_override = mat
		inst.position = offset
		holder.add_child(inst)
		var part: AABB = inst.global_transform * mesh.get_aabb() if inst.is_inside_tree() else mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box


## Shrinks a picture with see-through parts without letting the see-through colour leak into its edges.
func _shrink_clean(image: Image, side: int) -> Image:
	image.convert(Image.FORMAT_RGBA8)
	image.premultiply_alpha()
	image.resize(side, side, Image.INTERPOLATE_LANCZOS)
	var data := image.get_data()
	for i in range(0, data.size(), 4):
		var a := data[i + 3]
		if a > 0 and a < 255:
			data[i] = mini(data[i] * 255 / a, 255)
			data[i + 1] = mini(data[i + 1] * 255 / a, 255)
			data[i + 2] = mini(data[i + 2] * 255 / a, 255)
	var clean := Image.create_from_data(side, side, false, Image.FORMAT_RGBA8, data)
	clean.fix_alpha_edges()
	return clean


func _frame(camera: Camera3D, box: AABB) -> void:
	var center := box.get_center()
	var radius := box.size.length() * 0.5
	var distance := maxf(radius, 0.15) / tan(deg_to_rad(camera.fov) * 0.5) * 1.02
	camera.position = center + Vector3(0, 0.34, 0.94).normalized() * distance
	camera.look_at(center)


func _bake_maps() -> void:
	for old in DirAccess.get_files_at("res://assets/maps"):
		if old.ends_with(".webp"):
			DirAccess.remove_absolute("res://assets/maps/" + old)
	_viewport = SubViewport.new()
	_viewport.size = MAP_SIZE * 2
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for map: Dictionary in Maps.all():
		# A moment from a real game, in clear weather, from low down at the side of the field.
		var seats: Array = []
		for i in 10:
			seats.append({"name": "Bot %d" % i, "bot": true, "team": i % 2, "skill": 0.7, "look": Cosmetics.random_look(rng, 0.7)})
		var sim := Sim.new()
		sim.setup(map["id"], seats, 1, 0.7, "clear")
		for i in int((Sim.COUNTDOWN + 9.0) / Sim.TICK):
			sim.step(Sim.TICK)
		sim.take_events()
		var view := MatchView.new()
		view.film = true
		_viewport.add_child(view)
		view.setup(sim, -1)
		view.set_process(false)
		Audio.silent += 1
		for i in 12:
			sim.step(Sim.TICK)
			view._process(Sim.TICK)
		Audio.silent -= 1
		var arena := sim.arena_size()
		var center := Vector3(arena.x * 0.5, 0, arena.y * 0.5)
		var reach := clampf(arena.x * 0.66, 30.0, 54.0)
		view.camera.global_position = center + Vector3(sin(0.55) * cos(0.46), sin(0.46), cos(0.55) * cos(0.46)) * reach
		view.camera.look_at(center + Vector3(0, 0.5, 0), Vector3.UP)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var image := _viewport.get_texture().get_image()
		image.resize(MAP_SIZE.x, MAP_SIZE.y, Image.INTERPOLATE_LANCZOS)
		image.save_webp(ProjectSettings.globalize_path(Maps.thumb_path(map["id"])), true, 0.9)
		_viewport.remove_child(view)
		view.free()
		await get_tree().process_frame
