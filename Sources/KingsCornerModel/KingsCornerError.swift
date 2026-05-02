import Foundation

public enum KingsCornerError: Error, Equatable, Sendable {
    case notEnoughPlayers
    case tooManyPlayers
    case notYourTurn
    case needsToDraw
    case alreadyDrew
    case cardNotInHand
    case invalidPlay
    case onlyKingsInCorners
    case cannotMoveEmptyPile
    case incompatiblePiles
    case roundAlreadyComplete
    case pileNotFound
}
