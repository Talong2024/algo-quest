extends Node2D
# ═══════════════════════════════════════════════════
# MainMenu.gd
# #REGION:UI — AlgoQuest main menu
# Inspired by: youtube.com/watch?v=zovnfSytasI
#   - Video/animated background
#   - Title slides up and fades in via AnimationPlayer
#   - Buttons stagger in after title
#   - Fade-in from black on entry
#   - Fade-to-black before scene change
# ═══════════════════════════════════════════════════

# #REGION:UI — Node refs from MainMenu.tscn
@onready var _title_lbl:   Label          = $UI/TitleGroup/TitleLabel
@onready var _title_glow:  Label          = $UI/TitleGroup/TitleGlow
@onready var _subtitle:    Label          = $UI/TitleGroup/SubtitleLabel
@onready var _menu_panel:  PanelContainer = $UI/MenuPanel
@onready var _panel_accent:ColorRect      = $UI/PanelAccent
@onready var _btn_container:VBoxContainer = $UI/MenuPanel/ButtonContainer
@onready var _fade:        ColorRect      = $UI/FadeOverlay
@onready var _video_bg:    Node2D         = $VideoBackground
@onready var _anim:        AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	_load_video_background()
	_build_menu_buttons()
	_build_and_play_intro_animation()
	AudioManager.play_bgm("menu")

# ══════════════════════════════════════════════════
# #REGION:VIDEO — Try to load .ogv background video
# ══════════════════════════════════════════════════
func _load_video_background() -> void:
	var ogv_path: String = "res://assets/video/main_menu_bg.ogv"
	if FileAccess.file_exists(ogv_path):
		var stream: Resource = load(ogv_path)
		if stream is VideoStream:
			var vp := VideoStreamPlayer.new()
			vp.stream   = stream as VideoStream
			vp.autoplay = true; vp.loop = true; vp.expand = true
			vp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_video_bg.add_child(vp)
			return
	# Fallback: tile the street map
	var tile: Texture2D = AssetMap.load_tex(AssetMap.MAP_TILES["street"])
	if tile:
		for row in 3:
			for col in 4:
				var s := Sprite2D.new()
				s.texture = tile; s.position = Vector2(col*384+192, row*320+160)
				s.modulate = Color(1,1,1,0.18)
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				_video_bg.add_child(s)

# ══════════════════════════════════════════════════
# #REGION:BUTTONS — Build codemon-styled buttons
# ══════════════════════════════════════════════════
func _build_menu_buttons() -> void:
	var has_save: bool = SaveManager.get_setting("char_variant","") != ""

	if has_save:
		_add_btn("▶  Continue",    func(): _go_to(GameRouter.go_auth_screen))
		_add_btn("🆕  New Game",   func():
			SaveManager.set_setting("char_variant","")
			ProgressTracker.reset_all()
			_go_to(GameRouter.go_auth_screen))
	else:
		_add_btn("▶  Play",        func(): _go_to(GameRouter.go_auth_screen))

	_add_btn("⚙  Settings",       func(): _go_to(GameRouter.go_settings))
	_add_btn("★  Credits",        func(): _go_to(GameRouter.go_credits))

func _add_btn(text: String, cb: Callable) -> void:
	var b: Button = AssetMap.make_codemon_button(text, Vector2(260, 46))
	b.modulate = Color(1, 1, 1, 0)   # starts invisible, animated in
	b.pressed.connect(cb)
	_btn_container.add_child(b)

func _go_to(fn: Callable) -> void:
	# Fade to black then call the routing function
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.35)
	tw.tween_callback(fn)

# ══════════════════════════════════════════════════
# #REGION:ANIMATION — Intro sequence via AnimationPlayer
# ══════════════════════════════════════════════════
func _build_and_play_intro_animation() -> void:
	var anim := Animation.new()
	anim.length = 2.2

	# Fade overlay goes from black → transparent (fade in from black)
	var t_fade: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_fade, "UI/FadeOverlay:color:a")
	anim.track_insert_key(t_fade, 0.0, 1.0)
	anim.track_insert_key(t_fade, 0.6, 0.0)

	# Title slides UP from below + fades in
	var t_title_y: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_title_y, "UI/TitleGroup/TitleLabel:position:y")
	anim.track_set_interpolation_type(t_title_y, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(t_title_y, 0.3, 195.0)
	anim.track_insert_key(t_title_y, 0.9, 140.0)

	var t_title_a: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_title_a, "UI/TitleGroup/TitleLabel:modulate:a")
	anim.track_insert_key(t_title_a, 0.3, 0.0)
	anim.track_insert_key(t_title_a, 0.9, 1.0)

	# Glow follows title
	var t_glow_y: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_glow_y, "UI/TitleGroup/TitleGlow:position:y")
	anim.track_set_interpolation_type(t_glow_y, Animation.INTERPOLATION_CUBIC)
	anim.track_insert_key(t_glow_y, 0.3, 198.0)
	anim.track_insert_key(t_glow_y, 0.9, 143.0)

	var t_glow_a: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_glow_a, "UI/TitleGroup/TitleGlow:theme_override_colors/font_color:a")
	anim.track_insert_key(t_glow_a, 0.3, 0.0)
	anim.track_insert_key(t_glow_a, 0.9, 0.3)

	# Subtitle fades in
	var t_sub_a: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_sub_a, "UI/TitleGroup/SubtitleLabel:modulate:a")
	anim.track_insert_key(t_sub_a, 0.8, 0.0)
	anim.track_insert_key(t_sub_a, 1.2, 1.0)

	# Panel slides in + fades
	var t_panel_a: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_panel_a, "UI/MenuPanel:modulate:a")
	anim.track_insert_key(t_panel_a, 1.0, 0.0)
	anim.track_insert_key(t_panel_a, 1.4, 1.0)

	var t_accent_a: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t_accent_a, "UI/PanelAccent:modulate:a")
	anim.track_insert_key(t_accent_a, 1.0, 0.0)
	anim.track_insert_key(t_accent_a, 1.4, 1.0)

	# Register and play
	var lib := AnimationLibrary.new()
	lib.add_animation("menu_in", anim)
	_anim.add_animation_library("", lib)
	_anim.animation_finished.connect(_on_intro_done)
	_anim.play("menu_in")

func _on_intro_done(_anim_name: StringName) -> void:
	# Stagger buttons in after main animation finishes
	var btns: Array = _btn_container.get_children()
	for i in btns.size():
		var btn := btns[i] as Button
		var tw := create_tween()
		tw.tween_interval(i * 0.08)
		tw.tween_property(btn, "modulate:a", 1.0, 0.3)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and ke.keycode == KEY_ESCAPE:
			get_tree().quit()
