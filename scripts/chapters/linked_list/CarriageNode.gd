extends Node2D
# #REGION:CHARACTERS — Linked list carriage node
# Built in _ready() (no @onready) — loaded via script not tscn.

signal clicked(node_id: int)

const ICONS: Array = ["array","int","for","while","if","string","bool","char"]

var data:     Dictionary = {}
var is_head:  bool       = false
var is_tail:  bool       = false
var selected: bool       = false
var _wobble:  float      = 0.0

var _body:   ColorRect
var _sprite: Sprite2D
var _value:  Label
var _type:   Label
var _wl:     ColorRect
var _wr:     ColorRect

func _ready() -> void:
	_build_nodes()

# #REGION:CHARACTERS — Build carriage visual children
func _build_nodes() -> void:
	# Carriage body
	_body = ColorRect.new()
	_body.set_position(Vector2(-50, -36)); _body.set_size(Vector2(100, 72))
	add_child(_body)

	# Carriage border overlay
	var border := ColorRect.new()
	border.color = Color(0, 0, 0, 0)  # transparent — outline drawn via draw
	border.set_position(Vector2(-50, -36)); border.set_size(Vector2(100, 72))
	add_child(border)

	# Codemon icon
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(3.2, 3.2)
	_sprite.position = Vector2(-18, -8)
	add_child(_sprite)

	# Value label (large)
	_value = Label.new()
	_value.set_position(Vector2(6, -12)); _value.set_size(Vector2(42, 24))
	_value.add_theme_font_size_override("font_size", 18)
	add_child(_value)

	# Type label (small)
	_type = Label.new()
	_type.set_position(Vector2(-40, 26)); _type.set_size(Vector2(80, 14))
	_type.add_theme_font_size_override("font_size", 9)
	add_child(_type)

	# Wheels
	_wl = ColorRect.new()
	_wl.color = Color("#282838")
	_wl.set_position(Vector2(-38, 30)); _wl.set_size(Vector2(18, 18))
	add_child(_wl)
	_wr = ColorRect.new()
	_wr.color = Color("#282838")
	_wr.set_position(Vector2(20, 30)); _wr.set_size(Vector2(18, 18))
	add_child(_wr)

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
	var col: Color = Color("#FFD93D") if is_head else \
		(Color("#FF9F43") if is_tail else \
		(Color("#6BCB77") if selected else Color("#4D96FF")))
	_body.color = col.darkened(0.65)
	var nid: int   = data.get("id", 0) as int
	var key: String = ICONS[nid % ICONS.size()] as String
	var tex: Texture2D = AssetMap.codemon(key)
	if tex: _sprite.texture = tex
	_value.text = data.get("label", "?") as String
	_value.add_theme_color_override("font_color", col)
	_type.text  = "HEAD" if is_head else ("TAIL" if is_tail else "node[%d]" % nid)
	_type.add_theme_color_override("font_color", col.darkened(0.1))
	_wl.color = col.darkened(0.8); _wr.color = col.darkened(0.8)

func _process(delta: float) -> void:
	if selected:
		_wobble += delta * 4.0
		position.y = sin(_wobble) * 5.0

func _on_input(_vp: Node, ev: InputEvent, _i: int) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("clicked", data.get("id", -1) as int)
