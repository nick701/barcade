import XCTest
@testable import Barcade

@MainActor
final class GameProtocolTests: XCTestCase {
    func testAllCatalogGamesConformToFrozenProtocol() {
        let games: [any BarcadeGame] = [
            SnakeGame(),
            FlappyGame(),
            TwentyFortyEightGame(),
            MinesweeperGame(size: .small),
            ReactionTimerGame(),
            BreakoutGame(),
            TetrisGame(),
            PongGame(),
            SimonSaysGame(),
            WhackAMoleGame(),
            TypeRacerGame(),
            TapTheDotGame(),
            SudokuGame(difficulty: .easy),
            AsteroidsGame(),
            BilliardsGame()
        ]

        XCTAssertEqual(games.count, 15)
        XCTAssertEqual(Set(games.map(\.id)), Set(GameCatalog.allIDs))
        XCTAssertEqual(Set(games.map(\.id)).count, games.count)

        for game in games {
            XCTAssertFalse(game.title.isEmpty)
            game.start()
            game.pause()
            game.resume()
            game.reset()
            XCTAssertGreaterThanOrEqual(game.currentScore, 0)
        }
    }
}
