extends Node
# ═══════════════════════════════════════════════════
# FirebaseManager.gd  —  AUTOLOAD SINGLETON
#
# Handles:
#  1. Sign-up   — creates account in Firebase Auth
#                 then writes player doc to Firestore
#  2. Sign-in   — verifies email/password via REST
#                 then loads player doc from Firestore
#  3. Save progress — PATCH player doc after each level
#  4. Leaderboard   — query top scores
#
# ── Setup ──────────────────────────────────────────
# 1. Go to console.firebase.google.com
# 2. Create project → Enable Authentication
#    (Email/Password provider)
# 3. Enable Firestore Database (production or test mode)
# 4. Copy your Web API key and Project ID below
# ═══════════════════════════════════════════════════

# ── CONFIGURE THESE ────────────────────────────────
const PROJECT_ID: String = "algoquest-3f812"
const API_KEY:    String = "AIzaSyC6r1sMMfdWqcSB2_-FH7ZsySKrPLVogrk"
# ───────────────────────────────────────────────────

const AUTH_BASE:  String = "https://identitytoolkit.googleapis.com/v1"
const FS_BASE:    String = \
	"https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents"

signal auth_success(player_data: Dictionary)
signal auth_error(message: String)
signal save_done(ok: bool)
signal leaderboard_loaded(entries: Array)

var _id_token:    String = ""
var _uid:         String = ""
var _http:        HTTPRequest
var _action:      String = ""
var _pending_data: Dictionary = {}

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.request_completed.connect(_on_done)
	add_child(_http)

func is_configured() -> bool:
	return PROJECT_ID != "YOUR_FIREBASE_PROJECT_ID" \
		and API_KEY != "YOUR_FIREBASE_WEB_API_KEY" \
		and PROJECT_ID != "" and API_KEY != ""

func is_signed_in() -> bool:
	return _id_token != ""

# ── AUTH ──────────────────────────────────────────

func sign_up(email: String, password: String, player_data: Dictionary) -> void:
	if not is_configured():
		emit_signal("auth_error", "Firebase not configured. See FirebaseManager.gd")
		return
	_action = "signup"
	_pending_data = player_data
	var url: String = "%s/accounts:signUp?key=%s" % [AUTH_BASE, API_KEY]
	var body: String = JSON.stringify({
		"email":             email,
		"password":          password,
		"returnSecureToken": true
	})
	_http.request(url, ["Content-Type: application/json"],
		HTTPClient.METHOD_POST, body)

func sign_in(email: String, password: String) -> void:
	if not is_configured():
		emit_signal("auth_error", "Firebase not configured. See FirebaseManager.gd")
		return
	_action = "signin"
	var url: String = "%s/accounts:signInWithPassword?key=%s" % [AUTH_BASE, API_KEY]
	var body: String = JSON.stringify({
		"email":             email,
		"password":          password,
		"returnSecureToken": true
	})
	_http.request(url, ["Content-Type: application/json"],
		HTTPClient.METHOD_POST, body)

func sign_out() -> void:
	_id_token = ""
	_uid      = ""
	SaveManager.set_setting("firebase_uid", "")
	SaveManager.set_setting("firebase_token", "")

# ── FIRESTORE PLAYER DOC ──────────────────────────

func create_player_doc(player_data: Dictionary) -> void:
	var url: String = "%s/players/%s?key=%s" % [FS_BASE % PROJECT_ID, _uid, API_KEY]
	var doc: Dictionary = _to_fs(_build_player_doc(player_data))
	var body: String = JSON.stringify({ "fields": doc })
	_action = "create_doc"
	_http.request(url, [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % _id_token
	], HTTPClient.METHOD_PATCH, body)

func load_player_doc() -> void:
	var url: String = "%s/players/%s?key=%s" % [FS_BASE % PROJECT_ID, _uid, API_KEY]
	_action = "load_doc"
	_http.request(url, [
		"Authorization: Bearer %s" % _id_token
	], HTTPClient.METHOD_GET, "")

func save_progress(chapter: int, level: int, _score: int, _perfect: bool) -> void:
	if not is_signed_in(): return
	var url: String = "%s/players/%s?key=%s" % [FS_BASE % PROJECT_ID, _uid, API_KEY]
	var snap: Dictionary = ProgressTracker.get_world_map_snapshot()
	var total: int = 0
	for ch in snap:
		total += snap[ch].get("best_score", 0) as int
	var fields: Dictionary = {
		"total_score":    total,
		"last_chapter":   chapter,
		"last_level":     level,
		"last_played_at": Time.get_datetime_string_from_system(),
	}
	_action = "save"
	_http.request(url, [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % _id_token
	], HTTPClient.METHOD_PATCH, JSON.stringify({ "fields": _to_fs(fields) }))

func load_leaderboard() -> void:
	if not is_configured():
		emit_signal("leaderboard_loaded", [])
		return
	var url: String = "%s:runQuery?key=%s" % [FS_BASE % PROJECT_ID, API_KEY]
	var q: Dictionary = { "structuredQuery": {
		"from":    [{ "collectionId": "players" }],
		"orderBy": [{ "field": { "fieldPath": "total_score" }, "direction": "DESCENDING" }],
		"limit":   50
	}}
	_action = "leaderboard"
	_http.request(url, ["Content-Type: application/json"],
		HTTPClient.METHOD_POST, JSON.stringify(q))

# ── INTERNAL ──────────────────────────────────────

func _build_player_doc(pd: Dictionary) -> Dictionary:
	return {
		"display_name": pd.get("name", ""),
		"email":        pd.get("email", ""),
		"year":         pd.get("year", ""),
		"course":       pd.get("course", ""),
		"character_id": pd.get("character_id", "keeper"),
		"total_score":  0,
		"chapters_done":0,
		"created_at":   Time.get_datetime_string_from_system(),
		"last_played_at": Time.get_datetime_string_from_system(),
	}

func _on_done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	var text: String = body.get_string_from_utf8()
	var j := JSON.new()
	j.parse(text)
	var data = j.data

	if result != HTTPRequest.RESULT_SUCCESS:
		emit_signal("auth_error", "Network error")
		return

	match _action:
		"signup":
			if code in [200, 201]:
				_id_token = (data as Dictionary).get("idToken",  "") as String
				_uid      = (data as Dictionary).get("localId",  "") as String
				SaveManager.set_setting("firebase_uid",   _uid)
				SaveManager.set_setting("firebase_token", _id_token)
				create_player_doc(_pending_data)
			else:
				var err: String = _parse_error(data)
				emit_signal("auth_error", err)

		"create_doc":
			if code in [200, 201]:
				emit_signal("auth_success", _pending_data)
			else:
				emit_signal("auth_error", "Could not save player data (%d)" % code)

		"signin":
			if code in [200, 201]:
				_id_token = (data as Dictionary).get("idToken",  "") as String
				_uid      = (data as Dictionary).get("localId",  "") as String
				SaveManager.set_setting("firebase_uid",   _uid)
				SaveManager.set_setting("firebase_token", _id_token)
				load_player_doc()
			else:
				var err: String = _parse_error(data)
				emit_signal("auth_error", err)

		"load_doc":
			if code == 200:
				var fields: Dictionary = (data as Dictionary).get("fields", {}) as Dictionary
				var player: Dictionary = _from_fs(fields)
				# Restore local name/character from cloud
				if player.has("display_name"):
					ProgressTracker.set_player_name(player["display_name"] as String)
				if player.has("character_id"):
					SaveManager.set_setting("character_id", player["character_id"] as String)
				emit_signal("auth_success", player)
			elif code == 404:
				# Doc doesn't exist yet — create it with cached pending data
				create_player_doc(_pending_data)
			else:
				emit_signal("auth_error", "Could not load player data (%d)" % code)

		"save":
			emit_signal("save_done", code in [200, 201])

		"leaderboard":
			if code != 200:
				emit_signal("leaderboard_loaded", [])
				return
			var entries: Array = []
			for item in (data as Array):
				if (item as Dictionary).has("document"):
					var doc_fields: Dictionary = \
						((item as Dictionary)["document"] as Dictionary).get("fields", {}) as Dictionary
					entries.append(_from_fs(doc_fields))
			emit_signal("leaderboard_loaded", entries)

func _parse_error(data) -> String:
	if data is Dictionary:
		var err_obj = (data as Dictionary).get("error", {})
		if err_obj is Dictionary:
			var msg: String = (err_obj as Dictionary).get("message", "") as String
			match msg:
				"EMAIL_EXISTS":            return "Email already registered. Please sign in."
				"INVALID_EMAIL":           return "Invalid email address."
				"WEAK_PASSWORD : Password should be at least 6 characters":
					return "Password must be at least 6 characters."
				"EMAIL_NOT_FOUND":         return "No account found with that email."
				"INVALID_PASSWORD":        return "Wrong password. Please try again."
				"USER_DISABLED":           return "This account has been disabled."
				"INVALID_LOGIN_CREDENTIALS": return "Wrong email or password."
				_:
					return msg if msg != "" else "Authentication failed."
	return "Authentication failed."

func _to_fs(d: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in d:
		var v = d[k]
		if   v is int   : out[k] = { "integerValue":  str(int(v)) }
		elif v is float : out[k] = { "doubleValue":   v }
		elif v is String: out[k] = { "stringValue":   v }
		elif v is bool  : out[k] = { "booleanValue":  v }
	return out

func _from_fs(fields: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in fields:
		var v: Dictionary = fields[k] as Dictionary
		if   v.has("integerValue") : out[k] = int(v["integerValue"] as String)
		elif v.has("doubleValue")  : out[k] = float(str(v["doubleValue"]))
		elif v.has("stringValue")  : out[k] = v["stringValue"]
		elif v.has("booleanValue") : out[k] = v["booleanValue"]
	return out
