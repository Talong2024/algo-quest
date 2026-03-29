extends Node
# ═══════════════════════════════════════════════════
# AssetMap.gd  —  AUTOLOAD SINGLETON
# Central registry for all asset paths.
# ═══════════════════════════════════════════════════

# ─── Map tiles ───────────────────────────────────
const MAP_TILES: Dictionary = {
	"street":   "res://assets/codemon/art/map/street_tile.png",
	"mountain": "res://assets/codemon/art/map/mountain.png",
	"desert":   "res://assets/codemon/art/map/desert.png",
	"forest":   "res://assets/codemon/art/map/forest.png",
	"beach":    "res://assets/codemon/art/map/beach.png",
	"boss":     "res://assets/codemon/art/map/boss.png",
}

# ─── Parallax ────────────────────────────────────
const PARALLAX: Dictionary = {
	"mountain": "res://assets/codemon/art/parallax/mountain.png",
	"desert":   "res://assets/codemon/art/parallax/desert.png",
}

# ─── Objects ─────────────────────────────────────
const OBJECTS: Dictionary = {
	"tree_01":     "res://assets/codemon/art/object/tree_normal.png",
	"tree_normal": "res://assets/codemon/art/object/tree_normal.png",
	"tree_round":  "res://assets/codemon/art/object/tree_round.png",
	"mushroom":    "res://assets/codemon/art/object/mushroom.png",
	"forest_rock": "res://assets/codemon/art/object/forest/rock.png",
	"cactus":      "res://assets/codemon/art/object/desert/cactus.png",
	"skull":       "res://assets/codemon/art/object/desert/skull.png",
	"boat":        "res://assets/codemon/art/object/beach/boat.png",
	"beach_tree":  "res://assets/codemon/art/object/beach/tree.png",
	"water":       "res://assets/codemon/art/object/beach/water.png",
	"fish_1":      "res://assets/codemon/art/object/beach/fish_1.png",
	"rock":        "res://assets/codemon/art/object/mountain/rock.png",
	"bridge_back": "res://assets/codemon/art/object/laboratory/bridge_back.png",
	"bush_1":      "res://assets/codemon/art/object/bush_01.png",
}

# ─── Logo ────────────────────────────────────────
const LOGO_D:       String = "res://assets/codemon/art/logo/D.png"
const LOGO_K:       String = "res://assets/codemon/art/logo/K.png"
const LOGO_BRACKET: String = "res://assets/codemon/art/logo/bracket.png"
const LOGO_CODEMON: String = "res://assets/codemon/art/logo/codemon.png"

# ─── Player/NPC ──────────────────────────────────
const JIMMY:        String = "res://assets/codemon/art/character/jimmy.png"
const WORLD_MAP:    String = "res://assets/codemon/art/map/map.png"
const PLAYER:       String = "res://assets/codemon/art/character/jimmy.png"

# ─── Video ───────────────────────────────────────
const MENU_BG_VIDEO: String = "res://assets/video/main_menu_bg.mp4"

# ─── Buttons (codemon style) ─────────────────────
const BTN_NORMAL:   String = "res://assets/codemon/art/component/btn_normal.png"
const BTN_PRESSED:  String = "res://assets/codemon/art/component/btn_clicked.png"
const BTN_HOVER:    String = "res://assets/codemon/art/component/btn_selected.png"
const BTN_DISABLED: String = "res://assets/codemon/art/component/btn_disabled.png"
const BTN_M_NORMAL: String = "res://assets/codemon/art/component/btn_m_normal.png"
const BTN_M_PRESSED:String = "res://assets/codemon/art/component/btn_m_clicked.png"
const BTN_M_HOVER:  String = "res://assets/codemon/art/component/btn_m_selected.png"

# ─── LPC Character assets ────────────────────────
const LPC_BODIES: Dictionary = {
	"bodies_1": "res://assets/lpc/bodies/bodies_1.png",
}
const LPC_HAIR: Dictionary = {
	"male_1":   "res://assets/lpc/hair/hair_male_1.png",
	"female_1": "res://assets/lpc/hair/hair_female_1.png",
}
const LPC_FACES: Dictionary = {
	"female_amber": "res://assets/lpc/faces/female_idle_amber.png",
	"female_black": "res://assets/lpc/faces/female_idle_black.png",
	"female_blue":  "res://assets/lpc/faces/female_idle_blue.png",
	"female_brown": "res://assets/lpc/faces/female_idle_brown.png",
	"female_light": "res://assets/lpc/faces/female_idle_light.png",
}
const LPC_SHIRTS: Dictionary = {
	"sleeveless_black": "res://assets/lpc/shirts/sleeveless_female_black.png",
	"sleeveless_blue":  "res://assets/lpc/shirts/sleeveless_female_blue.png",
	"sleeveless_green": "res://assets/lpc/shirts/sleeveless_female_green.png",
	"sleeveless_red":   "res://assets/lpc/shirts/sleeveless_female_red.png",
}

# ─── Codemon sprites ─────────────────────────────
const CODEMON: Dictionary = {
	"int":      "res://assets/codemon/art/character/codemon/int.png",
	"double":   "res://assets/codemon/art/character/codemon/double.png",
	"string":   "res://assets/codemon/art/character/codemon/string.png",
	"bool":     "res://assets/codemon/art/character/codemon/bool.png",
	"plus":     "res://assets/codemon/art/character/codemon/plus.png",
	"minus":    "res://assets/codemon/art/character/codemon/minus.png",
	"multiply": "res://assets/codemon/art/character/codemon/multiply.png",
	"divide":   "res://assets/codemon/art/character/codemon/divide.png",
	"modulo":   "res://assets/codemon/art/character/codemon/modulo.png",
	"if":       "res://assets/codemon/art/character/codemon/if.png",
	"else":     "res://assets/codemon/art/character/codemon/else.png",
	"for":      "res://assets/codemon/art/character/codemon/for.png",
	"while":    "res://assets/codemon/art/character/codemon/while.png",
	"and":      "res://assets/codemon/art/character/codemon/and.png",
	"or":       "res://assets/codemon/art/character/codemon/or.png",
	"array":    "res://assets/codemon/art/character/codemon/array.png",
	"char":     "res://assets/codemon/art/character/codemon/char.png",
	"plug":     "res://assets/codemon/art/character/codemon/plug.png",
}

# ─── NPC sprites ─────────────────────────────────
const NPCS: Dictionary = {
	"dr_forest":    "res://assets/codemon/art/character/npc/dr_forest.png",
	"dr_mountain":  "res://assets/codemon/art/character/npc/dr_mountain.png",
	"dr_desert":    "res://assets/codemon/art/character/npc/dr_desert.png",
	"dr_beach":     "res://assets/codemon/art/character/npc/dr_beach.png",
	"dr_lab":       "res://assets/codemon/art/character/npc/dr_laboratory.png",
	"doorman":      "res://assets/codemon/art/character/npc/doorman.png",
}

# ─── Audio ───────────────────────────────────────
const BGM: Dictionary = {
	"menu":  "res://assets/codemon/audio/music/menu.ogg",
	"ch1":   "res://assets/codemon/audio/music/ch1.ogg",
	"ch2":   "res://assets/codemon/audio/music/ch2.ogg",
	"ch3":   "res://assets/codemon/audio/music/ch3.ogg",
	"ch4":   "res://assets/codemon/audio/music/ch4.ogg",
	"ch5":   "res://assets/codemon/audio/music/ch5.ogg",
	"boss":  "res://assets/codemon/audio/music/boss.ogg",
}
const SFX: Dictionary = {
	"correct":   "res://assets/codemon/audio/sfx/correct.ogg",
	"wrong":     "res://assets/codemon/audio/sfx/wrong.ogg",
	"click":     "res://assets/codemon/audio/sfx/click.ogg",
	"chapter":   "res://assets/codemon/audio/sfx/chapter.ogg",
	"lose":      "res://assets/codemon/audio/sfx/lose.ogg",
}

const FONT_TTF: String = "res://assets/codemon/font/freepixel.ttf"

# ─── Helper methods ──────────────────────────────
func load_tex(path: String) -> Texture2D:
	if path == "" or not FileAccess.file_exists(path):
		return null
	return load(path) as Texture2D

func codemon(key: String) -> Texture2D:
	return load_tex(CODEMON.get(key, "") as String)

func npc(key: String) -> Texture2D:
	return load_tex(NPCS.get(key, "") as String)

func bgm(key: String) -> String:
	return BGM.get(key, "") as String

func sfx(key: String) -> String:
	return SFX.get(key, "") as String

func obj(key: String) -> Texture2D:
	return load_tex(OBJECTS.get(key, "") as String)

func apply_font(node: Control, size: int = 16) -> void:
	if not FileAccess.file_exists(FONT_TTF): return
	var font: FontFile = FontFile.new()
	font.load_dynamic_font(FONT_TTF)
	node.add_theme_font_override("font", font)
	node.add_theme_font_size_override("font_size", size)

func make_codemon_button(text: String, size: Vector2 = Vector2(184, 38)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size
	_style_button(b)
	return b

func _style_button(b: Button) -> void:
	# Normal state
	var sn := StyleBoxTexture.new()
	var nt := load_tex(BTN_NORMAL)
	if nt:
		sn.texture = nt
		sn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sn.set_expand_margin_all(4)
		b.add_theme_stylebox_override("normal", sn)

	# Hover state
	var sh := StyleBoxTexture.new()
	var ht := load_tex(BTN_HOVER)
	if ht:
		sh.texture = ht
		sh.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sh.set_expand_margin_all(4)
		b.add_theme_stylebox_override("hover", sh)

	# Pressed state
	var sp := StyleBoxTexture.new()
	var pt := load_tex(BTN_PRESSED)
	if pt:
		sp.texture = pt
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sp.set_expand_margin_all(4)
		b.add_theme_stylebox_override("pressed", sp)

	# Disabled state
	var sd := StyleBoxTexture.new()
	var dt := load_tex(BTN_DISABLED)
	if dt:
		sd.texture = dt
		sd.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sd.set_expand_margin_all(4)
		b.add_theme_stylebox_override("disabled", sd)

	b.add_theme_color_override("font_color",          Color("#e8e8f0"))
	b.add_theme_color_override("font_hover_color",    Color("#FFD93D"))
	b.add_theme_color_override("font_pressed_color",  Color("#ffffff"))
	b.add_theme_color_override("font_disabled_color", Color("#444455"))
	b.add_theme_font_size_override("font_size", 14)
