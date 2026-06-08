import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var scoreStore: ScoreStore

    @State private var errorMessage: String?
    @State private var confirmGlobalReset = false

    var body: some View {
        List {
            Section("Games") {
                ForEach(orderedGames) { game in
                    HStack {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.tertiary)

                        Label(game.title, systemImage: game.symbolName)

                        Spacer()

                        Toggle(
                            "Enabled",
                            isOn: enabledBinding(for: game.id)
                        )
                        .labelsHidden()
                    }
                }
                .onMove(perform: moveGames)
            }

            Section("Game Settings") {
                Picker("Snake speed", selection: snakeSpeedBinding) {
                    ForEach(SnakeSpeed.allCases, id: \.self) { speed in
                        Text(speed.rawValue.capitalized).tag(speed)
                    }
                }

                Picker("Minesweeper grid", selection: minesweeperSizeBinding) {
                    Text("9×9").tag(MinesweeperGridSize.small)
                    Text("16×16").tag(MinesweeperGridSize.medium)
                    Text("30×16").tag(MinesweeperGridSize.large)
                }

                Picker("Sudoku difficulty", selection: sudokuDifficultyBinding) {
                    ForEach(SudokuDifficulty.allCases, id: \.self) { difficulty in
                        Text(difficulty.rawValue.capitalized).tag(difficulty)
                    }
                }
            }

            Section("Scores") {
                ForEach(GameCatalog.all) { game in
                    if !scoreStore.scores(for: game.id).isEmpty {
                        Button("Reset \(game.title)") {
                            perform {
                                try scoreStore.reset(gameID: game.id)
                            }
                        }
                    }
                }

                Button("Reset All Scores", role: .destructive) {
                    confirmGlobalReset = true
                }
                .disabled(scoreStore.scoresByGame.isEmpty)
            }
        }
        .confirmationDialog(
            "Reset every high score?",
            isPresented: $confirmGlobalReset
        ) {
            Button("Reset All Scores", role: .destructive) {
                perform {
                    try scoreStore.resetAll()
                }
            }
        }
        .alert(
            "Could not save changes",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var orderedGames: [GameMetadata] {
        let byID = Dictionary(uniqueKeysWithValues: GameCatalog.all.map { ($0.id, $0) })
        return settingsStore.settings.gameOrder.compactMap { byID[$0] }
    }

    private func enabledBinding(for gameID: String) -> Binding<Bool> {
        Binding(
            get: { settingsStore.settings.enabledGames.contains(gameID) },
            set: { enabled in
                perform {
                    try settingsStore.setGameEnabled(gameID, enabled: enabled)
                }
            }
        )
    }

    private var snakeSpeedBinding: Binding<SnakeSpeed> {
        Binding(
            get: { settingsStore.settings.snakeSpeed },
            set: { speed in
                perform {
                    try settingsStore.setSnakeSpeed(speed)
                }
            }
        )
    }

    private var minesweeperSizeBinding: Binding<MinesweeperGridSize> {
        Binding(
            get: { settingsStore.settings.minesweeperGridSize },
            set: { size in
                perform {
                    try settingsStore.setMinesweeperGridSize(size)
                }
            }
        )
    }

    private var sudokuDifficultyBinding: Binding<SudokuDifficulty> {
        Binding(
            get: { settingsStore.settings.sudokuDifficulty },
            set: { difficulty in
                perform {
                    try settingsStore.setSudokuDifficulty(difficulty)
                }
            }
        )
    }

    private func moveGames(from source: IndexSet, to destination: Int) {
        var order = settingsStore.settings.gameOrder
        order.move(fromOffsets: source, toOffset: destination)
        perform {
            try settingsStore.setGameOrder(order)
        }
    }

    private func perform(_ operation: () throws -> Void) {
        do {
            try operation()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
