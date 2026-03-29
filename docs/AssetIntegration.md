# Chapter Asset Integration Reference

Copy the snippets below into each chapter's scripts.
None of this is auto-loaded — it's a how-to reference.

---

## Chapter 1 — Kingdom Queue

### CitizenNode.gd — add after `setup()`
```gdscript
func _apply_codemon_sprite() -> void:
    var priority: int = data.get("priority", 2) as int
    var icon_map := { 1:"int", 2:"string", 3:"bool", 4:"double" }
    var sprite := Sprite2D.new()
    sprite.texture        = AssetMap.codemon(icon_map.get(priority,"char") as String)
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    sprite.scale          = Vector2(1.5, 1.5)
    sprite.z_index        = 1
    add_child(sprite)
```

### World.gd — add at end of `_ready()`
```gdscript
func _apply_world_art() -> void:
    var tile := Sprite2D.new()
    tile.texture        = AssetMap.load_tex(AssetMap.MAP_TILES["street"])
    tile.position       = Vector2(640, 360)
    tile.scale          = Vector2(3.4, 2.3)
    tile.z_index        = -10
    tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(tile)
```

---

## Chapter 2 — Castle of Echoes

### RuneNode.gd — add constant + call in `_draw()`
```gdscript
const RUNE_CODEMON := {
    "Fire":"plus", "Ice":"minus", "Thunder":"multiply",
    "Earth":"divide", "Shadow":"modulo", "Light":"equal",
    "Wind":"if", "Void":"while",
}

func _draw_codemon_icon() -> void:
    var key: String    = RUNE_CODEMON.get(data.get("name",""), "plus") as String
    var tex: Texture2D = AssetMap.codemon(key)
    if tex:
        var alpha := 1.0 - (float(stack_size-1-depth)/max(stack_size,1)) * 0.55
        draw_texture_rect(tex, Rect2(-16,-16,32,32), false, Color(1,1,1,alpha))
    if is_top:
        draw_arc(Vector2.ZERO, 20, 0, TAU, 32,
            data.get("glow", Color("#C77DFF")) as Color, 2.0)
```

### CastleWorld.gd — add at end of `_ready()`
```gdscript
func _apply_world_art() -> void:
    var bg := Sprite2D.new()
    bg.texture        = AssetMap.load_tex(AssetMap.OBJECTS["mountain_bg"])
    bg.position       = Vector2(640, 360)
    bg.scale          = Vector2(2.6, 1.7)
    bg.z_index        = -10
    bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(bg)
    SpriteHelper.scatter_objects(self, 2, Rect2(100,80,1000,540), 8)
```

---

## Chapter 3 — Chain Train

### CarriageNode.gd — add after `setup()`
```gdscript
func _apply_codemon_icon() -> void:
    var icons := ["array","int","for","while","if","string"]
    var sprite := Sprite2D.new()
    sprite.texture        = AssetMap.codemon(icons[(data.get("id",0) as int) % icons.size()])
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    sprite.scale          = Vector2(0.8, 0.8)
    sprite.position       = Vector2(-28, 0)
    sprite.z_index        = 1
    add_child(sprite)
```

### TrainWorld.gd — add at end of `_ready()`
```gdscript
func _apply_world_art() -> void:
    var bg := Sprite2D.new()
    bg.texture        = AssetMap.load_tex(AssetMap.PARALLAX["desert"])
    bg.position       = Vector2(640, 360)
    bg.scale          = Vector2(4.0, 3.0)
    bg.z_index        = -10
    bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(bg)
    SpriteHelper.scatter_objects(self, 3, Rect2(80,80,1100,200), 5)
    SpriteHelper.scatter_objects(self, 3, Rect2(80,480,1100,160), 5)
```

---

## Chapter 4 — Oracle's Forest

### TreeNodeVisual.gd — add inside `_draw()` after the main circle
```gdscript
func _draw_codemon_face() -> void:
    var icons := ["if","else","for","while","and","or","bool","int"]
    var key   := icons[(data.get("value",0) as int) % icons.size()] as String
    var tex   := AssetMap.codemon(key)
    if tex:
        draw_texture_rect(tex, Rect2(-12,-12,24,24), false)
```

### ForestWorld.gd — add at end of `_ready()`
```gdscript
func _apply_world_art() -> void:
    var bg := Sprite2D.new()
    bg.texture        = AssetMap.load_tex(AssetMap.MAP_TILES["forest"])
    bg.position       = Vector2(640, 360)
    bg.scale          = Vector2(4.1, 2.9)
    bg.z_index        = -10
    bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(bg)
    SpriteHelper.scatter_objects(self, 4, Rect2(80,80,200,540), 6)
    SpriteHelper.scatter_objects(self, 4, Rect2(1000,80,200,540), 6)
```

---

## Chapter 5 — Kingdom Roads

### CityNode.gd — add inside `_draw()` after the city circle
```gdscript
func _draw_codemon_face() -> void:
    var icons := ["int","bool","char","for","while","plug"]
    var key   := icons[(data.get("id",0) as int) % icons.size()] as String
    var tex   := AssetMap.codemon(key)
    if tex:
        var alpha := 1.0 if state in ["visited","current","queued","stack"] else 0.5
        draw_texture_rect(tex, Rect2(-12,-12,24,24), false, Color(1,1,1,alpha))
```

### KingdomWorld.gd — add at end of `_ready()`
```gdscript
func _apply_world_art() -> void:
    var bg := Sprite2D.new()
    bg.texture        = AssetMap.load_tex(AssetMap.MAP_TILES["beach"])
    bg.position       = Vector2(640, 360)
    bg.scale          = Vector2(2.1, 1.9)
    bg.z_index        = -10
    bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(bg)
    SpriteHelper.scatter_objects(self, 5, Rect2(60,80,200,540), 4)
    SpriteHelper.scatter_objects(self, 5, Rect2(1020,80,200,540), 4)
```

---

## Cutscene — NPC portraits

### Cutscene.gd — add in `_ready()` after `_build_ui()`
```gdscript
var _visual: Node  # CutsceneVisual instance

func _apply_visual_layer() -> void:
    _visual = load("res://scripts/shared/CutsceneVisual.gd").new()
    _visual.name = "CutsceneVisual"
    add_child(_visual)
    _visual.setup(_face)   # _face = the ColorRect portrait placeholder

# Then in _show(), add:
#   if _visual: _visual.update_speaker(line["speaker"])
```

---

## WorldMap — background art

### WorldMap.gd — add in `_ready()` before `_build_hud()`
```gdscript
func _apply_visual_layer() -> void:
    var visual := load("res://scripts/shared/WorldMapVisual.gd").new()
    visual.name = "WorldMapVisual"
    add_child(visual)
    visual.setup()
```

---

## Pixel font — apply to any label

```gdscript
# In any script:
AssetMap.apply_font(my_label, 16)         # 16px pixel font
AssetMap.apply_font(my_button, 14)        # 14px on buttons
AssetMap.apply_font(my_title_label, 24)   # 24px for titles
```
