class_name Powerups
extends RefCounted
## Every power a crystal can hold. Sim reads `kind` and its parameters; the HUD, the codex and the 3D view read
## the name, description, category, card and sound. `tier` sets how often it comes up
## (1 common, 2 rare, 3 epic). There are two decks: on your own side of the line you draw from the defence deck, and over
## the line from the attack deck. Cross the line and whatever you're holding gets reshuffled into the other deck.
## `ai` tells the bots when it makes sense:
##   chase: an enemy you can tag is close      flee: someone who can tag you is close
##   crowd: several enemies are close          attack: going for the enemy base
##   guard: intruders near your base           jail: teammates in jail
##   any: use it soon after picking it up

const CATS := {
	"speed": {"name": "Speed", "color": Color("35d07f")},
	"attack": {"name": "Attack", "color": Color("ff5a4e")},
	"defend": {"name": "Defend", "color": Color("3aa6ff")},
	"trick": {"name": "Trick", "color": Color("b768ff")},
	"team": {"name": "Team", "color": Color("ffc21f")},
}
const TIER_NAMES := ["", "Common", "Rare", "Epic"]
const TIER_WEIGHT := [0, 60, 30, 12]
const FUNNY_WEIGHT := 3  ## Funny cards come up this many times as often: about half of what you draw.
const ATTACK := "attack"
const DEFEND := "defend"
## Everything else is in the attack deck: anything that goes fast, gets you in, or hits someone.
const DEFENCE_DECK := ["bubble_shield", "popup_wall", "base_lock", "sentry_buddy", "snare_ring", "pop_mines", "slow_dome", "thorn_hedge", "mirror_shield",
	"fresh_start", "instant_igloo", "guardian_angel", "orbit_shields", "robo_buddy", "stop_clock", "smoke_bomb", "fishing_net", "slime_ball", "big_magnet",
	"black_hole", "freeze_ray", "sky_zap", "bubble_trap", "shrink_ray", "tidal_wave", "soap_slick", "scare_horn", "banana_peels", "fake_crystal", "lullaby",
	"group_hug", "radar_ping", "cheer_squad", "crystal_vacuum", "power_rain", "jailbreak",
	"poop_drop", "stink_bomb", "whoopee_cushion", "bubble_gum", "itching_powder", "mouse_traps", "hot_sauce", "spring_trap", "plunger", "dad_joke"]

const ALL: Array[Dictionary] = [
	# --- Speed -----------------------------------------------------------------------------------
	{"id": "rocket_slippers", "name": "Rocket Slippers", "cat": "speed", "tier": 1, "ai": "flee", "sfx": "move_rocket",
		"desc": "Blast off: 60% faster for 5 seconds.", "kind": "self", "status": {"speed": 5.0}},
	{"id": "blink_step", "name": "Blink Step", "cat": "speed", "tier": 1, "ai": "flee", "sfx": "move_teleport",
		"desc": "Teleport a short way in the direction you aim.", "kind": "blink", "dist": 9.0},
	{"id": "super_hop", "name": "Super Hop", "cat": "speed", "tier": 1, "ai": "attack", "sfx": "move_bounce",
		"desc": "Leap over walls, water and enemies. Nobody can touch you in the air.", "kind": "hop", "dist": 10.0},
	{"id": "grapple_vine", "name": "Grapple Vine", "cat": "speed", "tier": 2, "ai": "attack", "sfx": "move_zip",
		"desc": "Fire a vine. It yanks you to the first wall it hits.", "kind": "grapple", "range": 18.0},
	{"id": "tailwind", "name": "Tailwind", "cat": "speed", "tier": 1, "ai": "any", "sfx": "trail_whoosh",
		"desc": "A long, steady boost: 30% faster for 10 seconds.", "kind": "self", "status": {"speed2": 10.0}},
	{"id": "ghost_sprint", "name": "Ghost Sprint", "cat": "speed", "tier": 2, "ai": "flee", "sfx": "kill_ghost",
		"desc": "Run through walls at full speed for 2.5 seconds. You can't tag or be tagged.", "kind": "self", "status": {"ghost": 2.5, "speed": 2.5}},
	{"id": "home_run", "name": "Home Run", "cat": "speed", "tier": 2, "ai": "flee", "sfx": "entrance_warp",
		"desc": "Warp straight back to your own base.", "kind": "recall"},
	{"id": "coco_boost", "name": "Coco Boost", "cat": "speed", "tier": 1, "ai": "chase", "sfx": "aura_electric",
		"desc": "Your dash recharges in half a second for 8 seconds.", "kind": "self", "status": {"dashboost": 8.0}},
	{"id": "magic_carpet", "name": "Magic Carpet", "cat": "speed", "tier": 2, "ai": "attack", "sfx": "move_zip",
		"desc": "Fly for 5 seconds: over water, fences and floor traps, and 25% faster. Walls still stop you.", "kind": "self", "status": {"carpet": 5.0}},
	{"id": "human_cannon", "name": "Human Cannon", "cat": "speed", "tier": 2, "ai": "attack", "sfx": "kill_steam_cannon",
		"desc": "Fire yourself right across the field, over anything in the way.", "kind": "hop", "dist": 24.0, "dur": 0.85},
	{"id": "moon_boots", "name": "Moon Boots", "cat": "speed", "tier": 1, "ai": "attack", "sfx": "move_bounce",
		"desc": "For 8 seconds your dash is a huge floaty leap, and it recharges fast.", "kind": "self", "status": {"moon": 8.0, "dashboost": 8.0}},
	{"id": "turbo_skates", "name": "Turbo Skates", "cat": "speed", "tier": 1, "ai": "attack", "sfx": "trail_whoosh",
		"desc": "80% faster for 6 seconds, but no brakes at all. Good luck on the corners.", "kind": "self", "status": {"turbo": 6.0}},
	{"id": "buddy_warp", "name": "Buddy Warp", "cat": "speed", "tier": 1, "ai": "attack", "sfx": "move_teleport",
		"desc": "Warp to whichever teammate is furthest up the field.", "kind": "warp_mate"},
	{"id": "rewind", "name": "Rewind", "cat": "speed", "tier": 2, "ai": "flee", "sfx": "move_swirl",
		"desc": "Jump back to where you were 4 seconds ago, and shake off anything holding you.", "kind": "rewind"},
	# --- Attack ----------------------------------------------------------------------------------
	{"id": "freeze_ray", "name": "Freeze Ray", "cat": "attack", "tier": 1, "ai": "chase", "sfx": "kill_freeze_ray",
		"desc": "A fast beam that freezes the first enemy it hits for 2 seconds.", "kind": "shot", "speed": 24.0, "range": 20.0, "r": 0.5, "status": {"freeze": 2.0}},
	{"id": "coconut_shot", "name": "Coconut Shot", "cat": "attack", "tier": 1, "ai": "chase", "sfx": "taunt_cannonball",
		"desc": "A homing coconut. Bonk: 1.5 seconds of stars.", "kind": "shot", "speed": 13.0, "range": 26.0, "r": 0.55, "homing": true, "status": {"stun": 1.5}},
	{"id": "fishing_net", "name": "Fishing Net", "cat": "attack", "tier": 1, "ai": "chase", "sfx": "kill_mummy_wrap",
		"desc": "A wide net that pins an enemy in place for 2 seconds.", "kind": "shot", "speed": 17.0, "range": 16.0, "r": 1.2, "status": {"root": 2.0}},
	{"id": "slime_ball", "name": "Slime Ball", "cat": "attack", "tier": 1, "ai": "chase", "sfx": "taunt_slime",
		"desc": "Bursts into a sticky puddle that slows enemies for 6 seconds.", "kind": "shot", "speed": 15.0, "range": 14.0, "r": 0.6, "status": {"slow": 2.0}, "burst": {"fx": "slow", "r": 3.6, "dur": 6.0}},
	{"id": "sky_zap", "name": "Sky Zap", "cat": "attack", "tier": 2, "ai": "guard", "sfx": "kill_lightning_strike",
		"desc": "Lightning strikes the enemy closest to your base. No aiming needed.", "kind": "zap", "status": {"stun": 1.6}},
	{"id": "thunderstorm", "name": "Thunderstorm", "cat": "attack", "tier": 3, "ai": "any", "sfx": "kill_storm_caller",
		"desc": "Three bolts hit three random enemies, anywhere on the map.", "kind": "storm", "count": 3, "status": {"stun": 1.2}},
	{"id": "shockwave", "name": "Shockwave", "cat": "attack", "tier": 1, "ai": "flee", "sfx": "kill_ka_boom",
		"desc": "Blast every nearby enemy away from you.", "kind": "aoe", "r": 7.0, "push": 20.0},
	{"id": "big_magnet", "name": "Big Magnet", "cat": "attack", "tier": 2, "ai": "chase", "sfx": "kill_ufo_abduction",
		"desc": "Yank nearby enemies straight toward you. Best on your own side.", "kind": "aoe", "r": 10.0, "push": -22.0},
	{"id": "mini_twister", "name": "Mini Twister", "cat": "attack", "tier": 2, "ai": "chase", "sfx": "kill_tornado",
		"desc": "A little tornado wanders forward and drags enemies around.", "kind": "zone", "fx": "drag", "r": 3.2, "dur": 6.0, "drift": 4.0, "at": 2.0},
	{"id": "black_hole", "name": "Black Hole", "cat": "attack", "tier": 3, "ai": "guard", "sfx": "kill_black_hole",
		"desc": "Throw a tiny black hole. It sucks in everyone on the enemy team for 4 seconds.", "kind": "zone", "fx": "pull", "r": 7.5, "dur": 4.0, "at": 9.0},
	{"id": "rolling_barrel", "name": "Rolling Barrel", "cat": "attack", "tier": 1, "ai": "guard", "sfx": "kill_steam_cannon",
		"desc": "A heavy barrel bowls through enemies and knocks them flying.", "kind": "shot", "speed": 14.0, "range": 24.0, "r": 1.0, "pierce": true, "bounces": 1, "push": 15.0, "status": {"stun": 0.6}},
	{"id": "ricochet_disc", "name": "Ricochet Disc", "cat": "attack", "tier": 2, "ai": "chase", "sfx": "kill_laser_disc",
		"desc": "Bounces off walls up to five times. Stuns the first enemy it finds.", "kind": "shot", "speed": 20.0, "range": 60.0, "r": 0.5, "bounces": 5, "status": {"stun": 1.1}},
	{"id": "hot_trail", "name": "Hot Trail", "cat": "attack", "tier": 2, "ai": "flee", "sfx": "trail_fire",
		"desc": "Run with a trail of flames for 5 seconds. Enemies who cross it get singed and stop.", "kind": "self", "status": {"firetrail": 5.0, "speed2": 5.0}},
	{"id": "earthquake", "name": "Earthquake", "cat": "attack", "tier": 3, "ai": "any", "sfx": "kill_giant_stomp",
		"desc": "The whole arena shakes. Every enemy on the ground is stunned for 1.2 seconds.", "kind": "quake", "status": {"stun": 1.2}},
	{"id": "meteor_shower", "name": "Meteor Shower", "cat": "attack", "tier": 3, "ai": "any", "sfx": "kill_meteor_call",
		"desc": "Meteors rain on the enemy's half for 5 seconds. Watch the shadows.", "kind": "meteors", "count": 12, "dur": 5.0},
	{"id": "giant_growth", "name": "Giant Growth", "cat": "attack", "tier": 2, "ai": "chase", "sfx": "kill_thunder_hammer",
		"desc": "Become huge for 6 seconds: longer reach, and stuns slide off you.", "kind": "self", "status": {"giant": 6.0}},
	{"id": "overcharge", "name": "Overcharge", "cat": "attack", "tier": 3, "ai": "chase", "sfx": "kill_plasma_blade",
		"desc": "For 5 seconds you can tag anyone, on either side of the line.", "kind": "self", "status": {"overcharge": 5.0}},
	{"id": "chain_tag", "name": "Chain Tag", "cat": "attack", "tier": 3, "ai": "chase", "sfx": "kill_star_shower",
		"desc": "Your next tag jumps to every enemy within 7 metres who can be tagged.", "kind": "self", "status": {"chain": 12.0}},
	{"id": "mega_wave", "name": "Mega Wave", "cat": "attack", "tier": 3, "ai": "chase", "sfx": "kill_plasma_blade",
		"desc": "Hold still, charge up, then fire a giant beam across the field. It goes through walls and knocks everyone flat.", "kind": "beam", "charge": 0.8, "len": 42.0, "r": 1.7, "hold": 0.5, "push": 18.0, "status": {"stun": 1.7}},
	{"id": "homing_missile", "name": "Homing Missile", "cat": "attack", "tier": 2, "ai": "chase", "sfx": "move_rocket",
		"desc": "Locks on to the nearest enemy and doesn't let go. Blows up with a big bang when it gets there.", "kind": "shot", "speed": 15.0, "range": 42.0, "r": 0.55, "homing": true, "turn": 9.0, "seek": 34.0, "status": {"stun": 1.5}, "blast": {"r": 3.4, "push": 18.0, "stun": 1.2}},
	{"id": "boomerang", "name": "Boomerang", "cat": "attack", "tier": 1, "ai": "chase", "sfx": "kill_laser_disc",
		"desc": "Flies out, comes back, and bonks everyone it passes both ways.", "kind": "shot", "speed": 19.0, "range": 34.0, "r": 0.65, "pierce": true, "returns": true, "status": {"stun": 1.0}},
	{"id": "giant_snowball", "name": "Giant Snowball", "cat": "attack", "tier": 2, "ai": "guard", "sfx": "kill_freeze_ray",
		"desc": "Starts small and grows as it rolls. Freezes everyone it runs over.", "kind": "shot", "speed": 11.0, "range": 34.0, "r": 0.55, "pierce": true, "grow": 0.5, "grow_to": 1.9, "status": {"freeze": 1.5}},
	{"id": "anvil_drop", "name": "Anvil Drop", "cat": "attack", "tier": 2, "ai": "chase", "sfx": "kill_giant_stomp",
		"desc": "Look up! An anvil falls on the nearest enemy. Its shadow chases them, then it lands. Flat for 2 seconds.", "kind": "drop", "range": 24.0, "fall": 1.1, "r": 1.7, "status": {"stun": 2.0}},
	{"id": "cream_pie", "name": "Cream Pie", "cat": "attack", "tier": 1, "ai": "chase", "sfx": "taunt_slime",
		"desc": "Right in the face. They can't see a thing for 4 seconds.", "kind": "shot", "speed": 21.0, "range": 20.0, "r": 0.55, "status": {"blind": 4.0, "slow": 1.0}},
	{"id": "angry_bees", "name": "Angry Bees", "cat": "attack", "tier": 2, "ai": "chase", "sfx": "aura_toxic",
		"desc": "A swarm goes after the nearest enemy for 7 seconds. They run slow, and sting.", "kind": "chaser", "fx": "bees", "range": 30.0, "r": 1.9, "dur": 7.0, "pace": 7.5},
	{"id": "rain_cloud", "name": "Personal Rain Cloud", "cat": "attack", "tier": 1, "ai": "chase", "sfx": "aura_water",
		"desc": "A small sad cloud follows the nearest enemy, slows them down, and shows everyone where they are. Then: zap.", "kind": "chaser", "fx": "cloud", "range": 30.0, "r": 1.3, "dur": 7.0, "pace": 12.0},
	{"id": "tidal_wave", "name": "Tidal Wave", "cat": "attack", "tier": 3, "ai": "any", "sfx": "aura_water",
		"desc": "A wall of water sweeps down the whole field from your side and washes every enemy back.", "kind": "wave", "speed": 15.0, "r": 2.6},
	{"id": "dragon_breath", "name": "Dragon Breath", "cat": "attack", "tier": 2, "ai": "chase", "sfx": "trail_fire",
		"desc": "Breathe a long line of fire in front of you. Anyone who crosses it gets singed and stops.", "kind": "fire_line", "count": 7, "gap": 1.9, "dur": 3.5},
	{"id": "meteor_slam", "name": "Meteor Slam", "cat": "attack", "tier": 2, "ai": "chase", "sfx": "kill_ka_boom",
		"desc": "Leap into the air and come down like a rock. Everyone nearby goes flying.", "kind": "slam", "dist": 13.0, "r": 4.6, "push": 20.0, "stun": 1.2},
	{"id": "chain_lightning", "name": "Chain Lightning", "cat": "attack", "tier": 2, "ai": "chase", "sfx": "kill_lightning_strike",
		"desc": "A bolt hits the nearest enemy, then jumps to whoever's near them, up to four times.", "kind": "chain_zap", "range": 22.0, "jump": 11.0, "count": 4, "status": {"stun": 1.0}},
	{"id": "shrink_ray", "name": "Shrink Ray", "cat": "attack", "tier": 1, "ai": "chase", "sfx": "kill_wand_twinkle",
		"desc": "Shrinks an enemy to pocket size for 5 seconds. Short legs, slow going.", "kind": "shot", "speed": 24.0, "range": 22.0, "r": 0.5, "status": {"mini": 5.0}},
	{"id": "bubble_trap", "name": "Bubble Trap", "cat": "attack", "tier": 1, "ai": "chase", "sfx": "aura_water",
		"desc": "Blow a bubble round an enemy. They float there for 2.5 seconds, tapping on the glass.", "kind": "shot", "speed": 13.0, "range": 18.0, "r": 0.8, "status": {"bubble": 2.5}},
	{"id": "cannonball", "name": "Cannonball", "cat": "attack", "tier": 2, "ai": "chase", "sfx": "taunt_cannonball",
		"desc": "Roll up in a ball for 3.5 seconds, very fast. Nobody can tag you, and everyone you hit goes flying.", "kind": "self", "status": {"roll": 3.5}},
	{"id": "hot_potato", "name": "Hot Potato", "cat": "attack", "tier": 2, "ai": "chase", "sfx": "taunt_popcorn_pop",
		"desc": "Hand the nearest enemy a very hot potato. It goes to whoever they touch. In 6 seconds: bang.", "kind": "potato", "range": 26.0, "dur": 6.0},
	# --- Defend ----------------------------------------------------------------------------------
	{"id": "bubble_shield", "name": "Bubble Shield", "cat": "defend", "tier": 1, "ai": "flee", "sfx": "aura_water",
		"desc": "Blocks the next tag against you. Lasts 8 seconds.", "kind": "self", "status": {"shield": 8.0}},
	{"id": "popup_wall", "name": "Pop-Up Wall", "cat": "defend", "tier": 1, "ai": "flee", "sfx": "entrance_stamp",
		"desc": "A wall bursts up in front of you for 7 seconds.", "kind": "wall", "len": 5, "dur": 7.0},
	{"id": "base_lock", "name": "Base Lock", "cat": "defend", "tier": 2, "ai": "guard", "sfx": "aura_holy",
		"desc": "Your base can't be captured for 9 seconds, wherever you are.", "kind": "baselock", "dur": 9.0},
	{"id": "sentry_buddy", "name": "Sentry Buddy", "cat": "defend", "tier": 2, "ai": "guard", "sfx": "taunt_drone_drop",
		"desc": "Plant a little turret that stuns enemies who come near. Lasts 12 seconds.", "kind": "sentry", "dur": 12.0},
	{"id": "snare_ring", "name": "Snare Ring", "cat": "defend", "tier": 2, "ai": "guard", "sfx": "kill_grave_grab",
		"desc": "Hidden snares appear around your base and pin any intruder who steps on one.", "kind": "snares", "count": 6, "dur": 16.0},
	{"id": "pop_mines", "name": "Pop Mines", "cat": "defend", "tier": 1, "ai": "flee", "sfx": "taunt_popcorn_pop",
		"desc": "Drop three mines around you. Whoever steps on one goes flying.", "kind": "mines", "count": 3, "dur": 14.0},
	{"id": "slow_dome", "name": "Slow Dome", "cat": "defend", "tier": 1, "ai": "flee", "sfx": "aura_shimmer",
		"desc": "A dome that drags enemies down to half speed for 6 seconds.", "kind": "zone", "fx": "slow", "r": 5.5, "dur": 6.0, "at": 0.0},
	{"id": "thorn_hedge", "name": "Thorn Hedge", "cat": "defend", "tier": 2, "ai": "guard", "sfx": "aura_nature",
		"desc": "Thorns ring your base for 10 seconds. Intruders get stuck on the way in.", "kind": "hedge", "dur": 10.0},
	{"id": "mirror_shield", "name": "Mirror Shield", "cat": "defend", "tier": 2, "ai": "flee", "sfx": "kill_wand_twinkle",
		"desc": "For 6 seconds shots bounce back at whoever fired them, and stuns can't touch you.", "kind": "self", "status": {"mirror": 6.0}},
	{"id": "fresh_start", "name": "Fresh Start", "cat": "defend", "tier": 2, "ai": "flee", "sfx": "trail_sparkle",
		"desc": "For 6 seconds you can tag anyone, on either side of the line.", "kind": "fresh"},
	{"id": "instant_igloo", "name": "Instant Igloo", "cat": "defend", "tier": 2, "ai": "flee", "sfx": "kill_freeze_ray",
		"desc": "Ice walls spring up all round you for 4 seconds. Nobody gets in. You don't get out.", "kind": "igloo", "dur": 4.0},
	{"id": "guardian_angel", "name": "Guardian Angel", "cat": "defend", "tier": 2, "ai": "any", "sfx": "aura_holy",
		"desc": "For 15 seconds, the next tag sends you home instead of to jail.", "kind": "self", "status": {"angel": 15.0}},
	{"id": "orbit_shields", "name": "Orbit Shields", "cat": "defend", "tier": 2, "ai": "flee", "sfx": "aura_shimmer",
		"desc": "Three orbs circle you for 8 seconds. They stop shots and shove away anyone who comes close.", "kind": "self", "status": {"orbit": 8.0}},
	{"id": "robo_buddy", "name": "Robo Buddy", "cat": "defend", "tier": 2, "ai": "guard", "sfx": "taunt_drone_drop",
		"desc": "A little robot follows you for 12 seconds and zaps enemies who get near.", "kind": "sentry", "dur": 12.0, "follow": true},
	{"id": "stop_clock", "name": "Stop Clock", "cat": "defend", "tier": 3, "ai": "flee", "sfx": "kill_wand_twinkle",
		"desc": "Time stops for every enemy on the field for 1.8 seconds. You keep going.", "kind": "quake", "status": {"freeze": 1.8}, "event": "timestop"},
	{"id": "smoke_bomb", "name": "Smoke Bomb", "cat": "defend", "tier": 1, "ai": "flee", "sfx": "kill_ghost_pop",
		"desc": "A big cloud of smoke for 7 seconds. Your team can't be seen inside it unless an enemy walks right in.", "kind": "smoke", "r": 5.5, "dur": 7.0},
	# --- Trick -----------------------------------------------------------------------------------
	{"id": "switcheroo", "name": "Switcheroo", "cat": "trick", "tier": 2, "ai": "attack", "sfx": "move_swirl",
		"desc": "Swap places with the nearest enemy.", "kind": "swap", "range": 18.0},
	{"id": "stale_curse", "name": "Stale Curse", "cat": "trick", "tier": 2, "ai": "chase", "sfx": "aura_dark",
		"desc": "The nearest enemy counts as the stalest player for 7 seconds. Anyone can tag them.", "kind": "curse", "range": 20.0, "status": {"stale": 7.0}},
	{"id": "squid_ink", "name": "Squid Ink", "cat": "trick", "tier": 1, "ai": "flee", "sfx": "taunt_ink_pot",
		"desc": "Splat ink over nearby enemies' eyes for 4 seconds.", "kind": "aoe", "r": 9.0, "status": {"blind": 4.0}},
	{"id": "mixup_hex", "name": "Mix-Up Hex", "cat": "trick", "tier": 2, "ai": "flee", "sfx": "aura_toxic",
		"desc": "Nearby enemies get their controls reversed for 4 seconds.", "kind": "aoe", "r": 9.0, "status": {"reverse": 4.0}},
	{"id": "soap_slick", "name": "Soap Slick", "cat": "trick", "tier": 1, "ai": "flee", "sfx": "taunt_jelly_wobble",
		"desc": "A soapy patch that sends enemies sliding helplessly for 9 seconds.", "kind": "zone", "fx": "slip", "r": 4.0, "dur": 9.0, "at": 0.0},
	{"id": "scare_horn", "name": "Scare Horn", "cat": "trick", "tier": 1, "ai": "flee", "sfx": "taunt_foghorn",
		"desc": "Honk! Nearby enemies run away from you in a panic for 2.5 seconds.", "kind": "aoe", "r": 8.0, "status": {"fear": 2.5}},
	{"id": "decoy_squad", "name": "Decoy Squad", "cat": "trick", "tier": 2, "ai": "attack", "sfx": "entrance_party",
		"desc": "Three copies of you scatter across the field. Tagging one gets a nasty surprise.", "kind": "decoys", "count": 3, "dur": 8.0},
	{"id": "invisi_cloak", "name": "Invisi-Cloak", "cat": "trick", "tier": 2, "ai": "attack", "sfx": "kill_ghost_pop",
		"desc": "Vanish from enemy eyes for 7 seconds, or until you tag someone.", "kind": "self", "status": {"invis": 7.0}},
	{"id": "ghost_mode", "name": "Ghost Mode", "cat": "trick", "tier": 2, "ai": "flee", "sfx": "finale_ghosts",
		"desc": "Float through walls and players for 3.5 seconds. You can't tag or be tagged.", "kind": "self", "status": {"ghost": 3.5}},
	{"id": "tiny_time", "name": "Tiny Time", "cat": "trick", "tier": 1, "ai": "attack", "sfx": "move_tiptoe",
		"desc": "Shrink for 7 seconds: a tiny target, and 25% faster.", "kind": "self", "status": {"tiny": 7.0}},
	{"id": "ninja_clones", "name": "Ninja Clones", "cat": "trick", "tier": 2, "ai": "attack", "sfx": "kill_ghost_pop",
		"desc": "Poof! Four clones run beside you, copying every step for 8 seconds. Touch the wrong one and it's a nasty surprise.", "kind": "clones", "count": 4, "dur": 8.0},
	{"id": "banana_peels", "name": "Banana Peels", "cat": "trick", "tier": 1, "ai": "flee", "sfx": "taunt_jelly_wobble",
		"desc": "Drop a trail of peels behind you. Oldest joke in the book, and it still works.", "kind": "peels", "count": 4, "dur": 15.0},
	{"id": "chicken_curse", "name": "Chicken Curse", "cat": "trick", "tier": 3, "ai": "chase", "sfx": "taunt_foghorn",
		"desc": "Turn the nearest enemy into a chicken for 4.5 seconds. Chickens can't tag, capture, dash or use cards.", "kind": "curse", "range": 22.0, "status": {"chicken": 4.5}},
	{"id": "dance_fever", "name": "Dance Fever", "cat": "trick", "tier": 2, "ai": "flee", "sfx": "finale_fiesta",
		"desc": "A disco ball drops. Every enemy nearby has to dance for 2.5 seconds. They have no choice.", "kind": "aoe", "r": 10.0, "status": {"dance": 2.5}},
	{"id": "lullaby", "name": "Lullaby", "cat": "trick", "tier": 2, "ai": "flee", "sfx": "aura_love",
		"desc": "A soft little tune sends nearby enemies straight to sleep for 2.5 seconds.", "kind": "aoe", "r": 11.0, "status": {"sleep": 2.5}},
	{"id": "portal_pair", "name": "Portal Pair", "cat": "trick", "tier": 2, "ai": "attack", "sfx": "trail_warp",
		"desc": "Opens two linked portals for 12 seconds, one here and one far ahead, for your team only.", "kind": "portal", "dist": 18.0, "dur": 12.0},
	{"id": "fake_crystal", "name": "Fake Crystal", "cat": "trick", "tier": 1, "ai": "any", "sfx": "piece_place",
		"desc": "Leave a crystal on the ground that isn't. The first enemy to grab it gets a surprise.", "kind": "fake", "dur": 40.0},
	{"id": "pickpocket", "name": "Pickpocket", "cat": "trick", "tier": 2, "ai": "chase", "sfx": "coins",
		"desc": "Steal a card right out of the nearest enemy's hand.", "kind": "steal", "range": 26.0},
	{"id": "wild_card", "name": "Wild Card", "cat": "trick", "tier": 2, "ai": "any", "sfx": "finale_gifts",
		"desc": "Spin the slots again and draw two brand new cards.", "kind": "wild", "count": 2},
	{"id": "copycat", "name": "Copycat", "cat": "trick", "tier": 1, "ai": "any", "sfx": "move_swirl",
		"desc": "Plays the last card anyone used, for your team.", "kind": "copy"},
	# --- Funny -----------------------------------------------------------------------------------
	{"id": "poop_drop", "name": "Poop Drop", "cat": "trick", "tier": 1, "ai": "guard", "sfx": "squelch", "funny": true,
		"desc": "Leave three fresh ones behind you. Step in one and you're stuck, you stink, and nobody can miss you for 7 seconds.", "kind": "traps", "fx": "poop", "count": 3, "dur": 16.0, "r": 0.9},
	{"id": "fart_fog", "name": "Fart Fog", "cat": "trick", "tier": 1, "ai": "flee", "sfx": "fart_long", "funny": true,
		"desc": "Let one go. A green cloud hangs round you for 7 seconds. Enemies inside cough, slow down, and run the wrong way.", "kind": "zone", "fx": "fart", "r": 5.5, "dur": 7.0, "at": 0.0},
	{"id": "stink_bomb", "name": "Stink Bomb", "cat": "trick", "tier": 1, "ai": "guard", "sfx": "fart_short", "funny": true,
		"desc": "Lob a little green bomb. It bursts into a cloud of fart fog wherever it lands.", "kind": "shot", "speed": 15.0, "range": 15.0, "r": 0.55, "status": {"slow": 2.0}, "burst": {"fx": "fart", "r": 4.2, "dur": 6.0}},
	{"id": "whoopee_cushion", "name": "Whoopee Cushion", "cat": "trick", "tier": 1, "ai": "guard", "sfx": "fart_short", "funny": true,
		"desc": "Hide two cushions on the ground. Sit on one and the whole field hears about it. You also go flying.", "kind": "traps", "fx": "whoopee", "count": 2, "dur": 18.0, "r": 1.0},
	{"id": "banana_bomb", "name": "Banana Bomb", "cat": "trick", "tier": 2, "ai": "chase", "sfx": "slide_whistle", "funny": true,
		"desc": "Throw a whole bunch. It bursts into six peels around where it lands, and every one of them sends somebody sliding.", "kind": "shot", "speed": 16.0, "range": 16.0, "r": 0.6, "burst": {"fx": "peel_ring", "count": 6, "r": 2.6, "dur": 12.0}},
	{"id": "giant_burp", "name": "Giant Burp", "cat": "attack", "tier": 1, "ai": "flee", "sfx": "burp", "funny": true,
		"desc": "Too much soda. Everyone nearby is blown off their feet, and nobody will ever speak of it.", "kind": "aoe", "r": 8.0, "push": 24.0, "status": {"stun": 0.4}, "word": "BUUURP!"},
	{"id": "big_sneeze", "name": "Big Sneeze", "cat": "attack", "tier": 1, "ai": "chase", "sfx": "sneeze", "funny": true,
		"desc": "Ah... ah... CHOO! A big wet splat flies forward, and everyone it hits goes sliding.", "kind": "shot", "speed": 18.0, "range": 18.0, "r": 1.1, "pierce": true, "push": 12.0, "status": {"slip": 2.5}},
	{"id": "cow_drop", "name": "Cow Drop", "cat": "attack", "tier": 2, "ai": "chase", "sfx": "slide_whistle", "funny": true,
		"desc": "Look up! A cow falls on the nearest enemy. Its shadow follows them, then: moo.", "kind": "drop", "range": 24.0, "fall": 1.2, "r": 2.1, "status": {"stun": 2.2}},
	{"id": "tickle_attack", "name": "Tickle Attack", "cat": "trick", "tier": 1, "ai": "chase", "sfx": "giggle", "funny": true,
		"desc": "A hundred feathers go for everyone nearby. For 4 seconds they can barely stand, let alone run straight.", "kind": "aoe", "r": 9.0, "status": {"tickle": 4.0}},
	{"id": "rubber_chicken", "name": "Rubber Chicken", "cat": "attack", "tier": 1, "ai": "chase", "sfx": "honk", "funny": true,
		"desc": "Slap everyone close to you with a rubber chicken. It's mostly the noise that hurts.", "kind": "aoe", "r": 3.4, "push": 30.0, "status": {"stun": 0.7}, "word": "SQUEAK!"},
	{"id": "wedgie", "name": "Mega Wedgie", "cat": "trick", "tier": 2, "ai": "chase", "sfx": "slide_whistle", "funny": true,
		"desc": "The nearest enemy gets hauled up by their pants. They can't move for 2 seconds. They'll never forget it.", "kind": "curse", "range": 18.0, "status": {"stun": 2.0}, "word": "WEDGIE!"},
	{"id": "bubble_gum", "name": "Bubble Gum", "cat": "trick", "tier": 1, "ai": "guard", "sfx": "squelch", "funny": true,
		"desc": "Spit a big pink wad. Whoever it hits is stuck for 2.5 seconds, and it leaves a sticky mess behind.", "kind": "shot", "speed": 15.0, "range": 16.0, "r": 0.6, "status": {"root": 2.5}, "burst": {"fx": "slow", "r": 2.6, "dur": 5.0}},
	{"id": "itching_powder", "name": "Itching Powder", "cat": "trick", "tier": 1, "ai": "guard", "sfx": "giggle", "funny": true,
		"desc": "Throw some down the nearest enemy's neck. For 6 seconds they keep stopping to scratch.", "kind": "curse", "range": 20.0, "status": {"itch": 6.0}, "word": "SO ITCHY!"},
	{"id": "bean_burrito", "name": "Bean Burrito", "cat": "speed", "tier": 1, "ai": "flee", "sfx": "fart_long", "funny": true, "cell": Cosmetics.Fx.PUFF, "color": "9be36a",
		"desc": "Eat it. For 5 seconds you run faster, and everything behind you regrets it.", "kind": "self", "status": {"speed2": 5.0, "farttrail": 5.0}},
	{"id": "clown_car", "name": "Clown Car", "cat": "trick", "tier": 2, "ai": "attack", "sfx": "honk", "funny": true, "cell": Cosmetics.Fx.CONFETTI,
		"desc": "Honk honk! Five of you pile out of nowhere and run alongside you for 7 seconds. Touch the wrong one and it's a nasty surprise.", "kind": "clones", "count": 5, "dur": 7.0},
	{"id": "pie_barrage", "name": "Pie Barrage", "cat": "attack", "tier": 2, "ai": "chase", "sfx": "squelch", "funny": true, "model": "cream_pie",
		"desc": "Five cream pies at once, in a fan. Every one that lands, somebody can't see for 3 seconds.", "kind": "volley", "count": 5, "spread": 0.2, "speed": 20.0, "range": 18.0, "r": 0.5, "status": {"blind": 3.0, "slow": 1.0}},
	{"id": "wet_fish", "name": "Wet Fish", "cat": "attack", "tier": 1, "ai": "chase", "sfx": "squelch", "funny": true, "cell": Cosmetics.Fx.FISH, "color": "7ee8ff",
		"desc": "Slap everyone close to you with a large wet fish. It doesn't hurt. It's just very, very surprising.", "kind": "aoe", "r": 4.0, "push": 26.0, "status": {"stun": 0.6}, "word": "SLAP!"},
	{"id": "banana_rain", "name": "Banana Rain", "cat": "trick", "tier": 2, "ai": "any", "sfx": "slide_whistle", "funny": true, "cell": Cosmetics.Fx.BANANA, "color": "ffe05c",
		"desc": "Ten peels fall out of the sky all over the enemy's half. Nobody knows who ordered them.", "kind": "peel_rain", "count": 10, "dur": 12.0},
	{"id": "stinky_socks", "name": "Stinky Socks", "cat": "trick", "tier": 1, "ai": "flee", "sfx": "fart_short", "funny": true, "cell": Cosmetics.Fx.PUFF, "color": "9be36a",
		"desc": "Take your shoes off. Everyone nearby runs away holding their nose, and the smell stays on them.", "kind": "aoe", "r": 8.0, "status": {"fear": 2.2, "stink": 5.0}, "word": "PEE-YEW!"},
	{"id": "piano_drop", "name": "Piano Drop", "cat": "attack", "tier": 2, "ai": "chase", "sfx": "slide_whistle", "funny": true,
		"desc": "A grand piano falls on the nearest enemy. Its shadow follows them. They should've taken lessons.", "kind": "drop", "range": 24.0, "fall": 1.2, "r": 2.2, "status": {"stun": 2.2}},
	{"id": "giant_foot", "name": "Giant Foot", "cat": "attack", "tier": 3, "ai": "chase", "sfx": "slide_whistle", "funny": true,
		"desc": "An enormous bare foot comes down from the sky on the nearest enemy, and anyone standing near them. Nobody knows whose.", "kind": "drop", "range": 26.0, "fall": 1.3, "r": 3.4, "status": {"stun": 2.6}},
	{"id": "snot_rocket", "name": "Snot Rocket", "cat": "attack", "tier": 1, "ai": "chase", "sfx": "sneeze", "funny": true, "model": "big_sneeze", "cell": Cosmetics.Fx.DROP, "color": "9be36a",
		"desc": "It finds its target, and you don't want to know how. Whoever it hits goes sliding.", "kind": "shot", "speed": 14.0, "range": 28.0, "r": 0.6, "homing": true, "status": {"slip": 2.5, "slow": 2.0}},
	{"id": "mouse_traps", "name": "Mouse Traps", "cat": "defend", "tier": 1, "ai": "guard", "sfx": "piece_place", "funny": true,
		"desc": "Hide four big mouse traps behind you. Snap. They'll be hopping for a while.", "kind": "traps", "fx": "snare", "count": 4, "dur": 16.0, "r": 1.1},
	{"id": "hot_sauce", "name": "Hot Sauce", "cat": "trick", "tier": 1, "ai": "guard", "sfx": "trail_fire", "funny": true, "cell": Cosmetics.Fx.FLAME, "color": "ff5a1f",
		"desc": "A squirt in the nearest enemy's mouth. They run in circles for 3 seconds, breathing fire on their own team's way.", "kind": "curse", "range": 18.0, "status": {"fear": 3.0, "firetrail": 3.0}, "word": "HOT HOT HOT!"},
	{"id": "spring_trap", "name": "Spring Trap", "cat": "trick", "tier": 1, "ai": "guard", "sfx": "move_bounce", "funny": true,
		"desc": "Hide two big springs on the ground. Step on one and you're thrown all the way back where you came from.", "kind": "traps", "fx": "spring", "count": 2, "dur": 18.0, "r": 1.1},
	{"id": "plunger", "name": "Plunger", "cat": "defend", "tier": 1, "ai": "guard", "sfx": "squelch", "funny": true, "model": "plunger",
		"desc": "Fire a toilet plunger. It sticks to the first enemy it hits and hauls them back to you. It's clean. Probably.", "kind": "shot", "speed": 22.0, "range": 18.0, "r": 0.5, "push": -24.0, "status": {"root": 0.8}},
	{"id": "dad_joke", "name": "Dad Joke", "cat": "trick", "tier": 1, "ai": "guard", "sfx": "giggle", "funny": true, "cell": Cosmetics.Fx.ZZZ,
		"desc": "Tell a dad joke. Everyone nearby stops dead and groans. It's not even a good one.", "kind": "aoe", "r": 10.0, "status": {"stun": 1.2},
		"jokes": ["Hi Hungry, I'm Dad!", "Knock knock.", "I'm on a seafood diet.", "Time flies like a banana.", "Two tags walk into a bar...", "Why so stale?"]},
	# --- Team ------------------------------------------------------------------------------------
	{"id": "jailbreak", "name": "Jailbreak", "cat": "team", "tier": 3, "ai": "jail", "sfx": "finale_fireworks",
		"desc": "Every teammate in jail walks free, from anywhere on the map.", "kind": "jailbreak"},
	{"id": "fiesta_rush", "name": "Party Rush", "cat": "team", "tier": 2, "ai": "attack", "sfx": "finale_fiesta",
		"desc": "Your whole team runs 30% faster for 7 seconds.", "kind": "team", "status": {"speed2": 7.0}},
	{"id": "team_refresh", "name": "Team Refresh", "cat": "team", "tier": 3, "ai": "chase", "sfx": "finale_rainbow",
		"desc": "For 6 seconds your whole team can tag anyone, on either side.", "kind": "teamfresh"},
	{"id": "group_hug", "name": "Group Hug", "cat": "team", "tier": 2, "ai": "attack", "sfx": "aura_love",
		"desc": "Everyone on your team gets a shield for 7 seconds.", "kind": "team", "status": {"shield": 7.0}},
	{"id": "radar_ping", "name": "Radar Ping", "cat": "team", "tier": 1, "ai": "any", "sfx": "trail_warp",
		"desc": "Your team sees hidden enemies and traps for 10 seconds.", "kind": "radar", "dur": 10.0},
	{"id": "capture_boost", "name": "Capture Boost", "cat": "team", "tier": 2, "ai": "attack", "sfx": "flag_capture",
		"desc": "You capture the enemy base twice as fast for 9 seconds.", "kind": "self", "status": {"fastcap": 9.0}},
	{"id": "power_rain", "name": "Power Rain", "cat": "team", "tier": 3, "ai": "any", "sfx": "finale_gifts",
		"desc": "Five new powerups rain down around you. Share. Or don't.", "kind": "rain", "count": 5},
	{"id": "rally_call", "name": "Rally Call", "cat": "team", "tier": 3, "ai": "attack", "sfx": "taunt_foghorn",
		"desc": "Everyone on your team warps straight to you. Jailed ones stay put, sadly.", "kind": "rally"},
	{"id": "crystal_vacuum", "name": "Crystal Vacuum", "cat": "team", "tier": 1, "ai": "any", "sfx": "kill_ufo_abduction",
		"desc": "Sucks every crystal within 18 metres to your feet. Don't forget to share.", "kind": "vacuum", "r": 18.0},
	{"id": "cheer_squad", "name": "Cheer Squad", "cat": "team", "tier": 2, "ai": "any", "sfx": "finale_cheer",
		"desc": "Your whole team shakes off stuns and curses, gets their dash back, and runs faster for 4 seconds.", "kind": "cheer", "status": {"speed2": 4.0}},
	{"id": "weather_machine", "name": "Weather Machine", "cat": "team", "tier": 3, "ai": "any", "sfx": "kill_storm_caller",
		"desc": "Turn the dial! The sky changes for 25 seconds: fog, storm, blizzard or sand. Nobody's ready but you.", "kind": "weather", "dur": 25.0, "kinds": ["fog", "storm", "snow", "sand", "night", "hail"]},
]

static var _by_id := {}
static var _pools := {}


static func by_id(id: String) -> Dictionary:
	if _by_id.is_empty():
		for def: Dictionary in ALL:
			_by_id[def["id"]] = def
	var found: Variant = _by_id.get(id)
	if found != null:
		return found
	return Skills.power_def(id) if id.begins_with("sk:") else {}


static func has(id: String) -> bool:
	return not by_id(id).is_empty()


## Which deck it's in: a card's, or for a skill, what kind of skill it is.
static func side_of(id: String) -> String:
	return DEFEND if id in DEFENCE_DECK else ATTACK


## A random powerup id from one deck, or from both, weighted by tier.
static func roll(rng: RandomNumberGenerator, side := "") -> String:
	if _pools.is_empty():
		_pools = {"": [], ATTACK: [], DEFEND: []}
		for def: Dictionary in ALL:
			for _i in int(TIER_WEIGHT[int(def["tier"])]) * (FUNNY_WEIGHT if def.get("funny", false) else 1):
				_pools[""].append(String(def["id"]))
				_pools[side_of(String(def["id"]))].append(String(def["id"]))
	var pool: Array = _pools[side]
	return pool[rng.randi_range(0, pool.size() - 1)]


static func index_of(id: String) -> int:
	for i in ALL.size():
		if ALL[i]["id"] == id:
			return i
	return -1


static func id_at(i: int) -> String:
	return String(ALL[i]["id"]) if i >= 0 and i < ALL.size() else ""


static func color(id: String) -> Color:
	var def := by_id(id)
	if def.is_empty():
		return Color.WHITE
	if def.has("color"):
		return Color(def["color"])
	return CATS[def["cat"]]["color"]


static func icon_path(id: String) -> String:
	return "res://assets/icons/power/%s.svg" % id
