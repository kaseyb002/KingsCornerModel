import Foundation

public enum Rank: Int, Equatable, Comparable, CaseIterable, Codable, Sendable {
    case ace = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    case ten = 10
    case jack = 11
    case queen = 12
    case king = 13

    public static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var displayableName: String {
        switch self {
        case .ace: "Ace"
        case .two: "2"
        case .three: "3"
        case .four: "4"
        case .five: "5"
        case .six: "6"
        case .seven: "7"
        case .eight: "8"
        case .nine: "9"
        case .ten: "10"
        case .jack: "Jack"
        case .queen: "Queen"
        case .king: "King"
        }
    }

    public var points: Int {
        switch self {
        case .king, .queen, .jack: 10
        default: rawValue
        }
    }
}
