extends Node2D
# ═══════════════════════════════════════════════════
# AuthScreen.gd  —  Sign In / Sign Up
#
# Fields:
#   Name (sign-up only)
#   Email
#   Password
#   Year (sign-up: 1st–4th year)
#   Course (sign-up: dropdown)
#
# Flow:
#   Sign up  → Firebase Auth createUser
#              → Firestore /players/{uid}
#              → CharacterSelect → WorldMap
#   Sign in  → Firebase Auth signIn
#              → load Firestore doc
#              → WorldMap
#   Offline  → skip, use local save only
# ═══════════════════════════════════════════════════

const COURSES: Array = [
	"Computer Science",
	"Information Systems",
	"Software Engineering",
	"Data Science",
	"Cybersecurity",
	"Computer Engineering",
	"Game Development",
	"Artificial Intelligence",
	"Web Development",
	"Other",
]

const YEARS: Array = [
	"1st Year",
	"2nd Year",
	"3rd Year",
	"4th Year",
	"Graduate",
]

var _mode:          String = "signin"   # "signin" or "signup"
var _busy:          bool   = false

# UI refs
var _panel:         ColorRect
var _title_lbl:     Label
var _error_lbl:     Label
var _name_row:      Control
var _year_row:      Control
var _course_row:    Control
var _email_field:   LineEdit
var _pass_field:    LineEdit
var _name_field:    LineEdit
var _year_opt:      OptionButton
var _course_opt:    OptionButton
var _submit_btn:    Button
var _toggle_btn:    Button
var _offline_btn:   Button
var _spinner:       Label

func _ready() -> void:
	_build_ui()
	_connect_firebase()

# ══════════════════════════════════════════════════
# UI Construction
# ══════════════════════════════════════════════════
# #REGION:UI — Sign-in/sign-up form layout
func _build_ui() -> void:
	# Background — use street tile faded
	var bg := ColorRect.new()
	bg.color = Color("#060610")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var tile_tex: Texture2D = AssetMap.load_tex(AssetMap.MAP_TILES.get("street",""))
	if tile_tex:
		for row in 4:
			for col in 4:
				var s := Sprite2D.new()
				s.texture = tile_tex
				s.position = Vector2(col*384+192, row*320+160)
				s.modulate = Color(1,1,1,0.12)
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s.z_index = -1
				add_child(s)

	# #REGION:LOGO — Left side AlgoQuest branding (replaces codemon logo)
	var brand_lbl := Label.new()
	brand_lbl.text = "ALGOQUEST"
	brand_lbl.set_position(Vector2(60, 160))
	brand_lbl.add_theme_font_size_override("font_size", 48)
	brand_lbl.add_theme_color_override("font_color", Color("#4D96FF"))
	add_child(brand_lbl)
	var brand_sub := Label.new()
	brand_sub.text = "Data Structures\n& Algorithms"
	brand_sub.set_position(Vector2(62, 222))
	brand_sub.add_theme_font_size_override("font_size", 16)
	brand_sub.add_theme_color_override("font_color", Color("#555577"))
	add_child(brand_sub)
	# SS bracket decorations
	var br_tex: Texture2D = AssetMap.load_tex(AssetMap.LOGO_BRACKET)
	if br_tex:
		var brl := Sprite2D.new()
		brl.texture = br_tex; brl.position = Vector2(50, 290)
		brl.scale = Vector2(0.8, 0.8); brl.modulate = Color(0.3, 0.5, 1.0, 0.5)
		brl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; add_child(brl)
		var brr := Sprite2D.new()
		brr.texture = br_tex; brr.position = Vector2(420, 290)
		brr.scale = Vector2(0.8, 0.8); brr.flip_h = true
		brr.modulate = Color(0.3, 0.5, 1.0, 0.5)
		brr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; add_child(brr)

	# Jimmy sprite on left
	# #REGION:CHARACTERS — LPC player character on login screen
	var lpc_char: Node2D = load("res://scripts/lpc/CharacterSprite.gd").new()
	lpc_char.position = Vector2(190, 360)
	lpc_char.scale = Vector2(4.5, 4.5)
	add_child(lpc_char)
	var saved_look: Dictionary = SaveManager.get_player_appearance()
	if saved_look.is_empty():
		saved_look = CharacterRandomizer.randomize_character()
	lpc_char.apply(saved_look)
	lpc_char.play("idle")
	lpc_char.set_direction(2)

	# Tagline
	_lbl("\"Master Data Structures. Capture your Codemons.\"",
		Vector2(50, 560), 13, Color("#555577"))

	# ── Panel ──────────────────────────────────────
	_panel = ColorRect.new()
	_panel.color = Color("#0d0d1a")
	_panel.set_position(Vector2(480, 60))
	_panel.set_size(Vector2(760, 600))
	add_child(_panel)

	# Panel top accent
	var accent := ColorRect.new()
	accent.color = Color("#4D96FF")
	accent.set_position(Vector2(480, 60))
	accent.set_size(Vector2(760, 4))
	add_child(accent)

	# AlgoQuest title inside panel
	_lbl("ALGOQUEST", Vector2(560, 80), 36, Color("#4D96FF"))
	_lbl("Data Structures & Algorithms", Vector2(570, 126), 13, Color("#555577"))

	# ── Tab buttons ────────────────────────────────
	var sign_in_tab := _tab_btn("Sign In",  Vector2(480, 162), true)
	var sign_up_tab := _tab_btn("Sign Up",  Vector2(620, 162), false)
	sign_in_tab.name = "TabSignIn"
	sign_up_tab.name = "TabSignUp"
	sign_in_tab.pressed.connect(func(): _set_mode("signin"))
	sign_up_tab.pressed.connect(func(): _set_mode("signup"))

	# ── Form ───────────────────────────────────────
	var form_y: float = 210.0
	const FX: float   = 510.0
	const FW: float   = 680.0

	# Name row (sign-up only)
	_name_row = _field_row("Display Name", FX, form_y, FW)
	_name_field = _name_row.get_child(1)
	_name_field.placeholder_text = "Jimmy"
	form_y += 68.0

	# Email
	var email_row := _field_row("Email", FX, form_y, FW)
	_email_field = email_row.get_child(1)
	_email_field.placeholder_text = "jimmy@university.edu"
	form_y += 68.0

	# Password
	var pass_row := _field_row("Password", FX, form_y, FW)
	_pass_field = pass_row.get_child(1)
	_pass_field.placeholder_text = "••••••••"
	_pass_field.secret = true
	form_y += 68.0

	# Year (sign-up only)
	_year_row = _field_row("Academic Year", FX, form_y, FW / 2.0 - 8)
	_year_opt = _make_option(YEARS, Vector2(FX + FW / 2.0, form_y), FW / 2.0 - 4)
	_year_row.get_child(0).queue_free()  # remove label, year_opt has its own
	_lbl("Academic Year", Vector2(FX, form_y - 22), 12, Color("#888899"))
	form_y += 68.0

	# Course (sign-up only)
	_course_row = _field_row("Course / Major", FX, form_y, FW)
	_course_opt = _make_option(COURSES, Vector2(FX, form_y), FW)
	_course_row.get_child(0).queue_free()
	_lbl("Course / Major", Vector2(FX, form_y - 22), 12, Color("#888899"))
	form_y += 72.0

	# Error label
	_error_lbl = Label.new()
	_error_lbl.text = ""
	_error_lbl.set_position(Vector2(FX, form_y))
	_error_lbl.set_size(Vector2(FW, 36))
	_error_lbl.add_theme_font_size_override("font_size", 13)
	_error_lbl.add_theme_color_override("font_color", Color("#FF6B6B"))
	_error_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_error_lbl)

	# Submit button
	_submit_btn = Button.new()
	_submit_btn.text = "Sign In"
	_submit_btn.set_position(Vector2(FX, form_y + 44))
	_submit_btn.set_size(Vector2(FW, 52))
	_submit_btn.add_theme_font_size_override("font_size", 18)
	_submit_btn.add_theme_color_override("font_color", Color("#e8e8f0"))
	_submit_btn.pressed.connect(_submit)
	add_child(_submit_btn)

	# Spinner
	_spinner = Label.new()
	_spinner.text = "⟳  Connecting..."
	_spinner.set_position(Vector2(FX + 240, form_y + 56))
	_spinner.add_theme_font_size_override("font_size", 14)
	_spinner.add_theme_color_override("font_color", Color("#4D96FF"))
	_spinner.visible = false
	add_child(_spinner)

	# Offline / skip button
	_offline_btn = Button.new()
	_offline_btn.text = "Play Offline (no account)"
	_offline_btn.set_position(Vector2(FX, form_y + 106))
	_offline_btn.set_size(Vector2(FW, 40))
	_offline_btn.add_theme_font_size_override("font_size", 13)
	_offline_btn.add_theme_color_override("font_color", Color("#444466"))
	_offline_btn.pressed.connect(_play_offline)
	add_child(_offline_btn)

	# Not configured warning
	if not FirebaseManager.is_configured():
		var warn := Label.new()
		warn.text = "⚠  Firebase not configured — online features disabled.\nSet PROJECT_ID and API_KEY in scripts/autoload/FirebaseManager.gd"
		warn.set_position(Vector2(FX, form_y + 158))
		warn.set_size(Vector2(FW, 60))
		warn.add_theme_font_size_override("font_size", 11)
		warn.add_theme_color_override("font_color", Color("#664400"))
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(warn)

	_set_mode("signin")

func _tab_btn(text: String, pos: Vector2, active: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.set_position(pos)
	b.set_size(Vector2(130, 36))
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color",
		Color("#e8e8f0") if active else Color("#444466"))
	add_child(b)
	return b

func _field_row(label_text: String, x: float, y: float, w: float) -> Control:
	var row := Control.new()
	row.set_position(Vector2(x, y - 24))
	row.set_size(Vector2(w, 68))
	add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.set_position(Vector2(0, 0))
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color("#888899"))
	row.add_child(lbl)

	var field := LineEdit.new()
	field.set_position(Vector2(0, 20))
	field.set_size(Vector2(w, 38))
	field.add_theme_font_size_override("font_size", 15)
	field.add_theme_color_override("font_color", Color("#e8e8f0"))
	row.add_child(field)

	return row

func _make_option(items: Array, pos: Vector2, w: float) -> OptionButton:
	var opt := OptionButton.new()
	opt.set_position(pos)
	opt.set_size(Vector2(w, 38))
	opt.add_theme_font_size_override("font_size", 13)
	for item in items:
		opt.add_item(item as String)
	add_child(opt)
	return opt

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text; l.set_position(pos)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	add_child(l); return l

# ══════════════════════════════════════════════════
# Mode toggle
# ══════════════════════════════════════════════════
# #REGION:UI:MODE — Toggle sign-in vs sign-up fields
func _set_mode(mode: String) -> void:
	_mode = mode
	var is_signup: bool = mode == "signup"

	_name_row.visible   = is_signup
	_year_row.visible   = is_signup
	_year_opt.visible   = is_signup
	_course_row.visible = is_signup
	_course_opt.visible = is_signup
	_submit_btn.text    = "Create Account" if is_signup else "Sign In"
	_error_lbl.text     = ""

	# Tab highlight
	var tab_in  := get_node_or_null("TabSignIn")  as Button
	var tab_up  := get_node_or_null("TabSignUp")  as Button
	if tab_in:
		tab_in.add_theme_color_override("font_color",
			Color("#e8e8f0") if mode == "signin" else Color("#444466"))
	if tab_up:
		tab_up.add_theme_color_override("font_color",
			Color("#e8e8f0") if mode == "signup" else Color("#444466"))

# ══════════════════════════════════════════════════
# Validation & Submit
# ══════════════════════════════════════════════════
func _submit() -> void:
	if _busy: return
	_error_lbl.text = ""

	var email: String    = _email_field.text.strip_edges()
	var password: String = _pass_field.text

	# Basic validation
	if email.is_empty():
		_show_error("Please enter your email address."); return
	if not "@" in email or not "." in email:
		_show_error("Please enter a valid email address."); return
	if password.length() < 6:
		_show_error("Password must be at least 6 characters."); return

	if _mode == "signup":
		var disp_name: String = _name_field.text.strip_edges()
		if disp_name.is_empty():
			_show_error("Please enter your display name."); return

		var year_str:   String = YEARS[_year_opt.selected]   as String
		var course_str: String = COURSES[_course_opt.selected] as String

		var player_data: Dictionary = {
			"name":         disp_name,
			"email":        email,
			"year":         year_str,
			"course":       course_str,
			"character_id": SaveManager.get_setting("character_id", "keeper") as String,
		}
		_set_busy(true)

		if FirebaseManager.is_configured():
			FirebaseManager.sign_up(email, password, player_data)
		else:
			# Offline mode — store locally and continue
			_apply_player_data(player_data)

	else:  # signin
		_set_busy(true)
		if FirebaseManager.is_configured():
			FirebaseManager.sign_in(email, password)
		else:
			_show_error("Firebase not configured. Use 'Play Offline' instead.")
			_set_busy(false)

func _play_offline() -> void:
	# Continue = has appearance saved → WorldMap
	# New Game = no appearance → Story intro → CharCreate
	var has_appearance: bool = not SaveManager.get_player_appearance().is_empty()
	if has_appearance:
		GameRouter.go_world_map()
	else:
		GameRouter.go_intro_world()

func _apply_player_data(player_data: Dictionary) -> void:
	var disp: String = player_data.get("name", "") as String
	if disp != "":
		ProgressTracker.set_player_name(disp)
	SaveManager.set_setting("player_year",   player_data.get("year",   "") as String)
	SaveManager.set_setting("player_course", player_data.get("course", "") as String)
	SaveManager.set_setting("player_email",  player_data.get("email",  "") as String)

	# #REGION:UI — Routing rules:
	# Sign UP (new account) → CharacterCreate → CharacterSelect → WorldMap
	# Sign IN (returning)   → WorldMap directly (already has character)
	# Offline NEW game      → CharacterCreate
	# Offline Continue      → WorldMap
	var is_new_account: bool = (_mode == "signup")
	var has_char: bool       = SaveManager.get_setting("char_variant", "") != ""
	var has_name: bool       = ProgressTracker.get_player_name() != ""

	var has_appearance: bool = not SaveManager.get_player_appearance().is_empty()
	if is_new_account or not has_appearance:
		GameRouter.go_intro_world()
	else:
		GameRouter.go_world_map()

func _set_busy(v: bool) -> void:
	_busy = v
	_submit_btn.visible  = not v
	_offline_btn.visible = not v
	_spinner.visible     = v

func _show_error(msg: String) -> void:
	_error_lbl.text = msg
	_set_busy(false)

# ══════════════════════════════════════════════════
# Firebase callbacks
# ══════════════════════════════════════════════════
func _connect_firebase() -> void:
	FirebaseManager.auth_success.connect(_on_auth_success)
	FirebaseManager.auth_error.connect(_on_auth_error)

func _on_auth_success(player_data: Dictionary) -> void:
	_set_busy(false)
	_apply_player_data(player_data)

func _on_auth_error(message: String) -> void:
	_set_busy(false)
	_show_error(message)
