extends Node2D
# ═══════════════════════════════════════════════════
# LevelComplete.gd  —  SHARED
# Rich end-of-chapter screen with full breakdown.
# ═══════════════════════════════════════════════════

const CHAPTER_COLORS: Array = [
	Color.TRANSPARENT,
	Color("#6BCB77"), Color("#C77DFF"), Color("#FFD93D"),
	Color("#6BCB77"), Color("#4D96FF"),
]
const DSA_RECAP: Dictionary = {
	1: "Queue: FIFO — First In, First Out. Dequeue from the front. O(1) enqueue and dequeue.",
	2: "Stack: LIFO — Last In, First Out. Pop from the top. Call stack, undo, expression parsing.",
	3: "Linked List: O(1) insert/delete at position. O(n) traverse. No random access — follow next pointers.",
	4: "BST: left < node < right. O(log n) search on balanced tree. AVL self-balances — |bf| ≤ 1.",
	5: "Graph: BFS = queue/levels. DFS = stack/deep. Dijkstra = min-dist greedy. Topo = in-degree 0 first.",
}

var _chapter:  int  = 1
var _score:    int  = 0
var _wrong:    int  = 0
var _perfect:  bool = false
var _has_next: bool = true

func receive_params(params: Dictionary) -> void:
	_chapter  = params.get("chapter",  1)    as int
	_score    = params.get("score",    0)     as int
	_wrong    = params.get("wrong",    0)     as int
	_perfect  = params.get("perfect",  false) as bool
	_has_next = params.get("has_next", true)  as bool

	# Record to ProgressTracker
	var result: Dictionary = ProgressTracker.complete_level(
		_chapter, 1, _score, _wrong)

	AudioManager.play_sfx("win" if _wrong == 0 else "chapter")
	_build_ui()

func _build_ui() -> void:
	var col: Color = CHAPTER_COLORS[_chapter]

	var bg := ColorRect.new()
	bg.color = Color("#0a0a0f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := ColorRect.new()
	panel.color = Color("#13131f")
	panel.set_position(Vector2(200, 60))
	panel.set_size(Vector2(880, 600))
	add_child(panel)

	# Color accent top bar
	var top := ColorRect.new()
	top.color = col
	top.set_position(Vector2(200, 60))
	top.set_size(Vector2(880, 6))
	add_child(top)

	# Title
	_lbl("Chapter %d Complete!" % _chapter, Vector2(240, 82), 32, col)
	_lbl(ProgressTracker.CHAPTER_NAMES.get(_chapter,""),
		Vector2(240, 124), 16, Color("#888899"))

	# Score + perfect
	_lbl("%d pts" % _score, Vector2(820, 82), 32, Color("#FFD93D"))
	if _perfect:
		_lbl("⭐ Perfect clear!", Vector2(820, 124), 14, Color("#FFD93D"))
	else:
		_lbl("%d wrong picks" % _wrong, Vector2(820, 124), 13, Color("#FF6B6B"))

	# Best score badge
	var best: int = ProgressTracker.get_chapter_best_score(_chapter)
	_lbl("Personal best: %d" % best, Vector2(240, 154), 12, Color("#555577"))

	# Progress comparison bar
	_lbl("Chapter score", Vector2(240, 185), 11, Color("#444466"))
	var pct: float = min(float(_score) / 5000.0, 1.0)
	var track := ColorRect.new()
	track.color = Color("#1a1a2a"); track.set_position(Vector2(240,200)); track.set_size(Vector2(600,10))
	add_child(track)
	var fill := ColorRect.new()
	fill.color = col; fill.set_position(Vector2(240,200)); fill.set_size(Vector2(600*pct,10))
	add_child(fill)
	_lbl("%d%%" % int(pct*100), Vector2(848, 196), 11, col)

	# DSA recap box
	var rb := ColorRect.new()
	rb.color = Color("#0d0d18"); rb.set_position(Vector2(220, 228)); rb.set_size(Vector2(840, 80))
	add_child(rb)
	_lbl("DSA you mastered:", Vector2(240, 238), 11, Color("#4D96FF"))
	var recap := Label.new()
	recap.text = DSA_RECAP.get(_chapter, "") as String
	recap.set_position(Vector2(240, 258))
	recap.set_size(Vector2(800, 44))
	recap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recap.add_theme_font_size_override("font_size", 13)
	recap.add_theme_color_override("font_color", Color("#aaaacc"))
	add_child(recap)

	# Level breakdown dots
	_lbl("Level breakdown:", Vector2(240, 326), 11, Color("#444466"))
	var lv_count: int = ProgressTracker.LEVELS_PER_CHAPTER.get(_chapter, 5) as int
	for i in range(1, lv_count + 1):
		var lv: Dictionary = ProgressTracker.get_level_data(_chapter, i)
		var done:    bool  = lv.get("complete",false) as bool
		var perfect: bool  = lv.get("perfect",false) as bool
		var lv_score: int  = lv.get("best_score",0) as int
		var lv_wrong: int  = lv.get("wrong_picks",0) as int
		var lv_time:  int  = lv.get("best_time",0) as int
		var dx: float = 240.0 + (i-1) * 130.0

		var dot := ColorRect.new()
		dot.color = Color("#FFD93D") if perfect else (col if done else Color("#1a1a2a"))
		dot.set_position(Vector2(dx, 344)); dot.set_size(Vector2(116, 60))
		add_child(dot)
		var text_col: Color = Color("#0a0a0f") if (done or perfect) else Color("#333355")
		_lbl("Level %d" % i, Vector2(dx+6, 348), 11, text_col)
		_lbl("%d pts" % lv_score, Vector2(dx+6, 364), 11, text_col)
		_lbl("%d wrong" % lv_wrong, Vector2(dx+6, 378), 10, text_col)
		if lv_time > 0:
			_lbl("%ds" % lv_time, Vector2(dx+70, 378), 10, text_col)

	# Mastery check
	var m_data: Dictionary = ProgressTracker.get_dsa_mastery(
		ProgressTracker.CHAPTER_DSA.get(_chapter,""))
	if m_data.get("mastered",false) as bool:
		var mb := ColorRect.new()
		mb.color = col.darkened(0.5); mb.set_position(Vector2(220, 420)); mb.set_size(Vector2(840,44))
		add_child(mb)
		_lbl("★  DSA MASTERED — you met all mastery conditions for this topic!",
			Vector2(240, 433), 14, col)

	# Global stats
	var stats: Dictionary = ProgressTracker.get_all_stats()
	_lbl("Total score: %d  |  Perfect clears: %d  |  Chapters done: %d/5" % [
		stats.get("total_score",0) as int,
		stats.get("perfect_clears",0) as int,
		stats.get("chapters_complete",0) as int,
	], Vector2(240, 476), 12, Color("#444466"))

	# Buttons
	if _has_next:
		_btn("Continue →", Vector2(720, 520), Vector2(280, 50), col,
			func(): GameRouter.proceed_after_chapter(_chapter))
	else:
		_btn("★ You Won!", Vector2(720, 520), Vector2(280, 50), Color("#FFD93D"),
			func(): GameRouter.go_cutscene("ending", func(): GameRouter.go_credits()))

	_btn("Progress", Vector2(220, 520), Vector2(160, 50), Color("#4D96FF"),
		func(): GameRouter.go_progress_screen())
	_btn("Retry", Vector2(392, 520), Vector2(160, 50), Color("#555577"),
		func(): GameRouter.start_chapter(_chapter))
	_btn("World Map", Vector2(564, 520), Vector2(148, 50), Color("#444466"),
		func(): GameRouter.go_world_map())

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new(); l.text=text; l.set_position(pos)
	l.add_theme_font_size_override("font_size",sz)
	l.add_theme_color_override("font_color",col); add_child(l); return l

func _btn(text: String, pos: Vector2, sz: Vector2, col: Color, cb: Callable) -> void:
	var b := Button.new(); b.text=text; b.set_position(pos); b.set_size(sz)
	b.add_theme_font_size_override("font_size",15)
	b.add_theme_color_override("font_color",col)
	b.pressed.connect(cb); add_child(b)
