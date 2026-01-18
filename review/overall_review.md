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
  - BillsList 未展示账单明细列表，导航入口与统计页割裂：`JustOne/Features/BillsList/BillsListView.swift`。
  - （已处理）BillsList 已接入真实数据（移除 Mock 分支）。
- P1
  - （已处理）BillsList 已监听 `billDidChange`，编辑后可刷新：`JustOne/Features/BillsList/BillsListView.swift`。
  - （已处理）时间范围改为使用本地时区计算：`JustOne/Features/BillsList/BillsListViewModel.swift`。
  - （已处理）`TimePolicy.snapshot` 已补充注释以澄清 UTC 命名。
- P2
  - （已处理）BillType 切换控件已抽出 `JOBillTypeSegmentedControl` 复用。
  - （已处理）Sheet 拖拽条样式已抽出 `JOSheetHandle` 复用。

## 2.3 已封装组件清单（已落地）

- `JOSheetHandle`
  - 场景：QuickEntry、分类明细 Sheet 顶部拖拽条。
  - 位置：`JustOne/Core/UIComponents/JOSheetHandle.swift`。
  - 落地：`QuickEntryView`、`BillsListCategoryDetailSheet`。
- `JOSheetContainer`
  - 场景：Sheet 背景/圆角/描边样式复用。
  - 位置：`JustOne/Core/UIComponents/JOSheetContainer.swift`。
  - 落地：`QuickEntryView`、`BillsListCategoryDetailSheet`。
- `JOBillTypeSegmentedControl`
  - 场景：支/收切换（QuickEntry/BillsList/Header）。
  - 位置：`JustOne/Core/UIComponents/JOBillTypeSegmentedControl.swift`。
  - 落地：`QuickEntryView`、`BillsListHeaderView`。
- `JOHeaderBar`
  - 场景：带返回键 + 中标题的页面头复用。
  - 位置：`JustOne/Core/UIComponents/JOHeaderBar.swift`。
  - 落地：`SettingsView`、`CategoriesView`、`PlaceholderView`。
- `JOCategoryIconTile`
  - 场景：分类图标卡片复用（分类页/QuickEntry）。
  - 位置：`JustOne/Core/UIComponents/JOCategoryIconTile.swift`。
  - 落地：`QuickEntryCategoryItem`、`CategoryGridItem`。

## 2.4 冗余代码与可删项

- `JustOne/Core/UIComponents/JOFAB.swift`
  - 处理：已删除，Preview 使用 `JOFloatingAddButton` 替代（`JustOne/Core/PreviewKit/PreviewGallery.swift`）。
- `JustOne/Features/BillsList/BillsListViewModel+MockData.swift`
  - 处理：已标记为 `#if DEBUG`，避免进入正式编译路径。
- `JustOne/Features/Debug/`
  - 处理：`DebugView`/`DebugViewModel` 已加 `#if DEBUG` 保护。
- `demos/`
  - 处理：保留为设计参考素材，未参与 App 运行（后续可再迁移至文档资源目录）。

## 2.5 MVP 边界确认（建议）

- MVP 必须有（以现状为准）
  - 记一笔（支/收）+ 编辑：已实现，`JustOne/Features/QuickEntry/`。
  - 列表分组展示：已实现于 Home，`JustOne/Features/Home/`。
  - 分类管理：已实现，`JustOne/Features/Categories/`。
  - 本地存储：已实现，`JustOne/Data/` + `JustOne/JustOne.xcdatamodeld/`。
  - 导出（CSV 最小可用）：未实现，需要补齐。
- MVP 暂不做（可延后）
  - iCloud 同步、无障碍/色盲适配、复杂转账/报销/借还款规则。
  - 定时记账（补跑/重复提示）、解锁密码/FaceID、小组件、主题/语言扩展。
  - 软删/回收站/7 天撤销删除流程（移出 MVP）。
- 已超出 MVP 的内容
  - 统计分析 UI 骨架（趋势/排行）已存在，建议“保留但不扩展”。
  - Debug 工具页仅保留在 Debug 编译配置。
