extends Node
## The player: name, wallet, trophies, what they own and wear, stats, daily rewards and quests. Saved on
## the device in user://profile.json, and copied to the server when logged in (Net.gd), so an account
## keeps them on any device.
##
## Coins and items are decided on the device, which is fine while everything in the shop is earned, not
## bought. Trophies come from the server for online matches.

signal changed
signal item_unlocked(slot: String, id: String)
signal leveled_up(level: int)

const DEFAULT_FILE := "user://profile.json"
const VERSION := 1
const START_COINS := 300
const START_GEMS := 20
const DAILY_REWARDS: Array[Dictionary] = [
	{"coins": 100}, {"coins": 150}, {"gems": 10}, {"coins": 250}, {"coins": 300}, {"gems": 20}, {"coins": 500, "gems": 30},
]
const QUESTS: Array[Dictionary] = [
	{"id": "tags", "name": "Tag %d players", "stat": "tags", "goal": 8, "coins": 120},
	{"id": "rescues", "name": "Free %d teammates", "stat": "rescues", "goal": 3, "coins": 150},
	{"id": "captures", "name": "Capture a base %d times", "stat": "captures", "goal": 2, "coins": 200},
	{"id": "powers", "name": "Use %d powerups", "stat": "powers", "goal": 12, "coins": 100},
	{"id": "wins", "name": "Win %d matches", "stat": "wins", "goal": 2, "gems": 10},
	{"id": "games", "name": "Play %d matches", "stat": "games", "goal": 3, "coins": 150},
]

var player_name := ""
var coins := START_COINS
var gems := START_GEMS
var trophies := 0
var best_trophies := 0
var xp := 0
var level := 1
var owned := {}
var look: Dictionary = Cosmetics.default_look()
var emotes: Array[String] = []
var stats := {"games": 0, "wins": 0, "tags": 0, "rescues": 0, "captures": 0, "powers": 0, "mvps": 0}
var favorite_map := ""
var difficulty := 1  ## Index into DIFFICULTIES for practice matches.
var tutorial_done := false
var matches_played := 0
var daily_day := ""  ## The date of the last daily reward claimed.
var daily_streak := 0
var quest_day := ""
var quest_ids: Array[String] = []
var quest_progress := {}
var quest_claimed := {}
var claimed_leagues := {}
var token := ""  ## The login token for the game server.
var account := ""  ## The username, if this device logged in or registered one; empty for guests.
var guild_id := 0
var guild_name := ""
var saved_at := 0


var _file := DEFAULT_FILE


func _ready() -> void:
	# Tests can play several accounts on one machine: -- --profile=name
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--profile="):
			_file = "user://profile_%s.json" % arg.trim_prefix("--profile=").validate_filename()
	load_profile()


func load_profile() -> void:
	if not FileAccess.file_exists(_file):
		player_name = Names.new_player()
		_ensure_quests()
		save()
		return
	var text := FileAccess.get_file_as_string(_file)
	var data: Variant = JSON.parse_string(text)
	if data is Dictionary:
		apply_data(data)
	_ensure_quests()


func to_data() -> Dictionary:
	return {"version": VERSION, "name": player_name, "coins": coins, "gems": gems, "trophies": trophies, "best_trophies": best_trophies,
		"xp": xp, "level": level, "owned": owned, "look": look, "look_version": 1, "emotes": emotes, "stats": stats, "favorite_map": favorite_map,
		"difficulty": difficulty, "tutorial_done": tutorial_done, "matches_played": matches_played, "daily_day": daily_day,
		"daily_streak": daily_streak, "quest_day": quest_day, "quest_ids": quest_ids, "quest_progress": quest_progress,
		"quest_claimed": quest_claimed, "claimed_leagues": claimed_leagues, "saved_at": saved_at}


## Only what the game itself should fill in from a save (or the server); anything else is ignored.
func apply_data(data: Dictionary) -> void:
	player_name = Names.clean(str(data.get("name", player_name)))
	if player_name == "":
		player_name = Names.new_player()
	coins = maxi(int(data.get("coins", coins)), 0)
	gems = maxi(int(data.get("gems", gems)), 0)
	trophies = maxi(int(data.get("trophies", trophies)), 0)
	best_trophies = maxi(int(data.get("best_trophies", best_trophies)), trophies)
	xp = maxi(int(data.get("xp", xp)), 0)
	level = maxi(int(data.get("level", level)), 1)
	if data.get("owned") is Dictionary:
		owned = data["owned"]
	if data.get("look") is Dictionary:
		var saved_look: Dictionary = data["look"]
		look = Cosmetics.default_look()
		for slot: String in look:
			if saved_look.has(slot) and not Cosmetics.item(slot, str(saved_look[slot])).is_empty():
				look[slot] = str(saved_look[slot])
		# Everyone used to start in shades, whether they chose them or not. They can always put them back on.
		if int(data.get("look_version", 0)) < 1 and look["mask"] == "shades":
			look["mask"] = ""
	emotes.clear()
	if data.get("emotes") is Array:
		for id: Variant in data["emotes"]:
			if not Cosmetics.item("emote", str(id)).is_empty():
				emotes.append(str(id))
	if data.get("stats") is Dictionary:
		for key: String in stats:
			stats[key] = int((data["stats"] as Dictionary).get(key, stats[key]))
	favorite_map = str(data.get("favorite_map", favorite_map))
	difficulty = int(data.get("difficulty", difficulty))
	tutorial_done = bool(data.get("tutorial_done", tutorial_done))
	matches_played = int(data.get("matches_played", matches_played))
	daily_day = str(data.get("daily_day", daily_day))
	daily_streak = int(data.get("daily_streak", daily_streak))
	quest_day = str(data.get("quest_day", quest_day))
	quest_ids.clear()
	if data.get("quest_ids") is Array:
		for id: Variant in data["quest_ids"]:
			quest_ids.append(str(id))
	if data.get("quest_progress") is Dictionary:
		quest_progress = data["quest_progress"]
	if data.get("quest_claimed") is Dictionary:
		quest_claimed = data["quest_claimed"]
	if data.get("claimed_leagues") is Dictionary:
		claimed_leagues = data["claimed_leagues"]
	saved_at = int(data.get("saved_at", saved_at))
	if data.has("token"):
		token = str(data["token"])
	if data.has("account"):
		account = str(data["account"])
	if data.has("guild_id"):
		guild_id = int(data["guild_id"])
		guild_name = str(data.get("guild_name", ""))


func save() -> void:
	saved_at = int(Time.get_unix_time_from_system())
	var data := to_data()
	data["token"] = token
	data["account"] = account
	data["guild_id"] = guild_id
	data["guild_name"] = guild_name
	var file := FileAccess.open(_file, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func notify_changed(sync := true) -> void:
	save()
	changed.emit()
	if sync and token != "":
		Net.queue_profile_sync()


# --- Items ----------------------------------------------------------------------------------------

func owns(slot: String, id: String) -> bool:
	return Cosmetics.is_free(slot, id) or owned.has(Cosmetics.key(slot, id))


func can_afford(slot: String, id: String) -> bool:
	var price := Cosmetics.price(slot, id)
	return coins >= int(price["coins"]) and gems >= int(price["gems"])


func buy(slot: String, id: String) -> bool:
	if owns(slot, id) or not can_afford(slot, id) or Cosmetics.item(slot, id).is_empty():
		return false
	var price := Cosmetics.price(slot, id)
	coins -= int(price["coins"])
	gems -= int(price["gems"])
	owned[Cosmetics.key(slot, id)] = true
	item_unlocked.emit(slot, id)
	if slot == "emote" and emotes.size() < 4:
		emotes.append(id)
	notify_changed()
	return true


## Buys at a given price (today's deal, say), and wears it right away.
func buy_at(slot: String, id: String, price: Dictionary) -> bool:
	if owns(slot, id) or Cosmetics.item(slot, id).is_empty() or coins < int(price["coins"]) or gems < int(price["gems"]):
		return false
	coins -= int(price["coins"])
	gems -= int(price["gems"])
	owned[Cosmetics.key(slot, id)] = true
	item_unlocked.emit(slot, id)
	if slot == "emote":
		if emotes.size() >= 4:
			emotes.pop_front()
		emotes.append(id)
	else:
		look[slot] = id
	notify_changed()
	return true


func equip(slot: String, id: String) -> void:
	if slot == "emote" or not owns(slot, id):
		return
	look[slot] = id
	notify_changed()


## Emotes in the match's wheel: up to four. Free ones fill any empty places.
func equipped_emotes() -> Array[String]:
	var out: Array[String] = []
	for id in emotes:
		if owns("emote", id) and out.size() < 4:
			out.append(id)
	for id: String in Cosmetics.DEFAULT_EMOTES:
		if out.size() < 4 and not out.has(id):
			out.append(id)
	return out


func toggle_emote(id: String) -> void:
	if not owns("emote", id):
		return
	if emotes.has(id):
		emotes.erase(id)
	else:
		if emotes.size() >= 4:
			emotes.pop_front()
		emotes.append(id)
	notify_changed()


func rename(new_name: String) -> void:
	var clean := Names.clean(new_name)
	if clean.length() >= 3:
		player_name = clean
		notify_changed()


# --- Matches --------------------------------------------------------------------------------------

## Adds a finished match to the profile. Returns what was earned, for the results screen.
## `mine` holds this player's numbers: tags, rescues, captures, powers, won, draw, mvp.
func apply_match(mine: Dictionary, online: bool) -> Dictionary:
	var won: bool = mine.get("won", false)
	var draw: bool = mine.get("draw", false)
	var is_mvp: bool = mine.get("mvp", false)
	var tags := int(mine.get("tags", 0))
	var rescues := int(mine.get("rescues", 0))
	var captures := int(mine.get("captures", 0))
	var powers := int(mine.get("powers", 0))
	var earned_coins := (35 if won else (20 if draw else 15)) + tags * 3 + rescues * 4 + captures * 12 + mini(powers, 8)
	if is_mvp:
		earned_coins += 15
	if not online:
		earned_coins = int(earned_coins * 0.6)
	var earned_xp := (50 if won else 25) + tags * 4 + rescues * 5 + captures * 15
	coins += earned_coins
	xp += earned_xp
	var old_level := level
	while xp >= Ranks.xp_for_level(level):
		xp -= Ranks.xp_for_level(level)
		level += 1
		gems += 5
	if level > old_level:
		leveled_up.emit(level)
	stats["games"] = int(stats["games"]) + 1
	stats["tags"] = int(stats["tags"]) + tags
	stats["rescues"] = int(stats["rescues"]) + rescues
	stats["captures"] = int(stats["captures"]) + captures
	stats["powers"] = int(stats["powers"]) + powers
	if won:
		stats["wins"] = int(stats["wins"]) + 1
	if is_mvp:
		stats["mvps"] = int(stats["mvps"]) + 1
	matches_played += 1
	_ensure_quests()
	_add_quest("tags", tags)
	_add_quest("rescues", rescues)
	_add_quest("captures", captures)
	_add_quest("powers", powers)
	_add_quest("games", 1)
	if won:
		_add_quest("wins", 1)
	notify_changed()
	return {"coins": earned_coins, "xp": earned_xp, "leveled": level > old_level, "level": level}


## Trophies only ever arrive from the server (online matches).
func set_trophies(value: int) -> void:
	trophies = maxi(value, 0)
	best_trophies = maxi(best_trophies, trophies)
	notify_changed(false)


# --- League rewards -------------------------------------------------------------------------------

func league_reward_ready() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for league: Dictionary in Ranks.LEAGUES:
		if best_trophies >= int(league["min"]) and int(league["reward_gems"]) > 0 and not claimed_leagues.has(league["id"]):
			out.append(league)
	return out


func claim_league(id: String) -> int:
	for league: Dictionary in Ranks.LEAGUES:
		if league["id"] == id and best_trophies >= int(league["min"]) and not claimed_leagues.has(id):
			claimed_leagues[id] = true
			gems += int(league["reward_gems"])
			notify_changed()
			return int(league["reward_gems"])
	return 0


# --- Daily reward and quests ---------------------------------------------------------------------

func _today() -> String:
	return Time.get_date_string_from_system()


func daily_ready() -> bool:
	return daily_day != _today()


## The reward waiting today, and its day in the seven-day cycle.
func daily_next() -> Dictionary:
	var day := daily_streak % DAILY_REWARDS.size() if _streak_alive() else 0
	var reward: Dictionary = DAILY_REWARDS[day].duplicate()
	reward["day"] = day
	return reward


func _streak_alive() -> bool:
	if daily_day == "":
		return false
	var last := Time.get_unix_time_from_datetime_string(daily_day)
	var now := Time.get_unix_time_from_datetime_string(_today())
	return now - last <= 86400 * 2 - 1 or now == last


func claim_daily() -> Dictionary:
	if not daily_ready():
		return {}
	var reward := daily_next()
	daily_streak = int(reward["day"]) + 1
	daily_day = _today()
	coins += int(reward.get("coins", 0))
	gems += int(reward.get("gems", 0))
	notify_changed()
	return reward


func _ensure_quests() -> void:
	if quest_day == _today() and not quest_ids.is_empty():
		return
	quest_day = _today()
	quest_progress = {}
	quest_claimed = {}
	var seed_rng := RandomNumberGenerator.new()
	seed_rng.seed = hash(quest_day)
	var pool: Array[Dictionary] = QUESTS.duplicate()
	quest_ids.clear()
	for _i in 3:
		var pick: Dictionary = pool.pop_at(seed_rng.randi_range(0, pool.size() - 1))
		quest_ids.append(String(pick["id"]))


func _add_quest(stat: String, amount: int) -> void:
	if amount <= 0:
		return
	for id in quest_ids:
		var def := quest_def(id)
		if def.get("stat") == stat:
			quest_progress[id] = mini(int(quest_progress.get(id, 0)) + amount, int(def["goal"]))


func quest_def(id: String) -> Dictionary:
	for def: Dictionary in QUESTS:
		if def["id"] == id:
			return def
	return {}


func quest_ready_count() -> int:
	var n := 0
	for id in quest_ids:
		if not quest_claimed.has(id) and int(quest_progress.get(id, 0)) >= int(quest_def(id).get("goal", 1)):
			n += 1
	return n


func claim_quest(id: String) -> bool:
	var def := quest_def(id)
	if def.is_empty() or quest_claimed.has(id) or int(quest_progress.get(id, 0)) < int(def["goal"]):
		return false
	quest_claimed[id] = true
	coins += int(def.get("coins", 0))
	gems += int(def.get("gems", 0))
	notify_changed()
	return true
