extends Node2D
const CHAPTER_ID: int = 4

const TUTORIAL_SCENE: String = "res://scenes/chapters/tree/Tutorial.tscn"
const GAME_SCENE:     String = "res://scenes/chapters/tree/Game.tscn"

const LEVELS: Array = [
	{"level":1,"title":"BST Search","op":"search","goal":5,
	 "desc":"Go left if smaller, right if larger — O(log n) search",
	 "dsainfo":"BST: left < node < right. Binary search in tree form"},
	{"level":2,"title":"BST Insert","op":"insert","goal":5,
	 "desc":"Insert maintaining BST property — always lands as a leaf",
	 "dsainfo":"Insert: search for position, place as leaf node"},
	{"level":3,"title":"BST Delete","op":"delete","goal":3,
	 "desc":"Two-child delete: replace with inorder successor",
	 "dsainfo":"Delete cases: leaf, one child, two children (inorder successor)"},
	{"level":4,"title":"AVL Balance","op":"balance","goal":3,
	 "desc":"Rotate to keep |balance_factor| ≤ 1 at every node",
	 "dsainfo":"AVL: self-balancing BST — O(log n) guaranteed always"},
	{"level":5,"title":"Heap Operations","op":"heap","goal":5,
	 "desc":"Max-heap: parent always greater than children",
	 "dsainfo":"Heap: extract-max O(log n), insert O(log n), build O(n)"},
	{"level":6,"title":"All Tree Ops","op":"mixed","goal":8,
	 "desc":"BST, AVL and Heap combined — master all tree operations",
	 "dsainfo":"Trees: BST search, AVL balance, Heap priority — all O(log n)"},
]

var current_level_idx: int = 0
var _active:      Node = null
var _world:       Node = null
var _bst_manager: Node = null
var _logic:       Node = null
var _dsa_panel:   Node = null

func _ready() -> void:
	_build_shared()
	_go_tutorial()

func _build_shared() -> void:
	_bst_manager = (load("res://scripts/chapters/tree/BSTManager.gd") as GDScript).new()
	_bst_manager.name = "T_BSTManager"; add_child(_bst_manager)

	_logic = (load("res://scripts/chapters/tree/GameLogic.gd") as GDScript).new()
	_logic.name = "T_Logic"; add_child(_logic)

	_dsa_panel = (load("res://scripts/chapters/tree/DSAPanel.gd") as GDScript).new()
	_dsa_panel.name = "T_DSAPanel"; _dsa_panel.z_index = 100; add_child(_dsa_panel)

	if _logic.has_signal("level_complete"):
		_logic.level_complete.connect(_on_level_complete)
	if _logic.has_signal("game_over"):
		_logic.game_over.connect(_on_game_over)

func _go_tutorial() -> void:
	if is_instance_valid(_world): _world.free(); _world = null
	_free_active()
	_world = (load("res://scripts/chapters/tree/ForestWorld.gd") as GDScript).new()
	_world.name = "T_WorldBehind"; _world.z_index = -20; add_child(_world)
	_active = (load(TUTORIAL_SCENE) as PackedScene).instantiate()
	_active.level_data = LEVELS[current_level_idx]
	if _active.has_signal("start_requested"):
		_active.start_requested.connect(func(): _go_game.call_deferred())
	add_child(_active)

func _go_game() -> void:
	if is_instance_valid(_world): _world.free(); _world = null
	_free_active()
	var cfg: Dictionary = LEVELS[current_level_idx]
	if _logic.has_method("reset_stats"): _logic.reset_stats()
	_active = (load(GAME_SCENE) as PackedScene).instantiate()
	add_child(_active)
	if _active.has_method("setup"):
		_active.setup(cfg, _bst_manager, _logic, _dsa_panel)
	if _active.has_signal("level_complete"):
		_active.level_complete.connect(_on_level_complete)
	if _active.has_signal("game_over"):
		_active.game_over.connect(_on_game_over)

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
