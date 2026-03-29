extends Node
# ═══════════════════════════════════════════════════
# AudioManager.gd  —  AUTOLOAD SINGLETON
# ═══════════════════════════════════════════════════

var _bgm:             AudioStreamPlayer
var _sfx:             AudioStreamPlayer
var _sfx2:            AudioStreamPlayer
var _current_bgm_key: String = ""

func _ready() -> void:
	_bgm  = _make_player("Music")
	_sfx  = _make_player("SFX")
	_sfx2 = _make_player("SFX")
	_apply_saved_volumes()

func _make_player(bus_name: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	var idx: int = AudioServer.get_bus_index(bus_name)
	p.bus = bus_name if idx >= 0 else "Master"
	add_child(p)
	return p

func _apply_saved_volumes() -> void:
	_set_bus_vol("Master", SaveManager.get_volume_master())
	_set_bus_vol("Music",  SaveManager.get_volume_music())
	_set_bus_vol("SFX",    SaveManager.get_volume_sfx())

func _set_bus_vol(bus_name: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))

func play_bgm(key: String, fade_sec: float = 0.6) -> void:
	if key == _current_bgm_key and _bgm.playing:
		return
	var path: String = AssetMap.bgm(key)
	if path == "" or not FileAccess.file_exists(path):
		_current_bgm_key = key
		return
	_current_bgm_key = key
	var stream: AudioStream = load(path)
	if _bgm.playing:
		var tw := create_tween()
		tw.tween_property(_bgm, "volume_db", -60.0, fade_sec * 0.5)
		tw.tween_callback(func():
			_bgm.stream    = stream
			_bgm.volume_db = -60.0
			_bgm.play()
			var tw2 := create_tween()
			tw2.tween_property(_bgm, "volume_db", 0.0, fade_sec * 0.5)
		)
	else:
		_bgm.stream    = stream
		_bgm.volume_db = 0.0
		_bgm.play()

func stop_bgm(fade_sec: float = 0.5) -> void:
	if not _bgm.playing: return
	var tw := create_tween()
	tw.tween_property(_bgm, "volume_db", -60.0, fade_sec)
	tw.tween_callback(_bgm.stop)

func play_sfx(key: String) -> void:
	var path: String = AssetMap.sfx(key)
	if path == "" or not FileAccess.file_exists(path):
		return
	var player: AudioStreamPlayer = _sfx2 if _sfx.playing else _sfx
	player.stream = load(path)
	player.play()

func set_master_volume(v: float) -> void:
	_set_bus_vol("Master", v)
	SaveManager.set_volume_master(v)

func set_music_volume(v: float) -> void:
	_set_bus_vol("Music", v)
	SaveManager.set_volume_music(v)

func set_sfx_volume(v: float) -> void:
	_set_bus_vol("SFX", v)
	SaveManager.set_volume_sfx(v)
