class_name Cosmetics
extends RefCounted
## The whole shop, organised by what you wear and do, not by character: masks, head gear, tops, pants,
## shoes, gloves, backs, run styles, dances, emotes, trails, auras, tag bursts, frames and titles. The
## avatar underneath is just one more choice. Everything is earned by playing. Prices: `coins` or `gems`;
## an item with neither (rarity "free") is yours from the start.
##
## An avatar's look is a dictionary with one entry per slot (see default_look).

const SLOTS := ["mask", "hat", "top", "pants", "shoes", "gloves", "back", "run", "dance", "emote", "trail", "aura", "burst", "frame", "title", "char", "skin"]
const SLOT_INFO := {
	"mask": {"name": "Masks", "icon": "mask"},
	"hat": {"name": "Head Gear", "icon": "hat"},
	"top": {"name": "Tops", "icon": "top"},
	"pants": {"name": "Pants", "icon": "pants"},
	"shoes": {"name": "Shoes", "icon": "shoes"},
	"gloves": {"name": "Gloves", "icon": "gloves"},
	"back": {"name": "Backs", "icon": "backpack"},
	"run": {"name": "Run Styles", "icon": "dash"},
	"dance": {"name": "Dances", "icon": "dance"},
	"emote": {"name": "Emotes", "icon": "emote"},
	"trail": {"name": "Trails", "icon": "trail"},
	"aura": {"name": "Auras", "icon": "aura"},
	"burst": {"name": "Tag FX", "icon": "burst"},
	"frame": {"name": "Frames", "icon": "frame"},
	"title": {"name": "Titles", "icon": "title"},
	"char": {"name": "Avatars", "icon": "avatar"},
	"skin": {"name": "Colours", "icon": "star"},
}
## The shop's top row. Accessories come first; avatars are one choice among them.
const GROUPS: Array[Dictionary] = [
	{"id": "wear", "name": "Wear", "icon": "mask", "slots": ["mask", "hat", "top", "pants", "shoes", "gloves", "back"]},
	{"id": "moves", "name": "Moves", "icon": "dance", "slots": ["run", "dance", "emote"]},
	{"id": "effects", "name": "Effects", "icon": "aura", "slots": ["trail", "aura", "burst"]},
	{"id": "profile", "name": "Profile", "icon": "frame", "slots": ["frame", "title"]},
	{"id": "avatars", "name": "Avatars", "icon": "avatar", "slots": ["char", "skin"]},
]
## Slots whose shop card is a picture of the item alone, rendered from its 3D model.
const BAKED_SLOTS := ["char", "mask", "hat", "top", "pants", "shoes", "gloves", "back"]
const RARITY := {
	"free": {"name": "Free", "color": Color("9aa3b8"), "coins": 0, "gems": 0},
	"common": {"name": "Common", "color": Color("6fcf6a"), "coins": 200, "gems": 0},
	"rare": {"name": "Rare", "color": Color("3aa6ff"), "coins": 600, "gems": 0},
	"epic": {"name": "Epic", "color": Color("b768ff"), "coins": 1500, "gems": 0},
	"legend": {"name": "Legendary", "color": Color("ffc21f"), "coins": 0, "gems": 120},
}
## Atlas cells in assets/fx/atlas.png.
enum Fx { SOFT, STAR, HEART, SPARK, RING, FLAME, LEAF, NOTE, PIXEL, PUFF, SNOW, COIN, BOLT, PETAL, DROP, CONFETTI }

## Worn over the face or the whole head. `cover` says how much of the head they hide: "eyes", "low" (nose and
## mouth), "plate" (the whole face) or "whole" (they replace the head). `no_hat`: they already are a hat.
const MASKS: Array[Dictionary] = [
	{"id": "", "name": "No Mask", "rarity": "free"},
	{"id": "shades", "name": "Cool Shades", "cover": "eyes", "rarity": "free"},
	{"id": "bandana", "name": "Bandit Bandana", "cover": "low", "rarity": "free"},
	{"id": "domino", "name": "Hero Mask", "cover": "eyes", "rarity": "common"},
	{"id": "ninja", "name": "Ninja Wrap", "cover": "whole", "rarity": "common"},
	{"id": "snorkel", "name": "Snorkel", "cover": "eyes", "rarity": "common"},
	{"id": "panda", "name": "Panda Face", "cover": "whole", "rarity": "common"},
	{"id": "tiger", "name": "Tiger Face", "cover": "whole", "rarity": "rare"},
	{"id": "luchador", "name": "Luchador", "cover": "whole", "rarity": "rare"},
	{"id": "clown", "name": "Clown Face", "cover": "plate", "rarity": "rare"},
	{"id": "tiki", "name": "Tiki Mask", "cover": "whole", "rarity": "rare"},
	{"id": "kitsune", "name": "Fox Spirit", "cover": "plate", "rarity": "rare"},
	{"id": "pixel", "name": "Pixel Visor", "cover": "eyes", "rarity": "rare"},
	{"id": "oni", "name": "Ogre Mask", "cover": "plate", "rarity": "epic"},
	{"id": "skull", "name": "Skull Face", "cover": "plate", "rarity": "epic"},
	{"id": "plague", "name": "Beak Mask", "cover": "plate", "rarity": "epic"},
	{"id": "knight", "name": "Knight Visor", "cover": "whole", "rarity": "epic"},
	{"id": "robot", "name": "Robo Face", "cover": "whole", "rarity": "epic"},
	{"id": "pumpkin", "name": "Pumpkin Head", "cover": "whole", "rarity": "epic"},
	{"id": "masskara", "name": "MassKara Smile", "cover": "plate", "rarity": "legend", "blurb": "The smiling festival mask of Bacolod."},
	{"id": "higante", "name": "Higante Giant", "cover": "whole", "rarity": "legend", "blurb": "A papier-mache giant head, as paraded in Angono."},
	{"id": "moriones", "name": "Roman Morion", "cover": "whole", "no_hat": true, "rarity": "legend", "blurb": "After the carved Holy Week helmets of Marinduque."},
	{"id": "golden", "name": "Golden Face", "cover": "plate", "rarity": "legend"},
	{"id": "galaxy", "name": "Starfield Face", "cover": "plate", "rarity": "legend"},
]

## Hats that can't go with this mask: it is a helmet already, or the hat is a helmet too.
static func wearing_clash(mask_id: String, hat_id: String) -> bool:
	if mask_id == "" or hat_id == "":
		return false
	var mask := item("mask", mask_id)
	if mask.get("no_hat", false):
		return true
	return hat_id == "astronaut" and String(mask.get("cover", "")) in ["plate", "whole"]


## Style sets the shape; c and c2 are its colours.
const TOPS: Array[Dictionary] = [
	{"id": "", "name": "Avatar's Own", "rarity": "free"},
	{"id": "tee", "name": "White Tee", "rarity": "free", "style": "tee", "c": "f6f3ff", "c2": "ff5a4e"},
	{"id": "sando", "name": "Sando Tank", "rarity": "free", "style": "tank", "c": "ffd23f", "c2": "ff7a1f"},
	{"id": "stripes", "name": "Sailor Stripes", "rarity": "common", "style": "stripes", "c": "ffffff", "c2": "2f5fd0"},
	{"id": "hoodie", "name": "Hoodie", "rarity": "common", "style": "hoodie", "c": "8d8ba8", "c2": "5c5a78"},
	{"id": "dots", "name": "Polka Dots", "rarity": "common", "style": "dots", "c": "ff6fb5", "c2": "ffffff"},
	{"id": "jersey", "name": "Hoops Jersey", "rarity": "common", "style": "jersey", "c": "e8483f", "c2": "ffffff"},
	{"id": "aloha", "name": "Island Shirt", "rarity": "rare", "style": "floral", "c": "19b8d6", "c2": "ffd23f"},
	{"id": "barong", "name": "Barong", "rarity": "rare", "style": "barong", "c": "fff6dd", "c2": "d9b774", "blurb": "Fine embroidered Filipino formal wear."},
	{"id": "varsity", "name": "Varsity Jacket", "rarity": "rare", "style": "varsity", "c": "2b2466", "c2": "ffd23f"},
	{"id": "overalls", "name": "Overalls", "rarity": "rare", "style": "overalls", "c": "3f7fd0", "c2": "ffb21f"},
	{"id": "gi", "name": "Ninja Gi", "rarity": "epic", "style": "gi", "c": "2b2448", "c2": "e8483f"},
	{"id": "pirate", "name": "Pirate Coat", "rarity": "epic", "style": "coat", "c": "a02a2a", "c2": "ffd23f"},
	{"id": "tux", "name": "Tuxedo", "rarity": "epic", "style": "tux", "c": "1d1a30", "c2": "ffffff"},
	{"id": "space", "name": "Space Suit", "rarity": "epic", "style": "space", "c": "e8ecf9", "c2": "ff7a1f"},
	{"id": "armor", "name": "Knight Plate", "rarity": "legend", "style": "armor", "c": "c5d0e6", "c2": "8f97b0"},
	{"id": "gold", "name": "Gold Plate", "rarity": "legend", "style": "armor", "c": "ffc21f", "c2": "e08e1f"},
	{"id": "galaxy", "name": "Galaxy Tee", "rarity": "legend", "style": "galaxy", "c": "2a1a6e", "c2": "ff6fb5"},
]

const PANTS: Array[Dictionary] = [
	{"id": "", "name": "Avatar's Own", "rarity": "free"},
	{"id": "shorts", "name": "Blue Shorts", "rarity": "free", "style": "shorts", "c": "2f5fd0", "c2": "ffffff"},
	{"id": "jeans", "name": "Jeans", "rarity": "free", "style": "long", "c": "3f6fb8", "c2": "ffd23f"},
	{"id": "track", "name": "Track Pants", "rarity": "common", "style": "track", "c": "24135f", "c2": "ffffff"},
	{"id": "cargo", "name": "Cargo Pants", "rarity": "common", "style": "cargo", "c": "77804a", "c2": "5a6135"},
	{"id": "stripes", "name": "Striped Shorts", "rarity": "common", "style": "stripes", "c": "ff5a4e", "c2": "ffffff"},
	{"id": "checks", "name": "Picnic Checks", "rarity": "common", "style": "checks", "c": "35d07f", "c2": "ffffff"},
	{"id": "board", "name": "Board Shorts", "rarity": "rare", "style": "floral", "c": "ff7a3c", "c2": "fff1a8"},
	{"id": "pajama", "name": "Pajamas", "rarity": "rare", "style": "dots", "c": "9fb4ff", "c2": "ffffff"},
	{"id": "tutu", "name": "Tutu", "rarity": "rare", "style": "tutu", "c": "ff9fd8", "c2": "ffffff"},
	{"id": "kilt", "name": "Tartan Kilt", "rarity": "epic", "style": "kilt", "c": "c9302a", "c2": "24135f"},
	{"id": "grass", "name": "Grass Skirt", "rarity": "epic", "style": "grass", "c": "6ccf5a", "c2": "d9c25a"},
	{"id": "armor", "name": "Plate Legs", "rarity": "epic", "style": "armor", "c": "c5d0e6", "c2": "8f97b0"},
	{"id": "neon", "name": "Neon Racers", "rarity": "legend", "style": "track", "c": "ff2fc0", "c2": "27e9ff"},
	{"id": "gold", "name": "Gold Leg Plates", "rarity": "legend", "style": "armor", "c": "ffc21f", "c2": "e08e1f"},
	{"id": "galaxy", "name": "Galaxy Pants", "rarity": "legend", "style": "galaxy", "c": "2a1a6e", "c2": "b768ff"},
]

const SHOES: Array[Dictionary] = [
	{"id": "", "name": "Avatar's Own", "rarity": "free"},
	{"id": "sneakers", "name": "Sneakers", "rarity": "free", "style": "sneaker", "c": "f6f3ff", "c2": "ff5a4e"},
	{"id": "tsinelas", "name": "Tsinelas", "rarity": "free", "style": "slipper", "c": "3aa6ff", "c2": "ffffff", "blurb": "The Filipino flip-flop, also good for throwing."},
	{"id": "hitops", "name": "Hi-Tops", "rarity": "common", "style": "hitop", "c": "e8483f", "c2": "ffffff"},
	{"id": "rainboots", "name": "Rain Boots", "rarity": "common", "style": "boot", "c": "ffd23f", "c2": "e8a81f"},
	{"id": "cowboy", "name": "Cowboy Boots", "rarity": "rare", "style": "boot", "c": "9a5f30", "c2": "e0b35e"},
	{"id": "clown", "name": "Clown Shoes", "rarity": "rare", "style": "clown", "c": "ff3f5a", "c2": "ffd23f"},
	{"id": "bunny", "name": "Bunny Slippers", "rarity": "rare", "style": "bunny", "c": "ffd0e6", "c2": "ff8fc8"},
	{"id": "flippers", "name": "Flippers", "rarity": "rare", "style": "flipper", "c": "19b8d6", "c2": "0f7f99"},
	{"id": "skates", "name": "Roller Skates", "rarity": "epic", "style": "roller", "c": "ff6fb5", "c2": "ffd23f"},
	{"id": "rocket", "name": "Rocket Boots", "rarity": "epic", "style": "rocket", "c": "c9d0e6", "c2": "ff7a1f"},
	{"id": "neon", "name": "Neon Kicks", "rarity": "legend", "style": "hitop", "c": "27e9ff", "c2": "ff2fc0"},
	{"id": "gold", "name": "Golden Kicks", "rarity": "legend", "style": "sneaker", "c": "ffc21f", "c2": "fff0a8"},
]

const GLOVES: Array[Dictionary] = [
	{"id": "", "name": "Bare Hands", "rarity": "free"},
	{"id": "bands", "name": "Wristbands", "rarity": "free", "style": "band", "c": "ff5a4e", "c2": "ffffff"},
	{"id": "mittens", "name": "Mittens", "rarity": "common", "style": "mitten", "c": "e8483f", "c2": "ffffff"},
	{"id": "work", "name": "Work Gloves", "rarity": "common", "style": "mitten", "c": "e0b35e", "c2": "9a6f30"},
	{"id": "boxing", "name": "Boxing Gloves", "rarity": "rare", "style": "boxing", "c": "e8282f", "c2": "ffffff"},
	{"id": "foam", "name": "Foam Finger", "rarity": "rare", "style": "foam", "c": "ffd23f", "c2": "24135f"},
	{"id": "crab", "name": "Crab Claws", "rarity": "rare", "style": "crab", "c": "ff5a3c", "c2": "ffb39a"},
	{"id": "claws", "name": "Monster Claws", "rarity": "epic", "style": "claw", "c": "4cbc5e", "c2": "f4f0d8"},
	{"id": "robot", "name": "Robo Hands", "rarity": "epic", "style": "robot", "c": "9aa8d6", "c2": "ffd23f"},
	{"id": "flame", "name": "Flame Hands", "rarity": "legend", "style": "flame", "c": "ff7a1f", "c2": "ffd23f"},
	{"id": "gold", "name": "Gold Gauntlets", "rarity": "legend", "style": "boxing", "c": "ffc21f", "c2": "fff0a8"},
]

## How your legs and arms move when you run.
const RUNS: Array[Dictionary] = [
	{"id": "", "name": "Classic Run", "rarity": "free"},
	{"id": "strut", "name": "Model Strut", "rarity": "common"},
	{"id": "skip", "name": "Happy Skip", "rarity": "common"},
	{"id": "waddle", "name": "Penguin Waddle", "rarity": "common"},
	{"id": "tiptoe", "name": "Tiptoe", "rarity": "rare"},
	{"id": "robot", "name": "Robot March", "rarity": "rare"},
	{"id": "zombie", "name": "Zombie Shuffle", "rarity": "rare"},
	{"id": "hop", "name": "Bunny Hop", "rarity": "epic"},
	{"id": "arms_back", "name": "Arms Back", "rarity": "epic"},
	{"id": "spin", "name": "Spin Runner", "rarity": "legend"},
	{"id": "float", "name": "Hover", "rarity": "legend"},
]

const HEROES: Array[Dictionary] = [
	{"id": "kiko", "name": "Kiko", "rarity": "free", "kind": "kid", "skin": "e8b07a", "hair": "2c1f3a", "style": "spiky", "top": "ff5a4e", "low": "2f5fd0", "shoe": "ffffff", "blurb": "Fastest kid on the block. Says so himself."},
	{"id": "lani", "name": "Lani", "rarity": "free", "kind": "kid", "skin": "d99a68", "hair": "3b2230", "style": "ponytail", "top": "35d07f", "low": "ffb52e", "shoe": "ff6fb5", "blurb": "Has never once lost at tag. Ask anyone."},
	{"id": "bong", "name": "Bong", "rarity": "free", "kind": "kid", "skin": "c98a58", "hair": "1d1630", "style": "bowl", "top": "3aa6ff", "low": "3a3a58", "shoe": "ffd23f", "blurb": "Quiet, sneaky, always in the tall grass."},
	{"id": "maya", "name": "Maya", "rarity": "common", "kind": "kid", "skin": "f0c090", "hair": "5a2b1a", "style": "buns", "top": "ff6fb5", "low": "ffffff", "shoe": "7f5cff", "blurb": "Named after a tiny bird. Just as hard to catch."},
	{"id": "rafael", "name": "Rafael", "rarity": "common", "kind": "kid", "skin": "b87a4c", "hair": "241a33", "style": "mohawk", "top": "ffd23f", "low": "24135f", "shoe": "ff5a4e", "blurb": "Louder than the fiesta band."},
	{"id": "tala", "name": "Tala", "rarity": "rare", "kind": "kid", "skin": "e0a874", "hair": "e8eaff", "style": "long", "top": "7f5cff", "low": "2b2466", "shoe": "bff3ff", "blurb": "Runs by starlight. Silver hair, no explanation."},
	{"id": "bantay", "name": "Bantay", "rarity": "common", "kind": "animal", "animal": "dog", "fur": "c98a4a", "belly": "fff1d6", "accent": "ff5a4e", "blurb": "Very good boy. Guards the base. Mostly."},
	{"id": "muning", "name": "Muning", "rarity": "common", "kind": "animal", "animal": "cat", "fur": "ffb04d", "belly": "fff6e6", "accent": "35d07f", "blurb": "Knocks your powerup off the table on purpose."},
	{"id": "tamaraw", "name": "Damulag", "rarity": "rare", "kind": "animal", "animal": "buffalo", "fur": "5c5a78", "belly": "8d8ba8", "accent": "ffd23f", "blurb": "Big, gentle, and absolutely not stopping."},
	{"id": "tarsi", "name": "Tarsi", "rarity": "rare", "kind": "animal", "animal": "tarsier", "fur": "b58d6a", "belly": "e6cfae", "accent": "3aa6ff", "blurb": "Those eyes see you. They always see you."},
	{"id": "tandang", "name": "Tandang", "rarity": "rare", "kind": "animal", "animal": "rooster", "fur": "fff4dc", "belly": "ffffff", "accent": "ff3f3f", "blurb": "Wakes the whole team at 4 a.m."},
	{"id": "biik", "name": "Biik", "rarity": "common", "kind": "animal", "animal": "pig", "fur": "ffa6c0", "belly": "ffd0de", "accent": "3aa6ff", "blurb": "Surprisingly aerodynamic."},
	{"id": "unggoy", "name": "Unggoy", "rarity": "rare", "kind": "animal", "animal": "monkey", "fur": "8a5a3a", "belly": "e6c9a0", "accent": "ffd23f", "blurb": "Stole the last hero's banana. And their shoes."},
	{"id": "buko", "name": "Buko", "rarity": "epic", "kind": "mascot", "shape": "coconut", "main": "7a5230", "second": "fff8ea", "accent": "35d07f", "blurb": "A coconut with places to be."},
	{"id": "manga", "name": "Manga", "rarity": "epic", "kind": "mascot", "shape": "mango", "main": "ffc21f", "second": "ff7f2e", "accent": "35d07f", "blurb": "The sweetest runner in the islands."},
	{"id": "halo", "name": "Halo", "rarity": "epic", "kind": "mascot", "shape": "cup", "main": "cfeeff", "second": "b57cff", "accent": "ff6fb5", "blurb": "Shaved ice, sweet beans, zero chill."},
	{"id": "botbot", "name": "Botbot", "rarity": "epic", "kind": "mascot", "shape": "robot", "main": "9aa8d6", "second": "ffd23f", "accent": "27e9ff", "blurb": "Calculated your route. Calculated your snack, too."},
	{"id": "multo", "name": "Multo", "rarity": "epic", "kind": "mascot", "shape": "ghost", "main": "eef1ff", "second": "c9c4ff", "accent": "7f5cff", "blurb": "Says boo. Means it."},
	{"id": "kosmo", "name": "Kosmo", "rarity": "legend", "kind": "mascot", "shape": "alien", "main": "6dffb0", "second": "2b2466", "accent": "ff6fb5", "blurb": "Came for the base, stayed for the fiesta."},
	{"id": "apoy", "name": "Apoy", "rarity": "legend", "kind": "mascot", "shape": "flame", "main": "ff7a1f", "second": "ffd23f", "accent": "ff3f3f", "blurb": "Don't ask for a hug."},
	{"id": "yelo", "name": "Yelo", "rarity": "legend", "kind": "mascot", "shape": "crystal", "main": "9fe6ff", "second": "e8fbff", "accent": "5a7dff", "blurb": "A cool head, in the most literal way."},
]

## Outfit colours: repaint the main and accent colours of any hero.
const SKINS: Array[Dictionary] = [
	{"id": "", "name": "Classic", "rarity": "free", "a": "", "b": ""},
	{"id": "fiesta", "name": "Fiesta", "rarity": "common", "a": "ff4f8b", "b": "ffd23f"},
	{"id": "ocean", "name": "Ocean", "rarity": "common", "a": "19b8d6", "b": "e6fdff"},
	{"id": "forest", "name": "Forest", "rarity": "common", "a": "2f9a4e", "b": "c9f28a"},
	{"id": "sunset", "name": "Sunset", "rarity": "common", "a": "ff7a3c", "b": "b0245f"},
	{"id": "candy", "name": "Candy", "rarity": "rare", "a": "ff9fd8", "b": "8fe8ff"},
	{"id": "royal", "name": "Royal", "rarity": "rare", "a": "5a2bd6", "b": "ffc21f"},
	{"id": "midnight", "name": "Midnight", "rarity": "rare", "a": "241a5c", "b": "8c7dff"},
	{"id": "bubblegum", "name": "Bubblegum", "rarity": "rare", "a": "ff6fb5", "b": "fff0f8"},
	{"id": "toxic", "name": "Toxic", "rarity": "epic", "a": "7dff3c", "b": "27153d"},
	{"id": "lava", "name": "Lava", "rarity": "epic", "a": "ff3a14", "b": "2c1414"},
	{"id": "ice_queen", "name": "Glacier", "rarity": "epic", "a": "b8eeff", "b": "2f5fd0"},
	{"id": "gold", "name": "Solid Gold", "rarity": "legend", "a": "ffc21f", "b": "fff0a8"},
	{"id": "shadow", "name": "Shadow", "rarity": "legend", "a": "141026", "b": "ff3f6a"},
	{"id": "neon", "name": "Neon Night", "rarity": "legend", "a": "ff2fc0", "b": "27e9ff"},
]

const HATS: Array[Dictionary] = [
	{"id": "", "name": "No Hat", "rarity": "free"},
	{"id": "cap", "name": "Ball Cap", "rarity": "free"},
	{"id": "salakot", "name": "Salakot", "rarity": "common"},
	{"id": "party", "name": "Party Hat", "rarity": "common"},
	{"id": "headphones", "name": "Headphones", "rarity": "common"},
	{"id": "bow", "name": "Big Bow", "rarity": "common"},
	{"id": "headband", "name": "Headband", "rarity": "common"},
	{"id": "beanie", "name": "Beanie", "rarity": "common"},
	{"id": "flowers", "name": "Flower Crown", "rarity": "rare"},
	{"id": "cowboy", "name": "Cowboy Hat", "rarity": "rare"},
	{"id": "propeller", "name": "Propeller Cap", "rarity": "rare"},
	{"id": "chef", "name": "Chef Hat", "rarity": "rare"},
	{"id": "tophat", "name": "Top Hat", "rarity": "rare"},
	{"id": "pirate", "name": "Pirate Hat", "rarity": "rare"},
	{"id": "sombrero", "name": "Sombrero", "rarity": "rare"},
	{"id": "viking", "name": "Viking Helm", "rarity": "epic"},
	{"id": "wizard", "name": "Wizard Hat", "rarity": "epic"},
	{"id": "santa", "name": "Holiday Hat", "rarity": "epic"},
	{"id": "halo_ring", "name": "Halo", "rarity": "epic"},
	{"id": "horns", "name": "Little Horns", "rarity": "epic"},
	{"id": "astronaut", "name": "Space Helmet", "rarity": "epic"},
	{"id": "crown", "name": "Golden Crown", "rarity": "legend"},
	{"id": "parol_hat", "name": "Parol Crown", "rarity": "legend"},
	{"id": "ufo", "name": "Tiny UFO", "rarity": "legend"},
]

const BACKS: Array[Dictionary] = [
	{"id": "", "name": "Nothing", "rarity": "free"},
	{"id": "backpack", "name": "School Bag", "rarity": "free"},
	{"id": "cape_red", "name": "Red Cape", "rarity": "common"},
	{"id": "cape_blue", "name": "Blue Cape", "rarity": "common"},
	{"id": "balloon", "name": "Lucky Balloon", "rarity": "common"},
	{"id": "shell", "name": "Turtle Shell", "rarity": "common"},
	{"id": "flag", "name": "Team Flag", "rarity": "rare"},
	{"id": "guitar", "name": "Guitar", "rarity": "rare"},
	{"id": "butterfly", "name": "Butterfly Wings", "rarity": "rare"},
	{"id": "jetpack", "name": "Jetpack", "rarity": "epic"},
	{"id": "angel", "name": "Angel Wings", "rarity": "epic"},
	{"id": "bat", "name": "Bat Wings", "rarity": "epic"},
	{"id": "parol", "name": "Parol Lantern", "rarity": "legend"},
	{"id": "dragon", "name": "Dragon Wings", "rarity": "legend"},
]

## Particles left behind while running. `fx` is an atlas cell, `c` the colours it cycles through.
const TRAILS: Array[Dictionary] = [
	{"id": "", "name": "Just Dust", "rarity": "free", "fx": Fx.PUFF, "c": ["ffffff"], "rate": 8.0, "size": 0.35},
	{"id": "sparks", "name": "Sparks", "rarity": "common", "fx": Fx.SPARK, "c": ["ffe36b", "ff9f2e"], "rate": 22.0, "size": 0.3},
	{"id": "bubbles", "name": "Bubbles", "rarity": "common", "fx": Fx.RING, "c": ["bff3ff", "ffffff"], "rate": 16.0, "size": 0.32, "rise": 1.5},
	{"id": "leaves", "name": "Falling Leaves", "rarity": "common", "fx": Fx.LEAF, "c": ["59c04f", "a6db5c", "ffc21f"], "rate": 14.0, "size": 0.32},
	{"id": "petals", "name": "Sampaguita", "rarity": "common", "fx": Fx.PETAL, "c": ["ffffff", "fff4c9"], "rate": 16.0, "size": 0.3},
	{"id": "notes", "name": "Music Notes", "rarity": "rare", "fx": Fx.NOTE, "c": ["ff6fb5", "3aa6ff", "ffd23f"], "rate": 10.0, "size": 0.42, "rise": 1.2},
	{"id": "hearts", "name": "Hearts", "rarity": "rare", "fx": Fx.HEART, "c": ["ff5a7a", "ff9fc0"], "rate": 14.0, "size": 0.36, "rise": 0.8},
	{"id": "stars", "name": "Stardust", "rarity": "rare", "fx": Fx.STAR, "c": ["ffd23f", "ffffff"], "rate": 18.0, "size": 0.36},
	{"id": "snow", "name": "Snowfall", "rarity": "rare", "fx": Fx.SNOW, "c": ["ffffff", "bfeeff"], "rate": 18.0, "size": 0.3},
	{"id": "confetti", "name": "Confetti", "rarity": "rare", "fx": Fx.CONFETTI, "c": ["ff5a7a", "ffd23f", "35d07f", "3aa6ff"], "rate": 26.0, "size": 0.28},
	{"id": "coins", "name": "Coin Spill", "rarity": "epic", "fx": Fx.COIN, "c": ["ffd23f"], "rate": 12.0, "size": 0.36, "rise": 2.0},
	{"id": "flames", "name": "Flame Feet", "rarity": "epic", "fx": Fx.FLAME, "c": ["ffb52e", "ff5a1f"], "rate": 32.0, "size": 0.45, "rise": 1.4},
	{"id": "bolts", "name": "Lightning Steps", "rarity": "epic", "fx": Fx.BOLT, "c": ["fff176", "7ee8ff"], "rate": 18.0, "size": 0.42},
	{"id": "pixels", "name": "Pixel Dust", "rarity": "epic", "fx": Fx.PIXEL, "c": ["ff2fc0", "27e9ff", "6dff8c"], "rate": 30.0, "size": 0.24},
	{"id": "ink", "name": "Ink Drips", "rarity": "epic", "fx": Fx.DROP, "c": ["24135f", "7f5cff"], "rate": 22.0, "size": 0.32},
	{"id": "rainbow", "name": "Rainbow Road", "rarity": "legend", "fx": Fx.SOFT, "c": ["ff5a5a", "ffb52e", "fff176", "5be36a", "3aa6ff", "b768ff"], "rate": 60.0, "size": 0.5},
	{"id": "galaxy", "name": "Galaxy Trail", "rarity": "legend", "fx": Fx.STAR, "c": ["b768ff", "27e9ff", "ffffff", "ff6fb5"], "rate": 40.0, "size": 0.4, "rise": 0.5},
	{"id": "embers", "name": "Phoenix Embers", "rarity": "legend", "fx": Fx.FLAME, "c": ["ffd23f", "ff7a1f", "ff2f4a"], "rate": 55.0, "size": 0.55, "rise": 2.2},
]

## Always on: particles circling the avatar, and a coloured ring on the ground.
const AURAS: Array[Dictionary] = [
	{"id": "", "name": "No Aura", "rarity": "free"},
	{"id": "sparkle", "name": "Sparkle", "rarity": "common", "fx": Fx.SPARK, "c": ["ffffff", "fff176"], "ring": "ffffff"},
	{"id": "leafy", "name": "Leafy Breeze", "rarity": "common", "fx": Fx.LEAF, "c": ["59c04f", "a6db5c"], "ring": "59c04f"},
	{"id": "bubbly", "name": "Bubbly", "rarity": "common", "fx": Fx.RING, "c": ["bff3ff"], "ring": "4fc8ff"},
	{"id": "lovely", "name": "Lovely", "rarity": "rare", "fx": Fx.HEART, "c": ["ff5a7a", "ffb3c7"], "ring": "ff5a7a"},
	{"id": "musical", "name": "Musical", "rarity": "rare", "fx": Fx.NOTE, "c": ["ffd23f", "3aa6ff"], "ring": "ffd23f"},
	{"id": "frosty", "name": "Frosty", "rarity": "rare", "fx": Fx.SNOW, "c": ["ffffff", "9fe6ff"], "ring": "9fe6ff"},
	{"id": "golden", "name": "Golden Glow", "rarity": "epic", "fx": Fx.STAR, "c": ["ffd23f", "fff0a8"], "ring": "ffc21f"},
	{"id": "electric", "name": "Electric", "rarity": "epic", "fx": Fx.BOLT, "c": ["fff176", "7ee8ff"], "ring": "7ee8ff"},
	{"id": "fire", "name": "On Fire", "rarity": "epic", "fx": Fx.FLAME, "c": ["ffb52e", "ff4a1f"], "ring": "ff6a1f"},
	{"id": "toxic", "name": "Toxic Cloud", "rarity": "epic", "fx": Fx.PUFF, "c": ["7dff3c", "3fbf4a"], "ring": "7dff3c"},
	{"id": "galaxy", "name": "Pocket Galaxy", "rarity": "legend", "fx": Fx.STAR, "c": ["b768ff", "27e9ff", "ff6fb5"], "ring": "b768ff"},
	{"id": "rainbow", "name": "Double Rainbow", "rarity": "legend", "fx": Fx.SOFT, "c": ["ff5a5a", "ffd23f", "5be36a", "3aa6ff", "b768ff"], "ring": "ffffff"},
	{"id": "royal", "name": "Royal Court", "rarity": "legend", "fx": Fx.COIN, "c": ["ffd23f"], "ring": "ffc21f"},
]

## What flies when you tag someone.
const BURSTS: Array[Dictionary] = [
	{"id": "", "name": "Pow!", "rarity": "free", "fx": Fx.STAR, "c": ["ffd23f", "ffffff"], "text": "TAG!"},
	{"id": "confetti", "name": "Confetti Pop", "rarity": "common", "fx": Fx.CONFETTI, "c": ["ff5a7a", "ffd23f", "35d07f", "3aa6ff"], "text": "YAY!"},
	{"id": "bubbles", "name": "Bubble Bath", "rarity": "common", "fx": Fx.RING, "c": ["bff3ff", "ffffff"], "text": "BLUB!"},
	{"id": "leaves", "name": "Leaf Storm", "rarity": "common", "fx": Fx.LEAF, "c": ["59c04f", "a6db5c"], "text": "SWOOSH!"},
	{"id": "hearts", "name": "Heartbreaker", "rarity": "rare", "fx": Fx.HEART, "c": ["ff5a7a", "ffb3c7"], "text": "SORRY!"},
	{"id": "coins", "name": "Jackpot", "rarity": "rare", "fx": Fx.COIN, "c": ["ffd23f"], "text": "CHA-CHING!"},
	{"id": "notes", "name": "Mic Drop", "rarity": "rare", "fx": Fx.NOTE, "c": ["ff6fb5", "3aa6ff"], "text": "ENCORE!"},
	{"id": "snow", "name": "Deep Freeze", "rarity": "epic", "fx": Fx.SNOW, "c": ["ffffff", "9fe6ff"], "text": "BRRR!"},
	{"id": "flames", "name": "Fireball", "rarity": "epic", "fx": Fx.FLAME, "c": ["ffb52e", "ff4a1f"], "text": "BURN!"},
	{"id": "bolts", "name": "Thunderclap", "rarity": "epic", "fx": Fx.BOLT, "c": ["fff176", "7ee8ff"], "text": "ZAP!"},
	{"id": "pixels", "name": "Game Over", "rarity": "epic", "fx": Fx.PIXEL, "c": ["ff2fc0", "27e9ff", "6dff8c"], "text": "GAME OVER"},
	{"id": "galaxy", "name": "Supernova", "rarity": "legend", "fx": Fx.STAR, "c": ["b768ff", "27e9ff", "ffffff"], "text": "COSMIC!"},
	{"id": "rainbow", "name": "Rainbow Blast", "rarity": "legend", "fx": Fx.SOFT, "c": ["ff5a5a", "ffd23f", "5be36a", "3aa6ff", "b768ff"], "text": "WOW!"},
]

const DANCES: Array[Dictionary] = [
	{"id": "", "name": "Happy Hop", "rarity": "free"},
	{"id": "wave", "name": "Big Wave", "rarity": "common"},
	{"id": "spin", "name": "Spinner", "rarity": "common"},
	{"id": "twist", "name": "The Twist", "rarity": "rare"},
	{"id": "robot", "name": "Robot Moves", "rarity": "rare"},
	{"id": "tinikling", "name": "Bamboo Hop", "rarity": "epic"},
	{"id": "flip", "name": "Backflip", "rarity": "epic"},
	{"id": "superstar", "name": "Superstar", "rarity": "legend"},
]

const EMOTES: Array[Dictionary] = [
	{"id": "hi", "name": "Hi!", "rarity": "free", "text": "Hi!"},
	{"id": "gg", "name": "GG", "rarity": "free", "text": "GG"},
	{"id": "nice", "name": "Nice!", "rarity": "free", "text": "Nice!"},
	{"id": "help", "name": "Help!", "rarity": "free", "text": "Help!"},
	{"id": "hoy", "name": "Hoy!", "rarity": "common", "text": "Hoy!"},
	{"id": "oops", "name": "Oops", "rarity": "common", "text": "Oops"},
	{"id": "haha", "name": "Haha", "rarity": "common", "text": "Haha!"},
	{"id": "lets_go", "name": "Let's Go!", "rarity": "common", "text": "Let's go!"},
	{"id": "ayos", "name": "Ayos!", "rarity": "rare", "text": "Ayos!"},
	{"id": "takbo", "name": "Takbo!", "rarity": "rare", "text": "Takbo!"},
	{"id": "too_slow", "name": "Too Slow", "rarity": "rare", "text": "Too slow!"},
	{"id": "on_me", "name": "On Me", "rarity": "rare", "text": "On me!"},
	{"id": "panalo", "name": "Panalo!", "rarity": "epic", "text": "Panalo!"},
	{"id": "catch_me", "name": "Catch Me", "rarity": "epic", "text": "Catch me!"},
	{"id": "boss", "name": "Boss Move", "rarity": "legend", "text": "Boss move."},
	{"id": "fiesta", "name": "Fiesta!", "rarity": "legend", "text": "FIESTA!"},
]
const DEFAULT_EMOTES: Array[String] = ["hi", "gg", "nice", "help"]

const FRAMES: Array[Dictionary] = [
	{"id": "", "name": "Plain", "rarity": "free", "c": "ffffff"},
	{"id": "mint", "name": "Mint", "rarity": "common", "c": "3fe0a8"},
	{"id": "sky", "name": "Sky", "rarity": "common", "c": "58c4ff"},
	{"id": "peach", "name": "Peach", "rarity": "common", "c": "ffb38a"},
	{"id": "ruby", "name": "Ruby", "rarity": "rare", "c": "ff3f6a"},
	{"id": "amethyst", "name": "Amethyst", "rarity": "rare", "c": "b768ff"},
	{"id": "sapphire", "name": "Sapphire", "rarity": "rare", "c": "3a6aff"},
	{"id": "emerald", "name": "Emerald", "rarity": "epic", "c": "1fbf6a"},
	{"id": "sunrise", "name": "Sunrise", "rarity": "epic", "c": "ff9f1f"},
	{"id": "gold", "name": "Gold", "rarity": "legend", "c": "ffc21f"},
	{"id": "diamond", "name": "Diamond", "rarity": "legend", "c": "bff3ff"},
]

const TITLES: Array[Dictionary] = [
	{"id": "", "name": "New Runner", "rarity": "free"},
	{"id": "barrio_kid", "name": "Barrio Kid", "rarity": "free"},
	{"id": "tag_rookie", "name": "Tag Rookie", "rarity": "common"},
	{"id": "fresh", "name": "Stay Fresh", "rarity": "common"},
	{"id": "runner", "name": "Road Runner", "rarity": "common"},
	{"id": "rescuer", "name": "The Rescuer", "rarity": "common"},
	{"id": "jail_regular", "name": "Jail Regular", "rarity": "common"},
	{"id": "base_thief", "name": "Base Thief", "rarity": "rare"},
	{"id": "slippery", "name": "Slippery Soap", "rarity": "rare"},
	{"id": "power_hungry", "name": "Power Hungry", "rarity": "rare"},
	{"id": "sneaky", "name": "Sneaky Grass", "rarity": "rare"},
	{"id": "guardian", "name": "Base Guardian", "rarity": "rare"},
	{"id": "fiesta_king", "name": "Fiesta Royalty", "rarity": "epic"},
	{"id": "untouchable", "name": "Untouchable", "rarity": "epic"},
	{"id": "jailbreaker", "name": "Jailbreaker", "rarity": "epic"},
	{"id": "tag_master", "name": "Tag Master", "rarity": "epic"},
	{"id": "agawan_legend", "name": "Agawan Legend", "rarity": "legend"},
	{"id": "the_goat", "name": "Number One Fan", "rarity": "legend"},
	{"id": "kapitan", "name": "Barangay Captain", "rarity": "legend"},
]

static var _index := {}


static func list(slot: String) -> Array[Dictionary]:
	match slot:
		"char": return HEROES
		"mask": return MASKS
		"top": return TOPS
		"pants": return PANTS
		"shoes": return SHOES
		"gloves": return GLOVES
		"run": return RUNS
		"skin": return SKINS
		"hat": return HATS
		"back": return BACKS
		"trail": return TRAILS
		"aura": return AURAS
		"burst": return BURSTS
		"dance": return DANCES
		"emote": return EMOTES
		"frame": return FRAMES
		"title": return TITLES
	return []


static func item(slot: String, id: String) -> Dictionary:
	if _index.is_empty():
		for s: String in SLOTS:
			var by_id := {}
			for entry: Dictionary in list(s):
				by_id[entry["id"]] = entry
			_index[s] = by_id
	return (_index.get(slot, {}) as Dictionary).get(id, {})


static func key(slot: String, id: String) -> String:
	return "%s:%s" % [slot, id]


static func price(slot: String, id: String) -> Dictionary:
	var entry := item(slot, id)
	var info: Dictionary = RARITY[entry.get("rarity", "common")]
	return {"coins": int(info["coins"]), "gems": int(info["gems"])}


static func is_free(slot: String, id: String) -> bool:
	return item(slot, id).get("rarity", "common") == "free"


static func total_items() -> int:
	var n := 0
	for s: String in SLOTS:
		n += list(s).size()
	return n


static func default_look() -> Dictionary:
	return {"char": "kiko", "skin": "", "mask": "shades", "hat": "", "top": "tee", "pants": "shorts", "shoes": "sneakers", "gloves": "", "back": "", "run": "", "trail": "", "aura": "", "burst": "", "dance": "", "frame": "", "title": ""}


## A believable random outfit, for bots.
static func random_look(rng: RandomNumberGenerator, fancy := 0.5) -> Dictionary:
	var look := default_look()
	for slot: String in ["mask", "top", "pants", "shoes"]:
		look[slot] = ""
	look["char"] = String(HEROES[rng.randi_range(0, HEROES.size() - 1)]["id"])
	for slot: String in ["mask", "hat", "top", "pants", "shoes", "gloves", "back", "run", "trail", "aura", "burst"]:
		if rng.randf() < fancy:
			var entries := list(slot)
			look[slot] = String(entries[rng.randi_range(0, entries.size() - 1)]["id"])
	return look


static func color(hex: String, fallback := Color.WHITE) -> Color:
	return Color(hex) if hex != "" else fallback


static func thumb_path(slot: String, id: String) -> String:
	return "res://assets/shop/%s_%s.webp" % [slot, id if id != "" else "none"]
