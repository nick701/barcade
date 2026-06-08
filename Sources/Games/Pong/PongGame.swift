import Combine
import SwiftUI

final class PongGame: ScoredGame {
    let title = "Pong vs AI"
    let id = "pong"

    @Published private(set) var ballPosition: GameVector
    @Published private(set) var playerY = 0.5
    @Published private(set) var aiY = 0.5
    @Published private(set) var playerScore = 0
    @Published private(set) var aiScore = 0
    @Published private(set) var isGameOver = false

    var currentScore: Int { playerScore }

    private var ballVelocity: GameVector
    private var isRunning = false
    private let paddleHalfHeight = 0.13
    private let winningScore = 7

    init(
        ballPosition: GameVector = GameVector(x: 0.5, y: 0.5),
        ballVelocity: GameVector = GameVector(x: 0.008, y: 0.005)
    ) {
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
        playerY = 0.5
        aiY = 0.5
        playerScore = 0
        aiScore = 0
        isGameOver = false
        resetBall(towardPlayer: Bool.random())
        isRunning = true
    }

    func movePlayer(to normalizedY: Double) {
        playerY = min(
            1 - paddleHalfHeight,
            max(paddleHalfHeight, normalizedY)
        )
    }

    func nudgePlayer(by amount: Double) {
        movePlayer(to: playerY + amount)
    }

    func tick() {
        guard isRunning else {
            return
        }

        updateAI()
        ballPosition = ballPosition + ballVelocity

        if ballPosition.y <= 0.02 || ballPosition.y >= 0.98 {
            ballVelocity.y *= -1
            ballPosition.y = min(0.98, max(0.02, ballPosition.y))
        }

        if ballPosition.x <= 0.07,
           ballVelocity.x < 0,
           abs(ballPosition.y - aiY) <= paddleHalfHeight {
            ballVelocity.x = abs(ballVelocity.x) * 1.02
            ballVelocity.y += (ballPosition.y - aiY) * 0.02
        }

        if ballPosition.x >= 0.93,
           ballVelocity.x > 0,
           abs(ballPosition.y - playerY) <= paddleHalfHeight {
            ballVelocity.x = -abs(ballVelocity.x) * 1.02
            ballVelocity.y += (ballPosition.y - playerY) * 0.02
        }

        if ballPosition.x < 0 {
            playerScore += 1
            finishPointOrReset()
        } else if ballPosition.x > 1 {
            aiScore += 1
            finishPointOrReset()
        }
    }

    private func updateAI() {
        let difficulty = min(
            0.012,
            0.004 + Double(playerScore + aiScore) * 0.0007
        )
        if ballPosition.y > aiY {
            aiY = min(aiY + difficulty, 1 - paddleHalfHeight)
        } else {
            aiY = max(aiY - difficulty, paddleHalfHeight)
        }
    }

    private func finishPointOrReset() {
        if playerScore >= winningScore || aiScore >= winningScore {
            isRunning = false
            isGameOver = true
        } else {
            resetBall(towardPlayer: Bool.random())
        }
    }

    private func resetBall(towardPlayer: Bool) {
        ballPosition = GameVector(x: 0.5, y: 0.5)
        ballVelocity = GameVector(
            x: towardPlayer ? 0.008 : -0.008,
            y: Double.random(in: -0.006...0.006)
        )
    }
}

struct PongGameView: View {
    @ObservedObject var game: PongGame
    @FocusState private var hasKeyboardFocus: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text("\(game.aiScore)  –  \(game.playerScore)")
                .font(.largeTitle.bold().monospacedDigit())

            GeometryReader { geometry in
                Canvas { context, size in
                    var divider = Path()
                    divider.move(to: CGPoint(x: size.width / 2, y: 0))
                    divider.addLine(to: CGPoint(x: size.width / 2, y: size.height))
                    context.stroke(
                        divider,
                        with: .color(.white.opacity(0.35)),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 8])
                    )

                    let aiPaddle = CGRect(
                        x: size.width * 0.04,
                        y: size.height * (game.aiY - 0.13),
                        width: 10,
                        height: size.height * 0.26
                    )
                    let playerPaddle = CGRect(
                        x: size.width * 0.96 - 10,
                        y: size.height * (game.playerY - 0.13),
                        width: 10,
                        height: size.height * 0.26
                    )
                    context.fill(Path(roundedRect: aiPaddle, cornerRadius: 5), with: .color(.orange))
                    context.fill(Path(roundedRect: playerPaddle, cornerRadius: 5), with: .color(.blue))

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
                        Text(game.playerScore > game.aiScore ? "You Win!" : "AI Wins")
                            .font(.title.bold())
                            .padding()
                            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            game.movePlayer(
                                to: value.location.y / max(1, geometry.size.height)
                            )
                        }
                )
            }

            HStack {
                Button {
                    game.nudgePlayer(by: -0.08)
                } label: {
                    Image(systemName: "arrow.up")
                }

                if game.isGameOver {
                    Button("Play Again") {
                        game.reset()
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button {
                    game.nudgePlayer(by: 0.08)
                } label: {
                    Image(systemName: "arrow.down")
                }
            }

            Text("You are the blue paddle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .focusable()
        .focused($hasKeyboardFocus)
        .onAppear { hasKeyboardFocus = true }
        .onKeyPress(.upArrow) {
            game.nudgePlayer(by: -0.05)
            return .handled
        }
        .onKeyPress(.downArrow) {
            game.nudgePlayer(by: 0.05)
            return .handled
        }
        .onReceive(
            Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
        ) { _ in
            game.tick()
        }
    }
}
