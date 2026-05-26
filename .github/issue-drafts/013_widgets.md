# [P4] Widget redesign — Small (Quick Entry) + Medium (Summary Trend)

> Depends on: #1, #2, #3 · Branch: `issue/013-widgets` · Effort: M

## Why
Widgets are first-class entry points to the app. Rebuild to match the new brand.

## Do
1. **`QuickEntryWidget` (Small, 158×158)** — rewrite `TallyWidgets/QuickEntryWidget.swift` + `TallyWidgets/WidgetViews/QuickEntryWidgetView.swift`:
   - Top row: `TallyMark(variant: .one, size: 16, color: .tallyAccent, strokeWidth: 2.2)` left, "今日" eyebrow right
   - Middle:
     - Today's expense as `TallyAmountText(cents: model.todayExpenseCents, size: 26, weight: .semibold)`
     - Sub: "4 笔 · 较昨日 ↓ X%" (sub-line; if no yesterday data, omit the comparison)
   - Bottom: pill button "记一笔" (cinnabar bg, `tallyAccentInk` text, `TallyMark .one` icon), size 12 weight 600
   - `.widgetURL(URL(string: "tally://quickEntry"))`
   - Container: `tallySurface` bg, 24pt radius (system handles), `tallyShadow2`

2. **`SummaryTrendWidget` (Medium, 338×158)** — rewrite `TallyWidgets/SummaryTrendWidget.swift` + view:
   - 2-column layout split by 0.5pt vertical divider:
     - **Left half** (flex 1.1):
       - Top: `TallyMark(variant: .five, size: 14)` + "X 月" eyebrow
       - Mid: "支出" eyebrow + `TallyAmountText` size 22 weight 600
       - Bottom row: 收入 + 结余 mini cells (size 11)
     - **Right half** (flex 1):
       - Top: Eyebrow "近 7 日" + avg `¥X` on right (size 9)
       - Mid: `Sparkline(data: model.trend7, height: 56, fill: true, dot: true, baseline: true)`
       - Bottom: "周一" / "今" labels
   - `.widgetURL(URL(string: "tally://home"))`

3. Both widgets must compile against the existing `WidgetSnapshotService` data shape (`QuickEntryWidgetModel`, `SummaryTrendWidgetModel`, `WidgetSnapshot`).
   - If `trend7` doesn't include yesterday/today comparison, add `todayCents` / `yesterdayCents` to `QuickEntryWidgetModel` (small schema bump). Update `WidgetSnapshotService` accordingly. Test that JSON encode/decode roundtrips.

4. **Color tokens in widgets**: widgets are a separate target. `Color("name")` from xcassets should work as long as the colorsets are also included in the `TallyWidgetsExtension` target's asset catalog membership. Verify membership via Xcode project file; if not, add `Tally/Assets.xcassets/Tokens/*` to both target memberships.

## Design
- `design/screens-others.jsx:467-565`

## Files
**Modify**:
- `TallyWidgets/QuickEntryWidget.swift`
- `TallyWidgets/SummaryTrendWidget.swift`
- `TallyWidgets/WidgetViews/QuickEntryWidgetView.swift`
- `TallyWidgets/WidgetViews/SummaryTrendWidgetView.swift`
- `TallyWidgets/WidgetViews/WidgetTheme.swift` (update to bridge to Tally tokens)
- `Shared/WidgetSupport/WidgetDataStore.swift` (only if `QuickEntryWidgetModel` needs new fields — add but keep backward compat)
- `Tally/Services/WidgetSnapshotService.swift` (compute new fields if added)

## Done when
- [ ] Both widgets render in Widget gallery on simulator (run app → long-press home → add widget)
- [ ] Tapping Small routes to `tally://quickEntry`
- [ ] Tapping Medium routes to `tally://home`
- [ ] Snapshot refreshes on `.billDidChange` (existing mechanism preserved)
- [ ] `xcodebuild build` passes for both `Tally` and `TallyWidgetsExtension`

## Don't
- Don't add a Large widget variant — out of scope.
- Don't add interactive buttons (iOS 17+ AppIntent buttons) — out of scope.
- Don't add Lock Screen widgets — out of scope.

## Notes
- Widgets render at a small physical size — readability over decoration. Eyebrow labels should be at most 11pt; values 22-26pt.
- For shadow tokens in widgets: SwiftUI widget rendering ignores most native shadows. Use a subtle border + bg contrast instead.
- The `WidgetSnapshot` JSON format change (if you add fields) requires safe defaults so older app versions writing the old format don't crash the widget reading the new format.
