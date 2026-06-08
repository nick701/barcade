import SwiftUI

struct MinesweeperCell: Identifiable {
    let id: Int
    var hasMine: Bool
    var adjacentMines: Int
    var isRevealed = false
    var isFlagged = false
}

final class MinesweeperGame: ScoredGame {
    let title = "Minesweeper"
    let id = "minesweeper"
    let width: Int
    let height: Int
    let mineCount: Int

    @Published private(set) var cells: [MinesweeperCell] = []
    @Published private(set) var isGameOver = false
    @Published private(set) var didWin = false
    @Published private(set) var currentScore = 0

    private var isRunning = false
    private var isFirstMove = true
    private let protectsFirstMove: Bool
    private let fixedMineLocations: Set<Int>?

    convenience init(size: MinesweeperGridSize) {
        switch size {
        case .small:
            self.init(width: 9, height: 9, mineCount: 10)
        case .medium:
            self.init(width: 16, height: 16, mineCount: 40)
        case .large:
            self.init(width: 30, height: 16, mineCount: 99)
        }
    }

    init(
        width: Int,
        height: Int,
        mineCount: Int? = nil,
        mineLocations: Set<Int>? = nil,
        protectsFirstMove: Bool = true
    ) {
        self.width = width
        self.height = height
        self.mineCount = mineCount ?? mineLocations?.count ?? 0
        self.protectsFirstMove = protectsFirstMove
        fixedMineLocations = mineLocations
        configureBoard()
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
        currentScore = 0
        isGameOver = false
        didWin = false
        isFirstMove = true
        configureBoard()
        isRunning = true
    }

    func toggleFlag(_ index: Int) {
        guard isRunning, cells.indices.contains(index), !cells[index].isRevealed else {
            return
        }
        cells[index].isFlagged.toggle()
    }

    func reveal(_ index: Int) {
        guard isRunning,
              cells.indices.contains(index),
              !cells[index].isFlagged,
              !cells[index].isRevealed else {
            return
        }

        if isFirstMove, protectsFirstMove, cells[index].hasMine {
            relocateMine(from: index)
        }
        isFirstMove = false

        if cells[index].hasMine {
            cells[index].isRevealed = true
            for mineIndex in cells.indices where cells[mineIndex].hasMine {
                cells[mineIndex].isRevealed = true
            }
            isRunning = false
            isGameOver = true
            return
        }

        revealSafeArea(from: index)
        checkForWin()
    }

    private func configureBoard() {
        let count = width * height
        let mines = fixedMineLocations ??
            Set((0..<count).shuffled().prefix(min(mineCount, count)))

        cells = (0..<count).map { index in
            MinesweeperCell(
                id: index,
                hasMine: mines.contains(index),
                adjacentMines: 0
            )
        }
        recalculateAdjacentCounts()
    }

    private func relocateMine(from index: Int) {
        guard let replacement = cells.indices.first(where: {
            $0 != index && !cells[$0].hasMine
        }) else {
            return
        }
        cells[index].hasMine = false
        cells[replacement].hasMine = true
        recalculateAdjacentCounts()
    }

    private func recalculateAdjacentCounts() {
        for index in cells.indices {
            cells[index].adjacentMines = neighbors(of: index)
                .filter { cells[$0].hasMine }
                .count
        }
    }

    private func revealSafeArea(from start: Int) {
        var queue = [start]
        var visited: Set<Int> = []

        while let index = queue.first {
            queue.removeFirst()
            guard !visited.contains(index),
                  !cells[index].isFlagged,
                  !cells[index].hasMine else {
                continue
            }

            visited.insert(index)
            if !cells[index].isRevealed {
                cells[index].isRevealed = true
                currentScore += 10
            }

            if cells[index].adjacentMines == 0 {
                queue.append(contentsOf: neighbors(of: index))
            }
        }
    }

    private func neighbors(of index: Int) -> [Int] {
        let x = index % width
        let y = index / width

        return (-1...1).flatMap { dy in
            (-1...1).compactMap { dx -> Int? in
                guard dx != 0 || dy != 0 else {
                    return nil
                }
                let nextX = x + dx
                let nextY = y + dy
                guard (0..<width).contains(nextX),
                      (0..<height).contains(nextY) else {
                    return nil
                }
                return nextY * width + nextX
            }
        }
    }

    private func checkForWin() {
        let safeCells = cells.filter { !$0.hasMine }
        guard safeCells.allSatisfy(\.isRevealed) else {
            return
        }
        didWin = true
        isGameOver = true
        isRunning = false
        currentScore += 500
    }
}

struct MinesweeperGameView: View {
    @ObservedObject var game: MinesweeperGame

    private var cellSize: CGFloat {
        switch game.width {
        case 0...9: 30
        case 10...16: 22
        default: 17
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Score \(game.currentScore)")
                    .font(.headline.monospacedDigit())

                Spacer()

                Text("Flags \(game.cells.filter(\.isFlagged).count)/\(game.mineCount)")
                    .foregroundStyle(.secondary)

                Button("New") {
                    game.reset()
                }
            }

            ScrollView([.horizontal, .vertical]) {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.fixed(cellSize), spacing: 2),
                        count: game.width
                    ),
                    spacing: 2
                ) {
                    ForEach(game.cells) { cell in
                        MinesweeperCellView(
                            cell: cell,
                            size: cellSize,
                            reveal: { game.reveal(cell.id) },
                            flag: { game.toggleFlag(cell.id) }
                        )
                    }
                }
                .padding(4)
            }
            .background(.black.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            if game.isGameOver {
                Text(game.didWin ? "Minefield cleared!" : "Boom!")
                    .font(.title2.bold())
            } else {
                Text("Left-click to reveal, right-click to flag")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct MinesweeperCellView: View {
    let cell: MinesweeperCell
    let size: CGFloat
    let reveal: () -> Void
    let flag: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(cell.isRevealed ? Color.secondary.opacity(0.14) : Color.accentColor.opacity(0.28))

            if cell.isFlagged {
                Image(systemName: "flag.fill")
                    .foregroundStyle(.orange)
            } else if cell.isRevealed, cell.hasMine {
                Image(systemName: "burst.fill")
                    .foregroundStyle(.red)
            } else if cell.isRevealed, cell.adjacentMines > 0 {
                Text(cell.adjacentMines.formatted())
                    .font(.system(size: max(9, size * 0.52), weight: .bold, design: .rounded))
            }

            ClickCaptureView(
                onPrimaryClick: reveal,
                onSecondaryClick: flag
            )
        }
        .frame(width: size, height: size)
    }
}
