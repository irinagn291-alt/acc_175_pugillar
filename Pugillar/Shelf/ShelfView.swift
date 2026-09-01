import SwiftUI

/// Role: Shelf. Overlay stack of sealed leaves only. ReviewScreen log. No public feed.
struct ShelfView: View {
    @State var session: LeafSession

    init(session: LeafSession) {
        _session = State(initialValue: session)
    }

    init() {
        _session = State(initialValue: .previewShelf())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            chrome
            if let fault = session.fault, session.shelf.isEmpty, session.warning == .startedEmpty {
                errorState(fault)
            } else if session.shelf.isEmpty {
                emptyState
            } else {
                populated
                backToHinge
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WaxFace.Palette.background.ignoresSafeArea())
    }

    private var chrome: some View {
        VStack(alignment: .leading, spacing: WaxFace.space(1)) {
            HStack(alignment: .firstTextBaseline) {
                Text("Sealed seams")
                    .wax(.title)
                    .foregroundStyle(WaxFace.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: WaxFace.space(1))
                closeButton
            }
            Text(jobLine)
                .wax(.body)
                .foregroundStyle(WaxFace.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, WaxFace.space(2))
        .padding(.top, WaxFace.space(2))
        .padding(.bottom, WaxFace.space(2))
    }

    private var jobLine: String {
        let count = WaxFigures.integer(session.shelf.count)
        return "\(count) filed diptychs. Close returns to today's hinge."
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
        .accessibilityLabel("Close shelf")
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
        .accessibilityHint("Closes the sealed stack")
    }

    private var emptyState: some View {
        VStack(spacing: WaxFace.space(2)) {
            Image("pgl_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 240, maxHeight: 240)
                .accessibilityHidden(true)
            Text("No sealed leaves.")
                .wax(.title)
                .foregroundStyle(WaxFace.Palette.ink)
            Text("Seal today's seam. Midnight will not file a one-sided night.")
                .wax(.body)
                .foregroundStyle(WaxFace.Palette.ink)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            Button {
                session.dismissOverlay()
            } label: {
                Text("Back to the seam")
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

    private var populated: some View {
        GeometryReader { geo in
            let wide = geo.size.width >= 700
            let gap = WaxFace.space(2)
            let count = max(session.shelf.count, 1)
            let bottomClear = WaxFace.space(4)
            ScrollView {
                if wide {
                    let rows = max((count + 1) / 2, 1)
                    let fitted = (geo.size.height - bottomClear - gap * CGFloat(rows - 1)) / CGFloat(rows)
                    let leafH = max(WaxFace.space(14), min(fitted, WaxFace.space(28)))
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: gap),
                            GridItem(.flexible(), spacing: gap),
                        ],
                        spacing: gap
                    ) {
                        ForEach(session.shelf) { card in
                            filedDiptych(card)
                                .frame(height: leafH)
                        }
                    }
                    .padding(.horizontal, WaxFace.space(2))
                } else {
                    let fitted = (geo.size.height - bottomClear - gap * CGFloat(count - 1)) / CGFloat(count)
                    let leafH = max(WaxFace.space(14), min(fitted, WaxFace.space(24)))
                    VStack(spacing: gap) {
                        ForEach(session.shelf) { card in
                            filedDiptych(card)
                                .frame(height: leafH)
                        }
                    }
                    .padding(.horizontal, WaxFace.space(2))
                }
            }
            .contentMargins(.bottom, bottomClear, for: .scrollContent)
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func filedDiptych(_ card: ShelfCard) -> some View {
        let dates = shelfDates(card)
        return VStack(alignment: .leading, spacing: WaxFace.space(1)) {
            HStack(alignment: .firstTextBaseline, spacing: WaxFace.space(1)) {
                Text(dates.primary)
                    .wax(.caption)
                    .foregroundStyle(WaxFace.Palette.ink)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
                Text("Sealed")
                    .wax(.caption)
                    .foregroundStyle(WaxFace.Palette.accent)
                    .layoutPriority(1)
            }
            HStack(spacing: 0) {
                plate(northName, ink: card.alphaInk)
                hingeRail
                plate(southName, ink: card.betaInk)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Sealed leaf \(dates.primary). \(northName): \(card.alphaInk). \(southName): \(card.betaInk)."
        )
    }

    private var northName: String {
        session.bond?.alphaName ?? "North"
    }

    private var southName: String {
        session.bond?.betaName ?? "South"
    }

    private func plate(_ name: String, ink: String) -> some View {
        VStack(alignment: .leading, spacing: WaxFace.space(1)) {
            Text(name)
                .wax(.caption, italic: true)
                .foregroundStyle(WaxFace.Palette.ink)
                .lineLimit(1)
                .truncationMode(.tail)
            Text(ink)
                .wax(.body)
                .foregroundStyle(WaxFace.Palette.ink)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(WaxFace.space(1))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WaxFace.Palette.background)
        .overlay {
            Rectangle().strokeBorder(WaxFace.Palette.accent, lineWidth: 2)
        }
        .padding(WaxFace.space(1))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WaxFace.Palette.surface)
        .overlay {
            Rectangle().strokeBorder(WaxFace.Palette.accent.opacity(0.7), lineWidth: 1)
        }
    }

    private var hingeRail: some View {
        ZStack {
            Rectangle()
                .fill(WaxFace.Palette.accent)
                .frame(width: 4)
            VStack {
                Circle()
                    .fill(WaxFace.Palette.accent)
                    .frame(width: 14, height: 14)
                Spacer(minLength: 0)
                Circle()
                    .fill(WaxFace.Palette.accent)
                    .frame(width: 14, height: 14)
            }
            .padding(.vertical, WaxFace.space(1))
        }
        .frame(width: 16)
        .frame(maxHeight: .infinity)
        .accessibilityHidden(true)
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

    private func shelfDates(_ card: ShelfCard) -> (primary: String, secondary: String?) {
        if let sealed = card.sealedAt {
            let sealedText = WaxFigures.day(sealed)
            if LeafDayKey.from(sealed, calendar: .current) == card.dayKey {
                return (sealedText, nil)
            }
            return (dayLabel(card.dayKey), sealedText)
        }
        return (dayLabel(card.dayKey), nil)
    }

    private func dayLabel(_ key: LeafDayKey) -> String {
        if let date = key.date(calendar: .current) {
            return WaxFigures.day(date)
        }
        return "—"
    }
}
