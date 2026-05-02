import Foundation

extension [Card] {
    public static func deck() -> [Card] {
        let placeholderID: CardID = 0
        var cards: [Card] = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                cards.append(Card(id: placeholderID, suit: suit, rank: rank))
            }
        }
        let shuffledIDs: [CardID] = (0 ..< cards.count).shuffled()
        return zip(cards, shuffledIDs).map { card, id in
            Card(id: id, suit: card.suit, rank: card.rank)
        }
    }

    public var totalPoints: Int {
        reduce(0) { $0 + $1.points }
    }

    public var logValue: String {
        map { $0.logValue }.joined(separator: ", ")
    }

    public var sortedForDisplay: [Card] {
        sorted { lhs, rhs in
            if lhs.suit == rhs.suit {
                return lhs.rank < rhs.rank
            }
            return lhs.suit.sortOrder < rhs.suit.sortOrder
        }
    }
}

extension [CardID] {
    public func totalPoints(cardsMap: [CardID: Card]) -> Int {
        reduce(0) { $0 + (cardsMap[$1]?.points ?? 0) }
    }
}

extension [CardID: Card] {
    public func findCards(byIDs cardIDs: [CardID]) -> [Card] {
        cardIDs.compactMap { self[$0] }
    }
}

private extension Suit {
    var sortOrder: Int {
        switch self {
        case .spades: 0
        case .hearts: 1
        case .clubs: 2
        case .diamonds: 3
        }
    }
}
