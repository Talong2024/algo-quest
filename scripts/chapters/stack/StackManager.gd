extends Node

# ═══════════════════════════════════════════════════
# S_StackManager.gd  —  THE stack data structure.
# LIFO: Last In, First Out.
# All game logic reads/writes only through here.
# ═══════════════════════════════════════════════════

signal stack_changed(snapshot: Array)
signal stack_overflow
signal stack_underflow

var stack:    Array = []
var max_size: int   = 6

## PUSH — add rune to TOP   O(1)
func push(rune: Dictionary) -> bool:
	if is_full():
		emit_signal("stack_overflow")
		return false
	stack.append(rune)
	emit_signal("stack_changed", stack.duplicate())
	return true

## POP — remove from TOP (LIFO!)   O(1)
func pop() -> Dictionary:
	if is_empty():
		emit_signal("stack_underflow")
		return {}
	var r: Dictionary = stack.pop_back()
	emit_signal("stack_changed", stack.duplicate())
	return r

## PEEK — look at top without removing
func peek() -> Dictionary:
	return stack[stack.size() - 1] if not is_empty() else {}

## True if given rune id is on TOP of stack
func is_correct_pop(rune_id: int) -> bool:
	if is_empty(): return false
	return (stack[stack.size() - 1]["id"] as int) == rune_id

## Depth from bottom: 0 = bottom, size-1 = top
func get_depth(rune_id: int) -> int:
	for i in stack.size():
		if (stack[i]["id"] as int) == rune_id:
			return i
	return -1

func is_empty() -> bool: return stack.size() == 0
func is_full()  -> bool: return stack.size() >= max_size
func size()     -> int:  return stack.size()

func clear() -> void:
	stack.clear()
	emit_signal("stack_changed", stack.duplicate())
