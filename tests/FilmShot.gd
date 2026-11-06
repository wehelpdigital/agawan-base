extends Node
## Plays a map's film and saves frames from each kind of shot:
##   godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 960x540 res://tests/FilmShot.tscn
##       -- --out=<dir> --map=<id> [--weather=fog]

var _out := "user://film"
var _map := "kyoto_plaza"


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--map="):
			_map = arg.trim_prefix("--map=")
		elif arg.begins_with("--weather="):
			Profile.favorite_weather = arg.trim_prefix("--weather=")
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _run() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(holder)
	var film := MapPreview.new()
	film.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.add_child(film)
	await get_tree().process_frame
	var started := Time.get_ticks_msec()
	film.play(_map)
	while film._view == null:
		await get_tree().process_frame
	print("film built in %d ms" % (Time.get_ticks_msec() - started))
	var frames := 0
	var clock := Time.get_ticks_msec()
	for shot in MapPreview.SHOTS:
		for moment: float in [1.0, 4.5]:
			var until := (shot * MapPreview.SHOT_SECONDS) + moment
			while film._clock < until:
				await get_tree().process_frame
				frames += 1
			await RenderingServer.frame_post_draw
			var image := get_viewport().get_texture().get_image()
			var path := "%s/%s_%d_%d.png" % [_out, _map, shot, int(moment)]
			image.save_png(path)
			print("saved ", path)
	print("about %.0f fps" % (frames * 1000.0 / maxf(Time.get_ticks_msec() - clock, 1.0)))
	get_tree().quit()
