extends Node
## Plays a real match with bots and saves screenshots, to check how a map looks:
##   godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1280x720 res://tests/MatchShot.tscn
##       -- --map=barrio_plaza --out=<dir> --tag=name --device=desktop --times=4,12

var _runner: MatchRunner
var _times: Array[float] = [4.0, 14.0]
var _out := "user://shots"
var _tag := "match"
var _map := "barrio_plaza"
var _clock := 0.0
var _hud_root: Control
var _fps_samples: Array[float] = []
var _power := ""
var _all_powers := false
var _power_i := 0
var _power_clock := 0.0


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="):
			_map = arg.trim_prefix("--map=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
		elif arg.begins_with("--power="):
			_power = arg.trim_prefix("--power=")
		elif arg == "--all-powers":
			_all_powers = true
		elif arg.begins_with("--speed="):
			Engine.time_scale = float(arg.trim_prefix("--speed="))
		elif arg.begins_with("--times="):
			_times.clear()
			for part in arg.trim_prefix("--times=").split(","):
				_times.append(float(part))
	DirAccess.make_dir_recursive_absolute(_out)
	UiScale.apply(get_tree())
	var world := Node3D.new()
	add_child(world)
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud_root = Control.new()
	_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_root.theme = UiKit.theme()
	layer.add_child(_hud_root)
	_runner = MatchRunner.new()
	add_child(_runner)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var seats: Array = []
	for i in 10:
		seats.append({"name": "Player" if i == 0 else Names.bot_name(rng), "bot": true, "skill": 0.7, "team": i % 2, "look": Cosmetics.random_look(rng, 0.8)})
	_runner.start(_map, seats, 0, 0.7, world, _hud_root, false, true, 99)


func _process(delta: float) -> void:
	_clock += delta
	if _runner.sim.phase == Sim.Phase.PLAY:
		_fps_samples.append(delta)
	if _power != "" and _clock > 3.5:
		_runner.sim.players[0].powers = [_power] as Array[String]
		_power = ""
	if _all_powers and _runner.sim.phase == Sim.Phase.PLAY:
		_power_clock -= delta
		if _power_clock <= 0.0 and _power_i < Powerups.ALL.size():
			_power_clock = 0.4
			var p: Sim.Player = _runner.sim.players[_power_i % 10]
			p.powers = [Powerups.id_at(_power_i)] as Array[String]
			p.want_use = true
			_power_i += 1
	if _times.is_empty():
		_finish()
	elif _clock >= _times[0]:
		var at: float = _times.pop_front()
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		image.save_png("%s/%s_%02d.png" % [_out, _tag, int(at)])


func _finish() -> void:
	var total := 0.0
	for d in _fps_samples:
		total += d
	if total > 0.0:
		print("%s: %.0f fps average, %d triangles on screen, %d draw calls" % [_tag, _fps_samples.size() / total,
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
	get_tree().quit()
