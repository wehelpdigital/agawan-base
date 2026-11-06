class_name FlagBunting
extends Control
## Strings of little flags from all over the world, hung across the top of a screen, stirring in the breeze.

const FLAGS := ["jp", "br", "fr", "ng", "in", "us", "ph", "gb", "kr", "mx", "de", "za", "it", "ca", "eg", "au", "tr", "es", "ke", "ar", "se", "th", "gr", "id", "pt", "nz", "ma", "co", "ie", "vn"]

var _t := 0.0
var _sag := 26.0
var _spans := 3
var _flag_w := 34.0


func setup(spans := 3, sag := 26.0, flag_w := 34.0) -> FlagBunting:
	_spans = spans
	_sag = sag
	_flag_w = flag_w
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	custom_minimum_size.y = sag + flag_w + 6.0
	return self


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var span := w / _spans
	var step := _flag_w * 1.34
	var index := 0
	var rope := PackedVector2Array()
	for s in _spans:
		var from := s * span
		for i in 17:
			var f := i / 16.0
			rope.append(Vector2(from + f * span, 2.0 + 4.0 * f * (1.0 - f) * _sag))
	draw_polyline(rope, UiKit.INK, 3.0, true)
	for s in _spans:
		var from := s * span
		var count := maxi(int(span / step), 2)
		for i in count:
			var f := (i + 0.5) / count
			var at := Vector2(from + f * span, 3.0 + 4.0 * f * (1.0 - f) * _sag)
			var flag := Flags.texture(FLAGS[index % FLAGS.size()], true)
			index += 1
			var h := _flag_w * float(flag.get_height()) / flag.get_width()
			var swing := sin(_t * 1.6 + index * 0.9) * 0.08 + (0.5 - f) * 0.6 * _sag / span * 2.0
			draw_set_transform(at, swing, Vector2.ONE)
			draw_texture_rect(flag, Rect2(-_flag_w * 0.5, 0.0, _flag_w, h), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
