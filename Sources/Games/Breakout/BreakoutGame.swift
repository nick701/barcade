import Combine
import SwiftUI

struct BreakoutBrick: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    var isActive = true

    func contains(_ point: GameVector) -> Bool {
        point.x >= x && point.x <= x + width &&
            point.y >= y && point.y <= y + height
    }
}

final class BreakoutGame: ScoredGame {
    let title = "Breakout"
    let id = "breakout"

    @Published private(set) var ballPosition: GameVector
    @Published private(set) var bricks: [BreakoutBrick]
    @Published private(set) var paddleX = 0.5
    @Published private(set) var lives = 3
    @Published private(set) var currentScore = 0
    @Published private(set) var isGameOver = false

    private var ballVelocity: GameVector
    private var isRunning = false
    private let paddleWidth = 0.24

    init(
        bricks: [BreakoutBrick]? = nil,
        ballPosition: GameVector = GameVector(x: 0.5, y: 0.72),
        ballVelocity: GameVector = GameVector(x: 0.006, y: -0.009)
    ) {
        self.bricks = bricks ?? Self.makeBricks()
        self.ballPosition = ballPosition
        self.ballVelocity = ballVelocity
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
        bricks = Self.makeBricks()
        paddleX = 0.5
        lives = 3
        currentScore = 0
        isGameOver = false
        resetBall()
        isRunning = true
    }

    func movePaddle(to normalizedX: Double) {
        paddleX = min(1 - paddleWidth / 2, max(paddleWidth / 2, normalizedX))
    }

    func nudgePaddle(by amount: Double) {
        movePaddle(to: paddleX + amount)
    }

    func tick() {
        guard isRunning else {
            return
        }

        ballPosition = ballPosition + ballVelocity

        if ballPosition.x <= 0.02 || ballPosition.x >= 0.98 {
            ballVelocity.x *= -1
            ballPosition.x = min(0.98, max(0.02, ballPosition.x))
        }
        if ballPosition.y <= 0.02 {
            ballVelocity.y = abs(ballVelocity.y)
        }

        let hitsPaddle = ballPosition.y >= 0.87 &&
            ballPosition.y <= 0.94 &&
            abs(ballPosition.x - paddleX) <= paddleWidth / 2
        if hitsPaddle, ballVelocity.y > 0 {
            ballVelocity.y = -abs(ballVelocity.y)
            ballVelocity.x += (ballPosition.x - paddleX) * 0.018
        }

        if let index = bricks.firstIndex(where: {
            $0.isActive && $0.contains(ballPosition)
        }) {
            bricks[index].isActive = false
            currentScore += 10
            ballVelocity.y *= -1

            if bricks.allSatisfy({ !$0.isActive }) {
                isRunning = false
                isGameOver = true
                return
            }
        }

        if ballPosition.y > 1.02 {
            lives -= 1
            if lives <= 0 {
                isRunning = false
                isGameOver = true
            } else {
                resetBall()
            }
        }
    }

    private func resetBall() {
        ballPosition = GameVector(x: 0.5, y: 0.72)
        ballVelocity = GameVector(
            x: Bool.random() ? 0.006 : -0.006,
            y: -0.009
        )
    }

    private static func makeBricks() -> [BreakoutBrick] {
        (0..<5).flatMap { row in
            (0..<8).map { column in
                BreakoutBrick(
                    x: 0.035 + Double(column) * 0.12,
                    y: 0.08 + Double(row) * 0.065,
                    width: 0.105,
                    height: 0.05
                )
            }
        }
    }
}

struct BreakoutGameView: View {
    @ObservedObject var game: BreakoutGame
    @FocusState private var hasKeyboardFocus: Bool

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Score \(game.currentScore)")
                    .font(.headline.monospacedDigit())
                Spacer()
                Text("Lives \(game.lives)")
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                Canvas { context, size in
                    for brick in game.bricks where brick.isActive {
                        let rect = CGRect(
                            x: size.width * brick.x,
                            y: size.height * brick.y,
                            width: size.width * brick.width,
                            height: size.height * brick.height
                        )
                        context.fill(
                            Path(roundedRect: rect, cornerRadius: 3),
                            with: .color(.orange)
                        )
                    }

                    let paddle = CGRect(
                        x: size.width * (game.paddleX - 0.12),
                        y: size.height * 0.9,
                        width: size.width * 0.24,
                        height: 10
                    )
                    context.fill(
                        Path(roundedRect: paddle, cornerRadius: 5),
                        with: .color(.blue)
                    )

                    let ball = CGRect(
                        x: size.width * game.ballPosition.x - 7,
                        y: size.height * game.ballPosition.y - 7,
                        width: 14,
                        height: 14
                    )
                    context.fill(Path(ellipseIn: ball), with: .color(.white))
                }
                .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    if game.isGameOver {
                        Text(game.lives > 0 ? "You cleared it!" : "Game Over")
                            .font(.title.bold())
                            .padding()
                            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            game.movePaddle(
                                to: value.location.x / max(1, geometry.size.width)
                            )
                        }
                )
            }

            HStack {
                Button {
                    game.nudgePaddle(by: -0.08)
                } label: {
                    Image(systemName: "arrow.left")
                }

                if game.isGameOver {
                    Button("Play Again") {
                        game.reset()
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button {
                    game.nudgePaddle(by: 0.08)
                } label: {
                    Image(systemName: "arrow.right")
                }
            }
        }
        .focusable()
        .focused($hasKeyboardFocus)
        .onAppear { hasKeyboardFocus = true }
        .onKeyPress(.leftArrow) {
            game.nudgePaddle(by: -0.05)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            game.nudgePaddle(by: 0.05)
            return .handled
        }
        .onReceive(
            Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
        ) { _ in
            game.tick()
        }
    }
}
