import Foundation

struct GameMetadata: Identifiable, Hashable {
    let id: String
    let title: String
    let symbolName: String
}

enum GameCatalog {
    static let all: [GameMetadata] = [
        GameMetadata(id: "snake", title: "Snake", symbolName: "circle.grid.cross"),
        GameMetadata(id: "flappy", title: "Flappy Bird", symbolName: "bird"),
        GameMetadata(id: "twenty-forty-eight", title: "2048", symbolName: "square.grid.2x2"),
        GameMetadata(id: "minesweeper", title: "Minesweeper", symbolName: "burst"),
        GameMetadata(id: "reaction-timer", title: "Reaction Timer", symbolName: "bolt"),
        GameMetadata(id: "breakout", title: "Breakout", symbolName: "rectangle.split.3x1"),
        GameMetadata(id: "tetris", title: "Tetris", symbolName: "square.grid.3x3"),
        GameMetadata(id: "pong", title: "Pong vs AI", symbolName: "arrow.left.and.right"),
        GameMetadata(id: "simon-says", title: "Simon Says", symbolName: "circle.hexagongrid"),
        GameMetadata(id: "whack-a-mole", title: "Whack-a-Mole", symbolName: "hammer"),
        GameMetadata(id: "type-racer", title: "Type Racer", symbolName: "keyboard"),
        GameMetadata(id: "tap-the-dot", title: "Tap the Dot", symbolName: "scope"),
        GameMetadata(id: "sudoku", title: "Sudoku", symbolName: "number.square"),
        GameMetadata(id: "asteroids", title: "Asteroids", symbolName: "sparkles"),
        GameMetadata(id: "billiards", title: "Mini Billiards", symbolName: "circle.circle")
    ]

    static let allIDs = all.map(\.id)
}
