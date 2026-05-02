import Foundation

public struct Round: Equatable, Codable, Sendable {
    // MARK: - Initialized Properties
    public let id: String
    public let started: Date

    // MARK: - Round Progression
    public internal(set) var state: State
    public internal(set) var cardsMap: [CardID: Card]
    public internal(set) var stockpile: [CardID]
    public internal(set) var playerHands: [PlayerHand]
    public internal(set) var piles: [PilePosition: [CardID]]

    // MARK: - Results
    public internal(set) var log: Log = .init()
    public internal(set) var ended: Date?

    public enum State: Equatable, Codable, Sendable {
        case waitingForPlayerToAct(playerID: PlayerID, drawState: DrawState)
        case roundComplete(winnerID: PlayerID?)

        public enum DrawState: Equatable, Codable, Sendable {
            case needsToDraw
            case hasDrawn
        }

        public enum CodingKeys: String, CodingKey {
            case waitingForPlayerToAct
            case roundComplete
        }

        public var logValue: String {
            switch self {
            case .waitingForPlayerToAct(let playerID, let drawState):
                "Waiting for \(playerID) (\(drawState))"
            case .roundComplete(let winnerID):
                "Round complete — winner: \(winnerID ?? "none")"
            }
        }
    }

    public static let cardsPerHand: Int = 7
    public static let minPlayers: Int = 2
    public static let maxPlayers: Int = 4
}
