extends Node

# ═══════════════════════════════════════════════════
# G_GameLogic.gd
# Validates player clicks for each graph algorithm.
# Tracks state: visited set, queue/stack, distances.
# ═══════════════════════════════════════════════════

signal score_changed(v: int)
signal lives_changed(v: int)
signal feedback(msg: String, good: bool)
signal states_changed(states: Dictionary)
signal edge_highlight(from_id: int, to_id: int, state: String)
signal dist_updated(node_id: int, label: String)
signal order_updated(node_id: int, label: String)
signal in_deg_updated(node_id: int, deg: int)
signal level_complete
signal game_over

const MAX_LIVES:      int = 3
const POINTS_STEP:    int = 150
const POINTS_PERFECT: int = 300

var score:     int    = 0
var lives:     int    = MAX_LIVES
var active:    bool   = false
var operation: String = "bfs"
var _mistakes: int    = 0
var _graph: Node2D

# Per-algorithm state
var visited:   Dictionary = {}
var bfs_queue: Array      = []
var dfs_stack: Array      = []
var dfs_steps: Array      = []
var dfs_step_idx: int     = 0
var dist:      Dictionary = {}
var prev:      Dictionary = {}
var dijk_visited: Dictionary = {}
var topo_in_deg: Dictionary  = {}
var topo_order:  Array       = []
var topo_idx:    int         = 0
var cycle_target: int        = -1

func init(g: Node2D) -> void:
	_graph = g

func reset_stats() -> void:
	score  = 0
	lives  = MAX_LIVES
	active = false
	_mistakes = 0
	emit_signal("score_changed", score)
	emit_signal("lives_changed", lives)

# ─── Start operations ─────────────────────────────

func start_bfs(start: int) -> void:
	operation  = "bfs"
	visited    = { start: true }
	bfs_queue  = [start]
	active     = true
	_emit_bfs_states()
	emit_signal("feedback",
		"BFS: Click the city at the FRONT of the queue (yellow). Explore level by level!", true)

func start_dfs(start: int) -> void:
	operation     = "dfs"
	visited       = {}
	dfs_stack     = [start]
	dfs_steps     = _graph.dfs_stack_steps(start)
	dfs_step_idx  = 0
	active        = true
	_emit_dfs_states()
	emit_signal("feedback",
		"DFS: Click the city on TOP of the stack (blue). Go as deep as possible!", true)

func start_dijkstra(start: int) -> void:
	operation     = "dijkstra"
	dijk_visited  = {}
	dist          = {}
	prev          = {}
	for nid in _graph.nodes:
		dist[nid] = INF
		prev[nid] = -1
	dist[start] = 0.0
	active = true
	for nid in _graph.nodes:
		emit_signal("dist_updated", nid, "∞" if dist[nid] == INF else str(int(dist[nid])))
	emit_signal("feedback",
		"DIJKSTRA: Click the UNVISITED city with the SMALLEST known distance!", true)

func start_cycle(back_edge: Dictionary) -> void:
	operation     = "cycle"
	cycle_target  = back_edge.get("to",-1) as int
	active        = true
	emit_signal("feedback",
		"CYCLE DETECT: Find the back edge! Click the city that creates the cycle (already visited).",
		true)

func start_topo(sorted_order: Array) -> void:
	operation    = "topo"
	topo_order   = sorted_order
	topo_idx     = 0
	topo_in_deg  = _graph.get_in_degrees()
	active       = true
	for nid in topo_in_deg:
		emit_signal("in_deg_updated", nid, topo_in_deg[nid] as int)
	emit_signal("feedback",
		"TOPO SORT: Click cities with in-degree 0 first (purple) — all prerequisites done!", true)
	_emit_topo_states()

# ─── Player click ─────────────────────────────────

func player_clicks(node_id: int) -> void:
	if not active: return
	match operation:
		"bfs":       _handle_bfs(node_id)
		"dfs":       _handle_dfs(node_id)
		"dijkstra":  _handle_dijkstra(node_id)
		"cycle":     _handle_cycle(node_id)
		"topo":      _handle_topo(node_id)

# ─── BFS handler ─────────────────────────────────

func _handle_bfs(node_id: int) -> void:
	if bfs_queue.is_empty(): return
	var expected: int = bfs_queue[0]   # FRONT of queue

	if node_id == expected:
		bfs_queue.pop_front()
		score += POINTS_STEP
		emit_signal("score_changed", score)

		# Enqueue unvisited neighbors
		var new_neighbors: Array = []
		for nb in _graph.neighbors(node_id):
			if not visited.has(nb):
				visited[nb] = true
				bfs_queue.append(nb)
				new_neighbors.append(nb)
				emit_signal("edge_highlight", node_id, nb, "frontier")

		var nb_str: String = str(new_neighbors) if not new_neighbors.is_empty() else "none"
		emit_signal("feedback",
			"✓ Dequeued %s! Enqueued neighbors: %s. Queue front is now: %s" % [
				_graph.nodes[node_id]["label"],
				nb_str,
				_graph.nodes[bfs_queue[0]]["label"] if not bfs_queue.is_empty() else "empty"
			], true)

		_emit_bfs_states()

		if bfs_queue.is_empty():
			_finish("BFS complete! Visited all reachable cities level by level.")
	else:
		emit_signal("edge_highlight", bfs_queue[0], node_id, "cycle")
		_wrong("✗ Wrong! BFS dequeues from the FRONT. Click %s next." % \
			_graph.nodes[expected]["label"])

# ─── DFS handler ─────────────────────────────────

func _handle_dfs(node_id: int) -> void:
	if dfs_step_idx >= dfs_steps.size():
		return
	var step:     Dictionary = dfs_steps[dfs_step_idx]
	var expected: int        = step["current"] as int

	if node_id == expected:
		dfs_step_idx += 1
		score += POINTS_STEP
		emit_signal("score_changed", score)
		visited[node_id] = true

		var stack_top: String = str(_graph.nodes[node_id]["label"])
		emit_signal("feedback",
			"✓ Visited %s (top of stack)! Going deep — check stack for next." % stack_top, true)

		_emit_dfs_states()

		if dfs_step_idx >= dfs_steps.size():
			_finish("DFS complete! Explored as deep as possible before backtracking.")
	else:
		_wrong("✗ Wrong! DFS visits the TOP of the stack. Expected: %s" % \
			_graph.nodes[expected]["label"])

# ─── Dijkstra handler ─────────────────────────────

func _handle_dijkstra(node_id: int) -> void:
	if dijk_visited.has(node_id):
		_wrong("✗ Already visited! Pick the unvisited city with smallest distance.")
		return

	var expected: int = _graph.dijkstra_next(dist, dijk_visited)
	if node_id == expected:
		dijk_visited[node_id] = true
		score += POINTS_STEP
		emit_signal("score_changed", score)

		# Relax neighbors
		var relaxed: Array = []
		for edge in _graph.adj.get(node_id,[]):
			var nb:  int   = edge["to"] as int
			var wt:  float = edge["weight"] as float
			var nd:  float = dist[node_id] + wt
			if nd < dist[nb]:
				dist[nb] = nd
				prev[nb] = node_id
				relaxed.append(nb)
				emit_signal("dist_updated", nb, str(int(nd)))
				emit_signal("edge_highlight", node_id, nb, "path")

		emit_signal("feedback",
			"✓ Settled %s (dist=%d). Relaxed %d neighbors." % [
				_graph.nodes[node_id]["label"],
				int(dist[node_id]), relaxed.size()], true)

		_emit_dijkstra_states()

		var next: int = _graph.dijkstra_next(dist, dijk_visited)
		if next == -1:
			_finish("Dijkstra complete! Shortest paths to all cities found.")
	else:
		_wrong("✗ Wrong! Pick the unvisited city with SMALLEST distance. Expected: %s (dist=%d)" % [
			_graph.nodes[expected]["label"], int(dist[expected])])

# ─── Cycle detection handler ──────────────────────

func _handle_cycle(node_id: int) -> void:
	if node_id == cycle_target:
		score += POINTS_STEP * 2
		emit_signal("score_changed", score)
		emit_signal("feedback",
			"✓ Found the back edge! Node %s was already visited — this edge creates the CYCLE!" % \
				_graph.nodes[node_id]["label"], true)
		_finish("Cycle detected! A back edge points to an ancestor — cycle exists.")
	else:
		_wrong("✗ Not a back edge. Find the road that points back to an already-visited city!")

# ─── Topological sort handler ─────────────────────

func _handle_topo(node_id: int) -> void:
	if topo_idx >= topo_order.size(): return
	var expected: int = topo_order[topo_idx]

	if node_id == expected:
		topo_idx += 1
		score += POINTS_STEP
		emit_signal("score_changed", score)

		# Reduce in-degree of neighbors
		for edge in _graph.adj.get(node_id,[]):
			var nb: int = edge["to"] as int
			topo_in_deg[nb] = max(0, (topo_in_deg.get(nb,0) as int) - 1)
			emit_signal("in_deg_updated", nb, topo_in_deg[nb] as int)

		emit_signal("feedback",
			"✓ %s processed (in-degree was 0). Reduced neighbors' in-degrees." % \
				_graph.nodes[node_id]["label"], true)

		_emit_topo_states()

		if topo_idx >= topo_order.size():
			_finish("Topological sort complete! All dependencies respected.")
	else:
		_wrong("✗ Wrong! Process cities with in-degree 0 (purple) first — all prerequisites done.")

# ─── State emitters ───────────────────────────────

func _emit_bfs_states() -> void:
	var states: Dictionary = {}
	for nid in _graph.nodes:
		if visited.has(nid) and not (nid in bfs_queue):
			states[nid] = "visited"
		elif nid in bfs_queue:
			states[nid] = "queued"
		else:
			states[nid] = "unvisited"
	if not bfs_queue.is_empty():
		states[bfs_queue[0]] = "current"
	emit_signal("states_changed", states)

func _emit_dfs_states() -> void:
	var states: Dictionary = {}
	var cur_stack: Array = []
	if dfs_step_idx < dfs_steps.size():
		cur_stack = dfs_steps[dfs_step_idx].get("stack",[]) as Array
	for nid in _graph.nodes:
		if visited.has(nid): states[nid] = "visited"
		elif nid in cur_stack: states[nid] = "stack"
		else: states[nid] = "unvisited"
	if not cur_stack.is_empty():
		states[cur_stack[cur_stack.size()-1]] = "current"
	emit_signal("states_changed", states)

func _emit_dijkstra_states() -> void:
	var states: Dictionary = {}
	for nid in _graph.nodes:
		if dijk_visited.has(nid): states[nid] = "visited"
		elif dist.get(nid, INF) < INF: states[nid] = "queued"
		else: states[nid] = "unvisited"
	var next: int = _graph.dijkstra_next(dist, dijk_visited)
	if next != -1: states[next] = "current"
	emit_signal("states_changed", states)

func _emit_topo_states() -> void:
	var states: Dictionary = {}
	for nid in _graph.nodes:
		if nid in topo_order.slice(0, topo_idx):
			states[nid] = "topo_done"
		elif (topo_in_deg.get(nid,1) as int) == 0:
			states[nid] = "topo_ready"
		else:
			states[nid] = "unvisited"
	emit_signal("states_changed", states)

func _finish(msg: String) -> void:
	active = false
	if _mistakes == 0:
		score += POINTS_PERFECT
		emit_signal("score_changed", score)
	emit_signal("feedback", msg, true)
	emit_signal("level_complete")

func _wrong(msg: String) -> void:
	_mistakes += 1
	lives -= 1
	emit_signal("lives_changed", lives)
	emit_signal("feedback", msg, false)
	if lives <= 0:
		active = false
		emit_signal("game_over")
