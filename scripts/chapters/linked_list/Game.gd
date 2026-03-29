extends Node2D

# ═══════════════════════════════════════════════════
# LL_Game.gd — Chain Train top-down gameplay.
# Carriages sit on the track. Couplers = next ptrs.
# Left panel = operation buttons + node list.
# Right panel = live pointer state.
# ═══════════════════════════════════════════════════

signal carriage_clicked(node_id: int)
signal gap_clicked(after_id: int)
signal reverse_clicked

const TRACK_CY:    float = 340.0
const START_X:     float = 160.0
const CARRIAGE_W:  float = 100.0
const CARRIAGE_H:  float = 70.0
const COUPLER_W:   float = 50.0
const CARRIAGE_STEP: float = 150.0  # carriage W + coupler W

var _cfg:         Dictionary       = {}
var _ll_ref: Node
var _logic_ref: Node
var _dsa_panel: Node2D

var _world: Node2D
var _carriage_nodes: Dictionary    = {}   # node_id -> LL_CarriageNode
var _gap_areas:      Array         = []   # gap Area2D nodes for insert
var _snapshot:       Array         = []

# UI
var _hud_score:   Label
var _hud_lives:   Label
var _hud_level:   Label
var _hud_dsa:     Label
var _feedback:    Label
var _fb_timer:    Timer
var _left_panel:  Control
var _right_panel: Control
var _rev_btn:     Button
var _q_btn:       Button

func setup(cfg: Dictionary, ll: Node, gl: Node, dp: Node2D) -> void:
	_cfg       = cfg
	_ll_ref    = ll
	_logic_ref = gl
	_dsa_panel = dp

func _ready() -> void:
	_build_world()
	_build_hud()
	_build_left_panel()
	_build_right_panel()
	_build_feedback()

func _build_world() -> void:
	_world = (load("res://scripts/chapters/linked_list/TrainWorld.gd") as GDScript).new()
	_world.name = "LL_TrainWorld"
	add_child(_world)
	if _dsa_panel:
		if _dsa_panel.get_parent(): _dsa_panel.reparent(self)
		else: add_child(_dsa_panel)

func _build_hud() -> void:
	var hud := ColorRect.new()
	hud.color = Color(0,0,0,0.72)
	hud.set_position(Vector2.ZERO)
	hud.set_size(Vector2(1280, 48))
	add_child(hud)

	_hud_level = _lbl("", Vector2(12,8),  13, Color("#FFD93D"))
	_hud_dsa   = _lbl("", Vector2(12,28), 11, Color("#444420"))

	if not _cfg.is_empty():
		_hud_level.text = "Level %d — %s" % [_cfg.get("level",1), _cfg.get("title","")]
		_hud_dsa.text   = "DSA: " + _cfg.get("dsainfo","")

	_hud_score = _lbl("Score: 0", Vector2(860,14), 16, Color("#FFD93D"))
	_hud_lives = _lbl("♥ ♥ ♥",   Vector2(1080,10), 20, Color("#FF6B6B"))

	_q_btn = Button.new()
	_q_btn.text = "[Q]  List panel"
	_q_btn.set_position(Vector2(1150, 52))
	_q_btn.set_size(Vector2(120, 28))
	_q_btn.add_theme_font_size_override("font_size", 11)
	_q_btn.pressed.connect(_toggle_dsa)
	add_child(_q_btn)

func _build_left_panel() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0,0,0,0.78)
	bg.set_position(Vector2(0,48))
	bg.set_size(Vector2(200, 672))
	add_child(bg)

	_lbl("Operations:", Vector2(10,58), 12, Color("#FFD93D"))

	_left_panel = Control.new()
	_left_panel.set_position(Vector2(8, 82))
	_left_panel.set_size(Vector2(186, 500))
	add_child(_left_panel)

	_rev_btn = Button.new()
	_rev_btn.text = "↺ Reverse train"
	_rev_btn.set_position(Vector2(8, 560))
	_rev_btn.set_size(Vector2(186, 40))
	_rev_btn.add_theme_font_size_override("font_size", 13)
	_rev_btn.add_theme_color_override("font_color", Color("#C77DFF"))
	_rev_btn.visible = false
	_rev_btn.pressed.connect(func(): emit_signal("reverse_clicked"))
	add_child(_rev_btn)

func _build_right_panel() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0,0,0,0.78)
	bg.set_position(Vector2(1080, 48))
	bg.set_size(Vector2(200, 672))
	add_child(bg)

	_lbl("Pointer state:", Vector2(1090,58), 12, Color("#FFD93D"))

	_right_panel = Control.new()
	_right_panel.set_position(Vector2(1088, 80))
	_right_panel.set_size(Vector2(186, 600))
	add_child(_right_panel)

func _build_feedback() -> void:
	_feedback = _lbl("", Vector2(210, 54), 13, Color("#6BCB77"))
	_feedback.set_custom_minimum_size(Vector2(860, 0))
	_fb_timer = Timer.new()
	_fb_timer.wait_time = 4.0
	_fb_timer.one_shot  = true
	_fb_timer.timeout.connect(func(): _feedback.text = "")
	add_child(_fb_timer)

# ─── Input ────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and ke.keycode == KEY_Q:
			_toggle_dsa()

func _toggle_dsa() -> void:
	if _dsa_panel: _dsa_panel.toggle()

# ─── Train rebuild ────────────────────────────────

func rebuild_train(snapshot: Array, operation: String) -> void:
	_snapshot = snapshot
	_clear_carriages()
	_clear_gaps()
	_rev_btn.visible = (operation == "reverse")

	for i in snapshot.size():
		var node: Dictionary = snapshot[i]
		var nid:  int        = node["id"] as int
		var cx:   float      = START_X + i * CARRIAGE_STEP
		var cy:   float      = TRACK_CY - CARRIAGE_H / 2.0

		var cn: Node2D = (load("res://scripts/chapters/linked_list/CarriageNode.gd") as GDScript).new()
		cn.name = "Carriage_%d" % nid
		cn.setup(node)
		cn.set_state(i == 0, i == snapshot.size()-1)
		cn.position = Vector2(cx + CARRIAGE_W/2.0, cy + CARRIAGE_H/2.0)
		cn.z_index  = 10

		# Highlight delete target
		if operation == "delete":
			var tgt: int = _logic_ref._delete_target_id
			if nid == tgt:
				cn.is_selected = true

		# Collision for click
		var area := Area2D.new()
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(CARRIAGE_W - 4, CARRIAGE_H - 4)
		shape.shape = box
		area.add_child(shape)
		area.input_event.connect(func(_vp, event, _idx):
			if event is InputEventMouseButton:
				var mb := event as InputEventMouseButton
				if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
					emit_signal("carriage_clicked", nid)
		)
		cn.add_child(area)
		add_child(cn)
		_carriage_nodes[nid] = cn

		# Draw coupler arrow (Node2D overlay)
		if i < snapshot.size() - 1:
			_draw_coupler(cx + CARRIAGE_W, cy + CARRIAGE_H/2.0,
				cx + CARRIAGE_STEP, cy + CARRIAGE_H/2.0, i, snapshot, operation)

		# Gap click zone for insert
		if operation == "insert" and i < snapshot.size() - 1:
			_add_gap_area(nid, cx + CARRIAGE_W + 4, cy, COUPLER_W - 8, CARRIAGE_H)

	# Also gap before head for insert-at-head
	if operation == "insert":
		_add_gap_area(-1, START_X - 44, TRACK_CY - CARRIAGE_H/2.0, 40, CARRIAGE_H)

	_rebuild_left_panel(operation, snapshot)
	_rebuild_right_panel(snapshot)

func _draw_coupler(x1: float, y: float, x2: float, _y2: float,
		idx: int, snapshot: Array, operation: String) -> void:
	# Visual coupler drawn as a Line2D-style Node2D
	var c := Node2D.new()
	c.z_index = 5
	add_child(c)

	# We draw via a script
	var s := GDScript.new()
	# Use a simpler approach — ColorRect for coupler bar
	var bar := ColorRect.new()
	bar.color = Color("#5a5020")
	bar.set_position(Vector2(x1, y - 6))
	bar.set_size(Vector2(x2 - x1, 12))
	add_child(bar)

	# Arrow label
	var lbl := Label.new()
	lbl.text = "→"
	lbl.set_position(Vector2((x1 + x2) / 2.0 - 6, y - 10))
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color("#FFD93D"))
	add_child(lbl)

	# Back arrow for doubly
	if _ll_ref.is_doubly:
		var lbl2 := Label.new()
		lbl2.text = "←"
		lbl2.set_position(Vector2((x1 + x2) / 2.0 - 6, y + 4))
		lbl2.add_theme_font_size_override("font_size", 14)
		lbl2.add_theme_color_override("font_color", Color("#4D96FF"))
		add_child(lbl2)

func _add_gap_area(after_id: int, gx: float, gy: float, gw: float, gh: float) -> void:
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(gw, gh)
	shape.shape = box
	area.position = Vector2(gx + gw/2.0, gy + gh/2.0)
	area.add_child(shape)

	var aid: int = after_id
	area.input_event.connect(func(_vp, event, _idx):
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				emit_signal("gap_clicked", aid)
	)

	# Visual gap indicator
	var gfx := ColorRect.new()
	gfx.color = Color("#4D96FF", 0.25)
	gfx.set_position(Vector2(gx, gy))
	gfx.set_size(Vector2(gw, gh))
	add_child(gfx)

	var lbl := Label.new()
	lbl.text = "+"
	lbl.set_position(Vector2(gx + gw/2.0 - 5, gy + gh/2.0 - 10))
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color("#4D96FF"))
	add_child(lbl)

	add_child(area)
	_gap_areas.append(area)

func _clear_carriages() -> void:
	for n in _carriage_nodes.values():
		if is_instance_valid(n): n.queue_free()
	_carriage_nodes.clear()
	# Also clear couplers and labels
	for child in get_children():
		if child is ColorRect or child is Label:
			if not (child == _hud_score or child == _hud_lives or
				child == _hud_level or child == _hud_dsa or
				child == _feedback):
				child.queue_free()

func _clear_gaps() -> void:
	for a in _gap_areas:
		if is_instance_valid(a): a.queue_free()
	_gap_areas.clear()

# ─── Panels ───────────────────────────────────────

func _rebuild_left_panel(operation: String, snapshot: Array) -> void:
	for c in _left_panel.get_children(): c.queue_free()

	var ops: Array = ["traverse","insert","delete","reverse"]
	var op_labels: Dictionary = {
		"traverse": "Traverse →",
		"insert":   "Insert node",
		"delete":   "Delete node",
		"reverse":  "Reverse ↺",
	}
	var op_cols: Dictionary = {
		"traverse": Color("#6BCB77"),
		"insert":   Color("#4D96FF"),
		"delete":   Color("#FF6B6B"),
		"reverse":  Color("#C77DFF"),
	}
	for i in ops.size():
		var op: String = ops[i]
		var is_active: bool = (op == operation)
		var btn := ColorRect.new()
		btn.color = Color("#1a2a08") if is_active else Color("#0a0e04")
		btn.set_position(Vector2(0, i * 54))
		btn.set_size(Vector2(186, 48))
		_left_panel.add_child(btn)
		var lbl := Label.new()
		lbl.text = op_labels[op]
		lbl.set_position(Vector2(2, i * 54 + 2))
		lbl.set_size(Vector2(186, 48))
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color",
			op_cols[op] if is_active else Color("#333320"))
		_left_panel.add_child(lbl)
		if is_active:
			var border := ColorRect.new()
			border.color = Color(0,0,0,0)
			border.set_position(Vector2(0, i * 54))
			border.set_size(Vector2(4, 48))
			_left_panel.add_child(border)

func _rebuild_right_panel(snapshot: Array) -> void:
	for c in _right_panel.get_children(): c.queue_free()

	var y: float = 0.0
	for i in snapshot.size():
		var node: Dictionary = snapshot[i]
		var col:  Color      = node.get("color", Color("#6BCB77")) as Color
		var lbl := Label.new()
		var nxt: int = node.get("next_id",-1) as int
		var prv: int = node.get("prev_id",-1) as int
		var txt: String = "id:%d  val:%s\nnext→%s" % [
			node.get("id",0), node.get("label","?"),
			"null" if nxt==-1 else str(nxt)
		]
		if _ll_ref.is_doubly:
			txt += "\nprev←%s" % ("null" if prv==-1 else str(prv))
		lbl.text = txt
		lbl.set_position(Vector2(0, y))
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", col)
		_right_panel.add_child(lbl)
		y += (50.0 if _ll_ref.is_doubly else 38.0)

# ─── HUD updates ──────────────────────────────────

func show_feedback(msg: String, good: bool) -> void:
	_feedback.text = msg
	_feedback.add_theme_color_override("font_color",
		Color("#6BCB77") if good else Color("#FF6B6B"))
	_fb_timer.start()

func update_score(v: int) -> void: _hud_score.text = "Score: %d" % v
func update_lives(v: int) -> void:
	var h := ""
	for i in 3: h += "♥ " if i < v else "♡ "
	_hud_lives.text = h
	_hud_lives.add_theme_color_override("font_color",
		Color("#FF0000") if v <= 1 else Color("#FF6B6B"))

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.set_position(pos)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	return l
