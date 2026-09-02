import Foundation
import Observation
import UIKit

/// Role: Leaf. Presentation session. The only type views talk to. Owns LeafStore; never leaks a shuttered Plate.
@MainActor
@Observable
final class LeafSession {
    private let store: (any LeafStoring)?
    private let calendar: Calendar
    private var now: @Sendable () -> Date
    private var inkTask: Task<Void, Never>?
    private var reviewConsumed = false
    private var bootstrapped = false
    private var homeReady = false
    private var lastDayKey: LeafDayKey?

    var snapshot = DiptychSnapshot(
        leafID: UUID(),
        dayKey: LeafDayKey.from(Date(), calendar: .current),
        writing: .alpha,
        alpha: .drafting(""),
        beta: .shuttered,
        prompt: nil,
        canSeal: false,
        isSealed: false,
        isEmpty: true,
        isRevealing: false
    )
    var bond: BondSnapshot?
    var shelf: [ShelfCard] = []
    var overlay: SeamCard?
    var showOnboarding = false
    var warning: LeafLoadWarning?
    var fault: String?
    var isLoading = false
    var showSpinner = false
    var sealBusy = false
    var commitFlash = false
    var onboardingComplete = false
    var askIndex = 0
    var reminderOn = false
    var reminderHour = 21
    var favoriteIDs: Set<UUID> = []
    var reading: ShelfCard?
    var shareText: String?

    init(store: (any LeafStoring)?, calendar: Calendar = .current, now: @escaping @Sendable () -> Date = { Date() }) {
        self.store = store
        self.calendar = calendar
        self.now = now
    }

    static func live() -> LeafSession {
        let directory: URL
        do {
            directory = try LeafStore.applicationSupportDirectory()
        } catch {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent("Pugillar", isDirectory: true)
        }
        let session = LeafSession(store: LeafStore(directory: directory))
        #if targetEnvironment(simulator)
        session.paintSeededHome()
        #endif
        return session
    }

    static func previewPopulated() -> LeafSession {
        let session = LeafSession(store: nil, now: { Date() })
        session.paintSeededHome()
        return session
    }

    static func previewNorthOnly() -> LeafSession {
        let calendar = Calendar.current
        let now = Date()
        var leaf = Leaf.blank(on: now, calendar: calendar)
        leaf.alphaPlate.ink = "North line only"
        let session = LeafSession(store: nil, now: { now })
        session.snapshot = BlindSeam.snapshot(leaf: leaf, writing: .alpha)
        session.onboardingComplete = true
        return session
    }

    static func previewBond() -> LeafSession {
        let session = previewPopulated()
        session.overlay = .bond
        return session
    }

    static func previewShelf() -> LeafSession {
        let session = previewPopulated()
        session.overlay = .shelf
        return session
    }

    static func previewSettings() -> LeafSession {
        let session = previewPopulated()
        session.overlay = .settings
        return session
    }

    static func previewEmptyShelf() -> LeafSession {
        let session = previewPopulated()
        session.shelf = []
        session.overlay = .shelf
        return session
    }

    func bootstrap() async {
        guard !bootstrapped else { return }
        bootstrapped = true
        await load()
        #if targetEnvironment(simulator)
        if snapshot.isEmpty && onboardingComplete {
            await restoreSeededHome(at: now())
        }
        #endif
        if onboardingComplete {
            applyReviewHook()
        } else {
            showOnboarding = true
        }
    }

    func load() async {
        isLoading = true
        fault = nil
        let spinner = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            self?.showSpinner = self?.isLoading == true
        }
        defer {
            isLoading = false
            showSpinner = false
            spinner.cancel()
            homeReady = true
        }
        guard let store else { return }
        do {
            try await store.seedDemoIfNeeded(now: now())
        } catch {
            fault = "The wax would not take the demo leaf. Try again."
        }
        let loaded = await store.load()
        warning = loaded.warning
        onboardingComplete = await store.isOnboardingComplete()
        loadPrefs()
        await refresh(from: loaded.leaves, bond: loaded.bond)
        if loaded.warning == .startedEmpty {
            fault = "A leaf file was damaged. The diptych started empty."
        }
    }

    func flush() async {
        inkTask?.cancel()
        do {
            try await store?.flush()
        } catch {
            fault = "The last line did not stay on the wax. Try again."
        }
    }

    func noteDay(_ date: Date) async {
        guard homeReady else { return }
        let key = LeafDayKey.from(date, calendar: calendar)
        guard key != lastDayKey else { return }
        lastDayKey = key
        await refreshHome(at: date)
    }

    func writeInk(_ text: String, hand: HandSide) {
        guard !snapshot.isSealed, snapshot.face(for: hand).isDrafting else { return }
        snapshot = snapshot.replacing(hand: hand, ink: text)
        inkTask?.cancel()
        inkTask = Task { [weak self] in
            await self?.persistInk(text, hand: hand)
        }
    }

    func answerPrompt(_ text: String, hand: HandSide) {
        guard var prompt = snapshot.prompt, !snapshot.isSealed else { return }
        switch hand {
        case .alpha:
            prompt.alphaAnswer = text
            prompt.betaUnlocked = Plate(hand: .alpha, ink: text).hasInk
        case .beta:
            guard prompt.betaUnlocked else { return }
            prompt.betaAnswer = text
        }
        snapshot.prompt = prompt
        inkTask?.cancel()
        inkTask = Task { [weak self] in
            await self?.persistPrompt(text, hand: hand)
        }
    }

    func takeStylus(_ hand: HandSide) {
        guard !snapshot.isSealed else { return }
        snapshot.writing = hand
        Task { await refreshHome(at: now()) }
    }

    func seal() async {
        guard snapshot.canSeal, !sealBusy else { return }
        sealBusy = true
        defer { sealBusy = false }
        guard let store else { return }
        do {
            let sealed = try await store.sealSeam(at: now(), question: todayAsk)
            snapshot = BlindSeam.snapshot(leaf: sealed, writing: snapshot.writing, revealing: true)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            commitFlash = true
            try? await Task.sleep(nanoseconds: 350_000_000)
            commitFlash = false
            await refreshHome(at: now())
            shelf = BlindSeam.shelf(from: await store.shelf())
            if let record = await store.bond() {
                bond = BlindSeam.bond(record, sealedLeaves: shelf.count, now: now(), calendar: calendar)
            }
            fault = nil
        } catch LeafStoreError.deadSeal {
            fault = "Seal stays dead until both plates hold ink."
        } catch {
            fault = "The seam would not seal. Try again."
        }
    }

    func present(_ card: SeamCard) {
        overlay = card
    }

    func dismissOverlay() {
        overlay = nil
    }

    func completeOnboarding(alpha: String, beta: String, bondedAt: Date) async {
                let alphaName = trimmed(alpha, fallback: "Alex")
        let betaName = trimmed(beta, fallback: "Sam")
        let stamp = calendar.startOfDay(for: bondedAt)
        do {
            try await store?.saveBond(
                BondRecord.fresh(handAlphaName: alphaName, handBetaName: betaName, bondedAt: stamp)
            )
            try await store?.setOnboardingComplete(true)
            onboardingComplete = true
            showOnboarding = false
            await load()
            applyReviewHook()
        } catch {
            fault = "The bond would not stamp. Try again."
        }
    }

    func rerunOnboarding() {
        overlay = nil
        showOnboarding = true
    }

    func resetAll() async {
        do {
            try await store?.resetAllData()
            snapshot = DiptychSnapshot(
                leafID: UUID(),
                dayKey: LeafDayKey.from(now(), calendar: calendar),
                writing: .alpha,
                alpha: .drafting(""),
                beta: .shuttered,
                prompt: nil,
                canSeal: false,
                isSealed: false,
                isEmpty: true,
                isRevealing: false
            )
            bond = nil
            shelf = []
            overlay = nil
            warning = nil
            fault = nil
            onboardingComplete = false
            showOnboarding = true
            homeReady = false
            lastDayKey = nil
            askIndex = 0
            reminderOn = false
            reminderHour = 21
            favoriteIDs = []
            reading = nil
            shareText = nil
            persistPrefs()
            Task { await PageBell.sync(on: false, hour: reminderHour) }
        } catch {
            fault = "Reset failed. The leaves are still on the shelf."
        }
    }

    func applyReviewHook() {
        guard !reviewConsumed else { return }
        reviewConsumed = true
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-ReviewScreen"), args.indices.contains(index + 1) else { return }
        switch args[index + 1] {
        case "today":
            overlay = nil
        case "log":
            overlay = .shelf
        case "goals":
            overlay = .bond
        default:
            break
        }
    }

    private func persistInk(_ text: String, hand: HandSide) async {
        guard let store else { return }
        do {
            let leaf = try await store.inkPlate(text, hand: hand, now: now())
            snapshot = BlindSeam.snapshot(leaf: leaf, writing: snapshot.writing)
            fault = nil
        } catch SeamSeal.Failure.betaLocked {
            fault = "The south plate waits until the north half answers."
            await refreshHome(at: now())
        } catch LeafStoreError.betaLocked {
            fault = "The south plate waits until the north half answers."
            await refreshHome(at: now())
        } catch {
            fault = "That line did not stay. Try again."
        }
    }

    private func persistPrompt(_ text: String, hand: HandSide) async {
        guard let store else { return }
        do {
            var leaf = try await store.homeLeaf(now: now())
            leaf = try SeamSeal.answerPrompt(text, on: hand, leaf: leaf)
            await store.note(leaf)
            snapshot = BlindSeam.snapshot(leaf: leaf, writing: snapshot.writing)
            fault = nil
        } catch SeamSeal.Failure.betaLocked {
            fault = "The south half waits until the north half answers."
            await refreshHome(at: now())
        } catch {
            fault = "The prompt would not take ink. Try again."
        }
    }

    private func refresh(from leaves: [Leaf], bond record: BondRecord?) async {
        shelf = BlindSeam.shelf(from: leaves)
        if let record {
            bond = BlindSeam.bond(record, sealedLeaves: shelf.count, now: now(), calendar: calendar)
        } else {
            bond = nil
        }
        await refreshHome(at: now())
    }

    private func refreshHome(at date: Date) async {
        guard let store else { return }
        do {
            let leaf = try await store.homeLeaf(now: date)
            lastDayKey = LeafDayKey.from(date, calendar: calendar)
            snapshot = BlindSeam.snapshot(leaf: leaf, writing: snapshot.writing)
        } catch {
            fault = "Today's leaf would not open. Try again."
        }
    }

    func paintSeededHome(at date: Date? = nil) {
        let stamp = date ?? now()
        let leaf = LeafSeed.homeLeaf(on: stamp, calendar: calendar)
        let record = LeafSeed.bond(on: stamp)
        let sealed = LeafSeed.sealedLeaves(on: stamp, calendar: calendar)
        snapshot = BlindSeam.snapshot(leaf: leaf, writing: .alpha)
        bond = BlindSeam.bond(record, sealedLeaves: sealed.count, now: stamp, calendar: calendar)
        shelf = BlindSeam.shelf(from: sealed)
        onboardingComplete = true
        showOnboarding = false
        loadPrefs()
    }

    var todayAsk: String { DayAsk.at(askIndex) }

    var weekMarks: [PageMath.WeekDay] {
        PageMath.week(now: now(), saved: shelf.map(\.dayKey), calendar: calendar)
    }

    var monthMarks: [PageMath.WeekDay] {
        PageMath.monthGrid(now: now(), saved: shelf.map(\.dayKey), calendar: calendar)
    }

    var writeStreak: Int {
        PageMath.streak(days: savedDates, now: now(), calendar: calendar)
    }

    var monthSaves: Int {
        PageMath.count(inMonthOf: now(), days: savedDates, calendar: calendar)
    }

    var recentSaves: Int {
        PageMath.count(lastDays: 30, days: savedDates, now: now(), calendar: calendar)
    }

    var todayWords: Int {
        PageMath.words(in: (snapshot.alpha.readableInk ?? "") + " " + (snapshot.beta.readableInk ?? ""))
    }

    func cycleAsk() {
        askIndex += 1
        persistPrefs()
    }

    func isFavorite(_ id: UUID) -> Bool {
        favoriteIDs.contains(id)
    }

    func toggleFavorite(_ id: UUID) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
        } else {
            favoriteIDs.insert(id)
        }
        persistPrefs()
    }

    func openDay(_ card: ShelfCard) {
        reading = card
    }

    func closeDay() {
        reading = nil
    }

    func shareDay(_ card: ShelfCard) {
        shareText = PageShare.day(
            card,
            alpha: bond?.alphaName ?? "First",
            beta: bond?.betaName ?? "Second"
        )
    }

    func shareBook() {
        shareText = PageShare.book(
            shelf,
            alpha: bond?.alphaName ?? "First",
            beta: bond?.betaName ?? "Second"
        )
    }

    func setReminder(on: Bool, hour: Int) {
        reminderOn = on
        reminderHour = min(max(hour, 0), 23)
        persistPrefs()
        Task { await PageBell.sync(on: reminderOn, hour: reminderHour) }
    }

    func saveNames(alpha: String, beta: String) async {
        let alphaName = trimmed(alpha, fallback: bond?.alphaName ?? "Alex")
        let betaName = trimmed(beta, fallback: bond?.betaName ?? "Sam")
        let stamp = bond?.bondedAt ?? calendar.startOfDay(for: now())
        do {
            try await store?.saveBond(
                BondRecord.fresh(handAlphaName: alphaName, handBetaName: betaName, bondedAt: stamp)
            )
            if let record = await store?.bond() {
                bond = BlindSeam.bond(record, sealedLeaves: shelf.count, now: now(), calendar: calendar)
            }
            fault = nil
        } catch {
            fault = "The names did not save. Try again."
        }
    }

    private var savedDates: [Date] {
        shelf.compactMap { $0.dayKey.date(calendar: calendar) ?? $0.sealedAt }
    }

    private func loadPrefs() {
        let defaults = UserDefaults.standard
        reminderOn = defaults.bool(forKey: PreferenceKey.reminderOn)
        if defaults.object(forKey: PreferenceKey.reminderHour) != nil {
            reminderHour = defaults.integer(forKey: PreferenceKey.reminderHour)
        }
        askIndex = defaults.integer(forKey: PreferenceKey.askIndex)
        favoriteIDs = Set((defaults.stringArray(forKey: PreferenceKey.favorites) ?? []).compactMap(UUID.init(uuidString:)))
    }

    private func persistPrefs() {
        let defaults = UserDefaults.standard
        defaults.set(reminderOn, forKey: PreferenceKey.reminderOn)
        defaults.set(reminderHour, forKey: PreferenceKey.reminderHour)
        defaults.set(askIndex, forKey: PreferenceKey.askIndex)
        defaults.set(favoriteIDs.map(\.uuidString), forKey: PreferenceKey.favorites)
    }

    private func restoreSeededHome(at date: Date) async {
        let leaf = LeafSeed.homeLeaf(on: date, calendar: calendar)
        if let store {
            await store.note(leaf)
            do {
                try await store.flush()
            } catch {
                fault = nil
            }
        }
        snapshot = BlindSeam.snapshot(leaf: leaf, writing: .alpha)
        if bond == nil {
            let record = LeafSeed.bond(on: date)
            bond = BlindSeam.bond(record, sealedLeaves: shelf.count, now: date, calendar: calendar)
        }
        if shelf.isEmpty {
            shelf = BlindSeam.shelf(from: LeafSeed.sealedLeaves(on: date, calendar: calendar))
        }
    }

    private func trimmed(_ raw: String, fallback: String) -> String {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? fallback : value
    }
}
