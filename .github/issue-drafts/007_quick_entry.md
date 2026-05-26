# [P3] QuickEntry sheet rebuild (+ CategoryPickerSheet)

> Depends on: #1-#5 · Branch: `issue/007-quick-entry` · Effort: L

## Why
The single highest-frequency surface — the "lock screen of a finance app." Every detail matters: caret blink, keypad spring, save button shadow, BillType toggle pill, nested category picker. This is THE hero screen.

## Do
1. Rewrite `Tally/Features/QuickEntry/QuickEntryView.swift` end-to-end. Keep `QuickEntryViewModel`'s public API; add `displayAmount: String` and `canSave: Bool` computed properties if missing.

2. **Header row** (per `design/screens-entry.jsx:57-66`):
   - Left: `取消` text button (size 14, `tallyInkDim`)
   - Center: `BillTypeToggle` (pill segmented control, expense/income)
   - Right: 36pt circle `+` button (placeholder action — opens "more" menu)

3. **Hero area**:
   - Tappable category chip: `CategoryTile(size: 28)` + name + chevron, pill bg `tallySurface2`, padding `(8, 16, 8, 8)`. Tap opens `CategoryPickerSheet`. Press scale 0.97 with `tallyFast`.
   - `HeroAmount` (per `design/screens-entry.jsx:171-197`):
     - Font size = 84 if integer ≤ 4 digits, 64 if ≤ 6 digits, 52 if longer (auto)
     - Renders sign at `0.5 * size`, dim opacity 0.55
     - `Yen` at `0.45` opacity, weight light
     - Integer in `.medium` weight
     - Decimal at `0.42 * size`, opacity 0.55
     - **Blinking caret**: 2pt × `0.66 * size`, `tallyAccent`, animated opacity 1 → 0.2 at 1.1s ease-in-out infinite (use `withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true))`)
   - Date pill + 备注 input below the hero amount

4. **Keypad** (per `design/screens-entry.jsx:212-264`):
   - 4×4 grid, 6pt gap, 56pt cell height, 14pt radius
   - Digits: `tallySurface2` bg, `tallyInk` fg, 22pt SF Pro
   - Action keys (backspace, calendar, minus, plus): `tallySurface` bg, `tallyInkDim` fg
   - Press transform: scale 0.94 with `tallySpring`
   - Layout:
     ```
     1  2  3  ⌫
     4  5  6  📅
     7  8  9  −
     .  0  00 +
     ```
   - `+` and `−` toggle BillType (not signed math); `📅` opens a date picker placeholder; `⌫` deletes last digit

5. **Save CTA**:
   - Full-width button, 18pt vertical padding, 24pt radius
   - Enabled state: `tallyAccent` bg + `tallyAccentInk` text + `tallyShadowFab` + `TallyMark(variant: .one)` icon
   - Disabled state (amount = 0): `tallySurface3` bg + `tallyInkFaint` text, no shadow
   - Label: `记一笔` (size 16, weight 600, letterSpacing 0.04em)
   - On tap: build `BillDraft` via current ViewModel API, call `viewModel.save()`, dismiss sheet, post `.billDidChange`

6. **`CategoryPickerSheet`** — new file `Tally/Features/QuickEntry/CategoryPickerSheet.swift`:
   - 78% height `tallySheet`
   - Header: "选择分类" title + close button (32pt circle, `tallySurface2`)
   - 4-column grid of categories filtered by current BillType:
     - 52pt `CategoryTile(filled: active ? .solid : .soft)` + name
     - Active: 1.5pt cinnabar ring at inset `-3`, name weight 600
   - "新分类" dashed tile at end → opens `CategoryEditSheet` (placeholder if #9 hasn't landed; just dismiss for now)

7. **Amount input mechanics** (preserve from `design/screens-entry.jsx:21-49`):
   - String repr supports decimals
   - Backspace removes last char; if length ≤ 1, reset to "0"
   - "." adds decimal point if none exists
   - "00" appends "00" if no decimal, or appends "0" if 1 decimal place is set, or no-ops if already 2 decimals
   - Digits replace "0" or append; respect 2-decimal max

## Design
- `design/screens-entry.jsx` (entire file)

## Files
**Modify**:
- `Tally/Features/QuickEntry/QuickEntryView.swift`
- `Tally/Features/QuickEntry/QuickEntryKeypad.swift`
- `Tally/Features/QuickEntry/QuickEntryLayout.swift`
- `Tally/Features/QuickEntry/QuickEntryViewModel.swift` (add computed props only)
- `Tally/Features/QuickEntry/QuickEntryCategoryItem.swift` (or replace with new picker)

**Create**:
- `Tally/Features/QuickEntry/CategoryPickerSheet.swift`

## Done when
- [ ] Typing digits updates the hero amount with correct sizing tier
- [ ] BillType toggle changes the sign + caret color of the hero
- [ ] Category chip tap opens picker; selecting one updates the chip and dismisses picker
- [ ] Save persists a `BillRecord` via `BillRepository.create()` (no behavior regression vs current)
- [ ] Caret blinks at ~1.1s cadence
- [ ] Keypad press shows spring scale animation
- [ ] `xcodebuild test -scheme TallyTests` passes — including any QuickEntryViewModel tests

## Don't
- Don't change `BillDraft` schema or `BillRepository.create` signature.
- Don't add receipt-photo / OCR / scan-receipt features.
- Don't auto-suggest category by ML / past behavior.
- Don't add an "amount calculator" (math operators do BillType toggle, NOT arithmetic).

## Notes
- This is THE most visually-detail-heavy issue. Spend time on the caret, keypad spring, and save-button shadow. Read `design/screens-entry.jsx:200-209` for the exact keyframe definitions of `tally-blink` and `tally-press`.
- The current code may have its own keypad implementation — replace it. Tests for amount-input logic should be preserved or rewritten to match new behavior.
- Use `.scaleEffect()` + `.animation(.tallySpring)` for keypad press. Don't use a long-running gesture; just `.onTapGesture` with scale animation.
