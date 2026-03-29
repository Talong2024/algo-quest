extends Node2D

signal next_requested
signal retry_requested
signal menu_requested

func setup(cfg: Dictionary, score: int, win: bool, has_next: bool) -> void:
	_build(cfg, score, win, has_next)

func _build(cfg: Dictionary, score: int, win: bool, has_next: bool) -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0e0f04")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := ColorRect.new()
	panel.color = Color("#0a0c02")
	panel.set_position(Vector2(240,80))
	panel.set_size(Vector2(800,560))
	add_child(panel)

	var title := Label.new()
	title.text = "Level %d Clear!" % cfg.get("level",1) if win else "Chain Broken!"
	title.set_position(Vector2(290,110))
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color",
		Color("#FFD93D") if win else Color("#FF6B6B"))
	add_child(title)

	var sl := Label.new()
	sl.text = "Score: %d" % score
	sl.set_position(Vector2(560,170))
	sl.add_theme_font_size_override("font_size", 22)
	sl.add_theme_color_override("font_color", Color("#FFD93D"))
	add_child(sl)

	var rb := ColorRect.new()
	rb.color = Color("#060802")
	rb.set_position(Vector2(260,215))
	rb.set_size(Vector2(760,160))
	add_child(rb)

	var rl := Label.new()
	rl.text = "What you learned:"
	rl.set_position(Vector2(276,227))
	rl.add_theme_font_size_override("font_size", 14)
	rl.add_theme_color_override("font_color", Color("#4D96FF"))
	add_child(rl)

	var recap := Label.new()
	recap.set_position(Vector2(276,250))
	recap.set_custom_minimum_size(Vector2(720,110))
	recap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recap.add_theme_font_size_override("font_size", 13)
	recap.add_theme_color_override("font_color", Color("#aaaaaa"))
	recap.text = _get_recap(cfg.get("level",1) as int, win)
	add_child(recap)

	var cb := ColorRect.new()
	cb.color = Color("#040600")
	cb.set_position(Vector2(260,385))
	cb.set_size(Vector2(760,80))
	add_child(cb)

	var code := Label.new()
	code.set_position(Vector2(276,397))
	code.add_theme_font_size_override("font_size", 12)
	code.add_theme_color_override("font_color", Color("#6BCB77"))
	code.text = _get_code(cfg.get("level",1) as int)
	add_child(code)

	if win and has_next:
		_btn("Next Level ▶", Vector2(740,490), Color("#6BCB77"), func(): emit_signal("next_requested"))
	elif win:
		_btn("🏆 Complete!", Vector2(740,490), Color("#FFD93D"), func(): emit_signal("menu_requested"))
	else:
		_btn("↺ Retry", Vector2(640,490), Color("#FF6B6B"), func(): emit_signal("retry_requested"))
	_btn("Menu", Vector2(260,490), Color("#888860"), func(): emit_signal("menu_requested"))

func _get_recap(level: int, win: bool) -> String:
	if not win:
		return "The chain broke! Remember: when deleting, always re-link BEFORE removing.\nprev.next = target.next  — skip over the target node.\nWrong operation = broken chain = node lost forever!"
	match level:
		1: return "TRAVERSE: visit every node by following next pointers, O(n) time.\nHead → node1 → node2 → … → null. No random access like arrays!\nReal world: playlists, browser history, undo chains."
		2: return "INSERT: O(1) once you have the position — just re-link two pointers.\n1. new.next = B.next   2. B.next = new\nCrucial order: set new.next FIRST or you lose the tail!"
		3: return "DELETE: O(1) to remove once found — just skip over with prev.next = target.next.\nThe removed node becomes unreachable — garbage collected.\nReal world: removing a song from a playlist, task from a queue."
		4: return "REVERSE: O(n) — must visit every node once to flip all pointers.\nprev=null, cur=head → flip cur.next=prev, advance both.\nReal world: reversing a playlist, undo stack reversal."
		5: return "DOUBLY LINKED: next AND prev pointers — traverse in both directions.\nInsert/delete must update BOTH neighbours' pointers (4 pointer changes).\nReal world: browser back/forward, deque, LRU cache."
		_: return "All linked list operations mastered!"

func _get_code(level: int) -> String:
	match level:
		1: return "cur = head\nwhile cur != null:\n    visit(cur.value); cur = cur.next   # O(n)"
		2: return "new_node.next = B.next   # MUST be first!\nB.next = new_node       # O(1) insert"
		3: return "prev.next = target.next  # skip over target\n# target is now unreachable → O(1) delete"
		4: return "prev, cur = null, head\nwhile cur: next=cur.next; cur.next=prev; prev=cur; cur=next\nhead = prev   # O(n) reverse"
		5: return "# Doubly: 4 pointer updates per insert\nnew.next=B.next; new.prev=B; B.next=new; new.next.prev=new"
		_: return "# All operations combined"

func _btn(text: String, pos: Vector2, col: Color, cb: Callable) -> void:
	var b := Button.new()
	b.text = text; b.set_position(pos); b.set_size(Vector2(160,46))
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", col)
	b.pressed.connect(cb); add_child(b)
