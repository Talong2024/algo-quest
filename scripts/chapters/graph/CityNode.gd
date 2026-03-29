extends Node2D

# ═══════════════════════════════════════════════════
# CityNode.gd — Kingdom Roads
# Graph node (city) with codemon sprite + state colors.
# ═══════════════════════════════════════════════════

signal clicked(node_id: int)

const CITY_ICONS: Array = ["int","bool","char","for","while","plug","string","array"]
const RADIUS: float = 32.0

var data:      Dictionary = {}
var state:     String     = "unvisited"
var dist_label:  String   = ""
var order_label: String   = ""
var in_degree:   int      = -1
var _sprite:   Sprite2D
var _pulse:    float      = 0.0

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

func _ready() -> void:
	_build()
	_setup_area()

func set_state(s: String) -> void:
	state = s
	_update_sprite()
	queue_redraw()

func _build() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(1.5, 1.5)
	add_child(_sprite)

func _update_sprite() -> void:
	var node_id: int = data.get("id", 0) as int
	var key: String  = CITY_ICONS[node_id % CITY_ICONS.size()] as String
	if state in ["current","queued","stack","topo_ready"]:
		var sel: Texture2D = AssetMap.codemon(key + "_sel")
		if sel:
			_sprite.texture = sel
			return
	var tex: Texture2D = AssetMap.codemon(key)
	if tex: _sprite.texture = tex

func _setup_area() -> void:
	var area := Area2D.new()
	var col  := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = RADIUS + 6
	col.shape   = circ
	area.input_event.connect(func(_v, ev, _i):
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				emit_signal("clicked", data.get("id", -1) as int)
	)
	area.add_child(col)
	add_child(area)

func _process(delta: float) -> void:
	_pulse += delta * 2.5
	if state in ["queued","current","topo_ready"]:
		_sprite.position.y = sin(_pulse) * 4.0
	queue_redraw()

func _draw() -> void:
	var col: Color = STATE_COLORS.get(state, STATE_COLORS["unvisited"]) as Color

	# Shadow
	draw_circle(Vector2(3, 3), RADIUS, Color(0, 0, 0, 0.4))
	# Body
	draw_circle(Vector2.ZERO, RADIUS, col.darkened(0.5))
	# Border
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 32, col, 2.5)

	# City label
	var lbl: String = data.get("label", "?") as String
	draw_string(ThemeDB.fallback_font, Vector2(-6, RADIUS + 16), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)

	# Distance label (Dijkstra)
	if dist_label != "":
		draw_string(ThemeDB.fallback_font, Vector2(-16, -RADIUS - 14), dist_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#4D96FF"))

	# Order label (BFS/DFS)
	if order_label != "":
		draw_string(ThemeDB.fallback_font, Vector2(-8, -RADIUS - 14), "#%s" % order_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)

	# In-degree badge (topological sort)
	if in_degree >= 0:
		var deg_col: Color = Color("#FFD93D") if in_degree == 0 else Color("#888899")
		draw_circle(Vector2(RADIUS, -RADIUS), 12, Color("#0d0d18"))
		draw_string(ThemeDB.fallback_font, Vector2(RADIUS - 6, -RADIUS + 5), str(in_degree), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, deg_col)

	# State indicator
	match state:
		"visited","topo_done":
			draw_string(ThemeDB.fallback_font, Vector2(-6, 6), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
		"cycle":
			draw_string(ThemeDB.fallback_font, Vector2(-8, 6), "⟳", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
