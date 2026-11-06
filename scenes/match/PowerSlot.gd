class_name PowerSlot
extends Control
## The power card you hold in a match. A new one arrives as a slot machine: the reel spins through the deck, slows, and
## stops on what you got, with a flash and a pop. The sim says when it's done, so the card can't be used before you
## can see it. An empty slot shows where a card will go.

const REEL_CARDS := 16
const DECK_SIZE := 12
const GOLD := Color("ffc21f")

static var _deck: Array[String] = []

var compact := false  ## The small slot for the card after this one.
var _id := ""
var _spinning := false
var _spin_left := 0.0
var _spin_target := 0.0
var _reel: Array[String] = []
var _last_cell := 0
var _window: Control
var _down := false
var _lift := 0.0
var _pop := 0.0
var _flash := 0.0
var _burst := -1.0
var _clock := 0.0


## A dozen cards to spin through, ready before the first crystal, so the first spin doesn't stutter while they load.
static func prepare_deck() -> void:
	if not _deck.is_empty():
		return
	var ids: Array[String] = []
	for def: Dictionary in Powerups.ALL:
		ids.append(String(def["id"]))
	ids.shuffle()
	_deck = ids.slice(0, DECK_SIZE)
	for id in _deck:
		PowerCard.texture(id)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_window = Control.new()
	_window.clip_contents = true
	_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_window.visible = false
	_window.draw.connect(_draw_reel)
	add_child(_window)
	resized.connect(_fit)
	_fit()


func _fit() -> void:
	if _window:
		var edge := size.x * 0.075
		_window.position = Vector2(edge, edge)
		_window.size = size - Vector2(edge, edge) * 2.0
	pivot_offset = size * Vector2(0.5, 1.0) if compact else size * Vector2(0.0 if Settings.left_handed else 1.0, 1.0)


func set_pressed_look(on: bool) -> void:
	_down = on
	_update_scale()
	queue_redraw()


func is_spinning() -> bool:
	return _spinning


## Called every frame with the card this slot holds, and how long its spin has left.
func show_state(id: String, spin_left: float) -> void:
	_spin_target = spin_left
	if spin_left > 0.0 and id != "":
		if not _spinning or id != _id:
			_start_spin(id, spin_left)
		return
	if not _spinning and id != _id:
		_id = id
		if id != "":
			_punch(0.5)
		queue_redraw()


func _start_spin(id: String, spin_left: float) -> void:
	prepare_deck()
	_id = id
	_spinning = true
	_spin_left = spin_left
	_last_cell = 0
	_reel.clear()
	for i in REEL_CARDS - 1:
		var next := _deck[randi() % _deck.size()]
		while not _reel.is_empty() and next == _reel[_reel.size() - 1]:
			next = _deck[randi() % _deck.size()]
		_reel.append(next)
	_reel.append(id)
	PowerCard.texture(id)
	_window.visible = true
	_tween_lift(1.0)
	queue_redraw()


func _land() -> void:
	_spinning = false
	_window.visible = false
	_tween_lift(0.0)
	_punch(1.0)
	_burst = 0.0
	Audio.sfx("powerup_good", 0.8 if compact else 1.0)
	Haptics.buzz("power")
	queue_redraw()


func _tween_lift(to: float) -> void:
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		_lift = v
		_update_scale(), _lift, to, 0.16 if to > 0.0 else 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _punch(amount: float) -> void:
	_pop = amount
	_flash = amount
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		_pop = v
		_flash = v
		_update_scale()
		queue_redraw(), amount, 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _update_scale() -> void:
	var grow := (0.9 if compact else 0.32) * _lift + 0.22 * _pop - (0.05 if _down else 0.0)
	scale = Vector2.ONE * (1.0 + grow)


func _process(delta: float) -> void:
	_clock += delta
	if _burst >= 0.0:
		_burst += delta / 0.5
		if _burst >= 1.0:
			_burst = -1.0
		queue_redraw()
	if not _spinning:
		return
	_spin_left = maxf(_spin_left - delta, 0.0)
	if absf(_spin_left - _spin_target) > 0.3:  # Online, the host's clock has the last word.
		_spin_left = _spin_target
	if _spin_target <= 0.0 and _spin_left <= 0.05:
		_land()
		return
	var cell := int(_reel_position())
	if cell != _last_cell:
		_last_cell = cell
		Audio.sfx("timer_tick", 0.3 if compact else 0.45, 0.85 + 0.5 * float(cell) / REEL_CARDS)
	_window.queue_redraw()
	queue_redraw()


## How far the reel has run, in cards: fast at first, then slowing to a stop on the last one.
func _reel_position() -> float:
	var done := 1.0 - clampf(_spin_left / Sim.SPIN_TIME, 0.0, 1.0)
	return (1.0 - pow(1.0 - done, 3.0)) * (_reel.size() - 1)


func _draw_reel() -> void:
	var at := _reel_position()
	var card := _window.size
	var step := card.y * 1.06
	var first := int(at)
	for i in range(first, mini(first + 2, _reel.size())):
		var y := (at - i) * step  # Each new card comes in from above.
		var near_end := i == _reel.size() - 1 and at > _reel.size() - 2.5
		PowerCard.paint(_window, Rect2(Vector2(0, y), card), _reel[i], near_end and not compact)
	# Light falling off towards the top and bottom of the window, as on a real reel.
	var shade := card.y * 0.2
	for i in 4:
		var strength := 0.34 * (1.0 - i / 4.0)
		_window.draw_rect(Rect2(0, i * shade * 0.25, card.x, shade * 0.25), Color(UiKit.INK, strength))
		_window.draw_rect(Rect2(0, card.y - (i + 1) * shade * 0.25, card.x, shade * 0.25), Color(UiKit.INK, strength))


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if _spinning:
		_draw_machine(rect)
		return
	if _id == "":
		if not compact:
			var radius := int(size.x * 0.14)
			draw_style_box(UiKit.style(UiKit.INK, radius, 3, UiKit.RIM), rect)
			var side := size.x * 0.62
			draw_texture_rect(UiKit.icon_texture("power"), Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side)), false)
		return
	var shadow := Rect2(rect.position + Vector2(0, size.y * 0.025), rect.size)
	draw_style_box(UiKit.style(Color(UiKit.INK, 0.45), int(size.x * 0.13)), shadow)
	PowerCard.paint(self, rect, _id, not compact)
	if _flash > 0.0:
		draw_style_box(UiKit.style(Color(1, 1, 1, _flash * 0.75), int(size.x * 0.13)), rect.grow(-size.x * 0.03))
	if _burst >= 0.0:
		_draw_stars()


## A gold frame with little lights chasing round it.
func _draw_machine(rect: Rect2) -> void:
	var radius := int(size.x * 0.14)
	draw_style_box(UiKit.style(GOLD, radius, 4, UiKit.INK), rect)
	if compact:
		return
	var count := 7
	var phase := int(_clock * 14.0)
	var bulb := size.x * 0.025
	for i in count:
		var f := (i + 0.5) / count
		var lit := (i + phase) % 2 == 0
		var colour := Color.WHITE if lit else Color("c9782a")
		var inset := size.x * 0.037
		draw_circle(Vector2(inset, size.y * f), bulb, colour)
		draw_circle(Vector2(size.x - inset, size.y * f), bulb, colour)


func _draw_stars() -> void:
	var star := UiKit.icon_texture("star")
	var center := size * 0.5
	var reach := size.y * (0.5 + _burst * 0.6)
	var side := size.x * 0.28 * (1.0 - _burst)
	for i in 8:
		var a := TAU * i / 8.0 + 0.3
		var at := center + Vector2(cos(a) * reach * 0.8, sin(a) * reach)
		draw_texture_rect(star, Rect2(at - Vector2(side, side) * 0.5, Vector2(side, side)), false)
