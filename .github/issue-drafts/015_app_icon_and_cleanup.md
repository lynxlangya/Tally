# [P5] App Icon placeholder + legacy JO* cleanup

> Depends on: #6-#14 · Branch: `issue/015-icon-and-cleanup` · Effort: S

## Why
Ship a usable App Icon now (placeholder using TallyMark) and delete dead legacy code so the codebase reflects the new design.

## Do
1. **App Icon (placeholder)**:
   - Generate a 1024×1024 PNG with: `tallyAccent` background (#C84A38) + centered `TallyMark(variant: .five)` in `tallyAccentInk` (#FBF5E8), stroke width tuned for the large size (e.g. 32-40pt at 1024×1024 viewBox proportion)
   - Save as `Tally/Assets.xcassets/AppIcon.appiconset/icon-1024.png`
   - Update `Contents.json` to point all required slots to this image (iOS 18+ requires multiple sizes; provide what's needed for build)
   - For iOS 18+ tinted/dark icon variants, you may optionally create variants — not blocking
   - Verify icon appears on simulator home screen after install

2. **Legacy `JO*` cleanup** — find and delete:
   - List all `JO*` types: `grep -rn 'struct JO\|class JO\|enum JO' Tally/ --include='*.swift'`
   - For each `JO*` type, verify NO production code references it (search `grep -rn 'JO[A-Z]' Tally/Features/ Tally/Core/UIComponents/Tally/ TallyWidgets/`)
   - Delete the file IF orphaned. If still referenced, fix the reference in the using screen (likely a missed conversion in earlier issues — open a follow-up issue instead of force-deleting).
   - Likely candidates to delete (verify before deleting): `JOTabBar.swift`, `JOFloatingAddButton.swift`, `JOListRow.swift`, `JOAmountText.swift`, `JOCard.swift`, `JOSegmentedControl.swift`, `JOBillTypeSegmentedControl.swift`, `JOSheetHandle.swift`, `JOSheetContainer.swift`, `JOHeaderBar.swift`, `JOCategoryIconTile.swift`, `JOChip.swift`, `JOIconButton.swift`, `JOSettingRow.swift`, `JOBackButton.swift`

3. **Legacy theme cleanup**:
   - Delete the OLD `Tally/Core/Theme/Colors.swift`, `Typography.swift`, `Radii.swift`, `Spacing.swift`, `Shadows.swift` IF no production code references them. Verify with grep.
   - Keep the new `TallyType.swift`, `TallySpacing.swift`, `TallyRadii.swift`, `TallyShadows.swift`, `TallyMotion.swift`, `Color+Tally.swift`.

4. **Reference cleanup**:
   - Remove the `JOTabScaffold` file name if rewriting to `TallyTabScaffold` (rename + update references)
   - Update `Architecture.mmd` to reflect new component names (replace JO* references with Tally* in the mermaid)

5. **Final verification**:
   - Run the full app on simulator. Tab through Home / QE / Stats / Profile / Settings sub-screens. Every screen must render without crash and visually match design.
   - Take a screenshot of each main screen and embed in PR description as proof.

## Files
**Modify**:
- `Tally/Assets.xcassets/AppIcon.appiconset/Contents.json` + add `icon-1024.png`
- `Architecture.mmd`

**Delete**:
- All orphaned `JO*` files under `Tally/Core/UIComponents/`
- Old theme files (`Colors.swift`, `Typography.swift`, etc.) IF unreferenced

## Done when
- [ ] App icon visible on simulator home screen after install
- [ ] `grep -rn '\bJO[A-Z]' Tally/ TallyTests/ TallyWidgets/ --include='*.swift'` returns zero matches in non-test production code
- [ ] `xcodebuild build` and `xcodebuild test -scheme TallyTests` pass
- [ ] PR description includes screenshots of Home, QuickEntry, Stats, Categories, Recurring, Profile, ImportExport

## Don't
- Don't ship a generic SF Symbol as the icon — use the TallyMark composition.
- Don't delete a `JO*` file without verifying zero production references first.
- Don't change architecture rules or repository protocols.

## Notes
- To generate the 1024×1024 icon, easiest path: create a temporary SwiftUI view with the composition, render it via `ImageRenderer`, save as PNG. Alternatively, draw in any tool (Figma / Sketch / even Preview) — only the final PNG matters.
- If any `JO*` file refuses to leave (still referenced by a screen you missed), open a `cleanup-followup` issue rather than blocking this PR.
