import SwiftUI

/// Role: Seam. Home diptych. Two wax recesses, one seam. Today's leaf never leaves.
struct DiptychView: View {
    @State var session: LeafSession
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(session: LeafSession) {
        _session = State(initialValue: session)
    }

    init() {
        _session = State(initialValue: .previewPopulated())
    }

    var body: some View {
        @Bindable var session = session
        ZStack {
            WaxFace.Palette.background.ignoresSafeArea()
            diptych
            if let card = session.reading {
                DayReadView(session: session, card: card)
            } else if let card = session.overlay {
                overlayStack(card)
            }
        }
        .preferredColorScheme(.dark)
        .task { await session.bootstrap() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .inactive || phase == .background {
                Task { await session.flush() }
            }
        }
        .fullScreenCover(isPresented: $session.showOnboarding) {
            OnboardingCover { alpha, beta, date in
                Task { await session.completeOnboarding(alpha: alpha, beta: beta, bondedAt: date) }
            }
        }
        .animation(reduceMotion ? nil : WaxFace.motion, value: session.overlay)
        .onChange(of: session.overlay) { _, _ in
            WaxFace.dismissKeyboard()
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: Binding(
            get: { session.shareText != nil },
            set: { if !$0 { session.shareText = nil } }
        )) {
            if let text = session.shareText {
                ShareSheet(items: [text])
            }
        }
    }

    private var diptych: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            VStack(alignment: .leading, spacing: 0) {
                header
                weekRail
                if !session.snapshot.isSealed {
                    todayAsk
                }
                GeometryReader { geo in
                    PugillaresHinge(
                        snapshot: session.snapshot,
                        alphaName: BlindSeam.name(.alpha, bond: session.bond),
                        betaName: BlindSeam.name(.beta, bond: session.bond),
                        onInk: { hand, text in
                            session.writeInk(text, hand: hand)
                        },
                        onHand: { hand in
                            session.takeStylus(hand)
                        }
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minHeight: 280)
                .padding(.horizontal, WaxFace.space(2))
                .padding(.top, WaxFace.space(1))
            }
            .task(id: timeline.date) {
                await session.noteDay(timeline.date)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: WaxFace.space(1)) {
                if let fault = session.fault {
                    faultBanner(fault)
                } else if session.showSpinner {
                    ProgressView()
                        .tint(WaxFace.Palette.accent)
                        .frame(height: WaxFace.tap)
                }
                if session.commitFlash {
                    Image("pgl_SuccessMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: WaxFace.space(6), height: WaxFace.space(6))
                        .accessibilityHidden(true)
                }
                Text(saveHint)
                    .wax(.caption)
                    .foregroundStyle(WaxFace.Palette.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                sealButton
            }
            .padding(.horizontal, WaxFace.space(2))
            .padding(.bottom, WaxFace.space(1))
            .background(WaxFace.Palette.background.ignoresSafeArea())
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: WaxFace.space(1)) {
            headerDecor
            HStack(alignment: .firstTextBaseline, spacing: WaxFace.space(1)) {
                VStack(alignment: .leading, spacing: WaxFace.space(1)) {
                    Text("Today's page")
                        .wax(.title)
                        .foregroundStyle(WaxFace.Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(nextTapLine)
                        .wax(.body)
                        .foregroundStyle(WaxFace.Palette.accent)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: WaxFace.space(1))
                VStack(alignment: .trailing, spacing: 0) {
                    Text(WaxFigures.integer(session.bond?.days ?? 0))
                        .wax(.figure)
                        .foregroundStyle(WaxFace.Palette.accent)
                    Text("days")
                        .wax(.caption)
                        .foregroundStyle(WaxFace.Palette.ink)
                }
                .layoutPriority(1)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Bond days \(WaxFigures.integer(session.bond?.days ?? 0))")
            }
            HStack(spacing: WaxFace.space(2)) {
                overlayLink("Together") { session.present(.bond) }
                overlayLink("Past days") { session.present(.shelf) }
                overlayLink("Settings") { session.present(.settings) }
                Spacer(minLength: 0)
            }
            HStack(spacing: WaxFace.space(1)) {
                stylusChip(.alpha)
                stylusChip(.beta)
            }
        }
        .padding(.horizontal, WaxFace.space(2))
        .contentShape(Rectangle())
        .onTapGesture { WaxFace.dismissKeyboard() }
    }

    private var headerDecor: some View {
        Color.clear
            .frame(height: WaxFace.space(5))
            .frame(maxWidth: .infinity)
            .overlay {
                Image("pgl_HeaderDecor")
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .padding(.horizontal, -WaxFace.space(2))
            .padding(.top, -WaxFace.space(1))
            .accessibilityHidden(true)
    }

    private var nextTapLine: String {
        if session.snapshot.isSealed {
            return "Saved. Open Past days to read both notes."
        }
        if session.snapshot.canSeal {
            return "Both notes are in. Save this day."
        }
        let north = plateHasInk(session.snapshot.alpha)
        let south = plateHasInk(session.snapshot.beta)
        let other = BlindSeam.name(north ? .beta : .alpha, bond: session.bond)
        if north, !south {
            return "Pass the phone. \(other) writes next."
        }
        if south, !north {
            return "Pass the phone. \(other) writes next."
        }
        return "You write first. They write second. Neither can peek."
    }

    private func plateHasInk(_ face: PlateFace) -> Bool {
        Plate(hand: .alpha, ink: face.readableInk ?? "").hasInk
    }

    private var todayAsk: some View {
        HStack(alignment: .top, spacing: WaxFace.space(2)) {
            VStack(alignment: .leading, spacing: WaxFace.space(1)) {
                Text("Today’s question")
                    .wax(.caption)
                    .foregroundStyle(WaxFace.Palette.muted)
                Text(session.todayAsk)
                    .wax(.body)
                    .foregroundStyle(WaxFace.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(WaxFigures.integer(session.todayWords)) words · \(WaxFigures.integer(session.writeStreak)) day streak")
                    .wax(.caption)
                    .foregroundStyle(WaxFace.Palette.muted)
            }
            Button {
                session.cycleAsk()
            } label: {
                Text("Next")
                    .wax(.caption)
                    .foregroundStyle(WaxFace.Palette.background)
                    .padding(.horizontal, WaxFace.space(2))
                    .frame(minHeight: WaxFace.tap)
                    .background(WaxFace.Palette.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next question")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, WaxFace.space(2))
        .padding(.top, WaxFace.space(1))
    }

    private var weekRail: some View {
        HStack(spacing: WaxFace.space(1)) {
            ForEach(session.weekMarks) { day in
                VStack(spacing: 4) {
                    Text(day.short)
                        .wax(.caption)
                        .foregroundStyle(day.isToday ? WaxFace.Palette.accent : WaxFace.Palette.muted)
                    Circle()
                        .fill(day.saved ? WaxFace.Palette.accent : WaxFace.Palette.surface)
                        .frame(width: 10, height: 10)
                        .overlay {
                            Circle().strokeBorder(WaxFace.Palette.accent, lineWidth: day.isToday ? 2 : 1)
                        }
                }
                .frame(maxWidth: .infinity)
                .accessibilityLabel(day.saved ? "\(day.short) saved" : "\(day.short) open")
            }
        }
        .padding(.horizontal, WaxFace.space(2))
        .padding(.top, WaxFace.space(1))
    }

    private var saveHint: String {
        if session.snapshot.isSealed {
            return "Today is locked. Tomorrow opens a new page."
        }
        if session.snapshot.canSeal {
            return "Saving files both notes and puts the day in Past days."
        }
        return "The save button waits until both people have written."
    }

    private var sealButton: some View {
        Button {
            Task { await session.seal() }
        } label: {
            HStack(spacing: WaxFace.space(1)) {
                Image("pgl_ControlFace")
                    .resizable()
                    .scaledToFit()
                    .frame(width: WaxFace.space(4), height: WaxFace.space(4))
                    .accessibilityHidden(true)
                Text(session.snapshot.isSealed ? "Saved for today" : "Save today's page")
                    .wax(.seal)
                    .foregroundStyle(WaxFace.Palette.background)
            }
            .frame(maxWidth: .infinity, minHeight: WaxFace.tap)
            .background(session.snapshot.canSeal ? WaxFace.Palette.accent : WaxFace.Palette.muted)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!session.snapshot.canSeal || session.sealBusy)
        .accessibilityLabel("Seal the seam")
        .accessibilityHint(session.snapshot.canSeal ? "Files both plates" : "Write both plates first")
    }

    private func overlayStack(_ card: SeamCard) -> some View {
        ZStack {
            WaxFace.Palette.background.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture { session.dismissOverlay() }
                .accessibilityHidden(true)
            Group {
                switch card {
                case .bond:
                    BondView(session: session)
                case .shelf:
                    ShelfView(session: session)
                case .settings:
                    SettingsView(session: session)
                case .seam:
                    BlindSeamView(session: session)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(WaxFace.Palette.background.ignoresSafeArea())
        }
    }

    private func stylusChip(_ hand: HandSide) -> some View {
        let selected = session.snapshot.writing == hand && !session.snapshot.isSealed
        let name = BlindSeam.name(hand, bond: session.bond)
        return Button {
            session.takeStylus(hand)
        } label: {
            Text(name)
                .wax(.caption)
                .foregroundStyle(selected ? WaxFace.Palette.background : WaxFace.Palette.ink)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, minHeight: WaxFace.tap)
                .background(selected ? WaxFace.Palette.accent : WaxFace.Palette.surface)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(session.snapshot.isSealed)
        .accessibilityLabel("\(name) writes now")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func overlayLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .wax(.caption)
                .foregroundStyle(WaxFace.Palette.accent)
                .frame(minHeight: WaxFace.tap)
                .padding(.horizontal, WaxFace.space(1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func faultBanner(_ text: String) -> some View {
        Button {
            Task { await session.load() }
        } label: {
            VStack(alignment: .leading, spacing: WaxFace.space(1)) {
                Text(text)
                    .wax(.caption)
                    .foregroundStyle(WaxFace.Palette.ink)
                Text("Try again")
                    .wax(.body)
                    .foregroundStyle(WaxFace.Palette.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(WaxFace.space(2))
            .background(WaxFace.Palette.surface)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
