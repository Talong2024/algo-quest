# AlgoQuest — Setup & Integration Guide

## Quick Start (play immediately)

Import this zip into Godot 4 and press Play.
All 5 games work as placeholders until you add chapter scripts.

---

## Adding a Chapter Game

### Step 1 — Copy scripts
```
your_game/scripts/* → algoquest/scripts/chapters/queue/
your_game/scenes/*  → algoquest/scenes/chapters/queue/
```

### Step 2 — Edit Main.gd (3 changes)

```gdscript
# 1. Add at top:
const CHAPTER_ID: int = 1   # 1=queue 2=stack 3=list 4=tree 5=graph

# 2. Replace _on_level_complete():
func _on_level_complete() -> void:
    var score: int = gate_keeper.score   # or game_logic.score
    var wrong: int = gate_keeper.mistakes
    if current_level >= LEVELS.size() - 1:
        GameRouter.chapter_complete(CHAPTER_ID, score, wrong)
    else:
        current_level += 1
        _go_tutorial()

# 3. Replace _on_game_over():
func _on_game_over() -> void:
    GameRouter.go_game_over(CHAPTER_ID)
```

### Step 3 — Update scene paths
```gdscript
const TUTORIAL_SCENE: String = "res://scenes/chapters/queue/Tutorial.tscn"
const GAME_SCENE:     String = "res://scenes/chapters/queue/Game.tscn"
```

---

## Adding Codemon Sprites to Your Game

### Background tilemap
```gdscript
func _ready() -> void:
    var tex := AssetMap.load_tex(AssetMap.MAP_TILES["forest"])
    if tex:
        var bg := Sprite2D.new()
        bg.texture = tex
        bg.position = Vector2(640, 360)
        bg.scale = Vector2(4.0, 3.0)
        bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        bg.z_index = -10
        add_child(bg)
```

### Character/node sprites
```gdscript
var sprite := Sprite2D.new()
sprite.texture = AssetMap.codemon("int")   # or "bool", "for", "if", etc.
sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
sprite.scale = Vector2(2.0, 2.0)
add_child(sprite)
```

### NPC character
```gdscript
var npc := Sprite2D.new()
npc.texture = AssetMap.npc("dr_forest")
npc.hframes = 2   # 2-frame idle animation
npc.frame = 0
npc.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
add_child(npc)
```

---

## Chapter → Asset Theme

| Chapter | Map tile | NPC | Codemon icons |
|---------|----------|-----|---------------|
| 1 Queue | `street` | `dr_lab` | int, string, bool, double |
| 2 Stack | `mountain` | `dr_mountain` | plus, minus, multiply, if |
| 3 List | `desert` | `dr_desert` | array, for, while, string |
| 4 Tree | `forest` | `dr_forest` | if, else, for, while, and |
| 5 Graph | `beach` | `dr_beach` | int, bool, for, plug |

---

## Audio Bus Setup (required for sound)

1. Open Godot → **Audio** panel (bottom)
2. Click **Add Bus** → name it `Music`
3. Click **Add Bus** → name it `SFX`
4. Save as `res://assets/codemon/audio_layout.tres` (already referenced)

---

## Firebase Leaderboard (optional)

```gdscript
# In scripts/autoload/FirebaseManager.gd:
const PROJECT_ID: String = "your-firebase-project-id"
```
