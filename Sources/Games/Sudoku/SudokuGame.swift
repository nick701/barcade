import SwiftUI

final class SudokuGame: ScoredGame {
    let title = "Sudoku"
    let id = "sudoku"
    let difficulty: SudokuDifficulty

    @Published private(set) var grid: [Int]
    @Published private(set) var solution: [Int]
    @Published private(set) var fixedCells: [Bool]
    @Published private(set) var mistakes = 0
    @Published private(set) var currentScore = 0
    @Published private(set) var isGameOver = false

    private var isRunning = false

    convenience init(difficulty: SudokuDifficulty) {
        let generated = Self.generate(difficulty: difficulty)
        self.init(
            puzzle: generated.puzzle,
            solution: generated.solution,
            difficulty: difficulty
        )
    }

    init(
        puzzle: [Int],
        solution: [Int],
        difficulty: SudokuDifficulty
    ) {
        self.grid = puzzle
        self.solution = solution
        self.difficulty = difficulty
        fixedCells = puzzle.map { $0 != 0 }
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
        let generated = Self.generate(difficulty: difficulty)
        grid = generated.puzzle
        solution = generated.solution
        fixedCells = grid.map { $0 != 0 }
        mistakes = 0
        currentScore = 0
        isGameOver = false
        isRunning = true
    }

    func setValue(_ value: Int, at index: Int) {
        guard isRunning,
              grid.indices.contains(index),
              !fixedCells[index],
              (0...9).contains(value) else {
            return
        }

        grid[index] = value
        if value != 0, value != solution[index] {
            mistakes += 1
        }

        let correctEntries = grid.indices.filter {
            !fixedCells[$0] && grid[$0] == solution[$0]
        }.count
        currentScore = correctEntries * 10

        if grid == solution {
            let completionBonus = switch difficulty {
            case .easy: 500
            case .medium: 800
            case .hard: 1_200
            }
            currentScore += completionBonus
            isRunning = false
            isGameOver = true
        }
    }

    private static func generate(
        difficulty: SudokuDifficulty
    ) -> (puzzle: [Int], solution: [Int]) {
        let digits = Array(1...9).shuffled()
        let rowOrder = shuffledUnits()
        let columnOrder = shuffledUnits()
        let solution = rowOrder.flatMap { row in
            columnOrder.map { column in
                let base = (row * 3 + row / 3 + column) % 9
                return digits[base]
            }
        }

        let removals = switch difficulty {
        case .easy: 35
        case .medium: 45
        case .hard: 55
        }
        var puzzle = solution
        for index in puzzle.indices.shuffled().prefix(removals) {
            puzzle[index] = 0
        }
        return (puzzle, solution)
    }

    private static func shuffledUnits() -> [Int] {
        [0, 1, 2].shuffled().flatMap { band in
            [0, 1, 2].shuffled().map { row in band * 3 + row }
        }
    }
}

struct SudokuGameView: View {
    @ObservedObject var game: SudokuGame
    @State private var selectedIndex: Int?

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 1),
        count: 9
    )

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(game.difficulty.rawValue.capitalized)
                    .font(.headline)
                Spacer()
                Text("Mistakes \(game.mistakes)")
                    .foregroundStyle(.secondary)
                Button("New") {
                    selectedIndex = nil
                    game.reset()
                }
            }

            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(game.grid.indices, id: \.self) { index in
                    Button {
                        if !game.fixedCells[index] {
                            selectedIndex = index
                        }
                    } label: {
                        Text(game.grid[index] == 0 ? "" : game.grid[index].formatted())
                            .font(.title3.monospacedDigit().bold())
                            .foregroundStyle(cellForeground(index))
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .background(cellBackground(index))
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .trailing) {
                        if index % 9 == 2 || index % 9 == 5 {
                            Rectangle()
                                .fill(.primary.opacity(0.5))
                                .frame(width: 2)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if index / 9 == 2 || index / 9 == 5 {
                            Rectangle()
                                .fill(.primary.opacity(0.5))
                                .frame(height: 2)
                        }
                    }
                }
            }
            .padding(2)
            .background(.primary.opacity(0.45), in: RoundedRectangle(cornerRadius: 6))

            HStack(spacing: 6) {
                ForEach(1...9, id: \.self) { number in
                    Button(number.formatted()) {
                        guard let selectedIndex else {
                            return
                        }
                        game.setValue(number, at: selectedIndex)
                    }
                    .buttonStyle(.bordered)
                }
            }

            HStack {
                Button("Erase") {
                    guard let selectedIndex else {
                        return
                    }
                    game.setValue(0, at: selectedIndex)
                }

                Spacer()

                if game.isGameOver {
                    Text("Solved!")
                        .font(.title2.bold())
                } else {
                    Text("Select a cell, then choose a number")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func cellBackground(_ index: Int) -> Color {
        if selectedIndex == index {
            return .accentColor.opacity(0.28)
        }
        return game.fixedCells[index]
            ? .secondary.opacity(0.16)
            : .secondary.opacity(0.05)
    }

    private func cellForeground(_ index: Int) -> Color {
        guard game.grid[index] != 0 else {
            return .primary
        }
        if game.fixedCells[index] {
            return .primary
        }
        return game.grid[index] == game.solution[index] ? .blue : .red
    }
}
