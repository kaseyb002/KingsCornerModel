import Foundation

extension PlayerHand {
    public static func fake(
        player: Player = .fake(),
        cards: [CardID] = Array(0 ..< 7)
    ) -> PlayerHand {
        .init(
            player: player,
            cards: cards
        )
    }
}
