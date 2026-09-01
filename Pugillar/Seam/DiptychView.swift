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
            if let card = session.overlay {
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
    }

    private var diptych: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            VStack(alignment: .leading, spacing: 0) {
                header
                if let prompt = session.snapshot.prompt, !session.snapshot.canSeal, !session.snapshot.isSealed {
                    promptLine(prompt)
                }
                GeometryReader { geo in
                    ZStack {
                        PugillaresHinge(
                            snapshot: session.snapshot,
                            onInk: { hand, text in
                                session.writeInk(text, hand: hand)
                            },
                            onHand: { hand in
                                session.takeStylus(hand)
                            }
                        )
                        .frame(width: geo.size.width, height: geo.size.height)
                        HStack(spacing: WaxFace.space(2)) {
                            waxInk(session.snapshot.alpha)
                            waxInk(session.snapshot.beta)
                        }
                        .padding(.horizontal, WaxFace.space(3))
                        .padding(.top, WaxFace.space(6))
                        .padding(.bottom, WaxFace.space(2))
                        .allowsHitTesting(false)
                    }
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
                    Text("Ink both plates")
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
                overlayLink("Bond") { session.present(.bond) }
                overlayLink("Shelf") { session.present(.shelf) }
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
            return "Filed. Open Shelf for past leaves."
        }
        if session.snapshot.canSeal {
            return "Both halves are ready. Seal the seam."
        }
        let north = plateHasInk(session.snapshot.alpha)
        let south = plateHasInk(session.snapshot.beta)
        if north, !south {
            return "Ink the south half."
        }
        if south, !north {
            return "Ink the north half."
        }
        return "Two halves. Write the first line."
    }

    private func plateHasInk(_ face: PlateFace) -> Bool {
        Plate(hand: .alpha, ink: face.readableInk ?? "").hasInk
    }

    private func waxInk(_ face: PlateFace) -> some View {
        Group {
            if face.isShuttered {
                Color.clear
            } else if let ink = face.readableInk, Plate(hand: .alpha, ink: ink).hasInk {
                Text(ink)
                    .wax(.body)
                    .foregroundStyle(WaxFace.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(WaxFace.space(2))
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func promptLine(_ prompt: PromptGate) -> some View {
        Text(prompt.question)
            .wax(.caption)
            .foregroundStyle(WaxFace.Palette.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, WaxFace.space(2))
            .padding(.top, WaxFace.space(1))
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
                Text("Seal the seam")
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
        .accessibilityLabel("\(name) takes the stylus")
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
