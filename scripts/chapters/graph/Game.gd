extends Node2D

signal city_clicked(node_id: int)

var _cfg:       Dictionary = {}
var _graph_ref: Node
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
var _left_panel: Control
var _right_panel: Control
var _q_btn:     Button
var _algo_state_label: Label

func setup(cfg: Dictionary, g: Node, gl: Node, dp: Node2D) -> void:
	_cfg       = cfg
	_graph_ref = g
	_logic_ref = gl
	_dsa_panel = dp

func _ready() -> void:
	_build_world()
	_build_hud()
	_build_panels()
	_build_feedback()

func _build_world() -> void:
	_world = (load("res://scripts/chapters/graph/KingdomWorld.gd") as GDScript).new()
	_world.name = "G_KingdomWorld"
	add_child(_world)

	_renderer = (load("res://scripts/chapters/graph/GraphRenderer.gd") as GDScript).new()
	_renderer.name = "G_GraphRenderer"
	_renderer.z_index = 5
	_renderer.city_clicked.connect(func(nid): emit_signal("city_clicked", nid))
	add_child(_renderer)

	if _dsa_panel:
		if _dsa_panel.get_parent(): _dsa_panel.reparent(self)
		else: add_child(_dsa_panel)

func _build_hud() -> void:
	var hud := ColorRect.new()
	hud.color = Color(0,0,0,0.72)
	hud.set_position(Vector2.ZERO); hud.set_size(Vector2(1280,48))
	add_child(hud)
	_hud_level = _lbl("",Vector2(12,8),13,Color("#FFD93D"))
	_hud_dsa   = _lbl("",Vector2(12,28),11,Color("#444420"))
	if not _cfg.is_empty():
		_hud_level.text = "Level %d — %s" % [_cfg.get("level",1), _cfg.get("title","")]
		_hud_dsa.text   = "DSA: " + _cfg.get("dsainfo","")
	_hud_score = _lbl("Score: 0",Vector2(860,14),16,Color("#FFD93D"))
	_hud_lives = _lbl("♥ ♥ ♥",Vector2(1080,10),20,Color("#FF6B6B"))
	_q_btn = Button.new()
	_q_btn.text = "[Q]  Graph panel"
	_q_btn.set_position(Vector2(1150,52)); _q_btn.set_size(Vector2(120,28))
	_q_btn.add_theme_font_size_override("font_size",11)
	_q_btn.pressed.connect(_toggle_dsa); add_child(_q_btn)

func _build_panels() -> void:
	var lb := ColorRect.new()
	lb.color = Color(0,0,0,0.78)
	lb.set_position(Vector2(0,48)); lb.set_size(Vector2(200,672))
	add_child(lb)
	_lbl("Algorithms:",Vector2(10,58),12,Color("#FFD93D"))
	_left_panel = Control.new()
	_left_panel.set_position(Vector2(8,82)); _left_panel.set_size(Vector2(186,400))
	add_child(_left_panel)
	_algo_state_label = Label.new()
	_algo_state_label.set_position(Vector2(10,490))
	_algo_state_label.set_custom_minimum_size(Vector2(186,200))
	_algo_state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_algo_state_label.add_theme_font_size_override("font_size",10)
	_algo_state_label.add_theme_color_override("font_color",Color("#6BCB77"))
	add_child(_algo_state_label)

	var rb := ColorRect.new()
	rb.color = Color(0,0,0,0.78)
	rb.set_position(Vector2(1080,48)); rb.set_size(Vector2(200,672))
	add_child(rb)
	_lbl("Graph state:",Vector2(1090,58),12,Color("#FFD93D"))
	_right_panel = Control.new()
	_right_panel.set_position(Vector2(1088,80)); _right_panel.set_size(Vector2(186,600))
	add_child(_right_panel)

func _build_feedback() -> void:
	_feedback = _lbl("",Vector2(210,54),13,Color("#6BCB77"))
	_feedback.set_custom_minimum_size(Vector2(860,0))
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fb_timer = Timer.new()
	_fb_timer.wait_time = 4.0; _fb_timer.one_shot = true
	_fb_timer.timeout.connect(func(): _feedback.text = "")
	add_child(_fb_timer)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and ke.keycode == KEY_Q: _toggle_dsa()

func _toggle_dsa() -> void:
	if _dsa_panel: _dsa_panel.toggle()

func refresh_graph(snapshot: Dictionary, operation: String,
		show_weights: bool = false) -> void:
	_renderer.render(snapshot, show_weights)
	_rebuild_left_panel(operation)
	_rebuild_right_panel(snapshot)
	if _dsa_panel: _dsa_panel.update(snapshot, operation, _logic_ref)

func on_states_changed(states: Dictionary) -> void:
	_renderer.set_all_states(states)
	_update_algo_state_label()

func on_edge_highlight(from_id: int, to_id: int, state: String) -> void:
	_renderer.highlight_edge(from_id, to_id, state)

func on_dist_updated(node_id: int, label: String) -> void:
	_renderer.set_dist_label(node_id, label)

func on_order_updated(node_id: int, label: String) -> void:
	_renderer.set_order_label(node_id, label)

func on_in_deg_updated(node_id: int, deg: int) -> void:
	_renderer.set_in_degree(node_id, deg)

func _update_algo_state_label() -> void:
	if _logic_ref == null: return
	var nodes: Dictionary = _graph_ref.nodes
	match _logic_ref.operation:
		"bfs":
			var ql: Array = []
			for nid in _logic_ref.bfs_queue:
				ql.append(nodes.get(nid,{}).get("label","?") as String)
			_algo_state_label.text = "Queue:\n[%s]\n\nVisited:\n{%s}" % [
				", ".join(ql),
				", ".join(_logic_ref.visited.keys().map(
					func(k): return nodes.get(k,{}).get("label","?") as String))]
		"dfs":
			var step: Dictionary = {}
			if _logic_ref.dfs_step_idx < _logic_ref.dfs_steps.size():
				step = _logic_ref.dfs_steps[_logic_ref.dfs_step_idx]
			var sl: Array = []
			for nid in step.get("stack",[]):
				sl.append(nodes.get(nid,{}).get("label","?") as String)
			_algo_state_label.text = "Stack (top→):\n[%s]\n\nVisited:\n{%s}" % [
				", ".join(sl),
				", ".join(_logic_ref.visited.keys().map(
					func(k): return nodes.get(k,{}).get("label","?") as String))]
		"dijkstra":
			var dl: Array = []
			for nid in _logic_ref.dist:
				var dv: float = _logic_ref.dist[nid] as float
				dl.append("%s:%s" % [nodes.get(nid,{}).get("label","?"),
					"∞" if dv==INF else str(int(dv))])
			_algo_state_label.text = "Distances:\n" + "\n".join(dl)
		"topo":
			var il: Array = []
			for nid in _logic_ref.topo_in_deg:
				il.append("%s=%d" % [nodes.get(nid,{}).get("label","?"),
					_logic_ref.topo_in_deg[nid]])
			_algo_state_label.text = "In-degrees:\n" + "\n".join(il)

func _rebuild_left_panel(operation: String) -> void:
	for c in _left_panel.get_children(): c.queue_free()
	var ops: Array    = ["bfs","dfs","dijkstra","cycle","topo"]
	var labels: Dictionary = {"bfs":"BFS (queue)","dfs":"DFS (stack)",
		"dijkstra":"Dijkstra","cycle":"Cycle detect","topo":"Topo sort"}
	var cols: Dictionary   = {"bfs":Color("#FFD93D"),"dfs":Color("#4D96FF"),
		"dijkstra":Color("#6BCB77"),"cycle":Color("#FF6B6B"),"topo":Color("#C77DFF")}
	for i in ops.size():
		var op: String   = ops[i]
		var active: bool = (op == operation)
		var bg := ColorRect.new()
		bg.color = Color("#1a2a08") if active else Color("#060a02")
		bg.set_position(Vector2(0,i*48)); bg.set_size(Vector2(186,44))
		_left_panel.add_child(bg)
		var lbl := Label.new()
		lbl.text = labels[op]
		lbl.set_position(Vector2(6,i*48+4)); lbl.set_size(Vector2(178,44))
		lbl.add_theme_font_size_override("font_size",13)
		lbl.add_theme_color_override("font_color",
			cols[op] if active else Color("#223310"))
		_left_panel.add_child(lbl)

func _rebuild_right_panel(snapshot: Dictionary) -> void:
	for c in _right_panel.get_children(): c.queue_free()
	var nodes: Dictionary = snapshot.get("nodes",{})
	var adj:   Dictionary = snapshot.get("adj",{})
	var directed: bool    = snapshot.get("directed",false) as bool
	var y: float = 0.0
	_r("Type: %s" % ("Directed" if directed else "Undirected"), Color("#888840"), y); y+=18
	_r("Nodes: %d" % nodes.size(), Color("#6BCB77"), y); y+=18
	var edge_count: int = 0
	for nid in adj: edge_count += adj[nid].size()
	if not directed: edge_count /= 2
	_r("Edges: %d" % edge_count, Color("#6BCB77"), y); y+=24
	_r("Adj list:", Color("#888840"), y); y+=16
	for nid in nodes:
		var nbs: Array = []
		for edge in adj.get(nid,[]):
			nbs.append("%s" % nodes.get(edge["to"] as int,{}).get("label","?"))
		_r("%s→[%s]" % [nodes[nid]["label"], ",".join(nbs)], Color("#6BCB77"), y); y+=16

func _r(text: String, col: Color, y: float) -> void:
	var l := Label.new(); l.text=text; l.set_position(Vector2(0,y))
	l.add_theme_font_size_override("font_size",10)
	l.add_theme_color_override("font_color",col)
	_right_panel.add_child(l)

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
	var l := Label.new(); l.text=text; l.set_position(pos)
	l.add_theme_font_size_override("font_size",sz)
	l.add_theme_color_override("font_color",col)
	add_child(l); return l
