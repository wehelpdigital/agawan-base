extends Control
## The rules, on a few cards. Shown once before the first match; always under Rules.

const CARDS: Array[Dictionary] = [
	{"icon": "swords", "color": Color("ffb21f"), "title": "5 vs 5", "text": "Two teams, two bases. Touch an enemy and one of you goes to jail. The question is which one."},
	{"icon": "flag", "color": Color("35d07f"), "title": "Your Side, Your Tag", "text": "A big line splits the field. On your side, you can tag any enemy. Over the line, on their side, they can tag you, so run back! A green arrow over an enemy means you can tag them, a red sign means they can tag you, and your own ring goes green or red to match."},
	{"icon": "cage", "color": Color("ff4f6b"), "title": "Jail & Rescue", "text": "Tagged players go to the jail beside the enemy base. Tap to break out, or wait for a teammate: one touch of the jail frees everyone, and rescuers get a free walk home."},
	{"icon": "crown", "color": Color("23a7ff"), "title": "Capture the Base", "text": "Stand on the enemy base to capture it. That's a point. First team to 3 wins. Jail the whole enemy team at once for a point too. Most points when time runs out wins."},
	{"icon": "power", "color": Color("b768ff"), "title": "Grab Crystals", "text": "Rainbow crystals drop all over the map. Nobody knows what's inside: grab one, and a slot machine spins up a power card. Hold two at a time. Tap a card to use it, or drag it to aim. The last minute is a Power Rush: they rain down."},
	{"icon": "mode_defend", "color": Color("3aa6ff"), "title": "Attack or Defend", "text": "On your side of the line you're defending, and crystals give you shield cards: traps, walls, nets. Over the line you're attacking, and they give you target cards: shots, speed, tricks. Cross the line and whatever you're holding spins into a card from the other deck, so use it before you go!"},
	{"icon": "skills", "color": Color("35d07f"), "title": "Skills", "text": "Every hero has a skill of their own, and a tree of others that open up as they level. You can take two into a match. Each level gives you a point to learn one or rank it up. Skills come back by themselves, so use them! Keys: Q and R."},
	{"icon": "map", "color": Color("35d07f"), "title": "Use the Field", "text": "Bushes hide you unless an enemy is close, but running shakes the leaves. Arrow floors shoot you along. Jump pads throw you to their marked box. Gates rise and fall on a beat. Fountains let you tag anyone for 6 seconds, even over the line, then refill. Altars keep growing crystals. Dash to clear low fences. Bumpers knock you flying."},
	{"icon": "w_heat", "color": Color("ff5a4e"), "title": "Mind the Traps", "text": "Spikes pop up on a beat. Crumbling floors fall away behind you. Big arms sweep the field. Traffic does not stop for tag. Quicksand drags you in, and only a dash gets you out. Geysers throw you wherever they like. Webs stick. Tides come in. Dash into a powder crate and everyone nearby goes flying. Climb a lookout tower and your team sees every enemy."},
	{"icon": "w_storm", "color": Color("3a6ad0"), "title": "Check the Sky", "text": "Every match has its own weather, and it changes how you play. Fog and night hide anyone far from your team. Rain makes you slide. Wind pushes you and your shots: watch the arrow. Lightning, hail and lava hit the marked spots, on either team. Sand, snow and heat all have their own tricks."},
	{"icon": "paw", "color": Color("ff9d2e"), "title": "Make It Yours", "text": "Every country's flag is free in the Shop's World tab. Pets follow you everywhere. There are masks, hats, dances and hellos from all over the planet, all earned just by playing."},
	{"icon": "dash", "color": Color("19d3e6"), "title": "Controls", "text": "Touch: left thumb runs, right thumb uses buttons.\nKeyboard: WASD or arrows, Space to dash, E to use a card, 1-4 for emotes.\nController: left stick, A to dash, X to use."},
]

var root: UiRoot
var args: Dictionary
var screen_name: String


func _ready() -> void:
	var first: bool = args.get("first", false)
	var outer := UiKit.vbox(8)
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 10
	outer.offset_right = -10
	outer.offset_top = 4
	outer.offset_bottom = -8
	add_child(outer)
	var head := UiKit.hbox(8)
	if not first:
		var back := UiKit.button("", "ink", 18, "arrow_left")
		back.custom_minimum_size = Vector2(56, 48)
		back.pressed.connect(func() -> void: root.go_back())
		head.add_child(back)
	var heading := UiKit.title("HOW TO PLAY", 28 if not root.compact else 22)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(heading)
	outer.add_child(head)
	var scroll := UiKit.scroller()
	outer.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 1 if root.phone_narrow or size.x < 760.0 else 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	for def: Dictionary in CARDS:
		grid.add_child(_card(def))
	var go := UiKit.button("LET'S PLAY!" if first else "GOT IT", "yellow", 24)
	go.custom_minimum_size.y = 60
	go.pressed.connect(func() -> void:
		Profile.tutorial_done = true
		Profile.save()
		if first:
			root.show_screen("home")
		else:
			root.go_back())
	outer.add_child(go)


func _card(def: Dictionary) -> Control:
	var card := UiKit.panel(UiKit.CARD, 18, 4)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := UiKit.hbox(12)
	card.add_child(row)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", UiKit.style(def["color"], 18, 3))
	plate.custom_minimum_size = Vector2(64, 64)
	plate.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	plate.add_child(UiKit.icon(def["icon"], 44))
	row.add_child(plate)
	var text := UiKit.vbox(2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(UiKit.title(def["title"], 21, UiKit.YELLOW))
	text.add_child(UiKit.body(def["text"], 16))
	row.add_child(text)
	return card
