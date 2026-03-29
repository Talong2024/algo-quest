extends Node

# ═══════════════════════════════════════════════════
# S_SpellCaster.gd
# Controls PUSH phase (auto) and POP phase (player).
# Validates LIFO order. Emits signals for UI.
# ═══════════════════════════════════════════════════

signal score_changed(v: int)
signal lives_changed(v: int)
signal feedback(msg: String, good: bool)
signal rune_pushed(rune: Dictionary)
signal rune_popped(rune: Dictionary)
signal push_phase_complete
signal door_unlocked(count: int)
signal level_complete
signal game_over

const MAX_LIVES:         int   = 3
const POINTS_PER_POP:   int   = 150
const PERFECT_BONUS:    int   = 300
const PUSH_INTERVAL:    float = 1.2

var score:      int    = 0
var lives:      int    = MAX_LIVES
var phase:      String = "push"
var active:     bool   = false
var wrong_pops: int    = 0
var pops_done:  int    = 0

var _runes:     Array  = []
var _push_idx:  int    = 0
var _push_timer: Timer
var _stack_ref: Node

func init(sm: Node) -> void:
	_stack_ref = sm
	_push_timer = Timer.new()
	_push_timer.timeout.connect(_push_next)
	add_child(_push_timer)
	_stack_ref.stack_overflow.connect(_on_overflow)

func start_level(runes: Array, stack_max: int) -> void:
	_runes       = runes
	_push_idx    = 0
	pops_done    = 0
	wrong_pops   = 0
	phase        = "push"
	active       = true
	_stack_ref.max_size = stack_max
	_stack_ref.clear()
	_push_timer.start(PUSH_INTERVAL)

func reset_stats() -> void:
	score  = 0
	lives  = MAX_LIVES
	active = false
	_push_timer.stop()
	emit_signal("score_changed", score)
	emit_signal("lives_changed", lives)

# ─── PUSH phase (automatic) ──────────────────────

func _push_next() -> void:
	if _push_idx >= _runes.size():
		_push_timer.stop()
		phase = "pop"
		emit_signal("push_phase_complete")
		emit_signal("feedback",
			"Stack ready! Click the TOP rune to pop — LIFO order!", true)
		return
	var rune: Dictionary = _runes[_push_idx]
	_stack_ref.push(rune)
	emit_signal("rune_pushed", rune)
	emit_signal("feedback",
		"PUSH: %s %s → now on TOP" % [rune["symbol"], rune["name"]], true)
	_push_idx += 1

# ─── POP phase (player) ──────────────────────────

func player_pops(rune_id: int) -> void:
	if not active or phase != "pop": return

	if _stack_ref.is_correct_pop(rune_id):
		var r: Dictionary = _stack_ref.pop()
		pops_done += 1
		score += POINTS_PER_POP
		emit_signal("score_changed", score)
		emit_signal("rune_popped", r)
		emit_signal("door_unlocked", pops_done)
		emit_signal("feedback",
			"✓ Correct POP! %s %s removed — LIFO! +%d pts" % [
				r["symbol"], r["name"], POINTS_PER_POP], true)
		if pops_done >= _runes.size():
			_finish_level()
	else:
		var top: Dictionary = _stack_ref.peek()
		wrong_pops += 1
		_lose_life("✗ Wrong! %s %s is on TOP — pop it first! (LIFO)" % [
			top.get("symbol","?"), top.get("name","?")])

func _on_overflow() -> void:
	_lose_life("✗ Stack overflow! Too many runes stacked!")

func _lose_life(msg: String) -> void:
	lives -= 1
	emit_signal("lives_changed", lives)
	emit_signal("feedback", msg, false)
	if lives <= 0:
		active = false
		_push_timer.stop()
		emit_signal("game_over")

func _finish_level() -> void:
	active = false
	_push_timer.stop()
	if wrong_pops == 0:
		score += PERFECT_BONUS
		emit_signal("score_changed", score)
	emit_signal("level_complete")
