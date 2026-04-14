extends Node2D
## Tutorial — RPG-style level intro using DialogueBox.
## Each level shows a character dialogue, then a brief mechanic demo,
## then reveals controls before letting the player start.

signal start_requested

const DIALOGUE_SCRIPTS = preload("res://scripts/shared/DialogueScripts.gd")

var level_data: Dictionary = {}

var _dlg: Node
var _demo_built: bool = false

func _ready() -> void:
	_build_scene_bg()
	_build_dialogue_box()
	_build_mechanic_preview()
	_build_controls_overlay()
	_build_start_btn()
	_start_intro()

# ── Background ────────────────────────────────────────────────────────────────

func _build_scene_bg() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04,0.05,0.13,0.96)
	bg.set_position(Vector2.ZERO); bg.set_size(Vector2(1280,720))
	add_child(bg)

	# Level header
	var header := ColorRect.new()
	header.color = Color(0.06,0.08,0.18,1.0)
	header.set_position(Vector2.ZERO); header.set_size(Vector2(1280,56))
	add_child(header)
	var accent := ColorRect.new()
	accent.color = Color("#4D96FF"); accent.set_position(Vector2(0,54)); accent.set_size(Vector2(1280,2))
	add_child(accent)

	var level: int = level_data.get("level",1) as int
	_lbl("KINGDOM GATE  •  CHAPTER 1  •  LEVEL %d" % level, Vector2(20,8), 11, Color("#4D96FF"))
	_lbl(level_data.get("title","") as String, Vector2(20,24), 20, Color("#e8e8f0"))
	_lbl("DSA: " + (level_data.get("dsainfo","") as String), Vector2(700,34), 12, Color("#556677"))

# ── Dialogue box ──────────────────────────────────────────────────────────────

func _build_dialogue_box() -> void:
	_dlg = load("res://scenes/shared/DialogueBox.tscn").instantiate()
	add_child(_dlg)

func _start_intro() -> void:
	var level: int = level_data.get("level",1) as int
	var script: Array = DIALOGUE_SCRIPTS.level_intro(level)
	if script.is_empty():
		_show_controls()
		return
	_dlg.show_dialogue(script, _show_controls)

# ── Mechanic preview diagram ──────────────────────────────────────────────────

func _build_mechanic_preview() -> void:
	# Small diagram panel showing the mechanic visually, top-center area
	var mechanic: String = level_data.get("mechanic","fifo") as String
	var panel := ColorRect.new()
	panel.color = Color(0.07,0.09,0.20,1.0)
	panel.set_position(Vector2(300,66)); panel.set_size(Vector2(680,260))
	panel.name = "MechanicPreview"
	panel.visible = false   # shown after dialogue
	add_child(panel)

	_lbl_in(panel, "HOW IT WORKS", Vector2(12,10), 11, Color("#4D96FF"))
	_build_diagram(mechanic, panel)

func _build_diagram(mechanic: String, parent: Control) -> void:
	match mechanic:
		"fifo":
			_lbl_in(parent,"← GATE",          Vector2(20,90),  13, Color("#FFD93D"))
			for i in 4:
				_box_in(parent, Vector2(140+i*130,70), ["1st","2nd","3rd","4th"][i],
					Color("#4D96FF") if i==0 else Color("#334466"), i==0)
			_lbl_in(parent,"Serve FRONT first →",Vector2(20,160), 11, Color("#6BCB77"))
			_lbl_in(parent,"New citizens JOIN at the back →",Vector2(400,200),11,Color("#aaaacc"))
		"overflow":
			_lbl_in(parent,"Queue has only 3 slots:", Vector2(20,70), 13, Color("#FF9900"))
			for i in 3:
				_box_in(parent,Vector2(100+i*140,100),["FULL","FULL","FULL"][i],Color("#FF4444"),false)
			_box_in(parent,Vector2(520,100),"BLOCKED",Color("#880000"),false)
			_lbl_in(parent,"↑ 4th citizen turned away — OVERFLOW!",Vector2(430,180),11,Color("#FF6B6B"))
			_lbl_in(parent,"Serve faster to prevent this →",Vector2(20,180),11,Color("#6BCB77"))
		"patience":
			_box_in(parent,Vector2(80,80),"Normal",Color("#4D96FF"),false)
			_box_in(parent,Vector2(220,80),"Elderly ⚠",Color("#C77DFF"),false)
			var bar_bg:=ColorRect.new(); bar_bg.color=Color("#1a1a2e"); bar_bg.set_position(Vector2(220,70)); bar_bg.set_size(Vector2(90,8)); parent.add_child(bar_bg)
			var bar:=ColorRect.new(); bar.color=Color("#FF3333"); bar.set_position(Vector2(220,70)); bar.set_size(Vector2(20,8)); parent.add_child(bar)
			_lbl_in(parent,"Almost gone!",Vector2(220,56),10,Color("#FF6B6B"))
			_lbl_in(parent,"Red bar = patience draining. Serve before it empties!",Vector2(30,190),12,Color("#C77DFF"))
		"priority":
			_lbl_in(parent,"Before (wrong):",Vector2(20,64),11,Color("#FF6B6B"))
			_box_in(parent,Vector2(80,90),"Normal\nP:3",Color("#4D96FF"),true)
			_box_in(parent,Vector2(200,90),"VIP ★\nP:1",Color("#FFD93D"),false)
			_lbl_in(parent,"↓ DRAG VIP up",Vector2(185,175),12,Color("#FFD93D"))
			_lbl_in(parent,"After (correct):",Vector2(20,185),11,Color("#6BCB77"))
			_box_in(parent,Vector2(80,205),"VIP ★\nP:1",Color("#FFD93D"),true)
			_box_in(parent,Vector2(200,205),"Normal\nP:3",Color("#4D96FF"),false)
		"deque":
			_lbl_in(parent,"[F] FRONT GATE ←",Vector2(20,110),13,Color("#6BCB77"))
			_box_in(parent,Vector2(200,90),"VIP\n→F",Color("#FFD93D"),true)
			_box_in(parent,Vector2(330,90),"Normal\nany",Color("#4D96FF"),false)
			_box_in(parent,Vector2(460,90),"Guard\n→B",Color("#FF6B6B"),false)
			_lbl_in(parent,"→ BACK GATE [B]",Vector2(560,110),13,Color("#FF9900"))
			_lbl_in(parent,"Route each citizen to the correct gate or lose a life!",Vector2(40,195),12,Color("#aaaacc"))

# ── Controls overlay (shown after dialogue, before start button) ──────────────

func _build_controls_overlay() -> void:
	var mechanic: String = level_data.get("mechanic","fifo") as String
	var panel := ColorRect.new()
	panel.color = Color(0.05,0.07,0.16,1.0)
	panel.set_position(Vector2(24,340)); panel.set_size(Vector2(560,170))
	panel.name = "ControlsPanel"
	panel.visible = false
	add_child(panel)

	_lbl_in(panel,"🎮  CONTROLS", Vector2(16,12), 13, Color("#FFD93D"))
	var controls := _get_controls(mechanic)
	for i in controls.size():
		var col: int = i / 3
		var row: int = i % 3
		_lbl_in(panel, controls[i], Vector2(16 + col*270, 38 + row*38), 13, Color("#aaccee"))

func _get_controls(mechanic: String) -> Array:
	match mechanic:
		"fifo","overflow","patience":
			return ["SPACE / E  →  Serve front citizen","Click citizen  →  Serve (if front)","[Q]  →  Toggle queue panel","Wrong pick  →  Lose a life","Overflow  →  Lose a life","Patience = 0  →  Lose a life"]
		"priority":
			return ["DRAG VIP  →  Reorder in queue","SPACE / E  →  Serve front (if sorted)","[Q]  →  Toggle queue panel","Wrong order  →  Gate jams","VIP = Priority 1  →  Goes first","Sort before serving!"]
		"deque":
			return ["F  →  Front gate (dequeue front)","B  →  Back gate (dequeue back)","Check citizen's gate label!","Wrong gate  →  Citizen angry","'→ FRONT'  →  Press F","'→ BACK'   →  Press B"]
		_: return []

func _build_start_btn() -> void:
	var btn := Button.new()
	btn.text = "Begin Level  →"
	btn.set_position(Vector2(490,650)); btn.set_size(Vector2(300,52))
	btn.add_theme_font_size_override("font_size",20)
	btn.add_theme_color_override("font_color",Color("#FFD93D"))
	btn.name = "StartBtn"
	btn.visible = false
	btn.pressed.connect(func(): emit_signal("start_requested"))
	add_child(btn)

func _show_controls() -> void:
	# After dialogue ends: show mechanic preview + controls + start button
	var preview: Control = get_node_or_null("MechanicPreview") as Control
	if preview: preview.visible = true
	var controls: Control = get_node_or_null("ControlsPanel") as Control
	if controls: controls.visible = true
	var btn: Button = get_node_or_null("StartBtn") as Button
	if btn: btn.visible = true
	_lbl("Ready? Click 'Begin Level' when you are.", Vector2(24,516), 14, Color("#556677"))

# ── Helpers ───────────────────────────────────────────────────────────────────

func _lbl(text:String, pos:Vector2, sz:int, col:Color) -> Label:
	var l:=Label.new(); l.text=text; l.set_position(pos)
	l.add_theme_font_size_override("font_size",sz)
	l.add_theme_color_override("font_color",col)
	add_child(l); return l

func _lbl_in(parent:Control, text:String, pos:Vector2, sz:int, col:Color) -> void:
	var l:=Label.new(); l.text=text; l.set_position(pos)
	l.add_theme_font_size_override("font_size",sz)
	l.add_theme_color_override("font_color",col)
	parent.add_child(l)

func _box_in(parent:Control, pos:Vector2, text:String, col:Color, is_front:bool) -> void:
	var bg:=ColorRect.new(); bg.color=col*Color(1,1,1,0.2)
	bg.set_position(pos); bg.set_size(Vector2(95,80)); parent.add_child(bg)
	var border:=ColorRect.new(); border.color=col
	border.set_position(pos); border.set_size(Vector2(95,3)); parent.add_child(border)
	var l:=Label.new(); l.text=text; l.set_position(pos+Vector2(6,30))
	l.add_theme_font_size_override("font_size",11)
	l.add_theme_color_override("font_color",Color("#e8e8f0")); parent.add_child(l)
	if is_front:
		var f:=Label.new(); f.text="◄ FRONT"; f.set_position(pos+Vector2(4,64))
		f.add_theme_font_size_override("font_size",9)
		f.add_theme_color_override("font_color",Color("#6BCB77")); parent.add_child(f)
