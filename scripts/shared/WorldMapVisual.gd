extends Node2D
# ═══════════════════════════════════════════════════
# WorldMapVisual.gd
# Replaces WorldMap's _draw() background with real
# codemon art. Drop-in replacement for the plain
# ColorRect tiles in WorldMap.gd.
#
# Usage: add as child of WorldMap node,
#        call setup() after _ready()
# ═══════════════════════════════════════════════════

func setup() -> void:
	_build_background()
	_build_chapter_tiles()
	_build_decorations()

func _build_background() -> void:
	# Full map overview image as base
	var map_tex: Texture2D = AssetMap.load_tex(AssetMap.WORLD_MAP)
	if map_tex:
		var bg := Sprite2D.new()
		bg.texture        = map_tex
		bg.position       = Vector2(640, 360)
		bg.scale          = Vector2(6.4, 5.14)   # stretch 200×140 → 1280×720
		bg.z_index        = -10
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(bg)
	else:
		# Fallback solid bg
		var bg := ColorRect.new()
		bg.color = Color("#1c1c0a")
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.z_index = -10
		add_child(bg)

func _build_chapter_tiles() -> void:
	# Position map tile previews near each chapter region
	# Positions match the CHAPTERS array in WorldMap.gd
	var chapter_tiles: Array = [
		{ "ch":1, "pos":Vector2(300,450), "tile":"street",   "scale":1.5 },
		{ "ch":2, "pos":Vector2(500,300), "tile":"mountain", "scale":1.2 },
		{ "ch":3, "pos":Vector2(700,440), "tile":"desert",   "scale":1.3 },
		{ "ch":4, "pos":Vector2(880,290), "tile":"forest",   "scale":1.2 },
		{ "ch":5, "pos":Vector2(1040,460),"tile":"beach",    "scale":1.4 },
	]

	for entry in chapter_tiles:
		var unlocked: bool = ProgressTracker.is_chapter_unlocked(entry["ch"] as int)
		var tile_key: String = entry["tile"] as String
		var tex_path: String = AssetMap.MAP_TILES.get(tile_key, "") as String
		if tex_path == "": continue
		var tex: Texture2D = AssetMap.load_tex(tex_path)
		if not tex: continue

		var s := Sprite2D.new()
		s.texture        = tex
		s.position       = entry["pos"] as Vector2
		s.scale          = Vector2.ONE * (entry["scale"] as float) * 0.5
		s.z_index        = -5
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.modulate       = Color(1,1,1,1) if unlocked else Color(0.3,0.3,0.3,0.6)
		add_child(s)

func _build_decorations() -> void:
	# Scatter environment objects around the map edges
	# Left area (near ch1)
	_place_obj("bush_1",  Vector2(140, 350), 2.0)
	_place_obj("bush_2",  Vector2(170, 420), 2.0)
	_place_obj("tree_01", Vector2(120, 280), 1.5)

	# Forest area (near ch4)
	_place_obj("tree_normal", Vector2(820, 160), 2.5)
	_place_obj("tree_round",  Vector2(950, 160), 2.5)
	_place_obj("mushroom",    Vector2(860, 220), 3.0)

	# Mountain area (near ch2)
	_place_obj("rock",         Vector2(440, 180), 2.0)
	_place_obj("sakura",       Vector2(560, 150), 1.8)

	# Desert area (near ch3)
	_place_obj("cactus",  Vector2(660, 480), 2.5)
	_place_obj("skull",   Vector2(780, 500), 2.0)

	# Beach area (near ch5)
	_place_obj("boat",       Vector2(1100, 350), 1.5)
	_place_obj("beach_tree", Vector2(1150, 460), 1.8)

	# Parallax bg for mountain area
	var mt_tex: Texture2D = AssetMap.load_tex(AssetMap.PARALLAX["mountain"])
	if mt_tex:
		var mt := Sprite2D.new()
		mt.texture        = mt_tex
		mt.position       = Vector2(500, 200)
		mt.z_index        = -8
		mt.modulate       = Color(1,1,1,0.3)
		mt.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(mt)

func _place_obj(key: String, pos: Vector2, sc: float) -> void:
	var tex: Texture2D = AssetMap.obj(key)
	if not tex: return
	var s := Sprite2D.new()
	s.texture        = tex
	s.position       = pos
	s.scale          = Vector2.ONE * sc
	s.z_index        = -3
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(s)
