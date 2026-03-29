extends Node2D

# ═══════════════════════════════════════════════════
# T_TreeRenderer.gd
# Calculates x/y positions for each BST node using
# recursive layout, then renders nodes and edges.
# Also handles heap array visualization.
# ═══════════════════════════════════════════════════

signal node_clicked(node_id: int)

const ROOT_Y:     float = 130.0
const LEVEL_GAP:  float = 130.0
const MIN_X_GAP:  float = 80.0
const WORLD_W:    float = 1080.0  # drawable width (excluding panels)
const WORLD_OX:   float = 200.0   # left panel width

var _node_visuals: Dictionary = {}   # node_id -> T_TreeNodeVisual
var _positions:    Dictionary = {}   # node_id -> Vector2
var _snapshot:     Dictionary = {}
var _show_balance: bool       = false
var _highlighted:  Array      = []   # node ids to highlight
var _found_id:     int        = -1
var _wrong_id:     int        = -1
var _insert_pos:   Vector2    = Vector2(-1,-1)  # ghost insert position
var _insert_side:  String     = ""
var _insert_after: int        = -1

func render(snapshot: Dictionary, show_balance: bool = false) -> void:
	_snapshot     = snapshot
	_show_balance = show_balance
	_clear_visuals()

	if snapshot.get("mode","bst") == "heap":
		_render_heap(snapshot.get("heap",[]))
	else:
		_calculate_positions(snapshot)
		_draw_edges(snapshot)
		_spawn_visuals(snapshot)
	queue_redraw()

func set_highlights(ids: Array, found: int = -1, wrong: int = -1) -> void:
	_highlighted = ids
	_found_id    = found
	_wrong_id    = wrong
	_refresh_states()

func set_insert_ghost(after_id: int, side: String) -> void:
	_insert_after = after_id
	_insert_side  = side
	queue_redraw()

func clear_insert_ghost() -> void:
	_insert_after = -1
	_insert_side  = ""
	queue_redraw()

# ─── Layout ──────────────────────────────────────

func _calculate_positions(snapshot: Dictionary) -> void:
	_positions.clear()
	var nodes:   Dictionary = snapshot.get("nodes", {})
	var root_id: int        = snapshot.get("root_id", -1)
	if root_id == -1: return
	# Count nodes per level for spacing
	_layout_rec(root_id, nodes, 0, WORLD_OX, WORLD_OX + WORLD_W, ROOT_Y)

func _layout_rec(nid: int, nodes: Dictionary, depth: int,
		x_min: float, x_max: float, y: float) -> void:
	if nid == -1: return
	var cx: float = (x_min + x_max) / 2.0
	var cy: float = y
	_positions[nid] = Vector2(cx, cy)
	var child_y: float = y + LEVEL_GAP
	var node: Dictionary = nodes[nid]
	_layout_rec(node["left_id"],  nodes, depth+1, x_min, cx, child_y)
	_layout_rec(node["right_id"], nodes, depth+1, cx, x_max, child_y)

# ─── Edge drawing ─────────────────────────────────

func _draw_edges(snapshot: Dictionary) -> void:
	var nodes: Dictionary = snapshot.get("nodes", {})
	for nid in _positions:
		var node: Dictionary = nodes[nid]
		var from: Vector2    = _positions[nid]
		for child_id in [node["left_id"], node["right_id"]]:
			if child_id != -1 and _positions.has(child_id):
				var to:    Vector2 = _positions[child_id]
				var is_hl: bool   = (nid in _highlighted) and (child_id in _highlighted)
				draw_line(from, to,
					Color("#6BCB77") if is_hl else Color("#2a4a15"), 2.0)
				# Direction label midpoint
				var mid: Vector2 = (from + to) / 2.0
				var is_left: bool = (child_id == node["left_id"])
				draw_string(ThemeDB.fallback_font,
					mid + Vector2(-16 if is_left else 4, -6),
					"<" if is_left else ">",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
					Color("#4D96FF") if is_left else Color("#FF6B6B"))

# ─── Visuals ─────────────────────────────────────

func _spawn_visuals(snapshot: Dictionary) -> void:
	var nodes: Dictionary = snapshot.get("nodes", {})
	var root_id: int      = snapshot.get("root_id", -1)
	for nid in _positions:
		if not nodes.has(nid): continue
		var vis: Node2D = (load("res://scripts/chapters/tree/TreeNodeVisual.gd") as GDScript).new()
		vis.name = "Node_%d" % nid
		vis.setup(nodes[nid])
		vis.position    = _positions[nid]
		vis.is_root     = (nid == root_id)
		vis.show_balance = _show_balance
		vis.z_index     = 10

		# State
		if nid == _found_id:
			vis.set_state("found")
		elif nid == _wrong_id:
			vis.set_state("wrong")
		elif nid in _highlighted:
			vis.set_state("highlighted")
		elif _show_balance and abs(nodes[nid].get("balance",0) as int) > 1:
			vis.set_state("unbalanced")

		# Collision
		var area  := Area2D.new()
		var shape := CollisionShape2D.new()
		var circ  := CircleShape2D.new()
		circ.radius = 36.0
		shape.shape = circ
		area.add_child(shape)
		var vid: int = nid
		area.input_event.connect(func(_vp, event, _idx):
			if event is InputEventMouseButton:
				var mb := event as InputEventMouseButton
				if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
					emit_signal("node_clicked", vid)
		)
		vis.add_child(area)
		add_child(vis)
		_node_visuals[nid] = vis

func _refresh_states() -> void:
	var nodes: Dictionary = _snapshot.get("nodes", {})
	for nid in _node_visuals:
		var vis: Node2D = _node_visuals[nid]
		if nid == _found_id:           vis.set_state("found")
		elif nid == _wrong_id:         vis.set_state("wrong")
		elif nid in _highlighted:      vis.set_state("highlighted")
		elif _show_balance and abs(nodes.get(nid, {}).get("balance",0) as int) > 1:
			vis.set_state("unbalanced")
		else:                          vis.set_state("normal")
	queue_redraw()

func _clear_visuals() -> void:
	for v in _node_visuals.values():
		if is_instance_valid(v): v.queue_free()
	_node_visuals.clear()
	for child in get_children():
		child.queue_free()

# ─── Heap rendering ──────────────────────────────

func _render_heap(heap: Array) -> void:
	if heap.is_empty(): return
	# Draw as tree layout from array indices
	var cols: Array = [Color("#FFD93D"),Color("#6BCB77"),Color("#4D96FF"),
		Color("#FF6B6B"),Color("#C77DFF"),Color("#FF9F43")]

	# Calculate positions for heap as complete binary tree
	var positions: Dictionary = {}
	for i in heap.size():
		var depth: int    = int(log(i+1) / log(2))
		var nodes_in_row: int = int(pow(2, depth))
		var pos_in_row:   int = i - (nodes_in_row - 1)
		var x: float = WORLD_OX + WORLD_W / (nodes_in_row + 1) * (pos_in_row + 1)
		var y: float = ROOT_Y + depth * LEVEL_GAP
		positions[i] = Vector2(x, y)

	# Draw edges
	for i in heap.size():
		if i == 0: continue
		var parent: int = (i-1)/2
		draw_line(positions[parent], positions[i], Color("#2a4a15"), 2.0)
		# Index labels
		var mid: Vector2 = (positions[parent] + positions[i]) / 2.0
		draw_string(ThemeDB.fallback_font, mid + Vector2(4,-6),
			"[%d]" % i, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#445530"))

	# Draw nodes
	for i in heap.size():
		var pos: Vector2 = positions[i]
		var col: Color   = cols[i % cols.size()]
		var is_root: bool = (i == 0)

		if is_root:
			draw_circle(pos, 42, col * Color(1,1,1,0.15))
		draw_circle(pos + Vector2(2,2), 32, Color(0,0,0,0.3))
		draw_circle(pos, 32, Color("#0a1604"))
		draw_circle(pos, 29, col.darkened(0.5))
		draw_arc(pos, 32, 0, TAU, 32, col, 2.5)
		draw_string(ThemeDB.fallback_font,
			pos + Vector2(-10, 7),
			str(heap[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, col)
		draw_string(ThemeDB.fallback_font,
			pos + Vector2(-12, -28),
			"[%d]" % i, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#445530"))
		if is_root:
			draw_rect(Rect2(pos.x-24, pos.y-52, 48, 16), Color("#FFD93D"))
			draw_string(ThemeDB.fallback_font, pos + Vector2(-20, -39),
				"ROOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#1a1000"))

func _draw() -> void:
	# Re-draw edges on redraw (visuals are separate nodes)
	if not _snapshot.is_empty() and _snapshot.get("mode","bst") != "heap":
		_draw_edges(_snapshot)
