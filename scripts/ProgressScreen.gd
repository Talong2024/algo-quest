extends Node2D
# ═══════════════════════════════════════════════════
# ProgressScreen.gd
# Full progress dashboard — shows everything:
#   • Overall stats bar
#   • Per-chapter cards (score, time, perfects, mastery)
#   • DSA mastery badges
#   • Achievement wall
#   • Login streak
# ═══════════════════════════════════════════════════

const CHAPTER_COLORS: Array = [
	Color("#6BCB77"), Color("#C77DFF"), Color("#FFD93D"),
	Color("#6BCB77"), Color("#4D96FF"),
]
const CHAPTER_NAMES: Array = [
	"", "Kingdom Queue", "Castle of Echoes",
	"Chain Train", "Oracle's Forest", "Kingdom Roads"
]
const DSA_LABELS: Dictionary = {
	"queue":       "Queue",
	"stack":       "Stack",
	"linked_list": "Linked List",
	"tree":        "BST/AVL/Heap",
	"graph":       "Graph",
}


func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0a0a0f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_build_header()
	_build_scrollable_content()

func _build_header() -> void:
	var hdr := ColorRect.new()
	hdr.color = Color("#13131f")
	hdr.set_position(Vector2.ZERO)
	hdr.set_size(Vector2(1280, 56))
	add_child(hdr)

	_lbl("Progress & Achievements", Vector2(20, 16), 20, Color("#e8e8f0"))

	var stats: Dictionary = ProgressTracker.get_all_stats()
	var streak: int = stats.get("login_streak", 0) as int

	_lbl("🔥 Day streak: %d" % streak, Vector2(900, 16), 14, Color("#FF9F43"))
	_lbl("Total score: %d" % (stats.get("total_score",0) as int),
		Vector2(900, 34), 12, Color("#FFD93D"))

	var back := Button.new()
	back.text = "← World Map"
	back.set_position(Vector2(1100, 12))
	back.set_size(Vector2(160, 34))
	back.add_theme_font_size_override("font_size", 13)
	back.pressed.connect(func(): GameRouter.go_world_map())
	add_child(back)

func _build_scrollable_content() -> void:
	var container := Control.new()
	container.set_position(Vector2(0, 64))
	container.set_size(Vector2(1280, 656))
	add_child(container)

	var scroll := ScrollContainer.new()
	scroll.set_position(Vector2.ZERO)
	scroll.set_size(Vector2(1280, 656))
	container.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.set_custom_minimum_size(Vector2(1260, 0))
	scroll.add_child(vbox)

	_build_stats_bar(vbox)
	_build_chapter_section(vbox)
	_build_dsa_mastery(vbox)
	_build_achievements(vbox)

# ─── Stats Bar ────────────────────────────────────

func _build_stats_bar(parent: Control) -> void:
	var stats: Dictionary = ProgressTracker.get_all_stats()
	var row := HBoxContainer.new()
	row.set_custom_minimum_size(Vector2(1260, 80))
	parent.add_child(row)

	var cards: Array = [
		["Total Score",       str(stats.get("total_score",0)),         Color("#FFD93D")],
		["Levels Complete",   str(stats.get("levels_complete",0)),      Color("#6BCB77")],
		["Perfect Clears",    str(stats.get("perfect_clears",0)),       Color("#C77DFF")],
		["Chapters Done",     "%d/5" % (stats.get("chapters_complete",0) as int), Color("#4D96FF")],
		["Play Time",         _fmt_time(stats.get("total_playtime_sec",0) as float), Color("#FF9F43")],
	]
	for card in cards:
		var bg := ColorRect.new()
		bg.color = Color("#13131f")
		bg.set_custom_minimum_size(Vector2(0, 72))
		bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(bg)
		_lbl(card[0] as String, Vector2(12, 8),  11, Color("#555577"), bg)
		_lbl(card[1] as String, Vector2(12, 32), 22, card[2] as Color, bg)

# ─── Per-Chapter Cards ────────────────────────────

func _build_chapter_section(parent: Control) -> void:
	_lbl("Chapters", Vector2(20, 8), 14, Color("#888899"), parent)

	for ch in range(1, 6):
		_build_chapter_card(ch, parent)

func _build_chapter_card(ch: int, parent: Control) -> void:
	var ch_data: Dictionary = ProgressTracker.get_chapter_data(ch)
	var col:     Color      = CHAPTER_COLORS[ch - 1]
	var unlocked: bool      = ch_data.get("unlocked", ch==1) as bool
	var complete: bool      = ch_data.get("complete", false) as bool
	var mastered: bool      = ProgressTracker.get_dsa_mastery(
		ProgressTracker.CHAPTER_DSA.get(ch,"")).get("mastered",false) as bool

	var card := ColorRect.new()
	card.color = Color("#13131f")
	card.set_custom_minimum_size(Vector2(1260, 90))
	parent.add_child(card)

	# Color bar on left
	var bar := ColorRect.new()
	bar.color = col if unlocked else Color("#2a2a3a")
	bar.set_position(Vector2(0,0))
	bar.set_size(Vector2(5, 90))
	card.add_child(bar)

	# Chapter name
	var status: String = "🔒 Locked" if not unlocked else \
		("✓ Complete" if complete else "In Progress")
	_lbl("%s — %s" % [CHAPTER_NAMES[ch], status],
		Vector2(20, 8), 16, col if unlocked else Color("#333355"), card)

	if not unlocked:
		_lbl("Complete Chapter %d to unlock" % (ch-1),
			Vector2(20, 34), 12, Color("#333355"), card)
		return

	# Score bar
	var best: int  = ch_data.get("best_score", 0) as int
	var max_s: int = 5000
	var pct:  float = min(float(best) / float(max_s), 1.0)
	_lbl("Best: %d pts" % best, Vector2(20, 34), 12, Color("#FFD93D"), card)
	var track := ColorRect.new()
	track.color = Color("#1a1a2a")
	track.set_position(Vector2(20, 54))
	track.set_size(Vector2(400, 8))
	card.add_child(track)
	var fill := ColorRect.new()
	fill.color = col
	fill.set_position(Vector2(20, 54))
	fill.set_size(Vector2(400 * pct, 8))
	card.add_child(fill)

	# Per-level dots
	var lv_count: int = ProgressTracker.LEVELS_PER_CHAPTER.get(ch, 5) as int
	for i in range(1, lv_count + 1):
		var lv_data: Dictionary = ProgressTracker.get_level_data(ch, i)
		var lv_done:    bool = lv_data.get("complete", false) as bool
		var lv_perfect: bool = lv_data.get("perfect", false) as bool
		var dx: float = 450.0 + (i-1) * 56.0
		var dot := ColorRect.new()
		dot.color = Color("#FFD93D") if lv_perfect else \
			(col if lv_done else Color("#1a1a2a"))
		dot.set_position(Vector2(dx, 24))
		dot.set_size(Vector2(44, 44))
		card.add_child(dot)
		_lbl("L%d" % i, Vector2(dx + 4, 30), 10,
			Color("#0a0a0f") if (lv_done or lv_perfect) else Color("#333355"), card)
		if lv_perfect:
			_lbl("★", Vector2(dx + 14, 44), 11, Color("#0a0a0f"), card)

	# Mastery badge
	if mastered:
		var badge := ColorRect.new()
		badge.color = col.darkened(0.4)
		badge.set_position(Vector2(1140, 20))
		badge.set_size(Vector2(110, 50))
		card.add_child(badge)
		_lbl("DSA MASTERED", Vector2(1148, 28), 10, col, card)
		_lbl("★", Vector2(1175, 44), 14, col, card)

	# Time
	var t: int = ch_data.get("total_time_sec", 0) as int
	if t > 0:
		_lbl(_fmt_time(t), Vector2(20, 68), 11, Color("#555577"), card)

	# Attempts
	var att: int = ch_data.get("attempts", 0) as int
	if att > 0:
		_lbl("%d attempt%s" % [att, "s" if att>1 else ""], Vector2(200, 68), 11, Color("#555577"), card)

# ─── DSA Mastery ──────────────────────────────────

func _build_dsa_mastery(parent: Control) -> void:
	_lbl("DSA Mastery", Vector2(20, 8), 14, Color("#888899"), parent)

	var row := HBoxContainer.new()
	row.set_custom_minimum_size(Vector2(1260, 100))
	parent.add_child(row)

	var topics: Array = ["queue","stack","linked_list","tree","graph"]
	var colors: Array = CHAPTER_COLORS

	for i in topics.size():
		var topic: String = topics[i]
		var m_data: Dictionary = ProgressTracker.get_dsa_mastery(topic)
		var mastered: bool = m_data.get("mastered", false) as bool
		var col: Color = colors[i]

		var card := ColorRect.new()
		card.color = col.darkened(0.6) if mastered else Color("#13131f")
		card.set_custom_minimum_size(Vector2(0, 92))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(card)

		_lbl(DSA_LABELS.get(topic,"?") as String, Vector2(12, 10), 14,
			col if mastered else Color("#333355"), card)
		_lbl("★ MASTERED" if mastered else "Not yet mastered",
			Vector2(12, 34), 11,
			Color("#FFD93D") if mastered else Color("#333355"), card)

		var best: int = m_data.get("best_score", 0) as int
		if best > 0:
			_lbl("Best: %d" % best, Vector2(12, 56), 10, Color("#555577"), card)

		var avg_wrong: int = m_data.get("avg_wrong", 0) as int
		if avg_wrong == 0 and mastered:
			_lbl("Flawless!", Vector2(12, 72), 10, col, card)

# ─── Achievement Wall ─────────────────────────────

func _build_achievements(parent: Control) -> void:
	_lbl("Achievements", Vector2(20, 8), 14, Color("#888899"), parent)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.set_custom_minimum_size(Vector2(1260, 0))
	parent.add_child(grid)

	var achieved: Dictionary = ProgressTracker.get_achievements()

	for id in ProgressTracker.ACHIEVEMENTS:
		var info:   Dictionary = ProgressTracker.ACHIEVEMENTS[id] as Dictionary
		var done:   bool       = (achieved.get(id, {}) as Dictionary).get("unlocked",false) as bool
		var ts:     int        = (achieved.get(id, {}) as Dictionary).get("unlocked_at",0) as int

		var card := ColorRect.new()
		card.color = Color("#1a1a2e") if done else Color("#0d0d18")
		card.set_custom_minimum_size(Vector2(0, 72))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)

		_lbl(info["name"] as String, Vector2(12, 8), 13,
			Color("#FFD93D") if done else Color("#333355"), card)
		_lbl(info["desc"] as String, Vector2(12, 30), 10,
			Color("#aaaacc") if done else Color("#2a2a3a"), card)

		if done and ts > 0:
			var dt: Dictionary = Time.get_datetime_dict_from_unix_time(ts)
			_lbl("%04d-%02d-%02d" % [dt["year"],dt["month"],dt["day"]],
				Vector2(12, 52), 9, Color("#444466"), card)
		elif not done:
			_lbl("🔒 locked", Vector2(12, 52), 9, Color("#222233"), card)

# ─── Helpers ──────────────────────────────────────

func _fmt_time(sec: float) -> String:
	var s: int = int(sec)
	var h: int = s / 3600
	var m: int = (s % 3600) / 60
	var r: int = s % 60
	if h > 0: return "%dh %dm" % [h, m]
	if m > 0: return "%dm %ds" % [m, r]
	return "%ds" % r

func _lbl(text: String, pos: Vector2, sz: int, col: Color,
		parent: Node = self) -> Label:
	var l := Label.new()
	l.text = text
	l.set_position(pos)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l
