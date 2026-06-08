import Combine
import SwiftUI

final class TapTheDotGame: ScoredGame {
    let title = "Tap the Dot"
    let id = "tap-the-dot"

    @Published private(set) var dotPosition = GameVector(x: 0.5, y: 0.5)
    @Published private(set) var dotVisible = false
    @Published private(set) var timeRemaining = 30.0
    @Published private(set) var currentScore = 0
    @Published private(set) var isGameOver = false

    private var dotAge = 0.0
    private var isRunning = false
    private var hasSpawned = false
    private let positionProvider: () -> GameVector

    init(
        positionProvider: @escaping () -> GameVector = {
            GameVector(
                x: Double.random(in: 0.1...0.9),
                y: Double.random(in: 0.1...0.9)
            )
        }
    ) {
        self.positionProvider = positionProvider
    }

    func start() {
        guard !isGameOver else {
            return
        }
        isRunning = true
        if !hasSpawned {
            spawnDot()
        }
    }

    func pause() {
        isRunning = false
    }

    func resume() {
        isRunning = !isGameOver
    }

    func reset() {
        timeRemaining = 30
        currentScore = 0
        isGameOver = false
        dotAge = 0
        hasSpawned = false
        isRunning = true
        spawnDot()
    }

    func tap(at position: GameVector) {
        guard isRunning, dotVisible else {
            return
        }
        let dx = position.x - dotPosition.x
        let dy = position.y - dotPosition.y
        guard sqrt(dx * dx + dy * dy) <= 0.09 else {
            return
        }
        currentScore += 1
        spawnDot()
    }

    func tick(delta: TimeInterval = 0.05) {
        guard isRunning else {
            return
        }

        timeRemaining = max(0, timeRemaining - delta)
        if timeRemaining == 0 {
            dotVisible = false
            isRunning = false
            isGameOver = true
            return
        }

        dotAge += delta
        if dotAge >= 0.82 {
            dotVisible = false
        }
        if dotAge >= 1.0 {
            spawnDot()
        }
    }

    private func spawnDot() {
        dotPosition = positionProvider()
        dotVisible = true
        dotAge = 0
        hasSpawned = true
    }
}

struct TapTheDotGameView: View {
    @ObservedObject var game: TapTheDotGame

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Score \(game.currentScore)")
                    .font(.headline.monospacedDigit())
                Spacer()
                Text("\(Int(ceil(game.timeRemaining)))s")
                    .font(.headline.monospacedDigit())
            }

            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.secondary.opacity(0.1))

                    if game.dotVisible {
                        Circle()
                            .fill(.pink)
                            .overlay {
                                Circle().stroke(.white, lineWidth: 3)
                            }
                            .frame(width: 42, height: 42)
                            .position(
                                x: geometry.size.width * game.dotPosition.x,
                                y: geometry.size.height * game.dotPosition.y
                            )
                    }

                    if game.isGameOver {
                        Text("Time!")
                            .font(.title.bold())
                            .padding()
                            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            game.tap(
                                at: GameVector(
                                    x: value.location.x / max(1, geometry.size.width),
                                    y: value.location.y / max(1, geometry.size.height)
                                )
                            )
                        }
                )
            }

            if game.isGameOver {
                Button("Play Again") {
                    game.reset()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("Click each dot before it disappears")
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
}
