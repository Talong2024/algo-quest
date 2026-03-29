extends Node2D

signal node_clicked(node_id: int)
signal insert_spot_clicked(after_id: int, side: String)
signal heap_node_clicked(idx: int)
signal reverse_clicked

var _cfg:      Dictionary = {}
var _bst_ref: Node
var _logic_ref: Node
var _dsa_panel: Node2D

var _world: Node2D
var _renderer: Node2D

var _hud_score: Label
var _hud_lives: Label
var _hud_level: Label
var _hud_dsa:   Label
var _feedback:  Label
var _fb_timer:  Timer
var _left_panel:  Control
var _right_panel: Control
var _q_btn:     Button
var _op_label:  Label

func setup(cfg: Dictionary, bst: Node, gl: Node, dp: Node2D) -> void:
	_cfg       = cfg
	_bst_ref   = bst
	_logic_ref = gl
	_dsa_panel = dp

func _ready() -> void:
	_build_world()
	_build_hud()
	_build_panels()
	_build_feedback()

func _build_world() -> void:
	_world = (load("res://scripts/chapters/tree/ForestWorld.gd") as GDScript).new()
	_world.name = "T_ForestWorld"
	add_child(_world)

	_renderer = (load("res://scripts/chapters/tree/TreeRenderer.gd") as GDScript).new()
	_renderer.name = "T_TreeRenderer"
	_renderer.z_index = 5
	_renderer.node_clicked.connect(func(nid): emit_signal("node_clicked", nid))
	add_child(_renderer)

	if _dsa_panel:
		if _dsa_panel.get_parent(): _dsa_panel.reparent(self)
		else: add_child(_dsa_panel)

func _build_hud() -> void:
	var hud := ColorRect.new()
	hud.color = Color(0,0,0,0.72)
	hud.set_position(Vector2.ZERO)
	hud.set_size(Vector2(1280,48))
	add_child(hud)

	_hud_level = _lbl("", Vector2(12,8),  13, Color("#6BCB77"))
	_hud_dsa   = _lbl("", Vector2(12,28), 11, Color("#334420"))
	if not _cfg.is_empty():
		_hud_level.text = "Level %d — %s" % [_cfg.get("level",1), _cfg.get("title","")]
		_hud_dsa.text   = "DSA: " + _cfg.get("dsainfo","")

	_hud_score = _lbl("Score: 0", Vector2(860,14), 16, Color("#FFD93D"))
	_hud_lives = _lbl("♥ ♥ ♥",   Vector2(1080,10), 20, Color("#FF6B6B"))

	_q_btn = Button.new()
	_q_btn.text = "[Q]  Tree panel"
	_q_btn.set_position(Vector2(1150,52))
	_q_btn.set_size(Vector2(120,28))
	_q_btn.add_theme_font_size_override("font_size", 11)
	_q_btn.pressed.connect(_toggle_dsa)
	add_child(_q_btn)

	_op_label = _lbl("", Vector2(210,54), 13, Color("#FFD93D"))

func _build_panels() -> void:
	# Left panel
	var lb := ColorRect.new()
	lb.color = Color(0,0,0,0.78)
	lb.set_position(Vector2(0,48))
	lb.set_size(Vector2(200,672))
	add_child(lb)

	_lbl("Operations:", Vector2(10,58), 12, Color("#FFD93D"))

	_left_panel = Control.new()
	_left_panel.set_position(Vector2(8,82))
	_left_panel.set_size(Vector2(186,600))
	add_child(_left_panel)

	# Right panel
	var rb := ColorRect.new()
	rb.color = Color(0,0,0,0.78)
	rb.set_position(Vector2(1080,48))
	rb.set_size(Vector2(200,672))
	add_child(rb)

	_lbl("Tree state:", Vector2(1090,58), 12, Color("#FFD93D"))

	_right_panel = Control.new()
	_right_panel.set_position(Vector2(1088,80))
	_right_panel.set_size(Vector2(186,600))
	add_child(_right_panel)

func _build_feedback() -> void:
	_feedback = _lbl("", Vector2(210,72), 13, Color("#6BCB77"))
	_feedback.set_custom_minimum_size(Vector2(860,0))
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fb_timer = Timer.new()
	_fb_timer.wait_time = 4.0
	_fb_timer.one_shot  = true
	_fb_timer.timeout.connect(func(): _feedback.text = "")
	add_child(_fb_timer)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and ke.keycode == KEY_Q:
			_toggle_dsa()

func _toggle_dsa() -> void:
	if _dsa_panel: _dsa_panel.toggle()

func refresh_tree(snapshot: Dictionary, operation: String,
		highlights: Array = [], found_id: int = -1) -> void:
	var show_bal: bool = (snapshot.get("mode","bst") == "avl")
	_renderer.render(snapshot, show_bal)
	_renderer.set_highlights(highlights, found_id, -1)
	_rebuild_right_panel(snapshot)
	_rebuild_left_panel(operation)
	if _dsa_panel:
		_dsa_panel.update(snapshot, operation)

func _rebuild_left_panel(operation: String) -> void:
	for c in _left_panel.get_children(): c.queue_free()
	var ops: Array = ["search","insert","delete","traverse","avl","heap"]
	var labels: Dictionary = {
		"search":"Search value","insert":"Insert node",
		"delete":"Delete node","traverse":"Traversal",
		"avl":"AVL rotation","heap":"Heap insert",
	}
	var cols: Dictionary = {
		"search":Color("#6BCB77"),"insert":Color("#4D96FF"),
		"delete":Color("#FF6B6B"),"traverse":Color("#FFD93D"),
		"avl":Color("#FF9F43"),"heap":Color("#C77DFF"),
	}
	for i in ops.size():
		var op: String     = ops[i]
		var active: bool   = (op == operation)
		var bg := ColorRect.new()
		bg.color = Color("#1a3a08") if active else Color("#060e02")
		bg.set_position(Vector2(0, i*48))
		bg.set_size(Vector2(186,44))
		_left_panel.add_child(bg)
		var lbl := Label.new()
		lbl.text = labels[op]
		lbl.set_position(Vector2(6, i*48+4))
		lbl.set_size(Vector2(178,44))
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color",
			cols[op] if active else Color("#223310"))
		_left_panel.add_child(lbl)

func _rebuild_right_panel(snapshot: Dictionary) -> void:
	for c in _right_panel.get_children(): c.queue_free()
	var nodes:   Dictionary = snapshot.get("nodes",{}) as Dictionary
	var inorder: Array      = snapshot.get("inorder",[]) as Array
	var h:       int        = snapshot.get("height",0) as int
	var bal:     bool       = snapshot.get("balanced",true) as bool
	var heap:    Array      = snapshot.get("heap",[]) as Array

	var y: Array = [0.0]  # wrapped in Array so lambda can mutate it
	var _r: Callable = func(text: String, col: Color) -> void:
		var l := Label.new()
		l.text = text; l.set_position(Vector2(0, y[0]))
		l.add_theme_font_size_override("font_size", 11)
		l.add_theme_color_override("font_color", col)
		l.set_custom_minimum_size(Vector2(184, 0))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_right_panel.add_child(l)
		y[0] += 20.0

	_r.call("Height: %d" % h, Color("#6BCB77"))
	_r.call("Balanced: %s" % ("✓ yes" if bal else "✗ no"),
		Color("#6BCB77") if bal else Color("#FF9F43"))
	_r.call("Nodes: %d" % nodes.size(), Color("#6BCB77"))

	if not heap.is_empty():
		_r.call("Heap array:", Color("#C77DFF"))
		_r.call(str(heap), Color("#C77DFF"))
	else:
		var vals: Array = []
		for nid in inorder:
			if nodes.has(nid): vals.append(str(nodes[nid]["value"]))
		_r.call("Inorder:", Color("#FFD93D"))
		_r.call(", ".join(vals), Color("#6BCB77"))

	_r.call("O(h): %s" % ("O(log n)" if bal else "O(n)"),
		Color("#6BCB77") if bal else Color("#FF6B6B"))

func show_feedback(msg: String, good: bool) -> void:
	_feedback.text = msg
	_feedback.add_theme_color_override("font_color",
		Color("#6BCB77") if good else Color("#FF6B6B"))
	_fb_timer.start()

func set_op_label(text: String) -> void:
	_op_label.text = text

func update_score(v: int) -> void: _hud_score.text = "Score: %d" % v
func update_lives(v: int) -> void:
	var h := ""
	for i in 3: h += "♥ " if i < v else "♡ "
	_hud_lives.text = h
	_hud_lives.add_theme_color_override("font_color",
		Color("#FF0000") if v <= 1 else Color("#FF6B6B"))

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text; l.set_position(pos)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	add_child(l); return l
