# Pugillar — Build Specification

> Portfolio app 56, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Ink both plates. Seal the seam.

| Field | Value |
| --- | --- |
| Product name | Pugillar |
| Bundle identifier | `com.navox.ydonosor` |
| Domain | https://navox-ydonosor.pro |
| Contact URL | https://navox-ydonosor.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Dark |
| Asset prefix | `pgl_` |
| User-Agent | `Pugillar/1.0 (iOS; +https://navox-ydonosor.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
5. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
6. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
7. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Pugillar -destination 'generic/platform=iOS' build`.
8. **Nothing may echo another app in this batch** in naming, layout or visuals.
9. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

Neither side reads until both write.

### 2.1 User flow

1. Name the two hands and set the bond date on the diptych
2. Write your half on a shuttered plate; the other plate stays unreadable
3. Pass the device; the other hand writes its half still blind
4. Seal opens the seam, files the leaf, and drops a blank leaf on the stack
5. If only one hand wrote, that leaf is still home after midnight; Bond and Shelf arrive as overlays

### 2.2 Essential behaviour

- bondDays = startOfDay(now) − startOfDay(bondedAt); milestones at 7, 30, 90 and 365
- Each plate is unreadable to the other hand until Seal
- Seal is dead until both plates have non-blank ink; a sealed leaf is immutable
- An unsealed leaf remains the home root across the day boundary
- Two-halves prompts: A answers before B unlocks
- Shelf is the stack of sealed leaves only; local, one-device, no public feed

---

## 3. Uniqueness assignment for Pugillar

| Axis | Assigned value |
| --- | --- |
| Architecture | **Blind-seam encoding (each Plate writes unseen; Seal reveals both and freezes the Leaf; a missing Plate keeps that Leaf as home)** |
| UI approach | **SwiftUI hosting a UIView pugillares hinge (two CALayer wax recesses; shutters stay down until Seal; a CATransform3D hinge then opens the seam)** |
| Naming convention | **Pugillares / wax-tablet lexicon** |
| File organization | **By plate role (Leaf, Plate, Seam, Bond, Shelf)** |
| Dependency strategy | **None (zero external dependencies)** |
| Design direction | **Wax pugillares (boxwood boards, black wax, bronze hinge, stylus, lampblack smear)** |
| Typography | **Hoefler Text** |
| Navigation pattern | **Seam-locked chrome (today's diptych never leaves; Bond, Shelf and Settings arrive as overlays)** |
| AI art style | **Late Roman ivory pugillares (carved panels, recessed wax, hinge rings)** |
| Functional twist | **Blind-seam seal (neither half is readable until both have written; seal files and freezes)** |
| Persistence | **JSON documents (one file per leaf; sealed files are immutable)** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — pair_diary

**Core** — Neither side reads until both write.

**Audience** — Couples or pairs who want one book, two hands, on one device.

**User flow**

1. Name the two hands and set the bond date on the diptych
2. Write your half on a shuttered plate; the other plate stays unreadable
3. Pass the device; the other hand writes its half still blind
4. Seal opens the seam, files the leaf, and drops a blank leaf on the stack
5. If only one hand wrote, that leaf is still home after midnight; Bond and Shelf arrive as overlays

**Essential features**

- bondDays = startOfDay(now) − startOfDay(bondedAt); milestones at 7, 30, 90 and 365
- Each plate is unreadable to the other hand until Seal
- Seal is dead until both plates have non-blank ink; a sealed leaf is immutable
- An unsealed leaf remains the home root across the day boundary
- Two-halves prompts: A answers before B unlocks
- Shelf is the stack of sealed leaves only; local, one-device, no public feed

**Twist** — Blind-seam seal. Each half of today's diptych is a shuttered plate. Typing is allowed; reading the other half is not. Seal stays dead until both plates have ink. Sealing opens the seam, writes the PairEntry, and freezes the leaf. A one-sided night does not archive — yesterday remains home. Home verb: seal-the-seam, not save-a-journal. Bond counts sealed leaves, not word counts.

**Why this is not a repeat** — pair_diary is unused in the 41-app ledger. The product is not a shared notes list, a couple chat, a year-tone canvas, or a mood pet: home is two shuttered plates whose other half cannot be read until both have written, and a one-sided day refuses to archive. That is a new home verb (seal-the-seam). Unique axes are newly coined except screens, which takes the still-free catalog slot Card stack overlays. Typography, dependencies, persistence, scanner, search_api and daykey reuse non-unique catalog values; search uses page_size 28, which is not among the occupied page sizes.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: Diptych: two columns, one seam.
- Invariant: Bond days = startOfDay(now) − startOfDay(bondedAt). Milestones 7/30/90/365. Two-halves: A answers before B unlocks.
- Never: No public feed.
- Desk `varroa_rate`: mites/100 bees; sugar factor 1.15; drop-board 2.4/days; month threshold. over iff raw≥threshold.

### 3.1 Architecture contract

The diptych is a blind-seam encoding: each Plate accepts ink while remaining unseen to the other hand, and Seal is the only reveal. A single LeafStore owns today's Leaf, both Plates, the Bond, and the Shelf; views never read a shuttered Plate and never mutate a sealed Leaf. Seal is a store method that stays dead until both Plates hold non-blank ink; a legal seal opens the seam, writes the PairEntry, freezes that Leaf, and drops a blank Leaf as the new home. If a Plate is still missing after midnight, that Leaf stays the home root — a one-sided night does not archive. Day keys are DateComponents year, month, day from Calendar.current.startOfDay. Unit-test bondDays = startOfDay(now) − startOfDay(bondedAt), milestones at 7/30/90/365, two-halves (A answers before B unlocks), the dead-seal gate, immutability after seal, and that a missing Plate keeps that Leaf as home.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

SwiftUI hosts one UIView pugillares hinge through UIViewRepresentable. Two CALayer wax recesses are the plates; shutter CALayers stay down until Seal; a CATransform3D hinge then opens the seam — not a SwiftUI split view and not two TextEditors side by side. Typing goes into the recess under the shutter; hit-testing and VoiceOver refuse the foreign plate until the seam opens, so unreadability is not colour alone. Bond, Shelf, and Settings are SwiftUI card-stack overlays over that representable. Empty and onboarding are full pages with frame(maxHeight: .infinity) and a bottom full-width CTA. Chrome lives inside Button labels with contentShape, min 44pt, buttonStyle plain. One haptic on a successful seal, none on presenting an overlay. Background fills the safe area; Shelf uses contentMargins.bottom. iPad is full screen and portrait. Wax recesses and shutters are procedural CALayer, never a generated texture stretched over labels.

### 3.3 Naming contract

Convention: Pugillares / wax-tablet lexicon.

Examples to follow: `Leaf`, `Plate`, `sealSeam(_:)`, `BondTally`

### 3.4 Dependency contract

Ship no third-party code and no vendored sources. project.yml lists no packages. The hinge UIView, Codable Leaf files, and Hoefler type scale stay inside the Pugillar target. Do not import Vision, VisionKit, or AVFoundation — the leftover still-capture barcode axis is unused. Do not call /cgi/search.pl. Foundation, SwiftUI, and UIKit only.

### 3.5 Navigation contract

Seam-locked chrome: today's diptych never leaves. There is no TabView and no pushed Detail. Bond, Shelf, and Settings arrive as card-stack overlays over the hinge. Close dismisses an overlay back to the seam. Contact URL lives on Settings. One haptic on a successful seal, none on presenting an overlay. After onboarding, read ProcessInfo.processInfo.arguments once: -ReviewScreen today stays on Diptych, log presents Shelf, goals presents Bond.

### 3.6 Screen composition contract

Card stack overlays

Physical screens: Diptych (root pugillares hinge; today's leaf never leaves; ReviewScreen today), Shelf (overlay stack of sealed leaves only; ReviewScreen log), Bond (overlay of bondDays and milestones 7/30/90/365; ReviewScreen goals), Settings (overlay; contact URL, re-run onboarding, resetAllData).

The two-halves prompt is an in-place gate on the hinge, not a destination. Onboarding is a one-shot cover that names the two hands, sets bondedAt, and writes a completion flag. Empty Diptych copy: Two halves. Write the first line. Empty Shelf is a full page, not a crumb in a Spacer. No tab bar. No public feed. No Today, Scan, Search, or Goals screens.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

---

## 4. Target file organization

Scheme: **By plate role (Leaf, Plate, Seam, Bond, Shelf)**

```
Pugillar/
  Leaf/
Plate/
Seam/
Bond/
Shelf/
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Diptych
A first-class screen for **Diptych**. Must render empty, populated and error states.

### 5.3 Bond
A first-class screen for **Bond**. Must render empty, populated and error states.

### 5.4 Shelf
A first-class screen for **Shelf**. Must render empty, populated and error states.

### 5.5 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.6 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.7 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.

---

## 6. Domain model

Minimum entities, named per this app's convention:

- **PairEntry** — named per this app's convention.
- **Prompt** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **Wax pugillares (boxwood boards, black wax, bronze hinge, stylus, lampblack smear)**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#100C08` | Screen background |
| `surface` | `#261E14` | Cards, rows, sheets |
| `ink` | `#EDE3CF` | Primary text and icons |
| `accent` | `#C08A3E` | Primary action, key figure, progress fill |
| `muted` | `#8A7B62` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **Hoefler Text**

Hoefler Text for plate ink, bondDays, and all prose, reached through one six-step accessor. HoeflerText-Italic for shuttered-plate captions; HoeflerText-Black for the seal verb. Bond counts and milestone integers go through NumberFormatter with Hoefler's old-style figures, never a raw interpolated Int. No Font.custom with fixedSize; sizes track Dynamic Type and stay at least 12pt. At the largest accessibility size, chrome labels may fall back to New York so the wax face never clips. Day edges use Calendar.current.startOfDay.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- One corner radius value applied consistently, or deliberately none if the
  design direction calls for hard edges.
- Every interactive element is at least 44x44 pt.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **JSON documents (one file per leaf; sealed files are immutable)**

JSON documents under Application Support, one Codable file per Leaf, named from DateComponents year, month, day (not an Int YYYYMMDD and not Date as a key). An unsealed Leaf is rewritten in place; after Seal the file is immutable — further encodes of that path are refused and tests prove the refuse. A missing Plate keeps that same file as the home root across the day boundary; Seal is what files it onto the Shelf, not midnight. Writes go through one LeafStore; views never touch FileManager. resetAllData() from Settings deletes the folder. Simulator seed only, once, behind pgl.demo.v1: name both hands, set bondedAt, write one sealed Leaf onto the Shelf, ink today's plates, and mark onboarding complete so the hinge is not empty. Never seed on a device.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Pugillar/1.0 (iOS; +https://navox-ydonosor.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- The app must not present itself as medical advice. It is a personal food log.
- Nutrition data is credited to Open Food Facts, a public database.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.lifestyle`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Dark
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.lifestyle
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Blind-seam seal (neither half is readable until both have written; seal files and freezes)

Home is two shuttered wax plates on one hinge; the verb is seal-the-seam, not save-a-journal. Each hand may type its own recess while the foreign plate stays unreadable — shuttered, not dimmed — until both hold non-blank ink and Seal opens the CATransform3D hinge, writes the PairEntry, freezes the Leaf, and drops a blank Leaf on the stack. A one-sided night does not archive, so that Leaf remains home after midnight. Two-halves prompts unlock B only after A has answered; Bond counts sealed leaves and days since bondedAt (milestones 7/30/90/365), never word counts; Shelf is the local sealed stack only, with no public feed. Unit-test the dead-seal gate, the missing-plate home rule, bondDays, milestones, and A-before-B; a shared notes list or a couple chat fails.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Late Roman ivory pugillares (carved panels, recessed wax, hinge rings)**

Base prompt, reused and extended for every asset:

```
Late Roman ivory pugillares, carved panels, recessed black wax, bronze hinge rings, boxwood boards, stylus, lampblack smear, museum raking light, dark ground, no text, no letters, no logo, no caption
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `pgl_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `pgl_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `pgl_Splash` | 1290x2796 | allowed | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `pgl_Onboarding1` | 1024x1536 | allowed | Onboarding page 1 illustration: what the app is for. |
| 4 | `pgl_Onboarding2` | 1024x1536 | allowed | Onboarding page 2 illustration: the main verb. |
| 5 | `pgl_Onboarding3` | 1024x1536 | allowed | Onboarding page 3 illustration: why they stay. |
| 6 | `pgl_EmptyHome` | 1024x1024 | allowed | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `pgl_EmptyList` | 1024x1024 | allowed | Empty state: a secondary list has no rows. |
| 8 | `pgl_CardBackdrop` | 1200x800 | allowed | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `pgl_ControlFace` | 512x512 | allowed | Custom control artwork used for the primary interactive element. |
| 10 | `pgl_TwistHero` | 1024x1024 | allowed | Hero art for the 'Blind-seam seal (neither half is readable until both have written; seal files and freezes)' feature screen. |
| 11 | `pgl_SuccessMark` | 512x512 | allowed | Shown briefly when the primary action succeeds. |
| 12 | `pgl_HeaderDecor` | 1200x600 | allowed | Decorative header accent on the main screen. |

### Prompt per asset

**`pgl_AppIcon`** — 1024x1024

```
Late Roman ivory pugillares closed, carved panels and bronze hinge rings, recessed black wax, centred, filling the canvas, museum raking light, no text, no letters, no rounded corners, no drop shadow, subject inside the middle 80 percent, opaque
```

**`pgl_Splash`** — 1290x2796

```
Vertical late Roman ivory pugillares on a lampblack ground, boxwood boards at the edges, quiet uncluttered centre band, bronze hinge, recessed wax, no text
```

**`pgl_Onboarding1`** — 1024x1536

```
Late Roman ivory diptych open as two columns, one bronze seam, recessed black wax empty, one glance at a pair of hands' book, museum light, no text
```

**`pgl_Onboarding2`** — 1024x1536

```
Late Roman pugillares mid-gesture: a stylus inking one shuttered wax plate while the other plate's shutter stays down, bronze hinge, lampblack smear, no text
```

**`pgl_Onboarding3`** — 1024x1536

```
The same ivory diptych after seal: hinge opened, both wax recesses readable, a sealed leaf stacked behind a fresh blank leaf, accumulated meaning, no text
```

**`pgl_EmptyHome`** — 1024x1024

```
Open ivory pugillares with two empty wax recesses and a closed bronze seam, waiting for the first line, calm and inviting, never sad, lampblack ground, no text
```

**`pgl_EmptyList`** — 1024x1024

```
Empty boxwood shelf of sealed pugillares, no leaves filed, bronze hinge rings unused, calm, no text
```

**`pgl_CardBackdrop`** — 1200x800

```
Low-contrast carved ivory grain and faint lampblack smear, quiet enough for text, no letters
```

**`pgl_ControlFace`** — 512x512

```
Square-on face of a single recessed black-wax plate with a bronze shutter lip, stylus nick, no text
```

**`pgl_TwistHero`** — 1024x1024

```
Late Roman ivory pugillares at the blind-seam: two shuttered plates, bronze hinge about to open, neither half readable yet, no text
```

**`pgl_SuccessMark`** — 512x512

```
Small bronze hinge ring locked after a seal, confirmation mark on ivory, no text
```

**`pgl_HeaderDecor`** — 1200x600

```
Wide late Roman ivory band, carved panel, recessed wax, bronze hinge rings, low contrast, no text
```


### 13.3 Asset rules

- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, background textures, and anything else that needs a guaranteed transparent region or a guaranteed seamless join are drawn in SwiftUI via `Path` or `Shape`. The image generator is not used for these elements: it guarantees neither an alpha channel nor a seamless tile.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. Never seed on a physical device. Guard with
`#if targetEnvironment(simulator)` and `pgl.demo.v1`.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as primary iconography.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.


---

## 17. Tests

Add a unit test target `PugillarTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Snapshot unit tests for every main screen named in section 3.6.
   Each of those screens must be a `*View` or `*Screen` type that constructs
   with no arguments (demo fixtures inside the view). The factory runs these
   tests on iPhone and iPad and keeps the PNGs.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Pugillar -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.

**Uniqueness**
- [ ] Architecture matches **Blind-seam encoding (each Plate writes unseen; Seal reveals both and freezes the Leaf; a missing Plate keeps that Leaf as home)** with no leakage across layers.
- [ ] UI approach matches **SwiftUI hosting a UIView pugillares hinge (two CALayer wax recesses; shutters stay down until Seal; a CATransform3D hinge then opens the seam)**.
- [ ] Navigation matches **Seam-locked chrome (today's diptych never leaves; Bond, Shelf and Settings arrive as overlays)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **Hoefler Text** and nothing else.
- [ ] Palette matches section 7.1 exactly.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Pugillar
xcodegen generate
xcodebuild -scheme Pugillar -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Pugillar -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
