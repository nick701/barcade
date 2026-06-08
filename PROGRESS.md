# Barcade Progress

## Checkpoint 1 - App scaffold

- Added the Xcode app and test targets plus a Swift Package manifest.
- Added the SwiftUI entry point, AppDelegate, NSStatusItem, NSPopover, and frozen BarcadeGame protocol.
- Configured LSUIElement so Barcade runs without a Dock icon.
- Added the project-local build/run script and Codex Run action.
- Verified `swift build`, `swift test`, and a warning-free `xcodebuild build`.
- Verified the built app launches and its generated Info.plist contains `LSUIElement = true`.
