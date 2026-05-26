# [P3] Statistics (BillsList) screen rebuild

> Depends on: #1-#5 · Branch: `issue/008-statistics-screen` · Effort: M

## Why
Second-most-used screen. Range bar + summary + 30-day sparkline + category ranking + dense bill list. Sparkline ONLY for trend — no pie charts, no bar charts.

## Do
1. Rewrite `Tally/Features/BillsList/BillsListView.swift` end-to-end. Keep `BillsListViewModel`'s public API; add `trend30Cents: [Int]` and `categoryRanking: [Ranking]` computed properties if missing.

2. **Title row** (per `design/screens-home.jsx:193-207`):
   - Left: Eyebrow "账本" + large title "2026 · X 月" (size 28, weight 600)
   - Right: 36pt search button (placeholder action)

3. **Range bar**: `Segmented` with options 周 / 月 / 季 / 年 / 自定. Size `.sm`. Active = `tallyAccent` bg.

4. **Summary card** (per `design/screens-home.jsx:236-256`):
   - `tallySurface` bg, 18pt radius, 0.5pt line, 20pt padding
   - 2-column grid: 支出 / 收入 with `TallyAmountText` size 24, weight 500
   - 0.5pt divider
   - 结余 row: label left, `TallyAmountText` size 22, weight 600, `tallyAccent` (income-style sign)

5. **30-day sparkline card** (per `design/screens-home.jsx:272-292`):
   - `tallySurface` bg, 18pt radius, 16pt vertical padding, 20pt horizontal
   - Eyebrow "30 日支出" + peak label `峰值 X/Y ¥Z` on the right
   - `Sparkline(data: trend30, fill: true, dot: true, baseline: true, height: 72)`
   - Axis labels: 5/1, 5/15, 5/30 (or equivalents based on range)

6. **Category ranking** (per `design/screens-home.jsx:295-332`):
   - Eyebrow "分类排名" + "共 N 项 · 看全部" on right
   - List up to 6 rows, each:
     - 28pt `CategoryTile`
     - Category name + count badge ("· 22")
     - `TallyAmountText` (no decimals — `¥%d`) on right
     - 3pt progress bar in category color, width = `amount / max * 100%`, `tallyEmph` animated

7. **Dense bills list**: reuse `BillsList(groups:dense: true)` from #6. Section title "明细" above.

8. Bottom padding 120pt to clear FAB.

## Design
- `design/screens-home.jsx:182-332`

## Files
**Modify**:
- `Tally/Features/BillsList/BillsListView.swift`
- `Tally/Features/BillsList/BillsListLayout.swift`
- `Tally/Features/BillsList/BillsListViewModel.swift` (add computed properties; don't break API)
- `Tally/Features/BillsList/BillsListViewModel+Models.swift`
- `Tally/Features/BillsList/Components/*` and `Views/*` — most subviews will be replaced

## Done when
- [ ] All 5 range options render summary + sparkline + ranking that update accordingly
- [ ] Category ranking bars use category color (not all cinnabar)
- [ ] Custom range opens a date picker (placeholder OK)
- [ ] `xcodebuild build` and tests pass

## Don't
- Don't add a real chart library (no Charts framework usage for this screen — Sparkline is built in #2).
- Don't change the time-range filtering logic in `BillsListViewModel`.
- Don't add export buttons here — Import/Export lives in #12's screen.

## Notes
- For "custom" range, the date picker is out of scope; placeholder button is acceptable.
- Trend30 data: cents per day for last 30 days (or selected range mapped to days). For "year" range, use months (12 points). For "quarter", use weeks (13 points). Whatever the range, sparkline `data.count` should be sensible (10-30 points typical).
- Category ranking: aggregate per-category totals for the active range, sort desc by amount, take top 6.
