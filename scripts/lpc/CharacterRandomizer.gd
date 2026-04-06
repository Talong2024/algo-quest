extends Node
## CharacterRandomizer — generates random valid appearance data for NPCs.
##
## USAGE:
##   var appearance = CharacterRandomizer.randomize_character()
##   var sprite = CharacterSprite.new()
##   sprite.apply(appearance)

const BODY_TYPES   = ["female", "male", "teen"]
const SKIN_TONES   = ["light", "tanned", "tanned2", "dark", "dark2"]

const HAIR_STYLES_SINGLE = [
	"bangs","bangslong","bangsshort","bedhead","long","long_straight",
	"longhawk","loose","messy1","messy2","page","page2","parted",
	"pixie","plain","shorthawk","swoop","unkempt"
]
const HAIR_STYLES_MULTI = [
	"bangslong2","bunches","high_ponytail","long_tied","ponytail",
	"ponytail2","princess","shoulderl","shoulderr","single","wavy"
]
const HAIR_COLORS = [
	"ash","black","blonde","blue","carrot","chestnut","dark_brown",
	"dark_gray","ginger","gold","gray","green","light_brown","navy",
	"orange","pink","platinum","purple","raven","red","redhead",
	"rose","sandy","strawberry","violet","white"
]
const SHIRT_STYLES = [
	"sleeveless1","sleeveless2","sleeveless2_buttoned","sleeveless2_cardigan",
	"sleeveless2_polo","sleeveless2_scoop","sleeveless2_vneck"
]
const SHIRT_COLORS = [
	"black","blue","bluegray","brown","charcoal","forest","gray","green",
	"lavender","leather","maroon","navy","orange","pink","purple","red",
	"rose","sky","slate","tan","teal","walnut","white","yellow"
]
const LEG_TYPES = [
	"","pants/magenta","pants/red","pants/teal","pants/white",
	"skirt/robe","armor/golden","armor/metal"
]
const SHOE_TYPES = [
	"","boots/basic","boots/fold","boots/revised","boots/rimmed",
	"shoes/basic","shoes/ghillies","shoes/revised","shoes/sara",
	"sandals","slippers","accessory/plate_toe","accessory/plate_toe_thick"
]
const SHOE_COLORS_FULL = [
	"black","blue","bluegray","brass","bronze","brown","ceramic","charcoal",
	"copper","forest","gold","gray","green","iron","lavender","leather",
	"maroon","navy","orange","pink","purple","red","rose","silver",
	"sky","slate","steel","tan","teal","walnut","white","yellow"
]
const SHOE_COLORS_SMALL = [
	"black","blue","bluegray","brown","charcoal","forest","gray","green",
	"lavender","leather","maroon","navy","orange","pink","purple","red",
	"rose","sky","slate","tan","teal","walnut","white","yellow"
]
const SOCK_TYPES  = ["","ankle","high","tabi"]
const SOCK_COLORS = [
	"black","blue","bluegray","brown","charcoal","forest","gray","green",
	"lavender","leather","maroon","navy","orange","pink","purple","red",
	"rose","sky","slate","tan","teal","walnut","white","yellow"
]

func _pick(arr: Array) -> String:
	return str(arr[randi() % arr.size()])

func _pick_hair_style() -> String:
	var all_styles: Array = HAIR_STYLES_SINGLE + HAIR_STYLES_MULTI
	if randf() < 0.10:
		return ""
	return str(all_styles[randi() % all_styles.size()])

func _shoe_colors_for(shoe_type: String) -> Array:
	if shoe_type == "slippers":
		return SHOE_COLORS_SMALL
	return SHOE_COLORS_FULL

func randomize_character() -> Dictionary:
	var body_type:   String = _pick(BODY_TYPES)
	var skin_tone:   String = _pick(SKIN_TONES)
	var hair_style:  String = _pick_hair_style()
	var hair_color:  String = _pick(HAIR_COLORS) if hair_style != "" else ""
	var shirt_style: String = _pick(SHIRT_STYLES)
	var shirt_color: String = _pick(SHIRT_COLORS)
	var leg_type:    String = _pick(LEG_TYPES)
	var shoe_type:   String = _pick(SHOE_TYPES)
	var shoe_color:  String = _pick(_shoe_colors_for(shoe_type)) if shoe_type != "" else ""
	var can_have_socks: bool = shoe_type != "" and shoe_type != "sandals" and shoe_type != "slippers"
	var sock_type:   String = _pick(SOCK_TYPES) if can_have_socks else ""
	var sock_color:  String = _pick(SOCK_COLORS) if sock_type != "" else ""

	return {
		"body_type":   body_type,
		"skin_tone":   skin_tone,
		"hair_style":  hair_style,
		"hair_color":  hair_color,
		"shirt_style": shirt_style,
		"shirt_color": shirt_color,
		"leg_type":    leg_type,
		"shoe_type":   shoe_type,
		"shoe_color":  shoe_color,
		"sock_type":   sock_type,
		"sock_color":  sock_color,
	}

func randomize_character_data() -> void:
	var a: Dictionary = randomize_character()
	var cd := CharacterData
	cd.body_type         = a["body_type"]
	cd.skin_tone_index   = SKIN_TONES.find(a["skin_tone"])
	var all_styles: Array = [""] + HAIR_STYLES_SINGLE + HAIR_STYLES_MULTI
	cd.hair_style_index  = max(0, all_styles.find(a["hair_style"]))
	cd.hair_color_index  = max(0, HAIR_COLORS.find(a["hair_color"]))
	cd.shirt_style_index = SHIRT_STYLES.find(a["shirt_style"])
	cd.shirt_color_index = SHIRT_COLORS.find(a["shirt_color"])
	cd.leg_type_index    = max(0, LEG_TYPES.find(a["leg_type"]))
	cd.shoe_type_index   = max(0, SHOE_TYPES.find(a["shoe_type"]))
	cd.shoe_color_index  = max(0, _shoe_colors_for(a["shoe_type"]).find(a["shoe_color"]))
	cd.sock_type_index   = max(0, ([""] + ["ankle","high","tabi"]).find(a["sock_type"]))
	cd.sock_color_index  = max(0, SOCK_COLORS.find(a["sock_color"]))
	cd.character_changed.emit()
