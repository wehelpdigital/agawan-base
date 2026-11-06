class_name FaceParts
extends RefCounted
## More faces: the second half of what Avatar3D can draw for an eye, a mouth or a comic mark. Faces.PARTS names them.

const DARK := Color("6a2038")
const TEAR := Color("7fdcff")


## An eye. `at` is where it sits and `s` is which side of the face it's on.
static func eye(a: Avatar3D, k: MeshKit, info: Dictionary, kind: String, at: Vector3, s: float) -> void:
	var size: float = info["size"]
	var ink: Color = info.get("ink", Color("1a1030"))
	var flat := at.z + size * 0.22 + 0.006
	match kind:
		"sparkly":  # Full of wonder, and lights.
			k.ball(at, Vector3(size * 0.88, size * 1.12, size * 0.4), ink, 10, 14)
			k.ball(at + Vector3(-size * 0.24, size * 0.44, size * 0.36), Vector3(size * 0.3, size * 0.32, size * 0.08), Color.WHITE, 5, 8)
			k.ball(at + Vector3(size * 0.28, -size * 0.3, size * 0.36), Vector3(size * 0.18, size * 0.2, size * 0.06), Color.WHITE, 4, 7)
			k.fan(_star_ring(Vector3(at.x + size * 0.18, at.y + size * 0.3, flat + 0.008), size * 0.26, size * 0.05, 4), Color.WHITE)
			k.fan(_star_ring(Vector3(at.x - size * 0.26, at.y - size * 0.34, flat + 0.008), size * 0.2, size * 0.04, 4), Color("ffe88a"))
		"evil":  # A sliced-off eye with a tiny glowing dot.
			var lid := PackedVector3Array()
			for i in 13:
				var t := PI + PI * i / 12.0
				lid.append(Vector3(at.x + cos(t) * size * 0.82, at.y + sin(t) * size * 0.88 + s * (cos(t)) * size * 0.14, flat))
			k.fan(lid, ink)
			k.ball(Vector3(at.x, at.y - size * 0.34, flat + 0.006), Vector3(size * 0.2, size * 0.2, size * 0.05), Color("ff3f3f"), 4, 7)
			a._line(k, Vector3(at.x + s * size * 1.0, at.y + size * 0.42, flat + 0.004), Vector3(at.x - s * size * 1.0, at.y - size * 0.12, flat + 0.004), size * 0.17, ink)
		"roll":  # Looking at the ceiling for help.
			a._white_eye(k, at, size * 0.82, size * 1.0, size * 0.36, ink)
			k.ball(at + Vector3(0, size * 0.56, size * 0.34), Vector3(size * 0.32, size * 0.3, size * 0.1), ink, 6, 9)
		"inward":  # Both eyes on your own nose.
			a._white_eye(k, at, size * 0.82, size * 0.98, size * 0.36, ink)
			k.ball(at + Vector3(-s * size * 0.42, -size * 0.06, size * 0.34), Vector3(size * 0.32, size * 0.4, size * 0.1), ink, 6, 9)
		"up_look":  # Having an idea.
			k.ball(at + Vector3(0, size * 0.08, 0), Vector3(size * 0.72, size * 0.98, size * 0.4), ink, 10, 14)
			k.ball(at + Vector3(size * 0.16, size * 0.56, size * 0.36), Vector3(size * 0.26, size * 0.26, size * 0.08), Color.WHITE, 5, 8)
		"low_look":
			a._white_eye(k, at, size * 0.82, size * 0.98, size * 0.36, ink)
			k.ball(at + Vector3(size * 0.16 * s, -size * 0.52, size * 0.34), Vector3(size * 0.3, size * 0.32, size * 0.1), ink, 6, 9)
		"cool":  # Painted-on shades.
			var pts := PackedVector3Array()
			for i in 16:
				var t := TAU * i / 16.0
				pts.append(Vector3(at.x + cos(t) * size * 1.02, at.y + (sin(t) * size * 0.62 if sin(t) > 0.0 else sin(t) * size * 0.78), flat))
			k.fan(pts, Color("141026"))
			a._line(k, Vector3(at.x - size * 0.5, at.y + size * 0.3, flat + 0.006), Vector3(at.x - size * 0.1, at.y + size * 0.44, flat + 0.006), size * 0.08, Color("9fe8ff"))
			a._line(k, Vector3(at.x - s * size * 1.0, at.y + size * 0.3, flat - 0.002), Vector3(at.x - s * size * 1.5, at.y + size * 0.34, flat - 0.002), size * 0.09, Color("141026"))
		"pixel":  # Very retro.
			for spot: Vector2 in [Vector2(-0.46, 0.46), Vector2(0.0, 0.46), Vector2(-0.46, 0.0), Vector2(0.0, 0.0), Vector2(0.46, 0.0), Vector2(0.0, -0.46), Vector2(0.46, -0.46), Vector2(-0.46, -0.46)]:
				_square(k, Vector3(at.x + spot.x * size, at.y + spot.y * size, flat), size * 0.23, ink)
			_square(k, Vector3(at.x - size * 0.46, at.y + size * 0.46, flat + 0.004), size * 0.14, Color.WHITE)
		"hollow":  # o o
			k.ball(at, Vector3(size * 0.9, size * 0.98, size * 0.36), ink, 10, 14)
			k.ball(at + Vector3(0, 0, size * 0.1), Vector3(size * 0.7, size * 0.78, size * 0.32), Color.WHITE, 10, 14)
		"flower":
			for i in 5:
				var t := PI * 0.5 + TAU * i / 5.0
				k.ball(Vector3(at.x + cos(t) * size * 0.56, at.y + sin(t) * size * 0.56, flat), Vector3(size * 0.42, size * 0.42, size * 0.1), Color("ff8fc2"), 5, 9)
			k.ball(Vector3(at.x, at.y, flat + 0.008), Vector3(size * 0.34, size * 0.34, size * 0.1), Color("ffd23f"), 5, 9)
		"target":
			k.ball(at, Vector3(size * 0.98, size * 0.98, size * 0.34), Color("e8282f"), 10, 14)
			k.ball(at + Vector3(0, 0, size * 0.12), Vector3(size * 0.68, size * 0.68, size * 0.28), Color.WHITE, 8, 12)
			k.ball(at + Vector3(0, 0, size * 0.22), Vector3(size * 0.36, size * 0.36, size * 0.22), Color("e8282f"), 6, 10)
		"moon":
			var pts := PackedVector3Array()
			for i in 13:
				var t := PI * 0.32 + PI * 1.36 * i / 12.0
				pts.append(Vector3(at.x + cos(t) * size * 0.98, at.y + sin(t) * size * 0.98, flat))
			for i in range(12, -1, -1):
				var t := PI * 0.32 + PI * 1.36 * i / 12.0
				pts.append(Vector3(at.x + size * 0.34 + cos(t) * size * 0.66, at.y + sin(t) * size * 0.66, flat))
			k.ribbon(_arc_path(at, size * 0.82, PI * 0.36, PI * 1.64, flat), size * 0.26, Color("ffd23f"))
		"sunny":
			for i in 8:
				var t := TAU * i / 8.0
				a._line(k, Vector3(at.x + cos(t) * size * 0.6, at.y + sin(t) * size * 0.6, flat), Vector3(at.x + cos(t) * size * 1.08, at.y + sin(t) * size * 1.08, flat), size * 0.12, Color("ff9d2e"))
			k.ball(at, Vector3(size * 0.62, size * 0.62, size * 0.34), Color("ffc21f"), 8, 12)
		"skull":
			k.ball(at + Vector3(0, size * 0.1, 0), Vector3(size * 0.8, size * 0.72, size * 0.34), Color.WHITE, 8, 12)
			k.ball(Vector3(at.x, at.y - size * 0.46, flat), Vector3(size * 0.44, size * 0.36, size * 0.14), Color.WHITE, 5, 9)
			for side: float in [-1.0, 1.0]:
				k.ball(Vector3(at.x + side * size * 0.3, at.y + size * 0.1, flat + 0.006), Vector3(size * 0.2, size * 0.24, size * 0.06), ink, 4, 8)
			a._line(k, Vector3(at.x, at.y - size * 0.44, flat + 0.006), Vector3(at.x, at.y - size * 0.72, flat + 0.006), size * 0.05, ink)
		"fire":
			k.tube(PackedVector3Array([Vector3(at.x, at.y - size * 0.6, flat - 0.01), Vector3(at.x - size * 0.04, at.y - size * 0.1, flat - 0.01), Vector3(at.x + size * 0.1, at.y + size * 0.42, flat - 0.01), Vector3(at.x + size * 0.32, at.y + size * 1.02, flat - 0.01)]), size * 0.72, Color("ff5a1f"), false, 10, size * 0.03)
			k.tube(PackedVector3Array([Vector3(at.x, at.y - size * 0.46, flat + 0.03), Vector3(at.x + size * 0.04, at.y, flat + 0.03), Vector3(at.x + size * 0.14, at.y + size * 0.42, flat + 0.03)]), size * 0.4, Color("ffd23f"), false, 8, size * 0.02)
		"snowflake":
			for i in 3:
				var t := PI * i / 3.0 + PI * 0.5
				var d := Vector3(cos(t), sin(t), 0) * size
				a._line(k, Vector3(at.x, at.y, flat) - d, Vector3(at.x, at.y, flat) + d, size * 0.13, Color("3a9cff"))
		"broken":
			var heart := PackedVector3Array()
			for i in range(23, -1, -1):
				var t := TAU * i / 24.0
				heart.append(Vector3(at.x + 16.0 * pow(sin(t), 3.0) * size * 0.07, at.y + (13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)) * size * 0.07, flat))
			k.fan(heart, Color("ff3f6a"))
			k.ribbon(PackedVector3Array([Vector3(at.x + size * 0.06, at.y + size * 0.5, flat + 0.006), Vector3(at.x - size * 0.18, at.y + size * 0.18, flat + 0.006), Vector3(at.x + size * 0.14, at.y - size * 0.1, flat + 0.006), Vector3(at.x - size * 0.06, at.y - size * 0.5, flat + 0.006)]), size * 0.08, Color("1a1030"))
		"tee":  # T T
			a._line(k, Vector3(at.x - size * 0.8, at.y + size * 0.44, flat), Vector3(at.x + size * 0.8, at.y + size * 0.44, flat), size * 0.16, ink)
			a._line(k, Vector3(at.x, at.y + size * 0.44, flat), Vector3(at.x, at.y - size * 0.8, flat), size * 0.16, ink)
		"plus":  # + +
			a._line(k, Vector3(at.x - size * 0.72, at.y, flat), Vector3(at.x + size * 0.72, at.y, flat), size * 0.16, ink)
			a._line(k, Vector3(at.x, at.y + size * 0.72, flat), Vector3(at.x, at.y - size * 0.72, flat), size * 0.16, ink)
		"teary":  # About to go.
			k.ball(at, Vector3(size * 0.88, size * 1.12, size * 0.4), ink, 10, 14)
			k.ball(at + Vector3(-size * 0.24, size * 0.4, size * 0.36), Vector3(size * 0.3, size * 0.32, size * 0.08), Color.WHITE, 5, 8)
			k.ball(Vector3(at.x, at.y - size * 0.72, flat + 0.004), Vector3(size * 0.72, size * 0.3, size * 0.08), TEAR, 5, 10)
			k.ball(Vector3(at.x - size * 0.2, at.y - size * 0.68, flat + 0.012), Vector3(size * 0.14, size * 0.08, size * 0.03), Color.WHITE, 3, 6)
		"glasses":  # Round specs, and two very small eyes.
			k.torus(at + Vector3(0, 0, size * 0.3), size * 0.92, size * 0.13, Color("141026"), 18, 5)
			k.ball(at + Vector3(0, 0, size * 0.12), Vector3(size * 0.8, size * 0.8, size * 0.1), Color("eaf6ff"), 6, 12)
			k.ball(at + Vector3(0, 0, size * 0.22), Vector3(size * 0.22, size * 0.26, size * 0.08), ink, 5, 8)
			a._line(k, Vector3(at.x - s * size * 0.9, at.y + size * 0.1, at.z + size * 0.3), Vector3(at.x - s * size * 1.25, at.y + size * 0.06, at.z + size * 0.3), size * 0.08, Color("141026"))
		"slit":  # Cat, or something much worse.
			k.ball(at, Vector3(size * 0.8, size * 0.98, size * 0.36), Color("c9f25a"), 10, 14)
			k.ball(at + Vector3(0, 0, size * 0.24), Vector3(size * 0.16, size * 0.78, size * 0.14), ink, 6, 10)
		"tilde":  # ~ ~
			var pts := PackedVector3Array()
			for i in 11:
				var f := lerpf(-1.0, 1.0, i / 10.0)
				pts.append(Vector3(at.x + f * size * 0.86, at.y + sin(f * 3.4) * size * 0.26, flat))
			k.ribbon(pts, size * 0.12, ink)
		"wink_star":
			a._arc(k, at, size, 0.5, ink)
			k.fan(_star_ring(Vector3(at.x + s * size * 1.0, at.y + size * 0.74, flat + 0.004), size * 0.42, size * 0.16, 5), Color("ffd23f"))


static func _square(k: MeshKit, at: Vector3, half: float, color: Color) -> void:
	k.fan(PackedVector3Array([at + Vector3(half, half, 0), at + Vector3(-half, half, 0), at + Vector3(-half, -half, 0), at + Vector3(half, -half, 0)]), color)


static func _star_ring(at: Vector3, big: float, small: float, points: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in points * 2:
		var t := PI * 0.5 + PI * i / points
		var r := big if i % 2 == 0 else small
		out.append(at + Vector3(cos(t) * r, sin(t) * r, 0))
	return out


static func _arc_path(at: Vector3, r: float, from: float, to: float, z: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in 15:
		var t := lerpf(from, to, i / 14.0)
		out.append(Vector3(at.x + cos(t) * r, at.y + sin(t) * r, z))
	return out


## A mouth.
static func mouth(a: Avatar3D, k: MeshKit, info: Dictionary, kind: String) -> void:
	var y: float = info["mouth_y"]
	var w: float = info["mouth_w"]
	match kind:
		"uh":  # Not impressed. Slanted.
			a._stroke(k, info, PackedVector2Array([Vector2(-w * 0.72, y - w * 0.46), Vector2(0, y - w * 0.32), Vector2(w * 0.72, y - w * 0.18)]), w * 0.14, DARK)
		"zip":  # Not saying a word.
			a._stroke(k, info, PackedVector2Array([Vector2(-w * 1.05, y - w * 0.3), Vector2(0, y - w * 0.3), Vector2(w * 1.05, y - w * 0.3)]), w * 0.16, DARK)
			for i in 7:
				var x := lerpf(-0.85, 0.85, i / 6.0) * w
				a._stroke(k, info, PackedVector2Array([Vector2(x, y - w * 0.14), Vector2(x, y - w * 0.3), Vector2(x, y - w * 0.46)]), w * 0.06, Color("c9b8d8"), 0.016)
			a._paint(k, info, Avatar3D._oval(Vector2(w * 1.14, y - w * 0.42), w * 0.13, w * 0.24, 10), Color("ffd23f"), 0.018)
		"kiss":  # Mwah.
			a._stroke(k, info, PackedVector2Array([Vector2(-w * 0.1, y - w * 0.04), Vector2(w * 0.26, y - w * 0.12), Vector2(w * 0.24, y - w * 0.32), Vector2(w * 0.02, y - w * 0.38)]), w * 0.15, DARK)
			a._stroke(k, info, PackedVector2Array([Vector2(w * 0.02, y - w * 0.38), Vector2(w * 0.3, y - w * 0.46), Vector2(w * 0.26, y - w * 0.66), Vector2(-w * 0.1, y - w * 0.72)]), w * 0.15, DARK)
		"whistle":  # Nothing to see here.
			a._paint(k, info, Avatar3D._oval(Vector2(w * 0.4, y - w * 0.3), w * 0.2, w * 0.22, 12), DARK)
		"drool":
			var line := PackedVector2Array()
			for i in 13:
				var f := lerpf(-1.0, 1.0, i / 12.0)
				line.append(Vector2(f * w * 1.1, y - w * 0.32 * (1.0 - f * f)))
			a._stroke(k, info, line, w * 0.15, DARK)
			a._paint(k, info, Avatar3D._grin_shape(y - w * 0.56, w * 0.14, w * 0.3), TEAR, 0.016)
		"sneeze":  # Ah... ah...
			a._paint(k, info, Avatar3D._oval(Vector2(0, y - w * 0.56), w * 0.86, w * 0.86), Color("6a1f3a"))
			a._paint(k, info, Avatar3D._oval(Vector2(0, y - w * 0.96), w * 0.5, w * 0.34), Color("ff8fa6"), 0.01)
		"fangs":
			a._open_mouth(k, info, y, w * 1.25)
			for s: float in [-1.0, 1.0]:
				var fang := PackedVector2Array([Vector2(s * w * 0.42, y - w * 0.04), Vector2(s * w * 0.76, y - w * 0.02), Vector2(s * w * 0.6, y - w * 0.56)])
				if s > 0.0:
					fang.reverse()
				a._paint(k, info, fang, Color.WHITE, 0.012)
		"sharp":  # A mouth with far too many teeth.
			a._paint(k, info, Avatar3D._grin_shape(y - w * 0.4, w * 1.42, w * 0.56), Color("1a1030"), 0.006)
			var top := PackedVector2Array()
			for i in 15:
				var f := lerpf(-1.0, 1.0, i / 14.0)
				top.append(Vector2(f * w * 1.2, y - w * 0.4 + f * f * w * 0.2 + (w * 0.2 if i % 2 == 0 else -w * 0.08)))
			a._stroke(k, info, top, w * 0.1, Color.WHITE, 0.012)
			var low := PackedVector2Array()
			for i in 13:
				var f := lerpf(-0.9, 0.9, i / 12.0)
				low.append(Vector2(f * w * 1.16, y - w * 0.62 + f * f * w * 0.3 + (w * 0.12 if i % 2 == 1 else -w * 0.1)))
			a._stroke(k, info, low, w * 0.09, Color.WHITE, 0.012)
		"eee":  # Oh no. Oh no, oh no.
			a._paint(k, info, Avatar3D._grin_shape(y - w * 0.42, w * 1.25, w * 0.4), DARK, 0.006)
			a._paint(k, info, Avatar3D._grin_shape(y - w * 0.42, w * 1.12, w * 0.3), Color.WHITE, 0.01)
			for f: float in [-0.6, -0.3, 0.0, 0.3, 0.6]:
				a._stroke(k, info, PackedVector2Array([Vector2(f * w * 1.12, y - w * 0.14), Vector2(f * w * 1.12, y - w * 0.42), Vector2(f * w * 1.12, y - w * 0.7)]), w * 0.05, Color("c9b8d8"), 0.014)
		"pant":  # Huff, huff, tongue out.
			a._open_mouth(k, info, y, w * 1.25)
			a._paint(k, info, Avatar3D._grin_shape(y - w * 0.9, w * 0.42, w * 0.56), Color("ff8fa6"), 0.012)
		"puff":  # Holding it all in.
			a._paint(k, info, Avatar3D._oval(Vector2(0, y - w * 0.3), w * 0.14, w * 0.14, 10), DARK)
			for s: float in [-1.0, 1.0]:
				a._paint(k, info, Avatar3D._oval(Vector2(s * w * 1.28, y - w * 0.22), w * 0.66, w * 0.58), Color("ff9fb8"), 0.004)
		"gum":  # Popping any second now.
			a._stroke(k, info, PackedVector2Array([Vector2(-w * 0.44, y - w * 0.32), Vector2(0, y - w * 0.3), Vector2(w * 0.3, y - w * 0.32)]), w * 0.13, DARK)
			var at := Avatar3D._on_head(info, w * 0.42, y - w * 0.3, 0.05)
			k.ball(at, Vector3(w * 0.72, w * 0.72, w * 0.5), Color("ff8fd0"), 7, 12)
			k.ball(at + Vector3(-w * 0.22, w * 0.28, w * 0.42), Vector3(w * 0.14, w * 0.14, w * 0.05), Color.WHITE, 3, 6)
		"stitch":
			a._stroke(k, info, PackedVector2Array([Vector2(-w * 1.0, y - w * 0.3), Vector2(0, y - w * 0.3), Vector2(w * 1.0, y - w * 0.3)]), w * 0.11, DARK)
			for f: float in [-0.66, -0.22, 0.22, 0.66]:
				a._stroke(k, info, PackedVector2Array([Vector2(f * w - w * 0.12, y - w * 0.08), Vector2(f * w, y - w * 0.3), Vector2(f * w + w * 0.12, y - w * 0.52)]), w * 0.07, DARK, 0.014)
		"one_tooth":
			var line := PackedVector2Array()
			for i in 13:
				var f := lerpf(-1.0, 1.0, i / 12.0)
				line.append(Vector2(f * w * 1.1, y - w * 0.32 * (1.0 - f * f)))
			a._paint(k, info, Avatar3D._grin_shape(y - w * 0.54, w * 0.22, w * 0.26), Color.WHITE, 0.012)
			a._stroke(k, info, line, w * 0.14, DARK, 0.016)
		"tri":  # A big happy triangle.
			a._paint(k, info, PackedVector2Array([Vector2(-w * 1.05, y + w * 0.02), Vector2(0, y - w * 1.14), Vector2(w * 1.05, y + w * 0.02)]), DARK)
			a._paint(k, info, Avatar3D._oval(Vector2(0, y - w * 0.68), w * 0.4, w * 0.24), Color("ff8fa6"), 0.01)
		"heart_m":
			var heart := PackedVector2Array()
			for i in range(23, -1, -1):
				var t := TAU * i / 24.0
				heart.append(Vector2(16.0 * pow(sin(t), 3.0) * w * 0.05, y - w * 0.52 + (13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)) * w * 0.05))
			a._paint(k, info, heart, Color("c9203f"))
		"wobble":  # Bottom lip going.
			var pts := PackedVector2Array()
			for i in 11:
				var f := lerpf(-1.0, 1.0, i / 10.0)
				pts.append(Vector2(f * w * 0.9, y - w * 0.48 + w * 0.3 * (1.0 - f * f) + sin(f * 9.0) * w * 0.08))
			a._stroke(k, info, pts, w * 0.14, DARK)
		"tache":  # A smile and a fine moustache, which you drew yourself.
			a._stroke(k, info, PackedVector2Array([Vector2(-w * 0.5, y - w * 0.44), Vector2(0, y - w * 0.56), Vector2(w * 0.5, y - w * 0.44)]), w * 0.1, DARK)
			for s: float in [-1.0, 1.0]:
				a._stroke(k, info, PackedVector2Array([Vector2(0, y - w * 0.1), Vector2(s * w * 0.56, y - w * 0.22), Vector2(s * w * 1.0, y - w * 0.04), Vector2(s * w * 1.24, y + w * 0.2)]), w * 0.2, Color("2a1c18"), 0.016)


## Comic marks around the face.
static func extra(a: Avatar3D, k: MeshKit, info: Dictionary, kind: String, hide: String) -> void:
	var y: float = info["y"]
	var gap: float = info["gap"]
	var size: float = info["size"]
	match kind:
		"hearts":
			for spot: Vector2 in [Vector2(gap + size * 1.0, y + size * 1.1), Vector2(gap + size * 1.72, y + size * 0.32)]:
				_heart(k, Avatar3D._on_head(info, minf(spot.x, 0.36), spot.y, 0.02), size * 0.03, Color("ff3f6a"))
		"note":
			var at := Avatar3D._on_head(info, gap + size * 0.9, y + size * 1.0, 0.02)
			k.ball(at + Vector3(-size * 0.18, -size * 0.34, 0), Vector3(size * 0.2, size * 0.15, 0.008), Color("3a6aff"), 4, 7)
			a._line(k, at + Vector3(0, -size * 0.3, 0), at + Vector3(0, size * 0.34, 0), size * 0.05, Color("3a6aff"))
			a._line(k, at + Vector3(0, size * 0.34, 0), at + Vector3(size * 0.26, size * 0.2, 0), size * 0.07, Color("3a6aff"))
		"question":
			var at := Avatar3D._on_head(info, gap + size * 0.72, y + size * 1.2, 0.02)
			k.ribbon(_arc_path(at + Vector3(0, size * 0.2, 0), size * 0.26, PI * 1.1, -PI * 0.42, at.z), size * 0.09, Color("3a6aff"))
			a._line(k, at + Vector3(0, -size * 0.04, 0), at + Vector3(0, -size * 0.2, 0), size * 0.09, Color("3a6aff"))
			k.ball(at + Vector3(0, -size * 0.4, 0), Vector3(size * 0.09, size * 0.09, 0.006), Color("3a6aff"), 3, 6)
		"exclaim":
			for offset: float in [0.0, -size * 0.6]:
				var at := Avatar3D._on_head(info, gap + size * 0.86 + offset, y + size * (1.2 + offset * 0.2), 0.02)
				a._line(k, at + Vector3(0, size * 0.42, 0), at + Vector3(0, -size * 0.1, 0), size * 0.1, Color("e8282f"))
				k.ball(at + Vector3(0, -size * 0.32, 0), Vector3(size * 0.1, size * 0.1, 0.006), Color("e8282f"), 3, 6)
		"bulb":
			var at := Avatar3D._on_head(info, gap * 0.4, y + size * 1.7, 0.03)
			k.ball(at, Vector3(size * 0.46, size * 0.46, size * 0.14), Color("ffe05c"), 6, 10)
			a._line(k, at + Vector3(-size * 0.16, -size * 0.5, 0), at + Vector3(size * 0.16, -size * 0.5, 0), size * 0.08, Color("7a7a8c"))
			for i in 5:
				var t := PI * 0.1 + PI * 0.8 * i / 4.0
				a._line(k, at + Vector3(cos(t) * size * 0.62, sin(t) * size * 0.62, 0), at + Vector3(cos(t) * size * 0.9, sin(t) * size * 0.9, 0), size * 0.05, Color("ffb21f"))
		"drop":  # The great big comic sweat drop.
			k.ball(Avatar3D._on_head(info, gap + size * 0.86, y + size * 1.2, 0.02), Vector3(size * 0.42, size * 0.66, 0.018), Color("8fe3ff"), 5, 9)
			k.ball(Avatar3D._on_head(info, gap + size * 0.76, y + size * 1.36, 0.04), Vector3(size * 0.1, size * 0.18, 0.005), Color.WHITE, 3, 5)
		"gloom":  # Lines of doom down the forehead.
			for f: float in [-0.6, -0.2, 0.2, 0.6]:
				var x := f * gap * 1.5
				a._stroke(k, info, PackedVector2Array([Vector2(x, y + size * 2.0), Vector2(x, y + size * 1.55), Vector2(x, y + size * 1.1)]), size * 0.08, Color("6a5ad0"), 0.014)
		"steam":
			for s: float in [-1.0, 1.0]:
				var at := Avatar3D._on_head(info, s * (gap + size * 1.1), y + size * 0.1, 0.03)
				k.ball(at, Vector3(size * 0.36, size * 0.3, 0.02), Color("fbfdff"), 4, 8)
				k.ball(at + Vector3(s * size * 0.44, size * 0.42, 0.01), Vector3(size * 0.5, size * 0.42, 0.02), Color("fbfdff"), 4, 8)
		"flush":
			if hide != "mouth":
				for s: float in [-1.0, 1.0]:
					a._paint(k, info, Avatar3D._oval(Vector2(s * (gap + size * 0.16), y - size * 1.1), size * 1.1, size * 0.56), Color("ff4f6e"), 0.004)
		"sick":  # Going green from the top down.
			a._paint(k, info, Avatar3D._oval(Vector2(0, y + size * 1.25), gap + size * 1.3, size * 0.86, 24), Color("8fd46a"), 0.003)
		"soot":
			for spot: Vector2 in [Vector2(-gap - size * 0.8, y - size * 1.1), Vector2(gap + size * 0.9, y + size * 0.96), Vector2(gap * 0.3, y - size * 1.5), Vector2(-gap * 0.5, y + size * 1.3)]:
				a._paint(k, info, Avatar3D._oval(spot, size * 0.44, size * 0.28, 10), Color("3a3440"), 0.004)
		"frost":
			for spot: Vector2 in [Vector2(-gap - size * 0.9, y + size * 1.1), Vector2(gap + size * 1.0, y - size * 0.9)]:
				a._paint(k, info, Avatar3D._oval(spot, size * 0.76, size * 0.6, 12), Color("c9f1ff"), 0.004)
			var at := Avatar3D._on_head(info, 0.0, y - size * 0.9, 0.02)
			k.push(Transform3D(Basis(Vector3.RIGHT, PI), at))
			k.cone(Vector3.ZERO, size * 0.5, size * 0.1, Color("bff0ff"), 5)
			k.pop()
		"stars":
			for i in 3:
				var t := PI * 0.18 + PI * 0.64 * i / 2.0
				var at := Avatar3D._on_head(info, cos(t) * (gap + size * 1.2), y + size * 1.0 + sin(t) * size * 0.9, 0.02)
				k.fan(_star_ring(at, size * 0.36, size * 0.14, 5), Color("ffc21f"))
		"blush_lines":  # / / /
			if hide != "mouth":
				for s: float in [-1.0, 1.0]:
					for f: float in [-0.5, 0.0, 0.5]:
						var x := s * (gap + size * 0.6) + f * size * 0.64
						var base := y - size * 1.1
						a._stroke(k, info, PackedVector2Array([Vector2(x + size * 0.14, base + size * 0.28), Vector2(x, base), Vector2(x - size * 0.14, base - size * 0.28)]), size * 0.07, Color("ff4f6e"), 0.008)
		"freckles":
			if hide != "mouth":
				for s: float in [-1.0, 1.0]:
					for spot: Vector2 in [Vector2(gap * 0.8, y - size * 1.0), Vector2(gap * 1.15, y - size * 1.25), Vector2(gap * 0.56, y - size * 1.3)]:
						a._paint(k, info, Avatar3D._oval(Vector2(s * spot.x, spot.y), size * 0.1, size * 0.1, 8), Color("9a5a34"), 0.006)
		"plaster":
			var at := Vector2(gap + size * 0.6, y - size * 1.0)
			a._paint(k, info, Avatar3D._oval(at, size * 0.66, size * 0.24, 12), Color("ffe6c2"), 0.008)


static func _heart(k: MeshKit, at: Vector3, step: float, color: Color) -> void:
	var heart := PackedVector3Array()
	for i in range(23, -1, -1):
		var t := TAU * i / 24.0
		heart.append(at + Vector3(16.0 * pow(sin(t), 3.0) * step, (13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)) * step, 0))
	k.fan(heart, color)
