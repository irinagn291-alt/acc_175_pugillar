import SwiftUI

/// Role: Shelf. Full saved day — read, favorite, share.
struct DayReadView: View {
    @State var session: LeafSession
    var card: ShelfCard

    var body: some View {
        VStack(alignment: .leading, spacing: WaxFace.space(2)) {
            HStack {
                Text(title)
                    .wax(.title)
                    .foregroundStyle(WaxFace.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button {
                    session.closeDay()
                } label: {
                    Text("Close")
                        .wax(.body)
                        .foregroundStyle(WaxFace.Palette.accent)
                        .frame(minWidth: WaxFace.tap, minHeight: WaxFace.tap)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            if let question = card.question, !question.isEmpty {
                Text(question)
                    .wax(.body)
                    .foregroundStyle(WaxFace.Palette.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: WaxFace.space(2)) {
                    note(session.bond?.alphaName ?? "First", card.alphaInk)
                    note(session.bond?.betaName ?? "Second", card.betaInk)
                    Text("\(WaxFigures.integer(PageMath.words(in: card.alphaInk + " " + card.betaInk))) words")
                        .wax(.caption)
                        .foregroundStyle(WaxFace.Palette.muted)
                }
            }
            HStack(spacing: WaxFace.space(1)) {
                Button {
                    session.toggleFavorite(card.id)
                } label: {
                    Text(session.isFavorite(card.id) ? "Saved in favorites" : "Add to favorites")
                        .wax(.body)
                        .foregroundStyle(WaxFace.Palette.background)
                        .frame(maxWidth: .infinity, minHeight: WaxFace.tap)
                        .background(WaxFace.Palette.accent)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Button {
                    session.shareDay(card)
                } label: {
                    Text("Share day")
                        .wax(.body)
                        .foregroundStyle(WaxFace.Palette.ink)
                        .frame(maxWidth: .infinity, minHeight: WaxFace.tap)
                        .background(WaxFace.Palette.surface)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(WaxFace.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(WaxFace.Palette.background.ignoresSafeArea())
    }

    private var title: String {
        if let sealed = card.sealedAt {
            return WaxFigures.day(sealed)
        }
        if let date = card.dayKey.date(calendar: .current) {
            return WaxFigures.day(date)
        }
        return "Saved day"
    }

    private func note(_ name: String, _ ink: String) -> some View {
        VStack(alignment: .leading, spacing: WaxFace.space(1)) {
            Text(name)
                .wax(.caption)
                .foregroundStyle(WaxFace.Palette.muted)
            Text(ink)
                .wax(.body)
                .foregroundStyle(WaxFace.Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(WaxFace.space(2))
                .background(WaxFace.Palette.surface)
        }
    }
}
