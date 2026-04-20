extends Node2D
# ═══════════════════════════════════════════════════
# CharacterCreate.gd — LPC Character Creator
# Player customizes their character using full LPC
# layered sprites. Appearance saved to SaveManager.
# ═══════════════════════════════════════════════════

const LPC_SPRITE = preload("res://scripts/lpc/CharacterSprite.gd")

# Option data
const BODY_TYPES:   Array = ["female","male","teen"]
const BODY_LABELS:  Array = ["Female","Male","Teen"]
const SKIN_TONES:   Array = ["light","tanned","tanned2","dark","dark2"]
const SKIN_LABELS:  Array = ["Light","Tanned","Tanned 2","Dark","Dark 2"]

const HAIR_STYLES:  Array = [
	"","bangs","bangslong","bangsshort","bedhead","long","long_straight",
	"longhawk","loose","messy1","messy2","page","page2","parted",
	"pixie","plain","shorthawk","swoop","unkempt",
	"bangslong2","bunches","high_ponytail","long_tied","ponytail",
	"ponytail2","princess","shoulderl","shoulderr","single","wavy"
]
const HAIR_LABELS:  Array = [
	"None","Bangs","Bangs Long","Bangs Short","Bedhead","Long","Long Straight",
	"Long Hawk","Loose","Messy 1","Messy 2","Page","Page 2","Parted",
	"Pixie","Plain","Short Hawk","Swoop","Unkempt",
	"Bangs Long 2","Bunches","High Ponytail","Long Tied","Ponytail",
	"Ponytail 2","Princess","Shoulder L","Shoulder R","Single","Wavy"
]
const HAIR_COLORS: Array = [
	"ash","black","blonde","blue","carrot","chestnut","dark_brown",
	"dark_gray","ginger","gold","gray","green","light_brown","navy",
	"orange","pink","platinum","purple","raven","red","redhead",
	"rose","sandy","strawberry","violet","white"
]
const SHIRT_STYLES: Array = [
	"sleeveless1","sleeveless2","sleeveless2_buttoned","sleeveless2_cardigan",
	"sleeveless2_polo","sleeveless2_scoop","sleeveless2_vneck"
]
const SHIRT_LABELS: Array = ["Basic","Collared","Buttoned","Cardigan","Polo","Scoop Neck","V-Neck"]
const SHIRT_COLORS: Array = [
	"black","blue","bluegray","brown","charcoal","forest","gray","green",
	"lavender","leather","maroon","navy","orange","pink","purple","red",
	"rose","sky","slate","tan","teal","walnut","white","yellow"
]
const LEG_TYPES:   Array = ["","pants/magenta","pants/red","pants/teal","pants/white","skirt/robe","armor/golden","armor/metal"]
const LEG_LABELS:  Array = ["None","Magenta Pants","Red Pants","Teal Pants","White Pants","Robe Skirt","Golden Greaves","Metal Armor"]
const SHOE_TYPES:  Array = ["","boots/basic","boots/fold","boots/revised","boots/rimmed","shoes/basic","shoes/ghillies","shoes/revised","shoes/sara","sandals","slippers"]
const SHOE_LABELS: Array = ["None","Basic Boots","Fold Boots","Revised Boots","Rimmed Boots","Basic Shoes","Ghillie Shoes","Revised Shoes","Sara Shoes","Sandals","Slippers"]
const SHOE_COLORS: Array = [
	"black","blue","bluegray","brass","bronze","brown","ceramic","charcoal",
	"copper","forest","gold","gray","green","iron","lavender","leather",
	"maroon","navy","orange","pink","purple","red","rose","silver",
	"sky","slate","steel","tan","teal","walnut","white","yellow"
]

# Current selections
var _body_idx:   int = 0
var _skin_idx:   int = 0
var _hair_idx:   int = 7   # loose
var _hcol_idx:   int = 1   # black
var _shirt_idx:  int = 0
var _scol_idx:   int = 22  # white
var _leg_idx:    int = 4   # white pants
var _shoe_idx:   int = 1   # basic boots
var _shcol_idx:  int = 14  # leather

var _preview: Node2D
var _anims: Array = ["idle","walk"]
var _anim_idx: int = 0
var _anim_timer: float = 0.0
var _anim_hold: float = 2.5

func _ready() -> void:
	_build_ui()
	_build_preview()
	_refresh()

func _build_preview() -> void:
	_preview = LPC_SPRITE.new()
	_preview.scale = Vector2(5, 5)
	# Position: tile top-left is at node position, offset so character is centered
	# feet at y≈0 from node: -61*scale, center x: -32*scale
	_preview.position = Vector2(640 - 32*5, 440 - 61*5)
	add_child(_preview)  # _ready() fires here, THEN apply() will work

func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color("#0d0f1a")
	bg.set_position(Vector2.ZERO)
	bg.set_size(Vector2(1280, 720))
	add_child(bg)

	# Title
	var title := Label.new()
	title.text = "Create Your Character"
	title.set_position(Vector2(480, 16))
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#FFD93D"))
	add_child(title)

	# Left column — body/hair/shirt
	_make_section("BODY TYPE",  Vector2(30, 70),  BODY_LABELS,  func(i): _body_idx=i; _refresh())
	_make_section("SKIN TONE",  Vector2(30, 150), SKIN_LABELS,  func(i): _skin_idx=i; _refresh())
	_make_section("HAIR STYLE", Vector2(30, 230), HAIR_LABELS,  func(i): _hair_idx=i; _refresh())
	_make_section("HAIR COLOR", Vector2(30, 310), HAIR_COLORS,  func(i): _hcol_idx=i; _refresh(), true)
	_make_section("SHIRT",      Vector2(30, 390), SHIRT_LABELS, func(i): _shirt_idx=i; _refresh())
	_make_section("SHIRT COLOR",Vector2(30, 470), SHIRT_COLORS, func(i): _scol_idx=i; _refresh(), true)

	# Right column — legs/shoes
	_make_section("LEGS",       Vector2(820, 70),  LEG_LABELS,  func(i): _leg_idx=i; _refresh())
	_make_section("FOOTWEAR",   Vector2(820, 150), SHOE_LABELS, func(i): _shoe_idx=i; _refresh())
	_make_section("SHOE COLOR", Vector2(820, 230), SHOE_COLORS, func(i): _shcol_idx=i; _refresh(), true)

	# Confirm button
	var confirm := _make_btn("Confirm & Continue", Vector2(490, 640), Vector2(300, 50))
	confirm.pressed.connect(_on_confirm)
	confirm.add_theme_color_override("font_color", Color("#FFD93D"))
	confirm.add_theme_font_size_override("font_size", 18)

func _make_section(label_text: String, pos: Vector2, options: Array, on_change: Callable, capitalize: bool = false) -> void:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.set_position(pos)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#7799aa"))
	add_child(lbl)

	var btn := OptionButton.new()
	btn.set_position(pos + Vector2(0, 18))
	btn.set_size(Vector2(380, 32))
	btn.add_theme_font_size_override("font_size", 12)
	for opt in options:
		var s: String = str(opt)
		btn.add_item(s.capitalize() if capitalize else s)
	btn.item_selected.connect(on_change)
	add_child(btn)

func _make_btn(text: String, pos: Vector2, sz: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.set_position(pos)
	b.set_size(sz)
	add_child(b)
	return b

func _get_appearance() -> Dictionary:
	return {
		"body_type":   BODY_TYPES[_body_idx],
		"skin_tone":   SKIN_TONES[_skin_idx],
		"hair_style":  HAIR_STYLES[_hair_idx],
		"hair_color":  HAIR_COLORS[_hcol_idx],
		"shirt_style": SHIRT_STYLES[_shirt_idx],
		"shirt_color": SHIRT_COLORS[_scol_idx],
		"leg_type":    LEG_TYPES[_leg_idx],
		"shoe_type":   SHOE_TYPES[_shoe_idx],
		"shoe_color":  SHOE_COLORS[_shcol_idx],
		"sock_type":   "",
		"sock_color":  "",
	}

func _refresh() -> void:
	_preview.apply(_get_appearance())
	_preview.play("idle")
	_preview.set_direction(2)

func _process(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= _anim_hold:
		_anim_timer = 0.0
		_anim_idx = (_anim_idx + 1) % _anims.size()
		_preview.play(_anims[_anim_idx])

func _on_confirm() -> void:
	var appearance: Dictionary = _get_appearance()
	SaveManager.set_player_appearance(appearance)
	# Always show the kingdom intro on first character creation
	if not ProgressTracker.cutscene_seen("intro"):
		GameRouter.go_cutscene("intro", func():
			GameRouter.go_cutscene("ch1_open", func():
				GameRouter.go_world_map()))
	else:
		GameRouter.go_world_map()
