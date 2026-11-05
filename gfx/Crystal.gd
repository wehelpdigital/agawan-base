class_name Crystal
extends RefCounted
## The mystery pickup: a cut gem whose colours keep drifting through the rainbow. What's inside isn't decided until
## someone grabs it. One mesh and one material, shared by every crystal on the field, with its dark outline built in.

const COLOURS := ["ff5a4e", "ffd23f", "35d07f", "3aa6ff", "b768ff", "ffffff"]
const SIDES := 8
const TABLE_R := 0.27
const TABLE_Y := 0.36
const GIRDLE_R := 0.58
const GIRDLE_Y := 0.12
const TIP_Y := -0.62
const OUTLINE_SCALE := 1.1

static var _mesh: ArrayMesh
static var _material: ShaderMaterial


static func mesh() -> ArrayMesh:
	if _mesh == null:
		var kit := MeshKit.new()
		for side in SIDES:
			var a := TAU * side / SIDES
			var b := TAU * (side + 1) / SIDES
			var mid := a + TAU / SIDES * 0.5
			var mid_before := mid - TAU / SIDES
			var table_a := _ring(a, TABLE_R, TABLE_Y)
			var table_b := _ring(b, TABLE_R, TABLE_Y)
			var girdle_m := _ring(mid, GIRDLE_R, GIRDLE_Y)
			var girdle_n := _ring(mid_before + TAU / SIDES * 2.0, GIRDLE_R, GIRDLE_Y)
			var hue := float(side) / SIDES
			_facet(kit, Vector3(0, TABLE_Y, 0), table_a, table_b, hue, 1.0)  # The flat top.
			_facet(kit, table_a, table_b, girdle_m, hue + 0.04, 0.92)  # The sloping crown...
			_facet(kit, table_b, girdle_m, girdle_n, hue + 0.08, 0.84)
			_facet(kit, girdle_m, girdle_n, Vector3(0, TIP_Y, 0), hue + 0.12, 0.74)  # ...and the point below.
		_mesh = kit.to_mesh()
	return _mesh


static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = preload("res://gfx/shaders/crystal.gdshader")
	return _material


static func _ring(angle: float, radius: float, y: float) -> Vector3:
	return Vector3(cos(angle) * radius, y, sin(angle) * radius)


## One flat face, and its outline: the same face a little bigger, inside out and marked (alpha 0) as ink.
static func _facet(kit: MeshKit, a: Vector3, b: Vector3, c: Vector3, hue: float, light: float) -> void:
	var middle := (a + b + c) / 3.0 - Vector3(0, -0.02, 0)
	var n := (b - a).cross(c - a).normalized()
	if n.dot(middle) < 0.0:  # Corners go counter-clockwise, seen from outside.
		var swap := b
		b = c
		c = swap
		n = -n
	var col := Color(fmod(hue, 1.0), light, 0.0, 1.0)
	kit._tri(a, b, c, n, n, n, col, col, col, false)
	var ink := Color(0, 0, 0, 0)
	var center := Vector3(0, -0.04, 0)
	kit._tri(center + (a - center) * OUTLINE_SCALE, center + (b - center) * OUTLINE_SCALE, center + (c - center) * OUTLINE_SCALE, n, n, n, ink, ink, ink, true)
