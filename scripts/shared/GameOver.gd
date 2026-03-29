extends Node2D

var _chapter: int = 1

func receive_params(p: Dictionary) -> void:
	_chapter = p.get("chapter", 1) as int
	AudioManager.play_sfx("lose")
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0a0005")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_lbl("Algorithm Failed!", Vector2(380, 200), 44, Color("#FF6B6B"))
	_lbl("Study the DSA panel and try again.",
		Vector2(400, 260), 16, Color("#888899"))

	var attempts: int = ProgressTracker.get_chapter_data(_chapter)\
		.get("attempts", 0) as int
	_lbl("Attempt #%d" % attempts, Vector2(560, 308), 14, Color("#555577"))

	_btn("Retry Chapter", Vector2(440, 380), Color("#FF6B6B"),
		func(): GameRouter.start_chapter(_chapter))
	_btn("Progress", Vector2(440, 440), Color("#4D96FF"),
		func(): GameRouter.go_progress_screen())
	_btn("World Map", Vector2(440, 500), Color("#555577"),
		func(): GameRouter.go_world_map())

func _lbl(t: String, p: Vector2, s: int, c: Color) -> void:
	var l := Label.new()
	l.text = t
	l.set_position(p)
	l.add_theme_font_size_override("font_size", s)
	l.add_theme_color_override("font_color", c)
	add_child(l)

func _btn(t: String, p: Vector2, c: Color, cb: Callable) -> void:
	var b := Button.new()
	b.text = t
	b.set_position(p)
	b.set_size(Vector2(400, 52))
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", c)
	b.pressed.connect(cb)
	add_child(b)
