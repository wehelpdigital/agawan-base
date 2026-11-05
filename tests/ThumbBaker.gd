extends Node
## Renders the pictures the menus use: a shop card of every wearable thing on its own, every avatar, and a
## small view of every map. Run it after changing how those look:
##   godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 400x400 res://tests/ThumbBaker.tscn
## Add -- --only=shop or --only=maps to do just one set.

const SHOP_SIZE := 192
const MAP_SIZE := Vector2i(320, 180)

var _viewport: SubViewport
var _only := ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
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
	for old in DirAccess.get_files_at("res://assets/shop"):
		DirAccess.remove_absolute("res://assets/shop/" + old)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(SHOP_SIZE, SHOP_SIZE)
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_8X
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
		for entry: Dictionary in Cosmetics.list(slot):
			var id: String = entry["id"]
			if id == "" and slot != "face":  # The plain face is a face too; the other empty slots are nothing.
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
			var image := _viewport.get_texture().get_image()
			image.save_webp(ProjectSettings.globalize_path(Cosmetics.thumb_path(slot, id)), true, 0.85)
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


func _frame(camera: Camera3D, box: AABB) -> void:
	var center := box.get_center()
	var radius := box.size.length() * 0.5
	var distance := maxf(radius, 0.15) / tan(deg_to_rad(camera.fov) * 0.5) * 1.02
	camera.position = center + Vector3(0, 0.34, 0.94).normalized() * distance
	camera.look_at(center)


func _bake_maps() -> void:
	for old in DirAccess.get_files_at("res://assets/maps"):
		DirAccess.remove_absolute("res://assets/maps/" + old)
	_viewport = SubViewport.new()
	_viewport.size = MAP_SIZE
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	for map: Dictionary in Maps.all():
		var world := Node3D.new()
		_viewport.add_child(world)
		var sim := Sim.new()
		sim.setup(map["id"], [], 1)
		world.add_child(ArenaBuilder.build(sim, false))
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(Maps.THEMES[map["theme"]]["sky"])
		var holder := WorldEnvironment.new()
		holder.environment = env
		world.add_child(holder)
		var camera := Camera3D.new()
		camera.fov = 30.0
		world.add_child(camera)
		var arena := sim.arena_size()
		var center := Vector3(arena.x * 0.5, 0, arena.y * 0.5)
		var aspect := float(MAP_SIZE.x) / MAP_SIZE.y
		var reach := arena.x * 0.5 / (tan(deg_to_rad(camera.fov) * 0.5) * aspect) * 1.06
		camera.position = center + Vector3(0, 62, 36).normalized() * reach
		camera.look_at(center)
		camera.make_current()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var image := _viewport.get_texture().get_image()
		image.save_webp(ProjectSettings.globalize_path(Maps.thumb_path(map["id"])), true, 0.8)
		world.queue_free()
		await get_tree().process_frame
