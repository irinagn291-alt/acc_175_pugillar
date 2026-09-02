import SwiftUI

/// Role: Leaf. One-shot cover. Names the hands, stamps bondedAt, writes the completion flag.
struct OnboardingCover: View {
    var onFinish: (String, String, Date) -> Void
    @State private var page = 0
    @State private var alphaName = ""
    @State private var betaName = ""
    @State private var bondedAt = Date()

    init(onFinish: @escaping (String, String, Date) -> Void = { _, _, _ in }) {
        self.onFinish = onFinish
    }

    init() {
        self.init(onFinish: { _, _, _ in })
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                pageOne.tag(0)
                pageTwo.tag(1)
                pageThree.tag(2)
                pageFour.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxHeight: .infinity)
            bottom
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WaxFace.Palette.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var pageOne: some View {
        page(
            image: "pgl_Onboarding1",
            title: "One shared page. Two people.",
            line: "A daily note for two people who share one phone. Not a chat."
        )
    }

    private var pageTwo: some View {
        page(
            image: "pgl_Onboarding2",
            title: "Write first. Peek later.",
            line: "You write your note. They write theirs. You cannot read the other side until both are done and you save."
        )
    }

    private var pageThree: some View {
        page(
            image: "pgl_Onboarding3",
            title: "Save the day, or it stays open.",
            line: "Midnight will not save a half-written page. Together counts saved days, not word counts."
        )
    }

    private var pageFour: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WaxFace.space(2)) {
                Text("Name both people")
                    .wax(.title)
                    .foregroundStyle(WaxFace.Palette.ink)
                TextField("First person", text: $alphaName)
                    .wax(.body)
                    .foregroundStyle(WaxFace.Palette.ink)
                    .padding(WaxFace.space(1))
                    .frame(minHeight: WaxFace.tap)
                    .background(WaxFace.Palette.surface)
                    .contentShape(Rectangle())
                TextField("Second person", text: $betaName)
                    .wax(.body)
                    .foregroundStyle(WaxFace.Palette.ink)
                    .padding(WaxFace.space(1))
                    .frame(minHeight: WaxFace.tap)
                    .background(WaxFace.Palette.surface)
                    .contentShape(Rectangle())
                DatePicker("Day you started", selection: $bondedAt, displayedComponents: .date)
                    .wax(.body)
                    .foregroundStyle(WaxFace.Palette.ink)
                    .tint(WaxFace.Palette.accent)
                    .frame(minHeight: WaxFace.tap)
            }
            .padding(WaxFace.space(3))
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { WaxFace.dismissKeyboard() }
    }

    private func page(image: String, title: String, line: String) -> some View {
        VStack(spacing: WaxFace.space(2)) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 280)
                .accessibilityHidden(true)
            Text(title)
                .wax(.title)
                .foregroundStyle(WaxFace.Palette.ink)
                .multilineTextAlignment(.center)
            Text(line)
                .wax(.body)
                .foregroundStyle(WaxFace.Palette.muted)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)
        }
        .padding(WaxFace.space(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var bottom: some View {
        VStack(spacing: WaxFace.space(1)) {
            Button(action: advance) {
                Text(page == 3 ? "Start today's page" : "Continue")
                    .wax(.seal)
                    .foregroundStyle(WaxFace.Palette.background)
                    .frame(maxWidth: .infinity, minHeight: WaxFace.tap)
                    .background(WaxFace.Palette.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if page < 3 {
                Button(action: skip) {
                    Text("Use defaults")
                        .wax(.body)
                        .foregroundStyle(WaxFace.Palette.muted)
                        .frame(maxWidth: .infinity, minHeight: WaxFace.tap)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, WaxFace.space(3))
        .padding(.bottom, WaxFace.space(3))
    }

    private func advance() {
        if page < 3 {
            page += 1
        } else {
            finish()
        }
    }

    private func skip() {
        alphaName = "Alex"
        betaName = "Sam"
        bondedAt = Calendar.current.startOfDay(for: Date())
        finish()
    }

    private func finish() {
        onFinish(alphaName, betaName, bondedAt)
    }
}
