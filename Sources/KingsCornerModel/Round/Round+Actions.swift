import Foundation

extension Round {

    // MARK: - Draw

    public mutating func drawCard() throws {
        guard case .waitingForPlayerToAct(let playerID, .needsToDraw) = state else {
            throw KingsCornerError.alreadyDrew
        }
        guard let playerIndex: Int = currentPlayerHandIndex else {
            throw KingsCornerError.notYourTurn
        }

        if let cardID: CardID = stockpile.popLast() {
            playerHands[playerIndex].cards.append(cardID)
            log.addAction(.init(playerID: playerID, decision: .draw(cardID: cardID)))
        }

        state = .waitingForPlayerToAct(playerID: playerID, drawState: .hasDrawn)
    }

    // MARK: - Play Card

    public mutating func playCard(cardID: CardID, on position: PilePosition) throws {
        guard case .waitingForPlayerToAct(let playerID, .hasDrawn) = state else {
            throw KingsCornerError.needsToDraw
        }
        guard let playerIndex: Int = currentPlayerHandIndex else {
            throw KingsCornerError.notYourTurn
        }
        guard let cardIndex: Int = playerHands[playerIndex].cards.firstIndex(of: cardID) else {
            throw KingsCornerError.cardNotInHand
        }
        guard let card: Card = cardsMap[cardID] else {
            throw KingsCornerError.cardNotInHand
        }
        guard var pile: [CardID] = piles[position] else {
            throw KingsCornerError.pileNotFound
        }

        try validatePlay(card: card, onPile: pile, at: position)

        pile.append(cardID)
        piles[position] = pile
        playerHands[playerIndex].cards.remove(at: cardIndex)

        log.addAction(.init(playerID: playerID, decision: .playCard(cardID: cardID, position: position)))

        if playerHands[playerIndex].cards.isEmpty {
            completeRound(winnerID: playerID)
        }
    }

    // MARK: - Move Pile

    public mutating func movePile(from source: PilePosition, to destination: PilePosition) throws {
        guard case .waitingForPlayerToAct(let playerID, .hasDrawn) = state else {
            throw KingsCornerError.needsToDraw
        }
        guard let sourcePile: [CardID] = piles[source], sourcePile.isEmpty == false else {
            throw KingsCornerError.cannotMoveEmptyPile
        }
        guard let destPile: [CardID] = piles[destination] else {
            throw KingsCornerError.pileNotFound
        }
        guard let bottomOfSource: Card = cardsMap[sourcePile[0]] else {
            throw KingsCornerError.cannotMoveEmptyPile
        }

        if destPile.isEmpty {
            if destination.isCorner {
                guard bottomOfSource.isKing else {
                    throw KingsCornerError.onlyKingsInCorners
                }
            }
        } else {
            guard let topOfDest: Card = cardsMap[destPile.last!] else {
                throw KingsCornerError.pileNotFound
            }
            guard bottomOfSource.canBePlacedOn(topOfDest) else {
                throw KingsCornerError.incompatiblePiles
            }
        }

        piles[destination] = destPile + sourcePile
        piles[source] = []

        log.addAction(.init(playerID: playerID, decision: .movePile(from: source, to: destination)))
    }

    // MARK: - End Turn

    public mutating func endTurn() throws {
        guard case .waitingForPlayerToAct(_, .hasDrawn) = state else {
            throw KingsCornerError.needsToDraw
        }
        guard let currentIndex: Int = currentPlayerHandIndex else {
            throw KingsCornerError.notYourTurn
        }

        let nextIndex: Int = (currentIndex + 1) % playerHands.count
        let nextPlayerID: PlayerID = playerHands[nextIndex].player.id

        state = .waitingForPlayerToAct(
            playerID: nextPlayerID,
            drawState: .needsToDraw
        )
    }

    // MARK: - Validation

    private func validatePlay(card: Card, onPile pile: [CardID], at position: PilePosition) throws {
        if pile.isEmpty {
            if position.isCorner {
                guard card.isKing else {
                    throw KingsCornerError.onlyKingsInCorners
                }
            }
        } else {
            guard let topCard: Card = cardsMap[pile.last!] else {
                throw KingsCornerError.pileNotFound
            }
            guard card.canBePlacedOn(topCard) else {
                throw KingsCornerError.invalidPlay
            }
        }
    }

    private mutating func completeRound(winnerID: PlayerID) {
        state = .roundComplete(winnerID: winnerID)
        ended = .now
        addPenaltyPoints()
    }
}
