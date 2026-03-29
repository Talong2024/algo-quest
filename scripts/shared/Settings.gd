extends Node2D

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#0a0a0f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_lbl("Settings", Vector2(540, 80), 32, Color("#e8e8f0"))

	_slider_row("Master Volume", Vector2(440, 180),
		SaveManager.get_volume_master(),
		func(v: float): AudioManager.set_master_volume(v))
	_slider_row("Music Volume", Vector2(440, 250),
		SaveManager.get_volume_music(),
		func(v: float): AudioManager.set_music_volume(v))
	_slider_row("SFX Volume", Vector2(440, 320),
		SaveManager.get_volume_sfx(),
		func(v: float): AudioManager.set_sfx_volume(v))

	_lbl("Save file: user://algoquest_save.json  (%.1f KB)" % \
		SaveManager.get_save_size_kb(),
		Vector2(440, 400), 12, Color("#555577"))

	var back := Button.new()
	back.text = "Back"
	back.set_position(Vector2(440, 460))
	back.set_size(Vector2(200, 48))
	back.add_theme_font_size_override("font_size", 16)
	back.pressed.connect(func(): GameRouter.go_main_menu())
	add_child(back)

func _slider_row(label: String, pos: Vector2, val: float, cb: Callable) -> void:
	_lbl(label, pos, 14, Color("#888899"))
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step      = 0.05
	s.value     = val
	s.set_position(pos + Vector2(0, 28))
	s.set_size(Vector2(320, 24))
	s.value_changed.connect(cb)
	add_child(s)
	var val_lbl := Label.new()
	val_lbl.set_position(pos + Vector2(334, 28))
	val_lbl.add_theme_font_size_override("font_size", 12)
	val_lbl.add_theme_color_override("font_color", Color("#888899"))
	val_lbl.text = "%d%%" % int(val * 100)
	add_child(val_lbl)
	s.value_changed.connect(func(v: float): val_lbl.text = "%d%%" % int(v * 100))

func _lbl(t: String, p: Vector2, s: int, c: Color) -> void:
	var l := Label.new()
	l.text = t
	l.set_position(p)
	l.add_theme_font_size_override("font_size", s)
	l.add_theme_color_override("font_color", c)
	add_child(l)
