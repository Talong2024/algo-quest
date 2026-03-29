extends Node2D
# ═══════════════════════════════════════════════════
# CharacterSelect.gd
# Player picks an avatar before entering the world.
# Avatar is stored in SaveManager and shown on
# WorldMap HUD and cutscene portraits.
# ═══════════════════════════════════════════════════

const CHARACTERS: Array = [
	{
		"id":    "keeper",
		"name":  "The Keeper",
		"title": "Classic",
		"desc":  "The original Code Keeper. Balanced in all DSAs.",
		"color": Color("#4D96FF"),
		"codemon": "",   # uses jimmy.png
		"bonus": "No bonus — pure skill.",
	},
	{
		"id":    "queue_knight",
		"name":  "Queue Knight",
		"title": "Queue Specialist",
		"desc":  "Trained at the Kingdom Gate. Earns +10% score in Ch1.",
		"color": Color("#6BCB77"),
		"codemon": "int",
		"bonus": "+10% score in Kingdom Queue",
	},
	{
		"id":    "stack_mage",
		"name":  "Stack Mage",
		"title": "Stack Specialist",
		"desc":  "Wizard of the Castle. Earns +10% score in Ch2.",
		"color": Color("#C77DFF"),
		"codemon": "if",
		"bonus": "+10% score in Castle of Echoes",
	},
	{
		"id":    "list_engineer",
		"name":  "List Engineer",
		"title": "List Specialist",
		"desc":  "Royal train conductor. Earns +10% score in Ch3.",
		"color": Color("#FFD93D"),
		"codemon": "array",
		"bonus": "+10% score in Chain Train",
	},
	{
		"id":    "tree_oracle",
		"name":  "Tree Oracle",
		"title": "Tree Specialist",
		"desc":  "Forest guardian. Earns +10% score in Ch4.",
		"color": Color("#6BCB77"),
		"codemon": "for",
		"bonus": "+10% score in Oracle's Forest",
	},
	{
		"id":    "graph_ranger",
		"name":  "Graph Ranger",
		"title": "Graph Specialist",
		"desc":  "Kingdom road scout. Earns +10% score in Ch5.",
		"color": Color("#FF9F43"),
		"codemon": "while",
		"bonus": "+10% score in Kingdom Roads",
	},
]

var _selected: int = 0
var _cards:    Array = []

func _ready() -> void:
	# Default to previously saved character if any
	var saved: String = SaveManager.get_setting("character_id", "") as String
	if saved != "":
		for i in CHARACTERS.size():
			if (CHARACTERS[i]["id"] as String) == saved:
				_selected = i
				break
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0a0a0f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var hdr := ColorRect.new()
	hdr.color = Color("#0d0d1a")
	hdr.set_position(Vector2.ZERO)
	hdr.set_size(Vector2(1280, 70))
	add_child(hdr)

	_lbl("Choose your Code Keeper", Vector2(430, 16), 24, Color("#e8e8f0"))
	_lbl("Your avatar and specialisation for the journey", Vector2(420, 46), 13, Color("#555577"))

	# Character cards — 3 per row
	for i in CHARACTERS.size():
		_build_card(i)

	# Detail panel (bottom)
	var detail_bg := ColorRect.new()
	detail_bg.name = "DetailBG"
	detail_bg.color = Color("#13131f")
	detail_bg.set_position(Vector2(0, 570))
	detail_bg.set_size(Vector2(1280, 150))
	add_child(detail_bg)

	_lbl("", Vector2(40, 585), 20, Color("#e8e8f0")).name = "DetailName"
	_lbl("", Vector2(40, 615), 14, Color("#888899")).name = "DetailDesc"
	_lbl("", Vector2(40, 642), 13, Color("#FFD93D")).name = "DetailBonus"

	var confirm_btn := Button.new()
	confirm_btn.name = "ConfirmBtn"
	confirm_btn.text = "Begin Adventure as %s  ▶" % (CHARACTERS[_selected]["name"] as String)
	confirm_btn.set_position(Vector2(800, 590))
	confirm_btn.set_size(Vector2(440, 60))
	confirm_btn.add_theme_font_size_override("font_size", 18)
	confirm_btn.add_theme_color_override("font_color",
		CHARACTERS[_selected]["color"] as Color)
	confirm_btn.pressed.connect(_confirm)
	add_child(confirm_btn)

	_update_detail()

func _build_card(idx: int) -> void:
	var ch:   Dictionary = CHARACTERS[idx]
	var col:  Color      = ch["color"] as Color
	var row:  int        = idx / 3
	var col_n: int       = idx % 3
	var cx:   float      = 40.0 + col_n * 400.0
	var cy:   float      = 90.0 + row * 240.0

	var card := ColorRect.new()
	card.name  = "Card_%d" % idx
	card.color = col.darkened(0.65) if idx == _selected else Color("#13131f")
	card.set_position(Vector2(cx, cy))
	card.set_size(Vector2(360, 210))
	add_child(card)
	_cards.append(card)

	# Color accent bar
	var accent := ColorRect.new()
	accent.color = col
	accent.set_position(Vector2.ZERO)
	accent.set_size(Vector2(360, 5))
	card.add_child(accent)

	# Avatar — codemon sprite or placeholder circle
	var avatar_node := Node2D.new()
	avatar_node.position = Vector2(60, 90)
	card.add_child(avatar_node)

	var codemon_key: String = ch["codemon"] as String
	if codemon_key != "":
		var tex: Texture2D = AssetMap.codemon(codemon_key)
		if tex:
			var sprite := Sprite2D.new()
			sprite.texture        = tex
			sprite.scale          = Vector2(2.5, 2.5)
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			avatar_node.add_child(sprite)
	# Else: jimmy.png would go here, left as circle for now

	# Name + title
	var name_lbl := Label.new()
	name_lbl.text = ch["name"] as String
	name_lbl.set_position(Vector2(100, 18))
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", col)
	card.add_child(name_lbl)

	var title_lbl := Label.new()
	title_lbl.text = ch["title"] as String
	title_lbl.set_position(Vector2(100, 44))
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.add_theme_color_override("font_color", Color("#555577"))
	card.add_child(title_lbl)

	# Selected indicator
	if idx == _selected:
		var sel := Label.new()
		sel.text = "✓ Selected"
		sel.set_position(Vector2(240, 180))
		sel.add_theme_font_size_override("font_size", 12)
		sel.add_theme_color_override("font_color", col)
		card.add_child(sel)

	# Clickable area
	var area  := Area2D.new()
	var shape := CollisionShape2D.new()
	var box   := RectangleShape2D.new()
	box.size   = Vector2(360, 210)
	shape.shape = box
	area.position = Vector2(180, 105)
	area.add_child(shape)
	var capture_idx := idx
	area.input_event.connect(func(_vp, event, _i):
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				_select(capture_idx)
	)
	card.add_child(area)

func _select(idx: int) -> void:
	_selected = idx
	# Rebuild cards to update selection visuals
	for c in _cards:
		if is_instance_valid(c): c.queue_free()
	_cards.clear()
	for i in CHARACTERS.size():
		_build_card(i)
	_update_detail()

	# Update confirm button text + color
	var btn := get_node_or_null("ConfirmBtn") as Button
	if btn:
		btn.text = "Begin Adventure as %s  ▶" % (CHARACTERS[_selected]["name"] as String)
		btn.add_theme_color_override("font_color",
			CHARACTERS[_selected]["color"] as Color)

func _update_detail() -> void:
	var ch: Dictionary = CHARACTERS[_selected]
	var name_lbl := get_node_or_null("DetailName") as Label
	var desc_lbl := get_node_or_null("DetailDesc") as Label
	var bonus_lbl := get_node_or_null("DetailBonus") as Label
	if name_lbl: name_lbl.text = ch["name"] as String
	if desc_lbl: desc_lbl.text = ch["desc"] as String
	if bonus_lbl: bonus_lbl.text = "Bonus: " + (ch["bonus"] as String)

func _confirm() -> void:
	var ch: Dictionary = CHARACTERS[_selected]
	var char_id: String = ch["id"] as String
	SaveManager.set_setting("character_id", char_id)
	SaveManager.set_setting("character_color",
		(ch["color"] as Color).to_html())
	SaveManager.set_setting("character_name", ch["name"] as String)
	# Play intro cutscene first time, skip on subsequent character changes
	# Save character choice to Firebase
	if FirebaseManager.is_signed_in():
		FirebaseManager.save_progress(0, 0, 0, false)
	if not ProgressTracker.cutscene_seen("intro"):
		GameRouter.go_cutscene("intro", func(): GameRouter.go_world_map())
	else:
		GameRouter.go_world_map()

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text; l.set_position(pos)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	add_child(l); return l
