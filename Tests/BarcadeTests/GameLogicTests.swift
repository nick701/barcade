import XCTest
@testable import Barcade

@MainActor
final class GameLogicTests: XCTestCase {
    func testSnakeMovesAndGrowsWhenItEatsFood() {
        let game = SnakeGame(
            boardSize: 8,
            initialFood: GridPoint(x: 5, y: 4)
        )

        game.start()
        game.tick()

        XCTAssertEqual(game.snake.first, GridPoint(x: 5, y: 4))
        XCTAssertEqual(game.snake.count, 4)
        XCTAssertEqual(game.currentScore, 10)
    }

    func testFlappyBirdFlapMovesBirdUpward() {
        let game = FlappyGame(initialPipes: [])
        let initialY = game.birdY

        game.start()
        game.flap()
        game.tick()

        XCTAssertGreaterThan(game.birdY, initialY)
    }

    func testTwentyFortyEightMergesEachTileOnce() {
        let game = TwentyFortyEightGame(
            initialGrid: [
                2, 2, 2, 2,
                0, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 0, 0
            ],
            spawnsTilesAfterMove: false
        )

        game.start()
        game.move(.left)

        XCTAssertEqual(Array(game.grid.prefix(4)), [4, 4, 0, 0])
        XCTAssertEqual(game.currentScore, 8)
    }

    func testMinesweeperRevealsCountsAndHonorsFlags() {
        let game = MinesweeperGame(
            width: 3,
            height: 3,
            mineLocations: [0],
            protectsFirstMove: false
        )

        game.start()
        game.reveal(4)
        XCTAssertEqual(game.cells[4].adjacentMines, 1)
        XCTAssertTrue(game.cells[4].isRevealed)

        game.toggleFlag(0)
        game.reveal(0)
        XCTAssertFalse(game.isGameOver)

        game.toggleFlag(0)
        game.reveal(0)
        XCTAssertTrue(game.isGameOver)
    }

    func testReactionTimerMeasuresMillisecondsAfterReady() {
        var now = Date(timeIntervalSince1970: 1_700_000_000)
        let game = ReactionTimerGame(
            clock: { now },
            delayProvider: { 1 }
        )

        game.start()
        now = now.addingTimeInterval(1)
        game.tick()
        now = now.addingTimeInterval(0.25)
        game.tap()

        XCTAssertEqual(game.currentScore, 250)
        XCTAssertTrue(game.isGameOver)
    }

    func testBreakoutBallDestroysBrickAndScores() {
        let brick = BreakoutBrick(
            x: 0.4,
            y: 0.2,
            width: 0.2,
            height: 0.08
        )
        let game = BreakoutGame(
            bricks: [brick],
            ballPosition: GameVector(x: 0.5, y: 0.24),
            ballVelocity: GameVector(x: 0, y: 0)
        )

        game.start()
        game.tick()

        XCTAssertFalse(game.bricks[0].isActive)
        XCTAssertEqual(game.currentScore, 10)
    }

    func testTetrisLocksPieceAndClearsCompletedLine() {
        var board = Array(repeating: 0, count: 200)
        for x in 0..<8 {
            board[19 * 10 + x] = 1
        }
        let game = TetrisGame(
            board: board,
            activePiece: TetrisPiece(type: .o, rotation: 0, x: 8, y: 18)
        )

        game.start()
        game.lockCurrentPiece()

        XCTAssertEqual(game.currentScore, 100)
        XCTAssertTrue(game.board.prefix(10).allSatisfy { $0 == 0 })
    }

    func testPongAwardsPlayerPointWhenAIMisses() {
        let game = PongGame(
            ballPosition: GameVector(x: -0.01, y: 0.8),
            ballVelocity: GameVector(x: -0.01, y: 0)
        )

        game.start()
        game.tick()

        XCTAssertEqual(game.playerScore, 1)
        XCTAssertEqual(game.currentScore, 1)
    }

    func testSimonSaysAdvancesAfterCorrectSequence() {
        let game = SimonSaysGame(randomColor: { .red })

        game.start()
        game.completePresentation()
        game.press(.red)

        XCTAssertEqual(game.currentScore, 1)
        XCTAssertEqual(game.sequence, [.red, .red])
        XCTAssertFalse(game.isGameOver)
    }

    func testWhackAMoleScoresActiveHole() {
        let game = WhackAMoleGame(randomHole: { 2 })

        game.start()
        game.tick(delta: 1)
        game.whack(hole: 2)

        XCTAssertEqual(game.currentScore, 1)
        XCTAssertNil(game.activeHole)
    }

    func testTypeRacerCalculatesWPMAndAccuracy() {
        var now = Date(timeIntervalSince1970: 1_700_000_000)
        let game = TypeRacerGame(
            sentenceProvider: { "hello" },
            clock: { now }
        )

        game.start()
        now = now.addingTimeInterval(60)
        game.updateInput("hello")

        XCTAssertEqual(game.currentScore, 1)
        XCTAssertEqual(game.accuracy, 100)
        XCTAssertTrue(game.isGameOver)
    }

    func testTapTheDotScoresHitAndMovesTarget() {
        let positions = [
            GameVector(x: 0.2, y: 0.3),
            GameVector(x: 0.7, y: 0.8)
        ]
        var index = 0
        let game = TapTheDotGame(positionProvider: {
            defer { index += 1 }
            return positions[min(index, positions.count - 1)]
        })

        game.start()
        game.tap(at: GameVector(x: 0.2, y: 0.3))

        XCTAssertEqual(game.currentScore, 1)
        XCTAssertEqual(game.dotPosition, GameVector(x: 0.7, y: 0.8))
    }

    func testSudokuCompletesWhenFinalValueIsCorrect() {
        let solution = (1...9).flatMap { row in
            (0..<9).map { column in
                ((row - 1) * 3 + (row - 1) / 3 + column) % 9 + 1
            }
        }
        var puzzle = solution
        puzzle[0] = 0
        let game = SudokuGame(
            puzzle: puzzle,
            solution: solution,
            difficulty: .easy
        )

        game.start()
        game.setValue(solution[0], at: 0)

        XCTAssertTrue(game.isGameOver)
        XCTAssertGreaterThan(game.currentScore, 0)
    }

    func testAsteroidsBulletDestroysTargetAndScores() {
        let asteroids = [
            Asteroid(position: GameVector(x: 0.5, y: 0.4), velocity: GameVector(x: 0, y: 0), radius: 0.05),
            Asteroid(position: GameVector(x: 0.8, y: 0.8), velocity: GameVector(x: 0, y: 0), radius: 0.05)
        ]
        let bullet = AsteroidBullet(
            position: GameVector(x: 0.5, y: 0.4),
            velocity: GameVector(x: 0, y: 0)
        )
        let game = AsteroidsGame(asteroids: asteroids, bullets: [bullet])

        game.start()
        game.tick()

        XCTAssertEqual(game.asteroids.count, 1)
        XCTAssertEqual(game.currentScore, 100)
    }

    func testBilliardsPocketedObjectBallScoresForPlayer() {
        let balls = [
            BilliardsBall(number: 0, position: GameVector(x: 0.3, y: 0.5), isCue: true),
            BilliardsBall(number: 1, position: GameVector(x: 0.04, y: 0.04)),
            BilliardsBall(number: 2, position: GameVector(x: 0.7, y: 0.5))
        ]
        let game = BilliardsGame(balls: balls)

        game.start()
        game.tick()

        XCTAssertEqual(game.playerScore, 100)
        XCTAssertFalse(game.balls.contains { $0.number == 1 })
    }
}
