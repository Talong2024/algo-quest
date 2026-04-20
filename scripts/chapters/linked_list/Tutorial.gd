extends Node2D

signal start_requested

var level_data: Dictionary = {}

var _timer:    Timer
var _anim_lbl: Label
var _step:     int   = 0
var _demo_ll:  Array = []   # [{label, next}]

const DIALOGUE_SCRIPTS = preload("res://scripts/shared/DialogueScripts.gd")

func _ready() -> void:
	_build_ui()
	_launch_dialogue()
	_run_demo()

func _launch_dialogue() -> void:
	var dlg: Node = load("res://scenes/shared/DialogueBox.tscn").instantiate()
	add_child(dlg)
	var level: int = level_data.get("level", 1) as int
	var lines: Array = DIALOGUE_SCRIPTS.ll_level_intro(level)
	if not lines.is_empty():
		dlg.show_dialogue(lines)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.06, 0.04, 0.88)
	bg.set_position(Vector2.ZERO)
	bg.set_size(Vector2(1280, 720))
	add_child(bg)

	var hdr := ColorRect.new()
	hdr.color = Color("#0a0c02")
	hdr.set_position(Vector2.ZERO)
	hdr.set_size(Vector2(1280,64))
	add_child(hdr)

	var tag := Label.new()
	tag.text  = "DSA TUTORIAL"
	tag.set_position(Vector2(20,8))
	tag.add_theme_font_size_override("font_size", 11)
	tag.add_theme_color_override("font_color", Color("#FFD93D"))
	add_child(tag)

	var title := Label.new()
	title.text = "Level %d — %s" % [level_data.get("level",1), level_data.get("title","")]
	title.set_position(Vector2(20,26))
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#e8e8d0"))
	add_child(title)

	var dsa := Label.new()
	dsa.text = "DSA Focus: " + level_data.get("dsainfo","linked list")
	dsa.set_position(Vector2(700,34))
	dsa.add_theme_font_size_override("font_size", 13)
	dsa.add_theme_color_override("font_color", Color("#FFD93D"))
	add_child(dsa)

	var desc := Label.new()
	desc.text = level_data.get("desc","")
	desc.set_position(Vector2(20,78))
	desc.set_custom_minimum_size(Vector2(800,40))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color("#aaaaaa"))
	add_child(desc)

	var rb := ColorRect.new()
	rb.color = Color("#0a0c02")
	rb.set_position(Vector2(20,140))
	rb.set_size(Vector2(540,280))
	add_child(rb)

	var rt := Label.new()
	rt.text = "Linked List Rules:"
	rt.set_position(Vector2(36,152))
	rt.add_theme_font_size_override("font_size", 15)
	rt.add_theme_color_override("font_color", Color("#FFD93D"))
	add_child(rt)

	var rules := Label.new()
	rules.set_position(Vector2(36,178))
	rules.set_custom_minimum_size(Vector2(500,220))
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.add_theme_font_size_override("font_size", 14)
	rules.add_theme_color_override("font_color", Color("#e8e8d0"))
	rules.text = _get_rules()
	add_child(rules)

	var pb := ColorRect.new()
	pb.color = Color("#1e2a0e")
	pb.set_position(Vector2(590,140))
	pb.set_size(Vector2(660,280))
	add_child(pb)

	var pt := Label.new()
	pt.text = "Live Demo:"
	pt.set_position(Vector2(606,152))
	pt.add_theme_font_size_override("font_size", 14)
	pt.add_theme_color_override("font_color", Color("#6BCB77"))
	add_child(pt)

	_anim_lbl = Label.new()
	_anim_lbl.set_position(Vector2(606,390))
	_anim_lbl.set_custom_minimum_size(Vector2(630,40))
	_anim_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_anim_lbl.add_theme_font_size_override("font_size", 13)
	_anim_lbl.add_theme_color_override("font_color", Color("#6BCB77"))
	add_child(_anim_lbl)

	var cb := ColorRect.new()
	cb.color = Color("#060802")
	cb.set_position(Vector2(20,440))
	cb.set_size(Vector2(1220,110))
	add_child(cb)

	var code := Label.new()
	code.text = (
		"# Linked List node in GDScript:\n" +
		"node = { 'value': 10, 'next': null }   # singly linked\n" +
		"node.next = next_node                   # set pointer\n" +
		"prev.next = node.next                   # delete: skip over node"
	)
	code.set_position(Vector2(36,452))
	code.add_theme_font_size_override("font_size", 13)
	code.add_theme_color_override("font_color", Color("#6BCB77"))
	add_child(code)

	var btn := Button.new()
	btn.text = "▶  Board the Train"
	btn.set_position(Vector2(540,572))
	btn.set_size(Vector2(200,52))
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(func(): emit_signal("start_requested"))
	add_child(btn)

	_timer = Timer.new()
	_timer.wait_time = 1.5
	_timer.timeout.connect(_demo_step)
	add_child(_timer)

func _run_demo() -> void:
	_demo_ll = []
	_step    = 0
	_timer.start()

func _demo_step() -> void:
	_step += 1
	var op: String = _get_demo_op()
	match _step:
		1:
			_demo_ll = [{"l":"A","c":Color("#FFD93D")},{"l":"B","c":Color("#6BCB77")},{"l":"C","c":Color("#4D96FF")}]
			_anim_lbl.text = "List: A → B → C → null  (HEAD=A, TAIL=C)"
		2:
			match op:
				"traverse": _anim_lbl.text = "TRAVERSE: visit A… follow next… visit B… follow next… visit C… null — done!"
				"insert":   _anim_lbl.text = "INSERT between B and C:\n1. new.next = C\n2. B.next = new\nResult: A → B → NEW → C"
				"delete":   _anim_lbl.text = "DELETE B:\nprev.next = B.next\nA.next = C  (skip B!)\nResult: A → C → null"
				"reverse":  _anim_lbl.text = "REVERSE:\nA.next=null, B.next=A, C.next=B\nNew HEAD = C\nResult: C → B → A → null"
		3: _step = 0; _anim_lbl.text = "Repeating demo..."
	queue_redraw()

func _get_demo_op() -> String:
	var level: int = level_data.get("level",1) as int
	match level:
		1: return "traverse"
		2: return "insert"
		3: return "delete"
		4: return "reverse"
		_: return "traverse"

func _get_rules() -> String:
	var level: int = level_data.get("level",1) as int
	match level:
		1: return "• Each carriage = a node with a VALUE and a NEXT pointer\n• HEAD is the engine (first node)\n• TAIL's next pointer = null (end of list)\n• Click each carriage in order HEAD → TAIL to traverse"
		2: return "• INSERT: add a new carriage between two existing ones\n• Step 1: new.next = B.next (point to B's old neighbour)\n• Step 2: B.next = new (B now points to new node)\n• Click the correct gap (blue +) to insert!"
		3: return "• DELETE: remove a carriage and re-link the chain\n• prev.next = target.next  (skip over target)\n• The removed node is now unreachable\n• Click the target carriage to remove it!"
		4: return "• REVERSE: flip all next pointer directions\n• TAIL becomes new HEAD\n• Every node's next now points backward\n• Click REVERSE button to flip the whole train!"
		5: return "• DOUBLY LINKED: each carriage has NEXT and PREV\n• next = forward pointer  |  prev = backward pointer\n• Can traverse in both directions\n• Insert/delete must update BOTH pointers!"
		_: return "• All linked list operations combined"

func _draw() -> void:
	if _demo_ll.is_empty(): return
	var ox: float = 610.0
	var oy: float = 290.0
	var nw: float = 70.0
	var nh: float = 48.0
	var gap: float = 40.0
	for i in _demo_ll.size():
		var nx: float = ox + i * (nw + gap)
		var col: Color = _demo_ll[i]["c"] as Color
		draw_rect(Rect2(nx, oy, nw, nh), col.darkened(0.5))
		draw_rect(Rect2(nx, oy, nw, nh), col, false, 1.5)
		draw_string(ThemeDB.fallback_font,
			Vector2(nx + nw/2.0 - 8, oy + nh/2.0 + 5),
			_demo_ll[i]["l"] as String,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
		if i < _demo_ll.size() - 1:
			draw_line(Vector2(nx+nw+2, oy+nh/2.0),
				Vector2(nx+nw+gap-2, oy+nh/2.0), Color("#6BCB77"), 2.0)
			draw_string(ThemeDB.fallback_font,
				Vector2(nx+nw+10, oy+nh/2.0-14), "→",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#FFD93D"))
		else:
			draw_string(ThemeDB.fallback_font,
				Vector2(nx+nw+6, oy+nh/2.0-5), "null",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#FF6B6B"))
