import Foundation

public enum Suit: String, Equatable, CaseIterable, Codable, Sendable {
    case hearts
    case diamonds
    case clubs
    case spades

    public var color: CardColor {
        switch self {
        case .hearts, .diamonds: .red
        case .clubs, .spades: .black
        }
    }

    public var displayableName: String {
        switch self {
        case .hearts: "Hearts"
        case .diamonds: "Diamonds"
        case .clubs: "Clubs"
        case .spades: "Spades"
        }
    }

    public var logSymbol: String {
        switch self {
        case .hearts: "♥"
        case .diamonds: "♦"
        case .clubs: "♣"
        case .spades: "♠"
        }
    }
}
