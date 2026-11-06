class_name Names
extends RefCounted
## Names for computer players and new accounts.

const FIRST := ["Turbo", "Sneaky", "Lucky", "Zippy", "Mighty", "Captain", "Sir", "Sunny", "Wild", "Cool", "Super", "Little", "Big", "Happy", "Boss"]
const LAST := ["Yuki", "Mei", "Priya", "Leo", "Freya", "Amara", "Zola", "Tariq", "Diego", "Luna", "Max", "Kai", "Sofia", "Noah", "Aisha", "Kenji", "Ines", "Omar", "Nia", "Hugo", "Mila", "Ravi", "Chloe", "Mateo", "Hana", "Lars", "Ayo", "Tala", "Kiko", "Lani", "Bianca", "Jin", "Emma", "Sami", "Anya", "Paolo", "Zuri", "Ivan", "Rosa", "Tomas"]
const PLAYER_A := ["Swift", "Sneaky", "Lucky", "Turbo", "Happy", "Wild", "Brave", "Mighty", "Sunny", "Silent", "Cosmic", "Spicy", "Fuzzy", "Jolly", "Rocket", "Golden"]
const PLAYER_B := ["Runner", "Tagger", "Mango", "Panda", "Tiger", "Coconut", "Comet", "Pirate", "Rooster", "Bamboo", "Falcon", "Taco", "Noodle", "Otter", "Kiwi", "Dragon"]


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
