class_name Ranks
extends RefCounted
## Trophies decide your league. Online wins earn trophies; practice against the AI doesn't.

const LEAGUES: Array[Dictionary] = [
	{"id": "sandal", "name": "Sandal", "min": 0, "color": Color("c98c4a"), "reward_gems": 0},
	{"id": "bamboo", "name": "Bamboo", "min": 100, "color": Color("9acb4f"), "reward_gems": 20},
	{"id": "bronze", "name": "Bronze", "min": 250, "color": Color("e08e45"), "reward_gems": 30},
	{"id": "silver", "name": "Silver", "min": 500, "color": Color("c5d0e6"), "reward_gems": 40},
	{"id": "gold", "name": "Gold", "min": 800, "color": Color("ffc21f"), "reward_gems": 60},
	{"id": "ruby", "name": "Ruby", "min": 1200, "color": Color("ff3f6a"), "reward_gems": 80},
	{"id": "sapphire", "name": "Sapphire", "min": 1700, "color": Color("3a6aff"), "reward_gems": 100},
	{"id": "amethyst", "name": "Amethyst", "min": 2300, "color": Color("b768ff"), "reward_gems": 120},
	{"id": "diamond", "name": "Diamond", "min": 3000, "color": Color("9fe6ff"), "reward_gems": 150},
	{"id": "legend", "name": "Agawan Legend", "min": 4000, "color": Color("ff9d2e"), "reward_gems": 250},
]


static func league_index(trophies: int) -> int:
	var best := 0
	for i in LEAGUES.size():
		if trophies >= int(LEAGUES[i]["min"]):
			best = i
	return best


static func league_for(trophies: int) -> Dictionary:
	return LEAGUES[league_index(trophies)]


## How far through the current league, 0..1, and the next league (empty at the top).
static func progress(trophies: int) -> Dictionary:
	var i := league_index(trophies)
	if i >= LEAGUES.size() - 1:
		return {"fraction": 1.0, "next": {}, "need": 0}
	var low := int(LEAGUES[i]["min"])
	var high := int(LEAGUES[i + 1]["min"])
	return {"fraction": float(trophies - low) / float(high - low), "next": LEAGUES[i + 1], "need": high - trophies}


## The bot skill for a player with this many trophies: new players meet gentle bots.
static func bot_skill(trophies: int) -> float:
	return clampf(0.32 + trophies / 3500.0, 0.32, 0.95)


## XP needed for each level.
static func xp_for_level(level: int) -> int:
	return 100 + (level - 1) * 40


## Trophies for an online match: a win is worth more than a loss costs, and doing well softens a loss.
static func trophy_delta(won: bool, draw: bool, is_mvp: bool, trophies: int) -> int:
	if draw:
		return 2
	var delta := 0
	if won:
		delta = 12 if trophies < 1000 else 9
	else:
		delta = -2 if trophies < 100 else (-4 if trophies < 1000 else -7)
	if is_mvp:
		delta += 3
	return delta
