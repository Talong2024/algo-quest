# AlgoQuest — Asset Audit & Plagiarism Risk Register

> Last updated: 2026-03-30
> Use this document before publishing or submitting the project.
> **GREEN** = safe to use. **AMBER** = verify before use. **RED** = do not use / replace first.

---

## 🟢 Safe to Use (Confirmed Open Licenses)

### Codemon Project Assets
| Asset | Location in project | License | Source |
|---|---|---|---|
| Codemon sprites (int, bool, if, for…) | `assets/codemon/art/character/codemon/` | **MIT** | [github.com/games-on-web/codemon](https://github.com/games-on-web/codemon) |
| Map tiles (street, forest, beach, desert, mountain) | `assets/codemon/art/map/` | **MIT** | Same repo |
| NPC sprites (dr_forest, dr_beach, dr_mountain, dr_desert, dr_lab, doorman) | `assets/codemon/art/character/npc/` | **MIT** | Same repo |
| UI components (btn_normal, dialog_box, dialog_next_btn…) | `assets/codemon/art/component/` | **MIT** | Same repo |
| Logo pieces (D.png, K.png, bracket.png, codemon.png) | `assets/codemon/art/logo/` | **MIT** | Same repo |
| Jimmy player sprite | `assets/codemon/art/character/jimmy.png` | **MIT** | Same repo |
| Object sprites (cactus, boat, tree, palm…) | `assets/codemon/art/object/` | **MIT** | Same repo |
| HUD icons | `assets/codemon/art/hud/` | **MIT** | Same repo |
| BGM tracks (ch1–ch5, menu, boss) | `assets/codemon/audio/music/` | **MIT** | Same repo |
| SFX (correct, wrong, click, lose) | `assets/codemon/audio/sfx/` | **MIT** | Same repo |
| FreePixel font | `assets/codemon/font/freepixel.ttf` | **Public Domain** | Emhuo |

### LPC (Liberated Pixel Cup) Assets
| Asset | Location | License | Source / Attribution required |
|---|---|---|---|
| Female face expressions (idle) | `assets/lpc/faces/` | **CC-BY-SA 3.0 / OGA-BY 3.0** | lpc-expressions pack — credit required |
| Sleeveless shirts | `assets/lpc/shirts/` | **CC-BY-SA 3.0** | sleeveless-shirts pack — credit required |
| Socks & shoes sheets | `assets/lpc/shoes/` | **CC-BY-SA 3.0** | lpc-socks-shoes pack — credit required |
| Body sheets (16×18) | `assets/lpc/bodies/` | **CC-BY-SA 3.0** | 16x18 RPG characters pack — credit required |
| Hair sheets (16×18) | `assets/lpc/hair/` | **CC-BY-SA 3.0** | 16x18 RPG characters pack — credit required |

> ⚠️ CC-BY-SA 3.0 requires: (1) credit the original authors in your game credits, (2) if you distribute the game, the art remains under the same license. For a school/university project this is fine. For a commercial release you must list all LPC contributors.

---

## 🟡 Amber — Verify Before Publishing

| Asset | Location | Issue | Action needed |
|---|---|---|---|
| Main menu background video | `assets/video/main_menu_bg.mp4` | Generated with **PixVerse V5** AI tool. PixVerse's ToS grants usage rights to outputs but AI-generated art has unclear copyright status in some jurisdictions. | ✅ Fine for academic/personal use. For commercial release: check PixVerse ToS at time of publishing, or replace with original pixel art. |
| Parallax backgrounds (mountain.png, desert.png) | `assets/codemon/art/parallax/` | Part of Codemon (MIT) but derived from unknown upstream sources in the original repo | Verify no unlicensed third-party art was included in the Codemon repo. Check Codemon's own asset credits. |
| Tutorial images | `assets/codemon/art/tutorial/` | Not all tutorial images in Codemon have individual credits listed | Review before including in published version. |

---

## 🔴 Do Not Use / Replace Before Release

| Asset | Location | Issue | Replacement |
|---|---|---|---|
| `univali_1.png`, `univali_2.png` (university logo) | `assets/codemon/art/logo/` | **University branding** — UNIVALI's institutional logo. Not licensed for use outside the Codemon academic project. | **Already not used** in AlgoQuest. Safe — we only use D.png, K.png, bracket.png, codemon.png. |
| Any Google Fonts or system fonts loaded at runtime | — | Default system fonts (Godot fallback) are fine. Be careful if you add web fonts. | Use FreePixel (already included) or other OFL-licensed fonts. |

---

## 📋 Required Credits (put these in your Credits screen)

```
=== ART ===

Codemon sprites, maps, UI, audio:
  Codemon project — github.com/games-on-web/codemon
  MIT License

LPC Face Expressions:
  Author: [lpc-expressions contributors on OpenGameArt.org]
  License: OGA-BY 3.0 / CC-BY-SA 3.0
  Source: opengameart.org

LPC Sleeveless Shirts:
  License: CC-BY-SA 3.0
  Source: opengameart.org

LPC Socks & Shoes:
  License: CC-BY-SA 3.0
  Source: opengameart.org

16×18 RPG Characters (bodies & hair):
  License: CC-BY-SA 3.0
  Source: opengameart.org

=== FONT ===

FreePixel by Emhuo — Public Domain

=== ENGINE ===

Godot Engine — MIT License — godotengine.org

=== VIDEO ===

Main menu background generated with PixVerse V5
```

---

## 🛡️ Safe for Academic Submission?

| Concern | Status |
|---|---|
| All code written by team | ✅ Yes — all GDScript written in this session |
| Art assets licensed | ✅ MIT / CC-BY-SA (with attribution) |
| No proprietary assets | ✅ No commercial art packs without license |
| AI video (PixVerse) | ✅ Acceptable for academic use |
| Firebase / Google services | ✅ Free tier, no redistribution concerns |
| University logo (UNIVALI) | ✅ Not included in AlgoQuest |

**Bottom line:** AlgoQuest is safe to submit as a university project and safe to put on GitHub, as long as the Credits screen lists the LPC contributors. It is also safe for non-commercial public release. For a commercial release, replace the PixVerse video with original art and confirm LPC SA compatibility with your business model.
