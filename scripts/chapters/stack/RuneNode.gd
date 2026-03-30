extends Node2D

# ═══════════════════════════════════════════════════
# RuneNode.gd — Castle of Echoes
# Visual rune in the stack using codemon operator sprites.
# ═══════════════════════════════════════════════════

signal clicked(rune_id: int)

const RUNE_SPRITES: Dictionary = {
	"Fire":    "plus",    "Ice":     "minus",
	"Thunder": "multiply","Earth":   "divide",
	"Shadow":  "modulo",  "Light":   "equal",
	"Wind":    "if",      "Void":    "while",
}
const RUNE_COLORS: Dictionary = {
	"Fire":    Color("#FF6B6B"), "Ice":     Color("#4D96FF"),
	"Thunder": Color("#FFD93D"), "Earth":   Color("#6BCB77"),
	"Shadow":  Color("#C77DFF"), "Light":   Color("#FFD93D"),
	"Wind":    Color("#4D96FF"), "Void":    Color("#888899"),
}

var data:       Dictionary = {}
var is_top:     bool       = false
var stack_depth: int       = 0
var depth_idx:  int        = 0   # 0 = top
var _sprite:    Sprite2D
var _pulse:     float      = 0.0


var _target_y:   float = 0.0
var _move_speed: float = 200.0

func set_target(ty: float, depth_i: int, total: int, is_top_flag: bool) -> void:
	_target_y = ty
	depth_idx   = depth_i
	stack_depth = total
	is_top      = is_top_flag
	_update_sprite()
	queue_redraw()

func pop_anim() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.5, 1.5), 0.08)
	tw.tween_property(self, "scale", Vector2(0.0, 0.0), 0.18)
	tw.tween_callback(queue_free)

func _ready() -> void:
	_build()
	_setup_area()

func setup(rune_data: Dictionary, spawn_y: float = 0.0, target_y: float = 0.0) -> void:
	data        = rune_data
	is_top      = false
	stack_depth = 0
	depth_idx   = 0
	_update_sprite()
	queue_redraw()

func update_stack_state(top: bool, depth: int, idx: int) -> void:
	is_top      = top
	stack_depth = depth
	depth_idx   = idx
	_update_sprite()
	queue_redraw()

func _build() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(2.0, 2.0)
	add_child(_sprite)

func _update_sprite() -> void:
	var rune_name: String = data.get("name", "Fire") as String
	var key: String = RUNE_SPRITES.get(rune_name, "plus") as String
	var tex: Texture2D = AssetMap.codemon(key if not is_top else key + "_sel")
	if not tex: tex = AssetMap.codemon(key)
	if tex: _sprite.texture = tex

func _setup_area() -> void:
	var area := Area2D.new()
	var col  := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 32.0
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
	if is_top:
		_sprite.scale = Vector2(2.0 + sin(_pulse) * 0.1, 2.0 + sin(_pulse) * 0.1)
	queue_redraw()

func _draw() -> void:
	var rune_name: String = data.get("name", "Fire") as String
	var col: Color = RUNE_COLORS.get(rune_name, Color("#C77DFF")) as Color
	var alpha: float = 1.0 - float(depth_idx) / float(max(stack_depth, 1)) * 0.5

	# Slot background
	draw_circle(Vector2.ZERO, 34, col.darkened(0.7) * Color(1,1,1,alpha))
	
	# Glow ring for top
	if is_top:
		draw_arc(Vector2.ZERO, 36, 0, TAU, 32, col, 2.5)
		draw_string(ThemeDB.fallback_font, Vector2(-14, -44), "TOP ↓ POP", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)

	# Rune name
	draw_string(ThemeDB.fallback_font, Vector2(-20, 28), rune_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col * Color(1,1,1,alpha))
	
	# Depth label
	draw_string(ThemeDB.fallback_font, Vector2(-10, 40), "depth:%d" % depth_idx, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#555577") * Color(1,1,1,alpha))

func _process(delta: float) -> void:
	if abs(position.y - _target_y) > 2.0:
		position.y = move_toward(position.y, _target_y, _move_speed * delta)
	_pulse += delta * 3.0
	if is_top:
		_sprite.scale = Vector2(2.0 + sin(_pulse) * 0.1, 2.0 + sin(_pulse) * 0.1)
	queue_redraw()
