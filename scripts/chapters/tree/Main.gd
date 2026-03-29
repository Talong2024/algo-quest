extends Node2D
# ═══════════════════════════════════════════════════
# Main.gd — Oracle's Forest
# Level progression shell. Wraps T_Tutorial → T_Game flow.
# Integrated with AlgoQuest via GameRouter.
# ═══════════════════════════════════════════════════

const CHAPTER_ID: int = 4

const TUTORIAL_SCENE: String = "res://scenes/chapters/tree/Tutorial.tscn"
const GAME_SCENE:     String = "res://scenes/chapters/tree/Game.tscn"

const LEVELS: Array = [
	{"level":1,"title":"BST Search","op":"search","goal":5,"desc":"Binary search — go left if smaller, right if larger"},
	{"level":2,"title":"BST Insert","op":"insert","goal":5,"desc":"Insert maintaining BST property — left<root<right"},
	{"level":3,"title":"BST Delete","op":"delete","goal":3,"desc":"Delete with inorder successor for two-child nodes"},
	{"level":4,"title":"AVL Balance","op":"balance","goal":3,"desc":"Rotate to keep |balance_factor| ≤ 1"},
	{"level":5,"title":"Heap Operations","op":"heap","goal":5,"desc":"Max-heap: parent always greater than children"},
	{"level":6,"title":"All Tree Ops","op":"mixed","goal":8,"desc":"BST, AVL and Heap combined"},
]

var current_level_idx: int = 0
var _active: Node = null

func _ready() -> void:
	_go_tutorial()

func _go_tutorial() -> void:
	if _active:
		_active.queue_free()
	var packed: PackedScene = load(TUTORIAL_SCENE)
	_active = packed.instantiate()
	_active.level_data = LEVELS[current_level_idx]
	if _active.has_signal("start_requested"):
		_active.start_requested.connect(_go_game)
	add_child(_active)

func _go_game() -> void:
	if _active:
		_active.queue_free()
	var packed: PackedScene = load(GAME_SCENE)
	_active = packed.instantiate()
	_active.level_data = LEVELS[current_level_idx]
	if _active.has_signal("level_complete"):
		_active.level_complete.connect(_on_level_complete)
	if _active.has_signal("game_over"):
		_active.game_over.connect(_on_game_over)
	# Wire T_GameLogic signals if present
	for child in _active.get_children():
		if child.has_signal("level_complete"):
			child.level_complete.connect(_on_level_complete)
		if child.has_signal("game_over"):
			child.game_over.connect(_on_game_over)
	add_child(_active)

func _on_level_complete() -> void:
	var score: int = 0
	var wrong: int = 0
	# Extract score from T_GameLogic child if present
	if _active:
		for child in _active.get_children():
			if "score" in child: score = child.score
			if "_mistakes" in child: wrong = child._mistakes
			elif "mistakes" in child: wrong = child.mistakes
	var all_done: bool = current_level_idx >= LEVELS.size() - 1
	if all_done:
		GameRouter.chapter_complete(CHAPTER_ID, score, wrong)
	else:
		current_level_idx += 1
		_go_tutorial()

func _on_game_over() -> void:
	GameRouter.go_game_over(CHAPTER_ID)
