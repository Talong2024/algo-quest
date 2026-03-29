extends Node2D
# MainMenu with video background + SS Syntax Squad branding

var _buttons: Array = []

func _ready() -> void:
	_build_video_bg()
	_build_ui()
	_reveal_title()
	AudioManager.play_bgm("menu")

func _build_video_bg() -> void:
	var video_path: String = AssetMap.MENU_BG_VIDEO
	if FileAccess.file_exists(video_path):
		var stream = load(video_path)
		if stream is VideoStream:
			var vp := VideoStreamPlayer.new()
			vp.stream   = stream
			vp.autoplay = true
			vp.loop     = true
			vp.expand   = true
			vp.z_index  = -10
			vp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			add_child(vp)
		else:
			_fallback_bg()
	else:
		_fallback_bg()

	var vign := ColorRect.new()
	vign.color = Color(0.0, 0.0, 0.05, 0.62)
	vign.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vign.z_index = -8
	add_child(vign)

func _fallback_bg() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#060612")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -10
	add_child(bg)
	var tile: Texture2D = AssetMap.load_tex(AssetMap.MAP_TILES["street"])
	if tile:
		for row in 4:
			for col in 4:
				var s := Sprite2D.new()
				s.texture = tile; s.position = Vector2(col*384+192, row*320+160)
				s.modulate = Color(1,1,1,0.14)
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s.z_index = -9; add_child(s)

func _build_ui() -> void:
	# Title
	var glow := _lbl("ALGOQUEST", Vector2(183, 143), 88, Color(0.1,0.3,0.8,0.3))
	glow.name = "TitleGlow"; glow.modulate.a = 0.0
	var title := _lbl("ALGOQUEST", Vector2(180, 140), 88, Color("#4D96FF"))
	title.name = "Title"; title.modulate.a = 0.0; title.position.y = 190.0
	var sub := _lbl("Data Structures & Algorithms", Vector2(248, 252), 20, Color("#888899"))
	sub.name = "Sub"; sub.modulate.a = 0.0

	# Left panel
	var panel := ColorRect.new()
	panel.color = Color(0.05, 0.03, 0.12, 0.78)
	panel.set_position(Vector2(80, 330)); panel.set_size(Vector2(300, 310))
	add_child(panel)
	var bar := ColorRect.new()
	bar.color = Color("#4D96FF")
	bar.set_position(Vector2(80, 330)); bar.set_size(Vector2(3, 310))
	add_child(bar)

	# Buttons
	var has_save: bool = ProgressTracker.get_player_name() != ""
	var by: float = 355.0
	const BW: float = 260.0; const BH: float = 46.0; const BG: float = 56.0

	if has_save:
		_add_btn("▶  Continue",  Vector2(100, by), Vector2(BW,BH), func(): GameRouter.go_auth_screen()); by += BG
		_add_btn("🆕  New Game", Vector2(100, by), Vector2(BW,BH), func():
			ProgressTracker.reset_all(); GameRouter.go_auth_screen()); by += BG
	else:
		_add_btn("▶  Play",     Vector2(100, by), Vector2(BW,BH), func(): GameRouter.go_auth_screen()); by += BG

	_add_btn("⚙  Settings",    Vector2(100, by), Vector2(BW,BH), func(): GameRouter.go_settings()); by += BG
	_add_btn("★  Credits",     Vector2(100, by), Vector2(BW,BH), func(): GameRouter.go_credits()); by += BG
	_add_btn("Change Character",Vector2(100, by), Vector2(BW,BH), func(): GameRouter.go_char_select())

	# Branding
	_lbl("v0.1  ·  A Syntax Squad Game", Vector2(900, 694), 11, Color("#333355"))
	_lbl("Press ESC to quit", Vector2(20, 694), 11, Color("#222233"))

func _add_btn(text: String, pos: Vector2, sz: Vector2, cb: Callable) -> void:
	var b: Button = AssetMap.make_codemon_button(text, sz)
	b.set_position(pos); b.modulate.a = 0.0; b.pressed.connect(cb)
	add_child(b); _buttons.append(b)

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new(); l.text = text; l.set_position(pos)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	add_child(l); return l

func _reveal_title() -> void:
	await get_tree().create_timer(0.3).timeout
	var title := get_node_or_null("Title") as Label
	var glow  := get_node_or_null("TitleGlow") as Label
	var sub   := get_node_or_null("Sub") as Label

	var t1 := create_tween().set_parallel(true)
	if title:
		t1.tween_property(title, "modulate:a",  1.0, 0.7).set_trans(Tween.TRANS_EXPO)
		t1.tween_property(title, "position:y", 140.0, 0.7).set_trans(Tween.TRANS_EXPO)
	if glow:
		t1.tween_property(glow,  "modulate:a",  1.0, 0.7)
		t1.tween_property(glow,  "position:y", 143.0, 0.7).set_trans(Tween.TRANS_EXPO)
	await get_tree().create_timer(0.5).timeout

	if sub:
		var t2 := create_tween()
		t2.tween_property(sub, "modulate:a", 1.0, 0.5)
	await get_tree().create_timer(0.3).timeout

	for i in _buttons.size():
		await get_tree().create_timer(0.07).timeout
		var tw := create_tween()
		tw.tween_property(_buttons[i], "modulate:a", 1.0, 0.3)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and ke.keycode == KEY_ESCAPE:
			get_tree().quit()
