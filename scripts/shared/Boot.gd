extends Node2D
# Boot.gd — routes to the correct first scene

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0a0a0f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_lbl("ALGOQUEST", Vector2(490, 300), 52, Color("#4D96FF"))
	_lbl("Loading...", Vector2(560, 380), 16, Color("#333355"))
	await get_tree().create_timer(0.5).timeout
	AudioManager.play_bgm("menu")
	_route()

func _route() -> void:
	var has_appearance: bool = not SaveManager.get_player_appearance().is_empty()
	if not ProgressTracker.cutscene_seen("ss_intro"):
		GameRouter.go_ss_intro()
	elif not has_appearance:
		# New player (no character yet) — go to character creation
		GameRouter.go_char_create()
	else:
		GameRouter.go_main_menu()

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new(); l.text = text; l.set_position(pos)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	add_child(l); return l
