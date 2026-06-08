struct GameVector: Equatable {
    var x: Double
    var y: Double

    static func + (lhs: GameVector, rhs: GameVector) -> GameVector {
        GameVector(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func * (lhs: GameVector, rhs: Double) -> GameVector {
        GameVector(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}
