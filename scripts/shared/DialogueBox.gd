extends CanvasLayer
## DialogueBox — reusable RPG-style dialogue system.
##
## Usage:
##   var dlg = preload("res://scenes/shared/DialogueBox.tscn").instantiate()
##   add_child(dlg)
##   dlg.show_dialogue(SCRIPT, on_complete_callable)
##
## Script format:
##   [
##     { "speaker": "Old Gatekeeper", "portrait": "doorman", "text": "Hello!" },
##     { "speaker": "You", "portrait": "player", "text": "Hi there." },
##     { "speaker": "Guard", "portrait": "guard", "text": "Choose:",
##       "choices": ["Go left", "Go right"], "choice_var": "direction" },
##   ]
##
## Portraits are LPC CharacterSprite nodes configured by portrait key.

signal dialogue_finished
signal choice_made(choice_var: String, index: int)

const TYPEWRITER_SPEED: float = 0.03   # seconds per character

@onready var _box_bg:    ColorRect   = $Root/BoxBG
@onready var _port_bg:   ColorRect   = $Root/PortraitBG
@onready var _port_node: Node2D      = $Root/PortraitSprite
@onready var _nameplate: ColorRect   = $Root/NamePlate
@onready var _name_lbl:  Label       = $Root/NamePlate/NameLabel
@onready var _text_lbl:  Label       = $Root/DialogueText
@onready var _hint_lbl:  Label       = $Root/NextHint
@onready var _choices:   VBoxContainer = $Root/ChoiceContainer

# Portrait sprite cache: portrait_key → CharacterSprite node
var _portrait_sprites: Dictionary = {}
# Currently visible portrait
var _active_portrait:  String = ""

# Dialogue state
var _script:        Array    = []
var _idx:           int      = 0
var _on_complete:   Callable = func(): pass
var _choices_vars:  Dictionary = {}   # variable name → chosen index

# Typewriter state
var _full_text:     String  = ""
var _shown:         int     = 0
var _typing:        bool    = false
var _type_timer:    float   = 0.0

# Portrait appearance presets
const PORTRAIT_PRESETS: Dictionary = {
	"narrator": {
		"color": Color(0.06, 0.06, 0.16),
		"name_color": Color(0.6, 0.7, 0.9),
		"appearance": {},   # no sprite, just colored box
	},
	"doorman": {
		"color": Color(0.14, 0.08, 0.04),
		"name_color": Color(1.0, 0.6, 0.1),
		"appearance": {
			"body_type":"male","skin_tone":"dark","hair_style":"plain",
			"hair_color":"gray","shirt_style":"sleeveless2","shirt_color":"charcoal",
			"leg_type":"pants/white","shoe_type":"boots/basic","shoe_color":"brown",
			"sock_type":"","sock_color":"",
		},
	},
	"player": {
		"color": Color(0.04, 0.12, 0.14),
		"name_color": Color(0.3, 0.9, 0.5),
		"appearance": {},   # loaded from SaveManager at runtime
	},
	"king": {
		"color": Color(0.14, 0.10, 0.02),
		"name_color": Color(1.0, 0.85, 0.2),
		"appearance": {
			"body_type":"male","skin_tone":"light","hair_style":"longhawk",
			"hair_color":"gold","shirt_style":"sleeveless2","shirt_color":"yellow",
			"leg_type":"armor/golden","shoe_type":"boots/rimmed","shoe_color":"brass",
			"sock_type":"","sock_color":"",
		},
	},
	"merchant": {
		"color": Color(0.04, 0.14, 0.06),
		"name_color": Color(0.4, 0.9, 0.5),
		"appearance": {
			"body_type":"female","skin_tone":"tanned","hair_style":"ponytail",
			"hair_color":"chestnut","shirt_style":"sleeveless2","shirt_color":"green",
			"leg_type":"skirt/robe","shoe_type":"shoes/sara","shoe_color":"brown",
			"sock_type":"","sock_color":"",
		},
	},
	"elderly": {
		"color": Color(0.10, 0.06, 0.14),
		"name_color": Color(0.75, 0.5, 1.0),
		"appearance": {
			"body_type":"female","skin_tone":"light","hair_style":"plain",
			"hair_color":"white","shirt_style":"sleeveless2","shirt_color":"lavender",
			"leg_type":"skirt/robe","shoe_type":"slippers","shoe_color":"gray",
			"sock_type":"","sock_color":"",
		},
	},
}

func _ready() -> void:
	visible = false
	_hint_lbl.visible = false
	_choices.visible  = false
	# Pre-build portrait sprite slot
	_build_portrait_sprite_slot()

func _build_portrait_sprite_slot() -> void:
	# The PortraitSprite node in the scene holds a CharacterSprite instance
	# Portrait area: x=16-176, y=(720-176)-(720-8) = 544 to 712
	# Center of portrait box on screen: x=96, y=628
	# CharacterSprite at scale 2.5, feet at y=0, offset=-61*2.5=-152
	# So sprite position = (96-32*2.5, 712-61*2.5) but in CanvasLayer coords
	# Use anchor-based positioning:
	var sprite_holder: Node2D = $Root/PortraitSprite as Node2D
	# Position will be set relative to the box — done in _show_portrait

# ── Public API ────────────────────────────────────────────────────────────────

func show_dialogue(script: Array, on_complete: Callable = func(): pass) -> void:
	_script      = script
	_idx         = 0
	_on_complete = on_complete
	_choices_vars.clear()
	self.visible = true
	_show_line(_idx)

func get_choice(var_name: String) -> int:
	return _choices_vars.get(var_name, 0) as int

func close() -> void:
	self.visible = false
	_clear_portrait()

# ── Dialogue flow ─────────────────────────────────────────────────────────────

func _show_line(idx: int) -> void:
	if idx >= _script.size():
		_finish()
		return
	var line: Dictionary = _script[idx]
	var portrait_key: String = str(line.get("portrait", "narrator"))
	var speaker: String      = str(line.get("speaker",  ""))
	var text: String         = str(line.get("text",     ""))
	var choices: Array       = line.get("choices", []) as Array

	_update_portrait(portrait_key)
	_name_lbl.text = speaker

	# Name color
	var preset: Dictionary = PORTRAIT_PRESETS.get(portrait_key, {}) as Dictionary
	var nc: Color = preset.get("name_color", Color("#FFD93D")) as Color
	_name_lbl.add_theme_color_override("font_color", nc)
	_nameplate.color = (nc * Color(1,1,1,0.12)).clamp()

	# Start typewriter
	_full_text = text
	_shown     = 0
	_text_lbl.text = ""
	_typing    = true
	_type_timer = 0.0
	_hint_lbl.visible = false

	# Choices (shown after typewriter finishes)
	if not choices.is_empty():
		_choices.visible = false   # shown after text done
		_setup_choices(line)
	else:
		_choices.visible = false

func _setup_choices(line: Dictionary) -> void:
	# Clear old choice buttons
	for child in _choices.get_children():
		child.queue_free()
	_build_choice_buttons.call_deferred(line)

func _build_choice_buttons(line: Dictionary) -> void:

	var choices: Array   = line.get("choices", []) as Array
	var cvar: String     = str(line.get("choice_var", "choice"))
	var idx_capture: int = _idx

	for i in choices.size():
		var btn := Button.new()
		btn.text = "[%d]  %s" % [i+1, str(choices[i])]
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", Color("#e8e8f0"))
		btn.focus_mode = Control.FOCUS_NONE
		var ci: int = i
		btn.pressed.connect(func():
			_choices_vars[cvar] = ci
			emit_signal("choice_made", cvar, ci)
			_choices.visible = false
			_idx += 1
			_show_line(_idx)
		)
		_choices.add_child(btn)

func _advance() -> void:
	if _typing:
		# Skip typewriter — show full text immediately
		_text_lbl.text = _full_text
		_shown         = _full_text.length()
		_typing        = false
		_on_typewriter_done()
		return
	# Check if waiting for choices
	if _choices.visible:
		return
	_idx += 1
	_show_line(_idx)

func _on_typewriter_done() -> void:
	var line: Dictionary = _script[_idx]
	var choices: Array   = line.get("choices", []) as Array
	if not choices.is_empty():
		_choices.visible  = true
		_hint_lbl.visible = false
	else:
		_hint_lbl.visible = true

func _finish() -> void:
	self.visible = false
	_clear_portrait()
	var cb: Callable = _on_complete
	_on_complete = func(): pass
	cb.call()

# ── Portrait management ───────────────────────────────────────────────────────

func _update_portrait(portrait_key: String) -> void:
	var preset: Dictionary = PORTRAIT_PRESETS.get(portrait_key, {}) as Dictionary

	# Background color
	var bg_col: Color = preset.get("color", Color(0.06,0.06,0.16)) as Color
	_port_bg.color = bg_col

	# Get or create the sprite for this portrait
	var appearance: Dictionary = preset.get("appearance", {}) as Dictionary
	if portrait_key == "player":
		appearance = SaveManager.get_player_appearance()
		if appearance.is_empty():
			appearance = CharacterRandomizer.randomize_character()

	if appearance.is_empty():
		# Narrator / no sprite — hide sprite area
		_hide_all_portraits()
		_active_portrait = portrait_key
		return

	# Create sprite if not cached
	if not _portrait_sprites.has(portrait_key):
		var sprite: Node2D = load("res://scripts/lpc/CharacterSprite.gd").new()
		sprite.name  = "Portrait_" + portrait_key
		sprite.scale = Vector2(2.5, 2.5)
		$Root/PortraitSprite.add_child(sprite)
		sprite.apply(appearance)
		_portrait_sprites[portrait_key] = sprite

	# Hide all, show this one
	_hide_all_portraits()
	var active: Node2D = _portrait_sprites[portrait_key] as Node2D
	active.visible = true

	# Position: portrait box bottom-left corner in screen coords
	# Box: x=16, y=(720-176)=544 to y=720-8=712, width=160
	# Feet at box bottom = 712. sprite position needs offset so feet sit at 712.
	# In CanvasLayer coords (same as screen): position.x = 16+80=96 (center of box)
	# sprite.position.x = 96 - 32*2.5 = 96-80 = 16
	# sprite.position.y = 712 - 61*2.5 = 712-152 = 560
	# But PortraitSprite node is at (0,0) in CanvasLayer, so these ARE screen coords.
	active.position = Vector2(16, 560)

	# Animate the sprite
	active.play("idle")
	# Speaker faces right (toward the text box) when their line plays
	active.set_direction(1 if portrait_key == "player" else 3)

	_active_portrait = portrait_key

	# Bounce effect — small scale pulse
	var tw := create_tween()
	tw.tween_property(active, "scale", Vector2(2.6, 2.6), 0.08).set_trans(Tween.TRANS_BACK)
	tw.tween_property(active, "scale", Vector2(2.5, 2.5), 0.12)

func _hide_all_portraits() -> void:
	for key: String in _portrait_sprites:
		(_portrait_sprites[key] as Node2D).visible = false

func _clear_portrait() -> void:
	_hide_all_portraits()

# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and ke.keycode in [KEY_SPACE, KEY_ENTER, KEY_Z]:
			_advance()
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_advance()

# ── Typewriter ────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _typing:
		return
	_type_timer += delta
	if _type_timer >= TYPEWRITER_SPEED:
		_type_timer -= TYPEWRITER_SPEED
		_shown = mini(_shown + 2, _full_text.length())   # 2 chars/tick = snappy
		_text_lbl.text = _full_text.substr(0, _shown)
		if _shown >= _full_text.length():
			_typing = false
			_on_typewriter_done()
