import XCTest
@testable import Pugillar

final class BondTallyTests: XCTestCase {
    private var calendar: Calendar!

    override func setUpWithError() throws {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = utc
    }

    func test_bondDaysUsesStartOfDay() {
        let bondedAt = instant(2026, 1, 1, hour: 23)
        let now = instant(2026, 1, 8, hour: 1)
        XCTAssertEqual(BondTally.bondDays(bondedAt: bondedAt, now: now, calendar: calendar), 7)
    }

    func test_milestonesAt7_30_90_365() {
        XCTAssertEqual(BondTally.milestones, [7, 30, 90, 365])
        XCTAssertEqual(BondTally.reachedMilestones(bondDays: 6), [])
        XCTAssertEqual(BondTally.reachedMilestones(bondDays: 7), [7])
        XCTAssertEqual(BondTally.reachedMilestones(bondDays: 30), [7, 30])
        XCTAssertEqual(BondTally.reachedMilestones(bondDays: 365), [7, 30, 90, 365])
        XCTAssertEqual(BondTally.nextMilestone(after: 7), 30)
        XCTAssertNil(BondTally.nextMilestone(after: 365))
    }

    func test_familyInvariant_bondDaysAndMilestones() {
        let bondedAt = instant(2025, 8, 30)
        let now = instant(2026, 8, 30)
        let days = BondTally.bondDays(bondedAt: bondedAt, now: now, calendar: calendar)
        XCTAssertEqual(days, 365)
        XCTAssertTrue(BondTally.reachedMilestones(bondDays: days).contains(365))
    }

    private func instant(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = hour
        return calendar.date(from: parts)!
    }
}
