import Foundation

extension PlayerHand {
    public func logValue(cardsMap: [CardID: Card]) -> String {
        let resolvedCards: [Card] = cardsMap.findCards(byIDs: cards)
        return """
        \(player.logValue)
        Cards (\(cards.count)): \(resolvedCards.sortedForDisplay.logValue)
        """
    }
}

extension [PlayerHand] {
    public func logValue(cardsMap: [CardID: Card]) -> String {
        map { $0.logValue(cardsMap: cardsMap) }.joined(separator: "\n\n")
    }
}
