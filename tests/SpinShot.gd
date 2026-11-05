extends Node
## Walks the player into a crystal in a real match and saves pictures of the slot machine as it runs:
##   godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1280x720 res://tests/SpinShot.tscn
##       -- --out=<dir> --tag=desktop [--device=phone_portrait] [--second]
## With --second, the player already holds a card, so the small slot spins instead.

var _runner: MatchRunner
var _out := "user://shots"
var _tag := "spin"
var _second := false


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
		elif arg == "--second":
			_second = true
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
	_runner = MatchRunner.new()
	add_child(_runner)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var seats: Array = []
	for i in 10:
		seats.append({"name": "You" if i == 0 else Names.bot_name(rng), "bot": i != 0, "skill": 0.5, "team": i % 2, "look": Cosmetics.default_look() if i == 0 else Cosmetics.random_look(rng, 0.8)})
	_runner.start("barrio_plaza", seats, 0, 0.5, world, hud_root, false, true, 99)
	_run.call_deferred()


func _run() -> void:
	var sim := _runner.sim
	while sim.phase != Sim.Phase.PLAY:
		await get_tree().process_frame
	await _wait(0.5)
	var me: Sim.Player = sim.players[0]
	sim.pickups.clear()
	if _second:
		me.powers = ["freeze_ray"] as Array[String]
	# A few crystals on the field, one right in front of the player.
	for i in 3:
		sim._spawn_pickup(me.pos + Vector2(3.0 + i * 2.0, 1.0))
	await _wait(0.6)
	await _shot("0_crystals")
	var crystal: Dictionary = sim.pickups[0]
	crystal["born"] = sim.t - 1.0
	me.pos = crystal["pos"]
	while me.spin_left <= 0.0:
		await get_tree().process_frame
	print("got ", me.powers)
	for at: float in [0.25, 0.65, 1.05]:
		await _wait(at - (Sim.SPIN_TIME - me.spin_left))
		await _shot("1_spin_%d" % int(at * 100.0))
	while me.spin_left > 0.0:
		await get_tree().process_frame
	await _wait(0.1)
	await _shot("2_landed")
	await _wait(0.8)
	await _shot("3_held")
	get_tree().quit()


func _wait(seconds: float) -> void:
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout
	await RenderingServer.frame_post_draw


func _shot(label: String) -> void:
	get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [_out, _tag, label])
