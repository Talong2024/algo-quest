extends Node2D
## IntroWorld — opening walkable area.
## WASD to move, E to interact with notice board or NPC.

const PLAYER_SPEED:    float   = 180.0
const INTERACT_RADIUS: float   = 90.0

var _player:          Node2D
var _npc:             Node2D
var _dlg:             Node
var _interact_lbl:    Label
var _can_move:        bool    = true
var _talked_to_npc:   bool    = false
var _board_was_read:  bool    = false   # renamed to avoid conflict with func name
var _dir:             int     = 2
var _moving:          bool    = false
var _was_moving:      bool    = false

const NPC_POS:   Vector2 = Vector2(860, 290)
const BOARD_POS: Vector2 = Vector2(300, 235)

# ── Dialogue ──────────────────────────────────────────────────────────────────

const BOARD_LINES: Array = [
	{"speaker":"Notice Board","portrait":"narrator",
	 "text":"⚑  OFFICIAL NOTICE — KINGDOM GATE\n\nA Queue Doorman is urgently needed.\nFirst-come, first-served must be enforced at all times."},
	{"speaker":"Notice Board","portrait":"narrator",
	 "text":"Applicants must understand:\n• Queues and FIFO ordering\n• Stack, Linked List, Tree, Graph structures\n\nReport to the Gatekeeper immediately.\n— By Order of His Majesty"},
]

const NPC_FIRST_LINES: Array = [
	{"speaker":"Old Gatekeeper","portrait":"doorman",
	 "text":"Ugh... these knees of mine. Twenty years at this gate and they've finally given out."},
	{"speaker":"Old Gatekeeper","portrait":"doorman",
	 "text":"Oh! A traveller! You there — have you studied Data Structures?"},
	{"speaker":"You","portrait":"player",
	 "text":"I... yes? I saw your notice board. The Doorman position—"},
	{"speaker":"Old Gatekeeper","portrait":"doorman",
	 "text":"Excellent! You're hired. Immediately. No arguments."},
	{"speaker":"You","portrait":"player",
	 "text":"Right now?! I haven't even set up my character yet—"},
	{"speaker":"Old Gatekeeper","portrait":"doorman",
	 "text":"Go sort yourself out. Come back looking like a proper Doorman. The queue won't manage itself!"},
]

const NPC_AFTER_BOARD: Array = [
	{"speaker":"Old Gatekeeper","portrait":"doorman",
	 "text":"Good — you read the notice. You know exactly what I need then. Go get your uniform sorted and report back!"},
]

const NPC_REPEAT: Array = [
	{"speaker":"Old Gatekeeper","portrait":"doorman",
	 "text":"Still here? Go get changed and report back to the gate!"},
]

# ── Build ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_world()
	_build_player()
	_build_npc()
	_build_ui()
	_build_dlg()
	_entrance_fade()

func _build_world() -> void:
	var bg_tex: Texture2D = AssetMap.load_tex("res://assets/codemon/art/map/bg_street.png")
	if bg_tex:
		var bg := Sprite2D.new()
		bg.texture = bg_tex; bg.position = Vector2(640, 360)
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; bg.z_index = -10
		add_child(bg)

	var ov := ColorRect.new()
	ov.color = Color(0,0,0,0.3); ov.set_position(Vector2.ZERO)
	ov.set_size(Vector2(1280,720)); ov.z_index = -9; add_child(ov)

	# Gate
	var arch := ColorRect.new()
	arch.color = Color(0.12,0.08,0.04,0.96)
	arch.set_position(Vector2(490,0)); arch.set_size(Vector2(300,110)); arch.z_index = 6
	add_child(arch)
	var gl := Label.new(); gl.text = "🏰  KINGDOM GATE"
	gl.set_position(Vector2(503,38))
	gl.add_theme_font_size_override("font_size",18)
	gl.add_theme_color_override("font_color",Color("#FFD93D")); gl.z_index = 7; add_child(gl)

	# Notice board
	var bprop := ColorRect.new()
	bprop.color = Color(0.3,0.2,0.08); bprop.set_position(Vector2(255,192))
	bprop.set_size(Vector2(90,70)); bprop.z_index = 5; add_child(bprop)
	var binner := ColorRect.new()
	binner.color = Color(0.85,0.75,0.4); binner.set_position(Vector2(263,198))
	binner.set_size(Vector2(74,52)); binner.z_index = 5; add_child(binner)
	var btxt := Label.new(); btxt.text = "📋  NOTICE"
	btxt.set_position(Vector2(268,210))
	btxt.add_theme_font_size_override("font_size",10)
	btxt.add_theme_color_override("font_color",Color(0.15,0.08,0.0)); btxt.z_index = 6; add_child(btxt)

	# Trees
	var tree_tex: Texture2D = AssetMap.load_tex("res://assets/codemon/art/object/tree_01.png")
	for tpos: Vector2 in [Vector2(80,210),Vector2(95,460),Vector2(1185,210),Vector2(1160,460)]:
		if tree_tex:
			var t := Sprite2D.new(); t.texture = tree_tex
			t.position = tpos; t.scale = Vector2(3,3)
			t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			t.z_index = int(tpos.y/10); add_child(t)

func _build_player() -> void:
	_player = load("res://scripts/lpc/CharacterSprite.gd").new()
	_player.name = "Player"; _player.scale = Vector2(3.0,3.0)
	_player.position = Vector2(640,640); _player.z_index = 10; add_child(_player)
	var app: Dictionary = SaveManager.get_player_appearance()
	if app.is_empty(): app = CharacterRandomizer.randomize_character()
	_player.apply(app); _player.play("idle"); _player.set_direction(2)

func _build_npc() -> void:
	_npc = load("res://scripts/lpc/CharacterSprite.gd").new()
	_npc.name = "NPC_Gatekeeper"; _npc.scale = Vector2(3.0,3.0)
	_npc.position = NPC_POS; _npc.z_index = 8; add_child(_npc)
	_npc.apply({
		"body_type":"male","skin_tone":"dark","hair_style":"plain","hair_color":"gray",
		"shirt_style":"sleeveless2","shirt_color":"charcoal",
		"leg_type":"pants/white","shoe_type":"boots/basic","shoe_color":"brown",
		"sock_type":"","sock_color":"",
	})
	_npc.play("idle"); _npc.set_direction(1)   # facing left toward lane

	var nl := Label.new(); nl.text = "Old Gatekeeper"
	nl.set_position(NPC_POS + Vector2(-48,-85))
	nl.add_theme_font_size_override("font_size",11)
	nl.add_theme_color_override("font_color",Color("#FFD93D")); nl.z_index = 11; add_child(nl)

func _build_ui() -> void:
	_interact_lbl = Label.new()
	_interact_lbl.text = "[ E ]  Interact"
	_interact_lbl.add_theme_font_size_override("font_size",13)
	_interact_lbl.add_theme_color_override("font_color",Color("#FFD93D"))
	_interact_lbl.visible = false; add_child(_interact_lbl)

	var ctrl := Label.new()
	ctrl.text = "WASD — Move   |   E — Interact"
	ctrl.set_position(Vector2(20,694))
	ctrl.add_theme_font_size_override("font_size",11)
	ctrl.add_theme_color_override("font_color",Color("#334455")); add_child(ctrl)

func _build_dlg() -> void:
	_dlg = load("res://scenes/shared/DialogueBox.tscn").instantiate()
	add_child(_dlg)

func _entrance_fade() -> void:
	var fade := ColorRect.new()
	fade.color = Color(0,0,0,1.0); fade.set_position(Vector2.ZERO)
	fade.set_size(Vector2(1280,720)); fade.z_index = 100; add_child(fade)
	var tw := create_tween()
	tw.tween_property(fade,"color:a",0.0,1.0)
	tw.tween_callback(fade.queue_free)

	var aname := Label.new(); aname.text = "AlgoQuest  —  Kingdom Gate"
	aname.set_position(Vector2(420,36))
	aname.add_theme_font_size_override("font_size",15)
	aname.add_theme_color_override("font_color",Color("#e8e8f0"))
	aname.modulate.a = 0.0; add_child(aname)
	var tw2 := create_tween()
	tw2.tween_property(aname,"modulate:a",1.0,0.5)
	tw2.tween_interval(2.0)
	tw2.tween_property(aname,"modulate:a",0.0,0.5)
	tw2.tween_callback(aname.queue_free)

# ── Movement ──────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _can_move: return
	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):    input.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):  input.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):  input.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"): input.x += 1
	_moving = input.length() > 0.1
	if _moving:
		input = input.normalized()
		var np: Vector2 = _player.position + input * PLAYER_SPEED * delta
		_player.position = Vector2(clampf(np.x,60,1220), clampf(np.y,130,680))
		# Direction: prefer horizontal so we get side-walk animation
		if abs(input.x) >= abs(input.y):
			_dir = 3 if input.x > 0 else 1
		else:
			_dir = 2 if input.y > 0 else 0
		_player.set_direction(_dir)
	if _moving != _was_moving:
		_was_moving = _moving
		_player.play("walk" if _moving else "idle")
		if not _moving: _player.set_direction(_dir)
	_check_proximity()

func _check_proximity() -> void:
	var near_npc:   bool = _player.position.distance_to(NPC_POS)   < INTERACT_RADIUS
	var near_board: bool = _player.position.distance_to(BOARD_POS) < INTERACT_RADIUS
	if near_npc or near_board:
		_interact_lbl.position = _player.position + Vector2(-50,-115)
		_interact_lbl.visible = true
		if near_npc:
			_npc.set_direction(1 if _player.position.x > NPC_POS.x else 3)
	else:
		_interact_lbl.visible = false

# ── Interact ──────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not _can_move: return
	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and ke.keycode == KEY_E:
			_try_interact()

func _try_interact() -> void:
	if _player.position.distance_to(NPC_POS) < INTERACT_RADIUS:
		_interact_with_npc()
	elif _player.position.distance_to(BOARD_POS) < INTERACT_RADIUS:
		_interact_with_board()

func _interact_with_npc() -> void:
	_can_move = false
	_player.play("idle")
	_player.set_direction(3 if NPC_POS.x > _player.position.x else 1)
	_npc.play("idle")
	_npc.set_direction(1 if NPC_POS.x > _player.position.x else 3)

	var lines: Array
	if _talked_to_npc:
		lines = NPC_REPEAT
	elif _board_was_read:
		lines = NPC_AFTER_BOARD
	else:
		lines = NPC_FIRST_LINES

	_dlg.show_dialogue(lines, _on_npc_done)

func _interact_with_board() -> void:
	_can_move = false
	_player.play("idle"); _player.set_direction(0)
	_board_was_read = true
	_dlg.show_dialogue(BOARD_LINES, _on_board_done)

func _on_board_done() -> void:
	_can_move = true

func _on_npc_done() -> void:
	if _talked_to_npc:
		_can_move = true
		return
	_talked_to_npc = true
	_can_move = false
	var fade := ColorRect.new()
	fade.color = Color(0,0,0,0.0); fade.set_position(Vector2.ZERO)
	fade.set_size(Vector2(1280,720)); fade.z_index = 100; add_child(fade)
	var tw := create_tween()
	tw.tween_property(fade,"color:a",1.0,0.8)
	tw.tween_callback(func(): GameRouter.go_char_create())
