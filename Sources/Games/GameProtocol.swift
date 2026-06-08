import Combine

protocol BarcadeGame {
    var title: String { get }
    var id: String { get }
    func start()
    func pause()
    func resume()
    func reset()
    var currentScore: Int { get }
}

protocol ScoredGame: AnyObject, BarcadeGame, ObservableObject {
    var isGameOver: Bool { get }
}
