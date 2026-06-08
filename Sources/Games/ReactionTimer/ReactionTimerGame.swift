import Combine
import SwiftUI

enum ReactionPhase: Equatable {
    case idle
    case waiting
    case ready
    case result
    case tooSoon
}

final class ReactionTimerGame: ScoredGame {
    let title = "Reaction Timer"
    let id = "reaction-timer"

    @Published private(set) var phase = ReactionPhase.idle
    @Published private(set) var currentScore = 0
    @Published private(set) var isGameOver = false

    private var isRunning = false
    private var readyAt: Date?
    private var greenAt: Date?
    private let clock: () -> Date
    private let delayProvider: () -> TimeInterval

    init(
        clock: @escaping () -> Date = Date.init,
        delayProvider: @escaping () -> TimeInterval = {
            Double.random(in: 1.5...4.5)
        }
    ) {
        self.clock = clock
        self.delayProvider = delayProvider
    }

    func start() {
        isRunning = true
        if phase == .idle {
            beginRound()
        }
    }

    func pause() {
        isRunning = false
    }

    func resume() {
        guard !isGameOver else {
            return
        }
        isRunning = true
    }

    func reset() {
        currentScore = 0
        isGameOver = false
        isRunning = true
        beginRound()
    }

    func tick() {
        guard isRunning,
              phase == .waiting,
              let readyAt,
              clock() >= readyAt else {
            return
        }
        greenAt = clock()
        self.readyAt = nil
        phase = .ready
    }

    func tap() {
        guard isRunning else {
            return
        }

        switch phase {
        case .waiting:
            phase = .tooSoon
            isGameOver = true
            isRunning = false
        case .ready:
            guard let greenAt else {
                return
            }
            currentScore = max(
                1,
                Int((clock().timeIntervalSince(greenAt) * 1_000).rounded())
            )
            phase = .result
            isGameOver = true
            isRunning = false
        case .idle, .result, .tooSoon:
            break
        }
    }

    private func beginRound() {
        phase = .waiting
        readyAt = clock().addingTimeInterval(delayProvider())
        greenAt = nil
    }
}

struct ReactionTimerGameView: View {
    @ObservedObject var game: ReactionTimerGame
    @ObservedObject var scoreStore: ScoreStore

    private var personalBest: Int? {
        scoreStore.scores(for: game.id).first?.score
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Reaction")
                    .font(.headline)
                Spacer()
                if let personalBest {
                    Text("Best \(personalBest) ms")
                        .foregroundStyle(.secondary)
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)

                VStack(spacing: 10) {
                    Image(systemName: phaseSymbol)
                        .font(.system(size: 48))
                    Text(phaseTitle)
                        .font(.largeTitle.bold())
                    Text(phaseDetail)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                game.tap()
            }

            if game.isGameOver {
                Button("Try Again") {
                    game.reset()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .onReceive(
            Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
        ) { _ in
            game.tick()
        }
    }

    private var backgroundColor: Color {
        switch game.phase {
        case .ready: .green.opacity(0.62)
        case .tooSoon: .red.opacity(0.42)
        default: .secondary.opacity(0.14)
        }
    }

    private var phaseSymbol: String {
        switch game.phase {
        case .waiting: "hourglass"
        case .ready: "hand.tap.fill"
        case .result: "stopwatch.fill"
        case .tooSoon: "exclamationmark.triangle.fill"
        case .idle: "stopwatch"
        }
    }

    private var phaseTitle: String {
        switch game.phase {
        case .waiting: "Wait for green"
        case .ready: "Click!"
        case .result: "\(game.currentScore) ms"
        case .tooSoon: "Too soon"
        case .idle: "Get ready"
        }
    }

    private var phaseDetail: String {
        switch game.phase {
        case .waiting: "Clicking early ends the round."
        case .ready: "Tap anywhere in this panel."
        case .result: "That run is saved to your scores."
        case .tooSoon: "Wait for the panel to turn green."
        case .idle: ""
        }
    }
}
