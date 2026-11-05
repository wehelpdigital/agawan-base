class_name Minimap
extends Control
## The whole field in the corner of the screen, as a little picture of it: each team's half, walls, water, bushes and
## every trick on the field, true-size bases and jails, crystals, and everyone you can see. Enemies have a green ring when you can tag
## them and a red one when they can tag you. The white box is what your camera can see. Hidden enemies don't appear,
## so it's no way around the tall grass.

const FRAME := 5.0  ## How far the frame stands out around the map.
const CAN_TAG := Color("7dff9c")
const CAN_BE_TAGGED := Color("ff5a5a")
const WALL := Color("2b2166")

var view_rect := Rect2()  ## What the camera sees, in field coordinates.

var _sim: Sim
var _me := 0
var _my_team := 0
var _rotated := false
var _bake: SubViewport
var _field: Control
var _star: Texture2D
var _cage: Texture2D


func setup(sim: Sim, local_id: int) -> void:
	_sim = sim
	_me = local_id
	var me := sim.player_by_id(local_id)
	_my_team = me.team if me else 0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_star = UiKit.icon_texture("star")
	_cage = UiKit.icon_texture("cage")
	# The field never changes, so it's drawn once, into a picture, at the size it's shown.
	_bake = SubViewport.new()
	_bake.disable_3d = true
	_bake.transparent_bg = true
	_bake.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_bake)
	_field = Control.new()
	_field.draw.connect(_draw_field)
	_bake.add_child(_field)
	resized.connect(_rebake)


func _rebake() -> void:
	if _sim == null or size.x < 1.0 or size.y < 1.0:
		return
	var density := clampf(get_viewport().get_final_transform().get_scale().x, 1.0, 2.5)
	var long := maxf(size.x, size.y) * density
	var short := minf(size.x, size.y) * density
	_bake.size = Vector2i(ceili(long), ceili(short))
	_field.size = Vector2(_bake.size)
	_field.queue_redraw()
	_bake.render_target_update_mode = SubViewport.UPDATE_ONCE


## On an upright screen the map turns to match the camera: enemy base at the top.
func set_rotated(on: bool) -> void:
	_rotated = on
	_rebake()
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


## The part that's only drawn once. It's always laid out with team 0 on the left; _draw turns it the right way round.
func _draw_field() -> void:
	var whole := Vector2(_bake.size)
	var theme: Dictionary = Maps.THEMES[Maps.by_id(_sim.map_id)["theme"]]
	var tile := whole / Vector2(_sim.w, _sim.h)
	_field.draw_rect(Rect2(Vector2.ZERO, whole), Color(theme["floor"][0]))
	# Each team's half carries a wash of its colour, with a dashed line down the middle.
	_field.draw_rect(Rect2(Vector2.ZERO, Vector2(whole.x * 0.5, whole.y)), Color(ArenaBuilder.team_color(0), 0.2))
	_field.draw_rect(Rect2(Vector2(whole.x * 0.5, 0), Vector2(whole.x * 0.5, whole.y)), Color(ArenaBuilder.team_color(1), 0.2))
	var dash := whole.y / 15.0
	for i in 8:
		_field.draw_rect(Rect2(whole.x * 0.5 - 1.0, dash * (i * 2.0 + 0.5), 2.0, dash), Color(1, 1, 1, 0.5))
	# Soft shapes run together where tiles of a kind touch, so walls and ponds read as one thing.
	var overlap := tile.y * 0.2
	var radius := int(tile.y * 0.34)
	for y in _sim.h:
		for x in _sim.w:
			var rect := Rect2(Vector2(x, y) * tile, tile)
			var code := _sim.tiles[y * _sim.w + x]
			match code:
				Maps.SOLID:
					_field.draw_style_box(UiKit.style(WALL, radius), rect.grow(overlap))
				Maps.PIT:
					_field.draw_style_box(UiKit.style(Color(theme["pit_c"]), radius), rect.grow(overlap))
				Maps.GRASS:
					_field.draw_style_box(UiKit.style(Color(theme["grass"]).darkened(0.08), radius), rect.grow(overlap))
				Maps.ICE:
					_field.draw_rect(rect, Color("d8f6ff"))
				Maps.MUD:
					_field.draw_rect(rect, Color("8a6240"))
				Maps.BOUNCE:
					_field.draw_circle(rect.get_center(), tile.y * 0.42, Color("ff4f8b"))
				Maps.TELE:
					_field.draw_circle(rect.get_center(), tile.y * 0.46, Color("b768ff"))
					_field.draw_circle(rect.get_center(), tile.y * 0.22, Color("27e9ff"))
				Maps.CON_R, Maps.CON_L, Maps.CON_U, Maps.CON_D:
					_field.draw_rect(rect, Color("6a84aa"))
				Maps.DASH_R: _draw_chevron(rect, Vector2.RIGHT)
				Maps.DASH_L: _draw_chevron(rect, Vector2.LEFT)
				Maps.DASH_U: _draw_chevron(rect, Vector2.UP)
				Maps.DASH_D: _draw_chevron(rect, Vector2.DOWN)
				Maps.JUMP:
					_field.draw_circle(rect.get_center(), tile.y * 0.46, Color("ff5a4e"))
					_field.draw_circle(rect.get_center(), tile.y * 0.22, Color("ffd23f"))
				Maps.LAND:
					_field.draw_arc(rect.get_center(), tile.y * 0.4, 0.0, TAU, 14, Color("ffd23f"), maxf(tile.y * 0.14, 1.5), true)
				Maps.GATE:
					_field.draw_rect(rect.grow(-tile.y * 0.08), Color("e8574a"))
				Maps.FENCE:
					_field.draw_rect(rect.grow(-tile.y * 0.28), Color("fff6e0"))
				Maps.BUMPER:
					_field.draw_circle(rect.get_center(), tile.y * 0.48, Color("ff5a4e"))
					_field.draw_circle(rect.get_center(), tile.y * 0.18, Color("fff6e0"))
				Maps.ALTAR:
					_field.draw_circle(rect.get_center(), tile.y * 0.44, Color("7a6ad8"))
	# The flight of every jump pad.
	for pad: int in _sim.jumps:
		var from := Vector2(pad % _sim.w + 0.5, pad / _sim.w + 0.5) * tile
		var land: int = _sim.jumps[pad]
		var to := Vector2(land % _sim.w + 0.5, land / _sim.w + 0.5) * tile
		var dots := int(from.distance_to(to) / maxf(tile.y * 0.6, 2.0))
		for i in range(1, dots):
			_field.draw_circle(from.lerp(to, float(i) / dots), maxf(tile.y * 0.07, 0.8), Color(1, 1, 1, 0.8))


func _draw_chevron(rect: Rect2, dir: Vector2) -> void:
	_field.draw_rect(rect, Color("ff7a1f"))
	var c := rect.get_center()
	var r := rect.size.y * 0.32
	var side := dir.orthogonal()
	_field.draw_polyline(PackedVector2Array([c - dir * r + side * r, c + dir * r, c - dir * r - side * r]), Color("fff176"), maxf(rect.size.y * 0.16, 1.5), true)


## Only fountains change: bright when full, dull when empty.
func _draw_fountains(long: float) -> void:
	var r: float = Maps.TILE * 0.5 / _sim.arena_size().x * long
	for tile: int in _sim.fountains:
		var at := _to_map(_sim.tile_center(tile))
		var ready := _sim.fountain_ready(tile)
		draw_circle(at, r + 1.2, UiKit.INK)
		draw_circle(at, r, Color("4fc8f4") if ready else Color("7a8aa0"))
		if ready:
			draw_circle(at, r * 0.45, Color.WHITE)


func _draw() -> void:
	if _sim == null:
		return
	var rect := Rect2(Vector2.ZERO, size)
	_draw_map_picture(rect)
	var long := maxf(size.x, size.y)
	var k := long / 170.0
	for team in 2:
		_draw_jail(team, long)
		_draw_base(team, long)
	_draw_fountains(long)
	_draw_camera_box()
	for item: Dictionary in _sim.pickups:
		_draw_crystal(item, k)
	for p: Sim.Player in _sim.players:
		if p.id != _me and p.state == Sim.State.PLAY and not _sim.is_hidden_from(p, _my_team):
			_draw_player(p, k)
	var me := _sim.player_by_id(_me)
	if me and me.state == Sim.State.PLAY:
		_draw_me(me, k)
	# The frame goes on last: a dark rounded surround, with a lighter line just inside.
	var frame := StyleBoxFlat.new()
	frame.draw_center = false
	frame.set_corner_radius_all(14)
	frame.set_border_width_all(int(FRAME))
	frame.border_color = UiKit.INK
	draw_style_box(frame, rect.grow(FRAME - 1.0))
	var line := StyleBoxFlat.new()
	line.draw_center = false
	line.set_corner_radius_all(10)
	line.set_border_width_all(2)
	line.border_color = Color("8f7bff")
	draw_style_box(line, rect.grow(-0.5))


func _draw_map_picture(rect: Rect2) -> void:
	var texture := _bake.get_texture()
	if _rotated:
		var side := Vector2(size.y, size.x)
		var turn := Transform2D(-PI * 0.5, Vector2(0, size.y)) if _my_team == 0 else Transform2D(PI * 0.5, Vector2(size.x, 0))
		draw_set_transform_matrix(turn)
		draw_texture_rect(texture, Rect2(Vector2.ZERO, side), false)
		draw_set_transform_matrix(Transform2D.IDENTITY)
	elif _my_team == 1:
		draw_set_transform_matrix(Transform2D(PI, size))
		draw_texture_rect(texture, rect, false)
		draw_set_transform_matrix(Transform2D.IDENTITY)
	else:
		draw_texture_rect(texture, rect, false)


## True to size, so you can see how much ground there is to guard. A red arc fills as it's being captured.
func _draw_base(team: int, long: float) -> void:
	var at := _to_map(_sim.base[team])
	var r: float = Sim.BASE_R / _sim.arena_size().x * long
	var color := ArenaBuilder.team_color(team)
	var taking := float(_sim.cap[team])
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
	if taking > 0.01:
		draw_circle(at, r + 2.5 + pulse * 2.0, Color("ff3f5a", 0.55))
	draw_circle(at, r + 1.5, UiKit.INK)
	draw_circle(at, r, color)
	draw_circle(at, r * 0.62, color.lightened(0.45))
	var side := r * 1.05
	draw_texture_rect(_star, Rect2(at - Vector2(side, side) * 0.5, Vector2(side, side)), false, Color(1, 1, 1, 0.95))
	if taking > 0.01:
		draw_arc(at, r + 1.0, -PI * 0.5, -PI * 0.5 + TAU * minf(taking, 1.0), 24, Color("ff3f5a"), 3.0, true)


## The cage, with a badge saying how many it holds.
func _draw_jail(team: int, long: float) -> void:
	var at := _to_map(_sim.jail[team])
	var r: float = Sim.JAIL_R / _sim.arena_size().x * long
	var color := ArenaBuilder.team_color(team)
	draw_circle(at, r + 1.5, UiKit.INK)
	draw_circle(at, r, color.lerp(Color("3a3058"), 0.55))
	var side := r * 1.7
	draw_texture_rect(_cage, Rect2(at - Vector2(side, side) * 0.5, Vector2(side, side)), false)
	var held := 0
	for p: Sim.Player in _sim.players:
		if p.state == Sim.State.JAIL and p.team != team:
			held += 1
	if held > 0:
		var badge := at + Vector2(r * 0.8, -r * 0.8)
		var badge_r := maxf(r * 0.62, 6.0)
		draw_circle(badge, badge_r + 1.0, UiKit.INK)
		draw_circle(badge, badge_r, UiKit.CORAL)
		var font := UiKit.font_title()
		var font_size := int(badge_r * 1.5)
		var text := str(held)
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, badge + Vector2(-w * 0.5, font_size * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)


func _draw_camera_box() -> void:
	if view_rect.size == Vector2.ZERO:
		return
	var a := _to_map(view_rect.position)
	var b := _to_map(view_rect.end)
	var box := Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), (a - b).abs()).intersection(Rect2(Vector2.ZERO, size))
	if box.size.x < 2.0 or box.size.y < 2.0:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.1)
	style.set_corner_radius_all(4)
	style.set_border_width_all(2)
	style.border_color = Color(1, 1, 1, 0.6)
	draw_style_box(style, box)


func _draw_crystal(item: Dictionary, k: float) -> void:
	var at := _to_map(item["pos"])
	var r := 3.2 * k + 0.5
	var shimmer := Color.from_hsv(fmod(Time.get_ticks_msec() * 0.00025 + int(item["uid"]) * 0.17, 1.0), 0.42, 1.0)
	draw_colored_polygon(_diamond(at, r + 1.4), UiKit.INK)
	draw_colored_polygon(_diamond(at, r), shimmer)


static func _diamond(at: Vector2, r: float) -> PackedVector2Array:
	return PackedVector2Array([at + Vector2(0, -r), at + Vector2(r * 0.8, 0), at + Vector2(0, r), at + Vector2(-r * 0.8, 0)])


func _draw_player(p: Sim.Player, k: float) -> void:
	var at := _to_map(p.pos)
	var r := 3.4 * k + 0.8
	var me := _sim.player_by_id(_me)
	if me and p.team != me.team and me.state == Sim.State.PLAY:
		if _sim.can_tag(me, p):
			draw_circle(at, r + 3.2, CAN_TAG)
		elif _sim.can_tag(p, me):
			draw_circle(at, r + 3.2, CAN_BE_TAGGED)
	draw_circle(at, r + 1.4, UiKit.INK)
	draw_circle(at, r, ArenaBuilder.team_color(p.team))


## You: bigger, in white, with a pulse and an arrow showing which way you're facing.
func _draw_me(me: Sim.Player, k: float) -> void:
	var at := _to_map(me.pos)
	var r := 4.6 * k + 1.0
	var pulse := fmod(Time.get_ticks_msec() * 0.0012, 1.0)
	draw_arc(at, r + 2.0 + pulse * 8.0 * k, 0.0, TAU, 20, Color(1, 1, 1, 0.75 * (1.0 - pulse)), 2.0, true)
	var ahead := _to_map(me.pos + me.face) - at
	if ahead.length() > 0.01:
		var dir := ahead.normalized()
		var side := dir.orthogonal()
		var tip := at + dir * (r + 6.0 * k + 2.0)
		var base_at := at + dir * (r - 0.5)
		draw_colored_polygon(PackedVector2Array([tip + dir * 1.5, base_at + side * (r * 0.95 + 1.2), base_at - side * (r * 0.95 + 1.2)]), UiKit.INK)
		draw_colored_polygon(PackedVector2Array([tip, base_at + side * r * 0.85, base_at - side * r * 0.85]), Color.WHITE)
	draw_circle(at, r + 1.6, UiKit.INK)
	draw_circle(at, r, Color.WHITE)
	draw_circle(at, r * 0.62, ArenaBuilder.team_color(me.team))
