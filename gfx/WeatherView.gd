class_name WeatherView
extends Node
## Everything you see of the weather: what's falling, the light, and the fog or dark that closes in round your team.
## It only reads the Sim, and sets itself up again whenever the weather changes (a Weather Machine can do that mid-match).

var _view: MatchView
var _shown := ""
var _fall: MultiMeshInstance3D
var _fall_mat: ShaderMaterial
var _offset := Vector3.ZERO
var _fall_speed := 0.0
var _sideways := false
var _layer: CanvasLayer
var _tint: ColorRect
var _veil: ColorRect
var _veil_mat: ShaderMaterial
var _flash := 0.0
var _env: Environment
var _sky_plain := Color.WHITE
var _splash_cd := 0.0
var _low := false


func setup(view: MatchView, env: Environment, low_detail: bool) -> void:
	_view = view
	_env = env
	_sky_plain = env.background_color
	_low = low_detail
	_layer = CanvasLayer.new()
	_layer.layer = -1
	add_child(_layer)
	_tint = ColorRect.new()
	_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tint_mat := ShaderMaterial.new()
	tint_mat.shader = preload("res://gfx/shaders/tint_mul.gdshader")
	_tint.material = tint_mat
	_layer.add_child(_tint)
	_veil = ColorRect.new()
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil_mat = ShaderMaterial.new()
	_veil_mat.shader = preload("res://gfx/shaders/weather_veil.gdshader")
	_veil.material = _veil_mat
	_layer.add_child(_veil)
	_fall = MultiMeshInstance3D.new()
	_fall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_fall.custom_aabb = AABB(Vector3(-500, -50, -500), Vector3(1000, 100, 1000))
	_fall_mat = ShaderMaterial.new()
	_fall_mat.shader = preload("res://gfx/shaders/weather.gdshader")
	_fall_mat.set_shader_parameter("atlas", preload("res://assets/fx/atlas.png"))
	_fall.material_override = _fall_mat
	view.add_child(_fall)


func flash(amount := 0.6) -> void:
	_flash = maxf(_flash, amount)


func _apply() -> void:
	_shown = _view.sim.weather
	var def := Weather.def(_shown)
	var tint: Color = Color(def["tint"]) if def.has("tint") else Color.WHITE
	(_tint.material as ShaderMaterial).set_shader_parameter("tint", tint)
	_tint.visible = def.has("tint")
	var veil_color: Color = Color(def["veil"]) if def.has("veil") else Color.WHITE
	veil_color.a = float(def.get("veil_thick", 0.0))
	_veil_mat.set_shader_parameter("veil", veil_color)
	_env.background_color = Color(def["sky"]) if def.has("sky") else _sky_plain
	if not def.has("fall"):
		_fall.visible = false
		return
	var fall: Array = def["fall"]
	var cells := {"streak": Cosmetics.Fx.STREAK, "snow": Cosmetics.Fx.SNOW, "soft": Cosmetics.Fx.SOFT, "puff": Cosmetics.Fx.PUFF, "cherry": Cosmetics.Fx.CHERRY}
	var stretched: bool = fall[0] == "streak"
	_fall_speed = float(fall[1])
	_sideways = def.get("sideways", false)
	_fall_mat.set_shader_parameter("cell", float(cells[fall[0]]))
	_fall_mat.set_shader_parameter("quad_size", Vector2(float(fall[2]), float(fall[3])))
	_fall_mat.set_shader_parameter("stretched", 1.0 if stretched else 0.0)
	var colour: Color = Color(fall[4])
	colour.a = 0.75 if stretched else 0.95
	_fall_mat.set_shader_parameter("tint", colour)
	var count := int(int(def.get("count", 120)) * (0.55 if _low else 1.0))
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = quad
	mm.instance_count = count
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in count:
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(rng.randf(), rng.randf(), rng.randf())))
	_fall.multimesh = mm
	_fall.visible = true


func _process(delta: float) -> void:
	if _view == null or _view.sim == null or _view.camera == null:
		return
	var sim := _view.sim
	if sim.weather != _shown:
		_apply()
	var def := Weather.def(_shown)
	if _fall.visible:
		var wind := Vector3(sim.wind.x, 0.0, sim.wind.y)
		var push := wind * (6.0 if _sideways else 2.6)
		var velocity := Vector3(0, -_fall_speed, 0) + push
		_offset += velocity * delta
		_fall_mat.set_shader_parameter("offset", _offset)
		_fall_mat.set_shader_parameter("center", _view.look_target())
		_fall_mat.set_shader_parameter("stretch_dir", velocity.normalized() if velocity.length() > 0.01 else Vector3.UP)
	_flash = maxf(_flash - delta * 3.2, 0.0)
	_veil_mat.set_shader_parameter("flash", _flash)
	if def.has("veil"):
		_place_holes(sim, def)
	else:
		_veil_mat.set_shader_parameter("holes", PackedVector3Array([Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]))
	_ground_touches(delta)


## Clear circles round everyone on your team, and on a dark night round every crystal, which glow.
func _place_holes(sim: Sim, _def: Dictionary) -> void:
	var view_size := _view.get_viewport().get_visible_rect().size
	_veil_mat.set_shader_parameter("aspect", view_size.x / maxf(view_size.y, 1.0))
	var holes := PackedVector3Array()
	holes.resize(8)
	var count := 0
	var right := _view.camera.global_transform.basis.x
	for p: Sim.Player in sim.team_of(_view.my_team):
		if p.state != Sim.State.PLAY or count >= 5:
			continue
		var reach := sim.sight_range * (1.0 if p.id == _view.local_id else 0.72)
		holes[count] = _hole(Vector3(p.pos.x, 0.5, p.pos.y), reach, right, view_size)
		count += 1
	if sim.weather == "night":
		for item: Dictionary in sim.pickups:
			if count >= 8:
				break
			var at: Vector2 = item["pos"]
			holes[count] = _hole(Vector3(at.x, 0.5, at.y), 2.6, right, view_size)
			count += 1
	_veil_mat.set_shader_parameter("holes", holes)


func _hole(at: Vector3, reach: float, right: Vector3, view_size: Vector2) -> Vector3:
	if _view.camera.is_position_behind(at):
		return Vector3.ZERO
	var center := _view.camera.unproject_position(at)
	var edge := _view.camera.unproject_position(at + right * reach)
	return Vector3(center.x / view_size.x, center.y / view_size.y, center.distance_to(edge) / view_size.y)


## Rain splashing on the floor, heat rising off it.
func _ground_touches(delta: float) -> void:
	var kind := _shown
	if kind not in ["rain", "storm", "heat", "ash"] or _low:
		return
	_splash_cd -= delta
	if _splash_cd > 0.0:
		return
	_splash_cd = 0.05 if kind in ["rain", "storm"] else 0.16
	var at := _view.look_target() + Vector3(randf_range(-16.0, 16.0), 0.1, randf_range(-11.0, 11.0))
	match kind:
		"rain", "storm":
			_view.fx.spawn(at, Vector3.ZERO, 0.28, 0.3, Cosmetics.Fx.RING, Color(1, 1, 1, 0.6))
		"heat":
			_view.fx.spawn(at, Vector3(0, 1.6, 0), 0.8, 0.4, Cosmetics.Fx.SOFT, Color(1.0, 0.8, 0.5, 0.2))
		"ash":
			_view.fx.spawn(at + Vector3(0, 0.2, 0), Vector3(0, 0.6, 0), 0.5, 0.2, Cosmetics.Fx.SPARK, Color("ff9d2e"))
