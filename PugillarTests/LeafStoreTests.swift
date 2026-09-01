import XCTest
@testable import Pugillar

final class LeafStoreTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var calendar: Calendar!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        suiteName = "pgl.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = utc
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    func test_roundTrip_reloadPreservesInkAndBond() async throws {
        let origin = instant(2026, 8, 30)
        let store = makeStore(now: { origin })
        let bond = BondRecord.fresh(handAlphaName: "North", handBetaName: "South", bondedAt: origin)
        try await store.saveBond(bond)
        _ = try await store.inkPlate("First line", hand: .alpha, now: origin)
        try await store.flush()

        let relaunched = makeStore(now: { origin })
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        let home = try await relaunched.homeLeaf(now: origin)
        XCTAssertEqual(home.alphaPlate.ink, "First line")
        XCTAssertEqual(loaded.bond?.handAlphaName, "North")
    }

    func test_sealSeamFilesLeafAndDropsBlankHome() async throws {
        let origin = instant(2026, 8, 30)
        let store = makeStore(now: { origin })
        _ = try await store.inkPlate("North", hand: .alpha, now: origin)
        _ = try await store.inkPlate("South", hand: .beta, now: origin)
        let sealed = try await store.sealSeam(at: origin.addingTimeInterval(3600))
        XCTAssertTrue(sealed.isSealed)

        let shelf = await store.shelf()
        XCTAssertEqual(shelf.count, 1)
        let home = try await store.homeLeaf(now: origin)
        XCTAssertFalse(home.isSealed)
        XCTAssertFalse(home.alphaPlate.hasInk)
    }

    func test_sealedFileRefusesFurtherEncode() async throws {
        let origin = instant(2026, 8, 30)
        let store = makeStore(now: { origin })
        _ = try await store.inkPlate("North", hand: .alpha, now: origin)
        _ = try await store.inkPlate("South", hand: .beta, now: origin)
        let sealed = try await store.sealSeam(at: origin)

        do {
            try await store.rewriteSealedForTesting(sealed)
            XCTFail("expected sealedImmutable")
        } catch {
            XCTAssertEqual(error as? LeafStoreError, .sealedImmutable)
        }
    }

    func test_oneSidedLeafStaysHomeAcrossDayBoundary() async throws {
        let dayOne = instant(2026, 8, 29)
        let dayTwo = instant(2026, 8, 30)
        let store = makeStore(now: { dayOne })
        let partial = try await store.inkPlate("Only north", hand: .alpha, now: dayOne)
        try await store.flush()
        XCTAssertEqual(partial.dayKey, LeafDayKey.from(dayOne, calendar: calendar))

        let relaunched = makeStore(now: { dayTwo })
        _ = await relaunched.load()
        let home = try await relaunched.homeLeaf(now: dayTwo)
        XCTAssertEqual(home.dayKey, LeafDayKey.from(dayOne, calendar: calendar))
        XCTAssertEqual(home.alphaPlate.ink, "Only north")
        XCTAssertFalse(home.betaPlate.hasInk)
    }

    func test_deadSealGateInStore() async throws {
        let origin = instant(2026, 8, 30)
        let store = makeStore(now: { origin })
        _ = try await store.inkPlate("North only", hand: .alpha, now: origin)
        do {
            _ = try await store.sealSeam(at: origin)
            XCTFail("expected deadSeal")
        } catch {
            XCTAssertEqual(error as? LeafStoreError, .deadSeal)
        }
    }

    func test_corruptFileFallsBackToBackup() async throws {
        let origin = instant(2026, 8, 30)
        let store = makeStore(now: { origin })
        let home = try await store.homeLeaf(now: origin)
        try await store.flush()
        let url = directory.appendingPathComponent("Leaves/home.json")
        let backup = url.appendingPathExtension("backup")
        try FileManager.default.copyItem(at: url, to: backup)
        try Data("{not-json".utf8).write(to: url)

        let loaded = await makeStore(now: { origin }).load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.leaves.first(where: { $0.id == home.id })?.id, home.id)
    }

    func test_corruptFileWithoutBackupStartsEmpty() async throws {
        try FileManager.default.createDirectory(at: directory.appendingPathComponent("Shelf"), withIntermediateDirectories: true)
        try Data("nope".utf8).write(to: directory.appendingPathComponent("Shelf/2026-08-30.json"))
        let day = instant(2026, 8, 30)
        let loaded = await makeStore(now: { day }).load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertTrue(loaded.leaves.isEmpty)
    }

    func test_homeLeafReadsDiskFileWithoutWiping() async throws {
        let origin = instant(2026, 8, 30)
        let store = makeStore(now: { origin })
        _ = try await store.inkPlate("Kept line", hand: .alpha, now: origin)
        try await store.flush()

        let other = makeStore(now: { origin })
        let home = try await other.homeLeaf(now: origin)
        XCTAssertEqual(home.alphaPlate.ink, "Kept line")
    }

    func test_seedRepairRestoresBlankHome() async throws {
        #if targetEnvironment(simulator)
        let origin = instant(2026, 8, 30)
        let store = makeStore(now: { origin })
        try await store.seedDemoIfNeeded(now: origin)
        _ = try await store.sealSeam(at: origin)
        var home = try await store.homeLeaf(now: origin)
        XCTAssertFalse(home.alphaPlate.hasInk)
        try await store.seedDemoIfNeeded(now: origin)
        home = try await store.homeLeaf(now: origin)
        XCTAssertTrue(home.canSeal)
        XCTAssertTrue(home.alphaPlate.hasInk)
        XCTAssertTrue(home.betaPlate.hasInk)
        #endif
    }

    func test_resetAllDataClearsLeaves() async throws {
        let origin = instant(2026, 8, 30)
        let store = makeStore(now: { origin })
        _ = try await store.inkPlate("Line", hand: .alpha, now: origin)
        try await store.resetAllData()
        let loaded = await store.load()
        XCTAssertTrue(loaded.leaves.isEmpty)
        XCTAssertNil(loaded.bond)
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let origin = instant(2026, 8, 30)
        let leaf = Leaf.blank(on: origin, calendar: calendar)
        let data = try LeafCodec.encode(leaf)
        let decoded = try LeafCodec.decode(data)
        XCTAssertEqual(decoded.id, leaf.id)

        let future = Data("{\"schemaVersion\":99}".utf8)
        XCTAssertThrowsError(try LeafCodec.decode(future)) { error in
            XCTAssertEqual(error as? LeafCodec.Failure, .unsupportedSchema(99))
        }
    }

    private func makeStore(now: @escaping @Sendable () -> Date) -> LeafStore {
        LeafStore(
            directory: directory,
            defaultsSuiteName: suiteName,
            calendar: calendar,
            now: now
        )
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
