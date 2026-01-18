# JustOne 现状审计（基于代码）

## 2.1 现有架构梳理（以代码为准）

- 模块/目录结构
  - App：`JustOne/App/`，负责注入与环境封装（`AppEnvironment`、`DIContainer`）。
  - Core：`JustOne/Core/`，含 Domain/Utilities/Theme/UIComponents/PreviewKit。
  - Data：`JustOne/Data/`，CoreData 栈 + Repository 实现 + Mapper。
  - Services：`JustOne/Services/`，Export/Recurring/Security/Seed 的协议与 Stub。
  - Features：`JustOne/Features/`，Home/QuickEntry/BillsList/Categories/Profile/Settings/Debug/AppShell。
- 关键数据流
  - QuickEntry：`QuickEntryView` -> `QuickEntryViewModel` -> `BillRepository` -> `CoreDataBillRepository` -> CoreData。
  - Home：`HomeView` -> `HomeViewModel` -> `BillRepository`/`CategoryRepository` -> CoreData。
  - Categories：`CategoriesView` -> `CategoriesViewModel` -> `CategoryRepository` -> CoreData。
- 依赖与注入方式
  - `AppEnvironment` 注入 `DIContainer`，由 `JustOneApp` 提供环境；View 通过 init 传入 Repo。
  - ViewModel 依赖协议（`RepositoryProtocols.swift`），无 CoreData 直接依赖。
- 已实现关键 Feature（以代码为准）
  - Home 仪表盘 + 分组列表：`JustOne/Features/Home/`。
  - QuickEntry 记一笔/编辑：`JustOne/Features/QuickEntry/`。
  - 分类管理（网格/新增/编辑/删除迁移）：`JustOne/Features/Categories/`。
  - BillsList 统计页 UI 骨架（头部/汇总/趋势/排行/分类明细）：`JustOne/Features/BillsList/`。
  - Profile + Settings 列表：`JustOne/Features/Profile/`、`JustOne/Features/Settings/`。
  - Debug 工具页（仅 Debug）：`JustOne/Features/Debug/`。

## 2.2 架构偏离与风险（P0/P1/P2）

- P0
  - BillsList 仍在使用 Mock 数据，真实数据未接入：`JustOne/Features/BillsList/BillsListViewModel.swift`（`useMockData = true`）。
  - BillsList 未展示账单明细列表，导航入口与统计页割裂：`JustOne/Features/BillsList/BillsListView.swift`。
  - 删除仅停留在确认对话框，未调用软删逻辑，用户会误以为删除成功：`JustOne/Features/Home/HomeView.swift`。
- P1
  - BillsList 未监听 `billDidChange`，一旦接入真实数据将出现编辑后不刷新的问题：`JustOne/Features/BillsList/BillsListView.swift`。
  - 时间范围计算使用 UTC 日历，可能与用户本地周起始产生偏差：`JustOne/Features/BillsList/BillsListViewModel.swift`。
  - `TimePolicy.snapshot` 命名与行为略有歧义（`occurredAtUTC` 实际写入本地时间对象）：`JustOne/Core/Utilities/TimePolicy.swift`。
- P2
  - BillType 切换控件重复实现（QuickEntry/BillsList），样式与行为分叉：`QuickEntryView.swift`、`BillsListHeaderView.swift`。
  - UI 中存在多处“胶囊/卡片”样式重复封装不足，后续迭代可能出现不一致。

## 2.3 需要封装的组件清单（建议）

- `JOSheetHandle`
  - 场景：QuickEntry、分类明细 Sheet 顶部拖拽条。
  - 位置：`Core/UIComponents/`。
  - API：`init(width: CGFloat = 40, height: CGFloat = 6, opacity: Double = 0.3)`。
- `JOSheetContainer`
  - 场景：QuickEntry 与分类明细 Sheet 的背景/圆角/描边样式一致。
  - 位置：`Core/UIComponents/`。
  - API：`init(cornerRadius: CGFloat, background: Color, borderOpacity: Double, @ViewBuilder content: () -> Content)`。
- `BillTypeSegmentedControl`
  - 场景：支/收切换（QuickEntry/BillsList/Header）。
  - 位置：`Core/UIComponents/` 或 `Features/Shared/Components/`。
  - API：`init(selection: Binding<BillType>, size: Size = .compact)`。
- `JOHeaderBar`
  - 场景：带返回键 + 中标题的页面头（Settings/Categories/Placeholder）。
  - 位置：`Core/UIComponents/`。
  - API：`init(title: String, onBack: () -> Void, trailing: AnyView? = nil)`。
- `JOCategoryIconTile`
  - 场景：分类图标卡片在 QuickEntry 与分类页复用。
  - 位置：`Features/Shared/Components/`。
  - API：`init(icon: String, title: String, color: Color, size: CGSize, showsTitle: Bool = true)`。

## 2.4 冗余代码与可删项

- `JustOne/Core/UIComponents/JOFAB.swift`
  - 冗余原因：仅在 Preview 使用，实际功能由 `JOFloatingAddButton` 取代。
  - 建议处理：合并或删除。
- `JustOne/Features/BillsList/BillsListViewModel+MockData.swift`
  - 冗余原因：生产逻辑未接入真实数据，Mock 数据被强制启用。
  - 建议处理：移入 `#if DEBUG` 或仅用于 Preview。
- `JustOne/Features/Debug/`
  - 冗余原因：仅 Debug 功能页，发布版无入口。
  - 建议处理：标记为 debug-only 或移入独立 Target。
- `demos/`
  - 冗余原因：设计参考素材，不参与 App 运行。
  - 建议处理：保留但与代码解耦，迁移至文档资源目录。

## 2.5 MVP 边界确认（建议）

- MVP 必须有（以现状为准）
  - 记一笔（支/收）+ 编辑：已实现，`JustOne/Features/QuickEntry/`。
  - 列表分组展示：已实现于 Home，`JustOne/Features/Home/`。
  - 分类管理：已实现，`JustOne/Features/Categories/`。
  - 本地存储：已实现，`JustOne/Data/` + `JustOne/JustOne.xcdatamodeld/`。
  - 软删 + 7 天撤销 + 回收站入口：未实现，需要补齐。
  - 导出（CSV 最小可用）：未实现，需要补齐。
- MVP 暂不做（可延后）
  - iCloud 同步、无障碍/色盲适配、复杂转账/报销/借还款规则。
  - 定时记账（补跑/重复提示）、解锁密码/FaceID、小组件、主题/语言扩展。
- 已超出 MVP 的内容
  - 统计分析 UI 骨架（趋势/排行）已存在，建议“保留但不扩展”。
  - Debug 工具页仅保留在 Debug 编译配置。
