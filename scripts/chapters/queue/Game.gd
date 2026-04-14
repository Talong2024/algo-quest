extends Node2D
## Q_Game — mechanic-driven gameplay scene.
##
## Controls per mechanic:
##  ALL:      SPACE / E / click = serve front citizen
##  L4 only:  drag citizen to reorder by priority
##  L5 only:  F = dequeue front gate, B = dequeue back gate

signal citizen_clicked(citizen_id: int)

const LANE_X:      float = 640.0
const SPAWN_Y:     float = 750.0
const FRONT_Y:     float = 210.0
const CITIZEN_GAP: float = 105.0

var _cfg:       Dictionary = {}
var _queue_ref: Node
var _gate_ref:  Node
var _dsa_panel: Node2D
var _mechanic:  String = "fifo"

var _citizen_nodes: Dictionary = {}
var _waiting_order: Array      = []

# Dragging (L4)
var _drag_node:   Node2D = null
var _drag_cid:    int    = -1

# UI
var _hud_score:    Label
var _hud_lives:    Label
var _feedback:     Label
var _fb_timer:     Timer
var _controls_lbl: Label
var _mechanic_bar: ColorRect   # L2 overflow flash
var _deque_hint:   Label       # L5 gate prompt
var _world:        Node2D

# Queue slot visuals (L2 overflow teaching)
var _slot_rects: Array = []

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
	_build_feedback()
	if _mechanic == "overflow":
		_build_queue_slots()
	if _mechanic == "deque":
		_build_deque_ui()

# ── World ─────────────────────────────────────────────────────────────────────

func _build_world() -> void:
	_world = (load("res://scenes/chapters/queue/World.tscn") as PackedScene).instantiate()
	_world.name = "Q_World"
	add_child(_world)
	if _dsa_panel:
		if not _dsa_panel.get_parent():
			add_child(_dsa_panel)
		elif _dsa_panel.get_parent() != self:
			_dsa_panel.reparent(self)

# ── HUD ───────────────────────────────────────────────────────────────────────

func _build_hud() -> void:
	var bar := ColorRect.new()
	bar.color = Color(0,0,0,0.8)
	bar.set_position(Vector2.ZERO)
	bar.set_size(Vector2(1280,52))
	add_child(bar)

	if not _cfg.is_empty():
		_lbl("Level %d — %s" % [_cfg.get("level",1), _cfg.get("title","")],
			Vector2(12,8), 13, Color("#4D96FF"))
		_lbl("DSA: " + _cfg.get("dsainfo",""), Vector2(12,28), 10, Color("#445566"))

	_hud_score = _lbl("Score: 0", Vector2(820,14), 16, Color("#FFD93D"))
	_hud_lives = _lbl("♥ ♥ ♥",   Vector2(1080,10), 20, Color("#FF6B6B"))

# ── Controls hint ─────────────────────────────────────────────────────────────

func _build_controls_hint() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0,0,0,0.7)
	bg.set_position(Vector2(0,54))
	bg.set_size(Vector2(250, 52 if _mechanic != "deque" else 68))
	add_child(bg)

	match _mechanic:
		"fifo","overflow","patience":
			_lbl("SPACE / E — serve front citizen", Vector2(8,60), 11, Color("#aaccaa"))
			_lbl("Click citizen to serve",           Vector2(8,76), 11, Color("#aaccaa"))
		"priority":
			_lbl("SPACE / E — serve front citizen",  Vector2(8,60), 11, Color("#aaccaa"))
			_lbl("DRAG VIP citizens to reorder",     Vector2(8,76), 11, Color("#FFD93D"))
		"deque":
			_lbl("F — serve FRONT gate",             Vector2(8,60), 11, Color("#6BCB77"))
			_lbl("B — serve BACK gate",              Vector2(8,76), 11, Color("#FF9900"))
			_lbl("Check citizen's gate label!",      Vector2(8,92), 10, Color("#aaaaaa"))

# ── L2: Queue slot visuals ────────────────────────────────────────────────────

func _build_queue_slots() -> void:
	var max_s: int = _queue_ref.max_size if _queue_ref else 4
	for i in max_s:
		var slot := ColorRect.new()
		slot.color = Color("#1a1a2e", 0.8)
		# Slots shown vertically in the lane
		slot.set_position(Vector2(LANE_X - 30, FRONT_Y + i * CITIZEN_GAP - 45))
		slot.set_size(Vector2(60, 90))
		slot.z_index = -1
		add_child(slot)
		_slot_rects.append(slot)
		# Slot number label
		var lbl := Label.new()
		lbl.text = str(i + 1)
		lbl.set_position(Vector2(LANE_X + 34, FRONT_Y + i * CITIZEN_GAP - 15))
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color("#445566"))
		add_child(lbl)

func _update_slot_colors() -> void:
	if _slot_rects.is_empty(): return
	var used: int = _queue_ref.size() if _queue_ref else 0
	var full: bool = _queue_ref.is_full() if _queue_ref else false
	for i in _slot_rects.size():
		var slot: ColorRect = _slot_rects[i] as ColorRect
		if i < used:
			slot.color = Color("#FF6B6B", 0.25) if full else Color("#4D96FF", 0.15)
		else:
			slot.color = Color("#1a1a2e", 0.5)

# ── L5: Deque UI ──────────────────────────────────────────────────────────────

func _build_deque_ui() -> void:
	# Front gate label (top)
	var fg := _lbl("↑ FRONT GATE  [F]", Vector2(LANE_X - 60, 100), 13, Color("#6BCB77"))
	# Back gate label (bottom)
	var bg2 := _lbl("↓ BACK GATE  [B]",  Vector2(LANE_X - 60, 680), 13, Color("#FF9900"))
	_deque_hint = _lbl("", Vector2(400, 56), 14, Color("#FFD93D"))

# ── Feedback ──────────────────────────────────────────────────────────────────

func _build_feedback() -> void:
	_feedback = _lbl("", Vector2(260, 56), 14, Color("#6BCB77"))
	_fb_timer = Timer.new()
	_fb_timer.wait_time = 3.5
	_fb_timer.one_shot  = true
	_fb_timer.timeout.connect(func(): _feedback.text = "")
	add_child(_fb_timer)

# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey:
		var ke: InputEventKey = ev as InputEventKey
		if not ke.pressed: return
		match ke.keycode:
			KEY_SPACE, KEY_E:
				if _mechanic == "deque":
					_gate_ref.player_dequeue_front()
				else:
					# Serve the front citizen
					if not _queue_ref.is_empty():
						var front: Dictionary = _queue_ref.peek_front()
						_gate_ref.player_picks(front["id"] as int)
			KEY_F:
				if _mechanic == "deque":
					_gate_ref.player_dequeue_front()
			KEY_B:
				if _mechanic == "deque":
					_gate_ref.player_dequeue_back()
			KEY_Q:
				if _dsa_panel: _dsa_panel.toggle()

	# Drag handling (L4 priority)
	if _mechanic == "priority":
		if ev is InputEventMouseMotion and _drag_node:
			_drag_node.position = get_global_mouse_position()

		if ev is InputEventMouseButton:
			var mb: InputEventMouseButton = ev as InputEventMouseButton
			if not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _drag_node:
				_finish_drag()

# ── Process ───────────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	for cid: int in _citizen_nodes:
		var node: Node2D = _citizen_nodes[cid] as Node2D
		node.patience_ratio = _gate_ref.get_patience_ratio(cid)
	if _mechanic == "overflow":
		_update_slot_colors()

# ── Citizen spawn / remove ────────────────────────────────────────────────────

func on_citizen_arrived(c: Dictionary) -> void:
	_waiting_order.append(c["id"] as int)
	_spawn_citizen_node(c)
	_reposition_all()

func on_citizen_served(c: Dictionary) -> void:
	_remove_citizen(c["id"] as int)

func on_citizen_expired(c: Dictionary) -> void:
	_remove_citizen(c["id"] as int)

func _spawn_citizen_node(c: Dictionary) -> void:
	var node: Node2D = (load("res://scenes/chapters/queue/CitizenNode.tscn") as PackedScene).instantiate()
	node.name     = "Citizen_%d" % (c["id"] as int)
	node.position = Vector2(LANE_X, SPAWN_Y)
	node.z_index  = 10
	var cid: int  = c["id"] as int
	node.clicked.connect(func(id: int): _gate_ref.player_picks(id))
	# L4: long-press / right-click starts drag
	if _mechanic == "priority":
		node.clicked.connect(func(id: int): _start_drag(id))
	add_child(node)
	node.setup(c, SPAWN_Y, SPAWN_Y)
	_citizen_nodes[cid] = node

func _remove_citizen(cid: int) -> void:
	if _citizen_nodes.has(cid):
		(_citizen_nodes[cid] as Node2D).play_serve_anim()
		_citizen_nodes.erase(cid)
	_waiting_order.erase(cid)
	_reposition_all()

func _reposition_all() -> void:
	for i in _waiting_order.size():
		var cid: int = _waiting_order[i]
		if _citizen_nodes.has(cid):
			(_citizen_nodes[cid] as Node2D).set_target_y(FRONT_Y + i * CITIZEN_GAP)

# ── Drag (L4) ─────────────────────────────────────────────────────────────────

func _start_drag(cid: int) -> void:
	if not _citizen_nodes.has(cid): return
	_drag_node = _citizen_nodes[cid] as Node2D
	_drag_cid  = cid
	_drag_node.start_drag()

func _finish_drag() -> void:
	if not _drag_node: return
	# Compute which queue slot the drop lands in
	var drop_y: float  = _drag_node.position.y
	var new_pos: int   = int((drop_y - FRONT_Y + CITIZEN_GAP * 0.5) / CITIZEN_GAP)
	new_pos            = clampi(new_pos, 0, _waiting_order.size() - 1)
	_gate_ref.player_reorder(_drag_cid, new_pos)
	_drag_node.stop_drag()
	_drag_node = null
	_drag_cid  = -1
	_reposition_all()

# ── GateKeeper signal handlers ────────────────────────────────────────────────

func show_feedback(msg: String, good: bool) -> void:
	_feedback.text = msg
	_feedback.add_theme_color_override("font_color",
		Color("#6BCB77") if good else Color("#FF6B6B"))
	_fb_timer.start()
	if not good:
		_flash_wrong()

func _flash_wrong() -> void:
	# Red screen flash so wrong answer has immediate visual impact
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.1, 0.1, 0.0)
	flash.set_position(Vector2.ZERO)
	flash.set_size(Vector2(1280, 720))
	flash.z_index = 200
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.35, 0.06)
	tw.tween_property(flash, "color:a", 0.0,  0.25)
	tw.tween_callback(flash.queue_free)

func update_score(v: int) -> void:
	_hud_score.text = "Score: %d" % v

func update_lives(v: int) -> void:
	var h := ""
	for i in 3: h += "♥ " if i < v else "♡ "
	_hud_lives.text = h
	_hud_lives.add_theme_color_override("font_color",
		Color("#FF0000") if v <= 1 else Color("#FF6B6B"))

func on_citizen_angry(citizen_id: int, msg: String) -> void:
	if _citizen_nodes.has(citizen_id):
		(_citizen_nodes[citizen_id] as CitizenNode).show_anger(msg)

func on_drag_requested(citizen_id: int) -> void:
	show_feedback("⬆ Drag the VIP to the correct position!", false)
	if _citizen_nodes.has(citizen_id):
		# Flash the citizen to indicate it's draggable
		var node: Node2D = _citizen_nodes[citizen_id] as Node2D
		var tw := node.create_tween()
		tw.tween_property(node, "modulate", Color("#FFD93D"), 0.2)
		tw.tween_property(node, "modulate", Color.WHITE,      0.2)
		tw.set_loops(3)

func on_overflow_visual() -> void:
	# Flash all slots red
	for slot: ColorRect in _slot_rects:
		slot.color = Color("#FF0000", 0.4)
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(func(): _update_slot_colors())

func on_deque_prompt(citizen_id: int, gate: String) -> void:
	if gate == "any":
		show_feedback("Press F (front) or B (back) to serve", true)
	else:
		show_feedback("This citizen needs the %s gate! Press %s" % [
			gate.to_upper(),
			"F" if gate == "front" else "B"
		], false)

# ── Helper ────────────────────────────────────────────────────────────────────

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.set_position(pos)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	return l
