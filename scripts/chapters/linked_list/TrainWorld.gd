extends Node2D
# Chain Train — desert.png tilemap + train track sprites

const TRACK_Y1: float = 310.0
const TRACK_Y2: float = 370.0
const TRACK_CY: float = 340.0

func _ready() -> void:
	_build_background()
	_build_track()
	_build_objects()

func _build_background() -> void:
	# Desert parallax sky
	var para: Texture2D = AssetMap.load_tex(AssetMap.PARALLAX["desert"])
	if para:
		var s := Sprite2D.new()
		s.texture = para; s.position = Vector2(640, 200)
		s.scale = Vector2(3.5, 2.5); s.modulate = Color(0.7, 0.6, 0.4, 0.5)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; s.z_index = -10
		add_child(s)

	# Desert tile floor — repeat to cover width
	var tex: Texture2D = AssetMap.load_tex(AssetMap.MAP_TILES["desert"])
	if tex:
		# Desert tile is 640×256, need to fill 1280×720
		for row in 4:
			for col in 2:
				var s := Sprite2D.new()
				s.texture = tex
				s.position = Vector2(col * 640 + 320, row * 256 + 128)
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s.z_index = -9
				add_child(s)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.35)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = -8; add_child(overlay)

func _build_track() -> void:
	# Track bed (dark gravel strip)
	var bed := ColorRect.new()
	bed.color = Color("#3a2a18")
	bed.set_position(Vector2(0, TRACK_Y1 - 24))
	bed.set_size(Vector2(1280, (TRACK_Y2 - TRACK_Y1) + 48))
	bed.z_index = -5; add_child(bed)

	# Rail ties — horizontal sleepers
	for x in range(0, 1280, 48):
		var tie := ColorRect.new()
		tie.color = Color("#5a3a20")
		tie.set_position(Vector2(x, TRACK_Y1 - 8))
		tie.set_size(Vector2(32, TRACK_Y2 - TRACK_Y1 + 16))
		tie.z_index = -4; add_child(tie)

	# Rails — two horizontal lines
	var rail1 := ColorRect.new()
	rail1.color = Color("#888880")
	rail1.set_position(Vector2(0, TRACK_Y1))
	rail1.set_size(Vector2(1280, 8))
	rail1.z_index = -3; add_child(rail1)

	var rail2 := ColorRect.new()
	rail2.color = Color("#888880")
	rail2.set_position(Vector2(0, TRACK_Y2 - 8))
	rail2.set_size(Vector2(1280, 8))
	rail2.z_index = -3; add_child(rail2)

func _build_objects() -> void:
	# Cactus along the track
	var cactus: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["cactus"])
	var cactus2: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["cactus"] + "")
	# Use desert object sprites
	for x in [80, 200, 350, 900, 1050, 1180]:
		_place(cactus, Vector2(x, 500), 2.5)
	for x in [130, 280, 800, 980, 1120]:
		_place(cactus, Vector2(x, 180), 2.0)

	# Skull decorations
	var skull: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["skull"])
	for x in [500, 750]:
		_place(skull, Vector2(x, 560), 1.8)

	# Conductor NPC at left station
	var npc: Texture2D = AssetMap.npc("dr_desert")
	if npc:
		var conductor := Sprite2D.new()
		conductor.texture = npc; conductor.hframes = 2; conductor.frame = 0
		conductor.position = Vector2(60, TRACK_CY - 60)
		conductor.scale = Vector2(3.0, 3.0)
		conductor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		conductor.z_index = 10; add_child(conductor)

func _place(tex: Texture2D, pos: Vector2, sc: float) -> void:
	if not tex: return
	var s := Sprite2D.new()
	s.texture = tex; s.position = pos; s.scale = Vector2(sc, sc)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = int(pos.y); add_child(s)
