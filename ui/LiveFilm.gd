class_name LiveFilm
extends Control
## A window with the real game running in it, with nothing heard from it. There's no video file behind it, so the download
## doesn't grow. While it gets ready a picture shows with a loader over it, and the work is done a little each frame so the
## loader keeps moving. MapPreview and SkillPreview say what's in it.

const STEP_BUDGET_USEC := 12000  ## How long one frame may spend getting the film ready.
const SETTLE_FRAMES := 5  ## Frames the film draws behind the picture before it shows: the first few are the slow ones.
const LEAST_LOADER_SECONDS := 0.6  ## So a fast device doesn't just flash the loader.
const FADE_SECONDS := 0.3
const MAX_WIDTH := 960.0

var _viewport: SubViewport
var _picture: TextureRect
var _still: TextureRect
var _loader: FilmLoader
var _fade: Tween
var _view: MatchView
var _sim: Sim
var _steps: Array[Callable] = []
var _steps_total := 1
var _wait_frames := 0
var _covered := false  ## The picture and loader are still over the film.
var _settling := 0
var _clock := 0.0
var _spare_time := 0.0


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func _ready() -> void:
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
	_add_overlays()
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


## Covers the window, and starts getting a new film ready.
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
	_covered = true
	_settling = SETTLE_FRAMES
	_wait_frames = 2  # So the loader's on screen before any of the work starts.
	_steps = [_prepare]
	_steps_total = 1
	_on_covered()


## The first piece of getting the film ready: makes the Sim, and calls _add_view to lay out the rest.
func _prepare() -> void:
	pass


## Whatever else goes over the picture.
func _add_overlays() -> void:
	pass


func _on_covered() -> void:
	pass


func _on_uncovered() -> void:
	pass


## Every frame, once it's running. Moves the camera, and anything else. `delta` is zero until the film's on show.
func _film(_delta: float) -> void:
	pass


## The view of the Sim, built in pieces.
func _add_view() -> void:
	_view = MatchView.new()
	_view.film = true
	_viewport.add_child(_view)
	_view.set_process(false)
	_steps.append_array(_view.setup_steps(_sim, -1))
	_steps_total = _steps.size()


func _do_steps() -> void:
	if _wait_frames > 0:
		_wait_frames -= 1
		return
	var began := Time.get_ticks_usec()
	while not _steps.is_empty() and Time.get_ticks_usec() - began < STEP_BUDGET_USEC:
		(_steps.pop_front() as Callable).call()
	_loader.progress = 1.0 - float(_steps.size()) / _steps_total
	_picture.visible = _steps.is_empty()  # Behind the picture: it has to be drawn to get made.


func _uncover() -> void:
	_covered = false
	_on_uncovered()
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
