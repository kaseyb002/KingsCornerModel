import Foundation

public struct PlayerHand: Equatable, Codable, Sendable {
    public var player: Player
    public var cards: [CardID]

    public init(
        player: Player,
        cards: [CardID]
    ) {
        self.player = player
        self.cards = cards
    }
}
