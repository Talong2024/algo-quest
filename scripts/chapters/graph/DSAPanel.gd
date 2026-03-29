extends Node2D

# ═══════════════════════════════════════════════════
# DSAPanel.gd — Kingdom Roads (Graph)
# Shows current algorithm state, queue/stack,
# visited set, distances, and explanation.
# ═══════════════════════════════════════════════════

var _bg:      ColorRect
var _title:   Label
var _body:    Label
var _hint:    Label
var _visible: bool = true

const W: float = 340.0
const H: float = 580.0
const X: float = 920.0
const Y: float = 70.0

func _ready() -> void:
	_build()

func _build() -> void:
	_bg = ColorRect.new()
	_bg.color = Color("#0d0d18")
	_bg.set_position(Vector2(X, Y))
	_bg.set_size(Vector2(W, H))
	add_child(_bg)

	var top := ColorRect.new()
	top.color = Color("#4D96FF")
	top.set_position(Vector2(X, Y))
	top.set_size(Vector2(W, 4))
	add_child(top)

	_title = Label.new()
	_title.set_position(Vector2(X + 12, Y + 10))
	_title.add_theme_font_size_override("font_size", 14)
	_title.add_theme_color_override("font_color", Color("#4D96FF"))
	add_child(_title)

	_body = Label.new()
	_body.set_position(Vector2(X + 12, Y + 36))
	_body.set_size(Vector2(W - 24, H - 80))
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override("font_size", 13)
	_body.add_theme_color_override("font_color", Color("#aaaacc"))
	add_child(_body)

	_hint = Label.new()
	_hint.set_position(Vector2(X + 12, Y + H - 36))
	_hint.set_size(Vector2(W - 24, 30))
	_hint.add_theme_font_size_override("font_size", 11)
	_hint.add_theme_color_override("font_color", Color("#555577"))
	add_child(_hint)

func update(snapshot: Dictionary, operation: String, logic = null) -> void:
	match operation:
		"bfs":
			_title.text = "BFS — Breadth-First Search"
			var body := "Data structure: QUEUE\n\nRule: enqueue all unvisited neighbors,\nthen dequeue the front.\n\n"
			if logic:
				var q: Array = logic.get("bfs_queue", []) as Array
				var v: Array = []
				for nid in logic.get("visited", {}):
					v.append(str(nid))
				body += "Queue: [%s]\nVisited: {%s}" % [", ".join(q.map(func(x): return str(x))), ", ".join(v)]
			_body.text = body
			_hint.text = "Click the YELLOW city (front of queue)"
		"dfs":
			_title.text = "DFS — Depth-First Search"
			_body.text = "Data structure: STACK\n\nRule: push unvisited neighbors,\npop from top, go as deep as possible.\n\nBack edge = cycle detected."
			_hint.text = "Click the YELLOW city (top of stack)"
		"dijkstra":
			_title.text = "Dijkstra — Shortest Path"
			_body.text = "Greedy: always expand the\nunvisited node with minimum distance.\n\nRelax edges: if dist[u]+w < dist[v],\nupdate dist[v].\n\nComplexity: O((V+E) log V)"
			_hint.text = "Click the closest unvisited city"
		"cycle":
			_title.text = "Cycle Detection"
			_body.text = "DFS with recursion stack.\n\nIf neighbor is in rec_stack:\n→ back edge found → CYCLE!\n\nUndirected: use parent tracking.\nDirected: use recursion stack."
			_hint.text = "Follow DFS — find the back edge"
		"topo":
			_title.text = "Topological Sort (Kahn's)"
			_body.text = "Step 1: compute in-degrees\nStep 2: enqueue nodes with in-degree=0\nStep 3: dequeue, reduce neighbors' in-degrees\nStep 4: if neighbor in-degree→0, enqueue it\n\nResult: valid dependency order."
			_hint.text = "Click city with in-degree = 0"
		_:
			_title.text = "Graph"
			_body.text = snapshot.get("desc", "") as String
			_hint.text = ""

func toggle() -> void:
	_visible = not _visible
	_bg.visible = _visible
	_title.visible = _visible
	_body.visible = _visible
	_hint.visible = _visible
