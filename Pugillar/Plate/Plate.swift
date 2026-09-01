import Foundation

/// Role: Plate. One wax recess on a leaf. Ink may be written while the foreign plate stays shuttered.
struct Plate: Codable, Equatable, Sendable, Identifiable {
    let hand: HandSide
    var ink: String

    var id: HandSide { hand }

    var hasInk: Bool {
        !ink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func blank(hand: HandSide) -> Plate {
        Plate(hand: hand, ink: "")
    }
}
