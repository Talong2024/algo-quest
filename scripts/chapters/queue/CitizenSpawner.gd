extends Node
signal citizen_arrived(citizen: Dictionary)
signal all_spawned

const NAMES := [
	"Alice","Bob","Carlos","Diana","Ethan","Fatima",
	"George","Hana","Ivan","Julia","Kofi","Lena",
	"Marco","Nadia","Omar","Priya","Quinn","Rosa","Sam","Tala"
]
const TYPES := {
	"normal":   {"label":"Normal",   "color":Color("#4D96FF"), "patience":18.0, "points":100,  "priority":3},
	"vip":      {"label":"VIP",      "color":Color("#FFD93D"), "patience":10.0, "points":200,  "priority":1},
	"merchant": {"label":"Merchant", "color":Color("#6BCB77"), "patience":22.0, "points":150,  "priority":2},
	"elderly":  {"label":"Elderly",  "color":Color("#C77DFF"), "patience":8.0,  "points":120,  "priority":3},
	"guard":    {"label":"Guard",    "color":Color("#FF6B6B"), "patience":30.0, "points":80,   "priority":2},
	"skeleton": {"label":"UNDEAD!",  "color":Color("#44FF88"), "patience":25.0, "points":-200, "priority":3, "is_enemy":true},
	"orc":      {"label":"MONSTER!", "color":Color("#FF4400"), "patience":20.0, "points":-300, "priority":3, "is_enemy":true},
}

# Returns citizens tuned to the level's mechanic
static func get_citizens(level: int, mechanic: String = "fifo") -> Array:
	match mechanic:
		"fifo":
			return [
				{"type":"normal"},{"type":"normal"},{"type":"normal"},
				{"type":"normal"},{"type":"normal"},
			]
		"overflow":
			# Fast spawn, need to keep serving or queue fills
			return [
				{"type":"normal"},{"type":"normal"},{"type":"normal"},
				{"type":"normal"},{"type":"normal"},{"type":"normal"},
				{"type":"normal"},{"type":"normal"},
			]
		"patience":
			# Enemies sneak into the queue — player must recognize and REJECT them
			return [
				{"type":"normal"},{"type":"elderly"},{"type":"normal"},
				{"type":"skeleton"},{"type":"normal"},{"type":"elderly"},
				{"type":"normal"},{"type":"orc"},{"type":"normal"},
			]
		"priority":
			# VIPs arrive mid-queue — must be dragged forward
			return [
				{"type":"normal"},{"type":"normal"},{"type":"vip"},
				{"type":"normal"},{"type":"vip"},{"type":"merchant"},
				{"type":"normal"},{"type":"vip"},{"type":"normal"},
			]
		"deque":
			# Guards can only exit back gate, VIPs only front gate
			return [
				{"type":"normal"},{"type":"guard","gate":"back"},
				{"type":"normal"},{"type":"vip","gate":"front"},
				{"type":"normal"},{"type":"guard","gate":"back"},
				{"type":"merchant"},{"type":"vip","gate":"front"},
				{"type":"normal"},
			]
		_:
			return [{"type":"normal"},{"type":"normal"},{"type":"normal"},{"type":"normal"},{"type":"normal"}]

var _citizens:  Array = []
var _idx:       int   = 0
var _interval:  float = 3.0
var _timer:     Timer
var _id:        int   = 0
var _cached_appearances: Dictionary = {}

func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.timeout.connect(_spawn_next)
	add_child(_timer)

func setup(citizens: Array, interval: float) -> void:
	_citizens = citizens
	_interval = interval
	_idx      = 0
	_id       = 0
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

	# Seeded appearance so same citizen always looks the same
	seed(_id + 54321)
	if not _cached_appearances.has(_id):
		_cached_appearances[_id] = CharacterRandomizer.randomize_character()
	var appearance: Dictionary = _cached_appearances[_id]
	# Override appearance for enemy types
	var ctype: String = template.get("type","normal")
	if ctype == "skeleton":
		appearance = {"body_type":"enemy_skeleton","skin_tone":"","hair_style":"","hair_color":"",
			"shirt_style":"","shirt_color":"","leg_type":"","shoe_type":"","shoe_color":"",
			"sock_type":"","sock_color":""}
	elif ctype == "orc":
		appearance = {"body_type":"enemy_orc","skin_tone":"","hair_style":"","hair_color":"",
			"shirt_style":"","shirt_color":"","leg_type":"","shoe_type":"","shoe_color":"",
			"sock_type":"","sock_color":""}

	var citizen: Dictionary = {
		"id":           _id,
		"name":         NAMES[_id % NAMES.size()],
		"type":         template.get("type","normal"),
		"gate":         template.get("gate","any"),  # "front","back","any"
		"label":        tdata["label"],
		"color":        tdata["color"],
		"patience":     tdata["patience"],
		"points":       tdata["points"],
		"priority":     tdata["priority"],
		"arrival_time": Time.get_ticks_msec() / 1000.0,
		"appearance":   appearance,
	}
	_id  += 1
	_idx += 1
	emit_signal("citizen_arrived", citizen)

func _get_appearance(cid: int) -> Dictionary:
	if not _cached_appearances.has(cid):
		seed(cid + 54321)
		_cached_appearances[cid] = CharacterRandomizer.randomize_character()
	return _cached_appearances[cid]
