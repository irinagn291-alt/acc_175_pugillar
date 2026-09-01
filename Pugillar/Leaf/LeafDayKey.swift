import Foundation

/// Role: Leaf. Day identity from Calendar.startOfDay — year, month, day, never YYYYMMDD Int.
struct LeafDayKey: Codable, Equatable, Hashable, Sendable, Comparable {
    let year: Int
    let month: Int
    let day: Int

    static func from(_ date: Date, calendar: Calendar) -> LeafDayKey {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        return LeafDayKey(
            year: parts.year ?? 1,
            month: parts.month ?? 1,
            day: parts.day ?? 1
        )
    }

    func date(calendar: Calendar) -> Date? {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        return calendar.date(from: parts).map { calendar.startOfDay(for: $0) }
    }

    var fileName: String {
        String(format: "%04d-%02d-%02d.json", year, month, day)
    }

    static func < (lhs: LeafDayKey, rhs: LeafDayKey) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }
}
