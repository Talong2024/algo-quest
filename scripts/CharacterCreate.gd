extends Node2D
# ═══════════════════════════════════════════════════
# CharacterCreate.gd
# Full character customisation using LPC sprite sheets.
# Layers: Body → Hair → Face → Shirt → Shoes
# Gender: Male / Female
# Saved to SaveManager for use on WorldMap HUD + NPCs.
# ═══════════════════════════════════════════════════

# ── Config ───────────────────────────────────────
const FRAME_SIZE: int = 16   # 16×18 RPG sheet cells
const FRAME_W:    int = 16
const FRAME_H:    int = 18
const PREVIEW_SCALE: float = 6.0

const HAIR_COLORS: Array = [
	{"name":"Black",  "col":Color("#1a1a1a")},
	{"name":"Brown",  "col":Color("#5c3d1e")},
	{"name":"Blonde", "col":Color("#dab84b")},
	{"name":"Red",    "col":Color("#a02020")},
	{"name":"White",  "col":Color("#e8e8e8")},
	{"name":"Blue",   "col":Color("#2040c0")},
]

const SKIN_TONES: Array = [
	{"name":"Light",  "key":"female_light"},
	{"name":"Olive",  "key":"female_brown"},
	{"name":"Brown",  "key":"female_amber"},
	{"name":"Dark",   "key":"female_black"},
]

const SHIRT_STYLES: Array = [
	{"name":"Black",  "key":"sleeveless_black"},
	{"name":"Blue",   "key":"sleeveless_blue"},
	{"name":"Green",  "key":"sleeveless_green"},
	{"name":"Red",    "key":"sleeveless_red"},
]

# ── State ────────────────────────────────────────
var _gender:     String = "female"
var _skin_idx:   int    = 0
var _hair_idx:   int    = 0
var _hair_col_idx: int  = 0
var _shirt_idx:  int    = 0
var _char_name:  String = ""

# Preview sprites
var _preview_body:  Sprite2D
var _preview_hair:  Sprite2D
var _preview_face:  Sprite2D
var _preview_shirt: Sprite2D

func _ready() -> void:
	_build_ui()
	_refresh_preview()

func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color("#08080f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Street tile BG
	var tile: Texture2D = AssetMap.load_tex(AssetMap.MAP_TILES["street"])
	if tile:
		for row in 4:
			for col in 4:
				var s := Sprite2D.new()
				s.texture = tile; s.position = Vector2(col*384+192, row*320+160)
				s.modulate = Color(1,1,1,0.10)
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s.z_index = -1; add_child(s)

	# Title
	_lbl("CHARACTER CREATION", Vector2(40, 20), 22, Color("#4D96FF"))
	_lbl("Customise your Code Keeper", Vector2(40, 52), 13, Color("#555577"))

	# ── Preview panel (centre) ──────────────────
	var prev_bg := ColorRect.new()
	prev_bg.color = Color("#13131f")
	prev_bg.set_position(Vector2(500, 60))
	prev_bg.set_size(Vector2(280, 400))
	add_child(prev_bg)
	_lbl("Preview", Vector2(590, 70), 13, Color("#888899"))

	# Preview sprites stacked
	_preview_body  = _make_preview_sprite(Vector2(640, 270))
	_preview_face  = _make_preview_sprite(Vector2(640, 270))
	_preview_hair  = _make_preview_sprite(Vector2(640, 270))
	_preview_shirt = _make_preview_sprite(Vector2(640, 270))

	# ── Left panel: customisation ───────────────
	var panel := ColorRect.new()
	panel.color = Color("#0d0d1a")
	panel.set_position(Vector2(40, 80))
	panel.set_size(Vector2(440, 560))
	add_child(panel)

	var py: float = 100.0

	# Gender
	_section_lbl("Gender", 60.0, py)
	py += 28.0
	_toggle_btn("Female", Vector2(60, py), func(): _set_gender("female"), _gender == "female")
	_toggle_btn("Male",   Vector2(200, py), func(): _set_gender("male"), _gender == "male")
	py += 52.0

	# Name
	_section_lbl("Name", 60.0, py)
	py += 28.0
	var name_field := LineEdit.new()
	name_field.placeholder_text = "Enter your name..."
	name_field.set_position(Vector2(60, py))
	name_field.set_size(Vector2(340, 38))
	name_field.add_theme_font_size_override("font_size", 14)
	name_field.text_changed.connect(func(t): _char_name = t)
	add_child(name_field)
	py += 52.0

	# Skin tone
	_section_lbl("Skin Tone", 60.0, py)
	py += 28.0
	for i in SKIN_TONES.size():
		var info: Dictionary = SKIN_TONES[i] as Dictionary
		var ci := i
		_radio_btn(info["name"] as String, Vector2(60 + i * 100, py),
			func(): _skin_idx = ci; _refresh_preview())
	py += 52.0

	# Hair style
	_section_lbl("Hair Style", 60.0, py)
	py += 28.0
	_arrow_row("Hair", 0, 2, Vector2(60, py), 320.0,
		func(): _hair_idx = (_hair_idx - 1 + 4) % 4; _refresh_preview(),
		func(): _hair_idx = (_hair_idx + 1) % 4; _refresh_preview(),
		func(): return "Style %d" % (_hair_idx + 1))
	py += 52.0

	# Hair colour
	_section_lbl("Hair Colour", 60.0, py)
	py += 28.0
	for i in HAIR_COLORS.size():
		var info: Dictionary = HAIR_COLORS[i] as Dictionary
		var ci := i
		var dot := Button.new()
		dot.set_position(Vector2(60 + i * 62, py))
		dot.set_size(Vector2(50, 28))
		dot.add_theme_color_override("font_color", info["col"] as Color)
		dot.text = "■"
		dot.pressed.connect(func(): _hair_col_idx = ci; _refresh_preview())
		add_child(dot)
	py += 52.0

	# Shirt
	_section_lbl("Shirt", 60.0, py)
	py += 28.0
	for i in SHIRT_STYLES.size():
		var info: Dictionary = SHIRT_STYLES[i] as Dictionary
		var ci := i
		_radio_btn(info["name"] as String, Vector2(60 + i * 100, py),
			func(): _shirt_idx = ci; _refresh_preview())
	py += 60.0

	# Confirm button
	var confirm: Button = AssetMap.make_codemon_button("✓  Create Character", Vector2(340, 52))
	confirm.set_position(Vector2(60, py))
	confirm.pressed.connect(_confirm)
	add_child(confirm)

	# Back button
	var back: Button = AssetMap.make_codemon_button("← Back", Vector2(160, 40))
	back.set_position(Vector2(1080, 660))
	back.pressed.connect(func(): GameRouter.go_auth_screen())
	add_child(back)

# ══════════════════════════════════════════════════
# Preview
# ══════════════════════════════════════════════════
func _refresh_preview() -> void:
	# Body
	var body_tex: Texture2D = AssetMap.load_tex(AssetMap.LPC_BODIES.get("bodies_1",""))
	if body_tex and is_instance_valid(_preview_body):
		_preview_body.texture = body_tex
		_preview_body.hframes = 20; _preview_body.vframes = 22
		_preview_body.frame   = 0

	# Face
	var skin: Dictionary  = SKIN_TONES[_skin_idx] as Dictionary
	var face_key: String  = skin["key"] as String
	var face_path: String = AssetMap.LPC_FACES.get(face_key, "") as String
	var face_tex: Texture2D = AssetMap.load_tex(face_path)
	if face_tex and is_instance_valid(_preview_face):
		_preview_face.texture = face_tex
		_preview_face.hframes = 8; _preview_face.vframes = 8
		_preview_face.frame   = 0

	# Hair tint
	var hair_col: Color = (HAIR_COLORS[_hair_col_idx] as Dictionary)["col"] as Color
	if is_instance_valid(_preview_hair):
		var hair_key: String  = "male_1" if _gender == "male" else "female_1"
		var hair_tex: Texture2D = AssetMap.load_tex(AssetMap.LPC_HAIR.get(hair_key,""))
		if hair_tex:
			_preview_hair.texture  = hair_tex
			_preview_hair.modulate = hair_col
			_preview_hair.hframes  = 32; _preview_hair.vframes = 25
			_preview_hair.frame    = _hair_idx

	# Shirt
	var shirt: Dictionary  = SHIRT_STYLES[_shirt_idx] as Dictionary
	var shirt_path: String = AssetMap.LPC_SHIRTS.get(shirt["key"] as String, "") as String
	var shirt_tex: Texture2D = AssetMap.load_tex(shirt_path)
	if shirt_tex and is_instance_valid(_preview_shirt):
		_preview_shirt.texture = shirt_tex
		_preview_shirt.hframes = 13; _preview_shirt.vframes = 4
		_preview_shirt.frame   = 0

func _make_preview_sprite(pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.position       = pos
	s.scale          = Vector2(PREVIEW_SCALE, PREVIEW_SCALE)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index        = 5
	add_child(s)
	return s

# ══════════════════════════════════════════════════
# Confirm
# ══════════════════════════════════════════════════
func _confirm() -> void:
	var final_name: String = _char_name.strip_edges()
	if final_name.is_empty():
		final_name = "Code Keeper"
	ProgressTracker.set_player_name(final_name)
	var skin: Dictionary = SKIN_TONES[_skin_idx] as Dictionary
	var shirt: Dictionary = SHIRT_STYLES[_shirt_idx] as Dictionary
	var hair_col: Dictionary = HAIR_COLORS[_hair_col_idx] as Dictionary
	SaveManager.set_setting("char_gender",   _gender)
	SaveManager.set_setting("char_skin",     skin["key"] as String)
	SaveManager.set_setting("char_hair_idx", _hair_idx)
	SaveManager.set_setting("char_hair_col", (hair_col["col"] as Color).to_html())
	SaveManager.set_setting("char_shirt",    shirt["key"] as String)
	GameRouter.go_char_select()

# ══════════════════════════════════════════════════
# UI helpers
# ══════════════════════════════════════════════════
func _set_gender(g: String) -> void:
	_gender = g; _refresh_preview()

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new(); l.text = text; l.set_position(pos)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	add_child(l); return l

func _section_lbl(text: String, x: float, y: float) -> void:
	_lbl(text, Vector2(x, y), 13, Color("#888899"))

func _toggle_btn(text: String, pos: Vector2, cb: Callable, _active: bool) -> Button:
	var b: Button = AssetMap.make_codemon_button(text, Vector2(120, 36))
	b.set_position(pos); b.pressed.connect(cb); add_child(b); return b

func _radio_btn(text: String, pos: Vector2, cb: Callable) -> Button:
	var b: Button = AssetMap.make_codemon_button(text, Vector2(88, 32))
	b.set_position(pos); b.pressed.connect(cb); add_child(b); return b

func _arrow_row(_label: String, _min: int, _max: int, pos: Vector2, width: float,
		cb_prev: Callable, cb_next: Callable, get_text: Callable) -> void:
	var prev: Button = AssetMap.make_codemon_button("◀", Vector2(36, 32))
	prev.set_position(pos); prev.pressed.connect(cb_prev); add_child(prev)
	var val := Label.new()
	val.set_position(pos + Vector2(44, 4))
	val.set_size(Vector2(width - 88, 28))
	val.add_theme_font_size_override("font_size", 13)
	val.add_theme_color_override("font_color", Color("#e8e8f0"))
	val.text = get_text.call() as String
	add_child(val)
	var nxt: Button = AssetMap.make_codemon_button("▶", Vector2(36, 32))
	nxt.set_position(pos + Vector2(width - 36, 0))
	nxt.pressed.connect(func(): cb_next.call(); val.text = get_text.call() as String)
	prev.pressed.connect(func(): val.text = get_text.call() as String)
	add_child(nxt)
