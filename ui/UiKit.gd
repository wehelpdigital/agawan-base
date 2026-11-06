class_name UiKit
extends RefCounted
## The look of the interface: colours, fonts, panels and the small factories every screen builds from.
## Bright glossy toys under a blue sky: white-rimmed plastic panels and buttons, and fat bouncy letters.

const INK := Color("0a1426")
const INK_SOFT := Color("1c2740")
const SKY := Color("2f8fff")
const SKY_LIGHT := Color("5fb6ff")
const PAPER := Color("fffdf4")
const CARD := Color("2f8bf0")
const CARD_LIGHT := Color("4a9ff5")
const RIM := Color("eef8ff")
const YELLOW := Color("ffd23f")
const ORANGE := Color("ff9d2e")
const CORAL := Color("ff5247")
const PINK := Color("ff6fb5")
const MINT := Color("5ff0a0")
const AQUA := Color("19d3e6")
const BLUE := Color("3aa6ff")
const PURPLE := Color("a98bff")
const WHITE := Color("ffffff")
const MUTED := INK  ## Secondary text is no paler than the rest: small and dark, never grey.
const COIN := Color("ffc21f")
const GEM := Color("5ce8ff")
const TROPHY := Color("ffd23f")

const BUTTON_COLORS := {
	"yellow": {"top": Color("ffe45c"), "low": Color("ffbc1f"), "lip": Color("d98208"), "text": INK},
	"green": {"top": Color("6bef8f"), "low": Color("2cc75e"), "lip": Color("168a3f"), "text": WHITE},
	"blue": {"top": Color("6cc8ff"), "low": Color("2b8ff5"), "lip": Color("1a5fc0"), "text": WHITE},
	"pink": {"top": Color("ff9ccb"), "low": Color("ff5aa5"), "lip": Color("c42a78"), "text": WHITE},
	"coral": {"top": Color("ff8f7a"), "low": Color("f44a3c"), "lip": Color("b52a22"), "text": WHITE},
	"teal": {"top": Color("62e6e0"), "low": Color("1fc0c4"), "lip": Color("0f8791"), "text": WHITE},
	"black": {"top": Color("2a3650"), "low": Color("141d30"), "lip": INK, "text": WHITE},
	"ink": {"top": Color("3f8fe8"), "low": Color("1f6fd0"), "lip": Color("124a96"), "text": WHITE},
	"white": {"top": Color("ffffff"), "low": Color("e8f2fb"), "lip": INK, "text": INK},
}

const WEIGHT_AXIS := 2003265652  ## The font's "wght" axis. It has to be this number: the name alone is silently ignored.

static var _title_font: Font
static var _body_font: Font
static var _body_bold: Font
static var _theme: Theme
static var _icons := {}
static var _markers := {}


static func font_title() -> Font:
	if _title_font == null:
		# A fat, friendly face, drawn a little narrower, so words fit on buttons on small phones.
		var variation := FontVariation.new()
		variation.base_font = load("res://assets/fonts/RammettoOne-Regular.ttf")
		variation.variation_transform = Transform2D(Vector2(0.88, 0), Vector2(0, 1), Vector2.ZERO)
		_title_font = variation
	return _title_font


static func font_body() -> Font:
	if _body_font == null:
		var base: Font = load("res://assets/fonts/Nunito.ttf")
		var variation := FontVariation.new()
		variation.base_font = base
		variation.variation_opentype = {WEIGHT_AXIS: 700}
		_body_font = variation
	return _body_font


static func font_bold() -> Font:
	if _body_bold == null:
		var base: Font = load("res://assets/fonts/Nunito.ttf")
		var variation := FontVariation.new()
		variation.base_font = base
		variation.variation_opentype = {WEIGHT_AXIS: 900}
		_body_bold = variation
	return _body_bold


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = font_body()
	t.default_font_size = 20
	t.set_color("font_color", "Label", WHITE)
	var scroll := StyleBoxFlat.new()
	scroll.bg_color = Color(0, 0, 0, 0)
	scroll.set_corner_radius_all(6)
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = INK
	grabber.set_corner_radius_all(6)
	for kind: String in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", kind, scroll)
		t.set_stylebox("grabber", kind, grabber)
		t.set_stylebox("grabber_highlight", kind, grabber)
		t.set_stylebox("grabber_pressed", kind, grabber)
		t.set_stylebox("scroll_focus", kind, scroll)
	var field := style(PAPER, 16, 4, INK)
	field.content_margin_left = 16
	field.content_margin_right = 16
	field.content_margin_top = 10
	field.content_margin_bottom = 10
	var field_focus := style(WHITE, 16, 4, ORANGE)
	field_focus.content_margin_left = 16
	field_focus.content_margin_right = 16
	field_focus.content_margin_top = 10
	field_focus.content_margin_bottom = 10
	t.set_stylebox("normal", "LineEdit", field)
	t.set_stylebox("focus", "LineEdit", field_focus)
	t.set_stylebox("read_only", "LineEdit", field)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_placeholder_color", "LineEdit", Color(INK, 0.7))
	t.set_color("caret_color", "LineEdit", INK)
	t.set_color("selection_color", "LineEdit", Color(ORANGE, 0.45))
	t.set_font_size("font_size", "LineEdit", 20)
	var slider := style(INK, 8)
	slider.content_margin_top = 8
	slider.content_margin_bottom = 8
	var slider_fill := style(YELLOW, 8)
	slider_fill.content_margin_top = 8
	slider_fill.content_margin_bottom = 8
	t.set_stylebox("slider", "HSlider", slider)
	t.set_stylebox("grabber_area", "HSlider", slider_fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", slider_fill)
	var knob := _knob_texture()
	t.set_icon("grabber", "HSlider", knob)
	t.set_icon("grabber_highlight", "HSlider", knob)
	_theme = t
	return t


static func _knob_texture() -> Texture2D:
	var svg := "<svg xmlns='http://www.w3.org/2000/svg' width='40' height='40'><circle cx='20' cy='20' r='17' fill='#0a1426'/><circle cx='20' cy='20' r='12' fill='#fff'/></svg>"
	return _svg_texture(svg)


static func _svg_texture(svg: String, scale := 1.0) -> ImageTexture:
	var image := Image.new()
	image.load_svg_from_string(svg, scale)
	return ImageTexture.create_from_image(image)


static func style(bg: Color, radius := 18, border := 0, border_color := INK) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.set_corner_radius_all(radius)
	box.corner_detail = 6
	if border > 0:
		box.set_border_width_all(border)
		box.border_color = border_color
	return box


## A glossy plastic panel: a white rim, and a soft shadow on whatever it sits on.
static func card_style(bg := CARD, radius := 20, border := 4) -> StyleBoxFlat:
	var box := style(bg, radius, border, RIM)
	box.shadow_color = Color(INK, 0.32)
	box.shadow_size = 3
	box.shadow_offset = Vector2(0, 4)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 12
	return box


static func panel(bg := CARD, radius := 20, border := 4) -> PanelContainer:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", card_style(bg, radius, border))
	return box


static func label(text: String, size := 20, color := WHITE, outline := 0, display := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font_title() if display else font_body())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_color_override("font_outline_color", INK)
		l.add_theme_constant_override("outline_size", outline)
	return l


## Big letters with an ink outline and a drop shadow: headings and numbers.
static func title(text: String, size := 34, color := WHITE) -> Label:
	var l := label(text, size, color, maxi(int(size * 0.28), 6), true)
	l.add_theme_color_override("font_shadow_color", INK)
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", maxi(int(size * 0.1), 2))
	l.add_theme_constant_override("shadow_outline_size", maxi(int(size * 0.28), 6))
	return l


static func body(text: String, size := 18, color := INK) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## Body text with no panel behind it: outlined, so it can be read against the sky and the hills.
static func open_text(text: String, size := 18, color := WHITE) -> Label:
	var l := body(text, size, color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", maxi(int(size * 0.34), 5))
	return l


## A short message on a pale card of its own, which can be read whatever's behind it: sky, cloud or hill.
static func note(text: String, size := 17, wrap := true) -> PanelContainer:
	var card := PanelContainer.new()
	var box := style(PAPER, 16, 3, INK)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 8
	box.content_margin_bottom = 9
	card.add_theme_stylebox_override("panel", box)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := body(text, size, INK)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if not wrap:  # For a card that shrinks to fit its words: a wrapping label would shrink to one letter wide.
		line.autowrap_mode = TextServer.AUTOWRAP_OFF
	card.add_child(line)
	return card


static func hbox(gap := 10) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", gap)
	return b


static func vbox(gap := 10) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", gap)
	return b


static func margin(left := 10, top := 10, right := 10, bottom := 10) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", left)
	m.add_theme_constant_override("margin_top", top)
	m.add_theme_constant_override("margin_right", right)
	m.add_theme_constant_override("margin_bottom", bottom)
	return m


static func spacer() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## A scroll area that drags with a finger; desktop gets a slim bar.
static func scroller(horizontal := false) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if horizontal else ScrollContainer.SCROLL_MODE_DISABLED
	s.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if horizontal else ScrollContainer.SCROLL_MODE_AUTO
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.follow_focus = true
	return s


static func icon_texture(icon_name: String) -> Texture2D:
	if not _icons.has(icon_name):
		var path := "res://assets/icons/ui/%s.svg" % icon_name
		_icons[icon_name] = load(path) if ResourceLoader.exists(path) else null
	return _icons[icon_name]


static func icon(icon_name: String, size := 28.0) -> TextureRect:
	var r := TextureRect.new()
	r.texture = icon_texture(icon_name)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(size, size)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func image(path: String, size: Vector2) -> TextureRect:
	var r := TextureRect.new()
	if ResourceLoader.exists(path):
		r.texture = load(path)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## A number with a little icon, in a white pill: coins, gems, trophies.
static func stat_pill(icon_name: String, text: String, color: Color, height := 40.0) -> PanelContainer:
	var pill := PanelContainer.new()
	var box := style(PAPER, int(height * 0.5), 3, Color("a9d6ff"))
	box.shadow_color = Color(INK, 0.28)
	box.shadow_size = 2
	box.shadow_offset = Vector2(0, 3)
	box.content_margin_left = 8
	box.content_margin_right = 14
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	pill.add_theme_stylebox_override("panel", box)
	var row := hbox(6)
	row.add_child(icon(icon_name, height * 0.68))
	var value := label(text, int(height * 0.46), INK, 0, true)
	value.name = "Value"
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value)
	pill.add_child(row)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return pill


static func button(text: String, kind := "yellow", font_size := 24, icon_name := "") -> GameButton:
	var b := GameButton.new()
	b.setup(text, kind, font_size, icon_name)
	return b


static func format_number(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.right(3) + out
		s = s.left(s.length() - 3)
	return ("-" if n < 0 else "") + s + out


## Icons floating over players in a match. Drawn once, from SVG, so they stay sharp.
static func marker_texture(kind: String) -> Texture2D:
	if _markers.has(kind):
		return _markers[kind]
	var svg := ""
	match kind:
		"catch":  # A green hand-free "get them" arrow: you can tag this enemy.
			svg = "<svg xmlns='http://www.w3.org/2000/svg' width='96' height='96'><path d='M48 88 L10 42 H30 V8 H66 V42 H86 Z' fill='#0a1426' stroke='#0a1426' stroke-width='10' stroke-linejoin='round'/><path d='M48 80 L19 46 H37 V15 H59 V46 H77 Z' fill='#3bff7a'/><path d='M37 15 H59 V30 H37 Z' fill='#b6ffcf'/></svg>"
		"danger":  # A red warning sign: this enemy can tag you.
			svg = "<svg xmlns='http://www.w3.org/2000/svg' width='96' height='96'><path d='M48 8 L90 84 H6 Z' fill='#0a1426' stroke='#0a1426' stroke-width='10' stroke-linejoin='round'/><path d='M48 17 L80 77 H16 Z' fill='#ff3f5a'/><rect x='42' y='36' width='12' height='23' rx='5' fill='#fff'/><circle cx='48' cy='68' r='6.5' fill='#fff'/></svg>"
		"free":  # A white house: walk home, nobody can touch you.
			svg = "<svg xmlns='http://www.w3.org/2000/svg' width='96' height='96'><path d='M48 8 L90 46 H74 V86 H22 V46 H6 Z' fill='#0a1426' stroke='#0a1426' stroke-width='8' stroke-linejoin='round'/><path d='M48 16 L78 42 H66 V78 H30 V42 H18 Z' fill='#fff'/><rect x='41' y='52' width='14' height='26' fill='#0a1426'/></svg>"
	_markers[kind] = _svg_texture(svg)
	return _markers[kind]


## A soft splat for the Squid Ink screen effect.
static func ink_splat_texture() -> Texture2D:
	if _markers.has("ink"):
		return _markers["ink"]
	var svg := "<svg xmlns='http://www.w3.org/2000/svg' width='256' height='256'><g fill='#140a33'><circle cx='128' cy='128' r='74'/><circle cx='60' cy='88' r='30'/><circle cx='200' cy='76' r='24'/><circle cx='210' cy='174' r='34'/><circle cx='78' cy='200' r='26'/><circle cx='24' cy='150' r='12'/><circle cx='236' cy='120' r='10'/><circle cx='150' cy='26' r='14'/><circle cx='130' cy='236' r='11'/></g></svg>"
	_markers["ink"] = _svg_texture(svg)
	return _markers["ink"]
