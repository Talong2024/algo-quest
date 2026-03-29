# Firebase Setup — AlgoQuest Sign In / Sign Up

## What gets stored

Each player has a document at `/players/{uid}` in Firestore:

```json
{
  "display_name":   "Jimmy",
  "email":          "jimmy@university.edu",
  "year":           "1st Year",
  "course":         "Computer Science",
  "character_id":   "keeper",
  "total_score":    4200,
  "chapters_done":  3,
  "created_at":     "2025-03-29 10:00:00",
  "last_played_at": "2025-03-29 14:22:00"
}
```

---

## Step 1 — Create Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project** → name it `algoquest`
3. Disable Google Analytics (optional)

---

## Step 2 — Enable Email/Password Auth

1. Left sidebar → **Authentication** → **Get started**
2. **Sign-in method** tab → **Email/Password** → Enable → Save

---

## Step 3 — Enable Firestore Database

1. Left sidebar → **Firestore Database** → **Create database**
2. Choose **Start in test mode** (for development)
3. Pick a region → **Done**

---

## Step 4 — Get your credentials

1. Project Overview (gear icon) → **Project settings**
2. Scroll to **Your apps** → click **</>** (Web app)
3. Register app → copy the config values

You need:
- `projectId`  → use as `PROJECT_ID`
- `apiKey`     → use as `API_KEY`

---

## Step 5 — Set credentials in Godot

Open `scripts/autoload/FirebaseManager.gd`:

```gdscript
const PROJECT_ID: String = "algoquest-abc12"   # your projectId
const API_KEY:    String = "AIzaSy..."          # your apiKey
```

---

## Step 6 — Firestore Security Rules (before going public)

In Firebase Console → Firestore → **Rules**, replace with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Players can only read/write their own doc
    match /players/{userId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
    // Anyone authenticated can read leaderboard
    match /players/{userId} {
      allow read: if request.auth != null;
    }
  }
}
```

---

## Querying players by course/year (example)

```javascript
// In Firebase Console → Firestore → Indexes
// Or via REST:
{
  "structuredQuery": {
    "from": [{ "collectionId": "players" }],
    "where": {
      "fieldFilter": {
        "field": { "fieldPath": "course" },
        "op": "EQUAL",
        "value": { "stringValue": "Computer Science" }
      }
    },
    "orderBy": [{ "field": { "fieldPath": "total_score" }, "direction": "DESCENDING" }]
  }
}
```

---

## Game flow diagram

```
Launch
  └─ Boot.gd
       ├─ First launch → CodemonIntro → AuthScreen
       └─ Returning    → AuthScreen

AuthScreen (Sign In / Sign Up)
  ├─ Sign Up → Firebase createUser → Firestore write
  │              → CharacterSelect → WorldMap
  ├─ Sign In → Firebase signInWithPassword → Firestore read
  │              → WorldMap (restores progress)
  └─ Play Offline → NameEntry → CharacterSelect → WorldMap

Chapter Complete
  └─ GameRouter.chapter_complete()
       └─ FirebaseManager.save_progress() → Firestore PATCH
```
