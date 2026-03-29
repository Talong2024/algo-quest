extends Node2D
# Kingdom Queue — street_tile.png based world
# Uses codemon street_tile (384×320) as repeating tilemap background
# Plus object sprites for trees, bushes, gate

const LANE_X:  float = 640.0
const LANE_W:  float = 110.0
const GATE_Y:  float = 90.0

var _bg:      Sprite2D
var _objects: Array = []

func _ready() -> void:
	_build_background()
	_build_objects()

func _build_background() -> void:
	# Tiled street background — repeat the 384x320 tile to fill 1280x720
	var tex: Texture2D = AssetMap.load_tex(AssetMap.MAP_TILES["street"])
	if tex:
		for row in 4:
			for col in 4:
				var s := Sprite2D.new()
				s.texture        = tex
				s.position       = Vector2(col * 384 - 192 + 192, row * 320 - 160 + 160)
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s.z_index        = -10
				s.scale          = Vector2(1.0, 1.0)
				add_child(s)
	else:
		# Fallback drawn background
		var bg := ColorRect.new()
		bg.color = Color("#2d4a2d")
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.z_index = -10
		add_child(bg)

	# Dark overlay so game elements are visible
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.45)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = -9
	add_child(overlay)

	# Lane highlight — cobblestone path up centre
	var lane := ColorRect.new()
	lane.color = Color(0.2, 0.15, 0.08, 0.5)
	lane.set_position(Vector2(LANE_X - LANE_W / 2.0, 0))
	lane.set_size(Vector2(LANE_W, 720))
	lane.z_index = -8
	add_child(lane)

func _build_objects() -> void:
	# Gate arch at top of lane
	var gate_tex: Texture2D = AssetMap.load_tex(
		"res://assets/codemon/art/object/beach/castle.png")
	if gate_tex:
		var gate := Sprite2D.new()
		gate.texture        = gate_tex
		gate.position       = Vector2(LANE_X, GATE_Y + 20)
		gate.scale          = Vector2(2.2, 2.2)
		gate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		gate.z_index        = 5
		add_child(gate)

	# Trees flanking the path — left side
	var tree_tex: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["tree_01"])
	var bush_tex: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["bush_1"])

	var left_x_positions:  Array = [80, 180, 120, 200, 150, 100]
	var right_x_positions: Array = [1100, 1180, 1050, 1150, 1200, 1080]
	var y_positions:       Array = [150, 250, 350, 450, 550, 630]

	for i in left_x_positions.size():
		_place_sprite(tree_tex, Vector2(left_x_positions[i],  y_positions[i]), 2.5)
		_place_sprite(tree_tex, Vector2(right_x_positions[i], y_positions[i]), 2.5)

	# Bushes between trees
	for y in [200, 300, 400, 500, 600]:
		_place_sprite(bush_tex, Vector2(320, y), 2.0)
		_place_sprite(bush_tex, Vector2(960, y), 2.0)

	# Torches / markers at lane edges
	for y in [140, 260, 380, 500, 620]:
		_draw_torch_at(Vector2(LANE_X - LANE_W / 2.0 - 12, y))
		_draw_torch_at(Vector2(LANE_X + LANE_W / 2.0 + 12, y))

func _place_sprite(tex: Texture2D, pos: Vector2, sc: float) -> void:
	if not tex: return
	var s := Sprite2D.new()
	s.texture        = tex
	s.position       = pos
	s.scale          = Vector2(sc, sc)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index        = int(pos.y)  # y-sort
	add_child(s)

func _draw_torch_at(pos: Vector2) -> void:
	# Small animated torch using ColorRect (no external asset needed)
	var base := ColorRect.new()
	base.color = Color("#8B4513")
	base.set_position(pos + Vector2(-3, -8))
	base.set_size(Vector2(6, 10))
	base.z_index = 3
	add_child(base)
	var flame := ColorRect.new()
	flame.color = Color("#FF8C00")
	flame.set_position(pos + Vector2(-4, -16))
	flame.set_size(Vector2(8, 10))
	flame.z_index = 3
	add_child(flame)
