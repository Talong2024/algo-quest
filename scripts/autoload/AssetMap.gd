extends Node
# ═══════════════════════════════════════════════════
# AssetMap.gd  —  AUTOLOAD SINGLETON
# ════════════════════════════════════════════════════
# ▶ VISUAL REGIONS — search these tags to find what
#   controls each part of the screen:
#
#   #REGION:MAP_TILES    — chapter world backgrounds
#   #REGION:PARALLAX     — scrolling bg layers
#   #REGION:OBJECTS      — trees, rocks, props
#   #REGION:LOGO         — SS intro + main menu logo
#   #REGION:CHARACTERS   — player + NPC sprites
#   #REGION:VIDEO        — main menu background video
#   #REGION:BUTTONS      — codemon-style button art
#   #REGION:LPC          — character creation sheets
#   #REGION:CODEMON      — DSA creature sprites
#   #REGION:AUDIO        — music + sfx paths
# ════════════════════════════════════════════════════

#REGION:MAP_TILES ─────────────────────────────────
const MAP_TILES: Dictionary = {
	"street":   "res://assets/codemon/art/map/street_tile.png",
	"mountain": "res://assets/codemon/art/map/mountain.png",
	"desert":   "res://assets/codemon/art/map/desert.png",
	"forest":   "res://assets/codemon/art/map/forest.png",
	"beach":    "res://assets/codemon/art/map/beach.png",
	"boss":     "res://assets/codemon/art/map/boss.png",
}

#REGION:PARALLAX ───────────────────────────────────
const PARALLAX: Dictionary = {
	"mountain": "res://assets/codemon/art/parallax/mountain.png",
	"desert":   "res://assets/codemon/art/parallax/desert.png",
}

#REGION:OBJECTS ────────────────────────────────────
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

#REGION:LOGO ───────────────────────────────────────
const LOGO_D:       String = "res://assets/codemon/art/logo/D.png"
const LOGO_K:       String = "res://assets/codemon/art/logo/K.png"
const LOGO_BRACKET: String = "res://assets/codemon/art/logo/bracket.png"
const LOGO_CODEMON: String = "res://assets/codemon/art/logo/codemon.png"

#REGION:CHARACTERS ─────────────────────────────────
const JIMMY:     String = "res://assets/codemon/art/character/jimmy.png"
const WORLD_MAP: String = "res://assets/codemon/art/map/map.png"
# Player appearance is now LPC — use SaveManager.get_player_appearance() + CharacterSprite

const NPCS: Dictionary = {
	"dr_forest":   "res://assets/codemon/art/character/npc/dr_forest.png",
	"dr_mountain": "res://assets/codemon/art/character/npc/dr_mountain.png",
	"dr_desert":   "res://assets/codemon/art/character/npc/dr_desert.png",
	"dr_beach":    "res://assets/codemon/art/character/npc/dr_beach.png",
	"dr_lab":      "res://assets/codemon/art/character/npc/dr_laboratory.png",
	"doorman":     "res://assets/codemon/art/character/npc/doorman.png",
}

#REGION:VIDEO ──────────────────────────────────────
# ⚠ Godot 4 built-in only supports .ogv (Theora).
# Convert: ffmpeg -i main_menu_bg.mp4 -c:v libtheora -q:v 7 main_menu_bg.ogv
# Place the .ogv file in assets/video/ and it will load automatically.
const MENU_BG_VIDEO: String = "res://assets/video/main_menu_bg.mp4"

#REGION:BUTTONS ────────────────────────────────────
# These textures (92×19 px each) are applied as
# StyleBoxTexture on every Button node.
# border = 3px each side, text sits in the white center.
const BTN_NORMAL:   String = "res://assets/codemon/art/component/btn_normal.png"
const BTN_PRESSED:  String = "res://assets/codemon/art/component/btn_clicked.png"
const BTN_HOVER:    String = "res://assets/codemon/art/component/btn_selected.png"
const BTN_DISABLED: String = "res://assets/codemon/art/component/btn_disabled.png"
const BTN_M_NORMAL: String = "res://assets/codemon/art/component/btn_m_normal.png"
const BTN_M_PRESSED:String = "res://assets/codemon/art/component/btn_m_clicked.png"
const BTN_M_HOVER:  String = "res://assets/codemon/art/component/btn_m_selected.png"

#REGION:LPC ────────────────────────────────────────
# Full LPC character system — see scripts/lpc/ for CharacterData,
# CharacterRandomizer, and CharacterSprite.
# Asset roots:
#   Body:    res://assets/lpc/body/{female|male|teen}/{skin}/{anim}.png
#   Legs:    res://assets/lpc/legs/{type}/{gender}/{anim}.png
#   Shirt:   res://assets/lpc/{style}/{body}/{anim}/{color}.png
#   Hair:    res://assets/lpc/hair/{style}/adult/[bg|fg/]{anim}/{color}.png
#   Feet:    res://assets/lpc/feet/{type}/{body}/{anim}/{color}.png
const LPC_ROOT: String = "res://assets/lpc/"

#REGION:CODEMON ────────────────────────────────────
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

#REGION:AUDIO ──────────────────────────────────────
# Actual file names from assets/codemon/audio/
const BGM: Dictionary = {
	"menu":  "res://assets/codemon/audio/music/street_laboratory.ogg",
	"ch1":   "res://assets/codemon/audio/music/street_laboratory.ogg",
	"ch2":   "res://assets/codemon/audio/music/mountain.ogg",
	"ch3":   "res://assets/codemon/audio/music/desert.ogg",
	"ch4":   "res://assets/codemon/audio/music/forest.ogg",
	"ch5":   "res://assets/codemon/audio/music/beach.ogg",
	"boss":  "res://assets/codemon/audio/music/boss.ogg",
}
const SFX: Dictionary = {
	"correct": "res://assets/codemon/audio/sfx/success.ogg",
	"wrong":   "res://assets/codemon/audio/sfx/fail.ogg",
	"click":   "res://assets/codemon/audio/sfx/button.ogg",
	"chapter": "res://assets/codemon/audio/sfx/success.ogg",
	"lose":    "res://assets/codemon/audio/sfx/fail.ogg",
	"step":    "res://assets/codemon/audio/sfx/footstep.ogg",
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

func ui(key: String) -> Texture2D:
	# Legacy helper used by SpriteHelper
	match key:
		"btn_normal":   return load_tex(BTN_NORMAL)
		"btn_selected": return load_tex(BTN_HOVER)
		"btn_clicked":  return load_tex(BTN_PRESSED)
		"btn_disabled": return load_tex(BTN_DISABLED)
	return null

func hud(_key: String) -> Texture2D:
	return null

func chapter_theme(_ch: int) -> Dictionary:
	return {}

func apply_font(node: Control, size: int = 16) -> void:
	if not FileAccess.file_exists(FONT_TTF): return
	var font: FontFile = FontFile.new()
	font.load_dynamic_font(FONT_TTF)
	node.add_theme_font_override("font", font)
	node.add_theme_font_size_override("font_size", size)

# ─── Button factory (REGION:BUTTONS) ─────────────
# Creates a Button with codemon pixel-art styling.
# Text is always visible — dark text on white btn body.
func make_codemon_button(text: String, sz: Vector2 = Vector2(184, 38)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = sz
	b.clip_text = false

	# #REGION:BUTTONS — normal / hover / pressed / disabled styleboxes
	var norm_tex: Texture2D = load_tex(BTN_NORMAL)
	var hovr_tex: Texture2D = load_tex(BTN_HOVER)
	var pres_tex: Texture2D = load_tex(BTN_PRESSED)
	var disa_tex: Texture2D = load_tex(BTN_DISABLED)

	for pair in [
		["normal",   norm_tex],
		["hover",    hovr_tex],
		["pressed",  pres_tex],
		["disabled", disa_tex],
		["focus",    norm_tex],
	]:
		var tex: Texture2D = pair[1] as Texture2D
		if tex == null: continue
		var sb := StyleBoxTexture.new()
		sb.texture = tex
		# Border corners are 3 px — content area is center white region
		sb.set_texture_margin(SIDE_LEFT,   3)
		sb.set_texture_margin(SIDE_RIGHT,  3)
		sb.set_texture_margin(SIDE_TOP,    3)
		sb.set_texture_margin(SIDE_BOTTOM, 3)
		# Expand outward so button grows without distorting border
		sb.set_expand_margin_all(0)
		b.add_theme_stylebox_override(pair[0] as String, sb)

	# Text must be DARK so it shows on the white button body
	b.add_theme_color_override("font_color",          Color("#1a1a2e"))
	b.add_theme_color_override("font_hover_color",    Color("#0a0a1e"))
	b.add_theme_color_override("font_pressed_color",  Color("#333355"))
	b.add_theme_color_override("font_disabled_color", Color("#888899"))
	b.add_theme_color_override("font_focus_color",    Color("#1a1a2e"))
	b.add_theme_font_size_override("font_size", 13)
	b.flat = false
	return b
