# Chapter Integration Guide

How to connect each chapter's Main.gd to GameRouter.
These are copy-paste snippets — not a runnable script.

---

## 3 changes per chapter

### 1. Add CHAPTER_ID at the top
```gdscript
const CHAPTER_ID: int = 1  # 1=queue 2=stack 3=list 4=tree 5=graph
```

### 2. Replace `_on_level_complete()`
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

### 3. Replace `_on_game_over()`
```gdscript
func _on_game_over() -> void:
    AudioManager.play_sfx("lose")
    GameRouter.go_game_over(CHAPTER_ID)
```

### 4. Delete these (GameRouter handles them now)
```
func _on_next()  -> void: ...   # DELETE
func _on_retry() -> void: ...   # DELETE
func _on_menu()  -> void: ...   # DELETE
```

### 5. Update scene path constants
```gdscript
# Example for queue chapter:
const TUTORIAL_SCENE: String = "res://scenes/chapters/queue/Tutorial.tscn"
const GAME_SCENE:     String = "res://scenes/chapters/queue/Game.tscn"
# Remove LevelComplete constant — GameRouter loads the shared one
```

---

## Chapter ID map
| ID | Game |
|---|---|
| 1 | Kingdom Queue |
| 2 | Castle of Echoes |
| 3 | Chain Train |
| 4 | Oracle's Forest |
| 5 | Kingdom Roads |
