extends Node
# ═══════════════════════════════════════════════════
# ProgressTracker.gd  —  AUTOLOAD SINGLETON
#
# Tracks EVERYTHING about player progress:
#   - Which chapters are unlocked / complete
#   - Per-level stats (score, time, wrong picks, perfect)
#   - Overall stats (total score, playtime, streaks)
#   - DSA mastery per topic
#   - Achievements
#
# All other scripts read from / write to this.
# Persists via SaveManager.
# ═══════════════════════════════════════════════════

signal progress_updated
signal achievement_unlocked(id: String)
signal chapter_unlocked(chapter: int)
signal chapter_completed(chapter: int)
signal dsa_mastered(topic: String)

# ─── Constants ────────────────────────────────────

const CHAPTERS: int = 5

const DSA_TOPICS: Array = [
	"queue", "stack", "linked_list", "tree", "graph"
]

const CHAPTER_DSA: Dictionary = {
	1: "queue",
	2: "stack",
	3: "linked_list",
	4: "tree",
	5: "graph",
}

const CHAPTER_NAMES: Dictionary = {
	1: "Kingdom Queue",
	2: "Castle of Echoes",
	3: "Chain Train",
	4: "Oracle's Forest",
	5: "Kingdom Roads",
}

const LEVELS_PER_CHAPTER: Dictionary = {
	1: 5, 2: 5, 3: 5, 4: 6, 5: 5
}

# Mastery thresholds
const MASTERY_MIN_SCORE:    int   = 800
const MASTERY_MAX_WRONG:    int   = 2
const MASTERY_PERFECT_REQ:  int   = 1   # at least 1 perfect level in chapter

# ─── Runtime State ────────────────────────────────

# All data lives here and is synced to SaveManager
var _data: Dictionary = {}

# Current session tracking
var _session_start: float  = 0.0
var _level_start:   float  = 0.0
var _current_ch:    int    = 0
var _current_lvl:   int    = 0

# ─── Init ─────────────────────────────────────────

func _ready() -> void:
	_load()
	_session_start = Time.get_ticks_msec() / 1000.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save()

# ─── Data Loading/Saving ──────────────────────────

func _load() -> void:
	_data = SaveManager.load_progress()
	if _data.is_empty():
		_data = _default_data()

func _save() -> void:
	var elapsed: float = Time.get_ticks_msec() / 1000.0 - _session_start
	_data["stats"]["total_playtime_sec"] = \
		(_data["stats"].get("total_playtime_sec", 0) as float) + elapsed
	_session_start = Time.get_ticks_msec() / 1000.0
	SaveManager.save_progress(_data)
	emit_signal("progress_updated")

func _default_data() -> Dictionary:
	var d: Dictionary = {
		"player": {
			"name":       "",
			"id":         SaveManager.get_player_id(),
			"created_at": Time.get_unix_time_from_system(),
		},
		"chapters": {},
		"stats": {
			"total_score":        0,
			"total_playtime_sec": 0,
			"total_wrong_picks":  0,
			"perfect_clears":     0,
			"chapters_complete":  0,
			"levels_complete":    0,
			"login_streak":       0,
			"last_login_date":    "",
		},
		"dsa_mastery": {},
		"achievements": {},
		"cutscenes_seen": [],
	}
	# Initialize per-chapter structure
	for ch_i in range(1, CHAPTERS + 1):
		d["chapters"][str(ch_i)] = _default_chapter(ch_i)
	# Initialize DSA mastery
	for topic in DSA_TOPICS:
		d["dsa_mastery"][topic] = {
			"mastered":    false,
			"attempts":    0,
			"best_score":  0,
			"avg_wrong":   0,
		}
	return d

func _default_chapter(ch: int) -> Dictionary:
	var lvl_count: int = LEVELS_PER_CHAPTER.get(ch, 5) as int
	var levels: Dictionary = {}
	for i in range(1, lvl_count + 1):
		levels[str(i)] = {
			"complete":    false,
			"best_score":  0,
			"best_time":   0,
			"wrong_picks": -1,
			"perfect":     false,
			"attempts":    0,
		}
	return {
		"unlocked":       ch == 1,
		"complete":       false,
		"best_score":     0,
		"total_time_sec": 0,
		"perfect_clears": 0,
		"attempts":       0,
		"first_clear_at": 0,
		"levels":         levels,
	}

# ─── Session Control ──────────────────────────────

func start_chapter_session(chapter: int) -> void:
	_current_ch  = chapter
	_current_lvl = 0
	var ch_key: String = str(chapter)
	_data["chapters"][ch_key]["attempts"] = \
		(_data["chapters"][ch_key].get("attempts", 0) as int) + 1
	_save()

func start_level(chapter: int, level: int) -> void:
	_current_ch  = chapter
	_current_lvl = level
	_level_start = Time.get_ticks_msec() / 1000.0
	var lv_data: Dictionary = _get_lv(chapter, level)
	lv_data["attempts"] = (lv_data.get("attempts", 0) as int) + 1
	_save()

func complete_level(chapter: int, level: int, score: int, wrong_picks: int) -> Dictionary:
	var elapsed: float  = (Time.get_ticks_msec() / 1000.0) - _level_start
	var perfect: bool   = (wrong_picks == 0)
	var lv:      Dictionary = _get_lv(chapter, level)

	lv["complete"]   = true
	lv["wrong_picks"]= wrong_picks

	if score > (lv.get("best_score", 0) as int):
		lv["best_score"] = score

	if (lv.get("best_time", 0) as float) == 0 or elapsed < (lv.get("best_time", 0) as float):
		lv["best_time"] = int(elapsed)

	if perfect:
		lv["perfect"] = true

	# Global stats
	_data["stats"]["levels_complete"] = \
		(_data["stats"].get("levels_complete", 0) as int) + 1
	_data["stats"]["total_wrong_picks"] = \
		(_data["stats"].get("total_wrong_picks", 0) as int) + wrong_picks
	if perfect:
		_data["stats"]["perfect_clears"] = \
			(_data["stats"].get("perfect_clears", 0) as int) + 1

	_check_achievements(chapter, level, score, wrong_picks, perfect)
	_save()

	return {
		"elapsed_sec": int(elapsed),
		"perfect":     perfect,
		"new_best":    score > (lv.get("best_score", 0) as int),
	}

func complete_chapter(chapter: int, total_score: int) -> void:
	var ch: Dictionary = _get_ch(chapter)
	var was_first: bool = not (ch.get("complete", false) as bool)

	ch["complete"] = true

	if total_score > (ch.get("best_score", 0) as int):
		ch["best_score"] = total_score

	if was_first:
		ch["first_clear_at"] = int(Time.get_unix_time_from_system())
		_data["stats"]["chapters_complete"] = \
			(_data["stats"].get("chapters_complete", 0) as int) + 1
		_data["stats"]["total_score"] = \
			(_data["stats"].get("total_score", 0) as int) + total_score

		# Unlock next chapter
		if chapter < CHAPTERS:
			var next_ch: Dictionary = _get_ch(chapter + 1)
			if not (next_ch.get("unlocked", false) as bool):
				next_ch["unlocked"] = true
				emit_signal("chapter_unlocked", chapter + 1)

	# Check DSA mastery
	_check_dsa_mastery(chapter, total_score)
	emit_signal("chapter_completed", chapter)
	_check_achievements_chapter(chapter)
	_save()

# ─── DSA Mastery ──────────────────────────────────

func _check_dsa_mastery(chapter: int, score: int) -> void:
	var topic: String  = CHAPTER_DSA.get(chapter, "") as String
	if topic == "": return

	_get_ch(chapter)  # ensure chapter record exists
	var m_data: Dictionary = _data["dsa_mastery"].get(topic, {}) as Dictionary

	m_data["attempts"] = (m_data.get("attempts", 0) as int) + 1

	if score > (m_data.get("best_score", 0) as int):
		m_data["best_score"] = score

	# Calculate average wrong picks across all levels
	var total_wrong: int = 0
	var level_count: int = LEVELS_PER_CHAPTER.get(chapter, 5) as int
	for i in range(1, level_count + 1):
		var lv: Dictionary = _get_lv(chapter, i)
		total_wrong += max(0, lv.get("wrong_picks", 0) as int)
	m_data["avg_wrong"] = total_wrong / max(1, level_count)

	# Check mastery conditions
	var perfect_count: int = 0
	for i in range(1, level_count + 1):
		if (_get_lv(chapter, i).get("perfect", false) as bool):
			perfect_count += 1

	var mastered: bool = (
		score >= MASTERY_MIN_SCORE and
		(m_data.get("avg_wrong", 99) as int) <= MASTERY_MAX_WRONG and
		perfect_count >= MASTERY_PERFECT_REQ
	)
	if mastered and not (m_data.get("mastered", false) as bool):
		m_data["mastered"] = true
		emit_signal("dsa_mastered", topic)

	_data["dsa_mastery"][topic] = m_data

# ─── Achievements ─────────────────────────────────

const ACHIEVEMENTS: Dictionary = {
	"first_blood":   { "name": "First Blood",       "desc": "Complete your first level" },
	"queue_master":  { "name": "Queue Master",       "desc": "Master the Queue chapter" },
	"stack_master":  { "name": "Stack Master",       "desc": "Master the Stack chapter" },
	"list_master":   { "name": "List Master",        "desc": "Master the Linked List chapter" },
	"tree_master":   { "name": "Tree Master",        "desc": "Master the Tree chapter" },
	"graph_master":  { "name": "Graph Master",       "desc": "Master the Graph chapter" },
	"perfectionist": { "name": "Perfectionist",      "desc": "Get a perfect clear on any level" },
	"no_mistakes":   { "name": "Flawless",           "desc": "Complete a chapter with 0 wrong picks" },
	"speedrun":      { "name": "Speed Keeper",       "desc": "Complete a level in under 60 seconds" },
	"all_chapters":  { "name": "Code Keeper",        "desc": "Complete all 5 chapters" },
	"all_mastered":  { "name": "Algorithm Master",   "desc": "Master all 5 DSA topics" },
	"full_score":    { "name": "Maximum Effort",     "desc": "Score over 5000 in one chapter" },
	"streaker":      { "name": "On a Roll",          "desc": "Complete 3 levels in a row perfectly" },
}

func _check_achievements(_chapter: int, _level: int, _score: int,
		_wrong: int, perfect: bool) -> void:
	var stats: Dictionary = _data["stats"] as Dictionary
	if (stats.get("levels_complete", 0) as int) == 1:
		_unlock_achievement("first_blood")
	if perfect:
		_unlock_achievement("perfectionist")
	var elapsed: float = (Time.get_ticks_msec() / 1000.0) - _level_start
	if elapsed < 60.0:
		_unlock_achievement("speedrun")
	# Streak check
	var streak: int = _consecutive_perfect(_chapter)
	if streak >= 3:
		_unlock_achievement("streaker")

func _check_achievements_chapter(chapter: int) -> void:
	var ch: Dictionary = _get_ch(chapter)
	var total_wrong: int = 0
	var level_count: int = LEVELS_PER_CHAPTER.get(chapter, 5) as int
	for i in range(1, level_count + 1):
		total_wrong += max(0, _get_lv(chapter, i).get("wrong_picks", 0) as int)
	if total_wrong == 0:
		_unlock_achievement("no_mistakes")
	if (ch.get("best_score", 0) as int) > 5000:
		_unlock_achievement("full_score")

	# DSA master achievements
	var dsa_keys: Dictionary = {
		1: "queue_master", 2: "stack_master", 3: "list_master",
		4: "tree_master", 5: "graph_master"
	}
	var topic: String = CHAPTER_DSA.get(chapter, "") as String
	if topic != "":
		var m: Dictionary = _data["dsa_mastery"].get(topic, {}) as Dictionary
		if m.get("mastered", false) as bool:
			_unlock_achievement(dsa_keys.get(chapter, "") as String)

	# All chapters done?
	var all_done: bool = true
	for i in range(1, CHAPTERS + 1):
		if not (_get_ch(i).get("complete", false) as bool):
			all_done = false; break
	if all_done: _unlock_achievement("all_chapters")

	# All mastered?
	var all_mastered: bool = true
	for topic2 in DSA_TOPICS:
		var m2: Dictionary = _data["dsa_mastery"].get(topic2, {}) as Dictionary
		if not (m2.get("mastered", false) as bool):
			all_mastered = false; break
	if all_mastered: _unlock_achievement("all_mastered")

func _unlock_achievement(id: String) -> void:
	if id == "" or not ACHIEVEMENTS.has(id): return
	var already: Dictionary = _data["achievements"].get(id, {}) as Dictionary
	if already.get("unlocked", false) as bool: return
	_data["achievements"][id] = {
		"unlocked":    true,
		"unlocked_at": int(Time.get_unix_time_from_system()),
	}
	emit_signal("achievement_unlocked", id)
	_save()

func _consecutive_perfect(chapter: int) -> int:
	var count: int = 0
	var level_count: int = LEVELS_PER_CHAPTER.get(chapter, 5) as int
	for i in range(level_count, 0, -1):
		if _get_lv(chapter, i).get("perfect", false) as bool:
			count += 1
		else:
			break
	return count

# ─── Login Streak ─────────────────────────────────

func update_login_streak() -> void:
	var today: String = Time.get_date_string_from_system()
	var last:  String = _data["stats"].get("last_login_date", "") as String
	if last == today: return
	var streak: int = _data["stats"].get("login_streak", 0) as int
	# Check if yesterday
	var yesterday: Dictionary = Time.get_datetime_dict_from_system()
	yesterday["day"] = yesterday["day"] - 1
	var yest_str: String = "%04d-%02d-%02d" % [
		yesterday["year"], yesterday["month"], yesterday["day"]]
	_data["stats"]["login_streak"] = streak + 1 if last == yest_str else 1
	_data["stats"]["last_login_date"] = today
	_save()

# ─── Public Queries ───────────────────────────────

func is_chapter_unlocked(ch: int) -> bool:
	return _get_ch(ch).get("unlocked", ch == 1) as bool

func is_chapter_complete(ch: int) -> bool:
	return _get_ch(ch).get("complete", false) as bool

func get_chapter_best_score(ch: int) -> int:
	return _get_ch(ch).get("best_score", 0) as int

func get_level_data(ch: int, lv: int) -> Dictionary:
	return _get_lv(ch, lv).duplicate()

func get_chapter_data(ch: int) -> Dictionary:
	return _get_ch(ch).duplicate(true)

func get_all_stats() -> Dictionary:
	return _data["stats"].duplicate()

func get_dsa_mastery(topic: String) -> Dictionary:
	return (_data["dsa_mastery"].get(topic, {}) as Dictionary).duplicate()

func get_achievements() -> Dictionary:
	return _data["achievements"].duplicate(true)

func get_player_name() -> String:
	return _data["player"].get("name", "") as String

func set_player_name(player_name_str: String) -> void:
	_data["player"]["name"] = player_name_str
	_save()

func get_world_map_snapshot() -> Dictionary:
	var snap: Dictionary = {}
	for ch in range(1, CHAPTERS + 1):
		var ch_snap: Dictionary = _get_ch(ch)
		snap[ch] = {
			"unlocked":  ch_snap.get("unlocked", ch == 1),
			"complete":  ch_snap.get("complete", false),
			"best_score":ch_snap.get("best_score", 0),
			"mastered":  _is_ch_mastered(ch),
		}
	return snap

func get_full_summary() -> Dictionary:
	return {
		"player":     _data["player"].duplicate(),
		"stats":      _data["stats"].duplicate(),
		"chapters":   _data["chapters"].duplicate(true),
		"dsa_mastery":_data["dsa_mastery"].duplicate(true),
		"achievements":_data["achievements"].duplicate(true),
	}

func cutscene_seen(id: String) -> bool:
	return id in (_data.get("cutscenes_seen", []) as Array)

func mark_cutscene_seen(id: String) -> void:
	var seen: Array = _data.get("cutscenes_seen", []) as Array
	if not (id in seen):
		seen.append(id)
		_data["cutscenes_seen"] = seen
		_save()

func reset_all() -> void:
	_data = _default_data()
	_save()

# ─── Private helpers ──────────────────────────────

func _get_ch(ch: int) -> Dictionary:
	var key: String = str(ch)
	if not _data["chapters"].has(key):
		_data["chapters"][key] = _default_chapter(ch)
	return _data["chapters"][key] as Dictionary

func _get_lv(ch: int, lv: int) -> Dictionary:
	var ch_data: Dictionary = _get_ch(ch)
	var lv_key:  String     = str(lv)
	if not ch_data["levels"].has(lv_key):
		ch_data["levels"][lv_key] = {
			"complete": false, "best_score": 0,
			"best_time": 0, "wrong_picks": -1,
			"perfect": false, "attempts": 0,
		}
	return ch_data["levels"][lv_key] as Dictionary

func _is_ch_mastered(ch: int) -> bool:
	var topic: String = CHAPTER_DSA.get(ch, "") as String
	if topic == "": return false
	return (_data["dsa_mastery"].get(topic, {}) as Dictionary)\
		.get("mastered", false) as bool
