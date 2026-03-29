extends Node2D


const CHAPTER_ID: int = 1
# ═══════════════════════════════════════════════════
# Main.gd — Kingdom Queue Top-Down
# Owns all shared DSA nodes, manages scene transitions.
# ═══════════════════════════════════════════════════

const LEVELS: Array = [
	{ "level":1, "queue_size":3, "spawn_interval":4.0,
	"title":"The Gate Opens",
	"desc":"Citizens walk to the gate. Serve them in arrival order — First In, First Out!",
	"dsainfo":"FIFO: serve the FRONT citizen first" },
	{ "level":2, "queue_size":4, "spawn_interval":3.0,
	"title":"The Crowd Grows",
	"desc":"More citizens arrive! Queue fills up — serve before overflow!",
	"dsainfo":"Overflow: queue full — enqueue blocked" },
	{ "level":3, "queue_size":5, "spawn_interval":2.5,
	"title":"Patience Wears Thin",
	"desc":"Watch the patience bars! Elderly citizens leave faster.",
	"dsainfo":"Patience: citizens expire if waited too long" },
	{ "level":4, "queue_size":5, "spawn_interval":2.5,
	"title":"Royal VIPs",
	"desc":"Gold citizens are VIPs — learn the difference from a priority queue!",
	"dsainfo":"Priority Queue: rank overrides FIFO order" },
	{ "level":5, "queue_size":6, "spawn_interval":2.0,
	"title":"Two Gates",
	"desc":"Two queues open! Serve from both ends — the deque!",
	"dsainfo":"Deque: enqueue/dequeue from both ends" },
]

var current_level: int = 0

var queue_manager: Node
var citizen_spawner: Node
var gate_keeper: Node
var dsa_panel: Node2D

var _active_scene: Node = null

const TUTORIAL_SCENE:       String = "res://scenes/chapters/queue/Tutorial.tscn"
const GAME_SCENE:           String = "res://scenes/chapters/queue/Game.tscn"
const LEVEL_COMPLETE_SCENE: String = "res://scenes/chapters/queue/LevelComplete.tscn"

func _ready() -> void:
	_build_shared()
	_go_tutorial()

func _build_shared() -> void:
	queue_manager = (load("res://scripts/chapters/queue/QueueManager.gd") as GDScript).new()
	queue_manager.name = "Q_QueueManager"
	add_child(queue_manager)

	citizen_spawner = (load("res://scripts/chapters/queue/CitizenSpawner.gd") as GDScript).new()
	citizen_spawner.name = "Q_CitizenSpawner"
	add_child(citizen_spawner)

	gate_keeper = (load("res://scripts/chapters/queue/GateKeeper.gd") as GDScript).new()
	gate_keeper.name = "Q_GateKeeper"
	add_child(gate_keeper)
	gate_keeper.init(queue_manager)

	dsa_panel = (load("res://scripts/chapters/queue/DSAPanel.gd") as GDScript).new()
	dsa_panel.name = "Q_DSAPanel"
	dsa_panel.z_index = 100

	queue_manager.overflow_occurred.connect(gate_keeper.on_overflow)
	queue_manager.queue_changed.connect(_on_queue_changed)
	citizen_spawner.citizen_arrived.connect(_on_citizen_arrived)
	gate_keeper.citizen_served.connect(_on_citizen_served)
	gate_keeper.citizen_expired.connect(_on_citizen_expired)
	gate_keeper.game_over.connect(_on_game_over)
	gate_keeper.level_complete.connect(_on_level_complete)

func _go_tutorial() -> void:
	_load_scene(TUTORIAL_SCENE)
	var t: Node2D = _active_scene
	if t:
		t.level_data = LEVELS[current_level]
		t.start_requested.connect(_on_tutorial_done)

func _go_game() -> void:
	var cfg: Dictionary = LEVELS[current_level]
	queue_manager.max_size = cfg["queue_size"] as int
	queue_manager.clear()
	gate_keeper.reset_stats()

	var citizens: Array = (load("res://scripts/chapters/queue/CitizenSpawner.gd") as GDScript).get_citizens(cfg["level"] as int)
	citizen_spawner.setup(citizens, cfg["spawn_interval"] as float)

	_load_scene(GAME_SCENE)
	var g: Node2D = _active_scene
	if g:
		g.setup(cfg, queue_manager, gate_keeper, dsa_panel)

		# Reparent DSA panel into the game scene so it draws on top
		if dsa_panel.get_parent():
			dsa_panel.reparent(g)
		else:
			g.add_child(dsa_panel)

		g.citizen_clicked.connect(gate_keeper.player_picks)
		citizen_spawner.citizen_arrived.connect(g.on_citizen_arrived)
		gate_keeper.citizen_served.connect(g.on_citizen_served)
		gate_keeper.citizen_expired.connect(g.on_citizen_expired)
		gate_keeper.feedback.connect(g.show_feedback)
		gate_keeper.score_changed.connect(g.update_score)
		gate_keeper.lives_changed.connect(g.update_lives)

	gate_keeper.start_level(citizens.size())
	citizen_spawner.start()

func _load_scene(path: String) -> void:
	if _active_scene:
		_active_scene.queue_free()
	var packed: PackedScene = load(path)
	_active_scene = packed.instantiate()
	add_child(_active_scene)

func _on_tutorial_done() -> void: _go_game()
func _on_level_complete() -> void:
	var score: int = gate_keeper.score if gate_keeper else 0
	var wrong: int = 0  # tracked by ProgressTracker via complete_level
	var all_done: bool = current_level >= LEVELS.size() - 1
	if all_done:
		GameRouter.chapter_complete(CHAPTER_ID, score, wrong)
	else:
		current_level = mini(current_level + 1, LEVELS.size() - 1)
		_go_tutorial()

func _on_game_over() -> void:
	GameRouter.go_game_over(CHAPTER_ID)

func _on_queue_changed(snapshot: Array) -> void:
	dsa_panel.update(snapshot, queue_manager.max_size)

func _on_citizen_arrived(c: Dictionary) -> void:
	gate_keeper.on_citizen_arrived(c)
	queue_manager.enqueue(c)

func _on_citizen_served(_c: Dictionary) -> void:
	pass

func _on_citizen_expired(_c: Dictionary) -> void:
	pass
