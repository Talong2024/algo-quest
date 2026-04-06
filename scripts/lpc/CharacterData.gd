extends Node

const ANIMATIONS: Dictionary = {
	"idle":        {"frames": 2,  "rows": 4, "fps": 4},
	"walk":        {"frames": 9,  "rows": 4, "fps": 8},
	"run":         {"frames": 9,  "rows": 4, "fps": 12},
	"slash":       {"frames": 6,  "rows": 4, "fps": 8},
	"spellcast":   {"frames": 7,  "rows": 4, "fps": 8},
	"thrust":      {"frames": 8,  "rows": 4, "fps": 8},
	"shoot":       {"frames": 13, "rows": 4, "fps": 8},
	"halfslash":   {"frames": 6,  "rows": 4, "fps": 8},
	"backslash":   {"frames": 13, "rows": 4, "fps": 8},
	"jump":        {"frames": 8,  "rows": 4, "fps": 8},
	"sit":         {"frames": 3,  "rows": 4, "fps": 4},
	"emote":       {"frames": 3,  "rows": 4, "fps": 4},
	"combat_idle": {"frames": 2,  "rows": 4, "fps": 4},
	"hurt":        {"frames": 6,  "rows": 4, "fps": 6},
	"climb":       {"frames": 6,  "rows": 4, "fps": 8},
}

const BODY_TYPES: Array     = ["female", "male", "teen"]
const DIRECTION_NAMES: Array = ["Up", "Left", "Down", "Right"]
const TILE_SIZE: int         = 64

const DISPLAY_ANIMATIONS: Array = [
	"idle","walk","run","combat_idle","slash","halfslash","backslash",
	"spellcast","thrust","shoot","jump","sit","emote","hurt","climb"
]

# ---- Shirts ----
const SHIRT_STYLES: Array = [
	"sleeveless1","sleeveless2","sleeveless2_buttoned",
	"sleeveless2_cardigan","sleeveless2_polo",
	"sleeveless2_scoop","sleeveless2_vneck"
]
const SHIRT_LABELS: Array = [
	"Basic","Collared","Buttoned","Cardigan","Polo","Scoop Neck","V-Neck"
]
const SHIRT_COLORS: Array = [
	"black","blue","bluegray","brown","charcoal","forest","gray",
	"green","lavender","leather","maroon","navy","orange","pink",
	"purple","red","rose","sky","slate","tan","teal","walnut","white","yellow"
]

# ---- Skin tones (from Universal LPC Spritesheet) ----
const SKIN_TONES: Array  = ["light","tanned","tanned2","dark","dark2"]
const SKIN_LABELS: Array = ["Light","Tanned","Tanned 2","Dark","Dark 2"]

# ---- Hair ----
const HAIR_STYLES_SINGLE: Array = [
	"bangs","bangslong","bangsshort","bedhead","long","long_straight",
	"longhawk","loose","messy1","messy2","page","page2","parted",
	"pixie","plain","shorthawk","swoop","unkempt"
]
const HAIR_STYLES_MULTI: Array = [
	"bangslong2","bunches","high_ponytail","long_tied","ponytail",
	"ponytail2","princess","shoulderl","shoulderr","single","wavy"
]
const HAIR_LABELS_SINGLE: Array = [
	"Bangs","Bangs Long","Bangs Short","Bedhead","Long","Long Straight",
	"Long Hawk","Loose","Messy 1","Messy 2","Page","Page 2","Parted",
	"Pixie","Plain","Short Hawk","Swoop","Unkempt"
]
const HAIR_LABELS_MULTI: Array = [
	"Bangs Long 2","Bunches","High Ponytail","Long Tied","Ponytail",
	"Ponytail 2","Princess","Shoulder L","Shoulder R","Single","Wavy"
]
const HAIR_COLORS: Array = [
	"ash","black","blonde","blue","carrot","chestnut","dark_brown",
	"dark_gray","ginger","gold","gray","green","light_brown","navy",
	"orange","pink","platinum","purple","raven","red","redhead",
	"rose","sandy","strawberry","violet","white"
]

func get_all_hair_styles() -> Array:
	var out: Array = ["none"]
	out.append_array(HAIR_STYLES_SINGLE)
	out.append_array(HAIR_STYLES_MULTI)
	return out

func get_all_hair_labels() -> Array:
	var out: Array = ["None"]
	out.append_array(HAIR_LABELS_SINGLE)
	out.append_array(HAIR_LABELS_MULTI)
	return out

func is_hair_multi(style: String) -> bool:
	return HAIR_STYLES_MULTI.has(style)

# ---- Footwear ----
const SHOE_TYPES: Array = [
	"none",
	"boots/basic","boots/fold","boots/revised","boots/rimmed",
	"shoes/basic","shoes/ghillies","shoes/revised","shoes/sara",
	"sandals","slippers",
	"accessory/plate_toe","accessory/plate_toe_thick"
]
const SHOE_LABELS: Array = [
	"None",
	"Basic Boots","Fold Boots","Revised Boots","Rimmed Boots",
	"Basic Shoes","Ghillie Shoes","Revised Shoes","Sara Shoes",
	"Sandals","Slippers","Plate Toe Cap","Plate Toe (Thick)"
]
const SHOE_COLORS: Array = [
	"black","blue","bluegray","brass","bronze","brown","ceramic","charcoal",
	"copper","forest","gold","gray","green","iron","lavender","leather",
	"maroon","navy","orange","pink","purple","red","rose","silver",
	"sky","slate","steel","tan","teal","walnut","white","yellow"
]
const SLIPPER_COLORS: Array = [
	"black","blue","bluegray","brown","charcoal","forest","gray",
	"green","lavender","leather","maroon","navy","orange","pink",
	"purple","red","rose","sky","slate","tan","teal","walnut","white","yellow"
]
const SOCK_TYPES: Array  = ["none","socks/ankle","socks/high","socks/tabi"]
const SOCK_LABELS: Array = ["None","Ankle Socks","High Socks","Tabi Socks"]
const SOCK_COLORS: Array = [
	"black","blue","bluegray","brown","charcoal","forest","gray",
	"green","lavender","leather","maroon","navy","orange","pink",
	"purple","red","rose","sky","slate","tan","teal","walnut","white","yellow"
]

# ---- Runtime state ----
var body_type: String       = "female"
var skin_tone_index: int    = 0
var shirt_style_index: int  = 0
var shirt_color_index: int  = 22   # white
var hair_style_index: int   = 0
var hair_color_index: int   = 1    # black
var shoe_type_index: int    = 0
var shoe_color_index: int   = 14   # leather
var sock_type_index: int    = 0
var sock_color_index: int   = 0
var current_animation: String = "idle"
var direction: int          = 2    # down

signal character_changed

func get_feet_body(body: String) -> String:
	return "male" if body == "male" else "thin"

func get_shoe_colors() -> Array:
	if shoe_type_index < SHOE_TYPES.size():
		if SHOE_TYPES[shoe_type_index] == "slippers":
			return SLIPPER_COLORS
	return SHOE_COLORS

func get_hair_style() -> String:
	var all_styles: Array = get_all_hair_styles()
	if hair_style_index <= 0 or hair_style_index >= all_styles.size():
		return "none"
	return all_styles[hair_style_index]

# ---- Legs ----
const LEG_TYPES: Array  = ["none", "pants/magenta", "pants/red", "pants/teal", "pants/white", "skirt/robe", "armor/golden", "armor/metal"]
const LEG_LABELS: Array = ["None", "Pants (Magenta)", "Pants (Red)", "Pants (Teal)", "Pants (White)", "Robe Skirt", "Golden Greaves", "Metal Pants"]

var leg_type_index: int = 4   # default: white pants
