class_name MapPreview
extends Control
## A little film of a map: ten bots really playing it, in its weather, shot by a camera that keeps moving and cutting.
## There's no video file behind it. It's the game itself, so every map has one and the download doesn't grow, and
## nothing in it makes a sound. While it gets ready, the map's picture shows with a loader over it, and the work is done
## a little each frame so the loader keeps moving.

const SHOT_SECONDS := 5.5
const WARM_UP := 6.0  ## Seconds of play run before the film starts, so the bots are already out on the field.
const WARM_UP_CHUNK := 30  ## Ticks of that done in one go.
const STEP_BUDGET_USEC := 12000  ## How long one frame may spend getting the film ready.
const SETTLE_FRAMES := 5  ## Frames the film draws behind the picture before it shows: the first few are the slow ones.
const LEAST_LOADER_SECONDS := 0.6  ## So a fast device doesn't just flash the loader.
const FADE_SECONDS := 0.3
const MAX_WIDTH := 960.0
const SHOTS := 4

var _viewport: SubViewport
var _picture: TextureRect
var _still: TextureRect
var _sky_chip: HBoxContainer
var _sky_icon: TextureRect
var _sky_name: Label
var _loader: FilmLoader
var _fade: Tween
var _view: MatchView
var _sim: Sim
var _map_id := ""
var _steps: Array[Callable] = []
var _steps_total := 1
var _wait_frames := 0
var _covered := false  ## The picture and loader are still over the film.
var _settling := 0
var _clock := 0.0
var _spare_time := 0.0
var _shot := -1
var _cuts := 0
var _star := -1
var _star_dir := Vector3(0, 0, 1)
var _cam_at := Vector3.ZERO
var _cam_look := Vector3.ZERO
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func _ready() -> void:
	_rng.randomize()
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_DISABLED if Quality.is_low() else Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_viewport)
	_picture = TextureRect.new()
	_picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_SCALE
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_picture.texture = _viewport.get_texture()
	_picture.visible = false
	add_child(_picture)
	_still = TextureRect.new()
	_still.set_anchors_preset(Control.PRESET_FULL_RECT)
	_still.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_still.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_still.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_still)
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
	_loader = FilmLoader.new()
	_loader.visible = false
	add_child(_loader)
	resized.connect(_fit_viewport)
	_fit_viewport()


func _fit_viewport() -> void:
	if size.x < 1.0 or size.y < 1.0 or _viewport == null:
		return
	var wanted := size * get_viewport().get_final_transform().get_scale()
	var most := MAX_WIDTH * (0.6 if Quality.is_low() else 1.0)
	if wanted.x > most:
		wanted *= most / wanted.x
	_viewport.size = Vector2i(ceili(wanted.x), ceili(wanted.y))


## Plays this map. Its picture and the loader show at once; the film takes over when it's ready to run smoothly.
func play(map_id: String) -> void:
	if map_id == _map_id and (_view != null or not _steps.is_empty()):
		return
	_map_id = map_id
	var path := Maps.thumb_path(map_id)
	_still.texture = load(path) if ResourceLoader.exists(path) else null
	_load()


func _load() -> void:
	if _fade:
		_fade.kill()
	if _view:
		_viewport.remove_child(_view)
		_view.free()
		_view = null
	_still.visible = true
	_still.modulate.a = 1.0
	_loader.restart()
	_picture.visible = false
	_sky_chip.visible = false
	_covered = true
	_settling = SETTLE_FRAMES
	_wait_frames = 2  # So the loader's on screen before any of the work starts.
	_steps = [_prepare]
	_steps_total = 1


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
	_view = MatchView.new()
	_view.film = true
	_viewport.add_child(_view)
	_view.set_process(false)
	_steps.append_array(_view.setup_steps(_sim, -1))
	_steps_total = _steps.size()


func _warm_up() -> void:
	for i in WARM_UP_CHUNK:
		_sim.step(Sim.TICK)
	_sim.take_events()


func _do_steps() -> void:
	if _wait_frames > 0:
		_wait_frames -= 1
		return
	var began := Time.get_ticks_usec()
	while not _steps.is_empty() and Time.get_ticks_usec() - began < STEP_BUDGET_USEC:
		(_steps.pop_front() as Callable).call()
	_loader.progress = 1.0 - float(_steps.size()) / _steps_total
	_picture.visible = _steps.is_empty()  # Behind the map's picture: it has to be drawn to get made.


func _uncover() -> void:
	_covered = false
	_sky_chip.visible = true
	_fade = create_tween().set_parallel()
	_fade.tween_property(_still, "modulate:a", 0.0, FADE_SECONDS)
	_fade.tween_property(_loader, "modulate:a", 0.0, FADE_SECONDS)
	_fade.chain().tween_callback(func() -> void:
		_still.visible = false
		_loader.visible = false)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if not _steps.is_empty():
		_do_steps()
		return
	if _view == null:
		return
	_spare_time += delta
	var steps := 0
	while _spare_time >= Sim.TICK and steps < 3:
		_spare_time -= Sim.TICK
		_sim.step(Sim.TICK)
		steps += 1
	if steps == 3:
		_spare_time = 0.0
	if _sim.phase == Sim.Phase.END:
		_load()
		return
	Audio.silent += 1
	_view._process(delta)
	Audio.silent -= 1
	_film(0.0 if _covered else delta)
	if _covered:
		_settling -= 1
		if _settling <= 0 and _loader.age >= LEAST_LOADER_SECONDS:
			_uncover()


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
