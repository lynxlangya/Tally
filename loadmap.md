# JustOne（记账 App）开发任务路线图（小步迭代/边验收边交付）

> 原则：每一步都可编译/可运行/可演示；每个任务都有明确验收标准；任务小、细、可切片。

---

## 0. 项目基线（Architecture Baseline）— 以现有实现为准

> 目标：架构分层与依赖注入已落地，可持续迭代；以下内容对现状做描述与校准。

---

### 0.1 分层边界与依赖规则（已落地）

- 步骤（现状）
  1. 已建立目录分层：`App/`、`Features/`、`Services/`、`Data/`、`Core/`、`Resources/`。
  2. 架构规则文档：`JustOne/Core/ArchitectureRules.md`。
  3. 依赖注入集中在 `JustOne/App/DIContainer.swift` + `JustOne/App/AppEnvironment.swift`。
- 验收标准（已覆盖）
  - ✅ Feature/VM 未直接使用 CoreData API（`JustOne/Features/` 内无 CoreData 引用）。
  - ✅ Repo/Service 实现由 DIContainer 统一创建并注入。
  - ✅ 架构规则文档可定位与阅读。

---

### 0.2 Domain 约束与关键枚举（统一口径）

- 步骤（现状）
  1. 枚举定义：`BillType`/`ExportFormat`/`ThemeMode`（`JustOne/Core/Domain/Enums.swift`）。
  2. 金额与格式：`Money` + `MoneyFormatter`（`JustOne/Core/Utilities/Money.swift`）。
  3. 日期口径：`DayKeyFormatter`（`JustOne/Core/Utilities/DayKeyFormatter.swift`）。
- 验收标准（已覆盖）
  - ✅ UI 金额显示走 `JOAmountText` -> `MoneyFormatter`。
  - ✅ 分组口径统一使用 occurredLocalDate（`HomeViewModel`、`BillsListViewModel`）。
  - ✅ 关键枚举不使用字符串魔法值。

---

### 0.3 CoreData 实体与字段（模型已固化）

- 步骤（现状）
  1. 模型使用 `.xcdatamodeld`：`JustOne/JustOne.xcdatamodeld/JustOne.xcdatamodel/contents`。
  2. Bill/Category/RecurringTask 字段已落地，Category 额外包含 `colorHex`。
  3. `CoreDataSeedService` 负责预置分类与系统“未分类”。
- 验收标准（已覆盖）
  - ✅ Bill 字段包含 id/type/amount/occurredAtUTC/tzId/tzOffset/occurredLocalDate/createdAt/updatedAt/deletedAt/trashUntil。
  - ✅ Category/RecurringTask 字段齐全并可持久化。
  - ✅ “未分类”系统分类存在且 isSystem=true（`JustOne/Data/CoreDataSeedService.swift`）。

---

### 0.4 时区策略基线（已落地）

- 步骤（现状）
  1. `TimePolicy.snapshot` 生成 occurredAtUTC/tzId/tzOffset/occurredLocalDate（`JustOne/Core/Utilities/TimePolicy.swift`）。
  2. 新增/编辑账单写入时区快照（`CoreDataBillRepository.swift`、`QuickEntryViewModel.swift`）。
  3. 列表分组/筛选基于 occurredLocalDate（`HomeViewModel.swift`、`BillsListViewModel.swift`）。
- 验收标准（已覆盖）
  - ✅ 创建/更新 Bill 时写入四字段（TimePolicy + Repository/VM）。
  - ✅ 分组 key 统一来源于 occurredLocalDate。
  - ✅ 展示时间使用 tzId/tzOffset 进行转换（`BillsListViewModel.timeFormatterString`）。

---

### 0.5 Repository 协议 + 最小实现（已落地）

- 步骤（现状）
  1. 协议定义：`JustOne/Data/Repositories/RepositoryProtocols.swift`。
  2. CoreData 实现：`CoreDataBillRepository`/`CoreDataCategoryRepository`/`CoreDataRecurringRepository`/`CoreDataTrashRepository`。
  3. Preview/测试可用 Mock：`JustOne/Data/Repositories/MockRepositories.swift`。
- 验收标准（已覆盖）
  - ✅ ViewModel 仅依赖协议（`HomeViewModel`、`QuickEntryViewModel`、`CategoriesViewModel`）。
  - ✅ Preview 可注入 inMemory CoreData（`PersistenceController.preview`）。
  - ✅ 替换 repo 实现不影响 Feature 编译。

---

### 0.6 Services 骨架（已存在 Stub）

- 步骤（现状）
  1. 协议定义：`ExportService`/`RecurringService`/`SecurityService`（`JustOne/Services/`）。
  2. Stub 实现已接入 DIContainer。
- 验收标准（已覆盖）
  - ✅ Feature 仅依赖协议，当前 Stub 不阻断编译。
  - ✅ 后续实现可替换 `Stub*`。

---

### 0.7 Debug 验证页（已存在）

- 步骤（现状）
  1. DebugView 提供 seed/随机账单/刷新操作（`JustOne/Features/Debug/`）。
  2. 仅 Debug 构建通过 Profile 入口打开。
- 验收标准（已覆盖）
  - ✅ Debug 下可验证 seed -> create -> fetch 数据闭环。
  - ✅ Release 无入口。

---

## 1. App Shell（导航骨架）

### 1.0 Design System 基线（Tokens + 组件库 + Preview）

- 步骤（现状）
  1. Tokens 已落在 `JustOne/Core/Theme/`（Colors/Typography/Radii/Spacing/Shadows）。
  2. 组件库已落在 `JustOne/Core/UIComponents/`（JOCard/JOPrimaryButton/JOIconButton/JOSegmentedControl/JOAmountText/JOListRow/JOChip/JOFloatingAddButton/JOSettingRow/JOBackButton 等）。
  3. 组件预览页 `JustOne/Core/PreviewKit/PreviewGallery.swift` 已存在。
- 验收标准（已覆盖）
  - ✅ Home/Profile/BillsList 等页面引用 tokens/组件。
  - ✅ PreviewGallery 可预览核心组件状态。
  - ✅ 页面主色/圆角/间距来源于 tokens。

### 1.1 两个 Tab + 双 NavigationStack（已落地）

- 步骤（现状）
  1. `JOTabScaffold` 构建 Home/Profile 双 Tab + NavigationStack。
  2. 自定义 TabBar + FloatingAddButton（`JOTabBar`/`JOFloatingAddButton`）。
  3. Home 顶部按钮进入 BillsList（`HomeView`）。
- 验收标准（已覆盖）
  - ✅ Home/Profile 可切换。
  - ✅ Home -> BillsList 导航正常。
  - ✅ QuickEntry 通过 sheet 弹出。

### 1.2 Home Dashboard UI（已实现基础）

- 步骤（现状）
  1. 顶部栏：月份按钮 + 进入明细按钮（月份按钮当前仅 UI）。
  2. 汇总区：本月支出/收入/结余，使用 `JOAmountText`。
  3. 列表区：按 occurredLocalDate 分组，`JOListRow` 展示。
- 验收标准（已覆盖）
  - ✅ 首页可展示真实账单分组列表（`HomeViewModel.load`）。
  - ✅ 金额样式走 tokens/组件。
  - ✅ 点击条目可进入编辑（QuickEntry）。

### 1.3 Profile 主页 UI（已实现）

- 步骤（现状）
  1. 头像与统计区为静态展示。
  2. 入口：类别设置、每日提醒、设置。
- 验收标准（已覆盖）
  - ✅ Profile 结构与 demo 对齐，入口可导航。
  - ✅ 每日提醒为 UI 开关占位。

### 1.4 Settings 列表 UI（已实现）

- 步骤（现状）
  1. Settings 列表 UI 完成。
  2. 入口均指向占位页 `PlaceholderView`。
- 验收标准（已覆盖）
  - ✅ 列表结构与 demo 对齐。
  - ✅ 导航可用（占位）。

---

## 2. 数据层（CoreData + 模型 + Repository）

### 2.1 CoreData 栈（PersistenceController）

- 步骤（现状）
  1. `PersistenceController` 支持 inMemory Preview。
  2. store 路径与自动迁移已配置。
  3. 数据保护使用 `FileProtectionType.complete`。
- 验收标准（已覆盖）
  - ✅ App 启动可加载 CoreData store。
  - ✅ Preview 可注入 inMemory store。
  - ✅ 保护策略可定位（`JustOne/Data/PersistenceController.swift`）。

### 2.2 定义数据模型（Bill/Category/RecurringTask）

- 步骤（现状）
  1. 模型落地在 `.xcdatamodeld`，字段与 0.3 一致。
  2. Category 增补 `colorHex` 字段以支持颜色配置。
- 验收标准（已覆盖）
  - ✅ NSManagedObject 可生成并使用。
  - ✅ 可以创建并保存 Bill（QuickEntry/Debug 可验证）。
  - ✅ occurredLocalDate 为 YYYY-MM-DD。

### 2.3 Repository 协议与默认实现

- 步骤（现状）
  1. 协议与 CoreData 实现已完成。
  2. ViewModel 依赖协议注入。
- 验收标准（已覆盖）
  - ✅ 通过 Repository 完成：新增 Bill、查询 Bill 列表。
  - ✅ ViewModel 无 CoreData 直接依赖。

---

## 3. 时区策略（防漂移）与日期口径

### 3.1 账单创建时写入时区快照

- 步骤（现状）
  1. `TimePolicy.snapshot` 负责快照生成。
  2. 新增/编辑保存时写入四字段。
- 验收标准（已覆盖）
  - ✅ 新增账单后字段齐全。
  - ✅ occurredLocalDate 与用户选择日期一致。

### 3.2 分组与“同日”判断统一使用 occurredLocalDate

- 步骤（现状）
  1. Home/BillsList 分组与筛选基于 occurredLocalDate。
  2. DayKey 生成统一入口 `DayKeyFormatter`。
- 验收标准（已覆盖）
  - ✅ 分组不受系统时区变化影响。
  - ✅ 同一账单稳定落在同一分组。

---

## 4. 分类（收入/支出两套 + 未分类系统类）

### 4.1 预置分类与系统“未分类”

- 步骤（现状）
  1. 启动时 seed 预置分类（支出/收入各一组）。
  2. 创建系统分类“未分类”（income/expense 各一个）。
  3. 数据层禁止删除/编辑系统分类。
- 验收标准（已覆盖）
  - ✅ 首次启动可看到预置分类。
  - ✅ 未分类存在且 isSystem=true。
  - ✅ 系统分类不可删除/改名（`CoreDataCategoryRepository`）。

### 4.2 分类管理页（网格 + 收入/支出切换）

- 步骤（现状）
  1. `CategoriesView` 使用 `JOSegmentedControl` 切换支/收。
  2. 网格展示分类（icon + name），含“新增类别”卡片。
  3. 数量限制 30 个。
- 验收标准（已覆盖）
  - ✅ 可切换两套分类列表。
  - ✅ 新增分类可持久化。
  - ✅ 达到 30 个后禁止新增并提示。

### 4.3 分类删除规则（已引用 → 迁移未分类）

- 步骤（现状）
  1. 删除弹窗提醒迁移到未分类。
  2. 真实删除前执行迁移（Repository 层完成）。
- 验收标准（已覆盖）
  - ✅ 删除提示已实现（`CategoriesView`）。
  - ✅ 删除后相关账单迁移到未分类（`CoreDataCategoryRepository.delete`）。
  - ✅ 删除后不可恢复。

### 4.4 分类编辑页（已实现）

- 步骤（现状）
  1. 新增/编辑共用 `CategoryEditSheet`。
  2. 名称/颜色/图标可编辑，名称限制 5 字。
  3. 编辑态提供删除/保存按钮。
- 验收标准（已覆盖）
  - ✅ 编辑后可保存并持久化。
  - ✅ 名称限制生效，可清空。
  - ✅ 系统分类不可编辑/删除（数据层保护）。

---

## 5. 账单流（新增/编辑/明细）

### 5.1 BillsList（统计页骨架现状）

- 步骤（现状）
  1. 头部筛选与时间范围切换已实现（`BillsListHeader` + `TimeRangeBar`）。
  2. 汇总/趋势/排行区块 UI 已实现（`BillsListSummaryView`/`BillsListTrendSection`/`BillsListRankingView`）。
  3. 排行条目可打开分类明细弹框（见 5.2）。
  4. 当前数据源固定为 Mock，未接入真实账单。
- 验收标准（已覆盖）
  - ✅ 统计页结构可运行/可预览。
  - ✅ 周/月/年切换可驱动数据刷新（Mock）。
  - ✅ 排行点击弹出分类明细 sheet。
  - ⚠️ 现状：`BillsListViewModel.useMockData = true`，未展示真实明细列表。

### 5.2 BillsList - 分类明细弹框

- 步骤（现状）
  1. 点击排行条目弹出分类明细 sheet。
  2. 弹框样式与拖拽指示条已实现。
  3. 支持点击明细进入编辑（QuickEntry）。
- 验收标准（已覆盖）
  - ✅ 弹框高度为屏幕 2/3，顶部有拖拽指示条。
  - ✅ 分类名/总额/明细列表展示。
  - ✅ 点击条目进入编辑。

### 5.3 QuickEntry + BillEditor（新增/编辑）

- 步骤（现状）
  1. Home FAB 打开 QuickEntry 两步式弹框（分类 -> 金额）。
  2. 分类网格/支收切换/备注输入/自定义键盘已实现。
  3. 保存后写入 Repository，编辑复用同一 UI。
- 验收标准（已覆盖）
  - ✅ 支/收切换生效，分类网格可点击。
  - ✅ 金额输入限制两位小数，负数不允许。
  - ✅ 保存后持久化，编辑可回填并更新。

### 5.4 首页列表联动（新增/编辑后刷新）

- 步骤（现状）
  1. 首页列表使用 `BillRepository.list()`（过滤 deletedAt）。
  2. 新增/编辑通过 `billDidChange` 通知触发刷新。
  3. 左滑删除仅有确认 UI，尚未调用软删。
- 验收标准（已覆盖）
  - ✅ 新增/编辑后首页列表刷新。
  - ✅ 点击首页列表进入编辑，值可回填。
  - ✅ 左滑删除弹出确认（尚未执行业务删除）。

---
## 6. 软删与回收站（7 天撤销）

### 6.1 账单软删（删除进入回收站）

- 步骤
  1. BillsList 支持滑动删除（或菜单删除）
  2. 删除操作：
     - 设置 deletedAt = now
     - trashUntil = now + 7 days
  3. 正常列表查询默认过滤 deletedAt != nil
- 验收标准
  - ✅ 删除后账单从正常列表消失
  - ✅ 回收站能看到该账单，显示剩余天数
  - ✅ 7 天字段正确写入

### 6.2 回收站页面（恢复/永久删除/清空）

- 步骤
  1. Profile -> Settings -> Trash 入口（或 Profile 直接入口）
  2. 回收站列表展示：
     - 金额/分类/日期/备注
     - 剩余天数（trashUntil - now）
  3. 操作：
     - 恢复：清空 deletedAt/trashUntil
     - 永久删除：从 CoreData delete
     - 清空：批量永久删除
  4. 定时清理：App 启动或回前台清理 trashUntil < now 的记录
- 验收标准
  - ✅ 恢复后回到正常列表可见
  - ✅ 永久删除后彻底不存在
  - ✅ 过期自动清理生效（可通过修改系统时间或注入 nowProvider 测试）
  - ✅ UI 使用 `JOListRow` + `JOChip` 展示剩余天数

---

## 7. 定时记账（补跑 30 天 + 重复提示）

### 7.1 定时任务列表（占位到可用）

- 步骤
  1. Profile -> Settings -> RecurringTasks 入口
  2. 列表展示任务：类型/分类/金额/时间/启用状态（对照 `demos/justone_profile_&_settings_6`）
  3. 新建/编辑任务页：选择类型/分类/金额/时间/备注/启用
- 验收标准
  - ✅ 任务 CRUD 可用并持久化
  - ✅ 任务启用/停用状态可切换
  - ✅ UI 结构与 demo 对齐

### 7.2 RecurringService：补跑与生成账单

- 步骤
  1. 在 App 启动/回前台触发：
     - 遍历启用任务
     - 根据 lastRunAtUTC 计算遗漏天数（上限 30 天）
     - 逐日生成账单（isFromRecurring = true）
  2. 生成前做重复检测（仅定时生成触发）：
     - 同金额 + 同分类 + 同 occurredLocalDate 命中
     - 回调给 UI：提示用户是否继续生成
  3. lastRunAtUTC 更新策略：成功生成后更新；用户取消是否更新需明确（建议：取消不更新，保持下次仍提示）
- 验收标准
  - ✅ 关机/未打开多天后，首次启动能补跑（<=30 天）
  - ✅ 命中重复规则会提示且由用户决定
  - ✅ 仅 isFromRecurring 流程触发重复提示；手动记账不触发

---

## 8. 导出（CSV/PDF）— 先骨架后完善

### 8.1 ExportService 接口与占位实现

- 步骤
  1. 定义 ExportService：
     - exportCSV(range) -> URL
     - exportPDF(range) -> URL（可先返回占位或简化）
  2. 文件名规则：
     - Bill_YYYYMMDD-YYYYMMDD.csv/pdf
  3. CSV 字段顺序：
     - 时间、类型、分类、金额、备注
- 验收标准
  - ✅ 能导出 CSV 文件到临时目录并可分享（UI 可占位按钮触发）
  - ✅ 文件名符合规则
  - ✅ CSV 内容字段顺序正确，金额两位小数

### 8.2 Settings 中导出入口（占位）

- 步骤
  1. Settings 添加导出入口
  2. 导出页面 UI 对照 `demos/justone_profile_&_settings_8`（CSV/PDF 切换、日期范围）
  3. 调用 ExportService 并弹出分享面板
- 验收标准
  - ✅ 可从 Settings 一键导出 CSV（本月）
  - ✅ 分享面板可用（或保存到 Files）
  - ✅ UI 结构与 demo 对齐（格式切换/说明文案）

---

## 9. 安全（密码/FaceID 占位 + CoreData 保护）

### 9.1 SecurityService（开关与验证占位）

- 步骤
  1. SecurityService：
     - isLockEnabled
     - authenticate()（LocalAuthentication）
  2. 解锁设置页 UI 对照 `demos/justone_profile_&_settings_5`
  3. Settings 添加开关：启用解锁（占位）
  4. App 进入前台/启动时若启用则弹解锁（可先简单实现）
- 验收标准
  - ✅ 启用后启动/回前台会触发验证
  - ✅ 验证失败不可进入主界面（至少停留在锁屏遮罩页）
  - ✅ UI 结构与 demo 对齐（密码/FaceID/TouchID 开关）

### 9.2 数据保护策略确认

- 步骤
  1. CoreData store 使用文件保护等级（Data Protection）
  2. 关键设置写入 Keychain
- 验收标准
  - ✅ 可明确指出保护策略已启用（代码与配置可追溯）
  - ✅ Keychain 读写可用（简单存取测试）

---

## 10. 统计分析（对照 `demos/justone_statistics_analysis`）

### 10.1 统计聚合接口

- 步骤
  1. 新建 StatisticsService（按月汇总、按日趋势、分类排行）
  2. 口径统一：按 occurredLocalDate 聚合
- 验收标准
  - ✅ 统计接口能给出月总额、趋势数据、分类排行
  - ✅ 数据口径不受系统时区变化影响

### 10.2 统计页面 UI

- 步骤
  1. 实现统计页面：月份选择、支/收切换、折线图/排行列表
  2. UI 对照 `demos/justone_statistics_analysis`，图表可先用 SwiftUI Shape 占位
- 验收标准
  - ✅ 统计页结构与 demo 对齐（趋势图 + 排行列表）
  - ✅ 统计数据来自 StatisticsService

---

## 11. 设置扩展页面（可选/非 MVP）

### 11.1 账号设置页（对照 `demos/justone_profile_&_settings_3`）

- 步骤
  1. 账号页 UI：头像/账号信息/同步/修改密码（占位）
  2. 操作先接入占位提示
- 验收标准
  - ✅ UI 结构与 demo 对齐

### 11.2 主题设置页（对照 `demos/justone_profile_&_settings_9`）

- 步骤
  1. 主题模式（浅色/深色/跟随系统）
  2. 强调色选择（先做 UI 与持久化占位）
- 验收标准
  - ✅ UI 结构与 demo 对齐
  - ✅ 主题设置可持久化（UserDefaults）

### 11.3 语言设置页（对照 `demos/justone_profile_&_settings_11`）

- 步骤
  1. 语言列表 UI（跟随系统/简中/英文等）
  2. 切换逻辑可先占位提示
- 验收标准
  - ✅ UI 结构与 demo 对齐

### 11.4 小组件预览页（对照 `demos/justone_profile_&_settings_2`）

- 步骤
  1. 小组件预览 UI 与说明文案
  2. 入口与占位提示
- 验收标准
  - ✅ UI 结构与 demo 对齐

---

## 12. 收尾：质量、测试与可维护性

### 12.1 Preview 与 Mock 数据注入

- 步骤
  1. 为各页面提供 Preview 注入（inMemory CoreData）
  2. 提供少量 seed Bill 用于列表预览
- 验收标准
  - ✅ 主要页面 Preview 可正常渲染
  - ✅ 不依赖真机/真实数据

### 12.2 边界用例验收清单（最少 20 条）

- 步骤
  1. 写入 docs/acceptance.md（或直接在仓库 README）
  2. 覆盖：
     - 分类删除迁移、未分类保护
     - 软删恢复与过期清理
     - 定时补跑上限与重复提示
     - 金额校验、发生时间统计口径
     - 导出字段与命名
- 验收标准
  - ✅ 至少 20 条用例，可手工逐条验证
  - ✅ 每条用例有“步骤/期望结果”

---

> 每完成一个小节，必须做一次“可演示验收”，再进入下一节。
