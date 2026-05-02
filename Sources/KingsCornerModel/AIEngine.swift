import Foundation

public struct AIEngine: Equatable, Codable, Sendable {
    public enum Difficulty: String, Equatable, Codable, Sendable, CaseIterable {
        case easy
        case medium
        case hard

        public var displayableName: String {
            switch self {
            case .easy: "Easy"
            case .medium: "Medium"
            case .hard: "Hard"
            }
        }
    }

    public let difficulty: Difficulty

    public init(difficulty: Difficulty = .medium) {
        self.difficulty = difficulty
    }

    public static func fake(
        difficulty: Difficulty = .medium
    ) -> AIEngine {
        .init(difficulty: difficulty)
    }

    // MARK: - Public Entry Point

    public func takeTurn(round: inout Round) {
        guard case .waitingForPlayerToAct(_, .needsToDraw) = round.state else { return }

        do {
            try round.drawCard()
        } catch {
            return
        }

        switch difficulty {
        case .easy:
            playEasy(round: &round)
        case .medium:
            playMedium(round: &round)
        case .hard:
            playHard(round: &round)
        }

        guard round.isComplete == false else { return }
        try? round.endTurn()
    }

    // MARK: - Easy

    /// Plays one random valid card, then ends turn.
    private func playEasy(round: inout Round) {
        guard let hand: PlayerHand = round.currentPlayerHand else { return }

        for cardID in hand.cards.shuffled() {
            let positions: [PilePosition] = round.validPositions(for: cardID)
            if let position: PilePosition = positions.randomElement() {
                try? round.playCard(cardID: cardID, on: position)
                return
            }
        }
    }

    // MARK: - Medium

    /// Plays Kings to corners, then plays all obvious single-card placements.
    private func playMedium(round: inout Round) {
        guard round.isComplete == false else { return }
        playKingsToCorners(round: &round)
        playAllMatchingCards(round: &round)
    }

    // MARK: - Hard

    /// Plays Kings first, then moves piles to free foundation spots, then plays all cards.
    /// Repeats until no more progress can be made.
    private func playHard(round: inout Round) {
        guard round.isComplete == false else { return }

        var madeProgress: Bool = true
        while madeProgress && round.isComplete == false {
            madeProgress = false

            if playKingsToCorners(round: &round) { madeProgress = true }
            if movePilesToFreeFoundations(round: &round) { madeProgress = true }
            if playAllMatchingCards(round: &round) { madeProgress = true }
            if movePilesToBuildSequences(round: &round) { madeProgress = true }
        }
    }

    // MARK: - Shared Helpers

    @discardableResult
    private func playKingsToCorners(round: inout Round) -> Bool {
        guard let hand: PlayerHand = round.currentPlayerHand else { return false }
        var played: Bool = false

        for cardID in hand.cards {
            guard let card: Card = round.cardsMap[cardID], card.isKing else { continue }
            for corner in PilePosition.corners {
                if round.canPlayCard(cardID, on: corner) {
                    try? round.playCard(cardID: cardID, on: corner)
                    played = true
                    if round.isComplete { return true }
                    break
                }
            }
        }
        return played
    }

    @discardableResult
    private func playAllMatchingCards(round: inout Round) -> Bool {
        var played: Bool = false
        var madeProgress: Bool = true

        while madeProgress && round.isComplete == false {
            madeProgress = false
            guard let hand: PlayerHand = round.currentPlayerHand else { break }

            for cardID in hand.cards {
                guard round.cardsMap[cardID]?.isKing == false else { continue }
                let positions: [PilePosition] = round.validPositions(for: cardID)
                if let bestPosition: PilePosition = pickBestPosition(positions, round: round) {
                    try? round.playCard(cardID: cardID, on: bestPosition)
                    madeProgress = true
                    played = true
                    if round.isComplete { return true }
                    break
                }
            }
        }
        return played
    }

    private func pickBestPosition(_ positions: [PilePosition], round: Round) -> PilePosition? {
        guard positions.isEmpty == false else { return nil }
        if difficulty == .easy { return positions.randomElement() }

        return positions.max { a, b in
            let aPile: [CardID] = round.piles[a] ?? []
            let bPile: [CardID] = round.piles[b] ?? []
            return aPile.count < bPile.count
        }
    }

    @discardableResult
    private func movePilesToFreeFoundations(round: inout Round) -> Bool {
        var moved: Bool = false

        for foundation in PilePosition.foundations {
            guard let pile: [CardID] = round.piles[foundation], pile.isEmpty == false else {
                continue
            }
            guard let bottomCard: Card = round.cardsMap[pile[0]] else { continue }

            if bottomCard.isKing {
                for corner in PilePosition.corners {
                    if round.canMovePile(from: foundation, to: corner) {
                        try? round.movePile(from: foundation, to: corner)
                        moved = true
                        break
                    }
                }
            } else {
                for dest in PilePosition.allCases where dest != foundation {
                    if round.canMovePile(from: foundation, to: dest) {
                        try? round.movePile(from: foundation, to: dest)
                        moved = true
                        break
                    }
                }
            }
        }
        return moved
    }

    @discardableResult
    private func movePilesToBuildSequences(round: inout Round) -> Bool {
        let moves: [(from: PilePosition, to: PilePosition)] = round.validPileMoves()
        for move in moves {
            guard let sourcePile: [CardID] = round.piles[move.from],
                  sourcePile.isEmpty == false
            else { continue }

            let sourceIsFoundation: Bool = move.from.isFoundation
            if sourceIsFoundation {
                try? round.movePile(from: move.from, to: move.to)
                return true
            }
        }
        return false
    }
}
