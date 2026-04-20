class_name CitizenNode
extends Node2D

signal clicked(citizen_id: int)
signal drag_released(citizen_id: int, world_pos: Vector2)

@onready var _char_sprite:  Node2D    = $CharSprite
@onready var _patience_bar: ColorRect = $PatienceBar
@onready var _patience_bg:  ColorRect = $PatienceBarBG
@onready var _name_lbl:     Label     = $NameLabel
@onready var _badge:        Label     = $TypeBadge
@onready var _click_area:   Area2D    = $ClickArea

var data:           Dictionary = {}
var patience_ratio: float      = 1.0

var _target_y:   float = 0.0
var _move_speed: float = 180.0

# Drag state (L4 priority)
var _dragging:    bool    = false
var _drag_offset: Vector2 = Vector2.ZERO

# Visual extras
var _speech_bubble: Control   # cooking-game style request bubble
var _speech_lbl:    Label
var _bubble_anim:   float = 0.0
var _anger_lbl:     Label
var _anger_timer:   float = 0.0
var _gate_lbl:      Label
var _aura:          ColorRect  # enemy dark aura

const TYPE_COLORS: Dictionary = {
	"normal":   Color("#4D96FF"),
	"vip":      Color("#FFD93D"),
	"merchant": Color("#6BCB77"),
	"elderly":  Color("#C77DFF"),
	"guard":    Color("#FF6B6B"),
	"skeleton": Color("#44FF88"),
	"orc":      Color("#FF4400"),
}

# What each citizen type says when waiting
const CITIZEN_REQUESTS: Dictionary = {
	"normal":   ["Please!","Your turn!","Waiting...","Let me in!"],
	"vip":      ["I am VIP!","Royalty first!","Do you know who I am?"],
	"merchant": ["Trade permit!","Official business!","I have goods!"],
	"elderly":  ["Been waiting hours...","These old bones...","Kind soul?"],
	"guard":    ["On patrol!","Official duty!","Kingdom guard!"],
	"skeleton": ["...","Rattle rattle","Here to serve?"],
	"orc":      ["GRRRR","Me want in!","RAWR"],
}

func _ready() -> void:
	_click_area.input_event.connect(_on_area_input)
	_build_extras()
	tree_entered.connect(_on_tree_entered)

func _build_extras() -> void:
	# Enemy dark aura (hidden for normal citizens)
	_aura = ColorRect.new()
	_aura.color = Color(0.8, 0.0, 0.0, 0.0)
	_aura.set_position(Vector2(-40, -160))
	_aura.set_size(Vector2(80, 180))
	_aura.z_index = -1
	add_child(_aura)

	# Speech bubble — shows citizen's request (Overcooked style)
	_speech_bubble = Control.new()
	_speech_bubble.set_position(Vector2(-50, -180))
	_speech_bubble.set_size(Vector2(100, 30))
	_speech_bubble.visible = false
	add_child(_speech_bubble)

	var bubble_bg := ColorRect.new()
	bubble_bg.color = Color(0.95, 0.95, 0.85, 0.92)
	bubble_bg.set_position(Vector2.ZERO); bubble_bg.set_size(Vector2(100, 28))
	_speech_bubble.add_child(bubble_bg)

	var bubble_tail := ColorRect.new()
	bubble_tail.color = Color(0.95, 0.95, 0.85, 0.92)
	bubble_tail.set_position(Vector2(40, 26)); bubble_tail.set_size(Vector2(12, 8))
	_speech_bubble.add_child(bubble_tail)

	_speech_lbl = Label.new()
	_speech_lbl.set_position(Vector2(4, 2)); _speech_lbl.set_size(Vector2(92, 24))
	_speech_lbl.add_theme_font_size_override("font_size", 10)
	_speech_lbl.add_theme_color_override("font_color", Color("#222222"))
	_speech_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speech_bubble.add_child(_speech_lbl)

	# Anger bubble
	_anger_lbl = Label.new()
	_anger_lbl.add_theme_font_size_override("font_size", 11)
	_anger_lbl.add_theme_color_override("font_color", Color("#FF6B6B"))
	_anger_lbl.position = Vector2(-40, -205)
	_anger_lbl.visible  = false
	add_child(_anger_lbl)

	# Gate hint (L5 deque)
	_gate_lbl = Label.new()
	_gate_lbl.add_theme_font_size_override("font_size", 10)
	_gate_lbl.add_theme_color_override("font_color", Color("#FFD93D"))
	_gate_lbl.position = Vector2(-20, 36)
	_gate_lbl.visible  = false
	add_child(_gate_lbl)

var _pending_bubble: bool = false

func setup(citizen: Dictionary, _sy: float = 0.0, ty: float = 0.0) -> void:
	data      = citizen
	_target_y = ty
	_refresh()
	_pending_bubble = true  # show bubble once we enter the tree

func _on_tree_entered() -> void:
	if _pending_bubble:
		_pending_bubble = false
		get_tree().create_timer(0.5).timeout.connect(_show_speech_bubble, CONNECT_ONE_SHOT)

func _show_speech_bubble() -> void:
	if not is_instance_valid(_speech_bubble): return
	var ctype: String = str(data.get("type", "normal"))
	var requests: Array = CITIZEN_REQUESTS.get(ctype, ["..."])
	_speech_lbl.text = requests[randi() % requests.size()]
	_speech_bubble.visible = true

func set_target_y(y: float) -> void:
	_target_y = y

func has_arrived() -> bool:
	return abs(position.y - _target_y) < 8.0

func show_anger(msg: String) -> void:
	_anger_lbl.text    = "💢 " + msg
	_anger_lbl.visible = true
	_anger_timer       = 2.0
	_speech_bubble.visible = false
	var ctype: String = str(data.get("type",""))
	if is_instance_valid(_char_sprite):
		if ctype in ["skeleton","orc"]:
			_char_sprite.play("emote")
		else:
			_char_sprite.play("hurt")

func play_slash_anim() -> void:
	if is_instance_valid(_char_sprite):
		_char_sprite.play("hurt")
	_anger_lbl.text    = "⚔️ REPELLED!"
	_anger_lbl.visible = true
	_anger_timer       = 1.5
	_speech_bubble.visible = false
	var tw := create_tween()
	tw.tween_property(self,"modulate",Color("#FF4400"),0.1)
	tw.tween_property(self,"modulate",Color.WHITE,0.2)
	tw.tween_property(self,"scale",Vector2(0.0,0.0),0.3).set_trans(Tween.TRANS_EXPO)
	tw.tween_callback(queue_free)

func play_serve_anim() -> void:
	_speech_bubble.visible = false
	if is_instance_valid(_char_sprite):
		_char_sprite.play("emote")
	var tw := create_tween()
	tw.tween_property(self,"position:x", position.x + 200.0, 0.4).set_trans(Tween.TRANS_EXPO)
	tw.parallel().tween_property(self,"modulate:a", 0.0, 0.35)
	tw.tween_callback(queue_free)

func show_gate_hint(gate: String) -> void:
	_gate_lbl.text    = "[F]" if gate == "front" else "[B]"
	_gate_lbl.visible = true

func update_patience(ratio: float) -> void:
	patience_ratio = ratio
	if is_instance_valid(_patience_bar):
		_patience_bar.size.x = 48.0 * ratio
		var col: Color = Color("#6BCB77")
		if ratio < 0.5: col = Color("#FFD93D")
		if ratio < 0.25: col = Color("#FF6B6B")
		_patience_bar.color = col
		_patience_bg.visible = true
		_patience_bar.visible = true

func _refresh() -> void:
	var ctype: String = str(data.get("type","normal"))
	var tdata: Dictionary = {}
	var col:   Color = TYPE_COLORS.get(ctype, Color("#4D96FF")) as Color

	# Enemy aura
	if ctype in ["skeleton","orc"]:
		_aura.color = Color(0.8, 0.0, 0.0, 0.15)

	# Apply LPC appearance
	if is_instance_valid(_char_sprite):
		var appearance: Dictionary = data.get("appearance", {}) as Dictionary
		if appearance.is_empty():
			appearance = CharacterRandomizer.randomize_character()
			if ctype == "skeleton":
				appearance = {"body_type":"enemy_skeleton","skin_tone":"","hair_style":"","shirt_style":"","leg_type":"","shoe_type":"","sock_type":""}
			elif ctype == "orc":
				appearance = {"body_type":"enemy_orc","skin_tone":"","hair_style":"","shirt_style":"","leg_type":"","shoe_type":"","sock_type":""}
		_char_sprite.apply(appearance)
		_char_sprite.play("idle")
		_char_sprite.set_direction(2)

	if is_instance_valid(_name_lbl):
		_name_lbl.text = data.get("name","?") as String
		_name_lbl.add_theme_color_override("font_color", col)

	if is_instance_valid(_badge):
		_badge.text = data.get("label","?") as String
		_badge.add_theme_color_override("font_color", col.darkened(0.1))

func _process(delta: float) -> void:
	if _dragging:
		position = get_global_mouse_position() + _drag_offset
		return

	# Smooth movement
	if abs(position.y - _target_y) > 2.0:
		position.y = move_toward(position.y, _target_y, _move_speed * delta)
		if is_instance_valid(_char_sprite):
			_char_sprite.play("walk")
			_char_sprite.set_direction(1)
	else:
		if is_instance_valid(_char_sprite):
			if _char_sprite._anim == "walk":
				_char_sprite.play("idle")
				_char_sprite.set_direction(2)

	# Anger bubble timer
	if _anger_timer > 0.0:
		_anger_timer -= delta
		if _anger_timer <= 0.0:
			_anger_lbl.visible = false

	# Speech bubble bob animation
	if is_instance_valid(_speech_bubble) and _speech_bubble.visible:
		_bubble_anim += delta * 2.0
		_speech_bubble.position.y = -180.0 + sin(_bubble_anim) * 3.0

	# Enemy aura pulse
	if str(data.get("type","")) in ["skeleton","orc"]:
		_aura.color.a = 0.1 + sin(_bubble_anim * 1.5) * 0.08

func _on_area_input(_vp: Node, ev: InputEvent, _i: int) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				emit_signal("clicked", data.get("id",-1) as int)
