# Barcade Progress

## Checkpoint 1 - App scaffold

- Added the Xcode app and test targets plus a Swift Package manifest.
- Added the SwiftUI entry point, AppDelegate, NSStatusItem, NSPopover, and frozen BarcadeGame protocol.
- Configured LSUIElement so Barcade runs without a Dock icon.
- Added the project-local build/run script and Codex Run action.
- Verified `swift build`, `swift test`, and a warning-free `xcodebuild build`.
- Verified the built app launches and its generated Info.plist contains `LSUIElement = true`.

## Checkpoint 2 - JSON persistence

- Added `SettingsStore` with plan-defined defaults and atomic JSON persistence.
- Added persisted game order, enabled games, launch preference, shortcut, window mode, onboarding state, and per-game settings.
- Added `ScoreStore` with ISO-8601 timestamps, top-five score retention, and per-game/global resets.
- Default storage is `~/.config/barcade/settings.json` and `~/.config/barcade/scores.json`.
- Added injected storage directories for isolated tests.
- Verified four store tests pass with SwiftPM and Xcode; Xcode test output has zero warnings.

## Checkpoint 3 - Picker, scores, and settings

- Replaced the placeholder popover with Games, Scores, and Settings sections.
- Added the enabled-game picker grid in persisted user order.
- Added top-five score lists with timestamps.
- Added game toggles, drag-to-reorder support, Snake/Minesweeper/Sudoku settings, and score resets.
- Wired both stores into app startup with a visible storage error state.
- Verified a real launch creates both JSON files under `~/.config/barcade/`.
- Verified five tests pass with SwiftPM and Xcode; Xcode test output has zero warnings.

## Checkpoint 4 - Pause and resume lifecycle

- Added one shared `PauseManager` for the active `BarcadeGame`.
- Popover closure and window focus loss pause the active game immediately.
- Popover reopening and window focus regain resume only a focus-paused game.
- Duplicate focus notifications are idempotent.
- Injected the manager into the root view for game-host registration.
- Verified seven tests pass with SwiftPM and Xcode; Xcode test output has zero warnings.

## Checkpoint 5 - Fifteen playable games

- Added one shared game-session host for start, pause, resume, score recording, and teardown.
- Implemented and individually build-verified, in plan order:
  1. Snake
  2. Flappy Bird
  3. 2048
  4. Minesweeper
  5. Reaction Timer
  6. Breakout
  7. Tetris
  8. Pong vs AI
  9. Simon Says
  10. Whack-a-Mole
  11. Type Racer
  12. Tap the Dot
  13. Sudoku
  14. Asteroids
  15. Mini Billiards
- Each game has start, scoring, game-over/completion, and restart behavior.
- Each game is isolated in its own folder and conforms to the frozen `BarcadeGame` interface through `ScoredGame`.
- Reaction Timer rankings correctly treat lower millisecond values as better.
- Verified 23 tests pass with SwiftPM and Xcode; Xcode test output has zero warnings.
- Confirmed no network API usage exists in app or test sources.

## Checkpoint 6 - Native macOS integrations

- Added launch-at-login registration with `SMAppService.mainApp`.
- Added a Carbon global hotkey manager with persisted, user-editable modifier-and-key shortcuts.
- Registered the default global shortcut as `⌥G`.
- Added pin controls and persisted floating-window mode.
- Floating mode moves the existing hosting controller between `NSPopover` and `NSWindow`, preserving active game state.
- The floating window participates in the same pause/resume focus lifecycle.
- Verified a real launch with floating mode enabled creates an on-screen Barcade window, then restored the prior settings file.
- Verified 24 tests pass with SwiftPM and Xcode; Xcode test output has zero warnings.

## Checkpoint 7 - First-launch onboarding

- Added a three-step tooltip overlay for game selection, scores/settings navigation, and pin/shortcut access.
- Added Next, Skip, and Start Playing controls with visible step progress.
- Persisted completion in `settings.json`; completed onboarding does not reappear on later launches.
- Verified the first-launch state launches successfully in a floating Barcade window.
- Visual screenshot inspection was unavailable because macOS Screen Recording permission is disabled.
- Verified 25 tests pass with SwiftPM and Xcode; Xcode test output has zero warnings.

## Checkpoint 8 - Unit tests

- Added exhaustive `BarcadeGame` conformance coverage for all 15 catalog games.
- Invoked `start`, `pause`, `resume`, and `reset` for every game implementation.
- Expanded store coverage for defaults, JSON round trips, validation, top-five retention, reaction-time sorting, and resets.
- Verified 27 tests pass with SwiftPM and Xcode; Xcode test output has zero warnings.
