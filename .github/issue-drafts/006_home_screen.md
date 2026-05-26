# [P3] Home screen rebuild

> Depends on: #1-#5 · Branch: `issue/006-home-screen` · Effort: M

## Why
Home is the daily landing. 56pt hero amount + 7-day sparkline + day-grouped bills. Must match design 1:1.

## Do
1. Rewrite `Tally/Features/Home/HomeView.swift` end-to-end. Keep `HomeViewModel`'s public API unchanged — if the new layout needs derived values (e.g. `dailyAverage`, `trend7`, `monthBalance`), add computed properties to the ViewModel rather than breaking the existing surface.

2. **`HomeHeader`** (per `design/screens-home.jsx:24-83`):
   - Eyebrow row: `Eyebrow("本月 · 5 月")` + 32pt rounded calendar button (`tallySurface2` bg, line icon)
   - Hero: 56pt `TallyAmountText` with the month's expense total (sign `.none`, `tallyInk`)
   - Sub-label: `本月支出` size 12 in `tallyInkFaint`
   - 3-column stats (top-bordered with 0.5pt `tallyLine`, 18pt padding-top):
     - `收入` (sign `.income`, color `tallyInk`)
     - `结余` (sign `.income`/`.expense` based on net, color `tallyAccent`, **centered**)
     - `日均` (sign `.none`, color `tallyInkDim`, **right-aligned**)
   - 7-day spark card: `tallySurface` bg + 18pt radius + 0.5pt line + `近 7 日` eyebrow + day-name + amount label on the right + 7-point sparkline + day-labels strip below

3. **`BillsList` / `DayGroup` / `BillRow`** (per `design/screens-home.jsx:103-180`):
   - DayGroup header: date label on left, totals on right (`−¥X` for expense + optional `+¥Y` for income in cinnabar)
   - BillRow: 36pt `CategoryTile` + title (bill.note or category name, ellipsis) + subtitle (category + time) + `TallyAmountText` (signed)
   - Hover/press: `tallySurface` background, `tallyFast` transition

4. List wrapper: `paddingBottom: 120` to clear FAB + tab bar.

5. Wire to `HomeViewModel`:
   - `viewModel.summary.expenseCents` → hero
   - `viewModel.summary.incomeCents` / `.balance` / dailyAverage → stats row
   - `viewModel.groups` → day groups
   - Trend7 data: add a new computed property `viewModel.trend7Cents` that returns `[Int]` (cents per day) for the last 7 days; UI converts to `[Double]` for `Sparkline`

## Design
- `design/screens-home.jsx:7-180`
- `design/screenshots/01-home.png`, `03-home.png`

## Files
**Modify**:
- `Tally/Features/Home/HomeView.swift`
- `Tally/Features/Home/HomeViewModel.swift` — add only NEW computed properties (`trend7Cents`, `dailyAverageCents`, etc.). Don't remove existing.

## Done when
- [ ] Home matches the design screenshot at iPhone 17 size in Dark mode (visual diff acceptable within 4pt)
- [ ] Light mode renders without broken contrasts (toggle in Simulator: Settings → Developer → Appearance)
- [ ] Tapping a bill opens an edit sheet (placeholder is fine — actual edit flow is out of scope)
- [ ] Tapping the calendar button is a no-op or opens a placeholder (date picker is out of scope)
- [ ] `xcodebuild build` passes
- [ ] All tests pass, including `HomeViewModelTests`

## Don't
- Don't change `HomeViewModel`'s existing public API. Only ADD computed properties.
- Don't add full-blown charts. Sparkline only.
- Don't add motivational copy, streak counters, etc.
- Don't fetch additional data beyond what the ViewModel already provides.

## Notes
- Hero amount: when month-expense is 0, render `¥0.00` in `tallyInkDim` (a soft empty state).
- For income-only days (no expense in the group), only show the `+¥X` total on the right.
- `日均` formula: `monthExpense / daysElapsedInMonth`. Use `Calendar.current` to determine "days elapsed" (1 ≤ value ≤ daysInMonth).
- Trend7 data: cents per day for the last 7 days including today; today is the rightmost data point.
