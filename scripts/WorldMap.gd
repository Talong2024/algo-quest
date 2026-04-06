extends Node2D
# ═══════════════════════════════════════════════════
# WorldMap.gd — AlgoQuest Kingdom Map
# #REGION:MAP_TILES  — Full map background
# #REGION:CHARACTERS — LPC player avatar walks the map
# #REGION:UI         — Chapter nodes, roads, HUD, tooltip
# ═══════════════════════════════════════════════════

const LPC_SPRITE = preload("res://scripts/lpc/CharacterSprite.gd")

const CHAPTERS: Array = [
	{"id":1,"name":"Kingdom Gate",    "game":"Kingdom Queue",   "dsa":"Queue — FIFO",
	 "pos":Vector2(300,380),"color":Color("#6BCB77"),"icon":"🏰"},
	{"id":2,"name":"Castle of Echoes","game":"Castle of Echoes","dsa":"Stack — LIFO",
	 "pos":Vector2(500,230),"color":Color("#C77DFF"),"icon":"🗼"},
	{"id":3,"name":"Chain Station",   "game":"Chain Train",     "dsa":"Linked List",
	 "pos":Vector2(700,370),"color":Color("#FFD93D"),"icon":"🚂"},
	{"id":4,"name":"Oracle's Forest", "game":"Oracle's Forest", "dsa":"BST/AVL/Heap",
	 "pos":Vector2(880,220),"color":Color("#6BCB77"),"icon":"🌲"},
	{"id":5,"name":"Kingdom Roads",   "game":"Kingdom Roads",   "dsa":"Graph Algorithms",
	 "pos":Vector2(1040,390),"color":Color("#4D96FF"),"icon":"🗺"},
]
const ROADS: Array = [[1,2],[1,3],[2,3],[2,4],[3,5],[4,5]]

var _map_data:   Dictionary = {}
var _hover_id:   int        = -1
var _avatar_pos: Vector2    = Vector2(300, 380)

# Scene nodes — @onready matches the rewritten .tscn
@onready var _map_bg:      Sprite2D       = $MapBackground
@onready var _avatar:      Node2D         = $PlayerAvatar
@onready var _av_label:    Label          = $PlayerAvatar/AvatarLabel
@onready var _anim:        AnimationPlayer = $AnimationPlayer
@onready var _tooltip_bg:  Control        = $HUD/TooltipBG
@onready var _tooltip_lbl: Label          = $HUD/TooltipBG/TooltipLbl

# LPC avatar sprite — created in _build_player_avatar
var _av_sprite: Node2D = null

func _ready() -> void:
	ProgressTracker.update_login_streak()
	_map_data = ProgressTracker.get_world_map_snapshot()
	_build_map_background()
	_build_player_avatar()
	_build_hud()
	_build_region_areas()
	_play_enter_animation()
	queue_redraw()

# ══════════════════════════════════════════════════
# #REGION:MAP_TILES
# ══════════════════════════════════════════════════
func _build_map_background() -> void:
	var tex: Texture2D = AssetMap.load_tex("res://assets/codemon/art/map/bg_forest.png")
	if tex and is_instance_valid(_map_bg):
		_map_bg.texture  = tex
		_map_bg.position = Vector2(640, 360)

# ══════════════════════════════════════════════════
# #REGION:CHARACTERS — LPC player avatar
# ══════════════════════════════════════════════════
func _build_player_avatar() -> void:
	# Create CharacterSprite as child of PlayerAvatar node
	_av_sprite = LPC_SPRITE.new()
	_av_sprite.name  = "LPCSprite"
	_av_sprite.scale = Vector2(2.5, 2.5)
	# Offset: feet at node origin y=0, centered horizontally
	# feet at tile row 61 of 64, scale 2.5 → y=-61*2.5=-152, x=-32*2.5=-80
	_av_sprite.position = Vector2(-32 * 2.5, -61 * 2.5)
	_avatar.add_child(_av_sprite)

	# Apply saved player appearance (or random if first run)
	var appearance: Dictionary = SaveManager.get_player_appearance()
	if appearance.is_empty():
		appearance = CharacterRandomizer.randomize_character()
	_av_sprite.apply(appearance)
	_av_sprite.play("idle")
	_av_sprite.set_direction(2)

	# Name label
	_av_label.text = ProgressTracker.get_player_name()

	# Place avatar at starting position
	_avatar.position = _avatar_pos

func _play_avatar_anim(anim: String, dir: int) -> void:
	if is_instance_valid(_av_sprite):
		_av_sprite.play(anim)
		_av_sprite.set_direction(dir)

# ══════════════════════════════════════════════════
# #REGION:UI — Top HUD bar
# ══════════════════════════════════════════════════
func _build_hud() -> void:
	var hud_bar: CanvasLayer = $HUD as CanvasLayer
	var bg := ColorRect.new()
	bg.color = Color(0,0,0,0.75)
	bg.set_position(Vector2.ZERO)
	bg.set_size(Vector2(1280, 58))
	hud_bar.add_child(bg)

	_hud_lbl(hud_bar, "ALGOQUEST",   Vector2(20,8),  10, Color("#4D96FF"))
	_hud_lbl(hud_bar, "Kingdom Map", Vector2(20,26), 20, Color("#e8e8d0"))
	_hud_lbl(hud_bar, ProgressTracker.get_player_name(), Vector2(820,10), 13, Color("#888860"))

	var stats: Dictionary = ProgressTracker.get_all_stats()
	_hud_lbl(hud_bar,
		"Score: %d  |  Perfects: %d  |  Streak: %d days" % [
			stats.get("total_score",0) as int,
			stats.get("perfect_clears",0) as int,
			stats.get("login_streak",0) as int],
		Vector2(820,30), 12, Color("#FFD93D"))

	var btns: Array = [
		["Character", func(): GameRouter.go_char_select()],
		["Progress",  func(): GameRouter.go_progress_screen()],
		["Settings",  func(): GameRouter.go_settings()],
	]
	for i: int in btns.size():
		var b: Button = AssetMap.make_codemon_button(btns[i][0] as String, Vector2(96,28))
		b.position = Vector2(790 + i*108, 62)
		b.pressed.connect(btns[i][1] as Callable)
		hud_bar.add_child(b)

	# DSA mastery dots
	var topics: Array[String] = ["queue","stack","linked_list","tree","graph"]
	var tcols:  Array[Color]  = [Color("#6BCB77"),Color("#C77DFF"),Color("#FFD93D"),Color("#6BCB77"),Color("#4D96FF")]
	for i: int in topics.size():
		var m: bool = (ProgressTracker.get_dsa_mastery(topics[i]) as Dictionary).get("mastered",false) as bool
		var dot := ColorRect.new()
		dot.color = tcols[i] if m else Color("#1a1a2a")
		dot.set_position(Vector2(200+i*24, 68))
		dot.set_size(Vector2(18,10))
		hud_bar.add_child(dot)

func _hud_lbl(parent: Node, text: String, pos: Vector2, sz: int, col: Color) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)

# ══════════════════════════════════════════════════
# #REGION:UI — Click areas for each chapter node
# ══════════════════════════════════════════════════
func _build_region_areas() -> void:
	for ch: Dictionary in CHAPTERS:
		var cid:      int     = ch["id"] as int
		var pos:      Vector2 = ch["pos"] as Vector2
		var unlocked: bool    = (_map_data.get(cid,{}) as Dictionary).get("unlocked", cid==1) as bool
		var area  := Area2D.new()
		var shape := CollisionShape2D.new()
		var circ  := CircleShape2D.new()
		circ.radius = 54.0
		shape.shape = circ
		area.position = pos
		area.add_child(shape)
		area.input_event.connect(func(_vp: Node, event: InputEvent, _idx: int):
			if event is InputEventMouseButton:
				var mb: InputEventMouseButton = event as InputEventMouseButton
				if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
					_click(cid, unlocked, pos))
		area.mouse_entered.connect(func(): _hover(cid, pos))
		area.mouse_exited.connect(func(): _unhover())
		add_child(area)

# ══════════════════════════════════════════════════
# #REGION:ANIMATION — Fade-in on enter
# ══════════════════════════════════════════════════
func _play_enter_animation() -> void:
	if not is_instance_valid(_anim): return
	var anim := Animation.new()
	anim.length = 0.8
	var t: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t, ".:modulate:a")
	anim.track_insert_key(t, 0.0, 0.0)
	anim.track_insert_key(t, 0.8, 1.0)
	var lib := AnimationLibrary.new()
	lib.add_animation("enter", anim)
	_anim.add_animation_library("", lib)
	_anim.play("enter")

# ══════════════════════════════════════════════════
# #REGION:UI — Draw map roads and chapter nodes
# ══════════════════════════════════════════════════
func _draw() -> void:
	# Roads
	for conn: Array in ROADS:
		var pa: Vector2 = CHAPTERS[conn[0]-1]["pos"] as Vector2
		var pb: Vector2 = CHAPTERS[conn[1]-1]["pos"] as Vector2
		var ca: bool    = (_map_data.get(conn[0],{}) as Dictionary).get("complete",false) as bool
		draw_line(pa, pb, Color("#3a3010"), 6.0)
		draw_line(pa, pb, Color("#5a5020") if ca else Color("#2a2010"), 3.0)

	for ch: Dictionary in CHAPTERS:
		var cid:      int     = ch["id"] as int
		var pos:      Vector2 = ch["pos"] as Vector2
		var col:      Color   = ch["color"] as Color
		var d:        Dictionary = _map_data.get(cid,{}) as Dictionary
		var unlocked: bool    = d.get("unlocked", cid==1) as bool
		var complete: bool    = d.get("complete", false)  as bool
		var mastered: bool    = d.get("mastered", false)  as bool
		var hover:    bool    = _hover_id == cid
		var score:    int     = d.get("best_score", 0)    as int

		draw_circle(pos, 64, Color("#1a1a08", 0.8))
		if unlocked:
			var g: Color = Color("#FFD93D") if mastered else col
			draw_circle(pos, 60, g * Color(1,1,1, 0.12 + (0.1 if hover else 0.0)))
		draw_circle(pos+Vector2(3,3), 46, Color(0,0,0,0.5))
		draw_circle(pos, 46, col.darkened(0.5) if unlocked else Color("#1a1a10"))
		var border: Color = Color("#FFD93D") if mastered else \
			(col.lightened(0.3) if hover else (col if unlocked else Color("#2a2a10")))
		draw_arc(pos, 46, 0, TAU, 32, border, 2.5)
		draw_string(ThemeDB.fallback_font, pos+Vector2(-12,8),
			ch["icon"] as String, HORIZONTAL_ALIGNMENT_LEFT, -1, 22,
			col if unlocked else Color("#333320"))
		if not unlocked:
			draw_string(ThemeDB.fallback_font, pos+Vector2(-10,22),
				"🔒", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#555530"))
		if complete:
			draw_string(ThemeDB.fallback_font, pos+Vector2(-10,-56),
				"⭐", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#FFD93D"))
		if mastered:
			draw_string(ThemeDB.fallback_font, pos+Vector2(10,-56),
				"★", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#FFD93D"))
		draw_string(ThemeDB.fallback_font, pos+Vector2(-42,58),
			ch["name"] as String, HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
			col if unlocked else Color("#333320"))
		if score > 0:
			draw_string(ThemeDB.fallback_font, pos+Vector2(-24,74),
				"%d pts" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#888840"))

# ══════════════════════════════════════════════════
# #REGION:UI — Hover / click
# ══════════════════════════════════════════════════
func _hover(cid: int, pos: Vector2) -> void:
	_hover_id = cid
	var ch: Dictionary = CHAPTERS[cid-1]
	var d:  Dictionary = _map_data.get(cid,{}) as Dictionary
	var unlocked: bool = d.get("unlocked", cid==1) as bool
	var complete: bool = d.get("complete", false)  as bool
	var mastered: bool = d.get("mastered", false)  as bool
	var status: String
	if not unlocked: status = "🔒 Complete Ch%d first" % (cid-1)
	elif mastered:   status = "★ Mastered! Click to replay"
	elif complete:   status = "✓ Complete — click to replay"
	else:            status = "Click to enter!"
	if is_instance_valid(_tooltip_bg):
		_tooltip_bg.visible = true
		_tooltip_bg.position = pos + Vector2(56,-20)
		_tooltip_lbl.text = "%s\n%s\nDSA: %s\n%s" % [
			ch["name"], ch["game"], ch["dsa"], status]
	queue_redraw()

func _unhover() -> void:
	_hover_id = -1
	if is_instance_valid(_tooltip_bg): _tooltip_bg.visible = false
	queue_redraw()

func _click(cid: int, unlocked: bool, pos: Vector2) -> void:
	if not unlocked:
		AudioManager.play_sfx("wrong")
		return
	AudioManager.play_sfx("click")
	_walk_avatar_to(pos, func(): GameRouter.start_chapter(cid))

func _walk_avatar_to(target: Vector2, after: Callable) -> void:
	if not is_instance_valid(_avatar):
		after.call()
		return
	var dir: int = 3 if target.x > _avatar.position.x else 1  # right or left
	_play_avatar_anim("walk", dir)
	var tw := create_tween()
	tw.tween_property(_avatar, "position", target, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func():
		_avatar_pos = target
		_play_avatar_anim("idle", 2)
		after.call())

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.set_position(pos)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	return l
