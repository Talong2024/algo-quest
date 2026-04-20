extends Node2D
## World — Kingdom Queue game world.
## Doorman = player's character, stands RIGHT of the gate arch.

func _ready() -> void:
	_setup_player_doorman()
	_setup_trees()

func _setup_player_doorman() -> void:
	var doorman: Node2D = get_node_or_null("Doorman") as Node2D
	if not is_instance_valid(doorman):
		doorman = load("res://scripts/lpc/CharacterSprite.gd").new()
		doorman.name     = "Doorman"
		doorman.scale    = Vector2(2.5, 2.5)
		# Position: clearly RIGHT of the gate arch, outside the lane
		# Gate arch: x=490-790. Lane: x=590-690. Doorman at x=820 = safe right side.
		doorman.position = Vector2(840, 300)
		doorman.z_index  = 10
		add_child(doorman)

	# Small name label above doorman, not overlapping gate sign
	var player_name: String = ProgressTracker.get_player_name()
	var lbl := Label.new()
	lbl.text = "(You)" if player_name == "" else player_name
	lbl.position = Vector2(820, 200)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#FFD93D"))
	lbl.z_index = 11
	add_child(lbl)

	var appearance: Dictionary = SaveManager.get_player_appearance()
	if appearance.is_empty():
		appearance = CharacterRandomizer.randomize_character()
	doorman.apply(appearance)
	doorman.play("idle")
	doorman.set_direction(1)  # face left toward the lane

func _setup_trees() -> void:
	var tree_tex: Texture2D = AssetMap.load_tex("res://assets/codemon/art/object/tree_01.png")
	for node_name in ["TreeLeft1","TreeLeft2","TreeLeft3","TreeRight1","TreeRight2","TreeRight3"]:
		var node: Sprite2D = get_node_or_null(node_name) as Sprite2D
		if node:
			node.texture = tree_tex
