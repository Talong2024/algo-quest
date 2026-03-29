extends Node2D

# ═══════════════════════════════════════════════════
# Q_DSAPanel.gd
# Toggled by pressing Q or clicking the [Q] button.
# Draws a dark overlay showing the queue state,
# front/rear pointers, and GDScript code.
# ═══════════════════════════════════════════════════

var visible_panel: bool  = false
var _snapshot:     Array = []
var _max_size:     int   = 6

const PANEL_X: float = 60.0
const PANEL_Y: float = 80.0
const PANEL_W: float = 1160.0
const PANEL_H: float = 560.0
const SLOT_W:  float = 160.0
const SLOT_H:  float = 72.0
const SLOT_GAP:float = 10.0

func toggle() -> void:
	visible_panel = !visible_panel
	queue_redraw()

func update(snapshot: Array, max_sz: int) -> void:
	_snapshot = snapshot
	_max_size = max_sz
	if visible_panel:
		queue_redraw()

func _draw() -> void:
	if not visible_panel:
		return
	_draw_overlay()
	_draw_title()
	_draw_slots()
	_draw_pointers()
	_draw_code()
	_draw_close_hint()

func _draw_overlay() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.82))
	draw_rect(Rect2(PANEL_X, PANEL_Y, PANEL_W, PANEL_H), Color("#0d0d18"))
	draw_rect(Rect2(PANEL_X, PANEL_Y, PANEL_W, PANEL_H),
		Color("#2a2a3e"), false, 1.0)

func _draw_title() -> void:
	draw_string(ThemeDB.fallback_font,
		Vector2(PANEL_X + 20, PANEL_Y + 30),
		"QUEUE DATA STRUCTURE — Live State",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#4D96FF"))
	draw_string(ThemeDB.fallback_font,
		Vector2(PANEL_X + 20, PANEL_Y + 52),
		"Enqueue → rear    |    Front → Dequeue    |    FIFO: First In, First Out",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#555577"))

func _draw_slots() -> void:
	var start_x: float = PANEL_X + 20
	var sy:      float = PANEL_Y + 80

	for i in _max_size:
		var sx:     float = start_x + i * (SLOT_W + SLOT_GAP)
		var filled: bool  = i < _snapshot.size()
		var col:    Color = Color("#1a1a2e")

		if filled:
			col = (_snapshot[i]["color"] as Color).darkened(0.55)

		draw_rect(Rect2(sx, sy, SLOT_W, SLOT_H), col)
		draw_rect(Rect2(sx, sy, SLOT_W, SLOT_H), Color("#2a2a4e"), false, 1.0)

		# Index badge
		draw_rect(Rect2(sx + 4, sy + 4, 28, 18), Color("#1a1a3e"))
		draw_string(ThemeDB.fallback_font,
			Vector2(sx + 8, sy + 17),
			"[%d]" % i, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#555577"))

		if filled:
			var c: Dictionary = _snapshot[i]
			draw_circle(Vector2(sx + 22, sy + SLOT_H / 2.0 + 4), 12,
				c["color"] as Color)
			draw_string(ThemeDB.fallback_font,
				Vector2(sx + 40, sy + SLOT_H / 2.0 - 2),
				c["name"] as String,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e8e8f0"))
			draw_string(ThemeDB.fallback_font,
				Vector2(sx + 40, sy + SLOT_H / 2.0 + 16),
				"[%s]" % c["label"],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, c["color"] as Color)
		else:
			draw_string(ThemeDB.fallback_font,
				Vector2(sx + SLOT_W / 2.0 - 14, sy + SLOT_H / 2.0 + 5),
				"empty", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#2a2a4e"))

func _draw_pointers() -> void:
	var start_x: float = PANEL_X + 20
	var py:      float = PANEL_Y + 160

	if not _snapshot.is_empty():
		draw_string(ThemeDB.fallback_font,
			Vector2(start_x + 4, py),
			"▲  FRONT  (dequeue here)",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#6BCB77"))

		var ri:  int   = _snapshot.size() - 1
		var rx:  float = start_x + ri * (SLOT_W + SLOT_GAP)
		draw_string(ThemeDB.fallback_font,
			Vector2(rx + 4, py),
			"▲  REAR  (enqueue here)",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FF6B6B"))

	draw_string(ThemeDB.fallback_font,
		Vector2(PANEL_X + 20, py + 20),
		"size: %d / %d     front: %s     rear: %s" % [
			_snapshot.size(), _max_size,
			(_snapshot[0]["name"] as String) if not _snapshot.is_empty() else "null",
			(_snapshot[-1]["name"] as String) if not _snapshot.is_empty() else "null",
		],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#555577"))

func _draw_code() -> void:
	var cy: float = PANEL_Y + 220
	draw_rect(Rect2(PANEL_X + 20, cy, PANEL_W - 40, 140), Color("#0a0a14"))
	draw_string(ThemeDB.fallback_font,
		Vector2(PANEL_X + 36, cy + 22),
		"# GDScript — Queue operations:",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#555577"))
	draw_string(ThemeDB.fallback_font,
		Vector2(PANEL_X + 36, cy + 44),
		"queue.append(citizen)        # ENQUEUE — add citizen to REAR     O(1)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#6BCB77"))
	draw_string(ThemeDB.fallback_font,
		Vector2(PANEL_X + 36, cy + 64),
		"queue.pop_front()            # DEQUEUE — remove from FRONT       O(n)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#4D96FF"))
	draw_string(ThemeDB.fallback_font,
		Vector2(PANEL_X + 36, cy + 84),
		"queue[0]                     # PEEK    — see front without remove O(1)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#FFD93D"))
	draw_string(ThemeDB.fallback_font,
		Vector2(PANEL_X + 36, cy + 104),
		"queue.size() >= max_size     # OVERFLOW — queue is full, reject",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#FF6B6B"))

	# FIFO diagram
	var dx: float = PANEL_X + 36
	var dy: float = cy + 128
	draw_string(ThemeDB.fallback_font, Vector2(dx, dy),
		"FIFO order:  [FRONT]  Alice → Bob → Carlos → Diana  [REAR]   ← new arrivals join here",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#888899"))

func _draw_close_hint() -> void:
	draw_string(ThemeDB.fallback_font,
		Vector2(PANEL_X + PANEL_W - 180, PANEL_Y + 24),
		"Press Q to close",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#555577"))
