extends Node2D

# ═══════════════════════════════════════════════════
# TreeNodeVisual.gd — Oracle's Forest
# BST/AVL node with codemon sprite face.
# ═══════════════════════════════════════════════════

signal clicked(node_id: int)

const NODE_ICONS: Array = ["if","else","for","while","and","or","bool","int","char","string"]
const RADIUS: float = 30.0

var data:     Dictionary = {}
var state:    String     = "normal"   # normal | searching | found | inserted | deleted | unbalanced
var _sprite:  Sprite2D
var _pulse:   float      = 0.0

const STATE_COLORS: Dictionary = {
	"normal":     Color("#2a2a4a"),
	"searching":  Color("#FFD93D"),
	"found":      Color("#6BCB77"),
	"inserted":   Color("#4D96FF"),
	"deleted":    Color("#FF6B6B"),
	"unbalanced": Color("#FF9F43"),
	"path":       Color("#C77DFF"),
}

func _ready() -> void:
	_build()
	_setup_area()

func setup(node_data: Dictionary, node_state: String = "normal") -> void:
	data  = node_data
	state = node_state
	_update_sprite()
	queue_redraw()

func set_state(s: String) -> void:
	state = s
	_update_sprite()
	queue_redraw()

func _build() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(1.4, 1.4)
	add_child(_sprite)

func _update_sprite() -> void:
	var val: int    = data.get("value", 0) as int
	var key: String = NODE_ICONS[val % NODE_ICONS.size()] as String
	# Use selected variant for active states
	if state in ["found","inserted","searching"]:
		var sel_tex: Texture2D = AssetMap.codemon(key + "_sel")
		if sel_tex:
			_sprite.texture = sel_tex
			return
	var tex: Texture2D = AssetMap.codemon(key)
	if tex: _sprite.texture = tex

func _setup_area() -> void:
	var area := Area2D.new()
	var col  := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = RADIUS + 4
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
	_pulse += delta * 3.0
	if state in ["searching","found","inserted"]:
		_sprite.scale = Vector2(
			1.4 + sin(_pulse) * 0.1,
			1.4 + sin(_pulse) * 0.1
		)
	queue_redraw()

func _draw() -> void:
	var col: Color = STATE_COLORS.get(state, STATE_COLORS["normal"]) as Color

	# Node circle
	draw_circle(Vector2.ZERO, RADIUS + 2, Color(0,0,0,0.4))
	draw_circle(Vector2.ZERO, RADIUS, col.darkened(0.4))
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 32, col, 2.0)

	# Value label
	var val: int = data.get("value", 0) as int
	draw_string(ThemeDB.fallback_font, Vector2(-8, RADIUS + 16), str(val), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)

	# Balance factor (AVL)
	var bf: int = data.get("balance_factor", 0) as int
	if bf != 0:
		var bf_col: Color = Color("#FF6B6B") if abs(bf) > 1 else Color("#FFD93D")
		draw_string(ThemeDB.fallback_font, Vector2(RADIUS + 4, -8), "bf:%d" % bf, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, bf_col)

	# State indicator
	match state:
		"found":
			draw_string(ThemeDB.fallback_font, Vector2(-14, -RADIUS - 14), "★ FOUND", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
		"unbalanced":
			draw_string(ThemeDB.fallback_font, Vector2(-24, -RADIUS - 14), "⚠ ROTATE!", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
		"inserted":
			draw_string(ThemeDB.fallback_font, Vector2(-14, -RADIUS - 14), "+ NEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
