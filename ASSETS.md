# AlgoQuest — Codemon Asset Reference

All assets live in `res://assets/codemon/`.
They are mapped through `AssetMap.gd` (autoload).

---

## Audio

### BGM tracks (7 music files)
| AlgoQuest scene | Codemon file | Feel |
|---|---|---|
| Main menu, World Map, Ch1 | `audio/music/street_laboratory.ogg` | Town/lab, upbeat |
| Ch2 Castle of Echoes | `audio/music/mountain.ogg` | Epic, castle |
| Ch3 Chain Train | `audio/music/desert.ogg` | Adventurous, open |
| Ch4 Oracle's Forest | `audio/music/forest.ogg` | Calm, mysterious |
| Ch5 Kingdom Roads | `audio/music/beach.ogg` | Bright, open world |
| Final Boss | `audio/music/boss.ogg` | Intense battle |
| Boss defeated | `audio/music/boss_defeated.ogg` | Victory fanfare |

### SFX (7 sound effects)
| AlgoQuest use | Codemon file |
|---|---|
| Correct pick | `audio/sfx/success.ogg` |
| Wrong pick | `audio/sfx/fail.ogg` |
| Button / click | `audio/sfx/button.ogg` |
| PUSH rune / jump | `audio/sfx/jump_1.ogg` |
| POP rune / land | `audio/sfx/jump_2.ogg` |
| Chain link | `audio/sfx/bubble.ogg` |
| Footstep | `audio/sfx/footstep.ogg` |

---

## Characters

### Player
`art/character/jimmy.png` — 768×48 spritesheet, 16 frames of 48×48
```
Frames 0-3:  walk down
Frames 4-7:  walk left
Frames 8-11: walk right
Frames 12-15: walk up
```
Use in Cutscene as "Code Keeper" portrait.

### NPCs (each 96×48 → 2 frames of 48×48)
| NPC | File | AlgoQuest role |
|---|---|---|
| dr_forest | `art/character/npc/dr_forest.png` | Oracle (Ch4) |
| dr_mountain | `art/character/npc/dr_mountain.png` | Wizard (Ch2) |
| dr_lab | `art/character/npc/dr_laboratory.png` | Gate Captain (Ch1) |
| dr_desert | `art/character/npc/dr_desert.png` | Conductor (Ch3) |
| dr_beach | `art/character/npc/dr_beach.png` | Map Spirit (Ch5) |
| merchant | `art/character/npc/merchant.png` | Merchant/Herald |
| doorman | `art/character/npc/doorman.png` | Doorman/Messenger |
| plug | `art/character/npc/plug.png` | Algorithm Overlord |

### Codemon sprites (32×32 each, 64×64 for bubble_sort)
These are the "algorithm monsters" — used as citizens, runes, node icons.

**Used as citizens (Ch1 Queue):**
- `int.png` → noble (priority 1)
- `string.png` → commoner (priority 2)
- `bool.png` → merchant
- `double.png` → elderly

**Used as runes (Ch2 Stack):**
- `plus.png` → Fire rune
- `minus.png` → Ice rune
- `multiply.png` → Thunder rune
- `divide.png` → Earth rune
- `modulo.png` → Shadow rune
- `equal.png` → Light rune
- `if.png` → Wind rune
- `while.png` → Void rune

**Used as carriage icons (Ch3 Linked List):**
- `array.png`, `int.png`, `for.png`, `while.png`, `if.png`, `string.png`

**Used as tree node icons (Ch4 BST/AVL):**
- `if.png`, `else.png`, `for.png`, `while.png`, `and.png`, `or.png`

**Used as city icons (Ch5 Graph):**
- `int.png`, `bool.png`, `char.png`, `for.png`, `while.png`, `plug.png`

**Selected state variants** (used for highlighted/current node):
- Most codemon have a matching `_selected.png` — use on active/top node.

---

## UI Components

### Dialog system
| File | Size | Use |
|---|---|---|
| `art/component/dialog_box.png` | 377×79 | Cutscene dialogue background (9-patch) |
| `art/component/dialog_choice_box.png` | — | Choice dialogue |
| `art/component/dialog_next_btn.png` | — | Advance arrow |

### Buttons
| File | Size | Use |
|---|---|---|
| `art/component/btn_normal.png` | 92×19 | Default button normal state |
| `art/component/btn_selected.png` | 92×19 | Hover state |
| `art/component/btn_clicked.png` | 92×19 | Pressed state |
| `art/component/btn_disabled.png` | 92×19 | Disabled state |
| `art/component/btn_m_normal.png` | — | Medium button |
| `art/component/btn_small_normal.png` | — | Small button |
| `art/component/btn_circle_normal.png` | — | Circle button (DSA panel toggle) |

Apply as StyleBoxTexture with `texture_margin_left/right = 4`.

### Panels
| File | Size | Use |
|---|---|---|
| `art/component/background_l.png` | 385×193 | Large panel (tutorial, DSA panel) |
| `art/component/background_m.png` | — | Medium panel (HUD, popups) |
| `art/component/interaction_btn.png` | — | Interaction prompt |

---

## HUD Icons (32×32 each)
| File | Use |
|---|---|
| `art/hud/correct.png` | Correct answer indicator |
| `art/hud/wrong.png` | Wrong answer indicator |
| `art/hud/coin.png` | Score icon |
| `art/hud/battery.png` | Lives (full) |
| `art/hud/no_battery.png` | Lives (empty) |
| `art/hud/book.png` | DSA panel icon |
| `art/hud/map.png` | World map icon |
| `art/hud/gear.png` | Settings icon |
| `art/hud/scroll.png` | Progress / achievements |
| `art/hud/bag.png` | Inventory |

---

## Map Tiles (background art)
| File | Size | Chapter |
|---|---|---|
| `art/map/map.png` | 200×140 | World map overview (scale 6.4× to fill 1280×720) |
| `art/map/street_tile.png` | 384×320 | Ch1 Kingdom Queue |
| `art/map/mountain.png` | 320×128 | Ch2 Castle of Echoes |
| `art/map/desert.png` | 640×256 | Ch3 Chain Train |
| `art/map/forest.png` | 320×256 | Ch4 Oracle's Forest |
| `art/map/beach.png` | 576×384 | Ch5 Kingdom Roads |
| `art/map/boss.png` | 384×192 | Final Boss arena |
| `art/map/laboratory.png` | 320×192 | Lab / extras |

**Usage:** Load as Sprite2D, scale to fill 1280×720, z_index=-10,
`texture_filter = TEXTURE_FILTER_NEAREST`.

---

## Environment Objects

### Forest (Ch4)
- `art/object/forest/topo árvore normal.png` (93×98) — green tree canopy
- `art/object/forest/topo árvore redonda.png` (100×84) — round canopy
- `art/object/forest/cogumelo fofinho.png` (31×33) — cute mushroom
- `art/object/forest/pedras perdidas.png` (34×32) — rocks
- `art/object/forest/folhas de outono.png` (127×64) — autumn leaves

### Mountain/Castle (Ch2)
- `art/object/mountain/back_mountain.png` (512×448) — mountain bg
- `art/object/mountain/top_mountain.png` (960×256) — mountain top strip
- `art/object/mountain/bridge_back.png` (512×68) — bridge
- `art/object/mountain/rock.png` (128×96) — rocks
- `art/object/mountain/sakura.png` (122×130) — sakura tree

### Desert/Train (Ch3)
- `art/object/desert/cactus.png` (23×60) — cactus
- `art/object/desert/cactus_2.png` (68×129) — big cactus
- `art/object/desert/skull.png` (86×64) — skull
- `art/object/desert/pyramid.png` (1073×585) — pyramid (use small scale)

### Beach/Graph (Ch5)
- `art/object/beach/boat.png` (129×65) — boat
- `art/object/beach/tree.png` (98×130) — palm tree
- `art/object/beach/water.png` (160×191) — water tile
- `art/object/beach/fish_1.png` (58×56) — fish decoration

### General
- `art/object/bush_01.png` (96×16) — bush row
- `art/object/tree_01.png` (76×91) — generic tree
- `art/object/portal.png` (32×32) — portal / warp point
- `art/object/notebook.png` (96×64) — notebook (tutorial hint)
- `art/object/computer.png` (260×223) — computer terminal

---

## Parallax Backgrounds
- `art/parallax/parallax-mountain-bg.png` — mountain skyline (use for Ch2, WorldMap near Ch4)
- `art/parallax/desert.png` — desert sky (use for Ch3 background)

---

## Fonts
- `font/freepixel.ttf` — pixel font, use for all game text at 2× scale
- `font/text.tres` — Godot FontFile resource wrapping freepixel
- `font/title.tres` — larger title variant
- `font/actor.tres` — dialogue actor name font

**To use pixel font in Godot:**
```gdscript
var font: Font = load("res://assets/codemon/font/freepixel.ttf")
label.add_theme_font_override("font", font)
label.add_theme_font_size_override("font_size", 16)
```

---

## Audio Bus Layout
`audio_layout.tres` — codemon's existing bus layout with Music + SFX buses.
Already referenced in `project.godot`.

---

## Quick integration checklist

- [ ] `AssetMap.gd` added to autoloads — done ✓
- [ ] `SpriteHelper.gd` added to autoloads — done ✓
- [ ] `audio_layout.tres` pointing to codemon file — done ✓
- [ ] Ch1: CitizenNode → `_apply_codemon_sprite()`
- [ ] Ch1: World.gd → `_apply_world_art()` (street tile)
- [ ] Ch2: RuneNode → `_draw_with_codemon()`
- [ ] Ch2: CastleWorld → `_apply_world_art()` (mountain)
- [ ] Ch3: CarriageNode → `_apply_codemon_icon()`
- [ ] Ch3: TrainWorld → `_apply_world_art()` (desert)
- [ ] Ch4: TreeNodeVisual → `_draw_codemon_face()`
- [ ] Ch4: ForestWorld → `_apply_world_art()` (forest)
- [ ] Ch5: CityNode → `_draw_codemon_face()`
- [ ] Ch5: KingdomWorld → `_apply_world_art()` (beach)
- [ ] Cutscene → add `CutsceneVisual` child, call `update_speaker()`
- [ ] WorldMap → add `WorldMapVisual` child, call `setup()`
- [ ] All screens → replace `Button.new()` with `SpriteHelper.make_styled_button()`
