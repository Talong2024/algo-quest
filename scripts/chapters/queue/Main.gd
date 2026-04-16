extends Node2D
const CHAPTER_ID: int = 1

# ── Level definitions — each teaches ONE concept through consequence ──────────
const LEVELS: Array = [
	{
		"level": 1, "queue_size": 4, "spawn_interval": 4.5,
		"title": "The Gate Opens",
		"desc":  "Serve citizens in the order they arrived. The front person goes first — always.",
		"dsainfo": "FIFO: First In, First Out — serve the front citizen",
		"mechanic": "fifo",
		"hint": "Press SPACE or click the FRONT citizen to serve them",
	},
	{
		"level": 2, "queue_size": 3, "spawn_interval": 2.8,
		"title": "The Queue Fills Up",
		"desc":  "The queue can only hold 3 people. When it's full, no one else can join — serve fast!",
		"dsainfo": "Bounded queue: overflow happens when capacity is exceeded",
		"mechanic": "overflow",
		"hint": "Watch the queue slots — serve before they fill or citizens are turned away",
	},
	{
		"level": 3, "queue_size": 5, "spawn_interval": 3.0,
		"title": "Patience Runs Out",
		"desc":  "Elderly citizens leave if they wait too long. You may need to serve them early — breaking FIFO.",
		"dsainfo": "TTL: items expire in a queue. Sometimes order must bend.",
		"mechanic": "patience",
		"hint": "Watch red patience bars — serve elderly citizens before they leave!",
	},
	{
		"level": 4, "queue_size": 5, "spawn_interval": 3.5,
		"title": "Royal Priority",
		"desc":  "VIP citizens must be placed in priority order. Drag them into the correct position in the queue.",
		"dsainfo": "Priority Queue: higher priority dequeues before lower, regardless of arrival",
		"mechanic": "priority",
		"hint": "DRAG VIP citizens to reorder the queue. Wrong order = gate blocks!",
	},
	{
		"level": 5, "queue_size": 6, "spawn_interval": 2.5,
		"title": "Two Gates — The Deque",
		"desc":  "Two gates open! Press F to serve from the front, B to serve from the back.",
		"dsainfo": "Deque: Double-Ended Queue — enqueue/dequeue from either end",
		"mechanic": "deque",
		"hint": "Press F (front gate) or B (back gate). Some citizens need a specific gate!",
	},
]

var current_level: int = 0
var queue_manager:  Node
var citizen_spawner: Node
var gate_keeper:    Node
var dsa_panel:      Node2D
var _active_scene:  Node = null

const TUTORIAL_SCENE       := "res://scenes/chapters/queue/Tutorial.tscn"
const GAME_SCENE           := "res://scenes/chapters/queue/Game.tscn"

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
	dsa_panel.name    = "Q_DSAPanel"
	dsa_panel.z_index = 100

	queue_manager.overflow_occurred.connect(gate_keeper.on_overflow)
	queue_manager.queue_changed.connect(_on_queue_changed)
	citizen_spawner.citizen_arrived.connect(_on_citizen_arrived)
	gate_keeper.citizen_served.connect(_on_citizen_served)
	gate_keeper.citizen_expired.connect(_on_citizen_expired)
	gate_keeper.game_over.connect(_on_game_over)
	gate_keeper.level_complete.connect(_on_level_complete)

func _go_tutorial() -> void:
	_build_world_for_tutorial()
	# If level 1: play walk-in before showing tutorial
	if current_level == 0:
		_play_walkin_then_tutorial()
	else:
		_show_tutorial()

func _play_walkin_then_tutorial() -> void:
	var world_behind: Node2D = get_node_or_null("Q_WorldBehind") as Node2D
	if not world_behind:
		_show_tutorial()
		return

	var walker: Node2D = load("res://scripts/lpc/CharacterSprite.gd").new()
	walker.name     = "WalkInPlayer"
	walker.scale    = Vector2(3.0, 3.0)
	walker.position = Vector2(640, 780)
	walker.z_index  = 20
	world_behind.add_child(walker)

	var appearance: Dictionary = SaveManager.get_player_appearance()
	if appearance.is_empty():
		appearance = CharacterRandomizer.randomize_character()
	walker.apply(appearance)
	walker.play("walk")
	walker.set_direction(1)  # sideways walk (left profile) looks correct

	var tw := create_tween()
	tw.tween_property(walker, "position:y", 310.0, 2.8).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		walker.play("idle")
		walker.set_direction(2)
		get_tree().create_timer(0.9).timeout.connect(_show_tutorial, CONNECT_ONE_SHOT)
	)

func _show_tutorial() -> void:
	_load_scene(TUTORIAL_SCENE)
	var t: Node2D = _active_scene
	if t:
		t.level_data = LEVELS[current_level]
		t.start_requested.connect(_on_tutorial_done)

func _build_world_for_tutorial() -> void:
	var world: Node2D = (load("res://scenes/chapters/queue/World.tscn") as PackedScene).instantiate()
	world.name    = "Q_WorldBehind"
	world.z_index = -20
	add_child(world)

func _go_game() -> void:
	var wb: Node = get_node_or_null("Q_WorldBehind")
	if wb: wb.queue_free()

	var cfg: Dictionary = LEVELS[current_level]
	queue_manager.max_size = cfg["queue_size"] as int
	if queue_manager.queue_changed.is_connected(_on_queue_changed):
		queue_manager.queue_changed.disconnect(_on_queue_changed)
	queue_manager.clear()
	gate_keeper.reset_stats()
	gate_keeper.set_mechanic(cfg.get("mechanic","fifo") as String)

	var citizens: Array = (load("res://scripts/chapters/queue/CitizenSpawner.gd") as GDScript).get_citizens(
		cfg["level"] as int, cfg.get("mechanic","fifo") as String)
	citizen_spawner.setup(citizens, cfg["spawn_interval"] as float)

	_load_scene(GAME_SCENE)
	var g: Node2D = _active_scene
	if g:
		g.setup(cfg, queue_manager, gate_keeper, dsa_panel)
		if dsa_panel.get_parent():
			dsa_panel.reparent(g)
		else:
			g.add_child(dsa_panel)
		if not queue_manager.queue_changed.is_connected(_on_queue_changed):
			queue_manager.queue_changed.connect(_on_queue_changed)

		# Clean stale connections
		for sig_name in ["citizen_arrived","citizen_served","citizen_expired"]:
			pass
		if citizen_spawner.citizen_arrived.is_connected(g.on_citizen_arrived):
			citizen_spawner.citizen_arrived.disconnect(g.on_citizen_arrived)
		if gate_keeper.citizen_served.is_connected(g.on_citizen_served):
			gate_keeper.citizen_served.disconnect(g.on_citizen_served)
		if gate_keeper.citizen_expired.is_connected(g.on_citizen_expired):
			gate_keeper.citizen_expired.disconnect(g.on_citizen_expired)

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

	gate_keeper.start_level(citizens.size())
	citizen_spawner.start()

func _load_scene(path: String) -> void:
	if _active_scene:
		_active_scene.queue_free()
	_active_scene = (load(path) as PackedScene).instantiate()
	add_child(_active_scene)

func _on_tutorial_done() -> void: _go_game()

func _on_level_complete() -> void:
	var score: int    = gate_keeper.score if gate_keeper else 0
	var all_done: bool = current_level >= LEVELS.size() - 1
	if all_done:
		GameRouter.chapter_complete(CHAPTER_ID, score, 0)
	else:
		current_level = mini(current_level + 1, LEVELS.size() - 1)
		_go_tutorial()

func _on_game_over() -> void:
	GameRouter.go_game_over(CHAPTER_ID)

func _on_queue_changed(snapshot: Array) -> void:
	if is_instance_valid(dsa_panel):
		dsa_panel.update(snapshot, queue_manager.max_size)

func _on_citizen_arrived(c: Dictionary) -> void:
	gate_keeper.on_citizen_arrived(c)
	queue_manager.enqueue(c)

func _on_citizen_served(_c: Dictionary) -> void: pass
func _on_citizen_expired(_c: Dictionary) -> void: pass
