extends Node2D
## Q_Game — Queue chapter gameplay.
## Cooking-game style: citizens show speech bubbles, slots flash on overflow,
## enemies have dark auras, VIPs have gold glow, gate rings on serve.

signal citizen_clicked(citizen_id: int)

const LANE_X:      float = 640.0
const SPAWN_Y:     float = 780.0
const FRONT_Y:     float = 185.0
const CITIZEN_GAP: float = 110.0

var _cfg:       Dictionary = {}
var _queue_ref: Node
var _gate_ref:  Node
var _dsa_panel: Node2D
var _mechanic:  String = "fifo"

var _citizen_nodes: Dictionary = {}
var _waiting_order: Array      = []

# Drag (L4)
var _drag_node: Node2D = null
var _drag_cid:  int    = -1

# UI
var _hud_score:   Label
var _hud_lives:   Label
var _feedback:    Label
var _fb_timer:    Timer
var _phase_lbl:   Label
var _world:       Node2D
var _gate_flash:  ColorRect   # flashes green on correct serve
var _slot_rects:  Array = []  # L2 overflow slots
var _combo_lbl:   Label       # combo counter (Diner Dash style)
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
	if _mechanic == "overflow":
		_build_queue_slots()
	if _mechanic == "deque":
		_build_deque_ui()

func _build_world() -> void:
	_world = (load("res://scenes/chapters/queue/World.tscn") as PackedScene).instantiate()
	_world.name = "Q_World"; add_child(_world)

func _build_hud() -> void:
	var bar := ColorRect.new()
	bar.color = Color(0.04, 0.03, 0.08, 0.88)
	bar.set_position(Vector2.ZERO); bar.set_size(Vector2(1280, 54))
	add_child(bar)
	var gold := ColorRect.new()
	gold.color = Color(0.65, 0.50, 0.15, 1.0)
	gold.set_position(Vector2(0, 54)); gold.set_size(Vector2(1280, 2))
	add_child(gold)

	if not _cfg.is_empty():
		_lbl("Chapter I  •  Kingdom Gate  •  Level %d" % _cfg.get("level",1),
			Vector2(12,6), 11, Color("#4D96FF"))
		_lbl(_cfg.get("title","") as String, Vector2(12,22), 16, Color("#e8e8f0"))
		_lbl("[ " + _cfg.get("dsainfo","") + " ]", Vector2(12,40), 9, Color("#334455"))

	_hud_score = _lbl("Score: 0", Vector2(700,18), 16, Color("#FFD93D"))
	_hud_lives = _lbl("♥ ♥ ♥",   Vector2(1150,14), 18, Color("#FF6B6B"))

func _build_gate_flash() -> void:
	# Full-lane green flash on correct serve — satisfying feedback like Overcooked
	_gate_flash = ColorRect.new()
	_gate_flash.color = Color(0.2, 1.0, 0.3, 0.0)
	_gate_flash.set_position(Vector2(LANE_X - 80, 0))
	_gate_flash.set_size(Vector2(160, 720))
	_gate_flash.z_index = 50
	_gate_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_gate_flash)

func _flash_gate(good: bool) -> void:
	var col: Color = Color(0.2, 1.0, 0.3, 0.45) if good else Color(1.0, 0.1, 0.1, 0.35)
	_gate_flash.color = col
	var tw := create_tween()
	tw.tween_property(_gate_flash, "color:a", 0.0, 0.3)

func _build_controls_hint() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0,0,0,0.65)
	bg.set_position(Vector2(0,56)); bg.set_size(Vector2(210, 60))
	add_child(bg)
	match _mechanic:
		"fifo","overflow":
			_lbl("SPACE / E — serve citizen at gate", Vector2(8,62), 10, Color("#aaccaa"))
			_lbl("Click citizen at gate to serve",    Vector2(8,76), 10, Color("#aaccaa"))
		"patience":
			_lbl("SPACE / E — serve front citizen",   Vector2(8,62), 10, Color("#aaccaa"))
			_lbl("R — REJECT / SLASH enemy",          Vector2(8,76), 10, Color("#FF4400"))
		"priority":
			_lbl("DRAG citizens to reorder queue",    Vector2(8,62), 10, Color("#FFD93D"))
			_lbl("SPACE — serve when order correct",  Vector2(8,76), 10, Color("#aaccaa"))
		"deque":
			_lbl("F — serve FRONT gate citizen",      Vector2(8,62), 10, Color("#6BCB77"))
			_lbl("B — serve BACK gate citizen",       Vector2(8,76), 10, Color("#FF9900"))

func _build_feedback() -> void:
	_feedback = _lbl("", Vector2(220, 62), 15, Color("#6BCB77"))
	_fb_timer = Timer.new(); _fb_timer.wait_time = 3.0; _fb_timer.one_shot = true
	_fb_timer.timeout.connect(func(): _feedback.text = "")
	add_child(_fb_timer)

func _build_combo() -> void:
	# Diner Dash style combo counter
	_combo_lbl = _lbl("", Vector2(LANE_X - 50, 100), 22, Color("#FFD93D"))
	_combo_lbl.z_index = 60

func _build_queue_slots() -> void:
	# Overflow: visible slots that pulse red when nearly full
	var max_size: int = _cfg.get("queue_size", 3) as int
	for i in max_size:
		var slot := ColorRect.new()
		slot.color = Color(0.15, 0.12, 0.08, 0.7)
		slot.set_position(Vector2(LANE_X + 50, FRONT_Y + i * CITIZEN_GAP - 48))
		slot.set_size(Vector2(60, 90))
		slot.z_index = -1
		add_child(slot)
		_slot_rects.append(slot)
		var lbl := Label.new()
		lbl.text = "Slot %d" % (i+1)
		lbl.set_position(Vector2(LANE_X + 52, FRONT_Y + i * CITIZEN_GAP - 42))
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.4, 0.3, 0.2))
		add_child(lbl)

func _build_deque_ui() -> void:
	# L5: Two gate indicators
	var front_gate := ColorRect.new()
	front_gate.color = Color(0.1, 0.5, 0.1, 0.5)
	front_gate.set_position(Vector2(LANE_X - 55, FRONT_Y - 60))
	front_gate.set_size(Vector2(110, 30)); front_gate.z_index = -1
	add_child(front_gate)
	var fl := Label.new(); fl.text = "F = FRONT GATE"
	fl.set_position(Vector2(LANE_X - 53, FRONT_Y - 56))
	fl.add_theme_font_size_override("font_size", 10)
	fl.add_theme_color_override("font_color", Color("#6BCB77")); add_child(fl)

	var bot_y: float = FRONT_Y + 4 * CITIZEN_GAP
	var back_gate := ColorRect.new()
	back_gate.color = Color(0.5, 0.3, 0.0, 0.5)
	back_gate.set_position(Vector2(LANE_X - 55, bot_y))
	back_gate.set_size(Vector2(110, 30)); back_gate.z_index = -1
	add_child(back_gate)
	var bl := Label.new(); bl.text = "B = BACK GATE"
	bl.set_position(Vector2(LANE_X - 53, bot_y + 4))
	bl.add_theme_font_size_override("font_size", 10)
	bl.add_theme_color_override("font_color", Color("#FF9900")); add_child(bl)

# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey:
		var ke := ev as InputEventKey
		if not ke.pressed: return
		match ke.keycode:
			KEY_SPACE, KEY_E:
				if _mechanic == "deque":
					_gate_ref.player_dequeue_front()
				else:
					_try_serve_front()
			KEY_F:
				if _mechanic == "deque": _gate_ref.player_dequeue_front()
			KEY_B:
				if _mechanic == "deque": _gate_ref.player_dequeue_back()
			KEY_R:
				_gate_ref.player_reject_enemy()
			KEY_Q:
				if _dsa_panel: _dsa_panel.toggle()

func _try_serve_front() -> void:
	if _queue_ref.is_empty(): return
	var front: Dictionary = _queue_ref.peek_front()
	var fid: int = front.get("id", -1) as int
	var fnode: CitizenNode = _citizen_nodes.get(fid, null) as CitizenNode
	if fnode and fnode.has_arrived():
		_gate_ref.player_picks(fid)

# ── Citizens ──────────────────────────────────────────────────────────────────

func on_citizen_arrived(c: Dictionary) -> void:
	var cid: int = c.get("id",-1) as int
	_waiting_order.append(cid)
	var node: CitizenNode = (load("res://scenes/chapters/queue/CitizenNode.tscn") as PackedScene
		).instantiate() as CitizenNode
	node.position = Vector2(LANE_X, SPAWN_Y)
	node.z_index  = 10
	# Add to tree FIRST so get_tree() works inside setup()
	add_child(node)
	node.setup(c, SPAWN_Y, FRONT_Y)
	# Only serve when citizen has physically reached the gate
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
	_flash_gate(true)
	_add_combo()
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
	_flash_gate(false)
	_reposition_all()

func on_citizen_angry(cid: int, msg: String) -> void:
	if _citizen_nodes.has(cid):
		(_citizen_nodes[cid] as CitizenNode).show_anger(msg)
	_flash_gate(false)
	_combo = 0; _combo_lbl.text = ""

func on_enemy_rejected(cid: int) -> void:
	if _citizen_nodes.has(cid):
		(_citizen_nodes[cid] as CitizenNode).play_slash_anim()
		_citizen_nodes.erase(cid)
	_waiting_order.erase(cid)
	_flash_gate(true)
	_add_combo()
	_reposition_all()

func on_overflow_visual() -> void:
	# Flash all slots red — danger signal like Overcooked burner on fire
	for slot in _slot_rects:
		var s := slot as ColorRect
		var tw := create_tween()
		tw.tween_property(s, "color", Color(0.8, 0.1, 0.1, 0.85), 0.1)
		tw.tween_property(s, "color", Color(0.15, 0.12, 0.08, 0.7), 0.4)
	_flash_gate(false)
	_combo = 0; _combo_lbl.text = ""

func on_drag_requested(_cid: int) -> void: pass
func on_deque_prompt(_cid: int, _gate: String) -> void: pass

func _add_combo() -> void:
	_combo += 1
	_combo_timer = 3.0
	if _combo >= 2:
		_combo_lbl.text = "x%d COMBO!" % _combo
		var tw := create_tween()
		tw.tween_property(_combo_lbl, "scale", Vector2(1.3,1.3), 0.08)
		tw.tween_property(_combo_lbl, "scale", Vector2(1.0,1.0), 0.12)

func _reposition_all() -> void:
	var sz: int = _waiting_order.size()
	for i in sz:
		var cid: int = _waiting_order[i]
		if _citizen_nodes.has(cid):
			var node := _citizen_nodes[cid] as CitizenNode
			var ty: float = FRONT_Y + i * CITIZEN_GAP
			node.set_target_y(ty)
	# Color overflow slots by occupancy
	for i in _slot_rects.size():
		var slot := _slot_rects[i] as ColorRect
		if i < sz:
			var ratio: float = float(sz) / float(_cfg.get("queue_size",3) as int)
			slot.color = Color(0.6, 0.1, 0.1, 0.7) if ratio >= 0.75 else Color(0.3, 0.5, 0.2, 0.7)
		else:
			slot.color = Color(0.15, 0.12, 0.08, 0.7)

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
