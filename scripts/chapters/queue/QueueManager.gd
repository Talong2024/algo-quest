extends Node

signal queue_changed(snapshot: Array)
signal overflow_occurred
signal underflow_occurred

var queue: Array = []
var max_size: int = 6

func enqueue(citizen: Dictionary) -> bool:
	if is_full():
		emit_signal("overflow_occurred")
		return false
	queue.append(citizen)
	emit_signal("queue_changed", queue.duplicate())
	return true

func dequeue() -> Dictionary:
	if is_empty():
		emit_signal("underflow_occurred")
		return {}
	var c: Dictionary = queue.pop_front()
	emit_signal("queue_changed", queue.duplicate())
	return c

func peek_front() -> Dictionary:
	return queue[0] if not is_empty() else {}

func is_correct_pick(citizen_id: int) -> bool:
	if is_empty(): return false
	return (queue[0]["id"] as int) == citizen_id

func get_position(citizen_id: int) -> int:
	for i in queue.size():
		if (queue[i]["id"] as int) == citizen_id:
			return i
	return -1

func is_empty() -> bool: return queue.size() == 0
func is_full()  -> bool: return queue.size() >= max_size
func size()     -> int:  return queue.size()

func clear() -> void:
	queue.clear()
	emit_signal("queue_changed", queue.duplicate())
