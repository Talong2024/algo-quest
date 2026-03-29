extends Node
# ═══════════════════════════════════════════════════
# ScoreTracker.gd  —  AUTOLOAD SINGLETON
# Tracks the current chapter session's running score.
# Feeds into ProgressTracker and FirebaseManager.
# ═══════════════════════════════════════════════════

var chapter:    int   = 0
var score:      int   = 0
var wrong:      int   = 0
var start_time: float = 0.0

func begin(ch: int) -> void:
	chapter    = ch
	score      = 0
	wrong      = 0
	start_time = Time.get_ticks_msec() / 1000.0

func add_score(pts: int) -> void:
	score += pts

func add_wrong() -> void:
	wrong += 1

func elapsed_sec() -> int:
	return int(Time.get_ticks_msec() / 1000.0 - start_time)

func is_perfect() -> bool:
	return wrong == 0

func get_payload() -> Dictionary:
	return {
		"chapter":    chapter,
		"score":      score,
		"wrong":      wrong,
		"time_sec":   elapsed_sec(),
		"perfect":    is_perfect(),
	}
