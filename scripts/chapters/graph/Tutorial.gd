extends CanvasLayer

signal start_requested
var level_data: Dictionary = {}
var _timer: Timer
var _anim_lbl: Label
var _step: int = 0

func _ready() -> void:
	_build_ui()
	_timer = Timer.new(); _timer.wait_time = 1.6
	_timer.timeout.connect(_demo_step); add_child(_timer); _timer.start()

func _build_ui() -> void:
	var bg := ColorRect.new(); bg.color = Color(0.04, 0.06, 0.04, 0.88)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var hdr := ColorRect.new(); hdr.color = Color("#111108")
	hdr.set_position(Vector2.ZERO); hdr.set_size(Vector2(1280,64)); add_child(hdr)
	_lbl("DSA TUTORIAL",Vector2(20,8),11,Color("#FFD93D"))
	_lbl("Level %d — %s" % [level_data.get("level",1),level_data.get("title","")],
		Vector2(20,26),22,Color("#e8e8d0"))
	_lbl("DSA Focus: "+level_data.get("dsainfo",""),Vector2(700,34),13,Color("#FFD93D"))
	var desc := _lbl(level_data.get("desc",""),Vector2(20,78),15,Color("#aaaaaa"))
	desc.set_custom_minimum_size(Vector2(800,0)); desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var rb := ColorRect.new(); rb.color=Color("#111108"); rb.set_position(Vector2(20,140)); rb.set_size(Vector2(540,280)); add_child(rb)
	_lbl("Graph Rules:",Vector2(36,152),15,Color("#FFD93D"))
	var rules := Label.new(); rules.text=_get_rules(); rules.set_position(Vector2(36,178))
	rules.set_custom_minimum_size(Vector2(500,220)); rules.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	rules.add_theme_font_size_override("font_size",14); rules.add_theme_color_override("font_color",Color("#e8e8d0")); add_child(rules)
	var pb := ColorRect.new(); pb.color=Color("#1a1a0a"); pb.set_position(Vector2(590,140)); pb.set_size(Vector2(660,280)); add_child(pb)
	_lbl("Live Demo:",Vector2(606,152),14,Color("#FFD93D"))
	_anim_lbl = Label.new(); _anim_lbl.set_position(Vector2(606,380))
	_anim_lbl.set_custom_minimum_size(Vector2(630,60)); _anim_lbl.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_anim_lbl.add_theme_font_size_override("font_size",13); _anim_lbl.add_theme_color_override("font_color",Color("#FFD93D")); add_child(_anim_lbl)
	var cb := ColorRect.new(); cb.color=Color("#080a02"); cb.set_position(Vector2(20,440)); cb.set_size(Vector2(1220,110)); add_child(cb)
	var code := Label.new(); code.text=_get_code(); code.set_position(Vector2(36,452))
	code.add_theme_font_size_override("font_size",13); code.add_theme_color_override("font_color",Color("#6BCB77")); add_child(code)
	var btn := Button.new(); btn.text="▶  Ride into the Kingdom"; btn.set_position(Vector2(500,572)); btn.set_size(Vector2(280,52))
	btn.add_theme_font_size_override("font_size",18); btn.pressed.connect(func(): emit_signal("start_requested")); add_child(btn)

func _demo_step() -> void:
	_step += 1
	var op: String = level_data.get("operation","bfs") as String
	match op:
		"bfs":
			match _step:
				1: _anim_lbl.text="Graph: A-B-C-D-E\nStart BFS from A"
				2: _anim_lbl.text="Visit A → queue: [B, C]\n(A's neighbors enqueued)"
				3: _anim_lbl.text="Dequeue B → queue: [C, D]\n(B's unvisited neighbors enqueued)"
				4: _anim_lbl.text="Dequeue C → queue: [D, E]\nLevel 2 complete!"
				5: _step=0; _anim_lbl.text="BFS visits level-by-level using a queue!"
		"dfs":
			match _step:
				1: _anim_lbl.text="Start DFS from A\nStack: [A]"
				2: _anim_lbl.text="Pop A, push neighbors\nStack: [B, C] → visit B next"
				3: _anim_lbl.text="Pop B, push B's neighbors\nStack: [C, D] → go deep!"
				4: _anim_lbl.text="Pop D — dead end! Backtrack\nStack: [C] → pop C next"
				5: _step=0; _anim_lbl.text="DFS goes deep first, backtracks when stuck!"
		"dijkstra":
			match _step:
				1: _anim_lbl.text="Start at A (dist=0)\nAll others: dist=∞"
				2: _anim_lbl.text="Settle A (min dist)\nRelax: B=3, C=2"
				3: _anim_lbl.text="Settle C (dist=2, min)\nRelax: E=4"
				4: _anim_lbl.text="Settle B (dist=3)\nShortest paths found!"
				5: _step=0; _anim_lbl.text="Always pick unvisited city with smallest distance!"
		"cycle":
			match _step:
				1: _anim_lbl.text="Traverse: A→B→C"
				2: _anim_lbl.text="From C, edge to A exists\nA is already visited!"
				3: _anim_lbl.text="This is a BACK EDGE → CYCLE!\nA→B→C→A forms a cycle"
				4: _step=0; _anim_lbl.text="Back edges in DFS reveal cycles!"
		"topo":
			match _step:
				1: _anim_lbl.text="Directed graph: A→B, A→C, B→D\nIn-degrees: A=0, B=1, C=1, D=1"
				2: _anim_lbl.text="Process A first (in-degree 0)\nReduce B and C in-degrees"
				3: _anim_lbl.text="Now B and C have in-degree 0\nProcess either next!"
				4: _step=0; _anim_lbl.text="Topo sort: always process 0 in-degree nodes first!"

func _get_rules() -> String:
	match level_data.get("operation","bfs") as String:
		"bfs":  return "• Graph: cities = nodes, roads = edges\n• BFS explores level by level using a QUEUE\n• Click the city at the FRONT of the queue (yellow)\n• Enqueues all unvisited neighbors before moving to next level\n• Wrong city = wrong level order = -1 life"
		"dfs":  return "• DFS explores as deep as possible using a STACK\n• Click the city on TOP of the stack (blue)\n• When a dead end is hit, BACKTRACK (pop stack)\n• Explores one full branch before trying another\n• Stack shows the current exploration path"
		"dijkstra": return "• Dijkstra finds SHORTEST paths to all cities\n• Always pick the UNVISITED city with SMALLEST known distance\n• Relaxation: if new_dist < old_dist, update!\n• Road weights = travel cost between cities\n• Guarantees shortest path when all weights ≥ 0"
		"cycle":return "• A CYCLE means you can get back to a city you already visited\n• DFS detects cycles via BACK EDGES\n• A back edge points from current city to an ancestor\n• Click the city that creates the cycle (already visited)\n• Directed graphs: back edges in DFS tree = cycle"
		"topo": return "• TOPOLOGICAL SORT: order cities so all roads go forward\n• Only works on DAGs (directed acyclic graphs)\n• A city can only be visited when ALL prerequisites are done\n• In-degree = number of roads pointing TO this city\n• Process cities with in-degree 0 first (purple = ready)"
		_: return ""

func _get_code() -> String:
	match level_data.get("operation","bfs") as String:
		"bfs":  return "queue.popleft()  # dequeue FRONT — FIFO order\nfor nb in adj[city]:\n    if nb not visited: visited.add(nb); queue.append(nb)"
		"dfs":  return "stack.pop()  # pop TOP — LIFO order\nfor nb in adj[city]:\n    if nb not visited: stack.append(nb)"
		"dijkstra": return "u = min(unvisited, key=lambda v: dist[v])  # smallest dist\nfor v,w in adj[u]:\n    if dist[u]+w < dist[v]: dist[v]=dist[u]+w  # relax"
		"cycle":return "if nb in visited and nb != parent:  # back edge!\n    CYCLE FOUND  # nb is ancestor → cycle exists"
		"topo": return "queue = [v for v if in_deg[v]==0]  # start: no prerequisites\nfor nb in adj[u]: in_deg[nb]-=1  # reduce on processing"
		_: return ""

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l:=Label.new(); l.text=text; l.set_position(pos)
	l.add_theme_font_size_override("font_size",sz); l.add_theme_color_override("font_color",col); add_child(l); return l
