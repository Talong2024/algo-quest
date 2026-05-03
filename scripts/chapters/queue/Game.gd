extends Node2D
## Q_Game — Side-scrolling castle queue.
## Citizens walk in from the right, queue left toward the gate.
## Gate is on the LEFT. Citizens line up right-to-left.
## Serve the LEFTMOST (front) citizen at the gate.

signal citizen_clicked(citizen_id: int)

# Side-scroller layout
const GATE_X:      float = 200.0   # gate position X
const QUEUE_Y:     float = 540.0   # queue standing Y (ground level)
const SPAWN_X:     float = 1400.0  # citizens spawn off right edge
const CITIZEN_GAP: float = 100.0   # spacing between citizens
const FRONT_X:     float = 280.0   # front-of-queue X (near gate)

var _cfg:       Dictionary = {}
var _queue_ref: Node
var _gate_ref:  Node
var _dsa_panel: Node2D
var _mechanic:  String = "fifo"

var _citizen_nodes: Dictionary = {}
var _waiting_order: Array      = []

# UI
var _hud_score:   Label
var _hud_lives:   Label
var _feedback:    Label
var _fb_timer:    Timer
var _world:       Node2D
var _gate_flash:  ColorRect
var _slot_rects:  Array = []
var _combo_lbl:   Label
var _combo:       int   = 0
var _combo_timer: float = 0.0

func setup(cfg: Dictionary, qm: Node, gk: Node, dp: Node2D) -> void:
	_cfg       = cfg
	_queue_ref = qm
	_gate_ref  = gk
	_dsa_panel = dp
	_mechanic  = str(cfg.get("mechanic","fifo"))

func _ready() -> void:
	_build_world()
	_build_hud()
	_build_controls_hint()
	_build_gate_flash()
	_build_feedback()
	_build_combo()
	if _mechanic == "overflow": _build_queue_slots()
	if _mechanic == "deque":    _build_deque_ui()

func _build_world() -> void:
	_world = (load("res://scenes/chapters/queue/World.tscn") as PackedScene).instantiate()
	_world.name = "Q_World"
	_world.total_locks = _cfg.get("queue_size", 5) as int
	add_child(_world)

func _build_hud() -> void:
	# Top HUD bar
	var bar := ColorRect.new()
	bar.color = Color(0.05, 0.03, 0.08, 0.92)
	bar.set_position(Vector2.ZERO); bar.set_size(Vector2(1280, 52))
	add_child(bar)
	var sep := ColorRect.new()
	sep.color = Color(0.65, 0.50, 0.15, 1.0)
	sep.set_position(Vector2(0, 52)); sep.set_size(Vector2(1280, 2))
	add_child(sep)

	if not _cfg.is_empty():
		_lbl("Chapter I  •  Kingdom Gate  •  Level %d" % _cfg.get("level",1),
			Vector2(12,5), 10, Color("#4D96FF"))
		_lbl(_cfg.get("title","") as String, Vector2(12,20), 16, Color("#e8e8f0"))
		_lbl("[ " + _cfg.get("dsainfo","") + " ]", Vector2(12,39), 9, Color("#334455"))

	_hud_score = _lbl("Score: 0",  Vector2(700, 16), 16, Color("#FFD93D"))
	_hud_lives = _lbl("♥ ♥ ♥",    Vector2(1150, 12), 18, Color("#FF6B6B"))

func _build_gate_flash() -> void:
	_gate_flash = ColorRect.new()
	_gate_flash.color = Color(0.2, 1.0, 0.3, 0.0)
	_gate_flash.set_position(Vector2(0, 300))
	_gate_flash.set_size(Vector2(320, 420))
	_gate_flash.z_index = 50
	_gate_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_gate_flash)

func _flash_gate(good: bool) -> void:
	var col := Color(0.2, 1.0, 0.3, 0.45) if good else Color(1.0, 0.1, 0.1, 0.35)
	_gate_flash.color = col
	var tw := create_tween()
	tw.tween_property(_gate_flash, "color:a", 0.0, 0.35)

func _build_controls_hint() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_position(Vector2(1060, 54)); bg.set_size(Vector2(220, 70))
	add_child(bg)
	match _mechanic:
		"fifo","overflow":
			_lbl("SPACE / E — serve citizen at gate", Vector2(1068,60), 10, Color("#aaccaa"))
			_lbl("Click citizen at gate to serve",    Vector2(1068,76), 10, Color("#aaccaa"))
		"patience":
			_lbl("SPACE / E — serve citizen at gate", Vector2(1068,60), 10, Color("#aaccaa"))
			_lbl("R — REJECT enemy at gate",          Vector2(1068,76), 10, Color("#FF4400"))
		"priority":
			_lbl("DRAG citizens to reorder",          Vector2(1068,60), 10, Color("#FFD93D"))
			_lbl("SPACE — serve when sorted",         Vector2(1068,76), 10, Color("#aaccaa"))
		"deque":
			_lbl("SPACE / F — serve FRONT (left)",    Vector2(1068,60), 10, Color("#6BCB77"))
			_lbl("B — serve BACK (right)",            Vector2(1068,76), 10, Color("#FF9900"))

func _build_feedback() -> void:
	_feedback = _lbl("", Vector2(320, 60), 14, Color("#6BCB77"))
	_fb_timer  = Timer.new(); _fb_timer.wait_time = 3.0; _fb_timer.one_shot = true
	_fb_timer.timeout.connect(func(): _feedback.text = "")
	add_child(_fb_timer)

func _build_combo() -> void:
	_combo_lbl = _lbl("", Vector2(500, 480), 22, Color("#FFD93D"))
	_combo_lbl.z_index = 60

func _build_queue_slots() -> void:
	var max_size: int = _cfg.get("queue_size", 3) as int
	for i in max_size:
		var slot := ColorRect.new()
		slot.color = Color(0.15, 0.12, 0.08, 0.6)
		slot.set_position(Vector2(FRONT_X + i * CITIZEN_GAP - 50, QUEUE_Y - 80))
		slot.set_size(Vector2(90, 90))
		slot.z_index = -1
		add_child(slot)
		_slot_rects.append(slot)
		# Slot number label
		var lbl := Label.new()
		lbl.text = "S%d" % (i+1)
		lbl.set_position(Vector2(FRONT_X + i * CITIZEN_GAP - 46, QUEUE_Y - 74))
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.4, 0.2))
		add_child(lbl)

func _build_deque_ui() -> void:
	var fl := Label.new()
	fl.text = "[ FRONT GATE — SPACE/F ]"
	fl.set_position(Vector2(130, 500)); fl.z_index = 5
	fl.add_theme_font_size_override("font_size", 10)
	fl.add_theme_color_override("font_color", Color("#6BCB77"))
	add_child(fl)
	var bl := Label.new()
	bl.text = "[ BACK GATE — B ]"
	bl.set_position(Vector2(900, 500)); bl.z_index = 5
	bl.add_theme_font_size_override("font_size", 10)
	bl.add_theme_color_override("font_color", Color("#FF9900"))
	add_child(bl)

# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey:
		var ke := ev as InputEventKey
		if not ke.pressed: return
		match ke.keycode:
			KEY_SPACE, KEY_E, KEY_F:
				if _mechanic == "deque": _gate_ref.player_dequeue_front()
				else: _try_serve_front()
			KEY_B:
				if _mechanic == "deque": _gate_ref.player_dequeue_back()
			KEY_R: _gate_ref.player_reject_enemy()
			KEY_Q: if _dsa_panel: _dsa_panel.toggle()

func _try_serve_front() -> void:
	if _queue_ref.is_empty(): return
	var front: Dictionary = _queue_ref.peek_front()
	var fid: int = front.get("id",-1) as int
	var fn: CitizenNode = _citizen_nodes.get(fid, null) as CitizenNode
	if fn and fn.has_arrived():
		_gate_ref.player_picks(fid)

# ── Citizens ──────────────────────────────────────────────────────────────────

func on_citizen_arrived(c: Dictionary) -> void:
	var cid: int = c.get("id",-1) as int
	_waiting_order.append(cid)
	var node: CitizenNode = (load("res://scenes/chapters/queue/CitizenNode.tscn") as PackedScene
		).instantiate() as CitizenNode
	# Side-scroller: citizens start off right edge, walk left
	node.position = Vector2(SPAWN_X, QUEUE_Y)
	node.z_index  = 10 + cid
	add_child(node)
	node.setup(c, SPAWN_X, FRONT_X)
	node.clicked.connect(func(id: int):
		var n: CitizenNode = _citizen_nodes.get(id, null) as CitizenNode
		if n and n.has_arrived():
			_gate_ref.player_picks(id)
	)
	_citizen_nodes[cid] = node
	_reposition_all()

func on_citizen_served(c: Dictionary) -> void:
	var cid: int = c.get("id",-1) as int
	if _citizen_nodes.has(cid):
		(_citizen_nodes[cid] as CitizenNode).play_serve_anim()
		_citizen_nodes.erase(cid)
	_waiting_order.erase(cid)
	_flash_gate(true); _add_combo()
	_reposition_all()

func on_citizen_expired(c: Dictionary) -> void:
	var cid: int = c.get("id",-1) as int
	if _citizen_nodes.has(cid):
		var n := _citizen_nodes[cid] as CitizenNode
		var tw := create_tween()
		tw.tween_property(n, "modulate:a", 0.0, 0.5)
		tw.tween_callback(n.queue_free)
		_citizen_nodes.erase(cid)
	_waiting_order.erase(cid)
	_combo = 0; _combo_lbl.text = ""
	_flash_gate(false); _reposition_all()

func on_citizen_angry(cid: int, msg: String) -> void:
	if _citizen_nodes.has(cid):
		(_citizen_nodes[cid] as CitizenNode).show_anger(msg)
	_flash_gate(false); _combo = 0; _combo_lbl.text = ""

func on_enemy_rejected(cid: int) -> void:
	if _citizen_nodes.has(cid):
		(_citizen_nodes[cid] as CitizenNode).play_slash_anim()
		_citizen_nodes.erase(cid)
	_waiting_order.erase(cid)
	_flash_gate(true); _add_combo(); _reposition_all()

func on_overflow_visual() -> void:
	for slot in _slot_rects:
		var s := slot as ColorRect
		var tw := create_tween()
		tw.tween_property(s, "color", Color(0.8, 0.1, 0.1, 0.85), 0.1)
		tw.tween_property(s, "color", Color(0.15, 0.12, 0.08, 0.6),  0.4)
	_flash_gate(false); _combo = 0; _combo_lbl.text = ""

func on_drag_requested(_cid: int) -> void: pass
func on_deque_prompt(_cid: int, _gate: String) -> void: pass

func _add_combo() -> void:
	_combo += 1; _combo_timer = 3.0
	if _combo >= 2:
		_combo_lbl.text = "x%d COMBO!" % _combo
		var tw := create_tween()
		tw.tween_property(_combo_lbl,"scale",Vector2(1.3,1.3),0.08)
		tw.tween_property(_combo_lbl,"scale",Vector2(1.0,1.0),0.12)

func _reposition_all() -> void:
	# Front citizen goes to FRONT_X, each behind goes further right
	var sz: int = _waiting_order.size()
	for i in sz:
		var cid: int = _waiting_order[i]
		if _citizen_nodes.has(cid):
			var node := _citizen_nodes[cid] as CitizenNode
			var tx: float = FRONT_X + i * CITIZEN_GAP
			node.set_target_x(tx)
	# Update overflow slot colours
	for i in _slot_rects.size():
		var slot := _slot_rects[i] as ColorRect
		var ratio: float = float(sz) / float(_cfg.get("queue_size",3) as int)
		if i < sz:
			slot.color = Color(0.6,0.1,0.1,0.7) if ratio >= 0.75 else Color(0.3,0.5,0.2,0.7)
		else:
			slot.color = Color(0.15,0.12,0.08,0.6)

func _process(delta: float) -> void:
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo = 0; _combo_lbl.text = ""

func show_feedback(msg: String, good: bool) -> void:
	_feedback.text = msg
	_feedback.add_theme_color_override("font_color",
		Color("#6BCB77") if good else Color("#FF6B6B"))
	_fb_timer.start()

func update_score(v: int) -> void: _hud_score.text = "Score: %d" % v
func update_lives(v: int) -> void:
	var h := ""
	for i in 3: h += "♥ " if i < v else "♡ "
	_hud_lives.text = h.strip_edges()
	_hud_lives.add_theme_color_override("font_color",
		Color("#FF0000") if v <= 1 else Color("#FF6B6B"))

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new(); l.text = text; l.set_position(pos)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	add_child(l); return l
