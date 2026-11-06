extends Node
## The rules of leveling up, on a throwaway profile:
##   godot --headless --path . --audio-driver Dummy res://tests/SkillProfileTest.tscn -- --profile=skilltest

var _fails := 0


func _ok(cond: bool, what: String) -> void:
	if not cond:
		_fails += 1
		printerr("FAIL: ", what)


func _ready() -> void:
	Profile.heroes = {}
	var hero := "sir_clank"
	var own := Skills.own_skill(hero)
	var state := Profile.hero_state(hero)
	_ok(state["level"] == 1 and state["chosen"] == [own] and state["ranks"][own] == 1, "a new hero has their own skill")
	_ok(Profile.hero_points(hero) == 0, "and nothing to spend")
	_ok(not Profile.raise_skill(hero, own), "so nothing goes up")
	var look := Profile.seat_look()
	Profile.look["char"] = hero
	look = Profile.seat_look()
	_ok(look["skills"] == [[own, 1]], "and that's what you take into a match")
	_ok(not Profile.look.has("skills"), "without it sticking to how you look")
	# Up a level.
	var mine := {"won": true, "tags": 50, "captures": 3}
	var rewards := Profile.apply_match(mine, false)
	_ok(rewards["hero_leveled"], "a good match takes a new hero up a level")
	var level: int = rewards["hero_level"]
	_ok(level >= 2 and Profile.hero_points(hero) == level - 1, "with a point for each level")
	var nodes := Skills.tree(hero)
	var second := String(nodes[1]["skill"])
	var third := String(nodes[2]["skill"])
	_ok(Profile.can_raise_skill(hero, own), "you can rank up your own skill")
	_ok(Profile.can_raise_skill(hero, second), "or learn the next one")
	_ok(not Profile.can_raise_skill(hero, String(nodes[5]["skill"])), "but not one that's not open yet")
	_ok(Profile.raise_skill(hero, second), "learn it")
	_ok(Profile.hero_state(hero)["chosen"].size() == 2, "that's two")
	# Two is the limit.
	Profile.heroes[hero]["level"] = Skills.MAX_LEVEL
	_ok(not Profile.can_raise_skill(hero, third), "and there's no third")
	_ok(third not in Profile.skill_options(hero), "not even as an option")
	_ok(Profile.raise_skill(hero, own), "but you can rank up the ones you've got")
	for _i in 10:
		Profile.raise_skill(hero, own)
	_ok(Profile.hero_state(hero)["ranks"][own] == Skills.MAX_RANK, "up to the top rank")
	var before := Profile.hero_points(hero)
	Profile.drop_skill(hero, second)
	_ok(Profile.hero_points(hero) == before + 1, "take one out and you get its points back")
	_ok(Profile.can_raise_skill(hero, third), "and there's room for another")
	# Saved and loaded.
	Profile.raise_skill(hero, third)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(Profile.to_data()))
	var was: Dictionary = Profile.hero_state(hero).duplicate(true)
	Profile.heroes = {}
	Profile.apply_data(saved)
	_ok(Profile.hero_state(hero)["chosen"] == was["chosen"] and Profile.hero_state(hero)["level"] == was["level"], "it survives a save")
	# A save can say anything.
	saved["heroes"] = {"sir_clank": {"level": 999, "xp": -5, "chosen": ["fireball", "hex", "boulder", own], "ranks": {own: 99}}, "nobody": {"level": 5}, "kiko": "what"}
	Profile.apply_data(saved)
	var clean := Profile.hero_state(hero)
	_ok(clean["level"] == Skills.MAX_LEVEL and clean["xp"] == 0, "a silly save gets cleaned up")
	_ok(clean["chosen"].size() <= Skills.MAX_CHOSEN, "two skills at most")
	for skill: String in clean["chosen"]:
		_ok(int(clean["ranks"][skill]) <= Skills.MAX_RANK, "ranks in range")
	_ok(Profile.hero_points(hero) >= 0, "and no spending what you never had")
	_ok(not Profile.heroes.has("nobody") and not Profile.heroes.has("kiko"), "nobody who isn't real, or isn't what they should be")
	# Top level stops.
	Profile.heroes = {}
	for _i in 40:
		Profile.apply_match(mine, false)
	_ok(Profile.hero_state(hero)["level"] == Skills.MAX_LEVEL, "levels stop at the top")
	var path := ProjectSettings.globalize_path("user://profile_skilltest.json")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	print("SkillProfileTest: ", "OK" if _fails == 0 else "%d FAILED" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
