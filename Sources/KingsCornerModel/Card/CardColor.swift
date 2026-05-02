import Foundation

public enum CardColor: String, Equatable, Codable, Sendable {
    case red
    case black

    public var opposite: CardColor {
        switch self {
        case .red: .black
        case .black: .red
        }
    }
}
