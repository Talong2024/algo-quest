extends Node
# ═══════════════════════════════════════════════════
# SpriteHelper.gd  —  AUTOLOAD SINGLETON
#
# Applies codemon assets to AlgoQuest game nodes.
# Called from each chapter's spawner/world scripts.
# ═══════════════════════════════════════════════════

# ─── Jimmy (player) spritesheet ───────────────────
# jimmy.png = 768×48 → 16 frames of 48×48
# Frame layout (guessed from typical top-down RPG):
#   0-3:  walk down
#   4-7:  walk left
#   8-11: walk right
#   12-15:walk up

const JIMMY_FRAME_W: int = 48
const JIMMY_FRAME_H: int = 48
const JIMMY_FRAMES:  int = 16

# ─── NPC spritesheet ──────────────────────────────
# Each NPC png = 96×48 → 2 frames of 48×48
# Frame 0 = facing forward (idle)
# Frame 1 = talking animation

const NPC_FRAME_W: int = 48
const NPC_FRAME_H: int = 48

# ─── Chapter citizen/node sprites ─────────────────
# Maps chapter → which codemon icons to use as
# citizens (queue), runes (stack), carriages (list),
# orbs (tree), cities (graph)

const CHAPTER_CODEMON_SETS: Dictionary = {
	1: ["int","bool","char","string","double","array"],       # citizens
	2: ["plus","minus","multiply","divide","equal","if"],     # runes
	3: ["array","int","for","while","if","string"],           # carriage labels
	4: ["if","else","for","while","and","or"],                # tree node icons
	5: ["int","bool","char","for","while","plug"],            # city icons
}

# ─── Apply sprite to a Sprite2D node ──────────────

func apply_codemon_icon(sprite: Sprite2D, chapter: int, index: int) -> void:
	var set_key: Array = CHAPTER_CODEMON_SETS.get(chapter, ["int"]) as Array
	var key: String    = set_key[index % set_key.size()] as String
	var tex: Texture2D = AssetMap.codemon(key)
	if tex and sprite:
		sprite.texture = tex

func apply_npc(sprite: Sprite2D, npc_key: String) -> void:
	var tex: Texture2D = AssetMap.npc(npc_key)
	if tex and sprite:
		sprite.texture       = tex
		sprite.hframes       = 2
		sprite.vframes       = 1
		sprite.frame         = 0

func apply_hud_icon(tex_rect: TextureRect, key: String) -> void:
	var tex: Texture2D = AssetMap.hud(key)
	if tex and tex_rect:
		tex_rect.texture = tex

func apply_ui_panel(tex_rect: TextureRect, key: String) -> void:
	var tex: Texture2D = AssetMap.ui(key)
	if tex and tex_rect:
		tex_rect.texture = tex

# ─── Build a Sprite2D from an asset key ───────────

func make_sprite(key: String, dict: Dictionary = {}) -> Sprite2D:
	var s := Sprite2D.new()
	var path: String = ""
	if not dict.is_empty():
		path = dict.get(key, "") as String
	if path == "":
		# Try codemon dict
		path = AssetMap.CODEMON.get(key, "") as String
	if path == "":
		path = AssetMap.OBJECTS.get(key, "") as String
	if path != "" and ResourceLoader.exists(path):
		s.texture = load(path)
	return s

# ─── World decoration: scatter objects in a region ──

func scatter_objects(parent: Node2D, chapter: int,
		region: Rect2, count: int) -> void:
	var theme: Dictionary = AssetMap.chapter_theme(chapter)
	var obj_keys: Array   = theme.get("env_objects", ["bush_1"]) as Array
	for i in count:
		var key: String    = obj_keys[i % obj_keys.size()] as String
		var tex: Texture2D = AssetMap.obj(key)
		if not tex: continue
		var s := Sprite2D.new()
		s.texture  = tex
		s.position = Vector2(
			region.position.x + randf() * region.size.x,
			region.position.y + randf() * region.size.y
		)
		s.z_index  = 2
		# Nearest-neighbor for pixel art
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		parent.add_child(s)

# ─── Pixel-art texture filter helper ─────────────

func set_nearest(node: CanvasItem) -> void:
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

# ─── Dialog box builder ───────────────────────────

func make_dialog_box(parent: Node, pos: Vector2,
		speaker: String, text: String) -> Control:
	var container := Control.new()
	container.set_position(pos)
	parent.add_child(container)

	# Background
	var bg := TextureRect.new()
	bg.texture         = AssetMap.ui("dialog_box")
	bg.expand_mode     = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode    = TextureRect.STRETCH_SCALE
	bg.set_size(Vector2(480, 100))
	bg.texture_filter  = CanvasItem.TEXTURE_FILTER_NEAREST
	container.add_child(bg)

	# Speaker name
	var sp := Label.new()
	sp.text = speaker
	sp.set_position(Vector2(16, 8))
	sp.add_theme_font_size_override("font_size", 12)
	sp.add_theme_color_override("font_color", Color("#FFD93D"))
	container.add_child(sp)

	# Body text
	var lbl := Label.new()
	lbl.text = text
	lbl.set_position(Vector2(16, 28))
	lbl.set_size(Vector2(448, 64))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color("#e8e8f0"))
	container.add_child(lbl)

	# Next button arrow
	var next := TextureRect.new()
	next.texture        = AssetMap.ui("dialog_next_btn")
	next.set_position(Vector2(450, 74))
	next.set_size(Vector2(20, 20))
	next.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	container.add_child(next)

	return container

# ─── Styled button with codemon art ───────────────

func make_styled_button(text: String, pos: Vector2,
		sz: Vector2 = Vector2(120, 24)) -> Button:
	var b := Button.new()
	b.text = text
	b.set_position(pos)
	b.set_size(sz)
	b.add_theme_font_size_override("font_size", 12)

	# Apply normal/pressed/hover textures from codemon UI
	var normal_tex := AssetMap.ui("btn_normal")
	var select_tex := AssetMap.ui("btn_selected")
	var click_tex  := AssetMap.ui("btn_clicked")

	if normal_tex:
		var sb_normal := StyleBoxTexture.new()
		sb_normal.texture = normal_tex
		sb_normal.texture_margin_left  = 4
		sb_normal.texture_margin_right = 4
		b.add_theme_stylebox_override("normal", sb_normal)

	if select_tex:
		var sb_hover := StyleBoxTexture.new()
		sb_hover.texture = select_tex
		sb_hover.texture_margin_left  = 4
		sb_hover.texture_margin_right = 4
		b.add_theme_stylebox_override("hover",   sb_hover)
		b.add_theme_stylebox_override("focus",   sb_hover)

	if click_tex:
		var sb_press := StyleBoxTexture.new()
		sb_press.texture = click_tex
		sb_press.texture_margin_left  = 4
		sb_press.texture_margin_right = 4
		b.add_theme_stylebox_override("pressed", sb_press)

	return b
