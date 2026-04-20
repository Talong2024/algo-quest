extends Node2D
const CHAPTER_ID: int = 3

const TUTORIAL_SCENE: String = "res://scenes/chapters/linked_list/Tutorial.tscn"
const GAME_SCENE:     String = "res://scenes/chapters/linked_list/Game.tscn"

const LEVELS: Array = [
	{"level":1,"title":"Traverse the Chain","op":"traverse","goal":5,
	 "desc":"Follow next pointers from head to tail — O(n) traversal",
	 "dsainfo":"Linked List: no random access, follow next pointers one by one"},
	{"level":2,"title":"Insert a Carriage","op":"insert","goal":3,
	 "desc":"Insert new carriages at the correct position",
	 "dsainfo":"Insert O(1): update prev.next and new.next — no shifting needed"},
	{"level":3,"title":"Delete a Carriage","op":"delete","goal":3,
	 "desc":"Unlink carriages — update the next pointer to skip the node",
	 "dsainfo":"Delete O(1): bypass the node — prev.next = node.next"},
	{"level":4,"title":"Reverse the Train","op":"reverse","goal":1,
	 "desc":"Reverse all next pointers — O(n) single pass",
	 "dsainfo":"Reverse: three pointers (prev, cur, next) — O(n) time O(1) space"},
	{"level":5,"title":"Mixed Operations","op":"mixed","goal":8,
	 "desc":"All operations combined — traverse, insert, delete, reverse",
	 "dsainfo":"Real-world: music playlists, browser history, undo chains"},
]

var current_level_idx: int = 0
var _active:     Node = null
var _world:      Node = null
var _ll_manager: Node = null
var _logic:      Node = null
var _dsa_panel:  Node = null

func _ready() -> void:
	_build_shared()
	_go_tutorial()

func _build_shared() -> void:
	_ll_manager = (load("res://scripts/chapters/linked_list/LinkedListManager.gd") as GDScript).new()
	_ll_manager.name = "LL_Manager"; add_child(_ll_manager)

	_logic = (load("res://scripts/chapters/linked_list/GameLogic.gd") as GDScript).new()
	_logic.name = "LL_Logic"; add_child(_logic)

	_dsa_panel = (load("res://scripts/chapters/linked_list/DSAPanel.gd") as GDScript).new()
	_dsa_panel.name = "LL_DSAPanel"; _dsa_panel.z_index = 100; add_child(_dsa_panel)

	if _logic.has_signal("level_complete"):
		_logic.level_complete.connect(_on_level_complete)
	if _logic.has_signal("game_over"):
		_logic.game_over.connect(_on_game_over)

func _go_tutorial() -> void:
	if is_instance_valid(_world): _world.free(); _world = null
	_free_active()
	_world = (load("res://scripts/chapters/linked_list/TrainWorld.gd") as GDScript).new()
	_world.name = "LL_WorldBehind"; _world.z_index = -20; add_child(_world)
	_active = (load(TUTORIAL_SCENE) as PackedScene).instantiate()
	_active.level_data = LEVELS[current_level_idx]
	if _active.has_signal("start_requested"):
		_active.start_requested.connect(func(): _go_game.call_deferred())
	add_child(_active)

func _go_game() -> void:
	if is_instance_valid(_world): _world.free(); _world = null
	_free_active()
	var cfg: Dictionary = LEVELS[current_level_idx]
	if _logic.has_method("start_level"): _logic.start_level(str(cfg.get("op","traverse")), cfg)
	_active = (load(GAME_SCENE) as PackedScene).instantiate()
	add_child(_active)
	if _active.has_method("setup"):
		_active.setup(cfg, _ll_manager, _logic, _dsa_panel)
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
