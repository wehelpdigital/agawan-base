extends Node
## How many triangles each hero and each thing you can wear costs, heaviest first. Ten of them are on screen at once:
##   godot --headless --audio-driver Dummy --path . res://tests/ItemCost.tscn


func _ready() -> void:
	_run.call_deferred()


func _count(node: Node) -> int:
	var total := 0
	if node is MeshInstance3D and node.mesh:
		for surface in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			total += index.size() / 3 if index.size() > 0 else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	for child in node.get_children():
		total += _count(child)
	return total


func _run() -> void:
	await get_tree().process_frame
	var base := _cost({})
	print("a plain kid: ", base)
	for slot: String in ["char", "hat", "mask", "back", "top", "pants", "shoes", "gloves", "pet"]:
		var rows: Array = []
		for entry: Dictionary in Cosmetics.list(slot):
			if entry["id"] == "":
				continue
			var look := {}
			look[slot] = entry["id"]
			var cost := _pet_cost(entry["id"]) if slot == "pet" else _cost(look) - (0 if slot == "char" else base)
			rows.append([cost, entry["id"]])
		rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
		var total := 0
		for row: Array in rows:
			total += int(row[0])
		print("%s: average %d, heaviest: %s" % [slot, total / maxi(rows.size(), 1), str(rows.slice(0, 10))])
	get_tree().quit()


func _pet_cost(id: String) -> int:
	var mesh := Pet3D.mesh(id)
	var total := 0
	if mesh:
		for surface in mesh.get_surface_count():
			var arrays: Array = mesh.surface_get_arrays(surface)
			total += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3 if arrays[Mesh.ARRAY_INDEX] == null else (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	return total


func _cost(extra: Dictionary) -> int:
	var look := Cosmetics.default_look()
	for slot_name: String in ["mask", "top", "pants", "shoes"]:
		look[slot_name] = ""
	look.merge(extra, true)
	var avatar := Avatar3D.new()
	add_child(avatar)
	avatar.setup(look, Color("ffb21f"))
	var total := _count(avatar)
	avatar.free()
	return total
