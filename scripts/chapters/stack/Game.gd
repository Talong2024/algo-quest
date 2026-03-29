extends Node2D

# ═══════════════════════════════════════════════════
# S_Game.gd  —  Top-down Castle of Echoes gameplay.
# Runes float in the corridor from wizard → door.
# Click TOP rune to pop. Left panel = rune buttons.
# ═══════════════════════════════════════════════════

signal rune_clicked(rune_id: int)

const LANE_X:    float = 640.0
const DOOR_Y:    float = 80.0
const WIZARD_Y:  float = 620.0
const TOP_Y:     float = 150.0   # Y of top rune slot
const RUNE_GAP:  float = 88.0    # vertical spacing between rune slots
const SPAWN_Y:   float = 700.0

var _cfg:         Dictionary = {}
var _stack_ref: Node
var _caster_ref: Node
var _dsa_panel: Node2D

var _world: Node2D
var _rune_nodes:  Dictionary = {}   # rune_id -> S_RuneNode
var _rune_order:  Array      = []   # bottom → top (push order)
var _all_runes:   Array      = []   # full rune list for this level

# UI
var _hud_score:   Label
var _hud_lives:   Label
var _hud_level:   Label
var _hud_dsa:     Label
var _phase_lbl:   Label
var _feedback:    Label
var _fb_timer:    Timer
var _pop_panel:   Control
var _pop_btns:    Dictionary = {}
var _q_btn:       Button

func setup(cfg: Dictionary, sm: Node, sc: Node, dp: Node2D) -> void:
	_cfg        = cfg
	_stack_ref  = sm
	_caster_ref = sc
	_dsa_panel  = dp

func _ready() -> void:
	_build_world()
	_build_hud()
	_build_pop_panel()
	_build_feedback()

func _build_world() -> void:
	_world      = (load("res://scripts/chapters/stack/CastleWorld.gd") as GDScript).new()
	_world.name = "S_CastleWorld"
	_world.total_locks = _cfg.get("stack_size", 3) as int
	add_child(_world)

	if _dsa_panel:
		if _dsa_panel.get_parent(): _dsa_panel.reparent(self)
		else: add_child(_dsa_panel)

func _build_hud() -> void:
	var hud := ColorRect.new()
	hud.color = Color(0, 0, 0, 0.72)
	hud.set_position(Vector2.ZERO)
	hud.set_size(Vector2(1280, 48))
	add_child(hud)

	_hud_level = _lbl("", Vector2(12, 8),  13, Color("#C77DFF"))
	_hud_dsa   = _lbl("", Vector2(12, 28), 11, Color("#443355"))

	if not _cfg.is_empty():
		_hud_level.text = "Level %d  —  %s" % [_cfg.get("level",1), _cfg.get("title","")]
		_hud_dsa.text   = "DSA: " + _cfg.get("dsainfo","")

	_hud_score = _lbl("Score: 0", Vector2(860, 14), 16, Color("#FFD93D"))
	_hud_lives = _lbl("♥ ♥ ♥",   Vector2(1080, 10), 20, Color("#FF6B6B"))

	_phase_lbl = _lbl("📖 PUSH phase — watch the wizard cast...",
		Vector2(210, 54), 13, Color("#FFD93D"))

	_q_btn = Button.new()
	_q_btn.text = "[Q]  Stack panel"
	_q_btn.set_position(Vector2(1150, 52))
	_q_btn.set_size(Vector2(120, 28))
	_q_btn.add_theme_font_size_override("font_size", 11)
	_q_btn.pressed.connect(_toggle_dsa)
	add_child(_q_btn)

func _build_pop_panel() -> void:
	var panel_bg := ColorRect.new()
	panel_bg.color = Color(0, 0, 0, 0.78)
	panel_bg.set_position(Vector2(0, 48))
	panel_bg.set_size(Vector2(200, 672))
	add_child(panel_bg)

	_lbl("Pop runes (LIFO):", Vector2(10, 58), 12, Color("#C77DFF"))
	_lbl("Only TOP is\nclickable!", Vector2(10, 78), 11, Color("#443355"))

	_pop_panel = Control.new()
	_pop_panel.set_position(Vector2(8, 114))
	_pop_panel.set_size(Vector2(186, 600))
	add_child(_pop_panel)

func _build_feedback() -> void:
	_feedback = _lbl("", Vector2(210, 72), 14, Color("#C77DFF"))
	_fb_timer = Timer.new()
	_fb_timer.wait_time = 3.0
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

# ─── Rune Nodes ───────────────────────────────────

func set_all_runes(runes: Array) -> void:
	_all_runes = runes

func on_rune_pushed(r: Dictionary) -> void:
	_rune_order.append(r["id"] as int)
	_spawn_rune_node(r)
	_reposition_runes()
	_rebuild_pop_buttons()

func on_rune_popped(r: Dictionary) -> void:
	var rid: int = r["id"] as int
	if _rune_nodes.has(rid):
		(_rune_nodes[rid]).pop_anim()
		_rune_nodes.erase(rid)
	_rune_order.erase(rid)
	if _pop_btns.has(rid):
		_pop_btns[rid].queue_free()
		_pop_btns.erase(rid)
	_reposition_runes()
	_rebuild_pop_buttons()

func _spawn_rune_node(r: Dictionary) -> void:
	var node: Node2D = (load("res://scripts/chapters/stack/RuneNode.gd") as GDScript).new()
	node.name = "Rune_%d" % (r["id"] as int)
	node.setup(r, SPAWN_Y, SPAWN_Y)
	node.position = Vector2(LANE_X, SPAWN_Y)
	node.z_index  = 10

	var rid: int = r["id"] as int
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 32.0
	shape.shape   = circle
	area.add_child(shape)
	area.input_event.connect(func(_vp, event, _idx):
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				emit_signal("rune_clicked", rid)
	)
	node.add_child(area)
	add_child(node)
	_rune_nodes[rid] = node

func _reposition_runes() -> void:
	var sz: int = _rune_order.size()
	for i in sz:
		var rid: int = _rune_order[i]
		if not _rune_nodes.has(rid): continue
		var node: Node2D = _rune_nodes[rid]
		# Bottom rune is furthest from door, top is closest
		var ty: float = TOP_Y + (sz - 1 - i) * RUNE_GAP
		node.set_target(ty, i, sz, i == sz - 1)

	# Update world door
	_world.queue_redraw()

# ─── Pop Panel ────────────────────────────────────

func _rebuild_pop_buttons() -> void:
	for child in _pop_panel.get_children():
		child.queue_free()
	_pop_btns.clear()

	var btn_h: float = 64.0
	var gap:   float = 6.0
	var sz:    int   = _rune_order.size()

	# Show top → bottom (reversed for panel readability)
	for i in sz:
		var stack_idx: int = sz - 1 - i   # top = 0 in panel
		var rid: int = _rune_order[stack_idx]
		# Find rune data
		var rdata: Dictionary = {}
		for rd in _all_runes:
			if (rd["id"] as int) == rid:
				rdata = rd
				break
		if rdata.is_empty(): continue

		var is_top: bool = (stack_idx == sz - 1)
		var btn := Button.new()
		btn.text = "%s %s\n%s" % [
			rdata.get("symbol","?"),
			rdata.get("name","?"),
			"← TOP (click!)" if is_top else "buried — idx %d" % stack_idx
		]
		btn.set_position(Vector2(0, i * (btn_h + gap)))
		btn.set_size(Vector2(186, btn_h))
		btn.add_theme_font_size_override("font_size", 12)
		btn.disabled = not is_top

		if is_top:
			btn.add_theme_color_override("font_color", Color("#C77DFF"))
		else:
			btn.add_theme_color_override("font_color", Color("#443355"))
			btn.modulate = Color(1, 1, 1, 0.45)

		btn.pressed.connect(func(): emit_signal("rune_clicked", rid))
		_pop_panel.add_child(btn)
		_pop_btns[rid] = btn

# ─── Phase change ─────────────────────────────────

func on_push_phase_done() -> void:
	_phase_lbl.text = "✨ POP phase — click the TOP rune (LIFO!)!"
	_phase_lbl.add_theme_color_override("font_color", Color("#C77DFF"))
	if _dsa_panel: _dsa_panel.update(_stack_ref.stack.duplicate(),
		_stack_ref.max_size, "pop")
	_world.phase = "pop"
	_world.queue_redraw()

func on_door_unlock(count: int) -> void:
	_world.door_unlocked_count = count
	_world.queue_redraw()

# ─── HUD ──────────────────────────────────────────

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
