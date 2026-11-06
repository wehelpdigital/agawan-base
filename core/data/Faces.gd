class_name Faces
extends RefCounted
## All the faces an avatar can pull, and when it pulls them. Avatar3D draws them.

## Every face an avatar can pull: left eye, right eye, mouth, then anything extra. See _eye, _draw_mouth, _face_extra.
const PARTS := {
	"normal": ["dot", "dot", "smile"],
	"look_l": ["dot_l", "dot_l", "smile"],
	"look_r": ["dot_r", "dot_r", "smile"],
	"blink": ["shut", "shut", "smile"],
	"happy": ["up", "up", "big"],
	"focus": ["squint", "squint", "flat"],
	"dizzy": ["x", "x", "wavy"],
	"shock": ["wide", "wide", "shock"],
	"sad": ["sad", "sad", "sad"],
	"wink": ["dot", "squint", "tongue"],
	"tongue": ["dot", "dot", "tongue"],
	"smug": ["half", "half", "smirk"],
	"grin": ["up", "up", "teeth"],
	"cat": ["up", "up", "cat", "blush"],
	"uwu": ["down", "down", "cat", "blush"],
	"blank": ["tiny", "tiny", "tiny"],
	"sideeye": ["side", "side", "flat"],
	"pout": ["dot", "dot", "pout", "blush"],
	"shy": ["dot", "dot", "wavy", "blush"],
	"nervous": ["wide", "wide", "wavy", "sweat"],
	"laugh": ["squint", "squint", "laugh", "tear"],
	"love": ["heart", "heart", "big"],
	"star": ["star", "star", "big", "sparkle"],
	"money": ["coin", "coin", "teeth"],
	"derp": ["big", "small", "tongue"],
	"cry": ["shut", "shut", "wail", "tears"],
	"angry": ["mad", "mad", "gritted", "vein"],
	"scream": ["wide", "wide", "scream"],
	"swirl": ["swirl", "swirl", "wavy"],
	"puppy": ["puppy", "puppy", "o"],
	"sleepy": ["line", "line", "o", "zzz", "bubble"],
}
## Faces whose eyes are open, so that they blink.
const BLINKING := ["normal", "look_l", "look_r", "tongue", "pout", "shy", "puppy"]
const FUNNY := ["wink", "tongue", "smug", "grin", "cat", "uwu", "blank", "sideeye", "pout", "shy", "nervous", "laugh", "love", "star", "money", "derp", "cry", "angry", "scream", "swirl", "puppy", "sleepy"]
## What the face does while something is happening. One is picked each time it happens.
const DURING := {
	"stun": ["dizzy", "swirl", "derp"],
	"freeze": ["shock", "blank", "nervous"],
	"root": ["nervous", "angry", "shock"],
	"jail": ["sad", "cry", "pout", "angry", "blank"],
	"sad": ["sad", "cry", "blank"],
	"dance": ["happy", "grin", "star", "love", "laugh", "wink"],
	"air": ["happy", "scream", "star"],
	"dash": ["focus", "angry", "grin"],
}
const TAGGING := ["smug", "laugh", "grin", "tongue", "wink", "money"]
const TAGGED := ["shock", "scream", "derp", "cry", "swirl", "nervous"]
const CHEERING := ["star", "love", "laugh", "grin", "happy", "cat"]
const BOOING := ["sad", "cry", "angry", "blank", "scream", "pout"]
const GOT_CRYSTAL := ["star", "money", "puppy", "happy"]

## Who each character is: their usual mouth and eyes, the walk they fall back on, the silly thing they do when left
## standing, the faces they pull most, and what they say about it.
const PEOPLE := {
	"kiko": {"mouth": "gap", "run": "strut", "gag": "flex", "likes": ["grin", "smug", "wink", "star"],
		"lines": ["Did you see that?!", "Too fast!", "Try and catch me!"]},
	"lani": {"mouth": "big", "gag": "wave", "likes": ["laugh", "wink", "happy", "tongue"],
		"lines": ["Hi hi hi!", "Tag? I'm in!", "You're it! Probably."]},
	"bong": {"mouth": "smirk", "eyes": "side", "run": "tiptoe", "gag": "peek", "likes": ["sideeye", "smug", "blank", "wink"],
		"lines": ["Shh...", "You didn't see me.", "Is it safe?"]},
	"maya": {"mouth": "cat", "run": "skip", "gag": "hop", "likes": ["cat", "uwu", "shy", "love"],
		"lines": ["Wheee!", "One more hop!", "Tweet tweet!"]},
	"rafael": {"mouth": "teeth", "run": "arms_back", "gag": "shout", "likes": ["laugh", "grin", "scream", "angry"],
		"lines": ["HELLOOOO!", "WAS THAT TOO LOUD?", "I'M WHISPERING!"]},
	"tala": {"mouth": "smile", "gag": "stargaze", "likes": ["star", "sleepy", "uwu", "love"],
		"lines": ["Ooh, a star!", "So many stars...", "Was that a pole?"]},
	"bantay": {"mouth": "tongue", "gag": "chase_tail", "likes": ["tongue", "puppy", "happy", "love"],
		"lines": ["Tail! TAIL!", "Almost got it!", "Who's a good boy?!"]},
	"muning": {"mouth": "cat", "run": "strut", "gag": "lick", "likes": ["smug", "sideeye", "sleepy", "cat"],
		"lines": ["Mlem.", "I meant to do that.", "Feed me."]},
	"tamaraw": {"mouth": "big", "run": "waddle", "gag": "yawn", "likes": ["sleepy", "blank", "happy", "derp"],
		"lines": ["Haaaaawn...", "Five more minutes.", "Is it lunch?"]},
	"tarsi": {"mouth": "tiny", "run": "hop", "gag": "owl_turn", "likes": ["shock", "blank", "nervous", "derp"],
		"lines": ["I see you.", "Still see you.", "Neck's fine, thanks."]},
	"tandang": {"run": "arms_back", "gag": "crow", "likes": ["scream", "laugh", "angry", "derp"],
		"lines": ["COCK-A-DOODLE-DOO!", "Wake up!", "It's 4 a.m.!"]},
	"biik": {"mouth": "big", "run": "waddle", "gag": "wiggle", "likes": ["love", "money", "happy", "laugh"],
		"lines": ["Oink!", "Wiggle wiggle!", "Got snacks?"]},
	"unggoy": {"mouth": "buck", "run": "skip", "gag": "scratch", "likes": ["laugh", "derp", "tongue", "grin"],
		"lines": ["Ooh ooh!", "Itchy!", "These your shoes?"]},
	"buko": {"mouth": "buck", "run": "waddle", "gag": "wobble", "likes": ["derp", "grin", "swirl", "tongue"],
		"lines": ["Whoa, dizzy!", "Nice umbrella, huh?", "Don't drink me!"]},
	"manga": {"mouth": "big", "run": "skip", "gag": "shy_sway", "likes": ["shy", "love", "uwu", "cat"],
		"lines": ["Oh, stop it...", "You're too sweet!", "Am I ripe yet?"]},
	"halo": {"mouth": "tongue", "run": "tiptoe", "gag": "brain_freeze", "likes": ["shock", "swirl", "tongue", "happy"],
		"lines": ["BRAIN FREEZE!", "Cold cold cold!", "Worth it!"]},
	"botbot": {"run": "robot", "gag": "glitch", "likes": ["blank", "money", "star", "swirl"],
		"lines": ["BEEP. Boop?", "Error: too cute.", "Turn me off and on?"]},
	"multo": {"mouth": "tongue", "run": "float", "gag": "boo", "likes": ["tongue", "scream", "wink", "laugh"],
		"lines": ["BOO!", "Sorry! Too scary?", "Boo? Boo."]},
	"kosmo": {"mouth": "smile", "run": "float", "gag": "hello", "likes": ["star", "swirl", "happy", "derp"],
		"lines": ["Hello, Earth!", "We come in peace!", "What's a party?"]},
	"apoy": {"mouth": "teeth", "run": "arms_back", "gag": "flare", "likes": ["grin", "angry", "laugh", "smug"],
		"lines": ["Hot stuff!", "Hug? No? OK.", "Totally fine."]},
	"yelo": {"mouth": "smile", "run": "waddle", "gag": "shiver", "likes": ["nervous", "blank", "sad", "uwu"],
		"lines": ["B-b-brrr!", "C-c-cold!", "W-who left the door open?"]},
	"yuki": {"mouth": "smile", "run": "ninja", "gag": "wave", "likes": ["happy", "focus", "wink", "uwu"],
		"lines": ["Yoroshiku!", "Sorry! Tag!", "One more round?"]},
	"mei": {"mouth": "big", "run": "skip", "gag": "hop", "likes": ["laugh", "wink", "cat", "smug"],
		"lines": ["This way, quick!", "Hungry yet?", "I know a shortcut!"]},
	"priya": {"mouth": "gap", "run": "strut", "gag": "flex", "likes": ["grin", "star", "smug", "happy"],
		"lines": ["First place again!", "Keep up!", "Nobody's faster!"]},
	"leo": {"mouth": "big", "run": "strut", "gag": "shout", "likes": ["laugh", "grin", "love", "shock"],
		"lines": ["Mamma mia!", "Ecco! A tag!", "Who wants pasta?"]},
	"freya": {"mouth": "smile", "gag": "stargaze", "likes": ["blank", "smug", "happy", "star"],
		"lines": ["This? This is warm.", "Nice breeze.", "Ooh, northern lights!"]},
	"amara": {"mouth": "teeth", "run": "skip", "gag": "wave", "likes": ["laugh", "grin", "happy", "wink"],
		"lines": ["Let's gooo!", "Too slow!", "Run, run, run!"]},
	"zola": {"mouth": "teeth", "run": "skip", "gag": "hop", "likes": ["grin", "wink", "laugh", "star"],
		"lines": ["Watch this move!", "Feel the beat!", "One more dance!"]},
	"tariq": {"mouth": "smirk", "gag": "peek", "likes": ["smug", "sideeye", "wink", "grin"],
		"lines": ["Sand everywhere.", "Yalla, yalla!", "Did you see the pyramids?"]},
	"diego": {"mouth": "gap", "run": "strut", "gag": "flex", "likes": ["grin", "smug", "laugh", "wink"],
		"lines": ["Andale!", "Taco break?", "Easy!"]},
	"luna": {"mouth": "big", "run": "skip", "gag": "hop", "likes": ["laugh", "happy", "love", "star"],
		"lines": ["La la la!", "Gol, gol, GOL!", "Dance with me!"]},
	"max": {"mouth": "smile", "gag": "wave", "likes": ["nervous", "happy", "shy", "uwu"],
		"lines": ["Sorry!", "Sorry again!", "Tag, eh? Sorry."]},
	"kai": {"mouth": "tongue", "run": "waddle", "gag": "yawn", "likes": ["sleepy", "happy", "tongue", "blank"],
		"lines": ["Aloha!", "No rush, friend.", "Surf's up. Wait, what game?"]},
}
## How long each gag lasts, and the face that goes with it.
const GAGS := {
	"flex": {"time": 1.9, "face": "grin"},
	"wave": {"time": 1.6, "face": "happy"},
	"peek": {"time": 2.2, "face": "sideeye"},
	"hop": {"time": 1.5, "face": "cat"},
	"shout": {"time": 1.6, "face": "scream"},
	"stargaze": {"time": 2.4, "face": "star"},
	"chase_tail": {"time": 2.3, "face": "tongue"},
	"lick": {"time": 1.8, "face": "tongue"},
	"yawn": {"time": 2.3, "face": "sleepy"},
	"owl_turn": {"time": 2.4, "face": "blank"},
	"crow": {"time": 1.7, "face": "scream"},
	"wiggle": {"time": 1.7, "face": "love"},
	"scratch": {"time": 1.9, "face": "derp"},
	"wobble": {"time": 2.2, "face": "swirl"},
	"shy_sway": {"time": 2.2, "face": "shy"},
	"brain_freeze": {"time": 1.6, "face": "shock"},
	"glitch": {"time": 1.7, "face": "blank"},
	"boo": {"time": 1.6, "face": "scream"},
	"hello": {"time": 2.0, "face": "happy"},
	"flare": {"time": 1.7, "face": "grin"},
	"shiver": {"time": 2.0, "face": "nervous"},
}

static var _bag: Array = []


## A different silly face each time, going through all of them before any comes back.
static func funny() -> String:
	if _bag.is_empty():
		_bag = FUNNY.duplicate()
		_bag.shuffle()
	return String(_bag.pop_back())


static func person(hero_id: String) -> Dictionary:
	return PEOPLE.get(hero_id, {})


## A silly face for this character: mostly one of their favourites.
static func funny_for(hero_id: String) -> String:
	var likes: Array = person(hero_id).get("likes", [])
	if not likes.is_empty() and randf() < 0.65:
		return String(likes[randi() % likes.size()])
	return funny()
