extends Node2D

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0a0a0f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_lbl("ALGOQUEST", Vector2(440, 80), 52, Color("#4D96FF"))
	_lbl("DSA Teaching Game — Built with Godot 4 & Firebase",
		Vector2(300, 148), 16, Color("#555577"))

	_lbl("Chapters", Vector2(520, 220), 20, Color("#FFD93D"))
	_lbl("Kingdom Queue     — FIFO Queue",        Vector2(440, 260), 14, Color("#6BCB77"))
	_lbl("Castle of Echoes  — LIFO Stack",         Vector2(440, 284), 14, Color("#C77DFF"))
	_lbl("Chain Train       — Linked List",         Vector2(440, 308), 14, Color("#FFD93D"))
	_lbl("Oracle's Forest   — BST / AVL / Heap",   Vector2(440, 332), 14, Color("#6BCB77"))
	_lbl("Kingdom Roads     — Graph Algorithms",   Vector2(440, 356), 14, Color("#4D96FF"))

	_lbl("Assets", Vector2(520, 410), 16, Color("#888899"))
	_lbl("Kenney.nl — CC0 game assets",             Vector2(440, 446), 13, Color("#666688"))
	_lbl("OpenGameArt.org — CC0 audio & sprites",   Vector2(440, 468), 13, Color("#666688"))
	_lbl("itch.io community free assets",            Vector2(440, 490), 13, Color("#666688"))

	var btn := Button.new()
	btn.text = "Back to Menu"
	btn.set_position(Vector2(490, 560))
	btn.set_size(Vector2(300, 48))
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(func(): GameRouter.go_main_menu())
	add_child(btn)

func _lbl(t: String, p: Vector2, s: int, c: Color) -> void:
	var l := Label.new()
	l.text = t
	l.set_position(p)
	l.add_theme_font_size_override("font_size", s)
	l.add_theme_color_override("font_color", c)
	add_child(l)
