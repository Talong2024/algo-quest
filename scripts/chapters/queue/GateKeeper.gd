extends Node
## GateKeeper — mechanic-driven teaching logic.
## Each mechanic teaches ONE queue concept through consequences, not questions.

signal score_changed(v: int)
signal lives_changed(v: int)
signal feedback(msg: String, good: bool)
signal citizen_served(c: Dictionary)
signal citizen_expired(c: Dictionary)
signal anger_triggered(citizen_id: int, msg: String)   # wrong FIFO pick
signal drag_requested(citizen_id: int)                  # L4: player must drag this VIP
signal overflow_visual                                   # L2: flash the full queue
signal deque_prompt(citizen_id: int, gate: String)      # L5: show which gate
signal game_over
signal level_complete

const MAX_LIVES:     int   = 3
const PATIENCE_TICK: float = 1.0

var score:    int    = 0
var lives:    int    = MAX_LIVES
var required: int    = 0
var served:   int    = 0
var active:   bool   = false
var mechanic: String = "fifo"   # fifo | overflow | patience | priority | deque

var _patience:  Dictionary = {}
var _tick:      float      = 0.0
var _queue_ref: Node

# L4 priority: tracks which citizens have been correctly positioned
var _priority_confirmed: Dictionary = {}
# L5 deque: waiting for player to press F or B
var _deque_pending: Dictionary = {}   # citizen_id -> "front"|"back"|"any"

func init(q: Node) -> void:
	_queue_ref = q

func set_mechanic(m: String) -> void:
	mechanic = m

func start_level(count: int) -> void:
	required = count
	served   = 0
	active   = true
	_patience.clear()
	_priority_confirmed.clear()
	_deque_pending.clear()

func reset_stats() -> void:
	score    = 0
	lives    = MAX_LIVES
	active   = false
	_patience.clear()
	_priority_confirmed.clear()
	_deque_pending.clear()
	emit_signal("score_changed", score)
	emit_signal("lives_changed", lives)

func _process(delta: float) -> void:
	if not active: return
	_tick += delta
	if _tick >= PATIENCE_TICK:
		_tick = 0.0
		_tick_patience()

# ── Citizen arrival ───────────────────────────────────────────────────────────

func on_citizen_arrived(c: Dictionary) -> void:
	_patience[c["id"] as int] = c["patience"] as float
	# L4: if VIP arrives, signal that player needs to drag them
	if mechanic == "priority" and c.get("type","") == "vip":
		emit_signal("drag_requested", c["id"] as int)
	# L5: register gate requirement
	if mechanic == "deque":
		_deque_pending[c["id"] as int] = str(c.get("gate","any"))

# ── Player actions ────────────────────────────────────────────────────────────

## SPACE / E / click front citizen — serve from front
func player_picks(citizen_id: int) -> void:
	if not active: return
	match mechanic:
		"fifo", "overflow", "patience":
			_serve_fifo(citizen_id)
		"priority":
			_serve_priority(citizen_id)
		"deque":
			# In deque mode, clicking triggers the gate prompt
			if _deque_pending.has(citizen_id):
				var gate: String = _deque_pending[citizen_id] as String
				emit_signal("deque_prompt", citizen_id, gate)

## L5: Player presses F — dequeue from front
func player_dequeue_front() -> void:
	if not active or mechanic != "deque" or _queue_ref.is_empty(): return
	var c: Dictionary = _queue_ref.peek_front()
	var cid: int      = c["id"] as int
	var required_gate: String = str(_deque_pending.get(cid,"any"))
	if required_gate == "back":
		_lose_life("✗ %s needs the BACK gate! Press B instead." % c.get("name","?"))
		emit_signal("anger_triggered", cid, "Wrong gate!")
	else:
		_do_serve(_queue_ref.dequeue())

## L5: Player presses B — dequeue from back
func player_dequeue_back() -> void:
	if not active or mechanic != "deque" or _queue_ref.is_empty(): return
	var c: Dictionary = _queue_ref.queue[_queue_ref.queue.size()-1]
	var cid: int      = c["id"] as int
	var required_gate: String = str(_deque_pending.get(cid,"any"))
	if required_gate == "front":
		_lose_life("✗ %s needs the FRONT gate! Press F instead." % c.get("name","?"))
		emit_signal("anger_triggered", cid, "Wrong gate!")
	else:
		# Remove from back manually
		_queue_ref.queue.remove_at(_queue_ref.queue.size()-1)
		_queue_ref.emit_signal("queue_changed", _queue_ref.queue.duplicate())
		_do_serve(c)

## L4: Player drags a citizen to a new position
func player_reorder(citizen_id: int, new_pos: int) -> void:
	if not active or mechanic != "priority": return
	var q: Array = _queue_ref.queue
	var old_pos: int = _queue_ref.get_position(citizen_id)
	if old_pos < 0: return

	# Move the citizen
	var citizen: Dictionary = q[old_pos]
	q.remove_at(old_pos)
	new_pos = clampi(new_pos, 0, q.size())
	q.insert(new_pos, citizen)
	_queue_ref.emit_signal("queue_changed", q.duplicate())

	# Check if placement is correct: priority 1 should be ahead of priority 2, etc.
	var correct: bool = _check_priority_order()
	if correct:
		emit_signal("feedback", "✓ Correct order! VIP is in position.", true)
		_priority_confirmed[citizen_id] = true
	else:
		emit_signal("feedback", "✗ Wrong position! Higher priority goes first.", false)

func _check_priority_order() -> bool:
	var q: Array = _queue_ref.queue
	for i in range(q.size() - 1):
		var pa: int = q[i].get("priority",3) as int
		var pb: int = q[i+1].get("priority",3) as int
		if pa > pb:  # lower number = higher priority; pa>pb means wrong order
			return false
	return true

# ── FIFO serve ────────────────────────────────────────────────────────────────

func _serve_fifo(citizen_id: int) -> void:
	if _queue_ref.is_empty(): return
	if _queue_ref.is_correct_pick(citizen_id):
		_do_serve(_queue_ref.dequeue())
	else:
		# Wrong pick — show anger on the skipped citizen AND the wrongly-picked one
		var front: Dictionary = _queue_ref.peek_front()
		emit_signal("anger_triggered", front["id"] as int,
			"I was here first!")
		emit_signal("anger_triggered", citizen_id,
			"Wait your turn!")
		_lose_life("✗ %s was here first! FIFO — serve the front." % front.get("name","?"))

# ── Priority serve ────────────────────────────────────────────────────────────

func _serve_priority(citizen_id: int) -> void:
	if _queue_ref.is_empty(): return
	var front: Dictionary = _queue_ref.peek_front()
	if (front["id"] as int) == citizen_id:
		# Serving from front — only allow if priority order is correct
		if _check_priority_order():
			_do_serve(_queue_ref.dequeue())
		else:
			emit_signal("anger_triggered", citizen_id, "Wrong order!")
			_lose_life("✗ Queue order wrong! Drag VIPs into position first.")
	else:
		emit_signal("anger_triggered", citizen_id, "Wait your turn!")
		_lose_life("✗ Serve from the FRONT after reordering by priority.")

# ── Core serve ────────────────────────────────────────────────────────────────

func _do_serve(c: Dictionary) -> void:
	if c.is_empty(): return
	var cid: int = c["id"] as int
	_patience.erase(cid)
	_deque_pending.erase(cid)
	var tdata: Dictionary = {}
	if _queue_ref.has_method("get_type_data"):
		tdata = _queue_ref.get_type_data(c.get("type","normal") as String)
	var is_enemy: bool = (c.get("type","") as String) in ["skeleton","orc"]
	if is_enemy:
		# Player let a MONSTER through the gate — lose a life!
		emit_signal("anger_triggered", cid, "INTRUDER!")
		_lose_life("💀 You let a %s through the gate! -1 life!" % c.get("label","monster"))
		emit_signal("citizen_served", c)   # still remove from scene
		return
	score += c["points"] as int
	served += 1
	emit_signal("score_changed", score)
	emit_signal("citizen_served", c)
	emit_signal("feedback", "✓ %s served!  +%d" % [c.get("name","?"), c["points"] as int], true)
	_check_complete()

func on_overflow() -> void:
	emit_signal("overflow_visual")
	_lose_life("✗ Queue overflow! Serve faster — the queue was full.")

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
				_lose_life("⚠ %s ran out of patience and left!" % c.get("name","?"))
				break

func get_patience_ratio(citizen_id: int) -> float:
	if not _patience.has(citizen_id): return 0.0
	var pos: int = _queue_ref.get_position(citizen_id)
	if pos < 0: return 1.0
	return clampf(_patience[citizen_id] / (_queue_ref.queue[pos]["patience"] as float), 0.0, 1.0)

# ── Internal ──────────────────────────────────────────────────────────────────

func _lose_life(msg: String) -> void:
	lives -= 1
	emit_signal("lives_changed", lives)
	emit_signal("feedback", msg, false)
	if lives <= 0:
		active = false
		emit_signal("game_over")

func _check_complete() -> void:
	if served >= required and _queue_ref.is_empty():
		active = false
		emit_signal("level_complete")
