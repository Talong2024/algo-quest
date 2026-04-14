extends Node2D
## World — Kingdom Queue scene.
## Loaded via .tscn so all nodes exist. Doorman built fully in code here
## so it works whether loaded from .tscn OR via GDScript.new().

func _ready() -> void:
	_setup_player_doorman()
	_setup_trees()

func _setup_player_doorman() -> void:
	# The player IS the doorman — show their created character beside the gate
	var doorman: Node2D = get_node_or_null("Doorman") as Node2D
	if not is_instance_valid(doorman):
		doorman = load("res://scripts/lpc/CharacterSprite.gd").new()
		doorman.name     = "Doorman"
		doorman.scale    = Vector2(3.5, 3.5)
		doorman.position = Vector2(760, 303)
		doorman.z_index  = 10
		add_child(doorman)

	# Label shows player name
	var player_name: String = ProgressTracker.get_player_name()
	var lbl := Label.new()
	lbl.text = player_name if player_name != "" else "You"
	lbl.position = Vector2(730, 56)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#FFD93D"))
	lbl.z_index = 11
	add_child(lbl)

	# Use the player's created appearance
	var appearance: Dictionary = SaveManager.get_player_appearance()
	if appearance.is_empty():
		appearance = CharacterRandomizer.randomize_character()
	doorman.apply(appearance)
	doorman.play("idle")
	doorman.set_direction(3)  # face left (toward the lane)

func _setup_trees() -> void:
	var tree_tex: Texture2D = AssetMap.load_tex("res://assets/codemon/art/object/tree_01.png")
	var bush_tex: Texture2D = AssetMap.load_tex("res://assets/codemon/art/object/bush_01.png")
	for node_name in ["TreeLeft1","TreeLeft2","TreeLeft3","TreeRight1","TreeRight2","TreeRight3"]:
		var node: Sprite2D = get_node_or_null(node_name) as Sprite2D
		if node:
			node.texture = tree_tex if "Tree" in node_name else bush_tex
