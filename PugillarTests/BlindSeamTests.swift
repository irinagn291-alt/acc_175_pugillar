import XCTest
@testable import Pugillar

final class BlindSeamTests: XCTestCase {
    private var calendar: Calendar!

    override func setUpWithError() throws {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = utc
    }

    func test_foreignPlateInkNeverReachesSnapshotUntilBothWrite() throws {
        var leaf = Leaf.blank(on: instant(2026, 8, 30), calendar: calendar)
        leaf.alphaPlate.ink = "North secret"
        let writingAlpha = BlindSeam.snapshot(leaf: leaf, writing: .alpha)
        XCTAssertEqual(writingAlpha.alpha.readableInk, "North secret")
        XCTAssertNil(writingAlpha.beta.readableInk)
        XCTAssertTrue(writingAlpha.beta.isShuttered)
        XCTAssertFalse(writingAlpha.canSeal)

        leaf.betaPlate.ink = "South secret"
        let both = BlindSeam.snapshot(leaf: leaf, writing: .alpha)
        XCTAssertEqual(both.alpha.readableInk, "North secret")
        XCTAssertEqual(both.beta.readableInk, "South secret")
        XCTAssertTrue(both.canSeal)

        let writingBeta = BlindSeam.snapshot(leaf: leaf, writing: .beta)
        XCTAssertEqual(writingBeta.alpha.readableInk, "North secret")
        XCTAssertEqual(writingBeta.beta.readableInk, "South secret")

        let sealed = try SeamSeal.apply(to: leaf, at: instant(2026, 8, 30, hour: 21))
        let open = BlindSeam.snapshot(leaf: sealed, writing: .alpha)
        XCTAssertEqual(open.alpha.readableInk, "North secret")
        XCTAssertEqual(open.beta.readableInk, "South secret")
        XCTAssertFalse(open.canSeal)
    }

    func test_replacingShutteredInkIsIgnored() {
        var leaf = Leaf.blank(on: instant(2026, 8, 30), calendar: calendar)
        leaf.alphaPlate.ink = "Kept"
        let snap = BlindSeam.snapshot(leaf: leaf, writing: .alpha)
        let next = snap.replacing(hand: .beta, ink: "leak")
        XCTAssertNil(next.beta.readableInk)
        XCTAssertTrue(next.beta.isShuttered)
    }

    func test_twoHalvesLocksBetaFaceUntilAlphaAnswers() {
        var leaf = Leaf.blank(on: instant(2026, 8, 30), calendar: calendar)
        leaf.prompt = Prompt(question: "Where next?")
        let locked = BlindSeam.snapshot(leaf: leaf, writing: .beta)
        XCTAssertTrue(locked.beta.isShuttered)
        XCTAssertEqual(locked.prompt?.betaUnlocked, false)

        leaf.prompt?.alphaAnswer = "North"
        let open = BlindSeam.snapshot(leaf: leaf, writing: .beta)
        XCTAssertTrue(open.beta.isDrafting)
        XCTAssertEqual(open.prompt?.betaUnlocked, true)
    }

    func test_familyInvariant_startOfDayBondedAtAndMilestones() {
        let bondedAt = instant(2026, 1, 1, hour: 23)
        let now = instant(2026, 1, 8, hour: 1)
        let days = BondTally.bondDays(bondedAt: bondedAt, now: now, calendar: calendar)
        XCTAssertEqual(days, 7)
        XCTAssertEqual(BondTally.reachedMilestones(bondDays: days), [7])
        let record = BondRecord.fresh(handAlphaName: "N", handBetaName: "S", bondedAt: bondedAt)
        let snap = BlindSeam.bond(record, sealedLeaves: 2, now: now, calendar: calendar)
        XCTAssertEqual(snap.days, 7)
        XCTAssertEqual(snap.reached, [7])
        XCTAssertEqual(snap.next, 30)
        XCTAssertEqual(snap.sealedLeaves, 2)
    }

    func test_seededHomeSnapshotCanSealAndShowsBothPlates() async {
        let (canSeal, isEmpty, alpha, beta) = await MainActor.run {
            let session = LeafSession.previewPopulated()
            return (
                session.snapshot.canSeal,
                session.snapshot.isEmpty,
                session.snapshot.alpha.readableInk,
                session.snapshot.beta.readableInk
            )
        }
        XCTAssertTrue(canSeal)
        XCTAssertFalse(isEmpty)
        XCTAssertEqual(alpha?.isEmpty, false)
        XCTAssertEqual(beta?.isEmpty, false)
    }

    func test_overlayDoesNotLeaveDiptych() async {
        let (home, overlay, after) = await MainActor.run {
            let session = LeafSession.previewPopulated()
            let home = session.snapshot.leafID
            session.present(.shelf)
            let overlay = session.overlay
            session.dismissOverlay()
            return (home, overlay, session.snapshot.leafID)
        }
        XCTAssertEqual(overlay, .shelf)
        XCTAssertEqual(after, home)
    }

    func test_writeInkOnShutteredPlateIsRefused() async {
        let leaked = await MainActor.run {
            let session = LeafSession.previewNorthOnly()
            session.writeInk("leak", hand: .beta)
            return session.snapshot.beta.readableInk
        }
        XCTAssertNil(leaked)
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
