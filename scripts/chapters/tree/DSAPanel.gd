extends Node2D

var visible_panel: bool     = false
var _snapshot:     Dictionary = {}
var _operation:    String   = "search"

const PX: float = 60.0
const PY: float = 60.0
const PW: float = 1160.0
const PH: float = 580.0

func toggle() -> void:
	visible_panel = !visible_panel
	queue_redraw()

func update(snapshot: Dictionary, operation: String) -> void:
	_snapshot  = snapshot
	_operation = operation
	if visible_panel: queue_redraw()

func _draw() -> void:
	if not visible_panel: return
	_draw_bg()
	_draw_title()
	_draw_tree_ascii()
	_draw_stats()
	_draw_code()
	_draw_hint()

func _draw_bg() -> void:
	draw_rect(Rect2(0,0,1280,720), Color(0,0,0,0.88))
	draw_rect(Rect2(PX,PY,PW,PH), Color("#060e04"))
	draw_rect(Rect2(PX,PY,PW,PH), Color("#2a4a15"), false, 1.0)

func _draw_title() -> void:
	var mode: String = _snapshot.get("mode","bst") as String
	var titles: Dictionary = {
		"bst":  "BINARY SEARCH TREE",
		"avl":  "AVL TREE (self-balancing)",
		"heap": "HEAP (priority queue)",
	}
	var op_labels: Dictionary = {
		"search":   "SEARCH — navigate left/right to find value",
		"insert":   "INSERT — plant node in correct BST position",
		"delete":   "DELETE — remove node, re-link with successor",
		"traverse": "TRAVERSAL — visit all nodes in defined order",
		"avl":      "AVL ROTATION — restore balance after insert",
		"heap":     "HEAP INSERT — bubble-up to restore heap property",
	}
	draw_string(ThemeDB.fallback_font,
		Vector2(PX+20, PY+28),
		"%s  —  %s" % [titles.get(mode,"BST"), op_labels.get(_operation,"")],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#6BCB77"))
	draw_string(ThemeDB.fallback_font,
		Vector2(PX+20, PY+50),
		"BST rule: all LEFT children < node < all RIGHT children  |  left → smaller  |  right → larger",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#334420"))

func _draw_tree_ascii() -> void:
	var nodes:   Dictionary = _snapshot.get("nodes", {})
	var root_id: int        = _snapshot.get("root_id", -1)
	var heap:    Array      = _snapshot.get("heap", [])

	if _snapshot.get("mode","bst") == "heap":
		# Show heap as array
		draw_string(ThemeDB.fallback_font,
			Vector2(PX+20, PY+80), "Heap array (index → value):",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#334420"))
		for i in heap.size():
			var hx: float = PX + 20 + i * 70
			draw_rect(Rect2(hx, PY+96, 62, 36), Color("#0a1a04"))
			draw_rect(Rect2(hx, PY+96, 62, 36), Color("#2a4a15"), false, 1.0)
			draw_string(ThemeDB.fallback_font, Vector2(hx+4, PY+108),
				"[%d]" % i, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#334420"))
			draw_string(ThemeDB.fallback_font, Vector2(hx+8, PY+124),
				str(heap[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#6BCB77"))
		draw_string(ThemeDB.fallback_font,
			Vector2(PX+20, PY+148),
			"Parent of [i] = [(i-1)/2]  |  Left child = [2i+1]  |  Right child = [2i+2]",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#334420"))
	else:
		# Show inorder, preorder, postorder
		var inorder:  Array = _snapshot.get("inorder",[])
		var vals: Array = []
		for nid in inorder:
			if nodes.has(nid): vals.append(str(nodes[nid]["value"]))
		draw_string(ThemeDB.fallback_font,
			Vector2(PX+20, PY+80),
			"Inorder (sorted): " + ", ".join(vals) + "  ← BST inorder always gives sorted output!",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#6BCB77"))

		# Show level by level
		if root_id != -1:
			draw_string(ThemeDB.fallback_font,
				Vector2(PX+20, PY+106),
				"Level-order (BFS): " + _level_order_str(root_id, nodes),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#4D96FF"))

func _level_order_str(root: int, nodes: Dictionary) -> String:
	var result: Array = []
	var queue: Array  = [root]
	while not queue.is_empty():
		var nid: int = queue.pop_front()
		if not nodes.has(nid): continue
		result.append(str(nodes[nid]["value"]))
		var l: int = nodes[nid]["left_id"]
		var r: int = nodes[nid]["right_id"]
		if l != -1: queue.append(l)
		if r != -1: queue.append(r)
	return ", ".join(result)

func _draw_stats() -> void:
	var sy: float = PY + 136
	var h:  int   = _snapshot.get("height", 0) as int
	var bal: bool = _snapshot.get("balanced", true) as bool
	var sz:  int  = (_snapshot.get("nodes",{}) as Dictionary).size()

	draw_string(ThemeDB.fallback_font, Vector2(PX+20, sy),
		"nodes: %d   |   height: %d   |   balanced: %s   |   O(search): %s" % [
			sz, h, "✓ yes" if bal else "✗ no",
			"O(log n)" if bal else "O(n) — degraded!"],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
		Color("#6BCB77") if bal else Color("#FF9F43"))

func _draw_code() -> void:
	var cy: float = PY + 165
	draw_rect(Rect2(PX+20, cy, PW-40, 210), Color("#040a02"))

	var code_blocks: Dictionary = {
		"search": [
			["# BST Search — O(log n) balanced, O(n) worst:", Color("#334420")],
			["def search(node, target):", Color("#6BCB77")],
			["    if node is None or node.val == target: return node", Color("#6BCB77")],
			["    if target < node.val: return search(node.left, target)   # go left", Color("#4D96FF")],
			["    else:                return search(node.right, target)  # go right", Color("#FF6B6B")],
		],
		"insert": [
			["# BST Insert — O(log n):", Color("#334420")],
			["def insert(node, val):", Color("#6BCB77")],
			["    if node is None: return Node(val)   # found empty spot!", Color("#6BCB77")],
			["    if val < node.val: node.left  = insert(node.left, val)", Color("#4D96FF")],
			["    else:              node.right = insert(node.right, val)", Color("#FF6B6B")],
		],
		"traverse": [
			["# BST Traversals:", Color("#334420")],
			["def inorder(n):   inorder(n.left); visit(n); inorder(n.right)   # sorted!", Color("#6BCB77")],
			["def preorder(n):  visit(n); preorder(n.left); preorder(n.right) # root first", Color("#4D96FF")],
			["def postorder(n): postorder(n.left); postorder(n.right); visit(n) # root last", Color("#C77DFF")],
		],
		"delete": [
			["# BST Delete — 3 cases:", Color("#334420")],
			["# Case 1: leaf → just remove", Color("#6BCB77")],
			["# Case 2: one child → replace with child", Color("#6BCB77")],
			["# Case 3: two children → replace with inorder successor (min of right subtree)", Color("#FFD93D")],
			["successor = find_min(node.right)   # smallest in right subtree", Color("#FFD93D")],
		],
		"avl": [
			["# AVL Rotation — restore balance when |bf| > 1:", Color("#334420")],
			["bf = height(left) - height(right)   # balance factor", Color("#FF9F43")],
			["if bf > 1:  rotate_right(node)   # left-heavy", Color("#6BCB77")],
			["if bf < -1: rotate_left(node)    # right-heavy", Color("#FF6B6B")],
			["# LL→right rotate  LR→left-right  RL→right-left  RR→left rotate", Color("#334420")],
		],
		"heap": [
			["# Heap insert + bubble-up:", Color("#334420")],
			["heap.append(value)   # add at end", Color("#6BCB77")],
			["i = len(heap) - 1", Color("#6BCB77")],
			["while i > 0 and heap[i] < heap[(i-1)//2]:   # min-heap", Color("#FFD93D")],
			["    swap(heap[i], heap[(i-1)//2]); i = (i-1)//2   # bubble up!", Color("#FFD93D")],
		],
	}

	var lines: Array = code_blocks.get(_operation, code_blocks["search"])
	for i in lines.size():
		draw_string(ThemeDB.fallback_font,
			Vector2(PX+36, cy + 22 + i*36),
			lines[i][0] as String,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
			lines[i][1] as Color)

func _draw_hint() -> void:
	draw_string(ThemeDB.fallback_font,
		Vector2(PX+PW-180, PY+22),
		"Press Q to close",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#334420"))
