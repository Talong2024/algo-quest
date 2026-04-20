extends Node2D
# ═══════════════════════════════════════════════════
# SSIntro.gd — Syntax Squad logo splash
# Uses AnimationPlayer for the bracket + letter reveal.
# Inspired by: youtube.com/watch?v=zovnfSytasI
#   - Fast bracket slam from sides
#   - Letters bounce in
#   - Title fade + scale
#   - Hold → fade to black → MainMenu
# ═══════════════════════════════════════════════════

var _skipped: bool = false

# #REGION:LOGO — Node refs from SSIntro.tscn
@onready var _logo_group:   Node2D         = $LogoGroup
@onready var _bracket_l:    Sprite2D       = $LogoGroup/BracketLeft
@onready var _bracket_r:    Sprite2D       = $LogoGroup/BracketRight
@onready var _letter_s1:    Label          = $LogoGroup/LetterS1
@onready var _letter_s2:    Label          = $LogoGroup/LetterS2
@onready var _title_lbl:    Label          = $LogoGroup/TitleLabel
@onready var _presents_lbl: Label          = $LogoGroup/PresentsLabel
@onready var _fade_overlay: ColorRect      = $FadeOverlay
@onready var _stars_node:   Node2D         = $Stars
@onready var _anim:         AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	_load_bracket_texture()
	_add_stars()
	_build_and_play_animation()

# #REGION:LOGO — Load bracket from AssetMap
func _load_bracket_texture() -> void:
	var tex: Texture2D = AssetMap.load_tex(AssetMap.LOGO_BRACKET)
	if tex:
		_bracket_l.texture = tex
		_bracket_r.texture = tex

# #REGION:BACKGROUND — Procedural star field
func _add_stars() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 1337
	for _i in 80:
		var s := ColorRect.new()
		var b: float = rng.randf_range(0.3, 1.0)
		s.color = Color(b, b, b * 1.1, rng.randf_range(0.3, 0.9))
		s.set_position(Vector2(rng.randf_range(0, 1280), rng.randf_range(0, 720)))
		var sz: float = rng.randf_range(1.5, 3.5)
		s.set_size(Vector2(sz, sz))
		_stars_node.add_child(s)

# #REGION:ANIMATION — Build AnimationPlayer tracks programmatically
# Bracket slam → letter bounce → title reveal → hold → fade out
func _build_and_play_animation() -> void:
	var anim := Animation.new()
	anim.length = 4.2

	# ── Logo group fade in ─────────────────────────
	var t_logo_a: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_logo_a, "LogoGroup:modulate:a")
	anim.track_insert_key(t_logo_a, 0.0, 0.0)
	anim.track_insert_key(t_logo_a, 0.05, 1.0)

	# ── Bracket left: slides from off-screen-left ──
	var t_bl_x: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_bl_x, "LogoGroup/BracketLeft:position:x")
	anim.track_set_interpolation_type(t_bl_x, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(t_bl_x, 0.0,  -480.0)
	anim.track_insert_key(t_bl_x, 0.38, -260.0)
	anim.track_insert_key(t_bl_x, 0.44, -240.0)
	anim.track_insert_key(t_bl_x, 0.50, -260.0)

	# ── Bracket right: slides from off-screen-right ─
	var t_br_x: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_br_x, "LogoGroup/BracketRight:position:x")
	anim.track_set_interpolation_type(t_br_x, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(t_br_x, 0.0,   480.0)
	anim.track_insert_key(t_br_x, 0.38,  260.0)
	anim.track_insert_key(t_br_x, 0.44,  240.0)
	anim.track_insert_key(t_br_x, 0.50,  260.0)

	# ── Letter S1: drops from above + bounces ──────
	var t_s1_y: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_s1_y, "LogoGroup/LetterS1:position:y")
	anim.track_set_interpolation_type(t_s1_y, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(t_s1_y, 0.35, -200.0)
	anim.track_insert_key(t_s1_y, 0.58,  -70.0)
	anim.track_insert_key(t_s1_y, 0.64,  -55.0)
	anim.track_insert_key(t_s1_y, 0.70,  -70.0)

	# ── Letter S2: drops from above ────────────────
	var t_s2_y: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_s2_y, "LogoGroup/LetterS2:position:y")
	anim.track_set_interpolation_type(t_s2_y, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(t_s2_y, 0.40, -200.0)
	anim.track_insert_key(t_s2_y, 0.62,  -70.0)
	anim.track_insert_key(t_s2_y, 0.68,  -55.0)
	anim.track_insert_key(t_s2_y, 0.74,  -70.0)

	# ── Title: fade in + scale up ──────────────────
	var t_title_a: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_title_a, "LogoGroup/TitleLabel:modulate:a")
	anim.track_insert_key(t_title_a, 0.7, 0.0)
	anim.track_insert_key(t_title_a, 1.0, 1.0)

	var t_pres_a: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_pres_a, "LogoGroup/PresentsLabel:modulate:a")
	anim.track_insert_key(t_pres_a, 0.9, 0.0)
	anim.track_insert_key(t_pres_a, 1.2, 1.0)

	# ── Hold, then fade to black ───────────────────
	var t_fade: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_fade, "FadeOverlay:color:a")
	anim.track_insert_key(t_fade, 0.0,  0.0)
	anim.track_insert_key(t_fade, 3.4,  0.0)
	anim.track_insert_key(t_fade, 4.1,  1.0)

	# Register and play
	var lib := AnimationLibrary.new()
	lib.add_animation("intro", anim)
	_anim.add_animation_library("", lib)
	_anim.animation_finished.connect(_on_anim_finished)
	_anim.play("intro")

func _on_anim_finished(_name: StringName) -> void:
	_finish()

func _input(event: InputEvent) -> void:
	if _skipped: return
	var hit: bool = false
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and ke.keycode in [KEY_SPACE, KEY_ENTER, KEY_ESCAPE]:
			hit = true
	if event is InputEventMouseButton:
		if (event as InputEventMouseButton).pressed: hit = true
	if hit: _skip()

func _skip() -> void:
	if _skipped: return
	_skipped = true
	_anim.stop()
	var tw := create_tween()
	tw.tween_property(_fade_overlay, "color:a", 1.0, 0.3)
	tw.tween_callback(_finish)

func _finish() -> void:
	ProgressTracker.mark_cutscene_seen("ss_intro")
	# New players go straight to character creation after the intro
	if SaveManager.get_player_appearance().is_empty():
		GameRouter.go_char_create()
	else:
		GameRouter.go_main_menu()
