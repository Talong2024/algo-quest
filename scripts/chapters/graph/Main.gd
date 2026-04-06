extends Node2D
# ═══════════════════════════════════════════════════
# Main.gd — Kingdom Roads (Graph Algorithms)
# Level progression: Node2D → G_Game loop
# Integrated with AlgoQuest via GameRouter.
# ═══════════════════════════════════════════════════

const CHAPTER_ID: int = 5

const TUTORIAL_SCENE: String = "res://scenes/chapters/graph/Tutorial.tscn"
const GAME_SCENE:     String = "res://scenes/chapters/graph/Game.tscn"

const LEVELS: Array = [
	{"level":1,"title":"BFS Traversal",    "op":"bfs",     "goal":5, "desc":"Breadth-first: explore level by level using a queue"},
	{"level":2,"title":"DFS Traversal",    "op":"dfs",     "goal":5, "desc":"Depth-first: explore as deep as possible using a stack"},
	{"level":3,"title":"Shortest Path",    "op":"dijkstra","goal":3, "desc":"Dijkstra: always expand the minimum distance node"},
	{"level":4,"title":"Cycle Detection",  "op":"cycle",   "goal":3, "desc":"DFS: back edge = cycle found"},
	{"level":5,"title":"Topological Sort", "op":"topo",    "goal":3, "desc":"Process nodes with in-degree 0 first"},
]

var current_level_idx: int = 0
var _active: Node = null
var _graph_manager: Node = null

func _ready() -> void:
	# Create shared graph manager
	_graph_manager = Node.new()
	_graph_manager.set_script(load("res://scripts/chapters/graph/GraphManager.gd"))
	_graph_manager.name = "G_GraphManager"
	add_child(_graph_manager)
	_go_tutorial()

func _go_tutorial() -> void:
	# Build world behind so tutorial shows as overlay
	var world: Node2D = (load("res://scripts/chapters/graph/KingdomWorld.gd") as GDScript).new()
	world.name = "_WorldBehind"
	world.z_index = -20
	add_child(world)
	if _active: _active.queue_free()
	var packed: PackedScene = load(TUTORIAL_SCENE)
	_active = packed.instantiate()
	_active.level_data = LEVELS[current_level_idx]
	if _active.has_signal("start_requested"):
		_active.start_requested.connect(_go_game)
	add_child(_active)

func _go_game() -> void:
	if _active: _active.queue_free()
	var lvl: Dictionary = LEVELS[current_level_idx]
	# Build the graph for this level
	var graph_data: Dictionary = (load("res://scripts/chapters/graph/GraphManager.gd") as GDScript).make_level_graph(lvl.get("level", 1) as int)
	_graph_manager.build(graph_data)
	
	var packed: PackedScene = load(GAME_SCENE)
	_active = packed.instantiate()
	_active.level_data = lvl
	add_child(_active)
	
	# Wire up after adding to tree
	if _active.has_method("setup"):
		var renderer = null
		var logic = null
		var dsa = null
		for child in _active.get_children():
			if child.get_script() and "G_GraphRenderer" in str(child.get_script()):
				renderer = child
			elif child.get_script() and "G_GameLogic" in str(child.get_script()):
				logic = child
			elif child.get_script() and "DSAPanel" in str(child.get_script()):
				dsa = child
		if renderer and logic:
			_active.setup(lvl, renderer, logic, dsa)
	
	# Wire signals
	for child in _active.get_children():
		if child.has_signal("level_complete"):
			child.level_complete.connect(_on_level_complete)
		if child.has_signal("game_over"):
			child.game_over.connect(_on_game_over)
	if _active.has_signal("level_complete"):
		_active.level_complete.connect(_on_level_complete)
	if _active.has_signal("game_over"):
		_active.game_over.connect(_on_game_over)

func _on_level_complete() -> void:
	var score: int = 0
	var wrong: int = 0
	if _active:
		for child in _active.get_children():
			if "score" in child: score = child.score
			if "_mistakes" in child: wrong = child._mistakes
	var all_done: bool = current_level_idx >= LEVELS.size() - 1
	if all_done:
		GameRouter.chapter_complete(CHAPTER_ID, score, wrong)
	else:
		current_level_idx += 1
		_go_tutorial()

func _on_game_over() -> void:
	GameRouter.go_game_over(CHAPTER_ID)
