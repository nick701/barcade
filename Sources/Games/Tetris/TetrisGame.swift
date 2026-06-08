import Combine
import SwiftUI

enum Tetromino: Int, CaseIterable {
    case i = 1
    case o
    case t
    case s
    case z
    case j
    case l

    var basePoints: [GridPoint] {
        switch self {
        case .i:
            [
                GridPoint(x: 0, y: 1),
                GridPoint(x: 1, y: 1),
                GridPoint(x: 2, y: 1),
                GridPoint(x: 3, y: 1)
            ]
        case .o:
            [
                GridPoint(x: 0, y: 0),
                GridPoint(x: 1, y: 0),
                GridPoint(x: 0, y: 1),
                GridPoint(x: 1, y: 1)
            ]
        case .t:
            [
                GridPoint(x: 1, y: 0),
                GridPoint(x: 0, y: 1),
                GridPoint(x: 1, y: 1),
                GridPoint(x: 2, y: 1)
            ]
        case .s:
            [
                GridPoint(x: 1, y: 0),
                GridPoint(x: 2, y: 0),
                GridPoint(x: 0, y: 1),
                GridPoint(x: 1, y: 1)
            ]
        case .z:
            [
                GridPoint(x: 0, y: 0),
                GridPoint(x: 1, y: 0),
                GridPoint(x: 1, y: 1),
                GridPoint(x: 2, y: 1)
            ]
        case .j:
            [
                GridPoint(x: 0, y: 0),
                GridPoint(x: 0, y: 1),
                GridPoint(x: 1, y: 1),
                GridPoint(x: 2, y: 1)
            ]
        case .l:
            [
                GridPoint(x: 2, y: 0),
                GridPoint(x: 0, y: 1),
                GridPoint(x: 1, y: 1),
                GridPoint(x: 2, y: 1)
            ]
        }
    }
}

struct TetrisPiece: Equatable {
    var type: Tetromino
    var rotation: Int
    var x: Int
    var y: Int

    var points: [GridPoint] {
        guard type != .o else {
            return type.basePoints
        }

        var points = type.basePoints
        for _ in 0..<(rotation % 4) {
            points = points.map { point in
                GridPoint(x: 3 - point.y, y: point.x)
            }
        }
        return points
    }
}

final class TetrisGame: ScoredGame {
    let title = "Tetris"
    let id = "tetris"
    let width = 10
    let height = 20

    @Published private(set) var board: [Int]
    @Published private(set) var activePiece: TetrisPiece
    @Published private(set) var currentScore = 0
    @Published private(set) var isGameOver = false

    private var isRunning = false

    init(
        board: [Int]? = nil,
        activePiece: TetrisPiece? = nil
    ) {
        self.board = board ?? Array(repeating: 0, count: 200)
        self.activePiece = activePiece ?? Self.randomPiece()
    }

    func start() {
        isRunning = !isGameOver
    }

    func pause() {
        isRunning = false
    }

    func resume() {
        isRunning = !isGameOver
    }

    func reset() {
        board = Array(repeating: 0, count: width * height)
        activePiece = Self.randomPiece()
        currentScore = 0
        isGameOver = false
        isRunning = true
    }

    func tick() {
        guard isRunning else {
            return
        }
        if canPlace(activePiece, offsetX: 0, offsetY: 1) {
            activePiece.y += 1
        } else {
            lockCurrentPiece()
        }
    }

    func moveHorizontal(_ amount: Int) {
        guard isRunning, canPlace(activePiece, offsetX: amount, offsetY: 0) else {
            return
        }
        activePiece.x += amount
    }

    func softDrop() {
        tick()
    }

    func hardDrop() {
        guard isRunning else {
            return
        }
        while canPlace(activePiece, offsetX: 0, offsetY: 1) {
            activePiece.y += 1
            currentScore += 1
        }
        lockCurrentPiece()
    }

    func rotate() {
        guard isRunning else {
            return
        }
        var rotated = activePiece
        rotated.rotation = (rotated.rotation + 1) % 4

        for kick in [0, -1, 1, -2, 2] {
            if canPlace(rotated, offsetX: kick, offsetY: 0) {
                rotated.x += kick
                activePiece = rotated
                return
            }
        }
    }

    func lockCurrentPiece() {
        for point in absolutePoints(for: activePiece) {
            guard point.y >= 0,
                  point.y < height,
                  point.x >= 0,
                  point.x < width else {
                continue
            }
            board[point.y * width + point.x] = activePiece.type.rawValue
        }

        clearCompletedLines()
        activePiece = Self.randomPiece()

        if !canPlace(activePiece, offsetX: 0, offsetY: 0) {
            isRunning = false
            isGameOver = true
        }
    }

    private func canPlace(
        _ piece: TetrisPiece,
        offsetX: Int,
        offsetY: Int
    ) -> Bool {
        absolutePoints(for: piece).allSatisfy { point in
            let x = point.x + offsetX
            let y = point.y + offsetY
            guard x >= 0, x < width, y < height else {
                return false
            }
            return y < 0 || board[y * width + x] == 0
        }
    }

    private func absolutePoints(for piece: TetrisPiece) -> [GridPoint] {
        piece.points.map {
            GridPoint(x: piece.x + $0.x, y: piece.y + $0.y)
        }
    }

    private func clearCompletedLines() {
        var rows = (0..<height).map { y in
            Array(board[(y * width)..<(y * width + width)])
        }
        let remaining = rows.filter { !$0.allSatisfy { $0 != 0 } }
        let cleared = height - remaining.count
        guard cleared > 0 else {
            return
        }

        rows = Array(
            repeating: Array(repeating: 0, count: width),
            count: cleared
        ) + remaining
        board = rows.flatMap { $0 }

        let lineScore = switch cleared {
        case 1: 100
        case 2: 300
        case 3: 500
        default: 800
        }
        currentScore += lineScore
    }

    private static func randomPiece() -> TetrisPiece {
        TetrisPiece(
            type: Tetromino.allCases.randomElement() ?? .t,
            rotation: 0,
            x: 3,
            y: 0
        )
    }
}

struct TetrisGameView: View {
    @ObservedObject var game: TetrisGame
    @FocusState private var hasKeyboardFocus: Bool

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Score \(game.currentScore)")
                    .font(.headline.monospacedDigit())
                Spacer()
                Button("New") {
                    game.reset()
                }
            }

            GeometryReader { geometry in
                let cell = min(
                    geometry.size.width / CGFloat(game.width),
                    geometry.size.height / CGFloat(game.height)
                )

                Canvas { context, _ in
                    for y in 0..<game.height {
                        for x in 0..<game.width {
                            let value = game.board[y * game.width + x]
                            if value != 0 {
                                drawCell(
                                    context: &context,
                                    x: x,
                                    y: y,
                                    value: value,
                                    cell: cell
                                )
                            }
                        }
                    }

                    for point in game.activePiece.points {
                        drawCell(
                            context: &context,
                            x: game.activePiece.x + point.x,
                            y: game.activePiece.y + point.y,
                            value: game.activePiece.type.rawValue,
                            cell: cell
                        )
                    }
                }
                .frame(
                    width: cell * CGFloat(game.width),
                    height: cell * CGFloat(game.height)
                )
                .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 6))
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

            HStack {
                Button { game.moveHorizontal(-1) } label: {
                    Image(systemName: "arrow.left")
                }
                Button { game.softDrop() } label: {
                    Image(systemName: "arrow.down")
                }
                Button { game.rotate() } label: {
                    Image(systemName: "rotate.right")
                }
                Button { game.moveHorizontal(1) } label: {
                    Image(systemName: "arrow.right")
                }
                Button("Drop") { game.hardDrop() }
            }
            .buttonStyle(.bordered)
        }
        .focusable()
        .focused($hasKeyboardFocus)
        .onAppear { hasKeyboardFocus = true }
        .onKeyPress(.leftArrow) {
            game.moveHorizontal(-1)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            game.moveHorizontal(1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            game.softDrop()
            return .handled
        }
        .onKeyPress(.upArrow) {
            game.rotate()
            return .handled
        }
        .onKeyPress(.space) {
            game.hardDrop()
            return .handled
        }
        .onReceive(
            Timer.publish(every: 0.55, on: .main, in: .common).autoconnect()
        ) { _ in
            game.tick()
        }
    }

    private func drawCell(
        context: inout GraphicsContext,
        x: Int,
        y: Int,
        value: Int,
        cell: CGFloat
    ) {
        guard y >= 0 else {
            return
        }
        let rect = CGRect(
            x: CGFloat(x) * cell + 1,
            y: CGFloat(y) * cell + 1,
            width: cell - 2,
            height: cell - 2
        )
        context.fill(
            Path(roundedRect: rect, cornerRadius: 2),
            with: .color(color(for: value))
        )
    }

    private func color(for value: Int) -> Color {
        switch value {
        case 1: .cyan
        case 2: .yellow
        case 3: .purple
        case 4: .green
        case 5: .red
        case 6: .blue
        default: .orange
        }
    }
}
