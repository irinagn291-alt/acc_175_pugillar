import Foundation

/// Role: Leaf. Streak, week marks, word counts. Views never compute these.
enum PageMath {
    struct WeekDay: Equatable, Identifiable, Sendable {
        var id: LeafDayKey
        var short: String
        var saved: Bool
        var isToday: Bool
    }

    static func words(in text: String) -> Int {
        text.split { $0.isWhitespace || $0.isNewline }.filter { !$0.isEmpty }.count
    }

    static func streak(days: [Date], now: Date, calendar: Calendar) -> Int {
        let saved = Set(days.map { calendar.startOfDay(for: $0) })
        let today = calendar.startOfDay(for: now)
        let cursor = saved.contains(today) ? today : calendar.date(byAdding: .day, value: -1, to: today)
        guard var day = cursor, saved.contains(day) else { return 0 }
        var count = 0
        while saved.contains(day) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    static func count(inMonthOf now: Date, days: [Date], calendar: Calendar) -> Int {
        let parts = calendar.dateComponents([.year, .month], from: now)
        return days.filter { day in
            let other = calendar.dateComponents([.year, .month], from: day)
            return other.year == parts.year && other.month == parts.month
        }.count
    }

    static func count(lastDays window: Int, days: [Date], now: Date, calendar: Calendar) -> Int {
        let today = calendar.startOfDay(for: now)
        guard let start = calendar.date(byAdding: .day, value: -(max(window, 1) - 1), to: today) else {
            return 0
        }
        return days.filter { calendar.startOfDay(for: $0) >= start }.count
    }

    static func week(
        now: Date,
        saved: [LeafDayKey],
        calendar: Calendar
    ) -> [WeekDay] {
        let today = calendar.startOfDay(for: now)
        let keys = Set(saved)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = calendar.locale ?? .current
        formatter.dateFormat = "EEE"
        return (0..<7).compactMap { offset -> WeekDay? in
            guard let date = calendar.date(byAdding: .day, value: offset - 6, to: today) else { return nil }
            let key = LeafDayKey.from(date, calendar: calendar)
            return WeekDay(
                id: key,
                short: String(formatter.string(from: date).prefix(2)),
                saved: keys.contains(key),
                isToday: key == LeafDayKey.from(today, calendar: calendar)
            )
        }
    }

    static func monthGrid(now: Date, saved: [LeafDayKey], calendar: Calendar) -> [WeekDay] {
        let today = calendar.startOfDay(for: now)
        let todayKey = LeafDayKey.from(today, calendar: calendar)
        guard
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: today)),
            let range = calendar.range(of: .day, in: .month, for: start)
        else { return [] }
        let keys = Set(saved)
        return range.compactMap { day -> WeekDay? in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: start) else { return nil }
            let key = LeafDayKey.from(date, calendar: calendar)
            return WeekDay(
                id: key,
                short: String(day),
                saved: keys.contains(key),
                isToday: key == todayKey
            )
        }
    }
}
