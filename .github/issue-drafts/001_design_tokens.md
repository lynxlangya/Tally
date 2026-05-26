# [P1] Design tokens — Colors / Typography / Spacing / Radii / Shadows / Motion

> Depends on: — · Blocks: 002, 004, 005, 006-014 · Branch: `issue/001-design-tokens` · Effort: M

## Why
The previous theme is bound to the old design. Replace all theme primitives with the cinnabar + ink-and-paper system before any UI work.

## Do
1. **Colors** — port `design/tokens.css` lines 15-97 to SwiftUI tokens:
   - Accent: `Color.tallyAccent` / `.tallyAccentHi` / `.tallyAccentLo` / `.tallyAccentInk` / `.tallyAccentTint`
   - Surfaces: `.tallyBg` / `.tallySurface` / `.tallySurface2` / `.tallySurface3` / `.tallyLine` / `.tallyLineHi`
   - Ink: `.tallyInk` / `.tallyInkDim` / `.tallyInkFaint` / `.tallyInkGhost`
   - `.tallyScrim`
   - 12 category swatches: `.catTerracotta` / `.catPersimmon` / `.catOchre` / `.catOlive` / `.catMoss` / `.catSage` / `.catTeal` / `.catSlate` / `.catIndigo` / `.catPlum` / `.catRose` / `.catAsh`
   - Each token must have Any + Dark variants as a `.colorset` under `Tally/Assets.xcassets/Tokens/`. Use exact hex values from `design/tokens.css`.
2. **Typography** — `Tally/Core/Theme/TallyType.swift`:
   - `TallyType.display(_ size: CGFloat, weight: Font.Weight = .medium)` → SF Pro Display
   - `TallyType.body(_ size: CGFloat, weight: Font.Weight = .regular)` → SF Pro Text
   - `TallyType.num(_ size: CGFloat, weight: Font.Weight = .medium)` → display + `.monospacedDigit()`
   - Document size scale used in design: 10, 11, 12, 13, 14, 15, 17, 22, 24, 28, 32, 56, 64, 84
3. **Spacing** — `Tally/Core/Theme/TallySpacing.swift`: `s1=4, s2=8, s3=12, s4=16, s5=20, s6=24, s7=32, s8=40, s9=56` as `CGFloat` constants in an enum.
4. **Radii** — `Tally/Core/Theme/TallyRadii.swift`: `xs=6, sm=10, md=14, lg=18, xl=24, xxl=32, pill=999`.
5. **Shadows** — `Tally/Core/Theme/TallyShadows.swift`: 3 tokens (`shadow1`, `shadow2`, `shadowFab`) as ViewModifier or `View.shadow()` wrapper. Both color-scheme variants.
6. **Motion** — `Tally/Core/Theme/TallyMotion.swift`:
   - `Animation.tallyFast` = `.easeOut(duration: 0.12)`
   - `Animation.tallyBase` = `.easeOut(duration: 0.22)`
   - `Animation.tallyEmph` = `.easeOut(duration: 0.36)`
   - `Animation.tallySpring` = `.spring(response: 0.36, dampingFraction: 0.62)` (approximates `cubic-bezier(0.34, 1.56, 0.64, 1)`)

## Design
- `design/tokens.css` (whole file, especially lines 15-97)

## Files
**Create**:
- `Tally/Core/Theme/Color+Tally.swift`
- `Tally/Core/Theme/TallyType.swift`
- `Tally/Core/Theme/TallySpacing.swift`
- `Tally/Core/Theme/TallyRadii.swift`
- `Tally/Core/Theme/TallyShadows.swift`
- `Tally/Core/Theme/TallyMotion.swift`
- `Tally/Assets.xcassets/Tokens/<token>.colorset/Contents.json` — one per color token, with Any + Dark variants

**Modify**: none in this issue. Legacy `Tally/Core/Theme/Colors.swift` etc. stay; they'll be removed in #15.

## Done when
- [ ] All tokens compile and are accessible from any SwiftUI view via `Color.tally*` / `TallyType.*` / `TallySpacing.*`
- [ ] A new SwiftUI Preview file `Tally/Core/Theme/TallyTokensPreview.swift` renders all 12 category colors + all surface/ink colors in both Light + Dark (verify by toggling preview scheme)
- [ ] No hex literals introduced in view code (this issue doesn't touch view code anyway)
- [ ] `xcodebuild build` passes
- [ ] `xcodebuild test -scheme TallyTests` passes

## Don't
- Don't touch any feature view code.
- Don't delete the legacy `Colors.swift` / `Typography.swift` / `Radii.swift` / `Spacing.swift` / `Shadows.swift` — they're still referenced by `JO*` components.
- Don't add Geist or any custom font.

## Notes
- SwiftUI `Color("name")` reads from xcassets at runtime and auto-switches Light/Dark. This is the desired pattern.
- Animation timings: don't quote the cubic-bezier exactly — SwiftUI uses spring physics. The `tallySpring` approximation is close enough; verify by eye.
- Make sure each colorset's Contents.json sets `"color-space": "display-p3"` to match the design intent.
