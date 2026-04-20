extends Node2D

signal start_requested

var level_data: Dictionary = {}

var _demo_stack: Array = []
var _step:       int   = 0
var _timer:      Timer
var _anim_lbl:   Label

const DIALOGUE_SCRIPTS = preload("res://scripts/shared/DialogueScripts.gd")

func _ready() -> void:
	_build_ui()
	_launch_dialogue()
	_run_demo()

func _launch_dialogue() -> void:
	var dlg: Node = load("res://scenes/shared/DialogueBox.tscn").instantiate()
	add_child(dlg)
	var level: int = level_data.get("level", 1) as int
	var lines: Array = DIALOGUE_SCRIPTS.stack_level_intro(level)
	if not lines.is_empty():
		dlg.show_dialogue(lines)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.06, 0.04, 0.88)
	bg.set_position(Vector2.ZERO)
	bg.set_size(Vector2(1280, 720))
	add_child(bg)

	var header := ColorRect.new()
	header.color = Color("#110e18")
	header.set_position(Vector2.ZERO)
	header.set_size(Vector2(1280, 64))
	add_child(header)

	var tag := Label.new()
	tag.text = "DSA TUTORIAL"
	tag.set_position(Vector2(20, 8))
	tag.add_theme_font_size_override("font_size", 11)
	tag.add_theme_color_override("font_color", Color("#C77DFF"))
	add_child(tag)

	var title := Label.new()
	title.text = "Level %d — %s" % [level_data.get("level",1), level_data.get("title","The First Door")]
	title.set_position(Vector2(20, 26))
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#e8e8f0"))
	add_child(title)

	var dsa_lbl := Label.new()
	dsa_lbl.text = "DSA Focus: " + level_data.get("dsainfo","LIFO stack")
	dsa_lbl.set_position(Vector2(700, 34))
	dsa_lbl.add_theme_font_size_override("font_size", 13)
	dsa_lbl.add_theme_color_override("font_color", Color("#C77DFF"))
	add_child(dsa_lbl)

	var desc := Label.new()
	desc.text = level_data.get("desc","")
	desc.set_position(Vector2(20, 78))
	desc.set_custom_minimum_size(Vector2(800, 40))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color("#aaaacc"))
	add_child(desc)

	var rules_bg := ColorRect.new()
	rules_bg.color = Color(0.04, 0.06, 0.04, 0.88)
	rules_bg.set_position(Vector2(20, 140))
	rules_bg.set_size(Vector2(540, 280))
	add_child(rules_bg)

	var rt := Label.new()
	rt.text = "Stack Rules:"
	rt.set_position(Vector2(36, 152))
	rt.add_theme_font_size_override("font_size", 15)
	rt.add_theme_color_override("font_color", Color("#FFD93D"))
	add_child(rt)

	var rules := Label.new()
	rules.set_position(Vector2(36, 178))
	rules.set_custom_minimum_size(Vector2(500, 220))
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.add_theme_font_size_override("font_size", 14)
	rules.add_theme_color_override("font_color", Color("#e8e8f0"))
	rules.text = _get_rules()
	add_child(rules)

	var preview_bg := ColorRect.new()
	preview_bg.color = Color(0.04, 0.06, 0.04, 0.88)
	preview_bg.set_position(Vector2(590, 140))
	preview_bg.set_size(Vector2(660, 280))
	add_child(preview_bg)

	var pt := Label.new()
	pt.text = "Live Demo (LIFO):"
	pt.set_position(Vector2(606, 152))
	pt.add_theme_font_size_override("font_size", 14)
	pt.add_theme_color_override("font_color", Color("#C77DFF"))
	add_child(pt)

	_anim_lbl = Label.new()
	_anim_lbl.set_position(Vector2(606, 390))
	_anim_lbl.add_theme_font_size_override("font_size", 13)
	_anim_lbl.add_theme_color_override("font_color", Color("#C77DFF"))
	add_child(_anim_lbl)

	var code_bg := ColorRect.new()
	code_bg.color = Color(0.04, 0.06, 0.04, 0.88)
	code_bg.set_position(Vector2(20, 440))
	code_bg.set_size(Vector2(1220, 110))
	add_child(code_bg)

	var code := Label.new()
	code.text = (
		"# Stack in GDScript:\n" +
		"stack.append(rune)           # PUSH — add to TOP    O(1)\n" +
		"stack.pop_back()             # POP  — remove TOP    O(1)   ← LIFO!\n" +
		"stack[stack.size()-1]        # PEEK — see top       O(1)"
	)
	code.set_position(Vector2(36, 452))
	code.add_theme_font_size_override("font_size", 13)
	code.add_theme_color_override("font_color", Color("#C77DFF"))
	add_child(code)

	var btn := Button.new()
	btn.text = "▶  Enter the Castle"
	btn.set_position(Vector2(540, 572))
	btn.set_size(Vector2(200, 52))
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(func(): emit_signal("start_requested"))
	add_child(btn)

	_timer = Timer.new()
	_timer.wait_time = 1.3
	_timer.timeout.connect(_demo_step)
	add_child(_timer)

func _run_demo() -> void:
	_demo_stack = []
	_step = 0
	_timer.start()

func _demo_step() -> void:
	_step += 1
	match _step:
		1: _demo_stack.append({"name":"Thunder","color":Color("#FFD93D"),"symbol":"⚡"}); _anim_lbl.text = "PUSH Thunder → goes to TOP"
		2: _demo_stack.append({"name":"Ice","color":Color("#4D96FF"),"symbol":"❄"}); _anim_lbl.text = "PUSH Ice → goes to TOP (Thunder buried!)"
		3: _demo_stack.append({"name":"Fire","color":Color("#FF6B6B"),"symbol":"🔥"}); _anim_lbl.text = "PUSH Fire → goes to TOP"
		4:
			if not _demo_stack.is_empty():
				var r: Dictionary = _demo_stack.pop_back()
				_anim_lbl.text = "POP → %s removed first (was TOP — LIFO!)" % r["name"]
		5:
			if not _demo_stack.is_empty():
				var r: Dictionary = _demo_stack.pop_back()
				_anim_lbl.text = "POP → %s next (exact reverse of push!)" % r["name"]
		6: _step = 0; _anim_lbl.text = "Repeating demo..."
	queue_redraw()

func _get_rules() -> String:
	var level: int = level_data.get("level", 1) as int
	match level:
		1: return "• Wizard PUSHES runes onto the stack one by one\n• You must POP them in REVERSE order (LIFO)\n• Click the TOP rune in the corridor or left panel\n• Wrong pop = spell backfires = -1 life"
		2: return "• Deeper stack — more runes to remember\n• The BOTTOM rune was pushed first — popped LAST\n• Watch depth labels: idx:0 = bottom, top = last\n• You cannot reach buried runes without popping top!"
		3: return "• 4 runes — the corridor fills with magic!\n• Stack reverses any sequence automatically\n• Push order: A B C D  →  Pop order: D C B A\n• Perfect round (no wrong pops) = +300 bonus!"
		4: return "• 5 runes — predict the stack state!\n• Before popping, visualize what's buried below\n• Press Q to open the stack panel and check\n• Each correct pop unlocks one door segment"
		5: return "• FULL stack — 6 runes!\n• One wrong push = OVERFLOW = -1 life\n• Stack max size is fixed — cannot exceed it\n• Complete all pops in correct order to escape!"
		_: return "• All stack concepts combined\n• PUSH, POP, PEEK, LIFO, overflow"

func _draw() -> void:
	# Demo stack — drawn as top-down runes in a corridor
	var lane_x: float = 920.0
	var top_y:  float = 200.0
	var gap:    float = 52.0
	var sz:     int   = _demo_stack.size()

	# Mini corridor
	draw_rect(Rect2(lane_x - 24, 160, 48, 250), Color("#28223a"))
	draw_line(Vector2(lane_x - 24, 160), Vector2(lane_x - 24, 410), Color("#3a2a4a"), 1.5)
	draw_line(Vector2(lane_x + 24, 160), Vector2(lane_x + 24, 410), Color("#3a2a4a"), 1.5)

	# Mini door
	draw_rect(Rect2(lane_x - 24, 152, 48, 16), Color("#2a2035"))
	draw_string(ThemeDB.fallback_font, Vector2(lane_x - 22, 164),
		"DOOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#C77DFF"))

	for i in sz:
		var is_top: bool = (i == sz - 1)
		var ty: float = top_y + (sz - 1 - i) * gap
		var col: Color = (_demo_stack[i]["color"] as Color)
		var alpha: float = 1.0 - (float(sz - 1 - i) / max(sz, 1)) * 0.5
		if is_top:
			draw_circle(Vector2(lane_x, ty), 22, col * Color(1,1,1,0.3))
		draw_circle(Vector2(lane_x, ty), 18, Color("#1a1025") * Color(1,1,1,alpha))
		draw_arc(Vector2(lane_x, ty), 16, 0, TAU, 24, col * Color(1,1,1,alpha), 2.5)
		draw_string(ThemeDB.fallback_font, Vector2(lane_x - 8, ty + 6),
			_demo_stack[i]["symbol"] as String, HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
			col * Color(1,1,1,alpha))
		if is_top:
			draw_string(ThemeDB.fallback_font, Vector2(lane_x + 24, ty + 4),
				_demo_stack[i]["name"] + " [TOP]", HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
				Color("#C77DFF"))
		else:
			draw_string(ThemeDB.fallback_font, Vector2(lane_x + 24, ty + 4),
				_demo_stack[i]["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
				Color("#665577"))
