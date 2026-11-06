extends Control
## Your name, stats and account. An account (username and password) keeps your things across devices.

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
	var heading := UiKit.title("PROFILE", 28)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(heading)
	outer.add_child(head)
	var scroll := UiKit.scroller()
	outer.add_child(scroll)
	var body := UiKit.vbox(10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	body.add_child(_name_card())
	body.add_child(_stats_card())
	body.add_child(_account_card())


func _name_card() -> Control:
	var card := UiKit.panel(UiKit.CARD, 18, 4)
	var col := UiKit.vbox(8)
	card.add_child(col)
	var row := UiKit.hbox(8)
	var field := LineEdit.new()
	field.text = Profile.player_name
	field.max_length = 16
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.custom_minimum_size.y = 50
	row.add_child(field)
	var save := UiKit.button("Save", "green", 18)
	save.custom_minimum_size.y = 50
	save.pressed.connect(func() -> void:
		var clean := Names.clean(field.text)
		if clean.length() < 3:
			root.toast("Names need at least 3 letters.", UiKit.CORAL)
			return
		Profile.rename(clean)
		root.toast("Hello, %s!" % clean, UiKit.MINT))
	row.add_child(save)
	col.add_child(row)
	var league := Ranks.league_for(Profile.trophies)
	var title := Cosmetics.item("title", Profile.look.get("title", ""))
	col.add_child(UiKit.body("%s · %s League · Level %d" % [title.get("name", "New Runner"), league["name"], Profile.level], 16, UiKit.MUTED))
	var xp_bar := ProgressBar.new()
	xp_bar.show_percentage = false
	xp_bar.custom_minimum_size.y = 14
	xp_bar.max_value = Ranks.xp_for_level(Profile.level)
	xp_bar.value = Profile.xp
	xp_bar.add_theme_stylebox_override("background", UiKit.style(UiKit.INK, 7))
	xp_bar.add_theme_stylebox_override("fill", UiKit.style(UiKit.AQUA, 7))
	col.add_child(xp_bar)
	return card


func _stats_card() -> Control:
	var card := UiKit.panel(UiKit.CARD, 18, 4)
	var grid := GridContainer.new()
	grid.columns = 2 if root.phone_narrow else 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	card.add_child(grid)
	var games := int(Profile.stats["games"])
	var win_rate := int(100.0 * float(Profile.stats["wins"]) / games) if games > 0 else 0
	for entry: Array in [["Matches", games], ["Wins", Profile.stats["wins"]], ["Win rate", "%d%%" % win_rate], ["MVP", Profile.stats["mvps"]],
			["Tags", Profile.stats["tags"]], ["Rescues", Profile.stats["rescues"]], ["Captures", Profile.stats["captures"]], ["Best trophies", Profile.best_trophies]]:
		var cell := UiKit.vbox(0)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value := UiKit.title(str(entry[1]), 22, UiKit.YELLOW)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(value)
		var caption := UiKit.label(str(entry[0]), 14, UiKit.MUTED)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(caption)
		grid.add_child(cell)
	return card


func _account_card() -> Control:
	var card := UiKit.panel(UiKit.CARD, 18, 4)
	var col := UiKit.vbox(8)
	card.add_child(col)
	if not Net.online:
		col.add_child(UiKit.body("Accounts need the game server. You're offline, and your progress is saved on this device.", 16, UiKit.MUTED))
		return card
	if Profile.account != "":
		col.add_child(UiKit.body("Signed in as %s. Your things follow you to any device." % Profile.account, 17))
		var out := UiKit.button("Sign Out", "ink", 18)
		out.pressed.connect(func() -> void:
			await Net.logout()
			root.toast("Signed out.")
			root.show_screen("profile"))
		col.add_child(out)
		return card
	col.add_child(UiKit.body("Playing as a guest. Pick a username and password to keep your things on any device.", 16, UiKit.MUTED))
	var user := LineEdit.new()
	user.placeholder_text = "Username"
	user.max_length = 20
	user.custom_minimum_size.y = 50
	col.add_child(user)
	var pass_field := LineEdit.new()
	pass_field.placeholder_text = "Password (8+ characters)"
	pass_field.secret = true
	pass_field.max_length = 64
	pass_field.custom_minimum_size.y = 50
	col.add_child(pass_field)
	var row := UiKit.hbox(8)
	var register := UiKit.button("Create Account", "yellow", 17)
	register.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	register.pressed.connect(func() -> void: _account_action(true, user.text, pass_field.text))
	row.add_child(register)
	var login := UiKit.button("Sign In", "blue", 17)
	login.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	login.pressed.connect(func() -> void: _account_action(false, user.text, pass_field.text))
	row.add_child(login)
	col.add_child(row)
	return card


func _account_action(create: bool, username: String, password: String) -> void:
	var clean := username.strip_edges()
	if clean.length() < 3 or password.length() < 8:
		root.toast("Username needs 3+ letters, password 8+ characters.", UiKit.CORAL)
		return
	var result: Dictionary = {}
	if create:
		result = await Net.register(clean, password)
	else:
		result = await Net.login(clean, password)
	if result["ok"]:
		Audio.sfx("achievement")
		root.toast("Signed in as %s!" % clean, UiKit.MINT)
		root.show_screen("profile")
	else:
		Audio.sfx("ui_error")
		root.toast(str((result["data"] as Dictionary).get("error", "That didn't work.")), UiKit.CORAL)
