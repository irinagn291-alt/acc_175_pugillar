import Foundation

/// Role: Leaf. Daily questions both people answer on today's page.
enum DayAsk {
    static let questions: [String] = [
        "What do you want the other person to know about today?",
        "What was the best five minutes of the day?",
        "What do you need from each other tomorrow?",
        "What made you laugh?",
        "What do you want to remember from today?",
        "What felt heavy, and what helped?",
        "What are you grateful they did?",
        "If today had a title, what would it be?",
        "What should we do together this week?",
        "What are you looking forward to?",
        "What do you wish you had said out loud?",
        "What small win should we keep?",
    ]

    static func at(_ index: Int) -> String {
        questions[((index % questions.count) + questions.count) % questions.count]
    }
}
