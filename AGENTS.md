# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

Tally 是一个 iOS / iPadOS 单币种（CNY）记账 App，SwiftUI + Core Data + WidgetKit。Xcode 26.5、iOS deployment target 26.2、Swift 5.0。Bundle ID `com.langya.Tally`，App Group `group.com.langya.Tally`，URL Scheme `tally://`。设置页可切换 `¥` / `$` 金额显示符号，但不改变业务币种 CNY。中文沟通（review 文档、任务、注释均为中文）。

## 常用命令

构建 / 运行（默认走 `Tally` scheme + iPhone 17 模拟器；其他可用机型见 `xcrun simctl list devices available iPhone`）：

```bash
xcodebuild -project Tally.xcodeproj -scheme Tally \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

跑全量测试（`TallyTests` 是单元测试 target，host 在 `Tally.app` 上；`TallyTests.xcscheme` 是测试入口）：

```bash
xcodebuild -project Tally.xcodeproj -scheme TallyTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

跑单个测试 / 单个类（`-only-testing:TallyTests/<Class>/<method>`）：

```bash
xcodebuild -project Tally.xcodeproj -scheme TallyTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' test \
  -only-testing:TallyTests/HomeViewModelTests/testDeleteBillRemovesItemFromGroupsAndRepository
```

没有 SwiftLint / SwiftFormat 配置，依赖纯 Xcode 工具链；不要引入额外脚手架。

## 架构（必读，强约束）

完整规则在 [Tally/Core/ArchitectureRules.md](Tally/Core/ArchitectureRules.md)，依赖方向：**Features → Services → Repositories → Data**，Core 横切但不反向依赖任何层。

- `Tally/App/` — 入口。`TallyApp` 启动时跑 `RecurringService.runCatchUp(maxDays: 60)` 补齐定时账单 + `WidgetSnapshotService.refresh` 刷新 widget。`AppEnvironment.live` / `.preview` 通过 EnvironmentValues 注入 `DIContainer`，`DIContainer` 集中创建 `Repositories`（CoreData 实现）与 `Services`（含 Stub 与真实实现）。Feature/VM 不能直接 `init` 任何 repo / service。
- `Tally/Features/` — SwiftUI View + `@MainActor` ObservableObject ViewModel，每个子目录是一块业务（Home / QuickEntry / BillsList / Categories / Recurring / Settings / Profile / Debug / AppShell）。**禁止** 在该层出现 `NSManagedObjectContext` / `NSFetchRequest` / `PersistenceController` / `import CoreData`，目前已干净，新增代码不要打破。
- `Tally/Services/` — 业务编排协议 + Stub + 真实实现（`DefaultRecurringService`、`DefaultImportExportService`、`StubExportService`、`StubSecurityService`、`CoreDataSeedService`）。`WidgetSnapshotService` 是个静态 enum，不走 DI。
- `Tally/Data/` — `PersistenceController`（懒加载 `Tally.xcdatamodeld`，store URL 在 `NSPersistentContainer.defaultDirectoryURL()/Tally.sqlite`，开 `FileProtectionType.complete`，自动迁移），`CoreDataBillRepository` 等 4 个真实仓库 + `CoreDataImportWriteRepository`（导入专用写入路径）+ `MockRepositories`（Preview / Debug / 测试用）+ `BillRecordMapper`。所有真实实现走 `context.performAndWaitThrowing { ... }`。
- `Tally/Core/` — 横切代码：`Domain/`（`BillType` `BillDraft` `BillRecord` `CategoryRecord` `RecurringTaskRecord` + `SystemCategories` 中的"未分类" ID），`Utilities/`，`Theme/`（Tally token + Legacy 兼容主题），`UIComponents/`（`Tally/` 组件与 `Legacy*` 兼容组件），`DeepLink/DeepLinkRouter`，`Recurring/RecurringScheduler`+`RepeatRule`，`Services/ReminderNotificationManager`。

完整组件依赖图在 [Architecture.mmd](Architecture.mmd)（mermaid 源）和 `Architecture.png`。

## 关键口径（写代码前对齐）

- **金额**：唯一业务类型是 `Money(cents: Int)`，**不允许负数**（构造时 precondition），业务币种固定为 CNY。展示统一走 `MoneyFormatter`；金额显示符号由 `MoneyDisplaySymbolStore` 读取设置页的 `¥` / `$` 偏好，只影响 UI 文案，不代表多币种。UI 上不要 `String(format:)` 自己拼，也不要直接用系统 currency formatter 重新引入 `CN¥`。
- **时间**：写入账单时必须用 `TimePolicy.snapshot(for: localDate)` 同时落 4 个字段——`occurredAtUTC` / `tzId` / `tzOffset` / `occurredLocalDate`。**分组、筛选、月度汇总一律以 `occurredLocalDate` 为准**（避免跨时区漂移），展示时间走 `tzId` + `tzOffset` 还原。`DayKeyFormatter`（`yyyy-MM-dd`，`en_US_POSIX`，每个时区缓存一个 `DateFormatter` 在 Thread dictionary）是唯一日期 key 生成入口。
- **枚举**：`BillType` / `ExportFormat` / `ThemeMode` 用 raw string，禁止散字符串魔法值。
- **"未分类"系统分类**：UUID 写死在 `SystemCategories`，`isSystem=true`，删除自定义分类时 `CategoryRepository.delete(id:migrateTo:)` 把账单迁过去；不要让它被 UI 删掉。
- **删除策略（本轮发布锁定）**：UI 走永久删除——`BillRepository.delete(id:)` / `TrashRepository.deleteForever(id:)`。`softDelete` / `restore` / `purgeExpired` 协议方法保留但本轮不接 UI，不要新增回收站入口（来源：[Tasks/21_Release_risk_cleanup.md](Tasks/21_Release_risk_cleanup.md)）。
- **数据刷新通信**：写操作（新建 / 编辑 / 删除 / 导入 / 定时补齐）完成后发 `NotificationCenter.default.post(name: .billDidChange, object: nil)`（见 `Core/Utilities/AppEvents.swift`），Home / BillsList / Widget 监听这个通知再各自 reload。Widget 走 `WidgetSnapshotService.refresh(using:)` 写共享 App Group + `WidgetCenter.reloadTimelines`。
- **Deep Link**：scheme `tally://`，已知路由 `quickEntry` / `home` / `statistics`（`DeepLinkRouter`）。
- **定时账单**：`DefaultRecurringService.runCatchUp(maxDays:)` 在启动 / 回到前台时跑，按 `RepeatRule`（daily / weeklyMonday / weeklySunday / monthlyFirst / monthlyLast）从 `nextFireDate` 推进到 `now`，写 `BillDraft(isFromRecurring: true)`，落库前用 `detectDuplicate` 防同标的同金额同时间双写。

## Widget

`TallyWidgets` 是 WidgetKit extension，包含 `QuickEntryWidget`（点击通过 `tally://quickEntry` 拉起记账）与 `SummaryTrendWidget`（月度收支 + 7 日 sparkline）。数据由 App 进程通过 [Shared/WidgetSupport/WidgetDataStore.swift](Shared/WidgetSupport/WidgetDataStore.swift) 写入 App Group UserDefaults，Widget 进程读；快照同时携带当前金额显示符号。两者通过 `WidgetKind.quickEntry` / `WidgetKind.summaryTrend` 字符串绑定。

## 测试

XCTest + `@testable import Tally`。`InMemoryBillRepository` / `InMemoryRecurringRepository` 等测试替身在 `TallyTests/TestDoubles.swift`，**真实 CoreData 走 `PersistenceController(inMemory: true)`**（见 `CoreDataImportWriteRepositoryTests`）。`@MainActor` ViewModel 测试用 `await MainActor.run { ... }` 包一层。`HomeViewModel` / `BillsListViewModel` 等都接受 `nowProvider: () -> Date` 注入用于固化时间。

## 任务与 Review 流程（项目惯例）

- [loadmap.md](loadmap.md) 是路线图与每个任务的验收 checklist，新任务在 [Tasks/](Tasks) 下编号顺延，发布风险整改总控见 [Tasks/21_Release_risk_cleanup.md](Tasks/21_Release_risk_cleanup.md)。
- [review/](review) 下按任务编号 `<id>_review.md` 落每轮代码评审，模板在 [.gemini/skills/task-code-review/SKILL.md](.gemini/skills/task-code-review/SKILL.md)：先看架构对齐再列 P0–P3 问题、给文件:行号证据、最小修复建议，最后写"本次落地记录（YYYY-MM-DD）"+ 最小验证结果。新任务每阶段结束都要回填这两项。
- Bug 复盘在 [bugs/](bugs)，整体项目深度复盘在 [project_deep_review_20260207.md](project_deep_review_20260207.md)，发版自查在 [app_store_submission_checklist_20260207.md](app_store_submission_checklist_20260207.md)。
