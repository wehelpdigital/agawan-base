class_name MeshKit
extends RefCounted
## Builds chunky low-poly meshes from code: boxes, balls, cylinders, cones and rings with vertex colours,
## all merged into one mesh, so a whole arena or character is a single draw call.
##
## Outlines are geometry too: every shape also adds a slightly bigger inside-out copy in ink colour,
## which shows only around the silhouette. That costs a few triangles and no extra draw call, and works
## the same on every device.
##


const INK := Color("24135f")

var verts := PackedVector3Array()
var norms := PackedVector3Array()
var cols := PackedColorArray()
var outline := 0.035  ## Outline thickness in metres; 0 turns outlines off.
var ink := INK
var xform := Transform3D.IDENTITY
var _basis_n := Basis.IDENTITY
var _flip_bevel := false
var _stack: Array[Transform3D] = []


func push(t: Transform3D) -> void:
	_stack.append(xform)
	set_xform(xform * t)


func pop() -> void:
	set_xform(_stack.pop_back())


func set_xform(t: Transform3D) -> void:
	xform = t
	_basis_n = t.basis.inverse().transposed()


func is_empty() -> bool:
	return verts.is_empty()


func to_mesh(mesh: ArrayMesh = null) -> ArrayMesh:
	var out := mesh if mesh else ArrayMesh.new()
	if verts.is_empty():
		return out
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


## Corners counter-clockwise seen from outside.
func _tri(a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, ca: Color, cb: Color, cc: Color, flip: bool) -> void:
	var pa := xform * a
	var pb := xform * b
	var pc := xform * c
	if flip:
		verts.append(pa)
		verts.append(pb)
		verts.append(pc)
		norms.append((_basis_n * na).normalized())
		norms.append((_basis_n * nb).normalized())
		norms.append((_basis_n * nc).normalized())
		cols.append(ca)
		cols.append(cb)
		cols.append(cc)
	else:  # Godot's front faces wind clockwise.
		verts.append(pa)
		verts.append(pc)
		verts.append(pb)
		norms.append((_basis_n * na).normalized())
		norms.append((_basis_n * nc).normalized())
		norms.append((_basis_n * nb).normalized())
		cols.append(ca)
		cols.append(cc)
		cols.append(cb)


func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, ca: Color, cb: Color, cc: Color, cd: Color, flip: bool) -> void:
	_tri(a, b, c, n, n, n, ca, cb, cc, flip)
	_tri(a, c, d, n, n, n, ca, cc, cd, flip)


## A flat one-sided quad (no outline), corners counter-clockwise seen from its front.
func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	var n := (b - a).cross(d - a).normalized()
	var col := color
	_quad(a, b, c, d, n, col, col, col, col, false)


## A flat quad lying on the ground at height y.
func ground(rect: Rect2, y: float, color: Color, color2: Variant = null) -> void:
	var c1 := color
	var c2: Color = (color2 as Color) if color2 != null else c1
	var a := Vector3(rect.position.x, y, rect.position.y)
	var b := Vector3(rect.position.x, y, rect.end.y)
	var c := Vector3(rect.end.x, y, rect.end.y)
	var d := Vector3(rect.end.x, y, rect.position.y)
	_quad(a, b, c, d, Vector3.UP, c1, c2, c2, c1, false)


## A box. `bevel` cuts its edges for a chunky, catch-the-light look; `low` darkens the bottom a little.
func box(center: Vector3, size: Vector3, color: Color, bevel := 0.0, low := 0.86) -> void:
	var col := color
	var col_low := (color * Color(low, low, low, 1.0))
	if bevel <= 0.0:
		if outline > 0.0:
			_box_plain(center, size + Vector3.ONE * outline * 2.0, ink, ink, true)
		_box_plain(center, size, col, col_low, false)
	else:
		if outline > 0.0:
			_flip_bevel = true
			_box_bevel(center, size + Vector3.ONE * outline * 2.0, bevel + outline * 0.4, ink, ink)
			_flip_bevel = false
		_box_bevel(center, size, bevel, col, col_low)


func _box_plain(center: Vector3, size: Vector3, col: Color, col_low: Color, flip: bool) -> void:
	var h := size * 0.5
	var c := center
	var p := [
		c + Vector3(-h.x, -h.y, -h.z), c + Vector3(h.x, -h.y, -h.z), c + Vector3(h.x, h.y, -h.z), c + Vector3(-h.x, h.y, -h.z),
		c + Vector3(-h.x, -h.y, h.z), c + Vector3(h.x, -h.y, h.z), c + Vector3(h.x, h.y, h.z), c + Vector3(-h.x, h.y, h.z)]
	_quad(p[4], p[5], p[6], p[7], Vector3.BACK, col_low, col_low, col, col, flip)
	_quad(p[1], p[0], p[3], p[2], Vector3.FORWARD, col_low, col_low, col, col, flip)
	_quad(p[5], p[1], p[2], p[6], Vector3.RIGHT, col_low, col_low, col, col, flip)
	_quad(p[0], p[4], p[7], p[3], Vector3.LEFT, col_low, col_low, col, col, flip)
	_quad(p[7], p[6], p[2], p[3], Vector3.UP, col, col, col, col, flip)
	_quad(p[0], p[1], p[5], p[4], Vector3.DOWN, col_low, col_low, col_low, col_low, flip)


func _box_bevel(center: Vector3, size: Vector3, b: float, col: Color, col_low: Color) -> void:
	var h := size * 0.5
	b = minf(b, minf(h.x, minf(h.y, h.z)) * 0.9)
	# Corner of the box with signs, moved in by b along the two other axes of a face.
	var pt := func(sx: float, sy: float, sz: float, ax: int) -> Vector3:
		var v := Vector3(sx * h.x, sy * h.y, sz * h.z)
		if ax != 0:
			v.x -= sx * b
		if ax != 1:
			v.y -= sy * b
		if ax != 2:
			v.z -= sz * b
		return center + v
	var shade := func(p: Vector3) -> Color:
		return col if p.y > center.y else col_low
	# The six faces.
	for sign_v: float in [-1.0, 1.0]:
		_face(pt.call(-1.0, -1.0, sign_v, 2), pt.call(1.0, -1.0, sign_v, 2), pt.call(1.0, 1.0, sign_v, 2), pt.call(-1.0, 1.0, sign_v, 2), Vector3(0, 0, sign_v), shade, sign_v < 0.0)
		_face(pt.call(sign_v, -1.0, 1.0, 0), pt.call(sign_v, -1.0, -1.0, 0), pt.call(sign_v, 1.0, -1.0, 0), pt.call(sign_v, 1.0, 1.0, 0), Vector3(sign_v, 0, 0), shade, sign_v < 0.0)
		_face(pt.call(-1.0, sign_v, 1.0, 1), pt.call(1.0, sign_v, 1.0, 1), pt.call(1.0, sign_v, -1.0, 1), pt.call(-1.0, sign_v, -1.0, 1), Vector3(0, sign_v, 0), shade, sign_v < 0.0)
	# The twelve bevelled edges.
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:  # Along z.
			var a: Vector3 = pt.call(sx, sy, 1.0, 0)
			var c: Vector3 = pt.call(sx, sy, -1.0, 0)
			var e: Vector3 = pt.call(sx, sy, 1.0, 1)
			var g: Vector3 = pt.call(sx, sy, -1.0, 1)
			_edge(a, c, g, e, Vector3(sx, sy, 0).normalized(), shade)
		for sz: float in [-1.0, 1.0]:  # Along y.
			var a: Vector3 = pt.call(sx, 1.0, sz, 0)
			var c: Vector3 = pt.call(sx, -1.0, sz, 0)
			var e: Vector3 = pt.call(sx, 1.0, sz, 2)
			var g: Vector3 = pt.call(sx, -1.0, sz, 2)
			_edge(a, c, g, e, Vector3(sx, 0, sz).normalized(), shade)
	for sy: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:  # Along x.
			var a: Vector3 = pt.call(1.0, sy, sz, 1)
			var c: Vector3 = pt.call(-1.0, sy, sz, 1)
			var e: Vector3 = pt.call(1.0, sy, sz, 2)
			var g: Vector3 = pt.call(-1.0, sy, sz, 2)
			_edge(a, c, g, e, Vector3(0, sy, sz).normalized(), shade)
	# The eight corner triangles.
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				var a: Vector3 = pt.call(sx, sy, sz, 0)
				var c: Vector3 = pt.call(sx, sy, sz, 1)
				var d: Vector3 = pt.call(sx, sy, sz, 2)
				_oriented_tri(a, c, d, Vector3(sx, sy, sz).normalized(), shade)


func _face(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, shade: Callable, reverse: bool) -> void:
	if reverse:
		_quad(d, c, b, a, n, shade.call(d), shade.call(c), shade.call(b), shade.call(a), _flip_bevel)
	else:
		_quad(a, b, c, d, n, shade.call(a), shade.call(b), shade.call(c), shade.call(d), _flip_bevel)


func _edge(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, shade: Callable) -> void:
	_oriented_tri(a, b, c, n, shade)
	_oriented_tri(a, c, d, n, shade)


## Winds a triangle so it faces along n, whatever order the corners came in.
func _oriented_tri(a: Vector3, b: Vector3, c: Vector3, n: Vector3, shade: Callable) -> void:
	if (b - a).cross(c - a).dot(n) < 0.0:
		var swap := b
		b = c
		c = swap
	_tri(a, b, c, n, n, n, shade.call(a), shade.call(b), shade.call(c), _flip_bevel)


## An ellipsoid with smooth shading. `r` is the radius on each axis.
func ball(center: Vector3, r: Vector3, color: Color, rings := 9, segs := 14) -> void:
	if outline > 0.0:
		_ball(center, r + Vector3.ONE * outline, ink, rings, segs, true, false)
	_ball(center, r, color, rings, segs, false, true)


func _ball(center: Vector3, r: Vector3, col: Color, rings: int, segs: int, flip: bool, shaded: bool) -> void:
	var low := col * Color(0.86, 0.86, 0.86, 1.0) if shaded else col
	var rows: Array[PackedVector3Array] = []
	for i in rings + 1:
		var phi := PI * float(i) / rings
		var row := PackedVector3Array()
		for j in segs + 1:
			var theta := TAU * float(j) / segs
			row.append(Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta)))
		rows.append(row)
	var inv := Vector3(1.0 / maxf(r.x, 0.001), 1.0 / maxf(r.y, 0.001), 1.0 / maxf(r.z, 0.001))
	for i in rings:
		for j in segs:
			var u1 := rows[i][j]
			var u2 := rows[i][j + 1]
			var u3 := rows[i + 1][j + 1]
			var u4 := rows[i + 1][j]
			var p1 := center + u1 * r
			var p2 := center + u2 * r
			var p3 := center + u3 * r
			var p4 := center + u4 * r
			var n1 := (u1 * inv).normalized()
			var n2 := (u2 * inv).normalized()
			var n3 := (u3 * inv).normalized()
			var n4 := (u4 * inv).normalized()
			var c1 := col.lerp(low, 1.0 - (u1.y * 0.5 + 0.5))
			var c2 := col.lerp(low, 1.0 - (u2.y * 0.5 + 0.5))
			var c3 := col.lerp(low, 1.0 - (u3.y * 0.5 + 0.5))
			var c4 := col.lerp(low, 1.0 - (u4.y * 0.5 + 0.5))
			_tri(p1, p2, p3, n1, n2, n3, c1, c2, c3, flip)
			_tri(p1, p3, p4, n1, n3, n4, c1, c3, c4, flip)


## A cylinder or cone from `at` going up `height`; r0 at the bottom, r1 at the top.
func cyl(at: Vector3, height: float, r0: float, r1: float, color: Color, segs := 10, smooth := true) -> void:
	if outline > 0.0:
		_cyl(at - Vector3(0, outline, 0), height + outline * 2.0, r0 + outline, r1 + outline if r1 > 0.0 else outline * 0.5, ink, segs, true, true, false)
	_cyl(at, height, r0, r1, color, segs, false, smooth, true)


func _cyl(at: Vector3, height: float, r0: float, r1: float, col: Color, segs: int, flip: bool, smooth: bool, shaded: bool) -> void:
	var low := col * Color(0.82, 0.82, 0.82, 1.0) if shaded else col
	var top := at + Vector3(0, height, 0)
	var slope := (r0 - r1) / maxf(height, 0.001)
	for j in segs:
		var a0 := TAU * float(j) / segs
		var a1 := TAU * float(j + 1) / segs
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var b0 := at + d0 * r0
		var b1 := at + d1 * r0
		var t0 := top + d0 * r1
		var t1 := top + d1 * r1
		var n0 := (d0 + Vector3(0, slope, 0)).normalized()
		var n1 := (d1 + Vector3(0, slope, 0)).normalized()
		if not smooth:
			var mid := (n0 + n1).normalized()
			n0 = mid
			n1 = mid
		# Counter-clockwise from outside: down-a, up-a... seen from outside, angle increases to the left.
		_tri(b1, b0, t0, n1, n0, n0, low, low, col, flip)
		_tri(b1, t0, t1, n1, n0, n1, low, col, col, flip)
		if r1 > 0.0:
			_tri(top, t1, t0, Vector3.UP, Vector3.UP, Vector3.UP, col, col, col, flip)
		if r0 > 0.0:
			_tri(at, b0, b1, Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, low, low, low, flip)


func cone(at: Vector3, height: float, r: float, color: Color, segs := 10) -> void:
	cyl(at, height, r, 0.0, color, segs)


## A ring lying flat: major radius R, tube radius r.
func torus(center: Vector3, big: float, r: float, color: Color, segs := 14, sides := 6) -> void:
	if outline > 0.0:
		_torus(center, big, r + outline, ink, segs, sides, true)
	_torus(center, big, r, color, segs, sides, false)


func _torus(center: Vector3, big: float, r: float, col: Color, segs: int, sides: int, flip: bool) -> void:
	for j in segs:
		var a0 := TAU * float(j) / segs
		var a1 := TAU * float(j + 1) / segs
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		for k in sides:
			var b0 := TAU * float(k) / sides
			var b1 := TAU * float(k + 1) / sides
			var n00 := d0 * cos(b0) + Vector3.UP * sin(b0)
			var n01 := d0 * cos(b1) + Vector3.UP * sin(b1)
			var n10 := d1 * cos(b0) + Vector3.UP * sin(b0)
			var n11 := d1 * cos(b1) + Vector3.UP * sin(b1)
			var p00 := center + d0 * big + n00 * r
			var p01 := center + d0 * big + n01 * r
			var p10 := center + d1 * big + n10 * r
			var p11 := center + d1 * big + n11 * r
			_tri(p10, p00, p01, n10, n00, n01, col, col, col, flip)
			_tri(p10, p01, p11, n10, n01, n11, col, col, col, flip)


## A thin flat triangle standing up, both sides visible: pennants, leaves, flames, fins.
func blade(a: Vector3, b: Vector3, c: Vector3, color: Color, sway := 0.0) -> void:
	var col := color
	col.a = 1.0
	var n := (b - a).cross(c - a).normalized()
	var tip := col
	tip.a = sway
	var root := col
	root.a = 0.0
	_tri(a, b, c, n, n, n, root, root, tip, false)
	_tri(a, c, b, -n, -n, -n, root, tip, root, false)


## A coloured rectangle standing on the face of something, a hair proud of it (eyes, stripes, signs).
func decal_box(center: Vector3, size: Vector3, color: Color) -> void:
	var saved := outline
	outline = 0.0
	box(center, size, color, 0.0, 1.0)
	outline = saved
