extends Node2D

signal next_requested
signal retry_requested
signal menu_requested

func setup(cfg: Dictionary, score: int, win: bool, has_next: bool) -> void:
	_build(cfg, score, win, has_next)

func _build(cfg: Dictionary, score: int, win: bool, has_next: bool) -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0d1a08")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := ColorRect.new()
	panel.color = Color("#080f04")
	panel.set_position(Vector2(240,80)); panel.set_size(Vector2(800,560))
	add_child(panel)

	_lbl("Level %d Clear!" % cfg.get("level",1) if win else "Lost in the Forest!",
		Vector2(290,110), 34,
		Color("#6BCB77") if win else Color("#FF6B6B"))

	_lbl("Score: %d" % score, Vector2(560,170), 22, Color("#FFD93D"))

	var rb := ColorRect.new()
	rb.color = Color("#040a02"); rb.set_position(Vector2(260,215)); rb.set_size(Vector2(760,160))
	add_child(rb)

	_lbl("What you learned:", Vector2(276,227), 14, Color("#4D96FF"))

	var recap := Label.new()
	recap.set_position(Vector2(276,250)); recap.set_custom_minimum_size(Vector2(720,110))
	recap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recap.add_theme_font_size_override("font_size", 13)
	recap.add_theme_color_override("font_color", Color("#aaaaaa"))
	recap.text = _get_recap(cfg.get("level",1) as int,
		cfg.get("operation","search") as String, win)
	add_child(recap)

	var cb := ColorRect.new()
	cb.color = Color("#020601"); cb.set_position(Vector2(260,385)); cb.set_size(Vector2(760,80))
	add_child(cb)

	var code := Label.new()
	code.set_position(Vector2(276,397))
	code.add_theme_font_size_override("font_size", 12)
	code.add_theme_color_override("font_color", Color("#6BCB77"))
	code.text = _get_code(cfg.get("operation","search") as String)
	add_child(code)

	if win and has_next:
		_btn("Next Level ▶", Vector2(740,490), Color("#6BCB77"),
			func(): emit_signal("next_requested"))
	elif win:
		_btn("🏆 Oracle Master!", Vector2(720,490), Color("#FFD93D"),
			func(): emit_signal("menu_requested"))
	else:
		_btn("↺ Retry", Vector2(640,490), Color("#FF6B6B"),
			func(): emit_signal("retry_requested"))
	_btn("Menu", Vector2(260,490), Color("#556640"),
		func(): emit_signal("menu_requested"))

func _get_recap(level: int, op: String, win: bool) -> String:
	if not win:
		return "You got lost in the forest! Remember the BST rule:\nleft children are ALWAYS smaller, right children are ALWAYS larger.\nUse this rule to navigate every step."
	match op:
		"search":  return "BST Search: O(log n) on balanced tree — halves the search space each step.\nWrong direction = wasted comparison. Real world: binary search, database indexes.\nAn unbalanced BST degrades to O(n) — same as linear search!"
		"insert":  return "BST Insert: navigate using BST rules until you find an empty spot — O(log n).\nOrder of insertion matters! Same values in different order = different tree shape.\nReal world: maintaining sorted order while allowing fast insertion."
		"traverse":return "Inorder traversal ALWAYS gives sorted output from a BST — O(n).\nPreorder useful for copying/serializing trees. Postorder for deletion.\nReal world: expression trees, file system traversal, compiler ASTs."
		"delete":  return "BST Delete with two children: replace with INORDER SUCCESSOR (min of right subtree).\nThis maintains BST property while keeping the tree connected.\nReal world: removing elements from priority queues, database record deletion."
		"avl":     return "AVL tree: guarantees O(log n) by keeping |balance factor| ≤ 1 at every node.\nRotations are O(1) — just pointer changes. At most 2 rotations per insert.\nReal world: Linux kernel scheduler, database indexes, Java TreeMap."
		"heap":    return "Heap: complete binary tree with heap property. Insert = O(log n) bubble-up.\nRoot always contains min (min-heap) or max (max-heap).\nReal world: priority queues, Dijkstra's algorithm, heap sort, OS schedulers."
		_: return "All tree concepts mastered!"

func _get_code(op: String) -> String:
	match op:
		"search":  return "O(log n): while cur: if target==cur.val: FOUND\n    elif target < cur.val: cur=cur.left else: cur=cur.right"
		"insert":  return "Navigate to empty spot using BST rule → Node(val)\nif val < node.val: go left  |  if val > node.val: go right"
		"traverse":return "inorder: left→root→right  |  preorder: root→left→right\npostorder: left→right→root  |  inorder gives sorted output!"
		"delete":  return "Two children: successor=min(right); node.val=successor.val\ndelete successor from right subtree → O(log n)"
		"avl":     return "bf=h(left)-h(right): >1→rotate_right, <-1→rotate_left\nLR/RL cases need double rotation → always O(log n) after"
		"heap":    return "insert: heap.append(val); bubble_up from end → O(log n)\nextract_min: root=heap[0]; replace with last; bubble_down"
		_: return ""

func _btn(text: String, pos: Vector2, col: Color, cb: Callable) -> void:
	var b := Button.new(); b.text=text; b.set_position(pos); b.set_size(Vector2(170,46))
	b.add_theme_font_size_override("font_size",15); b.add_theme_color_override("font_color",col)
	b.pressed.connect(cb); add_child(b)

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new(); l.text=text; l.set_position(pos)
	l.add_theme_font_size_override("font_size",sz); l.add_theme_color_override("font_color",col)
	add_child(l); return l
