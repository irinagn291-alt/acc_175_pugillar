# Craft

**Ship these. They are what made the real apps feel finished.**

- Home **is** the mechanic (canvas, rings, tower, wheel, matrix, dial, board, console). A tab plus a list of records is a clone.
- One persisted verb on home. Unit-test that verb. A decorative Game / Aura / Circuit / Nest / Sweep tab is filler — do not ship one.
- Every primary list has an empty state: generated art, one headline, one line, one CTA as a **full page** (`frame(maxHeight: .infinity)`). A crumb in a `Spacer` fails.
- Hit the whole chrome, not the glyph. Chrome lives **inside** the `Button` label with `.contentShape`. Min ~44pt. Rows, chips, cards, tab columns: one target.
- Onboarding Next / Continue / START is bottom, full width — not a 36pt control in the corner.
- Simulator seed only, once, behind a versioned key. Never seed on a device. Skip onboarding on Simulator after seed so home is not empty.
- Background fills the safe area (no white strips). Tab bar sits on the home indicator; lists use `contentMargins(.bottom)`.
- Contact URL on Settings (or Goals). App Review looks for it.
- Offline: if the product needs a catalog, a local shelf must catch empty/fail search. A spinner forever fails.
- Denied camera (when used) explains the state and routes to Settings. Silent no-op fails.
- Numbers go through `NumberFormatter`. Day edges use `Calendar.current.startOfDay`.
- One haptic on a successful commit, none on navigation.
- VoiceOver labels on every icon-only control. Colour is never the only signal.

**Review screenshots (21AUG App02–09)**

The running app, not `ImageRenderer`. One launch argument, three keys:

- `-ReviewScreen today` — home after onboarding (often a no-op)
- `-ReviewScreen log` — log / statement / planner
- `-ReviewScreen goals` — goals / targets / profile

Read `ProcessInfo.processInfo.arguments` **once**, **after** onboarding is done.
If onboarding is still showing, the hook never fires.

Companion (Simulator only):

- Seed one demo day behind a versioned key (`{prefix}.demo.v1`).
- Mark onboarding complete in the same seed so the hook is reachable.
- `#if targetEnvironment(simulator)`. Never seed on a device.
- Seed fills the primary surface (four slot posts from the local shelf).

Driver (outside the app): build → install on iPhone and iPad → launch with the
argument → wait until the UI settles → `xcrun simctl io <udid> screenshot`.
Name files `{App}-{today|log|goals}.png`. Pick any available simulator UDID.

**Pixels the reviewer will reject (same defects we already patched by hand).**

- Hit the whole chrome, not the glyph. Chrome lives **inside** the `Button` label with `.contentShape`. Min ~44pt. Rows, chips, cards, tab columns: one target, `buttonStyle(.plain)`.
- Empty and onboarding are full pages (`frame(maxHeight: .infinity)`), CTA at the bottom full width — not a 36pt Next in the corner or a crumb in a `Spacer`.
- Search with no query shows a shelf, not a hole. Home after onboarding has seeded demo data on Simulator.
- Seed only `#if targetEnvironment(simulator)` + a versioned key. Skip onboarding on Simulator after seed. Unique mocks per app.
- Background fills the safe area (no white strips). Tab bar sits on the home indicator; lists use `contentMargins(.bottom)`. No `.clipShape` on the whole tab bar.
- iPad is full screen, not a form-sheet iPhone frame. Portrait unless the mechanic is landscape.
- Icons have enough opaque pixels. No `layer.contents` over labels. No mushy full-screen stretch. Contrast ≥ 4.5; text ≥ 12pt; no `Font.custom(..., fixedSize:)`.
- Close dismisses. Camera denied routes to Settings. Contact URL on Settings. Home **is** the mechanic.

**Family `pair_diary`**
- Home: Diptych: two columns, one seam.
- Invariant (unit-test this): Bond days = startOfDay(now) − startOfDay(bondedAt). Milestones 7/30/90/365. Two-halves: A answers before B unlocks.
- Empty: Two halves. Write the first line.
- Fake that fails: A shared notes list or a couple chat.
- Never: No public feed.

**Desk `varroa_rate` — Hive mites**
- Home: Vertical hive stack + season ring.
- Invariant (unit-test this): mites/100 bees; sugar factor 1.15; drop-board 2.4/days; month threshold. over iff raw≥threshold.
- Fake that fails: Inspection checklist.

**From the shelf**
Gold from another family (do not copy domain, types, or texts):
- Occupath — family instrument_desk — Token-block occupation. A single-line block issues exactly one token. Painting two trains on the same interval is not a red overlay on a valid chart — the second train is refused until the holder returns the token. Tapping the conflict offers a meet that transfers the token and rewrites the later path, so the verb on home is take-or-hand-the-token, not edit-a-row. — axes architecture=DCI (Data Context Interaction), ui=SwiftUI hosting a UIView with a CATiledLayer Marey surface, naming=Railway / working-timetable lexicon
- Washfolio — family year_mood_canvas — Neighbor-bleed wash. Committing today's tone mixes it toward yesterday so consecutive days form a continuous wash; an isolated day stays pure. Analytics count wash-runs, not chips. — axes architecture=Document-View (one year document, views observe it), ui=SwiftUI hosting a UICollectionView compositional representable for the 365-cell year, naming=Almanac lexicon
