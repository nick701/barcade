import Foundation

struct ScoreEntry: Codable, Equatable, Identifiable {
    let score: Int
    let date: Date

    var id: String {
        "\(date.timeIntervalSince1970)-\(score)"
    }
}

@MainActor
final class ScoreStore: ObservableObject {
    @Published private(set) var scoresByGame: [String: [ScoreEntry]]

    private let fileURL: URL

    init(directoryURL: URL? = nil) throws {
        let directoryURL = directoryURL ?? Self.defaultDirectoryURL
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        fileURL = directoryURL.appendingPathComponent("scores.json")

        if FileManager.default.fileExists(atPath: fileURL.path) {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            scoresByGame = try decoder.decode([String: [ScoreEntry]].self, from: data)
        } else {
            scoresByGame = [:]
            try persist()
        }
    }

    func scores(for gameID: String) -> [ScoreEntry] {
        scoresByGame[gameID] ?? []
    }

    func record(score: Int, for gameID: String, date: Date = Date()) throws {
        var scores = scoresByGame[gameID] ?? []
        scores.append(ScoreEntry(score: score, date: date))
        scores.sort {
            if $0.score == $1.score {
                return $0.date > $1.date
            }
            if gameID == "reaction-timer" {
                return $0.score < $1.score
            }
            return $0.score > $1.score
        }
        scoresByGame[gameID] = Array(scores.prefix(5))
        try persist()
    }

    func reset(gameID: String) throws {
        scoresByGame.removeValue(forKey: gameID)
        try persist()
    }

    func resetAll() throws {
        scoresByGame.removeAll()
        try persist()
    }

    private func persist() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(scoresByGame)
        try data.write(to: fileURL, options: .atomic)
    }

    private static var defaultDirectoryURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("barcade", isDirectory: true)
    }
}
