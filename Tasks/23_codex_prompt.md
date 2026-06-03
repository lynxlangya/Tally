# Codex 执行 Prompt — 任务 23：智能分类建议算法

> 用法：把下面「===PROMPT START===」到「===PROMPT END===」之间的内容整段发给 codex。
> 它已含完整指令；codex 应先读 `Tasks/23_CategorySuggestionService.md` 再动手。

===PROMPT START===

在 Tally 仓库（iOS SwiftUI + Core Data 记账 App）实现「智能分类建议算法」。完整规格在 `Tasks/23_CategorySuggestionService.md`，**先完整读它**，再读 `CLAUDE.md` / `AGENTS.md` 与 `Tally/Core/ArchitectureRules.md` 对齐架构约束。本任务是任务 22（已完成的 v1.1a UI 重构）的后续 v1.1b。

## 目标

新增 `CategorySuggestionService`，根据用户自己的历史账单（时段切片 + 近因衰减 + 全局频率）对分类排序，替换 `QuickEntryViewModel.suggestedCategories` 当前的 sortOrder 排序来源，并点亮全量 picker 的「常用」区。**只做排序，不做预选**（预选是 v1.2，本任务不碰）。

## 动手前先验证这些事实（文档 §3 给了我的核对结论，但你要亲自确认真实代码，以代码为准）

1. `DIContainer.swift` 里 `Services` struct 的真实字段与 `live`/`mock` 工厂的真实构造写法。
2. `QuickEntryViewModel.init` 与 `QuickEntryView.init` 的真实现签名。
3. `QuickEntryView(...)` 的全部调用点（grep 整库，含各 View 的 `#Preview`）——一个都不能漏，否则编译断。
4. `BillRepository.list(fromDayKey:toDayKey:type:)`、`TimePolicy.editorDate`、`DayKeyFormatter.dayKey`、`SystemCategoryID.uncategorized(for:)` 的真实签名。
5. 任务 22 已写好的 `QuickEntryViewModel.suggestedCategories` 现有实现（你要替换它的排序来源，但保留「选中项置顶 + 取前 N」逻辑）。

## 必须遵守的红线（违反即返工）

- **架构方向** Features → Services → Repositories → Data。新 service 放 `Tally/Services/`，依赖 `BillRepository`。**禁止**在 Services / Features 层 `import CoreData` / 出现 `NSManagedObjectContext` / `NSFetchRequest`。
- **打分核心是纯函数**：输入 `[BillRecord] + [CategoryRecord] + now`，输出 `[UUID]`；不碰 IO、不读 UserDefaults、`now` 可注入。
- **时间口径（最易错）**：`occurredAtUTC` 存的是「记账时本地时区的瞬时」，**绝不能**对它直接 `Calendar(.current).hour`。必须用 `TimePolicy.editorDate(from:tzId:tzOffset:)` 还原本地 Date 后再取 hour。错了整个时段特征偏移。
- **数据范围**：同 type、最近 90 天、排除 `isFromRecurring==true`、排除 nil/未分类 categoryId、排除已删分类。
- **排序确定性**：score 并列或全 0 时回退按 `sortOrder` 升序——绝不能让字典无序导致每次打开顺序抖动。
- **建议失败不能拖垮记账**：所有 repo 调用 `try?` 包裹，抛错回退 `candidates.map(\.id)`。
- **冷启动**：有效历史 < 10 笔时直接返回 sortOrder 顺序，不硬猜。

## 接口（按文档 §4.6）

```swift
protocol CategorySuggestionService {
    func orderedCategoryIDs(type: BillType, now: Date, candidates: [CategoryRecord]) -> [UUID]
}
```
权重 `wTime=0.5 / wRecency=0.3 / wFreq=0.2`、`halfLifeDays=10`、时段窗口 `±1.5h`（跨午夜环绕）全部定义为具名常量。

## 交付物

1. `Tally/Services/CategorySuggestionService.swift`：protocol + `DefaultCategorySuggestionService` + `StubCategorySuggestionService`。
2. `DIContainer` 的 Services `live()` + `mock()` 均注入。
3. `QuickEntryViewModel` 加 `suggestionService` 形参（给默认 `StubCategorySuggestionService()`），`suggestedCategories` 排序来源换成 service。
4. `QuickEntryView` 透传 + 全部调用点（含 Preview）补注入 `environment.container.services.categorySuggestion`。
5. `QuickEntryView` 的 `.tallySheet` 调用点重新传 `frequentCategories: viewModel.suggestedCategories`（任务 22 临时关掉了，现在点亮）。
6. `TallyTests/CategorySuggestionServiceTests.swift`：纯函数固定 now + 合成账单断言排序（覆盖时段切片、近因、跨午夜 23点→0/1点、冷启动回退、并列回退 sortOrder）；service 用 `InMemoryBillRepository` 端到端测。合成 `BillRecord` 参考 `QuickEntryViewModelTests.fixedDate`（用 `Asia/Shanghai` 时区，保证 `TimePolicy.editorDate` 还原出预期小时）。

## 不要做（超范围，留给 v1.2/v1.3）

- 不碰 `QuickEntryViewModel.defaultCategory()` 的预选逻辑（预选 + margin 门槛是 v1.2）。
- 不加金额/星期特征、不做备注 NLP、不做持久化计数缓存。
- 不改 `CategoryPickerSheet` 组件（两层能力任务 22 已实现，只需调用点传参）。

## 验收门槛（全绿才算完成）

```bash
xcodebuild -project Tally.xcodeproj -scheme Tally \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

xcodebuild -project Tally.xcodeproj -scheme TallyTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' test \
  -only-testing:TallyTests/CategorySuggestionServiceTests \
  -only-testing:TallyTests/QuickEntryViewModelTests
```
- 两个 scheme 均 BUILD/TEST SUCCEEDED。
- 现有 `QuickEntryViewModelTests`（13 个用例）不能挂。

## 收尾（按项目惯例）

- 在 `Tasks/23_CategorySuggestionService.md` 末尾追加「本次落地记录（YYYY-MM-DD）」：改动文件清单 + 最小验证结果（构建/测试输出）。
- 在 `review/23_review.md` 写一轮自评（模板见 `.gemini/skills/task-code-review/SKILL.md`：架构对齐 → P0–P3 问题 → 文件:行号证据 → 最小验证）。
- **直接在当前分支 `feat/quick-entry-picker` 上开发**（该分支已含任务 22 的改动，本任务在其之上叠加，不要切新分支）。
- 工作区可能有任务 22 的未提交改动——这是预期的、属于本系列前一阶段，**不要回退或清理它们**，在其基础上继续即可。
- **不要**自行合并到 main，也不要做任何发版相关操作。是否 commit 听用户指示。

===PROMPT END===
