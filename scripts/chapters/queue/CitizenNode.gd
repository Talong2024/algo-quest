class_name CitizenNode
extends Node2D
signal clicked(citizen_id: int)
signal drag_released(citizen_id: int, world_pos: Vector2)

@onready var _char_sprite:  Node2D    = $CharSprite
@onready var _patience_bar: ColorRect = $PatienceBar
@onready var _name_lbl:     Label     = $NameLabel
@onready var _badge:        Label     = $TypeBadge
@onready var _click_area:   Area2D    = $ClickArea

var data:           Dictionary = {}
var patience_ratio: float      = 1.0

var _target_y:   float = 0.0
var _move_speed: float = 180.0
var _was_moving: bool  = false

# Drag state (L4 priority)
var _dragging:    bool    = false
var _drag_offset: Vector2 = Vector2.ZERO

# Anger bubble
var _anger_lbl:  Label
var _anger_timer: float = 0.0

# Gate hint (L5)
var _gate_lbl: Label

const TYPE_COLORS: Dictionary = {
	"normal":   Color("#4D96FF"),
	"vip":      Color("#FFD93D"),
	"merchant": Color("#6BCB77"),
	"elderly":  Color("#C77DFF"),
	"guard":    Color("#FF6B6B"),
}

func _ready() -> void:
	_click_area.input_event.connect(_on_area_input)
	_build_anger_bubble()
	_build_gate_hint()

func _build_anger_bubble() -> void:
	_anger_lbl = Label.new()
	_anger_lbl.add_theme_font_size_override("font_size", 11)
	_anger_lbl.add_theme_color_override("font_color", Color("#FF6B6B"))
	_anger_lbl.position = Vector2(-40, -145)
	_anger_lbl.visible  = false
	add_child(_anger_lbl)

func _build_gate_hint() -> void:
	_gate_lbl = Label.new()
	_gate_lbl.add_theme_font_size_override("font_size", 10)
	_gate_lbl.add_theme_color_override("font_color", Color("#FFD93D"))
	_gate_lbl.position = Vector2(-20, 36)
	_gate_lbl.visible  = false
	add_child(_gate_lbl)

func setup(citizen: Dictionary, _sy: float = 0.0, ty: float = 0.0) -> void:
	data      = citizen
	_target_y = ty
	_apply_appearance()
	# Show gate requirement for deque level
	var gate: String = str(citizen.get("gate","any"))
	if gate != "any":
		_gate_lbl.text    = "→ %s gate" % gate.to_upper()
		_gate_lbl.visible = true

func set_target_y(y: float) -> void:
	_target_y = y

func show_anger(msg: String) -> void:
	_anger_lbl.text    = "💢 " + msg
	_anger_lbl.visible = true
	_anger_timer       = 2.0
	if is_instance_valid(_char_sprite):
		_char_sprite.play("hurt")

func play_serve_anim() -> void:
	if is_instance_valid(_char_sprite):
		_char_sprite.play("emote")
	var tw := create_tween()
	tw.tween_interval(0.35)
	tw.tween_property(self, "scale", Vector2(1.4, 1.4), 0.07).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2(0.0,  0.0), 0.15).set_trans(Tween.TRANS_EXPO)
	tw.tween_callback(queue_free)

func start_drag() -> void:
	_dragging = true
	z_index   = 50

func stop_drag() -> void:
	_dragging = false
	z_index   = 10
	emit_signal("drag_released", data.get("id",-1) as int, global_position)

func _apply_appearance() -> void:
	var ctype: String = str(data.get("type","normal"))
	var col:   Color  = TYPE_COLORS.get(ctype, Color("#4D96FF")) as Color
	var app:   Dictionary = data.get("appearance",{}) as Dictionary
	if is_instance_valid(_char_sprite) and not app.is_empty():
		_char_sprite.apply(app)
		_char_sprite.play("idle")
		_char_sprite.set_direction(2)  # face camera when idle
	if is_instance_valid(_name_lbl):
		_name_lbl.text = str(data.get("name","?"))
		_name_lbl.add_theme_color_override("font_color", Color("#e8e8f0"))
	if is_instance_valid(_badge):
		_badge.text = "[%s]" % ctype
		_badge.add_theme_color_override("font_color", col)

func _process(delta: float) -> void:
	# Movement
	var moving: bool = abs(position.y - _target_y) > 2.0
	if moving:
		position.y = move_toward(position.y, _target_y, _move_speed * delta)
	if moving != _was_moving:
		_was_moving = moving
		if is_instance_valid(_char_sprite):
			if moving:
				_char_sprite.play("walk")
				# Citizens walk UP the screen toward the gate
				_char_sprite.set_direction(0)
			else:
				_char_sprite.play("idle")
				# Idle — face the camera (down)
				_char_sprite.set_direction(2)

	# Patience bar
	if is_instance_valid(_patience_bar):
		_patience_bar.visible = patience_ratio < 0.95
		_patience_bar.size    = Vector2(48.0 * patience_ratio, 5.0)
		_patience_bar.color   = Color("#6BCB77").lerp(Color("#FF6B6B"), 1.0 - patience_ratio)

	# Anger bubble timeout
	if _anger_timer > 0.0:
		_anger_timer -= delta
		if _anger_timer <= 0.0:
			_anger_lbl.visible = false
			if is_instance_valid(_char_sprite):
				_char_sprite.play("idle")

func _on_area_input(_vp: Node, ev: InputEvent, _idx: int) -> void:
	if not ev is InputEventMouseButton: return
	var mb: InputEventMouseButton = ev as InputEventMouseButton
	if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("clicked", data.get("id",-1) as int)
