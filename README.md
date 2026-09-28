# PlayHub (GameCenter)

An iOS game hub built with SwiftUI. It bundles three mini-games behind a
four-tab app shell, and tracks your scores, stats and where you played.

**Games:** Tap Frenzy · Light It Up · Quiz Rush
**Tabs:** Home · Stats · Map · Settings

## Games

### Tap Frenzy
A 30-second reflex game. A ball appears at a random position on screen and
jumps somewhere else every time you tap it. Each tap scores a point. Your best
score is remembered between launches.

### Light It Up
A 60-second whack-a-mole style game that gets harder as the round goes on.
Cards appear in a grid and one lights up briefly. Tap it before it goes dark.

| Level | Time | Cards | Lit window |
|-------|------|-------|------------|
| L1 | 0–15 s | 3 (row) | 1.5 s |
| L2 | 15–30 s | 4 | 1.2 s |
| L3 | 30–45 s | 6 (2 × 3) | 1.0 s |
| L4 | 45 s – end | 9 (3 × 3), 2 lit at once | 0.8 s |

Correct tap: +10. Wrong tap or a missed (timed-out) card: -5. Each level has
its own glow colour and there is a level-up flash when the level changes.

### Quiz Rush
Ten multiple-choice trivia questions fetched live from the
[Open Trivia DB](https://opentdb.com) API.

- Correct answer: +10, plus a growing bonus for consecutive correct answers (streak)
- Wrong answer: -3 and the streak resets, but you still move on
- Loading state while fetching, and an error state with a Retry button if the network fails
- Green flash on a correct answer, shake on a wrong one
- Enter your name at the end to save your score to the Quiz Rush leaderboard

## Features

- **Tab bar app shell** with Home, Stats, Map and Settings. Each tab has its own `NavigationStack`.
- **Local score history** for every game, saved automatically when a round ends. Each game has a History screen showing rounds played, best, average, and every round with a star on your best.
- **Share your score** from the game-over screen using the system share sheet, e.g. "I just scored 47 on Quiz Rush — beat that."
- **Combined Scoreboard** that merges all three games into one ranked list, with a mode filter, personal bests per game, and Clear All.
- **Stats tab** showing total games played, total marks, personal bests, and a bar chart of score history per game (Swift Charts).
- **Map tab** showing a pin for each round played, tagged with your location at the time (MapKit + Core Location). Tap a pin to see that round's game, score and time.
- **Daily challenge reminder** using local notifications. Turn it on in Settings and pick a time.
- **Settings** with the notifications toggle, reminder time picker, and Reset All Stats behind a confirmation dialog.

## Requirements

- Xcode 15 or later
- iOS 17 or later (the Map tab uses the iOS 17 `Map(position:)` API)
- Internet connection for Quiz Rush only

## Setup

1. Open the project in Xcode and add all `.swift` files to the app target.
2. **Add the location permission text to Info.plist** (required, otherwise the
   permission prompt never appears and the Map tab stays empty):
   - Key: `Privacy - Location When In Use Usage Description`
   - Value: e.g. "PlayHub tags each completed round with your location so you can see it on the Map tab."
3. Local notifications need no Info.plist key. The permission prompt appears the first time you enable the daily reminder in Settings.
4. If testing in the iOS Simulator, set a location first:
   **Features → Location → Apple** (or a custom location). The simulator has no GPS by default.
5. Build and run.

## Architecture

The app follows MVVM. Game logic lives in ViewModels (or engines), views only
render state, and persistence is handled by small store types.

```
Models        GameMode, Card, GameLevel, TriviaQuestion,
              score records (one per game), LeaderboardEntry,
              CombinedScoreRecord
ViewModels    Light It Up engine, Quiz Rush ViewModel, Stats ViewModel
Services      LocationService, NotificationService, TriviaAPI,
              local stores (TapFrenzyLocalStore, LightItUpLocalStore,
              LeaderboardStore)
Views         Tabs: HomeTab, StatsTab, MapTab, SettingsTab
              Games: Tap Frenzy, Light It Up, Quiz Rush + a History view each
              Shared: ScoreboardView, score badge
```

### How a finished round is saved

1. The game ends (timer hits zero, or question 10 is answered).
2. The game's store saves a record: score, date, and the current latitude and
   longitude from `LocationService` if available.
3. The record is encoded as JSON and stored in `UserDefaults`.
4. `CombinedScoreboard.loadAll()` reads all three stores and merges them into
   `CombinedScoreRecord` values. The **Scoreboard**, **Stats** and **Map** screens all read from this one merged source, so they always agree with each other.

### Why the stores are separate

Tap Frenzy and Light It Up save plain score records. Quiz Rush saves a named
entry because it has a leaderboard. Keeping the three stores independent meant
adding a new feature to one game never risked breaking the others, and the
merge step in `CombinedScoreboard` is the only place that knows about all three.

### Quiz Rush data flow

`TriviaAPI` fetches and decodes the JSON into `TriviaQuestion` values (HTML
entities like `&quot;` are decoded once at parse time). The ViewModel exposes a
`QuizState` enum (`loading`, `loaded`, `failed`), and the view is just a
`switch` over that state, so all fetching, scoring and streak logic stays out
of the view.

## Known limitations

- **Location is best-effort.** If a round ends before Core Location has a fix, or permission was denied, that round is saved without a location and will not appear on the Map. Rounds saved before location capture was added also have no pin.
- **Location only updates while the app is open.** There is no background location.
- **Scores are stored locally only.** Nothing syncs between devices and everything is lost if the app is deleted. The "leaderboard" is a personal one on this device, not a global one.
- **Stats and Map read from `UserDefaults` when the tab appears**, so they refresh on tab switch rather than updating live while you are looking at them.
- **The daily reminder is a single fixed message** at a chosen time, not a unique daily challenge.
- **Quiz Rush needs internet.** With no connection it shows the error state and a Retry button.
- **Reset All Stats cannot be undone.** It is all-or-nothing, with no per-game reset.
- **Tap Frenzy round length and Light It Up levels are fixed** in code, not configurable in Settings.
