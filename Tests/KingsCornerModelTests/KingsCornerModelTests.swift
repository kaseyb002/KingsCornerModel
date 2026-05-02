import Foundation
import Testing
@testable import KingsCornerModel

// MARK: - Deck Tests

@Test func deckSize() throws {
    let deck: [Card] = .deck()
    #expect(deck.count == 52)
    #expect(Set(deck.map { $0.id }).count == 52)
}

@Test func deckContainsAllCards() throws {
    let deck: [Card] = .deck()
    for suit in Suit.allCases {
        for rank in Rank.allCases {
            let found: Bool = deck.contains { $0.suit == suit && $0.rank == rank }
            #expect(found, "Missing \(rank.displayableName) of \(suit.displayableName)")
        }
    }
}

// MARK: - Round Init Tests

@Test func roundInit() throws {
    let round: Round = try .init(
        players: [.fake(id: "p1"), .fake(id: "p2")]
    )
    #expect(round.cardsMap.count == 52)
    #expect(round.playerHands.count == 2)
    #expect(round.playerHands[0].cards.count == 7)
    #expect(round.playerHands[1].cards.count == 7)
    #expect(round.stockpile.count == 52 - 14 - 4)
    #expect(round.piles.count == 8)

    for position in PilePosition.foundations {
        #expect(round.piles[position]?.count == 1)
    }
    for position in PilePosition.corners {
        #expect(round.piles[position]?.isEmpty == true)
    }
}

@Test func roundInitThreeAndFourPlayers() throws {
    let round3: Round = try .init(
        players: [.fake(), .fake(), .fake()]
    )
    #expect(round3.playerHands.count == 3)
    #expect(round3.stockpile.count == 52 - 21 - 4)

    let round4: Round = try .init(
        players: [.fake(), .fake(), .fake(), .fake()]
    )
    #expect(round4.playerHands.count == 4)
    #expect(round4.stockpile.count == 52 - 28 - 4)
}

@Test func roundInitNotEnoughPlayers() throws {
    #expect(throws: KingsCornerError.notEnoughPlayers) {
        _ = try Round(players: [.fake()])
    }
}

@Test func roundInitTooManyPlayers() throws {
    #expect(throws: KingsCornerError.tooManyPlayers) {
        _ = try Round(players: [.fake(), .fake(), .fake(), .fake(), .fake()])
    }
}

// MARK: - Draw Tests

@Test func drawCard() throws {
    var round: Round = try .init(players: [.fake(id: "p1"), .fake(id: "p2")])
    let stockpileCount: Int = round.stockpile.count
    let handCount: Int = round.playerHands[0].cards.count

    try round.drawCard()

    #expect(round.stockpile.count == stockpileCount - 1)
    #expect(round.playerHands[0].cards.count == handCount + 1)

    if case .waitingForPlayerToAct(let playerID, .hasDrawn) = round.state {
        #expect(playerID == "p1")
    } else {
        Issue.record("Expected hasDrawn state")
    }
}

@Test func drawCardAlreadyDrew() throws {
    var round: Round = try .init(players: [.fake(id: "p1"), .fake(id: "p2")])
    try round.drawCard()

    #expect(throws: KingsCornerError.alreadyDrew) {
        try round.drawCard()
    }
}

// MARK: - Play Card Tests

@Test func playCardOnFoundation() throws {
    let deck: [Card] = buildTestDeck()
    var round: Round = try .init(id: "test", deck: deck, players: [
        .fake(id: "p1", name: "Alice", points: 0),
        .fake(id: "p2", name: "Bob", points: 0),
    ])

    try round.drawCard()

    let northPile: [CardID] = round.piles[.north]!
    guard let topCard: Card = round.cardsMap[northPile.last!] else {
        Issue.record("No top card")
        return
    }

    let targetRank: Int = topCard.rank.rawValue - 1
    let targetColor: CardColor = topCard.color.opposite
    guard targetRank >= 1,
          let rank: Rank = Rank(rawValue: targetRank)
    else { return }

    let matchingCardID: CardID? = round.playerHands[0].cards.first { cardID in
        guard let card: Card = round.cardsMap[cardID] else { return false }
        return card.rank == rank && card.color == targetColor
    }

    if let cardID: CardID = matchingCardID {
        let handBefore: Int = round.playerHands[0].cards.count
        try round.playCard(cardID: cardID, on: .north)
        #expect(round.playerHands[0].cards.count == handBefore - 1)
        #expect(round.piles[.north]!.last == cardID)
    }
}

@Test func playKingToCorner() throws {
    let deck: [Card] = buildDeckWithKingInHand()
    var round: Round = try .init(id: "test", deck: deck, players: [
        .fake(id: "p1", name: "Alice", points: 0),
        .fake(id: "p2", name: "Bob", points: 0),
    ])

    try round.drawCard()

    let kingID: CardID? = round.playerHands[0].cards.first { cardID in
        round.cardsMap[cardID]?.isKing == true
    }

    guard let kingID else {
        Issue.record("No king in hand")
        return
    }

    try round.playCard(cardID: kingID, on: .northEast)
    #expect(round.piles[.northEast]!.contains(kingID))
}

@Test func playNonKingToCornerFails() throws {
    let deck: [Card] = buildTestDeck()
    var round: Round = try .init(id: "test", deck: deck, players: [
        .fake(id: "p1", name: "Alice", points: 0),
        .fake(id: "p2", name: "Bob", points: 0),
    ])

    try round.drawCard()

    let nonKingID: CardID? = round.playerHands[0].cards.first { cardID in
        round.cardsMap[cardID]?.isKing == false
    }
    guard let nonKingID else { return }

    #expect(throws: KingsCornerError.onlyKingsInCorners) {
        try round.playCard(cardID: nonKingID, on: .northEast)
    }
}

// MARK: - Move Pile Tests

@Test func movePile() throws {
    let deck: [Card] = buildDeckForPileMove()
    var round: Round = try .init(id: "test", deck: deck, players: [
        .fake(id: "p1", name: "Alice", points: 0),
        .fake(id: "p2", name: "Bob", points: 0),
    ])

    try round.drawCard()

    let moves: [(from: PilePosition, to: PilePosition)] = round.validPileMoves()
    if let move = moves.first {
        let sourceCount: Int = round.piles[move.from]!.count
        let destCount: Int = round.piles[move.to]!.count
        try round.movePile(from: move.from, to: move.to)
        #expect(round.piles[move.from]!.isEmpty)
        #expect(round.piles[move.to]!.count == sourceCount + destCount)
    }
}

@Test func moveEmptyPileFails() throws {
    var round: Round = try .init(players: [.fake(id: "p1"), .fake(id: "p2")])
    try round.drawCard()

    #expect(throws: KingsCornerError.cannotMoveEmptyPile) {
        try round.movePile(from: .northEast, to: .north)
    }
}

// MARK: - End Turn Tests

@Test func endTurnAdvancesPlayer() throws {
    var round: Round = try .init(players: [
        .fake(id: "p1"),
        .fake(id: "p2"),
        .fake(id: "p3"),
    ])

    try round.drawCard()
    try round.endTurn()

    if case .waitingForPlayerToAct(let playerID, .needsToDraw) = round.state {
        #expect(playerID == "p2")
    } else {
        Issue.record("Expected p2's turn")
    }

    try round.drawCard()
    try round.endTurn()

    if case .waitingForPlayerToAct(let playerID, .needsToDraw) = round.state {
        #expect(playerID == "p3")
    } else {
        Issue.record("Expected p3's turn")
    }

    try round.drawCard()
    try round.endTurn()

    if case .waitingForPlayerToAct(let playerID, .needsToDraw) = round.state {
        #expect(playerID == "p1")
    } else {
        Issue.record("Expected p1's turn (wrap around)")
    }
}

// MARK: - Scoring Tests

@Test func penaltyPointsOnRoundEnd() throws {
    let deck: [Card] = buildDeckForQuickWin()
    var round: Round = try .init(id: "test", deck: deck, players: [
        .fake(id: "p1", name: "Alice", points: 0),
        .fake(id: "p2", name: "Bob", points: 0),
    ])

    try playQuickWin(round: &round)

    #expect(round.isComplete)
    if case .roundComplete(let winnerID) = round.state {
        #expect(winnerID == "p1")
    }

    let winnerHand: PlayerHand = round.playerHands.first { $0.player.id == "p1" }!
    #expect(winnerHand.player.points == 0)

    let loserHand: PlayerHand = round.playerHands.first { $0.player.id == "p2" }!
    #expect(loserHand.player.points > 0)
}

// MARK: - Validation Helper Tests

@Test func validPositionsForCard() throws {
    var round: Round = try .init(players: [.fake(id: "p1"), .fake(id: "p2")])
    try round.drawCard()

    let kingID: CardID? = round.playerHands[0].cards.first { cardID in
        round.cardsMap[cardID]?.isKing == true
    }

    if let kingID {
        let positions: [PilePosition] = round.validPositions(for: kingID)
        let cornerPositions: [PilePosition] = positions.filter { $0.isCorner }
        #expect(cornerPositions.isEmpty == false)
    }
}

// MARK: - AI Tests

@Test func aiEasyCompletesWithoutError() throws {
    var round: Round = try .init(players: [.fake(id: "p1"), .fake(id: "p2")])
    let engine: AIEngine = .init(difficulty: .easy)

    for _ in 0 ..< 10 {
        guard round.isComplete == false else { break }
        engine.takeTurn(round: &round)
    }
}

@Test func aiMediumCompletesWithoutError() throws {
    var round: Round = try .init(players: [.fake(id: "p1"), .fake(id: "p2")])
    let engine: AIEngine = .init(difficulty: .medium)

    for _ in 0 ..< 50 {
        guard round.isComplete == false else { break }
        engine.takeTurn(round: &round)
    }
}

@Test func aiHardCompletesWithoutError() throws {
    var round: Round = try .init(players: [.fake(id: "p1"), .fake(id: "p2")])
    let engine: AIEngine = .init(difficulty: .hard)

    for _ in 0 ..< 50 {
        guard round.isComplete == false else { break }
        engine.takeTurn(round: &round)
    }
}

@Test func aiHardPlaysFullRound() throws {
    var round: Round = try .init(players: [.fake(id: "p1"), .fake(id: "p2")])
    let engine: AIEngine = .init(difficulty: .hard)

    var turnCount: Int = 0
    while round.isComplete == false && turnCount < 200 {
        engine.takeTurn(round: &round)
        turnCount += 1
    }

    if round.isComplete {
        if case .roundComplete(let winnerID) = round.state {
            #expect(winnerID != nil)
        }
    }
}

// MARK: - Full Round Playthrough

@Test func fullRoundPlaythrough() throws {
    let deck: [Card] = buildDeckForQuickWin()
    var round: Round = try .init(id: "test", deck: deck, players: [
        .fake(id: "p1", name: "Alice", points: 0),
        .fake(id: "p2", name: "Bob", points: 0),
    ])

    #expect(round.playerHands[0].cards.count == 7)
    #expect(round.playerHands[1].cards.count == 7)
    #expect(round.isComplete == false)

    try playQuickWin(round: &round)

    #expect(round.isComplete)
    if case .roundComplete(let winnerID) = round.state {
        #expect(winnerID == "p1")
    } else {
        Issue.record("Expected round complete")
    }
    #expect(round.playerHands[0].cards.isEmpty)
    #expect(round.ended != nil)
    #expect(round.log.actions.isEmpty == false)
}

// MARK: - Fake Tests

@Test func fakeRound() throws {
    let round: Round = try .fake()
    #expect(round.cardsMap.count == 52)
    #expect(round.playerHands.count == 2)
}

@Test func fakePlayer() {
    let player: Player = .fake()
    #expect(player.id.isEmpty == false)
    #expect(player.name.isEmpty == false)
}

@Test func fakeCard() {
    let card: Card = .fake()
    #expect(Suit.allCases.contains(card.suit))
    #expect(Rank.allCases.contains(card.rank))
}

@Test func fakeAIEngine() {
    let engine: AIEngine = .fake()
    #expect(engine.difficulty == .medium)
}

// MARK: - Card Placement Logic

@Test func cardCanBePlacedOn() {
    let blackSeven: Card = .init(id: 0, suit: .spades, rank: .seven)
    let redEight: Card = .init(id: 1, suit: .hearts, rank: .eight)
    let blackEight: Card = .init(id: 2, suit: .clubs, rank: .eight)
    let redNine: Card = .init(id: 3, suit: .diamonds, rank: .nine)

    #expect(blackSeven.canBePlacedOn(redEight) == true)
    #expect(blackSeven.canBePlacedOn(blackEight) == false)
    #expect(redEight.canBePlacedOn(redNine) == false)
    #expect(redEight.canBePlacedOn(blackSeven) == false)
}

// MARK: - Helpers

/// Builds a deterministic 52-card deck.
private func buildTestDeck() -> [Card] {
    var cards: [Card] = []
    var id: CardID = 0
    for suit in Suit.allCases {
        for rank in Rank.allCases {
            cards.append(Card(id: id, suit: suit, rank: rank))
            id += 1
        }
    }
    return cards
}

/// Builds a deck where Player 1's hand contains at least one King.
private func buildDeckWithKingInHand() -> [Card] {
    var cards: [Card] = buildTestDeck()
    let kingIndex: Int = cards.firstIndex { $0.rank == .king }!
    let lastIndex: Int = cards.count - 1
    cards.swapAt(kingIndex, lastIndex)
    return cards
}

/// Builds a deck designed so piles can be moved.
private func buildDeckForPileMove() -> [Card] {
    var cards: [Card] = []
    var id: CardID = 0

    func card(_ suit: Suit, _ rank: Rank) -> Card {
        let c: Card = .init(id: id, suit: suit, rank: rank)
        id += 1
        return c
    }

    // stockpile filler
    let fillerSuits: [Suit] = [.hearts, .diamonds, .clubs, .spades]
    for suit in fillerSuits {
        for rank: Rank in [.ace, .two, .three, .four, .five] {
            cards.append(card(suit, rank))
        }
    }
    for suit in fillerSuits {
        for rank: Rank in [.six, .seven, .eight] {
            cards.append(card(suit, rank))
        }
    }

    // foundations (dealt as last 4 after hands): 
    // N=9♠(black), S=10♥(red), E=J♣(black), W=Q♦(red)
    let foundationW: Card = card(.diamonds, .queen)
    let foundationE: Card = card(.clubs, .jack)
    let foundationS: Card = card(.hearts, .ten)
    let foundationN: Card = card(.spades, .nine)

    // Player 2 hand (7 cards)
    let p2Hand: [Card] = [
        card(.hearts, .ace),
        card(.clubs, .two),
        card(.diamonds, .three),
        card(.spades, .four),
        card(.hearts, .five),
        card(.clubs, .six),
        card(.diamonds, .seven),
    ]

    // Player 1 hand: king + other cards
    let p1Hand: [Card] = [
        card(.spades, .king),
        card(.hearts, .queen),
        card(.clubs, .nine),
        card(.diamonds, .eight),
        card(.hearts, .jack),
        card(.spades, .ten),
        card(.diamonds, .ace),
    ]

    // N pile has 9♠(black), S has 10♥(red) -> 9♠ can be placed on 10♥ (alternating, descending)
    cards.append(contentsOf: [foundationW, foundationE, foundationS, foundationN])
    cards.append(contentsOf: p2Hand)
    cards.append(contentsOf: p1Hand)

    return cards
}

/// Builds a deck designed so Player 1 can win quickly.
private func buildDeckForQuickWin() -> [Card] {
    var cards: [Card] = []
    var id: CardID = 0

    func card(_ suit: Suit, _ rank: Rank) -> Card {
        let c: Card = .init(id: id, suit: suit, rank: rank)
        id += 1
        return c
    }

    // Stockpile filler (will be at bottom of array = first in stockpile)
    var filler: [Card] = []
    for suit in Suit.allCases {
        for rank: Rank in [.ace, .two, .three, .four, .five] {
            filler.append(card(suit, rank))
        }
    }

    // Stockpile top card (drawn by p1): 4♥
    let drawCard: Card = card(.hearts, .four)

    // Foundations: N=7♠(black), S=8♥(red), E=9♣(black), W=10♦(red)
    let foundationW: Card = card(.diamonds, .ten)
    let foundationE: Card = card(.clubs, .nine)
    let foundationS: Card = card(.hearts, .eight)
    let foundationN: Card = card(.spades, .seven)

    // Player 2 hand (7 cards - doesn't matter, just filler)
    let p2Hand: [Card] = [
        card(.hearts, .ace),
        card(.clubs, .two),
        card(.diamonds, .three),
        card(.spades, .jack),
        card(.hearts, .queen),
        card(.clubs, .ace),
        card(.diamonds, .two),
    ]

    // Player 1 hand - carefully chosen so they can play all cards:
    // K♠(black), Q♥(red), 6♥(red), 5♠(black), 7♣(black), 8♦(red), 9♠(black)
    //
    // Play sequence:
    // 1. Draw 4♥
    // 2. K♠ -> NE corner
    // 3. Q♥ -> NE (on K♠) 
    // 4. 6♥ -> N (on 7♠)
    // 5. 5♠ -> N (on 6♥)
    // 6. 4♥ -> N (on 5♠)
    // 7. 7♣ -> S (on 8♥)
    // 8. 8♦ -> E (on 9♣)
    // 9. 9♠ -> W (on 10♦)
    let p1Hand: [Card] = [
        card(.spades, .king),
        card(.hearts, .queen),
        card(.hearts, .six),
        card(.spades, .five),
        card(.clubs, .seven),
        card(.diamonds, .eight),
        card(.spades, .nine),
    ]

    // Assemble deck: [filler..., drawCard, foundations, p2Hand, p1Hand]
    cards.append(contentsOf: filler)
    cards.append(drawCard)
    cards.append(contentsOf: [foundationW, foundationE, foundationS, foundationN])
    cards.append(contentsOf: p2Hand)
    cards.append(contentsOf: p1Hand)

    return cards
}

/// Plays the quick win sequence for Player 1 on a round built with buildDeckForQuickWin().
private func playQuickWin(round: inout Round) throws {
    // Player 1's turn
    try round.drawCard()

    let hand: [CardID] = round.playerHands[0].cards

    let kingID: CardID = hand.first { round.cardsMap[$0]?.rank == .king && round.cardsMap[$0]?.suit == .spades }!
    let queenID: CardID = hand.first { round.cardsMap[$0]?.rank == .queen && round.cardsMap[$0]?.suit == .hearts }!
    let six_heartsID: CardID = hand.first { round.cardsMap[$0]?.rank == .six && round.cardsMap[$0]?.suit == .hearts }!
    let five_spadesID: CardID = hand.first { round.cardsMap[$0]?.rank == .five && round.cardsMap[$0]?.suit == .spades }!
    let four_heartsID: CardID = round.playerHands[0].cards.first { round.cardsMap[$0]?.rank == .four && round.cardsMap[$0]?.suit == .hearts }!
    let seven_clubsID: CardID = hand.first { round.cardsMap[$0]?.rank == .seven && round.cardsMap[$0]?.suit == .clubs }!
    let eight_diamondsID: CardID = hand.first { round.cardsMap[$0]?.rank == .eight && round.cardsMap[$0]?.suit == .diamonds }!
    let nine_spadesID: CardID = hand.first { round.cardsMap[$0]?.rank == .nine && round.cardsMap[$0]?.suit == .spades }!

    try round.playCard(cardID: kingID, on: .northEast)
    try round.playCard(cardID: queenID, on: .northEast)
    try round.playCard(cardID: six_heartsID, on: .north)
    try round.playCard(cardID: five_spadesID, on: .north)
    try round.playCard(cardID: four_heartsID, on: .north)
    try round.playCard(cardID: seven_clubsID, on: .south)
    try round.playCard(cardID: eight_diamondsID, on: .east)
    try round.playCard(cardID: nine_spadesID, on: .west)
}
