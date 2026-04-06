extends Node
# ═══════════════════════════════════════════════════
# Q_CitizenSpawner.gd — Kingdom Queue
# Generates citizens with random LPC appearances and emits citizen_arrived.
# ═══════════════════════════════════════════════════

signal citizen_arrived(citizen: Dictionary)
signal all_spawned

const NAMES := [
	"Alice","Bob","Carlos","Diana","Ethan",
	"Fatima","George","Hana","Ivan","Julia","Kofi","Lena",
	"Marco","Nadia","Omar","Priya","Quinn","Rosa","Sam","Tala"
]

const TYPES := {
	"normal":   {"label":"Normal",   "color":Color("#4D96FF"), "patience":15.0, "points":100, "priority":2},
	"vip":      {"label":"VIP",      "color":Color("#FFD93D"), "patience":8.0,  "points":200, "priority":1},
	"merchant": {"label":"Merchant", "color":Color("#6BCB77"), "patience":20.0, "points":150, "priority":2},
	"elderly":  {"label":"Elderly",  "color":Color("#C77DFF"), "patience":10.0, "points":120, "priority":2},
}

# Seeded appearances so the same citizen_id always looks the same across frames
var _cached_appearances: Dictionary = {}

static func get_citizens(level: int) -> Array:
	match level:
		1: return [{"type":"normal"},{"type":"normal"},{"type":"normal"},
				   {"type":"normal"},{"type":"normal"}]
		2: return [{"type":"normal"},{"type":"normal"},{"type":"normal"},
				   {"type":"normal"},{"type":"normal"},{"type":"normal"},
				   {"type":"normal"},{"type":"normal"}]
		3: return [{"type":"normal"},{"type":"elderly"},{"type":"normal"},
				   {"type":"elderly"},{"type":"normal"},{"type":"normal"},{"type":"elderly"}]
		4: return [{"type":"normal"},{"type":"vip"},{"type":"normal"},
				   {"type":"merchant"},{"type":"vip"},{"type":"normal"},
				   {"type":"normal"},{"type":"vip"}]
		5: return [{"type":"normal"},{"type":"vip"},{"type":"elderly"},
				   {"type":"merchant"},{"type":"normal"},{"type":"vip"},
				   {"type":"elderly"},{"type":"merchant"},{"type":"normal"}]
		_: return [{"type":"normal"},{"type":"normal"},{"type":"normal"},
				   {"type":"normal"},{"type":"normal"}]

var _citizens:  Array = []
var _idx:       int   = 0
var _interval:  float = 3.0
var _timer:     Timer
var _id:        int   = 0

func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.timeout.connect(_spawn_next)
	add_child(_timer)

func setup(citizens: Array, interval: float) -> void:
	_citizens  = citizens
	_interval  = interval
	_idx       = 0
	_id        = 0
	_cached_appearances.clear()

func start() -> void:
	_spawn_next()
	_timer.start(_interval)

func stop() -> void:
	_timer.stop()

func _spawn_next() -> void:
	if _idx >= _citizens.size():
		_timer.stop()
		emit_signal("all_spawned")
		return

	var template: Dictionary = _citizens[_idx]
	var tdata: Dictionary    = TYPES.get(template.get("type","normal"), TYPES["normal"])

	# Generate or retrieve a seeded LPC appearance for this citizen id
	var appearance: Dictionary = _get_appearance(_id)

	var citizen: Dictionary = {
		"id":           _id,
		"name":         NAMES[_id % NAMES.size()],
		"type":         template.get("type","normal"),
		"label":        tdata["label"],
		"color":        tdata["color"],
		"patience":     tdata["patience"],
		"points":       tdata["points"],
		"priority":     tdata["priority"],
		"arrival_time": Time.get_ticks_msec() / 1000.0,
		"appearance":   appearance,   # LPC appearance dict
	}

	_id  += 1
	_idx += 1
	emit_signal("citizen_arrived", citizen)

func _get_appearance(citizen_id: int) -> Dictionary:
	if _cached_appearances.has(citizen_id):
		return _cached_appearances[citizen_id]
	# Seed RNG so same ID always gets the same look
	seed(citizen_id + 12345)
	var appearance: Dictionary = CharacterRandomizer.randomize_character()
	_cached_appearances[citizen_id] = appearance
	return appearance
