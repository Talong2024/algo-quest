extends Node

# ═══════════════════════════════════════════════════
# S_RuneSpawner.gd
# Generates rune sequences per level.
# Each rune is pushed in order — player must pop
# them in REVERSE order (LIFO).
# ═══════════════════════════════════════════════════

const RUNES: Array = [
	{ "name":"Fire",    "symbol":"🔥", "color":Color("#FF6B6B"), "glow":Color("#ff2200") },
	{ "name":"Ice",     "symbol":"❄",  "color":Color("#4D96FF"), "glow":Color("#00aaff") },
	{ "name":"Thunder", "symbol":"⚡",  "color":Color("#FFD93D"), "glow":Color("#ffaa00") },
	{ "name":"Earth",   "symbol":"🌿", "color":Color("#6BCB77"), "glow":Color("#00cc44") },
	{ "name":"Shadow",  "symbol":"🌑", "color":Color("#C77DFF"), "glow":Color("#aa00ff") },
	{ "name":"Light",   "symbol":"✨", "color":Color("#ffe066"), "glow":Color("#ffff00") },
	{ "name":"Wind",    "symbol":"🌀", "color":Color("#66ccff"), "glow":Color("#00ddff") },
	{ "name":"Void",    "symbol":"🔮", "color":Color("#cc77ff"), "glow":Color("#8800ff") },
]

var _next_id: int = 0

static func get_sequence(level: int) -> Array:
	match level:
		1: return [0, 1]
		2: return [0, 2, 3]
		3: return [1, 0, 4, 2]
		4: return [3, 1, 5, 0, 4]
		5: return [0, 2, 1, 6, 3, 7]
		_: return [0, 1, 2, 3, 4, 5]

func build_runes(sequence: Array) -> Array:
	var result: Array = []
	_next_id = 0
	for i in sequence.size():
		var base: Dictionary = RUNES[sequence[i] % RUNES.size()]
		result.append({
			"id":          _next_id,
			"name":        base["name"],
			"symbol":      base["symbol"],
			"color":       base["color"],
			"glow":        base["glow"],
			"push_order":  i,
		})
		_next_id += 1
	return result
