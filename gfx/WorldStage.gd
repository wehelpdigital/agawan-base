class_name WorldStage
extends Node3D
## A tiny planet for the menus to stand on, turning slowly with toy models of famous places on it. It's turned on its side, so the
## equator runs under your feet and everything goes past to your left and right, never through you.

const FULL_RADIUS := 10.0  ## The size it's built at; `setup` scales it.
## Where things are, near enough: latitude, longitude, what, how big, which way it faces.
const PLACES := [
	[48, 2, "eiffel", 0.42], [52, -1, "big_clock", 0.32], [41, 12, "colosseum", 0.26], [37, 25, "blue_dome", 0.42], [52, 5, "windmill", 0.34], [60, 10, "viking_ship", 0.3],
	[30, 31, "pyramid", 0.36], [26, 26, "sphinx", 0.38], [32, -7, "riad", 0.4], [-20, 35, "acacia", 0.56], [-28, 25, "giraffe", 0.46], [-18, 18, "elephant", 0.4],
	[28, 78, "taj", 0.32], [40, 116, "wall_tower", 0.42], [35, 139, "torii", 0.44], [36, 136, "pagoda", 0.4], [38, 127, "sakura", 0.5], [20, 100, "stupa", 0.42],
	[-25, 133, "red_mesa", 0.2], [-30, 145, "kangaroo", 0.62], [-32, 120, "gum_tree", 0.56], [-42, 172, "sheep", 0.6],
	[40, -74, "liberty", 0.36], [43, -80, "skyscraper", 0.3], [37, -122, "palm", 0.5], [55, -110, "pine_snow", 0.62], [60, -100, "moose", 0.5], [66, -40, "igloo", 0.5],
	[20, -89, "step_pyramid", 0.3], [24, -102, "cactus", 0.8], [-22, -43, "sugarloaf", 0.34], [-18, -70, "llama", 0.62], [-30, -60, "toucan_tree", 0.44], [22, -157, "tiki", 0.7],
	[38, 35, "hot_balloon", 0.34], [-12, 148, "palm", 0.5], [-38, 145, "sheep", 0.5], [-16, 47, "palm", 0.5], [-36, 18, "acacia", 0.4], [56, 60, "pine", 0.6], [50, 90, "mountain", 0.26], [-40, -68, "mountain", 0.28],
]

static var _ball: ArrayMesh
static var _props: ArrayMesh
static var _clouds: ArrayMesh
static var _sea_mat: ShaderMaterial

var spin_speed := 0.09
var _turning: Node3D
var _cloud_layer: Node3D


## The top of the planet is at y = 0; its middle is `radius` below.
func setup(radius: float) -> void:
	var size := radius / FULL_RADIUS
	position = Vector3(0, -radius, 0)
	scale = Vector3.ONE * size
	var side_on := Node3D.new()
	side_on.rotation.z = PI * 0.5
	add_child(side_on)
	_turning = Node3D.new()
	side_on.add_child(_turning)
	var ball := MeshInstance3D.new()
	ball.mesh = _globe()
	ball.material_override = _sea()
	ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_turning.add_child(ball)
	var things := MeshInstance3D.new()
	things.mesh = _landmarks()
	things.material_override = ArenaBuilder.prop_material()
	things.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_turning.add_child(things)
	_cloud_layer = Node3D.new()
	side_on.add_child(_cloud_layer)
	var clouds := MeshInstance3D.new()
	clouds.mesh = _puffs()
	clouds.material_override = Avatar3D._material("normal")
	clouds.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cloud_layer.add_child(clouds)


func _process(delta: float) -> void:
	if _turning:
		_turning.rotation.y += delta * spin_speed
		_cloud_layer.rotation.y += delta * spin_speed * 1.4


static func _sea() -> ShaderMaterial:
	if _sea_mat == null:
		_sea_mat = ShaderMaterial.new()
		_sea_mat.shader = preload("res://gfx/shaders/planet.gdshader")
		_sea_mat.set_shader_parameter("picture", preload("res://assets/brand/world_map.png"))
	return _sea_mat


## A ball with the map on it, longitude 0 facing +Z and north up +Y.
static func _globe() -> ArrayMesh:
	if _ball != null:
		return _ball
	var rows := 18 if Quality.is_low() else 28
	var cols := 32 if Quality.is_low() else 48
	var at := func(row: int, col: int) -> Array:
		var lat := PI * 0.5 - PI * row / rows
		var lon := -PI + TAU * col / cols
		var n := Vector3(cos(lat) * sin(lon), sin(lat), cos(lat) * cos(lon))
		return [n * FULL_RADIUS, n, Vector2(float(col) / cols, float(row) / rows)]
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	for row in rows:
		for col in cols:
			var a: Array = at.call(row, col)
			var b: Array = at.call(row, col + 1)
			var c: Array = at.call(row + 1, col + 1)
			var d: Array = at.call(row + 1, col)
			for corner: Array in [a, b, c, a, c, d]:
				verts.append(corner[0])
				norms.append(corner[1])
				uvs.append(corner[2])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	_ball = ArrayMesh.new()
	_ball.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return _ball


static func _surface(latitude: float, longitude: float) -> Transform3D:
	var lat := deg_to_rad(latitude)
	var lon := deg_to_rad(longitude)
	var up := Vector3(cos(lat) * sin(lon), sin(lat), cos(lat) * cos(lon))
	var along := up.cross(Vector3.UP if absf(up.y) < 0.95 else Vector3.RIGHT).normalized()
	var ahead := along.cross(up).normalized()
	return Transform3D(Basis(along, up, ahead), up * (FULL_RADIUS - 0.04))


static func _landmarks() -> ArrayMesh:
	if _props != null:
		return _props
	var k := ArenaBuilder.prop_kit(Quality.is_low())
	k.detail = 0.6
	for place: Array in PLACES:
		k.push(_surface(place[0], place[1]))
		PropKit.draw(k, place[2], Vector3.ZERO, fmod(float(place[1]), 3.0), float(place[3]) * 0.8, fmod(absf(float(place[0])) * 0.13, 1.0), Color("ff5a4e"))
		k.pop()
	# A bit of green round them, and trees all over.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for _i in 60:
		var lat := rng.randf_range(20.0, 62.0) * (1.0 if rng.randf() < 0.6 else -0.7)
		var lon := rng.randf_range(-180.0, 180.0)
		if not _is_land(lat, lon):
			continue
		k.push(_surface(lat, lon))
		var tree := "pine" if absf(lat) > 48.0 else "tree"
		PropKit.draw(k, tree, Vector3.ZERO, 0.0, rng.randf_range(0.2, 0.3))
		k.pop()
	_props = k.to_mesh()
	return _props


## Rough, but enough to keep trees out of the sea.
static func _is_land(lat: float, lon: float) -> bool:
	if lon > -125.0 and lon < -70.0 and lat > 25.0 and lat < 60.0:
		return true
	if lon > -70.0 and lon < -40.0 and lat > -30.0 and lat < 0.0:
		return true
	if lon > -5.0 and lon < 30.0 and lat > 40.0 and lat < 60.0:
		return true
	if lon > 10.0 and lon < 35.0 and lat > -30.0 and lat < 28.0:
		return true
	if lon > 40.0 and lon < 130.0 and lat > 30.0 and lat < 65.0:
		return true
	return lon > 118.0 and lon < 148.0 and lat > -36.0 and lat < -18.0


static func _puffs() -> ArrayMesh:
	if _clouds != null:
		return _clouds
	var k := ArenaBuilder.prop_kit(true)
	k.detail = 0.6
	k.outline = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for _i in 22:
		var lat := rng.randf_range(16.0, 70.0) * (1.0 if rng.randf() < 0.5 else -1.0)
		var lon := rng.randf_range(-180.0, 180.0)
		var place := _surface(lat, lon)
		place.origin = place.origin.normalized() * (FULL_RADIUS + rng.randf_range(2.6, 4.2))
		k.push(place)
		var size := rng.randf_range(0.6, 1.1)
		for offset: Vector3 in [Vector3(-0.8, 0, 0), Vector3(0.8, 0, 0), Vector3(0, 0.3, 0), Vector3(0.1, 0.0, 0.5)]:
			k.ball(offset * size, Vector3(0.9, 0.55, 0.7) * size, Color("ffffff"), 6, 9)
		k.pop()
	_clouds = k.to_mesh()
	return _clouds
