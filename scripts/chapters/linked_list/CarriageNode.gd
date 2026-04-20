extends Node2D
## CarriageNode — a train carriage carrying actual cargo.
## Uses real crate/barrel/sack sprites as cargo icons inside the carriage body.

signal clicked(node_id: int)

# Cargo sprites — actual crates, barrels, sacks matching train theme
const CARGO: Array = [
	"res://assets/game/linked_list/crate_wood.png",
	"res://assets/game/linked_list/crate_apples.png",
	"res://assets/game/linked_list/crate_grain.png",
	"res://assets/game/linked_list/crate_carrots.png",
	"res://assets/game/linked_list/crate_mixed.png",
	"res://assets/game/linked_list/sack_large.png",
	"res://assets/game/linked_list/sack_medium.png",
	"res://assets/game/linked_list/barrel.png",
	"res://assets/game/linked_list/vic_chest_closed.png",
	"res://assets/game/linked_list/vic_barrel_brown.png",
	"res://assets/game/linked_list/vic_pot_clay.png",
]

var data:     Dictionary = {}
var is_head:  bool       = false
var is_tail:  bool       = false
var selected: bool       = false
var _wobble:  float      = 0.0

# Visual nodes
var _body:        ColorRect  # carriage body
var _roof:        ColorRect  # carriage roof strip
var _window_l:    ColorRect  # left window
var _window_r:    ColorRect  # right window
var _cargo:       Sprite2D   # cargo icon inside carriage
var _value_lbl:   Label      # node value
var _type_lbl:    Label      # HEAD/TAIL/node label
var _wheel_l:     ColorRect
var _wheel_r:     ColorRect

func _ready() -> void:
	_build_nodes()

func _build_nodes() -> void:
	# Carriage body — wooden brown train car
	_body = ColorRect.new()
	_body.color = Color("#5a3a18")
	_body.set_position(Vector2(-50, -36)); _body.set_size(Vector2(100, 68))
	add_child(_body)

	# Roof
	_roof = ColorRect.new()
	_roof.color = Color("#3a2010")
	_roof.set_position(Vector2(-50, -36)); _roof.set_size(Vector2(100, 8))
	add_child(_roof)

	# Left window
	_window_l = ColorRect.new()
	_window_l.color = Color("#aaddff", 0.7)
	_window_l.set_position(Vector2(-40, -24)); _window_l.set_size(Vector2(20, 20))
	add_child(_window_l)

	# Right window
	_window_r = ColorRect.new()
	_window_r.color = Color("#aaddff", 0.7)
	_window_r.set_position(Vector2(20, -24)); _window_r.set_size(Vector2(20, 20))
	add_child(_window_r)

	# Cargo sprite — centered in carriage
	_cargo = Sprite2D.new()
	_cargo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_cargo.scale = Vector2(2.8, 2.8)
	_cargo.position = Vector2(0, -4)
	add_child(_cargo)

	# Value label (node data value)
	_value_lbl = Label.new()
	_value_lbl.set_position(Vector2(14, -34)); _value_lbl.set_size(Vector2(34, 18))
	_value_lbl.add_theme_font_size_override("font_size", 14)
	add_child(_value_lbl)

	# Type label (HEAD/TAIL/node)
	_type_lbl = Label.new()
	_type_lbl.set_position(Vector2(-46, 24)); _type_lbl.set_size(Vector2(92, 12))
	_type_lbl.add_theme_font_size_override("font_size", 9)
	_type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_type_lbl)

	# Wheels — chunky circles using ColorRect
	_wheel_l = ColorRect.new()
	_wheel_l.color = Color("#1a1a1a")
	_wheel_l.set_position(Vector2(-40, 30)); _wheel_l.set_size(Vector2(22, 22))
	add_child(_wheel_l)
	_wheel_r = ColorRect.new()
	_wheel_r.color = Color("#1a1a1a")
	_wheel_r.set_position(Vector2(18, 30)); _wheel_r.set_size(Vector2(22, 22))
	add_child(_wheel_r)

	# Wheel axle
	var axle := ColorRect.new()
	axle.color = Color("#555555")
	axle.set_position(Vector2(-40, 38)); axle.set_size(Vector2(80, 6))
	add_child(axle)

	# Click area
	var area := Area2D.new()
	var sh   := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(100, 72); sh.shape = rect
	area.add_child(sh)
	area.input_event.connect(_on_input)
	add_child(area)

func setup(node_data: Dictionary, head: bool = false, tail: bool = false) -> void:
	data = node_data; is_head = head; is_tail = tail
	_refresh()

func set_state(head: bool, tail: bool) -> void:
	is_head = head; is_tail = tail; _refresh()

func _refresh() -> void:
	if not is_instance_valid(_body): return

	# Color scheme: HEAD=gold, TAIL=orange, selected=green, normal=blue
	var col: Color = Color("#FFD93D") if is_head else \
		(Color("#FF9F43") if is_tail else \
		(Color("#6BCB77") if selected else Color("#7a5030")))

	_body.color   = col.darkened(0.5)
	_roof.color   = col.darkened(0.7)
	_wheel_l.color = col.darkened(0.8)
	_wheel_r.color = col.darkened(0.8)

	# Window tint matches state
	var wc: Color = col.lightened(0.3)
	_window_l.color = Color(wc.r, wc.g, wc.b, 0.6)
	_window_r.color = Color(wc.r, wc.g, wc.b, 0.6)

	# Pick cargo sprite based on node id
	var nid: int = data.get("id", 0) as int
	var path: String = CARGO[nid % CARGO.size()] as String
	if ResourceLoader.exists(path):
		_cargo.texture = load(path) as Texture2D

	_value_lbl.text = data.get("label", "?") as String
	_value_lbl.add_theme_color_override("font_color", col.lightened(0.4))

	_type_lbl.text = "HEAD →" if is_head else ("← TAIL" if is_tail else "node[%d]" % nid)
	_type_lbl.add_theme_color_override("font_color", col.lightened(0.2))

func _process(delta: float) -> void:
	if selected:
		_wobble += delta * 4.0
		position.y = sin(_wobble) * 5.0

func _on_input(_vp: Node, ev: InputEvent, _i: int) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("clicked", data.get("id", -1) as int)
