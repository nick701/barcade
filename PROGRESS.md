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
