class_name Weather
extends RefCounted
## What the sky is doing. Every kind changes how a match plays, not just how it looks. Sim reads the numbers; MatchView
## and WeatherView read the rest.
##   sight: enemies further than this from all of your team are hidden from you (metres; 0 = you see the whole field)
##   grip: how quickly your feet answer the stick (dry ground is 22; lower slides)
##   speed: everyone's running speed is multiplied by this
##   wind: gusts push players and shots this hard, and swing round every so often
##   strike: seconds between strikes from the sky on a marked spot (0 = none)
##   dash: dash recharge is multiplied by this

const ALL := {
	"clear": {"name": "Clear Skies", "icon": "w_sun", "hint": "Nice day for a chase.", "sight": 0.0, "grip": 22.0, "speed": 1.0, "wind": 0.0, "strike": 0.0, "dash": 1.0},
	"fog": {"name": "Thick Fog", "icon": "w_fog", "hint": "You can only see close by. Anything could be out there.", "sight": 12.0, "grip": 22.0, "speed": 1.0, "wind": 0.0, "strike": 0.0, "dash": 1.0,
		"veil": "ffffff", "veil_thick": 0.94, "tint": "dfe8f0", "sky": "cfdce6"},
	"night": {"name": "Moonless Night", "icon": "w_night", "hint": "Dark out. You only see what's near your team, and crystals glow.", "sight": 13.0, "grip": 22.0, "speed": 1.0, "wind": 0.0, "strike": 0.0, "dash": 1.0,
		"veil": "050a24", "veil_thick": 0.95, "tint": "5a6bb5", "sky": "0f1636"},
	"rain": {"name": "Pouring Rain", "icon": "w_rain", "hint": "Slippery ground: you slide when you turn.", "sight": 0.0, "grip": 6.5, "speed": 1.0, "wind": 0.6, "strike": 0.0, "dash": 1.0,
		"tint": "aebcdc", "sky": "7c8fb0", "fall": ["streak", 26.0, 0.09, 0.9, "cfe6ff"], "count": 240},
	"storm": {"name": "Thunderstorm", "icon": "w_storm", "hint": "Lightning hits the marked spots. Don't stand there!", "sight": 0.0, "grip": 8.0, "speed": 1.0, "wind": 1.6, "strike": 1.4, "dash": 1.0,
		"tint": "8290bd", "sky": "4a5478", "fall": ["streak", 32.0, 0.08, 1.05, "cfe6ff"], "count": 280, "strike_fx": "bolt"},
	"snow": {"name": "Blizzard", "icon": "w_snow", "hint": "Everyone's slower, the wind keeps shoving you, and you can't see far.", "sight": 17.0, "grip": 10.0, "speed": 0.9, "wind": 3.2, "strike": 0.0, "dash": 1.0,
		"veil": "f4faff", "veil_thick": 0.7, "tint": "e2ecf8", "sky": "dcebf6", "fall": ["snow", 5.0, 0.3, 0.3, "ffffff"], "count": 240},
	"hail": {"name": "Hailstorm", "icon": "w_hail", "hint": "Big lumps of ice are coming down. Watch for the shadows.", "sight": 0.0, "grip": 9.0, "speed": 1.0, "wind": 0.8, "strike": 0.9, "dash": 1.0,
		"tint": "c0d0e8", "sky": "a8bcd4", "fall": ["soft", 22.0, 0.14, 0.14, "f4fbff"], "count": 150, "strike_fx": "hail"},
	"wind": {"name": "Gale", "icon": "w_wind", "hint": "The wind pushes you and bends your shots. Watch the arrow.", "sight": 0.0, "grip": 22.0, "speed": 1.0, "wind": 5.0, "strike": 0.0, "dash": 1.0,
		"fall": ["streak", 2.0, 0.05, 0.9, "ffffff"], "count": 70, "sideways": true},
	"sand": {"name": "Sandstorm", "icon": "w_sand", "hint": "Sand in your eyes and wind at your back, or in your face.", "sight": 14.0, "grip": 22.0, "speed": 1.0, "wind": 4.2, "strike": 0.0, "dash": 1.0,
		"veil": "e0a860", "veil_thick": 0.85, "tint": "f0c890", "sky": "e8b878", "fall": ["soft", 1.5, 0.14, 0.14, "f0cf98"], "count": 240, "sideways": true},
	"heat": {"name": "Heat Wave", "icon": "w_heat", "hint": "Too hot to hurry: dashes take half as long again to recharge.", "sight": 0.0, "grip": 22.0, "speed": 1.0, "wind": 0.0, "strike": 0.0, "dash": 1.5,
		"tint": "ffe0b0", "sky": "ffd08a", "shimmer": true},
	"ash": {"name": "Lava Rain", "icon": "w_ash", "hint": "The volcano is throwing rocks. Get out of the circles!", "sight": 18.0, "grip": 22.0, "speed": 1.0, "wind": 1.0, "strike": 1.0, "dash": 1.0,
		"veil": "4a2a20", "veil_thick": 0.55, "tint": "d8a888", "sky": "7a4a38", "fall": ["puff", 3.0, 0.2, 0.2, "6a5a58"], "count": 130, "strike_fx": "lava"},
	"meteors": {"name": "Meteor Rain", "icon": "w_meteor", "hint": "Falling stars, and they land hard. Get out of the circles!", "sight": 0.0, "grip": 22.0, "speed": 1.0, "wind": 0.0, "strike": 1.1, "dash": 1.0,
		"strike_fx": "lava"},
	"blossom": {"name": "Blossom Breeze", "icon": "w_blossom", "hint": "A soft wind and falling petals. Lovely, but it does push.", "sight": 0.0, "grip": 22.0, "speed": 1.0, "wind": 1.6, "strike": 0.0, "dash": 1.0,
		"fall": ["cherry", 2.5, 0.26, 0.26, "ffc2dc"], "count": 110, "sideways": true},
}
## The order they're offered in, in the map picker.
const ORDER := ["clear", "fog", "night", "rain", "storm", "snow", "hail", "wind", "sand", "heat", "ash", "meteors", "blossom"]
const CHANCE_CLEAR := 0.3  ## How often a map you left to chance just has a nice day.


static func def(id: String) -> Dictionary:
	return ALL.get(id, ALL["clear"])


## This map's weather today, from what can happen there.
static func roll(theme: Dictionary, rng: RandomNumberGenerator) -> String:
	var kinds: Array = theme.get("weather", [])
	if kinds.is_empty() or rng.randf() < CHANCE_CLEAR:
		return "clear"
	return String(kinds[rng.randi_range(0, kinds.size() - 1)])
