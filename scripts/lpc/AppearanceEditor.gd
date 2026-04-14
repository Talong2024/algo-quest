extends CanvasLayer
## AppearanceEditor — runtime appearance tweaker.
## Press F2 in-game to open. Edit any CharacterSprite on screen.
## Changes are printed to console as a GDScript dictionary you can paste.

const LPC_SPRITE = preload("res://scripts/lpc/CharacterSprite.gd")

# Options
const BODY_TYPES:   Array = ["female","male","teen"]
const SKIN_TONES:   Array = ["light","tanned","tanned2","dark","dark2"]
const HAIR_STYLES:  Array = ["","bangs","bangslong","bangsshort","bedhead","long","long_straight","longhawk","loose","messy1","messy2","page","page2","parted","pixie","plain","shorthawk","swoop","unkempt","bangslong2","bunches","high_ponytail","long_tied","ponytail","ponytail2","princess","shoulderl","shoulderr","single","wavy"]
const HAIR_COLORS:  Array = ["ash","black","blonde","blue","carrot","chestnut","dark_brown","dark_gray","ginger","gold","gray","green","light_brown","navy","orange","pink","platinum","purple","raven","red","redhead","rose","sandy","strawberry","violet","white"]
const SHIRT_STYLES: Array = ["sleeveless1","sleeveless2","sleeveless2_buttoned","sleeveless2_cardigan","sleeveless2_polo","sleeveless2_scoop","sleeveless2_vneck"]
const SHIRT_COLORS: Array = ["black","blue","bluegray","brown","charcoal","forest","gray","green","lavender","leather","maroon","navy","orange","pink","purple","red","rose","sky","slate","tan","teal","walnut","white","yellow"]
const LEG_TYPES:    Array = ["","pants/magenta","pants/red","pants/teal","pants/white","skirt/robe","armor/golden","armor/metal"]
const SHOE_TYPES:   Array = ["","boots/basic","boots/fold","boots/revised","boots/rimmed","shoes/basic","shoes/ghillies","shoes/revised","shoes/sara","sandals","slippers","accessory/plate_toe","accessory/plate_toe_thick"]
const SHOE_COLORS:  Array = ["black","blue","bluegray","brass","bronze","brown","ceramic","charcoal","copper","forest","gold","gray","green","iron","lavender","leather","maroon","navy","orange","pink","purple","red","rose","silver","sky","slate","steel","tan","teal","walnut","white","yellow"]
const SOCK_TYPES:   Array = ["","ankle","high","tabi"]
const SOCK_COLORS:  Array = ["black","blue","bluegray","brown","charcoal","forest","gray","green","lavender","leather","maroon","navy","orange","pink","purple","red","rose","sky","slate","tan","teal","walnut","white","yellow"]
const ANIMS:        Array = ["idle","walk","run","emote","hurt","sit","jump","climb"]
const DIRS:         Array = ["Up","Left","Down","Right"]

# Current edited state
var _appearance: Dictionary = {}
var _anim: String = "idle"
var _dir:  int    = 2


# UI
var _panel:   Control
var _preview: Node2D
var _opts:    Dictionary = {}   # key -> OptionButton
var _visible: bool = false

func _ready() -> void:
	layer = 200
	_build_panel()
	_build_preview()
	_panel.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and ke.keycode == KEY_F2:
			_toggle()

func _toggle() -> void:
	_visible = !_visible
	_panel.visible = _visible
	if _visible and _appearance.is_empty():
		_appearance = CharacterRandomizer.randomize_character()
		_sync_ui_to_appearance()
		_refresh_preview()

# ── Build UI ─────────────────────────────────────────────────────────────────

func _build_panel() -> void:
	_panel = Control.new()
	add_child(_panel)

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.10, 0.97)
	bg.set_position(Vector2(0, 0))
	bg.set_size(Vector2(520, 720))
	_panel.add_child(bg)

	var title := Label.new()
	title.text = "⚙ Appearance Editor  [F2 to close]"
	title.set_position(Vector2(10, 8))
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color("#FFD93D"))
	_panel.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.set_position(Vector2(0, 36))
	scroll.set_size(Vector2(520, 560))
	_panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.set_size(Vector2(500, 0))
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	# Sections
	_add_section(vbox, "Body Type",   "body_type",   BODY_TYPES)
	_add_section(vbox, "Skin Tone",   "skin_tone",   SKIN_TONES)
	_add_section(vbox, "Hair Style",  "hair_style",  HAIR_STYLES)
	_add_section(vbox, "Hair Color",  "hair_color",  HAIR_COLORS)
	_add_section(vbox, "Shirt Style", "shirt_style", SHIRT_STYLES)
	_add_section(vbox, "Shirt Color", "shirt_color", SHIRT_COLORS)
	_add_section(vbox, "Leg Type",    "leg_type",    LEG_TYPES)
	_add_section(vbox, "Shoe Type",   "shoe_type",   SHOE_TYPES)
	_add_section(vbox, "Shoe Color",  "shoe_color",  SHOE_COLORS)
	_add_section(vbox, "Sock Type",   "sock_type",   SOCK_TYPES)
	_add_section(vbox, "Sock Color",  "sock_color",  SOCK_COLORS)

	# Animation + direction row
	var anim_hbox := HBoxContainer.new()
	vbox.add_child(anim_hbox)
	var anim_lbl := Label.new()
	anim_lbl.text = "Animation"
	anim_lbl.custom_minimum_size = Vector2(120, 0)
	anim_lbl.add_theme_font_size_override("font_size", 11)
	anim_lbl.add_theme_color_override("font_color", Color("#7799aa"))
	anim_hbox.add_child(anim_lbl)
	var anim_opt := OptionButton.new()
	anim_opt.custom_minimum_size = Vector2(180, 0)
	for a: String in ANIMS: anim_opt.add_item(a)
	anim_opt.item_selected.connect(func(i: int): _anim = ANIMS[i]; _refresh_preview())
	anim_hbox.add_child(anim_opt)
	var dir_opt := OptionButton.new()
	dir_opt.custom_minimum_size = Vector2(100, 0)
	for d: String in DIRS: dir_opt.add_item(d)
	dir_opt.select(2)
	dir_opt.item_selected.connect(func(i: int): _dir = i; _preview.set_direction(i))
	anim_hbox.add_child(dir_opt)

	# Buttons row
	var btn_row := HBoxContainer.new()
	btn_row.set_position(Vector2(10, 608))
	_panel.add_child(btn_row)

	var copy_btn := Button.new()
	copy_btn.text = "📋 Copy Dict"
	copy_btn.custom_minimum_size = Vector2(140, 36)
	copy_btn.pressed.connect(_copy_to_clipboard)
	btn_row.add_child(copy_btn)

	var rand_btn := Button.new()
	rand_btn.text = "🎲 Randomize"
	rand_btn.custom_minimum_size = Vector2(130, 36)
	rand_btn.pressed.connect(_randomize)
	btn_row.add_child(rand_btn)

	var apply_btn := Button.new()
	apply_btn.text = "✅ Apply to Target"
	apply_btn.custom_minimum_size = Vector2(150, 36)
	apply_btn.pressed.connect(_apply_to_target)
	btn_row.add_child(apply_btn)

	# Result label
	var result_lbl := Label.new()
	result_lbl.name = "ResultLbl"
	result_lbl.set_position(Vector2(10, 652))
	result_lbl.set_size(Vector2(500, 60))
	result_lbl.add_theme_font_size_override("font_size", 9)
	result_lbl.add_theme_color_override("font_color", Color("#6BCB77"))
	result_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_panel.add_child(result_lbl)

func _add_section(parent: Control, label: String, key: String, options: Array) -> void:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)
	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(120, 0)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color("#7799aa"))
	hbox.add_child(lbl)
	var opt := OptionButton.new()
	opt.custom_minimum_size = Vector2(360, 0)
	opt.add_theme_font_size_override("font_size", 11)
	for o in options:
		opt.add_item(str(o) if str(o) != "" else "(none)")
	opt.item_selected.connect(func(i: int):
		_appearance[key] = options[i]
		_refresh_preview())
	hbox.add_child(opt)
	_opts[key] = opt

func _build_preview() -> void:
	_preview = LPC_SPRITE.new()
	_preview.position = Vector2(640, 560)
	_preview.scale    = Vector2(5, 5)
	add_child(_preview)

# ── Logic ─────────────────────────────────────────────────────────────────────

func _sync_ui_to_appearance() -> void:
	var key_arrays: Dictionary = {
		"body_type": BODY_TYPES, "skin_tone": SKIN_TONES,
		"hair_style": HAIR_STYLES, "hair_color": HAIR_COLORS,
		"shirt_style": SHIRT_STYLES, "shirt_color": SHIRT_COLORS,
		"leg_type": LEG_TYPES, "shoe_type": SHOE_TYPES,
		"shoe_color": SHOE_COLORS, "sock_type": SOCK_TYPES, "sock_color": SOCK_COLORS
	}
	for key: String in key_arrays:
		if _opts.has(key):
			var arr: Array = key_arrays[key]
			var val: String = str(_appearance.get(key, ""))
			var idx: int = arr.find(val)
			if idx >= 0:
				(_opts[key] as OptionButton).select(idx)

func _refresh_preview() -> void:
	_preview.apply(_appearance)
	_preview.play(_anim)
	_preview.set_direction(_dir)

func _randomize() -> void:
	_appearance = CharacterRandomizer.randomize_character()
	_sync_ui_to_appearance()
	_refresh_preview()

func _copy_to_clipboard() -> void:
	var lines: Array[String] = ["{\n"]
	for key: String in _appearance:
		lines.append('\t"%s": "%s",\n' % [key, str(_appearance[key])])
	lines.append("}")
	var text: String = "".join(lines)
	DisplayServer.clipboard_set(text)
	var lbl: Label = _panel.get_node("ResultLbl") as Label
	if lbl:
		lbl.text = "✓ Copied to clipboard! Paste into World.gd / CharacterData."
	print("=== Appearance Dict ===\n" + text)

func _apply_to_target() -> void:
	# Find the nearest CharacterSprite in the scene and apply to it
	var root: Node = get_tree().root
	var sprites: Array = _find_sprites(root)
	var lbl: Label = _panel.get_node("ResultLbl") as Label
	if sprites.is_empty():
		if lbl: lbl.text = "No CharacterSprite found in scene!"
		return
	# Apply to first found
	var target: Node2D = sprites[0] as Node2D
	target.apply(_appearance)
	target.play(_anim)
	target.set_direction(_dir)
	if lbl: lbl.text = "✓ Applied to %s" % target.get_path()

func _find_sprites(node: Node) -> Array:
	var found: Array = []
	if node.get_script() and str(node.get_script().resource_path).ends_with("CharacterSprite.gd"):
		found.append(node)
	for child in node.get_children():
		found.append_array(_find_sprites(child))
	return found
