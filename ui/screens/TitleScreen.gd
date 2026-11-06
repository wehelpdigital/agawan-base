extends Control
## The first thing you see: the logo over a little planet, with a game of tag going on round it. The tap here is also what
## browsers need before they allow sound.

const RUNNERS := [
	{"char": "kiko", "top": "tee", "pants": "shorts", "shoes": "sneakers", "pet": "puppy", "flag": "ph"},
	{"char": "sir_clank", "pet": "squire", "flag": "gb", "back": "lance"},
	{"char": "take", "pet": "shoot", "flag": "cn"},
	{"char": "yuki", "hat": "hachimaki", "pet": "shiba", "flag": "jp"},
	{"char": "amara", "top": "kente", "pet": "lion", "flag": "ng"},
	{"char": "diego", "hat": "sombrero", "pet": "axolotl", "flag": "mx"},
	{"char": "freya", "hat": "viking", "pet": "reindeer", "flag": "no"},
	{"char": "botbot", "pet": "robo", "flag": "earth"},
	{"char": "paco", "pet": "butterfly", "flag": "mx"},
	{"char": "neb", "pet": "scarab", "flag": "eg"},
	{"char": "luna", "hat": "plume", "pet": "toucan", "flag": "br"},
	{"char": "leo", "hat": "beret", "pet": "dachshund", "flag": "it"},
]

var root: UiRoot
var args: Dictionary
var screen_name: String
var _tap: Label
var _tap_button: PanelContainer
var _logo: TextureRect
var _clock := 0.0
var _left := false
var _viewport: SubViewport
var _camera: Camera3D
var _runners: Array[Avatar3D] = []
var _pets: Array[Pet3D] = []
var _fx: FxField
var _spark := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_world()
	add_child(FlagBunting.new().setup(3 if not root.phone_narrow else 2, 22.0 if root.compact else 28.0, 30.0 if root.compact else 36.0))
	var view := size
	var col := UiKit.vbox(6)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_top = 36.0 if root.compact else 52.0
	col.offset_bottom = -8.0
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	var logo_h := minf(view.y * (0.5 if not root.portrait else 0.44), view.x * 0.8)
	var logo_w := minf(view.x * 0.92, logo_h * 1.2)
	_logo = UiKit.image("res://assets/brand/logo.png", Vector2(logo_w, logo_h))
	_logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(_logo)
	col.add_child(UiKit.spacer())
	_tap_button = _play_pill()
	_tap_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(_tap_button)
	var note := UiKit.label("5 vs 5 tag, all around the world", 16 if root.phone_narrow else 18, UiKit.WHITE)
	note.add_theme_color_override("font_outline_color", UiKit.INK)
	note.add_theme_constant_override("outline_size", 6)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(note)
	if not root.compact and not root.phone_narrow:
		_add_corner_facts()
	_logo.pivot_offset = Vector2(logo_w, logo_h) * 0.5
	_logo.scale = Vector2.ONE * 0.6
	create_tween().tween_property(_logo, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_pill() -> PanelContainer:
	var pill := PanelContainer.new()
	var box := UiKit.style(Color("ffc21f"), 34, 5, UiKit.WHITE)
	box.shadow_color = Color(UiKit.INK, 0.5)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 6)
	box.content_margin_left = 40
	box.content_margin_right = 40
	box.content_margin_top = 8
	box.content_margin_bottom = 10
	pill.add_theme_stylebox_override("panel", box)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tap = UiKit.label("TAP TO PLAY", 34 if not root.compact else 26, UiKit.INK, 0, true)
	_tap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.add_child(_tap)
	return pill


## What's in the box, stuck on like stickers at the sides.
func _add_corner_facts() -> void:
	var left := [["map", "%d MAPS" % Maps.all().size()], ["power", "%d POWER CARDS" % Powerups.ALL.size()], ["w_storm", "%d KINDS OF WEATHER" % Weather.ALL.size()]]
	var right := [["paw", "%d PETS" % (Cosmetics.list("pet").size() - 1)], ["flag", "%d FLAGS" % (Cosmetics.list("flag").size() - 1)], ["avatar", "%d HEROES" % Cosmetics.list("char").size()]]
	for side: int in 2:
		var box := UiKit.vbox(8)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.set_anchors_preset(Control.PRESET_TOP_LEFT if side == 0 else Control.PRESET_TOP_RIGHT)
		box.grow_horizontal = Control.GROW_DIRECTION_END if side == 0 else Control.GROW_DIRECTION_BEGIN
		box.position = Vector2(18.0, size.y * 0.26) if side == 0 else Vector2(size.x - 18.0, size.y * 0.26)
		add_child(box)
		for row: Array in (left if side == 0 else right):
			var sticker := PanelContainer.new()
			var style := UiKit.card_style(UiKit.PAPER, 18, 3)
			style.border_color = UiKit.INK
			style.content_margin_top = 4
			style.content_margin_bottom = 4
			sticker.add_theme_stylebox_override("panel", style)
			sticker.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sticker.rotation = deg_to_rad(-2.0 if side == 0 else 2.0)
			var line := UiKit.hbox(6)
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			line.add_child(UiKit.icon(row[0], 30))
			line.add_child(UiKit.label(row[1], 15, UiKit.INK, 0, true))
			sticker.add_child(line)
			box.add_child(sticker)
		if side == 1:
			box.reset_size()
			box.position.x = size.x - 18.0 - box.get_combined_minimum_size().x


## The planet, and everyone running round it.
func _build_world() -> void:
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_viewport)
	var picture := TextureRect.new()
	picture.set_anchors_preset(Control.PRESET_FULL_RECT)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.texture = _viewport.get_texture()
	add_child(picture)
	var world := Node3D.new()
	_viewport.add_child(world)
	_camera = Camera3D.new()
	_camera.fov = 26.0
	world.add_child(_camera)
	var stage := WorldStage.new()
	world.add_child(stage)
	stage.setup(9.0)
	stage.spin_speed = 0.16
	_fx = FxField.new(160)
	_fx.density = 0.5 if Quality.is_low() else 1.0
	world.add_child(_fx)
	var count := 4 if Quality.is_low() else 6
	for i in count:
		var look := Cosmetics.default_look()
		look.merge(RUNNERS[i], true)
		look["top"] = RUNNERS[i].get("top", "")
		look["pants"] = RUNNERS[i].get("pants", "")
		look["shoes"] = RUNNERS[i].get("shoes", "")
		look["pet"] = RUNNERS[i].get("pet", "")
		look["flag"] = RUNNERS[i].get("flag", "")
		look["trail"] = ["sparks", "sakura", "feathers", "leaves", "snow", "pixels", "feathers", "petals"][i]
		var runner := Avatar3D.new()
		world.add_child(runner)
		runner.setup(look, ArenaBuilder.team_color(i % 2))
		runner.state = "run"
		runner.moving = 1.0
		runner.rotation.y = 0.95
		_runners.append(runner)
		var pet := Pet3D.new()
		world.add_child(pet)
		pet.setup(look["pet"])
		pet.rotation.y = 0.95
		_pets.append(pet)
	_fit()
	resized.connect(_fit)


func _fit() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	var density := get_viewport().get_final_transform().get_scale()
	_viewport.size = Vector2i(ceili(minf(size.x * density.x, 1400.0)), ceili(minf(size.y * density.y, 1400.0 * size.y / size.x)))
	var aspect := size.x / size.y
	# Back far enough that the runners fit across, whatever shape the screen is, with the top of the planet low in the picture.
	var distance := clampf(30.0 / aspect, 12.0, 19.0)
	var high := distance * tan(deg_to_rad(_camera.fov * 0.5)) * 2.0
	var middle := high * 0.31
	_camera.position = Vector3(0, middle + distance * 0.1, distance)
	_camera.look_at(Vector3(0, middle, 0))


func _process(delta: float) -> void:
	_clock += delta
	if _tap_button:
		var breathe := 1.0 + sin(_clock * 4.0) * 0.035
		_tap_button.pivot_offset = _tap_button.size * 0.5
		_tap_button.scale = Vector2.ONE * breathe
	if _logo:
		_logo.rotation = sin(_clock * 1.3) * 0.012
	# Round and round they go, overtaking and falling behind, along the top of the planet.
	var spacing := 2.45
	for i in _runners.size():
		var runner := _runners[i]
		var x := (float(i) - (_runners.size() - 1) * 0.5) * spacing + sin(_clock * 0.5 + i * 1.7) * 0.55
		var curve := x * x * 0.055
		runner.position = Vector3(x, -curve, 0.25 * sin(_clock * 0.7 + i))
		runner.rotation.z = -x * 0.09
		runner.emit_effects(_fx, delta, true)
		var pet := _pets[i]
		var px := x - 0.82
		pet.position = Vector3(px, -px * px * 0.055, 0.5 + 0.25 * sin(_clock * 0.7 + i))
		pet.rotation.z = -px * 0.09
		pet.follow_in_place(delta)
	_spark -= delta
	if _spark <= 0.0:
		_spark = randf_range(1.8, 3.6)
		_runners[randi() % _runners.size()].react(Faces.funny(), 1.4)


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_go()


func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventKey and event.pressed) or (event is InputEventJoypadButton and event.pressed):
		_go()


func _go() -> void:
	if _left:
		return
	_left = true
	Audio.sfx("ui_confirm")
	Audio.music("menu")
	if not Profile.tutorial_done:
		root.show_screen("howto", {"first": true})
	else:
		root.show_screen("home")
