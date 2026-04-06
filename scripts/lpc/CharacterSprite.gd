extends Node2D
## CharacterSprite — LPC layered sprite compositor.
##
## KEY DESIGN: ONE shared frame counter drives ALL layers simultaneously.
## This guarantees perfect sync — body, hair, shirt, legs, shoes all
## advance on the exact same tick. No per-layer drift possible.
##
## Safe to call apply() before add_child(); _ready_done flag defers load.

const LAYER_ORDER: Array[String] = ["hair_bg","body","legs","socks","shoes","shirt","hair_fg"]

const ANIMATIONS: Dictionary = {
	"idle":        {"frames":2,  "rows":4,"fps":4},
	"walk":        {"frames":9,  "rows":4,"fps":8},
	"run":         {"frames":9,  "rows":4,"fps":12},
	"slash":       {"frames":6,  "rows":4,"fps":8},
	"spellcast":   {"frames":7,  "rows":4,"fps":8},
	"thrust":      {"frames":8,  "rows":4,"fps":8},
	"shoot":       {"frames":13, "rows":4,"fps":8},
	"halfslash":   {"frames":6,  "rows":4,"fps":8},
	"backslash":   {"frames":13, "rows":4,"fps":8},
	"jump":        {"frames":8,  "rows":4,"fps":8},
	"sit":         {"frames":3,  "rows":4,"fps":4},
	"emote":       {"frames":3,  "rows":4,"fps":4},
	"combat_idle": {"frames":2,  "rows":4,"fps":4},
	"hurt":        {"frames":6,  "rows":4,"fps":6},
	"climb":       {"frames":6,  "rows":4,"fps":8},
}

const TILE: int = 64
const MULTI_HAIR: Array[String] = [
	"bangslong2","bunches","high_ponytail","long_tied","ponytail",
	"ponytail2","princess","shoulderl","shoulderr","single","wavy"
]

var _layers: Dictionary = {}       # lname -> Sprite2D
var _appearance: Dictionary = {}
var _anim: String  = "idle"
var _dir:  int     = 2             # 0=up 1=left 2=down 3=right

# Shared animation clock — ONE counter for all layers
var _frame:    int   = 0
var _timer:    float = 0.0

var _ready_done: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	for lname: String in LAYER_ORDER:
		var s := Sprite2D.new()
		s.name   = lname
		s.centered = false
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.visible = false
		add_child(s)
		_layers[lname] = s
	_ready_done = true
	if not _appearance.is_empty():
		_load_all()

# ── Public API ────────────────────────────────────────────────────────────────

func apply(appearance: Dictionary) -> void:
	_appearance = appearance
	if _ready_done:
		_load_all()

func play(anim_name: String) -> void:
	if _anim == anim_name:
		return
	_anim  = anim_name
	_frame = 0
	_timer = 0.0
	if _ready_done:
		_load_all()

func set_direction(dir: int) -> void:
	_dir = dir
	if _ready_done:
		_update_all_regions()

func get_appearance() -> Dictionary:
	return _appearance.duplicate()

# ── Animation clock ──────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _ready_done:
		return
	var anim_data: Dictionary = ANIMATIONS.get(_anim, {})
	if anim_data.is_empty():
		return

	var fps:         float = float(anim_data.get("fps", 8))
	var frame_count: int   = int(anim_data.get("frames", 1))
	var interval:    float = 1.0 / fps

	_timer += delta
	if _timer >= interval:
		_timer -= interval
		_frame = (_frame + 1) % frame_count
		# All layers advance to the SAME frame simultaneously
		_update_all_regions()

# ── Layer loading ─────────────────────────────────────────────────────────────

func _load_all() -> void:
	if _appearance.is_empty() or not _ready_done:
		return
	_frame = 0
	_timer = 0.0
	_load_body()
	_load_legs()
	_load_socks()
	_load_shoes()
	_load_shirt()
	_load_hair()

func _load_body() -> void:
	var raw:  String = str(_appearance.get("body_type", "female"))
	var body: String = "female" if raw == "teen" else raw
	var skin: String = str(_appearance.get("skin_tone", "light"))
	_set_layer("body", "res://assets/lpc/body/%s/%s/%s.png" % [body, skin, _anim])

func _load_legs() -> void:
	var leg: String = str(_appearance.get("leg_type", ""))
	if leg.is_empty():
		_layers["legs"].visible = false
		return
	var gender: String = str(_appearance.get("body_type", "female"))
	_set_layer("legs", "res://assets/lpc/legs/%s/%s/%s.png" % [leg, gender, _anim])

func _load_shirt() -> void:
	var style:  String = str(_appearance.get("shirt_style", "sleeveless1"))
	var gender: String = str(_appearance.get("body_type",   "female"))
	var color:  String = str(_appearance.get("shirt_color", "white"))
	_set_layer("shirt", "res://assets/lpc/%s/%s/%s/%s.png" % [style, gender, _anim, color])

func _load_hair() -> void:
	var style: String = str(_appearance.get("hair_style", ""))
	if style.is_empty():
		_layers["hair_bg"].visible = false
		_layers["hair_fg"].visible = false
		return
	var color: String = str(_appearance.get("hair_color", "black"))
	if style in MULTI_HAIR:
		_set_layer("hair_bg", "res://assets/lpc/hair/%s/adult/bg/%s/%s.png" % [style, _anim, color])
		_set_layer("hair_fg", "res://assets/lpc/hair/%s/adult/fg/%s/%s.png" % [style, _anim, color])
	else:
		_layers["hair_bg"].visible = false
		_set_layer("hair_fg", "res://assets/lpc/hair/%s/adult/%s/%s.png" % [style, _anim, color])

func _load_socks() -> void:
	var sock: String = str(_appearance.get("sock_type", ""))
	if sock.is_empty():
		_layers["socks"].visible = false
		return
	var raw:   String = str(_appearance.get("body_type", "female"))
	var fb:    String = "male" if raw == "male" else "thin"
	var color: String = str(_appearance.get("sock_color", "black"))
	_set_layer("socks", "res://assets/lpc/feet/socks/%s/%s/%s/%s.png" % [sock, fb, _anim, color])

func _load_shoes() -> void:
	var shoe: String = str(_appearance.get("shoe_type", ""))
	if shoe.is_empty():
		_layers["shoes"].visible = false
		return
	var raw:   String = str(_appearance.get("body_type", "female"))
	var fb:    String = "male" if raw == "male" else "thin"
	var color: String = str(_appearance.get("shoe_color", "black"))
	_set_layer("shoes", "res://assets/lpc/feet/%s/%s/%s/%s.png" % [shoe, fb, _anim, color])

# ── Core helpers ──────────────────────────────────────────────────────────────

func _set_layer(lname: String, path: String) -> void:
	var s: Sprite2D = _layers[lname]
	if not ResourceLoader.exists(path):
		s.visible = false
		return
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		s.visible = false
		return
	s.texture = tex
	s.visible = true
	# Don't reset _frame here — shared clock stays intact across layer loads
	_update_region(lname)

func _update_region(lname: String) -> void:
	var s: Sprite2D = _layers[lname]
	if not s.visible or s.texture == null:
		return
	var anim_data: Dictionary = ANIMATIONS.get(_anim, {})
	if anim_data.is_empty():
		return
	var rows: int = int(anim_data.get("rows", 4))
	var row:  int = _dir if rows == 4 else 0
	s.region_enabled = true
	s.region_rect    = Rect2(_frame * TILE, row * TILE, TILE, TILE)

func _update_all_regions() -> void:
	for lname: String in LAYER_ORDER:
		_update_region(lname)
