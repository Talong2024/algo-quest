extends Node

# ═══════════════════════════════════════════════════
# T_BSTManager.gd
# Implements BST, AVL, and Min-Heap in one class.
# Nodes are Dictionaries:
#   { id, value, left_id, right_id, parent_id, height, balance }
# ═══════════════════════════════════════════════════

signal tree_changed(snapshot: Dictionary)

var nodes:    Dictionary = {}   # id -> node dict
var root_id:  int        = -1
var mode:     String     = "bst"   # "bst" | "avl" | "heap"
var heap:     Array      = []      # array-based heap
var _next_id: int        = 0

# ─── Build ───────────────────────────────────────

func build_bst(values: Array) -> void:
	nodes.clear()
	root_id  = -1
	_next_id = 0
	for v in values:
		insert_bst(v as int, false)
	_update_all_heights()
	_emit()

func build_heap(values: Array, is_min: bool = true) -> void:
	heap = values.duplicate()
	_heapify(is_min)
	_emit()

# ─── BST Insert ──────────────────────────────────

func insert_bst(value: int, emit: bool = true) -> int:
	var nid: int = _new_node(value)
	if root_id == -1:
		root_id = nid
	else:
		_bst_insert_rec(root_id, nid, value)
	if mode == "avl":
		root_id = _avl_rebalance(root_id)
	_update_all_heights()
	if emit: _emit()
	return nid

func _bst_insert_rec(cur_id: int, new_id: int, value: int) -> void:
	var cur: Dictionary = nodes[cur_id]
	if value < cur["value"] as int:
		if cur["left_id"] == -1:
			cur["left_id"] = new_id
			nodes[new_id]["parent_id"] = cur_id
		else:
			_bst_insert_rec(cur["left_id"], new_id, value)
	else:
		if cur["right_id"] == -1:
			cur["right_id"] = new_id
			nodes[new_id]["parent_id"] = cur_id
		else:
			_bst_insert_rec(cur["right_id"], new_id, value)

# ─── BST Search ──────────────────────────────────

## Returns ordered list of node ids on path to value (-1 if not found)
func search_path(value: int) -> Array:
	var path: Array = []
	var cur:  int   = root_id
	while cur != -1:
		path.append(cur)
		var v: int = nodes[cur]["value"] as int
		if value == v: break
		elif value < v: cur = nodes[cur]["left_id"]
		else:            cur = nodes[cur]["right_id"]
	return path

func find_node_id(value: int) -> int:
	var path: Array = search_path(value)
	if path.is_empty(): return -1
	var last: int = path[path.size()-1]
	return last if (nodes[last]["value"] as int) == value else -1

# ─── BST Delete ──────────────────────────────────

func delete_bst(node_id: int) -> void:
	if not nodes.has(node_id): return
	root_id = _bst_delete_rec(root_id, nodes[node_id]["value"] as int)
	if mode == "avl" and root_id != -1:
		root_id = _avl_rebalance(root_id)
	_update_all_heights()
	_emit()

func _bst_delete_rec(cur_id: int, value: int) -> int:
	if cur_id == -1: return -1
	var cur: Dictionary = nodes[cur_id]
	var v: int = cur["value"] as int
	if value < v:
		cur["left_id"] = _bst_delete_rec(cur["left_id"], value)
		if cur["left_id"] != -1:
			nodes[cur["left_id"]]["parent_id"] = cur_id
	elif value > v:
		cur["right_id"] = _bst_delete_rec(cur["right_id"], value)
		if cur["right_id"] != -1:
			nodes[cur["right_id"]]["parent_id"] = cur_id
	else:
		# Node to delete found
		if cur["left_id"] == -1:
			var r: int = cur["right_id"]
			nodes.erase(cur_id)
			return r
		elif cur["right_id"] == -1:
			var l: int = cur["left_id"]
			nodes.erase(cur_id)
			return l
		else:
			# Has two children — replace with inorder successor
			var succ_id: int = _min_node(cur["right_id"])
			cur["value"] = nodes[succ_id]["value"]
			cur["right_id"] = _bst_delete_rec(cur["right_id"], nodes[succ_id]["value"] as int)
	return cur_id

func _min_node(nid: int) -> int:
	while nodes[nid]["left_id"] != -1:
		nid = nodes[nid]["left_id"]
	return nid

# ─── Traversals ──────────────────────────────────

func inorder() -> Array:
	var res: Array = []
	_inorder_rec(root_id, res)
	return res

func preorder() -> Array:
	var res: Array = []
	_preorder_rec(root_id, res)
	return res

func postorder() -> Array:
	var res: Array = []
	_postorder_rec(root_id, res)
	return res

func _inorder_rec(nid: int, res: Array) -> void:
	if nid == -1: return
	_inorder_rec(nodes[nid]["left_id"], res)
	res.append(nid)
	_inorder_rec(nodes[nid]["right_id"], res)

func _preorder_rec(nid: int, res: Array) -> void:
	if nid == -1: return
	res.append(nid)
	_preorder_rec(nodes[nid]["left_id"], res)
	_preorder_rec(nodes[nid]["right_id"], res)

func _postorder_rec(nid: int, res: Array) -> void:
	if nid == -1: return
	_postorder_rec(nodes[nid]["left_id"], res)
	_postorder_rec(nodes[nid]["right_id"], res)
	res.append(nid)

# ─── AVL ─────────────────────────────────────────

func _avl_rebalance(nid: int) -> int:
	if nid == -1: return -1
	var n: Dictionary = nodes[nid]
	n["left_id"]  = _avl_rebalance(n["left_id"])
	n["right_id"] = _avl_rebalance(n["right_id"])
	_update_height(nid)
	var bf: int = _balance_factor(nid)
	if bf > 1:
		if _balance_factor(n["left_id"]) < 0:
			n["left_id"] = _rotate_left(n["left_id"])
		return _rotate_right(nid)
	if bf < -1:
		if _balance_factor(n["right_id"]) > 0:
			n["right_id"] = _rotate_right(n["right_id"])
		return _rotate_left(nid)
	return nid

func _rotate_right(y: int) -> int:
	var x:  int = nodes[y]["left_id"]
	var t2: int = nodes[x]["right_id"]
	nodes[x]["right_id"] = y
	nodes[y]["left_id"]  = t2
	nodes[x]["parent_id"] = nodes[y]["parent_id"]
	nodes[y]["parent_id"] = x
	if t2 != -1: nodes[t2]["parent_id"] = y
	_update_height(y)
	_update_height(x)
	return x

func _rotate_left(x: int) -> int:
	var y:  int = nodes[x]["right_id"]
	var t2: int = nodes[y]["left_id"]
	nodes[y]["left_id"]  = x
	nodes[x]["right_id"] = t2
	nodes[y]["parent_id"] = nodes[x]["parent_id"]
	nodes[x]["parent_id"] = y
	if t2 != -1: nodes[t2]["parent_id"] = x
	_update_height(x)
	_update_height(y)
	return y

func _balance_factor(nid: int) -> int:
	if nid == -1: return 0
	return _height(nodes[nid]["left_id"]) - _height(nodes[nid]["right_id"])

func _height(nid: int) -> int:
	return nodes[nid]["height"] if nid != -1 else -1

func _update_height(nid: int) -> void:
	if nid == -1: return
	nodes[nid]["height"]  = 1 + max(_height(nodes[nid]["left_id"]),
		_height(nodes[nid]["right_id"]))
	nodes[nid]["balance"] = _balance_factor(nid)

func _update_all_heights() -> void:
	_update_heights_rec(root_id)

func _update_heights_rec(nid: int) -> void:
	if nid == -1: return
	_update_heights_rec(nodes[nid]["left_id"])
	_update_heights_rec(nodes[nid]["right_id"])
	_update_height(nid)

# ─── Heap ────────────────────────────────────────

func heap_insert(value: int, is_min: bool = true) -> void:
	heap.append(value)
	_bubble_up(heap.size() - 1, is_min)
	_emit()

func heap_extract_root(is_min: bool = true) -> int:
	if heap.is_empty(): return -1
	var root: int = heap[0]
	heap[0] = heap[heap.size()-1]
	heap.pop_back()
	if not heap.is_empty():
		_bubble_down(0, is_min)
	_emit()
	return root

func _heapify(is_min: bool) -> void:
	for i in range(heap.size()/2 - 1, -1, -1):
		_bubble_down(i, is_min)

func _bubble_up(i: int, is_min: bool) -> void:
	while i > 0:
		var parent: int = (i - 1) / 2
		var should_swap: bool = heap[i] < heap[parent] if is_min else heap[i] > heap[parent]
		if should_swap:
			var tmp: int = heap[i]; heap[i] = heap[parent]; heap[parent] = tmp
			i = parent
		else: break

func _bubble_down(i: int, is_min: bool) -> void:
	var n: int = heap.size()
	while true:
		var target: int = i
		var l: int = 2*i+1
		var r: int = 2*i+2
		if l < n:
			var better: bool = heap[l] < heap[target] if is_min else heap[l] > heap[target]
			if better: target = l
		if r < n:
			var better: bool = heap[r] < heap[target] if is_min else heap[r] > heap[target]
			if better: target = r
		if target != i:
			var tmp: int = heap[i]; heap[i] = heap[target]; heap[target] = tmp
			i = target
		else: break

## Bubble-up path for teaching: returns array of indices
func heap_bubble_up_path(start_idx: int, is_min: bool) -> Array:
	var path: Array = [start_idx]
	var i: int = start_idx
	while i > 0:
		var parent: int = (i-1)/2
		var better: bool = heap[i] < heap[parent] if is_min else heap[i] > heap[parent]
		if better: path.append(parent); i = parent
		else: break
	return path

# ─── Helpers ─────────────────────────────────────

func _new_node(value: int) -> int:
	var nid: int = _next_id
	_next_id += 1
	nodes[nid] = {
		"id":        nid,
		"value":     value,
		"left_id":   -1,
		"right_id":  -1,
		"parent_id": -1,
		"height":    0,
		"balance":   0,
	}
	return nid

func get_tree_height() -> int:
	return _height(root_id) + 1 if root_id != -1 else 0

func is_balanced() -> bool:
	return _is_balanced_rec(root_id)

func _is_balanced_rec(nid: int) -> bool:
	if nid == -1: return true
	var bf: int = abs(_balance_factor(nid))
	return bf <= 1 and _is_balanced_rec(nodes[nid]["left_id"]) and \
		_is_balanced_rec(nodes[nid]["right_id"])

func get_snapshot() -> Dictionary:
	return {
		"nodes":    nodes.duplicate(true),
		"root_id":  root_id,
		"mode":     mode,
		"heap":     heap.duplicate(),
		"inorder":  inorder(),
		"height":   get_tree_height(),
		"balanced": is_balanced(),
	}

func _emit() -> void:
	emit_signal("tree_changed", get_snapshot())
