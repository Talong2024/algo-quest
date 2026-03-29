extends Node2D

# ═══════════════════════════════════════════════════
# CitizenNode.gd — Kingdom Queue
# Visual representation of a citizen in the queue.
# Uses codemon sprites for character visuals.
# ═══════════════════════════════════════════════════

signal clicked(citizen_id: int)

const CITIZEN_SPRITES: Dictionary = {
	"normal":   "int",
	"vip":      "for",
	"merchant": "string",
	"elderly":  "bool",
}

const CITIZEN_COLORS: Dictionary = {
	"normal":   Color("#4D96FF"),
	"merchant": Color("#6BCB77"),
	"vip":      Color("#FFD93D"),
	"elderly":  Color("#C77DFF"),
}

var data:      Dictionary = {}
var queue_pos: int        = -1    # -1 = not in queue
var is_front:  bool       = false
var _sprite:   Sprite2D
var _glow:     float      = 0.0
var _bounce:   float      = 0.0

func _ready() -> void:
	_build_visuals()
	_setup_input()

func setup(citizen: Dictionary, spawn_y: float = 0.0, target_y: float = 0.0) -> void:
	data     = citizen
	is_front = false  # updated by Game.gd via set_front()
	_update_visuals()

func set_front(v: bool) -> void:
	is_front = v
	_update_visuals()
	queue_redraw()

func _build_visuals() -> void:
	# Background circle
	var bg := ColorRect.new()
	bg.color = Color("#1a1a2e")
	bg.set_position(Vector2(-44, -50))
	bg.set_size(Vector2(88, 100))
	add_child(bg)

	# Codemon sprite
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(2.2, 2.2)
	_sprite.position = Vector2(0, -14)
	add_child(_sprite)

	# Clickable area
	var area := Area2D.new()
	var col  := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(88, 100)
	col.shape  = rect
	area.add_child(col)
	area.input_event.connect(func(_v, event, _i):
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				emit_signal("clicked", data.get("id", -1) as int)
	)
	add_child(area)

func _update_visuals() -> void:
	if not _sprite: return
	var ctype: String = data.get("type", "normal") as String
	var key: String   = CITIZEN_SPRITES.get(ctype, "int") as String
	var tex: Texture2D = AssetMap.codemon(key)
	if tex: _sprite.texture = tex

func _process(delta: float) -> void:
	_bounce += delta * 2.0
	if is_front:
		_sprite.position.y = -14.0 + sin(_bounce) * 4.0
	queue_redraw()

func _draw() -> void:
	var ctype: String = data.get("type", "normal") as String
	var col: Color    = CITIZEN_COLORS.get(ctype, Color("#4D96FF")) as Color

	# Border glow for front
	if is_front:
		draw_arc(Vector2(0, -14), 36, 0, TAU, 32, col, 2.5)
		draw_string(ThemeDB.fallback_font, Vector2(-24, 46), "SERVE ME!", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
	else:
		draw_arc(Vector2(0, -14), 36, 0, TAU, 32, col.darkened(0.5), 1.5)

	# Name label
	var citizen_name: String = data.get("name", "?") as String
	draw_string(ThemeDB.fallback_font, Vector2(-32, 28), citizen_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e8e8f0"))

	# Type badge
	draw_string(ThemeDB.fallback_font, Vector2(-24, 40), "[%s]" % ctype, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)

	# Queue position indicator
	if queue_pos >= 0:
		var pos_col: Color = Color("#6BCB77") if queue_pos == 0 else Color("#555577")
		draw_string(ThemeDB.fallback_font, Vector2(-8, -46), "#%d" % (queue_pos + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, pos_col)

func _setup_input() -> void:
	pass  # handled via Area2D above
