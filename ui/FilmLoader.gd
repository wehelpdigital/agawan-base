class_name FilmLoader
extends Control
## Goes over a map's picture while its film gets ready: three balls bouncing on a bar that fills as the work gets done.
## Yellow on black with a white rim, the same as the web page's own loading bar.

const CARD_SIZE := Vector2(190, 92)
const BAR_SIZE := Vector2(154, 14)
const BAR_TOP := 50.0
const BALL_COLORS: Array[Color] = [UiKit.CORAL, UiKit.YELLOW, UiKit.AQUA]
const BALL_RADIUS := 8.0
const BALL_GAP := 30.0
const HOP_HEIGHT := 18.0
const HOP_SECONDS := 0.6
const FILL_SPEED := 2.5  ## The most of the bar it can fill in a second.
const WORDS := "Loading video..."

var progress := 0.0
var age := 0.0

var _shown := 0.0
var _card_box := UiKit.style(UiKit.INK, 16, 3, UiKit.WHITE)
var _track_box := UiKit.style(UiKit.INK_SOFT, 7, 2, UiKit.WHITE)
var _fill_box := UiKit.style(UiKit.YELLOW, 5)


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func restart() -> void:
	progress = 0.0
	age = 0.0
	_shown = 0.0
	modulate.a = 1.0
	visible = true


func _process(delta: float) -> void:
	if not visible:
		return
	age += delta
	_shown = move_toward(_shown, progress, delta * FILL_SPEED)
	queue_redraw()


func _draw() -> void:
	var card := Rect2(((size - CARD_SIZE) * 0.5).floor(), CARD_SIZE)
	draw_style_box(_card_box, card)
	var bar := Rect2(card.position + Vector2((CARD_SIZE.x - BAR_SIZE.x) * 0.5, BAR_TOP), BAR_SIZE)
	draw_style_box(_track_box, bar)
	var inside := bar.grow(-2.0)
	var filled := inside.size.x * _shown
	if filled >= 10.0:  # Any thinner and its round ends don't fit.
		draw_style_box(_fill_box, Rect2(inside.position, Vector2(filled, inside.size.y)))
	for i in BALL_COLORS.size():
		_ball(BALL_COLORS[i], Vector2(bar.get_center().x + (i - 1) * BALL_GAP, bar.position.y), i)
	draw_set_transform(Vector2.ZERO)
	draw_string(UiKit.font_bold(), card.position + Vector2(0, 82), WORDS, HORIZONTAL_ALIGNMENT_CENTER, CARD_SIZE.x, 16, UiKit.WHITE)


## One ball, standing on this spot, which squashes as it lands.
func _ball(color: Color, ground: Vector2, turn: int) -> void:
	var hop := fposmod(age / HOP_SECONDS - turn * 0.18, 1.0)
	var height := 4.0 * hop * (1.0 - hop)
	var stretch := clampf(height * 4.0, 0.0, 1.0)
	var tall := lerpf(0.76, 1.0, stretch)
	var rim := BALL_RADIUS + 2.0
	draw_set_transform(ground - Vector2(0, rim * tall + height * HOP_HEIGHT), 0.0, Vector2(lerpf(1.2, 1.0, stretch), tall))
	draw_circle(Vector2.ZERO, rim, UiKit.WHITE, true, -1.0, true)
	draw_circle(Vector2.ZERO, BALL_RADIUS, color, true, -1.0, true)
	draw_circle(Vector2(-2.6, -3.0), 2.0, UiKit.WHITE, true, -1.0, true)
