class_name Maps
extends RefCounted
## Every arena. A map is a theme (how it looks) plus a layout (where the walls, water and pads are).
## Layouts are drawn as the left half of the field and mirrored, so both teams always get the same
## ground: "x" mirrors left to right, "rot" turns the half 180 degrees.
##
## Tiles: . floor   # wall   ~ water/lava/void (blocks feet, not shots)   g bushes (hide you)
##        i ice     m mud    b bounce pad (flies you to its mirror)    t teleporter (joined to its mirror)
##        > < ^ v conveyor   A your base      J the jail where you keep prisoners
##        R L U D dash floor: shoots you that way
##        1 2     jump pad: throws you to the landing box with the same number ! @
##        =       gate: rises and falls on a timer
##        f       fountain: makes whoever touches it fresh, then needs time to refill
##        * crystal altar: always grows a new crystal
##        %       low fence: stops a walk, but a dash goes over it
##        o       bumper: knocks you flying
##        s       spikes: pop up on a beat
##        c       crumbling floor: falls away after you stand on it, and grows back
##        a       spinning arm: a long beam sweeping round this block
##        |       road: traffic comes down it every so often
##        z       geyser: blows on a beat and throws you somewhere nearby
##        q       quicksand: drags you to its middle; dash to get out
##        w       lookout tower: stand on it and your team sees every enemy
##        x       powder crate: blows up when dashed into or shot, and comes back later
##        n       stepping stone: sinks and rises in turn with its neighbours
##        y       web: catches whoever runs in, and takes a while to grow back
##        T       tide flats: the sea comes in on a timer and slows you right down

const TILE := 2.0  ## Metres per tile.
const CLEAR_BASE := 5.8  ## Nothing stands this close to the middle of a base...
const CLEAR_JAIL := 3.2  ## ...or of a jail.

enum { FLOOR, SOLID, PIT, GRASS, ICE, MUD, BOUNCE, TELE, CON_R, CON_L, CON_U, CON_D, DASH_R, DASH_L, DASH_U, DASH_D, JUMP, LAND, GATE, FOUNTAIN, ALTAR, FENCE, BUMPER,
	SPIKES, CRUMBLE, ARM, ROAD, GEYSER, QUICKSAND, TOWER, TNT, STONE, WEB, TIDE }

const JUMP_PADS := {"1": "!", "2": "@"}

const LAYOUTS := {
	"plaza": {"name": "Plaza", "mirror": "x", "blurb": "Wide open. Good for your first game.", "rows": [
		"..............",
		"..J...RR...*..",
		"..............",
		"......##......",
		"......##..ggg.",
		"..........ggg.",
		"..............",
		"..A....1..##!f",
		"..............",
		"..........ggg.",
		"......##..ggg.",
		"......##......",
		"..............",
		".....RR....*..",
		"..............",
	]},
	"crossroads": {"name": "Crossroads", "mirror": "x", "blurb": "Four walled blocks and a busy junction.", "rows": [
		"..............",
		"..J.........*.",
		"......####....",
		"......####..gg",
		"......##....gg",
		"..........=...",
		"..........#...",
		"..A.......#.of",
		"..........#...",
		"..........=...",
		"......##....gg",
		"......####..gg",
		"......####....",
		".......RRR....",
		"............*.",
	]},
	"twin_ponds": {"name": "Twin Ponds", "mirror": "x", "blurb": "Two ponds squeeze the middle of the field.", "rows": [
		"..............",
		"..J......gg...",
		"......1..gg...",
		"......~~~~....",
		".....~~~~~~.*.",
		"......~~~~....",
		"........!.....",
		"..A.....RRR..f",
		"........@.....",
		"......~~~~....",
		".....~~~~~~.*.",
		"......~~~~....",
		"......2..gg...",
		".........gg...",
		"..............",
	]},
	"zigzag": {"name": "Zigzag", "mirror": "rot", "blurb": "Slanted walls that bend every chase.", "rows": [
		"..............",
		"..J.....##....",
		"........##..f.",
		"......##..D...",
		"......##...gg.",
		"....##.....gg.",
		"....##.%....o.",
		"..A....%..##.*",
		".......%..##..",
		"........##.U..",
		".gg.....##....",
		".gg...##......",
		"......##......",
		"....##.R......",
		"....##.R......",
	]},
	"fortress": {"name": "Fortress", "mirror": "x", "blurb": "Your base sits behind walls with two gates.", "rows": [
		"..............",
		"..J.....*.RR..",
		"..............",
		"#####.........",
		"....#.....gg..",
		"....#.....gg..",
		".....=........",
		"..A..=....##.f",
		".....=........",
		"....#.....gg..",
		"....#.....gg..",
		"#####.........",
		"..............",
		"........*RR...",
		"..............",
	]},
	"conveyors": {"name": "Conveyor Alley", "mirror": "x", "blurb": "Belts carry you to the front or sweep you home.", "rows": [
		"..............",
		"..J...........",
		"....>>>>>>>>>>",
		"..............",
		"......##.gg.*.",
		"......##.gg...",
		"..............",
		"..A.....o..o.f",
		"..............",
		"......##.gg...",
		"......##.gg.*.",
		"..............",
		"....<<<<<<<<<<",
		"..............",
		"..............",
	]},
	"bouncy": {"name": "Bounce Canal", "mirror": "x", "blurb": "A canal down the middle. Bounce pads fly you over it.", "rows": [
		"...........~~~",
		"..J....gg..~~~",
		".......gg..~~~",
		".........b.~~~",
		"...........~~~",
		".........*.~~~",
		"..............",
		"..A.....RR...f",
		"..............",
		".........*.~~~",
		"...........~~~",
		".........b.~~~",
		".......gg..~~~",
		".......gg..~~~",
		"...........~~~",
	]},
	"teleports": {"name": "Warp Yard", "mirror": "x", "blurb": "Step in a warp and step out on the far side.", "rows": [
		"..............",
		"..J.....##....",
		"........##....",
		".....t......*.",
		"..............",
		"......==..gg..",
		"......##..gg..",
		"..A...##..o..f",
		"......##..gg..",
		"......==..gg..",
		"..............",
		".....t......*.",
		"........##....",
		"........##....",
		"..............",
	]},
	"rink": {"name": "Skating Rink", "mirror": "x", "blurb": "The whole middle is slippery. Mind the turns.", "rows": [
		".........R....",
		"..J.......*...",
		".......iiiiiii",
		"......iiiiiioi",
		".....iii##iiii",
		".....iii##iiii",
		".....iiiiiiiii",
		"..A..iiiioiiif",
		".....iiiiiiiii",
		".....iii##iiii",
		".....iii##iiii",
		"......iiiiiioi",
		".......iiiiiii",
		"..........*...",
		".........R....",
	]},
	"mudflats": {"name": "Mud Flats", "mirror": "x", "blurb": "Sticky patches slow you down. The dry lanes are worth it.", "rows": [
		"...........*..",
		"..J......mmmmm",
		".........mmmmm",
		"......##.mmmmm",
		"......##.RRR..",
		"..............",
		"........mmmm..",
		"..A...1.mmmm!f",
		"........mmmm..",
		"..............",
		"......##.RRR..",
		"......##.mmmmm",
		".........mmmmm",
		".........mmmmm",
		"...........*..",
	]},
	"hideout": {"name": "Hide & Seek", "mirror": "x", "blurb": "Tall grass everywhere. Who's in there?", "rows": [
		".......gggggg.",
		"..J....gggggg.",
		"......ggg..gg.",
		"......gg..*.!.",
		"....ggg..##...",
		"....gg...##.gg",
		".........gggg.",
		"..A...1..ggggf",
		".........gggg.",
		"....gg...##.gg",
		"....ggg..##...",
		"......gg..*...",
		"......ggg..gg.",
		".......gggggg.",
		".......gggggg.",
	]},
	"pillars": {"name": "Pillars", "mirror": "x", "blurb": "A forest of pillars. Perfect for shaking off a chaser.", "rows": [
		"..............",
		"..J...#...#...",
		".....%....*...",
		"....#%..#...#.",
		"..............",
		"......#.o.#...",
		"..............",
		"..A.#...#...#f",
		"..............",
		"......#.o.#...",
		"..............",
		"....#%..#...#.",
		".....%....*...",
		"......#...#...",
		"..............",
	]},
	"bridges": {"name": "Three Bridges", "mirror": "x", "blurb": "A river cuts the field. Hold the bridges.", "rows": [
		"..........~~~~",
		"..J.....*.~~~~",
		"..........~~~~",
		"...........=..",
		"..........~~~~",
		"........b.~~~~",
		"..........~~~~",
		"..A..........f",
		"..........~~~~",
		"........b.~~~~",
		"..........~~~~",
		"...........=..",
		"..........~~~~",
		"........*.~~~~",
		"..........~~~~",
	]},
	"ringroad": {"name": "Ring Road", "mirror": "x", "blurb": "A great block in the centre. Go round, left or right.", "rows": [
		"..............",
		"..J.....RRR..f",
		"..............",
		".......*.#####",
		".........#####",
		".........#####",
		"...gg....#####",
		"..A.gg.b.#####",
		"...gg....#####",
		".........#####",
		".........#####",
		".......*.#####",
		"..............",
		"........RRR..f",
		"..............",
	]},
	"pinwheel": {"name": "Pinwheel", "mirror": "rot", "blurb": "Walls spin around the centre. No two lanes are the same.", "rows": [
		"..............",
		"..J.......####",
		"..........#...",
		"...gg.....#.*.",
		"...gg...D.....",
		".......###....",
		".......#......",
		"..A....#.....f",
		".......#......",
		"....####......",
		"...........U..",
		".....o...gg...",
		".........gg...",
		"........RR....",
		"..............",
	]},
	"gauntlet": {"name": "The Gauntlet", "mirror": "x", "blurb": "Long corridors, tight corners, nowhere to hide.", "rows": [
		"........gg....",
		"..J...........",
		"....##########",
		"......RRR....*",
		"..............",
		"....########..",
		"..............",
		"..A.....%....f",
		"..............",
		"....########..",
		"..............",
		"......RRR....*",
		"....##########",
		"..............",
		"........gg....",
	]},
	"crumble": {"name": "Crumble Crossing", "mirror": "x", "blurb": "Bridges fall away after you cross. Don't stop to wave.", "rows": [
		"..........~~~~",
		"..J.....*.~~~~",
		"....%.....cccc",
		"....%.....~~~~",
		".......gg.~~~~",
		".......gg.cccc",
		"..........~~~~",
		"..A..........f",
		"..........~~~~",
		".......gg.cccc",
		".......gg.~~~~",
		"....%.....~~~~",
		"....%.....cccc",
		"........*.~~~~",
		"..........~~~~",
	]},
	"rush_hour": {"name": "Rush Hour", "mirror": "x", "blurb": "Look both ways. Traffic doesn't stop for a game of tag.", "rows": [
		"........|...|.",
		"..J.....|.*.|.",
		"........|...|.",
		".....##.|.gg|.",
		".....##.|.gg|.",
		"........|...|.",
		"........|...|.",
		"..A.....|.o.|f",
		"........|...|.",
		"........|...|.",
		".....##.|.gg|.",
		".....##.|.gg|.",
		"........|...|.",
		"........|.*.|.",
		"........|...|.",
	]},
	"spike_alley": {"name": "Spike Alley", "mirror": "x", "blurb": "Spikes pop up on a beat. Learn the beat.", "rows": [
		"..............",
		"..J....ss.*...",
		".......ss.....",
		"....##...ss.gg",
		"....##...ss.gg",
		".......ss.....",
		".......ss.....",
		"..A......ss..f",
		".......ss.....",
		".......ss.....",
		"....##...ss.gg",
		"....##...ss.gg",
		".......ss.....",
		".......ss.*...",
		"..............",
	]},
	"windmills": {"name": "Spinning Arms", "mirror": "x", "blurb": "Big arms sweep the field. Duck through at the right moment.", "rows": [
		"..............",
		"..J.........*.",
		"......gg......",
		"........a.....",
		"......gg......",
		"............a.",
		"..............",
		"..A.....a....f",
		"..............",
		"............a.",
		"......gg......",
		"........a.....",
		"......gg......",
		"............*.",
		"..............",
	]},
	"springs": {"name": "Hot Springs", "mirror": "x", "blurb": "Geysers blow on a beat, and throw you wherever they like.", "rows": [
		"..............",
		"..J....z..z.*.",
		"..............",
		"......~~~~....",
		".....~~~~~~.z.",
		"......~~~~....",
		"..........z...",
		"..A..z.......f",
		"..........z...",
		"......~~~~....",
		".....~~~~~~.z.",
		"......~~~~....",
		"..............",
		".......z..z.*.",
		"..............",
	]},
	"sinking": {"name": "Sinking Sands", "mirror": "x", "blurb": "Quicksand drags you in. Dash out before it swallows your lead.", "rows": [
		"......qqq.....",
		"..J...qqq...*.",
		"..........##..",
		".........q##..",
		"........qqq...",
		"....##..qqq.gg",
		"....##...q..gg",
		"..A..........f",
		"....##...q..gg",
		"....##..qqq.gg",
		"........qqq...",
		".........q##..",
		"..........##..",
		"......qqq...*.",
		"......qqq.....",
	]},
	"lookout": {"name": "The Lookout", "mirror": "x", "blurb": "Stand on a lookout tower and your team sees everyone.", "rows": [
		".......gggggg.",
		"..J....g....g.",
		"......wg..w.g.",
		".......g....g.",
		"....ggggg.ggg.",
		"....g.........",
		"....g...*.....",
		"..A.....##...f",
		"....g...*.....",
		"....g.........",
		"....ggggg.ggg.",
		".......g....g.",
		"......wg..w.g.",
		".......g....g.",
		".......gggggg.",
	]},
	"powder": {"name": "Powder Keg", "mirror": "x", "blurb": "Dash into a crate and it all goes up, so mind who's standing next to it.", "rows": [
		"..............",
		"..J...xx....*.",
		"......xx..o...",
		"..........xxx.",
		"....##....x...",
		"....##...gg...",
		".........gg.xx",
		"..A.......x..f",
		".........gg.xx",
		"....##...gg...",
		"....##....x...",
		"..........xxx.",
		"......xx..o...",
		"......xx....*.",
		"..............",
	]},
	"stepping": {"name": "Stepping Stones", "mirror": "x", "blurb": "Stones sink and rise in turn. Time your crossing, or take the long way round.", "rows": [
		"..........~~~~",
		"..J.....*.~~~~",
		"........b.~~~~",
		"..........nnnn",
		"..........~~~~",
		".......gg.~~~~",
		".......gg..~~~",
		"..A.........f.",
		".......gg..~~~",
		".......gg.~~~~",
		"..........~~~~",
		"..........nnnn",
		"........b.~~~~",
		"........*.~~~~",
		"..........~~~~",
	]},
	"webs": {"name": "Sticky Woods", "mirror": "x", "blurb": "Webs catch whoever runs in first. Let someone else go ahead.", "rows": [
		"....g.y..g....",
		"..J.g.y..g..*.",
		"....g....g.y..",
		".....y...g.y..",
		"...........gg.",
		"....gg.y...gg.",
		"....gg.y.y....",
		"..A......y...f",
		"....gg.y.y....",
		"....gg.y...gg.",
		"...........gg.",
		".....y...g.y..",
		"....g....g.y..",
		"....g.y..g..*.",
		"......y..g....",
	]},
	"tides": {"name": "Rising Tide", "mirror": "x", "blurb": "The sea comes in on a timer. Be somewhere dry when it does.", "rows": [
		"..........TTTT",
		"..J.....*.TTTT",
		".........TTTTT",
		"....##..TTTTTT",
		"....##..TT##TT",
		"........TTTTTT",
		"...........TTT",
		"..A......o...f",
		"...........TTT",
		"........TTTTTT",
		"....##..TT##TT",
		"....##..TTTTTT",
		".........TTTTT",
		"........*.TTTT",
		"..........TTTT",
	]},
	"temple": {"name": "Temple Run", "mirror": "x", "blurb": "Spikes, falling floors and a sweeping arm. Someone didn't want visitors.", "rows": [
		"..............",
		"..J...####...*",
		"......####.a..",
		"..............",
		".....ss...ccc.",
		".....ss.#.ccc.",
		"........#.....",
		"..A...ss.....f",
		"........#.....",
		".....ss.#.ccc.",
		".....ss...ccc.",
		"..............",
		"......####.a..",
		"......####...*",
		"..............",
	]},
	"bazaar": {"name": "The Bazaar", "mirror": "x", "blurb": "Tight alleys and low stalls. Dash over them to lose a chaser.", "rows": [
		"......#...#...",
		"..J...#.*.#.gg",
		"......#...#.gg",
		"...........RRR",
		"....%%%.%%%...",
		"......#...#...",
		"......#.o.#.*.",
		"..A..........f",
		"......#.o.#.*.",
		"......#...#...",
		"....%%%.%%%...",
		"...........RRR",
		"......#...#.gg",
		"......#.*.#.gg",
		"......#...#...",
	]},
	"circuit": {"name": "The Circuit", "mirror": "x", "blurb": "Belts carry you into the traffic. Hop off in time.", "rows": [
		"........|.....",
		"..J.....|.*...",
		"....>>>>|>>>>>",
		"........|.....",
		"......gg|..o..",
		"......gg|.....",
		"........|.....",
		"..A.....|....f",
		"........|.....",
		"......gg|.....",
		"......gg|..o..",
		"........|.....",
		"....<<<<|<<<<<",
		"........|.*...",
		"........|.....",
	]},
	"crater": {"name": "Crater Rim", "mirror": "x", "blurb": "A crumbling ring round a great pit. The short way is the risky way.", "rows": [
		"..............",
		"..J......*....",
		"..........cccc",
		".........cc~~~",
		"........cc~~~~",
		"....z...c~~~~~",
		"........c~~~~~",
		"..A.....c~~~~~",
		"........c~~~~~",
		"....z...c~~~~~",
		"........cc~~~~",
		".........cc~~~",
		"..........cccc",
		".........*....",
		"..............",
	]},
	"maze": {"name": "The Maze", "mirror": "x", "blurb": "Walls, gates and dead ends. The tower shows you who's coming.", "rows": [
		"..............",
		"..J...####.#..",
		"......#..=.#.*",
		".....##.##.#..",
		"......#.....w.",
		"...##.#.###.##",
		"......=.#.....",
		"..A.....#.o..f",
		"......=.#.....",
		"...##.#.###.##",
		"......#.....w.",
		".....##.##.#..",
		"......#..=.#.*",
		"......####.#..",
		"..............",
	]},
	"islands": {"name": "Island Hop", "mirror": "x", "blurb": "Warp across, bounce over, and don't get cornered on the sand.", "rows": [
		"..........~~~~",
		"..J.......~..~",
		"..........~.*~",
		"......t...~..~",
		".......~~~~~.~",
		".......~....b.",
		".......~.gg...",
		"..A......gg..f",
		".......~.gg...",
		".......~....b.",
		".......~~~~~.~",
		"......t...~..~",
		"..........~.*~",
		"..........~..~",
		"..........~~~~",
	]},
	"castle": {"name": "Castle Siege", "mirror": "x", "blurb": "A moat, a wall and a gate on the beat. Watch from the tower.", "rows": [
		"..............",
		"..J......~~...",
		"......w..~~.*.",
		"......###.~~..",
		"........#.~~..",
		"........#.~~.o",
		"........=.....",
		"..A.....=....f",
		"........=.....",
		"........#.~~.o",
		"........#.~~..",
		"......###.~~..",
		".........~~.*.",
		".........~~...",
		"..............",
	]},
	"canals": {"name": "The Canals", "mirror": "x", "blurb": "Water everywhere and only three ways across.", "rows": [
		"......~~..~~..",
		"..J...~~..~~.*",
		"......~~..~~..",
		"..............",
		"......~~..~~..",
		"......~~..~~gg",
		"......~~..~~gg",
		"..A..........f",
		"......~~..~~gg",
		"......~~..~~gg",
		"......~~..~~..",
		"..............",
		"......~~..~~..",
		"......~~..~~.*",
		"......~~..~~..",
	]},
	"skatepark": {"name": "Skate Park", "mirror": "x", "blurb": "Ice, boost floors and bumpers. Nobody here has any brakes.", "rows": [
		"...........iii",
		"..J...RR..iiii",
		".........iiiii",
		".....o..iiio.i",
		"........iiiiii",
		"......RR.iii.*",
		"..........ii..",
		"..A...o..RRR.f",
		"..........ii..",
		"......RR.iii.*",
		"........iiiiii",
		".....o..iiio.i",
		".........iiiii",
		"......RR..iiii",
		"...........iii",
	]},
	"zen": {"name": "Quiet Garden", "mirror": "x", "blurb": "Low fences and soft bushes, and someone behind every one.", "rows": [
		"..............",
		"..J...%%%..gg.",
		".......%...gg.",
		"...........*..",
		"....gg..o.....",
		"....gg...%%%..",
		"..........%...",
		"..A...gg.....f",
		"..........%...",
		"....gg...%%%..",
		"....gg..o.....",
		"...........*..",
		".......%...gg.",
		"......%%%..gg.",
		"..............",
	]},
	"oasis": {"name": "The Oasis", "mirror": "x", "blurb": "Water in the middle and quicksand round the edge. Pick your poison.", "rows": [
		"......qqqq....",
		"..J..qqqqqq.*.",
		"......qqqq....",
		"............qq",
		"....#......qqq",
		"....#...~~..qq",
		".......~~~~...",
		"..A....~~~~..f",
		".......~~~~...",
		"....#...~~..qq",
		"....#......qqq",
		"............qq",
		"......qqqq....",
		".....qqqqqq.*.",
		"......qqqq....",
	]},
	"pinball": {"name": "Pinball", "mirror": "x", "blurb": "Bumpers everywhere. You will go where they send you.", "rows": [
		"..............",
		"..J.o...o...*.",
		"......o...o...",
		"..o.........o.",
		".....>>>>>....",
		"...o......o...",
		"......o.......",
		"..A.....o....f",
		"......o.......",
		"...o......o...",
		".....<<<<<....",
		"..o.........o.",
		"......o...o...",
		"....o...o...*.",
		"..............",
	]},
	"crossing": {"name": "Level Crossing", "mirror": "x", "blurb": "One long road down the line, and a geyser to get you over it.", "rows": [
		"...........|..",
		"..J...gg...|*.",
		"......gg...|..",
		"...........|..",
		"....##.....|cc",
		"....##...z.|cc",
		"...........|..",
		"..A..z.....|.f",
		"...........|..",
		"....##...z.|cc",
		"....##.....|cc",
		"...........|..",
		"......gg...|..",
		"......gg...|*.",
		"...........|..",
	]},
	"gladiator": {"name": "Gladiator Pit", "mirror": "x", "blurb": "Spikes in the sand and arms sweeping round. The crowd loves it.", "rows": [
		"..............",
		"..J.....s.s.*.",
		"......s.....s.",
		"..........a...",
		"....#.s.....s.",
		"....#...s.s...",
		"..............",
		"..A.....a....f",
		"..............",
		"....#...s.s...",
		"....#.s.....s.",
		"..........a...",
		"......s.....s.",
		"........s.s.*.",
		"..............",
	]},
}

## Look of a map. `pit` names what the ~ tiles are, `blocks` and `decor` are PropKit prop names.
const THEMES := {
	"barrio": {"name": "Barrio", "floor": ["7fd65a", "71c94f"], "edge": "58b048", "bg": "4aa03f", "sky": "8fe3ff",
		"pit": "water", "pit_c": "2ec4e8", "wall": "d99a5b", "accent": "ff5a7a", "grass": "2ea84a", "blocks": ["crate", "stall", "hay"], "decor": ["hut", "palm", "banderitas", "palm", "bush"], "music": "tropical_island"},
	"terraces": {"name": "Terraces", "floor": ["a6db5c", "96cf4e"], "edge": "6fae3c", "bg": "5c9c37", "sky": "b7ecff",
		"pit": "water", "pit_c": "6edff2", "wall": "9b7a54", "accent": "f7d154", "grass": "48b23f", "blocks": ["rock", "stump", "hay"], "decor": ["pine", "hut", "rock", "bush"], "music": "tropical_tiki"},
	"beach": {"name": "Coconut Beach", "floor": ["ffe39c", "fbd98a"], "edge": "f2c675", "bg": "2ec4e8", "sky": "9ff0ff",
		"pit": "water", "pit_c": "2ad3e6", "wall": "c98d55", "accent": "ff7a59", "grass": "6ccf5a", "blocks": ["barrel", "crate", "rock"], "decor": ["palm", "umbrella", "palm", "boat", "rock"], "music": "tropical_beach"},
	"terminal": {"name": "Jeepney Terminal", "floor": ["8f93a8", "85899e"], "edge": "6d7186", "bg": "5a5e74", "sky": "a8d8ff",
		"pit": "void", "pit_c": "3a3d52", "wall": "e8574a", "accent": "ffd23f", "grass": "4bb56b", "blocks": ["jeep", "cone_stack", "crate"], "decor": ["building", "lamp", "building", "tree"], "music": "funk"},
	"volcano": {"name": "Volcano", "floor": ["6b4a44", "5f403b"], "edge": "4a312d", "bg": "3a2522", "sky": "ffb27a",
		"pit": "lava", "pit_c": "ff6a1f", "wall": "3d2a32", "accent": "ffa51f", "grass": "a34a2e", "blocks": ["rock", "crystal", "rock"], "decor": ["spire", "rock", "spire"], "music": "gamer_hard"},
	"mangrove": {"name": "Mangrove", "floor": ["6cc2a0", "60b694"], "edge": "4b9d80", "bg": "2c8f8a", "sky": "c4f2d8",
		"pit": "water", "pit_c": "33b7a6", "wall": "7a5a3c", "accent": "ffcb47", "grass": "2f9c59", "blocks": ["stump", "rock", "barrel"], "decor": ["mangrove", "mushroom", "mangrove", "lily"], "music": "tropical_tiki"},
	"glacier": {"name": "Glacier", "floor": ["e4f6ff", "d4edfb"], "edge": "b6dcf2", "bg": "9ad0ee", "sky": "d9f3ff",
		"pit": "water", "pit_c": "4fb0e8", "wall": "8fc7ee", "accent": "ff6fb5", "grass": "b5e3f5", "blocks": ["ice_block", "crystal", "snowman"], "decor": ["pine_snow", "ice_block", "snowman", "pine_snow"], "music": "kids_polka"},
	"halo": {"name": "Halo-Halo Land", "floor": ["ffc9ea", "ffbde3"], "edge": "f09fd2", "bg": "b57cff", "sky": "ffe3f6",
		"pit": "syrup", "pit_c": "9d5cff", "wall": "ff7ab8", "accent": "6fe7ff", "grass": "7be0b5", "blocks": ["cake", "gumdrop", "donut"], "decor": ["lollipop", "cone", "lollipop", "gumdrop"], "music": "kids_polka"},
	"arcade": {"name": "Neon Arcade", "floor": ["2b2466", "251f5b"], "edge": "1c174a", "bg": "120e36", "sky": "3a2d8a",
		"pit": "void", "pit_c": "0b0826", "wall": "ff3fb4", "accent": "27e9ff", "grass": "27e9ff", "blocks": ["cabinet", "neon_block", "neon_block"], "decor": ["neon_tower", "cabinet", "neon_tower"], "music": "gamer_final"},
	"ruins": {"name": "Jungle Ruins", "floor": ["b9b98a", "acac7e"], "edge": "8a8a60", "bg": "3f8f4a", "sky": "bff0c6",
		"pit": "water", "pit_c": "3fbfae", "wall": "8e8e74", "accent": "f4b942", "grass": "3aa04a", "blocks": ["pillar", "rock", "statue"], "decor": ["jungle_tree", "pillar", "statue", "jungle_tree"], "music": "latin_samba"},
	"cove": {"name": "Pirate Cove", "floor": ["e6c387", "dcb878"], "edge": "b98f57", "bg": "1f8fc4", "sky": "a5e5ff",
		"pit": "water", "pit_c": "1fa9d6", "wall": "8a5a34", "accent": "e8483f", "grass": "63b84e", "blocks": ["barrel", "chest", "crate"], "decor": ["ship", "palm", "rock", "barrel"], "music": "rock_sock"},
	"moon": {"name": "Moon Base", "floor": ["b8b4cc", "aca8c2"], "edge": "8c88a6", "bg": "2a2750", "sky": "4a4590",
		"pit": "void", "pit_c": "1a1838", "wall": "6f6ad0", "accent": "6dffb0", "grass": "6dffb0", "blocks": ["pod", "crystal", "neon_block"], "decor": ["dish", "pod", "rock"], "music": "gamer_coins"},
	"spooky": {"name": "Spooky Hollow", "floor": ["6d6490", "625a85"], "edge": "4c4470", "bg": "2c2750", "sky": "6a5aa8",
		"pit": "syrup", "pit_c": "62e0a0", "wall": "4a3f6b", "accent": "ff9d2e", "grass": "4aa58a", "blocks": ["tomb", "pumpkin", "stump"], "decor": ["dead_tree", "tomb", "dead_tree", "pumpkin"], "music": "cartoon_snitch"},
	"schoolyard": {"name": "Schoolyard", "floor": ["d9b98a", "cfae7e"], "edge": "b4935f", "bg": "76c35c", "sky": "bdeaff",
		"pit": "water", "pit_c": "4cc7ee", "wall": "e4574f", "accent": "ffd23f", "grass": "59c04f", "blocks": ["crate", "tire", "hay"], "decor": ["tree", "building", "tree", "bush"], "music": "cartoon_jaunty"},
	# --- Around the world ----------------------------------------------------------------------------------
	"kyoto": {"name": "Kyoto Gardens", "place": "Japan", "region": "asia", "style": "gravel", "floor": ["c9d6a0", "bcca92"], "edge": "8fa070", "bg": "6fa86a", "sky": "ffe3ee",
		"pit": "water", "pit_c": "4fc0d0", "wall": "c9403a", "accent": "ff9fc8", "grass": "4fa858", "blocks": ["stone_lantern", "bamboo", "rock"], "decor": ["torii", "pagoda", "sakura", "sakura", "bamboo"],
		"music": "tropical_tiki", "weather": ["blossom", "rain", "fog"], "layouts": ["zen", "stepping", "lookout", "springs"]},
	"tokyo": {"name": "Tokyo Crossing", "place": "Japan", "region": "asia", "style": "asphalt", "floor": ["5a6078", "525870"], "edge": "3a4058", "bg": "2a2f48", "sky": "ffb3d4",
		"pit": "void", "pit_c": "1a1d30", "wall": "ff5a8a", "accent": "27e9ff", "grass": "3ac0a0", "blocks": ["vending", "neon_block", "cone_stack"], "decor": ["skyscraper", "billboard", "tokyo_tower", "neon_tower", "skyscraper"],
		"music": "gamer_final", "weather": ["rain", "night", "blossom"], "lane": "bullet_train", "layouts": ["rush_hour", "circuit", "crossing", "teleports"]},
	"seoul": {"name": "Seoul Hanok Lanes", "place": "South Korea", "region": "asia", "style": "gravel", "floor": ["d9cfae", "cec39f"], "edge": "a89a78", "bg": "7a9a70", "sky": "c9ecff",
		"pit": "water", "pit_c": "4cbad8", "wall": "4a5a7a", "accent": "ff6fb5", "grass": "4fa858", "blocks": ["stone_lantern", "lantern_post", "crate"], "decor": ["pagoda", "skyscraper", "sakura", "wall_tower"],
		"music": "funk", "weather": ["snow", "rain", "blossom", "night"], "layouts": ["maze", "bazaar", "lookout", "spike_alley"]},
	"greatwall": {"name": "The Great Wall", "place": "China", "region": "asia", "style": "cobble", "floor": ["c4baa0", "b8ae94"], "edge": "8f8670", "bg": "6a9a6a", "sky": "d9eef5",
		"pit": "water", "pit_c": "4fb0c0", "wall": "b8ae96", "accent": "e8483f", "grass": "4a9a52", "blocks": ["wall_block", "lantern_post", "bamboo"], "decor": ["wall_tower", "mountain", "pagoda", "bamboo"],
		"music": "cartoon_snitch", "weather": ["fog", "snow", "wind"], "lane": "cart", "layouts": ["castle", "maze", "fortress", "lookout"]},
	"agra": {"name": "Agra Gardens", "place": "India", "region": "asia", "style": "marble", "floor": ["f4eee0", "ece4d2"], "edge": "cfc6b0", "bg": "7cc46a", "sky": "ffd9b8",
		"pit": "water", "pit_c": "5ec8e0", "wall": "e8c98a", "accent": "ff9933", "grass": "43a553", "blocks": ["planter", "marble", "pottery"], "decor": ["taj", "cypress", "elephant", "tuk_tuk", "cypress"],
		"music": "tropical_tiki", "weather": ["rain", "storm", "heat"], "lane": "tuk_tuk", "layouts": ["canals", "oasis", "zen", "crossing"]},
	"bangkok": {"name": "Bangkok Floating Market", "place": "Thailand", "region": "asia", "style": "planks", "floor": ["d9a868", "cf9c5c"], "edge": "a8743c", "bg": "2ea8c8", "sky": "ffe9b8",
		"pit": "water", "pit_c": "38b8c0", "wall": "e8483f", "accent": "ffc21f", "grass": "3f9f55", "blocks": ["lantern_post", "crate", "rugs"], "decor": ["stupa", "long_boat", "palm", "tuk_tuk"],
		"music": "latin_samba", "weather": ["rain", "storm", "heat"], "lane": "tuk_tuk", "layouts": ["canals", "circuit", "bazaar", "stepping"]},
	"cappadocia": {"name": "Cappadocia Balloons", "place": "Turkiye", "region": "asia", "style": "sand", "floor": ["ecd2a8", "e2c69a"], "edge": "c0a078", "bg": "c49a70", "sky": "ffe0c9",
		"pit": "void", "pit_c": "6a4a3a", "wall": "c0986a", "accent": "e8483f", "grass": "8aa84f", "blocks": ["chimney_small", "rock", "pottery"], "decor": ["chimney", "hot_balloon", "chimney", "hot_balloon"],
		"music": "cartoon_jaunty", "weather": ["wind", "snow", "heat"], "layouts": ["crater", "lookout", "pillars", "webs"]},
	"paris": {"name": "Paris Boulevard", "place": "France", "region": "europe", "style": "cobble", "floor": ["c9c4bc", "bdb8b0"], "edge": "98938c", "bg": "86ad72", "sky": "d6e8f5",
		"pit": "water", "pit_c": "5fb0c8", "wall": "5a6a8a", "accent": "e8483f", "grass": "4fa858", "blocks": ["cafe", "flower_box", "kiosk"], "decor": ["eiffel", "townhouse", "paris_lamp", "tree", "townhouse"],
		"music": "cartoon_jaunty", "weather": ["rain", "fog", "wind"], "lane": "taxi", "layouts": ["bazaar", "rush_hour", "crossroads", "pillars"]},
	"london": {"name": "Foggy London", "place": "United Kingdom", "region": "europe", "style": "brick", "floor": ["bfa89a", "b39c8e"], "edge": "8a7468", "bg": "7c9a70", "sky": "c4d0d8",
		"pit": "water", "pit_c": "5a98b0", "wall": "c9403a", "accent": "1f3f8a", "grass": "4a9a52", "blocks": ["phone_box", "mailbox", "crate"], "decor": ["big_clock", "townhouse", "red_bus", "paris_lamp"],
		"music": "rock_sock", "weather": ["fog", "rain", "storm"], "lane": "red_bus", "layouts": ["rush_hour", "maze", "lookout", "bridges"]},
	"venice": {"name": "Venice Canals", "place": "Italy", "region": "europe", "style": "marble", "floor": ["ecdcc4", "e2d0b6"], "edge": "c0ac90", "bg": "3fa8b8", "sky": "ffe6cf",
		"pit": "water", "pit_c": "3fb8b0", "wall": "c9604a", "accent": "2f4fd0", "grass": "4fa858", "blocks": ["mooring", "flower_box", "crate"], "decor": ["gondola", "palazzo", "bell_tower", "gondola"],
		"music": "latin_samba", "weather": ["fog", "rain"], "layouts": ["canals", "stepping", "bridges", "tides"]},
	"rome": {"name": "Roman Forum", "place": "Italy", "region": "europe", "style": "marble", "floor": ["e6dabc", "dccfae"], "edge": "b8aa88", "bg": "8fb06a", "sky": "c9ecff",
		"pit": "void", "pit_c": "5a4a38", "wall": "e6d6b0", "accent": "c9302a", "grass": "5f9f55", "blocks": ["column", "statue", "amphora"], "decor": ["colosseum", "column", "cypress", "statue"],
		"music": "rock_sock", "weather": ["heat", "storm"], "layouts": ["gladiator", "temple", "pillars", "crumble"]},
	"santorini": {"name": "Santorini Cliffs", "place": "Greece", "region": "europe", "style": "marble", "floor": ["fbf8ef", "f2eee2"], "edge": "d4d0c4", "bg": "1f8fd0", "sky": "bfe9ff",
		"pit": "water", "pit_c": "1f9fe0", "wall": "2a7fd0", "accent": "2a7fd0", "grass": "6fae5a", "blocks": ["white_house", "column", "amphora"], "decor": ["blue_dome", "white_house", "greek_mill", "cypress"],
		"music": "tropical_beach", "weather": ["wind", "heat"], "layouts": ["crumble", "stepping", "tides", "pillars"]},
	"holland": {"name": "Tulip Fields", "place": "Netherlands", "region": "europe", "style": "tulips", "floor": ["a8d86a", "9ccc5e"], "edge": "78a848", "bg": "5ca8d8", "sky": "cfeaff",
		"pit": "water", "pit_c": "4cb0e0", "wall": "c9604a", "accent": "ff4f6a", "grass": "3f9f55", "blocks": ["tulip_pot", "hay", "clog_pair"], "decor": ["windmill", "canal_house", "tulip_row", "windmill", "tulip_row"],
		"music": "kids_polka", "weather": ["wind", "rain", "fog"], "layouts": ["windmills", "canals", "twin_ponds", "zen"]},
	"highlands": {"name": "Scottish Highlands", "place": "Scotland", "region": "europe", "style": "grass", "floor": ["a8b870", "9cac64"], "edge": "788a50", "bg": "7a6a9a", "sky": "c4d4e0",
		"pit": "water", "pit_c": "4a88a8", "wall": "9a9a8a", "accent": "b768ff", "grass": "7a6ab0", "blocks": ["stone_wall", "rock", "hay"], "decor": ["castle", "sheep", "pine", "rock", "sheep"],
		"music": "rock_sock", "weather": ["rain", "fog", "wind", "storm"], "lane": "sheep", "layouts": ["castle", "crossing", "lookout", "mudflats"]},
	"nordic": {"name": "Northern Lights", "place": "Norway", "region": "europe", "style": "snow", "floor": ["e8f4fc", "dcebf6"], "edge": "b8d4e8", "bg": "2a4a7a", "sky": "1f3a6a", "aurora": true,
		"pit": "water", "pit_c": "3a88c0", "wall": "6a4a3a", "accent": "6dffb0", "grass": "2f8a7a", "blocks": ["ice_block", "log_stack", "rock"], "decor": ["viking_ship", "pine_snow", "stave_hut", "igloo", "pine_snow"],
		"music": "kids_polka", "weather": ["night", "snow", "hail"], "layouts": ["rink", "skatepark", "crumble", "stepping"]},
	"newyork": {"name": "New York Blocks", "place": "United States", "region": "americas", "style": "asphalt", "floor": ["7a8094", "70768a"], "edge": "565c70", "bg": "4a5068", "sky": "bcd8f0",
		"pit": "void", "pit_c": "2a2d40", "wall": "c9604a", "accent": "ffc21f", "grass": "4fa858", "blocks": ["hydrant", "crate", "cone_stack"], "decor": ["skyscraper", "liberty", "skyscraper", "water_tower"],
		"music": "funk", "weather": ["snow", "rain", "night", "storm"], "lane": "taxi", "layouts": ["rush_hour", "crossing", "powder", "gauntlet"]},
	"rockies": {"name": "Canadian Rockies", "place": "Canada", "region": "americas", "style": "snow", "floor": ["eef6fb", "e2edf5"], "edge": "c0d4e4", "bg": "5a8ab0", "sky": "bfe2ff",
		"pit": "water", "pit_c": "4ab0d8", "wall": "a8743c", "accent": "e8282f", "grass": "3f8f65", "blocks": ["log_stack", "rock", "ice_block"], "decor": ["mountain", "pine_snow", "moose", "log_cabin", "pine_snow"],
		"music": "kids_polka", "weather": ["snow", "hail", "fog"], "lane": "moose", "layouts": ["rink", "lookout", "crossing", "powder"]},
	"yucatan": {"name": "Yucatan Temples", "place": "Mexico", "region": "americas", "style": "stone", "floor": ["c4c494", "b8b888"], "edge": "909068", "bg": "3f8f4a", "sky": "c9f0d0",
		"pit": "water", "pit_c": "3fbfae", "wall": "9a9a78", "accent": "ff5a4e", "grass": "2f9a4e", "blocks": ["carved", "pillar", "cactus"], "decor": ["step_pyramid", "jungle_tree", "cactus", "banderitas", "step_pyramid"],
		"music": "latin_samba", "weather": ["heat", "rain", "storm"], "layouts": ["temple", "webs", "hideout", "crumble"]},
	"rio": {"name": "Rio Carnival", "place": "Brazil", "region": "americas", "style": "waves", "floor": ["f4e6c0", "ead8ac"], "edge": "c8b488", "bg": "2ec4e8", "sky": "9ff0ff",
		"pit": "water", "pit_c": "2ad3e6", "wall": "35d07f", "accent": "ffd23f", "grass": "2fae4e", "blocks": ["drums", "crate", "barrel"], "decor": ["sugarloaf", "palm", "float", "toucan_tree", "banderitas"],
		"music": "latin_samba", "weather": ["rain", "heat", "storm"], "lane": "float", "layouts": ["pinball", "tides", "bazaar", "skatepark"]},
	"andes": {"name": "Andes Terraces", "place": "Peru", "region": "americas", "style": "stone", "floor": ["b8c88a", "accc7e"], "edge": "88a060", "bg": "6a8ab0", "sky": "cfe6f5",
		"pit": "void", "pit_c": "4a5a6a", "wall": "9a9a8a", "accent": "e8483f", "grass": "4f9f55", "blocks": ["stone_wall", "rock", "hay"], "decor": ["mountain", "llama", "terrace", "pine", "llama"],
		"music": "tropical_tiki", "weather": ["fog", "wind", "hail"], "lane": "llama", "layouts": ["crumble", "windmills", "lookout", "stepping"]},
	"cairo": {"name": "Giza Sands", "place": "Egypt", "region": "africa", "style": "sand", "floor": ["f0d8a0", "e6cc92"], "edge": "c4a870", "bg": "e0b878", "sky": "ffe8bf",
		"pit": "water", "pit_c": "3fc0c0", "wall": "c9a060", "accent": "2f5fd0", "grass": "6a9f4a", "blocks": ["sandstone", "pottery", "obelisk"], "decor": ["pyramid", "sphinx", "palm", "camel", "pyramid"],
		"music": "cartoon_snitch", "weather": ["sand", "heat"], "lane": "camel", "layouts": ["sinking", "oasis", "temple", "gladiator"]},
	"marrakesh": {"name": "Marrakesh Bazaar", "place": "Morocco", "region": "africa", "style": "zellige", "floor": ["e8a878", "de9c6c"], "edge": "b87850", "bg": "c9784a", "sky": "ffd9a8",
		"pit": "water", "pit_c": "38b0b8", "wall": "c9604a", "accent": "1f8a9a", "grass": "5f9f55", "blocks": ["rugs", "pottery", "spices"], "decor": ["riad", "tent", "palm", "lantern_post", "riad"],
		"music": "cartoon_snitch", "weather": ["sand", "heat"], "lane": "camel", "layouts": ["bazaar", "sinking", "powder", "maze"]},
	"savanna": {"name": "Serengeti Savanna", "place": "Tanzania", "region": "africa", "style": "dry", "floor": ["e0c878", "d6bc6c"], "edge": "b09a50", "bg": "c4a850", "sky": "ffdca0",
		"pit": "water", "pit_c": "4ab8c8", "wall": "b5763c", "accent": "e8483f", "grass": "a8a840", "blocks": ["termite", "rock", "hay"], "decor": ["acacia", "giraffe", "elephant", "acacia", "rock"],
		"music": "tropical_island", "weather": ["heat", "storm", "sand"], "lane": "elephant", "layouts": ["crossing", "sinking", "lookout", "hideout"]},
	"outback": {"name": "Aussie Outback", "place": "Australia", "region": "oceania", "style": "dry", "floor": ["e09a68", "d6905c"], "edge": "b06e40", "bg": "c46a3a", "sky": "ffcfa0",
		"pit": "void", "pit_c": "7a3a20", "wall": "c9502f", "accent": "ffc21f", "grass": "8aa040", "blocks": ["red_rock", "termite", "road_sign"], "decor": ["red_mesa", "gum_tree", "kangaroo", "wind_pump", "gum_tree"],
		"music": "rock_sock", "weather": ["heat", "sand", "wind", "storm"], "lane": "jeep", "layouts": ["sinking", "powder", "crossing", "gauntlet"]},
	"hawaii": {"name": "Hawaiian Waves", "place": "Hawaii", "region": "oceania", "style": "sand", "floor": ["f8e4b0", "eed8a0"], "edge": "d4bc80", "bg": "1fb8d8", "sky": "aef2ff",
		"pit": "water", "pit_c": "1fc4e0", "wall": "a06a3a", "accent": "ff5a7a", "grass": "2fae4e", "blocks": ["surf_rack", "rock", "tiki"], "decor": ["palm", "volcano_far", "tiki", "umbrella", "palm"],
		"music": "tropical_beach", "weather": ["wind", "rain", "ash"], "layouts": ["crater", "tides", "springs", "pinball"]},
}

const THEME_ORDER := ["barrio", "beach", "schoolyard", "terraces", "terminal", "mangrove", "halo", "glacier", "ruins", "cove", "volcano", "spooky", "arcade", "moon",
	"kyoto", "tokyo", "seoul", "greatwall", "agra", "bangkok", "cappadocia", "paris", "london", "venice", "rome", "santorini", "holland", "highlands", "nordic",
	"newyork", "rockies", "yucatan", "rio", "andes", "cairo", "marrakesh", "savanna", "outback", "hawaii"]
## The first themes: places in the Philippines, and places that aren't anywhere.
const OLD_THEME_INFO := {
	"barrio": {"place": "Philippines", "region": "asia", "weather": ["rain", "heat", "storm"]},
	"beach": {"place": "Philippines", "region": "asia", "weather": ["wind", "heat", "storm"]},
	"terraces": {"place": "Philippines", "region": "asia", "weather": ["fog", "rain"]},
	"terminal": {"place": "Philippines", "region": "asia", "weather": ["rain", "heat", "night"], "lane": "jeep"},
	"mangrove": {"place": "Philippines", "region": "asia", "weather": ["rain", "fog"]},
	"halo": {"place": "Dessert Dreamland", "region": "fantasy", "weather": ["blossom", "hail"]},
	"schoolyard": {"place": "Your Own Backyard", "region": "fantasy", "weather": ["rain", "wind"]},
	"glacier": {"place": "The Far North", "region": "fantasy", "weather": ["snow", "hail", "wind"]},
	"ruins": {"place": "Lost Jungle", "region": "fantasy", "weather": ["fog", "rain", "storm"]},
	"cove": {"place": "Pirate Seas", "region": "fantasy", "weather": ["storm", "wind", "fog"]},
	"volcano": {"place": "Fire Island", "region": "fantasy", "weather": ["ash", "heat"]},
	"spooky": {"place": "Somewhere Spooky", "region": "fantasy", "weather": ["night", "fog", "storm"]},
	"arcade": {"place": "Inside the Machine", "region": "fantasy", "weather": ["night"]},
	"moon": {"place": "The Moon", "region": "fantasy", "weather": ["meteors"]},
}
const REGIONS := [
	{"id": "asia", "name": "Asia"}, {"id": "europe", "name": "Europe"}, {"id": "americas", "name": "Americas"},
	{"id": "africa", "name": "Africa"}, {"id": "oceania", "name": "Oceania"}, {"id": "fantasy", "name": "Fantasy"},
]
## The ground behind each base, added to the far edge of every layout, with a clear row above and below the field:
## room to come round the back of a base, and hedges, cover and crystals to bring you there.
const YARDS := [
	[".....", ".ggg.", ".ggg.", ".....", ".....", ".....", "..#..", "..#..", ".*...", "..#..", "..#..", ".....", ".....", ".....", ".ggg.", ".ggg.", "....."],
	[".....", "..#..", "..#..", ".....", ".....", ".gg..", ".gg..", ".gg..", ".gg..", ".gg..", ".gg..", ".gg..", ".....", ".....", "..#..", "..#..", "....."],
	[".....", ".....", ".#.#.", ".....", ".....", ".#.#.", ".....", ".....", ".....", ".....", ".....", ".#.#.", ".....", ".....", ".#.#.", ".....", "....."],
	[".....", ".~~..", ".~~..", ".....", ".....", "..gg.", "..gg.", ".....", ".....", ".....", "..gg.", "..gg.", ".....", ".....", ".~~..", ".~~..", "....."],
]
const LAYOUT_ORDER := ["plaza", "crossroads", "twin_ponds", "zigzag", "fortress", "conveyors", "bouncy", "teleports", "rink", "mudflats", "hideout", "pillars", "bridges", "ringroad", "pinwheel", "gauntlet",
	"crumble", "rush_hour", "spike_alley", "windmills", "springs", "sinking", "lookout", "powder", "stepping", "webs", "tides", "temple", "bazaar", "circuit", "crater", "maze", "islands", "castle", "canals", "skatepark", "zen", "oasis", "pinball", "crossing", "gladiator"]
## What the first themes step through, so their maps stay the same. The world themes choose their own (`layouts`).
const FIRST_LAYOUTS := 16
const MAPS_PER_THEME := 4

static var _maps: Array[Dictionary] = []
static var _by_id := {}


## Every map: {id, name, theme, layout}. Themes step through the layouts so every layout appears in
## several looks.
static func all() -> Array[Dictionary]:
	if _maps.is_empty():
		var n := 0
		for theme: String in THEME_ORDER:
			var own: Array = THEMES[theme].get("layouts", [])
			for i in MAPS_PER_THEME:
				var layout: String
				if own.is_empty():
					layout = LAYOUT_ORDER[n % FIRST_LAYOUTS]
					n += 1
				else:
					layout = own[i]
				var map := {"id": "%s_%s" % [theme, layout], "theme": theme, "layout": layout,
					"name": "%s: %s" % [THEMES[theme]["name"], LAYOUTS[layout]["name"]]}
				_maps.append(map)
				_by_id[map["id"]] = map
	return _maps


static func by_id(id: String) -> Dictionary:
	all()
	return _by_id.get(id, {})


## Where a theme is, what part of the world that's in, and what the weather can do there.
static func theme_info(theme_id: String) -> Dictionary:
	var theme: Dictionary = THEMES.get(theme_id, {})
	return theme if theme.has("region") else OLD_THEME_INFO.get(theme_id, {})


static func random_id(rng: RandomNumberGenerator = null) -> String:
	var list := all()
	var i := rng.randi_range(0, list.size() - 1) if rng else randi_range(0, list.size() - 1)
	return String(list[i]["id"])


static func thumb_path(id: String) -> String:
	return "res://assets/maps/%s.webp" % id


## Expands a map's layout to the whole field:
## {w, h, tiles: PackedByteArray, base: [Vector2, Vector2], jail: [Vector2, Vector2], tele: {tile: tile}}.
## Team 0 starts on the left, team 1 on the right; base and jail positions are in metres.
static func build_grid(map_id: String) -> Dictionary:
	var map := by_id(map_id)
	if map.is_empty():
		map = all()[0]
	var layout: Dictionary = LAYOUTS[map["layout"]]
	var rows := _with_yard(layout["rows"], YARDS[LAYOUT_ORDER.find(map["layout"]) % YARDS.size()])
	var half_w: int = String(rows[0]).length()
	var h: int = rows.size()
	var w := half_w * 2
	var tiles := PackedByteArray()
	tiles.resize(w * h)
	var rot: bool = layout["mirror"] == "rot"
	var base := [Vector2.ZERO, Vector2.ZERO]
	var jail := [Vector2.ZERO, Vector2.ZERO]
	var tele_half: Array[Vector2i] = []
	var pads := {}
	var landings := {}
	for y in h:
		var row: String = rows[y]
		for x in half_w:
			var c := row[x]
			var mx := w - 1 - x
			var my := h - 1 - y if rot else y
			if c == "A":
				base[0] = _center(x, y)
				base[1] = _center(mx, my)
				c = "."
			elif c == "J":
				jail[0] = _center(x, y)
				jail[1] = _center(mx, my)
				c = "."
			elif c == "t":
				tele_half.append(Vector2i(x, y))
			elif JUMP_PADS.has(c):
				pads[c] = Vector2i(x, y)
			elif JUMP_PADS.values().has(c):
				landings[c] = Vector2i(x, y)
			tiles[y * w + x] = _code(c)
			tiles[my * w + mx] = _mirror_code(_code(c), rot)
	# Bases and jails always stand on clear ground.
	for team in 2:
		_clear(tiles, w, h, base[team], CLEAR_BASE)
		_clear(tiles, w, h, jail[team], CLEAR_JAIL)
	var tele := {}
	for t: Vector2i in tele_half:
		var a := t.y * w + t.x
		var b := (h - 1 - t.y if rot else t.y) * w + (w - 1 - t.x)
		tele[a] = b
		tele[b] = a
	# A jump pad and its landing box, on each half of the field.
	var jumps := {}
	for c: String in pads:
		var from: Vector2i = pads[c]
		var to: Vector2i = landings[JUMP_PADS[c]]
		jumps[from.y * w + from.x] = to.y * w + to.x
		jumps[(h - 1 - from.y if rot else from.y) * w + (w - 1 - from.x)] = (h - 1 - to.y if rot else to.y) * w + (w - 1 - to.x)
	return {"w": w, "h": h, "tiles": tiles, "base": base, "jail": jail, "tele": tele, "jumps": jumps, "lanes": _find_lanes(tiles, w, h)}


static func _with_yard(rows: Array, yard: Array) -> Array:
	var out: Array = []
	var width := String(rows[0]).length()
	out.append(String(yard[0]) + _edge_row(rows[0], width))
	for i in rows.size():
		out.append(String(yard[i + 1]) + String(rows[i]))
	out.append(String(yard[rows.size() + 1]) + _edge_row(rows[rows.size() - 1], width))
	return out


## The clear row above and below the field, with any road carrying on through it.
static func _edge_row(next_to: String, width: int) -> String:
	var row := ""
	for i in width:
		row += "|" if next_to[i] == "|" else "."
	return row


## Each straight run of road down the field is one lane: {x, y0, y1} in metres, the middle of the road and its ends.
static func _find_lanes(tiles: PackedByteArray, w: int, h: int) -> Array:
	var lanes: Array = []
	for x in w:
		var y := 0
		while y < h:
			if tiles[y * w + x] != ROAD:
				y += 1
				continue
			var from := y
			while y < h and tiles[y * w + x] == ROAD:
				y += 1
			if y - from >= 4:
				lanes.append({"x": (x + 0.5) * TILE, "y0": from * TILE, "y1": y * TILE, "down": x < w / 2})
	return lanes


static func _center(x: int, y: int) -> Vector2:
	return Vector2((x + 0.5) * TILE, (y + 0.5) * TILE)


static func _clear(tiles: PackedByteArray, w: int, h: int, at: Vector2, radius: float) -> void:
	for y in h:
		for x in w:
			if _center(x, y).distance_to(at) <= radius:
				tiles[y * w + x] = FLOOR


static func _code(c: String) -> int:
	match c:
		"#": return SOLID
		"~": return PIT
		"g": return GRASS
		"i": return ICE
		"m": return MUD
		"b": return BOUNCE
		"t": return TELE
		">": return CON_R
		"<": return CON_L
		"^": return CON_U
		"v": return CON_D
		"R": return DASH_R
		"L": return DASH_L
		"U": return DASH_U
		"D": return DASH_D
		"1", "2": return JUMP
		"!", "@": return LAND
		"=": return GATE
		"f": return FOUNTAIN
		"*": return ALTAR
		"%": return FENCE
		"o": return BUMPER
		"s": return SPIKES
		"c": return CRUMBLE
		"a": return ARM
		"|": return ROAD
		"z": return GEYSER
		"q": return QUICKSAND
		"w": return TOWER
		"x": return TNT
		"n": return STONE
		"y": return WEB
		"T": return TIDE
	return FLOOR


static func _mirror_code(code: int, rot: bool) -> int:
	match code:
		CON_R: return CON_L
		CON_L: return CON_R
		CON_U: return CON_D if rot else CON_U
		CON_D: return CON_U if rot else CON_D
		DASH_R: return DASH_L
		DASH_L: return DASH_R
		DASH_U: return DASH_D if rot else DASH_U
		DASH_D: return DASH_U if rot else DASH_D
	return code
