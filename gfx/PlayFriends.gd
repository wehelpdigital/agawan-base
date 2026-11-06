class_name PlayFriends
extends Node3D
## Your friends on the home screen's little world, so you're never out there alone: two play tag behind you, three skip rope
## and two throw a ball about, badly. They arrive one at a time, so the screen opens straight away. All for show, and nobody
## ever crosses in front of you: it's your avatar on show here.

signal said(line: String, at: Vector3)  ## One of them has something to say, from about here.

const FRIEND_SIZE := 0.62
const WIDE_ROOM := 2.6  ## How far out to each side there's room on a wide screen. A narrower one brings everybody in.
const LEAST_ROOM := 0.72
const FIRST_WAIT := 0.3
const NEXT_WAIT := 0.12
const QUIET_MSEC := 4500  ## They take turns to talk.
const HEAD_HEIGHT := 2.05

const SIDE_X := 1.6  ## Where the rope and the ball games are, either side of you and a little behind.
const SIDE_Z := -1.05

const TRACK_X := 2.05  ## The way tag runs, from side to side: a curve round the back of you, coming forward at each end.
const TRACK_BACK_Z := -0.62
const TRACK_BEND := 0.82
const RUN_SPEED := 1.9
const CATCH_UP := 1.15
const TAG_REACH := 0.62

const ROPE_SPOT := 0.85  ## How far from the skipper each one turning it stands.
const ROPE_HALF := 0.58
const ROPE_REACH := 0.66
const ROPE_AXIS := 0.46
const ROPE_SECONDS := 1.0
const SKIPPER_SIZE := 0.48  ## Smaller, so the rope clears their head.
const SKIP_HEIGHT := 0.26

const BALL_SPOT := 0.72
const BALL_RADIUS := 0.15
const BALL_HANDS := Vector2(0.3, 0.56)  ## In from where they stand, and up.
const BALL_HEAD := 1.1
const BONK_CHANCE := 0.2

const TAG_LINES := ["Tag! You're it!", "Got you!", "Too slow!", "Gotcha!"]
const CHASE_LINES := ["Get back here!", "No fair!", "I'll get you!", "Rematch!"]
const RUN_LINES := ["Can't catch me!", "Come and play!", "Over here!", "Catch me!"]
const BONK_LINES := ["Ow!", "My head!", "I meant to do that.", "Who threw that?"]
const TRIP_LINES := ["Oops!", "My feet!", "Again!", "It was the rope!"]
const POP_COLORS := [Color("ffd23f"), Color("ff5247"), Color("19d3e6"), Color("ffffff")]
const BUTTERFLY_COLORS := [Color("ffd23f"), Color("ff6fb5"), Color("a98bff"), Color("ffffff")]
const BUTTERFLY_SECONDS := 1.3

static var _looks: Array[Dictionary] = []  ## The same friends all session, so they feel like yours.

var _radius := 3.4
var _room := 1.0
var _fx: FxField
var _you: Avatar3D
var _todo: Array[Callable] = []
var _todo_wait := FIRST_WAIT
var _friends: Array[Avatar3D] = []
var _quiet_until := 0
var _butterfly_wait := 1.0
var _left: Node3D
var _right: Node3D

var _seats: Array[Node3D] = []
var _runners: Array[Avatar3D] = []
var _track: Array[float] = [-0.1, -1.0]  ## How far along each runner has got, from -1 to 1.
var _holds: Array[float] = [0.2, 0.2]  ## How long before each runner sets off.
var _it := 1
var _way := 1.0

var _turners: Array[Avatar3D] = []
var _skipper: Avatar3D
var _rope: MeshInstance3D
var _rope_turn := 0.0
var _rope_stop := 0.0
var _skips := 0
var _trip_at := 0

var _throwers: Array[Avatar3D] = []
var _ball: MeshInstance3D
var _holding := 0
var _catching := 1
var _ball_wait := 0.7
var _flight := -1.0  ## 0 to 1 while the ball's in the air.
var _flight_time := 1.0
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _arc := 1.0
var _bonk := false
var _dazed := -1
var _dazed_left := 0.0


## `radius` is the planet's, with its top at y = 0. Set the room with set_room().
func setup(radius: float, fx: FxField, you: Avatar3D) -> void:
	_radius = radius
	_fx = fx
	_you = you
	_trip_at = randi_range(7, 18)
	_left = Node3D.new()
	add_child(_left)
	_right = Node3D.new()
	add_child(_right)
	set_room(WIDE_ROOM)
	_todo = [_add_runner, _add_runner, _add_thrower.bind(-1.0), _add_thrower.bind(1.0)]
	if Settings.quality != "low" and not Quality.auto_lowered:  # Phones too: a match shows more than this.
		_todo.append_array([_add_turner.bind(-1.0), _add_turner.bind(1.0), _add_skipper])


## Fits everybody into a picture that shows this far to each side of you.
func set_room(half_width: float) -> void:
	_room = clampf(half_width / WIDE_ROOM, LEAST_ROOM, 1.0)
	_left.transform = _game_spot(-1.0)
	_right.transform = _game_spot(1.0)


## Everybody who's watching is pleased with you.
func cheer() -> void:
	for who in _friends:
		if randf() < 0.6:
			who.react_any(Faces.CHEERING, 1.2)
			who.squash(0.2)


func _process(delta: float) -> void:
	_todo_wait -= delta
	if _todo_wait <= 0.0 and not _todo.is_empty():
		_todo_wait = NEXT_WAIT
		(_todo.pop_front() as Callable).call()
	if _runners.size() == 2:
		_play_tag(delta)
	if _throwers.size() == 2:
		_play_ball(delta)
	if _skipper:
		_play_rope(delta)
	_butterfly_wait -= delta
	if _butterfly_wait <= 0.0:
		_butterfly_wait = BUTTERFLY_SECONDS * randf_range(0.6, 1.4)
		_add_butterfly()


# --- Who's here -----------------------------------------------------------------------------------

func _game_spot(side: float) -> Transform3D:
	var place := _on_planet(side * SIDE_X * _room, SIDE_Z, Vector3(-side * 0.35, 0, 1))
	var fit := lerpf(0.82, 1.0, inverse_lerp(LEAST_ROOM, 1.0, _room))
	return Transform3D(place.basis.scaled(Vector3.ONE * fit), place.origin)


## Standing on the planet at this spot, as seen from above, and facing this way.
func _on_planet(x: float, z: float, facing: Vector3) -> Transform3D:
	var up := Vector3(x, sqrt(maxf(_radius * _radius - x * x - z * z, 0.01)), z).normalized()
	var ahead := (facing - up * facing.dot(up)).normalized()
	return Transform3D(Basis(up.cross(ahead), up, ahead), up * _radius - Vector3(0, _radius, 0))


## Out to one side, where it won't flutter across your face.
func _add_butterfly() -> void:
	var side := -1.0 if randf() < 0.5 else 1.0
	var at := Vector3(side * randf_range(1.2, 2.7) * _room, randf_range(0.5, 1.9), randf_range(-1.0, 0.2))
	var drift := Vector3(-side * randf_range(0.05, 0.3), randf_range(0.05, 0.25), randf_range(-0.1, 0.1))
	_fx.spawn(at, drift, 3.2, 0.2, Cosmetics.Fx.BUTTERFLY, BUTTERFLY_COLORS[randi() % BUTTERFLY_COLORS.size()], randf_range(-0.5, 0.5))


func _look_for(index: int) -> Dictionary:
	while _looks.size() <= index:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var look := Cosmetics.random_look(rng, 0.3)
		while _looks.any(func(other: Dictionary) -> bool: return other["char"] == look["char"]):
			look = Cosmetics.random_look(rng, 0.3)
		for slot: String in ["pet", "flag", "aura"]:
			look[slot] = ""
		_looks.append(look)
	return _looks[index]


func _add_friend(parent: Node3D, at: Vector3, yaw: float, size := FRIEND_SIZE) -> Avatar3D:
	var index := _friends.size()
	var look := _look_for(index)
	if size < FRIEND_SIZE:  # Nothing tall on the one under the rope.
		look = look.duplicate()
		look["hat"] = ""
	var who := Avatar3D.new()
	parent.add_child(who)
	who.setup(look, ArenaBuilder.team_color(index % 2))
	who.position = at
	who.rotation.y = yaw
	who.scale = Vector3.ONE * 0.01
	create_tween().tween_property(who, "scale", Vector3.ONE * size, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	who.gag_started.connect(_speak.bind(who))
	_friends.append(who)
	return who


func _speak(line: String, who: Avatar3D, always := false) -> void:
	if line == "" or (Time.get_ticks_msec() < _quiet_until and not always):
		return
	_quiet_until = Time.get_ticks_msec() + QUIET_MSEC
	said.emit(line, who.to_global(Vector3(0, HEAD_HEIGHT, 0)))


func _any(lines: Array) -> String:
	return String(lines[randi() % lines.size()])


# --- Tag ------------------------------------------------------------------------------------------

func _add_runner() -> void:
	var seat := Node3D.new()
	add_child(seat)
	_seats.append(seat)
	_runners.append(_add_friend(seat, Vector3.ZERO, 0.0))
	_place_runner(_runners.size() - 1)


func _track_point(along: float) -> Vector2:
	return Vector2(along * TRACK_X * _room, TRACK_BACK_Z + along * along * TRACK_BEND)


func _place_runner(i: int) -> void:
	var at := _track_point(_track[i])
	var ahead := _track_point(_track[i] + _way * 0.02) - at
	_seats[i].transform = _on_planet(at.x, at.y, Vector3(ahead.x, 0, ahead.y))


func _play_tag(delta: float) -> void:
	for i in 2:
		var who := _runners[i]
		if _holds[i] > 0.0:
			_holds[i] -= delta
			if _holds[i] <= 0.0:
				who.state = "run"
				who.moving = 1.0
				_speak(_any(CHASE_LINES if i == _it else RUN_LINES), who)
		elif who.state == "run":
			var along := _track[i]
			var stretch := _track_point(along).distance_to(_track_point(along + 0.02)) / 0.02
			_track[i] = along + _way * RUN_SPEED * (CATCH_UP if i == _it else 1.0) * delta / stretch
			if absf(_track[i]) > 0.4:  # Not while behind you: the sparkles would go over you.
				who.emit_effects(_fx, delta, true)
			if absf(_track[i]) >= 1.0 and i != _it:  # Nowhere left to run.
				_track[i] = _way
				who.state = "idle"
				who.moving = 0.0
				who.react("nervous", 2.0)
		_place_runner(i)
	if _holds[0] <= 0.0 and _holds[1] <= 0.0 and _track_point(_track[0]).distance_to(_track_point(_track[1])) < TAG_REACH:
		_tag()


func _tag() -> void:
	var tagger := _runners[_it]
	var tagged := _runners[1 - _it]
	tagger.state = "air"
	tagger.moving = 0.0
	tagger.react_any(Faces.TAGGING, 1.6)
	tagged.state = "stun"
	tagged.moving = 0.0
	tagged.react_any(Faces.TAGGED, 1.8)
	tagged.squash(0.4)
	tagged.flash()
	var spot := tagged.to_global(Vector3(0, 1.7, 0))
	_pop("TAG!", spot)
	_fx.burst(spot, 14, 2.6, 0.6, 0.24, Cosmetics.Fx.STAR, POP_COLORS, 4.0)
	_speak(_any(TAG_LINES), tagger, true)
	_you.react_any(Faces.CHEERING, 1.2)
	_it = 1 - _it
	_way = -_way
	_holds[_it] = 2.3
	_holds[1 - _it] = 1.2


func _pop(text: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.font = UiKit.font_title()
	label.font_size = 40
	label.outline_size = 12
	label.pixel_size = 0.008
	label.modulate = UiKit.YELLOW
	label.outline_modulate = UiKit.INK
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 3
	label.position = to_local(at)
	label.scale = Vector3.ONE * 0.4
	add_child(label)
	var tween := create_tween().set_parallel()
	tween.tween_property(label, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y + 0.5, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.25).set_delay(0.65)
	tween.tween_property(label, "outline_modulate:a", 0.0, 0.25).set_delay(0.65)
	tween.chain().tween_callback(label.queue_free)


# --- The ball -------------------------------------------------------------------------------------

func _add_thrower(side: float) -> void:
	_throwers.append(_add_friend(_right, Vector3(side * BALL_SPOT, 0, 0), -side * 0.75))
	if _throwers.size() == 2:
		_ball = MeshInstance3D.new()
		_ball.mesh = _ball_mesh()
		_ball.material_override = Avatar3D._material("normal")
		_ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_ball.position = _ball_hands(_holding)
		_right.add_child(_ball)


static func _ball_mesh() -> ArrayMesh:
	var k := MeshKit.new()
	k.soften = true
	k.shells = false
	var r := Vector3.ONE * BALL_RADIUS
	k.ball(Vector3.ZERO, r, Color("ffffff"), 10, 16)
	k.outline = 0.0
	k.band(Vector3.ZERO, r, 0.42, 0.8, UiKit.CORAL)
	k.band(Vector3.ZERO, r, -0.19, 0.19, UiKit.AQUA)
	k.band(Vector3.ZERO, r, -0.8, -0.42, UiKit.YELLOW)
	return k.to_mesh()


func _ball_hands(i: int) -> Vector3:
	var side := -1.0 if i == 0 else 1.0
	return Vector3(side * (BALL_SPOT - BALL_HANDS.x), BALL_HANDS.y, BALL_RADIUS)


func _ball_head(i: int) -> Vector3:
	return Vector3((-1.0 if i == 0 else 1.0) * BALL_SPOT, BALL_HEAD, 0)


func _play_ball(delta: float) -> void:
	if _dazed >= 0:
		_dazed_left -= delta
		if _dazed_left <= 0.0:
			_throwers[_dazed].state = "idle"
			_dazed = -1
	if _flight < 0.0:
		_ball_wait -= delta
		if _ball_wait <= 0.0:
			_throw()
		return
	_ball.rotation.x += delta * 8.0
	_flight += delta / _flight_time
	if _flight >= 1.0:
		_land()
		return
	_ball.position = _from.lerp(_to, _flight) + Vector3.UP * _arc * 4.0 * _flight * (1.0 - _flight)
	if not _bonk and _flight > 0.45:
		_throwers[_catching].state = "air"


func _throw() -> void:
	_catching = 1 - _holding
	_bonk = randf() < BONK_CHANCE and _dazed < 0
	_throwers[_holding].state = "idle"
	_throwers[_holding].squash(0.22)
	_send_ball(_ball_head(_catching) if _bonk else _ball_hands(_catching), 0.95, 1.05)


func _send_ball(to: Vector3, seconds: float, arc: float) -> void:
	_from = _ball.position
	_to = to
	_flight = 0.0
	_flight_time = seconds
	_arc = arc


func _land() -> void:
	_flight = -1.0
	var catcher := _throwers[_catching]
	if not _bonk:
		catcher.state = "idle"
		catcher.squash(0.22)
		catcher.react_any(Faces.CHEERING, 0.8)
		_holding = _catching
		_ball_wait = 0.5
		return
	# Right on the head. It bounces back to whoever threw it, who thinks it's very funny.
	_bonk = false
	catcher.state = "stun"
	catcher.squash(0.4)
	catcher.react_any(Faces.TAGGED, 1.8)
	_dazed = _catching
	_dazed_left = 1.7
	var thrower := _throwers[_holding]
	thrower.react("laugh", 1.6)
	_fx.burst(_ball.global_position, 9, 1.8, 0.5, 0.2, Cosmetics.Fx.STAR, POP_COLORS, 3.0)
	_speak(_any(BONK_LINES), catcher, true)
	_you.react("laugh", 1.2)
	_catching = _holding
	_send_ball(_ball_hands(_holding), 0.8, 0.8)


# --- The skipping rope ----------------------------------------------------------------------------

func _add_turner(side: float) -> void:
	var who := _add_friend(_left, Vector3(side * ROPE_SPOT, 0, 0), -side * 0.45)
	who.state = "turning"
	_turners.append(who)


func _add_skipper() -> void:
	_skipper = _add_friend(_left, Vector3.ZERO, 0.0, SKIPPER_SIZE)
	_skipper.state = "air"
	_rope = MeshInstance3D.new()
	_rope.mesh = _rope_mesh()
	_rope.material_override = Avatar3D._material("normal")
	_rope.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rope.position = Vector3(0, ROPE_AXIS, 0)
	_left.add_child(_rope)


static func _rope_mesh() -> ArrayMesh:
	var k := MeshKit.new()
	k.shells = false
	k.outline = 0.0
	var path := PackedVector3Array()
	for i in 21:
		var t := i / 10.0 - 1.0
		path.append(Vector3(t * ROPE_HALF, ROPE_REACH * pow(1.0 - t * t, 0.6), 0))
	k.tube(path, 0.03, UiKit.PINK, false, 6)
	return k.to_mesh()


func _play_rope(delta: float) -> void:
	if _rope_stop > 0.0:
		_rope_stop -= delta
		if _rope_stop <= 0.0:
			_skipper.state = "air"
			for who in _turners:
				who.state = "turning"
		return
	var was := _rope_turn
	_rope_turn = fmod(_rope_turn + delta / ROPE_SECONDS, 1.0)
	_rope.rotation.x = PI + _rope_turn * TAU  # Under their feet at 0, over their head at a half.
	var tripping := _skips >= _trip_at
	var height := 0.0 if tripping else SKIP_HEIGHT * maxf(cos(_rope_turn * TAU), 0.0)
	_skipper.position.y = move_toward(_skipper.position.y, height, delta * 3.0)
	if tripping and was < 0.95 and _rope_turn >= 0.95:
		_trip()
	elif was < 0.25 and _rope_turn >= 0.25:  # Down again.
		_skips += 1
		_skipper.squash(0.16)
		if _skips % 5 == 0:
			_speak("%d!" % _skips, _skipper)


func _trip() -> void:
	_skips = 0
	_trip_at = randi_range(7, 18)
	_rope_stop = 1.7
	_skipper.position.y = 0.0
	_skipper.state = "stun"
	_skipper.squash(0.35)
	_skipper.react_any(Faces.TAGGED, 1.7)
	for who in _turners:
		who.state = "idle"
		who.react("laugh", 1.6)
	_speak(_any(TRIP_LINES), _skipper, true)
