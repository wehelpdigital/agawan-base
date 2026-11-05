extends Control
## The rules, on a few cards. Shown once before the first match; always under Rules.

const CARDS: Array[Dictionary] = [
	{"icon": "swords", "color": Color("ffb21f"), "title": "5 vs 5", "text": "Two teams, two bases. Touch an enemy and one of you goes to jail. The question is which one."},
	{"icon": "flag", "color": Color("35d07f"), "title": "The Fresher Wins", "text": "Whoever left their base LAST is fresher, and tags the other. A green arrow over an enemy means you can tag them. A red sign means they can tag you. Touch your own base to get fresh again."},
	{"icon": "cage", "color": Color("ff4f6b"), "title": "Jail & Rescue", "text": "Tagged players go to the jail beside the enemy base. Tap to break out, or wait for a teammate: one touch of the jail frees everyone, and rescuers get a free walk home."},
	{"icon": "crown", "color": Color("23a7ff"), "title": "Capture the Base", "text": "Stand on the enemy base to capture it. That's a point. First team to 3 wins. Jail the whole enemy team at once for a point too. Most points when time runs out wins."},
	{"icon": "power", "color": Color("b768ff"), "title": "Grab Powerups", "text": "Powerups drop all over the map. Hold two at a time. Tap the big button to use one, or drag it to aim. Fiesta Time, the last minute, rains them down."},
	{"icon": "dash", "color": Color("19d3e6"), "title": "Controls", "text": "Touch: left thumb runs, right thumb uses buttons.\nKeyboard: WASD or arrows, Space to dash, E to use a powerup, 1-4 for emotes.\nController: left stick, A to dash, X to use."},
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
	plate.add_child(UiKit.icon(def["icon"], 44, UiKit.INK))
	row.add_child(plate)
	var text := UiKit.vbox(2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(UiKit.title(def["title"], 21, UiKit.YELLOW))
	text.add_child(UiKit.body(def["text"], 16))
	row.add_child(text)
	return card
