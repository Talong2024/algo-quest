# AlgoQuest 🏰

**Learn Data Structures & Algorithms through a top-down fantasy RPG built in Godot 4.**

AlgoQuest is a complete DSA teaching game with 5 chapters, each covering a different data structure through interactive gameplay. Players explore a kingdom map, unlock chapters, and earn mastery badges by correctly applying DSA concepts.

---

## 📖 Chapters

| # | Game | Data Structure | Theme |
|---|------|---------------|-------|
| 1 | Kingdom Queue | Queue — FIFO | Castle gate, citizens |
| 2 | Castle of Echoes | Stack — LIFO | Dungeon, magic runes |
| 3 | Chain Train | Linked List | Desert railway |
| 4 | Oracle's Forest | BST / AVL / Heap | Enchanted forest |
| 5 | Kingdom Roads | Graph Algorithms (BFS, DFS, Dijkstra) | Coastal kingdom |

---

## 🚀 Getting Started

### Requirements
- [Godot Engine 4.2+](https://godotengine.org/download)

### Run the game
1. Clone the repo:
   ```bash
   git clone https://github.com/YOUR_USERNAME/algoquest.git
   cd algoquest
   ```
2. Open **Godot 4**
3. Click **Import** → select the `algoquest/` folder → open `project.godot`
4. Press **F5** or click **Play**

---

## 🏗️ Project Structure

```
algoquest/
├── project.godot              ← Godot project file
├── scenes/
│   ├── Boot.tscn              ← First scene (auto-routes)
│   ├── MainMenu.tscn
│   ├── NameEntry.tscn
│   ├── CharacterSelect.tscn   ← Choose your Code Keeper
│   ├── WorldMap.tscn          ← Kingdom hub (chapter select)
│   ├── Cutscene.tscn          ← Story scenes
│   ├── ProgressScreen.tscn    ← Achievements & stats
│   ├── Settings.tscn
│   ├── Credits.tscn
│   ├── shared/
│   │   ├── LevelComplete.tscn ← Chapter end screen
│   │   ├── GameOver.tscn
│   │   └── AchievementPopup.tscn
│   └── chapters/
│       ├── queue/             ← Kingdom Queue scenes
│       ├── stack/             ← Castle of Echoes scenes
│       ├── linked_list/       ← Chain Train scenes
│       ├── tree/              ← Oracle's Forest scenes
│       └── graph/             ← Kingdom Roads scenes
│
├── scripts/
│   ├── autoload/              ← Singleton autoloads
│   │   ├── GameRouter.gd      ← All scene navigation
│   │   ├── SaveManager.gd     ← Disk persistence
│   │   ├── ProgressTracker.gd ← Achievements, mastery, stats
│   │   ├── ScoreTracker.gd    ← Session scoring
│   │   ├── AudioManager.gd    ← BGM/SFX with fade
│   │   ├── AssetMap.gd        ← Central asset registry
│   │   └── FirebaseManager.gd ← Leaderboard (optional)
│   ├── shared/                ← Scene scripts
│   │   ├── Boot.gd, MainMenu.gd, NameEntry.gd
│   │   ├── WorldMap.gd, CharacterSelect.gd
│   │   ├── LevelComplete.gd, GameOver.gd
│   │   ├── SpriteHelper.gd    ← Sprite utilities
│   │   └── CutsceneVisual.gd  ← NPC portrait system
│   ├── Cutscene.gd            ← Dialogue engine
│   ├── ProgressScreen.gd
│   ├── WorldMap.gd
│   └── chapters/
│       ├── queue/             ← QueueManager, CitizenNode, GateKeeper...
│       ├── stack/             ← StackManager, RuneNode, SpellCaster...
│       ├── linked_list/       ← LinkedListManager, CarriageNode...
│       ├── tree/              ← BSTManager, TreeNodeVisual, TreeRenderer...
│       └── graph/             ← GraphManager, CityNode, GraphRenderer...
│
├── assets/
│   └── codemon/               ← Pixel art assets (from Codemon project)
│       ├── art/
│       │   ├── character/     ← Player (jimmy.png), NPCs, codemon sprites
│       │   ├── map/           ← Tilemap backgrounds per chapter
│       │   ├── object/        ← Environment objects (trees, rocks, etc.)
│       │   ├── component/     ← UI panels, buttons
│       │   └── hud/           ← HUD icons
│       ├── audio/
│       │   ├── music/         ← BGM per chapter
│       │   └── sfx/           ← Sound effects
│       └── font/
│           └── freepixel.ttf  ← Pixel font
│
└── docs/
    ├── HowToAddGames.md       ← How to connect chapter games
    ├── AssetIntegration.md    ← How to add sprites per chapter
    └── ChapterIntegration.md  ← Main.gd integration template
```

---

## 🎮 Features

- **5 complete DSA chapters** — Queue, Stack, Linked List, BST/AVL/Heap, Graph
- **Interactive gameplay** — click codemon sprites to perform DSA operations
- **Real tilemap backgrounds** — pixel-art environments per chapter
- **NPC characters** — animated codemon sprites as chapter guides
- **Progress tracking** — per-level stats, best scores, time, perfect clears
- **DSA mastery system** — earn mastery badges when you meet all conditions
- **13 achievements** — Perfectionist, Speed Keeper, Algorithm Master, etc.
- **Character selection** — 6 characters with chapter-specific score bonuses
- **Story cutscenes** — full dialogue system with NPC portraits
- **Firebase leaderboard** — optional online scoreboard
- **Login streak** — daily login tracking

---

## 🔧 Firebase Setup (Optional)

To enable online leaderboards:

1. Create a project at [Firebase Console](https://console.firebase.google.com)
2. Enable Firestore Database
3. Open `scripts/autoload/FirebaseManager.gd`
4. Set `const PROJECT_ID: String = "your-project-id"`

---

## 🎨 Assets

Art and audio assets are from the [Codemon](https://github.com/games-on-web/codemon) project (MIT licensed).

- Pixel sprites: codemon character art
- Tilemap backgrounds: codemon map tiles
- Music: codemon BGM tracks
- Font: FreePixel (public domain)

---

## 📄 License

MIT License — see [LICENSE](LICENSE)

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'Add my feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request
