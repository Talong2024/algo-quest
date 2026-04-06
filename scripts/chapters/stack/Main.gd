extends Node2D


const CHAPTER_ID: int = 2
# ═══════════════════════════════════════════════════
# Main.gd — Castle of Echoes Top-Down
# Owns shared DSA nodes. Manages scene transitions.
# ═══════════════════════════════════════════════════

const LEVELS: Array = [
	{ "level":1, "stack_size":3, "title":"The First Door",
	"desc":"The wizard casts 2 spells. Watch them PUSH. Then click the TOP rune to POP — LIFO!",
	"dsainfo":"LIFO: pop in exact reverse of push order" },
	{ "level":2, "stack_size":4, "title":"Deeper Magic",
	"desc":"3 runes stacked. The BOTTOM rune is the last you'll ever pop. Watch the depth labels.",
	"dsainfo":"Stack depth: buried runes are inaccessible" },
	{ "level":3, "stack_size":5, "title":"The Spell Reversal",
	"desc":"4 runes. The stack reverses the push sequence automatically — that is LIFO in action!",
	"dsainfo":"Reversal: stack naturally reverses any sequence" },
	{ "level":4, "stack_size":6, "title":"Predict the Stack",
	"desc":"5 runes. Press Q to open the stack panel — predict what is buried before you pop!",
	"dsainfo":"Stack state: visualize contents after each operation" },
	{ "level":5, "stack_size":6, "title":"The Full Tower",
	"desc":"6 runes — full stack! One extra push = OVERFLOW = tower collapses!",
	"dsainfo":"Overflow: pushing past max_size causes failure" },
]

var current_level: int = 0

var stack_manager: Node
var rune_spawner: Node
var spell_caster: Node
var dsa_panel: Node2D

var _active_scene: Node = null

const TUTORIAL_SCENE:       String = "res://scenes/chapters/stack/Tutorial.tscn"
const GAME_SCENE:           String = "res://scenes/chapters/stack/Game.tscn"
const LEVEL_COMPLETE_SCENE: String = "res://scenes/chapters/stack/LevelComplete.tscn"

func _ready() -> void:
	_build_shared()
	_go_tutorial()

func _build_shared() -> void:
	stack_manager = (load("res://scripts/chapters/stack/StackManager.gd") as GDScript).new()
	stack_manager.name = "S_StackManager"
	add_child(stack_manager)

	rune_spawner = (load("res://scripts/chapters/stack/RuneSpawner.gd") as GDScript).new()
	rune_spawner.name = "S_RuneSpawner"
	add_child(rune_spawner)

	spell_caster = (load("res://scripts/chapters/stack/SpellCaster.gd") as GDScript).new()
	spell_caster.name = "S_SpellCaster"
	add_child(spell_caster)
	spell_caster.init(stack_manager)

	dsa_panel = (load("res://scripts/chapters/stack/DSAPanel.gd") as GDScript).new()
	dsa_panel.name = "S_DSAPanel"
	dsa_panel.z_index = 100

	stack_manager.stack_changed.connect(_on_stack_changed)
	spell_caster.score_changed.connect(_on_score)
	spell_caster.lives_changed.connect(_on_lives)
	spell_caster.feedback.connect(_on_feedback)
	spell_caster.rune_pushed.connect(_on_rune_pushed)
	spell_caster.rune_popped.connect(_on_rune_popped)
	spell_caster.push_phase_complete.connect(_on_push_done)
	spell_caster.door_unlocked.connect(_on_door_unlock)
	spell_caster.level_complete.connect(_on_level_complete)
	spell_caster.game_over.connect(_on_game_over)

func _go_tutorial() -> void:
	# Build world behind so tutorial shows as overlay
	var world: Node2D = (load("res://scripts/chapters/stack/CastleWorld.gd") as GDScript).new()
	world.name = "_WorldBehind"
	world.z_index = -20
	add_child(world)
	_load_scene(TUTORIAL_SCENE)
	var t: Node2D = _active_scene
	if t:
		t.level_data = LEVELS[current_level]
		t.start_requested.connect(_on_tutorial_done)

func _go_game() -> void:
	var cfg: Dictionary = LEVELS[current_level]
	stack_manager.max_size = cfg["stack_size"] as int
	stack_manager.clear()
	spell_caster.reset_stats()

	var sequence: Array = (load("res://scripts/chapters/stack/RuneSpawner.gd") as GDScript).get_sequence(cfg["level"] as int)
	var runes: Array    = rune_spawner.build_runes(sequence)

	_load_scene(GAME_SCENE)
	var g: Node2D = _active_scene
	if g:
		g.setup(cfg, stack_manager, spell_caster, dsa_panel)

		if dsa_panel.get_parent(): dsa_panel.reparent(g)
		else: g.add_child(dsa_panel)

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

func _load_scene(path: String) -> void:
	if _active_scene: _active_scene.queue_free()
	_active_scene = (load(path) as PackedScene).instantiate()
	add_child(_active_scene)

func _on_tutorial_done() -> void:  _go_game()
func _on_level_complete() -> void:
	var score: int = spell_caster.score if spell_caster else 0
	var wrong: int = spell_caster.wrong_pops if spell_caster else 0
	var all_done: bool = current_level >= LEVELS.size() - 1
	if all_done:
		GameRouter.chapter_complete(CHAPTER_ID, score, wrong)
	else:
		current_level = mini(current_level + 1, LEVELS.size() - 1)
		_go_tutorial()

func _on_game_over() -> void:
	GameRouter.go_game_over(CHAPTER_ID)

func _on_stack_changed(snapshot: Array) -> void:
	dsa_panel.update(snapshot, stack_manager.max_size,
		"push" if spell_caster.phase == "push" else "pop")

func _on_score(_v: int) -> void:  pass
func _on_lives(_v: int) -> void:  pass
func _on_feedback(_m: String, _g: bool) -> void: pass
func _on_rune_pushed(_r: Dictionary) -> void:    pass
func _on_rune_popped(_r: Dictionary) -> void:    pass
func _on_push_done() -> void:     pass
func _on_door_unlock(_c: int) -> void: pass
