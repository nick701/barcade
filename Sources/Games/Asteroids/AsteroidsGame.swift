import Combine
import SwiftUI

struct Asteroid: Identifiable {
    let id = UUID()
    var position: GameVector
    var velocity: GameVector
    var radius: Double
}

struct AsteroidBullet: Identifiable {
    let id = UUID()
    var position: GameVector
    var velocity: GameVector
    var age = 0.0
}

final class AsteroidsGame: ScoredGame {
    let title = "Asteroids"
    let id = "asteroids"

    @Published private(set) var shipPosition = GameVector(x: 0.5, y: 0.5)
    @Published private(set) var shipAngle = -Double.pi / 2
    @Published private(set) var asteroids: [Asteroid]
    @Published private(set) var bullets: [AsteroidBullet]
    @Published private(set) var lives = 3
    @Published private(set) var currentScore = 0
    @Published private(set) var isGameOver = false

    private var shipVelocity = GameVector(x: 0, y: 0)
    private var isRunning = false

    init(
        asteroids: [Asteroid]? = nil,
        bullets: [AsteroidBullet] = []
    ) {
        self.asteroids = asteroids ?? Self.makeAsteroids(count: 5)
        self.bullets = bullets
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
        shipPosition = GameVector(x: 0.5, y: 0.5)
        shipVelocity = GameVector(x: 0, y: 0)
        shipAngle = -Double.pi / 2
        asteroids = Self.makeAsteroids(count: 5)
        bullets = []
        lives = 3
        currentScore = 0
        isGameOver = false
        isRunning = true
    }

    func rotate(by radians: Double) {
        guard isRunning else {
            return
        }
        shipAngle += radians
    }

    func thrust() {
        guard isRunning else {
            return
        }
        shipVelocity.x += cos(shipAngle) * 0.0015
        shipVelocity.y += sin(shipAngle) * 0.0015
    }

    func shoot() {
        guard isRunning else {
            return
        }
        let direction = GameVector(
            x: cos(shipAngle),
            y: sin(shipAngle)
        )
        bullets.append(
            AsteroidBullet(
                position: shipPosition,
                velocity: shipVelocity + direction * 0.018
            )
        )
    }

    func tick(delta: TimeInterval = 1.0 / 60.0) {
        guard isRunning else {
            return
        }

        shipPosition = wrapped(shipPosition + shipVelocity)
        shipVelocity = shipVelocity * 0.995

        for index in asteroids.indices {
            asteroids[index].position = wrapped(
                asteroids[index].position + asteroids[index].velocity
            )
        }
        for index in bullets.indices {
            bullets[index].position = wrapped(
                bullets[index].position + bullets[index].velocity
            )
            bullets[index].age += delta
        }
        bullets.removeAll { $0.age > 1.4 }

        resolveBulletCollisions()
        resolveShipCollision()

        if asteroids.isEmpty, !isGameOver {
            asteroids = Self.makeAsteroids(count: 6)
        }
    }

    private func resolveBulletCollisions() {
        var bulletIDs: Set<UUID> = []
        var asteroidIDs: Set<UUID> = []

        for bullet in bullets {
            if let asteroid = asteroids.first(where: {
                distance(bullet.position, $0.position) <= $0.radius
            }) {
                bulletIDs.insert(bullet.id)
                asteroidIDs.insert(asteroid.id)
                currentScore += 100
            }
        }

        bullets.removeAll { bulletIDs.contains($0.id) }
        asteroids.removeAll { asteroidIDs.contains($0.id) }
    }

    private func resolveShipCollision() {
        guard let asteroid = asteroids.first(where: {
            distance(shipPosition, $0.position) <= $0.radius + 0.035
        }) else {
            return
        }

        asteroids.removeAll { $0.id == asteroid.id }
        lives -= 1
        if lives <= 0 {
            isRunning = false
            isGameOver = true
        } else {
            shipPosition = GameVector(x: 0.5, y: 0.5)
            shipVelocity = GameVector(x: 0, y: 0)
        }
    }

    private func wrapped(_ point: GameVector) -> GameVector {
        GameVector(
            x: point.x < 0 ? point.x + 1 : (point.x > 1 ? point.x - 1 : point.x),
            y: point.y < 0 ? point.y + 1 : (point.y > 1 ? point.y - 1 : point.y)
        )
    }

    private func distance(_ lhs: GameVector, _ rhs: GameVector) -> Double {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return sqrt(dx * dx + dy * dy)
    }

    private static func makeAsteroids(count: Int) -> [Asteroid] {
        (0..<count).map { index in
            let angle = Double(index) / Double(count) * Double.pi * 2
            return Asteroid(
                position: GameVector(
                    x: 0.5 + cos(angle) * 0.4,
                    y: 0.5 + sin(angle) * 0.4
                ),
                velocity: GameVector(
                    x: Double.random(in: -0.004...0.004),
                    y: Double.random(in: -0.004...0.004)
                ),
                radius: Double.random(in: 0.035...0.07)
            )
        }
    }
}

struct AsteroidsGameView: View {
    @ObservedObject var game: AsteroidsGame
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
                    for asteroid in game.asteroids {
                        let rect = CGRect(
                            x: size.width * (asteroid.position.x - asteroid.radius),
                            y: size.height * (asteroid.position.y - asteroid.radius),
                            width: size.width * asteroid.radius * 2,
                            height: size.height * asteroid.radius * 2
                        )
                        context.stroke(
                            Path(ellipseIn: rect),
                            with: .color(.white),
                            lineWidth: 2
                        )
                    }

                    for bullet in game.bullets {
                        let rect = CGRect(
                            x: size.width * bullet.position.x - 2,
                            y: size.height * bullet.position.y - 2,
                            width: 4,
                            height: 4
                        )
                        context.fill(Path(ellipseIn: rect), with: .color(.yellow))
                    }

                    let center = CGPoint(
                        x: size.width * game.shipPosition.x,
                        y: size.height * game.shipPosition.y
                    )
                    let angle = game.shipAngle
                    let nose = CGPoint(
                        x: center.x + cos(angle) * 17,
                        y: center.y + sin(angle) * 17
                    )
                    let left = CGPoint(
                        x: center.x + cos(angle + 2.45) * 13,
                        y: center.y + sin(angle + 2.45) * 13
                    )
                    let right = CGPoint(
                        x: center.x + cos(angle - 2.45) * 13,
                        y: center.y + sin(angle - 2.45) * 13
                    )
                    var ship = Path()
                    ship.move(to: nose)
                    ship.addLine(to: left)
                    ship.addLine(to: right)
                    ship.closeSubpath()
                    context.stroke(ship, with: .color(.cyan), lineWidth: 2)
                }
                .background(.black.opacity(0.9), in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    if game.isGameOver {
                        Text("Game Over")
                            .font(.title.bold())
                            .padding()
                            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
            }

            HStack {
                Button { game.rotate(by: -0.18) } label: {
                    Image(systemName: "rotate.left")
                }
                Button("Thrust") { game.thrust() }
                Button("Fire") { game.shoot() }
                    .buttonStyle(.borderedProminent)
                Button { game.rotate(by: 0.18) } label: {
                    Image(systemName: "rotate.right")
                }
            }

            if game.isGameOver {
                Button("Play Again") {
                    game.reset()
                }
            } else {
                Text("Arrows to steer, spacebar to fire")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .focusable()
        .focused($hasKeyboardFocus)
        .onAppear { hasKeyboardFocus = true }
        .onKeyPress(.leftArrow) {
            game.rotate(by: -0.14)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            game.rotate(by: 0.14)
            return .handled
        }
        .onKeyPress(.upArrow) {
            game.thrust()
            return .handled
        }
        .onKeyPress(.space) {
            game.shoot()
            return .handled
        }
        .onReceive(
            Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
        ) { _ in
            game.tick()
        }
    }
}
