# 任务 23：智能分类建议算法（CategorySuggestionService）

> 前置：任务 22（v1.1a UI 重构）已完成——键盘上方横向快捷行 + 全量 picker 已就位，
> 快捷行数据当前由 `QuickEntryViewModel.suggestedCategories`（按 `sortOrder` 取前 N + 保证选中可见）驱动。
> 本任务 = 任务 22 路线图里的 **v1.1b**：用真实打分算法替换 `suggestedCategories` 的排序来源。
> 执行者：codex（独立开发）。本文档提供全部精确接口，不依赖额外对话上下文。

---

## 0. 一句话目标

新增 `CategorySuggestionService`（Services 层，纯函数打分 + DI 注入），根据用户**自己的历史账单**（时段切片 + 近因衰减 + 全局频率）对分类排序，喂给快速记账的横向快捷行；并点亮全量 picker 的「常用」区。**本任务只做排序，不做预选**（预选 + 置信门槛是后续 v1.2，见 §9）。

## 1. 为什么这么设计（约束来源，勿改动方向）

- **时段是「特征」不是「规则」**：不写死「18 点→晚餐」，而是用「当前小时 ±窗口」去切片**用户自己**的历史，问「这个用户此刻最常记什么」。不吃早餐的人早上自然不会被推早餐。
- **排序优先于预选**：排序错了用户也只需一眼一点，容错高；预选错了要走「点 chip→找→选」。故本任务先做排序，预选留到 v1.2。
- **冷启动用 last-used 兜底**：历史不足时不硬猜，退回任务 22 已实现的 `LastUsedCategoryStore`，再不行不预选。
- **全量区固定 sortOrder**：picker 的「全部」区永远按 `sortOrder`，只有「常用」区动态——守住空间肌肉记忆。

## 2. 架构落点（强约束，违反即返工）

依赖方向 **Features → Services → Repositories → Data**（见 `Tally/Core/ArchitectureRules.md`）。

- 新文件 `Tally/Services/CategorySuggestionService.swift`：`protocol` + `DefaultCategorySuggestionService`（struct）+ `StubCategorySuggestionService`（桩）。
- service 依赖 `BillRepository`（合法：Services → Repositories）。
- **打分核心必须是纯函数**：输入 `[BillRecord] + [CategoryRecord] + now`，输出排序后的 `[UUID]`。不碰 IO、不读 UserDefaults、可注入 `now` —— 便于固化时间单测。
- **禁止**在 Services / Features 层 `import CoreData`、出现 `NSManagedObjectContext` / `NSFetchRequest`。
- service 经 `DIContainer.Services` 注入，`QuickEntryView` 从 `@Environment(\.appEnvironment).container.services` 取，传给 `QuickEntryViewModel`。

## 3. 已确认的代码事实（codex 照此对接，不要臆测）

### 3.1 领域模型字段（`Tally/Core/Domain/Models.swift`）

```swift
struct BillRecord {
    let id: UUID
    let type: BillType            // .income / .expense
    let amount: Money             // Money(cents: Int)
    let occurredAtUTC: Date       // ⚠️ 见 §4.1 时间口径坑
    let tzId: String
    let tzOffset: Int             // secondsFromGMT
    let occurredLocalDate: String // "yyyy-MM-dd"
    let note: String?
    let categoryId: UUID?         // 可空
    let isFromRecurring: Bool     // ⚠️ 必须排除 true（定时账单不计入）
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let trashUntil: Date?
}

struct CategoryRecord {
    let id: UUID
    let type: BillType
    let name: String
    let iconKey: String
    let colorHex: Int?
    let isSystem: Bool
    let sortOrder: Int
}
```

### 3.2 仓库接口（`Tally/Data/Repositories/RepositoryProtocols.swift`）

```swift
protocol BillRepository {
    func list(fromDayKey: String, toDayKey: String, type: BillType?) throws -> [BillRecord]  // ← 90 天窗口用这个
    // ... 其余略
}
protocol CategoryRepository {
    func list(type: BillType) throws -> [CategoryRecord]
}
```

- dayKey 字符串格式 `"yyyy-MM-dd"`，用 `DayKeyFormatter.dayKey(for:timeZone:)` 生成（`Tally/Core/Utilities/DayKeyFormatter.swift`，`en_US_POSIX`）。

### 3.3 系统分类（排除「未分类」用）

`Tally/Core/Domain/SystemCategories.swift`：
```swift
SystemCategoryID.uncategorized(for: type) -> UUID   // 打分时排除这个
```

### 3.4 时间还原工具（`Tally/Core/Utilities/TimePolicy.swift`）

```swift
TimePolicy.editorDate(from: occurredAtUTC, tzId: tzId, tzOffset: tzOffset) -> Date  // 还原「记账当时本地 wall-clock」
```

### 3.5 DI 容器（`Tally/App/DIContainer.swift`）

`DIContainer.Services` 是个 struct，有 `live(...)` 与 `mock()` 两个工厂。**两个都要加新 service**：
```swift
struct Services {
    let export: ExportService
    let importExport: ImportExportService
    let recurring: RecurringService
    let security: SecurityService
    let seed: SeedService
    let categorySuggestion: CategorySuggestionService   // ← 新增
    // live(): categorySuggestion: DefaultCategorySuggestionService(billRepository: repositories.bill)
    // mock(): categorySuggestion: StubCategorySuggestionService()
}
```
> codex 注意：先读 `DIContainer.swift` 确认 `Services` 的真实字段名与两个工厂的真实构造写法，照其体例加，不要照搬上面字段假设。

### 3.6 VM 与 View 注入链

- `QuickEntryViewModel.init` 现签名（`Tally/Features/QuickEntry/QuickEntryViewModel.swift`）：
  ```swift
  init(repository: BillRepository, categoryRepository: CategoryRepository,
       editingBill: BillRecord? = nil, nowProvider: @escaping () -> Date = Date.init)
  ```
  → 加形参 `suggestionService: CategorySuggestionService`（建议给默认值 `StubCategorySuggestionService()`，避免现有测试全量改写）。
- `QuickEntryView.init`（`Tally/Features/QuickEntry/QuickEntryView.swift` 顶部 `init`，约第 14 行）也要透传该依赖到 VM。
- **3 个调用点**全部要补传 `environment.container.services.categorySuggestion`：
  - `Tally/Features/AppShell/TallyTabScaffold.swift`（约 45 行）
  - `Tally/Features/Home/HomeView.swift`（约 76 行）
  - `Tally/Features/BillsList/BillsListView.swift`（约 123 行）
  - 注意：这些 View 的 `#Preview` 里也可能有 `QuickEntryView(...)`（用 `AppEnvironment.preview.container...`），一并补全，否则 Preview / 测试目标编译断。

### 3.7 Service 体例范本（照抄结构，见 `Tally/Services/RecurringService.swift`）

```swift
protocol RecurringService { ... }
struct DefaultRecurringService: RecurringService {
    private let billRepository: BillRepository
    private let nowProvider: () -> Date
    init(billRepository: BillRepository, nowProvider: @escaping () -> Date = Date.init) { ... }
}
```

## 4. 算法规格

### 4.1 ⚠️ 时间口径坑（最易错，先读）

`TimePolicy.snapshot` 把 `occurredAtUTC` 直接存为「记账时 `.current` 时区的 Date 瞬时」（见 `TimePolicy.swift` 内 `occurredAtUTC = localDate`）。因此：

> **绝对不要** 对 `occurredAtUTC` 直接 `Calendar(.current).component(.hour, ...)` —— 跨时区记录会偏移。
> **必须** 用 `TimePolicy.editorDate(from: r.occurredAtUTC, tzId: r.tzId, tzOffset: r.tzOffset)` 还原出「记账当时的本地 Date」，再对它取 hour / weekday。

### 4.2 数据范围

- 同 `selectedType`（收/支分开）。
- 最近 **90 天**：`toDayKey = 今天`，`fromDayKey = 今天 - 90 天`（用 `DayKeyFormatter` + `Calendar`）。
- **排除** `isFromRecurring == true`。
- **排除** `categoryId == nil` 或 `== SystemCategoryID.uncategorized(for: type)`。
- 只保留 `categoryId` 仍存在于当前候选 `[CategoryRecord]` 里的（已删分类的历史不参与）。

### 4.3 打分函数（纯函数）

对每个候选分类 `c`：
```
score(c) = wTime * timeAffinity(c) + wRecency * recency(c) + wFreq * frequency(c)
```
- `frequency(c)`：90 天内该分类账单计数，按 90 天总数归一化到 [0,1]。
- `recency(c)`：对该分类每笔账单按「距今天数」做指数衰减 `exp(-days / halfLifeDays)` 求和，再对全体归一化。`halfLifeDays` 初值 **10**。
- `timeAffinity(c)`：只统计「还原后的本地小时」落在 `currentHour ± window` 内的该分类账单计数（**跨午夜环绕**：window=1.5h，即 23 点应覆盖到 0、1 点），归一化。
- 权重初值：`wTime = 0.5, wRecency = 0.3, wFreq = 0.2`。**定义成具名常量**，集中可调。v1.2 有数据后再校准。

排序规则：`score` 降序；**score 全 0 或并列时，回退按 `sortOrder` 升序**（保证确定性，避免字典无序导致排序抖动）。

### 4.4 输出与「保证选中可见」

service 输出**完整排序后的 `[UUID]`**（不截断）。「取前 N + 选中项强制可见」的逻辑**留在 `QuickEntryViewModel.suggestedCategories`**（任务 22 已实现该截断+置顶逻辑），本任务只把它的**排序来源**从 `categories`（sortOrder）换成 service 的结果。

即 VM 里大致：
```swift
// 旧：var result = Array(categories.prefix(limit))
// 新：
// let ordered = suggestionService.orderedCategoryIDs(type: selectedType, now: nowProvider(), candidates: categories)
// let orderedCategories = ordered.compactMap { id in categories.first { $0.id == id } }
// var result = Array(orderedCategories.prefix(limit))
// 「选中项不在前列则置顶」逻辑保持不变（任务 22 已有）
```

### 4.5 冷启动

service 内部有效历史不足时（如 < 10 笔）：直接返回**按 `sortOrder` 排序的候选 ID**（等价于现状），不硬猜。last-used 的兜底已由 VM 的 `defaultCategory()`（任务 22）在「预选」层承担，本任务排序层只需保证「没数据时退回 sortOrder」即可。

### 4.6 建议接口签名

```swift
protocol CategorySuggestionService {
    /// 返回按建议度排序的全部候选分类 ID（不截断）。失败 / 无数据时回退 sortOrder 顺序。
    func orderedCategoryIDs(type: BillType, now: Date, candidates: [CategoryRecord]) -> [UUID]
}
```
- `candidates` 由 VM 传入（即 VM 已加载并按 sortOrder 排好、已排除未分类的 `categories`）。service 只读历史做重排，不自己查分类表 → 减少耦合，也让纯函数更好测。
- service 内部 `try?` 包裹 repo 调用，**抛错时回退** `candidates.map(\.id)`，绝不让记账流因建议失败而崩。

## 5. 全量 picker「常用」区点亮

任务 22 把 picker 的常用区**暂时关掉了**（`QuickEntryView` 的 `.tallySheet` 调用点不传 `frequentCategories`，避免「常用=sortOrder 前缀」与「全部」开头重复）。本任务排序变成算法驱动后，常用区有了真实信息量，**重新传入**：

```swift
CategoryPickerSheet(
    categories: viewModel.categories,
    frequentCategories: viewModel.suggestedCategories,  // ← 重新接上
    selectedCategory: viewModel.selectedCategory,
    selectedType: nil,
    onSelectType: nil,
    onSelect: handleCategorySelection,
    onAddCategory: {}
)
```
`CategoryPickerSheet` 的两层渲染能力在任务 22 已实现且保留，无需再改组件。

## 6. 验收 checklist

- [ ] 新增 `CategorySuggestionService.swift`：protocol + Default 实现 + Stub。
- [ ] 打分为纯函数，`now` 可注入，无 IO / 无 CoreData import。
- [ ] 本地小时经 `TimePolicy.editorDate` 还原（非对 occurredAtUTC 直接取 hour）。
- [ ] 90 天窗口；排除 isFromRecurring / 未分类 / nil categoryId / 已删分类。
- [ ] 跨午夜窗口正确（23 点覆盖 0、1 点）。
- [ ] 权重 / halfLife / window 为具名常量。
- [ ] 排序确定性：score 并列回退 sortOrder。
- [ ] 抛错 / 冷启动回退 sortOrder，记账流不崩。
- [ ] `DIContainer` 的 Services live() + mock() 均注入新 service。
- [ ] VM + View + 3 个调用点 + 相关 Preview 注入打通。
- [ ] `QuickEntryViewModel.suggestedCategories` 排序来源换成 service；「选中置顶」逻辑不变。
- [ ] 全量 picker 重新传 `frequentCategories`。
- [ ] 单测：纯函数固定 now + 合成账单 → 期望排序（含时段切片、近因、跨午夜、冷启动回退、并列回退）。
- [ ] service 用 `InMemoryBillRepository`（`TallyTests/TestDoubles.swift`）注入历史做端到端测。
- [ ] 现有 `QuickEntryViewModelTests` 全绿（13 个）；新增建议测试全绿。
- [ ] `xcodebuild ... -scheme Tally build` 与 `-scheme TallyTests test` 均通过。

## 7. 测试构建命令（项目惯例，iPhone 17 模拟器）

```bash
# 构建
xcodebuild -project Tally.xcodeproj -scheme Tally \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# 跑建议相关测试
xcodebuild -project Tally.xcodeproj -scheme TallyTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' test \
  -only-testing:TallyTests/CategorySuggestionServiceTests \
  -only-testing:TallyTests/QuickEntryViewModelTests
```

## 8. 测试范式（照抄，见 `TallyTests/QuickEntryViewModelTests.swift`）

- `@MainActor` VM 测试用 `await MainActor.run { ... }` 包一层。
- 测试替身：`InMemoryBillRepository` / `MockCategoryRepository`（后者在 `Tally/Data/Repositories/MockRepositories.swift`，`list(type:)` 按 sortOrder 排序）。
- 固定时间：service 与 VM 都用 `now` / `nowProvider` 注入，**不要**依赖系统当前时间。
- 合成 `BillRecord` 时注意 `occurredAtUTC` 要能被 `TimePolicy.editorDate` 还原出预期小时——构造时用明确时区（参考 `QuickEntryViewModelTests.fixedDate`，timeZone 用 `Asia/Shanghai`）。

## 9. 明确不做（留给 v1.2，勿超范围）

- **预选 + margin 置信门槛**：本任务不碰 `QuickEntryViewModel.defaultCategory()` 的预选逻辑，预选仍是 last-used / 首次不预选。
- 金额量级、星期几特征：v1.3+。
- 备注 NLP：不做。
- 增量计数表 / 持久化缓存：本任务直接扫 90 天（数据量小，够用）。

## 10. 风险

- **时间口径**（§4.1）：最易错，错了时段特征整体偏移。
- **排序抖动**：字典无序 / 并列未定序会导致每次打开顺序跳变，必须用 sortOrder 兜底定序。
- **建议失败拖垮记账**：所有 repo 调用 try? 回退，绝不抛到 VM。
- **Preview / 测试编译**：漏改 mock() 或 Preview 调用点会导致 build 断，验收前务必整体编译两个 scheme。
