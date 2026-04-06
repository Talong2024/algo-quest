extends Node2D
# #REGION:MAP_TILES — Kingdom Queue world
# Built entirely in code (no @onready) since Game.gd
# instantiates this via load("World.gd").new().
# NPC doorman now uses CharacterSprite (LPC).

const LANE_X: float = 640.0
const LANE_W: float = 110.0

func _ready() -> void:
	_build_background()
	_build_walls()
	_build_lane()
	_build_gate()
	_build_torches()
	_build_trees()
	_build_npc()

# #REGION:MAP_TILES
func _build_background() -> void:
	var bg_tex: Texture2D = AssetMap.load_tex("res://assets/codemon/art/map/bg_street.png")
	if bg_tex:
		var bg := Sprite2D.new()
		bg.texture = bg_tex
		bg.position = Vector2(640, 360)
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.z_index = -10
		add_child(bg)
	var ov := ColorRect.new()
	ov.color = Color(0, 0, 0, 0.38)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.z_index = -9
	add_child(ov)

# #REGION:UI — Stone walls
func _build_walls() -> void:
	var wl := ColorRect.new()
	wl.color = Color("#2d1e10")
	wl.set_position(Vector2(0, 0))
	wl.set_size(Vector2(LANE_X - LANE_W/2, 720))
	wl.z_index = -7; add_child(wl)
	var wr := ColorRect.new()
	wr.color = Color("#2d1e10")
	wr.set_position(Vector2(LANE_X + LANE_W/2, 0))
	wr.set_size(Vector2(1280 - LANE_X - LANE_W/2, 720))
	wr.z_index = -7; add_child(wr)
	for i in 12:
		var lh := ColorRect.new()
		lh.color = Color("#1a0e06", 0.5)
		lh.set_position(Vector2(0, i * 60)); lh.set_size(Vector2(LANE_X - LANE_W/2, 2))
		lh.z_index = -6; add_child(lh)
		var lh2 := ColorRect.new()
		lh2.color = Color("#1a0e06", 0.5)
		lh2.set_position(Vector2(LANE_X + LANE_W/2, i * 60))
		lh2.set_size(Vector2(1280 - LANE_X - LANE_W/2, 2))
		lh2.z_index = -6; add_child(lh2)
	var el := ColorRect.new()
	el.color = Color("#0a0605")
	el.set_position(Vector2(LANE_X - LANE_W/2 - 3, 0)); el.set_size(Vector2(4, 720))
	el.z_index = -6; add_child(el)
	var er := ColorRect.new()
	er.color = Color("#0a0605")
	er.set_position(Vector2(LANE_X + LANE_W/2, 0)); er.set_size(Vector2(4, 720))
	er.z_index = -6; add_child(er)

# #REGION:UI — Lane
func _build_lane() -> void:
	var lane := ColorRect.new()
	lane.color = Color("#6a5a48", 0.6)
	lane.set_position(Vector2(LANE_X - LANE_W/2, 0)); lane.set_size(Vector2(LANE_W, 720))
	lane.z_index = -8; add_child(lane)
	for i in 10:
		var jh := ColorRect.new()
		jh.color = Color("#3a2a1a", 0.4)
		jh.set_position(Vector2(LANE_X - LANE_W/2, i * 72)); jh.set_size(Vector2(LANE_W, 2))
		jh.z_index = -7; add_child(jh)

# #REGION:UI — Castle gate
func _build_gate() -> void:
	var arch := ColorRect.new()
	arch.color = Color("#1a0d06")
	arch.set_position(Vector2(LANE_X - 80, 0)); arch.set_size(Vector2(160, 90))
	arch.z_index = 4; add_child(arch)
	var arch_inner := ColorRect.new()
	arch_inner.color = Color("#0a0604")
	arch_inner.set_position(Vector2(LANE_X - 50, 0)); arch_inner.set_size(Vector2(100, 75))
	arch_inner.z_index = 5; add_child(arch_inner)
	var gate_lbl := Label.new()
	gate_lbl.text = "KINGDOM GATE"
	gate_lbl.set_position(Vector2(LANE_X - 62, 18))
	gate_lbl.add_theme_font_size_override("font_size", 11)
	gate_lbl.add_theme_color_override("font_color", Color("#FFD93D"))
	gate_lbl.z_index = 6; add_child(gate_lbl)
	for i in 4:
		var bar := ColorRect.new()
		bar.color = Color("#4a3018", 0.9)
		bar.set_position(Vector2(LANE_X - 48 + i * 26, 0)); bar.set_size(Vector2(8, 72))
		bar.z_index = 5; add_child(bar)

# #REGION:OBJECTS — Torches
func _build_torches() -> void:
	for y in [130, 260, 390, 520, 650]:
		_torch(Vector2(LANE_X - LANE_W/2 - 20, y))
		_torch(Vector2(LANE_X + LANE_W/2 + 12, y))

func _torch(pos: Vector2) -> void:
	var pole := ColorRect.new()
	pole.color = Color("#5a3010")
	pole.set_position(pos + Vector2(0, -12)); pole.set_size(Vector2(8, 16))
	pole.z_index = 3; add_child(pole)
	var glow := ColorRect.new()
	glow.color = Color("#FF9900", 0.8)
	glow.set_position(pos + Vector2(-4, -26)); glow.set_size(Vector2(16, 18))
	glow.z_index = 3; add_child(glow)
	var inner := ColorRect.new()
	inner.color = Color("#FFFF44", 0.9)
	inner.set_position(pos + Vector2(0, -22)); inner.set_size(Vector2(8, 10))
	inner.z_index = 4; add_child(inner)

# #REGION:OBJECTS — Trees
func _build_trees() -> void:
	var tree_tex: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS.get("tree_01",""))
	var bush_tex: Texture2D = AssetMap.load_tex(AssetMap.OBJECTS.get("bush_1",""))
	for pos in [Vector2(80,200), Vector2(200,400), Vector2(100,580),
	Vector2(1180,200), Vector2(1060,400), Vector2(1160,580)]:
		_place(tree_tex, pos, 2.8)
	for pos in [Vector2(300,260), Vector2(140,340), Vector2(950,260), Vector2(1080,340)]:
		_place(bush_tex, pos, 2.0)

# #REGION:CHARACTERS — Doorman NPC using LPC CharacterSprite
func _build_npc() -> void:
	# Create a CharacterSprite for the doorman
	var npc: Node2D = load("res://scripts/lpc/CharacterSprite.gd").new()
	npc.name = "Doorman_LPC"

	# Give the doorman a fixed, distinctive appearance — guard-like
	var doorman_appearance := {
		"body_type":   "male",
		"skin_tone":   "tanned",
		"hair_style":  "shorthawk",
		"hair_color":  "dark_brown",
		"shirt_style": "sleeveless2",
		"shirt_color": "charcoal",
		"leg_type":    "armor/metal",
		"shoe_type":   "boots/basic",
		"shoe_color":  "brown",
		"sock_type":   "",
		"sock_color":  "",
	}
	# Scale up and place to the right of the gate, beside the lane
	var npc_scale := 3.5
	npc.scale = Vector2(npc_scale, npc_scale)
	npc.position = Vector2(LANE_X + LANE_W/2 + 30, 80)
	npc.z_index = 10
	add_child(npc)  # add_child FIRST so _ready() fires and _layers are built
	npc.apply(doorman_appearance)
	npc.play("combat_idle")
	npc.set_direction(2)

	# "DOORMAN" label above
	var lbl := Label.new()
	lbl.text = "Doorman"
	lbl.set_position(Vector2(LANE_X + LANE_W/2 + 18, 56))
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color("#FFD93D"))
	lbl.z_index = 11
	add_child(lbl)

func _place(tex: Texture2D, pos: Vector2, sc: float) -> void:
	if not tex: return
	var s := Sprite2D.new()
	s.texture = tex; s.position = pos; s.scale = Vector2(sc, sc)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = int(pos.y / 10); add_child(s)
