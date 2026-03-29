extends Node

# ═══════════════════════════════════════════════════
# T_GameLogic.gd
# Validates player actions for each operation.
# Tracks score, lives, mistakes.
# ═══════════════════════════════════════════════════

signal score_changed(v: int)
signal lives_changed(v: int)
signal feedback(msg: String, good: bool)
signal highlight_path(ids: Array, found_id: int, wrong_id: int)
signal level_complete
signal game_over
signal request_redraw

const MAX_LIVES:      int = 3
const POINTS_STEP:    int = 150
const POINTS_PERFECT: int = 300

var score:     int    = 0
var lives:     int    = MAX_LIVES
var active:    bool   = false
var operation: String = "search"
var _mistakes: int    = 0

# Operation state
var _search_target:    int   = -1
var _search_path:      Array = []
var _search_idx:       int   = 0

var _traverse_order:   Array = []
var _traverse_idx:     int   = 0
var _traverse_type:    String = "inorder"

var _insert_value:     int   = -1
var _insert_path:      Array = []
var _insert_idx:       int   = 0
var _insert_done:      bool  = false

var _delete_target_id: int   = -1
var _delete_done:      bool  = false

var _avl_rotation_needed: String = ""
var _avl_unbalanced_id:   int    = -1
var _avl_done:            bool   = false

var _heap_insert_value:   int    = -1
var _heap_bubble_path:    Array  = []
var _heap_bubble_idx:     int    = 0
var _heap_is_min:         bool   = true

var _bst_ref: Node

func init(bst: Node) -> void:
	_bst_ref = bst

func reset_stats() -> void:
	score  = 0
	lives  = MAX_LIVES
	active = false
	_mistakes = 0
	emit_signal("score_changed", score)
	emit_signal("lives_changed", lives)

func start_search(target: int) -> void:
	operation      = "search"
	_search_target = target
	_search_path   = _bst_ref.search_path(target)
	_search_idx    = 0
	active         = true
	emit_signal("feedback",
		"SEARCH: Find value %d — click nodes going left if smaller, right if larger!" % target,
		true)
	emit_signal("highlight_path", [], -1, -1)

func start_insert(value: int) -> void:
	operation     = "insert"
	_insert_value = value
	_insert_done  = false
	active        = true
	# Pre-calculate correct insert path
	_insert_path = _bst_ref.search_path(value)
	_insert_idx  = 0
	emit_signal("feedback",
		"INSERT: Plant node %d — navigate to the correct empty spot!" % value, true)

func start_traverse(ttype: String) -> void:
	operation        = "traverse"
	_traverse_type   = ttype
	_traverse_idx    = 0
	active           = true
	match ttype:
		"inorder":  _traverse_order = _bst_ref.inorder()
		"preorder": _traverse_order = _bst_ref.preorder()
		"postorder":_traverse_order = _bst_ref.postorder()
	var type_hint: Dictionary = {
		"inorder":  "left → root → right (gives sorted order!)",
		"preorder": "root → left → right",
		"postorder":"left → right → root",
	}
	emit_signal("feedback",
		"TRAVERSAL (%s): %s — click nodes in correct order!" % [ttype, type_hint.get(ttype,"")],
		true)

func start_delete(target_id: int) -> void:
	operation         = "delete"
	_delete_target_id = target_id
	_delete_done      = false
	active            = true
	var val: int = _bst_ref.nodes[target_id]["value"] as int
	emit_signal("feedback",
		"DELETE: Remove node %d — click it to start removal!" % val, true)
	emit_signal("highlight_path", [target_id], -1, -1)

func start_avl(unbalanced_id: int, rotation: String) -> void:
	operation             = "avl"
	_avl_unbalanced_id    = unbalanced_id
	_avl_rotation_needed  = rotation
	_avl_done             = false
	active                = true
	emit_signal("feedback",
		"AVL ROTATION: Tree is unbalanced! Click the unbalanced node to rotate (%s)." % rotation,
		true)
	emit_signal("highlight_path", [unbalanced_id], -1, -1)

func start_heap(value: int, is_min: bool) -> void:
	operation          = "heap"
	_heap_insert_value = value
	_heap_is_min       = is_min
	_bst_ref.heap_insert(value, is_min)
	_heap_bubble_path  = _bst_ref.heap_bubble_up_path(
		_bst_ref.heap.size()-1, is_min)
	_heap_bubble_idx   = 0
	active             = true
	var htype: String  = "Min-Heap" if is_min else "Max-Heap"
	emit_signal("feedback",
		"%s INSERT %d: click nodes in bubble-up order!" % [htype, value], true)

# ─── Player Actions ───────────────────────────────

func player_clicks_node(node_id: int) -> void:
	if not active: return
	match operation:
		"search":   _handle_search(node_id)
		"traverse": _handle_traverse(node_id)
		"delete":   _handle_delete(node_id)
		"avl":      _handle_avl(node_id)
		"insert":   _handle_insert_navigate(node_id)

func player_clicks_insert_spot(after_id: int, side: String) -> void:
	if not active or operation != "insert": return
	# Check if this is the correct spot
	var correct_parent_id: int = -1
	var correct_side:      String = ""
	if not _insert_path.is_empty():
		var last_id: int = _insert_path[_insert_path.size()-1]
		var last_val: int = _bst_ref.nodes[last_id]["value"] as int
		correct_parent_id = last_id
		correct_side = "left" if _insert_value < last_val else "right"

	if after_id == correct_parent_id and side == correct_side:
		_bst_ref.insert_bst(_insert_value)
		score += POINTS_STEP * (_insert_path.size())
		emit_signal("score_changed", score)
		emit_signal("feedback",
			"✓ Correct! Node %d inserted as %s child of %d!" % [
				_insert_value, side, _bst_ref.nodes[correct_parent_id]["value"]], true)
		_finish_operation()
	else:
		_wrong("✗ Wrong spot! Follow BST rule: left if smaller, right if larger.")

func player_clicks_heap_node(heap_idx: int) -> void:
	if not active or operation != "heap": return
	if _heap_bubble_idx >= _heap_bubble_path.size():
		return
	var expected: int = _heap_bubble_path[_heap_bubble_idx]
	if heap_idx == expected:
		_heap_bubble_idx += 1
		score += POINTS_STEP
		emit_signal("score_changed", score)
		emit_signal("feedback",
			"✓ Correct bubble-up step! [%d] ← value moves up" % heap_idx, true)
		if _heap_bubble_idx >= _heap_bubble_path.size():
			_finish_operation()
	else:
		_wrong("✗ Wrong! Bubble-up goes to parent: [%d]→[%d]" % [
			_heap_bubble_path[_heap_bubble_idx],
			(_heap_bubble_path[_heap_bubble_idx]-1)/2])

# ─── Operation handlers ───────────────────────────

func _handle_search(node_id: int) -> void:
	if _search_idx >= _search_path.size(): return
	var expected: int = _search_path[_search_idx]
	if node_id == expected:
		_search_idx += 1
		score += POINTS_STEP
		emit_signal("score_changed", score)
		var val: int = _bst_ref.nodes[node_id]["value"] as int
		var is_found: bool = (val == _search_target)
		emit_signal("highlight_path",
			_search_path.slice(0, _search_idx),
			node_id if is_found else -1, -1)
		if is_found:
			emit_signal("feedback",
				"★ FOUND %d! Search took %d comparisons — O(log n) on balanced tree!" % [
					_search_target, _search_idx], true)
			_finish_operation()
		else:
			var dir: String = "left" if _search_target < val else "right"
			emit_signal("feedback",
				"✓ %d: target %d %s%d → go %s!" % [
					val, _search_target,
					"<" if dir=="right" else ">", val, dir], true)
	else:
		emit_signal("highlight_path",
			_search_path.slice(0, _search_idx), -1, node_id)
		_wrong("✗ Wrong node! Go %s from current — target %d %s node value." % [
			"left" if _search_target < (_bst_ref.nodes[_search_path[_search_idx]]["value"] as int)
			else "right", _search_target,
			"<" if _search_target < (_bst_ref.nodes[_search_path[_search_idx]]["value"] as int)
			else ">"])

func _handle_traverse(node_id: int) -> void:
	if _traverse_idx >= _traverse_order.size(): return
	var expected: int = _traverse_order[_traverse_idx]
	if node_id == expected:
		_traverse_idx += 1
		score += POINTS_STEP
		emit_signal("score_changed", score)
		emit_signal("highlight_path",
			_traverse_order.slice(0, _traverse_idx), -1, -1)
		emit_signal("feedback",
			"✓ Node %d — %s step %d/%d!" % [
				_bst_ref.nodes[node_id]["value"],
				_traverse_type, _traverse_idx,
				_traverse_order.size()], true)
		if _traverse_idx >= _traverse_order.size():
			_finish_operation()
	else:
		emit_signal("highlight_path",
			_traverse_order.slice(0, _traverse_idx), -1, node_id)
		_wrong("✗ Wrong! %s visits node %d next." % [
			_traverse_type,
			_bst_ref.nodes[expected]["value"]])

func _handle_delete(node_id: int) -> void:
	if node_id == _delete_target_id:
		_bst_ref.delete_bst(node_id)
		score += POINTS_STEP * 2
		emit_signal("score_changed", score)
		emit_signal("feedback",
			"✓ Deleted! Inorder successor re-linked the tree automatically.", true)
		_finish_operation()
	else:
		_wrong("✗ Click the highlighted node to delete it!")

func _handle_avl(node_id: int) -> void:
	if node_id == _avl_unbalanced_id:
		_bst_ref.mode = "avl"
		_bst_ref._update_all_heights()
		_bst_ref.root_id = _bst_ref._avl_rebalance(_bst_ref.root_id)
		_bst_ref._update_all_heights()
		_bst_ref._emit()
		score += POINTS_STEP * 2
		emit_signal("score_changed", score)
		emit_signal("feedback",
			"✓ Rotated! Tree is now balanced — height reduced, O(log n) restored!", true)
		_finish_operation()
	else:
		_wrong("✗ Click the orange unbalanced node (|balance| > 1)!")

func _handle_insert_navigate(node_id: int) -> void:
	if _insert_idx >= _insert_path.size(): return
	var expected: int = _insert_path[_insert_idx]
	if node_id == expected:
		_insert_idx += 1
		score += POINTS_STEP
		emit_signal("score_changed", score)
		var val: int   = _bst_ref.nodes[node_id]["value"] as int
		var dir: String = "left" if _insert_value < val else "right"
		emit_signal("feedback",
			"✓ %d: %d goes %s → keep going!" % [val, _insert_value, dir], true)
		if _insert_idx >= _insert_path.size():
			# At correct parent — now click the gap
			var parent: Dictionary = _bst_ref.nodes[expected]
			var side: String = "left" if _insert_value < (parent["value"] as int) else "right"
			emit_signal("feedback",
				"Now click the %s gap next to node %d to plant the new node!" % [
					side, parent["value"]], true)
	else:
		_wrong("✗ Wrong! Use BST rule: go left if %d < node value, right if larger." % _insert_value)

func _finish_operation() -> void:
	active = false
	if _mistakes == 0:
		score += POINTS_PERFECT
		emit_signal("score_changed", score)
	emit_signal("level_complete")

func _wrong(msg: String) -> void:
	_mistakes += 1
	lives -= 1
	emit_signal("lives_changed", lives)
	emit_signal("feedback", msg, false)
	if lives <= 0:
		active = false
		emit_signal("game_over")
