import Foundation

extension Card {
    public static func fake(
        id: CardID = .random(in: 0 ... 999),
        suit: Suit = .allCases.randomElement()!,
        rank: Rank = .allCases.randomElement()!
    ) -> Card {
        .init(id: id, suit: suit, rank: rank)
    }
}
