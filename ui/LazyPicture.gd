class_name LazyPicture
extends TextureRect
## A picture that only loads once it comes on screen, a few each frame. A screen full of big lists opens straight away and
## only pays for what you scroll to.

const PER_FRAME := 3
const SMOOTH := preload("res://gfx/shaders/smooth_picture.gdshader")

static var _frame := -1
static var _spent := 0
static var _smooth_material: ShaderMaterial

var _path := ""


func setup(path: String) -> LazyPicture:
	_path = path
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	material = smooth_material()
	set_process(path != "")
	return self


func _process(_delta: float) -> void:
	if not is_visible_in_tree() or not get_viewport_rect().intersects(get_global_rect()):
		return
	if not take_turn():
		return
	texture = load(_path) if ResourceLoader.exists(_path) else null
	set_process(false)


## Keeps a picture from going jagged when it's drawn small.
static func smooth_material() -> ShaderMaterial:
	if _smooth_material == null:
		_smooth_material = ShaderMaterial.new()
		_smooth_material.shader = SMOOTH
	return _smooth_material


## True if there's still room to load something this frame.
static func take_turn() -> bool:
	if Engine.get_process_frames() != _frame:
		_frame = Engine.get_process_frames()
		_spent = 0
	if _spent >= PER_FRAME:
		return false
	_spent += 1
	return true
