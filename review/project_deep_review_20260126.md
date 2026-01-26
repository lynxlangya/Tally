# JustOne 项目深度 Review（2026-01-26）

## 发现问题（按严重程度）

### P1 — 性能/可扩展风险：多处“全量读取 + 主线程计算”
- **现象**：多个 ViewModel 在主线程读取全部账单并做多轮过滤/聚合，数据量增长后会明显拖慢 UI，违背“高效”目标。  
  - `JustOne/Features/Home/HomeViewModel.swift`：`load()` 每次 `billRepository.list()` → in-memory 过滤当月、分组、再排序。  
  - `JustOne/Features/BillsList/BillsListViewModel.swift`：`load()` 拉全量后构建趋势/排行/分组，多轮遍历。  
  - `JustOne/Features/QuickEntry/QuickEntryViewModel.swift`：`loadAvailableYears()` 每次全量扫描以取年份。  
  - `JustOne/Services/WidgetSnapshotService.swift`：`buildSparkline` 对每一天再遍历账单（近似 O(N * days)）。
- **风险**：账单数增长后首页/明细/快捷记账都可能出现卡顿，Widget 刷新也会变慢。  
- **建议**：  
  1) Repository 增加 **按月/按日范围查询**（直接在 CoreData 层做 predicate + sort），减少上层过滤；  
  2) 对趋势/排行使用 **预分组（DayKey → sum）**，减少重复遍历；  
  3) 在 ViewModel 中将重计算放入后台 Task，再回到主线程发布结果。

### P2 — 共享数据结构重复，存在“漂移”风险
- **现象**：`WidgetDataStore` 在 App 与 Widget 两个 target 下各有一份实现。  
  - `JustOne/Core/WidgetSupport/WidgetDataStore.swift`  
  - `JustOneWidgets/WidgetDataStore.swift`
- **风险**：后续改动容易出现逻辑不一致，导致 Widget 与 App 数据结构不匹配。  
- **建议**：将该文件移动到 `Shared/` 并勾选两个 target；或通过 Swift Package/共享文件夹统一维护。

### P2 — Formatter 热路径频繁创建
- **现象**：`DayKeyFormatter` / `MoneyFormatter` 内部每次调用都会创建 Formatter。  
  - `JustOne/Core/Utilities/DayKeyFormatter.swift`  
  - `JustOne/Core/Utilities/Money.swift`
- **风险**：列表/趋势等高频路径会增加开销。  
- **建议**：用 `static let` 缓存 DateFormatter / NumberFormatter（与现有 `BillsListViewModel` 静态 formatter 方式一致）。

### P2 — 主题系统存在“双入口、未贯通”
- **现象**：`ThemeManager` 维护 theme settings，但实际渲染依赖 `JOTheme.mode` 静态值；两者未联动。  
  - `JustOne/Core/Theme/ThemeManager.swift`  
  - `JustOne/Core/Theme/Colors.swift`
- **风险**：未来若开放换肤/模式切换，会出现 UI 不更新或状态分裂。  
- **建议**：将 `ThemeManager.settings` 驱动到 `JOTheme.mode`，并通过 Environment/ObservableObject 统一更新。

### P3 — 预置分类更新策略不完整
- **现象**：`CoreDataSeedService` 只在空库时导入全部默认分类；已有数据时仅补系统分类。  
  - `JustOne/Data/CoreDataSeedService.swift`
- **风险**：当你调整“默认 20/10 类”或图标后，已有用户不会自动补齐新预置。  
- **建议**：新增“缺失默认分类补齐”策略（仅插入未存在的 preset，保留用户自定义）。

### P3 — 缺少关键业务测试/回归点
- **现象**：目前缺少对关键口径的自动化验证（时区/occurredLocalDate、软删清理、重复规则）。  
- **风险**：后续迭代易出现隐性回归。  
- **建议**：至少补 3~5 个单元测试：  
  - TimePolicy/DayKeyFormatter 相关  
  - Trash purge 时间边界  
  - QuickEntry 金额解析/运算规则

---

## 架构与设计评估（优点）
- **分层清晰**：`Features -> Services -> Repositories -> Data -> Core` 层次完整，且 Features 未直接依赖 CoreData（符合 `ArchitectureRules.md`）。  
- **DI 与 Environment**：通过 `DIContainer` + `AppEnvironment` 注入，结构简洁、便于替换。  
- **主题/组件体系完善**：`Core/Theme` + `Core/UIComponents` 把视觉要素集中管理，符合“简洁、优雅”。  
- **数据口径正确**：账单分组依赖 `occurredLocalDate`，避免时区漂移，核心业务口径明确。  

---

## UI/组件层面的“简洁/高效/优雅”匹配度
- **简洁**：组件复用率高（`JOListRow` / `JOCard` / `JOSegmentedControl`），整体结构干净。  
- **高效**：视觉层不堆叠过多复杂层；但业务层全量计算需要优化（见 P1）。  
- **优雅**：色彩、阴影、磨砂一致性很好，注意避免过多特效叠加（WidgetPreview 是一个显眼热点）。  

---

## 建议的下一步（按优先级）
1) **引入 Repository 的“按月/按日范围查询”**，避免全量拉取。  
2) **修复 Formatter 热路径创建**（DayKey/Money 统一缓存）。  
3) **统一 WidgetDataStore** 到 Shared 文件，避免漂移。  
4) 规划 **ThemeManager ↔ JOTheme.mode** 的联动，保证未来换肤无痛接入。  
5) 增加关键业务单测，确保时区/软删/金额解析的稳定性。  

---

## 结论
当前架构整体方向正确，组件体系与视觉风格较统一，已经具备“简洁/优雅”的基础。  
最大短板在于 **数据层的全量读取与多轮内存计算**，这是影响“高效”的核心问题。  
若优先解决 P1/P2 项，整体质量会明显上一个台阶。
