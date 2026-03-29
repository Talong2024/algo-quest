extends Node2D

signal next_requested
signal retry_requested
signal menu_requested

func setup(cfg: Dictionary, score: int, win: bool, has_next: bool) -> void:
	var bg:=ColorRect.new(); bg.color=Color("#1a1a0a"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var panel:=ColorRect.new(); panel.color=Color("#111108"); panel.set_position(Vector2(240,80)); panel.set_size(Vector2(800,560)); add_child(panel)
	_lbl("Level %d Clear!" % cfg.get("level",1) if win else "Roads Blocked!",Vector2(290,110),34,Color("#FFD93D") if win else Color("#FF6B6B"))
	_lbl("Score: %d"%score,Vector2(560,170),22,Color("#FFD93D"))
	var rb:=ColorRect.new(); rb.color=Color("#080a02"); rb.set_position(Vector2(260,215)); rb.set_size(Vector2(760,160)); add_child(rb)
	_lbl("What you learned:",Vector2(276,227),14,Color("#4D96FF"))
	var recap:=Label.new(); recap.set_position(Vector2(276,250)); recap.set_custom_minimum_size(Vector2(720,110))
	recap.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; recap.add_theme_font_size_override("font_size",13)
	recap.add_theme_color_override("font_color",Color("#aaaaaa"))
	recap.text=_get_recap(cfg.get("operation","bfs") as String, win); add_child(recap)
	var cb:=ColorRect.new(); cb.color=Color("#040602"); cb.set_position(Vector2(260,385)); cb.set_size(Vector2(760,80)); add_child(cb)
	var code:=Label.new(); code.set_position(Vector2(276,397)); code.add_theme_font_size_override("font_size",12)
	code.add_theme_color_override("font_color",Color("#6BCB77"))
	code.text=_get_code(cfg.get("operation","bfs") as String); add_child(code)
	if win and has_next: _btn("Next Level ▶",Vector2(740,490),Color("#6BCB77"),func(): emit_signal("next_requested"))
	elif win: _btn("🏆 Kingdom Master!",Vector2(700,490),Color("#FFD93D"),func(): emit_signal("menu_requested"))
	else: _btn("↺ Retry",Vector2(640,490),Color("#FF6B6B"),func(): emit_signal("retry_requested"))
	_btn("Menu",Vector2(260,490),Color("#666640"),func(): emit_signal("menu_requested"))

func _get_recap(op: String, win: bool) -> String:
	if not win: return "The roads confused you! Remember the key rule for each algorithm:\nBFS=queue/FIFO, DFS=stack/LIFO, Dijkstra=min unvisited dist, Cycle=back edge, Topo=in-degree 0 first."
	match op:
		"bfs":  return "BFS explores level by level using a QUEUE (FIFO). Guarantees shortest path in unweighted graphs.\nAll cities at distance 1 before distance 2, etc. Time: O(V+E), Space: O(V).\nReal world: social networks, GPS navigation, web crawlers."
		"dfs":  return "DFS explores as deep as possible using a STACK (LIFO). Backtracks when stuck.\nGood for: maze solving, topological sort, cycle detection, connected components.\nTime: O(V+E), Space: O(V). Recursive DFS uses the call stack implicitly."
		"dijkstra": return "Dijkstra finds shortest paths from a source to all cities — O((V+E)log V) with min-heap.\nGreedy: always settle the closest unvisited city. Requires non-negative edge weights.\nReal world: GPS routing, network packets, game pathfinding (A* extends Dijkstra)."
		"cycle":return "Cycle detection via DFS back edges: if DFS reaches an already-visited ancestor, a cycle exists.\nUndirected: any visited non-parent neighbor = cycle. Directed: recursive stack = cycle.\nReal world: deadlock detection, dependency resolution, circuit analysis."
		"topo": return "Topological sort: linear order of nodes where all edges go forward. Only possible on DAGs.\nKahn's algorithm: repeatedly process nodes with in-degree 0, reduce neighbor in-degrees.\nReal world: build systems (make), task scheduling, course prerequisites, package managers."
		_: return "All graph algorithms mastered!"

func _get_code(op: String) -> String:
	match op:
		"bfs":  return "from collections import deque\nqueue=deque([start]); visited={start}\nwhile queue: u=queue.popleft(); [queue.append(v) for v in adj[u] if v not in visited]"
		"dfs":  return "stack=[start]; visited=set()\nwhile stack: u=stack.pop(); visited.add(u); stack.extend(v for v in adj[u] if v not in visited)"
		"dijkstra": return "import heapq; dist={v:inf for v in G}; dist[s]=0; pq=[(0,s)]\nwhile pq: d,u=heappop(pq); [heappush(pq,(d+w,v)) for v,w in adj[u] if d+w<dist[v] and not (dist[v:=v]>d+w)]"
		"cycle":return "# DFS cycle detection:\nfor nb in adj[node]:\n    if nb in visited and nb!=parent: return True  # back edge = cycle!"
		"topo": return "in_deg={v:0 for v in G}; [in_deg.__setitem__(v,in_deg[v]+1) for u in G for v in adj[u]]\nq=[v for v in G if in_deg[v]==0]\nwhile q: u=q.pop(0); [q.append(v) for v in adj[u] if (in_deg.__setitem__(v,in_deg[v]-1) or True) and in_deg[v]==0]"
		_: return ""

func _btn(text: String, pos: Vector2, col: Color, cb: Callable) -> void:
	var b:=Button.new(); b.text=text; b.set_position(pos); b.set_size(Vector2(180,46))
	b.add_theme_font_size_override("font_size",15); b.add_theme_color_override("font_color",col)
	b.pressed.connect(cb); add_child(b)

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l:=Label.new(); l.text=text; l.set_position(pos)
	l.add_theme_font_size_override("font_size",sz); l.add_theme_color_override("font_color",col); add_child(l); return l
