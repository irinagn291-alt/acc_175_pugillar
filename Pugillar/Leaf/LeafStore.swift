import Foundation

/// Role: Leaf. Preference keys. Demo seed is Simulator-only and versioned.
enum PreferenceKey {
    static let demoSeed = "pgl.demo.v1"
    static let onboardingComplete = "pgl.onboarding.complete"
}

/// Role: Leaf. Recoverable load outcome. Never crash on a corrupt leaf file.
enum LeafLoadWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}

/// Role: Leaf. Store failures. Views map these; SeamSeal never sees them.
enum LeafStoreError: Error, Equatable, Sendable {
    case sealedImmutable
    case deadSeal
    case alreadySealed
    case betaLocked
    case noHomeLeaf
}

/// Role: Leaf. The only seam views may talk to. FileManager stays inside the actor.
protocol LeafStoring: Sendable {
    func load() async -> (leaves: [Leaf], bond: BondRecord?, warning: LeafLoadWarning?)
    func homeLeaf(now: Date) async throws -> Leaf
    func inkPlate(_ text: String, hand: HandSide, now: Date) async throws -> Leaf
    func sealSeam(at date: Date) async throws -> Leaf
    func shelf() async -> [Leaf]
    func bond() async -> BondRecord?
    func saveBond(_ bond: BondRecord) async throws
    func note(_ leaf: Leaf) async
    func flush() async throws
    func resetAllData() async throws
    func seedDemoIfNeeded(now: Date) async throws
    func isOnboardingComplete() async -> Bool
    func setOnboardingComplete(_ flag: Bool) async throws
}

/// Role: Leaf. JSON per leaf under Application Support. Memory is the source of truth.
actor LeafStore: LeafStoring {
    private let directory: URL
    private let defaultsSuiteName: String?
    private let fileManager: FileManager
    private let writeDelayNanoseconds: UInt64
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    private var leavesByID: [UUID: Leaf] = [:]
    private var homeLeafID: UUID?
    private var pendingHomeWrite = false
    private var writeTask: Task<Void, Never>?
    private var bondRecord: BondRecord?
    private var onboardingComplete = false
    private(set) var warning: LeafLoadWarning?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        defaultsSuiteName: String? = nil,
        fileManager: FileManager = .default,
        writeDelayNanoseconds: UInt64 = 300_000_000,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.directory = directory
        self.defaultsSuiteName = defaultsSuiteName
        self.fileManager = fileManager
        self.writeDelayNanoseconds = writeDelayNanoseconds
        self.calendar = calendar
        self.now = now
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Pugillar", isDirectory: true)
    }

    private var leavesDirectory: URL {
        directory.appendingPathComponent("Leaves", isDirectory: true)
    }

    private var shelfDirectory: URL {
        directory.appendingPathComponent("Shelf", isDirectory: true)
    }

    private static let homeFileName = "home.json"

    var leaves: [Leaf] {
        leavesByID.values.sorted { $0.dayKey < $1.dayKey }
    }

    func load() async -> (leaves: [Leaf], bond: BondRecord?, warning: LeafLoadWarning?) {
        warning = nil
        leavesByID = [:]
        homeLeafID = nil
        prepareDirectory()
        bondRecord = readBond()
        onboardingComplete = readSettings() ?? false

        var recovered = false
        var loadedAny = false

        for url in shelfURLs() {
            if let leaf = decodeFile(url) {
                leavesByID[leaf.id] = leaf
                loadedAny = true
                continue
            }
            if let leaf = decodeFile(backupURL(for: url)) {
                leavesByID[leaf.id] = leaf
                recovered = true
                loadedAny = true
            }
        }

        let homeURL = homeFileURL()
        if let leaf = decodeFile(homeURL) {
            leavesByID[leaf.id] = leaf
            homeLeafID = leaf.id
            loadedAny = true
        } else if let leaf = decodeFile(backupURL(for: homeURL)) {
            leavesByID[leaf.id] = leaf
            homeLeafID = leaf.id
            recovered = true
            loadedAny = true
        }

        if recovered {
            warning = .recoveredFromBackup
        } else if !loadedAny && (!shelfURLs().isEmpty || fileManager.fileExists(atPath: homeURL.path)) {
            warning = .startedEmpty
        }
        return (leaves, bondRecord, warning)
    }

    func homeLeaf(now referenceDate: Date) async throws -> Leaf {
        if let open = unsealedLeaf {
            return open
        }
        if let existing = openHomeFromDisk() {
            leavesByID[existing.id] = existing
            homeLeafID = existing.id
            return existing
        }
        let blank = Leaf.blank(on: referenceDate, calendar: calendar)
        leavesByID[blank.id] = blank
        homeLeafID = blank.id
        try persistHome(blank)
        return blank
    }

    func inkPlate(_ text: String, hand: HandSide, now referenceDate: Date) async throws -> Leaf {
        var leaf = try await homeLeaf(now: referenceDate)
        leaf = try SeamSeal.ink(text, on: hand, leaf: leaf)
        leavesByID[leaf.id] = leaf
        homeLeafID = leaf.id
        await noteHome(leaf)
        return leaf
    }

    func sealSeam(at date: Date) async throws -> Leaf {
        guard var leaf = unsealedLeaf else {
            throw LeafStoreError.noHomeLeaf
        }
        do {
            leaf = try SeamSeal.apply(to: leaf, at: date)
        } catch SeamSeal.Failure.deadSeal {
            throw LeafStoreError.deadSeal
        } catch SeamSeal.Failure.alreadySealed {
            throw LeafStoreError.alreadySealed
        } catch SeamSeal.Failure.betaLocked {
            throw LeafStoreError.betaLocked
        }
        leavesByID[leaf.id] = leaf
        try persistSealed(leaf)
        removeHomeFile()

        let fresh = Leaf.blank(on: date, calendar: calendar)
        leavesByID[fresh.id] = fresh
        homeLeafID = fresh.id
        try persistHome(fresh)
        return leaf
    }

    func shelf() async -> [Leaf] {
        ShelfStack.entries(from: leaves)
    }

    func bond() async -> BondRecord? {
        bondRecord
    }

    func saveBond(_ bond: BondRecord) async throws {
        bondRecord = bond
        try persistBond(bond)
    }

    func note(_ leaf: Leaf) async {
        await noteHome(leaf)
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        if pendingHomeWrite, let id = homeLeafID, let leaf = leavesByID[id] {
            try persistHome(leaf)
            pendingHomeWrite = false
        }
        if let bondRecord {
            try persistBond(bondRecord)
        }
        try persistSettings(onboardingComplete)
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        pendingHomeWrite = false
        leavesByID = [:]
        homeLeafID = nil
        bondRecord = nil
        onboardingComplete = false
        warning = nil
        lastWriteError = nil
        let defaults = preferenceDefaults()
        defaults.removeObject(forKey: PreferenceKey.demoSeed)
        defaults.removeObject(forKey: PreferenceKey.onboardingComplete)
        if fileManager.fileExists(atPath: directory.path) {
            try fileManager.removeItem(at: directory)
        }
        prepareDirectory()
    }

    func seedDemoIfNeeded(now referenceDate: Date) async throws {
        #if targetEnvironment(simulator)
        let defaults = preferenceDefaults()
        if defaults.object(forKey: PreferenceKey.demoSeed) != nil {
            try restoreDemoHomeIfBlank(on: referenceDate)
            try writeMissingSealedLeaves(on: referenceDate)
            return
        }

        let bond = LeafSeed.bond(on: referenceDate)
        bondRecord = bond
        try persistBond(bond)

        try writeMissingSealedLeaves(on: referenceDate)

        let home = LeafSeed.homeLeaf(on: referenceDate, calendar: calendar)
        leavesByID[home.id] = home
        homeLeafID = home.id
        try persistHome(home)

        onboardingComplete = true
        try persistSettings(true)
        defaults.set(true, forKey: PreferenceKey.demoSeed)
        defaults.set(true, forKey: PreferenceKey.onboardingComplete)
        #endif
    }

    func isOnboardingComplete() async -> Bool {
        onboardingComplete
    }

    func setOnboardingComplete(_ flag: Bool) async throws {
        onboardingComplete = flag
        try persistSettings(flag)
        preferenceDefaults().set(flag, forKey: PreferenceKey.onboardingComplete)
    }

    /// Tests only — proves sealed shelf files refuse re-encode.
    func rewriteSealedForTesting(_ leaf: Leaf) throws {
        try persistSealed(leaf)
    }

    var unsealedLeaf: Leaf? {
        guard let homeLeafID, let leaf = leavesByID[homeLeafID], !leaf.isSealed else {
            return nil
        }
        return leaf
    }

    private func openHomeFromDisk() -> Leaf? {
        if let leaf = decodeFile(homeFileURL()), !leaf.isSealed {
            return leaf
        }
        if let leaf = decodeFile(backupURL(for: homeFileURL())), !leaf.isSealed {
            return leaf
        }
        return nil
    }

    private func writeMissingSealedLeaves(on date: Date) throws {
        for sealed in LeafSeed.sealedLeaves(on: date, calendar: calendar) {
            let url = shelfFileURL(for: sealed.dayKey)
            if fileManager.fileExists(atPath: url.path) { continue }
            leavesByID[sealed.id] = sealed
            try persistSealed(sealed)
        }
    }

    private func restoreDemoHomeIfBlank(on date: Date) throws {
        if let leaf = openHomeFromDisk(), leaf.alphaPlate.hasInk || leaf.betaPlate.hasInk {
            leavesByID[leaf.id] = leaf
            homeLeafID = leaf.id
            return
        }
        let home = LeafSeed.homeLeaf(on: date, calendar: calendar)
        leavesByID[home.id] = home
        homeLeafID = home.id
        try persistHome(home)
    }

    private func noteHome(_ leaf: Leaf) async {
        guard !leaf.isSealed else { return }
        leavesByID[leaf.id] = leaf
        homeLeafID = leaf.id
        pendingHomeWrite = true
        scheduleFlush()
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            if pendingHomeWrite, let id = homeLeafID, let leaf = leavesByID[id] {
                try persistHome(leaf)
                pendingHomeWrite = false
            }
            lastWriteError = nil
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func persistHome(_ leaf: Leaf) throws {
        guard !leaf.isSealed else { throw LeafStoreError.sealedImmutable }
        prepareDirectory()
        let url = homeFileURL()
        let data = try LeafCodec.encode(leaf)
        if fileManager.fileExists(atPath: url.path) {
            let backup = backupURL(for: url)
            try? fileManager.removeItem(at: backup)
            try? fileManager.copyItem(at: url, to: backup)
        }
        try data.write(to: url, options: .atomic)
    }

    private func persistSealed(_ leaf: Leaf) throws {
        guard leaf.isSealed else { return }
        prepareDirectory()
        let url = shelfFileURL(for: leaf.dayKey)
        if fileManager.fileExists(atPath: url.path), let existing = decodeFile(url), existing.isSealed {
            throw LeafStoreError.sealedImmutable
        }
        let data = try LeafCodec.encode(leaf)
        if fileManager.fileExists(atPath: url.path) {
            let backup = backupURL(for: url)
            try? fileManager.removeItem(at: backup)
            try? fileManager.copyItem(at: url, to: backup)
        }
        try data.write(to: url, options: .atomic)
    }

    private func removeHomeFile() {
        let url = homeFileURL()
        try? fileManager.removeItem(at: url)
        try? fileManager.removeItem(at: backupURL(for: url))
    }

    private func persistBond(_ bond: BondRecord) throws {
        prepareDirectory()
        let url = bondURL()
        let data = try BondCodec.encode(bond)
        if fileManager.fileExists(atPath: url.path) {
            let backup = backupURL(for: url)
            try? fileManager.removeItem(at: backup)
            try? fileManager.copyItem(at: url, to: backup)
        }
        try data.write(to: url, options: .atomic)
    }

    private func persistSettings(_ complete: Bool) throws {
        prepareDirectory()
        let url = settingsURL()
        let data = try SettingsCodec.encode(onboardingComplete: complete)
        if fileManager.fileExists(atPath: url.path) {
            let backup = backupURL(for: url)
            try? fileManager.removeItem(at: backup)
            try? fileManager.copyItem(at: url, to: backup)
        }
        try data.write(to: url, options: .atomic)
    }

    private func readBond() -> BondRecord? {
        let url = bondURL()
        if let data = try? Data(contentsOf: url), let bond = try? BondCodec.decode(data) {
            return bond
        }
        if let data = try? Data(contentsOf: backupURL(for: url)) {
            return try? BondCodec.decode(data)
        }
        return nil
    }

    private func readSettings() -> Bool? {
        let url = settingsURL()
        if let data = try? Data(contentsOf: url), let flag = try? SettingsCodec.decode(data) {
            return flag
        }
        if let data = try? Data(contentsOf: backupURL(for: url)) {
            return try? SettingsCodec.decode(data)
        }
        return nil
    }

    private func decodeFile(_ url: URL) -> Leaf? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? LeafCodec.decode(data)
    }

    private func shelfURLs() -> [URL] {
        let contents = try? fileManager.contentsOfDirectory(at: shelfDirectory, includingPropertiesForKeys: nil)
        return (contents ?? []).filter { url in
            url.pathExtension == "json" && !url.lastPathComponent.hasSuffix(".json.backup")
        }
    }

    private func homeFileURL() -> URL {
        leavesDirectory.appendingPathComponent(Self.homeFileName)
    }

    private func shelfFileURL(for dayKey: LeafDayKey) -> URL {
        shelfDirectory.appendingPathComponent(dayKey.fileName)
    }

    private func bondURL() -> URL {
        directory.appendingPathComponent("bond.json")
    }

    private func settingsURL() -> URL {
        directory.appendingPathComponent("settings.json")
    }

    private func backupURL(for url: URL) -> URL {
        url.appendingPathExtension("backup")
    }

    private func preferenceDefaults() -> UserDefaults {
        if let defaultsSuiteName {
            return UserDefaults(suiteName: defaultsSuiteName) ?? .standard
        }
        return .standard
    }

    private func prepareDirectory() {
        for folder in [directory, leavesDirectory, shelfDirectory] {
            if !fileManager.fileExists(atPath: folder.path) {
                try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            }
        }
    }

    private func scheduleFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }
}
