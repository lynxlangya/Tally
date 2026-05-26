# [P3] Profile screen rebuild (+ streak strip)

> Depends on: #1-#5 · Branch: `issue/011-profile` · Effort: M

## Why
Profile becomes the settings hub + a low-key identity surface. The new "streak strip" is engagement signal — NOT gamification. No badges, no levels, no "X day streak unlocked!" copy.

## Do
1. Rewrite `Tally/Features/Profile/ProfileView.swift`:

   **Identity row** (per `design/screens-others.jsx:292-310`):
   - 72pt avatar tile: rounded square radius 22, dark gradient bg, 0.5pt `tallyLineHi` border, contains `TallyMark(variant: .five, size: 32, color: .tallyAccent, strokeWidth: 2.2)`
   - Name (size 22, weight 600, letterSpacing -0.02em) — from a `UserSettings` placeholder (hardcode `Mr. 琅邪` if no auth)
   - Sub: `bill count` 笔 + `已记 N 天` (count distinct day keys in BillRepository)

   **Streak strip card** (per `design/screens-others.jsx:312-336`):
   - 16pt vertical / 18pt horizontal padding, `tallySurface` bg, 18pt radius, 0.5pt line
   - Eyebrow "本周" + "已记 X / 7 天" right-aligned
   - Row of 7 vertical bars, height proportional to that day's bill count (min 4pt, ceiling 28pt)
   - Done days: `tallyAccent`. Future / today-unrecorded: `tallyInkGhost` at 0.4 opacity.
   - Day labels: 一 二 三 四 五 六 日 (size 10, faint)

   **Settings group card** (per `design/screens-others.jsx:339-348`):
   - `tallySurface` bg + 18pt radius + 0.5pt line, single card with 0.5pt dividers between rows
   - 7 rows:
     1. 分类管理 — `cart.fill` icon, sub: 支出 N · 收入 M
     2. 定时记账 — `repeat` icon, sub: N 条已启用, chip: 下次触发日
     3. 导入与导出 — `doc.text.fill`, sub: CSV · JSON 备份
     4. 主题与外观 — `leaf.fill`, sub: 深色 · 朱砂
     5. 语言 — `book.fill`, sub: 简体中文
     6. Widget — `tram.fill`, sub: 快捷记账 · 月度趋势
     7. 关于 Tally — `doc.text.fill`, sub: vX.Y.Z
   - Each row: 32pt rounded icon tile (`tallySurface2`) + title + sub + optional chip + chevron, 14pt padding

2. Tapping a row navigates to the respective sub-screen (use `NavigationLink` or callback). Sub-screen content beyond a basic shell is out of scope here (Categories #9, Recurring #10, ImportExport #12 cover their own screens; Theme/Language/About/Widget can be placeholders).

3. **Streak computation** — add a computed property `recordedDayKeysThisWeek: Set<String>` on a new lightweight `ProfileViewModel` (if no existing VM, create one). Use `BillRepository.list(fromDayKey:toDayKey:type:)` for last 7 days.

## Design
- `design/screens-others.jsx:276-380`

## Files
**Create / Modify**:
- `Tally/Features/Profile/ProfileView.swift` (rewrite)
- `Tally/Features/Profile/ProfileViewModel.swift` (create if missing — `@MainActor final class`, accepts `BillRepository` + `CategoryRepository`)

## Done when
- [ ] All 7 rows render and tap-route to their sub-screens (placeholders OK)
- [ ] Streak strip uses real BillRepository data
- [ ] Identity row renders the TallyMark glyph on the dark avatar tile
- [ ] `xcodebuild test -scheme TallyTests` passes

## Don't
- ❌ No "X day streak" badges, no "you're on fire" copy, no haptic celebration on streak milestones
- ❌ No social / sharing / leaderboard features
- ❌ No "tip of the day" / motivational quotes
- Don't expose auth UI (auth not in scope for this refactor)

## Notes
- The streak strip is a low-key signal: just "X / 7 days recorded this week," nothing more.
- Bill count = total non-deleted bills. Day count = distinct `occurredLocalDate` values.
- For Categories sub label: derive from `CategoryRepository.count(type: .expense) + .count(type: .income)`.
- For Recurring chip: pull `recurringRepository.list().filter { $0.isEnabled }` and find earliest `nextFireDate`.
