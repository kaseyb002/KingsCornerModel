import Foundation

public enum PilePosition: String, Equatable, Codable, Sendable, CaseIterable, Hashable {
    case north
    case south
    case east
    case west
    case northEast
    case northWest
    case southEast
    case southWest

    public var isCorner: Bool {
        switch self {
        case .northEast, .northWest, .southEast, .southWest: true
        case .north, .south, .east, .west: false
        }
    }

    public var isFoundation: Bool { isCorner == false }

    public static let foundations: [PilePosition] = [.north, .south, .east, .west]
    public static let corners: [PilePosition] = [.northEast, .northWest, .southEast, .southWest]

    public var displayableName: String {
        switch self {
        case .north: "North"
        case .south: "South"
        case .east: "East"
        case .west: "West"
        case .northEast: "North East"
        case .northWest: "North West"
        case .southEast: "South East"
        case .southWest: "South West"
        }
    }
}
