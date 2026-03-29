extends Node2D
# ═══════════════════════════════════════════════════
# Main.gd — Chain Train
# Level progression shell. Wraps LL_Tutorial → LL_Game flow.
# Integrated with AlgoQuest via GameRouter.
# ═══════════════════════════════════════════════════

const CHAPTER_ID: int = 3

const TUTORIAL_SCENE: String = "res://scenes/chapters/linked_list/Tutorial.tscn"
const GAME_SCENE:     String = "res://scenes/chapters/linked_list/Game.tscn"

const LEVELS: Array = [
	{"level":1,"title":"Traverse the Chain","op":"traverse","goal":5,"desc":"Follow next pointers from head to tail"},
	{"level":2,"title":"Insert a Carriage","op":"insert","goal":3,"desc":"Insert new carriages at the correct position"},
	{"level":3,"title":"Delete a Carriage","op":"delete","goal":3,"desc":"Unlink carriages — update the next pointer"},
	{"level":4,"title":"Reverse the Train","op":"reverse","goal":1,"desc":"Reverse all next pointers — O(n) single pass"},
	{"level":5,"title":"Mixed Operations","op":"mixed","goal":8,"desc":"All operations combined"},
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
	# Wire LL_GameLogic signals if present
	for child in _active.get_children():
		if child.has_signal("level_complete"):
			child.level_complete.connect(_on_level_complete)
		if child.has_signal("game_over"):
			child.game_over.connect(_on_game_over)
	add_child(_active)

func _on_level_complete() -> void:
	var score: int = 0
	var wrong: int = 0
	# Extract score from LL_GameLogic child if present
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
