class_name Powerups
extends RefCounted
## Every power a crystal can hold. Sim reads `kind` and its parameters; the HUD, the codex and the 3D view read
## the name, description, category, card and sound. `tier` sets how often it comes up
## (1 common, 2 rare, 3 epic). `ai` tells the bots when it makes sense:
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
		"desc": "Hidden snares appear around your base and pin any intruder who steps on one.", "kind": "snares", "count": 6, "dur": 25.0},
	{"id": "pop_mines", "name": "Pop Mines", "cat": "defend", "tier": 1, "ai": "flee", "sfx": "taunt_popcorn_pop",
		"desc": "Drop three mines around you. Whoever steps on one goes flying.", "kind": "mines", "count": 3, "dur": 20.0},
	{"id": "slow_dome", "name": "Slow Dome", "cat": "defend", "tier": 1, "ai": "flee", "sfx": "aura_shimmer",
		"desc": "A dome that drags enemies down to half speed for 6 seconds.", "kind": "zone", "fx": "slow", "r": 5.5, "dur": 6.0, "at": 0.0},
	{"id": "thorn_hedge", "name": "Thorn Hedge", "cat": "defend", "tier": 2, "ai": "guard", "sfx": "aura_nature",
		"desc": "Thorns ring your base for 10 seconds. Intruders get stuck on the way in.", "kind": "hedge", "dur": 10.0},
	{"id": "mirror_shield", "name": "Mirror Shield", "cat": "defend", "tier": 2, "ai": "flee", "sfx": "kill_wand_twinkle",
		"desc": "For 6 seconds shots bounce back at whoever fired them, and stuns can't touch you.", "kind": "self", "status": {"mirror": 6.0}},
	{"id": "fresh_start", "name": "Fresh Start", "cat": "defend", "tier": 2, "ai": "flee", "sfx": "trail_sparkle",
		"desc": "For 6 seconds you can tag anyone, on either side of the line.", "kind": "fresh"},
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
	# --- Team ------------------------------------------------------------------------------------
	{"id": "jailbreak", "name": "Jailbreak", "cat": "team", "tier": 3, "ai": "jail", "sfx": "finale_fireworks",
		"desc": "Every teammate in jail walks free, from anywhere on the map.", "kind": "jailbreak"},
	{"id": "fiesta_rush", "name": "Fiesta Rush", "cat": "team", "tier": 2, "ai": "attack", "sfx": "finale_fiesta",
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
]

static var _by_id := {}
static var _pool: Array[String] = []


static func by_id(id: String) -> Dictionary:
	if _by_id.is_empty():
		for def: Dictionary in ALL:
			_by_id[def["id"]] = def
	return _by_id.get(id, {})


static func has(id: String) -> bool:
	return not by_id(id).is_empty()


## A random powerup id, weighted by tier.
static func roll(rng: RandomNumberGenerator) -> String:
	if _pool.is_empty():
		for def: Dictionary in ALL:
			for _i in int(TIER_WEIGHT[int(def["tier"])]):
				_pool.append(String(def["id"]))
	return _pool[rng.randi_range(0, _pool.size() - 1)]


static func index_of(id: String) -> int:
	for i in ALL.size():
		if ALL[i]["id"] == id:
			return i
	return -1


static func id_at(i: int) -> String:
	return String(ALL[i]["id"]) if i >= 0 and i < ALL.size() else ""


static func color(id: String) -> Color:
	var def := by_id(id)
	return CATS[def["cat"]]["color"] if not def.is_empty() else Color.WHITE


static func icon_path(id: String) -> String:
	return "res://assets/icons/power/%s.svg" % id
