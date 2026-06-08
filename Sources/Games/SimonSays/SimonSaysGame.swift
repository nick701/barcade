import Combine
import SwiftUI

enum SimonColor: String, CaseIterable {
    case red
    case blue
    case green
    case yellow
}

enum SimonPhase: Equatable {
    case idle
    case showing
    case input
    case gameOver
}

final class SimonSaysGame: ScoredGame {
    let title = "Simon Says"
    let id = "simon-says"

    @Published private(set) var sequence: [SimonColor] = []
    @Published private(set) var highlightedColor: SimonColor?
    @Published private(set) var phase = SimonPhase.idle
    @Published private(set) var currentScore = 0
    @Published private(set) var isGameOver = false

    private var inputIndex = 0
    private var presentationIndex = 0
    private var presentationElapsed = 0.0
    private var isRunning = false
    private let randomColor: () -> SimonColor

    init(
        randomColor: @escaping () -> SimonColor = {
            SimonColor.allCases.randomElement() ?? .red
        }
    ) {
        self.randomColor = randomColor
    }

    var presentationInterval: TimeInterval {
        max(0.22, 0.7 - Double(sequence.count) * 0.04)
    }

    func start() {
        isRunning = true
        if phase == .idle {
            sequence = [randomColor()]
            beginPresentation()
        }
    }

    func pause() {
        isRunning = false
    }

    func resume() {
        isRunning = !isGameOver
    }

    func reset() {
        sequence = [randomColor()]
        currentScore = 0
        isGameOver = false
        isRunning = true
        beginPresentation()
    }

    func tick(delta: TimeInterval = 0.05) {
        guard isRunning, phase == .showing else {
            return
        }

        presentationElapsed += delta
        guard presentationElapsed >= presentationInterval / 2 else {
            return
        }
        presentationElapsed = 0

        if highlightedColor == nil {
            guard presentationIndex < sequence.count else {
                phase = .input
                inputIndex = 0
                return
            }
            highlightedColor = sequence[presentationIndex]
        } else {
            highlightedColor = nil
            presentationIndex += 1
            if presentationIndex >= sequence.count {
                phase = .input
                inputIndex = 0
            }
        }
    }

    func completePresentation() {
        highlightedColor = nil
        phase = .input
        inputIndex = 0
    }

    func press(_ color: SimonColor) {
        guard isRunning, phase == .input else {
            return
        }

        guard sequence[inputIndex] == color else {
            phase = .gameOver
            isGameOver = true
            isRunning = false
            return
        }

        inputIndex += 1
        if inputIndex == sequence.count {
            currentScore = sequence.count
            sequence.append(randomColor())
            beginPresentation()
        }
    }

    private func beginPresentation() {
        phase = .showing
        highlightedColor = nil
        presentationIndex = 0
        presentationElapsed = 0
        inputIndex = 0
    }
}

struct SimonSaysGameView: View {
    @ObservedObject var game: SimonSaysGame

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Round \(game.currentScore + 1)")
                    .font(.headline.monospacedDigit())
                Spacer()
                Text(statusText)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(SimonColor.allCases, id: \.self) { color in
                    Button {
                        game.press(color)
                    } label: {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(swiftUIColor(color))
                            .opacity(
                                game.highlightedColor == color ? 1 : 0.48
                            )
                            .overlay {
                                if game.highlightedColor == color {
                                    Image(systemName: "sparkle")
                                        .font(.largeTitle)
                                        .foregroundStyle(.white)
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                    }
                    .buttonStyle(.plain)
                    .disabled(game.phase != .input)
                }
            }

            if game.isGameOver {
                VStack(spacing: 8) {
                    Text("Sequence missed")
                        .font(.title2.bold())
                    Button("Play Again") {
                        game.reset()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("Watch the pattern, then repeat it")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onReceive(
            Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
        ) { _ in
            game.tick()
        }
    }

    private var statusText: String {
        switch game.phase {
        case .showing: "Watch"
        case .input: "Your turn"
        case .gameOver: "Game over"
        case .idle: "Ready"
        }
    }

    private func swiftUIColor(_ color: SimonColor) -> Color {
        switch color {
        case .red: .red
        case .blue: .blue
        case .green: .green
        case .yellow: .yellow
        }
    }
}
