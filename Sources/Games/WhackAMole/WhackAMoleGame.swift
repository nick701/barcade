import Combine
import SwiftUI

final class WhackAMoleGame: ScoredGame {
    let title = "Whack-a-Mole"
    let id = "whack-a-mole"

    @Published private(set) var activeHole: Int?
    @Published private(set) var timeRemaining = 30.0
    @Published private(set) var currentScore = 0
    @Published private(set) var isGameOver = false

    private var moleElapsed = 0.0
    private var isRunning = false
    private let randomHole: () -> Int

    init(randomHole: @escaping () -> Int = { Int.random(in: 0..<9) }) {
        self.randomHole = randomHole
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
        activeHole = nil
        timeRemaining = 30
        currentScore = 0
        isGameOver = false
        moleElapsed = 0
        isRunning = true
    }

    func tick(delta: TimeInterval = 0.1) {
        guard isRunning else {
            return
        }

        timeRemaining = max(0, timeRemaining - delta)
        if timeRemaining == 0 {
            activeHole = nil
            isRunning = false
            isGameOver = true
            return
        }

        moleElapsed += delta
        let interval = max(0.3, 0.8 - Double(currentScore) * 0.02)
        if moleElapsed >= interval {
            activeHole = randomHole()
            moleElapsed = 0
        }
    }

    func whack(hole: Int) {
        guard isRunning, activeHole == hole else {
            return
        }
        currentScore += 1
        activeHole = nil
    }
}

struct WhackAMoleGameView: View {
    @ObservedObject var game: WhackAMoleGame

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 12),
        count: 3
    )

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Score \(game.currentScore)")
                    .font(.headline.monospacedDigit())
                Spacer()
                Text("\(Int(ceil(game.timeRemaining)))s")
                    .font(.headline.monospacedDigit())
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(0..<9) { hole in
                    Button {
                        game.whack(hole: hole)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.brown.opacity(0.36))
                            if game.activeHole == hole {
                                Image(systemName: "face.smiling.inverse")
                                    .font(.system(size: 34))
                                    .foregroundStyle(.orange)
                                    .transition(.scale)
                            }
                        }
                        .aspectRatio(1, contentMode: .fit)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(.green.opacity(0.16), in: RoundedRectangle(cornerRadius: 14))

            if game.isGameOver {
                VStack(spacing: 8) {
                    Text("Time!")
                        .font(.title.bold())
                    Button("Play Again") {
                        game.reset()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("Click each mole before it moves")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onReceive(
            Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
        ) { _ in
            game.tick()
        }
    }
}
