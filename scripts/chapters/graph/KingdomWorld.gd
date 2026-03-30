extends Node2D
# #REGION:MAP_TILES — Kingdom Roads (beach) background
# bg_beach.png full-screen + roads + beach NPC

func _ready() -> void:
	_build_background()
	_build_roads()
	_build_decorations()
	_build_npc()

# #REGION:MAP_TILES — Beach pre-tiled full background
func _build_background() -> void:
	var bg_tex: Texture2D = AssetMap.load_tex(
		"res://assets/codemon/art/map/bg_beach.png")
	if bg_tex:
		var bg := Sprite2D.new()
		bg.texture = bg_tex; bg.position = Vector2(640, 360)
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.z_index = -10; add_child(bg)
	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0.05, 0.38)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.z_index = -9; add_child(ov)

# #REGION:UI — Road network lines between city nodes
func _build_roads() -> void:
	var roads: Array = [
		[Vector2(300,380), Vector2(700,370)],
		[Vector2(700,370), Vector2(880,220)],
		[Vector2(880,220), Vector2(1040,390)],
		[Vector2(500,230), Vector2(700,370)],
		[Vector2(880,220), Vector2(500,230)],
		[Vector2(300,380), Vector2(500,550)],
		[Vector2(700,370), Vector2(500,550)],
	]
	for road in roads:
		var line := Line2D.new()
		line.add_point(road[0] as Vector2)
		line.add_point(road[1] as Vector2)
		line.width = 12; line.default_color = Color("#3a2808", 0.65)
		line.z_index = -5; add_child(line)

# #REGION:OBJECTS — Beach decorations
func _build_decorations() -> void:
	var boat:  Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["boat"])
	var palm:  Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["beach_tree"])
	var water: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["water"])
	var fish:  Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["fish_1"])
	_place(water, Vector2(100, 580), 1.2); _place(water, Vector2(200, 620), 1.0)
	_place(boat,  Vector2(150, 560), 1.8)
	_place(fish,  Vector2(120, 600), 1.5); _place(fish, Vector2(220, 640), 1.2)
	for pos in [Vector2(80,200), Vector2(180,120), Vector2(1150,180),
	Vector2(1200,350), Vector2(100,480), Vector2(1100,550)]:
		_place(palm, pos, 1.8)

# #REGION:CHARACTERS — Beach NPC
func _build_npc() -> void:
	var tex: Texture2D = AssetMap.npc("dr_beach")
	if not tex: return
	var npc := Sprite2D.new()
	npc.texture = tex; npc.hframes = 2; npc.frame = 0
	npc.position = Vector2(640, 620)
	npc.scale = Vector2(3.0, 3.0)
	npc.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	npc.z_index = 10; add_child(npc)
	var t := Timer.new(); t.wait_time = 1.0; t.autostart = true
	t.timeout.connect(func():
		if is_instance_valid(npc): npc.frame = (npc.frame + 1) % 2)
	add_child(t)

func _place(tex: Texture2D, pos: Vector2, sc: float) -> void:
	if not tex: return
	var s := Sprite2D.new()
	s.texture = tex; s.position = pos; s.scale = Vector2(sc, sc)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = int(pos.y / 10); add_child(s)
