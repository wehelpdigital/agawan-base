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
const MAX_CRYSTALS := 72
const STATUS_ICONS := {
	"stink": [Cosmetics.Fx.PUFF, "9be36a"], "tickle": [Cosmetics.Fx.FEATHER, "fff6dd"], "itch": [Cosmetics.Fx.SPARK, "ffb21f"],
	"stun": [Cosmetics.Fx.STAR, "ffd23f"], "freeze": [Cosmetics.Fx.SNOW, "bff3ff"], "root": [Cosmetics.Fx.RING, "c9b95c"],
	"slow": [Cosmetics.Fx.DROP, "62e0a0"], "slip": [Cosmetics.Fx.RING, "bff3ff"], "reverse": [Cosmetics.Fx.SPARK, "b768ff"],
	"fear": [Cosmetics.Fx.DROP, "9fe6ff"], "blind": [Cosmetics.Fx.DROP, "0a1426"], "stale": [Cosmetics.Fx.PUFF, "8a8a6a"],
	"overcharge": [Cosmetics.Fx.BOLT, "fff176"], "firetrail": [Cosmetics.Fx.FLAME, "ff7a1f"], "chain": [Cosmetics.Fx.BOLT, "7ee8ff"],
	"speed": [Cosmetics.Fx.PUFF, "ffffff"], "speed2": [Cosmetics.Fx.PUFF, "ffffff"], "dashboost": [Cosmetics.Fx.BOLT, "35d07f"],
	"fastcap": [Cosmetics.Fx.STAR, "ffc21f"],
	"sleep": [Cosmetics.Fx.ZZZ, "bfeeff"], "dance": [Cosmetics.Fx.NOTE, "ff6fb5"], "charging": [Cosmetics.Fx.SPARK, "7ee8ff"], "turbo": [Cosmetics.Fx.PUFF, "ffffff"],
	"moon": [Cosmetics.Fx.STAR, "fff176"], "mini": [Cosmetics.Fx.SPARK, "ffffff"], "potato": [Cosmetics.Fx.FLAME, "ff9d2e"], "angel": [Cosmetics.Fx.STAR, "ffffff"],
}

var sim: Sim
var local_id := -1
var my_team := 0
var fx: FxField
var camera: Camera3D
var low_detail := false
var tag_bots := false  ## Online, AI players say so over their heads.
var film := false  ## A map's film in a menu: no name tags, and whoever's filming moves the camera.
var film_look := Vector3.ZERO

var _avatars: Array[Avatar3D] = []
var _rings: Array[MeshInstance3D] = []
var _markers: Array[Sprite3D] = []
var _labels: Array[Label3D] = []
var _shields: Array[MeshInstance3D] = []
var _ices: Array[MeshInstance3D] = []
var _shadows: Array[MeshInstance3D] = []
var _status_cd := PackedFloat32Array()
var _shown_pos: Array[Vector3] = []
var _crystal_born := {}  ## Crystal uid -> when it appeared, for the pop.
var _crystal_warnings := {}  ## Crystal uid -> the "!" over a fake one, for the team that left it.
var _crystal_gems: MultiMesh
var _crystal_marks: Array[MultiMesh] = []  ## Shield, target.
var _crystal_rings: Array[MultiMesh] = []
static var _zone_meshes := {}
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
var _pets: Array = []  # Each player's Pet3D, or null.
var _flag_icons: Array = []  # The little flag beside each name, or null.
var _chickens := {}
var _status_props := {}  # [player, kind] -> a node shown only while they have that status.
var _spikes: MeshInstance3D
var _crumble_slabs := {}
var _arm_nodes: Array = []
var _lane_nodes: Array = []
var _lane_warns: Array = []
var _geyser_jets := {}
var _crate_nodes := {}
var _stone_nodes := {}
var _web_nodes := {}
var _tide_water: MeshInstance3D
var _spikes_were_up := false
var weather_view: WeatherView
var _env: Environment


func setup(p_sim: Sim, p_local_id: int) -> void:
	for step: Callable in setup_steps(p_sim, p_local_id):
		step.call()


## The work of setup() in pieces, for a caller that keeps something moving on screen in between. Run them in order.
func setup_steps(p_sim: Sim, p_local_id: int) -> Array[Callable]:
	sim = p_sim
	local_id = p_local_id
	var me := sim.player_by_id(local_id)
	my_team = me.team if me else 0
	low_detail = Quality.is_low()
	_theme_id = Maps.by_id(sim.map_id)["theme"]
	_status_cd.resize(sim.players.size())
	var steps: Array[Callable] = [_build_arena, _build_gates, _build_fountains, _build_hazards.bind(Maps.THEMES[_theme_id]), _build_sky_and_camera, _build_shared_meshes]
	for p: Sim.Player in sim.players:
		steps.append(_build_player.bind(p))
	steps.append(_build_base_markers)
	steps.append(_build_weather)
	return steps


func _build_arena() -> void:
	var arena_node := ArenaBuilder.build(sim, low_detail)
	add_child(arena_node)
	var grass_node := arena_node.get_node_or_null("Grass") as MeshInstance3D
	if grass_node:
		_grass_mat = grass_node.material_override


func _build_sky_and_camera() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(Maps.THEMES[_theme_id]["sky"])
	_env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_env := WorldEnvironment.new()
	world_env.environment = _env
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


func _build_weather() -> void:
	weather_view = WeatherView.new()
	add_child(weather_view)
	weather_view.setup(self, _env, low_detail)
	_portrait = get_viewport().get_visible_rect().size.y > get_viewport().get_visible_rect().size.x
	_reset_camera()


func _build_shared_meshes() -> void:
	_ring_mesh = QuadMesh.new()
	_ring_mesh.orientation = PlaneMesh.FACE_Y
	_ring_mesh.size = Vector2.ONE
	_build_crystals()
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


## Every crystal on the field at one go. There can be a lot of them, and this keeps them to a handful of draw calls.
func _build_crystals() -> void:
	_crystal_gems = _crystal_layer(Crystal.mesh(), Crystal.material())
	for icon_name: String in ["mode_defend", "mode_attack"]:
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE * 1.05
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_texture = UiKit.icon_texture(icon_name)
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.billboard_keep_scale = true
		mat.no_depth_test = true
		mat.render_priority = 1
		_crystal_marks.append(_crystal_layer(quad, mat))
	if not low_detail:
		for color: Color in [Color("7ec8ff"), Color("ff8a78")]:
			var disc := QuadMesh.new()
			disc.orientation = PlaneMesh.FACE_Y
			disc.size = Vector2.ONE * 1.9
			_crystal_rings.append(_crystal_layer(disc, _disc_material(color, 3.0, 0.3, 2.5)))


func _crystal_layer(mesh: Mesh, mat: Material) -> MultiMesh:
	var layer := MultiMesh.new()
	layer.transform_format = MultiMesh.TRANSFORM_3D
	layer.mesh = mesh
	layer.instance_count = MAX_CRYSTALS
	layer.visible_instance_count = 0
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = layer
	inst.material_override = mat
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	inst.extra_cull_margin = 200.0
	add_child(inst)
	return layer


## A piece of a zone, drawn once however many there are.
func _zone_mesh(key: String, draw_it: Callable) -> MeshInstance3D:
	if not _zone_meshes.has(key):
		var k := MeshKit.new()
		k.soften = true
		k.shells = false
		k.outline = 0.02
		k.detail = 0.8
		draw_it.call(k)
		_zone_meshes[key] = k.to_mesh()
	var inst := MeshInstance3D.new()
	inst.mesh = _zone_meshes[key]
	inst.material_override = Avatar3D._material("normal")
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return inst


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


func _build_player(p: Sim.Player) -> void:
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
	label.outline_modulate = Color("0a1426")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 1
	label.fixed_size = false
	add_child(label)
	_labels.append(label)
	_add_pet_and_flag(p, av)
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


func _add_pet_and_flag(p: Sim.Player, av: Avatar3D) -> void:
	var pet_id := str(p.look.get("pet", ""))
	# On a slow device, only your own: ten pets is a lot of extra triangles.
	if pet_id != "" and not Cosmetics.item("pet", pet_id).is_empty() and (not low_detail or p.id == local_id):
		var pet := Pet3D.new()
		add_child(pet)
		pet.setup(pet_id)
		pet.position = av.position + Vector3(1.0, 0, 0.5)
		pet.scale = Vector3.ONE * 1.15
		_pets.append(pet)
	else:
		_pets.append(null)
	var flag_id := str(p.look.get("flag", ""))
	if flag_id != "" and not Cosmetics.item("flag", flag_id).is_empty():
		var icon := Sprite3D.new()
		icon.texture = Flags.texture(flag_id)
		icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		icon.no_depth_test = true
		icon.pixel_size = 0.0058
		icon.render_priority = 1
		add_child(icon)
		_flag_icons.append(icon)
	else:
		_flag_icons.append(null)


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
		jail_label.outline_modulate = Color("0a1426")
		jail_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		jail_label.position = Vector3(sim.jail[team].x, 2.4, sim.jail[team].y - Sim.JAIL_R)
		add_child(jail_label)
		_jail_labels.append(jail_label)


# --- Camera ---------------------------------------------------------------------------------------

## The stick's "up" in world space: the arena turns so your enemy's base is always ahead of you.
func view_yaw() -> float:
	return _cam_yaw


## What the camera's looking at, on the ground.
func look_target() -> Vector3:
	return film_look if film else _cam_target


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
	_update_hazards(delta)
	_update_bushes()
	_update_bases()
	_update_emotes(delta)
	if not film:
		_follow_camera(delta)
	_tick_timer_sound()


func _hidden_to_me(p: Sim.Player) -> bool:
	return sim.is_hidden_from(p, my_team) and not film


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
		elif sim.has_status(p, "tiny") or sim.has_status(p, "mini"):
			scale *= 0.6
		av.scale = av.scale.lerp(Vector3.ONE * scale, clampf(delta * 8.0, 0.0, 1.0))
		var is_moving := speed > 0.6
		av.moving = clampf(speed / Sim.SPEED, 0.0, 1.0)
		av.state = _anim_state(p, airborne, is_moving)
		var hidden := _hidden_to_me(p)
		var clucking := sim.has_status(p, "chicken") and not hidden
		var rolling := sim.has_status(p, "roll") and not hidden
		av.visible = not hidden and not clucking and not rolling
		var lifted := 0.0
		if sim.has_status(p, "carpet"):
			lifted = 0.42 + sin(Time.get_ticks_msec() * 0.005) * 0.05
		elif sim.has_status(p, "bubble"):
			lifted = 0.9 + sin(Time.get_ticks_msec() * 0.004) * 0.08
		av.position.y = shown.y + lifted
		_update_status_props(i, p, shown, scale, hidden, delta)
		_update_pet(i, p, shown, is_moving, hidden, delta)
		if _flag_icons[i]:
			var icon: Sprite3D = _flag_icons[i]
			icon.visible = not hidden and not film
			var text_w := UiKit.font_body().get_string_size(_labels[i].text, HORIZONTAL_ALIGNMENT_LEFT, -1, 40).x * _labels[i].pixel_size
			icon.position = shown + Vector3(0, 2.05 * scale + 0.1, 0) - camera.global_transform.basis.x * (text_w * 0.5 + 0.42)
		_shadows[i].visible = not hidden and not airborne
		_shadows[i].position = Vector3(shown.x, 0.02, shown.z)
		_labels[i].visible = not hidden and not film
		_labels[i].position = shown + Vector3(0, 2.05 * scale + 0.1, 0)
		_rings[i].visible = not hidden and p.state == Sim.State.PLAY
		_rings[i].position = Vector3(shown.x, 0.04, shown.z)
		_update_material(p, av)
		_update_marker(i, p, me, shown, scale, hidden)
		_shields[i].visible = not hidden and (sim.has_status(p, "shield") or sim.has_status(p, "mirror") or sim.has_status(p, "bubble"))
		if _shields[i].visible:
			_shields[i].position = shown + Vector3(0, lifted, 0)
			_shields[i].scale = Vector3.ONE * scale * (1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.03)
			(_shields[i].material_override as ShaderMaterial).set_shader_parameter("tint", Color("fff3a8") if sim.has_status(p, "mirror") else Color("ffffff"))
		_ices[i].visible = not hidden and sim.has_status(p, "freeze")
		_ices[i].position = shown
		if not hidden and p.state == Sim.State.PLAY:
			av.emit_effects(fx, delta, is_moving and not airborne)
			if sim.is_charged(p) and randf() < delta * 16.0:
				fx.spawn(shown + Vector3(randf_range(-0.6, 0.6), randf_range(0.4, 1.8), randf_range(-0.6, 0.6)), Vector3(0, 1.2, 0), 0.5, 0.28, Cosmetics.Fx.STAR, Color("ffd23f"), 2.0)
		_status_particles(i, p, shown, delta, hidden)


func _anim_state(p: Sim.Player, airborne: bool, is_moving: bool) -> String:
	if sim.phase == Sim.Phase.END:
		return "dance" if p.team == sim.winner else "sad"
	if p.state == Sim.State.JAIL:
		return "jail"
	if airborne:
		return "air"
	if sim.has_status(p, "dance") or sim.has_status(p, "tickle"):
		return "dance"
	if sim.has_status(p, "itch") and sim.is_held(p):
		return "root"
	if sim.has_status(p, "freeze"):
		return "freeze"
	if sim.has_status(p, "stun") or sim.has_status(p, "sleep"):
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
	if p.id == local_id:  # Your own ring: green when you're the hunter, red when you're the hunted.
		var ring_color := Color("ffd23f") if sim.is_charged(p) else (Color("3bff7a") if sim.on_home_side(p) else Color("ff3f5a"))
		(_rings[i].material_override as ShaderMaterial).set_shader_parameter("color", ring_color)
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


func _update_pet(i: int, p: Sim.Player, shown: Vector3, is_moving: bool, hidden: bool, delta: float) -> void:
	if _pets[i] == null:
		return
	var pet: Pet3D = _pets[i]
	pet.visible = not hidden
	var facing := Vector3(p.face.x, 0, p.face.y)
	pet.follow(delta, Vector3(shown.x, 0, shown.z), facing, is_moving, fx if not hidden else null)


## Things that only show while a status lasts: a carpet under you, orbs round you, a hot potato over your head.
func _update_status_props(i: int, p: Sim.Player, shown: Vector3, scale: float, hidden: bool, delta: float) -> void:
	var now := Time.get_ticks_msec() * 0.001
	for kind: String in ["carpet", "orbit", "potato", "angel", "roll", "chicken", "sleep"]:
		var on := sim.has_status(p, kind) and not hidden and p.state == Sim.State.PLAY
		var key := i * 16 + ["carpet", "orbit", "potato", "angel", "roll", "chicken", "sleep"].find(kind)
		if not on:
			if _status_props.has(key):
				(_status_props[key] as Node3D).visible = false
			continue
		if not _status_props.has(key):
			_status_props[key] = _make_status_prop(kind)
		var node: Node3D = _status_props[key]
		node.visible = true
		node.position = shown
		match kind:
			"carpet":
				node.rotation.y = _avatars[i].rotation.y
				node.position.y = 0.34 + sin(now * 5.0) * 0.05
			"orbit":
				node.rotation.y = now * 4.0
			"potato":
				node.position.y = shown.y + 2.2 * scale + sin(now * 9.0) * 0.08
				node.rotation.z = sin(now * 13.0) * 0.3
				if randf() < delta * 10.0:
					fx.spawn(node.position + Vector3(0, 0.3, 0), Vector3(0, 1.0, 0), 0.5, 0.26, Cosmetics.Fx.PUFF, Color("ffffff"))
			"angel":
				node.position.y = shown.y + 2.05 * scale
				node.rotation.y = now * 2.0
			"roll":
				node.position.y = 0.85
				node.rotation.x = now * 16.0
				node.rotation.y = _avatars[i].rotation.y
			"chicken":
				node.rotation.y = _avatars[i].rotation.y
				var pet := node as Pet3D
				pet.idle(delta * (3.0 if p.vel.length() > 1.0 else 1.0))


func _make_status_prop(kind: String) -> Node3D:
	if kind == "chicken":
		var bird := Pet3D.new()
		add_child(bird)
		bird.setup("rooster")
		bird.scale = Vector3.ONE * 2.1
		return bird
	var k := MeshKit.new()
	k.soften = true
	k.shells = false
	k.outline = 0.02
	k.detail = 0.8
	match kind:
		"carpet":
			k.soft_box(Vector3.ZERO, Vector3(0.82, 0.05, 1.1), Color("c9302a"), 0.5, 4, 12)
			k.outline = 0.0
			k.soft_box(Vector3(0, 0.03, 0), Vector3(0.62, 0.05, 0.9), Color("ffc21f"), 0.5, 3, 10)
			k.soft_box(Vector3(0, 0.05, 0), Vector3(0.42, 0.05, 0.7), Color("2f4fd0"), 0.5, 3, 10)
			k.outline = 0.02
			for s: float in [-0.6, -0.2, 0.2, 0.6]:
				k.ball(Vector3(s, 0, 1.18), Vector3(0.05, 0.03, 0.1), Color("ffc21f"), 3, 6)
				k.ball(Vector3(s, 0, -1.18), Vector3(0.05, 0.03, 0.1), Color("ffc21f"), 3, 6)
		"orbit":
			for i in 3:
				var a := TAU * i / 3.0
				k.ball(Vector3(cos(a) * 1.5, 0.95, sin(a) * 1.5), Vector3(0.3, 0.3, 0.3), [Color("7ee8ff"), Color("ffd23f"), Color("ff6fb5")][i], 8, 12)
		"potato":
			k.ball(Vector3.ZERO, Vector3(0.36, 0.28, 0.3), Color("d9a066"), 8, 12)
			k.ball(Vector3(0.14, 0.1, 0.24), Vector3(0.04, 0.04, 0.03), Color("7a4a26"), 3, 6)
			k.ball(Vector3(-0.14, 0.04, 0.26), Vector3(0.04, 0.04, 0.03), Color("7a4a26"), 3, 6)
			k.tube(PackedVector3Array([Vector3(0, 0.26, 0), Vector3(0.03, 0.42, 0), Vector3(0.12, 0.5, 0)]), 0.02, Color("3a4258"), false, 5)
			k.ball(Vector3(0.12, 0.54, 0), Vector3(0.08, 0.1, 0.08), Color("ffb52e"), 4, 7)
		"angel":
			k.torus(Vector3.ZERO, 0.4, 0.06, Color("fff176"), 20, 8)
		"roll":
			k.ball(Vector3.ZERO, Vector3(0.95, 0.95, 0.95), Color("2b3a5a"), 10, 16)
			k.outline = 0.0
			for a: float in [0.0, 1.57, 3.14, 4.71]:
				k.ball(Vector3(cos(a), sin(a), 0) * 0.7, Vector3(0.22, 0.22, 0.72), Color("ffd23f"), 4, 8)
			k.outline = 0.02
		"sleep":
			k.outline = 0.0
			k.ball(Vector3(0, 0.1, 0), Vector3.ONE * 0.01, Color.WHITE, 2, 4)
			k.outline = 0.02
	var node := _toon_mesh(k)
	add_child(node)
	return node


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


## Each crystal shows what it'll be for you: on your side of the line a shield, over the line a target.
func _update_pickups(_delta: float) -> void:
	var seen := {}
	var now := Time.get_ticks_msec() * 0.001
	var gems := 0
	var marks := [0, 0]
	var middle := sim.arena_size().x * 0.5
	for item: Dictionary in sim.pickups:
		if gems >= MAX_CRYSTALS:
			break
		var uid: int = item["uid"]
		seen[uid] = true
		var at: Vector2 = item["pos"]
		if not _crystal_born.has(uid):
			_crystal_born[uid] = now
			fx.burst(Vector3(at.x, 1.0, at.y), 10, 3.5, 0.45, 0.3, Cosmetics.Fx.SPARK, Crystal.COLOURS, 2.0)
			if item.has("trap") and int(item["trap"]) == my_team:
				_crystal_warnings[uid] = _crystal_warning(at)
		var pop := clampf((now - float(_crystal_born[uid])) / 0.28, 0.0, 1.0)
		var grow := 1.0 + 2.2 * pow(pop - 1.0, 3.0) + 1.2 * pow(pop - 1.0, 2.0) if pop > 0.0 else 0.05  # Overshoots a little as it lands.
		var y := 0.55 + sin(now * 3.0 + uid) * 0.12
		_crystal_gems.set_instance_transform(gems, Transform3D(Basis(Vector3.UP, now * 1.6 + uid).scaled(Vector3.ONE * 1.12 * grow), Vector3(at.x, y + 0.62, at.y)))
		var side := 0 if (at.x < middle) == (my_team == 0) else 1
		_crystal_marks[side].set_instance_transform(marks[side], Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * grow), Vector3(at.x, y + 1.6, at.y)))
		if not _crystal_rings.is_empty():
			_crystal_rings[side].set_instance_transform(marks[side], Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * grow), Vector3(at.x, 0.05, at.y)))
		gems += 1
		marks[side] += 1
	_crystal_gems.visible_instance_count = gems
	for side in 2:
		_crystal_marks[side].visible_instance_count = marks[side]
		if not _crystal_rings.is_empty():
			_crystal_rings[side].visible_instance_count = marks[side]
	if _crystal_born.size() != seen.size():
		for uid: int in _crystal_born.keys():
			if not seen.has(uid):
				_crystal_born.erase(uid)
				if _crystal_warnings.has(uid):
					(_crystal_warnings[uid] as Node).queue_free()
					_crystal_warnings.erase(uid)


## Your own team can tell it's a fake.
func _crystal_warning(at: Vector2) -> Label3D:
	var warning := Label3D.new()
	warning.text = "!"
	warning.font = UiKit.font_title()
	warning.font_size = 96
	warning.outline_size = 26
	warning.outline_modulate = UiKit.INK
	warning.pixel_size = 0.0072
	warning.modulate = Color("ff5a4e")
	warning.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	warning.no_depth_test = true
	warning.render_priority = 2
	warning.position = Vector3(at.x, 1.3, at.y)
	add_child(warning)
	return warning


func _update_zones() -> void:
	var seen := {}
	for z: Dictionary in sim.zones:
		var uid: int = z["uid"]
		var hidden_trap: bool = z["fx"] in ["mine", "snare", "whoopee"] and int(z["team"]) != my_team and float(sim.radar[my_team]) <= sim.t
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
		else:
			_animate_zone(z, node, at)
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
		"meteor", "anvil", "strike":
			color = Color("ff3f3f")
			style = 3.0
			spin = 3.0
			inner = 0.3
		"smoke":
			color = Color("d7d2ff")
			inner = 0.5
		"portal":
			color = ArenaBuilder.team_color(int(z["team"]))
			style = 3.0
			spin = 5.0
			inner = 0.6
		"cloud", "bees":
			color = Color(0, 0, 0, 0.0)
		"peel":
			color = Color("ffe05c")
			inner = 0.12
		"fart":
			color = Color("9be36a")
			inner = 0.5
		"poop":
			color = Color("8a5a2b")
			inner = 0.1
		"whoopee":
			color = Color("ff6fb5")
			inner = 0.1
		"beam", "tide":
			color = Color(0, 0, 0, 0.0)
	var node := Node3D.new()
	add_child(node)
	var plain_on_a_phone: bool = low_detail and String(z["fx"]) in ["peel", "poop", "whoopee", "mine", "snare"]  # They're easy to see, and there can be a lot of them.
	if String(z["fx"]) not in ["beam", "tide", "cloud", "bees"] and not plain_on_a_phone:
		node.add_child(_flat_quad(_disc_material(color, style, inner, spin), float(z["r"]) * 2.0, 0.0))
	_dress_zone(z, node)
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


## The bodies of the newer zones. Anything that moves gets moved in _animate_zone.
func _dress_zone(z: Dictionary, node: Node3D) -> void:
	var k := MeshKit.new()
	k.soften = true
	k.shells = false
	k.outline = 0.02
	k.detail = 0.8
	match String(z["fx"]):
		"beam":
			var aim: Vector2 = z["aim"]
			node.rotation.y = atan2(aim.x, aim.y)
			var length := float(z["len"])
			var warn := MeshInstance3D.new()
			warn.mesh = _ring_mesh
			var warn_mat := StandardMaterial3D.new()
			warn_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			warn_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			warn_mat.albedo_color = Color(1.0, 0.25, 0.3, 0.42)
			warn_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
			warn.material_override = warn_mat
			warn.scale = Vector3(float(z["r"]) * 2.0, 1.0, length)
			warn.position = Vector3(0, 0.05, length * 0.5)
			warn.name = "Warn"
			node.add_child(warn)
			var beam_kit := MeshKit.new()
			beam_kit.outline = 0.0
			beam_kit.soften = true
			beam_kit.shells = false
			beam_kit.ball(Vector3(0, 1.0, length * 0.5), Vector3(float(z["r"]), float(z["r"]), length * 0.52), Color("3aa6ff"), 6, 14)
			var beam := _toon_mesh(beam_kit)
			beam.name = "Beam"
			beam.visible = false
			node.add_child(beam)
			var core_kit := MeshKit.new()
			core_kit.outline = 0.0
			core_kit.soften = true
			core_kit.shells = false
			core_kit.ball(Vector3(0, 1.0, length * 0.5), Vector3(float(z["r"]) * 0.58, float(z["r"]) * 0.58, length * 0.53), Color("ffffff"), 6, 12)
			var core := _toon_mesh(core_kit)
			core.name = "Core"
			core.visible = false
			node.add_child(core)
		"tide":
			var half := sim.arena_size().y * 0.5 + 2.0
			k.outline = 0.0
			k.ball(Vector3(0, 0.7, 0), Vector3(float(z["r"]), 1.9, half), Color("2a8fe8"), 6, 18)
			k.ball(Vector3(signf((z["drift"] as Vector2).x) * float(z["r"]) * 0.6, 1.8, 0), Vector3(float(z["r"]) * 0.5, 0.6, half), Color("eaf8ff"), 5, 16)
			var wave := _toon_mesh(k)
			node.add_child(wave)
		"poop":
			node.add_child(_zone_mesh("poop", _draw_poop))
		"whoopee":
			node.add_child(_zone_mesh("whoopee", _draw_whoopee))
		"fart":
			var ghost := ShaderMaterial.new()
			ghost.shader = preload("res://gfx/shaders/ghost.gdshader")
			ghost.set_shader_parameter("alpha", 0.5)
			ghost.set_shader_parameter("tint", Color("9be36a"))
			var cloud := _zone_mesh("fart", _draw_fart)
			cloud.scale = Vector3.ONE * float(z["r"])
			cloud.material_override = ghost
			node.add_child(cloud)
		"smoke":
			var r := float(z["r"])
			var ghost := ShaderMaterial.new()
			ghost.shader = preload("res://gfx/shaders/ghost.gdshader")
			ghost.set_shader_parameter("alpha", 0.72)
			ghost.set_shader_parameter("tint", Color("efeaff"))
			k.outline = 0.0
			for i in 9:
				var a := TAU * i / 9.0
				k.ball(Vector3(cos(a) * r * 0.62, 0.7, sin(a) * r * 0.62), Vector3.ONE * r * 0.42, Color.WHITE, 5, 9)
			k.ball(Vector3(0, 1.1, 0), Vector3.ONE * r * 0.56, Color.WHITE, 6, 10)
			var cloud := _toon_mesh(k)
			cloud.material_override = ghost
			node.add_child(cloud)
		"cloud":
			for at: Vector3 in [Vector3(-0.46, 0, 0), Vector3(0.46, 0, 0), Vector3(0, 0.2, 0), Vector3(0, 0, 0.3)]:
				k.ball(at, Vector3(0.56, 0.42, 0.5), Color("6a7aa0"), 6, 10)
			var cloud := _toon_mesh(k)
			cloud.position.y = 3.3
			node.add_child(cloud)
		"anvil":
			k.soft_box(Vector3(0, 0.46, 0), Vector3(0.62, 0.14, 0.36), Color("3a4258"), 0.6, 4, 10)
			k.soft_box(Vector3(0, 0.22, 0), Vector3(0.26, 0.16, 0.3), Color("3a4258"), 0.6, 4, 10)
			k.soft_box(Vector3(0, 0.05, 0), Vector3(0.5, 0.08, 0.36), Color("2b3a5a"), 0.6, 4, 10)
			var iron := _zone_mesh("cow", _draw_cow) if z["pw"] == "cow_drop" else _toon_mesh(k)
			iron.name = "Falling"
			node.add_child(iron)
		"strike":
			var fall_fx := String(Weather.def(sim.weather).get("strike_fx", "bolt"))
			if fall_fx != "bolt":
				k.ball(Vector3.ZERO, Vector3.ONE * 0.62, Color("eaf8ff") if fall_fx == "hail" else Color("5a3a2a"), 7, 10)
				if fall_fx != "hail":
					k.outline = 0.0
					k.ball(Vector3(0.2, 0.2, 0.3), Vector3.ONE * 0.2, Color("ff9d2e"), 3, 6)
					k.outline = 0.02
				var rock := _toon_mesh(k)
				rock.name = "Falling"
				node.add_child(rock)
		"peel":
			for a: float in [0.0, 2.1, 4.2]:
				k.push(Transform3D(Basis(Vector3.UP, a), Vector3.ZERO))
				k.ball(Vector3(0.28, 0.06, 0), Vector3(0.3, 0.06, 0.13), Color("ffe05c"), 6, 9)
				k.pop()
			k.cone(Vector3(0, 0.05, 0), 0.34, 0.12, Color("ffd23f"), 8)
			node.add_child(_toon_mesh(k))
		"portal":
			k.outline = 0.0
			var team := ArenaBuilder.team_color(int(z["team"]))
			k.push(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 1.1, 0)))
			k.torus(Vector3.ZERO, 0.92, 0.1, team, 22, 6)
			k.pop()
			k.ball(Vector3(0, 1.1, 0), Vector3(0.84, 0.84, 0.05), Color("1c1040"), 6, 16)
			k.ball(Vector3(0, 1.1, 0.02), Vector3(0.44, 0.44, 0.05), team.lightened(0.3), 5, 12)
			node.add_child(_toon_mesh(k))


func _draw_poop(k: MeshKit) -> void:
	k.ball(Vector3(0, 0.13, 0), Vector3(0.42, 0.15, 0.42), Color("8a5a2b"), 6, 12)
	k.ball(Vector3(0, 0.33, 0), Vector3(0.3, 0.13, 0.3), Color("9c6a35"), 6, 12)
	k.ball(Vector3(0, 0.5, 0), Vector3(0.18, 0.11, 0.18), Color("8a5a2b"), 6, 10)
	k.cone(Vector3(0.02, 0.56, 0), 0.2, 0.09, Color("9c6a35"), 7)
	k.outline = 0.0
	for s: float in [-1.0, 1.0]:
		k.ball(Vector3(s * 0.1, 0.36, 0.26), Vector3(0.075, 0.09, 0.03), Color.WHITE, 4, 8)
		k.ball(Vector3(s * 0.1, 0.35, 0.285), Vector3(0.036, 0.045, 0.02), Color("1a1030"), 3, 6)


func _draw_whoopee(k: MeshKit) -> void:
	k.ball(Vector3(0, 0.1, 0), Vector3(0.6, 0.13, 0.5), Color("ff6fb5"), 6, 14)
	k.ball(Vector3(0, 0.08, 0.58), Vector3(0.14, 0.05, 0.16), Color("e8488f"), 4, 8)


## Made one unit across, and scaled to fit.
func _draw_fart(k: MeshKit) -> void:
	k.outline = 0.0
	for i in 7:
		var a := TAU * i / 7.0
		k.ball(Vector3(cos(a) * 0.6, 0.14, sin(a) * 0.6), Vector3.ONE * 0.38, Color.WHITE, 5, 8)
	k.ball(Vector3(0, 0.2, 0), Vector3.ONE * 0.5, Color.WHITE, 5, 9)


## A cow, legs out, on its way down.
func _draw_cow(k: MeshKit) -> void:
	k.ball(Vector3(0, 0.75, 0), Vector3(0.95, 0.6, 0.6), Color("fffdf4"), 8, 14)
	k.ball(Vector3(1.05, 1.05, 0), Vector3(0.42, 0.38, 0.38), Color("fffdf4"), 7, 12)
	k.ball(Vector3(1.32, 0.96, 0), Vector3(0.2, 0.18, 0.26), Color("ffb3b3"), 5, 8)
	k.outline = 0.0
	k.ball(Vector3(0.2, 1.2, 0.2), Vector3(0.36, 0.2, 0.34), Color("1a1030"), 5, 10)
	k.ball(Vector3(-0.5, 0.8, 0.46), Vector3(0.3, 0.26, 0.16), Color("1a1030"), 5, 8)
	k.ball(Vector3(1.14, 1.2, 0.3), Vector3(0.07, 0.09, 0.05), Color("1a1030"), 3, 6)
	k.ball(Vector3(1.14, 1.2, -0.3), Vector3(0.07, 0.09, 0.05), Color("1a1030"), 3, 6)
	k.outline = 0.02
	for x: float in [-0.55, 0.55]:
		for s: float in [-1.0, 1.0]:
			k.cyl(Vector3(x, 0.0, s * 0.35), 0.4, 0.13, 0.15, Color("fffdf4"), 8)
	k.cone(Vector3(1.0, 1.38, 0.2), 0.2, 0.06, Color("ffd23f"), 6)
	k.cone(Vector3(1.0, 1.38, -0.2), 0.2, 0.06, Color("ffd23f"), 6)


func _animate_zone(z: Dictionary, node: Node3D, at: Vector2) -> void:
	var left: float = float(z["until"]) - sim.t
	match String(z["fx"]):
		"fart":
			if randf() < 0.28:
				var a := randf() * TAU
				var r := float(z["r"]) * randf()
				fx.spawn(Vector3(at.x + cos(a) * r, randf_range(0.4, 1.8), at.y + sin(a) * r), Vector3(0, 0.7, 0), 0.9, 0.7, Cosmetics.Fx.PUFF, Color("9be36a"), 1.0)
		"poop":
			if randf() < 0.05:
				fx.spawn(Vector3(at.x + randf_range(-0.5, 0.5), 0.9, at.y + randf_range(-0.5, 0.5)), Vector3(randf_range(-0.6, 0.6), 0.5, randf_range(-0.6, 0.6)), 0.6, 0.16, Cosmetics.Fx.BEE, Color("1a1030"))
		"beam":
			var fired: bool = sim.t >= float(z["fires"])
			node.get_node("Warn").visible = not fired
			node.get_node("Beam").visible = fired
			node.get_node("Core").visible = fired
			if fired:
				var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.05) * 0.1
				for part: String in ["Beam", "Core"]:
					var beam: Node3D = node.get_node(part)
					beam.scale = Vector3(pulse, pulse, 1.0)
				if randf() < 0.6:
					var aim: Vector2 = z["aim"]
					var along := randf() * float(z["len"])
					fx.spawn(Vector3(at.x + aim.x * along, 1.0, at.y + aim.y * along), Vector3(randf_range(-3, 3), randf_range(0, 4), randf_range(-3, 3)), 0.3, 0.4, Cosmetics.Fx.SPARK, Color("bff3ff"))
			elif randf() < 0.7:
				var a := randf() * TAU
				fx.spawn(Vector3(at.x + cos(a) * 1.5, 1.2, at.y + sin(a) * 1.5), Vector3(-cos(a) * 3.0, 0, -sin(a) * 3.0), 0.4, 0.3, Cosmetics.Fx.SPARK, Color("7ee8ff"))
		"tide":
			node.position = Vector3(at.x, 0.0, sim.arena_size().y * 0.5)
			if randf() < 0.8:
				var z_at := randf_range(0.0, sim.arena_size().y)
				fx.spawn(Vector3(at.x, 1.6, z_at), Vector3(signf((z["drift"] as Vector2).x) * 5.0, 3.0, 0), 0.4, 0.5, Cosmetics.Fx.DROP, Color("eaf8ff"), 0.0, 6.0)
		"bees":
			for _i in 2:
				var a := randf() * TAU
				var r := randf_range(0.3, float(z["r"]))
				fx.spawn(Vector3(at.x + cos(a) * r, randf_range(0.6, 2.0), at.y + sin(a) * r), Vector3(-sin(a), randf_range(-1.0, 1.0), cos(a)) * 3.0, 0.22, 0.34, Cosmetics.Fx.BEE, Color("ffd23f"))
		"cloud":
			if randf() < 0.8:
				fx.spawn(Vector3(at.x + randf_range(-0.7, 0.7), 2.8, at.y + randf_range(-0.5, 0.5)), Vector3(0, -7.0, 0), 0.34, 0.26, Cosmetics.Fx.DROP, Color("7fc4f0"))
		"anvil":
			var iron: Node3D = node.get_node("Falling")
			iron.position.y = 13.0 * clampf(left / 0.32, 0.0, 1.0) if left < 0.32 else 20.0
		"strike":
			var fall: Node3D = node.get_node_or_null("Falling")
			if fall:
				fall.position.y = 15.0 * clampf(left / 0.55, 0.0, 1.0) if left < 0.55 else 30.0
		"portal":
			node.rotation.y = Time.get_ticks_msec() * 0.0009
		"smoke":
			if randf() < 0.2:
				var a := randf() * TAU
				fx.spawn(Vector3(at.x + cos(a) * float(z["r"]) * 0.7, 1.4, at.y + sin(a) * float(z["r"]) * 0.7), Vector3(0, 0.5, 0), 0.8, 1.1, Cosmetics.Fx.PUFF, Color("efeaff"))


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
		var going: Vector2 = s["vel"]
		var def_now := Powerups.by_id(s["pw"])
		var model := String(def_now.get("model", s["pw"]))
		match model:
			"homing_missile":
				node.rotation.y = atan2(going.x, going.y)
				fx.spawn(node.position - Vector3(going.x, 0, going.y).normalized() * 0.6, Vector3(0, 0.4, 0), 0.4, 0.34, Cosmetics.Fx.PUFF, Color("ffffff"))
			"boomerang":
				node.rotation.y += delta * 16.0
			"giant_snowball":
				node.scale = Vector3.ONE * float(s["r"]) / 0.55
				node.position.y = float(s["r"]) * 0.9
				node.rotation.x += delta * 6.0
		var color := Powerups.color(s["pw"])
		if model == "giant_snowball":
			if randf() < 0.4:
				fx.spawn(node.position - Vector3(0, float(s["r"]) * 0.7, 0), Vector3(randf_range(-0.6, 0.6), 0.8, randf_range(-0.6, 0.6)), 0.4, 0.3, Cosmetics.Fx.SNOW, Color.WHITE)
		elif randf() < 0.6:
			# A skill leaves a trail of what its hero's made of: flames, bats, little tacos.
			if def_now.has("cell"):
				fx.spawn(node.position, Vector3(randf_range(-0.4, 0.4), 0.3, randf_range(-0.4, 0.4)), 0.42, maxf(float(s["r"]) * 0.8, 0.36), int(def_now["cell"]), Color.WHITE if def_now.has("hero") else color, 2.0)
			else:
				fx.spawn(node.position, Vector3(randf_range(-0.4, 0.4), 0.3, randf_range(-0.4, 0.4)), 0.3, float(s["r"]) * 0.8, Cosmetics.Fx.SOFT, color)
	_erase_missing(_shots, seen)


func _make_shot(s: Dictionary) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	var pw: String = s["pw"]
	var kit := MeshKit.new()
	kit.soften = true
	kit.shells = false
	kit.outline = 0.02
	kit.detail = 0.8
	var r: float = s["r"]
	var color := Powerups.color(pw)
	match String(Powerups.by_id(pw).get("model", pw)):
		"fireball":
			kit.outline = 0.0
			kit.ball(Vector3.ZERO, Vector3.ONE * r, Color("ff7a1f"), 5, 10)
			kit.ball(Vector3(0, 0.05, 0.08), Vector3.ONE * r * 0.62, Color("ffd23f"), 4, 8)
		"stink_bomb":
			kit.ball(Vector3.ZERO, Vector3.ONE * r, Color("6fbf3f"), 5, 10)
			kit.cyl(Vector3(0, r * 0.9, 0), 0.22, 0.05, 0.04, Color("3a2a1c"), 6)
		"banana_bomb":
			for a: float in [-0.5, 0.0, 0.5]:
				kit.push(Transform3D(Basis(Vector3.BACK, a), Vector3.ZERO))
				kit.ball(Vector3(0, r * 0.7, 0), Vector3(r * 0.32, r * 0.95, r * 0.32), Color("ffe05c"), 5, 8)
				kit.pop()
		"big_sneeze":
			kit.ball(Vector3.ZERO, Vector3(r, r * 0.55, r), Color("9be36a"), 5, 10)
			kit.ball(Vector3(r * 0.7, 0, 0.3), Vector3.ONE * r * 0.3, Color("9be36a"), 3, 6)
			kit.ball(Vector3(-r * 0.6, 0.1, -0.3), Vector3.ONE * r * 0.26, Color("7ed957"), 3, 6)
		"bubble_gum":
			kit.ball(Vector3.ZERO, Vector3.ONE * r, Color("ff6fb5"), 5, 10)
			kit.outline = 0.0
			kit.ball(Vector3(-r * 0.35, r * 0.4, r * 0.55), Vector3.ONE * r * 0.22, Color.WHITE, 3, 6)
		"lockup":
			kit.torus(Vector3(-r * 0.5, 0, 0), r * 0.5, 0.07, Color("ffd23f"), 12, 5)
			kit.torus(Vector3(r * 0.5, 0, 0), r * 0.5, 0.07, Color("ffd23f"), 12, 5)
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
		"homing_missile":
			kit.ball(Vector3.ZERO, Vector3(0.26, 0.26, 0.62), Color("f4f6ff"), 5, 10)
			kit.ball(Vector3(0, 0, 0.5), Vector3(0.24, 0.24, 0.3), Color("ff5a4e"), 4, 8)
			for a: float in [0.0, 2.09, 4.19]:
				kit.ball(Vector3(cos(a) * 0.28, sin(a) * 0.28, -0.42), Vector3(0.14, 0.14, 0.2), Color("ff5a4e"), 3, 6)
		"boomerang":
			kit.ball(Vector3(0.28, 0, 0.1), Vector3(0.46, 0.07, 0.14), Color("ff9d2e"), 4, 8)
			kit.ball(Vector3(-0.18, 0, 0.28), Vector3(0.14, 0.07, 0.4), Color("ffd23f"), 4, 8)
		"giant_snowball":
			kit.ball(Vector3.ZERO, Vector3.ONE * r, Color("f4fbff"), 6, 10)
			kit.ball(Vector3(r * 0.5, r * 0.5, r * 0.5), Vector3.ONE * r * 0.26, Color("bfeeff"), 3, 6)
		"cream_pie":
			kit.cyl(Vector3(0, -0.14, 0), 0.16, r * 0.9, r * 1.1, Color("d9a066"), 10)
			kit.ball(Vector3(0, 0.08, 0), Vector3(r, r * 0.5, r), Color("fffdf4"), 5, 10)
			kit.ball(Vector3(0, 0.28, 0), Vector3.ONE * 0.11, Color("e8282f"), 3, 6)
		"shrink_ray":
			kit.torus(Vector3.ZERO, r * 0.7, 0.08, Color("ff6fb5"), 12, 4)
			kit.ball(Vector3.ZERO, Vector3.ONE * r * 0.4, Color("ffffff"), 4, 8)
		"bubble_trap":
			kit.outline = 0.0
			kit.ball(Vector3.ZERO, Vector3.ONE * r, Color("bff3ff"), 6, 10)
			kit.ball(Vector3(-r * 0.4, r * 0.4, r * 0.5), Vector3.ONE * r * 0.2, Color("ffffff"), 3, 6)
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
	if ent["type"] == "decoy" or ent["type"] == "clone":
		var owner := sim.player_by_id(int(ent["owner"]))
		var av := Avatar3D.new()
		add_child(av)
		av.setup(owner.look if owner else {}, ArenaBuilder.team_color(int(ent["team"])))
		av.state = "run"
		av.moving = 1.0
		av.scale = Vector3.ONE * AVATAR_SCALE
		av.position = Vector3((ent["pos"] as Vector2).x, 0, (ent["pos"] as Vector2).y)
		if owner:
			var label := Label3D.new()
			label.text = owner.name
			label.font = UiKit.font_body()
			label.font_size = 40
			label.outline_size = 10
			label.pixel_size = 0.008
			label.modulate = Color("c9f1ff") if owner.team == my_team else Color("ffc4bd")
			label.outline_modulate = Color("0a1426")
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.no_depth_test = true
			label.position = Vector3(0, 2.05, 0)
			av.add_child(label)
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


## Everything on the field that moves on its own: built once, moved in _update_hazards.
func _build_hazards(theme: Dictionary) -> void:
	var mat := Avatar3D._material("normal")
	var make := func(mesh: ArrayMesh, tile: int, y := 0.0) -> MeshInstance3D:
		var inst := MeshInstance3D.new()
		inst.mesh = mesh
		inst.material_override = mat
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var at := sim.tile_center(tile)
		inst.position = Vector3(at.x, y, at.y)
		add_child(inst)
		return inst
	var kit := func() -> MeshKit:
		var k := ArenaBuilder.prop_kit(low_detail)
		k.detail = 0.8
		return k
	var spikes_kit: MeshKit = kit.call()
	var crumble_mesh: ArrayMesh = null
	var crate_mesh: ArrayMesh = null
	var stone_mesh: ArrayMesh = null
	var web_mesh: ArrayMesh = null
	var jet_mesh: ArrayMesh = null
	var tide_kit := MeshKit.new()
	tide_kit.outline = 0.0
	for i in sim.w * sim.h:
		var at := sim.tile_center(i)
		match sim.tiles[i]:
			Maps.SPIKES:
				for ix in 3:
					for iy in 3:
						var spot := at + (Vector2(ix, iy) - Vector2.ONE) * Maps.TILE * 0.263
						spikes_kit.cone(Vector3(spot.x, 0.0, spot.y), 0.72, 0.11, Color("e8ecf9"), 8)
			Maps.CRUMBLE:
				if crumble_mesh == null:
					var k: MeshKit = kit.call()
					var tone := Color(theme["floor"][0]).lightened(0.05)
					k.soft_box(Vector3(0, -0.08, 0), Vector3(Maps.TILE * 0.47, 0.11, Maps.TILE * 0.47), tone.darkened(0.12), 0.5, 4, 12)
					k.outline = 0.0
					for path: Array in [[Vector3(-0.6, 0.03, -0.5), Vector3(-0.1, 0.03, -0.1), Vector3(0.1, 0.03, 0.5)], [Vector3(0.7, 0.03, -0.2), Vector3(0.1, 0.03, -0.05)]]:
						k.tube(PackedVector3Array(path), 0.03, Color("2b2448"), false, 3)
					crumble_mesh = k.to_mesh()
				_crumble_slabs[i] = make.call(crumble_mesh, i, 0.03)
			Maps.TNT:
				if crate_mesh == null:
					var k: MeshKit = kit.call()
					k.soft_box(Vector3(0, 0.72, 0), Vector3(0.84, 0.72, 0.84), Color("d8362f"), 0.45, 6, 12)
					k.outline = 0.0
					for f: float in [0.34, 1.1]:
						k.soft_box(Vector3(0, f, 0), Vector3(0.86, 0.1, 0.86), Color("ffc21f"), 0.5, 3, 10)
					k.outline = 0.02
					k.tube(PackedVector3Array([Vector3(0, 1.44, 0), Vector3(0.08, 1.7, 0), Vector3(0.22, 1.82, 0)]), 0.03, Color("3a4258"), false, 5)
					k.ball(Vector3(0.24, 1.86, 0), Vector3(0.09, 0.11, 0.09), Color("ffb52e"), 4, 7)
					crate_mesh = k.to_mesh()
				_crate_nodes[i] = make.call(crate_mesh, i)
			Maps.STONE:
				if stone_mesh == null:
					var k: MeshKit = kit.call()
					k.ball(Vector3(0, -0.04, 0), Vector3(Maps.TILE * 0.47, 0.16, Maps.TILE * 0.47), Color("a8b4c8"), 6, 14)
					k.outline = 0.0
					k.ball(Vector3(-0.2, 0.09, 0.14), Vector3(0.3, 0.04, 0.22), Color("c9d4e6"), 3, 8)
					k.outline = 0.02
					stone_mesh = k.to_mesh()
				_stone_nodes[i] = make.call(stone_mesh, i, 0.03)
			Maps.WEB:
				if web_mesh == null:
					var k: MeshKit = kit.call()
					k.outline = 0.0
					for a in 8:
						var d := Vector3(cos(TAU * a / 8.0), 0, sin(TAU * a / 8.0))
						k.tube(PackedVector3Array([Vector3(0, 0.04, 0), d * 0.92 + Vector3(0, 0.04, 0)]), 0.024, Color("f4f6ff"), false, 3)
					for ring: float in [0.32, 0.62, 0.9]:
						k.torus(Vector3(0, 0.04, 0), ring, 0.016, Color("f4f6ff"), 8, 3)
					k.ball(Vector3(0.2, 0.1, -0.2), Vector3(0.12, 0.09, 0.14), Color("2b2448"), 4, 7)
					web_mesh = k.to_mesh()
				_web_nodes[i] = make.call(web_mesh, i)
			Maps.GEYSER:
				if jet_mesh == null:
					var k := MeshKit.new()
					k.soften = true
					k.shells = false
					k.outline = 0.0
					k.detail = 0.8
					k.ball(Vector3(0, 1.3, 0), Vector3(0.34, 1.3, 0.34), Color("bfeeff"), 7, 10)
					k.ball(Vector3(0, 2.5, 0), Vector3(0.62, 0.34, 0.62), Color("f0fcff"), 5, 10)
					jet_mesh = k.to_mesh()
				var jet: MeshInstance3D = make.call(jet_mesh, i)
				jet.scale = Vector3(1, 0.01, 1)
				_geyser_jets[i] = jet
			Maps.TIDE:
				tide_kit.ground(Rect2(at - Vector2.ONE * Maps.TILE * 0.5, Vector2.ONE * Maps.TILE), 0.0, Color(theme["pit_c"]))
	if not spikes_kit.is_empty():
		_spikes = MeshInstance3D.new()
		_spikes.mesh = spikes_kit.to_mesh()
		_spikes.material_override = mat
		_spikes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_spikes.position.y = -0.9
		add_child(_spikes)
	if not tide_kit.is_empty():
		var water := ShaderMaterial.new()
		water.shader = preload("res://gfx/shaders/water.gdshader")
		water.set_shader_parameter("base_color", Color(theme["pit_c"]))
		water.set_shader_parameter("foam_color", Color("f2fdff"))
		_tide_water = MeshInstance3D.new()
		_tide_water.mesh = tide_kit.to_mesh()
		_tide_water.material_override = water
		_tide_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_tide_water.position.y = -0.3
		add_child(_tide_water)
	for arm: Dictionary in sim.arms:
		var k: MeshKit = kit.call()
		var at: Vector2 = arm["at"]
		var reach := Sim.ARM_REACH
		k.soft_box(Vector3(0, 0.85, 0), Vector3(reach, 0.19, 0.2), Color("ff7a1f"), 0.5, 4, 14)
		k.outline = 0.0
		for s: float in [-0.78, -0.42, 0.42, 0.78]:
			k.soft_box(Vector3(reach * s, 0.85, 0), Vector3(0.28, 0.2, 0.21), Color("fff6dd"), 0.5, 3, 8)
		k.outline = 0.02
		for s: float in [-1.0, 1.0]:
			k.ball(Vector3(s * reach, 0.85, 0), Vector3(0.3, 0.3, 0.3), Color("ffd23f"), 5, 8)
		k.ball(Vector3(0, 1.14, 0), Vector3(0.34, 0.14, 0.34), Color("ffd23f"), 5, 10)
		var inst := MeshInstance3D.new()
		inst.mesh = k.to_mesh()
		inst.material_override = mat
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		inst.position = Vector3(at.x, 0, at.y)
		add_child(inst)
		_arm_nodes.append(inst)
	var lane_prop := String(Maps.theme_info(_theme_id).get("lane", "jeep"))
	for lane: Dictionary in sim.lanes:
		var k: MeshKit = kit.call()
		var scale := 1.0 if lane_prop in ["bullet_train", "red_bus", "taxi", "tuk_tuk", "float", "cart"] else 1.5
		PropKit.draw(k, lane_prop, Vector3.ZERO, 0.0 if lane["down"] else PI, scale, randf(), Color(theme["accent"]))
		var inst := MeshInstance3D.new()
		inst.mesh = k.to_mesh()
		inst.material_override = mat
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(inst)
		_lane_nodes.append(inst)
		var warn := MeshInstance3D.new()
		var warn_mesh := QuadMesh.new()
		warn_mesh.orientation = PlaneMesh.FACE_Y
		warn_mesh.size = Vector2(Maps.TILE, float(lane["y1"]) - float(lane["y0"]))
		warn.mesh = warn_mesh
		var warn_mat := StandardMaterial3D.new()
		warn_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		warn_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		warn_mat.albedo_color = Color(1.0, 0.2, 0.2, 0.0)
		warn_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		warn.material_override = warn_mat
		warn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		warn.position = Vector3(float(lane["x"]), 0.03, (float(lane["y0"]) + float(lane["y1"])) * 0.5)
		add_child(warn)
		_lane_warns.append(warn_mat)


func _update_hazards(delta: float) -> void:
	var now := Time.get_ticks_msec() * 0.001
	if _spikes:
		var up := sim.spikes_up()
		var goal := 0.0 if up else (-0.6 + sin(now * 40.0) * 0.03 if sim.spikes_warning() else -0.9)
		_spikes.position.y = lerpf(_spikes.position.y, goal, clampf(delta * (26.0 if up else 9.0), 0.0, 1.0))
		if up != _spikes_were_up:
			_spikes_were_up = up
			if up:
				Audio.sfx("kill_grave_grab", 0.5)
	for i in _arm_nodes.size():
		(_arm_nodes[i] as Node3D).rotation.y = -sim.arm_angle(sim.arms[i])
	for i in _lane_nodes.size():
		var lane: Dictionary = sim.lanes[i]
		var at := sim.lane_at(lane)
		var node: Node3D = _lane_nodes[i]
		node.position = Vector3(float(lane["x"]), 0.0, at)
		var on_road: bool = at > float(lane["y0"]) - 8.0 and at < float(lane["y1"]) + 8.0
		node.visible = on_road
		(_lane_warns[i] as StandardMaterial3D).albedo_color.a = (0.2 + sin(now * 14.0) * 0.14) if on_road else 0.0
	for tile: int in _crumble_slabs:
		var slab: Node3D = _crumble_slabs[tile]
		var at := sim.tile_center(tile)
		if sim.crumble_gone(tile):
			slab.position.y = lerpf(slab.position.y, -1.4, clampf(delta * 5.0, 0.0, 1.0))
			slab.visible = slab.position.y > -1.2
		else:
			slab.visible = true
			var shake_by := sim.crumble_shake(tile)
			slab.position = Vector3(at.x + sin(now * 50.0 + tile) * 0.05 * shake_by, lerpf(slab.position.y, 0.03, clampf(delta * 6.0, 0.0, 1.0)), at.y + cos(now * 44.0 + tile) * 0.05 * shake_by)
	for tile: int in _crate_nodes:
		(_crate_nodes[tile] as Node3D).visible = sim.tnt_here(tile)
	for tile: int in _web_nodes:
		(_web_nodes[tile] as Node3D).visible = sim.web_here(tile)
	for tile: int in _stone_nodes:
		var stone: Node3D = _stone_nodes[tile]
		var goal := -0.5 if sim.stone_sunk(tile) else (0.03 + sin(now * 18.0) * 0.02 if sim.stone_warning(tile) else 0.03)
		stone.position.y = lerpf(stone.position.y, goal, clampf(delta * 6.0, 0.0, 1.0))
	for tile: int in _geyser_jets:
		var jet: Node3D = _geyser_jets[tile]
		var blowing := sim.geyser_blowing(tile)
		jet.scale.y = lerpf(jet.scale.y, 1.0 if blowing else 0.01, clampf(delta * (22.0 if blowing else 6.0), 0.0, 1.0))
		jet.visible = jet.scale.y > 0.03
		if sim.geyser_warning(tile) and randf() < delta * 14.0:
			var at := sim.tile_center(tile)
			fx.spawn(Vector3(at.x + randf_range(-0.4, 0.4), 0.3, at.y + randf_range(-0.4, 0.4)), Vector3(0, 1.5, 0), 0.4, 0.2, Cosmetics.Fx.RING, Color("eaf8ff"))
	if _tide_water:
		_tide_water.position.y = lerpf(-0.3, 0.06, sim.tide_level())


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
			_float_text(_world(x, y, 2.2), "CHARGED!", Color("ffd23f"))
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
		"reshuffle":
			fx.burst(_world(x, y, 1.4), 12, 3.5, 0.4, 0.3, Cosmetics.Fx.STAR, ["ffd23f", "ffffff"], 1.0)
			if mine:
				Audio.sfx("move_swirl", 0.8)
				Haptics.buzz("power")
				var over := not sim.on_home_side(pa)
				announce.emit("ATTACK DECK!" if over else "DEFENCE DECK!", Color("ff8a78") if over else Color("8fd8ff"), false)
		"splat":
			fx.burst(_world(x, y, 0.5), 16, 4.0, 0.5, 0.4, Cosmetics.Fx.PUFF, ["8a5a2b", "9be36a"], 3.0)
			_float_text(_world(x, y, 2.2), "EWWW!", Color("9be36a"))
			Audio.sfx("squelch", _audible(at2))
			if a >= 0:
				_avatars[a].react("queasy", 2.0)
			if a == local_id:
				shake(0.2)
		"toot":
			fx.burst(_world(x, y, 0.4), 14, 4.0, 0.5, 0.5, Cosmetics.Fx.PUFF, ["9be36a", "ff6fb5"], 1.0)
			_float_text(_world(x, y, 2.2), "PFFFT!", Color("ff6fb5"))
			Audio.sfx("fart_long", maxf(_audible(at2), 0.5))
			if a >= 0:
				_avatars[a].react("flustered", 1.8)
		"cough":
			_float_text(_world(x, y, 2.2), "COUGH!", Color("9be36a"), 0.6)
			if a >= 0:
				_avatars[a].react("queasy", 1.4)
		"word":
			_float_text(_world(x, y, 2.4), String(extra), Color("ffd23f"), 0.85)
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
				var words := {"tickle": "HA HA HA!", "stink": "EWWW!", "stun": "STUNNED!", "freeze": "FROZEN!", "root": "PINNED!", "fear": "PANIC!", "reverse": "CONTROLS FLIPPED!", "blind": "SPLAT! Can't see!", "stale": "CURSED!", "chicken": "BAWK!", "dance": "DANCE!", "sleep": "SO SLEEPY...", "bubble": "BLOOP!", "mini": "TINY!"}
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
		"bonk":
			fx.burst(_world(x, y, 1.0), 10, 5.0, 0.3, 0.34, Cosmetics.Fx.STAR, ["ffd23f", "ffffff"], 2.0)
			if _audible(at2) > 0.6:
				_float_text(_world(x, y, 2.2), "BONK!", Color("ffb21f"))
				Audio.sfx("clash_hit", _audible(at2), 1.2)
			if a >= 0:
				_avatars[a].squash(0.5)
				_avatars[a].react_any(Faces.TAGGED, 0.8)
			if mine:
				shake(0.2)
		"spiked":
			fx.burst(_world(x, y, 0.8), 10, 5.0, 0.35, 0.34, Cosmetics.Fx.STAR, ["ffffff", "ff5a4e"])
			_float_text(_world(x, y, 2.2), "OUCH!", Color("ff8a78"))
			Audio.sfx("clash_hit", _audible(at2))
			if a >= 0:
				_avatars[a].react_any(Faces.TAGGED, 1.0)
				_avatars[a].squash(0.6)
		"crack":
			fx.burst(_world(x, y, 0.1), 6, 2.0, 0.3, 0.3, Cosmetics.Fx.PUFF, ["d8c8a8"], 2.0)
			Audio.sfx("piece_place", _audible(at2) * 0.5, 1.5)
		"crumble":
			fx.burst(_world(x, y, 0.1), 14, 3.0, 0.45, 0.42, Cosmetics.Fx.PUFF, ["d8c8a8", "a89878"], 5.0)
			Audio.sfx("clash_tie", _audible(at2) * 0.6, 0.6)
		"fell":
			fx.burst(_world(x, y, 0.5), 12, 4.0, 0.4, 0.34, Cosmetics.Fx.DROP, ["8fe3ff", "ffffff"], 5.0)
			_float_text(_world(x, y, 2.2), "WHOOPS!", Color("c9f1ff"))
		"geyser":
			fx.burst(_world(x, y, 0.6), 22, 7.0, 0.6, 0.34, Cosmetics.Fx.DROP, ["bfeeff", "ffffff"], 8.0)
			Audio.sfx("aura_water", _audible(at2))
			if a >= 0:
				_avatars[a].react_any(Faces.CHEERING, 1.0)
		"webbed":
			fx.burst(_world(x, y, 0.8), 10, 3.0, 0.35, 0.3, Cosmetics.Fx.RING, ["ffffff"], 1.0)
			_float_text(_world(x, y, 2.2), "STUCK!", Color("ffffff"))
			Audio.sfx("kill_mummy_wrap", _audible(at2) * 0.8)
		"lookout":
			if b == my_team:
				announce.emit("LOOKOUT! Your team can see everyone!", Color("7ee8ff"), false)
			Audio.sfx("trail_warp", _audible(at2) * 0.6)
		"run_over":
			fx.burst(_world(x, y, 1.0), 18, 7.0, 0.45, 0.42, Cosmetics.Fx.STAR, ["ffd23f", "ffffff"])
			_float_text(_world(x, y, 2.4), "BEEP BEEP!", Color("ffd23f"))
			Audio.sfx("taunt_foghorn", _audible(at2) * 0.8)
			if a >= 0:
				_avatars[a].squash(1.0)
				_avatars[a].react_any(Faces.TAGGED, 1.2)
			if mine:
				shake(0.4)
		"angel":
			fx.burst(_world(x, y, 1.0), 22, 6.0, 0.7, 0.36, Cosmetics.Fx.STAR, ["ffffff", "fff176"], 0.0)
			_float_text(_world(x, y, 2.4), "SAVED!", Color("fff176"))
			Audio.sfx("aura_holy", _audible(at2))
		"potato":
			fx.burst(_world(x, y, 2.0), 8, 3.0, 0.3, 0.3, Cosmetics.Fx.FLAME, ["ff9d2e"], 2.0)
			_float_text(_world(x, y, 2.6), "HOT!", Color("ff9d2e"))
			if a == local_id:
				announce.emit("HOT POTATO! Pass it on!", Color("ff9d2e"), false)
		"slipped":
			_float_text(_world(x, y, 2.2), "WHOOPS!", Color("ffe05c"))
			Audio.sfx("taunt_jelly_wobble", _audible(at2) * 0.8)
			if a >= 0:
				_avatars[a].react("dizzy", 1.2)
		"strike":
			_weather_strike_lands(x, y, at2)
		"anvil":
			fx.burst(_world(x, y, 0.2), 20, 6.0, 0.4, 0.45, Cosmetics.Fx.PUFF, ["ffffff", "c9d0e6"], 3.0)
			if extra == "cow_drop":
				_float_text(_world(x, y, 2.2), "MOOO!", Color("ffffff"))
				Audio.sfx("moo", _audible(at2))
			else:
				_float_text(_world(x, y, 2.2), "CLANG!", Color("ffffff"))
			Audio.sfx("kill_giant_stomp", _audible(at2))
			shake(0.4 * _audible(at2))
		"beam":
			Audio.sfx("kill_plasma_blade", _audible(at2))
			shake(0.5)
			if weather_view:
				weather_view.flash(0.25)
		"timestop":
			announce.emit("TIME STOP!", Color("7ee8ff"), true)
			shake(0.3)
			if weather_view:
				weather_view.flash(0.4)
		"stolen":
			_float_text(_world(x, y, 2.4), "MY CARD!", Color("ffc4bd"))
			if a == local_id:
				announce.emit("%s stole your card!" % (pb.name if pb else "Someone"), Color("ffc4bd"), false)
		"weather":
			var def := Weather.def(String(extra))
			announce.emit(String(def["name"]).to_upper(), Color("ffffff"), true)
			feed.emit(String(def["hint"]), Color("c9f1ff"))
			if weather_view:
				weather_view.flash(0.3)
		"refreshed":
			if a >= 0:
				_avatars[a].flash()
				fx.burst(_avatars[a].position + Vector3(0, 1.0, 0), 10, 3.0, 0.4, 0.32, Cosmetics.Fx.SPARK, ["ffffff", "fff176"], 0.0)
		"go":
			Audio.sfx("match_start")
			announce.emit("GO!", Color("8fffb4"), true)
			if sim.weather != "clear":
				var sky := Weather.def(sim.weather)
				announce.emit("%s!" % String(sky["name"]).to_upper(), Color("ffe36b"), false)
				feed.emit(String(sky["hint"]), Color("ffffff"))
		"round":
			announce.emit("GET READY!", Color("ffffff"), true)
		"fiesta":
			Audio.sfx("finale_fiesta")
			Audio.fiesta_time()
			announce.emit("POWER RUSH! Crystals everywhere!", Color("ffd23f"), true)
		"overtime":
			Audio.sfx("timer_urgent")
			announce.emit("SUDDEN DEATH!", Color("ff5a4e"), true)
		"score":
			_on_score(a, b, at2, String(extra))
		"end":
			pass


func _weather_strike_lands(x: float, y: float, at2: Vector2) -> void:
	var kind := String(Weather.def(sim.weather).get("strike_fx", "bolt"))
	match kind:
		"bolt":
			for i in 9:
				fx.spawn(_world(x + sin(i * 2.1) * 0.3, y, 13.0 - i * 1.5), Vector3.ZERO, 0.2, 1.0, Cosmetics.Fx.BOLT, Color("fff176"))
			fx.burst(_world(x, y, 0.8), 14, 5.0, 0.35, 0.38, Cosmetics.Fx.SPARK, ["fff176", "ffffff"], 0.0)
			Audio.sfx("kill_lightning_strike", _audible(at2))
			if weather_view:
				weather_view.flash(0.55)
		"hail":
			fx.burst(_world(x, y, 0.3), 16, 5.0, 0.35, 0.28, Cosmetics.Fx.SNOW, ["ffffff", "bff3ff"], 6.0)
			Audio.sfx("piece_place", _audible(at2))
		_:
			fx.burst(_world(x, y, 0.5), 20, 7.0, 0.5, 0.48, Cosmetics.Fx.FLAME, ["ffb52e", "ff5a1f", "ffffff"])
			Audio.sfx("kill_ka_boom", _audible(at2))
	shake(0.22 * _audible(at2))


func _on_tag(tagger: Sim.Player, tagged: Sim.Player, at2: Vector2) -> void:
	if tagger == null or tagged == null:
		return
	if _pets[tagger.id]:
		(_pets[tagger.id] as Pet3D).cheer()
	if _pets[tagged.id]:
		(_pets[tagged.id] as Pet3D).dizzy()
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
	var has_cell := def.has("cell")
	var colours: Array = [Color.WHITE] if def.has("hero") else [c, "ffffff"]
	fx.burst(_world(at2.x, at2.y, 1.1), 18 if has_cell else 12, 4.5, 0.5, 0.42 if has_cell else 0.34, int(def.get("cell", Cosmetics.Fx.SPARK)), colours, 0.0)
	if p:
		_avatars[p.id].squash(0.25)
		if def.has("skill"):  # Everybody gets to see whose skill that was.
			_float_text(_avatars[p.id].position + Vector3(0, 2.6, 0), String(def["name"]), c.lightened(0.3), 0.55)
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


func _float_text(at: Vector3, text: String, color: Color, size := 1.0) -> void:
	var label := Label3D.new()
	label.text = text
	label.font = UiKit.font_title()
	label.font_size = 72
	label.outline_size = 18
	label.pixel_size = 0.013 * size
	label.modulate = color
	label.outline_modulate = Color("0a1426")
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
	label.outline_modulate = Color("0a1426")
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
