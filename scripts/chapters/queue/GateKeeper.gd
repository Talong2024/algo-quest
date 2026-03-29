extends Node

signal score_changed(v: int)
signal lives_changed(v: int)
signal feedback(msg: String, good: bool)
signal citizen_served(c: Dictionary)
signal citizen_expired(c: Dictionary)
signal game_over
signal level_complete

const MAX_LIVES: int      = 3
const PATIENCE_TICK: float = 1.0

var score: int    = 0
var lives: int    = MAX_LIVES
var required: int = 0
var served: int   = 0
var active: bool  = false

var _patience: Dictionary = {}
var _tick: float = 0.0
var _queue_ref: Node

func init(q: Node) -> void:
	_queue_ref = q

func start_level(count: int) -> void:
	required = count
	served   = 0
	active   = true
	_patience.clear()

func reset_stats() -> void:
	score  = 0
	lives  = MAX_LIVES
	active = false
	_patience.clear()
	emit_signal("score_changed", score)
	emit_signal("lives_changed", lives)

func _process(delta: float) -> void:
	if not active: return
	_tick += delta
	if _tick >= PATIENCE_TICK:
		_tick = 0.0
		_tick_patience()

func on_citizen_arrived(c: Dictionary) -> void:
	_patience[c["id"] as int] = c["patience"] as float

func player_picks(citizen_id: int) -> void:
	if not active: return
	if _queue_ref.is_correct_pick(citizen_id):
		var c: Dictionary = _queue_ref.dequeue()
		_patience.erase(citizen_id)
		score += c["points"] as int
		served += 1
		emit_signal("score_changed", score)
		emit_signal("citizen_served", c)
		emit_signal("feedback",
			"✓ %s served! FIFO honored +%d pts" % [c["name"], c["points"]], true)
		_check_complete()
	else:
		var front: Dictionary = _queue_ref.peek_front()
		_lose_life("✗ Wrong! Serve %s first — they arrived first!" % front.get("name", "?"))

func on_overflow() -> void:
	_lose_life("✗ Queue overflow! Too many waiting!")

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
				_lose_life("⚠ %s ran out of patience!" % c["name"])
				break

func get_patience_ratio(citizen_id: int) -> float:
	if not _patience.has(citizen_id): return 0.0
	var q_pos: int = _queue_ref.get_position(citizen_id)
	if q_pos < 0: return 1.0
	var c: Dictionary = _queue_ref.queue[q_pos]
	return clampf(_patience[citizen_id] / (c["patience"] as float), 0.0, 1.0)

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
