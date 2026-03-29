extends Node2D
# ═══════════════════════════════════════════════════
# CodemonIntro.gd
# Recreates the original Codemon opening cutscene:
#
#  ACT 1 — Logo splash (3 s)
#    The "DK" bracket logo tumbles in from off-screen,
#    letters spinning and scaling like the original
#    AnimationPlayer-driven intro.
#
#  ACT 2 — Street arrival (dialogue)
#    Jimmy walks onto the street tilemap.
#    Two lines of opening dialogue appear in the
#    codemon-style dialog box (typewriter reveal).
#    NPC portrait shown for each speaker.
#
#  ACT 3 — Fade to name entry
#    Screen fades black → GameRouter.go_auth_screen()
#
#  Skippable at any time with SPACE / Enter / click.
# ═══════════════════════════════════════════════════

signal intro_finished

# ── Dialogue data (from codemon i18n) ─────────────────────────────
const DIALOGUE: Array = [
	{
		"actor": "Jimmy",
		"text":  "Wow! If it weren't for the bus strike and this chaos\nin traffic, I wouldn't have been late for my first class.",
		"portrait": "jimmy",
	},
	{
		"actor": "Jimmy",
		"text":  "I can't wait to start my academic journey\nand capture my first Codemon!",
		"portrait": "jimmy",
	},
	{
		"actor": "Doorman",
		"text":  "Hey, kid! This is the AlgoQuest Kingdom.\nHere, programming concepts come alive as Codemons.",
		"portrait": "doorman",
	},
	{
		"actor": "Doorman",
		"text":  "To pass through the kingdom gates, you must master\nData Structures — Queue, Stack, Linked List, Trees, Graphs.",
		"portrait": "doorman",
	},
	{
		"actor": "Jimmy",
		"text":  "Data Structures... I've heard of those!\nAlright — I'm ready. Let's go!",
		"portrait": "jimmy",
	},
]

# ── State ──────────────────────────────────────────────────────────
enum Phase { LOGO, STREET, DIALOGUE, FADE_OUT }
var _phase:        Phase   = Phase.LOGO
var _dial_idx:     int     = 0
var _can_advance:  bool    = false
var _skipped:      bool    = false
var _on_finish:    Callable

# ── Timing ────────────────────────────────────────────────────────
const LOGO_DURATION:    float = 3.2   # seconds for logo animation
const STREET_HOLD:      float = 1.0   # seconds Jimmy walks before dialogue
const TYPEWRITER_SPEED: float = 0.04  # seconds per character
const FADE_DURATION:    float = 0.8

# ── Nodes created at runtime ──────────────────────────────────────
var _bg:             ColorRect
var _street_bg:      Sprite2D
var _overlay:        ColorRect      # fade overlay
var _logo_layer:     Node2D
var _street_layer:   Node2D
var _dialogue_layer: CanvasLayer
var _jimmy:          Sprite2D
var _doorman:        Sprite2D
var _dialog_box:     Control
var _actor_label:    Label
var _text_label:     Label
var _portrait_rect:  ColorRect
var _portrait_sprite: Sprite2D
var _next_hint:      Label
var _tween:          Tween

# ── Logo pieces ────────────────────────────────────────────────────
var _bracket_l:  Sprite2D
var _bracket_r:  Sprite2D
var _letter_d:   Sprite2D
var _letter_k:   Sprite2D
var _logo_full:  Sprite2D
var _logo_timer: float = 0.0

# ── Jimmy walk ────────────────────────────────────────────────────
var _jimmy_frame:  int   = 0
var _jimmy_anim:   float = 0.0
const JIMMY_FRAMES: int  = 16
const JIMMY_W:      int  = 48   # each frame is 48×48

func _ready() -> void:
	_build_bg()
	_start_logo()

func start(on_finish: Callable) -> void:
	_on_finish = on_finish

# ══════════════════════════════════════════════════════════════════
# Background
# ══════════════════════════════════════════════════════════════════
func _build_bg() -> void:
	_bg = ColorRect.new()
	_bg.color = Color("#050508")
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.z_index = 100
	add_child(_overlay)

# ══════════════════════════════════════════════════════════════════
# ACT 1 — Logo
# ══════════════════════════════════════════════════════════════════
func _start_logo() -> void:
	_phase = Phase.LOGO
	_logo_layer = Node2D.new()
	add_child(_logo_layer)

	# Dark background already set; add subtle star particles
	_add_stars()

	# "ALGOQUEST" title label (pixel style)
	var title := Label.new()
	title.text = "ALGOQUEST"
	title.set_position(Vector2(200, 280))
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color("#4D96FF"))
	title.modulate.a = 0.0
	_logo_layer.add_child(title)

	# Codemon logo image
	var logo_tex: Texture2D = AssetMap.load_tex(AssetMap.LOGO_CODEMON)
	if logo_tex:
		_logo_full = Sprite2D.new()
		_logo_full.texture        = logo_tex
		_logo_full.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_logo_full.position       = Vector2(640, 200)
		_logo_full.scale          = Vector2(0.55, 0.55)
		_logo_full.modulate.a     = 0.0
		_logo_layer.add_child(_logo_full)

	# Bracket left — flies in from left
	var br_tex: Texture2D = AssetMap.load_tex(AssetMap.LOGO_BRACKET)
	if br_tex:
		_bracket_l = Sprite2D.new()
		_bracket_l.texture        = br_tex
		_bracket_l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_bracket_l.position       = Vector2(-80, 360)
		_bracket_l.scale          = Vector2(1.8, 1.8)
		_bracket_l.rotation_degrees = -15.0
		_logo_layer.add_child(_bracket_l)

		_bracket_r = Sprite2D.new()
		_bracket_r.texture        = br_tex
		_bracket_r.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_bracket_r.position       = Vector2(1360, 360)
		_bracket_r.scale          = Vector2(1.8, 1.8)
		_bracket_r.flip_h         = true
		_logo_layer.add_child(_bracket_r)

	# Letters D and K
	var d_tex: Texture2D = AssetMap.load_tex(AssetMap.LOGO_D)
	var k_tex: Texture2D = AssetMap.load_tex(AssetMap.LOGO_K)
	if d_tex:
		_letter_d = Sprite2D.new()
		_letter_d.texture        = d_tex
		_letter_d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_letter_d.position       = Vector2(-120, 300)
		_letter_d.scale          = Vector2(1.6, 1.6)
		_letter_d.rotation_degrees = -15.0
		_logo_layer.add_child(_letter_d)
	if k_tex:
		_letter_k = Sprite2D.new()
		_letter_k.texture        = k_tex
		_letter_k.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_letter_k.position       = Vector2(1400, 300)
		_letter_k.scale          = Vector2(1.6, 1.6)
		_letter_k.rotation_degrees = 15.0
		_logo_layer.add_child(_letter_k)

	# "Presents" subtitle
	var presents := Label.new()
	presents.text = "presents"
	presents.set_position(Vector2(520, 500))
	presents.add_theme_font_size_override("font_size", 18)
	presents.add_theme_color_override("font_color", Color("#888899"))
	presents.modulate.a = 0.0
	_logo_layer.add_child(presents)

	# Animate everything with Tween
	_tween = create_tween().set_parallel(false)

	# Brackets fly in simultaneously (parallel)
	var par1: = create_tween().set_parallel(true)
	if _bracket_l:
		par1.tween_property(_bracket_l, "position", Vector2(280, 360), 0.5).set_trans(Tween.TRANS_BACK)
		par1.tween_property(_bracket_l, "rotation_degrees", 0.0, 0.5).set_trans(Tween.TRANS_EXPO)
	if _bracket_r:
		par1.tween_property(_bracket_r, "position", Vector2(1000, 360), 0.5).set_trans(Tween.TRANS_BACK)
	if _letter_d:
		par1.tween_property(_letter_d, "position", Vector2(380, 300), 0.5).set_trans(Tween.TRANS_BACK)
		par1.tween_property(_letter_d, "rotation_degrees", 0.0, 0.5)
	if _letter_k:
		par1.tween_property(_letter_k, "position", Vector2(820, 300), 0.5).set_trans(Tween.TRANS_BACK)
		par1.tween_property(_letter_k, "rotation_degrees", 0.0, 0.5)

	await get_tree().create_timer(0.6).timeout

	# Letters do a little bounce (slight rotation wiggle)
	var wig := create_tween().set_parallel(true)
	if _letter_d:
		wig.tween_property(_letter_d, "rotation_degrees", 8.0, 0.15).set_trans(Tween.TRANS_SINE)
	if _letter_k:
		wig.tween_property(_letter_k, "rotation_degrees", -8.0, 0.15).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(0.15).timeout
	var wig2 := create_tween().set_parallel(true)
	if _letter_d:
		wig2.tween_property(_letter_d, "rotation_degrees", 0.0, 0.15).set_trans(Tween.TRANS_SINE)
	if _letter_k:
		wig2.tween_property(_letter_k, "rotation_degrees", 0.0, 0.15).set_trans(Tween.TRANS_SINE)

	await get_tree().create_timer(0.2).timeout

	# Fade in codemon logo
	if _logo_full:
		var fl := create_tween()
		fl.tween_property(_logo_full, "modulate:a", 1.0, 0.6)

	# Fade in title
	var tl := create_tween()
	tl.tween_property(title, "modulate:a", 1.0, 0.5)
	var pl := create_tween()
	pl.tween_property(presents, "modulate:a", 1.0, 0.4)

	# Hold for a moment then fade out logo and transition to street
	await get_tree().create_timer(1.5).timeout

	# Skip hint
	var skip := Label.new()
	skip.text = "Press SPACE / ENTER to skip"
	skip.set_position(Vector2(420, 680))
	skip.add_theme_font_size_override("font_size", 12)
	skip.add_theme_color_override("font_color", Color("#333355"))
	_logo_layer.add_child(skip)

	await get_tree().create_timer(0.8).timeout

	# Fade out logo
	var fo := create_tween()
	fo.tween_property(_logo_layer, "modulate:a", 0.0, 0.5)
	await fo.finished

	_logo_layer.queue_free()
	_start_street()

func _add_stars() -> void:
	# Simple static stars drawn as small ColorRects
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for _i in 60:
		var star := ColorRect.new()
		var brightness: float = rng.randf_range(0.3, 0.9)
		star.color = Color(brightness, brightness, brightness * 1.2, rng.randf_range(0.4, 1.0))
		star.set_position(Vector2(rng.randf_range(0, 1280), rng.randf_range(0, 500)))
		var sz: float = rng.randf_range(1.0, 3.0)
		star.set_size(Vector2(sz, sz))
		_logo_layer.add_child(star)

# ══════════════════════════════════════════════════════════════════
# ACT 2 — Street arrival
# ══════════════════════════════════════════════════════════════════
func _start_street() -> void:
	_phase = Phase.STREET
	_street_layer = Node2D.new()
	add_child(_street_layer)

	# Street background using codemon street_tile
	var tile_tex: Texture2D = AssetMap.load_tex(AssetMap.MAP_TILES["street"])
	if tile_tex:
		for row in 4:
			for col in 4:
				var s := Sprite2D.new()
				s.texture = tile_tex
				s.position = Vector2(col * 384 + 192, row * 320 + 160)
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s.z_index = -10
				_street_layer.add_child(s)

	# Dark overlay for readability
	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0.45)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.z_index = -5
	_street_layer.add_child(ov)

	# Scene title
	var scene_title := Label.new()
	scene_title.text = "Street — First Day"
	scene_title.set_position(Vector2(20, 16))
	scene_title.add_theme_font_size_override("font_size", 14)
	scene_title.add_theme_color_override("font_color", Color("#FFD93D"))
	_street_layer.add_child(scene_title)

	# Some trees for decoration
	var tree_tex: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS.get("tree_01", ""))
	if tree_tex:
		for pos in [Vector2(80,200), Vector2(1180,200), Vector2(80,450), Vector2(1180,450)]:
			var t := Sprite2D.new()
			t.texture = tree_tex; t.position = pos
			t.scale = Vector2(2.5, 2.5)
			t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			t.z_index = 2; _street_layer.add_child(t)

	# Doorman NPC (right side, facing left)
	var door_tex: Texture2D = AssetMap.load_tex(
		"res://assets/codemon/art/character/npc/doorman.png")
	if door_tex:
		_doorman = Sprite2D.new()
		_doorman.texture = door_tex
		_doorman.hframes = 2; _doorman.frame = 0
		_doorman.position = Vector2(950, 340)
		_doorman.scale = Vector2(4.0, 4.0)
		_doorman.flip_h = true
		_doorman.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_doorman.z_index = 5; _street_layer.add_child(_doorman)

		# Doorman idle blink
		var dt := Timer.new(); dt.wait_time = 1.5; dt.autostart = true
		dt.timeout.connect(func():
			if is_instance_valid(_doorman):
				_doorman.frame = (_doorman.frame + 1) % 2
		); _street_layer.add_child(dt)

	# Jimmy sprite — starts off left edge
	var jimmy_tex: Texture2D = AssetMap.load_tex(AssetMap.JIMMY)
	if jimmy_tex:
		_jimmy = Sprite2D.new()
		_jimmy.texture = jimmy_tex
		_jimmy.hframes = JIMMY_FRAMES
		_jimmy.frame = 0   # walk-right frames
		_jimmy.position = Vector2(-40, 340)
		_jimmy.scale = Vector2(4.0, 4.0)
		_jimmy.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_jimmy.z_index = 5; _street_layer.add_child(_jimmy)

	# Fade in the street
	_street_layer.modulate.a = 0.0
	var fi := create_tween()
	fi.tween_property(_street_layer, "modulate:a", 1.0, 0.6)
	await fi.finished

	# Jimmy walks in from left
	_phase = Phase.STREET
	var walk := create_tween()
	walk.tween_property(_jimmy, "position", Vector2(380, 340), 1.8).set_trans(Tween.TRANS_LINEAR)
	await walk.finished

	await get_tree().create_timer(0.3).timeout
	_start_dialogue()

# Jimmy walk animation runs in _process
func _process(delta: float) -> void:
	if _phase == Phase.STREET and is_instance_valid(_jimmy):
		_jimmy_anim += delta
		if _jimmy_anim >= 0.12:
			_jimmy_anim = 0.0
			_jimmy_frame = (_jimmy_frame + 1) % 4  # first 4 frames = walk right
			_jimmy.frame = _jimmy_frame

# ══════════════════════════════════════════════════════════════════
# ACT 3 — Dialogue
# ══════════════════════════════════════════════════════════════════
func _start_dialogue() -> void:
	_phase = Phase.DIALOGUE
	_dial_idx = 0
	_build_dialog_box()
	_show_dialogue(_dial_idx)

func _build_dialog_box() -> void:
	_dialogue_layer = CanvasLayer.new()
	_dialogue_layer.layer = 10
	add_child(_dialogue_layer)

	# Dialog box background — mimic codemon's dialog_box.png style
	var box_bg := ColorRect.new()
	box_bg.color = Color("#0d0d18")
	box_bg.set_position(Vector2(0, 560))
	box_bg.set_size(Vector2(1280, 160))
	_dialogue_layer.add_child(box_bg)

	# Top border line
	var border := ColorRect.new()
	border.color = Color("#4D96FF")
	border.set_position(Vector2(0, 558))
	border.set_size(Vector2(1280, 3))
	_dialogue_layer.add_child(border)

	# Try to use codemon dialog_box.png
	var box_tex: Texture2D = AssetMap.load_tex(
		"res://assets/codemon/art/component/dialog_box.png")
	if box_tex:
		var box_sprite := Sprite2D.new()
		box_sprite.texture = box_tex
		box_sprite.position = Vector2(640, 640)
		box_sprite.scale = Vector2(1280.0 / box_tex.get_width(), 160.0 / box_tex.get_height())
		box_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_dialogue_layer.add_child(box_sprite)

	# Portrait area (left side of dialog)
	_portrait_rect = ColorRect.new()
	_portrait_rect.color = Color("#13131f")
	_portrait_rect.set_position(Vector2(12, 572))
	_portrait_rect.set_size(Vector2(96, 136))
	_dialogue_layer.add_child(_portrait_rect)

	_portrait_sprite = Sprite2D.new()
	_portrait_sprite.position = Vector2(60, 640)
	_portrait_sprite.scale = Vector2(3.0, 3.0)
	_portrait_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dialogue_layer.add_child(_portrait_sprite)

	# Actor name
	_actor_label = Label.new()
	_actor_label.set_position(Vector2(124, 566))
	_actor_label.add_theme_font_size_override("font_size", 16)
	_actor_label.add_theme_color_override("font_color", Color("#FFD93D"))
	_dialogue_layer.add_child(_actor_label)

	# Dialogue text (typewriter)
	_text_label = Label.new()
	_text_label.set_position(Vector2(124, 592))
	_text_label.set_size(Vector2(1120, 110))
	_text_label.add_theme_font_size_override("font_size", 15)
	_text_label.add_theme_color_override("font_color", Color("#e8e8f0"))
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_layer.add_child(_text_label)

	# "Next" hint arrow
	_next_hint = Label.new()
	_next_hint.text = "▼"
	_next_hint.set_position(Vector2(1230, 690))
	_next_hint.add_theme_font_size_override("font_size", 18)
	_next_hint.add_theme_color_override("font_color", Color("#4D96FF"))
	_next_hint.modulate.a = 0.0
	_dialogue_layer.add_child(_next_hint)

func _show_dialogue(idx: int) -> void:
	if idx >= DIALOGUE.size():
		_finish()
		return

	_can_advance = false
	_next_hint.modulate.a = 0.0

	var entry: Dictionary = DIALOGUE[idx]
	var actor: String = entry["actor"] as String
	var text:  String = entry["text"]  as String
	var portrait_key: String = entry["portrait"] as String

	_actor_label.text = actor

	# Load portrait
	var port_tex: Texture2D = null
	if portrait_key == "jimmy":
		port_tex = AssetMap.load_tex(AssetMap.JIMMY)
		if port_tex:
			_portrait_sprite.texture = port_tex
			_portrait_sprite.hframes = JIMMY_FRAMES
			_portrait_sprite.frame   = 0   # neutral frame
			_portrait_sprite.scale   = Vector2(2.8, 2.8)
			_portrait_sprite.position = Vector2(60, 630)
	elif portrait_key == "doorman":
		port_tex = AssetMap.load_tex(
			"res://assets/codemon/art/character/npc/doorman.png")
		if port_tex:
			_portrait_sprite.texture = port_tex
			_portrait_sprite.hframes = 2
			_portrait_sprite.frame   = 0
			_portrait_sprite.scale   = Vector2(3.2, 3.2)
			_portrait_sprite.position = Vector2(60, 630)

	# Highlight speaker on stage
	if is_instance_valid(_jimmy):
		_jimmy.modulate = Color(1.0, 1.0, 1.0) if portrait_key == "jimmy" else Color(0.5, 0.5, 0.5)
	if is_instance_valid(_doorman):
		_doorman.modulate = Color(1.0, 1.0, 1.0) if portrait_key == "doorman" else Color(0.5, 0.5, 0.5)

	# Typewriter reveal
	_text_label.text = text
	_text_label.visible_ratio = 0.0
	var tw := create_tween()
	tw.tween_property(_text_label, "visible_ratio", 1.0,
		float(text.length()) * TYPEWRITER_SPEED)
	await tw.finished

	_can_advance = true
	# Blink "next" arrow
	var blink := create_tween().set_loops()
	blink.tween_property(_next_hint, "modulate:a", 1.0, 0.4)
	blink.tween_property(_next_hint, "modulate:a", 0.2, 0.4)

func _advance_dialogue() -> void:
	if not _can_advance: return
	if _skipped: return
	_dial_idx += 1
	_show_dialogue(_dial_idx)

# ══════════════════════════════════════════════════════════════════
# Input
# ══════════════════════════════════════════════════════════════════
func _input(event: InputEvent) -> void:
	if _skipped: return

	var pressed: bool = false
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and (ke.keycode == KEY_SPACE or ke.keycode == KEY_ENTER
				or ke.keycode == KEY_ESCAPE):
			pressed = true
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			pressed = true

	if not pressed: return

	match _phase:
		Phase.LOGO:
			_skip()
		Phase.STREET:
			_skip()
		Phase.DIALOGUE:
			if _can_advance:
				_advance_dialogue()
			else:
				# Fast-forward typewriter
				_text_label.visible_ratio = 1.0

func _skip() -> void:
	if _skipped: return
	_skipped = true
	for child in get_children():
		child.queue_free()
	_build_bg()
	_finish()

# ══════════════════════════════════════════════════════════════════
# Finish → fade black → next scene
# ══════════════════════════════════════════════════════════════════
func _finish() -> void:
	_phase = Phase.FADE_OUT
	var fo := create_tween()
	fo.tween_property(_overlay, "modulate:a", 1.0, FADE_DURATION)
	await fo.finished

	ProgressTracker.mark_cutscene_seen("codemon_intro")

	if _on_finish.is_valid():
		_on_finish.call()
	else:
		GameRouter.go_auth_screen()
