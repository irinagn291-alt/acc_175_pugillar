import Foundation

/// Role: Leaf. One diptych document — two plates, optional prompt, sealed or open.
struct Leaf: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    let dayKey: LeafDayKey
    var alphaPlate: Plate
    var betaPlate: Plate
    var prompt: Prompt?
    var isSealed: Bool
    var pairEntry: PairEntry?

    var canSeal: Bool {
        alphaPlate.hasInk && betaPlate.hasInk && !isSealed
    }

    static func blank(on date: Date, calendar: Calendar, id: UUID = UUID()) -> Leaf {
        Leaf(
            id: id,
            dayKey: LeafDayKey.from(date, calendar: calendar),
            alphaPlate: .blank(hand: .alpha),
            betaPlate: .blank(hand: .beta),
            prompt: nil,
            isSealed: false,
            pairEntry: nil
        )
    }
}
