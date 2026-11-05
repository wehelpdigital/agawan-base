class_name Faces
extends RefCounted
## All the faces an avatar can pull, and when it pulls them. Avatar3D draws them.

## Every face an avatar can pull: left eye, right eye, mouth, then anything extra. See _eye, _draw_mouth, _face_extra.
const PARTS := {
	"normal": ["dot", "dot", "smile"],
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
const BLINKING := ["normal", "tongue", "pout", "shy", "puppy"]
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

static var _bag: Array = []


## A different silly face each time, going through all of them before any comes back.
static func funny() -> String:
	if _bag.is_empty():
		_bag = FUNNY.duplicate()
		_bag.shuffle()
	return String(_bag.pop_back())
