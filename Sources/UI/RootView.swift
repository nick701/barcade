import SwiftUI

struct RootView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var scoreStore: ScoreStore

    @State private var section = RootSection.games
    @State private var selectedGame: GameMetadata?

    var body: some View {
        VStack(spacing: 0) {
            if let selectedGame {
                placeholder(for: selectedGame)
            } else {
                Picker("Section", selection: $section) {
                    ForEach(RootSection.allCases) { section in
                        Label(section.title, systemImage: section.symbolName)
                            .tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding()

                Group {
                    switch section {
                    case .games:
                        GamePickerView(
                            games: GameCatalog.enabledGames(for: settingsStore.settings),
                            onSelect: { selectedGame = $0 }
                        )
                    case .scores:
                        HighScoresView(scoreStore: scoreStore)
                    case .settings:
                        SettingsView(
                            settingsStore: settingsStore,
                            scoreStore: scoreStore
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 460, height: 600)
        .background(.regularMaterial)
    }

    private func placeholder(for game: GameMetadata) -> some View {
        VStack(spacing: 18) {
            HStack {
                Button {
                    selectedGame = nil
                } label: {
                    Label("Games", systemImage: "chevron.left")
                }

                Spacer()
            }

            Spacer()

            Image(systemName: game.symbolName)
                .font(.system(size: 54))
                .foregroundStyle(.tint)

            Text(game.title)
                .font(.largeTitle.bold())

            Text("Game implementation is next.")
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(20)
    }
}

private enum RootSection: String, CaseIterable, Identifiable {
    case games
    case scores
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .games: "Games"
        case .scores: "Scores"
        case .settings: "Settings"
        }
    }

    var symbolName: String {
        switch self {
        case .games: "gamecontroller"
        case .scores: "trophy"
        case .settings: "gearshape"
        }
    }
}

struct StorageErrorView: View {
    let error: Error

    var body: some View {
        ContentUnavailableView {
            Label("Barcade could not start", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        }
        .frame(width: 460, height: 600)
    }
}
