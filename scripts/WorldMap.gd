extends Node2D
# ═══════════════════════════════════════════════════
# WorldMap.gd — the AlgoQuest kingdom map hub.
# Shows all 5 chapter regions with live progress.
# ═══════════════════════════════════════════════════

const CHAPTERS: Array = [
	{ "id":1, "name":"Kingdom Gate",    "game":"Kingdom Queue",   "dsa":"Queue — FIFO",
	"pos":Vector2(300,380), "color":Color("#6BCB77"), "icon":"🏰" },
	{ "id":2, "name":"Castle of Echoes","game":"Castle of Echoes","dsa":"Stack — LIFO",
	"pos":Vector2(500,230), "color":Color("#C77DFF"), "icon":"🗼" },
	{ "id":3, "name":"Chain Station",   "game":"Chain Train",     "dsa":"Linked List",
	"pos":Vector2(700,370), "color":Color("#FFD93D"), "icon":"🚂" },
	{ "id":4, "name":"Oracle's Forest", "game":"Oracle's Forest", "dsa":"BST/AVL/Heap",
	"pos":Vector2(880,220), "color":Color("#6BCB77"), "icon":"🌲" },
	{ "id":5, "name":"Kingdom Roads",   "game":"Kingdom Roads",   "dsa":"Graph Algorithms",
	"pos":Vector2(1040,390), "color":Color("#4D96FF"), "icon":"🗺" },
]

const ROADS: Array = [[1,2],[1,3],[2,3],[2,4],[3,5],[4,5]]

var _map_data:  Dictionary = {}
var _hover_id:  int        = -1

func _ready() -> void:
	ProgressTracker.update_login_streak()
	_map_data = ProgressTracker.get_world_map_snapshot()
	_build_hud()
	_build_region_areas()
	_build_tooltip()
	queue_redraw()

func _build_hud() -> void:
	var hud := ColorRect.new()
	hud.color = Color(0,0,0,0.75)
	hud.set_position(Vector2.ZERO)
	hud.set_size(Vector2(1280, 58))
	add_child(hud)

	_lbl("ALGOQUEST", Vector2(20,8), 10, Color("#4D96FF"))
	_lbl("Kingdom Map", Vector2(20,26), 20, Color("#e8e8d0"))
	_lbl("%s  [%s]" % [ProgressTracker.get_player_name(), SaveManager.get_setting("character_name","Code Keeper") as String],
		Vector2(820,10), 13, Color("#888860"))
	var stats: Dictionary = ProgressTracker.get_all_stats()
	_lbl("Score: %d  |  Perfects: %d  |  Streak: %d days" % [
		stats.get("total_score",0) as int,
		stats.get("perfect_clears",0) as int,
		stats.get("login_streak",0) as int,
	], Vector2(820,30), 12, Color("#FFD93D"))

	_hud_btn("Character",   Vector2(790,62), func(): GameRouter.go_char_select())
	_hud_btn("Progress",    Vector2(900,62), func(): GameRouter.go_progress_screen())
	_hud_btn("Settings",    Vector2(1010,62), func(): GameRouter.go_settings())
	_hud_btn("Leaderboard", Vector2(1120,62), func(): GameRouter.go_leaderboard())

	# Mastery summary row
	var topics: Array = ["queue","stack","linked_list","tree","graph"]
	var colors: Array = [Color("#6BCB77"),Color("#C77DFF"),Color("#FFD93D"),
		Color("#6BCB77"),Color("#4D96FF")]
	for i in topics.size():
		var m: bool = ProgressTracker.get_dsa_mastery(topics[i]).get("mastered",false) as bool
		var dot := ColorRect.new()
		dot.color = colors[i] if m else Color("#1a1a2a")
		dot.set_position(Vector2(200 + i*24, 68))
		dot.set_size(Vector2(18, 10))
		add_child(dot)

func _hud_btn(text: String, pos: Vector2, cb: Callable) -> void:
	var b := Button.new()
	b.text = text; b.set_position(pos); b.set_size(Vector2(100, 28))
	b.add_theme_font_size_override("font_size", 11)
	b.pressed.connect(cb); add_child(b)

func _build_region_areas() -> void:
	for ch in CHAPTERS:
		var cid:      int     = ch["id"] as int
		var pos:      Vector2 = ch["pos"] as Vector2
		var unlocked: bool    = (_map_data.get(cid,{}) as Dictionary).get("unlocked",cid==1) as bool

		var area  := Area2D.new()
		var shape := CollisionShape2D.new()
		var circ  := CircleShape2D.new()
		circ.radius = 54.0
		shape.shape = circ
		area.position = pos
		area.add_child(shape)
		area.input_event.connect(func(_vp,event,_idx):
			if event is InputEventMouseButton:
				var mb := event as InputEventMouseButton
				if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
					_click(cid, unlocked)
		)
		area.mouse_entered.connect(func(): _hover(cid))
		area.mouse_exited.connect(func(): _unhover())
		add_child(area)

func _build_tooltip() -> void:
	var tbg := ColorRect.new()
	tbg.name = "TooltipBG"
	tbg.color = Color("#13131f")
	tbg.set_size(Vector2(240, 100))
	tbg.visible = false
	add_child(tbg)

	var tlbl := Label.new()
	tlbl.name = "TooltipLbl"
	tlbl.set_position(Vector2(12, 8))
	tlbl.set_size(Vector2(220, 88))
	tlbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tlbl.add_theme_font_size_override("font_size", 12)
	tlbl.add_theme_color_override("font_color", Color("#e8e8d0"))
	tbg.add_child(tlbl)

# #REGION:MAP_TILES — Draws the world map nodes and connections
func _draw() -> void:
	# Roads
	for conn in ROADS:
		var a: int = conn[0] - 1
		var b: int = conn[1] - 1
		var pa: Vector2 = CHAPTERS[a]["pos"] as Vector2
		var pb: Vector2 = CHAPTERS[b]["pos"] as Vector2
		var complete_a: bool = (_map_data.get(a+1,{}) as Dictionary).get("complete",false) as bool
		draw_line(pa, pb, Color("#3a3010"), 6.0)
		draw_line(pa, pb, Color("#5a5020") if complete_a else Color("#2a2010"), 3.0)

	# Regions
	for ch in CHAPTERS:
		var cid:      int     = ch["id"] as int
		var pos:      Vector2 = ch["pos"] as Vector2
		var col:      Color   = ch["color"] as Color
		var d:        Dictionary = _map_data.get(cid, {}) as Dictionary
		var unlocked: bool    = (d.get("unlocked", cid == 1)) as bool
		var complete: bool    = d.get("complete", false) as bool
		var mastered: bool    = d.get("mastered", false) as bool
		var hover:    bool    = (_hover_id == cid)
		var score:    int     = d.get("best_score", 0) as int

		# Clearing
		draw_circle(pos, 64, Color("#1a1a08",0.8))

		# Glow
		if unlocked:
			var g: Color = Color("#FFD93D") if mastered else col
			draw_circle(pos, 60, g * Color(1,1,1, 0.12 + (0.1 if hover else 0.0)))

		# Body
		draw_circle(pos + Vector2(3,3), 46, Color(0,0,0,0.5))
		draw_circle(pos, 46, col.darkened(0.5) if unlocked else Color("#1a1a10"))

		# Border
		var border: Color = Color("#FFD93D") if mastered else \
			(col.lightened(0.3) if hover else (col if unlocked else Color("#2a2a10")))
		draw_arc(pos, 46, 0, TAU, 32, border, 2.5)

		# Icon
		draw_string(ThemeDB.fallback_font, pos+Vector2(-12,8),
			ch["icon"] as String, HORIZONTAL_ALIGNMENT_LEFT, -1, 22,
			col if unlocked else Color("#333320"))

		# Lock
		if not unlocked:
			draw_string(ThemeDB.fallback_font, pos+Vector2(-10,22),
				"🔒", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#555530"))

		# Stars: one per perfect clear
		if complete:
			draw_string(ThemeDB.fallback_font, pos+Vector2(-10,-56),
				"⭐", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#FFD93D"))
		if mastered:
			draw_string(ThemeDB.fallback_font, pos+Vector2(10,-56),
				"★", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#FFD93D"))

		# Name + score
		draw_string(ThemeDB.fallback_font, pos+Vector2(-42,58),
			ch["name"] as String, HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
			col if unlocked else Color("#333320"))
		if score > 0:
			draw_string(ThemeDB.fallback_font, pos+Vector2(-24,74),
				"%d pts" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#888840"))

func _hover(cid: int) -> void:
	_hover_id = cid
	var ch: Dictionary = CHAPTERS[cid-1]
	var d:  Dictionary = _map_data.get(cid,{}) as Dictionary
	var unlocked: bool = (d.get("unlocked", cid == 1)) as bool
	var complete: bool = d.get("complete",false) as bool
	var mastered: bool = d.get("mastered",false) as bool
	var pos: Vector2   = (ch["pos"] as Vector2) + Vector2(56,-20)

	var tbg: ColorRect = get_node("TooltipBG") as ColorRect
	tbg.set_position(pos); tbg.visible = true

	var status: String
	if not unlocked: status = "🔒 Complete Ch%d first" % (cid-1)
	elif mastered:   status = "★ Mastered! Click to replay"
	elif complete:   status = "✓ Complete — click to replay"
	else:            status = "Click to enter!"

	(tbg.get_node("TooltipLbl") as Label).text = "%s\n%s\nDSA: %s\n%s" % [
		ch["name"], ch["game"], ch["dsa"], status]
	queue_redraw()

func _unhover() -> void:
	_hover_id = -1
	(get_node("TooltipBG") as ColorRect).visible = false
	queue_redraw()

func _click(cid: int, unlocked: bool) -> void:
	if not unlocked:
		AudioManager.play_sfx("wrong")
		return
	AudioManager.play_sfx("click")
	GameRouter.start_chapter(cid)

func _lbl(text: String, pos: Vector2, sz: int, col: Color) -> Label:
	var l := Label.new(); l.text=text; l.set_position(pos)
	l.add_theme_font_size_override("font_size",sz)
	l.add_theme_color_override("font_color",col); add_child(l); return l
