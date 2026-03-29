extends Node2D

# ═══════════════════════════════════════════════════
# Q_Game.gd
# Top-down core gameplay scene.
# Manages citizen nodes walking up the lane,
# serve panel on the left, HUD, DSA panel toggle.
# ═══════════════════════════════════════════════════

signal citizen_clicked(citizen_id: int)

const LANE_X:     float = 640.0
const GATE_Y:     float = 90.0
const SPAWN_Y:    float = 700.0
const CITIZEN_GAP: float = 90.0   # spacing between citizens in line
const FRONT_Y:    float = 160.0   # Y position of front citizen (at gate)

var _cfg:         Dictionary = {}
var _queue_ref: Node
var _gate_ref: Node
var _dsa_panel: Node2D

var _citizen_nodes: Dictionary = {}   # citizen_id -> Q_CitizenNode
var _waiting_order: Array      = []   # ordered list of citizen ids (front first)

# UI nodes
var _hud_score:   Label
var _hud_lives:   Label
var _hud_level:   Label
var _hud_dsa_tag: Label
var _feedback:    Label
var _fb_timer:    Timer
var _serve_panel: Control
var _serve_btns:  Dictionary = {}    # citizen_id -> Button
var _q_btn:       Button
var _world: Node2D

func setup(cfg: Dictionary, qm: Node, gk: Node, dp: Node2D) -> void:
	_cfg       = cfg
	_queue_ref = qm
	_gate_ref  = gk
	_dsa_panel = dp

func _ready() -> void:
	_build_world()
	_build_hud()
	_build_serve_panel()
	_build_feedback()

# ─── Q_World ────────────────────────────────────────

func _build_world() -> void:
	_world = (load("res://scripts/chapters/queue/World.gd") as GDScript).new()
	_world.name = "Q_World"
	add_child(_world)

	# Add DSA panel on top of world
	if _dsa_panel and not _dsa_panel.get_parent():
		add_child(_dsa_panel)
	elif _dsa_panel and _dsa_panel.get_parent() != self:
		_dsa_panel.reparent(self)

# ─── HUD ─────────────────────────────────────────

func _build_hud() -> void:
	var hud := ColorRect.new()
	hud.color = Color(0, 0, 0, 0.7)
	hud.set_position(Vector2(0, 0))
	hud.set_size(Vector2(1280, 48))
	add_child(hud)

	_hud_level = _lbl("", Vector2(12, 8), 13, Color("#4D96FF"))
	_hud_dsa_tag = _lbl("", Vector2(12, 28), 11, Color("#445544"))

	if not _cfg.is_empty():
		_hud_level.text   = "Level %d  —  %s" % [_cfg.get("level",1), _cfg.get("title","")]
		_hud_dsa_tag.text = "DSA: " + _cfg.get("dsainfo","")

	_hud_score = _lbl("Score: 0", Vector2(860, 14), 16, Color("#FFD93D"))
	_hud_lives = _lbl("♥ ♥ ♥",   Vector2(1080, 10), 20, Color("#FF6B6B"))

	# Q button
	_q_btn = Button.new()
	_q_btn.text = "[Q]  Queue panel"
	_q_btn.set_position(Vector2(1150, 52))
	_q_btn.set_size(Vector2(120, 28))
	_q_btn.add_theme_font_size_override("font_size", 11)
	_q_btn.pressed.connect(_toggle_dsa)
	add_child(_q_btn)

# ─── Serve Panel (left side) ─────────────────────

func _build_serve_panel() -> void:
	var panel_bg := ColorRect.new()
	panel_bg.color = Color(0, 0, 0, 0.75)
	panel_bg.set_position(Vector2(0, 48))
	panel_bg.set_size(Vector2(200, 672))
	add_child(panel_bg)

	var title := _lbl("Click to serve:", Vector2(10, 58), 12, Color("#FFD93D"))

	var hint := _lbl(
		"Green = front\n(serve first!)",
		Vector2(10, 78), 11, Color("#445544"))

	_serve_panel = Control.new()
	_serve_panel.set_position(Vector2(8, 106))
	_serve_panel.set_size(Vector2(186, 610))
	add_child(_serve_panel)

# ─── Feedback ────────────────────────────────────

func _build_feedback() -> void:
	_feedback = _lbl("", Vector2(210, 54), 14, Color("#6BCB77"))
	_fb_timer = Timer.new()
	_fb_timer.wait_time = 3.0
	_fb_timer.one_shot  = true
	_fb_timer.timeout.connect(func(): _feedback.text = "")
	add_child(_fb_timer)

# ─── Input ───────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and ke.keycode == KEY_Q:
			_toggle_dsa()

func _toggle_dsa() -> void:
	if _dsa_panel:
		_dsa_panel.toggle()

# ─── Citizens ────────────────────────────────────

func on_citizen_arrived(c: Dictionary) -> void:
	_waiting_order.append(c["id"] as int)
	_spawn_citizen_node(c)
	_rebuild_serve_buttons()
	_reposition_all_citizens()

func on_citizen_served(c: Dictionary) -> void:
	var cid: int = c["id"] as int
	_remove_citizen(cid)

func on_citizen_expired(c: Dictionary) -> void:
	var cid: int = c["id"] as int
	_remove_citizen(cid)

func _remove_citizen(cid: int) -> void:
	if _citizen_nodes.has(cid):
		var node: Node2D = _citizen_nodes[cid]
		node.play_serve_anim()
		_citizen_nodes.erase(cid)
	_waiting_order.erase(cid)
	if _serve_btns.has(cid):
		_serve_btns[cid].queue_free()
		_serve_btns.erase(cid)
	_reposition_all_citizens()
	_refresh_serve_buttons()

func _spawn_citizen_node(c: Dictionary) -> void:
	var node: Node2D = (load("res://scripts/chapters/queue/CitizenNode.gd") as GDScript).new()
	node.name = "Citizen_%d" % (c["id"] as int)

	# Enable input — needs an Area2D or CollisionShape for _input_event
	# We use a simpler approach: direct mouse button checking in _process
	node.setup(c, SPAWN_Y, SPAWN_Y)
	node.position = Vector2(LANE_X, SPAWN_Y)
	node.z_index = 10

	# Connect click via Area2D pattern using simple input detection
	var cid: int = c["id"] as int
	node.clicked.connect(func(id: int): emit_signal("citizen_clicked", id))

	# Add CollisionShape so _input_event fires
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 28.0
	shape.shape = circle
	area.add_child(shape)
	area.input_event.connect(
		func(_vp, event, _idx):
			if event is InputEventMouseButton:
				var mb := event as InputEventMouseButton
				if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
					emit_signal("citizen_clicked", cid)
	)
	node.add_child(area)

	add_child(node)
	_citizen_nodes[cid] = node

func _reposition_all_citizens() -> void:
	for i in _waiting_order.size():
		var cid: int = _waiting_order[i]
		if _citizen_nodes.has(cid):
			var node: Node2D = _citizen_nodes[cid]
			var target_y: float = FRONT_Y + i * CITIZEN_GAP
			node.set_target_y(target_y)
			node.is_front = (i == 0)

func _process(_delta: float) -> void:
	# Update patience bars each frame
	for cid: int in _citizen_nodes:
		var node: Node2D = _citizen_nodes[cid]
		node.patience_ratio = _gate_ref.get_patience_ratio(cid)

# ─── Serve Panel ─────────────────────────────────

func _rebuild_serve_buttons() -> void:
	for child in _serve_panel.get_children():
		child.queue_free()
	_serve_btns.clear()

	var btn_h: float = 72.0
	var gap:   float = 8.0

	for i in _waiting_order.size():
		var cid: int = _waiting_order[i]
		var pos: int = _queue_ref.get_position(cid)
		if pos < 0: continue

		var c: Dictionary = _queue_ref.queue[pos]
		var btn := Button.new()
		btn.text = "%s\n[%s]" % [c["name"], c["label"]]
		btn.set_position(Vector2(0, i * (btn_h + gap)))
		btn.set_size(Vector2(186, btn_h))
		btn.add_theme_font_size_override("font_size", 13)

		if i == 0:
			btn.add_theme_color_override("font_color", Color("#6BCB77"))
		else:
			btn.add_theme_color_override("font_color", Color("#aaaacc"))
			btn.modulate = Color(1, 1, 1, 0.6)

		btn.pressed.connect(func(): emit_signal("citizen_clicked", cid))
		_serve_panel.add_child(btn)
		_serve_btns[cid] = btn

func _refresh_serve_buttons() -> void:
	_rebuild_serve_buttons()

func refresh_citizen_buttons(_snapshot: Array) -> void:
	_rebuild_serve_buttons()

# ─── Feedback / HUD updates ──────────────────────

func show_feedback(msg: String, good: bool) -> void:
	_feedback.text = msg
	_feedback.add_theme_color_override("font_color",
		Color("#6BCB77") if good else Color("#FF6B6B"))
	_fb_timer.start()

func update_score(v: int) -> void:
	_hud_score.text = "Score: %d" % v

func update_lives(v: int) -> void:
	var h := ""
	for i in 3: h += "♥ " if i < v else "♡ "
	_hud_lives.text = h
	_hud_lives.add_theme_color_override("font_color",
		Color("#FF0000") if v <= 1 else Color("#FF6B6B"))

# ─── Helper ──────────────────────────────────────

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.set_position(pos)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	return l
