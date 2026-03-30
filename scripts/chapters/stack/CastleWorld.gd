extends Node2D
# #REGION:MAP_TILES — Castle of Echoes background
# bg_mountain.png full-screen + dark stone corridor

const LANE_X: float = 640.0
const LANE_W: float = 120.0
const WIZARD_Y: float = 640.0

var door_unlocked_count: int = 0
var total_locks:         int = 3
var phase:               String = "push"
var _wizard_sprite: Sprite2D

func _ready() -> void:
	_build_background()
	_build_corridor()
	_build_npc()
	_build_torches()

# #REGION:MAP_TILES — Mountain pre-tiled full background
func _build_background() -> void:
	var bg_tex: Texture2D = AssetMap.load_tex(
		"res://assets/codemon/art/map/bg_mountain.png")
	if bg_tex:
		var bg := Sprite2D.new()
		bg.texture = bg_tex; bg.position = Vector2(640, 360)
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.z_index = -10; add_child(bg)
	var ov := ColorRect.new()
	ov.color = Color(0.04, 0.02, 0.08, 0.55)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.z_index = -9; add_child(ov)
	# Parallax sky strip top
	var para: Texture2D = AssetMap.load_tex(AssetMap.PARALLAX["mountain"])
	if para:
		var ps := Sprite2D.new()
		ps.texture = para; ps.position = Vector2(640, 160)
		ps.scale = Vector2(3.5, 1.8)
		ps.modulate = Color(0.5, 0.4, 0.6, 0.4)
		ps.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ps.z_index = -8; add_child(ps)

# #REGION:UI — Stone corridor walls and floor strip
func _build_corridor() -> void:
	var wall_l := ColorRect.new()
	wall_l.color = Color("#1a0d22")
	wall_l.set_position(Vector2(0, 0))
	wall_l.set_size(Vector2(LANE_X - LANE_W / 2.0, 720))
	wall_l.z_index = -7; add_child(wall_l)
	var wall_r := ColorRect.new()
	wall_r.color = Color("#1a0d22")
	wall_r.set_position(Vector2(LANE_X + LANE_W / 2.0, 0))
	wall_r.set_size(Vector2(1280 - LANE_X - LANE_W / 2.0, 720))
	wall_r.z_index = -7; add_child(wall_r)
	var floor_strip := ColorRect.new()
	floor_strip.color = Color("#2a2040")
	floor_strip.set_position(Vector2(LANE_X - LANE_W / 2.0, 0))
	floor_strip.set_size(Vector2(LANE_W, 720))
	floor_strip.z_index = -7; add_child(floor_strip)

# #REGION:CHARACTERS — Wizard NPC with idle animation
func _build_npc() -> void:
	var tex: Texture2D = AssetMap.npc("dr_mountain")
	if not tex: return
	_wizard_sprite = Sprite2D.new()
	_wizard_sprite.texture = tex; _wizard_sprite.hframes = 2; _wizard_sprite.frame = 0
	_wizard_sprite.position = Vector2(LANE_X, WIZARD_Y)
	_wizard_sprite.scale = Vector2(3.5, 3.5)
	_wizard_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_wizard_sprite.z_index = 10; add_child(_wizard_sprite)
	var t := Timer.new(); t.wait_time = 0.8; t.autostart = true
	t.timeout.connect(func():
		if is_instance_valid(_wizard_sprite):
			_wizard_sprite.frame = (_wizard_sprite.frame + 1) % 2)
	add_child(t)

# #REGION:OBJECTS — Wall torches
func _build_torches() -> void:
	for y in [150, 280, 420, 560]:
		_torch(Vector2(LANE_X - LANE_W / 2.0 - 16, y))
		_torch(Vector2(LANE_X + LANE_W / 2.0 + 16, y))

func _torch(pos: Vector2) -> void:
	var base := ColorRect.new()
	base.color = Color("#5a3010")
	base.set_position(pos + Vector2(-4, -10)); base.set_size(Vector2(8, 14))
	base.z_index = 4; add_child(base)
	var glow := ColorRect.new()
	glow.color = Color("#FF6600", 0.7)
	glow.set_position(pos + Vector2(-10, -22)); glow.set_size(Vector2(20, 16))
	glow.z_index = 4; add_child(glow)

func notify_push() -> void:
	phase = "push"
	if is_instance_valid(_wizard_sprite): _wizard_sprite.frame = 0
func notify_pop(_unlocked: int) -> void:
	if is_instance_valid(_wizard_sprite): _wizard_sprite.frame = 1
