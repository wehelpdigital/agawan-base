extends Node
## Everything online, in one place: accounts, leaderboards, guilds and chat over HTTP and a WebSocket,
## matchmaking, and passing match data between players. Nothing here is needed to play against the AI:
## with no server the game just stays offline and says so.
##
## The server is in server/ (Node). In the web build, the game talks to whichever server served the page.
## Native builds use DEFAULT_SERVER, or a server set in Settings. Override: -- --server=http://host:port

signal status_changed(online: bool)
signal chat_received(channel: String, message: Dictionary)
signal chat_history(channel: String, messages: Array)
signal queue_update(found: int, needed: int, waited: float, wait_total: float)
signal match_found(data: Dictionary)
signal match_snapshot(bytes: PackedByteArray)
signal match_input(bytes: PackedByteArray)
signal match_emote(player_id: int, emote_id: String)
signal match_host_changed(new_host: int)
signal match_player_left(player_id: int)
signal match_result(data: Dictionary)
signal guild_changed
signal room_updated(room: Dictionary)
signal room_error(message: String)
signal online_count(count: int)

const DEFAULT_SERVER := ""  ## Set this to the deployed server for Android, iOS and desktop builds.
const BIN_SNAPSHOT := 1
const BIN_INPUT := 2
const RECONNECT_SECONDS := 5.0
const SYNC_DELAY := 2.0
const LOGIN_RETRY_MAX := 120.0

var online := false
var players_online := 0
var room: Dictionary = {}  ## The Friend Room this player is in; empty when none.
var last_result: Dictionary = {}  ## The server's word on the last match, for the results screen.
var _ws := WebSocketPeer.new()
var _ws_open := false
var _ws_url := ""
var _retry := 0.0
var _base_url := ""
var _ping_timer := 0.0
var _sync_timer := -1.0
var _in_match := false
var _queueing := false
var _pending_login := false
var _login_wait := RECONNECT_SECONDS  ## Grows after each failed login, so a broken server isn't hammered.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_base_url = _resolve_server()
	if _base_url != "":
		_login_on_start()


func _resolve_server() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--server="):
			return arg.trim_prefix("--server=").trim_suffix("/")
	if Settings.server_url != "":
		return Settings.server_url.trim_suffix("/")
	if OS.has_feature("web"):
		var origin: Variant = JavaScriptBridge.eval("window.location.origin", true)
		if origin is String and String(origin).begins_with("http"):
			return String(origin)
	return DEFAULT_SERVER.trim_suffix("/")


func has_server() -> bool:
	return _base_url != ""


func server_url() -> String:
	return _base_url


func set_server(url: String) -> void:
	Settings.server_url = url.strip_edges().trim_suffix("/")
	Settings.save()
	_base_url = _resolve_server()
	_close_ws()
	if _base_url != "":
		_login_on_start()


# --- Accounts -------------------------------------------------------------------------------------

func _login_on_start() -> void:
	if _pending_login:
		return
	_pending_login = true
	if Profile.token == "":
		var result := await request("POST", "/api/auth/guest", {"name": Profile.player_name, "save": Profile.to_data()})
		if result["ok"]:
			_after_auth(result["data"])
	else:
		var result := await request("GET", "/api/me")
		if result["ok"]:
			_after_auth(result["data"])
		elif int(result["code"]) == 401:  # The server forgot this token; start over as a guest.
			Profile.token = ""
			var again := await request("POST", "/api/auth/guest", {"name": Profile.player_name, "save": Profile.to_data()})
			if again["ok"]:
				_after_auth(again["data"])
	_pending_login = false
	if Profile.token != "":
		_login_wait = RECONNECT_SECONDS
		_connect_ws()
	else:
		_retry = _login_wait
		_login_wait = minf(_login_wait * 2.0, LOGIN_RETRY_MAX)


func _after_auth(data: Dictionary) -> void:
	if data.has("token"):
		Profile.token = str(data["token"])
	var user: Dictionary = data.get("user", {})
	Profile.account = str(user.get("username", ""))
	Profile.guild_id = int(user.get("guild_id", 0))
	Profile.guild_name = str(user.get("guild_name", ""))
	var remote_save: Variant = user.get("save")
	# The newer save wins; trophies always follow the server.
	if remote_save is Dictionary and int((remote_save as Dictionary).get("saved_at", 0)) > Profile.saved_at:
		Profile.apply_data(remote_save)
	if user.has("trophies"):
		Profile.trophies = int(user["trophies"])
		Profile.best_trophies = maxi(Profile.best_trophies, Profile.trophies)
	if user.has("display_name"):
		Profile.player_name = str(user["display_name"])
	Profile.notify_changed(false)
	queue_profile_sync()


func register(username: String, password: String) -> Dictionary:
	var result := await request("POST", "/api/auth/register", {"username": username, "password": password, "save": Profile.to_data()})
	if result["ok"]:
		_after_auth(result["data"])
	return result


func login(username: String, password: String) -> Dictionary:
	var result := await request("POST", "/api/auth/login", {"username": username, "password": password})
	if result["ok"]:
		Profile.saved_at = 0  # On a new device, the account's save wins.
		_after_auth(result["data"])
		_close_ws()
		_connect_ws()
	return result


func logout() -> void:
	await request("POST", "/api/auth/logout", {})
	Profile.token = ""
	Profile.account = ""
	Profile.guild_id = 0
	Profile.guild_name = ""
	Profile.notify_changed(false)
	_close_ws()
	_login_on_start()


func queue_profile_sync() -> void:
	_sync_timer = SYNC_DELAY


func _sync_profile() -> void:
	if Profile.token == "":
		return
	await request("PUT", "/api/me", {"name": Profile.player_name, "look": Profile.look, "level": Profile.level, "save": Profile.to_data()})


# --- HTTP -----------------------------------------------------------------------------------------

## Returns {ok, code, data}. Never throws; failure is ok = false.
func request(method: String, path: String, body: Variant = null) -> Dictionary:
	if _base_url == "":
		return {"ok": false, "code": 0, "data": {"error": "offline"}}
	var http := HTTPRequest.new()
	http.timeout = 12.0
	# Browsers unzip replies by themselves, and left on, this would try to unzip them a second time and get
	# nothing. Hosts behind Cloudflare compress replies, so that would break every call there. The replies
	# here are small, so native builds lose nothing by asking for them plain.
	http.accept_gzip = false
	add_child(http)
	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	if Profile.token != "":
		headers.append("Authorization: Bearer %s" % Profile.token)
	var verb := HTTPClient.METHOD_GET
	match method:
		"POST": verb = HTTPClient.METHOD_POST
		"PUT": verb = HTTPClient.METHOD_PUT
		"DELETE": verb = HTTPClient.METHOD_DELETE
	var payload := JSON.stringify(body) if body != null else ""
	var error := http.request(_base_url + path, headers, verb, payload)
	if error != OK:
		http.queue_free()
		return {"ok": false, "code": 0, "data": {"error": "offline"}}
	var response: Array = await http.request_completed
	http.queue_free()
	var code: int = response[1]
	var parsed: Variant = JSON.parse_string((response[3] as PackedByteArray).get_string_from_utf8())
	var data: Dictionary = parsed if parsed is Dictionary else {}
	if int(response[0]) != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "code": 0, "data": {"error": "offline"}}
	# A reply that isn't the JSON we expect is a failure, not an empty success.
	return {"ok": code >= 200 and code < 300 and parsed is Dictionary, "code": code, "data": data}


func leaderboard(scope: String, limit := 100) -> Dictionary:
	return await request("GET", "/api/leaderboard?scope=%s&limit=%d" % [scope, limit])


func guild_list(search := "") -> Dictionary:
	return await request("GET", "/api/guilds?q=%s" % search.uri_encode())


func guild_get(id: int) -> Dictionary:
	return await request("GET", "/api/guilds/%d" % id)


func guild_create(guild_name: String, tag: String, about: String, badge: int) -> Dictionary:
	var result := await request("POST", "/api/guilds", {"name": guild_name, "tag": tag, "about": about, "badge": badge})
	if result["ok"]:
		_set_guild(result["data"])
	return result


func guild_join(id: int) -> Dictionary:
	var result := await request("POST", "/api/guilds/%d/join" % id, {})
	if result["ok"]:
		_set_guild(result["data"])
	return result


func guild_leave() -> Dictionary:
	var result := await request("POST", "/api/guilds/leave", {})
	if result["ok"]:
		_set_guild({})
	return result


func guild_kick(user_id: int) -> Dictionary:
	return await request("POST", "/api/guilds/kick", {"user_id": user_id})


func _set_guild(data: Dictionary) -> void:
	var guild: Dictionary = data.get("guild", {})
	Profile.guild_id = int(guild.get("id", 0))
	Profile.guild_name = str(guild.get("name", ""))
	Profile.notify_changed(false)
	_send({"t": "subscribe_guild"})
	guild_changed.emit()


# --- Realtime -------------------------------------------------------------------------------------

func _connect_ws() -> void:
	if _base_url == "" or Profile.token == "":
		return
	_close_ws()
	_ws = WebSocketPeer.new()
	_ws.inbound_buffer_size = 1 << 18
	_ws.outbound_buffer_size = 1 << 18
	_ws.encode_buffer_max_size = 1 << 18
	var scheme_url := _base_url.replace("https://", "wss://").replace("http://", "ws://")
	_ws_url = "%s/ws?token=%s" % [scheme_url, Profile.token.uri_encode()]
	if _ws.connect_to_url(_ws_url) != OK:
		_retry = RECONNECT_SECONDS


func _close_ws() -> void:
	if _ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		_ws.close()
	_ws_open = false
	room = {}
	_set_online(false)


func _set_online(value: bool) -> void:
	if online != value:
		online = value
		status_changed.emit(value)


func _process(delta: float) -> void:
	if _sync_timer > 0.0:
		_sync_timer -= delta
		if _sync_timer <= 0.0:
			_sync_profile()
	_ws.poll()
	match _ws.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not _ws_open:
				_ws_open = true
				_set_online(true)
			while _ws.get_available_packet_count() > 0:
				var packet := _ws.get_packet()
				if _ws.was_string_packet():
					_on_text(packet.get_string_from_utf8())
				else:
					_on_binary(packet)
			_ping_timer -= delta
			if _ping_timer <= 0.0:
				_ping_timer = 20.0
				_send({"t": "ping"})
		WebSocketPeer.STATE_CLOSED:
			if _ws_open:
				_ws_open = false
				room = {}
				_set_online(false)
				_retry = RECONNECT_SECONDS
			if _pending_login:
				pass  # The login in progress opens the connection when it's done.
			elif Profile.token != "" and _base_url != "":
				_retry -= delta
				if _retry <= 0.0:
					_retry = RECONNECT_SECONDS
					_connect_ws()
			elif _base_url != "":
				_retry -= delta
				if _retry <= 0.0:
					_login_on_start()


func _send(data: Dictionary) -> void:
	if _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text(JSON.stringify(data))


func _on_text(text: String) -> void:
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return
	var msg: Dictionary = parsed
	match str(msg.get("t", "")):
		"chat":
			chat_received.emit(str(msg.get("channel", "global")), msg)
		"chat_history":
			chat_history.emit(str(msg.get("channel", "global")), msg.get("messages", []))
		"online":
			players_online = int(msg.get("count", 0))
			online_count.emit(players_online)
		"queue":
			queue_update.emit(int(msg.get("found", 1)), int(msg.get("needed", 10)), float(msg.get("waited", 0.0)), float(msg.get("wait_total", 10.0)))
		"match_start":
			_queueing = false
			_in_match = true
			match_found.emit(msg)
		"match_emote":
			match_emote.emit(int(msg.get("player", -1)), str(msg.get("emote", "")))
		"match_host":
			match_host_changed.emit(int(msg.get("host", -1)))
		"match_left":
			match_player_left.emit(int(msg.get("player", -1)))
		"match_result":
			_in_match = false
			last_result = msg
			if msg.has("trophies"):
				Profile.set_trophies(int(msg["trophies"]))
			match_result.emit(msg)
		"guild_update":
			guild_changed.emit()
		"room":
			room = msg.get("room", {})
			room_updated.emit(room)
		"room_closed":
			room = {}
			room_updated.emit(room)
		"room_error":
			room_error.emit(str(msg.get("message", "That didn't work.")))


func _on_binary(packet: PackedByteArray) -> void:
	if packet.is_empty():
		return
	var kind := packet[0]
	var bytes := packet.slice(1)
	if kind == BIN_SNAPSHOT:
		match_snapshot.emit(bytes)
	elif kind == BIN_INPUT:
		match_input.emit(bytes)


## Chat is rate limited and filtered by the server.
func send_chat(channel: String, text: String) -> void:
	_send({"t": "chat", "channel": channel, "text": text})


func request_chat_history(channel: String) -> void:
	_send({"t": "chat_history", "channel": channel})


func queue_join(map_id: String) -> void:
	_queueing = true
	_send({"t": "queue", "map": map_id, "look": Profile.look, "name": Profile.player_name, "trophies": Profile.trophies})


func queue_leave() -> void:
	_queueing = false
	_send({"t": "queue_leave"})


func _me_payload() -> Dictionary:
	return {"name": Profile.player_name, "look": Profile.look, "trophies": Profile.trophies}


func room_create(map_id: String, skill: float) -> void:
	var data := _me_payload()
	data.merge({"t": "room_create", "map": map_id, "skill": skill})
	_send(data)


func room_join(code: String) -> void:
	if code == "":
		return
	var data := _me_payload()
	data.merge({"t": "room_join", "code": code})
	_send(data)


func room_leave() -> void:
	if not room.is_empty():
		room = {}
		_send({"t": "room_leave"})
		room_updated.emit(room)


func room_team(team: int) -> void:
	_send({"t": "room_team", "team": team})


func room_config(map_id: String, skill: float) -> void:
	_send({"t": "room_config", "map": map_id, "skill": skill})


func room_start() -> void:
	_send({"t": "room_start"})


func send_match_binary(kind: int, bytes: PackedByteArray) -> void:
	if _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	var packet := PackedByteArray([kind])
	packet.append_array(bytes)
	_ws.send(packet, WebSocketPeer.WRITE_MODE_BINARY)


func send_match_emote(player_id: int, emote_id: String) -> void:
	_send({"t": "match_emote", "player": player_id, "emote": emote_id})


func send_match_result(match_id: String, winner: int, mvp: int) -> void:
	_send({"t": "match_end", "match": match_id, "winner": winner, "mvp": mvp})


func leave_match() -> void:
	_in_match = false
	_send({"t": "match_leave"})
