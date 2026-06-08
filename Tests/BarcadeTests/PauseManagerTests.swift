import XCTest
@testable import Barcade

@MainActor
final class PauseManagerTests: XCTestCase {
    func testFocusLossAndRegainPauseAndResumeOnce() {
        let game = PauseTestGame()
        let manager = PauseManager()
        manager.activate(game)

        manager.focusLost()
        manager.focusLost()
        manager.focusRegained()
        manager.focusRegained()

        XCTAssertEqual(game.pauseCount, 1)
        XCTAssertEqual(game.resumeCount, 1)
        XCTAssertFalse(manager.isPaused)
    }

    func testFocusRegainDoesNothingWithoutActiveGame() {
        let manager = PauseManager()

        manager.focusLost()
        manager.focusRegained()

        XCTAssertFalse(manager.isPaused)
    }
}

private final class PauseTestGame: BarcadeGame {
    let title = "Test"
    let id = "test"
    private(set) var currentScore = 0
    private(set) var pauseCount = 0
    private(set) var resumeCount = 0

    func start() {}

    func pause() {
        pauseCount += 1
    }

    func resume() {
        resumeCount += 1
    }

    func reset() {}
}
