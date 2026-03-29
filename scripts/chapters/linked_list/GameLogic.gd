extends Node

# ═══════════════════════════════════════════════════
# LL_GameLogic.gd
# Validates player actions per operation type.
# Each level has a target operation and goal.
# Emits feedback and score changes.
# ═══════════════════════════════════════════════════

signal score_changed(v: int)
signal lives_changed(v: int)
signal feedback(msg: String, good: bool)
signal operation_complete
signal level_complete
signal game_over

const MAX_LIVES:         int = 3
const POINTS_CORRECT:    int = 200
const POINTS_PERFECT:    int = 400

var score:       int    = 0
var lives:       int    = MAX_LIVES
var active:      bool   = false
var operation:   String = "traverse"

# Traverse state
var _traverse_order:   Array = []   # expected node id order
var _traverse_idx:     int   = 0    # next expected id to visit

# Insert state
var _insert_after_id:  int   = -1   # where to insert
var _insert_value:     int   = 0    # value to insert
var _insert_done:      bool  = false

# Delete state
var _delete_target_id: int   = -1   # which node to delete
var _delete_done:      bool  = false

# Reverse state
var _reverse_expected: Array = []   # expected order after reverse
var _reverse_done:     bool  = false

var _mistakes:         int   = 0
var _ll_ref: Node

func init(ll: Node) -> void:
	_ll_ref = ll

func reset_stats() -> void:
	score  = 0
	lives  = MAX_LIVES
	active = false
	_mistakes = 0
	emit_signal("score_changed", score)
	emit_signal("lives_changed", lives)

func start_level(op: String, cfg: Dictionary) -> void:
	operation = op
	active    = true
	_mistakes = 0

	match op:
		"traverse":
			_traverse_order = _ll_ref.traverse()
			_traverse_idx   = 0
			emit_signal("feedback",
				"TRAVERSE: Click carriages in order HEAD → TAIL following next pointers!", true)

		"insert":
			_insert_after_id = cfg.get("after_id", -1) as int
			_insert_value    = cfg.get("value", 99) as int
			_insert_done     = false
			var after_label: String = "HEAD" if _insert_after_id == -1 else \
				"node %d" % _insert_after_id
			emit_signal("feedback",
				"INSERT: Add a new carriage (value %d) after %s. Click the correct gap!" % [
					_insert_value, after_label], true)

		"delete":
			_delete_target_id = cfg.get("target_id", -1) as int
			_delete_done      = false
			emit_signal("feedback",
				"DELETE: Remove carriage id:%d — click it to uncouple and re-link the chain!" % \
					_delete_target_id, true)

		"reverse":
			_reverse_expected = _ll_ref.traverse()
			_reverse_expected.reverse()
			_reverse_done     = false
			emit_signal("feedback",
				"REVERSE: Flip all couplers! Click REVERSE button to flip all next pointers.", true)

# ─── Player actions ───────────────────────────────

func player_clicks_carriage(node_id: int) -> void:
	if not active: return

	match operation:
		"traverse":
			if _traverse_idx >= _traverse_order.size():
				return
			var expected: int = _traverse_order[_traverse_idx]
			if node_id == expected:
				_traverse_idx += 1
				score += POINTS_CORRECT
				emit_signal("score_changed", score)
				emit_signal("feedback",
					"✓ Correct! node %d visited — following next pointer!" % node_id, true)
				if _traverse_idx >= _traverse_order.size():
					_finish_operation("Traversal complete! Visited all %d nodes." % _traverse_order.size())
			else:
				_wrong("✗ Wrong node! Start from HEAD and follow next pointers in order.")

		"delete":
			if node_id == _delete_target_id:
				_ll_ref.delete(node_id)
				_delete_done = true
				score += POINTS_CORRECT
				emit_signal("score_changed", score)
				emit_signal("feedback",
					"✓ Deleted node %d — chain re-linked! prev.next now points to next node." % node_id,
					true)
				_finish_operation("Delete complete!")
			else:
				_wrong("✗ Wrong carriage! Delete the highlighted one (id:%d)." % _delete_target_id)

func player_clicks_gap(after_id: int) -> void:
	if not active or operation != "insert": return

	if after_id == _insert_after_id:
		var new_id: int = _ll_ref.insert(after_id, _insert_value)
		if new_id >= 0:
			_insert_done = true
			score += POINTS_CORRECT
			emit_signal("score_changed", score)
			emit_signal("feedback",
				"✓ Inserted node (val:%d) — couplers re-linked! O(1) insertion!" % _insert_value,
				true)
			_finish_operation("Insert complete!")
	else:
		_wrong("✗ Wrong gap! Insert after node id:%d." % _insert_after_id)

func player_clicks_reverse() -> void:
	if not active or operation != "reverse": return
	_ll_ref.reverse()
	_reverse_done = true
	score += POINTS_CORRECT
	emit_signal("score_changed", score)
	emit_signal("feedback",
		"✓ Reversed! All next pointers flipped — TAIL became HEAD!", true)
	_finish_operation("Reverse complete!")

func _finish_operation(msg: String) -> void:
	if _mistakes == 0:
		score += POINTS_PERFECT
		emit_signal("score_changed", score)
	active = false
	emit_signal("operation_complete")
	emit_signal("level_complete")

func _wrong(msg: String) -> void:
	_mistakes += 1
	lives -= 1
	emit_signal("lives_changed", lives)
	emit_signal("feedback", msg, false)
	if lives <= 0:
		active = false
		emit_signal("game_over")
