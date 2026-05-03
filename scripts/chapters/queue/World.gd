extends Node2D
## Q_World — Side-scrolling castle gate world.
## Castle background tiled. Gate arch on left. Doorman (player) stands by gate.

const CASTLE_BG:    String = "res://assets/backgrounds/castle.png"
const CHARS_SHEET:  String = "res://assets/game/characters/chars_sheet.png"
const CHAR_TILE:    int    = 24

var door_unlocked_count: int = 0
var total_locks:         int = 3
var phase:               String = "push"

var _doorman:   Sprite2D
var _anim_timer: float = 0.0
var _anim_frame: int   = 0
const IDLE_FPS: float  = 3.0

func _ready() -> void:
	_build_background()
	_build_ground()
	_build_gate()
	_build_doorman()

func _build_background() -> void:
	if ResourceLoader.exists(CASTLE_BG):
		var tex: Texture2D = load(CASTLE_BG) as Texture2D
		var bg_h: float    = 600.0
		var scale_y: float = bg_h / tex.get_height()
		var scale_x: float = scale_y
		var tile_w: float  = tex.get_width() * scale_x
		var x: float = 0.0
		while x < 1300.0:
			var s := Sprite2D.new()
			s.texture        = tex
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.scale          = Vector2(scale_x, scale_y)
			s.centered       = false
			s.position       = Vector2(x, 0)
			s.z_index        = -10
			add_child(s)
			x += tile_w - 2.0
	else:
		var bg := ColorRect.new()
		bg.color = Color("#4a5560")
		bg.set_position(Vector2.ZERO); bg.set_size(Vector2(1280, 600))
		bg.z_index = -10; add_child(bg)

func _build_ground() -> void:
	var dirt := ColorRect.new()
	dirt.color = Color("#3a2a18")
	dirt.set_position(Vector2(0, 600)); dirt.set_size(Vector2(1280, 120))
	dirt.z_index = -5; add_child(dirt)
	var grass := ColorRect.new()
	grass.color = Color("#3a6b2a")
	grass.set_position(Vector2(0, 596)); grass.set_size(Vector2(1280, 8))
	grass.z_index = -4; add_child(grass)

func _build_gate() -> void:
	# Left stone pillar
	for ox in [40.0, 160.0]:
		var p := ColorRect.new(); p.color = Color("#5a5060")
		p.set_position(Vector2(ox, 350)); p.set_size(Vector2(50, 254))
		p.z_index = 2; add_child(p)
		# Pillar highlight edge
		var e := ColorRect.new(); e.color = Color("#7a7080")
		e.set_position(Vector2(ox, 350)); e.set_size(Vector2(6, 254))
		e.z_index = 3; add_child(e)
	# Arch top
	var top := ColorRect.new(); top.color = Color("#4a4050")
	top.set_position(Vector2(40, 330)); top.set_size(Vector2(170, 26))
	top.z_index = 2; add_child(top)
	# Crenellations on top
	for i in 4:
		var c := ColorRect.new(); c.color = Color("#5a5060")
		c.set_position(Vector2(48 + i * 40, 310)); c.set_size(Vector2(26, 24))
		c.z_index = 2; add_child(c)
	# Gate opening
	var gate := ColorRect.new(); gate.color = Color("#0a0810")
	gate.set_position(Vector2(90, 370)); gate.set_size(Vector2(70, 234))
	gate.z_index = 1; add_child(gate)
	# Gate portcullis bars
	for i in 3:
		var bar := ColorRect.new(); bar.color = Color("#2a2838", 0.8)
		bar.set_position(Vector2(100 + i * 20, 370)); bar.set_size(Vector2(6, 234))
		bar.z_index = 4; add_child(bar)
	# Gate label
	var lbl := Label.new()
	lbl.text = "KINGDOM GATE"
	lbl.set_position(Vector2(14, 316)); lbl.z_index = 5
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#FFD93D"))
	add_child(lbl)

func _build_doorman() -> void:
	# Player character standing right of gate using CGabriel sheet
	_doorman = Sprite2D.new()
	if ResourceLoader.exists(CHARS_SHEET):
		_doorman.texture = load(CHARS_SHEET) as Texture2D
	_doorman.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_doorman.centered       = false
	_doorman.region_enabled = true
	_doorman.region_rect    = Rect2(0, 24, CHAR_TILE, CHAR_TILE)  # row 1 = guard
	_doorman.scale          = Vector2(4.0, 4.0)
	_doorman.position       = Vector2(240, 504)   # right of gate
	_doorman.z_index        = 6
	_doorman.scale.x        = -4.0  # face right (toward the queue)
	add_child(_doorman)

	# "YOU" label above doorman
	var lbl := Label.new()
	lbl.text = "YOU"
	lbl.set_position(Vector2(238, 490)); lbl.z_index = 7
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color("#FFD93D"))
	add_child(lbl)

func _process(delta: float) -> void:
	# Animate doorman idle
	if not is_instance_valid(_doorman): return
	_anim_timer += delta
	if _anim_timer >= 1.0 / IDLE_FPS:
		_anim_timer -= 1.0 / IDLE_FPS
		_anim_frame = (_anim_frame + 1) % 2
		_doorman.region_rect = Rect2(_anim_frame * CHAR_TILE, 24, CHAR_TILE, CHAR_TILE)
