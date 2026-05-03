extends Node2D
## RuneNode — a magic spell stone pushed onto the stack.
## Visual: stone slab with glowing elemental symbol on top.
## Stacks visually bottom-to-top. TOP stone is bright and pulsing.
## Interaction: click TOP stone OR press SPACE to pop.

signal clicked(rune_id: int)

# Element symbol paths matching the uploaded elementsymbols.png
# Mapped to rune names semantically
const ELEM_SYMBOLS: Dictionary = {
	"Fire":    "res://assets/game/stack/elem_fire.png",
	"Ice":     "res://assets/game/stack/elem_ice.png",
	"Thunder": "res://assets/game/stack/elem_lightning.png",
	"Earth":   "res://assets/game/stack/elem_earth.png",
	"Shadow":  "res://assets/game/stack/elem_dark.png",
	"Light":   "res://assets/game/stack/elem_light.png",
	"Wind":    "res://assets/game/stack/elem_wind.png",
	"Void":    "res://assets/game/stack/elem_water.png",
}
const RUNE_COLORS: Dictionary = {
	"Fire":    Color("#FF6B6B"), "Ice":     Color("#88CCFF"),
	"Thunder": Color("#FFD93D"), "Earth":   Color("#6BCB77"),
	"Shadow":  Color("#C77DFF"), "Light":   Color("#FFE066"),
	"Wind":    Color("#88DDFF"), "Void":    Color("#6688AA"),
}

var data:       Dictionary = {}
var is_top:     bool       = false
var depth_idx:  int        = 0
var _target_y:  float      = 0.0
var _move_speed:float      = 220.0
var _pulse:     float      = 0.0

# Visuals — stone slab with element symbol
var _stone_slab:  ColorRect   # the stone background
var _stone_edge:  ColorRect   # darker edge for depth illusion
var _elem_sprite: Sprite2D    # elemental symbol on top
var _glow:        ColorRect   # colored glow when on top
var _name_lbl:    Label
var _depth_lbl:   Label
var _click_hint:  Label       # shows "CLICK!" or "SPACE" when on top

func _ready() -> void:
	_build_nodes()

func _build_nodes() -> void:
	# Stone slab base (wider than tall, like a real stone tablet)
	_stone_slab = ColorRect.new()
	_stone_slab.color = Color("#4a4550")
	_stone_slab.set_position(Vector2(-44, -28)); _stone_slab.set_size(Vector2(88, 56))
	add_child(_stone_slab)

	# Stone edge (bottom shadow for 3D effect)
	_stone_edge = ColorRect.new()
	_stone_edge.color = Color("#2a2530")
	_stone_edge.set_position(Vector2(-44, 26)); _stone_edge.set_size(Vector2(88, 10))
	add_child(_stone_edge)

	# Colored glow overlay (visible when top)
	_glow = ColorRect.new()
	_glow.color = Color(1,1,1,0)
	_glow.set_position(Vector2(-44, -28)); _glow.set_size(Vector2(88, 56))
	add_child(_glow)

	# Element symbol sprite
	_elem_sprite = Sprite2D.new()
	_elem_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_elem_sprite.scale = Vector2(5.0, 5.0)  # 96x72 → scaled for visibility
	_elem_sprite.position = Vector2(-12, -8)
	add_child(_elem_sprite)

	# Rune name
	_name_lbl = Label.new()
	_name_lbl.set_position(Vector2(-44, -50)); _name_lbl.set_size(Vector2(88, 18))
	_name_lbl.add_theme_font_size_override("font_size", 12)
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_name_lbl)

	# Depth indicator
	_depth_lbl = Label.new()
	_depth_lbl.set_position(Vector2(-44, 38)); _depth_lbl.set_size(Vector2(88, 14))
	_depth_lbl.add_theme_font_size_override("font_size", 9)
	_depth_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_depth_lbl)

	# Click hint (only shows when TOP)
	_click_hint = Label.new()
	_click_hint.text = "▼ CLICK or SPACE"
	_click_hint.set_position(Vector2(-60, -72)); _click_hint.set_size(Vector2(120, 16))
	_click_hint.add_theme_font_size_override("font_size", 10)
	_click_hint.add_theme_color_override("font_color", Color("#FFD93D"))
	_click_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_click_hint.visible = false
	add_child(_click_hint)

	# Drop shadow
	var shadow := ColorRect.new()
	shadow.color = Color(0,0,0,0.3)
	shadow.set_position(Vector2(-40, 36)); shadow.set_size(Vector2(80, 10))
	add_child(shadow)

	# Click collision
	var area := Area2D.new()
	var sh   := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(88, 66); sh.shape = rect
	area.add_child(sh)
	area.input_event.connect(_on_input)
	add_child(area)

func setup(rune_data: Dictionary, _sy: float = 0.0, _ty: float = 0.0) -> void:
	data = rune_data; _refresh()

func set_target(ty: float, di: int, _total: int, top_flag: bool) -> void:
	_target_y = ty; depth_idx = di; is_top = top_flag; _refresh()

func pop_anim() -> void:
	var tw := create_tween()
	tw.tween_property(self,"position:y", position.y - 80, 0.18).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self,"modulate:a", 0.0, 0.15)
	tw.tween_callback(queue_free)

func _refresh() -> void:
	if not is_instance_valid(_stone_slab): return
	var rname: String = data.get("name","Fire") as String
	var col: Color    = RUNE_COLORS.get(rname, Color("#C77DFF")) as Color
	var path: String  = ELEM_SYMBOLS.get(rname, "") as String

	# Load element symbol
	if path != "" and ResourceLoader.exists(path):
		_elem_sprite.texture = load(path) as Texture2D

	if is_top:
		_stone_slab.color = Color("#6a6575")     # lighter stone when top
		_glow.color       = Color(col.r, col.g, col.b, 0.22)
		_click_hint.visible = true
		_name_lbl.add_theme_color_override("font_color", col.lightened(0.3))
		_depth_lbl.text = "▲ TOP"
		_depth_lbl.add_theme_color_override("font_color", col)
		_elem_sprite.modulate = Color.WHITE
	else:
		_stone_slab.color = Color("#3a3540")     # darker when buried
		_glow.color       = Color(0,0,0,0)
		_click_hint.visible = false
		_name_lbl.add_theme_color_override("font_color", col.darkened(0.3))
		_depth_lbl.text = "d%d" % depth_idx
		_depth_lbl.add_theme_color_override("font_color", Color(0.4,0.4,0.5))
		_elem_sprite.modulate = Color(0.6, 0.6, 0.65)  # dimmed when buried

	_name_lbl.text = rname

func _process(delta: float) -> void:
	if abs(position.y - _target_y) > 2.0:
		position.y = move_toward(position.y, _target_y, _move_speed * delta)

	if is_top and is_instance_valid(_stone_slab):
		_pulse += delta * 2.0
		# Pulse the glow
		var alpha: float = 0.15 + sin(_pulse) * 0.10
		_glow.color.a = alpha
		# Slight scale pulse
		var s: float = 1.0 + sin(_pulse * 1.5) * 0.025
		scale = Vector2(s, s)
	else:
		scale = Vector2.ONE

func _on_input(_vp: Node, ev: InputEvent, _i: int) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("clicked", data.get("id",-1) as int)
