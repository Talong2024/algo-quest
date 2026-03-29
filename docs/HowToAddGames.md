# How to Connect Your Games to AlgoQuest

## The short version

Each of your 5 game projects needs 2 things done:
1. **Copy files** into the right folders
2. **Edit 3 lines** in each Main.gd

---

## Step 1 — Folder mapping

Copy from each standalone project into AlgoQuest:

```
kingdom_queue_topdown/
  scripts/*.gd          →   AlgoQuest/scripts/chapters/queue/
  scenes/*.tscn         →   AlgoQuest/scenes/chapters/queue/
  assets/               →   AlgoQuest/assets/chapters/queue/   (if any)

castle_echoes_topdown/
  scripts/*.gd          →   AlgoQuest/scripts/chapters/stack/
  scenes/*.tscn         →   AlgoQuest/scenes/chapters/stack/

chain_train/
  scripts/*.gd          →   AlgoQuest/scripts/chapters/linked_list/
  scenes/*.tscn         →   AlgoQuest/scenes/chapters/linked_list/

oracles_forest/
  scripts/*.gd          →   AlgoQuest/scripts/chapters/tree/
  scenes/*.tscn         →   AlgoQuest/scenes/chapters/tree/

kingdom_roads/
  scripts/*.gd          →   AlgoQuest/scripts/chapters/graph/
  scenes/*.tscn         →   AlgoQuest/scenes/chapters/graph/
```

---

## Step 2 — Edit each chapter's Main.gd (3 changes)

### Add at line 1:
```gdscript
const CHAPTER_ID: int = 1   # 1=queue, 2=stack, 3=linked_list, 4=tree, 5=graph
```

### Replace _on_level_complete():
```gdscript
func _on_level_complete() -> void:
    var score: int = game_logic.score
    var wrong: int = game_logic._mistakes
    ProgressTracker.complete_level(CHAPTER_ID, current_level + 1, score, wrong)
    AudioManager.play_sfx("correct" if wrong == 0 else "chapter")
    if current_level >= LEVELS.size() - 1:
        GameRouter.chapter_complete(CHAPTER_ID, score, wrong)
    else:
        current_level += 1
        _go_tutorial()
```

### Replace _on_game_over():
```gdscript
func _on_game_over() -> void:
    AudioManager.play_sfx("lose")
    GameRouter.go_game_over(CHAPTER_ID)
```

### Delete these (GameRouter handles them):
```gdscript
# DELETE:
func _on_next() -> void:   ...
func _on_retry() -> void:  ...
func _on_menu() -> void:   ...
```

### Update scene path constants:
```gdscript
# Change from:
const TUTORIAL_SCENE: String = "res://scenes/Tutorial.tscn"
const GAME_SCENE:     String = "res://scenes/Game.tscn"
# To (example for queue):
const TUTORIAL_SCENE: String = "res://scenes/chapters/queue/Tutorial.tscn"
const GAME_SCENE:     String = "res://scenes/chapters/queue/Game.tscn"
# Remove the LevelComplete constant — GameRouter loads the shared one
```

---

## Step 3 — Add codemon art to each game (optional)

### Background tilemap
Add this to each world script's _ready():
```gdscript
func _ready() -> void:
    # ... your existing code ...
    _apply_codemon_background()

func _apply_codemon_background() -> void:
    var tex: Texture2D = AssetMap.load_tex(AssetMap.MAP_TILES["street"]) # or forest, mountain etc
    if not tex: return
    var bg := Sprite2D.new()
    bg.texture        = tex
    bg.position       = Vector2(640, 360)
    bg.scale          = Vector2(3.5, 2.5)
    bg.z_index        = -10
    bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(bg)
```

### Character/node sprites
Add to CitizenNode, RuneNode, CarriageNode etc. in _ready():
```gdscript
func _ready() -> void:
    _add_codemon_sprite()

func _add_codemon_sprite() -> void:
    # Pick icon based on type
    var icons := ["int","bool","char","string","double","array"]
    var key: String = icons[(data.get("id", 0) as int) % icons.size()]
    var tex: Texture2D = AssetMap.codemon(key)
    if not tex: return
    var s := Sprite2D.new()
    s.texture        = tex
    s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    s.scale          = Vector2(1.5, 1.5)
    s.z_index        = 1
    add_child(s)
```

### TileMapLayer
If your game uses TileMapLayer, create a TileSet in Godot from the codemon PNGs:
1. FileSystem → `assets/codemon/art/map/forest.png` → right-click → New TileSet
2. Add to TileMapLayer node
3. Set Rendering → Texture Filter → Nearest

---

## Chapter ID map
| ID | Game | Folder |
|----|------|--------|
| 1  | Kingdom Queue   | scripts/chapters/queue/ |
| 2  | Castle of Echoes | scripts/chapters/stack/ |
| 3  | Chain Train     | scripts/chapters/linked_list/ |
| 4  | Oracle's Forest | scripts/chapters/tree/ |
| 5  | Kingdom Roads   | scripts/chapters/graph/ |
