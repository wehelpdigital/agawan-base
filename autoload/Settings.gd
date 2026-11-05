extends Node
## The player's settings, kept in user://settings.cfg.

signal changed

const FILE := "user://settings.cfg"

var music_volume := 0.7
var sfx_volume := 0.9
var quality := "auto"
var text_size := "normal"
var vibration := true
var camera_shake := true
var left_handed := false
var hints := true  ## Teaching tips in the first few matches.
var fps_counter := false
var server_url := ""  ## Empty: the default (see Net.gd).


func _init() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(FILE) != OK:
		return
	music_volume = float(cfg.get_value("audio", "music", music_volume))
	sfx_volume = float(cfg.get_value("audio", "sfx", sfx_volume))
	quality = str(cfg.get_value("video", "quality", quality))
	text_size = str(cfg.get_value("video", "text_size", text_size))
	fps_counter = bool(cfg.get_value("video", "fps", fps_counter))
	vibration = bool(cfg.get_value("game", "vibration", vibration))
	camera_shake = bool(cfg.get_value("game", "shake", camera_shake))
	left_handed = bool(cfg.get_value("game", "left_handed", left_handed))
	hints = bool(cfg.get_value("game", "hints", hints))
	server_url = str(cfg.get_value("net", "server_url", server_url))


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("video", "quality", quality)
	cfg.set_value("video", "text_size", text_size)
	cfg.set_value("video", "fps", fps_counter)
	cfg.set_value("game", "vibration", vibration)
	cfg.set_value("game", "shake", camera_shake)
	cfg.set_value("game", "left_handed", left_handed)
	cfg.set_value("game", "hints", hints)
	cfg.set_value("net", "server_url", server_url)
	cfg.save(FILE)
	changed.emit()
