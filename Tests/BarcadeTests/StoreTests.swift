import XCTest
@testable import Barcade

@MainActor
final class StoreTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }

    func testSettingsStoreCreatesPlanDefaults() throws {
        let store = try SettingsStore(directoryURL: temporaryDirectory)

        XCTAssertEqual(
            store.settings.enabledGames,
            ["snake", "twenty-forty-eight", "minesweeper", "flappy", "reaction-timer"]
        )
        XCTAssertEqual(store.settings.gameOrder, GameCatalog.allIDs)
        XCTAssertFalse(store.settings.launchAtLogin)
        XCTAssertEqual(store.settings.shortcut, "⌥G")
    }

    func testSettingsStorePersistsMutationsAsJSON() throws {
        let store = try SettingsStore(directoryURL: temporaryDirectory)
        try store.setGameEnabled("pong", enabled: true)
        try store.setGameOrder(["pong"] + GameCatalog.allIDs.filter { $0 != "pong" })
        try store.setSnakeSpeed(.fast)
        try store.setMinesweeperGridSize(.large)
        try store.setSudokuDifficulty(.hard)

        let reloaded = try SettingsStore(directoryURL: temporaryDirectory)

        XCTAssertTrue(reloaded.settings.enabledGames.contains("pong"))
        XCTAssertEqual(reloaded.settings.gameOrder.first, "pong")
        XCTAssertEqual(reloaded.settings.snakeSpeed, .fast)
        XCTAssertEqual(reloaded.settings.minesweeperGridSize, .large)
        XCTAssertEqual(reloaded.settings.sudokuDifficulty, .hard)
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: temporaryDirectory.appendingPathComponent("settings.json").path
            )
        )
    }

    func testCatalogFiltersEnabledGamesInStoredOrder() {
        var settings = AppSettings.defaults
        settings.enabledGames = ["snake", "pong", "flappy"]
        settings.gameOrder = ["pong", "flappy", "snake"] +
            GameCatalog.allIDs.filter { !["pong", "flappy", "snake"].contains($0) }

        XCTAssertEqual(
            GameCatalog.enabledGames(for: settings).map(\.id),
            ["pong", "flappy", "snake"]
        )
    }

    func testScoreStoreKeepsTopFiveAndPersists() throws {
        let store = try ScoreStore(directoryURL: temporaryDirectory)
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

        for score in [30, 10, 60, 40, 20, 50] {
            try store.record(
                score: score,
                for: "snake",
                date: baseDate.addingTimeInterval(TimeInterval(score))
            )
        }

        XCTAssertEqual(store.scores(for: "snake").map(\.score), [60, 50, 40, 30, 20])

        let reloaded = try ScoreStore(directoryURL: temporaryDirectory)
        XCTAssertEqual(reloaded.scores(for: "snake").map(\.score), [60, 50, 40, 30, 20])
    }

    func testScoreStoreResetsOneGameOrAllGames() throws {
        let store = try ScoreStore(directoryURL: temporaryDirectory)
        try store.record(score: 10, for: "snake")
        try store.record(score: 20, for: "pong")

        try store.reset(gameID: "snake")
        XCTAssertTrue(store.scores(for: "snake").isEmpty)
        XCTAssertEqual(store.scores(for: "pong").map(\.score), [20])

        try store.resetAll()
        XCTAssertTrue(store.scores(for: "pong").isEmpty)
    }

    func testReactionTimerRanksLowerTimesFirst() throws {
        let store = try ScoreStore(directoryURL: temporaryDirectory)
        try store.record(score: 420, for: "reaction-timer")
        try store.record(score: 260, for: "reaction-timer")

        XCTAssertEqual(
            store.scores(for: "reaction-timer").map(\.score),
            [260, 420]
        )
    }

    func testGlobalShortcutParsesDefaultOptionG() {
        let definition = GlobalShortcutManager.definition(for: "⌥G")

        XCTAssertEqual(definition?.keyCode, 5)
        XCTAssertNotEqual(definition?.modifiers, 0)
    }
}
