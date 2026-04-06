extends Node2D
# ═══════════════════════════════════════════════════
# CharacterSelect.gd — Pick a class, preview with LPC character
# ═══════════════════════════════════════════════════

const LPC_SPRITE = preload("res://scripts/lpc/CharacterSprite.gd")

const CHARACTERS: Array = [
	{"id":"keeper",      "name":"The Keeper",     "title":"Classic",          "color":Color("#4D96FF"), "bonus":"No bonus — pure skill.",           "desc":"The original Code Keeper. Balanced in all DSAs."},
	{"id":"queue_knight","name":"Queue Knight",    "title":"Queue Specialist", "color":Color("#6BCB77"), "bonus":"+10% score in Kingdom Queue",      "desc":"Trained at the Kingdom Gate. Expert at FIFO."},
	{"id":"stack_mage",  "name":"Stack Mage",      "title":"Stack Specialist", "color":Color("#C77DFF"), "bonus":"+10% score in Castle Stack",       "desc":"Master of last-in first-out sorcery."},
	{"id":"list_rider",  "name":"List Rider",      "title":"List Specialist",  "color":Color("#FFD93D"), "bonus":"+10% score in Train Linked List",  "desc":"Linked list navigator extraordinaire."},
	{"id":"tree_warden", "name":"Tree Warden",     "title":"Tree Specialist",  "color":Color("#FF6B6B"), "bonus":"+10% score in Forest BST",         "desc":"Guardian of the binary search forest."},
]

var _selected_idx: int = 0
var _preview: Node2D
var _name_lbl: Label
var _title_lbl: Label
var _desc_lbl: Label
var _bonus_lbl: Label

func _ready() -> void:
	_build_bg()
	_build_preview()
	_build_selector()
	_build_info()
	_build_confirm()
	_refresh()

func _build_bg() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0d0f1a")
	bg.set_position(Vector2.ZERO)
	bg.set_size(Vector2(1280, 720))
	add_child(bg)
	var title := Label.new()
	title.text = "Choose Your Class"
	title.set_position(Vector2(440, 16))
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#FFD93D"))
	add_child(title)

func _build_preview() -> void:
	# Show the player's chosen LPC appearance
	_preview = LPC_SPRITE.new()
	_preview.scale = Vector2(6, 6)
	# Offset: feet at y=440, centered x: 640 - 32*6 = 448
	_preview.position = Vector2(640 - 32*6, 440 - 61*6)
	add_child(_preview)
	var saved: Dictionary = SaveManager.get_player_appearance()
	if saved.is_empty():
		saved = CharacterRandomizer.randomize_character()
	_preview.apply(saved)
	_preview.play("idle")
	_preview.set_direction(2)

func _build_selector() -> void:
	var x: float = 60.0
	for i in CHARACTERS.size():
		var ch: Dictionary = CHARACTERS[i]
		var btn := Button.new()
		btn.text = ch["name"]
		btn.set_position(Vector2(x, 600))
		btn.set_size(Vector2(220, 60))
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_color_override("font_color", ch["color"] as Color)
		var idx: int = i
		btn.pressed.connect(func(): _on_pick(idx))
		add_child(btn)
		x += 234.0

func _build_info() -> void:
	var px: float = 80.0
	var py: float = 60.0
	_name_lbl  = _lbl("", Vector2(px, py),      22, Color("#e8e8f0"))
	_title_lbl = _lbl("", Vector2(px, py+34),   13, Color("#aaaacc"))
	_desc_lbl  = _lbl("", Vector2(px, py+60),   12, Color("#888899"))
	_bonus_lbl = _lbl("", Vector2(px, py+90),   13, Color("#6BCB77"))

func _build_confirm() -> void:
	var btn := Button.new()
	btn.text = "Start Adventure →"
	btn.set_position(Vector2(490, 670))
	btn.set_size(Vector2(300, 40))
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color("#FFD93D"))
	btn.pressed.connect(_on_confirm)
	add_child(btn)

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.set_position(pos)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	return l

func _on_pick(idx: int) -> void:
	_selected_idx = idx
	_refresh()

func _refresh() -> void:
	var ch: Dictionary = CHARACTERS[_selected_idx]
	_name_lbl.text  = ch["name"]
	_title_lbl.text = ch["title"]
	_desc_lbl.text  = ch["desc"]
	_bonus_lbl.text = "Bonus: " + ch["bonus"]
	_name_lbl.add_theme_color_override("font_color", ch["color"] as Color)
	# Cycle preview animation
	_preview.play("idle")

func _on_confirm() -> void:
	var ch: Dictionary = CHARACTERS[_selected_idx]
	SaveManager.set_setting("character_class", ch["id"])
	GameRouter.go_to("world_map")
