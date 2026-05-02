import Foundation

extension Round {
    mutating func addPenaltyPoints() {
        for index in 0 ..< playerHands.count {
            let penalty: Int = playerHands[index].cards.totalPoints(cardsMap: cardsMap)
            playerHands[index].player.points += penalty
        }
    }

    public func penaltyPoints(for playerID: PlayerID) -> Int {
        guard let hand: PlayerHand = playerHands.first(where: { $0.player.id == playerID }) else {
            return 0
        }
        return hand.cards.totalPoints(cardsMap: cardsMap)
    }
}
