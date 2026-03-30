extends Node2D
# #REGION:MAP_TILES — Chain Train (desert) background
# bg_desert.png full-screen + rail track across centre

const TRACK_Y1: float = 310.0
const TRACK_Y2: float = 370.0
const TRACK_CY: float = 340.0

func _ready() -> void:
	_build_background()
	_build_track()
	_build_objects()

# #REGION:MAP_TILES — Desert pre-tiled full background
func _build_background() -> void:
	var bg_tex: Texture2D = AssetMap.load_tex(
		"res://assets/codemon/art/map/bg_desert.png")
	if bg_tex:
		var bg := Sprite2D.new()
		bg.texture = bg_tex; bg.position = Vector2(640, 360)
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.z_index = -10; add_child(bg)
	var para: Texture2D = AssetMap.load_tex(AssetMap.PARALLAX["desert"])
	if para:
		var ps := Sprite2D.new()
		ps.texture = para; ps.position = Vector2(640, 180)
		ps.scale = Vector2(3.5, 2.0)
		ps.modulate = Color(1.0, 0.85, 0.6, 0.35)
		ps.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ps.z_index = -9; add_child(ps)
	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0.30)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.z_index = -8; add_child(ov)

# #REGION:UI — Railway track (ties + rails)
func _build_track() -> void:
	var bed := ColorRect.new()
	bed.color = Color("#3a2a18")
	bed.set_position(Vector2(0, TRACK_Y1 - 24))
	bed.set_size(Vector2(1280, (TRACK_Y2 - TRACK_Y1) + 48))
	bed.z_index = -5; add_child(bed)
	for x in range(0, 1280, 48):
		var tie := ColorRect.new()
		tie.color = Color("#5a3a20")
		tie.set_position(Vector2(x, TRACK_Y1 - 8))
		tie.set_size(Vector2(32, TRACK_Y2 - TRACK_Y1 + 16))
		tie.z_index = -4; add_child(tie)
	for ry in [TRACK_Y1, TRACK_Y2 - 8]:
		var rail := ColorRect.new()
		rail.color = Color("#888880")
		rail.set_position(Vector2(0, ry)); rail.set_size(Vector2(1280, 8))
		rail.z_index = -3; add_child(rail)

# #REGION:OBJECTS — Cactus, skulls, conductor NPC
func _build_objects() -> void:
	var cactus: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["cactus"])
	for pos in [Vector2(80,480), Vector2(200,500), Vector2(350,520),
	Vector2(900,490), Vector2(1050,510), Vector2(1180,480),
	Vector2(130,180), Vector2(280,150), Vector2(800,190), Vector2(1120,170)]:
		_place(cactus, pos, 2.5)
	var skull: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["skull"])
	for pos in [Vector2(500,560), Vector2(750,555)]:
		_place(skull, pos, 1.8)
	var npc: Texture2D = AssetMap.npc("dr_desert")
	if npc:
		var s := Sprite2D.new()
		s.texture = npc; s.hframes = 2; s.frame = 0
		s.position = Vector2(60, TRACK_CY - 60)
		s.scale = Vector2(3.0, 3.0)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.z_index = 10; add_child(s)

func _place(tex: Texture2D, pos: Vector2, sc: float) -> void:
	if not tex: return
	var s := Sprite2D.new()
	s.texture = tex; s.position = pos; s.scale = Vector2(sc, sc)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = int(pos.y / 10); add_child(s)
