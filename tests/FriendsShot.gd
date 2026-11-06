extends Node
## Opens the home screen and saves a picture every so often, to see the friends playing, and how much they cost:
##   godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 1280x720 res://tests/FriendsShot.tscn
##       -- --out=<dir> [--device=phone_portrait] [--every=0.6] [--count=16]

var _out := "user://friends"
var _every := 0.6
var _count := 16


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--every="):
			_every = arg.trim_prefix("--every=").to_float()
		elif arg.begins_with("--count="):
			_count = arg.trim_prefix("--count=").to_int()
	DirAccess.make_dir_recursive_absolute(_out)
	Profile.tutorial_done = true
	Profile.daily_day = Time.get_date_string_from_system()
	var main: Node = load("res://scenes/Main.gd").new()
	add_child(main)
	_run.call_deferred(main)


func _run(main: Node) -> void:
	await get_tree().create_timer(0.6).timeout
	var ui: UiRoot = main.ui
	var opened := Time.get_ticks_msec()
	ui.show_screen("home", {})
	var worst := 0.0
	var frames := 0
	for i in _count:
		var until := Time.get_ticks_msec() + int(_every * 1000.0)
		while Time.get_ticks_msec() < until:
			await get_tree().process_frame
			frames += 1
			worst = maxf(worst, get_process_delta_time())
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/home_%02d.png" % [_out, i])
	var seconds := (Time.get_ticks_msec() - opened) / 1000.0
	print("about %.0f fps, longest frame %d ms, %d triangles a frame, %d draw calls" % [frames / seconds, worst * 1000.0, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)])
	get_tree().quit()
