extends Control
## The Shop and Locker tabs: everything you can wear and do, sorted by kind of accessory, with a live 3D
## preview that zooms to whatever you're looking at. The Shop lists all of it, with today's deals first;
## the Locker shows only what you own. Avatars are one category among the others.

const DEALS_COUNT := 6

var root: UiRoot
var args: Dictionary
var screen_name: String
var _group := "wear"
var _slot := "mask"
var _selected := ""
var _avatar: AvatarView
var _grid: GridContainer
var _name_label: Label
var _info_label: Label
var _action: GameButton
var _preview: Dictionary = {}
var _groups_row: HBoxContainer
var _chips: HBoxContainer
var _chips_scroll: ScrollContainer
var _owned_only := false
var _grid_width := 0.0


func _ready() -> void:
	_owned_only = screen_name == "locker"
	Audio.music("menu" if _owned_only else "shop")
	_preview = Profile.look.duplicate()
	if not _owned_only:
		_group = "deals"
		_slot = "deals"
	if root.portrait:
		_build_portrait()
	else:
		_build_landscape()
	_build_tabs()
	_refill.call_deferred()
	_avatar.set_look(_preview)
	_show_item("", "")


func _build_landscape() -> void:
	var row := UiKit.hbox(10)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 10
	row.offset_right = -10
	row.offset_top = 4
	row.offset_bottom = -6
	add_child(row)
	var left := UiKit.vbox(6)
	left.custom_minimum_size.x = minf(size.x * 0.32, 360.0)
	row.add_child(left)
	_avatar = AvatarView.new()
	_avatar.zoomable = true
	left.add_child(_avatar)
	left.add_child(_info_panel())
	var right := UiKit.vbox(6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	_add_list(right)
	_grid_width = size.x - left.custom_minimum_size.x - 40.0


func _build_portrait() -> void:
	var col := UiKit.vbox(6)
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 8
	col.offset_right = -8
	col.offset_top = 4
	col.offset_bottom = -6
	add_child(col)
	var top := UiKit.hbox(6)
	top.custom_minimum_size.y = minf(size.y * 0.3, 280.0)
	col.add_child(top)
	_avatar = AvatarView.new()
	_avatar.zoomable = true
	top.add_child(_avatar)
	var info := _info_panel()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	_add_list(col)
	_grid_width = size.x - 24.0


func _add_list(parent: Control) -> void:
	var groups_scroll := UiKit.scroller(true)
	groups_scroll.custom_minimum_size.y = 56
	groups_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	groups_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_groups_row = UiKit.hbox(6)
	groups_scroll.add_child(_groups_row)
	parent.add_child(groups_scroll)
	_chips_scroll = UiKit.scroller(true)
	_chips_scroll.custom_minimum_size.y = 50
	_chips_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_chips_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_chips = UiKit.hbox(5)
	_chips_scroll.add_child(_chips)
	parent.add_child(_chips_scroll)
	var scroll := UiKit.scroller()
	parent.add_child(scroll)
	_grid = GridContainer.new()
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_grid)


func _info_panel() -> Control:
	var card := UiKit.panel(UiKit.CARD, 18, 4)
	var col := UiKit.vbox(4)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(col)
	_name_label = UiKit.title("", 20)
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_name_label)
	_info_label = UiKit.body("", 15, UiKit.MUTED)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_info_label)
	_action = UiKit.button("", "green", 15 if root.portrait else 19)
	_action.pressed.connect(_on_action)
	col.add_child(_action)
	return card


## Top row: Deals, Wear, Moves, Effects, Profile, Avatars. Second row: the kinds of item in that group.
func _build_tabs() -> void:
	for child in _groups_row.get_children():
		child.queue_free()
	for child in _chips.get_children():
		child.queue_free()
	if not _owned_only:
		_groups_row.add_child(_group_button("deals", "Deals", "star"))
	for group: Dictionary in Cosmetics.GROUPS:
		_groups_row.add_child(_group_button(group["id"], group["name"], group["icon"]))
	_chips_scroll.visible = _group != "deals"
	for group: Dictionary in Cosmetics.GROUPS:
		if group["id"] != _group:
			continue
		for slot: String in group["slots"]:
			var info: Dictionary = Cosmetics.SLOT_INFO[slot]
			var chip := UiKit.button(info["name"], "blue" if slot == _slot else "ink", 14, info["icon"])
			chip.custom_minimum_size.y = 44
			chip.pressed.connect(func() -> void:
				_slot = slot
				_after_tab())
			_chips.add_child(chip)


func _group_button(id: String, text: String, icon_name: String) -> Control:
	var b := UiKit.button(text, "yellow" if id == _group else "teal", 16, icon_name)
	b.custom_minimum_size.y = 50
	b.pressed.connect(func() -> void:
		_group = id
		if id == "deals":
			_slot = "deals"
		else:
			for group: Dictionary in Cosmetics.GROUPS:
				if group["id"] == id:
					_slot = group["slots"][0]
		_after_tab())
	return b


func _after_tab() -> void:
	_selected = ""
	_build_tabs()
	_refill()
	_show_item("", "")


## Today's deals: a different handful each day, half price, the same for everyone.
func _deals() -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Time.get_date_string_from_system())
	var pool: Array[Dictionary] = []
	for slot: String in Cosmetics.SLOTS:
		for entry: Dictionary in Cosmetics.list(slot):
			if entry["rarity"] != "free" and slot != "char":
				pool.append({"slot": slot, "id": entry["id"]})
	var out: Array[Dictionary] = []
	while out.size() < DEALS_COUNT and not pool.is_empty():
		out.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return out


func _refill() -> void:
	if not is_instance_valid(_grid):
		return
	for child in _grid.get_children():
		child.queue_free()
	var width := _grid_width if _grid_width > 0.0 else size.x
	_grid.columns = clampi(int(width / 128.0), 3, 8)
	var cell := (width - 8.0 * (_grid.columns - 1)) / _grid.columns
	if _slot == "deals":
		for deal in _deals():
			_grid.add_child(_card(deal["slot"], deal["id"], cell, true))
		return
	var shown := 0
	for entry: Dictionary in Cosmetics.list(_slot):
		if _owned_only and not Profile.owns(_slot, entry["id"]):
			continue
		_grid.add_child(_card(_slot, entry["id"], cell, false))
		shown += 1
	if shown == 0:
		var empty := UiKit.open_text("Nothing here yet. Win coins, then visit the Shop!", 18)
		_grid.add_child(empty)


func _card(slot: String, id: String, cell: float, deal: bool) -> Control:
	var entry := Cosmetics.item(slot, id)
	var rarity: Dictionary = Cosmetics.RARITY[entry["rarity"]]
	var owned := Profile.owns(slot, id)
	var equipped := _is_equipped(slot, id)
	var card := Button.new()
	card.flat = true
	card.focus_mode = Control.FOCUS_ALL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.custom_minimum_size = Vector2(0, cell + 34.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.pressed.connect(func() -> void: _on_card(slot, id))
	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := UiKit.card_style(UiKit.CARD if not equipped else Color("1f9c5c"), 14, 3)
	style.border_color = rarity["color"]
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 6
	box.add_theme_stylebox_override("panel", style)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	var col := UiKit.vbox(0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(col)
	var pic := ItemIcon.new()
	pic.setup(slot, id)
	pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(pic)
	var name_label := UiKit.label(String(entry["name"]), 13, UiKit.WHITE, 3, true)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(name_label)
	var foot := UiKit.hbox(3)
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if equipped:
		foot.add_child(UiKit.label("WORN" if slot != "emote" else "IN WHEEL", 13, UiKit.MINT, 3, true))
	elif owned:
		foot.add_child(UiKit.label("OWNED", 13, UiKit.MUTED, 3, true))
	else:
		var price := Cosmetics.price(slot, id)
		var gems := int(price["gems"])
		var coins := int(price["coins"])
		if deal:
			coins /= 2
			gems /= 2
		foot.add_child(UiKit.icon("gem" if gems > 0 else "coin", 16))
		foot.add_child(UiKit.label(UiKit.format_number(gems if gems > 0 else coins), 14, UiKit.YELLOW if deal else UiKit.WHITE, 3, true))
	col.add_child(foot)
	return card


func _is_equipped(slot: String, id: String) -> bool:
	if slot == "emote":
		return Profile.equipped_emotes().has(id)
	return str(Profile.look.get(slot, "")) == id


func _on_card(slot: String, id: String) -> void:
	Audio.sfx("ui_equip" if Profile.owns(slot, id) else "ui_click")
	_selected = id
	_show_item(slot, id)


## Shows an item on the avatar. An empty slot means nothing's selected.
func _show_item(slot: String, id: String) -> void:
	_selected = id
	_preview = Profile.look.duplicate()
	if slot != "" and slot != "emote":
		_preview[slot] = id
		_drop_clash(_preview, slot)
		if slot == "face":
			_preview["mask"] = ""
	_avatar.set_look(_preview, slot)
	if slot == "emote":
		_avatar.show_emote(String(Cosmetics.item(slot, id).get("text", "")))
	if slot == "":
		_name_label.remove_theme_color_override("font_color")
		_name_label.text = "Today's Deals" if _slot == "deals" else String(Cosmetics.SLOT_INFO.get(_slot, {}).get("name", ""))
		_info_label.text = "Half price, today only." if _slot == "deals" else "Tap anything to try it on."
		_action.visible = false
		return
	var entry := Cosmetics.item(slot, id)
	var rarity: Dictionary = Cosmetics.RARITY[entry["rarity"]]
	_name_label.text = String(entry["name"])
	_name_label.add_theme_color_override("font_color", (rarity["color"] as Color).lightened(0.25))
	_info_label.text = String(entry.get("blurb", "%s %s" % [rarity["name"], String(Cosmetics.SLOT_INFO[slot]["name"]).trim_suffix("s")]))
	_action.visible = true
	if Profile.owns(slot, id):
		if _is_equipped(slot, id):
			_action.set_kind("gray" if slot != "emote" else "ink")
			_action.set_text("WORN" if slot != "emote" else "REMOVE")
			_action.disabled = slot != "emote"
		else:
			_action.set_kind("green")
			_action.set_text("EQUIP" if slot != "emote" else "ADD TO WHEEL")
			_action.disabled = false
	else:
		var price := _price_now(slot, id)
		var gems := int(price["gems"])
		var coins := int(price["coins"])
		_action.set_kind("yellow")
		_action.set_text("BUY: %s %s" % [UiKit.format_number(gems if gems > 0 else coins), "GEMS" if gems > 0 else "COINS"])
		_action.disabled = Profile.coins < coins or Profile.gems < gems
	_action.set_meta("slot", slot)
	_action.set_meta("id", id)


## Some masks and hats can't be worn together. Trying one on takes the other off, in the preview and for real.
func _drop_clash(look: Dictionary, slot: String) -> void:
	if slot in ["mask", "hat"] and Cosmetics.wearing_clash(str(look.get("mask", "")), str(look.get("hat", ""))):
		look["hat" if slot == "mask" else "mask"] = ""


func _price_now(slot: String, id: String) -> Dictionary:
	var price := Cosmetics.price(slot, id)
	for deal in _deals():
		if deal["slot"] == slot and deal["id"] == id:
			return {"coins": int(price["coins"]) / 2, "gems": int(price["gems"]) / 2}
	return price


func _on_action() -> void:
	var slot: String = _action.get_meta("slot", "")
	var id: String = _action.get_meta("id", "")
	if slot == "":
		return
	if Profile.owns(slot, id):
		if slot == "emote":
			Profile.toggle_emote(id)
		else:
			Profile.equip(slot, id)
		Audio.sfx("ui_equip")
	else:
		if not Profile.buy_at(slot, id, _price_now(slot, id)):
			Audio.sfx("ui_error")
			return
		Audio.sfx("ui_purchase")
		root.toast("%s is yours!" % Cosmetics.item(slot, id)["name"], UiKit.YELLOW)
	if slot in ["mask", "hat"] and Cosmetics.wearing_clash(str(Profile.look.get("mask", "")), str(Profile.look.get("hat", ""))):
		Profile.equip("hat" if slot == "mask" else "mask", "")
	if slot == "face" and str(Profile.look.get("mask", "")) != "":
		Profile.equip("mask", "")
		root.toast("Mask off, so your new face shows!", UiKit.YELLOW)
	_refill()
	_show_item(slot, id)
