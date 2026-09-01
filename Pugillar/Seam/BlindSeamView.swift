import SwiftUI

/// Role: Seam. Twist screen. Blind-seam seal — neither half is readable until both have written.
struct BlindSeamView: View {
    @State var session: LeafSession

    init(session: LeafSession) {
        _session = State(initialValue: session)
    }

    init() {
        _session = State(initialValue: .previewPopulated())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: WaxFace.space(2)) {
            chrome
            if session.fault != nil && session.snapshot.isEmpty {
                errorState
            } else if session.snapshot.isEmpty && session.bond == nil {
                emptyState
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WaxFace.Palette.background.ignoresSafeArea())
    }

    private var chrome: some View {
        HStack {
            Text("Blind seam")
                .wax(.title)
                .foregroundStyle(WaxFace.Palette.ink)
            Spacer()
            Button {
                session.dismissOverlay()
            } label: {
                Text("Close")
                    .wax(.body)
                    .foregroundStyle(WaxFace.Palette.accent)
                    .frame(minWidth: WaxFace.tap, minHeight: WaxFace.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close seam")
        }
    }

    private var emptyState: some View {
        VStack(spacing: WaxFace.space(2)) {
            Image("pgl_TwistHero")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 240, maxHeight: 240)
                .accessibilityHidden(true)
            Text("Two shuttered plates.")
                .wax(.title)
                .foregroundStyle(WaxFace.Palette.ink)
            Text("Write the first line. Seal stays dead until the other hand writes.")
                .wax(.body)
                .foregroundStyle(WaxFace.Palette.muted)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            Button {
                session.dismissOverlay()
            } label: {
                Text("Ink a plate")
                    .wax(.seal)
                    .foregroundStyle(WaxFace.Palette.background)
                    .frame(maxWidth: .infinity, minHeight: WaxFace.tap)
                    .background(WaxFace.Palette.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var populated: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WaxFace.space(2)) {
                Image("pgl_TwistHero")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
                Text("Neither half is readable until both have written.")
                    .wax(.body)
                    .foregroundStyle(WaxFace.Palette.ink)
                Text("Seal files the leaf and freezes it. A missing plate keeps that leaf as home.")
                    .wax(.caption, italic: true)
                    .foregroundStyle(WaxFace.Palette.muted)
                Text(session.snapshot.canSeal ? "Both plates hold ink. The seam may open." : "Seal is dead. One plate is still blank.")
                    .wax(.body)
                    .foregroundStyle(WaxFace.Palette.accent)
            }
        }
        .contentMargins(.bottom, WaxFace.space(2), for: .scrollContent)
        .scrollDismissesKeyboard(.interactively)
    }

    private var errorState: some View {
        VStack(alignment: .leading, spacing: WaxFace.space(2)) {
            Text(session.fault ?? "The seam would not open.")
                .wax(.body)
                .foregroundStyle(WaxFace.Palette.ink)
            Button {
                Task { await session.load() }
            } label: {
                Text("Try again")
                    .wax(.body)
                    .foregroundStyle(WaxFace.Palette.background)
                    .frame(maxWidth: .infinity, minHeight: WaxFace.tap)
                    .background(WaxFace.Palette.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
