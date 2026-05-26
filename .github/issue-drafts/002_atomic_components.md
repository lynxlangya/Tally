# [P1] Atomic components — TallyMark / Yen / TallyAmountText / Eyebrow / Chip / Segmented / CategoryTile / Sparkline / TallySheet

> Depends on: #1 · Blocks: 005-013 · Branch: `issue/002-atomic-components` · Effort: L

## Why
Every screen depends on the same set of atoms. Build them once, well, with Previews. No screen work happens until these exist.

## Do
Create the following SwiftUI views under `Tally/Core/UIComponents/Tally/`:

1. **`TallyMark`** — logo glyph
   - Params: `size: CGFloat`, `variant: Variant` (`.one` / `.five`), `color: Color = .tallyInk`, `strokeWidth: CGFloat? = nil` (default `max(2, size * 0.12)`)
   - `.one` = single vertical bar; `.five` = 4 verticals + diagonal strike (tally count of 5)
   - Reference: `design/components.jsx:9-31`

2. **`Yen`** — half-weight ¥
   - Renders as inline text at 0.62em scale of parent font, opacity 0.55, weight `.light`, baseline-lifted by 0.06em (use `.baselineOffset(-fontSize * 0.06)`)
   - Reference: `design/components.jsx:34-46`

3. **`TallyAmountText`** — formatted amount with custom ¥, tabular integer, dim small decimal
   - Params: `cents: Int`, `sign: Sign = .none`, `size: CGFloat`, `weight: Font.Weight = .medium`, `color: Color = .tallyInk`, `dim: Bool = false`, `showYen: Bool = true`
   - `Sign` enum: `.none` / `.expense` (renders `−`) / `.income` (renders `+`)
   - Renders: `[sign][¥][integer with thousands sep].[2-digit cents at 0.62×size, opacity 0.5]`
   - Negative `cents` is treated as `abs(cents)` (sign carried by `sign:` param)
   - Reference: `design/components.jsx:49-71`

4. **`Eyebrow`** — micro-label
   - Params: `_ text: String`, `color: Color = .tallyInkFaint`
   - Style: size 11, weight 600, letterSpacing 0.04em via `.tracking(...)`, uppercase via `.textCase(.uppercase)`
   - Reference: `design/components.jsx:412-420`

5. **`Chip`** — read-only pill
   - Params: `_ text: String`, `tone: Tone = .neutral`, `size: Size = .sm`, `icon: Image? = nil`
   - Tones: `.neutral` (surface2 bg + inkDim), `.accent` (accentTint bg + accent fg), `.outline` (transparent bg + lineHi border + inkDim fg)
   - Reference: `design/components.jsx:390-409`

6. **`Segmented`** — pill segmented control
   - Generic over a `Hashable` value type: `Segmented<T>(value: Binding<T>, options: [(T, String)], size: Size = .md)`
   - Active segment: cinnabar bg + accentInk fg
   - Reference: `design/components.jsx:365-387`

7. **`CategoryTile`** — colored icon tile
   - Params: `iconName: String`, `color: Color`, `size: CGFloat = 36`, `radius: CGFloat = 14`, `filled: Fill = .soft`
   - `.soft` = `color.opacity(0.22)` background + `color` icon
   - `.solid` = full `color` background + `Color.tallyAccentInk` icon + subtle inset bottom shadow
   - Icon rendering via `TallyIcon(name:)` (built in #3). Use SF Symbol fallback in this issue if #3 hasn't landed.
   - Reference: `design/components.jsx:299-313`

8. **`Sparkline`** — smooth bezier line over data points
   - Params: `data: [Double]`, `color: Color = .tallyAccent`, `fill: Bool = true`, `dot: Bool = true`, `dotIndex: Int? = nil` (defaults to last), `baseline: Bool = false`, `width: CGFloat`, `height: CGFloat`
   - Use `Path` with quadratic Bezier through midpoints (same algorithm as `design/components.jsx:327-337`)
   - Fill: linear gradient color → transparent
   - Reference: `design/components.jsx:316-362`

9. **`View.tallySheet(...)`** modifier
   - Signature: `func tallySheet<Item, Content>(item: Binding<Item?>, heightFraction: CGFloat = 0.88, @ViewBuilder content: (Item) -> Content) -> some View`
   - Internals: wraps native `.sheet(item:)`, sets `.presentationDetents([.fraction(heightFraction)])`, `.presentationCornerRadius(32)`, `.presentationBackground(.tallySurface)`, hides system drag indicator, renders a custom 36×4 handle at top of content
   - Optional convenience: `func tallySheet<Content>(isPresented: Binding<Bool>, ...)`
   - Reference: `design/components.jsx:438-465`

Every component MUST have a SwiftUI Preview showing variants in Light + Dark.

## Design
- `design/components.jsx` (entire file)
- `design/screens-entry.jsx:171-197` — `HeroAmount` shows how `TallyAmountText` flexes for the giant input display (size 52/64/84 auto)

## Files
**Create**:
- `Tally/Core/UIComponents/Tally/TallyMark.swift`
- `Tally/Core/UIComponents/Tally/Yen.swift`
- `Tally/Core/UIComponents/Tally/TallyAmountText.swift`
- `Tally/Core/UIComponents/Tally/Eyebrow.swift`
- `Tally/Core/UIComponents/Tally/Chip.swift`
- `Tally/Core/UIComponents/Tally/Segmented.swift`
- `Tally/Core/UIComponents/Tally/CategoryTile.swift`
- `Tally/Core/UIComponents/Tally/Sparkline.swift`
- `Tally/Core/UIComponents/Tally/TallySheet.swift`
- `Tally/Core/UIComponents/Tally/TallyComponentsGallery.swift` (Preview-only gallery showing all 9)

## Done when
- [ ] All 9 components compile with no warnings
- [ ] Previews render Light + Dark variants
- [ ] `TallyAmountText` renders cleanly at sizes 14 / 17 / 22 / 28 / 56 / 84 with both signs and the dim variant
- [ ] `Sparkline` handles `data.count == 2`, `count == 7`, `count == 30` without crashing
- [ ] `TallySheet` correctly presents and dismisses; handle and corner radius match design
- [ ] No existing screen yet uses these atoms (visual diff with `main` should show ONLY new files)
- [ ] `xcodebuild build` passes
- [ ] `xcodebuild test -scheme TallyTests` passes

## Don't
- Don't wire any of these into existing screens — that's the per-screen issues.
- Don't touch `JO*` components.
- Don't add new third-party dependencies.

## Notes
- `color-mix(in oklab, color 22%, transparent)` from CSS has no exact SwiftUI equivalent. `color.opacity(0.22)` over the `tallySurface` bg is the agreed approximation.
- Tabular numerals: chain `.monospacedDigit()` on `Font`.
- Yen weight 300: SF Pro `.light` (weight value 300) is correct.
- For the keypad caret blink (referenced in #7), expose `TallyAmountText` rendering helpers as `static func` so QuickEntry can compose them; not a separate "Caret" component.
- Don't use SwiftUI Charts — design wants pixel control of the sparkline.
