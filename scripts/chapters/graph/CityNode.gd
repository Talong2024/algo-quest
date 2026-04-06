extends Node2D
# #REGION:CHARACTERS — Graph city node visual
# Built in _ready() (no @onready) — loaded via script not tscn.

signal clicked(node_id: int)

const CITY_ICONS: Array = ["int","bool","char","for","while","plug","string","array"]
const STATE_COLORS: Dictionary = {
	"unvisited": Color("#2a2a4a"),
	"queued":    Color("#FFD93D"),
	"stack":     Color("#C77DFF"),
	"current":   Color("#FF9F43"),
	"visited":   Color("#6BCB77"),
	"path":      Color("#4D96FF"),
	"cycle":     Color("#FF6B6B"),
	"topo_ready":Color("#FFD93D"),
	"topo_done": Color("#6BCB77"),
}

var data:       Dictionary = {}
var state:      String     = "unvisited"
var dist_label: String     = ""
var in_degree:  int        = -1
var _pulse:     float      = 0.0

var _circle:   ColorRect
var _sprite:   Sprite2D
var _city_lbl: Label
var _dist_lbl: Label
var _deg_lbl:  Label

func _ready() -> void:
	_build_nodes()

# #REGION:CHARACTERS — Build city visual children
func _build_nodes() -> void:
	# Shadow
	var shadow := ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.25)
	shadow.set_position(Vector2(-28, 26)); shadow.set_size(Vector2(56, 12))
	add_child(shadow)

	# Circle body
	_circle = ColorRect.new()
	_circle.set_position(Vector2(-32, -32)); _circle.set_size(Vector2(64, 64))
	add_child(_circle)

	# Codemon icon
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(3.2, 3.2)
	add_child(_sprite)

	# City letter label
	_city_lbl = Label.new()
	_city_lbl.set_position(Vector2(-8, 34)); _city_lbl.set_size(Vector2(24, 22))
	_city_lbl.add_theme_font_size_override("font_size", 16)
	add_child(_city_lbl)

	# Distance label
	_dist_lbl = Label.new()
	_dist_lbl.set_position(Vector2(-20, -52)); _dist_lbl.set_size(Vector2(56, 16))
	_dist_lbl.add_theme_font_size_override("font_size", 10)
	_dist_lbl.add_theme_color_override("font_color", Color("#FFD93D"))
	add_child(_dist_lbl)

	# In-degree badge (for topological sort)
	_deg_lbl = Label.new()
	_deg_lbl.set_position(Vector2(28, -40)); _deg_lbl.set_size(Vector2(24, 22))
	_deg_lbl.add_theme_font_size_override("font_size", 12)
	add_child(_deg_lbl)

	# Click area
	var area := Area2D.new()
	var sh   := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 38.0; sh.shape = circ
	area.add_child(sh)
	area.input_event.connect(_on_input)
	add_child(area)

func set_state(s: String) -> void:
	state = s; _refresh()

func _refresh() -> void:
	if not is_instance_valid(_circle): return
	var col: Color = STATE_COLORS.get(state, STATE_COLORS["unvisited"]) as Color
	_circle.color = col.darkened(0.5)
	var nid: int   = data.get("id", 0) as int
	var key: String = CITY_ICONS[nid % CITY_ICONS.size()] as String
	var tex: Texture2D = AssetMap.codemon(key)
	if tex: _sprite.texture = tex
	_city_lbl.text = data.get("label", "?") as String
	_city_lbl.add_theme_color_override("font_color", col)
	_dist_lbl.text = dist_label
	if in_degree >= 0:
		_deg_lbl.text  = str(in_degree)
		_deg_lbl.add_theme_color_override("font_color",
			Color("#FFD93D") if in_degree == 0 else Color("#888899"))

func _process(delta: float) -> void:
	_pulse += delta * 2.5
	if state in ["queued","current","topo_ready"] and is_instance_valid(_sprite):
		_sprite.position.y = sin(_pulse) * 4.0

func _on_input(_vp: Node, ev: InputEvent, _i: int) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("clicked", data.get("id", -1) as int)
