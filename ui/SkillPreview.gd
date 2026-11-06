class_name SkillPreview
extends LiveFilm
## How a skill looks: the hero using it on a few stand-ins, over and over, on a bare field. It's the real rules and the real
## effects, so what you see here is what you get in a match.

const STAGE_MAP := "barrio_plaza"
const LOOP_SECONDS := 4.6
const FIRE_AT := 0.8
const THROW_AT := 1.3  ## When the stand-in throws something at a hero with a shield up, to show it working.
const AT_BASE := ["baselock", "hedge", "recall"]  ## Skills that happen at your base, so that's where the camera goes.
const WALK_IN := ["mines", "wall", "sentry", "zone", "hedge", "peels", "baselock", "drop", "fire_line"]  ## Better with somebody walking into them.
const PLAIN_LOOK := {"char": "kiko", "top": "tee", "pants": "shorts", "shoes": "sneakers"}

var _hero := ""
var _skill := ""
var _rank := 1
var _fired := false
var _thrown := false
var _center := Vector3.ZERO
var _reach := 17.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	super()


## Shows this skill. The film only has to be made once for a hero; after that it just changes what they're doing.
func play(hero_id: String, skill: String, rank: int) -> void:
	_skill = skill
	_rank = clampi(rank, 1, Skills.MAX_RANK)
	if hero_id != _hero:
		_hero = hero_id
		var path := Maps.thumb_path(STAGE_MAP)
		_still.texture = load(path) if ResourceLoader.exists(path) else null
		_load()
	elif _view != null and _steps.is_empty():
		_rehearse()


func _seats() -> Array:
	var look := Profile.look.duplicate()
	look["char"] = _hero
	var seats: Array = [{"name": "", "bot": false, "team": 0, "look": look}]
	for i in range(1, 10):
		var seat_look: Dictionary = PLAIN_LOOK
		if i <= 3 or i == 5:  # The ones who'll be on camera get to look like somebody.
			seat_look = Cosmetics.random_look(_rng, 0.15)
			seat_look["pet"] = ""
			seat_look["flag"] = ""
			seat_look["aura"] = ""
			seat_look["trail"] = ""
		seats.append({"name": "", "bot": false, "team": i % 2, "look": seat_look})
	return seats


func _prepare() -> void:
	_sim = Sim.new()
	_sim.setup(STAGE_MAP, _seats(), 1, 0.5, "clear")
	_sim.clear_field()
	_sim.phase = Sim.Phase.PLAY
	_add_view()
	_steps.append(_rehearse)
	_steps_total = _steps.size()


## Everybody back to their marks.
func _rehearse() -> void:
	var def := Powerups.by_id(Skills.power_id(_skill, _rank))
	var kind := String(def.get("kind", ""))
	_clock = 0.0
	_fired = false
	_thrown = false
	_sim.zones.clear()
	_sim.shots.clear()
	_sim.ents.clear()
	_sim.walls.clear()
	_sim.base_lock = [0.0, 0.0]
	_sim.take_events()
	for p: Sim.Player in _sim.players:
		p.state = Sim.State.PLAY
		p.status.clear()
		p.vel = Vector2.ZERO
		p.kb = Vector2.ZERO
		p.mv = Vector2.ZERO
		p.leap_t = -1.0
		p.free_until = -1.0
		p.on_base = false
		p.powers.clear()
		p.face = Vector2.RIGHT if p.team == 0 else Vector2.LEFT
	var me: Sim.Player = _sim.players[0]
	var front: Sim.Player = _sim.players[1]
	var size_now := _sim.arena_size()
	var mid := size_now * 0.5
	var hero_at := mid + Vector2(-7.0, 0.0)
	var focus := hero_at + Vector2(3.6, 0.0)
	_reach = 17.0
	if kind in AT_BASE:
		var home: Vector2 = _sim.base[0]
		hero_at = home + Vector2(9.0, 1.0) if kind == "recall" else home + Vector2(2.0, 6.5)
		front.pos = home + Vector2(14.0, 0.0)
		focus = home + Vector2(5.0, 0.0)
		_reach = 21.0
	elif kind == "jailbreak":
		var cell: Vector2 = _sim.jail[1]
		hero_at = cell + Vector2(-7.0, 0.0)
		focus = cell + Vector2(-3.0, 0.0)
		front.pos = cell + Vector2(-3.0, 6.0)
	else:
		front.pos = hero_at + Vector2(7.0, 0.0)
	me.pos = hero_at
	_center = Vector3(focus.x, 0.4, focus.y)
	# A teammate beside you and two more enemies, for anything that hits a lot of people.
	var buddy: Sim.Player = _sim.players[2]
	buddy.pos = hero_at + Vector2(-1.6, 2.6)
	_sim.players[3].pos = front.pos + Vector2(1.8, -3.2)
	_sim.players[5].pos = front.pos + Vector2(1.8, 3.2)
	if kind == "jailbreak":
		buddy.state = Sim.State.JAIL
		buddy.jail_left = 99.0
		buddy.pos = _sim.jail[1] + Vector2(1.0, 0.0)
	# Everybody else is well out of shot.
	var far_x: float = 3.0 if focus.x > mid.x else size_now.x - 3.0
	var row := 0
	for i: int in [4, 6, 7, 8, 9]:
		_sim.players[i].pos = Vector2(far_x, 2.0 if row % 2 == 0 else size_now.y - 2.0)
		row += 1
	if kind == "peels":
		me.face = Vector2.LEFT  # So they land between you and whoever's behind you.
	if kind == "steal":
		front.powers = ["cream_pie"] as Array[String]
	if kind == "cleanse":
		me.status["slow"] = _sim.t + 9.0
		me.status["reverse"] = _sim.t + 9.0
	if kind in WALK_IN:
		var to: Vector2 = _sim.base[0] if kind in AT_BASE else me.pos
		front.mv = (to - front.pos).normalized() * 0.34


func _fire() -> void:
	_fired = true
	var me: Sim.Player = _sim.players[0]
	var front: Sim.Player = _sim.players[1]
	var def := Powerups.by_id(Skills.power_id(_skill, _rank))
	me.skills = [[_skill, _rank]]
	me.skill_cd[0] = 0.0
	me.aim = (front.pos - me.pos).normalized()
	me.want_skill = 0
	var status: Dictionary = def.get("status", {})
	if String(def.get("kind", "")) == "self" and (status.has("speed") or status.has("roll")):
		me.mv = me.aim * 0.8
	elif String(def.get("kind", "")) == "peels":
		me.mv = Vector2.LEFT * 0.5


func _film(delta: float) -> void:
	_clock += delta
	if _sim.phase != Sim.Phase.PLAY:
		_sim.phase = Sim.Phase.PLAY
	_sim.time_left = Sim.MATCH_TIME
	_sim.cap = [0.0, 0.0]
	_sim.score = [0, 0]
	if delta > 0.0:
		if not _fired and _clock >= FIRE_AT:
			_fire()
		var status: Dictionary = Powerups.by_id(Skills.power_id(_skill, _rank)).get("status", {})
		if not _thrown and _clock >= THROW_AT and (status.has("shield") or status.has("mirror")):
			_thrown = true
			var front: Sim.Player = _sim.players[1]
			_sim._fire(front, Powerups.by_id("coconut_shot"), (_sim.players[0].pos - front.pos).normalized())
		if _clock >= LOOP_SECONDS:
			_rehearse()
	var turn := sin(Time.get_ticks_msec() * 0.0004) * 0.14
	var lift := 0.62
	if _view.camera:
		_view.camera.global_position = _center + Vector3(sin(turn) * cos(lift), sin(lift), cos(turn) * cos(lift)) * _reach
		_view.camera.look_at(_center, Vector3.UP)
		_view.film_look = _center
