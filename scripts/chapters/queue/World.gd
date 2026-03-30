extends Node2D
# #REGION:MAP_TILES — Kingdom Queue world background
# Uses bg_street.png (1280x720 pre-tiled) as the full background.
# Adds a central cobblestone lane, gate arch, and side trees.

const LANE_X: float = 640.0
const LANE_W: float = 110.0
const GATE_Y: float = 90.0

func _ready() -> void:
	_build_background()
	_build_lane()
	_build_objects()

# #REGION:MAP_TILES — Full-screen pre-tiled background (no scaling artifacts)
func _build_background() -> void:
	var bg_tex: Texture2D = AssetMap.load_tex(
		"res://assets/codemon/art/map/bg_street.png")
	if bg_tex:
		var bg := Sprite2D.new()
		bg.texture        = bg_tex
		bg.position       = Vector2(640, 360)
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.z_index        = -10
		add_child(bg)
	else:
		var fb := ColorRect.new()
		fb.color = Color("#9ea8a0")
		fb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fb.z_index = -10; add_child(fb)
	# Dark overlay so gameplay elements stand out
	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0.38)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.z_index = -9; add_child(ov)

# #REGION:UI — Cobblestone central lane (gameplay area)
func _build_lane() -> void:
	var lane := ColorRect.new()
	lane.color = Color("#7a6a5a", 0.55)
	lane.set_position(Vector2(LANE_X - LANE_W / 2.0, 0))
	lane.set_size(Vector2(LANE_W, 720))
	lane.z_index = -7; add_child(lane)
	# Lane edge lines
	for offset in [-LANE_W/2.0, LANE_W/2.0]:
		var edge := ColorRect.new()
		edge.color = Color("#3a2a1a", 0.7)
		edge.set_position(Vector2(LANE_X + offset - 2, 0))
		edge.set_size(Vector2(4, 720))
		edge.z_index = -6; add_child(edge)

# #REGION:OBJECTS — Gate arch and tree decorations
func _build_objects() -> void:
	var castle: Texture2D = AssetMap.load_tex(
		"res://assets/codemon/art/object/beach/castle.png")
	if castle:
		var gate := Sprite2D.new()
		gate.texture = castle; gate.position = Vector2(LANE_X, GATE_Y + 20)
		gate.scale = Vector2(2.2, 2.2)
		gate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		gate.z_index = 5; add_child(gate)
	var tree: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["tree_01"])
	for pos in [Vector2(160,200), Vector2(1120,200), Vector2(160,420),
	Vector2(1120,420), Vector2(160,580), Vector2(1120,580)]:
		_place(tree, pos, 2.8)
	var bush: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["bush_1"])
	for pos in [Vector2(340,300), Vector2(940,300), Vector2(340,500), Vector2(940,500)]:
		_place(bush, pos, 2.0)

func _place(tex: Texture2D, pos: Vector2, sc: float) -> void:
	if not tex: return
	var s := Sprite2D.new()
	s.texture = tex; s.position = pos; s.scale = Vector2(sc, sc)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = int(pos.y / 10); add_child(s)
