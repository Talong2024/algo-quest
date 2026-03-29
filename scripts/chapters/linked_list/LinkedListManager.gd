extends Node

# ═══════════════════════════════════════════════════
# LL_LinkedListManager.gd
# THE linked list data structure.
# Each node is a Dictionary:
#   { id, value, label, color, next_id, prev_id }
# next_id = -1 means null (tail)
# prev_id = -1 means null (head) — used in doubly linked
# ═══════════════════════════════════════════════════

signal list_changed(snapshot: Array)
signal chain_broken(msg: String)

var nodes:      Dictionary = {}   # id -> node dict
var head_id:    int        = -1
var is_doubly:  bool       = false
var _next_id:   int        = 0

# ─── Core Operations ─────────────────────────────

## Build list from array of values
func build(values: Array, doubly: bool = false) -> void:
	nodes.clear()
	head_id   = -1
	is_doubly = doubly
	_next_id  = 0
	var prev: int = -1
	for i in values.size():
		var nid: int = _next_id
		_next_id += 1
		var colors: Array = [
			Color("#FFD93D"), Color("#6BCB77"), Color("#4D96FF"),
			Color("#FF6B6B"), Color("#C77DFF"), Color("#FF9F43"),
		]
		nodes[nid] = {
			"id":      nid,
			"value":   values[i] as int,
			"label":   str(values[i]),
			"color":   colors[nid % colors.size()],
			"next_id": -1,
			"prev_id": -1,
		}
		if prev >= 0:
			nodes[prev]["next_id"] = nid
			if doubly:
				nodes[nid]["prev_id"] = prev
		else:
			head_id = nid
		prev = nid
	_emit_changed()

## TRAVERSE — returns ordered array of node ids head→tail
func traverse() -> Array:
	var result: Array = []
	var cur: int = head_id
	var visited: Dictionary = {}
	while cur != -1:
		if visited.has(cur):
			break   # cycle guard
		visited[cur] = true
		result.append(cur)
		cur = nodes[cur]["next_id"] if nodes.has(cur) else -1
	return result

## INSERT — insert new node with value after given node id
## pass after_id = -1 to insert at head
func insert(after_id: int, value: int) -> int:
	var nid: int = _next_id
	_next_id += 1
	var colors: Array = [
		Color("#FFD93D"), Color("#6BCB77"), Color("#4D96FF"),
		Color("#FF6B6B"), Color("#C77DFF"), Color("#FF9F43"),
	]
	nodes[nid] = {
		"id":      nid,
		"value":   value,
		"label":   str(value),
		"color":   colors[nid % colors.size()],
		"next_id": -1,
		"prev_id": -1,
	}

	if after_id == -1:
		# Insert at head
		nodes[nid]["next_id"] = head_id
		if is_doubly and head_id != -1:
			nodes[head_id]["prev_id"] = nid
		head_id = nid
	else:
		if not nodes.has(after_id):
			emit_signal("chain_broken", "Node %d not found!" % after_id)
			return -1
		var old_next: int = nodes[after_id]["next_id"]
		nodes[after_id]["next_id"] = nid
		nodes[nid]["next_id"]      = old_next
		nodes[nid]["prev_id"]      = after_id if is_doubly else -1
		if is_doubly and old_next != -1:
			nodes[old_next]["prev_id"] = nid

	_emit_changed()
	return nid

## DELETE — remove node by id, re-link around it
func delete(node_id: int) -> bool:
	if not nodes.has(node_id):
		emit_signal("chain_broken", "Node %d not found!" % node_id)
		return false

	var prev_id: int = _find_prev(node_id)
	var next_id: int = nodes[node_id]["next_id"]

	# Re-link
	if prev_id == -1:
		head_id = next_id   # deleting head
	else:
		nodes[prev_id]["next_id"] = next_id

	if is_doubly and next_id != -1:
		nodes[next_id]["prev_id"] = prev_id

	nodes.erase(node_id)
	_emit_changed()
	return true

## REVERSE — flip all next (and prev) pointers
func reverse() -> void:
	var order: Array = traverse()
	if order.size() <= 1:
		return

	# Flip all next pointers
	for i in order.size():
		var nid: int = order[i]
		nodes[nid]["next_id"] = order[i - 1] if i > 0 else -1
		if is_doubly:
			nodes[nid]["prev_id"] = order[i + 1] if i < order.size() - 1 else -1

	head_id = order[order.size() - 1]
	_emit_changed()

## GET TAIL id
func get_tail_id() -> int:
	var order: Array = traverse()
	return order[order.size() - 1] if not order.is_empty() else -1

## GET ordered snapshot for UI
func get_snapshot() -> Array:
	var result: Array = []
	for nid in traverse():
		result.append(nodes[nid].duplicate())
	return result

## SIZE
func size() -> int:
	return traverse().size()

# ─── Helpers ─────────────────────────────────────

func _find_prev(node_id: int) -> int:
	if is_doubly and nodes.has(node_id):
		return nodes[node_id]["prev_id"]
	var cur: int = head_id
	while cur != -1:
		if nodes.has(cur) and nodes[cur]["next_id"] == node_id:
			return cur
		cur = nodes[cur]["next_id"] if nodes.has(cur) else -1
	return -1

func _emit_changed() -> void:
	emit_signal("list_changed", get_snapshot())
