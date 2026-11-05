class_name PowerCard
extends Control
## A power, as a card: its picture and its name. The picture comes from tools/gen_icons.py; the name is written on
## here in the game's font. `paint` draws one onto anything, which is how the slot machine in a match shows them.

static var _textures := {}

var power_id := ""


func setup(id: String) -> PowerCard:
	power_id = id
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


func _draw() -> void:
	paint(self, Rect2(Vector2.ZERO, size), power_id)


static func texture(id: String) -> Texture2D:
	if not _textures.has(id):
		_textures[id] = load(Powerups.icon_path(id))
	return _textures[id]


static func paint(canvas: CanvasItem, rect: Rect2, id: String, with_name := true) -> void:
	canvas.draw_texture_rect(texture(id), rect, false)
	if with_name:
		_write_name(canvas, rect, String(Powerups.by_id(id).get("name", "")))


## On one line if it fits, otherwise on two, split near the middle; made smaller only if it has to be.
static func _write_name(canvas: CanvasItem, rect: Rect2, text: String) -> void:
	var font := UiKit.font_title()
	var band := Rect2(rect.position + rect.size * Vector2(0.08, 0.755), rect.size * Vector2(0.84, 0.19))
	var font_size := maxi(int(band.size.y * 0.42), 8)
	var lines := PackedStringArray([text])
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > band.size.x:
		var words := text.split(" ")
		if words.size() > 1:
			var split := 1
			var best := INF
			for i in range(1, words.size()):
				var gap := absf(" ".join(words.slice(0, i)).length() - " ".join(words.slice(i)).length())
				if gap < best:
					best = gap
					split = i
			lines = PackedStringArray([" ".join(words.slice(0, split)), " ".join(words.slice(split))])
	var widest := 0.0
	for line in lines:
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	if widest > band.size.x:
		font_size = maxi(int(font_size * band.size.x / widest), 7)
	var step := font_size * 1.05
	var y := band.position.y + (band.size.y - step * lines.size()) * 0.5 + font_size * 0.86
	for line in lines:
		var w := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		canvas.draw_string(font, Vector2(band.get_center().x - w * 0.5, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
		y += step
