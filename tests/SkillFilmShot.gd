extends Node
## Plays every skill in the preview window, checks it went off, and saves a picture of each:
##   godot --path . --rendering-driver opengl3 --audio-driver Dummy --resolution 640x360 res://tests/SkillFilmShot.tscn -- --out=<dir> [--hero=sir_clank]

var _out := "user://skillfilm"
var _hero := "sir_clank"


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
		elif arg.begins_with("--hero="):
			_hero = arg.trim_prefix("--hero=")
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _run() -> void:
	var layer := Control.new()
	layer.theme = UiKit.theme()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	var film := SkillPreview.new()
	film.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(film)
	await get_tree().process_frame
	var started := Time.get_ticks_msec()
	var first: String = Skills.ALL.keys()[0]
	film.play(_hero, first, 3)
	while film._covered:
		await get_tree().process_frame
	print("preview ready after %d ms" % (Time.get_ticks_msec() - started))
	await get_tree().create_timer(0.4).timeout
	var quiet := 0
	var skills: Array = Skills.ALL.keys()
	skills.append(Skills.own_skill(_hero))
	for skill: String in skills:
		var used: int = film._sim.players[0].skills_used
		film.play(_hero, skill, 3)
		var wait := 0.0
		while film._clock < SkillPreview.FIRE_AT + 1.0 and wait < 4.0:
			await get_tree().process_frame
			wait += get_process_delta_time()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out, skill])
		if film._sim.players[0].skills_used == used:
			print("DIDN'T GO OFF: ", skill)
			quiet += 1
	print("SkillFilmShot: ", "OK" if quiet == 0 else "%d didn't go off" % quiet)
	get_tree().quit()
