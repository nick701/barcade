import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSPopoverDelegate, NSWindowDelegate {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let pauseManager = PauseManager()
    private let shortcutManager = GlobalShortcutManager()
    private var settingsStore: SettingsStore?
    private var scoreStore: ScoreStore?
    private var floatingWindow: NSWindow?
    private var subscriptions: Set<AnyCancellable> = []

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
            button.action = #selector(togglePresentation)
        }

        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentSize = NSSize(width: 460, height: 600)

        let rootView: AnyView
        do {
            let settingsStore = try SettingsStore()
            let scoreStore = try ScoreStore()
            self.settingsStore = settingsStore
            self.scoreStore = scoreStore
            rootView = AnyView(
                RootView(
                    settingsStore: settingsStore,
                    scoreStore: scoreStore,
                    pauseManager: pauseManager
                )
            )
            configurePlatformFeatures(settingsStore: settingsStore)
        } catch {
            rootView = AnyView(StorageErrorView(error: error))
        }
        popover.contentViewController = NSHostingController(rootView: rootView)
    }

    @objc private func togglePresentation() {
        if let floatingWindow {
            if floatingWindow.isVisible {
                floatingWindow.orderOut(nil)
                pauseManager.focusLost()
            } else {
                floatingWindow.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                pauseManager.observe(window: floatingWindow)
                pauseManager.focusRegained()
            }
            return
        }

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

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        pauseManager.focusLost()
        return false
    }

    private func configurePlatformFeatures(settingsStore: SettingsStore) {
        try? LaunchAtLoginManager.setEnabled(
            settingsStore.settings.launchAtLogin
        )

        settingsStore.$settings
            .map(\.shortcut)
            .removeDuplicates()
            .sink { [weak self] shortcut in
                guard let self else {
                    return
                }
                shortcutManager.register(shortcut: shortcut) { [weak self] in
                    self?.togglePresentation()
                }
            }
            .store(in: &subscriptions)

        settingsStore.$settings
            .map(\.floatingWindow)
            .removeDuplicates()
            .sink { [weak self] enabled in
                DispatchQueue.main.async {
                    self?.setFloatingWindow(enabled)
                }
            }
            .store(in: &subscriptions)
    }

    private func setFloatingWindow(_ enabled: Bool) {
        if enabled {
            guard floatingWindow == nil,
                  let contentController = popover.contentViewController else {
                return
            }

            if popover.isShown {
                popover.performClose(nil)
            }
            popover.contentViewController = nil

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 460, height: 600),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Barcade"
            window.level = .floating
            window.isReleasedWhenClosed = false
            window.contentViewController = contentController
            window.delegate = self
            window.center()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            floatingWindow = window
            pauseManager.observe(window: window)
            pauseManager.focusRegained()
        } else if let floatingWindow {
            let contentController = floatingWindow.contentViewController
            floatingWindow.contentViewController = nil
            floatingWindow.delegate = nil
            floatingWindow.orderOut(nil)
            popover.contentViewController = contentController
            self.floatingWindow = nil
            pauseManager.observe(window: nil)
        }
    }
}
