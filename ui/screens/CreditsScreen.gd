extends Control
## Who made the sounds, music, icons and fonts. CC BY works require this credit, so keep it in step with
## assets/audio/CREDITS.md.

const LINES := [
	["Music", "Kevin MacLeod (incompetech.com), CC BY 4.0: Island Meet and Greet, Tiki Bar Mixer, Beachfront Celebration, Peppy Pepe, Samba Isobel, Pixel Peeker Polka, Sock Hop, Exhilarate, Sneaky Snitch, Jaunty Gumption.\nHoliznaCC0, CC0: Make Funk, Hard Mode, Final Level, Coins."],
	["Sound effects", "Kenney (kenney.nl), Juhani Junkala (SubspaceAudio) and other Freesound authors, all CC0, plus sounds made for the game. The full list is in assets/audio/CREDITS.md."],
	["Fonts", "Rammetto One by Vernon Adams, Nunito by Vernon Adams, Cyreal and Jacques Le Bailly, both SIL Open Font License. The logo's letters are drawn from Luckiest Guy by Astigmatic, Apache License 2.0."],
	["The game", "Based on an old playground game played all over the world: Prisoner's Base, or Barlay, or Agawan Base. Heroes, pets, maps, logo and art are original to this game. Landmarks are toy models of real places, and flags are for fun: they don't mean anyone's taking sides."],
	["Engine", "Made with Godot Engine (godotengine.org)."],
]

var root: UiRoot
var args: Dictionary
var screen_name: String


func _ready() -> void:
	var outer := UiKit.vbox(8)
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.offset_left = 10
	outer.offset_right = -10
	outer.offset_top = 4
	outer.offset_bottom = -8
	add_child(outer)
	var head := UiKit.hbox(8)
	var back := UiKit.button("", "ink", 18, "arrow_left")
	back.custom_minimum_size = Vector2(56, 48)
	back.pressed.connect(func() -> void: root.go_back())
	head.add_child(back)
	var heading := UiKit.title("CREDITS", 28)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(heading)
	outer.add_child(head)
	var scroll := UiKit.scroller()
	outer.add_child(scroll)
	var body := UiKit.vbox(10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	for entry: Array in LINES:
		var card := UiKit.panel(UiKit.CARD, 16, 3)
		var col := UiKit.vbox(2)
		card.add_child(col)
		col.add_child(UiKit.title(entry[0], 19, UiKit.YELLOW))
		col.add_child(UiKit.body(entry[1], 16))
		body.add_child(card)
