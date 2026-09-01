import SwiftUI

/// Role: Bond. Overlay of bondDays and milestones 7/30/90/365. ReviewScreen goals.
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
                instrument(bond)
                backToHinge
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WaxFace.Palette.background.ignoresSafeArea())
    }

    private var chrome: some View {
        VStack(alignment: .leading, spacing: WaxFace.space(1)) {
            HStack(alignment: .firstTextBaseline) {
                Text("Bond days")
                    .wax(.title)
                    .foregroundStyle(WaxFace.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: WaxFace.space(1))
                closeButton
            }
            Text("The tally. Close returns to today's hinge.")
                .wax(.body)
                .foregroundStyle(WaxFace.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, WaxFace.space(2))
        .padding(.top, WaxFace.space(2))
        .padding(.bottom, WaxFace.space(2))
    }

    private var closeButton: some View {
        Button {
            session.dismissOverlay()
        } label: {
            Text("Close")
                .wax(.body)
                .foregroundStyle(WaxFace.Palette.background)
                .frame(minWidth: WaxFace.tap, minHeight: WaxFace.tap)
                .padding(.horizontal, WaxFace.space(2))
                .background(WaxFace.Palette.accent)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close bond")
        .accessibilityHint("Returns to today's hinge")
    }

    private var backToHinge: some View {
        Button {
            session.dismissOverlay()
        } label: {
            Text("Back to today's hinge")
                .wax(.seal)
                .foregroundStyle(WaxFace.Palette.background)
                .frame(maxWidth: .infinity, minHeight: WaxFace.tap)
                .background(WaxFace.Palette.accent)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, WaxFace.space(2))
        .padding(.vertical, WaxFace.space(2))
        .accessibilityHint("Closes the bond tally")
    }

    private var emptyState: some View {
        VStack(spacing: WaxFace.space(2)) {
            Image("pgl_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 240, maxHeight: 240)
                .accessibilityHidden(true)
            Text("No bond date.")
                .wax(.title)
                .foregroundStyle(WaxFace.Palette.ink)
            Text("Name the two hands and stamp the day you began.")
                .wax(.body)
                .foregroundStyle(WaxFace.Palette.ink)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            Button {
                session.rerunOnboarding()
            } label: {
                Text("Stamp the hands")
                    .wax(.seal)
                    .foregroundStyle(WaxFace.Palette.background)
                    .frame(maxWidth: .infinity, minHeight: WaxFace.tap)
                    .background(WaxFace.Palette.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, WaxFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func instrument(_ bond: BondSnapshot) -> some View {
        GeometryReader { geo in
            let wide = geo.size.width >= 700
            Group {
                if wide {
                    HStack(alignment: .top, spacing: WaxFace.space(2)) {
                        daysPlate(bond)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        markRail(bond)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    VStack(alignment: .leading, spacing: WaxFace.space(2)) {
                        daysPlate(bond)
                            .frame(maxWidth: .infinity)
                            .frame(height: max(WaxFace.space(22), geo.size.height * 0.36))
                        markRail(bond)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .padding(.horizontal, WaxFace.space(2))
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(tallyLabel(bond))
    }

    private func daysPlate(_ bond: BondSnapshot) -> some View {
        let toward = waxTowardNext(bond)
        return GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                WaxFace.Palette.surface
                WaxFace.Palette.background
                    .padding(WaxFace.space(2))
                WaxFace.Palette.accent.opacity(0.42)
                    .frame(height: max(WaxFace.space(4), (geo.size.height - WaxFace.space(4)) * toward))
                    .padding(.horizontal, WaxFace.space(2))
                    .padding(.bottom, WaxFace.space(2))
                VStack(alignment: .leading, spacing: WaxFace.space(1)) {
                    Text(WaxFigures.integer(bond.days))
                        .wax(.display)
                        .foregroundStyle(WaxFace.Palette.accent)
                    Text("days bonded")
                        .wax(.title)
                        .foregroundStyle(WaxFace.Palette.ink)
                    Text("\(bond.alphaName) · \(bond.betaName)")
                        .wax(.body)
                        .foregroundStyle(WaxFace.Palette.ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text("Bonded \(WaxFigures.day(bond.bondedAt))")
                        .wax(.body)
                        .foregroundStyle(WaxFace.Palette.ink)
                    Text("\(WaxFigures.integer(bond.sealedLeaves)) sealed leaves")
                        .wax(.body)
                        .foregroundStyle(WaxFace.Palette.ink)
                    if let next = bond.next {
                        Text("\(WaxFigures.integer(next - bond.days)) days to the \(WaxFigures.integer(next)) mark")
                            .wax(.body)
                            .foregroundStyle(WaxFace.Palette.ink)
                    }
                    leafWell(bond)
                }
                .padding(WaxFace.space(3))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .overlay {
                Rectangle().strokeBorder(WaxFace.Palette.accent, lineWidth: 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func leafWell(_ bond: BondSnapshot) -> some View {
        let stamps = stampCount(bond)
        return GeometryReader { geo in
            let gap = WaxFace.space(1)
            let cols = geo.size.width >= WaxFace.space(16) && geo.size.height >= WaxFace.space(12) ? 2 : max(stamps, 1)
            let rows = max((max(stamps, 1) + cols - 1) / cols, 1)
            let cellW = (geo.size.width - gap * CGFloat(max(cols - 1, 0))) / CGFloat(max(cols, 1))
            let cellH = (geo.size.height - gap * CGFloat(max(rows - 1, 0))) / CGFloat(rows)
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: gap), count: cols),
                spacing: gap
            ) {
                ForEach(0..<stamps, id: \.self) { _ in
                    leafStamp()
                        .frame(width: cellW, height: max(WaxFace.space(6), cellH))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func leafStamp() -> some View {
        ZStack {
            WaxFace.Palette.surface
            WaxFace.Palette.accent.opacity(0.3)
            VStack(spacing: WaxFace.space(1)) {
                Circle()
                    .fill(WaxFace.Palette.accent)
                    .frame(width: 14, height: 14)
                Text("sealed")
                    .wax(.caption)
                    .foregroundStyle(WaxFace.Palette.ink)
            }
        }
        .overlay {
            Rectangle().strokeBorder(WaxFace.Palette.accent, lineWidth: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func markRail(_ bond: BondSnapshot) -> some View {
        VStack(alignment: .leading, spacing: WaxFace.space(1)) {
            railHeader(bond)
            ForEach(BondTally.milestones.reversed(), id: \.self) { mark in
                markBand(mark, bond)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func railHeader(_ bond: BondSnapshot) -> some View {
        HStack(alignment: .center, spacing: WaxFace.space(1)) {
            Text("Marks 7 · 30 · 90 · 365")
                .wax(.caption)
                .foregroundStyle(WaxFace.Palette.ink)
                .layoutPriority(1)
            HStack(spacing: WaxFace.space(1)) {
                ForEach(0..<stampCount(bond), id: \.self) { _ in
                    Circle()
                        .fill(WaxFace.Palette.accent)
                        .frame(width: 10, height: 10)
                }
            }
            Text("\(WaxFigures.integer(bond.sealedLeaves)) sealed")
                .wax(.caption)
                .foregroundStyle(WaxFace.Palette.accent)
                .layoutPriority(1)
        }
    }

    private func markBand(_ mark: Int, _ bond: BondSnapshot) -> some View {
        let reached = bond.reached.contains(mark)
        let isNext = bond.next == mark
        let fill = min(1, CGFloat(max(bond.days, 0)) / CGFloat(max(mark, 1)))
        return HStack(alignment: .center, spacing: WaxFace.space(2)) {
            Text(WaxFigures.integer(mark))
                .wax(.figure)
                .foregroundStyle(reached ? WaxFace.Palette.accent : WaxFace.Palette.ink)
                .frame(minWidth: WaxFace.space(7), alignment: .trailing)
                .layoutPriority(1)
            VStack(spacing: 0) {
                Rectangle()
                    .fill(reached ? WaxFace.Palette.accent : WaxFace.Palette.ink.opacity(0.4))
                    .frame(width: 4)
                    .frame(maxHeight: .infinity)
                Circle()
                    .fill(reached ? WaxFace.Palette.accent : WaxFace.Palette.background)
                    .frame(width: 14, height: 14)
                    .overlay {
                        Circle().stroke(WaxFace.Palette.ink, lineWidth: 1)
                    }
                Rectangle()
                    .fill(reached ? WaxFace.Palette.accent : WaxFace.Palette.ink.opacity(0.4))
                    .frame(width: 4)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 16)
            .frame(maxHeight: .infinity)
            VStack(alignment: .leading, spacing: WaxFace.space(1)) {
                HStack(alignment: .firstTextBaseline, spacing: WaxFace.space(1)) {
                    Text(reached ? "reached" : (isNext ? "next mark" : "ahead"))
                        .wax(.body)
                        .foregroundStyle(WaxFace.Palette.ink)
                    if isNext {
                        Text("\(WaxFigures.integer(mark - bond.days)) days from now")
                            .wax(.caption)
                            .foregroundStyle(WaxFace.Palette.ink)
                    }
                }
                waxTrough(
                    fill: fill,
                    reached: reached,
                    isNext: isNext,
                    leaves: isNext ? stampCount(bond) : 0
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityLabel(
            "Milestone \(WaxFigures.integer(mark)) \(reached ? "reached" : (isNext ? "next" : "ahead"))"
        )
    }

    private func waxTrough(fill: CGFloat, reached: Bool, isNext: Bool, leaves: Int) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                WaxFace.Palette.surface
                WaxFace.Palette.accent.opacity(reached ? 0.88 : (isNext ? 0.55 : 0.28))
                    .frame(width: max(WaxFace.space(1), geo.size.width * fill))
                if leaves > 0 {
                    HStack(spacing: WaxFace.space(1)) {
                        ForEach(0..<leaves, id: \.self) { _ in
                            Circle()
                                .fill(WaxFace.Palette.background)
                                .frame(width: 12, height: 12)
                                .overlay {
                                    Circle().stroke(WaxFace.Palette.accent, lineWidth: 1)
                                }
                        }
                    }
                    .padding(.leading, WaxFace.space(1))
                }
            }
            .overlay {
                Rectangle().strokeBorder(WaxFace.Palette.accent, lineWidth: isNext ? 2 : 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func waxTowardNext(_ bond: BondSnapshot) -> CGFloat {
        guard let next = bond.next else { return 1 }
        return min(1, CGFloat(max(bond.days, 0)) / CGFloat(next))
    }

    private func stampCount(_ bond: BondSnapshot) -> Int {
        min(max(bond.sealedLeaves, 0), 8)
    }

    private func tallyLabel(_ bond: BondSnapshot) -> String {
        var parts = [
            "Bond days \(WaxFigures.integer(bond.days))",
            "\(bond.alphaName) and \(bond.betaName)",
            "\(WaxFigures.integer(bond.sealedLeaves)) sealed leaves",
        ]
        for mark in BondTally.milestones {
            let state = bond.reached.contains(mark) ? "reached" : "ahead"
            parts.append("\(WaxFigures.integer(mark)) \(state)")
        }
        return parts.joined(separator: ". ")
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
        .padding(.horizontal, WaxFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
