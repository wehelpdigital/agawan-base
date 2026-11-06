class_name WindArrow
extends Control
## Which way the wind is blowing, as seen from where the camera's looking.

var way := Vector2.RIGHT:
	set(v):
		way = v
		queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.46
	var dir := way.normalized() if way.length() > 0.01 else Vector2.RIGHT
	var side := dir.orthogonal()
	var tip := c + dir * r
	var points := PackedVector2Array([tip, c + side * r * 0.72, c + side * r * 0.3, c - dir * r + side * r * 0.3, c - dir * r - side * r * 0.3, c - side * r * 0.3, c - side * r * 0.72])
	draw_colored_polygon(points, UiKit.BLUE)
	points.append(tip)
	draw_polyline(points, UiKit.INK, 2.0, true)
