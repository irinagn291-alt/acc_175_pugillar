import SwiftUI

/// Role: Bond. Days together, streak, marks, last saved pages.
struct BondView: View {
    @State var session: LeafSession

    init(session: LeafSession) {
        _session = State(initialValue: session)
    }

    init() {
        _session = State(initialValue: .previewBond())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            chrome
            if let fault = session.fault, session.bond == nil {
                errorState(fault)
            } else if let bond = session.bond {
                ScrollView {
                    VStack(alignment: .leading, spacing: WaxFace.space(2)) {
                        hero(bond)
                        statRow(bond)
                        marks(bond)
                        recent
                        actions
                    }
                    .padding(.horizontal, WaxFace.space(2))
                    .padding(.bottom, WaxFace.space(2))
                }
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WaxFace.Palette.background.ignoresSafeArea())
    }

    private var chrome: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: WaxFace.space(1)) {
                Text("Together")
                    .wax(.title)
                    .foregroundStyle(WaxFace.Palette.ink)
                Text("Your shared book.")
                    .wax(.caption)
                    .foregroundStyle(WaxFace.Palette.muted)
            }
            Spacer(minLength: WaxFace.space(1))
            Button {
                session.dismissOverlay()
            } label: {
                Text("Close")
                    .wax(.body)
                    .foregroundStyle(WaxFace.Palette.background)
                    .padding(.horizontal, WaxFace.space(2))
                    .frame(minHeight: WaxFace.tap)
                    .background(WaxFace.Palette.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close together")
        }
        .padding(WaxFace.space(2))
    }

    private func hero(_ bond: BondSnapshot) -> some View {
        VStack(alignment: .leading, spacing: WaxFace.space(1)) {
            Text(WaxFigures.integer(bond.days))
                .wax(.display)
                .foregroundStyle(WaxFace.Palette.accent)
            Text("days together")
                .wax(.title)
                .foregroundStyle(WaxFace.Palette.ink)
            Text("\(bond.alphaName) and \(bond.betaName)")
                .wax(.body)
                .foregroundStyle(WaxFace.Palette.ink)
            Text("Started \(WaxFigures.day(bond.bondedAt))")
                .wax(.caption)
                .foregroundStyle(WaxFace.Palette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WaxFace.space(2))
        .background(WaxFace.Palette.surface)
        .overlay {
            Rectangle().strokeBorder(WaxFace.Palette.accent, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(tallyLabel(bond))
    }

    private func statRow(_ bond: BondSnapshot) -> some View {
        HStack(spacing: WaxFace.space(1)) {
            stat("Saved", WaxFigures.integer(bond.sealedLeaves))
            stat("Streak", WaxFigures.integer(session.writeStreak))
            stat("Last 30 days", WaxFigures.integer(session.recentSaves))
        }
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .wax(.figure)
                .foregroundStyle(WaxFace.Palette.accent)
            Text(title)
                .wax(.caption)
                .foregroundStyle(WaxFace.Palette.muted)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WaxFace.space(2))
        .background(WaxFace.Palette.surface)
    }

    private func marks(_ bond: BondSnapshot) -> some View {
        VStack(alignment: .leading, spacing: WaxFace.space(1)) {
            Text("Marks")
                .wax(.caption)
                .foregroundStyle(WaxFace.Palette.muted)
            ForEach(BondTally.milestones, id: \.self) { mark in
                let reached = bond.reached.contains(mark)
                let isNext = bond.next == mark
                HStack {
                    Text(WaxFigures.integer(mark))
                        .wax(.body)
                        .foregroundStyle(reached ? WaxFace.Palette.accent : WaxFace.Palette.ink)
                        .frame(width: 48, alignment: .leading)
                    Text(reached ? "Reached" : (isNext ? "Next · \(WaxFigures.integer(mark - bond.days)) days left" : "Ahead"))
                        .wax(.caption)
                        .foregroundStyle(WaxFace.Palette.muted)
                    Spacer()
                }
                .frame(minHeight: 36)
            }
        }
        .padding(WaxFace.space(2))
        .background(WaxFace.Palette.surface)
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: WaxFace.space(1)) {
            Text("Latest pages")
                .wax(.caption)
                .foregroundStyle(WaxFace.Palette.muted)
            if session.shelf.isEmpty {
                Text("Save today’s page to start the book.")
                    .wax(.body)
                    .foregroundStyle(WaxFace.Palette.ink)
            } else {
                ForEach(Array(session.shelf.prefix(3))) { card in
                    Button {
                        session.openDay(card)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.sealedAt.map(WaxFigures.day) ?? "Saved day")
                                .wax(.caption)
                                .foregroundStyle(WaxFace.Palette.accent)
                            Text(card.alphaInk)
                                .wax(.body)
                                .foregroundStyle(WaxFace.Palette.ink)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(WaxFace.space(2))
                        .background(WaxFace.Palette.background)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: WaxFace.space(1)) {
            Button {
                session.present(.shelf)
            } label: {
                Text("Open past days")
                    .wax(.seal)
                    .foregroundStyle(WaxFace.Palette.background)
                    .frame(maxWidth: .infinity, minHeight: WaxFace.tap)
                    .background(WaxFace.Palette.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button {
                session.dismissOverlay()
            } label: {
                Text("Back to today's page")
                    .wax(.body)
                    .foregroundStyle(WaxFace.Palette.ink)
                    .frame(maxWidth: .infinity, minHeight: WaxFace.tap)
                    .background(WaxFace.Palette.surface)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyState: some View {
        VStack(spacing: WaxFace.space(2)) {
            Text("No start date yet.")
                .wax(.title)
                .foregroundStyle(WaxFace.Palette.ink)
            Text("Name both people, then write today’s page.")
                .wax(.body)
                .foregroundStyle(WaxFace.Palette.ink)
                .multilineTextAlignment(.center)
            Button {
                session.rerunOnboarding()
            } label: {
                Text("Name both people")
                    .wax(.seal)
                    .foregroundStyle(WaxFace.Palette.background)
                    .frame(maxWidth: .infinity, minHeight: WaxFace.tap)
                    .background(WaxFace.Palette.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(WaxFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func tallyLabel(_ bond: BondSnapshot) -> String {
        "\(WaxFigures.integer(bond.days)) days together. \(bond.alphaName) and \(bond.betaName). \(WaxFigures.integer(bond.sealedLeaves)) saved days."
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
        .padding(WaxFace.space(2))
    }
}
