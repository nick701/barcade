import SwiftUI

struct HighScoresView: View {
    @ObservedObject var scoreStore: ScoreStore

    private var gamesWithScores: [GameMetadata] {
        GameCatalog.all.filter { !scoreStore.scores(for: $0.id).isEmpty }
    }

    var body: some View {
        Group {
            if gamesWithScores.isEmpty {
                ContentUnavailableView {
                    Label("No high scores yet", systemImage: "trophy")
                } description: {
                    Text("Play a game to put a score on the board.")
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        ForEach(gamesWithScores) { game in
                            VStack(alignment: .leading, spacing: 8) {
                                Label(game.title, systemImage: game.symbolName)
                                    .font(.headline)

                                ForEach(Array(scoreStore.scores(for: game.id).enumerated()), id: \.element.id) {
                                    index,
                                    entry in
                                    HStack {
                                        Text("#\(index + 1)")
                                            .foregroundStyle(.secondary)
                                            .frame(width: 28, alignment: .leading)

                                        Text(entry.score.formatted())
                                            .font(.body.monospacedDigit().bold())

                                        Spacer()

                                        Text(
                                            entry.date.formatted(
                                                date: .abbreviated,
                                                time: .shortened
                                            )
                                        )
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(12)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding([.horizontal, .bottom])
                }
            }
        }
    }
}
