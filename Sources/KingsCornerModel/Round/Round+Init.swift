import Foundation

extension Round {
    public init(
        id: String = UUID().uuidString,
        started: Date = .init(),
        players: [Player]
    ) throws {
        let deck: [Card] = [Card].deck().shuffled()
        try self.init(id: id, started: started, deck: deck, players: players)
    }

    init(
        id: String = UUID().uuidString,
        started: Date = .init(),
        deck: [Card],
        players: [Player]
    ) throws {
        guard players.count >= Self.minPlayers else {
            throw KingsCornerError.notEnoughPlayers
        }
        guard players.count <= Self.maxPlayers else {
            throw KingsCornerError.tooManyPlayers
        }

        self.id = id
        self.started = started
        self.cardsMap = Dictionary(uniqueKeysWithValues: deck.map { ($0.id, $0) })

        var remaining: [Card] = deck

        var hands: [PlayerHand] = []
        for player in players {
            let handCards: [Card] = Array(remaining.suffix(Self.cardsPerHand))
            remaining.removeLast(Self.cardsPerHand)
            hands.append(PlayerHand(player: player, cards: handCards.map(\.id)))
        }
        self.playerHands = hands

        var piles: [PilePosition: [CardID]] = [:]
        for position in PilePosition.foundations {
            let card: Card = remaining.removeLast()
            piles[position] = [card.id]
        }
        for position in PilePosition.corners {
            piles[position] = []
        }
        self.piles = piles

        self.stockpile = remaining.map(\.id)

        self.state = .waitingForPlayerToAct(
            playerID: players.first!.id,
            drawState: .needsToDraw
        )
    }
}
