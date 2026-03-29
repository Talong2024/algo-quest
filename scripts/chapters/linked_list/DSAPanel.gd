extends Node2D

var visible_panel: bool   = false
var _snapshot:     Array  = []
var _operation:    String = "traverse"
var _is_doubly:    bool   = false

const PX: float = 60.0
const PY: float = 70.0
const PW: float = 1160.0
const PH: float = 570.0

func toggle() -> void:
	visible_panel = !visible_panel
	queue_redraw()

func update(snapshot: Array, operation: String, doubly: bool) -> void:
	_snapshot  = snapshot
	_operation = operation
	_is_doubly = doubly
	if visible_panel: queue_redraw()

func _draw() -> void:
	if not visible_panel: return
	_draw_bg()
	_draw_title()
	_draw_nodes()
	_draw_code()
	_draw_hint()

func _draw_bg() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0,0,0,0.86))
	draw_rect(Rect2(PX, PY, PW, PH), Color("#0a0e04"))
	draw_rect(Rect2(PX, PY, PW, PH), Color("#4a5020"), false, 1.0)

func _draw_title() -> void:
	var op_labels: Dictionary = {
		"traverse": "TRAVERSE — follow next pointers head→tail",
		"insert":   "INSERT — add node, re-link neighbours",
		"delete":   "DELETE — remove node, re-link around it",
		"reverse":  "REVERSE — flip all next pointers",
	}
	var op_cols: Dictionary = {
		"traverse": Color("#6BCB77"),
		"insert":   Color("#4D96FF"),
		"delete":   Color("#FF6B6B"),
		"reverse":  Color("#C77DFF"),
	}
	var list_type: String = "DOUBLY LINKED LIST" if _is_doubly else "SINGLY LINKED LIST"
	draw_string(ThemeDB.fallback_font,
		Vector2(PX+20, PY+28),
		"%s  —  %s" % [list_type, op_labels.get(_operation,"")],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 17,
		op_cols.get(_operation, Color("#6BCB77")))
	draw_string(ThemeDB.fallback_font,
		Vector2(PX+20, PY+50),
		"Each carriage = node  |  Coupler = next pointer  |  HEAD = first  |  TAIL.next = null",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#555530"))

func _draw_nodes() -> void:
	if _snapshot.is_empty(): return

	var NW:  float = 140.0
	var NH:  float = 72.0
	var GAP: float = 60.0
	var oy:  float = PY + 80.0
	var ox:  float = PX + 30.0

	for i in _snapshot.size():
		var node: Dictionary = _snapshot[i]
		var nx:   float      = ox + i * (NW + GAP)
		var col:  Color      = node.get("color", Color("#6BCB77")) as Color
		var is_h: bool       = i == 0
		var is_t: bool       = i == _snapshot.size() - 1

		# Node box
		draw_rect(Rect2(nx, oy, NW, NH), col.darkened(0.55))
		draw_rect(Rect2(nx, oy, NW, NH),
			Color("#FFD93D") if is_h else (Color("#C77DFF") if is_t else col),
			false, 1.5)

		# HEAD / TAIL labels
		if is_h:
			draw_rect(Rect2(nx, oy-18, 48, 16), Color("#FFD93D"))
			draw_string(ThemeDB.fallback_font, Vector2(nx+3, oy-5),
				"HEAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#1a1000"))
		if is_t:
			draw_rect(Rect2(nx+NW-44, oy-18, 44, 16), Color("#C77DFF"))
			draw_string(ThemeDB.fallback_font, Vector2(nx+NW-40, oy-5),
				"TAIL", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#0a0010"))

		# Value
		draw_string(ThemeDB.fallback_font, Vector2(nx+NW/2-10, oy+NH/2+6),
			node.get("label","?") as String,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, col)

		# id
		draw_string(ThemeDB.fallback_font, Vector2(nx+4, oy+14),
			"id:%d" % (node.get("id",0) as int),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#888840"))

		# next pointer
		var nxt: int = node.get("next_id",-1) as int
		draw_string(ThemeDB.fallback_font, Vector2(nx+4, oy+NH-12),
			"next→%s" % ("null" if nxt==-1 else str(nxt)),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
			Color("#FF6B6B") if nxt==-1 else Color("#6BCB77"))

		# prev pointer (doubly)
		if _is_doubly:
			var prv: int = node.get("prev_id",-1) as int
			draw_string(ThemeDB.fallback_font, Vector2(nx+4, oy+NH-24),
				"prev←%s" % ("null" if prv==-1 else str(prv)),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
				Color("#FF6B6B") if prv==-1 else Color("#4D96FF"))

		# Arrow to next
		if not is_t:
			var ax1: float = nx + NW + 4
			var ax2: float = nx + NW + GAP - 4
			var ay:  float = oy + NH/2.0
			draw_line(Vector2(ax1, ay), Vector2(ax2, ay), Color("#6BCB77"), 2.0)
			# Arrowhead
			draw_line(Vector2(ax2, ay), Vector2(ax2-10, ay-6), Color("#6BCB77"), 2.0)
			draw_line(Vector2(ax2, ay), Vector2(ax2-10, ay+6), Color("#6BCB77"), 2.0)

		# Back arrow (doubly)
		if _is_doubly and not is_h:
			var ax1: float = nx - GAP + 4
			var ax2: float = nx - 4
			var ay:  float = oy + NH/2.0 + 10
			draw_line(Vector2(ax1, ay), Vector2(ax2, ay), Color("#4D96FF"), 1.5)
			draw_line(Vector2(ax1, ay), Vector2(ax1+10, ay-5), Color("#4D96FF"), 1.5)
			draw_line(Vector2(ax1, ay), Vector2(ax1+10, ay+5), Color("#4D96FF"), 1.5)

func _draw_code() -> void:
	var cy: float = PY + 195
	draw_rect(Rect2(PX+20, cy, PW-40, 170), Color("#060a02"))

	var lines: Dictionary = {
		"traverse": [
			["# GDScript — Traverse linked list:", Color("#555530")],
			["var cur = head", Color("#FFD93D")],
			["while cur != null:", Color("#6BCB77")],
			["    visit(cur.value)   # process node", Color("#6BCB77")],
			["    cur = cur.next     # follow pointer → O(n)", Color("#6BCB77")],
		],
		"insert": [
			["# GDScript — Insert after node B:", Color("#555530")],
			["new_node.next = B.next   # 1. point new node to B's old next", Color("#4D96FF")],
			["B.next = new_node        # 2. point B to new node  → O(1)*", Color("#4D96FF")],
			["# *O(n) to find position, O(1) to insert", Color("#555530")],
		],
		"delete": [
			["# GDScript — Delete node C (between B and D):", Color("#555530")],
			["prev.next = node_to_delete.next   # re-link B → D", Color("#FF6B6B")],
			["# node C is now unreachable → garbage collected", Color("#FF6B6B")],
			["# O(n) to find, O(1) to remove", Color("#555530")],
		],
		"reverse": [
			["# GDScript — Reverse singly linked list:", Color("#555530")],
			["prev, cur = null, head", Color("#C77DFF")],
			["while cur != null:", Color("#C77DFF")],
			["    next_tmp = cur.next   # save next", Color("#C77DFF")],
			["    cur.next = prev       # flip pointer ← O(n)", Color("#C77DFF")],
			["    prev, cur = cur, next_tmp", Color("#C77DFF")],
		],
	}

	var op_lines: Array = lines.get(_operation, lines["traverse"])
	for i in op_lines.size():
		draw_string(ThemeDB.fallback_font,
			Vector2(PX+36, cy + 22 + i*28),
			op_lines[i][0] as String,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
			op_lines[i][1] as Color)

func _draw_hint() -> void:
	draw_string(ThemeDB.fallback_font,
		Vector2(PX+PW-180, PY+22),
		"Press Q to close",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#555530"))
