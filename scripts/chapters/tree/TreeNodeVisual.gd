extends Node2D
# #REGION:CHARACTERS — BST/AVL tree node visual
# Built in _ready() (no @onready) — loaded via script not tscn.

signal clicked(node_id: int)

const NODE_ICONS: Array = ["if","else","for","while","and","or","bool","int"]
const STATE_COLORS: Dictionary = {
	"normal":   Color("#2a2a4a"),
	"searching":Color("#FFD93D"),
	"found":    Color("#6BCB77"),
	"inserted": Color("#4D96FF"),
	"deleted":  Color("#FF6B6B"),
	"unbalanced":Color("#FF9F43"),
	"path":     Color("#C77DFF"),
}

var data:   Dictionary = {}
var state:  String     = "normal"
var _pulse: float      = 0.0

var _circle:   ColorRect
var _sprite:   Sprite2D
var _val_lbl:  Label
var _bal_lbl:  Label
var _state_lbl:Label

func _ready() -> void:
	_build_nodes()

# #REGION:CHARACTERS — Build tree-node visual children
func _build_nodes() -> void:
	# Circle background
	_circle = ColorRect.new()
	_circle.set_position(Vector2(-30, -30)); _circle.set_size(Vector2(60, 60))
	add_child(_circle)

	# Codemon icon
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(3.0, 3.0)
	add_child(_sprite)

	# Value label
	_val_lbl = Label.new()
	_val_lbl.set_position(Vector2(-10, 32)); _val_lbl.set_size(Vector2(40, 18))
	_val_lbl.add_theme_font_size_override("font_size", 14)
	add_child(_val_lbl)

	# Balance factor badge
	_bal_lbl = Label.new()
	_bal_lbl.set_position(Vector2(28, -10)); _bal_lbl.set_size(Vector2(28, 16))
	_bal_lbl.add_theme_font_size_override("font_size", 9)
	add_child(_bal_lbl)

	# State label
	_state_lbl = Label.new()
	_state_lbl.set_position(Vector2(-24, -48)); _state_lbl.set_size(Vector2(56, 16))
	_state_lbl.add_theme_font_size_override("font_size", 9)
	add_child(_state_lbl)

	# Click area
	var area := Area2D.new()
	var sh   := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 36.0; sh.shape = circ
	area.add_child(sh)
	area.input_event.connect(_on_input)
	add_child(area)

func setup(node_data: Dictionary, node_state: String = "normal") -> void:
	data = node_data; state = node_state; _refresh()

func set_state(s: String) -> void:
	state = s; _refresh()

func _refresh() -> void:
	if not is_instance_valid(_circle): return
	var col: Color = STATE_COLORS.get(state, STATE_COLORS["normal"]) as Color
	_circle.color = col.darkened(0.5)
	var val: int   = data.get("value", 0) as int
	var key: String = NODE_ICONS[val % NODE_ICONS.size()] as String
	var tex: Texture2D = AssetMap.codemon(key)
	if tex: _sprite.texture = tex
	_val_lbl.text = str(val)
	_val_lbl.add_theme_color_override("font_color", col)
	var bf: int = data.get("balance_factor", 0) as int
	_bal_lbl.text = "" if bf == 0 else "bf%d" % bf
	_bal_lbl.add_theme_color_override("font_color",
		Color("#FF6B6B") if abs(bf) > 1 else Color("#FFD93D"))
	_state_lbl.text = "" if state == "normal" else state.to_upper()
	_state_lbl.add_theme_color_override("font_color", col)

func _process(delta: float) -> void:
	_pulse += delta * 3.0
	if state in ["found","inserted","searching"] and is_instance_valid(_sprite):
		_sprite.scale = Vector2(
			3.0 + sin(_pulse) * 0.1,
			3.0 + sin(_pulse) * 0.1)

func _on_input(_vp: Node, ev: InputEvent, _i: int) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("clicked", data.get("id", -1) as int)
