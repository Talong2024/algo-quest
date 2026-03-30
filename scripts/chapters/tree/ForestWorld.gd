extends Node2D
# #REGION:MAP_TILES — Oracle's Forest background
# bg_forest.png full-screen + tree border + oracle NPC

func _ready() -> void:
	_build_background()
	_build_trees()
	_build_oracle()

# #REGION:MAP_TILES — Forest pre-tiled full background
func _build_background() -> void:
	var bg_tex: Texture2D = AssetMap.load_tex(
		"res://assets/codemon/art/map/bg_forest.png")
	if bg_tex:
		var bg := Sprite2D.new()
		bg.texture = bg_tex; bg.position = Vector2(640, 360)
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.z_index = -10; add_child(bg)
	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0.40)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.z_index = -9; add_child(ov)
	# Magic glow patches
	for pos in [Vector2(200,300), Vector2(700,150), Vector2(1050,400)]:
		var glow := ColorRect.new()
		glow.color = Color(0.0, 0.3, 0.1, 0.15)
		glow.set_position(pos - Vector2(60,40)); glow.set_size(Vector2(120, 80))
		glow.z_index = -8; add_child(glow)

# #REGION:OBJECTS — Border trees and mushrooms
func _build_trees() -> void:
	var tn: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["tree_normal"])
	var tr: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["tree_round"])
	var mu: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["mushroom"])
	var ro: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["forest_rock"])
	for y in range(80, 720, 90):
		_place(tn, Vector2(50, y), 2.5)
		_place(tr, Vector2(130, y + 40), 2.2)
		_place(tn, Vector2(1230, y), 2.5)
		_place(tr, Vector2(1150, y + 40), 2.2)
	for x in range(280, 1000, 100):
		_place(tn, Vector2(x, 680), 2.0)
	for pos in [Vector2(240,300), Vector2(380,480), Vector2(900,220),
	Vector2(1010,510), Vector2(550,600)]:
		_place(mu, pos, 3.0)
	for pos in [Vector2(200,400), Vector2(1050,350), Vector2(320,550)]:
		_place(ro, pos, 2.5)

# #REGION:CHARACTERS — Oracle NPC at top-centre
func _build_oracle() -> void:
	var tex: Texture2D = AssetMap.npc("dr_forest")
	if not tex: return
	var oracle := Sprite2D.new()
	oracle.texture = tex; oracle.hframes = 2; oracle.frame = 0
	oracle.position = Vector2(640, 100)
	oracle.scale = Vector2(3.5, 3.5)
	oracle.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	oracle.z_index = 10; add_child(oracle)
	var t := Timer.new(); t.wait_time = 1.2; t.autostart = true
	t.timeout.connect(func():
		if is_instance_valid(oracle): oracle.frame = (oracle.frame + 1) % 2)
	add_child(t)

func _place(tex: Texture2D, pos: Vector2, sc: float) -> void:
	if not tex: return
	var s := Sprite2D.new()
	s.texture = tex; s.position = pos; s.scale = Vector2(sc, sc)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = int(pos.y / 10); add_child(s)
