extends Node2D
## CharacterSprite — pure Sprite2D compositor. No AnimatedSprite2D anywhere.
## Creates all layer nodes itself in _ready() — ignores whatever is in the .tscn.
## Sprite2D.region_rect set simultaneously on all layers = zero drift possible.

const LAYER_ORDER: Array[String] = ["hair_bg","body","legs","socks","shoes","shirt","hair_fg"]
const DIRS:        Array[String] = ["up","left","down","right"]
const VALID_ANIMS: Array[String] = ["idle","walk","run","emote","hurt","sit","jump","climb"]
const ANIM_FPS:    Dictionary    = {"idle":4,"walk":8,"run":12,"emote":4,"hurt":6,"sit":3,"jump":8,"climb":8}
const ANIM_FRAMES: Dictionary    = {"idle":2,"walk":9,"run":9,"emote":3,"hurt":6,"sit":3,"jump":8,"climb":6}
const MULTI_HAIR:  Array[String] = [
	"bangslong2","bunches","high_ponytail","long_tied","ponytail",
	"ponytail2","princess","shoulderl","shoulderr","single","wavy"
]
const TILE: int = 64

var _appearance:    Dictionary = {}
var _anim:          String     = "idle"
var _dir:           int        = 2
var _master_frame:  int        = 0
var _master_timer:  float      = 0.0
var _layer_frames:  Dictionary = {}   # lname → {tex, cols, row}
var _sprites:       Dictionary = {}   # lname → Sprite2D (owned by us)

func _ready() -> void:
	# Remove ALL existing children and rebuild from scratch.
	# This ensures we always have Sprite2D nodes regardless of what the .tscn had.
	for ch in get_children():
		ch.free()
	_sprites.clear()
	for lname: String in LAYER_ORDER:
		var s := Sprite2D.new()
		s.name           = lname
		s.centered       = false
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.visible        = false
		add_child(s)
		_sprites[lname] = s
	if not _appearance.is_empty():
		_commit()

func _get_sprite(lname: String) -> Sprite2D:
	return _sprites.get(lname, null) as Sprite2D

# ── Public API ────────────────────────────────────────────────────────────────

func apply(appearance: Dictionary) -> void:
	_appearance = appearance
	if _sprites.size() > 0: _commit()

func play(anim_name: String) -> void:
	if _anim == anim_name: return
	_anim          = anim_name
	_master_frame  = 0
	_master_timer  = 0.0
	if _sprites.size() > 0 and not _appearance.is_empty(): _commit()

func set_direction(dir: int) -> void:
	if _dir == dir: return
	_dir = dir
	_fix_hair_z()
	if _sprites.size() > 0: _push_frame()

func get_appearance() -> Dictionary: return _appearance.duplicate()

# ── Master clock ──────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _sprites.is_empty() or _appearance.is_empty(): return
	var fps:    int = ANIM_FPS.get(_anim,    8) as int
	var nf:     int = ANIM_FRAMES.get(_anim, 1) as int
	_master_timer += delta
	if _master_timer >= 1.0 / float(fps):
		_master_timer -= 1.0 / float(fps)
		_master_frame  = (_master_frame + 1) % nf
		_push_frame()

func _push_frame() -> void:
	for lname: String in LAYER_ORDER:
		var s: Sprite2D = _get_sprite(lname)
		if not s or not s.visible: continue
		var d: Dictionary = _layer_frames.get(lname, {}) as Dictionary
		if d.is_empty(): continue
		var cols: int = d["cols"] as int
		var row:  int = d["row"]  as int
		var col:  int = _master_frame % cols
		s.region_rect = Rect2(col * TILE, row * TILE, TILE, TILE)

# ── Commit ────────────────────────────────────────────────────────────────────

func _commit() -> void:
	if _sprites.is_empty() or _appearance.is_empty(): return

	# Step 1: hide all
	for lname: String in LAYER_ORDER:
		var s: Sprite2D = _get_sprite(lname)
		if s: s.visible = false
	_layer_frames.clear()

	# Step 2: load ALL textures first
	var paths:  Dictionary = _build_png_paths()
	var loaded: Dictionary = {}
	for lname: String in LAYER_ORDER:
		var p: String = str(paths.get(lname, ""))
		if p.is_empty() or not ResourceLoader.exists(p): continue
		var tex: Texture2D = load(p) as Texture2D
		if tex: loaded[lname] = tex

	# Step 3: reset clock
	_master_frame = 0
	_master_timer = 0.0

	# Step 4: assign all simultaneously
	var nf:  int = ANIM_FRAMES.get(_anim, 1) as int
	var row: int = _dir  # row 0=up,1=left,2=down,3=right — same in every LPC sheet
	for lname: String in LAYER_ORDER:
		var s: Sprite2D = _get_sprite(lname)
		if not s: continue
		if not loaded.has(lname): s.visible = false; continue
		var tex: Texture2D = loaded[lname] as Texture2D
		s.texture        = tex
		s.region_enabled = true
		s.region_rect    = Rect2(0, row * TILE, TILE, TILE)
		s.visible        = true
		_layer_frames[lname] = {"cols": nf, "row": row}

	_fix_hair_z()

func _fix_hair_z() -> void:
	var fg: Sprite2D = _get_sprite("hair_fg")
	if fg: fg.z_index = -1 if _dir == 0 else 0

# ── PNG paths ─────────────────────────────────────────────────────────────────

func _build_png_paths() -> Dictionary:
	var a    := _appearance
	var anim := _anim if _anim in VALID_ANIMS else "idle"
	var raw  := str(a.get("body_type", "female"))
	if raw.begins_with("enemy_"):
		return {"body": "res://assets/lpc/body/enemy/%s/%s.png" % [raw.replace("enemy_",""), anim]}
	var gender := raw
	var body   := "female" if raw == "teen" else raw
	var fb     := "male"   if raw == "male" else "thin"
	var skin   := str(a.get("skin_tone",   "light"))
	var hs     := str(a.get("hair_style",  ""))
	var hc     := str(a.get("hair_color",  "black"))
	var ss     := str(a.get("shirt_style", "sleeveless1"))
	var sc     := str(a.get("shirt_color", "white"))
	var leg    := str(a.get("leg_type",    ""))
	var shoe   := str(a.get("shoe_type",   ""))
	var shc    := str(a.get("shoe_color",  "black"))
	var sock   := str(a.get("sock_type",   ""))
	var skc    := str(a.get("sock_color",  "black"))
	var out    := {}
	out["body"]  = "res://assets/lpc/body/%s/%s/%s.png"              % [body, skin, anim]
	out["shirt"] = "res://assets/lpc/%s/%s/%s/%s.png"                % [ss, gender, anim, sc]
	if not leg.is_empty():
		out["legs"]  = "res://assets/lpc/legs/%s/%s/%s.png"          % [leg, gender, anim]
	if not shoe.is_empty():
		out["shoes"] = "res://assets/lpc/feet/%s/%s/%s/%s.png"       % [shoe, fb, anim, shc]
	if not sock.is_empty():
		out["socks"] = "res://assets/lpc/feet/socks/%s/%s/%s/%s.png" % [sock, fb, anim, skc]
	if not hs.is_empty():
		if hs in MULTI_HAIR:
			out["hair_bg"] = "res://assets/lpc/hair/%s/adult/bg/%s/%s.png" % [hs, anim, hc]
			out["hair_fg"] = "res://assets/lpc/hair/%s/adult/fg/%s/%s.png" % [hs, anim, hc]
		else:
			out["hair_fg"] = "res://assets/lpc/hair/%s/adult/%s/%s.png"    % [hs, anim, hc]
	return out
