extends Node
# ═══════════════════════════════════════════════════
# SaveManager.gd  —  AUTOLOAD SINGLETON
# All disk I/O lives here. ProgressTracker owns
# the data model; SaveManager owns the file.
# ═══════════════════════════════════════════════════

const SAVE_PATH:    String = "user://algoquest_save.json"
const BACKUP_PATH:  String = "user://algoquest_save.bak.json"
const CONFIG_PATH:  String = "user://algoquest.cfg"

var _cfg: ConfigFile = ConfigFile.new()

func _ready() -> void:
	_cfg.load(CONFIG_PATH)
	_ensure_player_id()

# ─── Player identity ──────────────────────────────

func get_player_id() -> String:
	var pid: String = _cfg.get_value("player","id","") as String
	return pid

func _ensure_player_id() -> void:
	if _cfg.get_value("player","id","") == "":
		var pid: String = "aq_" + str(randi_range(100000,999999)) + \
			"_" + str(int(Time.get_unix_time_from_system()))
		_cfg.set_value("player","id", pid)
		_cfg.save(CONFIG_PATH)

# ─── Settings ─────────────────────────────────────

func get_setting(key: String, default) -> Variant:
	return _cfg.get_value("settings", key, default)

func set_setting(key: String, value: Variant) -> void:
	_cfg.set_value("settings", key, value)
	_cfg.save(CONFIG_PATH)

func get_volume_master() -> float:
	return _cfg.get_value("settings","volume_master", 1.0) as float
func get_volume_music() -> float:
	return _cfg.get_value("settings","volume_music", 0.8) as float
func get_volume_sfx() -> float:
	return _cfg.get_value("settings","volume_sfx", 1.0) as float

func set_volume_master(v: float) -> void: set_setting("volume_master", v)
func set_volume_music(v: float) -> void:  set_setting("volume_music",  v)
func set_volume_sfx(v: float) -> void:    set_setting("volume_sfx",    v)

# ─── Progress data (JSON) ─────────────────────────

func save_progress(data: Dictionary) -> bool:
	# Write backup first
	if FileAccess.file_exists(SAVE_PATH):
		var src := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if src:
			var content: String = src.get_as_text()
			src.close()
			var bak := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
			if bak:
				bak.store_string(content)
				bak.close()

	# Write main save
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: cannot open save file")
		return false

	var json_str: String = JSON.stringify(data, "\t")
	file.store_string(json_str)
	file.close()
	return true

func load_progress() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		# Try backup
		return _load_backup()
	var content: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(content) != OK:
		push_error("SaveManager: corrupt save, loading backup")
		return _load_backup()
	return json.data as Dictionary

func _load_backup() -> Dictionary:
	if not FileAccess.file_exists(BACKUP_PATH): return {}
	var file := FileAccess.open(BACKUP_PATH, FileAccess.READ)
	if not file: return {}
	var content: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(content) != OK: return {}
	return json.data as Dictionary

func delete_save() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.remove_absolute(BACKUP_PATH)

func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func get_save_size_kb() -> float:
	if not FileAccess.file_exists(SAVE_PATH): return 0.0
	return FileAccess.get_file_as_bytes(SAVE_PATH).size() / 1024.0
