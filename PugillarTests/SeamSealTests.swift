import XCTest
@testable import Pugillar

final class SeamSealTests: XCTestCase {
    private var calendar: Calendar!

    override func setUpWithError() throws {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = utc
    }

    func test_deadSealGateRequiresBothPlates() {
        var leaf = Leaf.blank(on: instant(2026, 8, 30), calendar: calendar)
        leaf.alphaPlate.ink = "North line"
        XCTAssertFalse(leaf.canSeal)
        XCTAssertThrowsError(try SeamSeal.apply(to: leaf, at: instant(2026, 8, 30, hour: 20))) { error in
            XCTAssertEqual(error as? SeamSeal.Failure, .deadSeal)
        }

        leaf.betaPlate.ink = "South line"
        XCTAssertTrue(leaf.canSeal)
    }

    func test_sealFreezesPairEntry() throws {
        var leaf = Leaf.blank(on: instant(2026, 8, 30), calendar: calendar)
        leaf.alphaPlate.ink = "Alpha"
        leaf.betaPlate.ink = "Beta"
        let stamp = instant(2026, 8, 30, hour: 21)
        let sealed = try SeamSeal.apply(to: leaf, at: stamp)
        XCTAssertTrue(sealed.isSealed)
        XCTAssertEqual(sealed.pairEntry?.alphaInk, "Alpha")
        XCTAssertEqual(sealed.pairEntry?.betaInk, "Beta")
        XCTAssertEqual(sealed.pairEntry?.sealedAtUnixMilliseconds, PairEntry.unixMilliseconds(from: stamp))
    }

    func test_twoHalvesAlphaBeforeBeta() throws {
        var leaf = Leaf.blank(on: instant(2026, 8, 30), calendar: calendar)
        leaf.prompt = Prompt(question: "Where next?")
        XCTAssertThrowsError(try SeamSeal.answerPrompt("South", on: .beta, leaf: leaf)) { error in
            XCTAssertEqual(error as? SeamSeal.Failure, .betaLocked)
        }
        leaf = try SeamSeal.answerPrompt("North", on: .alpha, leaf: leaf)
        XCTAssertTrue(leaf.prompt?.betaUnlocked == true)
        leaf = try SeamSeal.answerPrompt("South", on: .beta, leaf: leaf)
        XCTAssertEqual(leaf.prompt?.betaAnswer, "South")
    }

    func test_alreadySealedLeafRejectsInk() throws {
        var leaf = Leaf.blank(on: instant(2026, 8, 30), calendar: calendar)
        leaf.alphaPlate.ink = "A"
        leaf.betaPlate.ink = "B"
        leaf = try SeamSeal.apply(to: leaf, at: instant(2026, 8, 30, hour: 22))
        XCTAssertThrowsError(try SeamSeal.ink("More", on: .alpha, leaf: leaf)) { error in
            XCTAssertEqual(error as? SeamSeal.Failure, .alreadySealed)
        }
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
