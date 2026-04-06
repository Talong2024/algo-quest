extends Node2D
# #REGION:CHARACTERS — One citizen in the Kingdom Queue.
# Uses CharacterSprite (LPC layered sprites) for appearance.
# Created via script so ALL nodes are built in _ready(), no @onready.

signal clicked(citizen_id: int)

const CITIZEN_SCALE: float = 2.5

var data:           Dictionary = {}
var is_front:       bool       = false
var patience_ratio: float      = 1.0
var _target_y:      float      = 0.0
var _move_speed:    float      = 180.0
var _bounce:        float      = 0.0

# Child nodes built in _ready
var _char_sprite: Node2D   # CharacterSprite instance
var _name_lbl:    Label
var _badge:       Label
var _patience:    ColorRect

# Type badge colors
const TYPE_COLORS: Dictionary = {
	"normal":   Color("#4D96FF"),
	"vip":      Color("#FFD93D"),
	"merchant": Color("#6BCB77"),
	"elderly":  Color("#C77DFF"),
}

func _ready() -> void:
	_build_nodes()

func _build_nodes() -> void:
	# Shadow under feet
	var shadow := ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.3)
	shadow.set_position(Vector2(-18, 4))
	shadow.set_size(Vector2(36, 8))
	add_child(shadow)

	# LPC CharacterSprite — full animated layered character
	_char_sprite = load("res://scripts/lpc/CharacterSprite.gd").new()
	_char_sprite.name = "CharSprite"
	_char_sprite.scale = Vector2(CITIZEN_SCALE, CITIZEN_SCALE)
	_char_sprite.position = Vector2(-32 * CITIZEN_SCALE, -61 * CITIZEN_SCALE)
	add_child(_char_sprite)  # add_child first so _ready fires before apply

	# Name label
	_name_lbl = Label.new()
	_name_lbl.set_position(Vector2(-32, 58))
	_name_lbl.set_size(Vector2(64, 14))
	_name_lbl.add_theme_font_size_override("font_size", 9)
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_name_lbl)

	# Type badge
	_badge = Label.new()
	_badge.set_position(Vector2(-32, 70))
	_badge.set_size(Vector2(64, 12))
	_badge.add_theme_font_size_override("font_size", 8)
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_badge)

	# Patience bar background
	var bar_bg := ColorRect.new()
	bar_bg.color = Color("#1a1a2e")
	bar_bg.set_position(Vector2(-24, -125))
	bar_bg.set_size(Vector2(48, 5))
	add_child(bar_bg)

	# Patience bar fill
	_patience = ColorRect.new()
	_patience.color = Color("#6BCB77")
	_patience.set_position(Vector2(-24, -125))
	_patience.set_size(Vector2(48, 5))
	_patience.visible = false
	add_child(_patience)

	# Click area
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(64, 80)
	shape.shape = rect
	area.add_child(shape)
	area.input_event.connect(_on_area_input)
	add_child(area)

func setup(citizen: Dictionary, _sy: float = 0.0, ty: float = 0.0) -> void:
	data = citizen
	_target_y = ty
	_refresh()

func set_front(v: bool) -> void:
	is_front = v
	_refresh()

func set_target_y(y: float) -> void:
	_target_y = y

func play_serve_anim() -> void:
	# Play happy emote then shrink out
	if is_instance_valid(_char_sprite):
		_char_sprite.play("emote")
	var tw := create_tween()
	tw.tween_interval(0.4)
	tw.tween_property(self, "scale", Vector2(1.5, 1.5), 0.08).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2(0.0, 0.0), 0.18).set_trans(Tween.TRANS_EXPO)
	tw.tween_callback(queue_free)

func _refresh() -> void:
	var ctype: String = data.get("type", "normal")
	var col: Color    = TYPE_COLORS.get(ctype, Color("#4D96FF"))

	# Apply the pre-randomized LPC appearance stored in citizen data
	if is_instance_valid(_char_sprite):
		var appearance: Dictionary = data.get("appearance", {})
		if not appearance.is_empty():
			_char_sprite.apply(appearance)
		# Front citizen faces down (toward camera), others face down too
		_char_sprite.set_direction(2)
		# Idle when waiting, walk animation when moving toward front
		_char_sprite.play("idle")

	if is_instance_valid(_name_lbl):
		_name_lbl.text = data.get("name", "?")
		_name_lbl.add_theme_color_override("font_color", Color("#e8e8f0"))

	if is_instance_valid(_badge):
		_badge.text = "[%s]" % ctype
		_badge.add_theme_color_override("font_color", col)

func _process(delta: float) -> void:
	# Smooth queue movement
	if abs(position.y - _target_y) > 2.0:
		position.y = move_toward(position.y, _target_y, _move_speed * delta)
		# Play walk while moving
		if is_instance_valid(_char_sprite):
			_char_sprite.play("walk")
	else:
		# Settled — play idle
		if is_instance_valid(_char_sprite):
			_char_sprite.play("idle")

	# Front citizen subtle bounce
	if is_front and is_instance_valid(_char_sprite):
		_bounce += delta * 2.0
		_char_sprite.position.y = sin(_bounce) * 2.0 + (-61 * CITIZEN_SCALE)

	# Patience bar
	if is_instance_valid(_patience):
		_patience.visible = patience_ratio < 0.9
		_patience.set_size(Vector2(48.0 * patience_ratio, 5))
		_patience.color = Color("#6BCB77").lerp(Color("#FF6B6B"), 1.0 - patience_ratio)

func _on_area_input(_vp: Node, ev: InputEvent, _idx: int) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("clicked", data.get("id", -1) as int)
