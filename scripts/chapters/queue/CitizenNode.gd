class_name CitizenNode
extends Node2D

signal clicked(citizen_id: int)

@onready var _click_area: Area2D = $ClickArea
@onready var _name_lbl:   Label  = $NameLabel
@onready var _badge:      Label  = $TypeBadge

var data:           Dictionary = {}
var _target_x:      float      = 0.0
var _move_speed:    float      = 160.0
var _pending_bubble: bool      = false

# Visual nodes (built in code)
var _char:         Sprite2D    # CGabriel character sprite
var _char_sheet:   Texture2D   # shared ref
var _anim_frame:   int         = 0
var _anim_timer:   float       = 0.0
const ANIM_FPS:    float       = 8.0
const CHAR_TILE:   int         = 24   # CGabriel 24x24
const CHAR_SCALE:  float       = 3.0

# Walk direction: positive = moving right, negative = moving left
var _moving_left:  bool        = true

var _speech_bubble: Control
var _speech_lbl:    Label
var _bubble_anim:   float      = 0.0
var _anger_lbl:     Label
var _anger_timer:   float      = 0.0

const TYPE_COLORS: Dictionary = {
	"normal":   Color("#4D96FF"), "vip":      Color("#FFD93D"),
	"merchant": Color("#6BCB77"), "elderly":  Color("#C77DFF"),
	"guard":    Color("#FF6B6B"), "skeleton": Color("#44FF88"),
	"orc":      Color("#FF4400"),
}
const CITIZEN_REQUESTS: Dictionary = {
	"normal":   ["Please!","Let me in!","Waiting..."],
	"vip":      ["I am VIP!","Royalty first!"],
	"merchant": ["Trade permit!","Official business!"],
	"elderly":  ["Been waiting...","Kind soul?"],
	"skeleton": ["...","Rattle..."],
	"orc":      ["GRRRR","RAWR"],
}
# CGabriel row assignments (row index in 24px sheet)
const TYPE_CHAR_ROW: Dictionary = {
	"normal": 0, "vip": 2, "merchant": 4, "elderly": 6,
	"guard": 1, "skeleton": 8, "orc": 10,
}

func _ready() -> void:
	_build_char()
	_build_speech_bubble()
	_build_anger_label()
	if _click_area:
		_click_area.input_event.connect(_on_area_input)
	tree_entered.connect(_on_tree_entered)

func _build_char() -> void:
	var sheet_path: String = "res://assets/game/characters/chars_sheet.png"
	if ResourceLoader.exists(sheet_path):
		_char_sheet = load(sheet_path) as Texture2D
	_char = Sprite2D.new()
	_char.texture        = _char_sheet
	_char.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_char.centered       = false
	_char.region_enabled = true
	_char.region_rect    = Rect2(0, 0, CHAR_TILE, CHAR_TILE)
	_char.scale          = Vector2(CHAR_SCALE, CHAR_SCALE)
	_char.position       = Vector2(-CHAR_TILE * CHAR_SCALE * 0.5, -CHAR_TILE * CHAR_SCALE)
	add_child(_char)

func _build_speech_bubble() -> void:
	_speech_bubble = Control.new()
	_speech_bubble.set_position(Vector2(-55, -CHAR_TILE * CHAR_SCALE - 38))
	_speech_bubble.set_size(Vector2(110, 28))
	_speech_bubble.visible = false
	add_child(_speech_bubble)
	var bg := ColorRect.new()
	bg.color = Color(0.95, 0.95, 0.85, 0.92)
	bg.set_size(Vector2(110, 28)); _speech_bubble.add_child(bg)
	var tail := ColorRect.new()
	tail.color = Color(0.95, 0.95, 0.85, 0.92)
	tail.set_position(Vector2(46, 26)); tail.set_size(Vector2(14, 7))
	_speech_bubble.add_child(tail)
	_speech_lbl = Label.new()
	_speech_lbl.set_position(Vector2(4, 3)); _speech_lbl.set_size(Vector2(102, 22))
	_speech_lbl.add_theme_font_size_override("font_size", 10)
	_speech_lbl.add_theme_color_override("font_color", Color("#222222"))
	_speech_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speech_bubble.add_child(_speech_lbl)

func _build_anger_label() -> void:
	_anger_lbl = Label.new()
	_anger_lbl.add_theme_font_size_override("font_size", 11)
	_anger_lbl.add_theme_color_override("font_color", Color("#FF6B6B"))
	_anger_lbl.position = Vector2(-48, -CHAR_TILE * CHAR_SCALE - 60)
	_anger_lbl.visible  = false
	add_child(_anger_lbl)

func _on_tree_entered() -> void:
	if _pending_bubble:
		_pending_bubble = false
		get_tree().create_timer(0.6).timeout.connect(_show_speech_bubble, CONNECT_ONE_SHOT)
	_apply_appearance()

func _apply_appearance() -> void:
	if not is_instance_valid(_char) or not _char_sheet: return
	var ctype: String = str(data.get("type","normal"))
	var row: int = TYPE_CHAR_ROW.get(ctype, 0) as int
	# Use walk frame 0 initially
	_char.region_rect = Rect2(0, row * CHAR_TILE, CHAR_TILE, CHAR_TILE)
	# Tint enemies slightly
	if ctype in ["skeleton","orc"]:
		_char.modulate = Color(0.8, 1.0, 0.8) if ctype == "skeleton" else Color(1.0, 0.7, 0.5)

func setup(citizen: Dictionary, _sx: float = 0.0, tx: float = 0.0) -> void:
	data      = citizen
	_target_x = tx
	_pending_bubble = true
	if is_instance_valid(_name_lbl):
		_name_lbl.text = citizen.get("name","?") as String
		var col: Color = TYPE_COLORS.get(str(citizen.get("type","normal")), Color("#4D96FF")) as Color
		_name_lbl.add_theme_color_override("font_color", col)
	if is_instance_valid(_badge):
		_badge.text = citizen.get("label","?") as String

func set_target_x(x: float) -> void: _target_x = x
func set_target_y(_y: float) -> void: pass  # compatibility stub

func has_arrived() -> bool:
	return abs(position.x - _target_x) < 10.0

func _show_speech_bubble() -> void:
	if not is_instance_valid(_speech_bubble): return
	var ctype: String = str(data.get("type","normal"))
	var reqs: Array   = CITIZEN_REQUESTS.get(ctype, ["..."])
	_speech_lbl.text  = reqs[randi() % reqs.size()]
	_speech_bubble.visible = true

func show_anger(msg: String) -> void:
	_anger_lbl.text    = "💢 " + msg
	_anger_lbl.visible = true
	_anger_timer       = 2.0
	_speech_bubble.visible = false

func play_slash_anim() -> void:
	_anger_lbl.text    = "⚔️ REPELLED!"
	_anger_lbl.visible = true
	_anger_timer       = 1.5
	_speech_bubble.visible = false
	var tw := create_tween()
	tw.tween_property(self,"modulate",Color("#FF4400"),0.1)
	tw.tween_property(self,"modulate",Color.WHITE,0.2)
	tw.tween_property(self,"scale",Vector2.ZERO,0.25).set_trans(Tween.TRANS_EXPO)
	tw.tween_callback(queue_free)

func play_serve_anim() -> void:
	_speech_bubble.visible = false
	var tw := create_tween()
	# Walk into the gate (leftward)
	tw.tween_property(self,"position:x", position.x - 120.0, 0.35).set_trans(Tween.TRANS_EXPO)
	tw.parallel().tween_property(self,"modulate:a",0.0,0.30)
	tw.tween_callback(queue_free)

func update_patience(ratio: float) -> void:
	pass  # patience bar not shown in side-scroller (keeps it clean)

func _process(delta: float) -> void:
	# Horizontal movement
	var dx: float = _target_x - position.x
	if abs(dx) > 2.0:
		position.x = move_toward(position.x, _target_x, _move_speed * delta)
		_moving_left = dx < 0
		_animate_walk(delta)
	else:
		_animate_idle(delta)

	# Anger timer
	if _anger_timer > 0.0:
		_anger_timer -= delta
		if _anger_timer <= 0.0: _anger_lbl.visible = false

	# Speech bubble bob
	if is_instance_valid(_speech_bubble) and _speech_bubble.visible:
		_bubble_anim += delta * 2.2
		_speech_bubble.position.y = (-CHAR_TILE * CHAR_SCALE - 38.0) + sin(_bubble_anim) * 3.0

func _animate_walk(delta: float) -> void:
	if not is_instance_valid(_char) or not _char_sheet: return
	_anim_timer += delta
	if _anim_timer >= 1.0 / ANIM_FPS:
		_anim_timer -= 1.0 / ANIM_FPS
		_anim_frame = (_anim_frame + 1) % 8  # walk cycle: 8 frames
	var ctype: String = str(data.get("type","normal"))
	var row: int = TYPE_CHAR_ROW.get(ctype, 0) as int
	_char.region_rect = Rect2(_anim_frame * CHAR_TILE, row * CHAR_TILE, CHAR_TILE, CHAR_TILE)
	# Flip sprite based on direction
	_char.scale.x = -CHAR_SCALE if _moving_left else CHAR_SCALE
	# Adjust position offset for flip
	_char.position.x = CHAR_TILE * CHAR_SCALE * 0.5 if _moving_left else -CHAR_TILE * CHAR_SCALE * 0.5

func _animate_idle(delta: float) -> void:
	if not is_instance_valid(_char): return
	_anim_timer += delta
	if _anim_timer >= 0.5:  # idle: slow blink/shift
		_anim_timer -= 0.5
		_anim_frame = (_anim_frame + 1) % 2
	var ctype: String = str(data.get("type","normal"))
	var row: int = TYPE_CHAR_ROW.get(ctype, 0) as int
	_char.region_rect = Rect2(_anim_frame * CHAR_TILE, row * CHAR_TILE, CHAR_TILE, CHAR_TILE)
	# Face left (toward gate) when idle
	_char.scale.x = -CHAR_SCALE

func _on_area_input(_vp: Node, ev: InputEvent, _i: int) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("clicked", data.get("id",-1) as int)
