import Foundation

enum SnakeSpeed: String, Codable, CaseIterable {
    case slow
    case medium
    case fast
}

enum MinesweeperGridSize: String, Codable, CaseIterable {
    case small
    case medium
    case large
}

enum SudokuDifficulty: String, Codable, CaseIterable {
    case easy
    case medium
    case hard
}

struct AppSettings: Codable, Equatable {
    var enabledGames: [String]
    var gameOrder: [String]
    var launchAtLogin: Bool
    var shortcut: String
    var snakeSpeed: SnakeSpeed
    var minesweeperGridSize: MinesweeperGridSize
    var sudokuDifficulty: SudokuDifficulty
    var floatingWindow: Bool
    var hasCompletedOnboarding: Bool

    static let defaults = AppSettings(
        enabledGames: [
            "snake",
            "twenty-forty-eight",
            "minesweeper",
            "flappy",
            "reaction-timer"
        ],
        gameOrder: GameCatalog.allIDs,
        launchAtLogin: false,
        shortcut: "⌥G",
        snakeSpeed: .medium,
        minesweeperGridSize: .small,
        sudokuDifficulty: .easy,
        floatingWindow: false,
        hasCompletedOnboarding: false
    )
}

enum SettingsStoreError: Error {
    case unknownGame(String)
    case invalidGameOrder
}

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var settings: AppSettings

    private let fileURL: URL

    init(directoryURL: URL? = nil) throws {
        let directoryURL = directoryURL ?? Self.defaultDirectoryURL
        fileURL = directoryURL.appendingPathComponent("settings.json")

        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        if FileManager.default.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            settings = try JSONDecoder().decode(AppSettings.self, from: data)
        } else {
            settings = .defaults
            try persist()
        }
    }

    func setGameEnabled(_ gameID: String, enabled: Bool) throws {
        guard GameCatalog.allIDs.contains(gameID) else {
            throw SettingsStoreError.unknownGame(gameID)
        }

        if enabled {
            if !settings.enabledGames.contains(gameID) {
                settings.enabledGames.append(gameID)
            }
        } else {
            settings.enabledGames.removeAll { $0 == gameID }
        }
        try persist()
    }

    func setGameOrder(_ order: [String]) throws {
        guard order.count == GameCatalog.allIDs.count,
              Set(order) == Set(GameCatalog.allIDs) else {
            throw SettingsStoreError.invalidGameOrder
        }
        settings.gameOrder = order
        try persist()
    }

    func setLaunchAtLogin(_ enabled: Bool) throws {
        settings.launchAtLogin = enabled
        try persist()
    }

    func setShortcut(_ shortcut: String) throws {
        settings.shortcut = shortcut
        try persist()
    }

    func setSnakeSpeed(_ speed: SnakeSpeed) throws {
        settings.snakeSpeed = speed
        try persist()
    }

    func setMinesweeperGridSize(_ size: MinesweeperGridSize) throws {
        settings.minesweeperGridSize = size
        try persist()
    }

    func setSudokuDifficulty(_ difficulty: SudokuDifficulty) throws {
        settings.sudokuDifficulty = difficulty
        try persist()
    }

    func setFloatingWindow(_ enabled: Bool) throws {
        settings.floatingWindow = enabled
        try persist()
    }

    func setOnboardingCompleted(_ completed: Bool) throws {
        settings.hasCompletedOnboarding = completed
        try persist()
    }

    private func persist() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(settings)
        try data.write(to: fileURL, options: .atomic)
    }

    private static var defaultDirectoryURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("barcade", isDirectory: true)
    }
}
