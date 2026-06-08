import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSPopoverDelegate {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let pauseManager = PauseManager()

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        popover = NSPopover()
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "gamecontroller.fill",
                accessibilityDescription: "Barcade"
            )
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(togglePopover)
        }

        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentSize = NSSize(width: 460, height: 600)

        let rootView: AnyView
        do {
            let settingsStore = try SettingsStore()
            let scoreStore = try ScoreStore()
            rootView = AnyView(
                RootView(
                    settingsStore: settingsStore,
                    scoreStore: scoreStore,
                    pauseManager: pauseManager
                )
            )
        } catch {
            rootView = AnyView(StorageErrorView(error: error))
        }
        popover.contentViewController = NSHostingController(rootView: rootView)
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            pauseManager.observe(window: popover.contentViewController?.view.window)
        }
    }

    func popoverWillShow(_ notification: Notification) {
        pauseManager.focusRegained()
    }

    func popoverDidClose(_ notification: Notification) {
        pauseManager.focusLost()
    }
}
