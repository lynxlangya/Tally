# [P3] Recurring list + RecurringFormSheet

> Depends on: #1-#5 · Branch: `issue/010-recurring` · Effort: M

## Why
Recurring rules drive the "set and forget" promise. Show rule chip + next-fire prominently. Paused rows visually dim.

## Do
1. Rewrite `Tally/Features/Recurring/RecurringBillsView.swift`:
   - `TallyNavHeader(title: "定时记账", trailing: 36pt cinnabar + button)`
   - Eyebrow summary row: "已启用 N 条 · 暂停 M 条" on left, "每月固定支出 ¥X" on right (size 11, tnum)
   - List of `RecurringRow`s (gap 10pt between rows):
     - `tallySurface` bg, 18pt radius, 0.5pt line, 14pt vertical / 16pt horizontal padding
     - 40pt `CategoryTile` + name (size 15, weight 600)
     - Rule chip via `Chip(tone: .outline, size: .xs)` next to name
     - Sub-line: clock icon + `下次 X/Y 周Z` in `tallyInkFaint`
     - `TallyAmountText` on right (`+/−` based on `isIncome`)
     - Paused (`!isEnabled`): row opacity 0.55
   - Tap row → opens edit sheet (placeholder if needed)
   - Swipe-left actions: 暂停/启用 + 删除 (preserve current `RecurringBillsViewModel` semantics)

2. Rewrite `Tally/Features/Recurring/RecurringBillFormSheet.swift`:
   - 62% height `tallySheet`
   - Header: 取消 / 新建定时 (or 编辑定时) / 保存 (cinnabar weight 600)
   - Form rows (each padding 16pt vertical, 0.5pt bottom line):
     - 分类: `CategoryTile(size: 28)` + name + chevron, tap opens category picker (reuse #7's CategoryPickerSheet)
     - 金额: `TallyAmountText` size 17, weight 600. Tap opens a small numeric editor sheet (placeholder OK)
     - 重复规则: label + 4-button grid below (每日 / 每周 / 月初 / 月末), 12pt vertical / 6pt horizontal padding per button, 14pt radius, active = `tallyAccentTint` bg + cinnabar text + 0.5pt cinnabar border
     - 下次触发: read-only (computed from rule + first date)
     - 备注: optional text input

3. Map UI rule keys to existing `RepeatRule` enum values:
   - "每日" → `.daily`
   - "每周" → `.weeklyMonday` (default; or expose weekday picker as follow-up issue)
   - "月初" → `.monthlyFirst`
   - "月末" → `.monthlyLast`

4. Form behavior:
   - 保存 calls `recurringRepository.create(...)` or `.update(...)` via existing `RecurringBillFormViewModel`
   - On success, dismiss sheet and refresh the list

## Design
- `design/screens-others.jsx:139-274`

## Files
**Modify**:
- `Tally/Features/Recurring/RecurringBillsView.swift`
- `Tally/Features/Recurring/RecurringBillsViewModel.swift` (keep API)
- `Tally/Features/Recurring/RecurringBillFormSheet.swift`
- `Tally/Features/Recurring/RecurringBillFormViewModel.swift` (keep API)
- `Tally/Features/Recurring/RecurringCategoryPickerSheet.swift` — likely just style refresh, may end up redirecting to `CategoryPickerSheet` from #7

## Done when
- [ ] Enabling/disabling persists via repository
- [ ] Saving creates/updates a recurring task; `DefaultRecurringService.runCatchUp` catches it correctly (existing `DefaultRecurringServiceTests` must pass)
- [ ] Paused rows render at 0.55 opacity
- [ ] Rule chip shows correct text per `ruleText`
- [ ] `xcodebuild test -scheme TallyTests` passes

## Don't
- Don't change `RepeatRule` enum cases.
- Don't change `RecurringTaskRecord` model.
- Don't add weekly-by-specific-weekday picker — out of scope.
- Don't add "skip next occurrence" feature.

## Notes
- `ruleText` for the chip can be derived from the `RepeatRule` enum + hour/minute. Keep it short.
- 下次触发 = `nextFireDate` formatted as `M/d 周W`.
- Today's-past-time validation logic in `RecurringBillFormViewModel` must be preserved (see `RecurringBillFormViewModelTests`).
