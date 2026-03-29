extends Node2D

signal toggled(is_visible: bool)

var visible_panel: bool  = false
var _snapshot:     Array = []
var _max_size:     int   = 6
var _phase:        String = "push"

const PX: float = 60.0
const PY: float = 80.0
const PW: float = 1160.0
const PH: float = 560.0
const SW: float = 150.0
const SH: float = 68.0
const SG: float = 8.0

func toggle() -> void:
	visible_panel = !visible_panel
	emit_signal("toggled", visible_panel)
	queue_redraw()

func update(snapshot: Array, max_sz: int, phase: String = "push") -> void:
	_snapshot = snapshot
	_max_size = max_sz
	_phase    = phase
	if visible_panel: queue_redraw()

func _draw() -> void:
	if not visible_panel: return
	_draw_bg()
	_draw_title()
	_draw_slots()
	_draw_pointers()
	_draw_code()
	_draw_hint()

func _draw_bg() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0, 0, 0, 0.85))
	draw_rect(Rect2(PX, PY, PW, PH), Color("#0d0a14"))
	draw_rect(Rect2(PX, PY, PW, PH), Color("#3a2a4a"), false, 1.0)

func _draw_title() -> void:
	var phase_col: Color = Color("#FFD93D") if _phase == "push" else Color("#C77DFF")
	var phase_str: String = "PUSH PHASE — watch runes stack up" if _phase == "push" else "POP PHASE — click TOP rune (LIFO!)"
	draw_string(ThemeDB.fallback_font,
		Vector2(PX + 20, PY + 30),
		"STACK DATA STRUCTURE  —  " + phase_str,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, phase_col)
	draw_string(ThemeDB.fallback_font,
		Vector2(PX + 20, PY + 52),
		"LIFO: Last In, First Out  |  Only TOP is accessible  |  Buried = unreachable",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#555577"))

func _draw_slots() -> void:
	# Draw stack bottom → top, left to right
	var ox: float = PX + 20
	var sy: float = PY + 80

	for i in _max_size:
		var sx:     float = ox + i * (SW + SG)
		var filled: bool  = i < _snapshot.size()
		var is_top: bool  = i == _snapshot.size() - 1 and filled

		var bg_col: Color = Color("#1a1025") if not filled else \
			(_snapshot[i]["color"] as Color).darkened(0.6)
		if is_top:
			bg_col = (_snapshot[i]["color"] as Color).darkened(0.35)

		draw_rect(Rect2(sx, sy, SW, SH), bg_col)
		draw_rect(Rect2(sx, sy, SW, SH),
			Color("#C77DFF") if is_top else Color("#2a1a3a"), false, 1.0)

		# Index
		draw_rect(Rect2(sx + 4, sy + 4, 30, 16), Color("#1a1025"))
		draw_string(ThemeDB.fallback_font,
			Vector2(sx + 8, sy + 16),
			"[%d]" % i, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#555577"))

		if filled:
			var r: Dictionary = _snapshot[i]
			draw_string(ThemeDB.fallback_font,
				Vector2(sx + 10, sy + SH/2.0 - 2),
				r["symbol"] as String,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, r["color"] as Color)
			draw_string(ThemeDB.fallback_font,
				Vector2(sx + 36, sy + SH/2.0 - 4),
				r["name"] as String,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e8e8f0"))
			if is_top:
				draw_string(ThemeDB.fallback_font,
					Vector2(sx + 36, sy + SH/2.0 + 14),
					"← POP here",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#C77DFF"))
		else:
			draw_string(ThemeDB.fallback_font,
				Vector2(sx + SW/2.0 - 14, sy + SH/2.0 + 5),
				"empty", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#2a1a3a"))

func _draw_pointers() -> void:
	var ox: float = PX + 20
	var py: float = PY + 158

	# BOTTOM label under slot 0
	draw_string(ThemeDB.fallback_font,
		Vector2(ox + 4, py),
		"▲ BOTTOM (pushed first)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#4D96FF"))

	# TOP label under last filled slot
	if not _snapshot.is_empty():
		var ti: int   = _snapshot.size() - 1
		var tx: float = ox + ti * (SW + SG)
		draw_string(ThemeDB.fallback_font,
			Vector2(tx + 4, py),
			"▲ TOP (pop here)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#C77DFF"))

	draw_string(ThemeDB.fallback_font,
		Vector2(ox, py + 20),
		"size: %d / %d     top: %s     bottom: %s" % [
			_snapshot.size(), _max_size,
			(_snapshot[-1]["name"] as String) if not _snapshot.is_empty() else "null",
			(_snapshot[0]["name"]  as String) if not _snapshot.is_empty() else "null",
		],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#555577"))

func _draw_code() -> void:
	var cy: float = PY + 210
	draw_rect(Rect2(PX + 20, cy, PW - 40, 150), Color("#080510"))
	draw_string(ThemeDB.fallback_font,
		Vector2(PX + 36, cy + 22),
		"# GDScript — Stack operations (LIFO):",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#555577"))
	draw_string(ThemeDB.fallback_font,
		Vector2(PX + 36, cy + 44),
		"stack.append(rune)           # PUSH — add to TOP               O(1)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#FFD93D"))
	draw_string(ThemeDB.fallback_font,
		Vector2(PX + 36, cy + 64),
		"stack.pop_back()             # POP  — remove from TOP          O(1)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#C77DFF"))
	draw_string(ThemeDB.fallback_font,
		Vector2(PX + 36, cy + 84),
		"stack[stack.size()-1]        # PEEK — see top without remove   O(1)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#4D96FF"))
	draw_string(ThemeDB.fallback_font,
		Vector2(PX + 36, cy + 104),
		"stack.size() >= max_size     # OVERFLOW — stack is full, reject",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#FF6B6B"))
	draw_string(ThemeDB.fallback_font,
		Vector2(PX + 36, cy + 126),
		"LIFO order:  PUSH Thunder→Ice→Fire   |   POP Fire→Ice→Thunder  (exact reverse!)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#888899"))

func _draw_hint() -> void:
	draw_string(ThemeDB.fallback_font,
		Vector2(PX + PW - 180, PY + 24),
		"Press Q to close",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#555577"))
