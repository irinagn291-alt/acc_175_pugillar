import Foundation

/// Role: Bond. Pure bond-day math. bondDays = startOfDay(now) − startOfDay(bondedAt).
enum BondTally {
    static let milestones = [7, 30, 90, 365]

    static func bondDays(bondedAt: Date, now: Date, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: bondedAt)
        let today = calendar.startOfDay(for: now)
        return calendar.dateComponents([.day], from: start, to: today).day ?? 0
    }

    static func reachedMilestones(bondDays: Int) -> [Int] {
        milestones.filter { bondDays >= $0 }
    }

    static func nextMilestone(after bondDays: Int) -> Int? {
        milestones.first { bondDays < $0 }
    }
}
