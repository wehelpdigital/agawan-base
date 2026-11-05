class_name Names
extends RefCounted
## Names for computer players and new accounts.

const FIRST := ["Kuya", "Ate", "Bunso", "Tito", "Tita", "Lolo", "Lola", "Totoy", "Nene", "Boss", "Pare", "Mare", "Idol", "Sir", "Kap"]
const LAST := ["Ben", "Joy", "Ricky", "Gina", "Dodong", "Inday", "Jun", "Baby", "Bong", "Rey", "Ling", "Nonoy", "Kiko", "Mayang", "Tess", "Popoy", "Waldo", "Pidoy"]
const PLAYER_A := ["Swift", "Sneaky", "Lucky", "Turbo", "Happy", "Wild", "Brave", "Mighty", "Sunny", "Silent", "Cosmic", "Spicy"]
const PLAYER_B := ["Runner", "Tagger", "Mango", "Tarsier", "Carabao", "Coconut", "Jeepney", "Sampaguita", "Pirate", "Rooster", "Bamboo", "Comet"]


static func bot_name(rng: RandomNumberGenerator) -> String:
	return "%s %s" % [FIRST[rng.randi_range(0, FIRST.size() - 1)], LAST[rng.randi_range(0, LAST.size() - 1)]]


static func new_player() -> String:
	return "%s%s%d" % [PLAYER_A.pick_random(), PLAYER_B.pick_random(), randi_range(10, 99)]


## Trims and limits a player or guild name.
static func clean(text: String, max_len := 16) -> String:
	var out := ""
	for i in text.length():
		var c := text[i]
		if c.unicode_at(0) >= 32 and c.unicode_at(0) != 127:
			out += c
	return out.strip_edges().left(max_len)
