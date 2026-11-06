extends Node
## A close look at every trick on the field together, from the match camera:
##   godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1280x720 res://tests/TrickShot.tscn
##       -- --map=barrio_plaza --out=<dir> --tag=x [--at=x,y]

var _map := "barrio_plaza"
var _out := "user://shots"
var _tag := "trick"
var _at := Vector2(-1, -1)
var _weather := "clear"
var _wait := 0.7


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="):
			_map = arg.trim_prefix("--map=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
		elif arg.begins_with("--weather="):
			_weather = arg.trim_prefix("--weather=")
		elif arg.begins_with("--wait="):
			_wait = float(arg.trim_prefix("--wait="))
		elif arg.begins_with("--at="):
			var parts := arg.trim_prefix("--at=").split(",")
			_at = Vector2(float(parts[0]), float(parts[1]))
	DirAccess.make_dir_recursive_absolute(_out)
	UiScale.apply(get_tree())
	var world := Node3D.new()
	add_child(world)
	var layer := CanvasLayer.new()
	add_child(layer)
	var hud_root := Control.new()
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.theme = UiKit.theme()
	layer.add_child(hud_root)
	var runner := MatchRunner.new()
	add_child(runner)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var seats: Array = []
	for i in 10:
		seats.append({"name": "You" if i == 0 else Names.bot_name(rng), "bot": i != 0, "skill": 0.5, "team": i % 2, "look": Cosmetics.default_look() if i == 0 else Cosmetics.random_look(rng, 0.7)})
	runner.start(_map, seats, 0, 0.5, world, hud_root, false, true, 99, _weather)
	var sim := runner.sim
	while sim.phase != Sim.Phase.PLAY:
		await get_tree().process_frame
	var me: Sim.Player = sim.players[0]
	var at := _at if _at.x >= 0.0 else sim.arena_size() * 0.5 - Vector2(8, 0)
	me.pos = at
	await get_tree().create_timer(_wait).timeout
	me.pos = at
	await get_tree().create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, _tag])
	get_tree().quit()
