# [P2] AppShell — TallyTabBar (3 tabs + center FAB) + TallyNavHeader

> Depends on: #1, #2 · Blocks: 006-012 · Branch: `issue/005-app-shell` · Effort: M

## Why
The shell sets the visual frame for every screen. The custom tab bar with center FAB is the camera-shutter feel that defines the brand.

## Do
1. **`TallyTabBar`** — `Tally/Features/AppShell/TallyTabBar.swift`:
   - 3 tabs: `今日` (home) / `账本` (stats) / `我` (profile)
   - Layout: `HStack` with widths `1fr 1fr 84pt 1fr` — FAB in column 3 with `.offset(y: -12)`
   - Active tab: 4×4 cinnabar dot above icon, label weight 600
   - Inactive label color: `tallyInkFaint`
   - 0.5pt top divider via `tallyLineHi`, 24pt inset on both ends
   - Top mask: `LinearGradient` from `tallyBg` to `tallyBg.opacity(0)` over the top 8pt
   - Total height 104pt with 28pt bottom safe inset

2. **`TallyFAB`** — `Tally/Features/AppShell/TallyFAB.swift`:
   - 68pt circle, `tallyAccent` fill
   - `TallyMark(variant: .one, size: 26, color: .tallyAccentInk, strokeWidth: 3.2)` glyph
   - Shadows: `tallyShadowFab` + inset top white-ish + inset bottom black-ish for tactile depth
   - Halo ring: 1pt border at inset `-6` of accent at 32% opacity
   - Press handler: scale `0.96` on press, spring back to `1` on release (`tallySpring`)

3. **`TallyNavHeader`** — `Tally/Core/UIComponents/Tally/TallyNavHeader.swift`:
   - Params: `title: String`, `onBack: (() -> Void)?`, `trailing: AnyView? = nil`, `eyebrow: String? = nil`
   - Back button: 36pt circle, chevron-left, `tallySurface2` bg
   - Centered title (size 17, weight 600)
   - Optional eyebrow above title (size 10, letterSpacing 0.12em, uppercase, faint)
   - Min height 48pt, padding `(8, 20, 12, 20)`

4. Rewrite the existing tab scaffold:
   - Open `Tally/Features/AppShell/JOTabScaffold.swift` (or whatever the existing file is named — verify via `git grep TabScaffold`)
   - Replace its tab bar + FAB invocation with `TallyTabBar` + `TallyFAB`
   - Keep `tabBarVisibility` environment value behavior unchanged (sub-screens still hide it)
   - FAB tap calls the existing QuickEntry presentation (placeholder until #7 rebuilds the sheet)

5. Keep `UITabBar.appearance().isHidden = true` in `TallyApp.init()` (already present).

## Design
- `design/shell.jsx:53-130` (tab bar + FAB)
- `design/shell.jsx:158-181` (NavHeader)
- `design/screenshots/01-home.png`, `03-home.png` (FAB visual confirmation)

## Files
**Create**:
- `Tally/Features/AppShell/TallyTabBar.swift`
- `Tally/Features/AppShell/TallyFAB.swift`
- `Tally/Core/UIComponents/Tally/TallyNavHeader.swift`

**Modify**:
- `Tally/Features/AppShell/JOTabScaffold.swift` (or equivalent — keep the file name for now, just swap internals)

## Done when
- [ ] Tab bar at iPhone 17 size matches `01-home.png` visually
- [ ] FAB press-and-release plays the spring scale animation
- [ ] Tapping the FAB opens the existing QuickEntry sheet (placeholder transitions are fine)
- [ ] Switching tabs animates the active dot
- [ ] Deep links `tally://home`, `tally://statistics`, `tally://quickEntry` still route correctly (run `DeepLinkAndTimePolicyTests` — must pass)
- [ ] `xcodebuild build` and `xcodebuild test -scheme TallyTests` both pass

## Don't
- Don't touch `DeepLinkRouter`.
- Don't change which tab maps to which screen.
- Don't add new tabs.
- Don't delete `JO*` components (#15 cleans them up).

## Notes
- The existing `JOFloatingAddButton` and `JOTabBar` files stay in the repo; just stop using them in `JOTabScaffold`. Their previews still compile.
- iOS 26 `TabView` has new placement APIs — feel free to use them if cleaner, but keep the FAB's exact visual spec (cinnabar + halo + lifted -12pt).
