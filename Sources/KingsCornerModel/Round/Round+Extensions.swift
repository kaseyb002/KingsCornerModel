import Foundation

extension Round {
    public var currentPlayerHandIndex: Int? {
        switch state {
        case .waitingForPlayerToAct(let playerID, _):
            return playerHands.firstIndex(where: { $0.player.id == playerID })
        case .roundComplete:
            return nil
        }
    }

    public var currentPlayerHand: PlayerHand? {
        guard let currentPlayerHandIndex else { return nil }
        return playerHands[currentPlayerHandIndex]
    }

    public var isComplete: Bool {
        if case .roundComplete = state { return true }
        return false
    }

    // MARK: - Validation Helpers

    public func canPlayCard(_ cardID: CardID, on position: PilePosition) -> Bool {
        guard let card: Card = cardsMap[cardID],
              let pile: [CardID] = piles[position]
        else { return false }

        if pile.isEmpty {
            return position.isCorner ? card.isKing : true
        }
        guard let topCard: Card = cardsMap[pile.last!] else { return false }
        return card.canBePlacedOn(topCard)
    }

    public func canMovePile(from source: PilePosition, to destination: PilePosition) -> Bool {
        guard let sourcePile: [CardID] = piles[source],
              sourcePile.isEmpty == false,
              let destPile: [CardID] = piles[destination],
              let bottomOfSource: Card = cardsMap[sourcePile[0]]
        else { return false }

        if destPile.isEmpty {
            return destination.isCorner ? bottomOfSource.isKing : true
        }
        guard let topOfDest: Card = cardsMap[destPile.last!] else { return false }
        return bottomOfSource.canBePlacedOn(topOfDest)
    }

    public func validPositions(for cardID: CardID) -> [PilePosition] {
        PilePosition.allCases.filter { canPlayCard(cardID, on: $0) }
    }

    public func validPileMoves() -> [(from: PilePosition, to: PilePosition)] {
        var moves: [(from: PilePosition, to: PilePosition)] = []
        for source in PilePosition.allCases {
            for destination in PilePosition.allCases where source != destination {
                if canMovePile(from: source, to: destination) {
                    moves.append((from: source, to: destination))
                }
            }
        }
        return moves
    }

    public func topCard(at position: PilePosition) -> Card? {
        guard let pile: [CardID] = piles[position],
              let topID: CardID = pile.last
        else { return nil }
        return cardsMap[topID]
    }

    // MARK: - Log

    public var logValue: String {
        let pileDescriptions: String = PilePosition.allCases.map { position in
            let pile: [CardID] = piles[position] ?? []
            let cards: String = pile.compactMap { cardsMap[$0]?.logValue }.joined(separator: " → ")
            return "  \(position.displayableName): \(cards.isEmpty ? "(empty)" : cards)"
        }.joined(separator: "\n")

        return """
        State: \(state.logValue)
        Stockpile remaining: \(stockpile.count)
        Piles:
        \(pileDescriptions)

        \(playerHands.logValue(cardsMap: cardsMap))
        """
    }
}
