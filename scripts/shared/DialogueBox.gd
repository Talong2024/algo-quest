extends CanvasLayer
## DialogueBox — Fire Emblem GBA-style RPG dialogue.
## Built entirely in code so positions are guaranteed correct.
## Box sits at bottom of screen. Background is SEMI-TRANSPARENT so world is visible.

signal dialogue_finished
signal choice_made(choice_var: String, index: int)

const TYPEWRITER_SPEED: float = 0.028
const BOX_H:  int = 180
const PORT_W: int = 170

# UI nodes (built in _ready)
var _root:      Control
var _box_outer: ColorRect
var _box_inner: ColorRect
var _port_bg:   ColorRect
var _port_node: Node2D
var _nameplate: ColorRect
var _name_lbl:  Label
var _text_lbl:  Label
var _hint_lbl:  Label
var _choices:   VBoxContainer

# Portrait sprite cache
var _portrait_sprites: Dictionary = {}
var _active_portrait:  String     = ""

# Dialogue state
var _script:      Array    = []
var _idx:         int      = 0
var _on_complete: Callable = func(): pass
var _choices_vars: Dictionary = {}

# Typewriter
var _full_text:   String  = ""
var _shown:       int     = 0
var _typing:      bool    = false
var _type_timer:  float   = 0.0

const PORTRAIT_PRESETS: Dictionary = {
	"narrator": {"name_color": Color(0.85,0.80,0.55), "appearance": {}},
	"doorman":  {"name_color": Color(1.0,0.65,0.15),  "appearance": {
		"body_type":"male","skin_tone":"dark","hair_style":"plain","hair_color":"gray",
		"shirt_style":"sleeveless2","shirt_color":"charcoal","leg_type":"pants/white",
		"shoe_type":"boots/basic","shoe_color":"brown","sock_type":"","sock_color":""}},
	"player":   {"name_color": Color(0.35,0.90,0.50), "appearance": {}},
	"king":     {"name_color": Color(1.0,0.85,0.20),  "appearance": {
		"body_type":"male","skin_tone":"light","hair_style":"longhawk","hair_color":"blonde",
		"shirt_style":"sleeveless2","shirt_color":"yellow","leg_type":"armor/golden",
		"shoe_type":"boots/rimmed","shoe_color":"brass","sock_type":"","sock_color":""}},
	"merchant": {"name_color": Color(0.40,0.90,0.50), "appearance": {
		"body_type":"female","skin_tone":"tanned","hair_style":"ponytail","hair_color":"chestnut",
		"shirt_style":"sleeveless2","shirt_color":"green","leg_type":"skirt/robe",
		"shoe_type":"shoes/sara","shoe_color":"brown","sock_type":"","sock_color":""}},
	"elderly":  {"name_color": Color(0.75,0.55,1.0),  "appearance": {
		"body_type":"female","skin_tone":"light","hair_style":"plain","hair_color":"white",
		"shirt_style":"sleeveless2","shirt_color":"lavender","leg_type":"skirt/robe",
		"shoe_type":"slippers","shoe_color":"gray","sock_type":"","sock_color":""}},
}

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var sw: int = 1280
	var sh: int = 720

	# Root control - full screen but mouse transparent
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# Outer border - FE GBA gold border
	_box_outer = ColorRect.new()
	_box_outer.color = Color(0.65, 0.50, 0.18, 0.97)
	_box_outer.set_position(Vector2(0, sh - BOX_H - 4))
	_box_outer.set_size(Vector2(sw, BOX_H + 4))
	_root.add_child(_box_outer)

	# Inner fill - dark parchment, SEMI-TRANSPARENT so world shows through slightly
	_box_inner = ColorRect.new()
	_box_inner.color = Color(0.08, 0.06, 0.03, 0.94)
	_box_inner.set_position(Vector2(2, sh - BOX_H - 2))
	_box_inner.set_size(Vector2(sw - 4, BOX_H))
	_root.add_child(_box_inner)

	# Portrait frame (dark stone)
	_port_bg = ColorRect.new()
	_port_bg.color = Color(0.12, 0.09, 0.04, 1.0)
	_port_bg.set_position(Vector2(6, sh - BOX_H))
	_port_bg.set_size(Vector2(PORT_W, BOX_H - 4))
	_root.add_child(_port_bg)

	# Portrait sprite container
	_port_node = Node2D.new()
	_port_node.name = "PortraitSprite"
	_root.add_child(_port_node)

	# Nameplate (above text, warm amber banner)
	_nameplate = ColorRect.new()
	_nameplate.color = Color(0.50, 0.36, 0.08, 0.97)
	_nameplate.set_position(Vector2(PORT_W + 10, sh - BOX_H - 22))
	_nameplate.set_size(Vector2(360, 22))
	_root.add_child(_nameplate)

	# Nameplate top border
	var np_top := ColorRect.new()
	np_top.color = Color(0.65, 0.50, 0.18, 1.0)
	np_top.set_position(Vector2(PORT_W + 10, sh - BOX_H - 24))
	np_top.set_size(Vector2(360, 2))
	_root.add_child(np_top)

	# Name label
	_name_lbl = Label.new()
	_name_lbl.set_position(Vector2(PORT_W + 20, sh - BOX_H - 20))
	_name_lbl.set_size(Vector2(350, 20))
	_name_lbl.add_theme_font_size_override("font_size", 14)
	_name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65))
	_root.add_child(_name_lbl)

	# Dialogue text
	_text_lbl = Label.new()
	_text_lbl.set_position(Vector2(PORT_W + 12, sh - BOX_H + 8))
	_text_lbl.set_size(Vector2(sw - PORT_W - 28, BOX_H - 40))
	_text_lbl.add_theme_font_size_override("font_size", 15)
	_text_lbl.add_theme_color_override("font_color", Color(0.95, 0.90, 0.75))
	_text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_root.add_child(_text_lbl)

	# "Press SPACE" hint
	_hint_lbl = Label.new()
	_hint_lbl.text = "▶  SPACE / click to continue"
	_hint_lbl.set_position(Vector2(sw - 320, sh - 28))
	_hint_lbl.set_size(Vector2(310, 20))
	_hint_lbl.add_theme_font_size_override("font_size", 11)
	_hint_lbl.add_theme_color_override("font_color", Color(0.65, 0.50, 0.20))
	_hint_lbl.visible = false
	_root.add_child(_hint_lbl)

	# Choices container
	_choices = VBoxContainer.new()
	_choices.set_position(Vector2(PORT_W + 12, sh - 100))
	_choices.set_size(Vector2(sw - PORT_W - 28, 90))
	_choices.add_theme_constant_override("separation", 4)
	_choices.visible = false
	_root.add_child(_choices)

	self.visible = false

# ── Public API ────────────────────────────────────────────────────────────────

func show_dialogue(script: Array, on_complete: Callable = func(): pass) -> void:
	_script       = script
	_idx          = 0
	_on_complete  = on_complete
	_choices_vars.clear()
	self.visible  = true
	_show_line(0)

func close() -> void:
	self.visible = false
	_clear_portraits()

# ── Dialogue ──────────────────────────────────────────────────────────────────

func _show_line(idx: int) -> void:
	if idx >= _script.size():
		_finish()
		return
	var line: Dictionary = _script[idx]
	var portrait: String = str(line.get("portrait","narrator"))
	var speaker:  String = str(line.get("speaker",""))
	var text:     String = str(line.get("text",""))

	_update_portrait(portrait)
	_name_lbl.text = speaker

	var nc: Color = (PORTRAIT_PRESETS.get(portrait,{}) as Dictionary).get(
		"name_color", Color(1.0,0.92,0.65)) as Color
	_name_lbl.add_theme_color_override("font_color", nc)

	_full_text  = text
	_shown      = 0
	_text_lbl.text = ""
	_typing     = true
	_type_timer = 0.0
	_hint_lbl.visible = false
	_choices.visible  = false

	var choices: Array = line.get("choices",[]) as Array
	if not choices.is_empty():
		_setup_choices.call_deferred(line)

func _setup_choices(line: Dictionary) -> void:
	for ch in _choices.get_children(): ch.queue_free()
	var choices: Array = line.get("choices",[]) as Array
	var cvar: String   = str(line.get("choice_var","choice"))
	for i in choices.size():
		var btn := Button.new()
		btn.text = "[%d]  %s" % [i+1, str(choices[i])]
		btn.add_theme_font_size_override("font_size", 13)
		btn.focus_mode = Control.FOCUS_NONE
		var ci: int = i
		btn.pressed.connect(func():
			_choices_vars[cvar] = ci
			emit_signal("choice_made", cvar, ci)
			_choices.visible = false
			_idx += 1
			_show_line(_idx))
		_choices.add_child(btn)

func _advance() -> void:
	if _typing:
		_text_lbl.text = _full_text
		_shown         = _full_text.length()
		_typing        = false
		_on_typewriter_done()
		return
	if _choices.visible: return
	_idx += 1
	_show_line(_idx)

func _on_typewriter_done() -> void:
	var line: Dictionary = _script[_idx]
	if not (line.get("choices",[]) as Array).is_empty():
		_choices.visible  = true
		_hint_lbl.visible = false
	else:
		_hint_lbl.visible = true

func _finish() -> void:
	self.visible = false
	_clear_portraits()
	var cb: Callable = _on_complete
	_on_complete = func(): pass
	cb.call()

# ── Portrait ──────────────────────────────────────────────────────────────────

# CGabriel faces: 8x8 grid at 48x48px per face
const FACES_SHEET: String = "res://assets/game/characters/faces_sheet.png"
# Map portrait key → face row,col in faces sheet
const FACE_POS: Dictionary = {
	"narrator": Vector2i(0, 0),
	"player":   Vector2i(1, 0),
	"doorman":  Vector2i(2, 0),
	"king":     Vector2i(3, 0),
	"merchant": Vector2i(0, 1),
	"elderly":  Vector2i(1, 1),
	"wizard":   Vector2i(2, 1),
	"oracle":   Vector2i(3, 1),
}

func _update_portrait(portrait: String) -> void:
	# Use CGabriel faces sheet — no LPC
	_clear_portraits()
	if not is_instance_valid(_port_node): return
	if not ResourceLoader.exists(FACES_SHEET): return

	var face_tex: Texture2D = load(FACES_SHEET) as Texture2D
	var fpos: Vector2i = FACE_POS.get(portrait, Vector2i(0,0)) as Vector2i
	const FTILE: int = 48

	# Reuse or create sprite for this portrait key
	var spr: Sprite2D
	if _portrait_sprites.has(portrait):
		spr = _portrait_sprites[portrait] as Sprite2D
	else:
		spr = Sprite2D.new()
		spr.name           = "DlgFace_" + portrait
		spr.texture        = face_tex
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.region_enabled = true
		spr.centered       = false
		spr.scale          = Vector2(3.0, 3.0)
		_port_node.add_child(spr)
		_portrait_sprites[portrait] = spr

	spr.region_rect = Rect2(fpos.x * FTILE, fpos.y * FTILE, FTILE, FTILE)
	spr.position    = Vector2(10, 720 - BOX_H + 4)
	spr.visible     = true

	# Bounce in
	var tw := create_tween()
	tw.tween_property(spr,"scale",Vector2(3.2,3.2),0.07)
	tw.tween_property(spr,"scale",Vector2(3.0,3.0),0.10)

func _clear_portraits() -> void:
	for k in _portrait_sprites:
		(_portrait_sprites[k] as Node2D).visible = false

# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not self.visible: return
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
	if not _typing: return
	_type_timer += delta
	if _type_timer >= TYPEWRITER_SPEED:
		_type_timer -= TYPEWRITER_SPEED
		_shown = mini(_shown + 2, _full_text.length())
		_text_lbl.text = _full_text.substr(0, _shown)
		if _shown >= _full_text.length():
			_typing = false
			_on_typewriter_done()
