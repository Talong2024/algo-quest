extends Node2D
## CharacterSprite — LPC layered sprite compositor.
## SYNC STRATEGY: One master timer drives all layers.
## Every _process tick, all visible layers are set to match the master frame.
## This makes drift physically impossible.

const LAYER_ORDER: Array[String] = ["hair_bg","body","legs","socks","shoes","shirt","hair_fg"]
const DIRS: Array[String]        = ["up","left","down","right"]
const VALID_ANIMS: Array[String] = ["idle","walk","run","emote","hurt","sit","jump","climb"]
const ANIM_FPS: Dictionary = {
	"idle": 4, "walk": 8, "run": 12, "emote": 4,
	"hurt": 6, "sit":  4, "jump": 8, "climb":  8,
}
const ANIM_FRAMES: Dictionary = {
	"idle": 2, "walk": 9, "run": 9, "emote": 3,
	"hurt": 6, "sit":  3, "jump": 8, "climb":  6,
}
const MULTI_HAIR: Array[String] = [
	"bangslong2","bunches","high_ponytail","long_tied","ponytail",
	"ponytail2","princess","shoulderl","shoulderr","single","wavy"
]

var _appearance: Dictionary = {}
var _anim:       String     = "idle"
var _dir:        int        = 2
var _ready_done: bool       = false

# Master clock — single source of truth for all layers
var _master_frame: int   = 0
var _master_timer: float = 0.0

func _ready() -> void:
	for lname: String in LAYER_ORDER:
		if not has_node(lname):
			var s := AnimatedSprite2D.new()
			s.name           = lname
			s.centered       = false
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.visible        = false
			s.pause()          # we drive frames manually
			add_child(s)
	_ready_done = true
	if not _appearance.is_empty():
		_load_all_layers()

func _get_layer(lname: String) -> AnimatedSprite2D:
	return get_node_or_null(lname) as AnimatedSprite2D

# ── Public API ────────────────────────────────────────────────────────────────

func apply(appearance: Dictionary) -> void:
	_appearance = appearance
	if _ready_done:
		_load_all_layers()

func play(anim_name: String) -> void:
	if _anim == anim_name:
		return
	_anim         = anim_name
	_master_frame = 0
	_master_timer = 0.0
	if _ready_done and not _appearance.is_empty():
		_load_all_layers()

func set_direction(dir: int) -> void:
	if _dir == dir:
		return
	_dir = dir
	_fix_hair_z()
	if _ready_done:
		_apply_frame_to_all()

func get_appearance() -> Dictionary:
	return _appearance.duplicate()

# ── Master clock ──────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _ready_done or _appearance.is_empty():
		return
	var fps:    int = ANIM_FPS.get(_anim, 8)  as int
	var frames: int = ANIM_FRAMES.get(_anim, 1) as int
	_master_timer += delta
	if _master_timer >= 1.0 / float(fps):
		_master_timer -= 1.0 / float(fps)
		_master_frame  = (_master_frame + 1) % frames
		_apply_frame_to_all()

## Push the master frame to every visible layer simultaneously.
func _apply_frame_to_all() -> void:
	var dir_name: String = DIRS[_dir]
	for lname: String in LAYER_ORDER:
		var node: AnimatedSprite2D = _get_layer(lname)
		if not node or not node.visible or not node.sprite_frames:
			continue
		if node.sprite_frames.has_animation(dir_name):
			# Make sure the correct animation is playing (direction may have changed)
			if node.animation != dir_name:
				node.play(dir_name)
				node.pause()
			node.frame = _master_frame

# ── Layer loading ─────────────────────────────────────────────────────────────

func _load_all_layers() -> void:
	if not _ready_done or _appearance.is_empty():
		return
	_master_frame = 0
	_master_timer = 0.0
	var paths: Dictionary = _build_paths()
	for lname: String in LAYER_ORDER:
		var node: AnimatedSprite2D = _get_layer(lname)
		if not node:
			continue
		var path: String = str(paths.get(lname, ""))
		if path.is_empty() or not ResourceLoader.exists(path):
			node.visible = false
			continue
		var sf: SpriteFrames = load(path) as SpriteFrames
		if not sf:
			node.visible = false
			continue
		node.sprite_frames = sf
		node.visible       = true
		# Start paused at frame 0 — _process drives it
		var dir_name: String = DIRS[_dir]
		if sf.has_animation(dir_name):
			node.play(dir_name)
			node.pause()
			node.frame = 0
	_fix_hair_z()

func _fix_hair_z() -> void:
	var fg: AnimatedSprite2D = _get_layer("hair_fg")
	if fg:
		# When facing UP we see the back of the head — front hair goes behind body
		fg.z_index = -1 if _dir == 0 else 0

func _build_paths() -> Dictionary:
	var a      := _appearance
	var anim   := _anim if _anim in VALID_ANIMS else "idle"
	var raw    := str(a.get("body_type",  "female"))
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
	out["body"]  = "res://assets/lpc/body/%s/%s/%s.tres"              % [body, skin, anim]
	out["shirt"] = "res://assets/lpc/%s/%s/%s/%s.tres"                % [ss, gender, anim, sc]
	if not leg.is_empty():
		out["legs"]  = "res://assets/lpc/legs/%s/%s/%s.tres"          % [leg, gender, anim]
	if not shoe.is_empty():
		out["shoes"] = "res://assets/lpc/feet/%s/%s/%s/%s.tres"       % [shoe, fb, anim, shc]
	if not sock.is_empty():
		out["socks"] = "res://assets/lpc/feet/socks/%s/%s/%s/%s.tres" % [sock, fb, anim, skc]
	if not hs.is_empty():
		if hs in MULTI_HAIR:
			out["hair_bg"] = "res://assets/lpc/hair/%s/adult/bg/%s/%s.tres" % [hs, anim, hc]
			out["hair_fg"] = "res://assets/lpc/hair/%s/adult/fg/%s/%s.tres" % [hs, anim, hc]
		else:
			out["hair_fg"] = "res://assets/lpc/hair/%s/adult/%s/%s.tres"    % [hs, anim, hc]
	return out
