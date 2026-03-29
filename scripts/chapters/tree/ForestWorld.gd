extends Node2D
# Oracle's Forest — forest.png tilemap + tree sprites

func _ready() -> void:
	_build_background()
	_build_trees()
	_build_oracle()

func _build_background() -> void:
	# Forest tile floor — 320×256, tile across screen
	var tex: Texture2D = AssetMap.load_tex(AssetMap.MAP_TILES["forest"])
	if tex:
		for row in 4:
			for col in 5:
				var s := Sprite2D.new()
				s.texture = tex
				s.position = Vector2(col * 320 + 160, row * 256 + 128)
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s.z_index = -10; add_child(s)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = -9; add_child(overlay)

	# Mossy glow patches
	for pos in [Vector2(200,300), Vector2(700,150), Vector2(1050,400), Vector2(400,550)]:
		var glow := ColorRect.new()
		glow.color = Color(0.0, 0.3, 0.1, 0.15)
		glow.set_position(pos - Vector2(60, 40))
		glow.set_size(Vector2(120, 80))
		glow.z_index = -8; add_child(glow)

func _build_trees() -> void:
	var tree_n: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["tree_normal"])
	var tree_r: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["tree_round"])
	var mush:   Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["mushroom"])
	var rock:   Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["forest_rock"])

	# Left border trees
	for y in range(80, 720, 90):
		_place(tree_n, Vector2(50, y), 2.5)
		_place(tree_r, Vector2(130, y + 40), 2.2)

	# Right border trees
	for y in range(80, 720, 90):
		_place(tree_n, Vector2(1230, y), 2.5)
		_place(tree_r, Vector2(1150, y + 40), 2.2)

	# Bottom fringe
	for x in range(280, 1000, 100):
		_place(tree_n, Vector2(x, 680), 2.0)

	# Mushrooms scattered
	for pos in [Vector2(240,300), Vector2(380,480), Vector2(900,220),
	Vector2(1010,510), Vector2(550,600)]:
		_place(mush, pos, 3.0)

	# Forest rocks
	for pos in [Vector2(200,400), Vector2(1050,350), Vector2(320,550)]:
		_place(rock, pos, 2.5)

func _build_oracle() -> void:
	# Oracle NPC at center-top
	var tex: Texture2D = AssetMap.npc("dr_forest")
	if not tex: return
	var oracle := Sprite2D.new()
	oracle.texture = tex; oracle.hframes = 2; oracle.frame = 0
	oracle.position = Vector2(640, 100)
	oracle.scale = Vector2(3.5, 3.5)
	oracle.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	oracle.z_index = 10; add_child(oracle)

	# Idle animation
	var t := Timer.new(); t.wait_time = 1.2; t.autostart = true
	t.timeout.connect(func():
		if is_instance_valid(oracle):
			oracle.frame = (oracle.frame + 1) % 2
	); add_child(t)

func _place(tex: Texture2D, pos: Vector2, sc: float) -> void:
	if not tex: return
	var s := Sprite2D.new()
	s.texture = tex; s.position = pos; s.scale = Vector2(sc, sc)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = int(pos.y / 10); add_child(s)
