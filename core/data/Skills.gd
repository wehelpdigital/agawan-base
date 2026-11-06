class_name Skills
extends RefCounted
## What each hero can do on top of the cards. Every hero has a skill of their own, and a tree of others to learn as they level
## up. Their tree is dealt at random, once, from the hero's name, so it's different for each of them and it never changes. You
## take two skills into a match at most, and each level gives you a point to spend on learning or ranking one up.
##
## A skill is written the same way as a power card (see Powerups.gd), so the rules (Sim.gd) play it the same way. In a match
## its id is "sk:<skill>:<rank>", which Powerups.by_id() understands.

const MAX_CHOSEN := 2
const MAX_RANK := 5
const MAX_LEVEL := 10
const TREE_LEVELS: Array[int] = [2, 3, 5, 7, 10]  ## When the rest of a hero's tree opens up. Their own skill is there from the start.
const TYPES := {
	"attack": {"name": "Attack", "color": Color("ff5a4e"), "icon": "mode_attack"},
	"defend": {"name": "Defence", "color": Color("3aa6ff"), "icon": "mode_defend"},
	"trick": {"name": "Trick", "color": Color("b768ff"), "icon": "power"},
}

const ALL := {
	# --- Attack ----------------------------------------------------------------------------------
	"fireball": {"name": "Fireball", "type": "attack", "cd": 14.0, "ai": "chase", "sfx": "trail_fire", "cell": Cosmetics.Fx.FLAME, "color": "ff7a1f", "model": "fireball",
		"desc": "Throw a ball of fire. It goes off with a bang where it lands, and everyone close goes flying.", "kind": "shot", "speed": 20.0, "range": 24.0, "r": 0.6, "status": {"stun": 1.0}, "blast": {"r": 3.0, "push": 14.0, "stun": 0.8}},
	"hex": {"name": "Hex", "type": "attack", "cd": 16.0, "ai": "chase", "sfx": "aura_dark", "cell": Cosmetics.Fx.SWIRL, "color": "a98bff",
		"desc": "Curses the nearest enemy. For 4 seconds they're slow, and their controls are back to front.", "kind": "curse", "range": 20.0, "status": {"reverse": 4.0, "slow": 4.0}, "word": "HEXED!"},
	"lockup": {"name": "Put to Jail", "type": "attack", "cd": 45.0, "ai": "chase", "sfx": "kill_mummy_wrap", "cell": Cosmetics.Fx.RING, "color": "ffd23f",
		"desc": "Throw the handcuffs. Whoever they catch goes straight to jail, on either side of the line.", "kind": "shot", "speed": 17.0, "range": 14.0, "r": 0.55, "jails": true},
	"ice_lance": {"name": "Ice Lance", "type": "attack", "cd": 12.0, "ai": "chase", "sfx": "kill_freeze_ray", "cell": Cosmetics.Fx.SNOW, "color": "7ee8ff", "model": "freeze_ray",
		"desc": "A fast shard of ice that freezes the first enemy it hits.", "kind": "shot", "speed": 26.0, "range": 24.0, "r": 0.45, "status": {"freeze": 1.6}},
	"lightning": {"name": "Lightning", "type": "attack", "cd": 18.0, "ai": "chase", "sfx": "kill_lightning_strike", "cell": Cosmetics.Fx.BOLT, "color": "fff176",
		"desc": "A bolt hits the nearest enemy, then jumps to whoever's near them.", "kind": "chain_zap", "range": 20.0, "jump": 9.0, "count": 3, "status": {"stun": 0.8}},
	"poison": {"name": "Poison Cloud", "type": "attack", "cd": 14.0, "ai": "chase", "sfx": "aura_toxic", "cell": Cosmetics.Fx.PUFF, "color": "62e0a0",
		"desc": "A green cloud ahead of you that drags enemies down to half speed.", "kind": "zone", "fx": "slow", "r": 4.5, "dur": 6.0, "at": 6.0},
	"boulder": {"name": "Rolling Boulder", "type": "attack", "cd": 16.0, "ai": "guard", "sfx": "kill_steam_cannon", "cell": Cosmetics.Fx.PUFF, "color": "b5763c",
		"desc": "A big rock bowls through everyone in its way and knocks them flying.", "kind": "shot", "speed": 12.0, "range": 22.0, "r": 0.95, "pierce": true, "push": 15.0, "status": {"stun": 0.8}},
	"meteor": {"name": "Meteor", "type": "attack", "cd": 18.0, "ai": "chase", "sfx": "kill_meteor_call", "cell": Cosmetics.Fx.FLAME, "color": "ff5a1f",
		"desc": "Calls a rock down on the nearest enemy. Its shadow follows them until it lands.", "kind": "drop", "range": 22.0, "fall": 1.0, "r": 2.0, "status": {"stun": 1.6}},
	"arrows": {"name": "Arrow Fan", "type": "attack", "cd": 10.0, "ai": "chase", "sfx": "kill_laser_disc", "cell": Cosmetics.Fx.STREAK, "color": "ffd23f",
		"desc": "Three shots in a fan. Each one stops an enemy for a moment.", "kind": "volley", "count": 3, "spread": 0.24, "speed": 24.0, "range": 20.0, "r": 0.38, "status": {"stun": 0.6}},
	"whirlwind": {"name": "Whirlwind", "type": "attack", "cd": 16.0, "ai": "chase", "sfx": "kill_tornado", "cell": Cosmetics.Fx.SWIRL, "color": "d7d2ff",
		"desc": "A small tornado wanders forward and drags enemies around.", "kind": "zone", "fx": "drag", "r": 3.2, "dur": 4.0, "drift": 5.0, "at": 1.5},
	"stalk": {"name": "Shadow Step", "type": "attack", "cd": 20.0, "ai": "chase", "sfx": "move_teleport", "cell": Cosmetics.Fx.SWIRL, "color": "7f38d6",
		"desc": "Appear right behind the nearest enemy, and for 2 seconds you can tag anyone.", "kind": "stalk", "range": 16.0, "status": {"overcharge": 2.0}},
	"charge": {"name": "Bull Charge", "type": "attack", "cd": 14.0, "ai": "attack", "sfx": "taunt_cannonball", "cell": Cosmetics.Fx.PUFF, "color": "ff9d2e",
		"desc": "Curl up and charge for 1.6 seconds. Nobody can tag you, and everyone you hit goes flying.", "kind": "self", "status": {"roll": 1.6}},
	"war_cry": {"name": "War Cry", "type": "attack", "cd": 15.0, "ai": "flee", "sfx": "taunt_foghorn", "cell": Cosmetics.Fx.NOTE, "color": "ffb21f",
		"desc": "A terrible shout. Nearby enemies run away from you in a panic.", "kind": "aoe", "r": 8.0, "status": {"fear": 2.0}},
	"sunbeam": {"name": "Sunbeam", "type": "attack", "cd": 24.0, "ai": "chase", "sfx": "kill_plasma_blade", "cell": Cosmetics.Fx.SUN, "color": "ffd23f",
		"desc": "Stand still for a moment, then fire a beam that goes through walls and knocks everyone flat.", "kind": "beam", "charge": 0.5, "len": 30.0, "r": 1.2, "hold": 0.35, "push": 12.0, "status": {"stun": 1.2}},
	"fire_line": {"name": "Flame Breath", "type": "attack", "cd": 15.0, "ai": "chase", "sfx": "trail_fire", "cell": Cosmetics.Fx.FLAME, "color": "ff7a1f",
		"desc": "Breathe a line of fire in front of you. Anyone who crosses it gets singed and stops.", "kind": "fire_line", "count": 5, "gap": 1.9, "dur": 3.0},
	"boomerang": {"name": "Boomerang", "type": "attack", "cd": 11.0, "ai": "chase", "sfx": "kill_laser_disc", "cell": Cosmetics.Fx.STAR, "color": "ff9d2e", "model": "boomerang",
		"desc": "Flies out and comes back, and bonks everyone it passes both ways.", "kind": "shot", "speed": 19.0, "range": 28.0, "r": 0.65, "pierce": true, "returns": true, "status": {"stun": 0.8}},
	"swarm": {"name": "Swarm", "type": "attack", "cd": 22.0, "ai": "chase", "sfx": "aura_toxic", "cell": Cosmetics.Fx.BEE, "color": "ffd23f",
		"desc": "A little swarm goes after the nearest enemy for 5 seconds. They run slow, and it stings.", "kind": "chaser", "fx": "bees", "range": 28.0, "r": 1.9, "dur": 5.0, "pace": 7.5},
	"magnet": {"name": "Tractor Beam", "type": "attack", "cd": 15.0, "ai": "chase", "sfx": "kill_ufo_abduction", "cell": Cosmetics.Fx.SPARK, "color": "b768ff",
		"desc": "Yanks nearby enemies straight toward you.", "kind": "aoe", "r": 9.0, "push": -20.0},
	# --- Defence ---------------------------------------------------------------------------------
	"stone_wall": {"name": "Stone Wall", "type": "defend", "cd": 12.0, "ai": "guard", "sfx": "entrance_stamp", "cell": Cosmetics.Fx.PUFF, "color": "b5763c",
		"desc": "A wall bursts up in front of you for 6 seconds.", "kind": "wall", "len": 5, "dur": 6.0},
	"barrier": {"name": "Magic Barrier", "type": "defend", "cd": 18.0, "ai": "flee", "sfx": "aura_shimmer", "cell": Cosmetics.Fx.RING, "color": "8fe3ff",
		"desc": "A bubble that stops the next tag or hit against you. Lasts 7 seconds.", "kind": "self", "status": {"shield": 7.0}},
	"vines": {"name": "Vine Snare", "type": "defend", "cd": 16.0, "ai": "guard", "sfx": "kill_grave_grab", "cell": Cosmetics.Fx.LEAF, "color": "35a659",
		"desc": "Hidden vines grow around you and pin any enemy who steps on one.", "kind": "mines", "trap": "snare", "count": 4, "dur": 14.0},
	"second_wind": {"name": "Second Wind", "type": "defend", "cd": 16.0, "ai": "flee", "sfx": "trail_sparkle", "cell": Cosmetics.Fx.HEART, "color": "ff6fb5",
		"desc": "Shake off anything holding you, get your dash back, and run faster for 3 seconds.", "kind": "cleanse", "status": {"speed2": 3.0}},
	"ward": {"name": "Base Ward", "type": "defend", "cd": 30.0, "ai": "guard", "sfx": "aura_holy", "cell": Cosmetics.Fx.STAR, "color": "ffd23f",
		"desc": "Your base can't be captured for 6 seconds, wherever you are.", "kind": "baselock", "dur": 6.0},
	"thorns": {"name": "Thorn Ring", "type": "defend", "cd": 26.0, "ai": "guard", "sfx": "aura_nature", "cell": Cosmetics.Fx.LEAF, "color": "35a659",
		"desc": "Thorns ring your base for 6 seconds. Intruders get stuck on the way in.", "kind": "hedge", "dur": 6.0},
	"frost_nova": {"name": "Frost Nova", "type": "defend", "cd": 18.0, "ai": "guard", "sfx": "kill_freeze_ray", "cell": Cosmetics.Fx.SNOW, "color": "bff3ff",
		"desc": "A blast of cold freezes every enemy close to you.", "kind": "aoe", "r": 6.0, "status": {"freeze": 1.2}},
	"sanctuary": {"name": "Sanctuary", "type": "defend", "cd": 30.0, "ai": "attack", "sfx": "aura_holy", "cell": Cosmetics.Fx.STAR, "color": "fff3a8",
		"desc": "Everyone on your team gets a bubble for 5 seconds.", "kind": "team", "status": {"shield": 5.0}},
	"mirror": {"name": "Mirror Skin", "type": "defend", "cd": 20.0, "ai": "flee", "sfx": "kill_wand_twinkle", "cell": Cosmetics.Fx.DIAMOND, "color": "fff3a8",
		"desc": "For 4 seconds shots bounce back at whoever fired them, and stuns can't touch you.", "kind": "self", "status": {"mirror": 4.0}},
	"sentry": {"name": "Little Sentry", "type": "defend", "cd": 24.0, "ai": "guard", "sfx": "taunt_drone_drop", "cell": Cosmetics.Fx.BOLT, "color": "3aa6ff",
		"desc": "Plant a little turret that stuns enemies who come near. Lasts 8 seconds.", "kind": "sentry", "dur": 8.0},
	"stomp": {"name": "Ground Stomp", "type": "defend", "cd": 20.0, "ai": "guard", "sfx": "kill_giant_stomp", "cell": Cosmetics.Fx.PUFF, "color": "d8c8a8",
		"desc": "Stamp your foot. Every enemy close to you is stunned and thrown back.", "kind": "aoe", "r": 7.0, "push": 12.0, "status": {"stun": 1.0}},
	"slick": {"name": "Slip and Slide", "type": "defend", "cd": 14.0, "ai": "guard", "sfx": "taunt_jelly_wobble", "cell": Cosmetics.Fx.DROP, "color": "bff3ff",
		"desc": "A slippery patch that sends enemies sliding helplessly for 7 seconds.", "kind": "zone", "fx": "slip", "r": 4.0, "dur": 7.0, "at": 0.0},
	"banana": {"name": "Banana Skins", "type": "defend", "cd": 12.0, "ai": "flee", "sfx": "taunt_jelly_wobble", "cell": Cosmetics.Fx.BANANA, "color": "ffe05c",
		"desc": "Drop peels behind you. Anyone who steps on one goes for a long, long slide.", "kind": "peels", "count": 3, "dur": 20.0},
	# --- Tricks ----------------------------------------------------------------------------------
	"teleport": {"name": "Teleport", "type": "trick", "cd": 11.0, "ai": "flee", "sfx": "move_teleport", "cell": Cosmetics.Fx.SPARK, "color": "b768ff",
		"desc": "Vanish and appear a short way in the direction you're going.", "kind": "blink", "dist": 11.0},
	"vanish": {"name": "Vanish", "type": "trick", "cd": 20.0, "ai": "attack", "sfx": "kill_ghost_pop", "cell": Cosmetics.Fx.GHOST, "color": "d7d2ff",
		"desc": "Disappear from enemy eyes for 5 seconds, or until you tag someone.", "kind": "self", "status": {"invis": 5.0}},
	"mirror_image": {"name": "Mirror Image", "type": "trick", "cd": 20.0, "ai": "attack", "sfx": "kill_ghost_pop", "cell": Cosmetics.Fx.PUFF, "color": "ffffff",
		"desc": "Two copies run beside you for 6 seconds. Touch the wrong one and it's a nasty surprise.", "kind": "clones", "count": 2, "dur": 6.0},
	"swap": {"name": "Swap", "type": "trick", "cd": 18.0, "ai": "attack", "sfx": "move_swirl", "cell": Cosmetics.Fx.SWIRL, "color": "b768ff",
		"desc": "Trade places with the nearest enemy.", "kind": "swap", "range": 16.0},
	"sleep": {"name": "Lullaby", "type": "trick", "cd": 20.0, "ai": "flee", "sfx": "aura_love", "cell": Cosmetics.Fx.ZZZ, "color": "a98bff",
		"desc": "A soft little tune sends nearby enemies straight to sleep.", "kind": "aoe", "r": 7.0, "status": {"sleep": 1.8}},
	"recall": {"name": "Recall", "type": "trick", "cd": 25.0, "ai": "flee", "sfx": "entrance_warp", "cell": Cosmetics.Fx.SPARK, "color": "27e9ff",
		"desc": "Warp straight back to your own base.", "kind": "recall"},
	"haste": {"name": "Haste", "type": "trick", "cd": 12.0, "ai": "flee", "sfx": "move_rocket", "cell": Cosmetics.Fx.STREAK, "color": "35d07f",
		"desc": "60% faster for 3 seconds.", "kind": "self", "status": {"speed": 3.0}},
	"rally": {"name": "Rally", "type": "trick", "cd": 24.0, "ai": "attack", "sfx": "finale_fiesta", "cell": Cosmetics.Fx.STAR, "color": "ffc21f",
		"desc": "Your whole team runs 30% faster for 4 seconds.", "kind": "team", "status": {"speed2": 4.0}},
	"jailbreak": {"name": "Jailbreak", "type": "trick", "cd": 60.0, "ai": "jail", "sfx": "finale_fireworks", "cell": Cosmetics.Fx.STAR, "color": "8fffb4",
		"desc": "Every teammate in jail walks free, from anywhere on the map.", "kind": "jailbreak"},
	"polymorph": {"name": "Polymorph", "type": "trick", "cd": 30.0, "ai": "chase", "sfx": "taunt_foghorn", "cell": Cosmetics.Fx.FEATHER, "color": "ffffff",
		"desc": "Turn the nearest enemy into a chicken for 3 seconds. Chickens can't tag, capture, dash or use cards.", "kind": "curse", "range": 18.0, "status": {"chicken": 3.0}},
	"leap": {"name": "Great Leap", "type": "trick", "cd": 10.0, "ai": "attack", "sfx": "move_bounce", "cell": Cosmetics.Fx.STAR, "color": "35d07f",
		"desc": "Leap over walls, water and enemies. Nobody can touch you in the air.", "kind": "hop", "dist": 12.0},
	"dance": {"name": "Catchy Tune", "type": "trick", "cd": 18.0, "ai": "flee", "sfx": "finale_fiesta", "cell": Cosmetics.Fx.NOTE, "color": "ff6fb5",
		"desc": "Every enemy close to you has to dance. They have no choice.", "kind": "aoe", "r": 7.0, "status": {"dance": 1.6}},
	"pickpocket": {"name": "Sticky Fingers", "type": "trick", "cd": 20.0, "ai": "chase", "sfx": "coins", "cell": Cosmetics.Fx.COIN, "color": "ffc21f",
		"desc": "Steal a card right out of the nearest enemy's hand.", "kind": "steal", "range": 20.0},
}

## Each hero's own skill: its name, what it works like, what it's made of, and a line about it.
const SIGNATURE := {
	"kiko": ["Slingshot Surprise", "arrows", Cosmetics.Fx.STAR, "Pockets full of pebbles."],
	"lani": ["Coconut Bomb", "fireball", Cosmetics.Fx.PALM, "Nobody knows where she keeps them."],
	"bong": ["Mud Pie", "poison", Cosmetics.Fx.PUFF, "Made fresh. Served hot."],
	"maya": ["Skipping Rope", "vines", Cosmetics.Fx.RING, "Leaves it lying around on purpose."],
	"rafael": ["Sprint Finish", "haste", Cosmetics.Fx.STREAK, "Saves it all for the last bit."],
	"tala": ["Moonbeam", "sunbeam", Cosmetics.Fx.MOON, "It's the same as sunlight, but later."],
	"bantay": ["Big Bark", "war_cry", Cosmetics.Fx.PAW, "All bark. Also a bit of bite."],
	"muning": ["Nine Lives", "second_wind", Cosmetics.Fx.PAW, "Is on life number six."],
	"tamaraw": ["Stampede of One", "charge", Cosmetics.Fx.PUFF, "Damulag doesn't turn round. Things move."],
	"tarsi": ["Big Stare", "hex", Cosmetics.Fx.SWIRL, "Those eyes do something to you."],
	"tandang": ["Wake-Up Call", "war_cry", Cosmetics.Fx.FEATHER, "Five in the morning, every morning."],
	"biik": ["Belly Flop", "stomp", Cosmetics.Fx.HEART, "Small pig. Huge landing."],
	"unggoy": ["Banana Skin Trail", "banana", Cosmetics.Fx.BANANA, "Ate the bananas. Kept the best part."],
	"buko": ["Coconut Drop", "meteor", Cosmetics.Fx.PALM, "Looks up, then doesn't have to."],
	"manga": ["Sticky Juice", "slick", Cosmetics.Fx.DROP, "You'll be washing that out for days."],
	"halo": ["Brain Freeze", "frost_nova", Cosmetics.Fx.SNOW, "Three spoonfuls too many."],
	"botbot": ["Laser Eyes", "sunbeam", Cosmetics.Fx.BOLT, "Was only supposed to read the barcode."],
	"multo": ["Now You See Me", "vanish", Cosmetics.Fx.GHOST, "Mostly you don't."],
	"kosmo": ["Tractor Beam", "magnet", Cosmetics.Fx.PLANET, "Just wants to take a closer look."],
	"apoy": ["Hot Head", "fireball", Cosmetics.Fx.FLAME, "Tends to lose it."],
	"yelo": ["Diamond Dust", "ice_lance", Cosmetics.Fx.DIAMOND, "Cold, sharp and very pretty."],
	"yuki": ["Snow Day", "frost_nova", Cosmetics.Fx.SNOW, "School's cancelled, and so are you."],
	"mei": ["Dragon Dance", "dance", Cosmetics.Fx.LANTERN, "Everybody joins in eventually."],
	"priya": ["Spice Bomb", "fireball", Cosmetics.Fx.PETAL, "Her mum's recipe, and she doesn't mess about."],
	"leo": ["Victory Lap", "haste", Cosmetics.Fx.STREAK, "Starts it a little early."],
	"freya": ["Thunder Clap", "lightning", Cosmetics.Fx.BOLT, "One clap, and the sky answers."],
	"amara": ["Brave Heart", "barrier", Cosmetics.Fx.HEART, "You'd have to get past her first."],
	"zola": ["Big Drum", "stomp", Cosmetics.Fx.NOTE, "You feel it before you hear it."],
	"tariq": ["Sandstorm", "whirlwind", Cosmetics.Fx.PUFF, "Comes with its own weather."],
	"diego": ["Golden Goal", "boulder", Cosmetics.Fx.STAR, "Top corner, through three defenders."],
	"luna": ["Moonwalk", "vanish", Cosmetics.Fx.MOON, "Backwards, out of sight."],
	"max": ["Sick Trick", "leap", Cosmetics.Fx.STREAK, "Lands it about half the time."],
	"kai": ["Big Wave", "boulder", Cosmetics.Fx.DROP, "Surf's up. You're under."],
	"sir_clank": ["Shield Slam", "charge", Cosmetics.Fx.SHIELD, "Comes through shield first, with a lot of noise."],
	"dame_rosa": ["Rose Hedge", "thorns", Cosmetics.Fx.ROSE, "Very beautiful, and very much not a door."],
	"bushi": ["One Clean Cut", "stalk", Cosmetics.Fx.SWORD, "Already behind you. Has been for a while."],
	"shino": ["Star Fan", "arrows", Cosmetics.Fx.SHURIKEN, "Three throwing stars, no warning."],
	"bjorn": ["Battle Horn", "war_cry", Cosmetics.Fx.ANCHOR, "They hear it across the fjord."],
	"salty": ["Fire the Cannon", "fireball", Cosmetics.Fx.ANCHOR, "Brought it with him. Don't ask how."],
	"neb": ["Curse of the Tomb", "hex", Cosmetics.Fx.SKULL, "You did read the sign on the door."],
	"mumford": ["Wrap It Up", "vines", Cosmetics.Fx.RING, "He has plenty of bandage to spare."],
	"brutus": ["Arena Stomp", "stomp", Cosmetics.Fx.SHIELD, "The crowd goes wild."],
	"terry": ["Clay Army", "mirror_image", Cosmetics.Fx.PUFF, "He's got thousands more at home."],
	"matryona": ["One Inside Another", "mirror_image", Cosmetics.Fx.HEART, "And another. And another."],
	"nuss": ["Nut Cracker", "boulder", Cosmetics.Fx.STAR, "Very good at his job."],
	"koko": ["Wooden Wobble", "sleep", Cosmetics.Fx.PETAL, "Rocks gently from side to side. You feel so tired."],
	"pippo": ["Joker's Trick", "swap", Cosmetics.Fx.CONFETTI, "Now you're over there. Ha."],
	"merl": ["Frog Spell", "polymorph", Cosmetics.Fx.STAR, "It should be a frog. It's always a chicken."],
	"zephyr": ["Your Wish", "teleport", Cosmetics.Fx.STAR, "He only grants this one to himself."],
	"seamus": ["Pinch of Luck", "second_wind", Cosmetics.Fx.CLOVER, "It's not cheating if it's luck."],
	"nibble": ["Bat Cloud", "swarm", Cosmetics.Fx.BAT, "His relatives are visiting."],
	"betty": ["Avalanche", "boulder", Cosmetics.Fx.SNOW, "She only sneezed."],
	"kappy": ["Puddle", "slick", Cosmetics.Fx.DROP, "Brought water from home, in his head."],
	"trollbert": ["Toll Bridge", "stone_wall", Cosmetics.Fx.PUFF, "Nobody crosses without paying."],
	"take": ["Bamboo Shoots", "vines", Cosmetics.Fx.BAMBOO, "They grow very fast. Very, very fast."],
	"deng": ["Bright Idea", "sunbeam", Cosmetics.Fx.LANTERN, "Finally got the lamp to do something."],
	"maki": ["Wasabi Shot", "fireball", Cosmetics.Fx.SUSHI, "It goes right up your nose."],
	"bao": ["Hot Steam", "poison", Cosmetics.Fx.DUMPLING, "Lifted the lid too early."],
	"tapi": ["Boba Burst", "arrows", Cosmetics.Fx.BUBBLE, "Don't suck too hard on the straw."],
	"paco": ["Salsa Splash", "fireball", Cosmetics.Fx.TACO, "Medium, he said. It was not medium."],
	"pierre": ["Flaky Crumbs", "slick", Cosmetics.Fx.CROISSANT, "They get everywhere. Everywhere."],
	"rita": ["Extra Cheese", "vines", Cosmetics.Fx.PIZZA, "Long, stringy and impossible to get away from."],
	"burgie": ["Ketchup Squirt", "arrows", Cosmetics.Fx.DROP, "Nobody's ever got the angle right."],
	"sprinkles": ["Sugar Rush", "haste", Cosmetics.Fx.DONUT, "Then the crash. But first, the rush."],
	"earl": ["Tea Break", "sleep", Cosmetics.Fx.TEACUP, "Do sit down. No, really. Sit down."],
	"avo": ["Pit Stop", "boulder", Cosmetics.Fx.LEAF, "Kept it for exactly this."],
	"pina": ["Spiky Crown", "barrier", Cosmetics.Fx.STAR, "Go on, try and tag that."],
	"funghi": ["Spore Cloud", "poison", Cosmetics.Fx.MUSHROOM, "He's a fun guy. It's a cloud of spores."],
	"snowjoe": ["Carrot Nose", "ice_lance", Cosmetics.Fx.SNOW, "Grows a new one by morning."],
	"sol": ["Solar Flare", "sunbeam", Cosmetics.Fx.SUN, "Don't look straight at it."],
	"spike": ["Needle Spray", "arrows", Cosmetics.Fx.CACTUS, "Please don't hug him."],
	"tulipa": ["Petal Storm", "whirlwind", Cosmetics.Fx.TULIP, "A lovely way to get lost."],
	"jack": ["Trick or Treat", "swap", Cosmetics.Fx.PUMPKIN, "It's a trick."],
	"kitsu": ["Nine Copies", "mirror_image", Cosmetics.Fx.FLAME, "He says nine. Count them."],
	"bambu": ["Snack Time", "second_wind", Cosmetics.Fx.BAMBOO, "Nothing a little bamboo can't fix."],
	"raja": ["Pounce", "stalk", Cosmetics.Fx.PAW, "You never see the stripes coming."],
	"jabari": ["Mighty Roar", "war_cry", Cosmetics.Fx.PAW, "Everyone remembers something they need to do."],
	"gajah": ["Trunk Spray", "slick", Cosmetics.Fx.DROP, "He's been saving it all morning."],
	"banjo": ["Long Nap", "sleep", Cosmetics.Fx.ZZZ, "It's catching."],
	"tilly": ["Big Bounce", "leap", Cosmetics.Fx.STAR, "Her pouch is full of springs."],
	"pablo": ["Belly Slide", "charge", Cosmetics.Fx.SNOW, "Wherever he's going, it's downhill."],
	"lento": ["Slow Down", "hex", Cosmetics.Fx.ZZZ, "Everyone goes at his speed now."],
	"capi": ["Everyone's Friend", "sanctuary", Cosmetics.Fx.HEART, "Nothing bad happens near a capybara."],
	"pacha": ["Llama Spit", "poison", Cosmetics.Fx.DROP, "You had it coming."],
	"heidi": ["Moo-ve Over", "charge", Cosmetics.Fx.CLOVER, "She's not stopping. She's a cow."],
	"gaston": ["Long Tongue", "magnet", Cosmetics.Fx.DROP, "Here, you. Yes, you."],
	"hoot": ["Night Eyes", "fire_line", Cosmetics.Fx.FEATHER, "Sees all of it. Doesn't care for it."],
	"nilo": ["Fluffy Fury", "swarm", Cosmetics.Fx.LEAF, "So cute. So many teeth."],
	"crikey": ["Snap", "lockup", Cosmetics.Fx.ANCHOR, "Once it shuts, you're going nowhere."],
	"fiona": ["Lucky Clover", "second_wind", Cosmetics.Fx.CLOVER, "Finds one exactly when she needs it."],
	"nikos": ["Plate Smash", "stomp", Cosmetics.Fx.STAR, "Opa!"],
	"elif": ["Tulip Field", "whirlwind", Cosmetics.Fx.TULIP, "They spin faster than you'd think."],
	"minji": ["Finger Heart", "sleep", Cosmetics.Fx.HEART, "Melts absolutely everybody."],
	"linh": ["Rice Hat Spin", "boomerang", Cosmetics.Fx.RING, "It always comes back."],
	"putri": ["Monkey Trick", "swap", Cosmetics.Fx.BANANA, "She learned it from a very old story."],
	"anya": ["Snowball Fight", "ice_lance", Cosmetics.Fx.SNOW, "She packs them hard."],
	"mateo": ["Rainbow Kick", "boomerang", Cosmetics.Fx.RAINBOW, "Over your head. Round the back."],
	"sami": ["Northern Lights", "sleep", Cosmetics.Fx.STAR, "You can't stop looking up."],
	"jamal": ["Fast Break", "haste", Cosmetics.Fx.STREAK, "Gone before the pass lands."],
	"kemar": ["Fastest Man", "haste", Cosmetics.Fx.STREAK, "Already there. Already bored."],
	"wanji": ["Long Run", "second_wind", Cosmetics.Fx.STREAK, "She hasn't even started yet."],
	"selam": ["Coffee Time", "rally", Cosmetics.Fx.TEACUP, "Three cups each, and off you all go."],
	"yasmin": ["Date Stone", "arrows", Cosmetics.Fx.STAR, "She never misses."],
	"aroha": ["Big Stick Game", "boomerang", Cosmetics.Fx.STAR, "Her family's been practising for years."],
	"sina": ["Sea Breeze", "teleport", Cosmetics.Fx.DROP, "One moment she's there. Then she's swimming."],
	# The ones from the old stories.
	"bramble": ["Call the Wild", "vines", Cosmetics.Fx.LEAF, "The forest owes him a favour."],
	"hazel": ["Hex Brew", "hex", Cosmetics.Fx.BAT, "Tastes like toads. Smells worse."],
	"gild": ["Golden Light", "sanctuary", Cosmetics.Fx.SUN, "Shines so bright you forget what you were doing."],
	"robyn": ["Triple Shot", "arrows", Cosmetics.Fx.FEATHER, "Splits the arrow you just fired."],
	"grok": ["Rage Smash", "stomp", Cosmetics.Fx.PUFF, "Grok no like. Grok hit ground."],
	"tam": ["Catchy Tune", "dance", Cosmetics.Fx.NOTE, "It'll be in your head for weeks."],
	"fizz": ["Bubbling Flask", "poison", Cosmetics.Fx.BUBBLE, "It wasn't meant to do that."],
	"nix": ["Vanishing Act", "vanish", Cosmetics.Fx.DICE, "And your wallet's gone as well."],
	"ember": ["Great Fireball", "fireball", Cosmetics.Fx.FLAME, "Her eyebrows grew back last week."],
	"frostine": ["Ice Nova", "frost_nova", Cosmetics.Fx.SNOW, "She's not cold. You're cold."],
	"volta": ["Forked Lightning", "lightning", Cosmetics.Fx.BOLT, "Her hair's been like that since the accident."],
	"elowen": ["Leaf Step", "teleport", Cosmetics.Fx.LEAF, "Nothing but a few leaves, falling."],
	"thrum": ["Big Hammer", "boulder", Cosmetics.Fx.STAR, "It's the small hammer that you've got to watch."],
	"snik": ["Sticky Fingers", "pickpocket", Cosmetics.Fx.COIN, "That was yours. It's his now."],
	"urk": ["Put to Jail", "lockup", Cosmetics.Fx.RING, "Urk grabs. You go. No talking."],
	"pixie": ["Pixie Dust", "sleep", Cosmetics.Fx.SPARK, "One sprinkle. Good night."],
	"bones": ["Throw a Bone", "boomerang", Cosmetics.Fx.SKULL, "He does need that back."],
	"cinder": ["Dragon Breath", "fire_line", Cosmetics.Fx.FLAME, "A very small dragon. A very big cough."],
}

static var _powers := {}
static var _trees := {}
static var _info := {}


## What a skill is: the row in ALL, or the hero's own one built on it, with its id.
static func info(skill: String) -> Dictionary:
	if _info.has(skill):
		return _info[skill]
	var out := {}
	if skill.begins_with("hero_"):
		var hero := skill.trim_prefix("hero_")
		if SIGNATURE.has(hero):
			var row: Array = SIGNATURE[hero]
			out = (ALL[row[1]] as Dictionary).duplicate(true)
			out["name"] = row[0]
			out["cell"] = row[2]
			out["desc"] = "%s %s" % [row[3], ALL[row[1]]["desc"]]
			out["hero"] = hero
			out["cd"] = float(out["cd"]) * 0.9
	elif ALL.has(skill):
		out = (ALL[skill] as Dictionary).duplicate(true)
	if not out.is_empty():
		out["skill"] = skill
	_info[skill] = out
	return out


static func own_skill(hero_id: String) -> String:
	return "hero_" + hero_id


static func cooldown(skill: String, rank: int) -> float:
	return float(info(skill).get("cd", 20.0)) * (1.0 - 0.08 * (clampi(rank, 1, MAX_RANK) - 1))


static func power_id(skill: String, rank: int) -> String:
	return "sk:%s:%d" % [skill, clampi(rank, 1, MAX_RANK)]


## A skill at some rank, written as a power. Higher ranks last longer and reach further.
static func power_def(id: String) -> Dictionary:
	if _powers.has(id):
		return _powers[id]
	var parts := id.split(":")
	var out := {}
	if parts.size() == 3 and not info(parts[1]).is_empty():
		out = info(parts[1]).duplicate(true)
		var rank := clampi(parts[2].to_int(), 1, MAX_RANK)
		var more := rank - 1
		out["id"] = id
		out["cat"] = out["type"]
		out["tier"] = 2
		if out.has("status"):
			for status: String in (out["status"] as Dictionary).keys():
				out["status"][status] = float(out["status"][status]) * (1.0 + 0.12 * more)
		if out.has("dur"):
			out["dur"] = float(out["dur"]) * (1.0 + 0.1 * more)
		if out.has("count"):
			out["count"] = int(out["count"]) + more / 2
		for field: String in ["range", "dist"]:
			if out.has(field):
				out[field] = float(out[field]) * (1.0 + 0.06 * more)
		if out.has("push"):
			out["push"] = float(out["push"]) * (1.0 + 0.08 * more)
		if out.has("blast"):
			out["blast"]["r"] = float(out["blast"]["r"]) * (1.0 + 0.08 * more)
			out["blast"]["stun"] = float(out["blast"]["stun"]) * (1.0 + 0.1 * more)
		if out.has("r") and String(out["kind"]) in ["aoe", "zone", "drop", "beam", "chaser"]:
			out["r"] = float(out["r"]) * (1.0 + 0.05 * more)
	_powers[id] = out
	return out


## A hero's tree: their own skill, then the others, each with the level it opens at. Always the same for the same hero.
static func tree(hero_id: String) -> Array:
	if _trees.has(hero_id):
		return _trees[hero_id]
	var rng := RandomNumberGenerator.new()
	rng.seed = ("skills:" + hero_id).hash()
	var own_base: String = SIGNATURE[hero_id][1] if SIGNATURE.has(hero_id) else ""
	var by_type := {"attack": [], "defend": [], "trick": []}
	for skill: String in ALL:
		if skill != own_base:
			by_type[ALL[skill]["type"]].append(skill)
	var picked: Array[String] = []
	for type: String in ["attack", "defend", "trick"]:  # One of each, so every tree gives you a choice.
		picked.append(_draw(by_type[type], rng))
	var rest: Array = by_type["attack"] + by_type["defend"] + by_type["trick"]
	while picked.size() < TREE_LEVELS.size():
		picked.append(_draw(rest, rng))
	for i in range(picked.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := picked[i]
		picked[i] = picked[j]
		picked[j] = swap
	var out: Array = [{"skill": own_skill(hero_id), "level": 1}]
	for i in picked.size():
		out.append({"skill": picked[i], "level": TREE_LEVELS[i]})
	_trees[hero_id] = out
	return out


static func _draw(list: Array, rng: RandomNumberGenerator) -> String:
	return String(list.pop_at(rng.randi_range(0, list.size() - 1)))


## What a computer player takes into a match: their own skill, and one more from their tree.
static func bot_loadout(rng: RandomNumberGenerator, hero_id: String, strength: float) -> Array:
	var nodes := tree(hero_id)
	var rank := clampi(1 + int(strength * 3.0), 1, MAX_RANK)
	var other: Dictionary = nodes[rng.randi_range(1, nodes.size() - 1)]
	return [[own_skill(hero_id), rank], [String(other["skill"]), maxi(rank - 1, 1)]]


## The two skills in a seat's look, checked. A save or another device's message can say anything.
static func from_look(look: Dictionary) -> Array:
	var out: Array = []
	var list: Variant = look.get("skills", [])
	if not list is Array:
		return out
	for entry: Variant in list:
		if entry is Array and (entry as Array).size() == 2 and out.size() < MAX_CHOSEN and not info(str(entry[0])).is_empty():
			out.append([str(entry[0]), clampi(int(entry[1]), 1, MAX_RANK)])
	return out


static func color(skill: String) -> Color:
	var def := info(skill)
	return TYPES[def["type"]]["color"] if not def.is_empty() else Color.WHITE


## XP to get from this level to the next.
static func xp_for_level(level: int) -> int:
	return 70 + (level - 1) * 45
