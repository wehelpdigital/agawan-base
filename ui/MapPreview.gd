class_name MapPreview
extends LiveFilm
## A little film of a map: ten bots really playing it, in its weather, shot by a camera that keeps moving and cutting. Every
## map has one.

const SHOT_SECONDS := 5.5
const WARM_UP := 6.0  ## Seconds of play run before the film starts, so the bots are already out on the field.
const WARM_UP_CHUNK := 30  ## Ticks of that done in one go.
const SHOTS := 4

var _sky_chip: HBoxContainer
var _sky_icon: TextureRect
var _sky_name: Label
var _map_id := ""
var _shot := -1
var _cuts := 0
var _star := -1
var _star_dir := Vector3(0, 0, 1)
var _cam_at := Vector3.ZERO
var _cam_look := Vector3.ZERO
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	super()


func _add_overlays() -> void:
	_sky_chip = UiKit.hbox(4)
	_sky_chip.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_sky_chip.offset_left = 8
	_sky_chip.offset_top = -34
	_sky_chip.offset_bottom = -6
	_sky_chip.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_sky_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sky_chip.visible = false
	_sky_icon = UiKit.icon("w_storm", 26)
	_sky_chip.add_child(_sky_icon)
	_sky_name = UiKit.label("", 15, UiKit.WHITE, 4, true)
	_sky_chip.add_child(_sky_name)
	add_child(_sky_chip)


func _on_covered() -> void:
	_sky_chip.visible = false


func _on_uncovered() -> void:
	_sky_chip.visible = true


## Plays this map. Its picture and the loader show at once; the film takes over when it's ready to run smoothly.
func play(map_id: String) -> void:
	if map_id == _map_id and (_view != null or not _steps.is_empty()):
		return
	_map_id = map_id
	var path := Maps.thumb_path(map_id)
	_still.texture = load(path) if ResourceLoader.exists(path) else null
	_load()


func _seats() -> Array:
	var seats: Array = []
	var taken := {}
	for i in 10:
		var bot_name := Names.bot_name(_rng)
		while taken.has(bot_name):
			bot_name = Names.bot_name(_rng)
		taken[bot_name] = true
		seats.append({"name": bot_name, "bot": true, "team": i % 2, "skill": _rng.randf_range(0.55, 0.85), "look": Cosmetics.random_look(_rng, 0.7)})
	return seats


## The first piece of getting the film ready, which lays out the rest.
func _prepare() -> void:
	_sim = Sim.new()
	_sim.setup(_map_id, _seats(), _rng.randi(), 0.7, Profile.favorite_weather)
	_clock = 0.0
	_shot = -1
	var weather := Weather.def(_sim.weather)
	_sky_icon.texture = UiKit.icon_texture(String(weather["icon"]))
	_sky_name.text = String(weather["name"])
	for i in ceili((Sim.COUNTDOWN + WARM_UP) / Sim.TICK / WARM_UP_CHUNK):
		_steps.append(_warm_up)
	_add_view()


func _warm_up() -> void:
	for i in WARM_UP_CHUNK:
		_sim.step(Sim.TICK)
	_sim.take_events()


## The camera. Four kinds of shot, in turn, all from low enough to see what things are.
func _film(delta: float) -> void:
	_clock += delta
	var shot := int(_clock / SHOT_SECONDS) % SHOTS
	var t := fmod(_clock, SHOT_SECONDS) / SHOT_SECONDS
	var cut := shot != _shot
	if cut:
		_shot = shot
		_cuts += 1
		_star = _pick_star()
	var arena := _sim.arena_size()
	var mid := Vector3(arena.x * 0.5, 0, arena.y * 0.5)
	var side := -1.0 if _cuts % 2 == 0 else 1.0  # Each time round, the other end of the field.
	var at := Vector3.ZERO
	var look := Vector3.ZERO
	match shot:
		0:  # Along the side of the field, the whole way.
			look = Vector3(arena.x * lerpf(0.26, 0.74, t if side > 0.0 else 1.0 - t), 0.6, mid.z)
			var reach := clampf(arena.x * 0.46, 24.0, 46.0)
			at = look + Vector3(0, sin(0.5), cos(0.5)) * reach
		1:  # Behind somebody, running.
			_follow_star(delta, cut)
			look = _cam_look
			at = _cam_at
		2:  # Over one base, pushing in towards the middle.
			var end := mid.x + side * arena.x * 0.5
			at = Vector3(end + side * lerpf(9.0, 2.0, t), 13.0, mid.z + lerpf(7.0, 3.0, t))
			look = Vector3(lerpf(end - side * 12.0, end - side * 20.0, t), 0.4, mid.z)
		_:  # Round the line in the middle.
			var angle := lerpf(-0.75, 0.75, t) * side
			var reach := clampf(arena.y * 0.72 + 10.0, 22.0, 40.0)
			look = mid + Vector3(0, 0.5, 0)
			at = mid + Vector3(sin(angle) * reach, reach * 0.52, cos(angle) * reach)
	if _view.camera and at.distance_to(look) > 0.1:
		_view.camera.global_position = at
		_view.camera.look_at(look, Vector3.UP)
		_view.film_look = look


func _pick_star() -> int:
	var best := -1
	var best_score := -INF
	for p: Sim.Player in _sim.players:
		if p.state != Sim.State.PLAY:
			continue
		var score := p.vel.length() + _rng.randf() * 5.0
		if score > best_score:
			best_score = score
			best = p.id
	return best


func _follow_star(delta: float, cut: bool) -> void:
	var star := _sim.player_by_id(_star)
	if star == null or star.state != Sim.State.PLAY:
		_star = _pick_star()
		star = _sim.player_by_id(_star)
		if star == null:
			return
	var at := Vector3(star.pos.x, 0, star.pos.y)
	if star.vel.length() > 1.0:
		var going := Vector3(star.vel.x, 0, star.vel.y).normalized()
		_star_dir = _star_dir.lerp(going, clampf(delta * 1.4, 0.0, 1.0)).normalized()
	var want_at := at - _star_dir * 12.0 + Vector3(0, 8.5, 0)
	var want_look := at + _star_dir * 2.0 + Vector3(0, 0.9, 0)
	if cut:
		_cam_at = want_at
		_cam_look = want_look
	else:
		_cam_at = _cam_at.lerp(want_at, clampf(delta * 2.6, 0.0, 1.0))
		_cam_look = _cam_look.lerp(want_look, clampf(delta * 4.0, 0.0, 1.0))
