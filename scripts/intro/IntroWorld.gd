extends Node2D
## IntroWorld — the opening walkable world.
## Player walks around, reads the notice board, talks to the NPC gatekeeper.
## After NPC dialogue finishes → CharacterCreate → game begins.
##
## Controls: WASD / Arrow keys to move, E to interact with nearby objects.

const PLAYER_SPEED: float = 180.0
const INTERACT_RADIUS: float = 80.0

# ── Scene nodes built in code ─────────────────────────────────────────────────
var _player:     Node2D   # CharacterSprite
var _npc:        Node2D   # Old gatekeeper CharacterSprite
var _board:      Node2D   # Notice board marker
var _dlg:        Node     # DialogueBox
var _interact_lbl: Label  # "Press E to interact" hint
var _map_label:  Label    # World name label

# ── State ─────────────────────────────────────────────────────────────────────
var _can_move:       bool   = true
var _talked_to_npc:  bool   = false
var _read_board:     bool   = false
var _dir:            int    = 2    # 0=up 1=left 2=down 3=right
var _moving:         bool   = false
var _npc_pos:        Vector2 = Vector2(760, 280)
var _board_pos:      Vector2 = Vector2(300, 240)

# ── Dialogue content ──────────────────────────────────────────────────────────
const BOARD_TEXT: Array = [
	{
		"speaker": "Notice Board",
		"portrait": "narrator",
		"text": "⚑  KINGDOM GATE — OFFICIAL NOTICE\n\nAll citizens must queue in an orderly fashion.\nFirst come, first served. Violation is punishable by law.",
	},
	{
		"speaker": "Notice Board",
		"portrait": "narrator",
		"text": "The Doorman position is currently VACANT.\nApplicants must demonstrate knowledge of Queue data structures.\n\n— By Order of the King",
	},
]

const NPC_FIRST_GREET: Array = [
	{
		"speaker": "Old Gatekeeper",
		"portrait": "doorman",
		"text": "Oof... these knees of mine. Twenty years at this gate and they've finally given out.",
	},
	{
		"speaker": "Old Gatekeeper",
		"portrait": "doorman",
		"text": "Oh! A visitor! You there — come closer. Don't be shy.",
	},
	{
		"speaker": "You",
		"portrait": "player",
		"text": "Hello? I just arrived in AlgoQuest. I saw the notice board about a Doorman position...",
	},
	{
		"speaker": "Old Gatekeeper",
		"portrait": "doorman",
		"text": "Yes! YES! That's exactly what I need. Look at this chaos — citizens everywhere, no order, no system!",
	},
	{
		"speaker": "Old Gatekeeper",
		"portrait": "doorman",
		"text": "The job is simple: manage a QUEUE. A line. Citizens wait in order. You serve the front one first. Always.",
	},
	{
		"speaker": "You",
		"portrait": "player",
		"text": "A Queue... like a real queue at a shop? First In, First Out?",
	},
	{
		"speaker": "Old Gatekeeper",
		"portrait": "doorman",
		"text": "Exactly! FIFO — First In, First Out. You DO know your Data Structures! Perfect.",
	},
	{
		"speaker": "Old Gatekeeper",
		"portrait": "doorman",
		"text": "But first — you'll need to look the part. Let's get you set up with a proper appearance for the role.",
	},
	{
		"speaker": "You",
		"portrait": "player",
		"text": "Wait — you're actually hiring me right now? I haven't even applied!",
	},
	{
		"speaker": "Old Gatekeeper",
		"portrait": "doorman",
		"text": "Consider this your interview. You passed. Now go get changed — the gate won't manage itself!",
	},
]

const NPC_AFTER_READ: Array = [
	{
		"speaker": "Old Gatekeeper",
		"portrait": "doorman",
		"text": "Oh good, you read the notice board! So you know what we need. A Doorman who understands queues.",
	},
	{
		"speaker": "Old Gatekeeper",
		"portrait": "doorman",
		"text": "That person is YOU. No arguments. Go get your uniform sorted and report back immediately.",
	},
]

func _ready() -> void:
	_build_world()
	_build_player()
	_build_npc()
	_build_board()
	_build_ui()
	_build_dialogue()
	_show_entrance_text()

# ── World ─────────────────────────────────────────────────────────────────────

func _build_world() -> void:
	# Background
	var bg_tex: Texture2D = AssetMap.load_tex("res://assets/codemon/art/map/bg_street.png")
	if bg_tex:
		var bg := Sprite2D.new()
		bg.texture = bg_tex
		bg.position = Vector2(640, 360)
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.z_index = -10
		add_child(bg)

	# Dark vignette
	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0.3)
	ov.set_position(Vector2.ZERO)
	ov.set_size(Vector2(1280, 720))
	ov.z_index = -9
	add_child(ov)

	# Gate arch at top
	var arch := ColorRect.new()
	arch.color = Color(0.12, 0.08, 0.04, 0.96)
	arch.set_position(Vector2(490, 0))
	arch.set_size(Vector2(300, 110))
	arch.z_index = 6
	add_child(arch)

	var gate_lbl := Label.new()
	gate_lbl.text = "🏰  KINGDOM GATE"
	gate_lbl.set_position(Vector2(505, 40))
	gate_lbl.add_theme_font_size_override("font_size", 18)
	gate_lbl.add_theme_color_override("font_color", Color("#FFD93D"))
	gate_lbl.z_index = 7
	add_child(gate_lbl)

	# Notice board prop
	var board_prop := ColorRect.new()
	board_prop.color = Color(0.3, 0.2, 0.08, 1.0)
	board_prop.set_position(Vector2(260, 195))
	board_prop.set_size(Vector2(80, 60))
	board_prop.z_index = 5
	add_child(board_prop)

	var board_inner := ColorRect.new()
	board_inner.color = Color(0.85, 0.75, 0.4, 1.0)
	board_inner.set_position(Vector2(268, 201))
	board_inner.set_size(Vector2(64, 46))
	board_inner.z_index = 5
	add_child(board_inner)

	var board_txt := Label.new()
	board_txt.text = "NOTICE\nBOARD"
	board_txt.set_position(Vector2(272, 205))
	board_txt.add_theme_font_size_override("font_size", 9)
	board_txt.add_theme_color_override("font_color", Color(0.2, 0.1, 0.0))
	board_txt.z_index = 6
	add_child(board_txt)

	# Trees for atmosphere
	var tree_tex: Texture2D = AssetMap.load_tex("res://assets/codemon/art/object/tree_01.png")
	for pos: Vector2 in [Vector2(80, 200), Vector2(100, 450), Vector2(1180, 200), Vector2(1160, 450)]:
		if tree_tex:
			var t := Sprite2D.new()
			t.texture = tree_tex
			t.position = pos
			t.scale = Vector2(3, 3)
			t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			t.z_index = int(pos.y / 10)
			add_child(t)

	# World boundary walls (invisible blockers just constrain movement in code)

func _build_player() -> void:
	_player = load("res://scripts/lpc/CharacterSprite.gd").new()
	_player.name = "Player"
	_player.scale = Vector2(3.0, 3.0)
	_player.position = Vector2(640, 620)
	_player.z_index = 10
	add_child(_player)

	var appearance: Dictionary = SaveManager.get_player_appearance()
	if appearance.is_empty():
		appearance = CharacterRandomizer.randomize_character()
	_player.apply(appearance)
	_player.play("idle")
	_player.set_direction(2)

func _build_npc() -> void:
	_npc = load("res://scripts/lpc/CharacterSprite.gd").new()
	_npc.name = "Gatekeeper"
	_npc.scale = Vector2(3.0, 3.0)
	_npc.position = _npc_pos
	_npc.z_index = 8
	add_child(_npc)

	_npc.apply({
		"body_type": "male", "skin_tone": "dark",
		"hair_style": "plain", "hair_color": "gray",
		"shirt_style": "sleeveless2", "shirt_color": "charcoal",
		"leg_type": "pants/white", "shoe_type": "boots/basic", "shoe_color": "brown",
		"sock_type": "", "sock_color": "",
	})
	_npc.play("idle")
	_npc.set_direction(2)

	# NPC name tag
	var npc_lbl := Label.new()
	npc_lbl.text = "Old Gatekeeper"
	npc_lbl.set_position(_npc_pos + Vector2(-40, -90))
	npc_lbl.add_theme_font_size_override("font_size", 11)
	npc_lbl.add_theme_color_override("font_color", Color("#FFD93D"))
	npc_lbl.z_index = 11
	add_child(npc_lbl)

func _build_board() -> void:
	_board = Node2D.new()
	_board.position = _board_pos
	add_child(_board)

func _build_ui() -> void:
	# Interact hint — shown when near interactable object
	_interact_lbl = Label.new()
	_interact_lbl.text = "E — Interact"
	_interact_lbl.set_position(Vector2(560, 660))
	_interact_lbl.add_theme_font_size_override("font_size", 14)
	_interact_lbl.add_theme_color_override("font_color", Color("#FFD93D"))
	_interact_lbl.visible = false
	add_child(_interact_lbl)

	# Controls reminder
	var ctrl := Label.new()
	ctrl.text = "WASD / Arrows — Move    E — Interact"
	ctrl.set_position(Vector2(20, 690))
	ctrl.add_theme_font_size_override("font_size", 11)
	ctrl.add_theme_color_override("font_color", Color("#334455"))
	add_child(ctrl)

func _build_dialogue() -> void:
	_dlg = load("res://scenes/shared/DialogueBox.tscn").instantiate()
	add_child(_dlg)

func _show_entrance_text() -> void:
	# Brief pan-in effect: fade from black
	var flash := ColorRect.new()
	flash.color = Color(0, 0, 0, 1.0)
	flash.set_position(Vector2.ZERO)
	flash.set_size(Vector2(1280, 720))
	flash.z_index = 100
	add_child(flash)

	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.0, 1.2)
	tw.tween_callback(flash.queue_free)

	# World name display
	_map_label = Label.new()
	_map_label.text = "AlgoQuest — Kingdom Gate"
	_map_label.set_position(Vector2(430, 30))
	_map_label.add_theme_font_size_override("font_size", 16)
	_map_label.add_theme_color_override("font_color", Color("#e8e8f0"))
	_map_label.modulate.a = 0.0
	add_child(_map_label)

	var tw2 := create_tween()
	tw2.tween_property(_map_label, "modulate:a", 1.0, 0.8)
	tw2.tween_interval(2.0)
	tw2.tween_property(_map_label, "modulate:a", 0.0, 0.8)
	tw2.tween_callback(_map_label.queue_free)

# ── Movement ──────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _can_move:
		return

	var input := Vector2.ZERO
	if Input.is_action_pressed("ui_up")    or Input.is_key_pressed(KEY_W): input.y -= 1
	if Input.is_action_pressed("ui_down")  or Input.is_key_pressed(KEY_S): input.y += 1
	if Input.is_action_pressed("ui_left")  or Input.is_key_pressed(KEY_A): input.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D): input.x += 1

	var was_moving: bool = _moving
	_moving = input.length() > 0.1

	if _moving:
		input = input.normalized()
		var new_pos: Vector2 = _player.position + input * PLAYER_SPEED * delta
		# Clamp to world bounds
		new_pos.x = clampf(new_pos.x, 60, 1220)
		new_pos.y = clampf(new_pos.y, 130, 680)
		_player.position = new_pos

		# Update direction
		var new_dir: int = _dir
		if abs(input.x) >= abs(input.y):
			new_dir = 3 if input.x > 0 else 1
		else:
			new_dir = 2 if input.y > 0 else 0
		if new_dir != _dir:
			_dir = new_dir
			_player.set_direction(_dir)

	if _moving != was_moving:
		_player.play("walk" if _moving else "idle")
		if not _moving:
			_player.set_direction(_dir)

	# Check proximity to interactables
	_check_interactions()

func _check_interactions() -> void:
	var near_npc:   bool = _player.position.distance_to(_npc_pos)   < INTERACT_RADIUS
	var near_board: bool = _player.position.distance_to(_board_pos) < INTERACT_RADIUS

	if near_npc or near_board:
		var target_pos: Vector2 = _npc_pos if near_npc else _board_pos
		_interact_lbl.position = _player.position + Vector2(-40, -110)
		_interact_lbl.visible = true
		# NPC faces player when close
		if near_npc and is_instance_valid(_npc):
			var dx: float = _player.position.x - _npc_pos.x
			_npc.set_direction(3 if dx > 0 else 1)
	else:
		_interact_lbl.visible = false

# ── Interaction ───────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not _can_move:
		return
	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and ke.keycode == KEY_E:
			_try_interact()

func _try_interact() -> void:
	var near_npc:   bool = _player.position.distance_to(_npc_pos)   < INTERACT_RADIUS
	var near_board: bool = _player.position.distance_to(_board_pos) < INTERACT_RADIUS

	if near_npc:
		_talk_to_npc()
	elif near_board:
		_read_board()

func _talk_to_npc() -> void:
	if _talked_to_npc:
		# Brief repeat line
		_dlg.show_dialogue([{
			"speaker": "Old Gatekeeper", "portrait": "doorman",
			"text": "Still here? Go get your appearance sorted and report back to the gate!",
		}])
		return
	_can_move = false
	_player.play("idle")
	# Face the NPC
	var dx: float = _npc_pos.x - _player.position.x
	_player.set_direction(3 if dx > 0 else 1)
	_npc.play("idle")
	_npc.set_direction(3 if dx < 0 else 1)

	var script: Array = NPC_AFTER_READ if _read_board else NPC_FIRST_GREET
	_dlg.show_dialogue(script, _on_npc_dialogue_done)

func _read_board() -> void:
	_can_move = false
	_player.play("idle")
	_player.set_direction(0)  # face the board (upward)
	_read_board = true
	_dlg.show_dialogue(BOARD_TEXT, func():
		_can_move = true
	)

func _on_npc_dialogue_done() -> void:
	_talked_to_npc = true
	_can_move = false
	# Fade out then go to character creation
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0.0)
	fade.set_position(Vector2.ZERO)
	fade.set_size(Vector2(1280, 720))
	fade.z_index = 100
	add_child(fade)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 1.0)
	tw.tween_callback(func(): GameRouter.go_char_create())
