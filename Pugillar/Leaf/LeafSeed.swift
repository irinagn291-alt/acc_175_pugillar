import Foundation

/// Role: Leaf. Simulator demo leaves. Device never writes this. Key: pgl.demo.v1.
enum LeafSeed {
    static let sealedLeafID = uuid("11111111-1111-4111-8111-111111111111")
    static let homeLeafID = uuid("22222222-2222-4222-8222-222222222222")

    private static func uuid(_ raw: String) -> UUID {
        guard let value = UUID(uuidString: raw) else {
            fatalError("Demo seed UUID literal is invalid")
        }
        return value
    }

    static func bond(on date: Date) -> BondRecord {
        BondRecord.fresh(
            handAlphaName: "North Hand",
            handBetaName: "South Hand",
            bondedAt: date.addingTimeInterval(-86400 * 14)
        )
    }

    static func sealedLeaf(on date: Date, calendar: Calendar) -> Leaf {
        sealedLeaves(on: date, calendar: calendar)[0]
    }

    static func sealedLeaves(on date: Date, calendar: Calendar) -> [Leaf] {
        let rows: [(String, Int, String, String)] = [
            (
                "11111111-1111-4111-8111-111111111111",
                -3,
                "The wax held our first line. I wrote while the south shutter stayed down.",
                "Sealed when both halves met. The seam opened and the leaf froze."
            ),
            (
                "33333333-3333-4333-8333-333333333333",
                -8,
                "Rain on the boards. I kept the stylus moving so the recess would not set.",
                "I answered after you passed the tablet. Neither of us read until Seal."
            ),
            (
                "44444444-4444-4444-8444-444444444444",
                -15,
                "Seven days in, the bond count sat on the rail. I wrote the night we almost skipped.",
                "I filled the south plate late. Midnight did not file us. Seal did."
            ),
            (
                "55555555-5555-4555-8555-555555555555",
                -21,
                "The first week mark. I listed what we would not say out loud.",
                "South wrote the rest. The hinge opened. The shelf took the leaf."
            ),
        ]
        return rows.map { raw, offset, alpha, beta in
            let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: date)) ?? date
            var leaf = Leaf.blank(on: day, calendar: calendar, id: uuid(raw))
            leaf.alphaPlate.ink = alpha
            leaf.betaPlate.ink = beta
            leaf.isSealed = true
            leaf.pairEntry = PairEntry(
                sealedAtUnixMilliseconds: PairEntry.unixMilliseconds(from: day.addingTimeInterval(20 * 3600)),
                alphaInk: alpha,
                betaInk: beta,
                promptQuestion: nil,
                promptAlphaAnswer: nil,
                promptBetaAnswer: nil
            )
            return leaf
        }
    }

    static func homeLeaf(on date: Date, calendar: Calendar) -> Leaf {
        var leaf = Leaf.blank(on: date, calendar: calendar, id: homeLeafID)
        leaf.alphaPlate.ink = "Morning on this plate. I wrote the north half and passed the tablet."
        leaf.betaPlate.ink = "Evening on this plate. Both recesses hold ink. Tap Seal the seam."
        return leaf
    }
}
