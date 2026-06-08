import SwiftUI

enum TileMove {
    case up
    case down
    case left
    case right
}

final class TwentyFortyEightGame: ScoredGame {
    let title = "2048"
    let id = "twenty-forty-eight"

    @Published private(set) var grid: [Int]
    @Published private(set) var currentScore = 0
    @Published private(set) var isGameOver = false

    private var isRunning = false
    private let spawnsTilesAfterMove: Bool

    init(initialGrid: [Int]? = nil, spawnsTilesAfterMove: Bool = true) {
        self.spawnsTilesAfterMove = spawnsTilesAfterMove
        grid = initialGrid ?? Array(repeating: 0, count: 16)
        if initialGrid == nil {
            addRandomTile()
            addRandomTile()
        }
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
        grid = Array(repeating: 0, count: 16)
        currentScore = 0
        isGameOver = false
        addRandomTile()
        addRandomTile()
        isRunning = true
    }

    func move(_ direction: TileMove) {
        guard isRunning else {
            return
        }

        let previous = grid
        for index in 0..<4 {
            let positions = positions(for: direction, line: index)
            let values = positions.map { grid[$0] }
            let merged = merge(values)
            for (position, value) in zip(positions, merged) {
                grid[position] = value
            }
        }

        guard grid != previous else {
            updateGameOver()
            return
        }

        if spawnsTilesAfterMove {
            addRandomTile()
        }
        updateGameOver()
    }

    private func positions(for direction: TileMove, line: Int) -> [Int] {
        switch direction {
        case .left:
            (0..<4).map { line * 4 + $0 }
        case .right:
            (0..<4).reversed().map { line * 4 + $0 }
        case .up:
            (0..<4).map { $0 * 4 + line }
        case .down:
            (0..<4).reversed().map { $0 * 4 + line }
        }
    }

    private func merge(_ values: [Int]) -> [Int] {
        let compact = values.filter { $0 != 0 }
        var result: [Int] = []
        var index = 0

        while index < compact.count {
            if index + 1 < compact.count, compact[index] == compact[index + 1] {
                let combined = compact[index] * 2
                result.append(combined)
                currentScore += combined
                index += 2
            } else {
                result.append(compact[index])
                index += 1
            }
        }

        return result + Array(repeating: 0, count: 4 - result.count)
    }

    private func addRandomTile() {
        let empty = grid.indices.filter { grid[$0] == 0 }
        guard let index = empty.randomElement() else {
            return
        }
        grid[index] = Double.random(in: 0...1) < 0.9 ? 2 : 4
    }

    private func updateGameOver() {
        guard !grid.contains(0) else {
            return
        }

        for y in 0..<4 {
            for x in 0..<4 {
                let value = grid[y * 4 + x]
                if x < 3, grid[y * 4 + x + 1] == value {
                    return
                }
                if y < 3, grid[(y + 1) * 4 + x] == value {
                    return
                }
            }
        }

        isRunning = false
        isGameOver = true
    }
}

struct TwentyFortyEightGameView: View {
    @ObservedObject var game: TwentyFortyEightGame
    @FocusState private var hasKeyboardFocus: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Score \(game.currentScore)")
                    .font(.headline.monospacedDigit())
                Spacer()
                Button("New Game") {
                    game.reset()
                    hasKeyboardFocus = true
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(game.grid.indices, id: \.self) { index in
                    let value = game.grid[index]
                    Text(value == 0 ? "" : value.formatted())
                        .font(.title2.bold().monospacedDigit())
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .background(tileColor(value), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(10)
            .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))

            if game.isGameOver {
                Text("No moves left")
                    .font(.title2.bold())
            } else {
                Text("Use the arrow keys to merge tiles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .focusable()
        .focused($hasKeyboardFocus)
        .onAppear { hasKeyboardFocus = true }
        .onKeyPress(.upArrow) {
            game.move(.up)
            return .handled
        }
        .onKeyPress(.downArrow) {
            game.move(.down)
            return .handled
        }
        .onKeyPress(.leftArrow) {
            game.move(.left)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            game.move(.right)
            return .handled
        }
    }

    private func tileColor(_ value: Int) -> Color {
        switch value {
        case 0: .secondary.opacity(0.14)
        case 2: .orange.opacity(0.22)
        case 4: .orange.opacity(0.35)
        case 8: .orange.opacity(0.55)
        case 16: .orange.opacity(0.7)
        case 32: .red.opacity(0.65)
        case 64: .red.opacity(0.8)
        default: .purple.opacity(0.75)
        }
    }
}
