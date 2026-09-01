import SwiftUI

/// Role: Leaf. Settings overlay. Contact URL, re-run onboarding, resetAllData.
struct SettingsView: View {
    @State var session: LeafSession
    @State private var confirmReset = false
    @Environment(\.openURL) private var openURL

    init(session: LeafSession) {
        _session = State(initialValue: session)
    }

    init() {
        _session = State(initialValue: .previewSettings())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: WaxFace.space(2)) {
            chrome
            if let fault = session.fault, session.bond == nil, !session.onboardingComplete {
                errorState(fault)
            } else if session.bond == nil && !session.onboardingComplete {
                emptyState
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WaxFace.Palette.background.ignoresSafeArea())
        .confirmationDialog("Erase every leaf?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset all data", role: .destructive) {
                Task { await session.resetAll() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var chrome: some View {
        HStack {
            Text("Settings")
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
            .accessibilityLabel("Close settings")
        }
        .padding(.horizontal, WaxFace.space(2))
        .padding(.top, WaxFace.space(2))
    }

    private var emptyState: some View {
        VStack(spacing: WaxFace.space(2)) {
            Image("pgl_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 240, maxHeight: 240)
                .accessibilityHidden(true)
            Text("No bond stamped.")
                .wax(.title)
                .foregroundStyle(WaxFace.Palette.ink)
            Text("Name the hands before the first seal.")
                .wax(.body)
                .foregroundStyle(WaxFace.Palette.muted)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            Button {
                session.rerunOnboarding()
            } label: {
                Text("Open onboarding")
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
        VStack(alignment: .leading, spacing: WaxFace.space(1)) {
            if let bond = session.bond {
                section("Hands")
                info("\(bond.alphaName) · \(bond.betaName)")
                info("Bonded \(WaxFigures.day(bond.bondedAt))")
                info("\(WaxFigures.integer(bond.days)) days · \(WaxFigures.integer(bond.sealedLeaves)) sealed")
            }
            section("App")
            action("Contact Pugillar") {
                openURL(PugillarClient.contactURL)
            }
            action("Re-run onboarding") {
                session.rerunOnboarding()
            }
            action("Reset all data") {
                confirmReset = true
            }
        }
    }

    private func section(_ title: String) -> some View {
        Text(title)
            .wax(.caption)
            .foregroundStyle(WaxFace.Palette.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, WaxFace.space(2))
            .padding(.top, WaxFace.space(2))
    }

    private func info(_ title: String) -> some View {
        Text(title)
            .wax(.body)
            .foregroundStyle(WaxFace.Palette.ink)
            .frame(maxWidth: .infinity, minHeight: WaxFace.tap, alignment: .leading)
            .padding(.horizontal, WaxFace.space(2))
            .background(WaxFace.Palette.surface)
    }

    private func action(_ title: String, work: @escaping () -> Void) -> some View {
        Button(action: work) {
            Text(title)
                .wax(.body)
                .foregroundStyle(WaxFace.Palette.ink)
                .frame(maxWidth: .infinity, minHeight: WaxFace.tap, alignment: .leading)
                .padding(.horizontal, WaxFace.space(2))
                .background(WaxFace.Palette.surface)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func errorState(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: WaxFace.space(2)) {
            Text(text)
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
