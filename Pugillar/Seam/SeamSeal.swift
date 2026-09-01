import Foundation

/// Role: Seam. Home verb. Seal stays dead until both plates hold ink; then the leaf freezes.
enum SeamSeal {
    enum Failure: Error, Equatable, Sendable {
        case deadSeal
        case alreadySealed
        case betaLocked
    }

    static func apply(to leaf: Leaf, at date: Date) throws -> Leaf {
        guard !leaf.isSealed else { throw Failure.alreadySealed }
        guard leaf.canSeal else { throw Failure.deadSeal }

        var sealed = leaf
        sealed.isSealed = true
        sealed.pairEntry = PairEntry(
            sealedAtUnixMilliseconds: PairEntry.unixMilliseconds(from: date),
            alphaInk: leaf.alphaPlate.ink,
            betaInk: leaf.betaPlate.ink,
            promptQuestion: leaf.prompt?.question,
            promptAlphaAnswer: leaf.prompt?.alphaAnswer,
            promptBetaAnswer: leaf.prompt?.betaAnswer
        )
        return sealed
    }

    static func ink(_ text: String, on hand: HandSide, leaf: Leaf) throws -> Leaf {
        guard !leaf.isSealed else { throw Failure.alreadySealed }
        if let prompt = leaf.prompt, !prompt.canInk(on: hand) {
            throw Failure.betaLocked
        }
        var next = leaf
        switch hand {
        case .alpha:
            next.alphaPlate.ink = text
        case .beta:
            next.betaPlate.ink = text
        }
        return next
    }

    static func answerPrompt(_ text: String, on hand: HandSide, leaf: Leaf) throws -> Leaf {
        guard !leaf.isSealed else { throw Failure.alreadySealed }
        guard var prompt = leaf.prompt else { return try ink(text, on: hand, leaf: leaf) }
        switch hand {
        case .alpha:
            prompt.alphaAnswer = text
        case .beta:
            guard prompt.betaUnlocked else { throw Failure.betaLocked }
            prompt.betaAnswer = text
        }
        var next = leaf
        next.prompt = prompt
        return next
    }
}
