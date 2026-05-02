import Foundation

extension Player {
    public var logValue: String {
        """
        ID: \(id)
        Name: \(name)
        Points: \(points)
        """
    }
}

extension [Player] {
    public var logValue: String {
        map { $0.logValue }.joined(separator: "\n\n")
    }
}
