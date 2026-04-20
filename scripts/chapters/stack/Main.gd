extends Node2D
const CHAPTER_ID: int = 2

const LEVELS: Array = [
	{"level":1,"stack_size":3,"title":"The First Door",
	 "desc":"Watch 2 spells PUSH. Then click the TOP rune to POP — Last In, First Out!",
	 "dsainfo":"LIFO: Last In, First Out — pop in reverse push order"},
	{"level":2,"stack_size":4,"title":"Deeper Magic",
	 "desc":"3 runes stacked. The BOTTOM rune is last — you can only reach the TOP.",
	 "dsainfo":"Stack depth: buried runes are inaccessible until those above are popped"},
	{"level":3,"stack_size":5,"title":"The Spell Reversal",
	 "desc":"4 runes. The stack reverses the push sequence automatically — that IS LIFO!",
	 "dsainfo":"Reversal: a stack naturally reverses any sequence"},
	{"level":4,"stack_size":6,"title":"Predict the Stack",
	 "desc":"5 runes. Open the stack panel [Q] — predict what's buried before you pop!",
	 "dsainfo":"Stack state: visualize contents at each step"},
	{"level":5,"stack_size":6,"title":"The Full Tower",
	 "desc":"6 runes — full stack! One extra push = OVERFLOW = tower collapses!",
	 "dsainfo":"Overflow: pushing past max_size causes stack failure"},
]

var current_level: int = 0
var stack_manager: Node = null
var rune_spawner:  Node = null
var spell_caster:  Node = null
var _dsa_panel:    Node = null
var _active_scene: Node = null
var _world_behind: Node = null

const TUTORIAL_SCENE := "res://scenes/chapters/stack/Tutorial.tscn"
const GAME_SCENE     := "res://scenes/chapters/stack/Game.tscn"

func _ready() -> void:
	_build_shared()
	_go_tutorial()

func _build_shared() -> void:
	stack_manager = (load("res://scripts/chapters/stack/StackManager.gd") as GDScript).new()
	stack_manager.name = "S_StackManager"; add_child(stack_manager)

	rune_spawner = (load("res://scripts/chapters/stack/RuneSpawner.gd") as GDScript).new()
	rune_spawner.name = "S_RuneSpawner"; add_child(rune_spawner)

	spell_caster = (load("res://scripts/chapters/stack/SpellCaster.gd") as GDScript).new()
	spell_caster.name = "S_SpellCaster"; add_child(spell_caster)
	spell_caster.init(stack_manager)

	_dsa_panel = (load("res://scripts/chapters/stack/DSAPanel.gd") as GDScript).new()
	_dsa_panel.name = "S_DSAPanel"; _dsa_panel.z_index = 100; add_child(_dsa_panel)

	stack_manager.stack_changed.connect(_on_stack_changed)
	spell_caster.level_complete.connect(_on_level_complete)
	spell_caster.game_over.connect(_on_game_over)

func _go_tutorial() -> void:
	if is_instance_valid(_world_behind): _world_behind.free()
	_world_behind = (load("res://scripts/chapters/stack/CastleWorld.gd") as GDScript).new()
	_world_behind.name = "S_WorldBehind"; _world_behind.z_index = -20; add_child(_world_behind)
	_free_scene()
	_active_scene = (load(TUTORIAL_SCENE) as PackedScene).instantiate(); add_child(_active_scene)
	_active_scene.level_data = LEVELS[current_level]
	_active_scene.start_requested.connect(func(): _go_game.call_deferred())

func _go_game() -> void:
	if is_instance_valid(_world_behind): _world_behind.free(); _world_behind = null
	var cfg: Dictionary = LEVELS[current_level]
	stack_manager.max_size = cfg["stack_size"] as int
	stack_manager.clear(); spell_caster.reset_stats()
	var sequence: Array = (load("res://scripts/chapters/stack/RuneSpawner.gd") as GDScript
		).get_sequence(cfg["level"] as int)
	var runes: Array = rune_spawner.build_runes(sequence)
	_free_scene()
	_active_scene = (load(GAME_SCENE) as PackedScene).instantiate(); add_child(_active_scene)
	var g: Node2D = _active_scene
	g.setup(cfg, stack_manager, spell_caster, _dsa_panel)
	g.set_all_runes(runes)
	g.rune_clicked.connect(spell_caster.player_pops)
	spell_caster.rune_pushed.connect(g.on_rune_pushed)
	spell_caster.rune_popped.connect(g.on_rune_popped)
	spell_caster.push_phase_complete.connect(g.on_push_phase_done)
	spell_caster.door_unlocked.connect(g.on_door_unlock)
	spell_caster.feedback.connect(g.show_feedback)
	spell_caster.score_changed.connect(g.update_score)
	spell_caster.lives_changed.connect(g.update_lives)
	spell_caster.start_level(runes, cfg["stack_size"] as int)

func _free_scene() -> void:
	if _active_scene and is_instance_valid(_active_scene):
		remove_child(_active_scene); _active_scene.free(); _active_scene = null

func _on_level_complete() -> void:
	var score: int = spell_caster.score if spell_caster else 0
	var wrong: int = spell_caster.wrong_pops if spell_caster else 0
	if current_level >= LEVELS.size() - 1:
		GameRouter.chapter_complete(CHAPTER_ID, score, wrong)
	else:
		current_level += 1
		_go_tutorial.call_deferred()

func _on_game_over() -> void: GameRouter.go_game_over(CHAPTER_ID)
func _on_stack_changed(snap: Array) -> void:
	if is_instance_valid(_dsa_panel):
		_dsa_panel.update(snap, stack_manager.max_size,
			"push" if spell_caster.phase == "push" else "pop")
