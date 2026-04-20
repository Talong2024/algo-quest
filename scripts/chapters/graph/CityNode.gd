extends Node2D
## CityNode — a city on the Kingdom Roads map.
## Uses real Victorian market/landmark sprites as city icons.
## State color changes to show BFS/DFS/Dijkstra progress.

signal clicked(node_id: int)

# City landmark sprites — market stalls, wells, lanterns, fountains
const CITY_SPRITES: Array = [
	"res://assets/game/graph/stall_red.png",
	"res://assets/game/graph/stall_blue.png",
	"res://assets/game/graph/stall_green.png",
	"res://assets/game/graph/stall_yellow.png",
	"res://assets/game/graph/well.png",
	"res://assets/game/graph/fountain.png",
	"res://assets/game/graph/lantern.png",
	"res://assets/game/graph/sign_hanging.png",
]

const STATE_COLORS: Dictionary = {
	"unvisited":  Color("#2a3a2a"),
	"queued":     Color("#FFD93D"),
	"stack":      Color("#C77DFF"),
	"current":    Color("#FF9F43"),
	"visited":    Color("#6BCB77"),
	"path":       Color("#4D96FF"),
	"cycle":      Color("#FF6B6B"),
	"topo_ready": Color("#FFD93D"),
	"topo_done":  Color("#6BCB77"),
}

var data:       Dictionary = {}
var state:      String     = "unvisited"
var dist_label: String     = ""
var in_degree:  int        = -1
var _pulse:     float      = 0.0

# Visual nodes
var _platform:   ColorRect  # stone platform base
var _building:   Sprite2D   # the landmark sprite
var _flag:       ColorRect  # colored state flag on top
var _city_lbl:   Label      # city letter name
var _dist_lbl:   Label      # Dijkstra distance
var _deg_lbl:    Label      # in-degree (topological)

func _ready() -> void:
	_build_nodes()

func _build_nodes() -> void:
	# Stone platform base — cities sit on stone ground
	_platform = ColorRect.new()
	_platform.color = Color("#5a5040")
	_platform.set_position(Vector2(-28, 24))
	_platform.set_size(Vector2(56, 12))
	add_child(_platform)

	# The landmark/building sprite
	_building = Sprite2D.new()
	_building.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_building.scale = Vector2(3.5, 3.5)
	_building.position = Vector2(0, -8)
	add_child(_building)

	# Colored flag/banner strip at top of building
	_flag = ColorRect.new()
	_flag.set_position(Vector2(-28, -56))
	_flag.set_size(Vector2(56, 8))
	add_child(_flag)

	# City letter (A, B, C... for graph nodes)
	_city_lbl = Label.new()
	_city_lbl.set_position(Vector2(-14, 34))
	_city_lbl.set_size(Vector2(28, 22))
	_city_lbl.add_theme_font_size_override("font_size", 18)
	_city_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_city_lbl)

	# Distance label (Dijkstra)
	_dist_lbl = Label.new()
	_dist_lbl.set_position(Vector2(-28, -72))
	_dist_lbl.set_size(Vector2(56, 16))
	_dist_lbl.add_theme_font_size_override("font_size", 11)
	_dist_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_dist_lbl)

	# In-degree label (topological sort)
	_deg_lbl = Label.new()
	_deg_lbl.set_position(Vector2(24, -8))
	_deg_lbl.set_size(Vector2(24, 16))
	_deg_lbl.add_theme_font_size_override("font_size", 9)
	add_child(_deg_lbl)

	# Click area
	var area := Area2D.new()
	var sh   := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(56, 80); sh.shape = rect
	area.add_child(sh)
	area.input_event.connect(_on_input)
	add_child(area)

	_refresh()

func _refresh() -> void:
	if not is_instance_valid(_building): return
	var col: Color = STATE_COLORS.get(state, Color("#2a3a2a")) as Color
	var nid: int   = data.get("id", 0) as int

	# Platform color tints with state
	_platform.color = col.darkened(0.6)
	_flag.color     = col

	# Load city landmark sprite
	var path: String = CITY_SPRITES[nid % CITY_SPRITES.size()] as String
	if ResourceLoader.exists(path):
		_building.texture = load(path) as Texture2D

	# Modulate building to reflect state
	_building.modulate = Color.WHITE if state == "unvisited" else col.lightened(0.2)

	# City letter label
	var city_name: String = data.get("label", "?") as String
	_city_lbl.text = city_name
	_city_lbl.add_theme_color_override("font_color", col.lightened(0.3))

	# Distance
	_dist_lbl.text = dist_label
	_dist_lbl.add_theme_color_override("font_color", Color("#FFD93D"))

	# In-degree
	if in_degree >= 0:
		_deg_lbl.text = "in:%d" % in_degree
		_deg_lbl.add_theme_color_override("font_color",
			Color("#FF6B6B") if in_degree == 0 else Color("#888899"))
	else:
		_deg_lbl.text = ""

func set_state(new_state: String) -> void:
	state = new_state; _refresh()

func set_dist(d: String) -> void:
	dist_label = d; _refresh()

func set_in_degree(deg: int) -> void:
	in_degree = deg; _refresh()

func _process(delta: float) -> void:
	# Active states get a gentle bob
	if state in ["queued","current","topo_ready"] and is_instance_valid(_building):
		_pulse += delta * 3.0
		_building.position.y = -8.0 + sin(_pulse) * 4.0

func _on_input(_vp: Node, ev: InputEvent, _i: int) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("clicked", data.get("id", -1) as int)
