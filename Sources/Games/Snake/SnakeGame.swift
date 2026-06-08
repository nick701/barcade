import Combine
import SwiftUI

struct GridPoint: Hashable {
    var x: Int
    var y: Int
}

enum SnakeDirection {
    case up
    case down
    case left
    case right

    var offset: GridPoint {
        switch self {
        case .up: GridPoint(x: 0, y: -1)
        case .down: GridPoint(x: 0, y: 1)
        case .left: GridPoint(x: -1, y: 0)
        case .right: GridPoint(x: 1, y: 0)
        }
    }

    func isOpposite(of other: SnakeDirection) -> Bool {
        switch (self, other) {
        case (.up, .down), (.down, .up), (.left, .right), (.right, .left):
            true
        default:
            false
        }
    }
}

final class SnakeGame: ScoredGame {
    let title = "Snake"
    let id = "snake"
    let boardSize: Int

    @Published private(set) var snake: [GridPoint] = []
    @Published private(set) var food = GridPoint(x: 0, y: 0)
    @Published private(set) var isGameOver = false
    @Published private(set) var currentScore = 0

    private var direction = SnakeDirection.right
    private var isRunning = false
    private let initialFood: GridPoint?

    init(boardSize: Int = 18, initialFood: GridPoint? = nil) {
        self.boardSize = boardSize
        self.initialFood = initialFood
        configureBoard()
    }

    func start() {
        guard !isGameOver else {
            return
        }
        isRunning = true
    }

    func pause() {
        isRunning = false
    }

    func resume() {
        guard !isGameOver else {
            return
        }
        isRunning = true
    }

    func reset() {
        currentScore = 0
        isGameOver = false
        direction = .right
        configureBoard()
        isRunning = true
    }

    func changeDirection(_ newDirection: SnakeDirection) {
        guard !newDirection.isOpposite(of: direction) else {
            return
        }
        direction = newDirection
    }

    func tick() {
        guard isRunning, let head = snake.first else {
            return
        }

        let offset = direction.offset
        let next = GridPoint(x: head.x + offset.x, y: head.y + offset.y)
        let hitWall = next.x < 0 || next.y < 0 ||
            next.x >= boardSize || next.y >= boardSize

        if hitWall || snake.dropLast().contains(next) {
            isRunning = false
            isGameOver = true
            return
        }

        snake.insert(next, at: 0)
        if next == food {
            currentScore += 10
            spawnFood()
        } else {
            snake.removeLast()
        }
    }

    private func configureBoard() {
        let center = boardSize / 2
        snake = [
            GridPoint(x: center, y: center),
            GridPoint(x: center - 1, y: center),
            GridPoint(x: center - 2, y: center)
        ]
        food = initialFood ?? randomAvailablePoint()
    }

    private func spawnFood() {
        food = randomAvailablePoint()
    }

    private func randomAvailablePoint() -> GridPoint {
        let available = (0..<boardSize).flatMap { y in
            (0..<boardSize).map { x in GridPoint(x: x, y: y) }
        }.filter { !snake.contains($0) }
        return available.randomElement() ?? GridPoint(x: 0, y: 0)
    }
}

struct SnakeGameView: View {
    @ObservedObject var game: SnakeGame
    let speed: SnakeSpeed

    @FocusState private var hasKeyboardFocus: Bool

    private var tickInterval: TimeInterval {
        switch speed {
        case .slow: 0.22
        case .medium: 0.14
        case .fast: 0.08
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Score \(game.currentScore)")
                    .font(.headline.monospacedDigit())
                Spacer()
                Text(speed.rawValue.capitalized)
                    .foregroundStyle(.secondary)
            }

            SnakeBoard(game: game)

            controls

            if game.isGameOver {
                Button("Play Again") {
                    game.reset()
                    hasKeyboardFocus = true
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("Arrow keys to steer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .focusable()
        .focused($hasKeyboardFocus)
        .onAppear { hasKeyboardFocus = true }
        .onReceive(
            Timer.publish(every: tickInterval, on: .main, in: .common).autoconnect()
        ) { _ in
            game.tick()
        }
        .onKeyPress(.upArrow) {
            game.changeDirection(.up)
            return .handled
        }
        .onKeyPress(.downArrow) {
            game.changeDirection(.down)
            return .handled
        }
        .onKeyPress(.leftArrow) {
            game.changeDirection(.left)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            game.changeDirection(.right)
            return .handled
        }
    }

    private var controls: some View {
        VStack(spacing: 4) {
            Button {
                game.changeDirection(.up)
            } label: {
                Image(systemName: "arrow.up")
            }

            HStack(spacing: 24) {
                Button {
                    game.changeDirection(.left)
                } label: {
                    Image(systemName: "arrow.left")
                }

                Button {
                    game.changeDirection(.down)
                } label: {
                    Image(systemName: "arrow.down")
                }

                Button {
                    game.changeDirection(.right)
                } label: {
                    Image(systemName: "arrow.right")
                }
            }
        }
        .buttonStyle(.bordered)
    }
}

private struct SnakeBoard: View {
    @ObservedObject var game: SnakeGame

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let cell = side / CGFloat(game.boardSize)

            Canvas { context, _ in
                for point in game.snake {
                    let rect = CGRect(
                        x: CGFloat(point.x) * cell,
                        y: CGFloat(point.y) * cell,
                        width: cell - 1,
                        height: cell - 1
                    )
                    context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(.green))
                }

                let foodRect = CGRect(
                    x: CGFloat(game.food.x) * cell,
                    y: CGFloat(game.food.y) * cell,
                    width: cell - 1,
                    height: cell - 1
                )
                context.fill(Path(ellipseIn: foodRect), with: .color(.red))
            }
            .frame(width: side, height: side)
            .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                if game.isGameOver {
                    Text("Game Over")
                        .font(.title.bold())
                        .padding()
                        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
