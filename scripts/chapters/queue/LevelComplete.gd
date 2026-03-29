extends Node2D

signal next_requested
signal retry_requested
signal menu_requested

func setup(cfg: Dictionary, score: int, win: bool, has_next: bool) -> void:
	_build(cfg, score, win, has_next)

func _build(cfg: Dictionary, score: int, win: bool, has_next: bool) -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0a0f0a")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := ColorRect.new()
	panel.color = Color("#0d150d")
	panel.set_position(Vector2(240, 80))
	panel.set_size(Vector2(800, 560))
	add_child(panel)

	var title := Label.new()
	title.text = "Level %d Clear!" % cfg.get("level",1) if win else "The Queue Collapsed!"
	title.set_position(Vector2(290, 110))
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color",
		Color("#6BCB77") if win else Color("#FF6B6B"))
	add_child(title)

	var score_lbl := Label.new()
	score_lbl.text = "Score: %d" % score
	score_lbl.set_position(Vector2(560, 170))
	score_lbl.add_theme_font_size_override("font_size", 22)
	score_lbl.add_theme_color_override("font_color", Color("#FFD93D"))
	add_child(score_lbl)

	var recap_bg := ColorRect.new()
	recap_bg.color = Color("#080f08")
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
	code_bg.color = Color("#040a04")
	code_bg.set_position(Vector2(260, 385))
	code_bg.set_size(Vector2(760, 80))
	add_child(code_bg)

	var code := Label.new()
	code.set_position(Vector2(276, 397))
	code.add_theme_font_size_override("font_size", 12)
	code.add_theme_color_override("font_color", Color("#6BCB77"))
	code.text = _get_code(cfg.get("level",1) as int)
	add_child(code)

	if win and has_next:
		_btn("Next Level ▶", Vector2(740, 490), Color("#6BCB77"),
			func(): emit_signal("next_requested"))
	elif win:
		_btn("🏆 Victory!", Vector2(740, 490), Color("#FFD93D"),
			func(): emit_signal("menu_requested"))
	else:
		_btn("↺ Retry", Vector2(640, 490), Color("#FF6B6B"),
			func(): emit_signal("retry_requested"))

	_btn("Menu", Vector2(260, 490), Color("#888899"),
		func(): emit_signal("menu_requested"))

func _get_recap(level: int, win: bool) -> String:
	if not win:
		return "The queue fell apart — remember: always serve the FRONT citizen first.\nThe front citizen walked to the gate first — FIFO means they go through first.\nWrong pick or overflow = life lost. Watch the green highlight!"
	match level:
		1: return "FIFO: First In, First Out. The citizen who arrived first is always served first.\nIn the top-down view, the citizen closest to the gate is always at the front.\nqueue.append() adds to rear — queue.pop_front() removes from front."
		2: return "Queue overflow: when the queue is full, new citizens can't join.\nThis maps to bounded buffers in real systems — network packets, print queues.\nServe faster or reduce citizens to prevent overflow."
		3: return "Patience/expiry: queue entries timeout if not served fast enough.\nThe patience bar under each citizen shows how long they'll wait.\nReal world: HTTP request timeouts, message queue TTL (time-to-live)."
		4: return "Priority Queue: not all entries are equal — VIPs have higher priority.\nReal world: OS process scheduling, hospital ER triage, A* pathfinding.\nRegular queue = FIFO. Priority queue = ordered by rank."
		5: return "Deque (Double-Ended Queue): enqueue and dequeue from BOTH ends.\nMore flexible — can act as both stack and queue.\nReal world: sliding window algorithms, browser history, task stealing."
		_: return "All queue concepts mastered: FIFO, overflow, patience, priority, deque!"

func _get_code(level: int) -> String:
	match level:
		1: return "queue.append(citizen)   # ENQUEUE\nqueue.pop_front()       # DEQUEUE — returns front citizen (FIFO!)"
		2: return "if queue.size() >= max_size:\n    return false  # overflow! citizen can't join"
		3: return "if wait_time >= patience:\n    queue.remove(citizen)  # expired — citizen left!"
		4: return "import heapq\nheapq.heappush(pq, (priority, citizen))  # priority queue"
		5: return "from collections import deque\nd.appendleft(x)  # enqueue front\nd.append(x)      # enqueue rear"
		_: return "# All queue operations combined!"

func _btn(text: String, pos: Vector2, col: Color, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.set_position(pos)
	b.set_size(Vector2(160, 46))
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", col)
	b.pressed.connect(cb)
	add_child(b)
