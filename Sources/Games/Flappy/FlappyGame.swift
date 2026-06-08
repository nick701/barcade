import Combine
import SwiftUI

struct FlappyPipe: Identifiable {
    let id = UUID()
    var x: Double
    var gapY: Double
    var hasScored = false
}

final class FlappyGame: ScoredGame {
    let title = "Flappy Bird"
    let id = "flappy"

    @Published private(set) var birdY = 0.5
    @Published private(set) var pipes: [FlappyPipe]
    @Published private(set) var isGameOver = false
    @Published private(set) var currentScore = 0

    private var velocity = 0.0
    private var isRunning = false
    private let birdX = 0.25
    private let gapSize = 0.28

    init(initialPipes: [FlappyPipe]? = nil) {
        pipes = initialPipes ?? [
            FlappyPipe(x: 0.9, gapY: 0.55),
            FlappyPipe(x: 1.45, gapY: 0.4)
        ]
    }

    func start() {
        guard !isGameOver else {
            return
        }
        isRunning = true
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
        birdY = 0.5
        velocity = 0
        pipes = [
            FlappyPipe(x: 0.9, gapY: randomGapY()),
            FlappyPipe(x: 1.45, gapY: randomGapY())
        ]
        currentScore = 0
        isGameOver = false
        isRunning = true
    }

    func flap() {
        guard isRunning else {
            return
        }
        velocity = 0.025
    }

    func tick() {
        guard isRunning else {
            return
        }

        velocity -= 0.0018
        birdY += velocity

        for index in pipes.indices {
            pipes[index].x -= 0.006
            if !pipes[index].hasScored, pipes[index].x < birdX {
                pipes[index].hasScored = true
                currentScore += 1
            }
        }

        if let first = pipes.first, first.x < -0.12 {
            pipes.removeFirst()
            let nextX = (pipes.last?.x ?? 0.9) + 0.55
            pipes.append(FlappyPipe(x: nextX, gapY: randomGapY()))
        }

        let hitBounds = birdY <= 0.02 || birdY >= 0.98
        let hitPipe = pipes.contains { pipe in
            abs(pipe.x - birdX) < 0.075 &&
                (birdY < pipe.gapY - gapSize / 2 || birdY > pipe.gapY + gapSize / 2)
        }

        if hitBounds || hitPipe {
            isRunning = false
            isGameOver = true
        }
    }

    private func randomGapY() -> Double {
        Double.random(in: 0.3...0.7)
    }
}

struct FlappyGameView: View {
    @ObservedObject var game: FlappyGame
    @FocusState private var hasKeyboardFocus: Bool

    var body: some View {
        VStack(spacing: 12) {
            Text("Score \(game.currentScore)")
                .font(.headline.monospacedDigit())

            GeometryReader { geometry in
                Canvas { context, size in
                    let birdCenter = CGPoint(
                        x: size.width * 0.25,
                        y: size.height * (1 - game.birdY)
                    )
                    let birdRect = CGRect(
                        x: birdCenter.x - 11,
                        y: birdCenter.y - 9,
                        width: 22,
                        height: 18
                    )
                    context.fill(
                        Path(roundedRect: birdRect, cornerRadius: 6),
                        with: .color(.yellow)
                    )

                    for pipe in game.pipes {
                        let x = size.width * pipe.x
                        let width = size.width * 0.1
                        let gapTop = size.height * (1 - (pipe.gapY + 0.14))
                        let gapBottom = size.height * (1 - (pipe.gapY - 0.14))

                        context.fill(
                            Path(
                                CGRect(
                                    x: x - width / 2,
                                    y: 0,
                                    width: width,
                                    height: max(0, gapTop)
                                )
                            ),
                            with: .color(.green)
                        )
                        context.fill(
                            Path(
                                CGRect(
                                    x: x - width / 2,
                                    y: gapBottom,
                                    width: width,
                                    height: max(0, size.height - gapBottom)
                                )
                            ),
                            with: .color(.green)
                        )
                    }
                }
                .background(.cyan.opacity(0.24), in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    if game.isGameOver {
                        Text("Game Over")
                            .font(.title.bold())
                            .padding()
                            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { game.flap() }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
            }

            HStack {
                Button("Flap") {
                    game.flap()
                    hasKeyboardFocus = true
                }
                .buttonStyle(.borderedProminent)

                if game.isGameOver {
                    Button("Play Again") {
                        game.reset()
                        hasKeyboardFocus = true
                    }
                }
            }

            Text("Spacebar or click to flap")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .focusable()
        .focused($hasKeyboardFocus)
        .onAppear { hasKeyboardFocus = true }
        .onKeyPress(.space) {
            game.flap()
            return .handled
        }
        .onReceive(
            Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
        ) { _ in
            game.tick()
        }
    }
}
