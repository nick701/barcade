import SwiftUI

final class TypeRacerGame: ScoredGame {
    let title = "Type Racer"
    let id = "type-racer"

    @Published private(set) var prompt: String
    @Published private(set) var typedText = ""
    @Published private(set) var wordsPerMinute = 0.0
    @Published private(set) var accuracy = 100.0
    @Published private(set) var currentScore = 0
    @Published private(set) var isGameOver = false

    private var startedAt: Date?
    private var pausedAt: Date?
    private var isRunning = false
    private let sentenceProvider: () -> String
    private let clock: () -> Date

    init(
        sentenceProvider: @escaping () -> String = {
            [
                "Small games make quiet moments surprisingly bright.",
                "The quickest route is often the one you can enjoy.",
                "A steady rhythm turns practice into progress.",
                "Menu bar adventures fit neatly between bigger tasks.",
                "Clear thinking grows from patient and focused work."
            ].randomElement() ?? "Type quickly and accurately."
        },
        clock: @escaping () -> Date = Date.init
    ) {
        self.sentenceProvider = sentenceProvider
        self.clock = clock
        prompt = sentenceProvider()
    }

    func start() {
        guard !isGameOver else {
            return
        }
        if startedAt == nil {
            startedAt = clock()
        }
        isRunning = true
    }

    func pause() {
        guard isRunning else {
            return
        }
        pausedAt = clock()
        isRunning = false
    }

    func resume() {
        guard !isGameOver else {
            return
        }
        if let pausedAt, let startedAt {
            self.startedAt = startedAt.addingTimeInterval(
                clock().timeIntervalSince(pausedAt)
            )
        }
        pausedAt = nil
        isRunning = true
    }

    func reset() {
        prompt = sentenceProvider()
        typedText = ""
        wordsPerMinute = 0
        accuracy = 100
        currentScore = 0
        isGameOver = false
        pausedAt = nil
        startedAt = clock()
        isRunning = true
    }

    func updateInput(_ text: String) {
        guard isRunning else {
            return
        }

        typedText = String(text.prefix(prompt.count))
        updateMetrics()

        if typedText.count >= prompt.count {
            isRunning = false
            isGameOver = true
        }
    }

    private func updateMetrics() {
        guard let startedAt else {
            return
        }
        let elapsedMinutes = max(
            clock().timeIntervalSince(startedAt) / 60,
            1.0 / 600
        )
        wordsPerMinute = Double(typedText.count) / 5 / elapsedMinutes

        let matches = zip(typedText, prompt).filter(==).count
        accuracy = typedText.isEmpty
            ? 100
            : Double(matches) / Double(typedText.count) * 100
        currentScore = Int(wordsPerMinute.rounded())
    }
}

struct TypeRacerGameView: View {
    @ObservedObject var game: TypeRacerGame
    @FocusState private var editorFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                metric(title: "WPM", value: game.wordsPerMinute.formatted(.number.precision(.fractionLength(0))))
                Spacer()
                metric(title: "Accuracy", value: "\(Int(game.accuracy.rounded()))%")
            }

            Text(game.prompt)
                .font(.title3.monospaced())
                .lineSpacing(6)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))

            TextEditor(
                text: Binding(
                    get: { game.typedText },
                    set: { game.updateInput($0) }
                )
            )
            .font(.title3.monospaced())
            .focused($editorFocused)
            .scrollContentBackground(.hidden)
            .padding(8)
            .background(.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            .disabled(game.isGameOver)

            if game.isGameOver {
                HStack {
                    Text("Finished!")
                        .font(.title2.bold())
                    Spacer()
                    Button("New Sentence") {
                        game.reset()
                        editorFocused = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("Type the sentence exactly as shown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear { editorFocused = true }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold().monospacedDigit())
        }
    }
}
