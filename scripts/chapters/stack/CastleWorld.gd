extends Node2D
# Castle of Echoes — mountain.png tilemap + parallax bg
# Stone corridor, enchanted door, wizard NPC sprite

const LANE_X:   float = 640.0
const LANE_W:   float = 120.0
const DOOR_Y:   float = 80.0
const WIZARD_Y: float = 640.0

var door_unlocked_count: int = 0
var total_locks:         int = 3
var phase:               String = "push"

var _wizard_sprite: Sprite2D

func _ready() -> void:
	_build_background()
	_build_npc()
	_build_door()
	_build_torches()

func _build_background() -> void:
	# Parallax mountain background
	var para_tex: Texture2D = AssetMap.load_tex(AssetMap.PARALLAX["mountain"])
	if para_tex:
		var para := Sprite2D.new()
		para.texture        = para_tex
		para.position       = Vector2(640, 280)
		para.scale          = Vector2(3.0, 2.2)
		para.modulate       = Color(0.4, 0.3, 0.5, 0.6)
		para.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		para.z_index        = -10
		add_child(para)

	# Mountain tile as floor
	var floor_tex: Texture2D = AssetMap.load_tex(AssetMap.MAP_TILES["mountain"])
	if floor_tex:
		for row in 7:
			var s := Sprite2D.new()
			s.texture        = floor_tex
			s.position       = Vector2(640, row * 128 + 64)
			s.scale          = Vector2(4.2, 1.0)
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.z_index        = -9
			add_child(s)

	# Dark stone overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0.05, 0.03, 0.08, 0.6)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = -8
	add_child(overlay)

	# Corridor walls
	var wall_l := ColorRect.new()
	wall_l.color = Color("#1a0d22")
	wall_l.set_position(Vector2(0, 0))
	wall_l.set_size(Vector2(LANE_X - LANE_W / 2.0, 720))
	wall_l.z_index = -7
	add_child(wall_l)

	var wall_r := ColorRect.new()
	wall_r.color = Color("#1a0d22")
	wall_r.set_position(Vector2(LANE_X + LANE_W / 2.0, 0))
	wall_r.set_size(Vector2(1280 - LANE_X - LANE_W / 2.0, 720))
	wall_r.z_index = -7
	add_child(wall_r)

	# Stone floor strip
	var floor_strip := ColorRect.new()
	floor_strip.color = Color("#2a2040")
	floor_strip.set_position(Vector2(LANE_X - LANE_W / 2.0, 0))
	floor_strip.set_size(Vector2(LANE_W, 720))
	floor_strip.z_index = -7
	add_child(floor_strip)

	# Wall rocks
	for tex_key in ["rock", "rock"]:
		var rt: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS.get("rock", ""))
		if rt:
			for y in [200, 400, 600]:
				_place(rt, Vector2(LANE_X - LANE_W / 2.0 - 40, y), 1.5)
				_place(rt, Vector2(LANE_X + LANE_W / 2.0 + 40, y), 1.5)

func _build_npc() -> void:
	# Wizard NPC sprite (dr_mountain)
	var tex: Texture2D = AssetMap.npc("dr_mountain")
	if tex:
		_wizard_sprite = Sprite2D.new()
		_wizard_sprite.texture        = tex
		_wizard_sprite.hframes        = 2
		_wizard_sprite.frame          = 0
		_wizard_sprite.position       = Vector2(LANE_X, WIZARD_Y)
		_wizard_sprite.scale          = Vector2(3.5, 3.5)
		_wizard_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_wizard_sprite.z_index        = 10
		add_child(_wizard_sprite)

		# Animate wizard frame
		var timer := Timer.new()
		timer.wait_time = 0.8
		timer.autostart = true
		timer.timeout.connect(func():
			if is_instance_valid(_wizard_sprite):
				_wizard_sprite.frame = (_wizard_sprite.frame + 1) % 2
		)
		add_child(timer)

func _build_door() -> void:
	# Bridge as door visual
	var bridge_tex: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS["bridge_back"])
	if bridge_tex:
		var door := Sprite2D.new()
		door.texture        = bridge_tex
		door.position       = Vector2(LANE_X, DOOR_Y + 20)
		door.scale          = Vector2(0.28, 2.0)
		door.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		door.z_index        = 5
		add_child(door)

func _build_torches() -> void:
	for y in [150, 280, 420, 560]:
		_build_torch(Vector2(LANE_X - LANE_W / 2.0 - 16, y))
		_build_torch(Vector2(LANE_X + LANE_W / 2.0 + 16, y))

func _build_torch(pos: Vector2) -> void:
	var base := ColorRect.new()
	base.color = Color("#5a3010")
	base.set_position(pos + Vector2(-4, -10))
	base.set_size(Vector2(8, 14))
	base.z_index = 4
	add_child(base)
	var glow := ColorRect.new()
	glow.color = Color("#FF6600", 0.7)
	glow.set_position(pos + Vector2(-10, -22))
	glow.set_size(Vector2(20, 16))
	glow.z_index = 4
	add_child(glow)

func _place(tex: Texture2D, pos: Vector2, sc: float) -> void:
	if not tex: return
	var s := Sprite2D.new()
	s.texture = tex; s.position = pos; s.scale = Vector2(sc, sc)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; s.z_index = 2
	add_child(s)

func notify_push() -> void:
	phase = "push"
	if is_instance_valid(_wizard_sprite): _wizard_sprite.frame = 0

func notify_pop(unlocked: int) -> void:
	door_unlocked_count = unlocked
	if is_instance_valid(_wizard_sprite): _wizard_sprite.frame = 1
