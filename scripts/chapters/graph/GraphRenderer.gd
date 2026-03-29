extends Node2D

# ═══════════════════════════════════════════════════
# G_GraphRenderer.gd
# Draws roads (edges) between cities and spawns
# G_CityNode visuals at their map positions.
# Also draws edge weight labels and direction arrows.
# ═══════════════════════════════════════════════════

signal city_clicked(node_id: int)

var _city_nodes:  Dictionary = {}   # node_id -> G_CityNode
var _snapshot:    Dictionary = {}
var _edge_states: Dictionary = {}   # "from_to" -> state (normal/highlight/cycle)
var _dist_labels: Dictionary = {}   # node_id -> String
var _order_labels:Dictionary = {}   # node_id -> String
var _in_degrees:  Dictionary = {}   # node_id -> int
var _show_weights:bool       = false
var _directed:    bool       = false

func render(snapshot: Dictionary, show_weights: bool = false) -> void:
	_snapshot     = snapshot
	_show_weights = show_weights
	_directed     = snapshot.get("directed", false) as bool
	_clear_cities()
	_spawn_cities(snapshot)
	queue_redraw()

func set_city_state(node_id: int, state: String) -> void:
	if _city_nodes.has(node_id):
		(_city_nodes[node_id]).set_state(state)

func set_all_states(states: Dictionary) -> void:
	for nid in states:
		if _city_nodes.has(nid):
			(_city_nodes[nid]).set_state(states[nid] as String)

func set_dist_label(node_id: int, label: String) -> void:
	_dist_labels[node_id] = label
	if _city_nodes.has(node_id):
		(_city_nodes[node_id]).dist_label = label

func set_order_label(node_id: int, label: String) -> void:
	_order_labels[node_id] = label
	if _city_nodes.has(node_id):
		(_city_nodes[node_id]).order_label = label

func set_in_degree(node_id: int, deg: int) -> void:
	_in_degrees[node_id] = deg
	if _city_nodes.has(node_id):
		(_city_nodes[node_id]).in_degree = deg

func highlight_edge(from_id: int, to_id: int, state: String) -> void:
	_edge_states["%d_%d" % [from_id, to_id]] = state
	_edge_states["%d_%d" % [to_id, from_id]] = state
	queue_redraw()

func clear_edge_highlights() -> void:
	_edge_states.clear()
	queue_redraw()

# ─── Drawing ─────────────────────────────────────

func _draw() -> void:
	if _snapshot.is_empty(): return
	_draw_roads()

func _draw_roads() -> void:
	var nodes: Dictionary = _snapshot.get("nodes",{})
	var adj:   Dictionary = _snapshot.get("adj",{})
	var drawn: Dictionary = {}

	for from_id in adj:
		for edge in adj[from_id]:
			var to_id: int = edge["to"] as int
			var key:   String = "%d_%d" % [min(from_id,to_id), max(from_id,to_id)]
			if not _directed and drawn.has(key): continue
			drawn[key] = true

			if not nodes.has(from_id) or not nodes.has(to_id): continue
			var fp: Vector2 = nodes[from_id]["pos"] as Vector2
			var tp: Vector2 = nodes[to_id]["pos"] as Vector2

			# Edge state
			var estate: String = _edge_states.get("%d_%d" % [from_id,to_id],
				_edge_states.get("%d_%d" % [to_id,from_id], "normal")) as String

			var road_col: Color
			var road_w:   float
			match estate:
				"highlight":
					road_col = Color("#6BCB77"); road_w = 4.0
				"path":
					road_col = Color("#4D96FF"); road_w = 4.0
				"cycle":
					road_col = Color("#FF6B6B"); road_w = 4.0
				"frontier":
					road_col = Color("#FFD93D"); road_w = 3.0
				_:
					road_col = Color("#5a5020"); road_w = 3.0

			# Road base (dirt path)
			draw_line(fp, tp, Color("#3a3010"), road_w + 3)
			draw_line(fp, tp, road_col, road_w)

			# Direction arrow for directed graphs
			if _directed:
				var mid:   Vector2 = (fp + tp) / 2.0
				var dir:   Vector2 = (tp - fp).normalized()
				var perp:  Vector2 = Vector2(-dir.y, dir.x)
				var arrow_tip:  Vector2 = mid + dir * 16
				var arrow_left: Vector2 = arrow_tip - dir*14 + perp*7
				var arrow_right:Vector2 = arrow_tip - dir*14 - perp*7
				var arr_pts: PackedVector2Array = PackedVector2Array([arrow_left,arrow_tip,arrow_right])
				draw_colored_polygon(arr_pts, road_col)

			# Weight label
			if _show_weights:
				var wt: int   = edge["weight"] as int
				var mid: Vector2 = (fp + tp) / 2.0
				var perp: Vector2 = Vector2(-(tp-fp).y, (tp-fp).x).normalized() * 18
				draw_rect(Rect2(mid + perp + Vector2(-12,-9), Vector2(24,18)),
					Color("#0a0a04"))
				draw_string(ThemeDB.fallback_font,
					mid + perp + Vector2(-8,5),
					str(wt), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#aaa840"))

# ─── City Visuals ─────────────────────────────────

func _spawn_cities(snapshot: Dictionary) -> void:
	var nodes: Dictionary = snapshot.get("nodes", {})
	for nid in nodes:
		var node: Dictionary = nodes[nid]
		var city: Node2D = (load("res://scripts/chapters/graph/CityNode.gd") as GDScript).new()
		city.name = "City_%d" % nid
		city.setup(node)
		city.position = node["pos"] as Vector2
		city.z_index  = 10
		if _dist_labels.has(nid):
			city.dist_label = _dist_labels[nid] as String
		if _order_labels.has(nid):
			city.order_label = _order_labels[nid] as String
		if _in_degrees.has(nid):
			city.in_degree = _in_degrees[nid] as int

		var vid: int = nid
		var area  := Area2D.new()
		var shape := CollisionShape2D.new()
		var circ  := CircleShape2D.new()
		circ.radius = 40.0
		shape.shape = circ
		area.add_child(shape)
		area.input_event.connect(func(_vp, event, _idx):
			if event is InputEventMouseButton:
				var mb := event as InputEventMouseButton
				if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
					emit_signal("city_clicked", vid)
		)
		city.add_child(area)
		add_child(city)
		_city_nodes[nid] = city

func _clear_cities() -> void:
	for c in _city_nodes.values():
		if is_instance_valid(c): c.queue_free()
	_city_nodes.clear()
	_dist_labels.clear()
	_order_labels.clear()
