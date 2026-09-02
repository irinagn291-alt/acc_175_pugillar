import XCTest
@testable import Pugillar

final class PageMathTests: XCTestCase {
    private var calendar: Calendar!

    override func setUpWithError() throws {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = utc
    }

    func test_wordsIgnoresEmptyChunks() {
        XCTAssertEqual(PageMath.words(in: "  long   day  "), 2)
        XCTAssertEqual(PageMath.words(in: ""), 0)
    }

    func test_streakCountsBackFromToday() {
        let today = instant(2026, 9, 2)
        let days = [instant(2026, 8, 31), instant(2026, 9, 1), today]
        XCTAssertEqual(PageMath.streak(days: days, now: today, calendar: calendar), 3)
    }

    func test_streakSurvivesIfTodayIsStillOpen() {
        let today = instant(2026, 9, 2)
        let days = [instant(2026, 8, 31), instant(2026, 9, 1)]
        XCTAssertEqual(PageMath.streak(days: days, now: today, calendar: calendar), 2)
    }

    func test_monthCountStaysInThisMonth() {
        let now = instant(2026, 9, 2)
        let days = [instant(2026, 8, 30), instant(2026, 9, 1), instant(2026, 9, 2)]
        XCTAssertEqual(PageMath.count(inMonthOf: now, days: days, calendar: calendar), 2)
    }

    func test_lastThirtyDaysIncludesAugustWhenEarlySeptember() {
        let now = instant(2026, 9, 2)
        let days = [instant(2026, 8, 10), instant(2026, 8, 30), instant(2026, 9, 1)]
        XCTAssertEqual(PageMath.count(lastDays: 30, days: days, now: now, calendar: calendar), 3)
    }

    func test_weekHasSevenMarks() {
        let now = instant(2026, 9, 2)
        let saved = [LeafDayKey.from(instant(2026, 9, 2), calendar: calendar)]
        let week = PageMath.week(now: now, saved: saved, calendar: calendar)
        XCTAssertEqual(week.count, 7)
        XCTAssertTrue(week.last?.isToday == true)
        XCTAssertTrue(week.last?.saved == true)
    }

    func test_askWraps() {
        XCTAssertEqual(DayAsk.at(0), DayAsk.questions[0])
        XCTAssertEqual(DayAsk.at(DayAsk.questions.count), DayAsk.questions[0])
        XCTAssertFalse(DayAsk.at(3).isEmpty)
    }

    private func instant(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = 12
        return calendar.date(from: parts)!
    }
}
