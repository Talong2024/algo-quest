extends Node2D
# ═══════════════════════════════════════════════════
# ChapterPlaceholder.gd
# Shown until the real chapter scripts are copied in.
# Auto-detects chapter from scene path.
# ═══════════════════════════════════════════════════

const CHAPTER_INFO: Dictionary = {
	1: {
		"ch_name":  "Kingdom Queue",
		"dsa":      "Queue — FIFO",
		"color":    Color("#6BCB77"),
		"desc":     "Serve citizens at the castle gate in order. First In, First Out.",
		"zip":      "kingdom_queue_topdown.zip",
		"folder":   "queue",
		"levels":   5,
		"icon":     "🏰",
		"steps": [
			"1. Unzip  kingdom_queue_topdown.zip",
			"2. Copy  scripts/*  →  scripts/chapters/queue/",
			"3. Copy  scenes/*   →  scenes/chapters/queue/",
			"4. Add  const CHAPTER_ID: int = 1  to Main.gd",
			"5. Replace  _on_level_complete  and  _on_game_over",
		],
	},
	2: {
		"ch_name":  "Castle of Echoes",
		"dsa":      "Stack — LIFO",
		"color":    Color("#C77DFF"),
		"desc":     "Pop runes from the enchanted stack. Last In, First Out.",
		"zip":      "castle_echoes_topdown.zip",
		"folder":   "stack",
		"levels":   5,
		"icon":     "🗼",
		"steps": [
			"1. Unzip  castle_echoes_topdown.zip",
			"2. Copy  scripts/*  →  scripts/chapters/stack/",
			"3. Copy  scenes/*   →  scenes/chapters/stack/",
			"4. Add  const CHAPTER_ID: int = 2  to Main.gd",
			"5. Replace  _on_level_complete  and  _on_game_over",
		],
	},
	3: {
		"ch_name":  "Chain Train",
		"dsa":      "Linked List",
		"color":    Color("#FFD93D"),
		"desc":     "Re-link train carriages. Traverse, insert, delete, reverse.",
		"zip":      "chain_train.zip",
		"folder":   "linked_list",
		"levels":   5,
		"icon":     "🚂",
		"steps": [
			"1. Unzip  chain_train.zip",
			"2. Copy  scripts/*  →  scripts/chapters/linked_list/",
			"3. Copy  scenes/*   →  scenes/chapters/linked_list/",
			"4. Add  const CHAPTER_ID: int = 3  to Main.gd",
			"5. Replace  _on_level_complete  and  _on_game_over",
		],
	},
	4: {
		"ch_name":  "Oracle's Forest",
		"dsa":      "BST / AVL / Heap",
		"color":    Color("#6BCB77"),
		"desc":     "Search the enchanted forest. Balance trees. Master the heap.",
		"zip":      "oracles_forest.zip",
		"folder":   "tree",
		"levels":   6,
		"icon":     "🌲",
		"steps": [
			"1. Unzip  oracles_forest.zip",
			"2. Copy  scripts/*  →  scripts/chapters/tree/",
			"3. Copy  scenes/*   →  scenes/chapters/tree/",
			"4. Add  const CHAPTER_ID: int = 4  to Main.gd",
			"5. Replace  _on_level_complete  and  _on_game_over",
		],
	},
	5: {
		"ch_name":  "Kingdom Roads",
		"dsa":      "Graph Algorithms",
		"color":    Color("#4D96FF"),
		"desc":     "BFS, DFS, Dijkstra, cycle detection, topological sort.",
		"zip":      "kingdom_roads.zip",
		"folder":   "graph",
		"levels":   5,
		"icon":     "🗺",
		"steps": [
			"1. Unzip  kingdom_roads.zip",
			"2. Copy  scripts/*  →  scripts/chapters/graph/",
			"3. Copy  scenes/*   →  scenes/chapters/graph/",
			"4. Add  const CHAPTER_ID: int = 5  to Main.gd",
			"5. Replace  _on_level_complete  and  _on_game_over",
		],
	},
}

var _chapter_id: int = 0

func _ready() -> void:
	_detect_chapter()
	_build_ui()

func receive_params(_p: Dictionary) -> void:
	pass

func _detect_chapter() -> void:
	var path: String = get_scene_file_path()
	if   "queue"       in path: _chapter_id = 1
	elif "stack"       in path: _chapter_id = 2
	elif "linked_list" in path: _chapter_id = 3
	elif "tree"        in path: _chapter_id = 4
	elif "graph"       in path: _chapter_id = 5

func _build_ui() -> void:
	var info: Dictionary = CHAPTER_INFO.get(_chapter_id, CHAPTER_INFO[1]) as Dictionary
	var col:     Color  = info["color"]    as Color
	var ch_name: String = info["ch_name"]  as String
	var dsa:     String = info["dsa"]      as String
	var desc:    String = info["desc"]     as String
	var icon:    String = info["icon"]     as String
	var lvls:    int    = info["levels"]   as int
	var steps:   Array  = info["steps"]    as Array

	# Background
	var bg := ColorRect.new()
	bg.color = Color("#0a0a0f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Try to load and show the map tile background
	var map_keys: Array = ["","street","mountain","desert","forest","beach"]
	if _chapter_id >= 1:
		var tex: Texture2D = AssetMap.load_tex(AssetMap.MAP_TILES.get(map_keys[_chapter_id], "") as String)
		if tex:
			var bg_tile := Sprite2D.new()
			bg_tile.texture        = tex
			bg_tile.position       = Vector2(640, 360)
			bg_tile.scale          = Vector2(4.2, 3.0)
			bg_tile.z_index        = -1
			bg_tile.modulate       = Color(1, 1, 1, 0.18)
			bg_tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(bg_tile)

	# Top accent bar
	var bar := ColorRect.new()
	bar.color = col
	bar.set_position(Vector2.ZERO)
	bar.set_size(Vector2(1280, 6))
	add_child(bar)

	# Top HUD
	var hud := ColorRect.new()
	hud.color = Color(0, 0, 0, 0.7)
	hud.set_position(Vector2(0, 6))
	hud.set_size(Vector2(1280, 52))
	add_child(hud)
	_lbl("ALGOQUEST", Vector2(20, 14), 10, Color("#4D96FF"))
	_lbl("Chapter %d of 5" % _chapter_id, Vector2(20, 30), 11, Color("#555577"))
	_btn("← World Map", Vector2(1100, 12), Vector2(160, 34), Color("#888899"),
		func(): GameRouter.go_world_map())

	# Big icon + title
	_lbl(icon, Vector2(80, 80), 52, col)
	_lbl(ch_name, Vector2(160, 88), 38, col)
	_lbl("DSA: %s" % dsa, Vector2(162, 138), 16, Color("#888899"))

	# Description
	var dl := Label.new()
	dl.text = desc
	dl.set_position(Vector2(80, 178))
	dl.set_size(Vector2(700, 44))
	dl.add_theme_font_size_override("font_size", 16)
	dl.add_theme_color_override("font_color", Color("#aaaacc"))
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(dl)

	# Level dots
	_lbl("%d Levels" % lvls, Vector2(80, 232), 13, Color("#555577"))
	for i in lvls:
		var progress: Dictionary = ProgressTracker.get_level_data(_chapter_id, i + 1)
		var done:    bool = progress.get("complete", false) as bool
		var perfect: bool = progress.get("perfect", false)  as bool
		var dot := ColorRect.new()
		dot.color = Color("#FFD93D") if perfect else (col if done else col.darkened(0.7))
		dot.set_position(Vector2(80 + i * 60, 252))
		dot.set_size(Vector2(52, 52))
		add_child(dot)
		_lbl("L%d" % (i+1), Vector2(88 + i*60, 260), 11,
			Color("#0a0a0f") if done else Color("#333355"))
		if perfect:
			_lbl("★", Vector2(100 + i*60, 276), 11, Color("#0a0a0f"))

	# RIGHT SIDE — How to add this game
	var panel := ColorRect.new()
	panel.color = Color("#0d0d18")
	panel.set_position(Vector2(820, 70))
	panel.set_size(Vector2(440, 420))
	add_child(panel)

	var ptop := ColorRect.new()
	ptop.color = col.darkened(0.5)
	ptop.set_position(Vector2(820, 70))
	ptop.set_size(Vector2(440, 4))
	add_child(ptop)

	_lbl("How to add this game:", Vector2(836, 84), 14, col)
	_lbl("(This placeholder shows until you copy scripts in)", Vector2(836, 106), 11, Color("#444466"))

	for i in steps.size():
		var step_bg := ColorRect.new()
		step_bg.color = Color("#13131f") if i % 2 == 0 else Color("#0a0a0f")
		step_bg.set_position(Vector2(820, 126 + i * 46))
		step_bg.set_size(Vector2(440, 44))
		add_child(step_bg)
		_lbl(steps[i] as String, Vector2(836, 138 + i * 46), 12, Color("#8888aa"))

	# Open docs button
	_btn("Open HowToAddGames.md", Vector2(836, 360), Vector2(400, 40), Color("#4D96FF"),
		func(): OS.shell_open(OS.get_user_data_dir()))

	_btn("Open ChapterIntegration.md", Vector2(836, 410), Vector2(400, 40), Color("#555577"),
		func(): OS.shell_open(OS.get_user_data_dir()))

	# Bottom buttons
	_btn("Progress & Achievements", Vector2(80, 330), Vector2(280, 46), Color("#4D96FF"),
		func(): GameRouter.go_progress_screen())

	_btn("★ Mark Complete (dev test)", Vector2(80, 386), Vector2(280, 46), col,
		func():
			ProgressTracker.complete_chapter(_chapter_id, 1500)
			GameRouter.go_world_map()
	)

	# DSA quick reference
	var ref_bg := ColorRect.new()
	ref_bg.color = Color("#080810")
	ref_bg.set_position(Vector2(80, 444))
	ref_bg.set_size(Vector2(700, 200))
	add_child(ref_bg)

	_lbl("DSA Quick Reference — %s" % dsa, Vector2(96, 456), 13, col)
	var ref_text: String = _get_dsa_ref(_chapter_id)
	var ref_lbl := Label.new()
	ref_lbl.text = ref_text
	ref_lbl.set_position(Vector2(96, 478))
	ref_lbl.set_size(Vector2(668, 156))
	ref_lbl.add_theme_font_size_override("font_size", 12)
	ref_lbl.add_theme_color_override("font_color", Color("#666688"))
	ref_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(ref_lbl)

func _get_dsa_ref(ch: int) -> String:
	match ch:
		1: return "FIFO: enqueue at rear, dequeue from front.\nqueue.append(item)   # O(1) enqueue\nqueue.pop_front()    # O(1) dequeue (use Array or custom Queue)\nUse case: task scheduling, BFS, print queue"
		2: return "LIFO: push/pop from the same end (top).\nstack.append(item)   # O(1) push\nstack.pop_back()     # O(1) pop\nUse case: undo/redo, call stack, expression parsing"
		3: return "Nodes connected by pointers. No random access.\nprev.next = node.next   # O(1) delete at position\nnew.next = B.next; B.next = new  # O(1) insert\nUse case: playlists, undo chains, LRU cache"
		4: return "BST: left < node < right. O(log n) balanced.\nif val < node.val: go left  else: go right\nAVL: |balance_factor| ≤ 1. Heap: parent ≤ children.\nUse case: databases, priority queues, schedulers"
		5: return "Graph: nodes + edges. adj list = Dict[node → [neighbors]].\nBFS: queue, levels.  DFS: stack, deep.  Dijkstra: min-dist.\nUse case: GPS, social networks, dependency resolution"
	return ""

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.set_position(pos)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	return l

func _btn(text: String, pos: Vector2, sz: Vector2, col: Color, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.set_position(pos)
	b.set_size(sz)
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", col)
	b.pressed.connect(cb)
	add_child(b)
