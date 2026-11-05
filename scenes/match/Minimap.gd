class_name Minimap
extends Control
## The whole field at a glance: walls, water, both bases and jails, players and powerups. Hidden enemies
## don't appear, so it's no way around the tall grass.

var _sim: Sim
var _me := 0
var _texture: ImageTexture
var _rotated := false
var _my_team := 0


func setup(sim: Sim, local_id: int) -> void:
	_sim = sim
	_me = local_id
	var me := sim.player_by_id(local_id)
	_my_team = me.team if me else 0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var image := Image.create(sim.w, sim.h, false, Image.FORMAT_RGBA8)
	var theme: Dictionary = Maps.THEMES[Maps.by_id(sim.map_id)["theme"]]
	var floor_color := Color(theme["floor"][0])
	for y in sim.h:
		for x in sim.w:
			var c := floor_color
			match sim.tiles[y * sim.w + x]:
				Maps.SOLID: c = Color("24135f")
				Maps.PIT: c = Color(theme["pit_c"]).darkened(0.1)
				Maps.GRASS: c = Color(theme["grass"]).darkened(0.1)
				Maps.ICE: c = Color("d8f6ff")
				Maps.MUD: c = Color("8a6240")
				Maps.BOUNCE: c = Color("ff4f8b")
				Maps.TELE: c = Color("b768ff")
			image.set_pixel(x, y, c)
	_texture = ImageTexture.create_from_image(image)


## On an upright screen the map turns to match the camera: enemy base at the top.
func set_rotated(on: bool) -> void:
	_rotated = on
	queue_redraw()


func _to_map(at: Vector2) -> Vector2:
	var arena := _sim.arena_size()
	var u := at.x / arena.x
	var v := at.y / arena.y
	if _rotated:
		# Enemy base up: team 0 runs bottom to top, team 1 sees it turned round.
		if _my_team == 0:
			return Vector2(v, 1.0 - u) * size
		return Vector2(1.0 - v, u) * size
	if _my_team == 0:
		return Vector2(u, v) * size
	return Vector2(1.0 - u, 1.0 - v) * size


func _draw() -> void:
	if _sim == null:
		return
	var rect := Rect2(Vector2.ZERO, size)
	draw_style_box(UiKit.style(UiKit.INK, 10), rect.grow(3.0))
	if _rotated:
		var side := Vector2(size.y, size.x)
		var xform := Transform2D()
		if _my_team == 0:
			xform = Transform2D(-PI * 0.5, Vector2(0, size.y))
		else:
			xform = Transform2D(PI * 0.5, Vector2(size.x, 0))
		draw_set_transform_matrix(xform)
		draw_texture_rect(_texture, Rect2(Vector2.ZERO, side), false, Color(1, 1, 1, 0.92))
		draw_set_transform_matrix(Transform2D.IDENTITY)
	elif _my_team == 1:
		draw_set_transform_matrix(Transform2D(PI, size))
		draw_texture_rect(_texture, rect, false, Color(1, 1, 1, 0.92))
		draw_set_transform_matrix(Transform2D.IDENTITY)
	else:
		draw_texture_rect(_texture, rect, false, Color(1, 1, 1, 0.92))
	var scale_k: float = minf(size.x, size.y) / 100.0
	for team in 2:
		var color := ArenaBuilder.team_color(team)
		draw_circle(_to_map(_sim.base[team]), 8.0 * scale_k + 2.0, UiKit.INK)
		draw_circle(_to_map(_sim.base[team]), 8.0 * scale_k, color)
		draw_arc(_to_map(_sim.jail[team]), 5.0 * scale_k + 1.0, 0.0, TAU, 14, color, 2.0, true)
	for item: Dictionary in _sim.pickups:
		var at_gem := _to_map(item["pos"])
		var gem_r := 3.0 * scale_k
		draw_colored_polygon(PackedVector2Array([at_gem + Vector2(0, -gem_r), at_gem + Vector2(gem_r, 0), at_gem + Vector2(0, gem_r), at_gem + Vector2(-gem_r, 0)]), Color("fff8c4"))
	for p: Sim.Player in _sim.players:
		if p.state != Sim.State.PLAY or _sim.is_hidden_from(p, _my_team):
			continue
		var at := _to_map(p.pos)
		var r := 3.6 * scale_k + 1.0
		draw_circle(at, r + 1.6, UiKit.INK)
		draw_circle(at, r, ArenaBuilder.team_color(p.team))
		if p.id == _me:
			draw_arc(at, r + 3.0, 0.0, TAU, 14, Color.WHITE, 2.0, true)
