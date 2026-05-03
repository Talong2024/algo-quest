extends Node2D
## S_Game — Stack chapter. Castle corridor. Rune stones stack in the lane.
## PUSH: wizard auto-casts spells (stone appears at bottom, stack grows up)
## POP: player clicks TOP stone OR presses SPACE to pop (LIFO order)
## Added: visual pop-order arrows, key hint on top stone, combo rewards

signal rune_clicked(rune_id: int)

const LANE_X:    float = 640.0
const DOOR_Y:    float = 60.0
const WIZARD_Y:  float = 620.0
const TOP_Y:     float = 130.0
const RUNE_GAP:  float = 86.0
const SPAWN_Y:   float = 700.0

var _cfg:       Dictionary = {}
var _stack_ref: Node
var _caster_ref:Node
var _dsa_panel: Node2D

var _world: Node2D
var _rune_nodes:  Dictionary = {}
var _rune_order:  Array      = []
var _all_runes:   Array      = []

var _hud_score:  Label
var _hud_lives:  Label
var _phase_lbl:  Label
var _feedback:   Label
var _fb_timer:   Timer
var _pop_panel:  Control
var _pop_btns:   Dictionary = {}
var _combo:      int   = 0
var _combo_timer:float = 0.0
var _combo_lbl:  Label
var _key_hint:   Label   # always-visible SPACE hint during pop phase

func setup(cfg: Dictionary, sm: Node, sc: Node, dp: Node2D) -> void:
	_cfg = cfg; _stack_ref = sm; _caster_ref = sc; _dsa_panel = dp

func _ready() -> void:
	_build_world()
	_build_hud()
	_build_pop_panel()
	_build_feedback()
	_build_combo()

func _build_world() -> void:
	_world = (load("res://scripts/chapters/stack/CastleWorld.gd") as GDScript).new()
	_world.name = "S_CastleWorld"
	_world.total_locks = _cfg.get("stack_size", 3) as int
	add_child(_world)
	if _dsa_panel:
		if _dsa_panel.get_parent(): _dsa_panel.reparent(self)
		else: add_child(_dsa_panel)

func _build_hud() -> void:
	var bar := ColorRect.new()
	bar.color = Color(0,0,0,0.75)
	bar.set_position(Vector2.ZERO); bar.set_size(Vector2(1280,48)); add_child(bar)

	_hud_score = _lbl("Score: 0",  Vector2(860,14), 16, Color("#FFD93D"))
	_hud_lives = _lbl("♥ ♥ ♥",    Vector2(1080,10), 20, Color("#FF6B6B"))

	if not _cfg.is_empty():
		_lbl("Level %d  —  %s" % [_cfg.get("level",1), _cfg.get("title","")],
			Vector2(12,8), 13, Color("#C77DFF"))
		_lbl("DSA: " + _cfg.get("dsainfo",""), Vector2(12,28), 10, Color("#443355"))

	_phase_lbl = _lbl("📖 PUSH phase — watch the wizard cast...",
		Vector2(210,54), 13, Color("#FFD93D"))

	# Key hint — always shows during pop phase
	_key_hint = _lbl("", Vector2(440, 54), 13, Color("#C77DFF"))

	var q_btn := Button.new()
	q_btn.text = "[Q] Stack panel"
	q_btn.set_position(Vector2(1150,52)); q_btn.set_size(Vector2(120,28))
	q_btn.add_theme_font_size_override("font_size", 11)
	q_btn.pressed.connect(func(): if _dsa_panel: _dsa_panel.toggle())
	add_child(q_btn)

func _build_pop_panel() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0,0,0,0.75)
	bg.set_position(Vector2(0,48)); bg.set_size(Vector2(200,672)); add_child(bg)
	_lbl("Stack (LIFO):", Vector2(10,58), 12, Color("#C77DFF"))
	_lbl("Pop TOP first →", Vector2(10,76), 10, Color("#6a5a8a"))
	_pop_panel = Control.new()
	_pop_panel.set_position(Vector2(8,110)); _pop_panel.set_size(Vector2(186,600))
	add_child(_pop_panel)

func _build_feedback() -> void:
	_feedback = _lbl("", Vector2(210,72), 14, Color("#C77DFF"))
	_fb_timer  = Timer.new(); _fb_timer.wait_time = 3.0; _fb_timer.one_shot = true
	_fb_timer.timeout.connect(func(): _feedback.text = ""); add_child(_fb_timer)

func _build_combo() -> void:
	_combo_lbl = _lbl("", Vector2(LANE_X - 60, 90), 20, Color("#FFD93D"))

# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed:
			match ke.keycode:
				KEY_SPACE, KEY_Z, KEY_E:
					_pop_top_rune()
				KEY_Q:
					if _dsa_panel: _dsa_panel.toggle()

func _pop_top_rune() -> void:
	## Pop the top-of-stack rune via keyboard
	if _rune_order.is_empty(): return
	var top_id: int = _rune_order[_rune_order.size()-1]
	emit_signal("rune_clicked", top_id)

# ── Rune management ───────────────────────────────────────────────────────────

func set_all_runes(runes: Array) -> void:
	_all_runes = runes

func on_rune_pushed(r: Dictionary) -> void:
	_rune_order.append(r["id"] as int)
	_spawn_rune_node(r)
	_reposition_runes()
	_rebuild_pop_panel()

func on_rune_popped(r: Dictionary) -> void:
	var rid: int = r["id"] as int
	if _rune_nodes.has(rid):
		(_rune_nodes[rid] as Node2D).pop_anim()
		_rune_nodes.erase(rid)
	_rune_order.erase(rid)
	if _pop_btns.has(rid):
		_pop_btns[rid].queue_free(); _pop_btns.erase(rid)
	_combo += 1; _combo_timer = 3.0
	if _combo >= 2:
		_combo_lbl.text = "x%d COMBO!" % _combo
		var tw := create_tween()
		tw.tween_property(_combo_lbl,"scale",Vector2(1.3,1.3),0.08)
		tw.tween_property(_combo_lbl,"scale",Vector2(1.0,1.0),0.12)
	_reposition_runes()
	_rebuild_pop_panel()

func _spawn_rune_node(r: Dictionary) -> void:
	var node: Node2D = (load("res://scripts/chapters/stack/RuneNode.gd") as GDScript).new()
	node.name    = "Rune_%d" % (r["id"] as int)
	node.position = Vector2(LANE_X, SPAWN_Y)
	node.z_index  = 10
	node.setup(r, SPAWN_Y, SPAWN_Y)
	var rid: int = r["id"] as int
	# Both click AND the area2d inside RuneNode emit the signal
	node.clicked.connect(func(id: int): emit_signal("rune_clicked", id))
	add_child(node)
	_rune_nodes[rid] = node

func _reposition_runes() -> void:
	var sz: int = _rune_order.size()
	for i in sz:
		var rid: int = _rune_order[i]
		if not _rune_nodes.has(rid): continue
		var ty: float = TOP_Y + (sz - 1 - i) * RUNE_GAP
		(_rune_nodes[rid] as Node2D).set_target(ty, i, sz, i == sz-1)
	_world.queue_redraw()

func _rebuild_pop_panel() -> void:
	for ch in _pop_panel.get_children(): ch.queue_free()
	_pop_btns.clear()
	var sz: int = _rune_order.size()
	for i in sz:
		var stack_idx: int = sz - 1 - i
		var rid: int = _rune_order[stack_idx]
		var rdata: Dictionary = {}
		for rd in _all_runes:
			if (rd["id"] as int) == rid: rdata = rd; break
		if rdata.is_empty(): continue
		var is_top: bool = (stack_idx == sz - 1)
		var btn := Button.new()
		btn.text = "%s %s%s" % [
			rdata.get("symbol","?"),
			rdata.get("name","?"),
			"\n▲ CLICK or SPACE" if is_top else "\n(buried)"
		]
		btn.set_position(Vector2(0, i * 70))
		btn.set_size(Vector2(186, 66))
		btn.add_theme_font_size_override("font_size", 11)
		btn.disabled = not is_top
		if is_top:
			btn.add_theme_color_override("font_color", Color("#C77DFF"))
		else:
			btn.add_theme_color_override("font_color", Color("#443355"))
			btn.modulate = Color(1,1,1,0.4)
		btn.pressed.connect(func(): emit_signal("rune_clicked", rid))
		_pop_panel.add_child(btn)
		_pop_btns[rid] = btn

func on_push_phase_done() -> void:
	_phase_lbl.text = "✨ POP phase — click or press SPACE!"
	_phase_lbl.add_theme_color_override("font_color", Color("#C77DFF"))
	_key_hint.text = "SPACE / Z / E = pop top rune"
	_key_hint.add_theme_color_override("font_color", Color("#FFD93D"))
	if _dsa_panel:
		_dsa_panel.update(_stack_ref.stack.duplicate(), _stack_ref.max_size, "pop")
	_world.phase = "pop"; _world.queue_redraw()

func on_door_unlock(count: int) -> void:
	_world.door_unlocked_count = count; _world.queue_redraw()

func _process(delta: float) -> void:
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0: _combo = 0; _combo_lbl.text = ""

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
	var l := Label.new(); l.text = text; l.set_position(pos)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	add_child(l); return l
