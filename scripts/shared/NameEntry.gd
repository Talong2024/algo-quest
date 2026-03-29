extends Node2D

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0a0a0f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_lbl("Welcome to AlgoQuest", Vector2(340, 200), 32, Color("#4D96FF"))
	_lbl("Learn Data Structures & Algorithms by playing",
		Vector2(340, 246), 15, Color("#555577"))
	_lbl("Enter your name, Code Keeper:", Vector2(440, 320), 18, Color("#e8e8f0"))

	var input := LineEdit.new()
	input.set_position(Vector2(440, 360))
	input.set_size(Vector2(400, 48))
	input.max_length = 20
	input.placeholder_text = "Code Keeper..."
	input.add_theme_font_size_override("font_size", 18)
	add_child(input)

	var btn := Button.new()
	btn.text = "Begin the Adventure"
	btn.set_position(Vector2(440, 424))
	btn.set_size(Vector2(400, 52))
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color("#6BCB77"))
	btn.pressed.connect(func():
		var n: String = input.text.strip_edges()
		if n.length() >= 2:
			ProgressTracker.set_player_name(n)
			AudioManager.play_sfx("click")
			GameRouter.go_char_select()
	)
	add_child(btn)

func _lbl(t: String, p: Vector2, s: int, c: Color) -> void:
	var l := Label.new()
	l.text = t
	l.set_position(p)
	l.add_theme_font_size_override("font_size", s)
	l.add_theme_color_override("font_color", c)
	add_child(l)
