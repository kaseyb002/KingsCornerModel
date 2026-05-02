import Foundation

public typealias CardID = Int

public struct Card: Equatable, Codable, Sendable, Identifiable {
    public let id: CardID
    public let suit: Suit
    public let rank: Rank

    public var color: CardColor { suit.color }
    public var isKing: Bool { rank == .king }
    public var points: Int { rank.points }

    public var displayableName: String {
        "\(rank.displayableName) of \(suit.displayableName)"
    }

    public var logValue: String {
        "\(rank.displayableName)\(suit.logSymbol)"
    }

    public init(id: CardID, suit: Suit, rank: Rank) {
        self.id = id
        self.suit = suit
        self.rank = rank
    }

    public func canBePlacedOn(_ other: Card) -> Bool {
        rank.rawValue == other.rank.rawValue - 1 && color != other.color
    }
}
