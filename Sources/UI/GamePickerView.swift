import SwiftUI

struct GamePickerView: View {
    let games: [GameMetadata]
    let onSelect: (GameMetadata) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Group {
            if games.isEmpty {
                ContentUnavailableView {
                    Label("No games enabled", systemImage: "gamecontroller")
                } description: {
                    Text("Enable at least one game in Settings.")
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(games) { game in
                            Button {
                                onSelect(game)
                            } label: {
                                VStack(spacing: 10) {
                                    Image(systemName: game.symbolName)
                                        .font(.system(size: 28))
                                        .foregroundStyle(.tint)

                                    Text(game.title)
                                        .font(.headline)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, minHeight: 112)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding([.horizontal, .bottom])
                }
            }
        }
        .navigationTitle("Games")
    }
}
