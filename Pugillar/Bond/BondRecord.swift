import Foundation

/// Role: Bond. Named hands and the bond date stamped on onboarding.
struct BondRecord: Codable, Equatable, Sendable {
    var handAlphaName: String
    var handBetaName: String
    var bondedAtUnixMilliseconds: Int64

    var bondedAt: Date {
        PairEntry.date(from: bondedAtUnixMilliseconds)
    }

    static func fresh(
        handAlphaName: String,
        handBetaName: String,
        bondedAt: Date
    ) -> BondRecord {
        BondRecord(
            handAlphaName: handAlphaName,
            handBetaName: handBetaName,
            bondedAtUnixMilliseconds: PairEntry.unixMilliseconds(from: bondedAt)
        )
    }
}
