extends Node2D
const CHAPTER_ID: int = 1

const LEVELS: Array = [
	{"level":1,"queue_size":5,"spawn_interval":5.0,"title":"The Gate Opens",
	 "dsainfo":"FIFO: serve the FRONT citizen first","mechanic":"fifo",
	 "hint":"Wait for citizen to reach the gate, then SPACE or click"},
	{"level":2,"queue_size":3,"spawn_interval":3.5,"title":"The Queue Fills Up",
	 "dsainfo":"Bounded queue: overflow when capacity exceeded","mechanic":"overflow",
	 "hint":"Serve fast — only 3 slots. Full queue = overflow!"},
	{"level":3,"queue_size":5,"spawn_interval":3.2,"title":"Monsters at the Gate",
	 "dsainfo":"TTL + Security: expiry and enemy rejection","mechanic":"patience",
	 "hint":"SPACE to serve citizens, R to REJECT monsters"},
	{"level":4,"queue_size":5,"spawn_interval":3.5,"title":"Royal Priority",
	 "dsainfo":"Priority Queue: rank overrides FIFO","mechanic":"priority",
	 "hint":"DRAG VIP citizens into correct priority position"},
	{"level":5,"queue_size":6,"spawn_interval":2.5,"title":"Two Gates — The Deque",
	 "dsainfo":"Deque: Double-Ended Queue","mechanic":"deque",
	 "hint":"F = front gate, B = back gate — check citizen labels!"},
]

var current_level:   int  = 0
var queue_manager:   Node = null
var citizen_spawner: Node = null
var gate_keeper:     Node = null
var _dsa_panel_node: Node = null
var _active_scene:   Node = null
var _world_behind:   Node = null  # track explicitly

const TUTORIAL_SCENE := "res://scenes/chapters/queue/Tutorial.tscn"
const GAME_SCENE     := "res://scenes/chapters/queue/Game.tscn"

func _ready() -> void:
	_build_shared()
	_go_tutorial()

func _build_shared() -> void:
	queue_manager = (load("res://scripts/chapters/queue/QueueManager.gd") as GDScript).new()
	queue_manager.name = "Q_QueueManager"; add_child(queue_manager)

	citizen_spawner = (load("res://scripts/chapters/queue/CitizenSpawner.gd") as GDScript).new()
	citizen_spawner.name = "Q_CitizenSpawner"; add_child(citizen_spawner)

	gate_keeper = (load("res://scripts/chapters/queue/GateKeeper.gd") as GDScript).new()
	gate_keeper.name = "Q_GateKeeper"; add_child(gate_keeper)
	gate_keeper.init(queue_manager)

	_dsa_panel_node = (load("res://scripts/chapters/queue/DSAPanel.gd") as GDScript).new()
	_dsa_panel_node.name = "Q_DSAPanel"; _dsa_panel_node.z_index = 100
	add_child(_dsa_panel_node)

	queue_manager.overflow_occurred.connect(gate_keeper.on_overflow)
	queue_manager.queue_changed.connect(_on_queue_changed)
	citizen_spawner.citizen_arrived.connect(_on_citizen_arrived)
	gate_keeper.citizen_served.connect(_on_citizen_served)
	gate_keeper.citizen_expired.connect(_on_citizen_expired)
	gate_keeper.game_over.connect(_on_game_over)
	gate_keeper.level_complete.connect(_on_level_complete)

# ── Tutorial flow ─────────────────────────────────────────────────────────────

func _go_tutorial() -> void:
	_spawn_world_behind()
	if current_level == 0:
		_play_walkin_then_tutorial()
	else:
		_show_tutorial()

func _spawn_world_behind() -> void:
	# Remove any existing world-behind first
	if is_instance_valid(_world_behind):
		_world_behind.free()
		_world_behind = null
	_world_behind = (load("res://scenes/chapters/queue/World.tscn") as PackedScene).instantiate()
	_world_behind.name = "Q_WorldBehind"; _world_behind.z_index = -20
	add_child(_world_behind)

func _play_walkin_then_tutorial() -> void:
	_show_tutorial()

func _show_tutorial() -> void:
	_free_scene()
	_active_scene = (load(TUTORIAL_SCENE) as PackedScene).instantiate()
	add_child(_active_scene)
	_active_scene.level_data = LEVELS[current_level]
	_active_scene.start_requested.connect(_on_tutorial_done)

# ── Game flow ─────────────────────────────────────────────────────────────────

func _go_game() -> void:
	# Free world-behind
	if is_instance_valid(_world_behind):
		_world_behind.free(); _world_behind = null

	var cfg: Dictionary = LEVELS[current_level]
	queue_manager.max_size = cfg["queue_size"] as int
	if queue_manager.queue_changed.is_connected(_on_queue_changed):
		queue_manager.queue_changed.disconnect(_on_queue_changed)
	queue_manager.clear()
	gate_keeper.reset_stats()
	gate_keeper.set_mechanic(cfg.get("mechanic","fifo") as String)

	var citizens: Array = (load("res://scripts/chapters/queue/CitizenSpawner.gd") as GDScript
		).get_citizens(cfg["level"] as int, cfg.get("mechanic","fifo") as String)
	citizen_spawner.setup(citizens, cfg["spawn_interval"] as float)

	_free_scene()
	_active_scene = (load(GAME_SCENE) as PackedScene).instantiate()
	add_child(_active_scene)
	var g: Node2D = _active_scene

	g.setup(cfg, queue_manager, gate_keeper, _dsa_panel_node)
	if not queue_manager.queue_changed.is_connected(_on_queue_changed):
		queue_manager.queue_changed.connect(_on_queue_changed)

	_safe_disconnect(citizen_spawner.citizen_arrived, g.on_citizen_arrived)
	_safe_disconnect(gate_keeper.citizen_served,      g.on_citizen_served)
	_safe_disconnect(gate_keeper.citizen_expired,     g.on_citizen_expired)
	_safe_disconnect(gate_keeper.feedback,            g.show_feedback)
	_safe_disconnect(gate_keeper.score_changed,       g.update_score)
	_safe_disconnect(gate_keeper.lives_changed,       g.update_lives)
	_safe_disconnect(gate_keeper.anger_triggered,     g.on_citizen_angry)
	_safe_disconnect(gate_keeper.drag_requested,      g.on_drag_requested)
	_safe_disconnect(gate_keeper.overflow_visual,     g.on_overflow_visual)
	_safe_disconnect(gate_keeper.deque_prompt,        g.on_deque_prompt)
	_safe_disconnect(gate_keeper.enemy_rejected,      g.on_enemy_rejected)

	g.citizen_clicked.connect(gate_keeper.player_picks)
	citizen_spawner.citizen_arrived.connect(g.on_citizen_arrived)
	gate_keeper.citizen_served.connect(g.on_citizen_served)
	gate_keeper.citizen_expired.connect(g.on_citizen_expired)
	gate_keeper.feedback.connect(g.show_feedback)
	gate_keeper.score_changed.connect(g.update_score)
	gate_keeper.lives_changed.connect(g.update_lives)
	gate_keeper.anger_triggered.connect(g.on_citizen_angry)
	gate_keeper.drag_requested.connect(g.on_drag_requested)
	gate_keeper.overflow_visual.connect(g.on_overflow_visual)
	gate_keeper.deque_prompt.connect(g.on_deque_prompt)
	gate_keeper.enemy_rejected.connect(g.on_enemy_rejected)

	gate_keeper.start_level(citizens.size())
	citizen_spawner.start()

func _free_scene() -> void:
	if _active_scene and is_instance_valid(_active_scene):
		remove_child(_active_scene)
		_active_scene.free()
		_active_scene = null

func _safe_disconnect(sig: Signal, cb: Callable) -> void:
	if sig.is_connected(cb): sig.disconnect(cb)

# ── Signals ───────────────────────────────────────────────────────────────────

func _on_tutorial_done() -> void: _go_game.call_deferred()

func _on_level_complete() -> void:
	var score: int = gate_keeper.score if gate_keeper else 0
	if current_level >= LEVELS.size() - 1:
		GameRouter.chapter_complete(CHAPTER_ID, score, 0)
	else:
		current_level += 1
		_go_tutorial()

func _on_game_over() -> void:
	GameRouter.go_game_over(CHAPTER_ID)

func _on_queue_changed(snapshot: Array) -> void:
	if is_instance_valid(_dsa_panel_node):
		_dsa_panel_node.update(snapshot, queue_manager.max_size)

func _on_citizen_arrived(c: Dictionary) -> void:
	gate_keeper.on_citizen_arrived(c)
	queue_manager.enqueue(c)

func _on_citizen_served(_c: Dictionary) -> void: pass
func _on_citizen_expired(_c: Dictionary) -> void: pass
