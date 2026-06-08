import AppKit
import Foundation

@MainActor
final class PauseManager: ObservableObject {
    @Published private(set) var isPaused = false

    private var activeGame: (any BarcadeGame)?
    private weak var observedWindow: NSWindow?
    private var notificationTokens: [NSObjectProtocol] = []

    func activate(_ game: any BarcadeGame) {
        activeGame = game
        isPaused = false
    }

    func deactivate() {
        activeGame = nil
        isPaused = false
    }

    func focusLost() {
        guard !isPaused, let activeGame else {
            return
        }
        activeGame.pause()
        isPaused = true
    }

    func focusRegained() {
        guard isPaused, let activeGame else {
            return
        }
        activeGame.resume()
        isPaused = false
    }

    func observe(window: NSWindow?) {
        guard observedWindow !== window else {
            return
        }

        stopObservingWindow()
        observedWindow = window

        guard let window else {
            return
        }

        let center = NotificationCenter.default
        notificationTokens = [
            center.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.focusLost()
                }
            },
            center.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.focusRegained()
                }
            }
        ]
    }

    private func stopObservingWindow() {
        let center = NotificationCenter.default
        notificationTokens.forEach(center.removeObserver)
        notificationTokens.removeAll()
        observedWindow = nil
    }
}
