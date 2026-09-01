import Foundation

/// Role: Leaf. Two-halves gate: alpha answers before beta may ink.
struct Prompt: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    var question: String
    var alphaAnswer: String
    var betaAnswer: String

    init(id: UUID = UUID(), question: String, alphaAnswer: String = "", betaAnswer: String = "") {
        self.id = id
        self.question = question
        self.alphaAnswer = alphaAnswer
        self.betaAnswer = betaAnswer
    }

    var betaUnlocked: Bool {
        !alphaAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func canInk(on hand: HandSide) -> Bool {
        switch hand {
        case .alpha:
            return true
        case .beta:
            return betaUnlocked
        }
    }
}
