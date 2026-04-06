extends Node2D

signal start_requested

var level_data: Dictionary = {}

var _demo_queue: Array = []
var _step:       int   = 0
var _timer:      Timer
var _anim_lbl:   Label

func _ready() -> void:
	_build_ui()
	_run_demo()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.06, 0.04, 0.88)  # semi-transparent overlay
	bg.set_position(Vector2.ZERO)
	bg.set_size(Vector2(1280, 720))
	add_child(bg)

	var header := ColorRect.new()
	header.color = Color("#0d150d")
	header.set_position(Vector2.ZERO)
	header.set_size(Vector2(1280, 64))
	add_child(header)

	var tag := Label.new()
	tag.text = "DSA TUTORIAL"
	tag.set_position(Vector2(20, 8))
	tag.add_theme_font_size_override("font_size", 11)
	tag.add_theme_color_override("font_color", Color("#4D96FF"))
	add_child(tag)

	var title := Label.new()
	title.text = "Level %d — %s" % [level_data.get("level",1), level_data.get("title","The Gate Opens")]
	title.set_position(Vector2(20, 26))
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#e8e8f0"))
	add_child(title)

	var dsa_lbl := Label.new()
	dsa_lbl.text = "DSA Focus: " + level_data.get("dsainfo","FIFO queue")
	dsa_lbl.set_position(Vector2(700, 34))
	dsa_lbl.add_theme_font_size_override("font_size", 13)
	dsa_lbl.add_theme_color_override("font_color", Color("#4D96FF"))
	add_child(dsa_lbl)

	# Desc
	var desc := Label.new()
	desc.text = level_data.get("desc","")
	desc.set_position(Vector2(20, 78))
	desc.set_custom_minimum_size(Vector2(800, 40))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", Color("#aaaacc"))
	add_child(desc)

	# Rules box
	var rules_bg := ColorRect.new()
	rules_bg.color = Color("#0d150d")
	rules_bg.set_position(Vector2(20, 140))
	rules_bg.set_size(Vector2(540, 280))
	add_child(rules_bg)

	var rt := Label.new()
	rt.text = "Queue Rules:"
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

	# Q_World preview box
	var preview_bg := ColorRect.new()
	preview_bg.color = Color("#2d4a2d")
	preview_bg.set_position(Vector2(590, 140))
	preview_bg.set_size(Vector2(660, 280))
	add_child(preview_bg)

	var pt := Label.new()
	pt.text = "Live Demo (FIFO):"
	pt.set_position(Vector2(606, 152))
	pt.add_theme_font_size_override("font_size", 14)
	pt.add_theme_color_override("font_color", Color("#6BCB77"))
	add_child(pt)

	_anim_lbl = Label.new()
	_anim_lbl.set_position(Vector2(606, 390))
	_anim_lbl.add_theme_font_size_override("font_size", 13)
	_anim_lbl.add_theme_color_override("font_color", Color("#6BCB77"))
	add_child(_anim_lbl)

	# Code box
	var code_bg := ColorRect.new()
	code_bg.color = Color("#080f08")
	code_bg.set_position(Vector2(20, 440))
	code_bg.set_size(Vector2(1220, 120))
	add_child(code_bg)

	var code := Label.new()
	code.text = (
		"# Queue in GDScript:\n" +
		"queue.append(citizen)      # ENQUEUE — add to rear    O(1)\n" +
		"queue.pop_front()          # DEQUEUE — remove front   O(n)\n" +
		"queue[0]                   # PEEK    — see front      O(1)"
	)
	code.set_position(Vector2(36, 452))
	code.add_theme_font_size_override("font_size", 13)
	code.add_theme_color_override("font_color", Color("#6BCB77"))
	add_child(code)

	# Start button
	var btn := Button.new()
	btn.text = "▶  Enter Kingdom"
	btn.set_position(Vector2(540, 594))
	btn.set_size(Vector2(200, 52))
	btn.add_theme_font_size_override("font_size", 18)
	btn.pressed.connect(func(): emit_signal("start_requested"))
	add_child(btn)

	_timer = Timer.new()
	_timer.wait_time = 1.4
	_timer.timeout.connect(_demo_step)
	add_child(_timer)

func _run_demo() -> void:
	_demo_queue = []
	_step = 0
	_timer.start()

func _demo_step() -> void:
	_step += 1
	match _step:
		1: _demo_queue.append({"name":"Alice","color":Color("#4D96FF")}); _anim_lbl.text = "ENQUEUE Alice → joins rear of line"
		2: _demo_queue.append({"name":"Bob","color":Color("#6BCB77")}); _anim_lbl.text = "ENQUEUE Bob → joins behind Alice"
		3: _demo_queue.append({"name":"Carlos","color":Color("#FFD93D")}); _anim_lbl.text = "ENQUEUE Carlos → joins at rear"
		4:
			if not _demo_queue.is_empty():
				var s: Dictionary = _demo_queue.pop_front()
				_anim_lbl.text = "DEQUEUE → %s served first (was at front!)" % s["name"]
		5:
			if not _demo_queue.is_empty():
				var s: Dictionary = _demo_queue.pop_front()
				_anim_lbl.text = "DEQUEUE → %s served next — FIFO!" % s["name"]
		6: _step = 0; _anim_lbl.text = "Repeating demo..."
	queue_redraw()

func _get_rules() -> String:
	var level: int = level_data.get("level", 1) as int
	match level:
		1: return "• Citizens walk up and queue at the gate\n• The FRONT citizen (closest to gate) must be served first\n• Click FRONT citizen or use left panel button\n• Wrong citizen = -1 life  |  Overflow = -1 life"
		2: return "• Queue has max capacity — watch it fill!\n• If full when new citizen arrives → OVERFLOW → -1 life\n• Serve quickly to free up space"
		3: return "• Each citizen has a patience bar (under their feet)\n• Bar drains while they wait — reaches zero → they leave\n• Elderly have less patience — prioritize them!"
		4: return "• VIP citizens (gold) have higher priority\n• In a real priority queue they'd jump ahead\n• Watch how different citizen types change strategy"
		5: return "• Two queues — serve from front and rear!\n• This is a DEQUE — double-ended queue\n• Manage both gates to prevent overflow"
		_: return "• All queue concepts combined\n• FIFO, overflow, patience, priority all active"

func _draw() -> void:
	# Draw demo queue as top-down citizens walking in a line
	var lane_x: float = 920.0
	var start_y: float = 380.0
	var gap: float = 60.0
	var gate_y: float = 170.0

	# Gate stub
	draw_rect(Rect2(lane_x - 30, gate_y, 60, 20), Color("#5a5040"))
	draw_string(ThemeDB.fallback_font, Vector2(lane_x - 24, gate_y + 14),
		"GATE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#aa8855"))

	# Path
	draw_rect(Rect2(lane_x - 20, gate_y + 20, 40, 260), Color("#3e352c"))

	# Citizens
	for i in _demo_queue.size():
		var cy: float = start_y - i * gap
		var col: Color = (_demo_queue[i]["color"] as Color).darkened(0.3)
		draw_circle(Vector2(lane_x, cy), 18, col)
		draw_circle(Vector2(lane_x, cy - 5), 7, col.lightened(0.2))
		if i == 0:
			draw_arc(Vector2(lane_x, cy), 22, 0, TAU, 24, Color("#6BCB77"), 2.0)
			draw_string(ThemeDB.fallback_font, Vector2(lane_x + 26, cy + 5),
				_demo_queue[i]["name"] as String + " [FRONT]",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#6BCB77"))
		else:
			draw_string(ThemeDB.fallback_font, Vector2(lane_x + 26, cy + 5),
				_demo_queue[i]["name"] as String,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#aaaacc"))
