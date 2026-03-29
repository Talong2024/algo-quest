extends Node2D
# ═══════════════════════════════════════════════════
# CutsceneVisual.gd
# Adds real codemon NPC portraits and environment
# art to the Cutscene scene.
# Add as child of Cutscene node; call setup() in
# Cutscene._ready() after building the base UI.
# ═══════════════════════════════════════════════════

# Maps speaker name → NPC sprite + background tile
const SPEAKER_MAP: Dictionary = {
	"Narrator":           { "npc": "",            "bg": "" },
	"Code Keeper":        { "npc": "",            "bg": "" },   # player = jimmy
	"Gate Captain":       { "npc": "dr_lab",      "bg": "street" },
	"Herald":             { "npc": "doorman",     "bg": "street" },
	"Wizard":             { "npc": "dr_mountain", "bg": "mountain" },
	"Conductor":          { "npc": "merchant",    "bg": "desert" },
	"Ancient Sage":       { "npc": "dr_forest",   "bg": "forest" },
	"Oracle":             { "npc": "dr_forest",   "bg": "forest" },
	"Map Spirit":         { "npc": "dr_beach",    "bg": "beach" },
	"Messenger":          { "npc": "doorman",     "bg": "beach" },
	"Algorithm Overlord": { "npc": "plug",        "bg": "" },   # plug = villain-ish
}

var _portrait_sprite:  Sprite2D
var _bg_sprite:        Sprite2D
var _current_speaker:  String = ""

func setup(portrait_rect: ColorRect) -> void:
	# Replace the plain ColorRect portrait with a real NPC sprite
	var pos:  Vector2 = portrait_rect.position
	var size: Vector2 = portrait_rect.size

	# Background tile behind portrait
	_bg_sprite           = Sprite2D.new()
	_bg_sprite.position  = pos + size / 2.0
	_bg_sprite.z_index   = 1
	_bg_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_rect.get_parent().add_child(_bg_sprite)

	# NPC portrait sprite
	_portrait_sprite           = Sprite2D.new()
	_portrait_sprite.position  = pos + size / 2.0
	_portrait_sprite.hframes   = 2
	_portrait_sprite.vframes   = 1
	_portrait_sprite.frame     = 0
	_portrait_sprite.z_index   = 2
	_portrait_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_rect.get_parent().add_child(_portrait_sprite)

	# Scale NPC sprite (48×48 source) to fill portrait rect
	var target_scale: float = min(size.x, size.y) / 48.0
	_portrait_sprite.scale = Vector2.ONE * target_scale * 0.9

	# Hide original ColorRect
	portrait_rect.visible = false

func update_speaker(speaker: String) -> void:
	if speaker == _current_speaker: return
	_current_speaker = speaker

	var entry: Dictionary = SPEAKER_MAP.get(speaker, {}) as Dictionary
	var npc_key: String   = entry.get("npc", "") as String
	var bg_key:  String   = entry.get("bg", "") as String

	# Update NPC portrait
	if npc_key != "":
		var tex: Texture2D = AssetMap.npc(npc_key)
		if tex:
			_portrait_sprite.texture = tex
			_portrait_sprite.visible = true
		else:
			_portrait_sprite.visible = false
	elif speaker == "Code Keeper":
		# Show Jimmy for player
		var jimmy_tex: Texture2D = AssetMap.load_tex(AssetMap.PLAYER)
		if jimmy_tex:
			_portrait_sprite.texture = jimmy_tex
			_portrait_sprite.hframes = 16
			_portrait_sprite.frame   = 0
			_portrait_sprite.visible = true
	elif speaker == "Algorithm Overlord":
		# Use bubble_sort codemon as villain
		var tex: Texture2D = AssetMap.codemon("bubble_sort")
		if tex:
			_portrait_sprite.texture = tex
			_portrait_sprite.hframes = 1
			_portrait_sprite.visible = true
	else:
		_portrait_sprite.visible = false

	# Update background tile
	if bg_key != "":
		var tile_path: String = AssetMap.MAP_TILES.get(bg_key, "") as String
		if tile_path != "":
			var bg_tex: Texture2D = AssetMap.load_tex(tile_path)
			if bg_tex:
				_bg_sprite.texture  = bg_tex
				_bg_sprite.scale    = Vector2.ONE * 3.0
				_bg_sprite.visible  = true
			else:
				_bg_sprite.visible = false
		else:
			_bg_sprite.visible = false
	else:
		_bg_sprite.visible = false
