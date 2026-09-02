import SwiftUI

/// Role: Shelf. Overlay stack of sealed leaves only. ReviewScreen log. No public feed.
struct ShelfView: View {
    @State var session: LeafSession
    @State private var query = ""
    @State private var favoritesOnly = false

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
            } else if visibleCards.isEmpty {
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
                Text("Past days")
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
            TextField("Search notes", text: $query)
                .wax(.body)
                .foregroundStyle(WaxFace.Palette.ink)
                .padding(.horizontal, WaxFace.space(1))
                .frame(minHeight: WaxFace.tap)
                .background(WaxFace.Palette.surface)
            Button {
                favoritesOnly.toggle()
            } label: {
                Text(favoritesOnly ? "Showing favorites" : "Show favorites")
                    .wax(.caption)
                    .foregroundStyle(WaxFace.Palette.accent)
                    .frame(minHeight: WaxFace.tap)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            monthGrid
        }
        .padding(.horizontal, WaxFace.space(2))
        .padding(.top, WaxFace.space(2))
        .padding(.bottom, WaxFace.space(2))
    }

    private var visibleCards: [ShelfCard] {
        session.shelf.filter { card in
            if favoritesOnly, !session.isFavorite(card.id) { return false }
            let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !needle.isEmpty else { return true }
            let hay = [card.alphaInk, card.betaInk, card.question ?? ""].joined(separator: " ")
            return hay.localizedCaseInsensitiveContains(needle)
        }
    }

    private var monthGrid: some View {
        let marks = session.monthMarks
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(marks) { day in
                Text(day.short)
                    .wax(.caption)
                    .foregroundStyle(day.saved ? WaxFace.Palette.background : WaxFace.Palette.ink)
                    .frame(maxWidth: .infinity, minHeight: 28)
                    .background(day.saved ? WaxFace.Palette.accent : WaxFace.Palette.surface)
                    .overlay {
                        if day.isToday {
                            Rectangle().strokeBorder(WaxFace.Palette.ink, lineWidth: 1)
                        }
                    }
                    .onTapGesture {
                        if let card = session.shelf.first(where: { $0.dayKey == day.id }) {
                            session.openDay(card)
                        }
                    }
            }
        }
        .accessibilityLabel("This month’s saved days")
    }

    private var jobLine: String {
        let count = WaxFigures.integer(session.shelf.count)
        return "\(count) saved days. Each card is both notes from that day."
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
            Text("Back to today's page")
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
            Text(session.shelf.isEmpty ? "No saved days yet." : "No days match.")
                .wax(.title)
                .foregroundStyle(WaxFace.Palette.ink)
            Text(session.shelf.isEmpty
                 ? "Write both notes on today's page, then save. Midnight will not save a half-written day."
                 : "Clear search or turn off favorites to see the rest.")
                .wax(.body)
                .foregroundStyle(WaxFace.Palette.ink)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
            Button {
                session.dismissOverlay()
            } label: {
                Text("Back to today's page")
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
            let count = max(visibleCards.count, 1)
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
                        ForEach(visibleCards) { card in
                            Button {
                                session.openDay(card)
                            } label: {
                                filedDiptych(card)
                            }
                            .buttonStyle(.plain)
                            .frame(height: leafH)
                        }
                    }
                    .padding(.horizontal, WaxFace.space(2))
                } else {
                    let fitted = (geo.size.height - bottomClear - gap * CGFloat(count - 1)) / CGFloat(count)
                    let leafH = max(WaxFace.space(14), min(fitted, WaxFace.space(24)))
                    VStack(spacing: gap) {
                        ForEach(visibleCards) { card in
                            Button {
                                session.openDay(card)
                            } label: {
                                filedDiptych(card)
                            }
                            .buttonStyle(.plain)
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
                Text(session.isFavorite(card.id) ? "Favorite" : "Open")
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
