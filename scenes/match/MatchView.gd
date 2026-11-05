class_name MatchView
extends Node3D
## Draws a Sim in 3D and plays its events as effects and sounds. It never changes the Sim, so it works
## the same for local matches, online hosts and online clients.

signal announce(text: String, color: Color, big: bool)  ## For the HUD: big words in the middle of the screen.
signal feed(text: String, color: Color)
signal stat_flash(kind: String)

const CAM_PITCH := deg_to_rad(52.0)
const AVATAR_SCALE := 1.2  ## Heroes are drawn bigger than their footprint: they are the show.
const SCORED_FACE_SECONDS := 3.0
const GATE_HEIGHT := 1.5
const GATE_WARNING := 1.0
const STATUS_ICONS := {
	"stun": [Cosmetics.Fx.STAR, "ffd23f"], "freeze": [Cosmetics.Fx.SNOW, "bff3ff"], "root": [Cosmetics.Fx.RING, "c9b95c"],
	"slow": [Cosmetics.Fx.DROP, "62e0a0"], "slip": [Cosmetics.Fx.RING, "bff3ff"], "reverse": [Cosmetics.Fx.SPARK, "b768ff"],
	"fear": [Cosmetics.Fx.DROP, "9fe6ff"], "blind": [Cosmetics.Fx.DROP, "123a6b"], "stale": [Cosmetics.Fx.PUFF, "8a8a6a"],
	"overcharge": [Cosmetics.Fx.BOLT, "fff176"], "firetrail": [Cosmetics.Fx.FLAME, "ff7a1f"], "chain": [Cosmetics.Fx.BOLT, "7ee8ff"],
	"speed": [Cosmetics.Fx.PUFF, "ffffff"], "speed2": [Cosmetics.Fx.PUFF, "ffffff"], "dashboost": [Cosmetics.Fx.BOLT, "35d07f"],
	"fastcap": [Cosmetics.Fx.STAR, "ffc21f"],
}

var sim: Sim
var local_id := -1
var my_team := 0
var fx: FxField
var camera: Camera3D
var low_detail := false
var tag_bots := false  ## Online, AI players say so over their heads.

var _avatars: Array[Avatar3D] = []
var _rings: Array[MeshInstance3D] = []
var _markers: Array[Sprite3D] = []
var _labels: Array[Label3D] = []
var _shields: Array[MeshInstance3D] = []
var _ices: Array[MeshInstance3D] = []
var _shadows: Array[MeshInstance3D] = []
var _status_cd := PackedFloat32Array()
var _shown_pos: Array[Vector3] = []
var _pickups := {}
var _zones := {}
var _shots := {}
var _ents := {}
var _walls := {}
var _cap_rings: Array[MeshInstance3D] = []
var _lock_domes: Array[MeshInstance3D] = []
var _jail_labels: Array[Label3D] = []
var _cam_target := Vector3.ZERO
var _cam_yaw := 0.0
var _shake := 0.0
var _time_scale_left := 0.0
var _portrait := false
var _dist := 26.0
var _emote_timers := {}
var _emote_labels := {}
var _wall_mesh: ArrayMesh
var _ring_mesh: QuadMesh
var _blob_mat: StandardMaterial3D
var _quad_cache := {}
var _shield_mesh: ArrayMesh
var _ice_mesh: ArrayMesh
var _grass_mat: ShaderMaterial
var _gates: Array[MeshInstance3D] = []
var _gates_were_shut := false
var _fountain_jets := {}  # Tile -> the water standing up out of it.
var _theme_id := ""
var _sound_cd := {}
var _tick_second := -1
var _team_ring_mats: Array[ShaderMaterial] = []


func setup(p_sim: Sim, p_local_id: int) -> void:
	sim = p_sim
	local_id = p_local_id
	var me := sim.player_by_id(local_id)
	my_team = me.team if me else 0
	low_detail = Quality.is_low()
	var map := Maps.by_id(sim.map_id)
	_theme_id = map["theme"]
	var theme: Dictionary = Maps.THEMES[_theme_id]
	var arena_node := ArenaBuilder.build(sim, low_detail)
	add_child(arena_node)
	var grass_node := arena_node.get_node_or_null("Grass") as MeshInstance3D
	if grass_node:
		_grass_mat = grass_node.material_override
	_build_gates()
	_build_fountains()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(theme["sky"])
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	camera = Camera3D.new()
	camera.fov = 30.0
	camera.near = 1.0
	camera.far = 160.0
	add_child(camera)
	camera.make_current()
	fx = FxField.new(160 if low_detail else 320)
	fx.density = 0.5 if low_detail else 1.0
	add_child(fx)
	_wall_mesh = ArenaBuilder.wall_mesh(_theme_id)
	_build_shared_meshes()
	_build_players()
	_build_base_markers()
	_portrait = get_viewport().get_visible_rect().size.y > get_viewport().get_visible_rect().size.x
	_reset_camera()


func _build_shared_meshes() -> void:
	_ring_mesh = QuadMesh.new()
	_ring_mesh.orientation = PlaneMesh.FACE_Y
	_ring_mesh.size = Vector2.ONE
	_blob_mat = StandardMaterial3D.new()
	_blob_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_blob_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_blob_mat.albedo_color = Color(0.08, 0.03, 0.24, 0.34)
	_blob_mat.albedo_texture = _soft_circle()
	_blob_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	var kit := MeshKit.new()
	kit.outline = 0.0
	kit.ball(Vector3(0, 0.9, 0), Vector3(1.15, 1.15, 1.15), Color("8fe3ff"), 6, 12)
	_shield_mesh = kit.to_mesh()
	kit = MeshKit.new()
	kit.box(Vector3(0, 0.95, 0), Vector3(1.45, 1.9, 1.45), Color("bfeeff"), 0.12)
	_ice_mesh = kit.to_mesh()


func _soft_circle() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	grad.add_point(0.55, Color(1, 1, 1, 1))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	return tex


func _disc_material(color: Color, style := 0.0, inner := 0.25, spin := 0.0, fill := 1.0) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://gfx/shaders/disc.gdshader")
	mat.set_shader_parameter("color", color)
	mat.set_shader_parameter("style", style)
	mat.set_shader_parameter("inner_alpha", inner)
	mat.set_shader_parameter("spin", spin)
	mat.set_shader_parameter("fill", fill)
	return mat


func _flat_quad(mat: Material, size: float, y := 0.03) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.mesh = _ring_mesh
	inst.material_override = mat
	inst.scale = Vector3(size, 1.0, size)
	inst.position.y = y
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return inst


func _build_players() -> void:
	_status_cd.resize(sim.players.size())
	for p: Sim.Player in sim.players:
		var color := ArenaBuilder.team_color(p.team)
		var av := Avatar3D.new()
		add_child(av)
		av.setup(p.look, color)
		av.position = Vector3(p.pos.x, 0, p.pos.y)
		_avatars.append(av)
		_shown_pos.append(av.position)
		var blob := _flat_quad(_blob_mat, 2.4, 0.02)
		add_child(blob)
		_shadows.append(blob)
		var is_me := p.id == local_id
		var ring := _flat_quad(_disc_material(color, 1.0 if not is_me else 3.0, 0.2 if is_me else 0.12, 1.6), 2.4 if not is_me else 2.7, 0.04)
		add_child(ring)
		_rings.append(ring)
		var mark := Sprite3D.new()
		mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		mark.no_depth_test = true
		mark.pixel_size = 0.009
		mark.render_priority = 2
		mark.visible = false
		add_child(mark)
		_markers.append(mark)
		var label := Label3D.new()
		label.text = p.name + (" [AI]" if p.bot and tag_bots else "")
		label.font = UiKit.font_body()
		label.font_size = 40
		label.outline_size = 10
		label.pixel_size = 0.0098
		label.modulate = Color("ffe9a8") if is_me else (Color("c9f1ff") if p.team == my_team else Color("ffc4bd"))
		label.outline_modulate = Color("123a6b")
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.render_priority = 1
		label.fixed_size = false
		add_child(label)
		_labels.append(label)
		var dome := MeshInstance3D.new()
		dome.mesh = _shield_mesh
		var ghost_mat := ShaderMaterial.new()
		ghost_mat.shader = preload("res://gfx/shaders/ghost.gdshader")
		ghost_mat.set_shader_parameter("alpha", 0.4)
		dome.material_override = ghost_mat
		dome.visible = false
		dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(dome)
		_shields.append(dome)
		var ice := MeshInstance3D.new()
		ice.mesh = _ice_mesh
		var ice_mat := ShaderMaterial.new()
		ice_mat.shader = preload("res://gfx/shaders/ghost.gdshader")
		ice_mat.set_shader_parameter("alpha", 0.55)
		ice.material_override = ice_mat
		ice.visible = false
		ice.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ice)
		_ices.append(ice)


func _build_base_markers() -> void:
	for team in 2:
		var at: Vector2 = sim.base[team]
		var ring := _flat_quad(_disc_material(Color("ff3f5a"), 2.0, 0.0, 0.0, 0.0), (Sim.BASE_R + 0.5) * 2.0, 0.06)
		ring.position = Vector3(at.x, 0.06, at.y)
		ring.visible = false
		add_child(ring)
		_cap_rings.append(ring)
		var dome := MeshInstance3D.new()
		var kit := MeshKit.new()
		kit.outline = 0.0
		kit.ball(Vector3.ZERO, Vector3(Sim.BASE_R + 0.3, Sim.BASE_R * 0.9, Sim.BASE_R + 0.3), Color("fff3a8"), 7, 18)
		dome.mesh = kit.to_mesh()
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://gfx/shaders/ghost.gdshader")
		mat.set_shader_parameter("alpha", 0.28)
		dome.material_override = mat
		dome.position = Vector3(at.x, 0, at.y)
		dome.visible = false
		dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(dome)
		_lock_domes.append(dome)
		var jail_label := Label3D.new()
		jail_label.font = UiKit.font_title()
		jail_label.font_size = 54
		jail_label.outline_size = 14
		jail_label.pixel_size = 0.012
		jail_label.text = "JAIL"
		jail_label.modulate = Color("fff3d6")
		jail_label.outline_modulate = Color("123a6b")
		jail_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		jail_label.position = Vector3(sim.jail[team].x, 2.4, sim.jail[team].y - Sim.JAIL_R)
		add_child(jail_label)
		_jail_labels.append(jail_label)


# --- Camera ---------------------------------------------------------------------------------------

## The stick's "up" in world space: the arena turns so your enemy's base is always ahead of you.
func view_yaw() -> float:
	return _cam_yaw


func _reset_camera() -> void:
	# Team 0 starts on the left. In landscape the enemy is to the right; on an upright screen the enemy
	# is at the top. Team 1 sees the same thing, turned round.
	var size := get_viewport().get_visible_rect().size
	_portrait = size.y > size.x * 1.05
	if _portrait:
		_cam_yaw = -PI * 0.5 if my_team == 0 else PI * 0.5
	else:
		_cam_yaw = 0.0 if my_team == 0 else PI
	_update_distance()
	var me := sim.player_by_id(local_id)
	if me:
		_cam_target = Vector3(me.pos.x, 0, me.pos.y)
	else:
		var arena := sim.arena_size()
		_cam_target = Vector3(arena.x * 0.5, 0, arena.y * 0.5)
	_place_camera()


func _update_distance() -> void:
	var size := get_viewport().get_visible_rect().size
	var aspect := size.x / maxf(size.y, 1.0)
	# Keep about 29 m across on wide screens and about 18 m on narrow ones, so phones see enough.
	var want_width := 29.0 if aspect >= 1.2 else 18.0
	var half_h := tan(deg_to_rad(camera.fov) * 0.5)
	_dist = want_width * 0.5 / (half_h * aspect)
	_dist = clampf(_dist, 16.0, 46.0)


func _place_camera() -> void:
	var back := Vector3(0, sin(CAM_PITCH), cos(CAM_PITCH)) * _dist
	back = back.rotated(Vector3.UP, _cam_yaw)
	var jitter := Vector3.ZERO
	if _shake > 0.0:
		jitter = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * _shake * 0.35
	camera.global_position = _cam_target + back + jitter
	camera.look_at(_cam_target + jitter * 0.5, Vector3.UP)


func _follow_camera(delta: float) -> void:
	var size := get_viewport().get_visible_rect().size
	var portrait_now := size.y > size.x * 1.05
	if portrait_now != _portrait:
		_reset_camera()
	var me := sim.player_by_id(local_id)
	var goal := _cam_target
	if me:
		goal = Vector3(_shown_pos[me.id].x, 0, _shown_pos[me.id].z)
		var look_ahead := Vector3(me.vel.x, 0, me.vel.y) * 0.25
		goal += look_ahead
	else:
		var arena := sim.arena_size()
		goal = Vector3(arena.x * 0.5, 0, arena.y * 0.5)
	var arena := sim.arena_size()
	# Don't show much past the walls.
	var half_h := tan(deg_to_rad(camera.fov) * 0.5) * _dist
	var half_w := half_h * size.x / maxf(size.y, 1.0)
	var margin_side := half_w - 3.0
	var margin_depth := half_h * 1.1 - 3.0
	if _portrait:
		var tmp := margin_side
		margin_side = margin_depth
		margin_depth = tmp
	var cx: float = arena.x * 0.5 if margin_side * 2.0 >= arena.x else clampf(goal.x, margin_side, arena.x - margin_side)
	var cz: float = arena.y * 0.5 if margin_depth * 2.0 >= arena.y else clampf(goal.z, margin_depth, arena.y - margin_depth)
	goal = Vector3(cx, 0, cz)
	_cam_target = _cam_target.lerp(goal, clampf(delta * 5.0, 0.0, 1.0))
	_shake = maxf(_shake - delta * 2.5, 0.0)
	_place_camera()


## Roughly what the camera can see of the field, for the box on the minimap.
func ground_view() -> Rect2:
	var view_size := get_viewport().get_visible_rect().size
	var half_h := tan(deg_to_rad(camera.fov) * 0.5) * _dist
	var half_w := half_h * view_size.x / maxf(view_size.y, 1.0)
	var across := Vector2(half_w, half_h * 1.15)
	if _portrait:
		across = Vector2(across.y, across.x)
	return Rect2(Vector2(_cam_target.x, _cam_target.z) - across, across * 2.0)


func shake(amount: float) -> void:
	if Settings.camera_shake:
		_shake = minf(_shake + amount, 1.0)


# --- Every frame ----------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if sim == null:
		return
	if _time_scale_left > 0.0:
		_time_scale_left -= delta
	_play_events()
	_update_players(delta)
	_update_pickups(delta)
	_update_zones()
	_update_shots(delta)
	_update_ents(delta)
	_update_walls()
	_update_gates(delta)
	_update_fountains(delta)
	_update_bushes()
	_update_bases()
	_update_emotes(delta)
	_follow_camera(delta)
	_tick_timer_sound()


func _hidden_to_me(p: Sim.Player) -> bool:
	return sim.is_hidden_from(p, my_team)


func _update_players(delta: float) -> void:
	var me := sim.player_by_id(local_id)
	for i in sim.players.size():
		var p: Sim.Player = sim.players[i]
		var av := _avatars[i]
		var target := Vector3(p.pos.x, 0, p.pos.y)
		var airborne := sim.is_airborne(p)
		if airborne:
			target.y = sin(clampf(p.leap_t, 0.0, 1.0) * PI) * clampf(p.leap_from.distance_to(p.leap_to) * 0.45, 1.0, 4.0)
		var shown := _shown_pos[i]
		var gap := shown.distance_to(target)
		if gap > 5.0:
			shown = target  # Warped or jailed: no sliding across the map.
			if p.state == Sim.State.PLAY:
				fx.burst(target + Vector3(0, 0.8, 0), 12, 4.0, 0.4, 0.35, Cosmetics.Fx.PUFF, ["ffffff"], 0.0)
		else:
			shown = shown.lerp(target, clampf(delta * 18.0, 0.0, 1.0))
		_shown_pos[i] = shown
		av.position = shown
		var speed := p.vel.length()
		var face := p.face
		if face.length() > 0.1:
			var want := atan2(face.x, face.y)
			av.rotation.y = lerp_angle(av.rotation.y, want, clampf(delta * 14.0, 0.0, 1.0))
		var scale := AVATAR_SCALE
		if sim.has_status(p, "giant"):
			scale *= 1.7
		elif sim.has_status(p, "tiny"):
			scale *= 0.6
		av.scale = av.scale.lerp(Vector3.ONE * scale, clampf(delta * 8.0, 0.0, 1.0))
		var is_moving := speed > 0.6
		av.moving = clampf(speed / Sim.SPEED, 0.0, 1.0)
		av.state = _anim_state(p, airborne, is_moving)
		var hidden := _hidden_to_me(p)
		av.visible = not hidden
		_shadows[i].visible = not hidden and not airborne
		_shadows[i].position = Vector3(shown.x, 0.02, shown.z)
		_labels[i].visible = not hidden
		_labels[i].position = shown + Vector3(0, 2.05 * scale + 0.1, 0)
		_rings[i].visible = not hidden and p.state == Sim.State.PLAY
		_rings[i].position = Vector3(shown.x, 0.04, shown.z)
		_update_material(p, av)
		_update_marker(i, p, me, shown, scale, hidden)
		_shields[i].visible = not hidden and sim.has_status(p, "shield") or (not hidden and sim.has_status(p, "mirror"))
		if _shields[i].visible:
			_shields[i].position = shown
			_shields[i].scale = Vector3.ONE * scale * (1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.03)
			(_shields[i].material_override as ShaderMaterial).set_shader_parameter("tint", Color("fff3a8") if sim.has_status(p, "mirror") else Color("ffffff"))
		_ices[i].visible = not hidden and sim.has_status(p, "freeze")
		_ices[i].position = shown
		if not hidden and p.state == Sim.State.PLAY:
			av.emit_effects(fx, delta, is_moving and not airborne)
		_status_particles(i, p, shown, delta, hidden)


func _anim_state(p: Sim.Player, airborne: bool, is_moving: bool) -> String:
	if sim.phase == Sim.Phase.END:
		return "dance" if p.team == sim.winner else "sad"
	if p.state == Sim.State.JAIL:
		return "jail"
	if airborne:
		return "air"
	if sim.has_status(p, "freeze"):
		return "freeze"
	if sim.has_status(p, "stun"):
		return "stun"
	if sim.has_status(p, "root"):
		return "root"
	if p.dash_left > 0.0 or p.vel.length() > Sim.SPEED * 1.8:
		return "dash"
	return "run" if is_moving else "idle"


func _update_material(p: Sim.Player, av: Avatar3D) -> void:
	var ghosted := sim.has_status(p, "ghost") or sim.is_free_walking(p) or sim.has_status(p, "invis")
	if sim.has_status(p, "freeze"):
		av.set_material_kind("frozen")
	elif ghosted:
		av.set_material_kind("ghost")
	elif not av._flash > 0.0:
		av.set_material_kind("normal")


func tile_is_grass(p: Sim.Player) -> bool:
	return sim.tile_at(p.pos) == Maps.GRASS


## The most important thing on screen: above every enemy, can you catch them, or can they catch you?
func _update_marker(i: int, p: Sim.Player, me: Sim.Player, shown: Vector3, scale: float, hidden: bool) -> void:
	var mark := _markers[i]
	var icon := ""
	if p.team != my_team and not hidden and p.state == Sim.State.PLAY and me and me.state == Sim.State.PLAY and not sim.is_free_walking(p):
		if sim.can_tag(me, p):
			icon = "catch"
		elif sim.can_tag(p, me) or (sim.fresh_value(p) > sim.fresh_value(me) and not p.on_base):
			icon = "danger"
	elif p.id == local_id and sim.is_free_walking(p):
		icon = "free"
	if icon == "":
		mark.visible = false
		return
	mark.visible = true
	mark.texture = UiKit.marker_texture(icon)
	var bob := sin(Time.get_ticks_msec() * 0.009 + i) * 0.1
	mark.position = shown + Vector3(0, 2.05 * scale + 1.15 + bob, 0)
	(_rings[i].material_override as ShaderMaterial).set_shader_parameter("color", Color("3bff7a") if icon == "catch" else (Color("ff3f5a") if icon == "danger" else Color("ffffff")))


func _status_particles(i: int, p: Sim.Player, shown: Vector3, delta: float, hidden: bool) -> void:
	_status_cd[i] -= delta
	if _status_cd[i] > 0.0 or hidden or p.state != Sim.State.PLAY:
		return
	for name: String in STATUS_ICONS:
		if sim.has_status(p, name):
			_status_cd[i] = 0.12 if not low_detail else 0.22
			var info: Array = STATUS_ICONS[name]
			var angle := randf() * TAU
			var at := shown + Vector3(cos(angle) * 0.6, 2.1 if name in ["stun", "blind", "reverse"] else randf_range(0.2, 1.4), sin(angle) * 0.6)
			fx.spawn(at, Vector3(cos(angle) * 0.6, 0.5, sin(angle) * 0.6), 0.5, 0.34, int(info[0]), Color(info[1]), 3.0)
			return


func _update_pickups(_delta: float) -> void:
	var seen := {}
	var now := Time.get_ticks_msec() * 0.001
	for item: Dictionary in sim.pickups:
		var uid: int = item["uid"]
		seen[uid] = true
		if not _pickups.has(uid):
			_pickups[uid] = _make_pickup(item)
		var node: Node3D = _pickups[uid]
		var at: Vector2 = item["pos"]
		node.position = Vector3(at.x, 0.55 + sin(now * 3.0 + uid) * 0.12, at.y)
		node.get_child(0).rotation.y = now * 1.6 + uid
	_erase_missing(_pickups, seen)


func _make_pickup(item: Dictionary) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	var gem := MeshInstance3D.new()
	gem.mesh = Crystal.mesh()
	gem.material_override = Crystal.material()
	gem.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	gem.position.y = 0.62
	gem.scale = Vector3.ONE * 1.12
	node.add_child(gem)
	var mark := Label3D.new()
	mark.text = "?"
	mark.font = UiKit.font_title()
	mark.font_size = 96
	mark.outline_size = 26
	mark.outline_modulate = UiKit.INK
	mark.pixel_size = 0.0072
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mark.no_depth_test = true
	mark.render_priority = 1
	mark.position.y = 0.72
	node.add_child(mark)
	var ring := _flat_quad(_disc_material(Color("fff1a8"), 3.0, 0.3, 2.5), 1.9, 0.0)
	ring.position.y = -0.5
	node.add_child(ring)
	node.scale = Vector3.ONE * 0.2
	create_tween().tween_property(node, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	fx.burst(Vector3((item["pos"] as Vector2).x, 1.0, (item["pos"] as Vector2).y), 10, 3.5, 0.45, 0.3, Cosmetics.Fx.SPARK, Crystal.COLOURS, 2.0)
	return node


func _update_zones() -> void:
	var seen := {}
	for z: Dictionary in sim.zones:
		var uid: int = z["uid"]
		var hidden_trap: bool = (z["fx"] == "mine" or z["fx"] == "snare") and int(z["team"]) != my_team and float(sim.radar[my_team]) <= sim.t
		seen[uid] = true
		if not _zones.has(uid):
			_zones[uid] = _make_zone(z)
		var node: Node3D = _zones[uid]
		var at: Vector2 = z["pos"]
		node.position = Vector3(at.x, 0.05, at.y)
		node.visible = not hidden_trap
		if z["fx"] == "drag" or z["fx"] == "pull":
			if not low_detail and randf() < 0.5:
				var a := randf() * TAU
				var r := float(z["r"]) * randf_range(0.5, 1.0)
				fx.spawn(Vector3(at.x + cos(a) * r, 0.2 + randf(), at.y + sin(a) * r), Vector3(-cos(a) * r, 0.6, -sin(a) * r) * 1.6, 0.5, 0.3, Cosmetics.Fx.PUFF, Color("d7d2ff"), 4.0)
		elif z["fx"] == "fire" and randf() < 0.35:
			fx.spawn(Vector3(at.x, 0.3, at.y), Vector3(randf_range(-0.2, 0.2), 1.6, randf_range(-0.2, 0.2)), 0.45, 0.5, Cosmetics.Fx.FLAME, Color("ff8a2b"), 1.0)
		elif z["fx"] == "meteor":
			var left: float = float(z["until"]) - sim.t
			if left < 0.7:
				var drop := left / 0.7
				fx.spawn(Vector3(at.x + drop * 3.0, 12.0 * drop + 0.3, at.y), Vector3.ZERO, 0.08, 1.3, Cosmetics.Fx.FLAME, Color("ff7a1f"))
	_erase_missing(_zones, seen)


func _make_zone(z: Dictionary) -> Node3D:
	var color := Powerups.color(z["pw"])
	var style := 0.0
	var inner := 0.28
	var spin := 0.0
	match String(z["fx"]):
		"slow":
			color = Color("62e0a0")
		"slip":
			color = Color("bff3ff")
			inner = 0.5
		"pull":
			color = Color("b768ff")
			style = 3.0
			spin = -3.0
			inner = 0.4
		"drag":
			color = Color("d7d2ff")
			style = 3.0
			spin = 4.0
		"fire":
			color = Color("ff7a1f")
			inner = 0.5
		"thorn":
			color = Color("35a659")
			style = 3.0
			spin = 0.5
			inner = 0.0
		"mine":
			color = Color("ff3f5a")
			style = 3.0
			spin = 2.0
		"snare":
			color = Color("c9b95c")
			inner = 0.5
		"meteor":
			color = Color("ff3f3f")
			style = 3.0
			spin = 3.0
			inner = 0.3
	var node := Node3D.new()
	add_child(node)
	node.add_child(_flat_quad(_disc_material(color, style, inner, spin), float(z["r"]) * 2.0, 0.0))
	if z["fx"] == "thorn":
		var kit := MeshKit.new()
		var r := float(z["r"])
		for i in 22:
			var a := TAU * i / 22.0
			kit.cone(Vector3(cos(a) * r, 0, sin(a) * r), 0.8, 0.22, Color("2f8f4a") if i % 2 == 0 else Color("48bd6b"), 5)
		node.add_child(_toon_mesh(kit))
	elif z["fx"] == "mine":
		var kit := MeshKit.new()
		kit.ball(Vector3(0, 0.12, 0), Vector3(0.36, 0.2, 0.36), Color("3a3748"), 3, 9)
		kit.ball(Vector3(0, 0.3, 0), Vector3(0.1, 0.1, 0.1), Color("ff3f5a"), 3, 6)
		node.add_child(_toon_mesh(kit))
	elif z["fx"] == "snare":
		var kit := MeshKit.new()
		kit.torus(Vector3(0, 0.07, 0), 0.5, 0.07, Color("7a6a3a"), 12, 4)
		for i in 6:
			var a := TAU * i / 6.0
			kit.cone(Vector3(cos(a) * 0.5, 0.05, sin(a) * 0.5), 0.3, 0.07, Color("c9d0e6"), 4)
		node.add_child(_toon_mesh(kit))
	elif z["fx"] == "drag":
		var kit := MeshKit.new()
		kit.outline = 0.0
		for i in 5:
			kit.torus(Vector3(0, 0.3 + i * 0.5, 0), 0.5 + i * 0.32, 0.12, Color("d7d2ff").lerp(Color("ffffff"), i * 0.2), 12, 4)
		var spinner := _toon_mesh(kit)
		node.add_child(spinner)
	elif z["fx"] == "pull":
		var kit := MeshKit.new()
		kit.outline = 0.0
		kit.ball(Vector3(0, 1.0, 0), Vector3(0.85, 0.85, 0.85), Color("140a33"), 6, 12)
		kit.torus(Vector3(0, 1.0, 0), 1.25, 0.1, Color("b768ff"), 18, 4)
		node.add_child(_toon_mesh(kit))
	return node


func _toon_mesh(kit: MeshKit) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.mesh = kit.to_mesh()
	inst.material_override = Avatar3D._material("normal")
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return inst


func _update_shots(delta: float) -> void:
	var seen := {}
	for s: Dictionary in sim.shots:
		var uid: int = s["uid"]
		seen[uid] = true
		if not _shots.has(uid):
			_shots[uid] = _make_shot(s)
		var node: Node3D = _shots[uid]
		var at: Vector2 = s["pos"]
		var goal := Vector3(at.x, 0.85, at.y)
		node.position = node.position.lerp(goal, clampf(delta * 28.0, 0.0, 1.0)) if node.position.distance_to(goal) < 4.0 else goal
		var color := Powerups.color(s["pw"])
		if randf() < 0.6:
			fx.spawn(node.position, Vector3(randf_range(-0.4, 0.4), 0.3, randf_range(-0.4, 0.4)), 0.3, float(s["r"]) * 0.8, Cosmetics.Fx.SOFT, color)
	_erase_missing(_shots, seen)


func _make_shot(s: Dictionary) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	var pw: String = s["pw"]
	var kit := MeshKit.new()
	var r: float = s["r"]
	var color := Powerups.color(pw)
	match pw:
		"coconut_shot":
			kit.ball(Vector3.ZERO, Vector3.ONE * r, Color("7a5230"), 4, 8)
		"rolling_barrel":
			PropKit.draw(kit, "barrel", Vector3(0, -0.65, 0), 0.0, 0.9)
		"fishing_net":
			kit.torus(Vector3.ZERO, r * 0.9, 0.08, Color("c9b95c"), 12, 4)
			for i in 4:
				kit.box(Vector3.ZERO, Vector3(r * 1.8, 0.04, 0.04).rotated(Vector3.UP, i * PI / 4.0).abs() + Vector3(0.03, 0.03, 0.03), Color("e8dc8a"))
		"ricochet_disc":
			kit.cyl(Vector3(0, -0.08, 0), 0.16, r * 1.3, r * 1.3, color, 12)
		"freeze_ray":
			kit.ball(Vector3.ZERO, Vector3.ONE * r, Color("bff3ff"), 4, 8)
		"slime_ball":
			kit.ball(Vector3.ZERO, Vector3.ONE * r, Color("62e0a0"), 4, 8)
		_:
			kit.ball(Vector3.ZERO, Vector3.ONE * r, color, 3, 8)
	node.add_child(_toon_mesh(kit))
	var at: Vector2 = s["pos"]
	node.position = Vector3(at.x, 0.85, at.y)
	return node


func _update_ents(delta: float) -> void:
	var seen := {}
	for ent: Dictionary in sim.ents:
		var uid: int = ent["uid"]
		seen[uid] = true
		if not _ents.has(uid):
			_ents[uid] = _make_ent(ent)
		var node: Node3D = _ents[uid]
		var at: Vector2 = ent["pos"]
		var goal := Vector3(at.x, 0, at.y)
		node.position = node.position.lerp(goal, clampf(delta * 16.0, 0.0, 1.0))
		if node is Avatar3D:
			var v: Vector2 = ent["vel"]
			if v.length() > 0.1:
				node.rotation.y = lerp_angle(node.rotation.y, atan2(v.x, v.y), clampf(delta * 12.0, 0.0, 1.0))
	_erase_missing(_ents, seen)


func _make_ent(ent: Dictionary) -> Node3D:
	if ent["type"] == "decoy":
		var owner := sim.player_by_id(int(ent["owner"]))
		var av := Avatar3D.new()
		add_child(av)
		av.setup(owner.look if owner else {}, ArenaBuilder.team_color(int(ent["team"])))
		av.state = "run"
		av.moving = 1.0
		av.position = Vector3((ent["pos"] as Vector2).x, 0, (ent["pos"] as Vector2).y)
		return av
	var kit := MeshKit.new()
	kit.cyl(Vector3.ZERO, 0.5, 0.5, 0.36, Color("c9d0e6"), 10)
	kit.ball(Vector3(0, 0.75, 0), Vector3(0.38, 0.32, 0.38), ArenaBuilder.team_color(int(ent["team"])), 4, 9)
	kit.box(Vector3(0, 0.75, 0.42), Vector3(0.14, 0.14, 0.45), Color("3a3748"))
	var node := _toon_mesh(kit)
	add_child(node)
	node.position = Vector3((ent["pos"] as Vector2).x, 0, (ent["pos"] as Vector2).y)
	return node


func _build_gates() -> void:
	var mesh := ArenaBuilder.block_mesh(Color("e8574a"), GATE_HEIGHT, true)
	var mat := Avatar3D._material("normal")
	for i in sim.w * sim.h:
		if sim.tiles[i] == Maps.GATE:
			var inst := MeshInstance3D.new()
			inst.mesh = mesh
			inst.material_override = mat
			inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var at := sim.tile_center(i)
			inst.position = Vector3(at.x, -GATE_HEIGHT - 0.1, at.y)
			add_child(inst)
			_gates.append(inst)


## Gates are shut or open by the clock. Just before they rise, their tops poke out, as a warning.
func _update_gates(delta: float) -> void:
	if _gates.is_empty():
		return
	var shut := sim.gates_shut()
	var left := sim.gates_change_in()
	var goal := 0.0
	if not shut:
		goal = -GATE_HEIGHT * 0.72 if left < GATE_WARNING else -GATE_HEIGHT - 0.1
	for gate in _gates:
		gate.position.y = lerpf(gate.position.y, goal, clampf(delta * 12.0, 0.0, 1.0))
	if shut != _gates_were_shut:
		_gates_were_shut = shut
		var loudest := 0.0
		for gate in _gates:
			loudest = maxf(loudest, _audible(Vector2(gate.position.x, gate.position.z)))
		Audio.sfx("entrance_stamp" if shut else "piece_place", loudest * 0.7)


func _build_fountains() -> void:
	var kit := MeshKit.new()
	kit.soften = true
	kit.shells = false
	kit.outline = 0.0
	kit.ball(Vector3(0, 0.46, 0), Vector3(0.14, 0.46, 0.14), Color("8fe3ff"), 8, 12)
	kit.ball(Vector3(0, 0.92, 0), Vector3(0.3, 0.16, 0.3), Color("d8f6ff"), 6, 12)
	var mesh := kit.to_mesh()
	var mat := Avatar3D._material("normal")
	for tile: int in sim.fountains:
		var inst := MeshInstance3D.new()
		inst.mesh = mesh
		inst.material_override = mat
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var at := sim.tile_center(tile)
		inst.position = Vector3(at.x, 0.5, at.y)
		add_child(inst)
		_fountain_jets[tile] = inst


## A full fountain plays, so you can see from across the field that it's ready. An empty one has only a trickle.
func _update_fountains(delta: float) -> void:
	var now := Time.get_ticks_msec() * 0.001
	for tile: int in _fountain_jets:
		var jet: MeshInstance3D = _fountain_jets[tile]
		var ready := sim.fountain_ready(tile)
		var height := (1.0 + sin(now * 7.0 + tile) * 0.1) if ready else 0.06
		jet.scale = jet.scale.lerp(Vector3(1.0 if ready else 0.5, height, 1.0 if ready else 0.5), clampf(delta * 8.0, 0.0, 1.0))
		if ready and randf() < delta * 5.0:
			var at := jet.position + Vector3(randf_range(-0.2, 0.2), 0.9, randf_range(-0.2, 0.2))
			fx.spawn(at, Vector3(randf_range(-0.8, 0.8), 1.6, randf_range(-0.8, 0.8)), 0.6, 0.2, Cosmetics.Fx.DROP, Color("8fe3ff"), 0.0)


## Lets you see into the bushes wherever you're allowed to see someone. Anyone unseen rustles the leaves as they run.
func _update_bushes() -> void:
	if _grass_mat == null:
		return
	var spots := PackedVector3Array()
	spots.resize(6)
	spots.fill(Vector3(-1000, 0, -1000))
	var count := 0
	var me := sim.player_by_id(local_id)
	if me and me.state == Sim.State.PLAY:
		spots[0] = Vector3(_shown_pos[me.id].x, 0, _shown_pos[me.id].z)
		count = 1
	for p: Sim.Player in sim.players:
		if p.id == local_id or p.state != Sim.State.PLAY or not tile_is_grass(p):
			continue
		if sim.is_hidden_from(p, my_team):
			if p.vel.length() > Sim.SPEED * 0.6 and randf() < 0.1:
				fx.spawn(Vector3(p.pos.x, 1.0, p.pos.y), Vector3(randf_range(-1.5, 1.5), 1.4, randf_range(-1.5, 1.5)), 0.55, 0.24, Cosmetics.Fx.LEAF, Color(Maps.THEMES[_theme_id]["grass"]).lightened(0.2), 3.0)
		elif count < 6:
			spots[count] = Vector3(_shown_pos[p.id].x, 0, _shown_pos[p.id].z)
			count += 1
	_grass_mat.set_shader_parameter("reveals", spots)


func _update_walls() -> void:
	var seen := {}
	for tile: int in sim.walls:
		seen[tile] = true
		if not _walls.has(tile):
			var inst := MeshInstance3D.new()
			inst.mesh = _wall_mesh
			inst.material_override = Avatar3D._material("normal")
			inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(inst)
			var at := sim.tile_center(tile)
			inst.position = Vector3(at.x, -1.4, at.y)
			create_tween().tween_property(inst, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_walls[tile] = inst
			fx.burst(Vector3(at.x, 0.4, at.y), 5, 3.0, 0.4, 0.4, Cosmetics.Fx.PUFF, ["ffffff"], 2.0)
	_erase_missing(_walls, seen)


func _erase_missing(store: Dictionary, seen: Dictionary) -> void:
	if store.size() == seen.size():
		var same := true
		for key: Variant in store:
			if not seen.has(key):
				same = false
				break
		if same:
			return
	for key: Variant in store.keys():
		if not seen.has(key):
			(store[key] as Node).queue_free()
			store.erase(key)


func _update_bases() -> void:
	for team in 2:
		var ring := _cap_rings[team]
		var amount: float = sim.cap[team]
		ring.visible = amount > 0.001
		if ring.visible:
			(ring.material_override as ShaderMaterial).set_shader_parameter("fill", amount)
			(ring.material_override as ShaderMaterial).set_shader_parameter("color", ArenaBuilder.team_color(1 - team))
		_lock_domes[team].visible = float(sim.base_lock[team]) > sim.t


func _tick_timer_sound() -> void:
	if sim.phase != Sim.Phase.PLAY:
		return
	var second := int(ceil(sim.time_left))
	if second != _tick_second:
		_tick_second = second
		if second <= 10 and second > 0:
			Audio.sfx("timer_urgent")


# --- Effects for what just happened ---------------------------------------------------------------

func _world(x: float, y: float, h := 0.8) -> Vector3:
	return Vector3(x, h, y)


func _play_events() -> void:
	for ev: Array in sim.take_events():
		_event(ev)


func _audible(at: Vector2) -> float:
	var me := sim.player_by_id(local_id)
	if me == null:
		return 0.8
	var d := me.pos.distance_to(at)
	return clampf(1.15 - d / 32.0, 0.25, 1.0)


func _event(ev: Array) -> void:
	var kind: String = ev[0]
	var a: int = ev[1]
	var b: int = ev[2]
	var x: float = ev[3]
	var y: float = ev[4]
	var at2 := Vector2(x, y)
	var extra: Variant = ev[5]
	var pa := sim.player_by_id(a)
	var pb := sim.player_by_id(b)
	var mine := a == local_id
	match kind:
		"tag":
			_on_tag(pa, pb, at2)
		"blocked":
			fx.burst(_world(x, y, 1.0), 14, 6.0, 0.4, 0.4, Cosmetics.Fx.RING, ["8fe3ff", "ffffff"])
			if pa:
				_avatars[a].react_any(Faces.TAGGED, 0.9)
			if pb:
				_avatars[b].react_any(Faces.TAGGING, 0.9)
			Audio.sfx("clash_tie", _audible(at2))
			if a == local_id or b == local_id:
				shake(0.25)
		"chain":
			fx.burst(_world(x, y, 1.0), 16, 7.0, 0.35, 0.4, Cosmetics.Fx.BOLT, ["7ee8ff", "ffffff"], 1.0)
		"rescue":
			fx.burst(_world(x, y, 1.2), 22, 7.0, 0.7, 0.42, Cosmetics.Fx.STAR, ["ffd23f", "ffffff", "35d07f"])
			if a >= 0:
				_avatars[a].react_any(Faces.CHEERING, 1.6)
			Audio.sfx("powerup_good")
			if pa:
				var mine_team := pa.team == my_team
				feed.emit("%s freed %d from jail!" % [pa.name, b], Color("8fffb4") if mine_team else Color("ffc4bd"))
				if mine_team:
					announce.emit("JAILBREAK!", Color("8fffb4"), false)
				if mine:
					stat_flash.emit("rescue")
		"freed":
			if a == local_id:
				announce.emit("FREE WALK! Get home!", Color("ffffff"), false)
				_avatars[a].flash()
		"respawn":
			if a >= 0:
				_avatars[a].flash()
				fx.burst(_avatars[a].position + Vector3(0, 0.8, 0), 12, 4.0, 0.4, 0.34, Cosmetics.Fx.STAR, [ArenaBuilder.team_color(pa.team), "ffffff"], 2.0)
		"home":
			if mine:
				Audio.sfx("topper_chime", 0.7)
				fx.shock_ring(_avatars[a].position, 2.0, Cosmetics.Fx.SPARK, ArenaBuilder.team_color(pa.team), 14)
		"pop":
			fx.burst(_world(x, y, 0.3), 14, 5.0, 0.4, 0.36, Cosmetics.Fx.PUFF, ["ffffff"], 2.0)
			Audio.sfx("move_bounce", _audible(at2))
			if mine:
				announce.emit("NO CAMPING!", Color("ffd23f"), false)
		"dash":
			fx.burst(_world(x, y, 0.3), 8, 2.5, 0.3, 0.4, Cosmetics.Fx.PUFF, ["ffffff"], 0.0)
			if mine:
				Audio.sfx("trail_whoosh", 0.7)
		"land":
			fx.burst(_world(x, y, 0.1), 7, 3.0, 0.3, 0.34, Cosmetics.Fx.PUFF, ["ffffff"], 0.0)
			if a >= 0:
				_avatars[a].squash(0.4)
			if mine:
				Audio.sfx("piece_place", 0.7)
		"boost":
			fx.burst(_world(x, y, 0.4), 6, 2.5, 0.28, 0.42, Cosmetics.Fx.PUFF, ["ffffff", "fff176"], 0.0)
			if mine or _audible(at2) > 0.6:
				Audio.sfx("trail_whoosh", _audible(at2) * 0.8)
		"jump":
			fx.burst(_world(x, y, 0.6), 12, 4.5, 0.4, 0.34, Cosmetics.Fx.STAR, ["ffd23f", "ffffff"], 2.0)
			Audio.sfx("move_bounce", _audible(at2))
			if a >= 0:
				_avatars[a].squash(0.55)
				_avatars[a].react_any(Faces.CHEERING, 1.0)
		"fountain":
			fx.burst(_world(x, y, 1.0), 18, 4.0, 0.6, 0.3, Cosmetics.Fx.DROP, ["8fe3ff", "ffffff"], 5.0)
			_float_text(_world(x, y, 2.2), "FRESH!", Color("8fe3ff"))
			Audio.sfx("aura_water", _audible(at2) * 0.8)
			if a >= 0:
				_avatars[a].react("happy", 1.0)
		"bump":
			fx.burst(_world(x, y, 1.0), 14, 6.0, 0.35, 0.36, Cosmetics.Fx.STAR, ["ff5a4e", "ffffff", "ffd23f"], 2.0)
			_float_text(_world(x, y, 2.0), "BOING!", Color("ffd23f"))
			Audio.sfx("move_bounce", _audible(at2) * 0.9, 1.3)
			if a >= 0:
				_avatars[a].squash(0.7)
				_avatars[a].react_any(Faces.TAGGED, 0.9)
			if mine:
				shake(0.14)
		"bounce":
			Audio.sfx("move_bounce", _audible(at2))
			if a >= 0:
				_avatars[a].squash(0.5)
		"warp":
			fx.burst(_world(x, y, 1.0), 14, 4.0, 0.4, 0.34, Cosmetics.Fx.SPARK, ["b768ff", "27e9ff"], 0.0)
			if mine or _audible(at2) > 0.6:
				Audio.sfx("move_teleport", _audible(at2))
		"pick":
			fx.burst(_world(x, y, 1.0), 16, 4.5, 0.5, 0.32, Cosmetics.Fx.STAR, Crystal.COLOURS, 2.0)
			if a >= 0:
				_avatars[a].react_any(Faces.GOT_CRYSTAL, Sim.SPIN_TIME)
			if mine:
				Audio.sfx("coins", 0.8)
		"drop":
			Audio.sfx("piece_pickup", _audible(at2) * 0.6)
		"use":
			_on_use(pa, String(extra), at2)
		"burst":
			var c2 := Powerups.color(String(extra))
			fx.shock_ring(_world(x, y, 0.2), 3.0, Cosmetics.Fx.PUFF, c2.lightened(0.35), 22)
			shake(0.18 if mine else 0.05)
		"hit":
			var c3 := Powerups.color(String(extra)) if extra is String and extra != "" else Color("ffffff")
			fx.burst(_world(x, y, 1.0), 14, 5.5, 0.4, 0.34, Cosmetics.Fx.STAR, [c3, "ffffff"])
			if a >= 0:
				_avatars[a].flash()
			Audio.sfx("clash_hit", _audible(at2))
			if a == local_id:
				shake(0.3)
		"cc":
			if a >= 0 and a < _avatars.size():
				_avatars[a].flash()
			if a == local_id:
				var words := {"stun": "STUNNED!", "freeze": "FROZEN!", "root": "PINNED!", "fear": "PANIC!", "reverse": "CONTROLS FLIPPED!", "blind": "INKED!", "stale": "CURSED!"}
				if words.has(extra):
					announce.emit(words[extra], Color("ffc4bd"), false)
				if extra == "blind":
					stat_flash.emit("blind")
		"zap":
			for i in 8:
				fx.spawn(_world(x, y, 12.0 - i * 1.5), Vector3.ZERO, 0.18, 0.95, Cosmetics.Fx.BOLT, Color("fff176"))
			fx.burst(_world(x, y, 0.8), 12, 5.0, 0.35, 0.38, Cosmetics.Fx.SPARK, ["fff176", "ffffff"], 0.0)
			Audio.sfx("kill_lightning_strike", _audible(at2))
			shake(0.2)
		"quake":
			shake(1.0)
			var arena := sim.arena_size()
			for i in 26:
				fx.spawn(Vector3(randf() * arena.x, 0.2, randf() * arena.y), Vector3(0, 3.0, 0), 0.6, 0.7, Cosmetics.Fx.PUFF, Color("d8c8a8"), 2.0, 4.0)
		"boom":
			fx.burst(_world(x, y, 0.6), 22, 8.0, 0.5, 0.5, Cosmetics.Fx.FLAME, ["ffb52e", "ff5a1f", "ffffff"])
			Audio.sfx("kill_ka_boom", _audible(at2))
			shake(0.3 * _audible(at2))
		"wall":
			Audio.sfx("entrance_stamp", _audible(at2))
		"swap":
			fx.burst(_world(x, y, 1.0), 16, 5.0, 0.4, 0.36, Cosmetics.Fx.SPARK, ["b768ff", "ffffff"], 0.0)
		"poof":
			fx.burst(_world(x, y, 0.9), 14, 4.0, 0.4, 0.42, Cosmetics.Fx.PUFF, ["ffffff", "d7d2ff"], 0.0)
			Audio.sfx("kill_ghost_pop", _audible(at2) * 0.8)
		"reflect":
			fx.burst(_world(x, y, 1.0), 10, 5.0, 0.3, 0.36, Cosmetics.Fx.SPARK, ["fff3a8", "ffffff"], 0.0)
			Audio.sfx("clash_tie", _audible(at2))
		"ricochet":
			fx.burst(_world(x, y, 0.8), 5, 4.0, 0.2, 0.26, Cosmetics.Fx.SPARK, ["ffffff"], 0.0)
			Audio.sfx("piece_pickup", _audible(at2) * 0.6)
		"sentry_shot":
			Audio.sfx("topper_pop", _audible(at2) * 0.6)
		"shot_end":
			fx.burst(_world(x, y, 0.8), 7, 3.0, 0.3, 0.3, Cosmetics.Fx.PUFF, [Powerups.color(String(extra))], 0.0)
		"lock":
			announce.emit("BASE LOCKED!", ArenaBuilder.team_color(a), false)
		"refreshed":
			if a >= 0:
				_avatars[a].flash()
				fx.burst(_avatars[a].position + Vector3(0, 1.0, 0), 10, 3.0, 0.4, 0.32, Cosmetics.Fx.SPARK, ["ffffff", "fff176"], 0.0)
		"go":
			Audio.sfx("match_start")
			announce.emit("GO!", Color("8fffb4"), true)
		"round":
			announce.emit("GET READY!", Color("ffffff"), true)
		"fiesta":
			Audio.sfx("finale_fiesta")
			Audio.fiesta_time()
			announce.emit("FIESTA TIME! Powerups everywhere!", Color("ffd23f"), true)
		"overtime":
			Audio.sfx("timer_urgent")
			announce.emit("SUDDEN DEATH!", Color("ff5a4e"), true)
		"score":
			_on_score(a, b, at2, String(extra))
		"end":
			pass


func _on_tag(tagger: Sim.Player, tagged: Sim.Player, at2: Vector2) -> void:
	if tagger == null or tagged == null:
		return
	var burst_def := Cosmetics.item("burst", tagger.look.get("burst", ""))
	if burst_def.is_empty():
		burst_def = Cosmetics.BURSTS[0]
	fx.burst(_world(at2.x, at2.y, 1.0), 26, 8.0, 0.6, 0.45, int(burst_def["fx"]), burst_def["c"])
	fx.shock_ring(_world(at2.x, at2.y, 0.2), 2.2, Cosmetics.Fx.PUFF, Color("ffffff"), 16)
	_float_text(_world(at2.x, at2.y, 2.2), String(burst_def["text"]), ArenaBuilder.team_color(tagger.team).lightened(0.3))
	_avatars[tagged.id].flash()
	_avatars[tagged.id].squash(1.0)
	_avatars[tagger.id].squash(0.3)
	_avatars[tagger.id].react_any(Faces.TAGGING, 1.6)
	_avatars[tagged.id].react_any(Faces.TAGGED, 1.2)
	var near := _audible(at2)
	Audio.sfx("kill_generic", near)
	var i_tagged := tagger.id == local_id
	var i_was_tagged := tagged.id == local_id
	if i_tagged:
		Audio.sfx("voice_nice_1", 0.8)
		shake(0.35)
		stat_flash.emit("tag")
		announce.emit("You tagged %s!" % tagged.name, Color("8fffb4"), false)
		Haptics.buzz("tag")
	elif i_was_tagged:
		Audio.sfx("voice_oof_1", 0.9)
		shake(0.6)
		announce.emit("Tagged by %s! To jail!" % tagger.name, Color("ffc4bd"), false)
		Haptics.buzz("jailed")
	else:
		feed.emit("%s tagged %s" % [tagger.name, tagged.name], Color("c9f1ff") if tagger.team == my_team else Color("ffc4bd"))


func _on_use(p: Sim.Player, id: String, at2: Vector2) -> void:
	var def := Powerups.by_id(id)
	if def.is_empty():
		return
	var c := Powerups.color(id)
	fx.burst(_world(at2.x, at2.y, 1.1), 12, 4.0, 0.4, 0.34, Cosmetics.Fx.SPARK, [c, "ffffff"], 0.0)
	if p:
		_avatars[p.id].squash(0.25)
	Audio.sfx(String(def["sfx"]), _audible(at2))
	if p and p.id != local_id and p.team != my_team and int(def["tier"]) >= 2:
		feed.emit("%s used %s" % [p.name, def["name"]], Color("ffc4bd"))
	elif p and p.id != local_id and p.team == my_team and def["cat"] == "team":
		feed.emit("%s used %s" % [p.name, def["name"]], Color("c9f1ff"))


func _on_score(team: int, who: int, at2: Vector2, reason: String) -> void:
	var color := ArenaBuilder.team_color(team)
	shake(0.7)
	for i in 3:
		fx.burst(_world(at2.x + randf_range(-2.0, 2.0), at2.y + randf_range(-2.0, 2.0), 1.5), 36, 10.0, 0.9, 0.5, Cosmetics.Fx.CONFETTI, [color, "ffffff", "ffd23f"], 8.0)
	var mine := team == my_team
	for p: Sim.Player in sim.players:
		_avatars[p.id].react_any(Faces.CHEERING if p.team == team else Faces.BOOING, SCORED_FACE_SECONDS)
	Audio.sfx("flag_capture")
	Audio.sfx("finale_cheer" if mine else "defeat", 0.7)
	var text := "BASE CAPTURED!" if reason == "capture" else "TOTAL JAIL!"
	announce.emit(text if mine else ("THEY TOOK OUR BASE!" if reason == "capture" else "WE'RE ALL IN JAIL!"), color.lightened(0.25), true)
	if who == local_id:
		stat_flash.emit("capture")


func _float_text(at: Vector3, text: String, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font = UiKit.font_title()
	label.font_size = 72
	label.outline_size = 18
	label.pixel_size = 0.013
	label.modulate = color
	label.outline_modulate = Color("123a6b")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 3
	label.position = at
	add_child(label)
	label.scale = Vector3.ONE * 0.4
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector3.ONE * 1.1, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "position:y", at.y + 1.5, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(label, "outline_modulate:a", 0.0, 0.2)
	tween.tween_callback(label.queue_free)


## An emote bubble over a player's head.
func show_emote(player_id: int, text: String) -> void:
	if player_id < 0 or player_id >= _avatars.size():
		return
	_avatars[player_id].react(Faces.funny(), 1.8)
	if _emote_labels.has(player_id):
		(_emote_labels[player_id] as Node).queue_free()
	var label := Label3D.new()
	label.text = text
	label.font = UiKit.font_title()
	label.font_size = 56
	label.outline_size = 16
	label.pixel_size = 0.013
	label.modulate = Color("ffffff")
	label.outline_modulate = Color("123a6b")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 3
	add_child(label)
	_emote_labels[player_id] = label
	_emote_timers[player_id] = 2.4
	label.scale = Vector3.ONE * 0.2
	create_tween().tween_property(label, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.sfx("chat_message", 0.6)


func _update_emotes(delta: float) -> void:
	for id: int in _emote_labels.keys():
		_emote_timers[id] = float(_emote_timers[id]) - delta
		var label: Label3D = _emote_labels[id]
		label.position = _shown_pos[id] + Vector3(0, 4.0, 0)
		if float(_emote_timers[id]) <= 0.0:
			label.queue_free()
			_emote_labels.erase(id)
			_emote_timers.erase(id)


## Screen position of a world point (for HUD pointers), or null when behind the camera.
func screen_of(world_pos: Vector3) -> Variant:
	if camera == null or camera.is_position_behind(world_pos):
		return null
	return camera.unproject_position(world_pos)


func avatar_of(id: int) -> Avatar3D:
	return _avatars[id] if id >= 0 and id < _avatars.size() else null
