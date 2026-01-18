# JustOne（记账 App）开发任务路线图（小步迭代/边验收边交付）

> 原则：每一步都可编译/可运行/可演示；每个任务都有明确验收标准；任务小、细、可切片。

---

## 0. 项目基线（Bootstrap）— 替换为「架构基线（Architecture Baseline）」

> 目标：不是“能跑起来”，而是“从第一天就不会烂尾”：依赖注入清晰、分层边界明确、数据模型与时区口径落地、可测试可预览。

---

### 0.1 分层边界与依赖规则（必须写死）

- 步骤
  1. 定义分层：Features / Services / Data / Core（Utilities & Theme）
  2. 写 `ArchitectureRules.md`（或放 README 顶部）明确依赖方向：
     - Features 只能依赖 Services 协议 + Repository 协议（不能直接摸 CoreData）
     - Services 可依赖 Repository 协议（或组合多个 Repo）
     - Data 层实现 CoreDataXXXRepository、PersistenceController
     - Core 只能放无业务的工具（Formatter/Date/Money/Theme）
  3. 建立 `DIContainer`（或 `AppEnvironment`）集中管理依赖注入（Repo/Service 注入到各 VM）
- 验收标准
  - ✅ 任意 ViewModel 文件内**不出现** `NSManagedObjectContext` / `NSFetchRequest` / `PersistenceController`
  - ✅ 所有 Repo/Service 都通过 `DIContainer` 注入（禁止在 ViewModel 内 `init()` 直接 new 实现类）
  - ✅ `ArchitectureRules.md` 可读且团队成员可按规则扩展

---

### 0.2 Domain 约束与关键枚举（统一口径）

- 步骤
  1. 定义 `BillType`（income/expense）、`ExportFormat`、`ThemeMode` 等枚举（Core 层）
  2. 定义统一的金额与日期规范：
     - CNY、两位小数、禁止负数（Money）
     - 发生时间统计口径（Date）
  3. 建立集中式 `Formatters`（MoneyFormatter / DayKeyFormatter）
- 验收标准
  - ✅ UI 中金额显示全走 MoneyFormatter（无散落 String(format:)）
  - ✅ “同日/分组/统计”口径只有一个函数产出 DayKey（occurredLocalDate）
  - ✅ BillType 只在一个地方定义，避免字符串魔法值

---

### 0.3 CoreData 实体与字段（先定结构，再写功能）

- 步骤
  1. 创建/确认 CoreData 模型（.xcdatamodeld 或代码生成其一，选定不摇摆）
  2. 落地实体与字段（必须齐全）：
     - Bill：id、type、amount、occurredAtUTC、tzId、tzOffset、occurredLocalDate、note、categoryId、isFromRecurring、createdAt、updatedAt、deletedAt、trashUntil
     - Category：id、type、name、iconKey、isSystem、sortOrder
     - RecurringTask：id、type、amount、categoryId、note、hour/minute、lastRunAtUTC、isEnabled、createdAt、updatedAt
  3. 建立 `SeedService`：首次启动写入预置分类 + 系统“未分类”
- 验收标准
  - ✅ App 启动后 CoreData 可持久化写入并读取一条 Bill（通过临时 debug action 或 Preview seed）
  - ✅ “未分类”已创建且标记 isSystem=true
  - ✅ 模型字段命名与类型稳定（后续迁移成本可控）

---

### 0.4 时区策略基线（防历史漂移）

- 步骤
  1. 新建 `TimePolicy`：
     - 输入：用户选择的发生时间（本地）
     - 输出：occurredAtUTC、tzId、tzOffset、occurredLocalDate(YYYY-MM-DD)
  2. 规定：分组/筛选/重复判断一律用 occurredLocalDate
  3. 为 “展示时间” 准备转换函数（按当前系统时区展示 occurredAtUTC）
- 验收标准
  - ✅ 创建 Bill 时必写四字段：occurredAtUTC/tzId/tzOffset/occurredLocalDate
  - ✅ BillsList 的分组 key 来自 occurredLocalDate（代码可定位）
  - ✅ 任何“同日”判断不使用 `Calendar.current` 直接算（避免时区漂移）

---

### 0.5 Repository 协议 + 最小实现（数据访问隔离）

- 步骤
  1. 定义协议：
     - BillRepository：create/update/fetch(by dayKey)/softDelete/restore/purgeExpired
     - CategoryRepository：list(type)/create/delete(with migration hook)/countLimit
     - RecurringRepository：CRUD/enable
     - TrashRepository：list/restore/deleteForever/clearAll
  2. 实现 `CoreDataBillRepository` 等最小可用实现（只做通路）
  3. ViewModel 仅依赖协议，注入 mock 以便 Preview/Test
- 验收标准
  - ✅ ViewModel 通过协议可完成：新增 Bill -> 查询 -> 展示（用极简列表验证）
  - ✅ 可用 inMemory CoreData + Mock Repo 运行 Preview
  - ✅ 替换 repo 实现不影响 Feature 层编译（证明隔离成立）

---

### 0.6 Services 骨架（后续功能的“插槽”）

- 步骤
  1. 定义接口（先不做复杂实现）：
     - ExportService：exportCSV/exportPDF
     - RecurringService：runCatchUp(maxDays=30)/detectDuplicate(for recurring only)
     - SecurityService：isLockEnabled/authenticate/keychainStore
  2. 将 Service 组合到 `DIContainer`
- 验收标准
  - ✅ Services 以协议形式存在，VM 只感知协议
  - ✅ 每个 Service 有一个最小 stub 实现（返回占位/抛错误）但不影响编译与导航
  - ✅ 后续补实现不会改动 Feature 的结构（只替换实现类）

---

### 0.7 “架构验收”演示页（强制可视化验收）

- 步骤
  1. 新建 Debug 页面（仅 Debug 编译配置可见）：
     - 一键 seed 数据
     - 一键创建 Bill（随机金额/分类/日期）
     - 切换展示分组（按 occurredLocalDate）
  2. 用于验证：Repo/TimePolicy/SeedService 都按预期工作
- 验收标准
  - ✅ 不写任何业务 UI 也能验证数据链路闭环（seed -> create -> fetch -> group）
  - ✅ 未来改动模型/策略时可快速回归验证

---

## 1. App Shell（导航骨架）

### 1.0 Design System 基线（Tokens + 组件库 + Preview 对照）

- 步骤
  1. 建立/补齐目录：
     - `Core/Theme/`：Colors、Typography、Radii、Spacing、Shadows
     - `Core/UIComponents/`：通用组件
     - `Core/PreviewKit/`：Mock 数据/Preview Helpers（可选）
  2. 从 demos 提取最小 tokens（先不追求全量）：
     - 主背景/卡片背景/分割线/主文字/次文字/强调色
     - 圆角：卡片、按钮、输入框（2～3 档）
     - 间距：4/8/12/16/24
     - 阴影：卡片/浮层（1～2 档）
  3. 实现最小组件（8～10 个）：
     - `JOCard`（容器）
     - `JOPrimaryButton`（主按钮）
     - `JOIconButton`（图标按钮）
     - `JOSegmentedControl`（支/收切换、周/月/年切换）
     - `JOAmountText`（金额展示：CNY/2 位）
     - `JOListRow`（列表行：左图标+标题+副标题+金额）
     - `JOFAB`（底部加号按钮）
     - `JOChip`（小标签/状态）
  4. 为每个组件写 Preview，并放入 `PreviewGallery` 页面集中展示
- 验收标准
  - ✅ 任意页面不允许直接写“散落的样式”（颜色/圆角/阴影应来自 tokens 或组件）
  - ✅ `PreviewGallery` 能一屏看到所有组件的状态（normal/disabled/selected）
  - ✅ Home/Profile 的关键元素能用组件替换（不要求像素级）

### 1.1 两个 Tab + 双 NavigationStack（含基础结构）

- 步骤
  1. 实现 TabView：Home / Profile
  2. 每个 Tab 内使用 NavigationStack
  3. Home 顶部右上角添加「明细」入口按钮（跳转 BillsList）
  4. Home/Profile 根页面搭建基础骨架（顶部栏/内容区/底部 Tab/FAB 占位）
- 验收标准
  - ✅ Home/Profile 两个 Tab 可切换
  - ✅ Home 右上角按钮可进入 BillsList（占位页即可）
  - ✅ 返回层级正确，无多余嵌套
  - ✅ Home/Profile 基础布局与 demos 结构一致（不追求像素级）

### 1.2 Home Dashboard UI（对照 `demos/justone_home_dashboard`）

- 步骤
  1. 顶部栏：月份选择、日历按钮（与 demo 结构一致）
  2. 汇总区：本月支出/收入/结余（`JOAmountText` + tokens）
  3. 列表区：按日分组展示（组标题 + 当日合计 + `JOListRow`）
  4. 首页 FAB 使用 `JOFAB`（先只做视觉与导航）
- 验收标准
  - ✅ 首页结构与 demo 对齐（顶部栏/汇总/分组列表）
  - ✅ 金额与文字样式只来自 tokens/组件
  - ✅ 可以使用 PreviewKit 假数据预览

### 1.3 Profile 主页 UI（对照 `demos/justone_profile_&_settings_1`）

- 步骤
  1. 头像与统计区（昵称 + 记录数）
  2. 功能入口行：分类设置、每日提醒、设置（`JOListRow` 风格）
  3. “每日提醒”先做 UI 开关占位
- 验收标准
  - ✅ Profile 结构与 demo 对齐
  - ✅ 入口行可导航到对应页面（未实现可先占位）

### 1.4 Settings 列表 UI（对照 `demos/justone_profile_&_settings_4`）

- 步骤
  1. 实现 Settings 列表页（账号、导出、解锁、定时、小组件、主题、语言）
  2. 每个入口先接入占位页面或后续任务页面
- 验收标准
  - ✅ Settings 列表 UI 与 demo 结构一致
  - ✅ 入口导航可用（未实现可先占位）

---

## 2. 数据层（CoreData + 模型 + Repository）

### 2.1 CoreData 栈（PersistenceController）

- 步骤
  1. 创建 PersistenceController（支持 inMemory 用于 Preview）
  2. 配置 CoreData store 位置与加载
  3. 添加“文件保护/加密”落点（至少 iOS Data Protection：complete 级别或同等策略）
- 验收标准
  - ✅ App 启动可加载 CoreData store
  - ✅ Preview 可注入 inMemory store
  - ✅ 加密/保护策略有明确实现或注释落点（能定位到具体代码行/配置项）

### 2.2 定义数据模型（Bill/Category/RecurringTask）

- 步骤
  1. 建立实体与字段（推荐 .xcdatamodeld；或纯代码生成，但必须统一）
  2. Bill 字段（必须）：
     - id(UUID), type(income/expense), amount(Decimal 或 Int cents)
     - occurredAtUTC(Date), tzId(String), tzOffset(Int)
     - occurredLocalDate(String: YYYY-MM-DD)
     - note(String?), categoryId(UUID?), isFromRecurring(Bool)
     - createdAt/updatedAt, deletedAt(Date?), trashUntil(Date?)
  3. Category 字段（必须）：
     - id, type(income/expense), name, iconKey, isSystem(Bool), sortOrder(Int)
  4. RecurringTask 字段（必须）：
     - id, type, amount, categoryId, note, hour/minute, lastRunAtUTC, isEnabled, createdAt/updatedAt
- 验收标准
  - ✅ 生成/编译通过（NSManagedObject 子类可用）
  - ✅ 可以创建并保存一条 Bill 到本地（通过简单测试按钮或临时代码）
  - ✅ occurredLocalDate 能正确生成（YYYY-MM-DD）

### 2.3 Repository 协议与默认实现

- 步骤
  1. 定义协议：
     - BillRepository：CRUD、软删、恢复、按日期分组查询
     - CategoryRepository：列表/新增/删除（删除规则后续实现）、排序
     - RecurringRepository：任务 CRUD、启停
     - TrashRepository：回收站列表/恢复/永久删除/清空
  2. 实现 CoreDataXXXRepository（最小可用）
- 验收标准
  - ✅ ViewModel 只能依赖协议，不直接依赖 CoreData 细节
  - ✅ 通过 Repository 完成：新增 Bill、查询 Bill 列表

---

## 3. 时区策略（防漂移）与日期口径

### 3.1 账单创建时写入时区快照

- 步骤
  1. 创建 TimePolicy 工具：
     - 获取当前系统 tzId / tzOffset
     - 由 occurredAt（本地）生成 occurredAtUTC
     - 生成 occurredLocalDate（按创建时系统时区）
  2. 在新增/编辑 Bill 保存时强制写入/更新上述字段
- 验收标准
  - ✅ 新增账单后字段齐全：occurredAtUTC/tzId/tzOffset/occurredLocalDate
  - ✅ occurredLocalDate 与用户选择的“发生日期”一致
  - ✅ 统计/分组不依赖当前时区（依赖 occurredLocalDate）

### 3.2 分组与“同日”判断统一使用 occurredLocalDate

- 步骤
  1. BillsList 按 occurredLocalDate 分组展示（今日/昨日概念可后续）
  2. 提供统一的 DayKey 生成函数（避免多处拼接）
- 验收标准
  - ✅ BillsList 分组稳定，不因系统时区变化而跨日
  - ✅ 同一账单永远落在同一个 occurredLocalDate 分组

---

## 4. 分类（收入/支出两套 + 未分类系统类）

### 4.1 预置分类与系统“未分类”

- 步骤
  1. 启动时 seed 预置分类（收入/支出各一组）
  2. 创建系统分类“未分类”（income/expense 各一个）
  3. 未分类：isSystem = true，数据层禁止删除/改名
- 验收标准
  - ✅ 首次启动能看到预置分类
  - ✅ 未分类存在且数据层不可删除/改名（UI 不展示，仅用于迁移）

### 4.2 分类管理页（网格 + 收入/支出切换）

- 步骤
  1. Categories 页面：`JOSegmentedControl` 切换 income/expense
  2. 网格展示分类（iconKey + name），对照 `demos/justone_profile_&_settings_7`
  3. “添加类别”卡片入口，数量限制 30
  4. 系统“未分类”不在列表展示，仅作为迁移目标（数据层禁止编辑/删除）
- 验收标准
  - ✅ 可切换两套分类列表
  - ✅ 新增分类成功并持久化
  - ✅ 达到 30 个后禁止新增并提示
  - ✅ 未分类不展示但仍存在，可作为迁移目标
  - ✅ UI 结构与 demo 一致（网格、卡片、分段切换）

### 4.3 分类删除规则（已引用 → 迁移未分类）

- 步骤
  1. 点击删除即弹窗提醒（说明迁移到未分类）
  2. 用户确认删除后：
     - 将相关 Bill.categoryId 置为对应“未分类”id
     - 删除该分类（不可恢复）
- 验收标准
  - ✅ 删除会提示迁移（无论是否被引用）
  - ✅ 确认删除后，相关账单分类全部变为未分类
  - ✅ 取消删除不改动数据
  - ✅ 分类删除后不可在回收站恢复（没有入口/没有数据）

### 4.4 分类编辑页（对照 `demos/justone_profile_&_settings_10`）

- 步骤
  1. 新增/编辑共用底部弹框，无标题，可下拉关闭
  2. 预览展示（图标 + 颜色），名称输入（最多 5 个字）
  3. 颜色选择（固定色 + 随机色）+ 图标网格（横向滑动 3 行）
  4. 编辑态底部“删除/保存”同排按钮
  5. 系统分类不在列表展示，数据层禁止编辑/删除
- 验收标准
  - ✅ 编辑后可保存并持久化
  - ✅ 名称最多 5 个字且可清空
  - ✅ 系统分类不可编辑（UI 不展示 + 数据层保护）

---

## 5. 账单流（新增/编辑/明细）

### 5.1 BillsList（明细列表页）

- 步骤
  1. Home 右上角进入 BillsList，UI 对照 `demos/justone_statistics_analysis`
  2. 主题色跟随全局 Tokens（不在页面内单独定义）
  3. 顶部筛选区：
     - 左侧返回按钮
     - 中部时间选择（随周/月/年切换变更文案）
       - 周：`2026 年第 X 周`（默认当前周）
       - 月：`2026 年 10 月`（默认当前月）
       - 年：`2026 年`（默认当前年）
     - 右侧支/收切换（胶囊分段）
  4. 汇总区块：
     - 标题随类型切换（本月总支出/本月总收入）
     - 总额金额（CNY 两位小数）
     - 环比/同比涨跌百分比（无数据时隐藏）
  5. 趋势折线图区块：
     - 根据选中范围（日/周/月）生成序列
     - 折线 + 绿色渐变填充（可先用 SwiftUI Shape 占位）
     - X 轴显示关键日期（1/15/31 或对应周/年）
     - 周范围时 X 轴显示：一、二、三、四、五、六、日
  6. 分类排行区块：
     - 以金额降序
     - 展示分类名/占比/金额
     - 进度条呈现占比（顶部一条强调色，其余灰绿）
     - 标题文案为“支出排行/收入排行”
     - 右侧筛选图标切换：最多/最少 支出/收入
  7. 时间范围切换（周/月/年）固定在底部胶囊条
  8. BillsList 展示按日分组的账单列表（类型/分类/金额/备注简略）
  9. 列表行使用 `JOListRow` + `JOAmountText`，分组头对照 `demos/justone_home_dashboard`
  10. 点击分类，弹出底部弹框（高度为屏幕 2/3）
- 验收标准
  - ✅ 明细列表可展示本地账单
  - ✅ 分组正确，列表滚动流畅
  - ✅ 点击条目可进入编辑
  - ✅ 顶部筛选区样式与 demo 一致（返回/时间选择/支收切换）
  - ✅ 时间选择文案随周/月/年切换更新
  - ✅ 汇总金额与趋势图按选中类型与时间范围计算
  - ✅ 周范围时 X 轴显示一~日
  - ✅ 分类排行可正确反映占比（总额为 0 时隐藏排行）
  - ✅ 排行标题随支出/收入切换
  - ✅ 排行筛选弹框高度为屏幕 2/3，选择后列表刷新
  - ✅ 时间范围切换后列表与统计联动刷新

### 5.2 BillsList - 分类明细弹框

- 步骤
  1. 触发入口：点击 5.1 的“分类排行”条目，弹出分类明细弹框（sheet）
     - 通过 `selectedCategoryId` + `isCategoryDetailPresented` 管理状态
  2. 弹框样式（参照 `demos/justone_statistics_analysis_detail`）
     - 背景遮罩：黑色半透明 + 轻微模糊
     - 弹框高度：屏幕 2/3
     - 顶部圆角：约 28~32，带轻微描边与阴影
     - 顶部拖拽指示条（Capsule）
  3. 顶部信息区
     - 居中显示分类名（如“房租”）
     - 显示该分类在当前时间范围内的总额（CNY 两位小数）
  4. 明细列表区（可滚动）
     - 每行：日期（如“10月1日”）+ 备注/商户（次行）+ 右侧金额
     - 金额格式：支出为负号/白色，收入为正号/主色
     - 行间分隔线：`white.opacity(0.05)`，行高约 56~64
  5. 数据与筛选逻辑
     - 仅展示：当前时间范围（周/月/年） + 当前类型（支出/收入） + 选中分类
     - 排序：按发生时间倒序
     - 过滤：排除 `deletedAt != nil`
  6. 空态处理
     - 若无记录，显示“暂无记录”占位文案
  7. 交互
     - 支持下拉关闭 / 点击遮罩关闭
     - 弹框出现与关闭动画使用轻微 `easeInOut`

- 验收
  - ✅ 点击分类后弹框显示，背景变暗并可关闭
  - ✅ 弹框高度为屏幕 2/3，顶部有拖拽指示条
  - ✅ 分类名与总额显示正确（随时间范围与类型联动）
  - ✅ 列表只包含该分类账单，排序正确
  - ✅ 无数据时显示空态文案

### 5.3 QuickEntry + BillEditor（新增/编辑）

- 步骤
  1. 新增入口：从 Home FAB 进入 QuickEntry 第一步（选分类，对照 `demos/justone_quick_entry_1`）
  2. 选择分类后进入金额键盘页（对照 `demos/justone_quick_entry_2`）
  3. 支持备注输入与日期快速入口
  4. 点击确认保存后返回，列表刷新
  5. 编辑模式：从 BillsList 进入并预填数据（可沿用同一 UI）
- 验收标准
  - ✅ 金额输入校验：负数禁止；最多 2 位小数
  - ✅ 保存后能在 BillsList 与 Home 占位列表看到新记录
  - ✅ 编辑能修改金额/分类/日期/备注并持久化
  - ✅ UI 结构与 QuickEntry demo 对齐（不追求像素级）

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
