extends Node2D
## CodemonIntro — opening story cutscene using DialogueBox.
## Player walks toward the gate, meets the old gatekeeper, gets hired.

const DIALOGUE_SCRIPTS = preload("res://scripts/shared/DialogueScripts.gd")

var _dlg: Node
var _player_walker: Node2D
var _crowd_nodes: Array = []
var _walk_done: bool = false

func _ready() -> void:
	_build_scene()
	_build_crowd()
	_build_dialogue_box()
	_play_entrance()

func _build_scene() -> void:
	var bg_tex: Texture2D = AssetMap.load_tex("res://assets/codemon/art/map/bg_street.png")
	if bg_tex:
		var bg := Sprite2D.new()
		bg.texture = bg_tex; bg.position = Vector2(640, 360)
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.z_index = -10; add_child(bg)

	var ov := ColorRect.new()
	ov.color = Color(0,0,0,0.4); ov.z_index = -9
	ov.set_position(Vector2.ZERO); ov.set_size(Vector2(1280,720))
	add_child(ov)

	# Gate
	var arch := ColorRect.new()
	arch.color = Color(0.12,0.08,0.04,0.95)
	arch.set_position(Vector2(490,0)); arch.set_size(Vector2(300,120))
	arch.z_index = 5; add_child(arch)
	var gate_lbl := Label.new()
	gate_lbl.text = "🏰  KINGDOM GATE"
	gate_lbl.set_position(Vector2(505,44))
	gate_lbl.add_theme_font_size_override("font_size",18)
	gate_lbl.add_theme_color_override("font_color",Color("#FFD93D"))
	gate_lbl.z_index = 6; add_child(gate_lbl)

	# Old Gatekeeper NPC — parked beside gate, facing left
	var gk: Node2D = load("res://scripts/lpc/CharacterSprite.gd").new()
	gk.position = Vector2(880, 310); gk.scale = Vector2(3.5,3.5); gk.z_index = 8
	add_child(gk)
	gk.apply({
		"body_type":"male","skin_tone":"dark","hair_style":"plain","hair_color":"gray",
		"shirt_style":"sleeveless2","shirt_color":"charcoal",
		"leg_type":"pants/white","shoe_type":"boots/basic","shoe_color":"brown",
		"sock_type":"","sock_color":"",
	})
	gk.play("idle"); gk.set_direction(3)

	# Skip hint
	var skip := Label.new()
	skip.text = "SPACE / click — advance   |   ESC — skip"
	skip.set_position(Vector2(20,692))
	skip.add_theme_font_size_override("font_size",11)
	skip.add_theme_color_override("font_color",Color("#334455"))
	add_child(skip)

func _build_crowd() -> void:
	# Chaotic crowd in background
	var positions := [
		Vector2(120,330),Vector2(200,370),Vector2(160,295),
		Vector2(1100,320),Vector2(1050,360),Vector2(1130,285),
		Vector2(580,430),Vector2(670,395),Vector2(750,450),
	]
	for i in positions.size():
		var c: Node2D = load("res://scripts/lpc/CharacterSprite.gd").new()
		c.position = positions[i]; c.scale = Vector2(2.0,2.0); c.z_index = 3
		seed(i * 9871)
		c.apply(CharacterRandomizer.randomize_character())
		c.play("idle"); c.set_direction(randi()%4)
		add_child(c)
		_crowd_nodes.append(c)

func _build_dialogue_box() -> void:
	_dlg = load("res://scenes/shared/DialogueBox.tscn").instantiate()
	add_child(_dlg)

func _play_entrance() -> void:
	# Player walks in from the bottom of the screen toward the gate
	_player_walker = load("res://scripts/lpc/CharacterSprite.gd").new()
	_player_walker.position = Vector2(640, 820)
	_player_walker.scale    = Vector2(3.5, 3.5)
	_player_walker.z_index  = 10
	add_child(_player_walker)

	var appearance: Dictionary = SaveManager.get_player_appearance()
	if appearance.is_empty():
		appearance = CharacterRandomizer.randomize_character()
	_player_walker.apply(appearance)
	_player_walker.play("walk")
	_player_walker.set_direction(0)  # walking up

	var tw := create_tween()
	tw.tween_property(_player_walker, "position:y", 370.0, 2.8).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		_player_walker.play("idle")
		_player_walker.set_direction(2)  # face camera
		await get_tree().create_timer(0.6).timeout
		_start_dialogue()
	)

func _start_dialogue() -> void:
	_dlg.show_dialogue(
		DIALOGUE_SCRIPTS.intro_arrival(),
		func(): GameRouter.go_char_create()
	)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and ke.keycode == KEY_ESCAPE:
			GameRouter.go_char_create()
