import Combine
import SwiftUI

struct BilliardsBall: Identifiable {
    let id = UUID()
    let number: Int
    var position: GameVector
    var velocity: GameVector
    let isCue: Bool

    init(
        number: Int,
        position: GameVector,
        velocity: GameVector = GameVector(x: 0, y: 0),
        isCue: Bool = false
    ) {
        self.number = number
        self.position = position
        self.velocity = velocity
        self.isCue = isCue
    }
}

final class BilliardsGame: ScoredGame {
    let title = "Mini Billiards"
    let id = "billiards"

    @Published private(set) var balls: [BilliardsBall]
    @Published private(set) var playerScore = 0
    @Published private(set) var aiScore = 0
    @Published private(set) var isPlayerTurn = true
    @Published private(set) var aimingAngle = 0.0
    @Published private(set) var power = 0.55
    @Published private(set) var isGameOver = false

    var currentScore: Int { playerScore }

    private var isRunning = false
    private var isShotInProgress = false
    private var aiDelay = 0.0
    private let ballRadius = 0.026
    private let pockets = [
        GameVector(x: 0.04, y: 0.06),
        GameVector(x: 0.5, y: 0.04),
        GameVector(x: 0.96, y: 0.06),
        GameVector(x: 0.04, y: 0.94),
        GameVector(x: 0.5, y: 0.96),
        GameVector(x: 0.96, y: 0.94)
    ]

    init(balls: [BilliardsBall]? = nil) {
        self.balls = balls ?? Self.makeRack()
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
        balls = Self.makeRack()
        playerScore = 0
        aiScore = 0
        isPlayerTurn = true
        aimingAngle = 0
        power = 0.55
        isGameOver = false
        isShotInProgress = false
        aiDelay = 0
        isRunning = true
    }

    func aim(at point: GameVector) {
        guard isRunning,
              isPlayerTurn,
              !isShotInProgress,
              let cue = balls.first(where: \.isCue) else {
            return
        }
        aimingAngle = atan2(
            point.y - cue.position.y,
            point.x - cue.position.x
        )
    }

    func setPower(_ value: Double) {
        power = min(1, max(0.1, value))
    }

    func shoot() {
        guard isPlayerTurn else {
            return
        }
        shootCurrentAim()
    }

    func tick(delta: TimeInterval = 1.0 / 60.0) {
        guard isRunning else {
            return
        }

        for index in balls.indices {
            balls[index].position = balls[index].position + balls[index].velocity
            balls[index].velocity = balls[index].velocity * 0.985
            if speed(of: balls[index].velocity) < 0.00025 {
                balls[index].velocity = GameVector(x: 0, y: 0)
            }
            bounceOffRails(index: index)
        }

        resolveBallCollisions()
        processPockets()

        if balls.filter({ !$0.isCue }).isEmpty {
            isShotInProgress = false
            isRunning = false
            isGameOver = true
            return
        }

        let allStopped = balls.allSatisfy { speed(of: $0.velocity) == 0 }
        if isShotInProgress, allStopped {
            isShotInProgress = false
            isPlayerTurn.toggle()
            aiDelay = 0
        }

        if !isPlayerTurn, !isShotInProgress, allStopped {
            aiDelay += delta
            if aiDelay >= 0.8 {
                prepareAIShot()
                shootCurrentAim()
            }
        }
    }

    private func shootCurrentAim() {
        guard isRunning,
              !isShotInProgress,
              let cueIndex = balls.firstIndex(where: \.isCue) else {
            return
        }
        balls[cueIndex].velocity = GameVector(
            x: cos(aimingAngle) * power * 0.035,
            y: sin(aimingAngle) * power * 0.035
        )
        isShotInProgress = true
    }

    private func prepareAIShot() {
        guard let cue = balls.first(where: \.isCue),
              let target = balls.filter({ !$0.isCue }).min(by: {
                  distance(cue.position, $0.position) <
                      distance(cue.position, $1.position)
              }) else {
            return
        }
        aimingAngle = atan2(
            target.position.y - cue.position.y,
            target.position.x - cue.position.x
        )
        power = min(0.9, 0.52 + Double(aiScore) * 0.03)
    }

    private func bounceOffRails(index: Int) {
        if balls[index].position.x < 0.04 || balls[index].position.x > 0.96 {
            balls[index].velocity.x *= -1
            balls[index].position.x = min(0.96, max(0.04, balls[index].position.x))
        }
        if balls[index].position.y < 0.06 || balls[index].position.y > 0.94 {
            balls[index].velocity.y *= -1
            balls[index].position.y = min(0.94, max(0.06, balls[index].position.y))
        }
    }

    private func resolveBallCollisions() {
        guard balls.count > 1 else {
            return
        }
        for first in 0..<(balls.count - 1) {
            for second in (first + 1)..<balls.count {
                guard distance(
                    balls[first].position,
                    balls[second].position
                ) <= ballRadius * 2 else {
                    continue
                }
                let firstVelocity = balls[first].velocity
                balls[first].velocity = balls[second].velocity
                balls[second].velocity = firstVelocity
            }
        }
    }

    private func processPockets() {
        var pocketedIDs: Set<UUID> = []
        var cuePocketed = false

        for ball in balls {
            guard pockets.contains(where: {
                distance(ball.position, $0) <= 0.055
            }) else {
                continue
            }

            if ball.isCue {
                cuePocketed = true
            } else {
                pocketedIDs.insert(ball.id)
                if isPlayerTurn {
                    playerScore += 100
                } else {
                    aiScore += 100
                }
            }
        }

        balls.removeAll { pocketedIDs.contains($0.id) }

        if cuePocketed, let cueIndex = balls.firstIndex(where: \.isCue) {
            balls[cueIndex].position = GameVector(x: 0.28, y: 0.5)
            balls[cueIndex].velocity = GameVector(x: 0, y: 0)
        }
    }

    private func speed(of vector: GameVector) -> Double {
        sqrt(vector.x * vector.x + vector.y * vector.y)
    }

    private func distance(_ lhs: GameVector, _ rhs: GameVector) -> Double {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return sqrt(dx * dx + dy * dy)
    }

    private static func makeRack() -> [BilliardsBall] {
        var balls = [
            BilliardsBall(
                number: 0,
                position: GameVector(x: 0.28, y: 0.5),
                isCue: true
            )
        ]
        let positions = [
            GameVector(x: 0.66, y: 0.5),
            GameVector(x: 0.71, y: 0.47),
            GameVector(x: 0.71, y: 0.53),
            GameVector(x: 0.76, y: 0.44),
            GameVector(x: 0.76, y: 0.5),
            GameVector(x: 0.76, y: 0.56)
        ]
        balls += positions.enumerated().map { index, position in
            BilliardsBall(number: index + 1, position: position)
        }
        return balls
    }
}

struct BilliardsGameView: View {
    @ObservedObject var game: BilliardsGame

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("You \(game.playerScore)")
                    .font(.headline.monospacedDigit())
                Spacer()
                Text(game.isPlayerTurn ? "Your turn" : "AI thinking")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("AI \(game.aiScore)")
                    .font(.headline.monospacedDigit())
            }

            GeometryReader { geometry in
                Canvas { context, size in
                    drawTable(context: &context, size: size)

                    if game.isPlayerTurn,
                       let cue = game.balls.first(where: \.isCue) {
                        var aim = Path()
                        let start = CGPoint(
                            x: size.width * cue.position.x,
                            y: size.height * cue.position.y
                        )
                        aim.move(to: start)
                        aim.addLine(
                            to: CGPoint(
                                x: start.x + cos(game.aimingAngle) * size.width * 0.3,
                                y: start.y + sin(game.aimingAngle) * size.width * 0.3
                            )
                        )
                        context.stroke(
                            aim,
                            with: .color(.white.opacity(0.6)),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                        )
                    }

                    let diameter = min(size.width, size.height) * 0.052
                    for ball in game.balls {
                        let rect = CGRect(
                            x: size.width * ball.position.x - diameter / 2,
                            y: size.height * ball.position.y - diameter / 2,
                            width: diameter,
                            height: diameter
                        )
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(ball.isCue ? .white : ballColor(ball.number))
                        )
                        if !ball.isCue {
                            context.draw(
                                Text(ball.number.formatted())
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white),
                                at: CGPoint(x: rect.midX, y: rect.midY)
                            )
                        }
                    }
                }
                .background(.green.opacity(0.64), in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.brown, lineWidth: 14)
                }
                .overlay {
                    if game.isGameOver {
                        Text(game.playerScore >= game.aiScore ? "You Win!" : "AI Wins")
                            .font(.title.bold())
                            .padding()
                            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            game.aim(
                                at: GameVector(
                                    x: value.location.x / max(1, geometry.size.width),
                                    y: value.location.y / max(1, geometry.size.height)
                                )
                            )
                        }
                )
            }

            HStack {
                Text("Power")
                Slider(
                    value: Binding(
                        get: { game.power },
                        set: { game.setPower($0) }
                    ),
                    in: 0.1...1
                )
                Button("Shoot") {
                    game.shoot()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!game.isPlayerTurn || game.isGameOver)
            }

            if game.isGameOver {
                Button("Play Again") {
                    game.reset()
                }
            } else {
                Text("Drag on the table to aim")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onReceive(
            Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
        ) { _ in
            game.tick()
        }
    }

    private func drawTable(context: inout GraphicsContext, size: CGSize) {
        let pockets = [
            CGPoint(x: size.width * 0.04, y: size.height * 0.06),
            CGPoint(x: size.width * 0.5, y: size.height * 0.04),
            CGPoint(x: size.width * 0.96, y: size.height * 0.06),
            CGPoint(x: size.width * 0.04, y: size.height * 0.94),
            CGPoint(x: size.width * 0.5, y: size.height * 0.96),
            CGPoint(x: size.width * 0.96, y: size.height * 0.94)
        ]
        for pocket in pockets {
            let rect = CGRect(
                x: pocket.x - 11,
                y: pocket.y - 11,
                width: 22,
                height: 22
            )
            context.fill(Path(ellipseIn: rect), with: .color(.black))
        }
    }

    private func ballColor(_ number: Int) -> Color {
        [.yellow, .blue, .red, .purple, .orange, .green][
            max(0, min(5, number - 1))
        ]
    }
}
