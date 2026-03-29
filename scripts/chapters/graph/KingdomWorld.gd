extends Node2D
# Kingdom Roads — beach.png tilemap + coastal decorations

func _ready() -> void:
	_build_background()
	_build_decorations()
	_build_npc()

func _build_background() -> void:
	# Beach tile — 576×384, tile to fill screen
	var tex: Texture2D = AssetMap.load_tex(AssetMap.MAP_TILES["beach"])
	if tex:
		for row in 3:
			for col in 3:
				var s := Sprite2D.new()
				s.texture = tex
				s.position = Vector2(col * 576 + 288, row * 384 + 192)
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s.z_index = -10; add_child(s)

	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.05, 0.45)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = -9; add_child(overlay)

	# Road network underlay
	for conn in [[300,380,700,370],[700,370,880,220],
	[880,220,1040,390],[300,380,700,370],
	[500,230,700,370],[880,220,500,230]]:
		var road := ColorRect.new()
		road.color = Color("#4a3820", 0.5)
		# Draw thick road as a stretched rect — approximate
		var from := Vector2(conn[0], conn[1])
		var to   := Vector2(conn[2], conn[3])
		var mid  := (from + to) / 2.0
		var len  := from.distance_to(to)
		var ang  := from.angle_to_point(to)
		var road2 := Line2D.new()
		road2.add_point(from); road2.add_point(to)
		road2.width = 14; road2.default_color = Color("#3a2808", 0.6)
		road2.z_index = -8; add_child(road2)

func _build_decorations() -> void:
	var boat:  Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["boat"])
	var palm:  Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["beach_tree"])
	var water: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["water"])
	var fish1: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["fish_1"])

	# Water area bottom-left
	_place(water, Vector2(100, 580), 1.2)
	_place(water, Vector2(200, 620), 1.0)

	# Boat at water
	_place(boat, Vector2(150, 560), 1.8)

	# Palm trees around edges
	for pos in [Vector2(80, 200), Vector2(180, 120), Vector2(1150, 180),
	Vector2(1200, 350), Vector2(100, 480), Vector2(1100, 550)]:
		_place(palm, pos, 1.8)

	# Fish in water
	_place(fish1, Vector2(120, 600), 1.5)
	_place(fish1, Vector2(220, 640), 1.2)

func _build_npc() -> void:
	var tex: Texture2D = AssetMap.npc("dr_beach")
	if not tex: return
	var map_spirit := Sprite2D.new()
	map_spirit.texture = tex; map_spirit.hframes = 2; map_spirit.frame = 0
	map_spirit.position = Vector2(640, 620)
	map_spirit.scale = Vector2(3.0, 3.0)
	map_spirit.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map_spirit.z_index = 10; add_child(map_spirit)

	var t := Timer.new(); t.wait_time = 1.0; t.autostart = true
	t.timeout.connect(func():
		if is_instance_valid(map_spirit):
			map_spirit.frame = (map_spirit.frame + 1) % 2
	); add_child(t)

func _place(tex: Texture2D, pos: Vector2, sc: float) -> void:
	if not tex: return
	var s := Sprite2D.new()
	s.texture = tex; s.position = pos; s.scale = Vector2(sc, sc)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = int(pos.y / 10); add_child(s)
