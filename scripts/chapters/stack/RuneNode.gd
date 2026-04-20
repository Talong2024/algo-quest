extends Node2D
## RuneNode — a magic rune stone pushed onto the stack.
## Uses actual rune stone sprites from runetilemap.png.
## Rune stones stack visually — each sits on top of the previous.

signal clicked(rune_id: int)

# Maps each rune name to its sprite file
const RUNE_SPRITES: Dictionary = {
	"Fire":    "res://assets/game/stack/rune_fire.png",
	"Ice":     "res://assets/game/stack/rune_ice.png",
	"Thunder": "res://assets/game/stack/rune_thunder.png",
	"Earth":   "res://assets/game/stack/rune_earth.png",
	"Shadow":  "res://assets/game/stack/rune_shadow.png",
	"Light":   "res://assets/game/stack/rune_light.png",
	"Wind":    "res://assets/game/stack/rune_wind.png",
	"Void":    "res://assets/game/stack/rune_void.png",
}
const RUNE_COLORS: Dictionary = {
	"Fire":    Color("#FF6B6B"), "Ice":     Color("#4D96FF"),
	"Thunder": Color("#FFD93D"), "Earth":   Color("#6BCB77"),
	"Shadow":  Color("#C77DFF"), "Light":   Color("#FFE066"),
	"Wind":    Color("#88DDFF"), "Void":    Color("#aaaacc"),
}

var data:       Dictionary = {}
var is_top:     bool       = false
var depth_idx:  int        = 0
var _target_y:  float      = 0.0
var _move_speed:float      = 200.0
var _pulse:     float      = 0.0

# Visual nodes
var _shadow:      ColorRect   # drop shadow beneath stone
var _stone:       Sprite2D    # the rune stone sprite
var _glow:        ColorRect   # color glow overlay when on top
var _name_lbl:    Label       # rune name
var _depth_lbl:   Label       # TOP / depth index

func _ready() -> void:
	_build_nodes()

func _build_nodes() -> void:
	# Drop shadow — gives sense of resting on a surface
	_shadow = ColorRect.new()
	_shadow.color = Color(0, 0, 0, 0.35)
	_shadow.set_position(Vector2(-38, 30))
	_shadow.set_size(Vector2(76, 10))
	add_child(_shadow)

	# Glow background (colored rect behind stone, for top-of-stack highlight)
	_glow = ColorRect.new()
	_glow.set_position(Vector2(-40, -40))
	_glow.set_size(Vector2(80, 80))
	_glow.color = Color(1, 1, 1, 0)
	add_child(_glow)

	# The rune stone sprite — 32x32 source, scaled up
	_stone = Sprite2D.new()
	_stone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_stone.scale = Vector2(4.0, 4.0)
	add_child(_stone)

	# Rune name above the stone
	_name_lbl = Label.new()
	_name_lbl.set_position(Vector2(-40, -62))
	_name_lbl.set_size(Vector2(80, 18))
	_name_lbl.add_theme_font_size_override("font_size", 12)
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_name_lbl)

	# Depth label below
	_depth_lbl = Label.new()
	_depth_lbl.set_position(Vector2(-40, 42))
	_depth_lbl.set_size(Vector2(80, 14))
	_depth_lbl.add_theme_font_size_override("font_size", 9)
	_depth_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_depth_lbl)

	# Click area matching stone size
	var area := Area2D.new()
	var sh   := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(80, 80); sh.shape = rect
	area.add_child(sh)
	area.input_event.connect(_on_input)
	add_child(area)

func setup(rune_data: Dictionary, _sy: float = 0.0, _ty: float = 0.0) -> void:
	data = rune_data
	_refresh()

func set_target(ty: float, di: int, total: int, top_flag: bool) -> void:
	_target_y = ty
	depth_idx  = di
	is_top     = top_flag
	_refresh()

func pop_anim() -> void:
	var tw := create_tween()
	# Stone lifts up then disappears
	tw.tween_property(self, "position:y", position.y - 60, 0.15).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "modulate:a", 0.0, 0.12)
	tw.tween_callback(queue_free)

func _refresh() -> void:
	if not is_instance_valid(_stone): return
	var rname: String = data.get("name", "Fire") as String
	var col:   Color  = RUNE_COLORS.get(rname, Color("#C77DFF")) as Color
	var path:  String = RUNE_SPRITES.get(rname, "") as String

	# Load rune stone texture
	if path != "" and ResourceLoader.exists(path):
		_stone.texture = load(path) as Texture2D

	# Top-of-stack: brighter, glowing, slightly larger pulse
	if is_top:
		_stone.modulate = Color(1.4, 1.4, 1.4)  # brighten top stone
		_glow.color = Color(col.r, col.g, col.b, 0.25)
		_name_lbl.add_theme_color_override("font_color", col.lightened(0.3))
		_depth_lbl.text = "▲ TOP"
		_depth_lbl.add_theme_color_override("font_color", col)
	else:
		_stone.modulate = Color(0.75, 0.75, 0.80)  # buried stones dimmer
		_glow.color = Color(0, 0, 0, 0)
		_name_lbl.add_theme_color_override("font_color", col.darkened(0.2))
		_depth_lbl.text = "d%d" % depth_idx
		_depth_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))

	_name_lbl.text = rname

func _process(delta: float) -> void:
	# Smooth movement toward target Y
	if abs(position.y - _target_y) > 2.0:
		position.y = move_toward(position.y, _target_y, _move_speed * delta)

	# Top stone pulses scale slightly
	if is_top and is_instance_valid(_stone):
		_pulse += delta * 2.5
		var s: float = 4.0 + sin(_pulse) * 0.15
		_stone.scale = Vector2(s, s)
	elif is_instance_valid(_stone):
		_stone.scale = Vector2(4.0, 4.0)

func _on_input(_vp: Node, ev: InputEvent, _i: int) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("clicked", data.get("id", -1) as int)
