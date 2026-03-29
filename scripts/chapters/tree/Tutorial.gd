extends Node2D

signal start_requested
var level_data: Dictionary = {}
var _timer: Timer
var _anim_lbl: Label
var _step: int = 0

func _ready() -> void:
	_build_ui()
	_timer = Timer.new()
	_timer.wait_time = 1.6
	_timer.timeout.connect(_demo_step)
	add_child(_timer)
	_timer.start()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0d1a08")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var hdr := ColorRect.new()
	hdr.color = Color("#080f04")
	hdr.set_position(Vector2.ZERO); hdr.set_size(Vector2(1280,64))
	add_child(hdr)

	_lbl("DSA TUTORIAL", Vector2(20,8), 11, Color("#6BCB77"))
	_lbl("Level %d — %s" % [level_data.get("level",1), level_data.get("title","")],
		Vector2(20,26), 22, Color("#e8f0e8"))
	_lbl("DSA Focus: " + level_data.get("dsainfo",""), Vector2(700,34), 13, Color("#6BCB77"))
	_lbl(level_data.get("desc",""), Vector2(20,78), 15, Color("#aaaaaa")).set_custom_minimum_size(Vector2(800,0))

	var rb := ColorRect.new()
	rb.color = Color("#080f04"); rb.set_position(Vector2(20,140)); rb.set_size(Vector2(540,280))
	add_child(rb)
	_lbl("Rules:", Vector2(36,152), 15, Color("#FFD93D"))
	var rules := Label.new()
	rules.text = _get_rules()
	rules.set_position(Vector2(36,178)); rules.set_custom_minimum_size(Vector2(500,220))
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.add_theme_font_size_override("font_size", 14)
	rules.add_theme_color_override("font_color", Color("#e8f0e8"))
	add_child(rules)

	var pb := ColorRect.new()
	pb.color = Color("#0d1a08"); pb.set_position(Vector2(590,140)); pb.set_size(Vector2(660,280))
	add_child(pb)
	_lbl("Live Demo:", Vector2(606,152), 14, Color("#6BCB77"))

	_anim_lbl = Label.new()
	_anim_lbl.set_position(Vector2(606,380)); _anim_lbl.set_custom_minimum_size(Vector2(630,60))
	_anim_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_anim_lbl.add_theme_font_size_override("font_size", 13)
	_anim_lbl.add_theme_color_override("font_color", Color("#6BCB77"))
	add_child(_anim_lbl)

	var cb := ColorRect.new()
	cb.color = Color("#040a02"); cb.set_position(Vector2(20,440)); cb.set_size(Vector2(1220,110))
	add_child(cb)
	var code := Label.new()
	code.text = _get_code()
	code.set_position(Vector2(36,452))
	code.add_theme_font_size_override("font_size", 13)
	code.add_theme_color_override("font_color", Color("#6BCB77"))
	add_child(code)

	var btn := Button.new()
	btn.text = "▶  Enter the Forest"
	btn.set_position(Vector2(540,572)); btn.set_size(Vector2(200,52))
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(func(): emit_signal("start_requested"))
	add_child(btn)

func _demo_step() -> void:
	_step += 1
	var op: String = level_data.get("operation","search") as String
	match op:
		"search":
			match _step:
				1: _anim_lbl.text = "BST has values: 20, 10, 30, 5, 15\nSearching for 15..."
				2: _anim_lbl.text = "Visit 20: 15 < 20 → go LEFT"
				3: _anim_lbl.text = "Visit 10: 15 > 10 → go RIGHT"
				4: _anim_lbl.text = "Visit 15: 15 == 15 → FOUND! ★\n3 comparisons — O(log n)!"
				5: _step = 0
		"insert":
			match _step:
				1: _anim_lbl.text = "Inserting value 25 into BST..."
				2: _anim_lbl.text = "25 > 20 → go right to 30"
				3: _anim_lbl.text = "25 < 30 → go LEFT — spot is empty!"
				4: _anim_lbl.text = "Plant node 25 as LEFT child of 30! ✓"
				5: _step = 0
		"traverse":
			match _step:
				1: _anim_lbl.text = "Tree: 20 (root), left=10, right=30"
				2: _anim_lbl.text = "INORDER: visit left → root → right"
				3: _anim_lbl.text = "Result: 5, 10, 15, 20, 30 — SORTED! ✓"
				4: _anim_lbl.text = "Inorder traversal of BST always\ngives values in sorted order!"
				5: _step = 0
		"delete":
			match _step:
				1: _anim_lbl.text = "Deleting node 10 (has two children)"
				2: _anim_lbl.text = "Find inorder successor: min of right subtree = 15"
				3: _anim_lbl.text = "Replace 10 with 15, delete original 15"
				4: _anim_lbl.text = "BST property maintained! ✓"
				5: _step = 0
		"avl":
			match _step:
				1: _anim_lbl.text = "Insert 4,3,2 into BST...\nTree becomes right-skewed!"
				2: _anim_lbl.text = "Balance factor of 4 = +2 (left-heavy)\nNeed RIGHT rotation!"
				3: _anim_lbl.text = "Rotate right: 3 becomes root\n4 becomes right child of 3"
				4: _anim_lbl.text = "Tree balanced! Height = 2 not 3\nO(log n) restored ✓"
				5: _step = 0
		"heap":
			match _step:
				1: _anim_lbl.text = "Min-Heap: parent ≤ children always"
				2: _anim_lbl.text = "Insert 3 at end: [10, 20, 15, 3]"
				3: _anim_lbl.text = "3 < parent(20) → SWAP! Bubble up..."
				4: _anim_lbl.text = "3 < parent(10) → SWAP again!\nResult: [3, 10, 15, 20] ✓"
				5: _step = 0
	queue_redraw()

func _get_rules() -> String:
	match level_data.get("operation","search") as String:
		"search":  return "• Each tree orb = a BST node with a value\n• LEFT children always SMALLER than parent\n• RIGHT children always LARGER than parent\n• Click nodes navigating left/right to find target\n• Wrong direction = wasted step = -1 life"
		"insert":  return "• Navigate to correct empty spot using BST rules\n• Click nodes to traverse toward insert position\n• Click the glowing gap to plant the new node\n• BST rule must hold after insert!"
		"delete":  return "• Case 1: leaf node → just remove\n• Case 2: one child → replace with child\n• Case 3: two children → replace with inorder successor (smallest in right subtree)\n• Click target node to begin deletion"
		"traverse":return "• INORDER: left → root → right (gives sorted output!)\n• PREORDER: root → left → right\n• POSTORDER: left → right → root\n• Click nodes in the correct traversal order"
		"avl":     return "• AVL tree: self-balancing BST\n• Balance factor = height(left) - height(right)\n• |bf| > 1 means UNBALANCED → rotate!\n• LL case: right rotate  |  RR: left rotate\n• LR/RL: double rotation"
		"heap":    return "• Min-Heap: parent always ≤ children\n• Max-Heap: parent always ≥ children\n• Insert at end, then BUBBLE UP\n• Bubble up: swap with parent while smaller (min)\n• Root is always min (min-heap) or max (max-heap)"
		_: return ""

func _get_code() -> String:
	match level_data.get("operation","search") as String:
		"search":  return "if target < node.val: go_left()   # click left child\nelif target > node.val: go_right() # click right child\nelse: FOUND!                       # O(log n) balanced"
		"insert":  return "if val < node.val: go left until empty → plant node\nif val > node.val: go right until empty → plant node"
		"traverse":return "inorder(node): inorder(left); visit(node); inorder(right)   # sorted output!"
		"delete":  return "successor = find_min(node.right)   # inorder successor\nnode.val = successor.val; delete_min(node.right)"
		"avl":     return "bf = height(left) - height(right)\nif bf > 1: rotate_right()   if bf < -1: rotate_left()"
		"heap":    return "heap.append(val)   # add at end\nwhile i>0 and heap[i]<heap[parent]: swap(); i=parent  # bubble up"
		_: return ""

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new(); l.text = text; l.set_position(pos)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col); add_child(l); return l

func _draw() -> void:
	# Mini BST demo diagram
	var cx: float = 920.0; var cy: float = 220.0
	var nodes_demo: Array = [
		[cx, cy, 20, Color("#FFD93D"), true],
		[cx-80, cy+80, 10, Color("#6BCB77"), false],
		[cx+80, cy+80, 30, Color("#4D96FF"), false],
		[cx-120, cy+160, 5, Color("#6BCB77"), false],
		[cx-40, cy+160, 15, Color("#6BCB77"), false],
	]
	draw_line(Vector2(cx,cy), Vector2(cx-80,cy+80), Color("#2a4a15"), 2.0)
	draw_line(Vector2(cx,cy), Vector2(cx+80,cy+80), Color("#2a4a15"), 2.0)
	draw_line(Vector2(cx-80,cy+80), Vector2(cx-120,cy+160), Color("#2a4a15"), 1.5)
	draw_line(Vector2(cx-80,cy+80), Vector2(cx-40,cy+160), Color("#2a4a15"), 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(cx-68,cy+38), "<", HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#4D96FF"))
	draw_string(ThemeDB.fallback_font, Vector2(cx+52,cy+38), ">", HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#FF6B6B"))
	for nd in nodes_demo:
		draw_circle(Vector2(nd[0],nd[1]), 26, Color("#0a1604"))
		draw_arc(Vector2(nd[0],nd[1]), 26, 0, TAU, 24, nd[3] as Color, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(nd[0]-8,nd[1]+6), str(nd[2]),
			HORIZONTAL_ALIGNMENT_LEFT,-1,16, nd[3] as Color)
