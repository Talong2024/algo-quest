extends Node2D
# #REGION:CHARACTERS — Stack chapter rune node
# Built in _ready() (no @onready) — loaded via script not tscn.

signal clicked(rune_id: int)

const RUNE_SPRITES: Dictionary = {
	"Fire":"plus","Ice":"minus","Thunder":"multiply",
	"Earth":"divide","Shadow":"modulo","Light":"equal",
	"Wind":"if","Void":"while","default":"for",
}
const RUNE_COLORS: Dictionary = {
	"Fire":Color("#FF6B6B"),"Ice":Color("#4D96FF"),
	"Thunder":Color("#FFD93D"),"Earth":Color("#6BCB77"),
	"Shadow":Color("#C77DFF"),"Light":Color("#FFE066"),
	"Wind":Color("#88DDFF"),"Void":Color("#888899"),
}

var data:        Dictionary = {}
var is_top:      bool       = false
var stack_depth: int        = 0
var depth_idx:   int        = 0
var _target_y:   float      = 0.0
var _move_speed: float      = 200.0
var _pulse:      float      = 0.0

var _glow:        ColorRect
var _sprite:      Sprite2D
var _depth_label: Label

func _ready() -> void:
	_build_nodes()

# #REGION:CHARACTERS — Build visual children
func _build_nodes() -> void:
	_glow = ColorRect.new()
	_glow.set_position(Vector2(-22, -22)); _glow.set_size(Vector2(44, 44))
	add_child(_glow)

	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(3.8, 3.8)
	add_child(_sprite)

	_depth_label = Label.new()
	_depth_label.set_position(Vector2(-18, 26))
	_depth_label.set_size(Vector2(36, 14))
	_depth_label.add_theme_font_size_override("font_size", 9)
	add_child(_depth_label)

	var area := Area2D.new()
	var sh   := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 28.0; sh.shape = circ
	area.add_child(sh)
	area.input_event.connect(_on_input)
	add_child(area)

func setup(rune_data: Dictionary, _sy: float = 0.0, _ty: float = 0.0) -> void:
	data = rune_data
	_refresh()

func update_stack_state(top: bool, depth: int, idx: int) -> void:
	is_top = top; stack_depth = depth; depth_idx = idx
	_refresh()

func set_target(ty: float, di: int, total: int, top_flag: bool) -> void:
	_target_y = ty; depth_idx = di; stack_depth = total; is_top = top_flag
	_refresh()

func pop_anim() -> void:
	# #REGION:ANIMATION
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.4, 1.4), 0.08).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2(0.0, 0.0), 0.18).set_trans(Tween.TRANS_EXPO)
	tw.tween_callback(queue_free)

func _refresh() -> void:
	if not is_instance_valid(_sprite): return
	var rname: String  = data.get("name", "Fire") as String
	var col:   Color   = RUNE_COLORS.get(rname, Color("#C77DFF")) as Color
	var key:   String  = RUNE_SPRITES.get(rname, "for") as String
	var tex: Texture2D = AssetMap.codemon(key)
	if tex: _sprite.texture = tex
	_sprite.modulate = Color.WHITE if not is_top else col.lightened(0.4)
	_glow.color = Color(col.r, col.g, col.b, 0.3 if is_top else 0.12)
	_depth_label.text = "TOP" if is_top else "d%d" % depth_idx
	_depth_label.add_theme_color_override("font_color", col)

func _process(delta: float) -> void:
	if abs(position.y - _target_y) > 2.0:
		position.y = move_toward(position.y, _target_y, _move_speed * delta)
	_pulse += delta * 3.0
	if is_top and is_instance_valid(_sprite):
		_sprite.scale = Vector2(
			3.8 + sin(_pulse) * 0.12,
			3.8 + sin(_pulse) * 0.12)

func _on_input(_vp: Node, ev: InputEvent, _i: int) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("clicked", data.get("id", -1) as int)
