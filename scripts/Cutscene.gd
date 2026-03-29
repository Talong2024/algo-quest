extends Node2D
# ═══════════════════════════════════════════════════
# Cutscene.gd — reusable for all cutscenes.
# Receives { cutscene_id } from GameRouter.
# Click / Space / Enter to advance.
# ═══════════════════════════════════════════════════

const SCRIPTS: Dictionary = {
	"intro": [
		{ "speaker":"Narrator",          "text":"The Algorithm Kingdom once thrived under five ancient laws — Queue, Stack, Linked List, Tree, and Graph. Each structure governed a part of the realm.",                     "color":"#888899" },
		{ "speaker":"Narrator",          "text":"Until the Algorithm Overlord shattered them all. Five structures broken. Five realms in chaos.",                                                                            "color":"#888899" },
		{ "speaker":"Algorithm Overlord","text":"Without structure, there is only entropy. The kingdom is mine.",                                                                                                            "color":"#FF6B6B" },
		{ "speaker":"Narrator",          "text":"But one soul understood every structure. The Code Keeper.",                                                                                                                "color":"#FFD93D" },
		{ "speaker":"Code Keeper",       "text":"I will restore the queue, the stack, the list, the tree, the graph. Every structure will hold again.",                                                                     "color":"#6BCB77" },
	],
	"ch1_open": [
		{ "speaker":"Gate Captain",      "text":"Keeper! The kingdom gate is in chaos! Citizens are served in random order — nobles pushing past elders, merchants cutting the line!",                                      "color":"#6BCB77" },
		{ "speaker":"Gate Captain",      "text":"The FIFO law is broken. First In, First Out — the citizen who arrived first must be served first. Without it, the kingdom starves!",                                       "color":"#6BCB77" },
		{ "speaker":"Code Keeper",       "text":"A queue. I understand. Stand aside — I will restore the order.",                                                                                                          "color":"#FFD93D" },
	],
	"ch1_close": [
		{ "speaker":"Gate Captain",      "text":"Order restored! The gate flows perfectly — every citizen served in the order they arrived. Thank you, Keeper!",                                                            "color":"#6BCB77" },
		{ "speaker":"Herald",            "text":"But news from the Castle — a wizard is trapped inside! He cast runes in the wrong order and now the doors won't open!",                                                   "color":"#FF9F43" },
		{ "speaker":"Code Keeper",       "text":"A stack. Runes cast in sequence must be popped in reverse. Last In, First Out. I must go.",                                                                               "color":"#FFD93D" },
	],
	"ch2_open": [
		{ "speaker":"Wizard",            "text":"Keeper! I pushed Fire, Ice, Thunder onto the spell stack — but the enchanted doors need them popped in REVERSE order! Thunder first, then Ice, then Fire!",              "color":"#C77DFF" },
		{ "speaker":"Wizard",            "text":"That is the law of the stack — Last In, First Out! The last spell I cast must be the first I release. But I cannot reach the buried spells!",                            "color":"#C77DFF" },
		{ "speaker":"Code Keeper",       "text":"I understand. The top rune must always come first. I will pop the stack — level by level until every door opens.",                                                        "color":"#FFD93D" },
	],
	"ch2_close": [
		{ "speaker":"Wizard",            "text":"Free at last! You understand the stack's greatest truth — it reverses any sequence automatically. That property underlies undo systems, recursion, and parsers!",        "color":"#C77DFF" },
		{ "speaker":"Wizard",            "text":"But I sense trouble below — the Chain Dungeon. The royal train's carriages have come unchained. Each node has lost its next pointer.",                                    "color":"#C77DFF" },
		{ "speaker":"Code Keeper",       "text":"A linked list. Nodes connected by pointers. I will re-link the chain.",                                                                                                   "color":"#FFD93D" },
	],
	"ch3_open": [
		{ "speaker":"Conductor",         "text":"The royal train is derailed! Carriages scattered across the track — their couplings broken, next pointers severed! The royal cargo is lost!",                            "color":"#FFD93D" },
		{ "speaker":"Conductor",         "text":"Without the chain, we cannot traverse from head to tail! We cannot insert new cargo, delete faulty carriages, or reverse the train for the return journey!",             "color":"#FFD93D" },
		{ "speaker":"Code Keeper",       "text":"Each carriage is a node. Each coupling is a next pointer. I will traverse, insert, delete, and reverse until the chain is whole again.",                                  "color":"#FFD93D" },
	],
	"ch3_close": [
		{ "speaker":"Conductor",         "text":"The train runs perfectly — head to tail, every node linked! You re-linked the chain without losing a single carriage!",                                                   "color":"#FFD93D" },
		{ "speaker":"Ancient Sage",      "text":"Well done, Keeper. But the Oracle's Forest has gone dark. The BST creatures are unfindable — left and right rules forgotten. The trees are unbalanced.",                 "color":"#6BCB77" },
		{ "speaker":"Code Keeper",       "text":"A binary search tree. Left children smaller, right children larger. I will search, insert, delete, and balance until the forest's order returns.",                        "color":"#FFD93D" },
	],
	"ch4_open": [
		{ "speaker":"Oracle",            "text":"Keeper... the creatures wander without order. Search now takes O(n) — linear, exhausting. We were O(log n). The BST property is gone.",                                  "color":"#6BCB77" },
		{ "speaker":"Oracle",            "text":"And the trees have grown lopsided — some lean so far right they are just linked lists. The AVL balance factor exceeds 1. We must rotate.",                               "color":"#6BCB77" },
		{ "speaker":"Code Keeper",       "text":"I will restore the BST rule. Search, insert, delete with the inorder successor. Rotate to balance. The forest will find its order.",                                      "color":"#FFD93D" },
	],
	"ch4_close": [
		{ "speaker":"Oracle",            "text":"The forest is balanced! All creatures found in O(log n) once more. The AVL rotations held — every balance factor is 1 or less!",                                         "color":"#6BCB77" },
		{ "speaker":"Map Spirit",        "text":"But the Kingdom Roads are severed. Roads loop back on themselves — travelers trapped in infinite cycles. BFS scouts cannot find their way. Dijkstra's paths are broken.", "color":"#4D96FF" },
		{ "speaker":"Code Keeper",       "text":"A graph. BFS for levels. DFS for depth. Dijkstra for shortest paths. I will detect every cycle and sort every dependency.",                                               "color":"#FFD93D" },
	],
	"ch5_open": [
		{ "speaker":"Messenger",         "text":"Keeper — merchants travel in circles forever! The cycle detection algorithm is gone. BFS scouts lose their queue. Dijkstra cannot find the cheapest route!",             "color":"#4D96FF" },
		{ "speaker":"Messenger",         "text":"And the royal decrees must be issued in dependency order — but the topological sort of the DAG is broken! Prerequisites are being skipped!",                             "color":"#4D96FF" },
		{ "speaker":"Code Keeper",       "text":"I will traverse breadth-first, depth-first, find shortest paths, detect every cycle, and sort the dependencies. The kingdom's roads will hold.",                        "color":"#FFD93D" },
	],
	"ch5_close": [
		{ "speaker":"Map Spirit",        "text":"All roads reconnected! Every city reachable. Shortest paths glowing blue. No cycles. Topological order restored — prerequisites respected!",                             "color":"#4D96FF" },
		{ "speaker":"Algorithm Overlord","text":"Impressive, Code Keeper. You restored the queue, the stack, the list, the tree, the graph — one by one.",                                                                "color":"#FF6B6B" },
		{ "speaker":"Algorithm Overlord","text":"But can you face all five at once? Come. Face me — if you dare.",                                                                                                        "color":"#FF6B6B" },
	],
	"boss_intro": [
		{ "speaker":"Algorithm Overlord","text":"I am the entropy that defeats every structure. I am the unsorted array. The unbalanced tree. The broken list. The cursed graph. The overflowed stack.",                  "color":"#FF6B6B" },
		{ "speaker":"Algorithm Overlord","text":"Defeat all five of my forms and the kingdom is yours. Fail once — and I consume it.",                                                                                    "color":"#FF6B6B" },
		{ "speaker":"Code Keeper",       "text":"Five structures. Five forms. I have mastered them all. Let's end this.",                                                                                                  "color":"#6BCB77" },
	],
	"ending": [
		{ "speaker":"Algorithm Overlord","text":"Impossible... you understood them all. Queue, Stack, Linked List, Tree, Graph. You saw the structure beneath the chaos.",                                                 "color":"#FF6B6B" },
		{ "speaker":"Narrator",          "text":"The Overlord dissolved into scattered bits. The five structures hummed together — gate, castle, train, forest, roads — all whole again.",                                "color":"#888899" },
		{ "speaker":"Narrator",          "text":"The Algorithm Kingdom was restored. Not by power — but by understanding every structure it was built on.",                                                               "color":"#888899" },
		{ "speaker":"Narrator",          "text":"Queue. Stack. Linked List. Tree. Graph. You are the Code Keeper.",                                                                                                       "color":"#FFD93D" },
	],
}

var _id:    String = ""
var _lines: Array  = []
var _idx:   int    = 0
var _bg:    ColorRect
var _face:  ColorRect
var _spkr:  Label
var _txt:   Label
var _prog:  Label

func receive_params(p: Dictionary) -> void:
	_id    = p.get("cutscene_id","intro") as String
	_lines = SCRIPTS.get(_id, []) as Array
	ProgressTracker.mark_cutscene_seen(_id)
	if _lines.is_empty(): GameRouter.cutscene_finished(); return
	_show(0)

func _ready() -> void:
	_bg = ColorRect.new()
	_bg.color = Color("#080810")
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	var box := ColorRect.new()
	box.color = Color("#0d0d1a")
	box.set_position(Vector2(0,520)); box.set_size(Vector2(1280,200)); add_child(box)

	var sep := ColorRect.new()
	sep.color = Color("#1a1a2e")
	sep.set_position(Vector2(0,518)); sep.set_size(Vector2(1280,2)); add_child(sep)

	_face = ColorRect.new()
	_face.set_position(Vector2(40,532)); _face.set_size(Vector2(110,110))
	add_child(_face)

	_spkr = Label.new()
	_spkr.set_position(Vector2(168,535))
	_spkr.add_theme_font_size_override("font_size",15)
	add_child(_spkr)

	_txt = Label.new()
	_txt.set_position(Vector2(168,560)); _txt.set_size(Vector2(1080,110))
	_txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_txt.add_theme_font_size_override("font_size",16)
	_txt.add_theme_color_override("font_color",Color("#e8e8f0"))
	add_child(_txt)

	_prog = Label.new()
	_prog.set_position(Vector2(20,12))
	_prog.add_theme_font_size_override("font_size",11)
	_prog.add_theme_color_override("font_color",Color("#333355"))
	add_child(_prog)

	var hint := Label.new()
	hint.text = "Click or press Space to continue  |  Esc to skip"
	hint.set_position(Vector2(860,698))
	hint.add_theme_font_size_override("font_size",11)
	hint.add_theme_color_override("font_color",Color("#333355"))
	add_child(hint)

func _show(idx: int) -> void:
	if idx >= _lines.size(): GameRouter.cutscene_finished(); return
	_idx = idx
	var line: Dictionary = _lines[idx]
	_spkr.text = line.get("speaker","") as String
	var col: Color = Color(line.get("color","#FFD93D") as String)
	_spkr.add_theme_color_override("font_color", col)
	_txt.text   = line.get("text","") as String
	_face.color = col.darkened(0.7)
	_prog.text  = "%d / %d  — %s" % [idx+1, _lines.size(), _id]

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_show(_idx + 1)
	elif event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed:
			if ke.keycode in [KEY_SPACE, KEY_ENTER]: _show(_idx + 1)
			elif ke.keycode == KEY_ESCAPE: GameRouter.cutscene_finished()
