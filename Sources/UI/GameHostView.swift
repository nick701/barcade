import SwiftUI

struct GameHostView: View {
    let game: GameMetadata
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var scoreStore: ScoreStore
    @ObservedObject var pauseManager: PauseManager
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: onBack) {
                    Label("Games", systemImage: "chevron.left")
                }

                Spacer()

                Text(game.title)
                    .font(.headline)

                Spacer()

                Color.clear.frame(width: 70, height: 1)
            }

            gameView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(16)
    }

    @ViewBuilder
    private var gameView: some View {
        switch game.id {
        case "snake":
            GameSessionView(
                game: SnakeGame(),
                scoreStore: scoreStore,
                pauseManager: pauseManager
            ) { game in
                SnakeGameView(
                    game: game,
                    speed: settingsStore.settings.snakeSpeed
                )
            }
        case "flappy":
            GameSessionView(
                game: FlappyGame(),
                scoreStore: scoreStore,
                pauseManager: pauseManager
            ) { game in
                FlappyGameView(game: game)
            }
        case "twenty-forty-eight":
            GameSessionView(
                game: TwentyFortyEightGame(),
                scoreStore: scoreStore,
                pauseManager: pauseManager
            ) { game in
                TwentyFortyEightGameView(game: game)
            }
        case "minesweeper":
            GameSessionView(
                game: MinesweeperGame(size: settingsStore.settings.minesweeperGridSize),
                scoreStore: scoreStore,
                pauseManager: pauseManager
            ) { game in
                MinesweeperGameView(game: game)
            }
        case "reaction-timer":
            GameSessionView(
                game: ReactionTimerGame(),
                scoreStore: scoreStore,
                pauseManager: pauseManager
            ) { game in
                ReactionTimerGameView(
                    game: game,
                    scoreStore: scoreStore
                )
            }
        case "breakout":
            GameSessionView(
                game: BreakoutGame(),
                scoreStore: scoreStore,
                pauseManager: pauseManager
            ) { game in
                BreakoutGameView(game: game)
            }
        case "tetris":
            GameSessionView(
                game: TetrisGame(),
                scoreStore: scoreStore,
                pauseManager: pauseManager
            ) { game in
                TetrisGameView(game: game)
            }
        case "pong":
            GameSessionView(
                game: PongGame(),
                scoreStore: scoreStore,
                pauseManager: pauseManager
            ) { game in
                PongGameView(game: game)
            }
        case "simon-says":
            GameSessionView(
                game: SimonSaysGame(),
                scoreStore: scoreStore,
                pauseManager: pauseManager
            ) { game in
                SimonSaysGameView(game: game)
            }
        case "whack-a-mole":
            GameSessionView(
                game: WhackAMoleGame(),
                scoreStore: scoreStore,
                pauseManager: pauseManager
            ) { game in
                WhackAMoleGameView(game: game)
            }
        case "type-racer":
            GameSessionView(
                game: TypeRacerGame(),
                scoreStore: scoreStore,
                pauseManager: pauseManager
            ) { game in
                TypeRacerGameView(game: game)
            }
        case "tap-the-dot":
            GameSessionView(
                game: TapTheDotGame(),
                scoreStore: scoreStore,
                pauseManager: pauseManager
            ) { game in
                TapTheDotGameView(game: game)
            }
        case "sudoku":
            GameSessionView(
                game: SudokuGame(
                    difficulty: settingsStore.settings.sudokuDifficulty
                ),
                scoreStore: scoreStore,
                pauseManager: pauseManager
            ) { game in
                SudokuGameView(game: game)
            }
        case "asteroids":
            GameSessionView(
                game: AsteroidsGame(),
                scoreStore: scoreStore,
                pauseManager: pauseManager
            ) { game in
                AsteroidsGameView(game: game)
            }
        case "billiards":
            GameSessionView(
                game: BilliardsGame(),
                scoreStore: scoreStore,
                pauseManager: pauseManager
            ) { game in
                BilliardsGameView(game: game)
            }
        default:
            ContentUnavailableView {
                Label(game.title, systemImage: game.symbolName)
            } description: {
                Text("This game is not implemented yet.")
            }
        }
    }
}

struct GameSessionView<Game: ScoredGame, Content: View>: View {
    @StateObject private var game: Game
    @ObservedObject private var scoreStore: ScoreStore
    @ObservedObject private var pauseManager: PauseManager
    private let content: (Game) -> Content

    init(
        game: @autoclosure @escaping () -> Game,
        scoreStore: ScoreStore,
        pauseManager: PauseManager,
        @ViewBuilder content: @escaping (Game) -> Content
    ) {
        _game = StateObject(wrappedValue: game())
        _scoreStore = ObservedObject(wrappedValue: scoreStore)
        _pauseManager = ObservedObject(wrappedValue: pauseManager)
        self.content = content
    }

    var body: some View {
        content(game)
            .onAppear {
                game.start()
                pauseManager.activate(game)
            }
            .onDisappear {
                game.pause()
                pauseManager.deactivate()
            }
            .onChange(of: game.isGameOver) { _, isGameOver in
                guard isGameOver, game.currentScore > 0 else {
                    return
                }
                try? scoreStore.record(score: game.currentScore, for: game.id)
            }
    }
}
