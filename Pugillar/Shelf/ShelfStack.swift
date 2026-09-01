import Foundation

/// Role: Shelf. Local stack of sealed leaves only — no public feed.
enum ShelfStack {
    static func entries(from leaves: [Leaf]) -> [Leaf] {
        leaves
            .filter(\.isSealed)
            .sorted { lhs, rhs in
                let left = lhs.pairEntry?.sealedAtUnixMilliseconds ?? 0
                let right = rhs.pairEntry?.sealedAtUnixMilliseconds ?? 0
                if left != right { return left > right }
                return lhs.dayKey > rhs.dayKey
            }
    }

    static func sealedCount(from leaves: [Leaf]) -> Int {
        leaves.filter(\.isSealed).count
    }
}
