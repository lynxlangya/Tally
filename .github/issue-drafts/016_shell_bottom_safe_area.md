# [Bug] TallyTabBar floats above physical bottom edge — kill the bottom safe-area gap

> Depends on: #5 (AppShell must already be in main) · Branch: `issue/016-shell-bottom-safe-area` · Effort: S

## Why

On iPhone 17 simulator (iOS 26.5, Light/Parchment theme), the `TallyTabBar` is currently positioned above the bottom safe-area inset instead of being glued to the physical bottom edge. Visible symptoms on every main screen (Home / Statistics / Profile):

1. There is empty `tallyBg` space between the tab bar's bottom edge and the physical bottom of the device
2. Underlying scroll content (e.g. the last row "每日提醒" on the Profile screen) bleeds through above the tab bar with no clean visual cut
3. The cinnabar FAB sits visually mid-screen instead of sitting near the bottom edge as in the design reference

The design (`design/shell.jsx:64-83`) intends the tab bar container to be glued to the physical bottom (`position: absolute; bottom: 0`) with a 28pt internal `paddingBottom` that reserves room for the iOS home indicator. **Background must extend to the physical bottom**; interactive content (tabs + FAB) sits within the 76pt upper region of the bar.

## Visual reference

- Design source: `design/shell.jsx:64-83` (TabBar container)
- Design screenshot (correct behavior, dark theme): `design/screenshots/01-home.png`, `03-home.png` — tab bar is flush with bottom; cinnabar bg gradient reaches the physical edge
- Current bug reproduction: open the app on iPhone 17 simulator, switch to Profile tab, scroll to the bottom of the settings list — observe the empty band below the tab bar and the bleed-through of preceding rows

## Do

1. Locate the current tab bar host. Likely files:
   - `Tally/Features/AppShell/TallyTabBar.swift`
   - `Tally/Features/AppShell/JOTabScaffold.swift` (or whatever the renamed shell container is — `git grep TabScaffold`)
   - Possibly the root `ContentView.swift` or `AppRootView.swift` if the tab bar is mounted there

2. Diagnose root cause. Likely one of:
   - The tab bar is mounted via `.safeAreaInset(edge: .bottom) { TallyTabBar(...) }` — the system auto-adds the home indicator inset on top of the tab bar's own padding
   - The tab bar's parent container has `.padding(.bottom, geometry.safeAreaInsets.bottom)` or equivalent
   - The root view declares `.ignoresSafeArea(.bottom)` but the tab bar is wrapped in a child that re-imposes safe area

3. Apply ONE of these fixes (pick the cleanest):

   **Option A — preferred** (background breaks out, content stays put):
   ```swift
   // Inside TallyTabBar
   var body: some View {
       HStack { /* tabs + FAB */ }
           .padding(.top, 8)
           .padding(.bottom, 28)     // reserve home indicator zone
           .frame(height: 104)
           .background(
               LinearGradient(/* tallyBg → transparent */)
                   .ignoresSafeArea(edges: .bottom)  // background only
           )
   }
   ```

   **Option B** (whole tab bar breaks out):
   ```swift
   ZStack(alignment: .bottom) {
       contentView
       TallyTabBar(...)
           .ignoresSafeArea(edges: .bottom)
   }
   ```

   **Option C** (kill the `.safeAreaInset` modifier and use overlay):
   ```swift
   contentView
       .overlay(alignment: .bottom) {
           TallyTabBar(...).ignoresSafeArea(edges: .bottom)
       }
   ```

4. Verify the 28pt internal `paddingBottom` stays — that's the home indicator clearance. Removing it would put the FAB / tab labels on top of the home indicator.

5. Verify the `tallyBg` → `tallyBg.opacity(0)` gradient mask at the top of the tab bar (per `design/shell.jsx:67`) still works after the fix.

## Files

**Modify** (verify before editing):
- `Tally/Features/AppShell/TallyTabBar.swift`
- `Tally/Features/AppShell/JOTabScaffold.swift` (or current renamed shell container)
- Possibly `Tally/ContentView.swift` if the tab bar is mounted there

**Don't touch**:
- `Tally/Features/AppShell/TallyFAB.swift` (FAB's `-12` lift stays)
- Any other screen view (Home / Stats / Profile / etc.)
- DeepLinkRouter
- `UITabBar.appearance().isHidden = true` in `TallyApp.init()` (keep)

## Done when

- [ ] On iPhone 17 simulator (both Light + Dark mode), the tab bar background extends to the physical bottom edge of the device — no `tallyBg` gap below
- [ ] No content from screens bleeds visibly above the tab bar (the gradient mask handles the cut cleanly)
- [ ] FAB stays at its current vertical position relative to the tab labels (still lifted -12pt above the row)
- [ ] Home indicator does NOT overlap any interactive element (tabs / FAB / labels)
- [ ] Sheet presentations (QuickEntry, CategoryPicker, etc.) are unaffected — their own bottom CTAs still respect safe area
- [ ] `xcodebuild -project Tally.xcodeproj -scheme Tally -destination 'platform=iOS Simulator,name=iPhone 17' build` passes
- [ ] `xcodebuild -project Tally.xcodeproj -scheme TallyTests -destination 'platform=iOS Simulator,name=iPhone 17' test` passes
- [ ] PR body includes before/after screenshots on the **Profile** screen (Light mode), since that's where the bug is most visible

## Don't

- Don't remove the 28pt internal `paddingBottom` from the tab bar — it's the home indicator clearance.
- Don't add `.ignoresSafeArea(edges: .bottom)` to ScrollView content inside Home / Stats / Profile — that would push their content under the tab bar without the gradient mask, creating a different visual bug.
- Don't change the FAB's `-12pt` lift, halo ring, or shadow.
- Don't change tab labels, icons, or the active-dot indicator.
- Don't change the gradient mask at the top of the tab bar (`tallyBg` → transparent over 8pt).
- Don't introduce GeometryReader at the root view just to read safe area insets — the SwiftUI `.ignoresSafeArea` modifier is the right tool here.

## Notes

- iOS 26's `TabView` has new placement APIs that may simplify the fix. If a clean rewrite using the native TabView with `.tabViewStyle(.sidebarAdaptable)` or similar works AND preserves the exact visual spec (cinnabar FAB with halo, -12pt lift, custom tab labels, active dot), it's acceptable. Otherwise, the custom `ZStack` / `.overlay` approach is fine.
- This bug surfaced after #5 (AppShell) was merged. Treat it as a polish-pass follow-up, not a Phase 2 rework.
- PR title: `fix(shell): drop TallyTabBar to physical bottom edge`
- Commit messages: `fix(shell): ...`
