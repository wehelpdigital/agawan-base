class_name ItemIcon
extends Control
## The picture on a shop card. Wearable things use a picture of the item alone, rendered from its 3D model
## (tests/ThumbBaker); the rest are drawn here from what the item actually does.

var _slot := ""
var _id := ""
var _thumb: Texture2D
var _entry: Dictionary = {}
var _atlas: Texture2D


func setup(slot: String, id: String) -> void:
	_slot = slot
	_id = id
	_entry = Cosmetics.item(slot, id)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := Cosmetics.thumb_path(slot, id)
	if slot in Cosmetics.BAKED_SLOTS and (id != "" or slot == "face") and ResourceLoader.exists(path):
		_thumb = load(path)
	_atlas = preload("res://assets/fx/atlas.png")


func _draw() -> void:
	var side := minf(size.x, size.y)
	var rect := Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))
	if _thumb:
		draw_texture_rect(_thumb, rect, false)
		return
	var center := size * 0.5
	var tint: Color = Color.WHITE if _entry["rarity"] == "free" else (Cosmetics.RARITY[_entry["rarity"]]["color"] as Color).lightened(0.3)
	match _slot:
		"trail", "aura", "burst":
			_draw_particles(center, side)
		"emote":
			_draw_bubble(center, side)
		"dance", "run":
			var icon := UiKit.icon_texture("dance" if _slot == "dance" else "dash")
			var s := side * 0.72
			draw_texture_rect(icon, Rect2(center - Vector2(s, s) * 0.5, Vector2(s, s)), false)
		"skin":
			_draw_swatch(center, side)
		"frame":
			var c := Color(_entry.get("c", "ffffff"))
			var s := side * 0.66
			var box := UiKit.style(UiKit.INK, int(s * 0.28), int(s * 0.14), c)
			draw_style_box(box, Rect2(center - Vector2(s, s) * 0.5, Vector2(s, s)))
		"title":
			var font := UiKit.font_title()
			var words := String(_entry["name"]).split(" ")
			var lines := words.size()
			var font_size := int(side * 0.17)
			for i in lines:
				var w := font.get_string_size(words[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				var at := center + Vector2(-w * 0.5, font_size * (i - (lines - 1) * 0.5) * 1.15 + font_size * 0.35)
				draw_string_outline(font, at, words[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, UiKit.INK)
				draw_string(font, at, words[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)
		_:
			_draw_none(center, side)


## An empty slot: "nothing here".
func _draw_none(center: Vector2, side: float) -> void:
	var r := side * 0.27
	draw_arc(center, r, 0.0, TAU, 32, UiKit.INK, 6.0, true)
	draw_line(center + Vector2(-r, r) * 0.7, center + Vector2(r, -r) * 0.7, UiKit.INK, 6.0, true)


func _draw_swatch(center: Vector2, side: float) -> void:
	var a := String(_entry.get("a", ""))
	var b := String(_entry.get("b", ""))
	var r := side * 0.3
	if a == "":
		_draw_none(center, side)
		return
	draw_circle(center + Vector2(-r * 0.45, 0), r + 4.0, UiKit.INK)
	draw_circle(center + Vector2(r * 0.45, 0), r + 4.0, UiKit.INK)
	draw_circle(center + Vector2(-r * 0.45, 0), r, Color(a))
	draw_circle(center + Vector2(r * 0.45, 0), r, Color(b))


func _draw_particles(center: Vector2, side: float) -> void:
	if not _entry.has("fx"):
		_draw_none(center, side)
		return
	var cell := int(_entry["fx"])
	var colors: Array = _entry["c"]
	var src := Rect2(Vector2(cell % 4, cell / 4) * 128.0, Vector2(128, 128))
	var ring: Color = Color(_entry["ring"]) if _entry.has("ring") else Color(0, 0, 0, 0)
	if ring.a > 0.0:
		draw_arc(center + Vector2(0, side * 0.2), side * 0.32, 0.0, TAU, 28, ring, 5.0, true)
	var spots := [Vector2(0, -0.24), Vector2(-0.26, -0.02), Vector2(0.26, -0.04), Vector2(-0.12, 0.2), Vector2(0.16, 0.22)]
	var sizes := [0.46, 0.32, 0.34, 0.28, 0.26]
	for i in spots.size():
		var s: float = side * float(sizes[i])
		var at: Vector2 = center + (spots[i] as Vector2) * side - Vector2(s, s) * 0.5
		draw_texture_rect_region(_atlas, Rect2(at, Vector2(s, s)), src, Color(colors[i % colors.size()]))


func _draw_bubble(center: Vector2, side: float) -> void:
	var text := String(_entry.get("text", ""))
	var font := UiKit.font_title()
	var box := Rect2(center - Vector2(side * 0.46, side * 0.28), Vector2(side * 0.92, side * 0.5))
	draw_style_box(UiKit.style(UiKit.PAPER, 14, 4), box)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-side * 0.14, side * 0.2), center + Vector2(side * 0.04, side * 0.2), center + Vector2(-side * 0.1, side * 0.36)]), UiKit.INK)
	var font_size := int(side * 0.19)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if w > box.size.x - 10.0:
		font_size = int(font_size * (box.size.x - 10.0) / w)
		w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, center + Vector2(-w * 0.5, font_size * 0.3 - side * 0.03), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiKit.INK)
