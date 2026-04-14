extends Node
# ═══════════════════════════════════════════════════
# GameRouter.gd  —  AUTOLOAD SINGLETON
# Single point of truth for all scene transitions.
# ═══════════════════════════════════════════════════

signal scene_changed(key: String)

const SCENES: Dictionary = {
	"boot":          "res://scenes/Boot.tscn",
	"ss_intro":      "res://scenes/SSIntro.tscn",
	"auth_screen":   "res://scenes/AuthScreen.tscn",
	"char_create":   "res://scenes/CharacterCreate.tscn",
	"codemon_intro": "res://scenes/CodemonIntro.tscn",
	"intro_world":   "res://scenes/intro/IntroWorld.tscn",
	"main_menu":     "res://scenes/MainMenu.tscn",
	"name_entry":    "res://scenes/NameEntry.tscn",
	"world_map":     "res://scenes/WorldMap.tscn",
	"cutscene":      "res://scenes/Cutscene.tscn",
	"progress":      "res://scenes/ProgressScreen.tscn",
	"settings":      "res://scenes/Settings.tscn",
	"credits":       "res://scenes/Credits.tscn",
	"char_select":   "res://scenes/CharacterSelect.tscn",
	"level_complete":"res://scenes/shared/LevelComplete.tscn",
	"game_over":     "res://scenes/shared/GameOver.tscn",
	"achievement":   "res://scenes/shared/AchievementPopup.tscn",
	"ch1": "res://scenes/chapters/queue/Main.tscn",
	"ch2": "res://scenes/chapters/stack/Main.tscn",
	"ch3": "res://scenes/chapters/linked_list/Main.tscn",
	"ch4": "res://scenes/chapters/tree/Main.tscn",
	"ch5": "res://scenes/chapters/graph/Main.tscn",
}

const BGM_MAP: Dictionary = {
	"boot": "", "main_menu": "menu", "name_entry": "menu",
	"world_map": "world", "cutscene": "menu",
	"progress": "menu", "settings": "menu",
	"ch1": "ch1", "ch2": "ch2", "ch3": "ch3", "ch4": "ch4", "ch5": "ch5",
	"level_complete": "", "game_over": "",
}

var current_scene_key: String  = ""
var _pending_params:   Dictionary = {}
var _after_cutscene:   Callable   = func(): pass
var _fade_rect:        ColorRect  = null

func _ready() -> void:
	_build_fade()
	ProgressTracker.achievement_unlocked.connect(_show_achievement)

# ─── Navigation API ───────────────────────────────

func go_boot() -> void:           _load("boot")
func go_main_menu() -> void:      _load("main_menu")
func go_codemon_intro() -> void:   _load("codemon_intro")
func go_intro_world() -> void:     _load("intro_world")
func go_char_create() -> void:    _load("char_create")
func go_ss_intro() -> void:       _load("ss_intro")
func go_auth_screen() -> void:    _load("auth_screen")
func go_name_entry() -> void:     _load("name_entry")
func go_world_map() -> void:      _load("world_map")
func go_progress_screen() -> void: _load("progress")
func go_settings() -> void:       _load("settings")
func go_credits() -> void:        _load("credits")
func go_char_select() -> void:     _load("char_select")
func go_leaderboard() -> void:     OS.shell_open("https://your-project.github.io/leaderboard.html")

func go_chapter(chapter: int) -> void:
	ProgressTracker.start_chapter_session(chapter)
	_load("ch%d" % chapter)

func go_cutscene(id: String, after: Callable) -> void:
	_after_cutscene = after
	_load("cutscene", { "cutscene_id": id })

func cutscene_finished() -> void:
	var cb: Callable = _after_cutscene
	_after_cutscene = func(): pass
	cb.call()

func go_level_complete(params: Dictionary) -> void:
	_load("level_complete", params)

func go_game_over(chapter: int) -> void:
	_load("game_over", { "chapter": chapter })

func start_chapter(chapter: int) -> void:
	if not ProgressTracker.is_chapter_unlocked(chapter):
		return
	var open_id: String = "ch%d_open" % chapter
	if not ProgressTracker.cutscene_seen(open_id):
		go_cutscene(open_id, func(): go_chapter(chapter))
	else:
		go_chapter(chapter)

func chapter_complete(chapter: int, score: int, wrong: int) -> void:
	ProgressTracker.complete_chapter(chapter, score)
	# Sync to Firebase
	FirebaseManager.save_progress(chapter, 0, score, wrong == 0)
	var params: Dictionary = {
		"chapter":  chapter,
		"score":    score,
		"wrong":    wrong,
		"perfect":  wrong == 0,
		"has_next": chapter < 5,
	}
	go_level_complete(params)

func proceed_after_chapter(chapter: int) -> void:
	var close_id: String = "ch%d_close" % chapter
	if not ProgressTracker.cutscene_seen(close_id):
		ProgressTracker.mark_cutscene_seen(close_id)
		if chapter >= 5:
			go_cutscene(close_id, func():
				go_cutscene("ending", func(): go_credits()))
		else:
			go_cutscene(close_id, func(): go_world_map())
	else:
		go_world_map()

# ─── Internal ─────────────────────────────────────

func _load(key: String, params: Dictionary = {}) -> void:
	if not SCENES.has(key):
		push_error("GameRouter: unknown scene '%s'" % key)
		return
	current_scene_key = key
	_pending_params   = params
	emit_signal("scene_changed", key)

	var bgm: String = BGM_MAP.get(key, "") as String
	if bgm != "":
		AudioManager.play_bgm(bgm)

	_fade_out(func():
		var packed: PackedScene = load(SCENES[key])
		get_tree().change_scene_to_packed(packed)
		_fade_in()
		if not params.is_empty():
			_deliver_params.call_deferred(params)
	)

func _deliver_params(params: Dictionary) -> void:
	await get_tree().process_frame
	var scene: Node = get_tree().current_scene
	if is_instance_valid(scene) and scene.has_method("receive_params"):
		scene.receive_params(params)

func _build_fade() -> void:
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0,0,0,1)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.z_index     = 1000
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)
	# Start faded in then fade out on first load
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color", Color(0,0,0,0), 0.5)

func _fade_out(then: Callable) -> void:
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color", Color(0,0,0,1), 0.25)
	tw.tween_callback(then)

func _fade_in() -> void:
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color", Color(0,0,0,0), 0.25)

func _show_achievement(id: String) -> void:
	# Overlay achievement popup without changing scene
	var popup: PackedScene = load(SCENES["achievement"])
	var node: Node = popup.instantiate()
	if node.has_method("show_achievement"):
		node.show_achievement(id)
	get_tree().current_scene.add_child(node)
