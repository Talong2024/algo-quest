extends Node2D
# Boot.gd — routes to the correct first scene
# Flow:
#   First ever launch:  SSIntro → MainMenu → AuthScreen → CodemonIntro → WorldMap
#   Returning player:   MainMenu → AuthScreen → WorldMap

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0a0a0f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_lbl("ALGOQUEST", Vector2(490, 300), 52, Color("#4D96FF"))
	_lbl("Loading...", Vector2(560, 380), 16, Color("#333355"))

	await get_tree().create_timer(0.8).timeout
	AudioManager.play_bgm("menu")

	# SS Intro only on very first launch
	if not ProgressTracker.cutscene_seen("ss_intro"):
		ProgressTracker.mark_cutscene_seen("ss_intro")
		GameRouter.go_ss_intro()
	elif SaveManager.get_player_appearance().is_empty():
		# Has seen SS intro but never completed character creation — go to intro world
		GameRouter.go_intro_world()
	else:
		GameRouter.go_main_menu()

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new(); l.text = text; l.set_position(pos)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	add_child(l); return l
