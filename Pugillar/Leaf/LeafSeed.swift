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
            handAlphaName: "Alex",
            handBetaName: "Sam",
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
                -1,
                "Tired, but dinner was good. Glad we sat down for this.",
                "Same. I liked the walk home more than I said."
            ),
            (
                "33333333-3333-4333-8333-333333333333",
                -2,
                "Work ran long. I still wanted to write you first.",
                "I saved the last cookie. Come get it tomorrow."
            ),
            (
                "44444444-4444-4444-8444-444444444444",
                -3,
                "Rain all afternoon. The apartment felt like ours again.",
                "Put on the record when you get in. I’ll make tea."
            ),
            (
                "55555555-5555-4555-8555-555555555555",
                -5,
                "Quiet Sunday. I needed that more than I knew.",
                "Next Sunday let’s leave the phones in the other room."
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
        leaf.alphaPlate.ink = "Long day. Glad we still sit down for this."
        leaf.betaPlate.ink = "Same. I liked the walk home."
        return leaf
    }
}
