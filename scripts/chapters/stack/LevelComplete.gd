extends Node2D

signal next_requested
signal retry_requested
signal menu_requested

func setup(cfg: Dictionary, score: int, win: bool, has_next: bool) -> void:
	_build(cfg, score, win, has_next)

func _build(cfg: Dictionary, score: int, win: bool, has_next: bool) -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0d0a14")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := ColorRect.new()
	panel.color = Color("#110e18")
	panel.set_position(Vector2(240, 80))
	panel.set_size(Vector2(800, 560))
	add_child(panel)

	var title := Label.new()
	title.text = "Level %d Clear!" % cfg.get("level",1) if win else "Spell Backfired!"
	title.set_position(Vector2(290, 110))
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color",
		Color("#C77DFF") if win else Color("#FF6B6B"))
	add_child(title)

	var score_lbl := Label.new()
	score_lbl.text = "Score: %d" % score
	score_lbl.set_position(Vector2(560, 170))
	score_lbl.add_theme_font_size_override("font_size", 22)
	score_lbl.add_theme_color_override("font_color", Color("#FFD93D"))
	add_child(score_lbl)

	var recap_bg := ColorRect.new()
	recap_bg.color = Color("#080510")
	recap_bg.set_position(Vector2(260, 215))
	recap_bg.set_size(Vector2(760, 160))
	add_child(recap_bg)

	var rl := Label.new()
	rl.text = "What you learned:"
	rl.set_position(Vector2(276, 227))
	rl.add_theme_font_size_override("font_size", 14)
	rl.add_theme_color_override("font_color", Color("#4D96FF"))
	add_child(rl)

	var recap := Label.new()
	recap.set_position(Vector2(276, 250))
	recap.set_custom_minimum_size(Vector2(720, 110))
	recap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recap.add_theme_font_size_override("font_size", 13)
	recap.add_theme_color_override("font_color", Color("#aaaacc"))
	recap.text = _get_recap(cfg.get("level",1) as int, win)
	add_child(recap)

	var code_bg := ColorRect.new()
	code_bg.color = Color("#040308")
	code_bg.set_position(Vector2(260, 385))
	code_bg.set_size(Vector2(760, 80))
	add_child(code_bg)

	var code := Label.new()
	code.set_position(Vector2(276, 397))
	code.add_theme_font_size_override("font_size", 12)
	code.add_theme_color_override("font_color", Color("#C77DFF"))
	code.text = _get_code(cfg.get("level",1) as int)
	add_child(code)

	if win and has_next:
		_btn("Next Floor ▶", Vector2(740, 490), Color("#C77DFF"),
			func(): emit_signal("next_requested"))
	elif win:
		_btn("🏆 Escaped!", Vector2(740, 490), Color("#FFD93D"),
			func(): emit_signal("menu_requested"))
	else:
		_btn("↺ Retry", Vector2(640, 490), Color("#FF6B6B"),
			func(): emit_signal("retry_requested"))

	_btn("Menu", Vector2(260, 490), Color("#888899"),
		func(): emit_signal("menu_requested"))

func _get_recap(level: int, win: bool) -> String:
	if not win:
		return "The spell backfired — remember LIFO: Last In, First Out.\nThe TOP rune must ALWAYS be popped first.\nYou cannot reach buried runes without clearing the top!"
	match level:
		1: return "LIFO: Last In, First Out. The last rune pushed is always the first popped.\nPush order: A B  →  Pop order: B A  (exact reverse!)\nstack.append() pushes to top — stack.pop_back() removes from top."
		2: return "Stack depth: buried runes are completely inaccessible until the top is cleared.\nThis is the core constraint of every stack — you cannot skip to a buried item.\nReal world: function call stack — can't return to caller before current call finishes."
		3: return "Stack reversal: a stack naturally reverses any sequence you push into it.\nThis property is used in undo systems, expression parsers, and backtracking.\nReal world: Ctrl+Z undo — last action pushed is first action undone."
		4: return "Stack state prediction: key skill for debugging recursive code.\nVisualize what's buried at each point — the call stack works identically.\nReal world: debugger call stack — each frame buried below the current one."
		5: return "Stack overflow: pushing beyond max capacity causes failure.\nIn real programs this crashes the process — stack memory is limited.\nReal world: infinite recursion = stack overflow error!"
		_: return "All stack concepts mastered: LIFO, depth, reversal, overflow!"

func _get_code(level: int) -> String:
	match level:
		1: return "stack.append(rune)      # PUSH\nstack.pop_back()        # POP — returns TOP (LIFO!)"
		2: return "stack[stack.size()-1]   # PEEK top without removing\nstack[0]               # PEEK bottom (buried deepest)"
		3: return "# Stack reverses sequences:\n# Push [A,B,C] → pop [C,B,A] (automatic reversal!)"
		4: return "# Predict stack state:\n# After push(A),push(B),push(C),pop() → stack = [A,B]"
		5: return "if stack.size() >= max_size:\n    return false  # overflow! cannot push"
		_: return "# All stack operations mastered!"

func _btn(text: String, pos: Vector2, col: Color, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.set_position(pos)
	b.set_size(Vector2(160, 46))
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", col)
	b.pressed.connect(cb)
	add_child(b)
