import Foundation

/// Role: Plate. What a view may see. Shuttered faces never carry ink.
enum PlateFace: Equatable, Sendable {
    case shuttered
    case drafting(String)
    case revealed(String)

    var readableInk: String? {
        switch self {
        case .shuttered:
            return nil
        case .drafting(let ink), .revealed(let ink):
            return ink
        }
    }

    var isDrafting: Bool {
        if case .drafting = self { return true }
        return false
    }

    var isShuttered: Bool {
        if case .shuttered = self { return true }
        return false
    }
}

/// Role: Plate. In-place two-halves gate. Beta stays locked until alpha answers.
struct PromptGate: Equatable, Sendable {
    var question: String
    var alphaAnswer: String
    var betaAnswer: String
    var betaUnlocked: Bool
}

/// Role: Plate. Blind-seam encoding of one Leaf. Views bind this, never a shuttered Plate.
struct DiptychSnapshot: Equatable, Sendable {
    var leafID: UUID
    var dayKey: LeafDayKey
    var writing: HandSide
    var alpha: PlateFace
    var beta: PlateFace
    var prompt: PromptGate?
    var canSeal: Bool
    var isSealed: Bool
    var isEmpty: Bool
    var isRevealing: Bool

    func face(for hand: HandSide) -> PlateFace {
        switch hand {
        case .alpha: alpha
        case .beta: beta
        }
    }

    func replacing(hand: HandSide, ink: String) -> DiptychSnapshot {
        var next = self
        switch hand {
        case .alpha:
            if case .shuttered = next.alpha { return self }
            next.alpha = next.isSealed ? .revealed(ink) : .drafting(ink)
        case .beta:
            if case .shuttered = next.beta { return self }
            next.beta = next.isSealed ? .revealed(ink) : .drafting(ink)
        }
        let alphaInk = next.alpha.readableInk ?? ""
        let betaInk = next.beta.readableInk ?? ""
        next.canSeal = Plate(hand: .alpha, ink: alphaInk).hasInk
            && Plate(hand: .beta, ink: betaInk).hasInk
            && !next.isSealed
        next.isEmpty = !Plate(hand: .alpha, ink: alphaInk).hasInk
            && !Plate(hand: .beta, ink: betaInk).hasInk
        return next
    }
}

/// Role: Bond. Display tally. Days from BondTally, never a raw interpolated Int.
struct BondSnapshot: Equatable, Sendable {
    var alphaName: String
    var betaName: String
    var bondedAt: Date
    var days: Int
    var reached: [Int]
    var next: Int?
    var sealedLeaves: Int
}

/// Role: Shelf. One sealed leaf as a card. Ink is already revealed.
struct ShelfCard: Equatable, Sendable, Identifiable {
    var id: UUID
    var dayKey: LeafDayKey
    var alphaInk: String
    var betaInk: String
    var sealedAt: Date?
    var question: String?
}

/// Role: Plate. Encodes a Leaf so views never read a shuttered plate and never mutate a sealed leaf.
enum BlindSeam {
    static func snapshot(
        leaf: Leaf,
        writing: HandSide,
        revealing: Bool = false
    ) -> DiptychSnapshot {
        DiptychSnapshot(
            leafID: leaf.id,
            dayKey: leaf.dayKey,
            writing: writing,
            alpha: face(leaf.alphaPlate, leaf: leaf, writing: writing, revealing: revealing),
            beta: face(leaf.betaPlate, leaf: leaf, writing: writing, revealing: revealing),
            prompt: leaf.prompt.map {
                PromptGate(
                    question: $0.question,
                    alphaAnswer: $0.alphaAnswer,
                    betaAnswer: $0.betaAnswer,
                    betaUnlocked: $0.betaUnlocked
                )
            },
            canSeal: leaf.canSeal,
            isSealed: leaf.isSealed,
            isEmpty: !leaf.alphaPlate.hasInk && !leaf.betaPlate.hasInk,
            isRevealing: revealing
        )
    }

    static func bond(
        _ record: BondRecord,
        sealedLeaves: Int,
        now: Date,
        calendar: Calendar
    ) -> BondSnapshot {
        let days = BondTally.bondDays(bondedAt: record.bondedAt, now: now, calendar: calendar)
        return BondSnapshot(
            alphaName: record.handAlphaName,
            betaName: record.handBetaName,
            bondedAt: record.bondedAt,
            days: days,
            reached: BondTally.reachedMilestones(bondDays: days),
            next: BondTally.nextMilestone(after: days),
            sealedLeaves: sealedLeaves
        )
    }

    static func shelf(from leaves: [Leaf]) -> [ShelfCard] {
        ShelfStack.entries(from: leaves).map { leaf in
            ShelfCard(
                id: leaf.id,
                dayKey: leaf.dayKey,
                alphaInk: leaf.pairEntry?.alphaInk ?? leaf.alphaPlate.ink,
                betaInk: leaf.pairEntry?.betaInk ?? leaf.betaPlate.ink,
                sealedAt: leaf.pairEntry.map { PairEntry.date(from: $0.sealedAtUnixMilliseconds) },
                question: leaf.pairEntry?.promptQuestion ?? leaf.prompt?.question
            )
        }
    }

    static func name(_ hand: HandSide, bond: BondSnapshot?) -> String {
        switch hand {
        case .alpha: bond?.alphaName ?? "Alpha"
        case .beta: bond?.betaName ?? "Beta"
        }
    }

    private static func face(
        _ plate: Plate,
        leaf: Leaf,
        writing: HandSide,
        revealing: Bool
    ) -> PlateFace {
        if leaf.isSealed || revealing {
            return .revealed(plate.ink)
        }
        if plate.hand == .beta, let prompt = leaf.prompt, !prompt.canInk(on: .beta) {
            return .shuttered
        }
        if leaf.canSeal || plate.hand == writing {
            return .drafting(plate.ink)
        }
        return .shuttered
    }
}
