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
## Avatars: no hard corners. Boxes become soft and rounded, cones get round tips, and every curve gets
## enough segments that no flat sides show. `detail` lowers the segment counts on slower devices.
var soften := false
var detail := 1.0
## Avatars draw their outline in the shader, so they build no outline shells: overlapping parts would
## cross each other's lines. `outline` then only says "line" (above zero) or "paint" (zero).
var shells := true
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
	if soften and minf(size.x, minf(size.y, size.z)) > 0.035:
		soft_box(center, size * 0.5, color, 0.62, 8, 12)
		return
	color = _marked(color)
	var col := color
	var col_low := (color * Color(low, low, low, 1.0))
	if bevel <= 0.0:
		if outline > 0.0 and shells:
			_box_plain(center, size + Vector3.ONE * outline * 2.0, ink, ink, true)
		_box_plain(center, size, col, col_low, false)
	else:
		if outline > 0.0 and shells:
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
	var tiny := false
	if soften:
		rings = maxi(int(maxi(rings, 8) * detail), 6)
		segs = maxi(int(maxi(segs, 14) * detail), 10)
		tiny = maxf(r.x, maxf(r.y, r.z)) < 0.05  # Too small for its outline to do anything but darken it.
	color = _marked(color)
	if outline > 0.0 and not tiny and shells:
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


## A soft, plush box: flat-ish faces melting into round edges. `half` is half its size on each axis;
## a smaller `e` is boxier, 1.0 would be a ball.
func soft_box(center: Vector3, half: Vector3, color: Color, e := 0.42, rings := 10, segs := 16) -> void:
	color = _marked(color)
	if outline > 0.0 and shells:
		_soft_box(center, half + Vector3.ONE * outline, ink, e, rings, segs, true, false)
	_soft_box(center, half, color, e, rings, segs, false, true)


func _soft_box(center: Vector3, half: Vector3, col: Color, e: float, rings: int, segs: int, flip: bool, shaded: bool) -> void:
	var low := col * Color(0.86, 0.86, 0.86, 1.0) if shaded else col
	var pow_of := func(v: float, k: float) -> float:
		return signf(v) * pow(absf(v), k)
	var pts: Array[PackedVector3Array] = []
	var ns: Array[PackedVector3Array] = []
	for i in rings + 1:
		var phi := PI * float(i) / rings
		var row_p := PackedVector3Array()
		var row_n := PackedVector3Array()
		for j in segs + 1:
			var theta := TAU * float(j) / segs
			var sp: float = pow_of.call(sin(phi), e)
			var cp: float = pow_of.call(cos(phi), e)
			var ct: float = pow_of.call(cos(theta), e)
			var st: float = pow_of.call(sin(theta), e)
			row_p.append(Vector3(sp * ct, cp, sp * st))
			var sp2: float = pow_of.call(sin(phi), 2.0 - e)
			var cp2: float = pow_of.call(cos(phi), 2.0 - e)
			var ct2: float = pow_of.call(cos(theta), 2.0 - e)
			var st2: float = pow_of.call(sin(theta), 2.0 - e)
			row_n.append(Vector3(sp2 * ct2 / half.x, cp2 / half.y, sp2 * st2 / half.z).normalized())
		pts.append(row_p)
		ns.append(row_n)
	for i in rings:
		for j in segs:
			var u1 := pts[i][j]
			var u2 := pts[i][j + 1]
			var u3 := pts[i + 1][j + 1]
			var u4 := pts[i + 1][j]
			var c1 := col.lerp(low, 0.5 - u1.y * 0.5)
			var c2 := col.lerp(low, 0.5 - u2.y * 0.5)
			var c3 := col.lerp(low, 0.5 - u3.y * 0.5)
			var c4 := col.lerp(low, 0.5 - u4.y * 0.5)
			_tri(center + u1 * half, center + u2 * half, center + u3 * half, ns[i][j], ns[i][j + 1], ns[i + 1][j + 1], c1, c2, c3, flip)
			_tri(center + u1 * half, center + u3 * half, center + u4 * half, ns[i][j], ns[i + 1][j + 1], ns[i + 1][j], c1, c3, c4, flip)


## A cylinder or cone from `at` going up `height`; r0 at the bottom, r1 at the top.
func cyl(at: Vector3, height: float, r0: float, r1: float, color: Color, segs := 10, smooth := true) -> void:
	if soften:
		segs = maxi(int(maxi(segs, 14) * detail), 7)
		smooth = true
		if r1 <= 0.001 and r0 > 0.0:  # A cone gets a round tip, sunk in so no flat cap shows.
			r1 = maxf(r0 * 0.34, 0.016)
			height -= r1 * 0.5
			var tip := at + Vector3(0, height, 0)
			if outline > 0.0 and shells:
				_ball(tip, Vector3.ONE * (r1 * 1.02 + outline), ink, 6, 10, true, false)
			_ball(tip, Vector3.ONE * r1 * 1.02, _marked(color), 6, 10, false, true)
	color = _marked(color)
	if outline > 0.0 and shells:
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
	if soften:
		segs = maxi(int(maxi(segs, 20) * detail), 10)
		sides = maxi(int(maxi(sides, 8) * detail), 5)
	color = _marked(color)
	if outline > 0.0 and shells:
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


## Vertex alpha tells the avatar shader whether this shape gets an edge line.
func _marked(color: Color) -> Color:
	if soften:
		color.a = 1.0 if outline > 0.0 else 0.0
	return color


## A flat shape from a closed outline, counter-clockwise as seen from its front. Mouths, tongues.
func fan(points: PackedVector3Array, color: Color, n := Vector3.BACK) -> void:
	color.a = 0.0
	var center := Vector3.ZERO
	for point in points:
		center += point
	center /= float(points.size())
	for i in points.size():
		_tri(center, points[i], points[(i + 1) % points.size()], n, n, n, color, color, color, false)


## A flat ribbon along a path, facing +Z and tapering at both ends. Brows, lashes, closed eyes.
func ribbon(path: PackedVector3Array, half_width: float, color: Color) -> void:
	color.a = 0.0
	var count := path.size()
	for i in count - 1:
		var d := (path[i + 1] - path[i])
		var side := Vector3(-d.y, d.x, 0.0).normalized()
		var w0 := half_width * (0.25 + 0.75 * sin(PI * float(i) / (count - 1)))
		var w1 := half_width * (0.25 + 0.75 * sin(PI * float(i + 1) / (count - 1)))
		_quad(path[i] - side * w0, path[i + 1] - side * w1, path[i + 1] + side * w1, path[i] + side * w0, Vector3.BACK, color, color, color, color, false)


## A coloured rectangle standing on the face of something, a hair proud of it (eyes, stripes, signs).
func decal_box(center: Vector3, size: Vector3, color: Color) -> void:
	color.a = 0.0
	_box_plain(center, size, color, color, false)


## Paint on the front (or back) of an ellipsoid, following its curve: pockets, panels, badges. The x and y
## limits are measured from the ellipsoid's centre.
func patch(center: Vector3, r: Vector3, x0: float, x1: float, y0: float, y1: float, color: Color, back := false, lift := 0.006, steps := 6) -> void:
	var side := -1.0 if back else 1.0
	var point := func(x: float, y: float) -> Vector3:
		var q := maxf(1.0 - pow(x / r.x, 2.0) - pow(y / r.y, 2.0), 0.0)
		return center + Vector3(x, y, side * (r.z * sqrt(q) + lift))
	var normal := func(p: Vector3) -> Vector3:
		var d := p - center
		return Vector3(d.x / (r.x * r.x), d.y / (r.y * r.y), d.z / (r.z * r.z)).normalized()
	for i in steps:
		for j in steps:
			var xa := lerpf(x0, x1, float(i) / steps)
			var xb := lerpf(x0, x1, float(i + 1) / steps)
			var ya := lerpf(y0, y1, float(j) / steps)
			var yb := lerpf(y0, y1, float(j + 1) / steps)
			var a: Vector3 = point.call(xa, ya)
			var b: Vector3 = point.call(xb, ya)
			var c: Vector3 = point.call(xb, yb)
			var d: Vector3 = point.call(xa, yb)
			if back:
				_tri(b, a, d, normal.call(b), normal.call(a), normal.call(d), color, color, color, false)
				_tri(b, d, c, normal.call(b), normal.call(d), normal.call(c), color, color, color, false)
			else:
				_tri(a, b, c, normal.call(a), normal.call(b), normal.call(c), color, color, color, false)
				_tri(a, c, d, normal.call(a), normal.call(c), normal.call(d), color, color, color, false)


## A stripe all the way round an ellipsoid, between two heights measured from its centre.
func band(center: Vector3, r: Vector3, y0: float, y1: float, color: Color, lift := 0.006, segs := 24) -> void:
	segs = maxi(int(segs * detail), 12)
	var rings := 3
	for i in rings:
		var ya := lerpf(y1, y0, float(i) / rings)
		var yb := lerpf(y1, y0, float(i + 1) / rings)
		var ka := sqrt(maxf(1.0 - pow(ya / r.y, 2.0), 0.0))
		var kb := sqrt(maxf(1.0 - pow(yb / r.y, 2.0), 0.0))
		for j in segs:
			var t0 := TAU * float(j) / segs
			var t1 := TAU * float(j + 1) / segs
			var u1 := Vector3(cos(t0) * ka, ya / r.y, sin(t0) * ka)
			var u2 := Vector3(cos(t1) * ka, ya / r.y, sin(t1) * ka)
			var u3 := Vector3(cos(t1) * kb, yb / r.y, sin(t1) * kb)
			var u4 := Vector3(cos(t0) * kb, yb / r.y, sin(t0) * kb)
			var p1 := center + u1 * r + u1.normalized() * lift
			var p2 := center + u2 * r + u2.normalized() * lift
			var p3 := center + u3 * r + u3.normalized() * lift
			var p4 := center + u4 * r + u4.normalized() * lift
			_tri(p1, p2, p3, u1, u2, u3, color, color, color, false)
			_tri(p1, p3, p4, u1, u3, u4, color, color, color, false)


## A round patch of paint on the front of an ellipsoid, with a smooth edge: bellies, faces, badges. It
## follows the curve, so it never shows the jagged line two intersecting shapes do.
func round_patch(center: Vector3, r: Vector3, cx: float, cy: float, px: float, py: float, color: Color, lift := 0.006, segs := 28) -> void:
	var point := func(x: float, y: float) -> Vector3:
		var q := maxf(1.0 - pow(x / r.x, 2.0) - pow(y / r.y, 2.0), 0.0)
		return center + Vector3(x, y, r.z * sqrt(q) + lift)
	var normal := func(p: Vector3) -> Vector3:
		var d := p - center
		return Vector3(d.x / (r.x * r.x), d.y / (r.y * r.y), d.z / (r.z * r.z)).normalized()
	var rings := 4
	for i in rings:
		var ka := float(i) / rings
		var kb := float(i + 1) / rings
		for j in segs:
			var a0 := TAU * float(j) / segs
			var a1 := TAU * float(j + 1) / segs
			var p1: Vector3 = point.call(cx + cos(a0) * px * ka, cy + sin(a0) * py * ka)
			var p2: Vector3 = point.call(cx + cos(a0) * px * kb, cy + sin(a0) * py * kb)
			var p3: Vector3 = point.call(cx + cos(a1) * px * kb, cy + sin(a1) * py * kb)
			var p4: Vector3 = point.call(cx + cos(a1) * px * ka, cy + sin(a1) * py * ka)
			_tri(p1, p2, p3, normal.call(p1), normal.call(p2), normal.call(p3), color, color, color, false)
			if i > 0:
				_tri(p1, p3, p4, normal.call(p1), normal.call(p3), normal.call(p4), color, color, color, false)


## A round dot sitting on the surface of an ellipsoid.
func spot(center: Vector3, r: Vector3, x: float, y: float, size: float, color: Color, back := false) -> void:
	var saved := outline
	outline = 0.0
	var q := maxf(1.0 - pow(x / r.x, 2.0) - pow(y / r.y, 2.0), 0.0)
	var z := r.z * sqrt(q)
	ball(center + Vector3(x, y, -z if back else z), Vector3(size, size, 0.012), color, 5, 9)
	outline = saved
