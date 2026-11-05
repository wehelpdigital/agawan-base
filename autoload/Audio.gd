extends Node
## Music and sound effects. Effects come from assets/audio/sfx, music from assets/audio/music; both are
## loaded the first time they are needed, so startup stays quick.

const POOL := 14
const MUSIC_FILES := {
	"menu": "tropical_island_meet_and_greet",
	"shop": "latin_peppy_pepe",
	"tropical_island": "tropical_island_meet_and_greet",
	"tropical_tiki": "tropical_tiki_bar_mixer",
	"tropical_beach": "tropical_beachfront_celebration",
	"funk": "funk_make_funk",
	"gamer_hard": "gamer_hard_mode",
	"gamer_final": "gamer_final_level",
	"gamer_coins": "gamer_coins",
	"kids_polka": "kids_pixel_peeker_polka",
	"latin_samba": "latin_samba_isobel",
	"rock_sock": "rock_sock_hop",
	"rock_fast": "rock_exhilarate",
	"cartoon_snitch": "cartoon_sneaky_snitch",
	"cartoon_jaunty": "cartoon_jaunty_gumption",
}

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}
var _last_played := {}
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_current := ""
var _fade: Tween
var _sfx_bus := 0
var _music_bus := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sfx_bus = _ensure_bus("Sfx")
	_music_bus = _ensure_bus("Music")
	for i in POOL:
		var player := AudioStreamPlayer.new()
		player.bus = "Sfx"
		add_child(player)
		_players.append(player)
	_music_a = AudioStreamPlayer.new()
	_music_a.bus = "Music"
	add_child(_music_a)
	_music_b = AudioStreamPlayer.new()
	_music_b.bus = "Music"
	add_child(_music_b)
	apply_volumes()
	Settings.changed.connect(apply_volumes)


func _ensure_bus(bus_name: String) -> int:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		return index
	AudioServer.add_bus()
	index = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")
	return index


func apply_volumes() -> void:
	AudioServer.set_bus_volume_db(_sfx_bus, linear_to_db(maxf(Settings.sfx_volume, 0.0001)))
	AudioServer.set_bus_mute(_sfx_bus, Settings.sfx_volume <= 0.001)
	AudioServer.set_bus_volume_db(_music_bus, linear_to_db(maxf(Settings.music_volume * 0.8, 0.0001)))
	AudioServer.set_bus_mute(_music_bus, Settings.music_volume <= 0.001)


## Plays an effect. Asking for the same one again within 45 ms does nothing: ten players' worth of
## sounds would otherwise stack into noise.
func sfx(sfx_name: String, volume := 1.0, pitch := 1.0) -> void:
	if sfx_name == "" or volume <= 0.01:
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_played.get(sfx_name, -1000)) < 45:
		return
	var stream := _load_sfx(sfx_name)
	if stream == null:
		return
	_last_played[sfx_name] = now
	var player := _players[_next]
	_next = (_next + 1) % POOL
	player.stream = stream
	player.volume_db = linear_to_db(volume)
	player.pitch_scale = pitch
	player.play()


func _load_sfx(sfx_name: String) -> AudioStream:
	if _cache.has(sfx_name):
		return _cache[sfx_name]
	var path := "res://assets/audio/sfx/%s.ogg" % sfx_name
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path)
	_cache[sfx_name] = stream
	return stream


func has_sfx(sfx_name: String) -> bool:
	return _load_sfx(sfx_name) != null


## Crossfades to a track from MUSIC_FILES; asking for the one already playing does nothing.
func music(track: String, fade_time := 0.8) -> void:
	if track == _music_current:
		return
	var file: String = MUSIC_FILES.get(track, "")
	var path := "res://assets/audio/music/%s.ogg" % file
	if file == "" or not ResourceLoader.exists(path):
		return
	_music_current = track
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	var incoming := _music_b if _music_a.playing else _music_a
	var outgoing := _music_a if incoming == _music_b else _music_b
	if _fade:
		_fade.kill()
	incoming.stream = stream
	incoming.volume_db = -40.0
	incoming.pitch_scale = 1.0
	incoming.play()
	_fade = create_tween().set_parallel()
	_fade.tween_property(incoming, "volume_db", 0.0, fade_time)
	if outgoing.playing:
		_fade.tween_property(outgoing, "volume_db", -40.0, fade_time)
		_fade.chain().tween_callback(outgoing.stop)


## The last minute of a match: the music picks up.
func fiesta_time() -> void:
	music("rock_fast", 0.5)


func music_duck(amount_db: float) -> void:
	AudioServer.set_bus_volume_db(_music_bus, linear_to_db(maxf(Settings.music_volume * 0.8, 0.0001)) + amount_db)
