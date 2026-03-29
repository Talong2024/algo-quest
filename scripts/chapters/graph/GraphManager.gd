extends Node

# ═══════════════════════════════════════════════════
# G_GraphManager.gd
# The graph data structure — adjacency list representation.
# Supports directed/undirected, weighted edges.
# Used by G_GameLogic for BFS, DFS, Dijkstra, Cycle, Topo.
# ═══════════════════════════════════════════════════

var nodes: Dictionary = {}   # node_id -> {label, x, y}
var adj:   Dictionary = {}   # node_id -> [{to, weight}]
var directed: bool    = false

# ─── Build ────────────────────────────────────────

func build(snapshot: Dictionary) -> void:
	nodes    = snapshot.get("nodes", {}) as Dictionary
	adj      = snapshot.get("adj",   {}) as Dictionary
	directed = snapshot.get("directed", false) as bool

func clear() -> void:
	nodes.clear()
	adj.clear()

# ─── Queries ──────────────────────────────────────

func neighbors(node_id: int) -> Array:
	var result: Array = []
	for edge in adj.get(node_id, []):
		result.append((edge as Dictionary).get("to", -1) as int)
	return result

func edge_weight(from_id: int, to_id: int) -> float:
	for edge in adj.get(from_id, []):
		var e: Dictionary = edge as Dictionary
		if e.get("to", -1) as int == to_id:
			return e.get("weight", 1.0) as float
	return INF

func get_in_degrees() -> Dictionary:
	var deg: Dictionary = {}
	for nid in nodes:
		deg[nid] = 0
	for nid in adj:
		for edge in adj[nid]:
			var to: int = (edge as Dictionary).get("to", -1) as int
			if deg.has(to):
				deg[to] = (deg[to] as int) + 1
	return deg

func snapshot() -> Dictionary:
	return { "nodes": nodes, "adj": adj, "directed": directed }

# ─── Algorithm helpers ────────────────────────────

## Returns BFS visit order from start node
func bfs_steps(start: int) -> Array:
	var visited: Dictionary = {}
	var queue: Array = [start]
	var order: Array = []
	visited[start] = true
	while not queue.is_empty():
		var cur: int = queue.pop_front() as int
		order.append(cur)
		for nb in neighbors(cur):
			if not visited.has(nb):
				visited[nb] = true
				queue.append(nb)
	return order

## Returns DFS visit order from start node (using explicit stack)
func dfs_stack_steps(start: int) -> Array:
	var visited: Dictionary = {}
	var stack: Array = [start]
	var order: Array = []
	while not stack.is_empty():
		var cur: int = stack.pop_back() as int
		if visited.has(cur):
			continue
		visited[cur] = true
		order.append(cur)
		var nbs: Array = neighbors(cur)
		nbs.reverse()
		for nb in nbs:
			if not visited.has(nb):
				stack.append(nb)
	return order

## Returns the next unvisited node with minimum distance (for Dijkstra)
func dijkstra_next(dist: Dictionary, visited: Dictionary) -> int:
	var best_id: int   = -1
	var best_d:  float = INF
	for nid in nodes:
		if visited.has(nid):
			continue
		var d: float = dist.get(nid, INF) as float
		if d < best_d:
			best_d  = d
			best_id = nid
	return best_id

## Returns true if the graph has a cycle (DFS back-edge detection)
func has_cycle() -> bool:
	var visited: Dictionary = {}
	var rec_stack: Dictionary = {}
	for start in nodes:
		if not visited.has(start):
			if _dfs_cycle(start, visited, rec_stack):
				return true
	return false

func _dfs_cycle(node: int, visited: Dictionary, rec_stack: Dictionary) -> bool:
	visited[node]   = true
	rec_stack[node] = true
	for nb in neighbors(node):
		if not visited.has(nb):
			if _dfs_cycle(nb, visited, rec_stack):
				return true
		elif rec_stack.has(nb):
			return true
	rec_stack.erase(node)
	return false

## Standard level graph layouts
static func make_level_graph(level: int) -> Dictionary:
	match level:
		1: # BFS — undirected 6-node graph
			return {
				"directed": false,
				"nodes": {
					0:{"label":"A","x":200,"y":360},
					1:{"label":"B","x":420,"y":200},
					2:{"label":"C","x":420,"y":520},
					3:{"label":"D","x":640,"y":360},
					4:{"label":"E","x":860,"y":200},
					5:{"label":"F","x":860,"y":520},
				},
				"adj": {
					0:[{"to":1,"weight":1},{"to":2,"weight":1}],
					1:[{"to":0,"weight":1},{"to":3,"weight":1},{"to":4,"weight":1}],
					2:[{"to":0,"weight":1},{"to":3,"weight":1}],
					3:[{"to":1,"weight":1},{"to":2,"weight":1},{"to":5,"weight":1}],
					4:[{"to":1,"weight":1},{"to":5,"weight":1}],
					5:[{"to":3,"weight":1},{"to":4,"weight":1}],
				}
			}
		2: # DFS — undirected
			return {
				"directed": false,
				"nodes": {
					0:{"label":"A","x":180,"y":360},
					1:{"label":"B","x":400,"y":180},
					2:{"label":"C","x":400,"y":540},
					3:{"label":"D","x":640,"y":360},
					4:{"label":"E","x":900,"y":180},
					5:{"label":"F","x":900,"y":540},
					6:{"label":"G","x":1100,"y":360},
				},
				"adj": {
					0:[{"to":1,"weight":1},{"to":2,"weight":1}],
					1:[{"to":0,"weight":1},{"to":3,"weight":1}],
					2:[{"to":0,"weight":1},{"to":3,"weight":1}],
					3:[{"to":1,"weight":1},{"to":2,"weight":1},{"to":4,"weight":1},{"to":5,"weight":1}],
					4:[{"to":3,"weight":1},{"to":6,"weight":1}],
					5:[{"to":3,"weight":1},{"to":6,"weight":1}],
					6:[{"to":4,"weight":1},{"to":5,"weight":1}],
				}
			}
		3: # Dijkstra — weighted undirected
			return {
				"directed": false,
				"nodes": {
					0:{"label":"A","x":180,"y":360},
					1:{"label":"B","x":420,"y":200},
					2:{"label":"C","x":420,"y":520},
					3:{"label":"D","x":700,"y":360},
					4:{"label":"E","x":980,"y":200},
					5:{"label":"F","x":980,"y":520},
				},
				"adj": {
					0:[{"to":1,"weight":4},{"to":2,"weight":2}],
					1:[{"to":0,"weight":4},{"to":2,"weight":1},{"to":3,"weight":5}],
					2:[{"to":0,"weight":2},{"to":1,"weight":1},{"to":3,"weight":8},{"to":4,"weight":10}],
					3:[{"to":1,"weight":5},{"to":2,"weight":8},{"to":4,"weight":2},{"to":5,"weight":6}],
					4:[{"to":2,"weight":10},{"to":3,"weight":2},{"to":5,"weight":3}],
					5:[{"to":3,"weight":6},{"to":4,"weight":3}],
				}
			}
		4: # Cycle detection — directed with a cycle
			return {
				"directed": true,
				"nodes": {
					0:{"label":"A","x":200,"y":360},
					1:{"label":"B","x":480,"y":200},
					2:{"label":"C","x":480,"y":520},
					3:{"label":"D","x":760,"y":360},
					4:{"label":"E","x":1040,"y":360},
				},
				"adj": {
					0:[{"to":1,"weight":1},{"to":2,"weight":1}],
					1:[{"to":3,"weight":1}],
					2:[{"to":3,"weight":1}],
					3:[{"to":4,"weight":1},{"to":1,"weight":1}],  # cycle: 3→1→3
					4:[],
				}
			}
		_: # Topological sort — DAG
			return {
				"directed": true,
				"nodes": {
					0:{"label":"A","x":160,"y":360},
					1:{"label":"B","x":400,"y":200},
					2:{"label":"C","x":400,"y":520},
					3:{"label":"D","x":660,"y":300},
					4:{"label":"E","x":660,"y":480},
					5:{"label":"F","x":940,"y":360},
				},
				"adj": {
					0:[{"to":1,"weight":1},{"to":2,"weight":1}],
					1:[{"to":3,"weight":1}],
					2:[{"to":3,"weight":1},{"to":4,"weight":1}],
					3:[{"to":5,"weight":1}],
					4:[{"to":5,"weight":1}],
					5:[],
				}
			}
