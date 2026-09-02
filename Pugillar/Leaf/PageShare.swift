import SwiftUI
import UIKit

@MainActor
enum PageShare {
    static func day(_ card: ShelfCard, alpha: String, beta: String) -> String {
        let when = card.sealedAt.map(WaxFigures.day) ?? card.dayKey.fileName
        var lines = ["Pugillar — \(when)"]
        if let question = card.question, !question.isEmpty {
            lines.append(question)
        }
        lines.append("\(alpha):")
        lines.append(card.alphaInk)
        lines.append("\(beta):")
        lines.append(card.betaInk)
        return lines.joined(separator: "\n\n")
    }

    static func book(_ cards: [ShelfCard], alpha: String, beta: String) -> String {
        guard !cards.isEmpty else { return "Pugillar — no saved days yet." }
        return cards.map { day($0, alpha: alpha, beta: beta) }.joined(separator: "\n\n———\n\n")
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
