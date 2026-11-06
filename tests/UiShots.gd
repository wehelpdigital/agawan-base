extends Node
## Visits every screen and saves a screenshot, and reports anything spilling off the screen:
##   godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 390x844 res://tests/UiShots.tscn
##       -- --out=<dir> --tag=phone --device=phone_portrait [--server=http://127.0.0.1:8787] [--rich] [--text=large]

const SCREENS := ["title", "howto", "home", "maps", "shop", "locker", "room", "ranks", "guild", "chat", "profile", "settings", "powers", "skills", "credits", "results"]

var _out := "user://shots"
var _tag := "ui"
var _main: Node
var _only := ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=")
	DirAccess.make_dir_recursive_absolute(_out)
	Profile.coins = 5400
	Profile.gems = 260
	Profile.level = 7
	Profile.trophies = 640
	Profile.best_trophies = 640
	Profile.tutorial_done = true
	Profile.daily_day = Time.get_date_string_from_system()
	for arg in OS.get_cmdline_user_args():
		if arg == "--rich":
			Profile.coins = 1250000
			Profile.gems = 12400
			Profile.trophies = 12400
			Profile.best_trophies = 12400
			Profile.level = 99
		elif arg.begins_with("--text="):
			Settings.text_size = arg.trim_prefix("--text=")
	_main = load("res://scenes/Main.gd").new()
	add_child(_main)
	_run.call_deferred()


func _run() -> void:
	await _wait(0.6)
	var ui: UiRoot = _main.ui
	for screen_name: String in SCREENS:
		if _only != "" and screen_name != _only:
			continue
		var screen_args := {}
		if screen_name == "results":
			screen_args = _sample_result()
		ui.show_screen(screen_name, screen_args)
		await _wait(0.9 if screen_name in ["home", "shop", "locker"] else 0.5)
		await _shot(screen_name)
		_audit(ui, screen_name)
	if _only == "":
		await _shop_extras(ui)
		await _skill_extras(ui)
	get_tree().quit()


## The shop's newer shelves, and a button you can't afford.
## A hero some way along, and the moment they go up a level.
func _skill_extras(ui: UiRoot) -> void:
	var hero := "bramble"
	var nodes := Skills.tree(hero)
	Profile.heroes[hero] = {"xp": 120, "level": 7, "chosen": [Skills.own_skill(hero), String(nodes[1]["skill"])], "ranks": {Skills.own_skill(hero): 3, String(nodes[1]["skill"]): 2}}
	ui.show_screen("skills", {"hero": hero})
	await _wait(3.0)
	await _shot("skills_along")
	_audit(ui, "skills_along")
	Profile.heroes["kiko"] = {"xp": 0, "level": 2, "chosen": [Skills.own_skill("kiko")], "ranks": {Skills.own_skill("kiko"): 1}}
	var args := _sample_result()
	args["rewards"] = {"coins": 40, "xp": 90, "hero": "kiko", "hero_leveled": true, "hero_level": 2}
	ui.show_screen("results", args)
	await _wait(0.7)
	await _shot("level_up")
	Profile.heroes.erase("kiko")
	Profile.heroes.erase(hero)


func _shop_extras(ui: UiRoot) -> void:
	ui.show_screen("shop")
	await _wait(0.5)
	var shop: Node = ui._screen
	for shelf: Array in [["pets", "pet", "pets"], ["world", "flag", "flags"], ["world", "region:asia", "asia"], ["wear", "hat", "hats"]]:
		shop.set("_group", shelf[0])
		shop.set("_slot", shelf[1])
		shop.call("_after_tab")
		await _wait(0.5)
		await _shot("shop_" + String(shelf[2]))
		_audit(ui, "shop_" + String(shelf[2]))
	shop.set("_group", "pets")
	shop.set("_slot", "pet")
	shop.call("_after_tab")
	await _wait(0.3)
	shop.call("_show_item", "pet", "dragon")
	await _wait(0.6)
	await _shot("shop_pet_tryon")
	var coins := Profile.coins
	var gems := Profile.gems
	Profile.coins = 0
	Profile.gems = 0
	shop.call("_show_item", "pet", "dragon")
	await _wait(0.3)
	await _shot("shop_cant_afford")
	Profile.coins = coins
	Profile.gems = gems


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	await RenderingServer.frame_post_draw


func _shot(screen_name: String) -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png("%s/%s_%s.png" % [_out, _tag, screen_name])
	if screen_name in ["title", "home"]:
		print("%s: %d triangles, %d draw calls" % [screen_name, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])


## Nothing that matters should stick out of the window, and no button should be too small to tap.
func _audit(ui: UiRoot, screen_name: String) -> void:
	var view := get_viewport().get_visible_rect().size
	var visible_rect := Rect2(Vector2.ZERO, view).grow(1.0)
	for node: Node in ui.find_children("*", "Control", true, false):
		var c := node as Control
		if c is GameButton and c.is_visible_in_tree() and c._row != null:
			var words: Vector2 = c._row.get_combined_minimum_size()
			var off: float = absf(c._row.position.x + c._row.size.x * 0.5 - c.size.x * 0.5)
			if words.x > c.size.x - 2.0 * GameButton.OUTLINE or words.y > c.size.y or off > 1.0:
				print("BUTTON ", screen_name, ": ", c.get_text(), " needs ", words, " and has ", c.size)
		if not c.is_visible_in_tree() or c.get_parent() is ScrollContainer or c.get_parent().name == "Backdrop":
			continue
		var inside_scroll := false
		var parent := c.get_parent()
		while parent:
			if parent is ScrollContainer:
				inside_scroll = true
				break
			parent = parent.get_parent()
		if inside_scroll:
			continue
		var rect := c.get_global_rect()
		if rect.size.x > 0.0 and not visible_rect.encloses(rect):
			print("  OFFSCREEN %s/%s: %s %s" % [_tag, screen_name, c.get_class(), rect])
		if c is BaseButton and (rect.size.y < 34.0 or rect.size.x < 34.0):
			print("  SMALL BUTTON %s/%s: %s %s" % [_tag, screen_name, c.name, rect.size])


func _sample_result() -> Dictionary:
	var rows: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 10:
		rows.append({"id": i, "name": Profile.player_name if i == 0 else Names.bot_name(rng), "team": i % 2, "bot": i != 0, "look": {}, "tags": rng.randi_range(0, 9), "rescues": rng.randi_range(0, 4), "captures": rng.randi_range(0, 2), "jailed": 2, "powers": 4, "score": rng.randi_range(0, 400)})
	return {"result": {"seconds": 142.0, "winner": 0, "my_team": 0, "score": [3, 1], "mine": {"won": true, "tags": 6, "rescues": 2, "captures": 1, "jailed": 3, "powers": 9, "skills": 5}, "players": rows, "mvp": 0, "reason": "capture", "online": false, "map": "barrio_plaza"}, "rewards": {"coins": 58, "xp": 90}}
