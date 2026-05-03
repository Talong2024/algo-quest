extends Node2D
const CHAPTER_ID: int = 5

const TUTORIAL_SCENE: String = "res://scenes/chapters/graph/Tutorial.tscn"
const GAME_SCENE:     String = "res://scenes/chapters/graph/Game.tscn"

const LEVELS: Array = [
	{"level":1,"title":"BFS Traversal","op":"bfs","goal":5,
	 "desc":"Breadth-first: explore level by level using a queue",
	 "dsainfo":"BFS: queue-based. Shortest path in unweighted graphs"},
	{"level":2,"title":"DFS Traversal","op":"dfs","goal":5,
	 "desc":"Depth-first: go as deep as possible before backtracking",
	 "dsainfo":"DFS: stack-based (or recursion). Used for cycle detection, topo sort"},
	{"level":3,"title":"Shortest Path","op":"dijkstra","goal":3,
	 "desc":"Always expand the closest unvisited city — greedy choice",
	 "dsainfo":"Dijkstra: min-dist greedy with priority queue. O((V+E) log V)"},
	{"level":4,"title":"Cycle Detection","op":"cycle","goal":3,
	 "desc":"DFS back edge = cycle. Track nodes in current path",
	 "dsainfo":"Cycle: DFS with visited + in-stack sets. Back edge = cycle found"},
	{"level":5,"title":"Topological Sort","op":"topo","goal":3,
	 "desc":"Process nodes with in-degree 0 first — Kahn's algorithm",
	 "dsainfo":"Topo sort: only on DAGs. Kahn's uses queue of zero-in-degree nodes"},
]

var current_level_idx: int = 0
var _active:        Node = null
var _world:         Node = null
var _graph_manager: Node = null
var _renderer:      Node = null
var _logic:         Node = null
var _dsa_panel:     Node = null

func _ready() -> void:
	_build_shared()
	_go_tutorial()

func _build_shared() -> void:
	_graph_manager = (load("res://scripts/chapters/graph/GraphManager.gd") as GDScript).new()
	_graph_manager.name = "G_GraphManager"; add_child(_graph_manager)

	_logic = (load("res://scripts/chapters/graph/GameLogic.gd") as GDScript).new()
	_logic.name = "G_Logic"; add_child(_logic)

	_dsa_panel = (load("res://scripts/chapters/graph/DSAPanel.gd") as GDScript).new()
	_dsa_panel.name = "G_DSAPanel"; _dsa_panel.z_index = 100; add_child(_dsa_panel)

	if _logic.has_signal("level_complete"):
		_logic.level_complete.connect(_on_level_complete)
	if _logic.has_signal("game_over"):
		_logic.game_over.connect(_on_game_over)

func _go_tutorial() -> void:
	if is_instance_valid(_world): _world.free(); _world = null
	_free_active()
	_world = (load("res://scripts/chapters/graph/KingdomWorld.gd") as GDScript).new()
	_world.name = "G_WorldBehind"; _world.z_index = -20; add_child(_world)
	_active = (load(TUTORIAL_SCENE) as PackedScene).instantiate()
	_active.level_data = LEVELS[current_level_idx]
	if _active.has_signal("start_requested"):
		_active.start_requested.connect(func(): _go_game.call_deferred())
	add_child(_active)

func _go_game() -> void:
	if is_instance_valid(_world): _world.free(); _world = null
	_free_active()
	var cfg: Dictionary = LEVELS[current_level_idx]
	# Build graph data for this level
	if _graph_manager.has_method("build"):
		var gdata: Dictionary = {}
		if _graph_manager.has_method("make_level_graph"):
			gdata = _graph_manager.make_level_graph(cfg.get("level",1) as int)
		_graph_manager.build(gdata)
	if _logic.has_method("reset_stats"): _logic.reset_stats()
	_active = (load(GAME_SCENE) as PackedScene).instantiate()
	add_child(_active)
	if _active.has_method("setup"):
		_active.setup(cfg, _graph_manager, _logic, _dsa_panel)
	# level_complete/game_over wired in _build_shared — no duplicate here

func _free_active() -> void:
	if _active and is_instance_valid(_active):
		remove_child(_active); _active.free(); _active = null

func _on_level_complete() -> void:
	var score: int = 0
	if _logic and "score" in _logic: score = _logic.score as int
	if current_level_idx >= LEVELS.size() - 1:
		GameRouter.chapter_complete(CHAPTER_ID, score, 0)
	else:
		current_level_idx += 1
		_go_tutorial.call_deferred()

func _on_game_over() -> void:
	GameRouter.go_game_over(CHAPTER_ID)
