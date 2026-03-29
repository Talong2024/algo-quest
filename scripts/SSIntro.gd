extends Node2D
# ═══════════════════════════════════════════════════
# SSIntro.gd  —  "Syntax Squad" logo splash
#
# Plays ONCE on very first app launch (before main menu).
# Recreates the codemon bracket animation with:
#   [SS] instead of [DK]
# Letter S tumbles in from left, second S from right,
# then "SYNTAX SQUAD" text fades in below brackets.
# Total: ~4 seconds → fades to MainMenu.
# Skippable with Space / Enter / click.
# ═══════════════════════════════════════════════════

var _skipped: bool   = false
var _on_done: Callable

func _ready() -> void:
	_build()

func start(on_done: Callable) -> void:
	_on_done = on_done

func _build() -> void:
	# Black background
	var bg := ColorRect.new()
	bg.color = Color("#050508")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Fade overlay
	var ov := ColorRect.new()
	ov.name = "Overlay"
	ov.color = Color(0, 0, 0, 0)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.z_index = 100
	add_child(ov)

	_add_stars(bg)
	_animate()

# #REGION:BACKGROUND — Star particle decorations
func _add_stars(parent: Node) -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 77
	for _i in 80:
		var s := ColorRect.new()
		var b: float = rng.randf_range(0.3, 1.0)
		s.color = Color(b, b, b * 1.1, rng.randf_range(0.3, 0.9))
		s.set_position(Vector2(rng.randf_range(0,1280), rng.randf_range(0,720)))
		var sz: float = rng.randf_range(1.0, 3.0)
		s.set_size(Vector2(sz, sz))
		parent.add_child(s)

# #REGION:LOGO — [SS] bracket logo animation sequence
func _animate() -> void:
	# ── Bracket sprites ──────────────────────────
	var br_tex: Texture2D = AssetMap.load_tex(AssetMap.LOGO_BRACKET)

	var bracket_l := Sprite2D.new()
	bracket_l.texture        = br_tex
	bracket_l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bracket_l.position       = Vector2(-120, 360)
	bracket_l.scale          = Vector2(2.2, 2.2)
	bracket_l.rotation_degrees = -18.0
	add_child(bracket_l)

	var bracket_r := Sprite2D.new()
	bracket_r.texture        = br_tex
	bracket_r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bracket_r.position       = Vector2(1400, 360)
	bracket_r.scale          = Vector2(2.2, 2.2)
	bracket_r.flip_h         = true
	add_child(bracket_r)

	# ── "S" letters (drawn as Labels since we don't have letter sprites) ──
	var letter_s1 := _make_letter("S", Vector2(-140, 240))
	var letter_s2 := _make_letter("S", Vector2(1420, 240))

	# ── Subtitle labels ───────────────────────────
	var title_lbl := Label.new()
	title_lbl.text = "SYNTAX SQUAD"
	title_lbl.set_position(Vector2(340, 430))
	title_lbl.add_theme_font_size_override("font_size", 42)
	title_lbl.add_theme_color_override("font_color", Color("#4D96FF"))
	title_lbl.modulate.a = 0.0
	add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "presents"
	sub_lbl.set_position(Vector2(560, 488))
	sub_lbl.add_theme_font_size_override("font_size", 18)
	sub_lbl.add_theme_color_override("font_color", Color("#555577"))
	sub_lbl.modulate.a = 0.0
	add_child(sub_lbl)

	var skip_lbl := Label.new()
	skip_lbl.text = "Press SPACE or click to skip"
	skip_lbl.set_position(Vector2(450, 680))
	skip_lbl.add_theme_font_size_override("font_size", 12)
	skip_lbl.add_theme_color_override("font_color", Color("#222233"))
	add_child(skip_lbl)

	# ── Animation sequence ───────────────────────
	_run_sequence(bracket_l, bracket_r, letter_s1, letter_s2, title_lbl, sub_lbl)

func _make_letter(ch: String, pos: Vector2) -> Label:
	var l := Label.new()
	l.text = ch
	l.set_position(pos)
	l.add_theme_font_size_override("font_size", 120)
	l.add_theme_color_override("font_color", Color("#4D96FF"))
	add_child(l)
	return l

func _run_sequence(bl, br, sl, sr, title, sub) -> void:
	# 0.0s — brackets + letters fly in
	var p1 := create_tween().set_parallel(true)
	p1.tween_property(bl, "position", Vector2(270, 360), 0.55).set_trans(Tween.TRANS_BACK)
	p1.tween_property(bl, "rotation_degrees", 0.0, 0.55).set_trans(Tween.TRANS_EXPO)
	p1.tween_property(br, "position", Vector2(950, 360), 0.55).set_trans(Tween.TRANS_BACK)
	p1.tween_property(sl, "position", Vector2(370, 240), 0.55).set_trans(Tween.TRANS_BACK)
	p1.tween_property(sl, "rotation_degrees", 0.0, 0.55)
	p1.tween_property(sr, "position", Vector2(740, 240), 0.55).set_trans(Tween.TRANS_BACK)
	p1.tween_property(sr, "rotation_degrees", 0.0, 0.55)
	await get_tree().create_timer(0.6).timeout

	# 0.6s — letters wiggle
	var wig := create_tween().set_parallel(true)
	wig.tween_property(sl, "rotation_degrees", 10.0, 0.14).set_trans(Tween.TRANS_SINE)
	wig.tween_property(sr, "rotation_degrees", -10.0, 0.14).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.15).timeout
	var wig2 := create_tween().set_parallel(true)
	wig2.tween_property(sl, "rotation_degrees", 0.0, 0.14).set_trans(Tween.TRANS_SINE)
	wig2.tween_property(sr, "rotation_degrees", 0.0, 0.14).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.2).timeout

	# 0.95s — title + sub fade in
	var ft := create_tween().set_parallel(true)
	ft.tween_property(title, "modulate:a", 1.0, 0.5)
	ft.tween_property(sub,   "modulate:a", 1.0, 0.4)
	await get_tree().create_timer(1.6).timeout

	# 2.55s — hold then fade out everything
	var fo := create_tween()
	fo.tween_property(self, "modulate:a", 0.0, 0.7)
	await fo.finished

	_finish()

func _input(event: InputEvent) -> void:
	if _skipped: return
	var hit: bool = false
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and (ke.keycode == KEY_SPACE or ke.keycode == KEY_ENTER
				or ke.keycode == KEY_ESCAPE):
			hit = true
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed: hit = true
	if hit:
		_skipped = true
		var fo := create_tween()
		fo.tween_property(self, "modulate:a", 0.0, 0.3)
		await fo.finished
		_finish()

func _finish() -> void:
	if _on_done.is_valid():
		_on_done.call()
	else:
		GameRouter.go_main_menu()
