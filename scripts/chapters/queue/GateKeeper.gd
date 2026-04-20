extends Node
## GateKeeper — core game logic. Each mechanic teaches one queue concept.

signal score_changed(v: int)
signal lives_changed(v: int)
signal feedback(msg: String, good: bool)
signal citizen_served(c: Dictionary)
signal citizen_expired(c: Dictionary)
signal anger_triggered(citizen_id: int, msg: String)
signal drag_requested(citizen_id: int)
signal overflow_visual
signal deque_prompt(citizen_id: int, gate: String)
signal enemy_rejected(citizen_id: int)
signal game_over
signal level_complete

const MAX_LIVES:     int   = 3
const PATIENCE_TICK: float = 1.0

var score:    int    = 0
var lives:    int    = MAX_LIVES
var required: int    = 0
var served:   int    = 0
var active:   bool   = false
var mechanic: String = "fifo"

var _patience:         Dictionary = {}
var _tick:             float      = 0.0
var _queue_ref:        Node
var _priority_ok:      bool       = true
var _deque_pending:    Dictionary = {}

func init(q: Node) -> void:
	_queue_ref = q

func set_mechanic(m: String) -> void:
	mechanic = m

func start_level(count: int) -> void:
	required = count
	served   = 0
	active   = true
	_patience.clear()
	_deque_pending.clear()

func reset_stats() -> void:
	score    = 0
	lives    = MAX_LIVES
	active   = false
	_patience.clear()
	_deque_pending.clear()
	emit_signal("score_changed", score)
	emit_signal("lives_changed", lives)

func _process(delta: float) -> void:
	if not active: return
	_tick += delta
	if _tick >= PATIENCE_TICK:
		_tick = 0.0
		_tick_patience()

# ── Arrival ───────────────────────────────────────────────────────────────────

func on_citizen_arrived(c: Dictionary) -> void:
	_patience[c["id"] as int] = c["patience"] as float
	if mechanic == "priority" and c.get("type","") == "vip":
		emit_signal("drag_requested", c["id"] as int)
	if mechanic == "deque":
		_deque_pending[c["id"] as int] = str(c.get("gate","any"))

# ── Player actions ────────────────────────────────────────────────────────────

func player_picks(citizen_id: int) -> void:
	if not active: return
	match mechanic:
		"fifo","overflow","patience": _serve_fifo(citizen_id)
		"priority":                   _serve_priority(citizen_id)
		"deque":
			if _deque_pending.has(citizen_id):
				emit_signal("deque_prompt", citizen_id,
					str(_deque_pending.get(citizen_id,"any")))

func player_reject_enemy() -> void:
	if not active or _queue_ref.is_empty(): return
	var c: Dictionary = _queue_ref.peek_front()
	if c.is_empty(): return
	var ctype: String = str(c.get("type",""))
	if ctype in ["skeleton","orc"]:
		var d: Dictionary = _queue_ref.dequeue()
		_patience.erase(d["id"] as int)
		score += 150
		served += 1
		emit_signal("score_changed", score)
		emit_signal("enemy_rejected", d["id"] as int)
		emit_signal("feedback", "⚔️ Enemy repelled! +150 pts", true)
		emit_signal("citizen_served", d)
		_check_complete()
	else:
		_lose_life("✗ %s is not an enemy!" % c.get("name","?"))

func player_dequeue_front() -> void:
	if not active or mechanic != "deque" or _queue_ref.is_empty(): return
	var c: Dictionary = _queue_ref.peek_front()
	var cid: int = c["id"] as int
	var req: String = str(_deque_pending.get(cid,"any"))
	if req == "back":
		_lose_life("✗ %s needs the BACK gate! Press B." % c.get("name","?"))
		emit_signal("anger_triggered", cid, "Wrong gate!")
	else:
		_do_serve(_queue_ref.dequeue())

func player_dequeue_back() -> void:
	if not active or mechanic != "deque" or _queue_ref.is_empty(): return
	var q: Array = _queue_ref.queue
	if q.is_empty(): return
	var c: Dictionary = q[q.size()-1]
	var cid: int = c["id"] as int
	var req: String = str(_deque_pending.get(cid,"any"))
	if req == "front":
		_lose_life("✗ %s needs the FRONT gate! Press F." % c.get("name","?"))
		emit_signal("anger_triggered", cid, "Wrong gate!")
	else:
		q.remove_at(q.size()-1)
		_queue_ref.emit_signal("queue_changed", q.duplicate())
		_do_serve(c)

func player_reorder(citizen_id: int, new_pos: int) -> void:
	if not active or mechanic != "priority": return
	var q: Array = _queue_ref.queue
	var old_pos: int = _queue_ref.get_position(citizen_id)
	if old_pos < 0: return
	var citizen: Dictionary = q[old_pos]
	q.remove_at(old_pos)
	q.insert(clampi(new_pos, 0, q.size()), citizen)
	_queue_ref.emit_signal("queue_changed", q.duplicate())
	if _check_priority_order():
		emit_signal("feedback", "✓ Correct priority order!", true)
	else:
		emit_signal("feedback", "✗ Wrong position — higher priority goes first.", false)

func _check_priority_order() -> bool:
	var q: Array = _queue_ref.queue
	for i in range(q.size()-1):
		if (q[i].get("priority",3) as int) > (q[i+1].get("priority",3) as int):
			return false
	return true

# ── FIFO / overflow / patience serve ─────────────────────────────────────────

func _serve_fifo(citizen_id: int) -> void:
	if _queue_ref.is_empty(): return
	if _queue_ref.is_correct_pick(citizen_id):
		_do_serve(_queue_ref.dequeue())
	else:
		var front: Dictionary = _queue_ref.peek_front()
		emit_signal("anger_triggered", front["id"] as int, "I was here first!")
		emit_signal("anger_triggered", citizen_id, "Wait your turn!")
		_lose_life("✗ Serve %s first — FIFO order!" % front.get("name","?"))

func _serve_priority(citizen_id: int) -> void:
	if _queue_ref.is_empty(): return
	var front: Dictionary = _queue_ref.peek_front()
	if (front["id"] as int) == citizen_id:
		if _check_priority_order():
			_do_serve(_queue_ref.dequeue())
		else:
			emit_signal("anger_triggered", citizen_id, "Wrong order!")
			_lose_life("✗ Priority order is wrong! Drag VIPs into position first.")
	else:
		emit_signal("anger_triggered", citizen_id, "Wait your turn!")
		_lose_life("✗ Serve from the FRONT after sorting by priority.")

func _do_serve(c: Dictionary) -> void:
	if c.is_empty(): return
	var cid: int = c["id"] as int
	_patience.erase(cid)
	_deque_pending.erase(cid)
	var ctype: String = str(c.get("type",""))
	if ctype in ["skeleton","orc"]:
		emit_signal("anger_triggered", cid, "INTRUDER!")
		_lose_life("💀 You let a %s through!" % c.get("label","monster"))
		emit_signal("citizen_served", c)
		# Still count as processed so level can complete
		served += 1
		_check_complete()
		return
	score += c["points"] as int
	served += 1
	emit_signal("score_changed", score)
	emit_signal("citizen_served", c)
	emit_signal("feedback", "✓ %s served! +%d" % [c.get("name","?"), c["points"] as int], true)
	_check_complete()

func on_overflow() -> void:
	emit_signal("overflow_visual")
	# Reduce required count — this citizen will never be served
	required = maxi(0, required - 1)
	_lose_life("✗ Queue overflow! Serve faster.")
	_check_complete()

# ── Patience ──────────────────────────────────────────────────────────────────

func _tick_patience() -> void:
	var expired: Array = []
	for cid: int in _patience:
		_patience[cid] -= PATIENCE_TICK
		if _patience[cid] <= 0.0:
			expired.append(cid)
	for cid: int in expired:
		_patience.erase(cid)
		for i in _queue_ref.queue.size():
			if (_queue_ref.queue[i]["id"] as int) == cid:
				var c: Dictionary = _queue_ref.queue[i]
				_queue_ref.queue.remove_at(i)
				_queue_ref.emit_signal("queue_changed", _queue_ref.queue.duplicate())
				emit_signal("citizen_expired", c)
				# Count expired as "processed" so level can complete
				served += 1
				_lose_life("⚠ %s left — out of patience!" % c.get("name","?"))
				_check_complete()
				break

func get_patience_ratio(citizen_id: int) -> float:
	if not _patience.has(citizen_id): return 0.0
	var pos: int = _queue_ref.get_position(citizen_id)
	if pos < 0: return 1.0
	return clampf(_patience[citizen_id] / (_queue_ref.queue[pos]["patience"] as float), 0.0, 1.0)

func _lose_life(msg: String) -> void:
	lives -= 1
	emit_signal("lives_changed", lives)
	emit_signal("feedback", msg, false)
	if lives <= 0:
		active = false
		emit_signal("game_over")

func _check_complete() -> void:
	if not active: return
	if served >= required and _queue_ref.is_empty():
		active = false
		emit_signal("level_complete")
