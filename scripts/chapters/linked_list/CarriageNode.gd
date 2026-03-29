extends Node2D

# ═══════════════════════════════════════════════════
# CarriageNode.gd — Chain Train
# Visual train carriage node with codemon sprite inside.
# ═══════════════════════════════════════════════════

signal clicked(node_id: int)

const CARRIAGE_ICONS: Array = ["array","int","for","while","if","string","bool","char"]
const W: float = 100.0
const H: float = 70.0

var data:     Dictionary = {}
var is_head:  bool       = false
var is_tail:  bool       = false
var selected: bool       = false
var _sprite:  Sprite2D
var _wobble:  float      = 0.0

func _ready() -> void:
	_build()
	_setup_area()

func setup(node_data: Dictionary, head: bool = false, tail: bool = false) -> void:
	data    = node_data
	is_head = head
	is_tail = tail
	_update_sprite()
	queue_redraw()

func _build() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(1.6, 1.6)
	_sprite.position = Vector2(-W/2 + 24, 0)
	add_child(_sprite)

func _update_sprite() -> void:
	var node_id: int = data.get("id", 0) as int
	var key: String  = CARRIAGE_ICONS[node_id % CARRIAGE_ICONS.size()] as String
	var tex: Texture2D = AssetMap.codemon(key)
	if tex: _sprite.texture = tex

func _setup_area() -> void:
	var area := Area2D.new()
	var col  := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(W, H)
	col.shape  = rect
	area.input_event.connect(func(_v, ev, _i):
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				emit_signal("clicked", data.get("id", -1) as int)
	)
	area.add_child(col)
	add_child(area)

func _process(delta: float) -> void:
	if selected:
		_wobble += delta * 4.0
		position.y = sin(_wobble) * 5.0
	queue_redraw()

func _draw() -> void:
	var col: Color = Color("#FFD93D") if is_head else \
		(Color("#FF9F43") if is_tail else Color("#2a2a3e"))
	if selected: col = Color("#6BCB77")

	# Carriage body
	draw_rect(Rect2(-W/2, -H/2, W, H), col.darkened(0.6))
	draw_rect(Rect2(-W/2, -H/2, W, H), col, false, 2.0)

	# Wheels
	draw_circle(Vector2(-W/2 + 18, H/2 - 2), 8, Color("#333355"))
	draw_circle(Vector2(W/2 - 18, H/2 - 2), 8, Color("#333355"))
	draw_circle(Vector2(-W/2 + 18, H/2 - 2), 5, Color("#555577"))
	draw_circle(Vector2(W/2 - 18, H/2 - 2), 5, Color("#555577"))

	# Label
	var lbl: String = data.get("label", "?") as String
	draw_string(ThemeDB.fallback_font, Vector2(10, 8), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, col)

	# Head / Tail tag
	if is_head:
		draw_string(ThemeDB.fallback_font, Vector2(-W/2 + 4, -H/2 - 14), "HEAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
	if is_tail:
		draw_string(ThemeDB.fallback_font, Vector2(-W/2 + 4, -H/2 - 14), "TAIL", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)

	# Next pointer arrow (drawn by Game.gd, but show null indicator)
	if data.get("next", -1) as int == -1:
		draw_string(ThemeDB.fallback_font, Vector2(W/2 - 30, 4), "→null", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#FF6B6B"))
