import Foundation

/// Role: Leaf. Frozen pair record written when the seam seals. Immutable after seal.
struct PairEntry: Codable, Equatable, Sendable {
    let sealedAtUnixMilliseconds: Int64
    let alphaInk: String
    let betaInk: String
    let promptQuestion: String?
    let promptAlphaAnswer: String?
    let promptBetaAnswer: String?

    static func unixMilliseconds(from date: Date) -> Int64 {
        Int64(date.timeIntervalSince1970 * 1000)
    }

    static func date(from unixMilliseconds: Int64) -> Date {
        Date(timeIntervalSince1970: TimeInterval(unixMilliseconds) / 1000)
    }
}
