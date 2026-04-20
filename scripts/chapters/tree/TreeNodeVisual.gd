extends Node2D
## TreeNodeVisual — a BST/AVL/Heap node shown as a glowing magic orb.
## Orb color changes per algorithm state. Orb spins when active.
## Uses rotating_orbs spritesheet (4cols × 8rows at 32x32).

signal clicked(node_id: int)

const ORB_SHEET: String = "res://assets/game/tree/orbs_sheet.png"
const TILE: int = 32

# Map state → (col, row) in the orb sheet
# Sheet: 4 cols × 8 rows. Each col = different color family.
const STATE_ORB: Dictionary = {
	"normal":     Vector2i(0, 0),  # blue-grey
	"searching":  Vector2i(1, 0),  # gold/yellow
	"found":      Vector2i(2, 0),  # green
	"inserted":   Vector2i(3, 0),  # bright blue
	"deleted":    Vector2i(0, 2),  # dark/grey
	"unbalanced": Vector2i(1, 1),  # orange
	"path":       Vector2i(2, 1),  # teal
	"heap_max":   Vector2i(3, 1),  # purple
}
const STATE_COLORS: Dictionary = {
	"normal":     Color("#4a5a8a"),
	"searching":  Color("#FFD93D"),
	"found":      Color("#6BCB77"),
	"inserted":   Color("#4D96FF"),
	"deleted":    Color("#667788"),
	"unbalanced": Color("#FF9F43"),
	"path":       Color("#44DDCC"),
	"heap_max":   Color("#C77DFF"),
}

var data:      Dictionary = {}
var state:     String     = "normal"
var _spin_frame: int      = 0
var _spin_timer: float    = 0.0
const SPIN_FPS: float     = 8.0  # frames per second for spin
const SPIN_FRAMES: int    = 8    # 8 rows = 8 spin frames per col

var _orb:       Sprite2D    # the orb sprite
var _glow_ring: ColorRect   # colored ring around orb
var _val_lbl:   Label       # node value label
var _bal_lbl:   Label       # balance factor (AVL)
var _state_lbl: Label       # state indicator above orb

func _ready() -> void:
	_build_nodes()

func _build_nodes() -> void:
	# Outer glow ring
	_glow_ring = ColorRect.new()
	_glow_ring.set_position(Vector2(-24, -24))
	_glow_ring.set_size(Vector2(48, 48))
	add_child(_glow_ring)

	# Orb sprite — 32x32 tile from sheet, scaled up
	_orb = Sprite2D.new()
	_orb.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_orb.region_enabled = true
	_orb.region_rect    = Rect2(0, 0, TILE, TILE)
	_orb.scale          = Vector2(3.0, 3.0)
	if ResourceLoader.exists(ORB_SHEET):
		_orb.texture = load(ORB_SHEET) as Texture2D
	add_child(_orb)

	# Value label — big number in centre
	_val_lbl = Label.new()
	_val_lbl.set_position(Vector2(-16, 46))
	_val_lbl.set_size(Vector2(48, 20))
	_val_lbl.add_theme_font_size_override("font_size", 15)
	_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_val_lbl)

	# Balance factor badge (top-right corner, AVL only)
	_bal_lbl = Label.new()
	_bal_lbl.set_position(Vector2(28, -44))
	_bal_lbl.set_size(Vector2(28, 16))
	_bal_lbl.add_theme_font_size_override("font_size", 9)
	add_child(_bal_lbl)

	# State label above orb
	_state_lbl = Label.new()
	_state_lbl.set_position(Vector2(-36, -58))
	_state_lbl.set_size(Vector2(72, 16))
	_state_lbl.add_theme_font_size_override("font_size", 9)
	_state_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_state_lbl)

	# Click area
	var area := Area2D.new()
	var sh   := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 28.0; sh.shape = circ
	area.add_child(sh)
	area.input_event.connect(_on_input)
	add_child(area)

	_refresh()

func _refresh() -> void:
	if not is_instance_valid(_orb): return
	var col: Color     = STATE_COLORS.get(state, Color("#4a5a8a")) as Color
	var orb_pos: Vector2i = STATE_ORB.get(state, Vector2i(0,0)) as Vector2i

	# Set orb region to correct column (color) at current spin frame
	var col_px: int   = orb_pos.x * TILE
	var row_px: int   = _spin_frame * TILE
	_orb.region_rect  = Rect2(col_px, row_px, TILE, TILE)

	# Glow ring
	_glow_ring.color = Color(col.r, col.g, col.b, 0.3)

	# Labels
	_val_lbl.text = data.get("label", str(data.get("value", "?"))) as String
	_val_lbl.add_theme_color_override("font_color", col.lightened(0.2))

	var bf: int = data.get("balance_factor", 999) as int
	if bf != 999:
		_bal_lbl.text = "%+d" % bf
		_bal_lbl.add_theme_color_override("font_color",
			Color("#FF6B6B") if abs(bf) > 1 else Color("#6BCB77"))
	else:
		_bal_lbl.text = ""

	_state_lbl.text = state if state != "normal" else ""
	_state_lbl.add_theme_color_override("font_color", col.lightened(0.3))

func set_state(new_state: String) -> void:
	state = new_state
	_refresh()

func _process(delta: float) -> void:
	# Spin the orb — active states spin faster
	var fps: float = SPIN_FPS * (2.0 if state != "normal" else 1.0)
	_spin_timer += delta
	if _spin_timer >= 1.0 / fps:
		_spin_timer -= 1.0 / fps
		_spin_frame = (_spin_frame + 1) % SPIN_FRAMES
		_refresh()

func _on_input(_vp: Node, ev: InputEvent, _i: int) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("clicked", data.get("id", -1) as int)
