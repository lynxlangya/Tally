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

### 1.1 两个 Tab + 双 NavigationStack

- 步骤
  1. 实现 TabView：Home / Profile
  2. 每个 Tab 内使用 NavigationStack
  3. Home 顶部右上角添加「明细」入口按钮（跳转 BillsList）
- 验收标准
  - ✅ Home/Profile 两个 Tab 可切换
  - ✅ Home 右上角按钮可进入 BillsList（占位页即可）
  - ✅ 返回层级正确，无多余嵌套

### 1.2 全局主题与基础样式（占位）

- 步骤
  1. 建立 Theme 结构：颜色/字号/间距（最少常量）
  2. 建立 Money/Date 格式化工具（Utilities/Formatters）
- 验收标准
  - ✅ 关键格式化工具有单一入口（如 MoneyFormatter/DateFormatterFactory）
  - ✅ 首页金额展示能统一格式（CNY/2 位）

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
  2. 创建系统分类“未分类”（income/expense 各一个或统一一个——需按实现选其一并写明）
  3. 未分类：isSystem = true，不可删除/不可改名
- 验收标准
  - ✅ 首次启动能看到预置分类
  - ✅ 未分类存在且不可删除（UI 层禁用 + 数据层保护）

### 4.2 分类管理页（网格 + 收入/支出切换）

- 步骤
  1. Categories 页面：Segment 切换 income/expense
  2. 网格展示分类（iconKey + name）
  3. 支持新增分类（数量限制 30）
- 验收标准
  - ✅ 可切换两套分类列表
  - ✅ 新增分类成功并持久化
  - ✅ 达到 30 个后禁止新增并提示

### 4.3 分类删除规则（已引用 → 迁移未分类）

- 步骤
  1. 删除分类前检查引用（Bill.categoryId == category.id）
  2. 若存在引用：弹窗提醒
  3. 用户确认删除后：
     - 将相关 Bill.categoryId 置为对应“未分类”id
     - 删除该分类（不可恢复）
- 验收标准
  - ✅ 删除已引用分类会提示
  - ✅ 确认删除后，相关账单分类全部变为未分类
  - ✅ 分类删除后不可在回收站恢复（没有入口/没有数据）

---

## 5. 账单流（新增/编辑/明细）

### 5.1 BillsList（明细列表页）

- 步骤
  1. Home 右上角进入 BillsList
  2. BillsList 展示按日分组的账单列表（类型/分类/金额/备注简略）
  3. 点击进入 BillEditor（编辑模式）
- 验收标准
  - ✅ 明细列表可展示本地账单
  - ✅ 分组正确，列表滚动流畅
  - ✅ 点击条目可进入编辑

### 5.2 BillEditor（新增/编辑）

- 步骤
  1. 从 Home FAB 进入 BillEditor（新增模式）
  2. 字段：
     - 类型（支/收）
     - 分类选择（跟随类型切换）
     - 金额输入（CNY/2 位，不允许负数）
     - 日期选择（发生时间）
     - 备注（可选）
  3. 保存后返回，列表刷新
- 验收标准
  - ✅ 金额输入校验：负数禁止；最多 2 位小数
  - ✅ 保存后能在 BillsList 与 Home 占位列表看到新记录
  - ✅ 编辑能修改金额/分类/日期/备注并持久化

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

---

## 7. 定时记账（补跑 30 天 + 重复提示）

### 7.1 定时任务列表（占位到可用）

- 步骤
  1. Profile -> Settings -> RecurringTasks 入口
  2. 列表展示任务：类型/分类/金额/时间/启用状态
  3. 新建/编辑任务页：选择类型/分类/金额/时间/备注/启用
- 验收标准
  - ✅ 任务 CRUD 可用并持久化
  - ✅ 任务启用/停用状态可切换

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
  2. 选择日期范围（占位 UI 可先默认本月）
  3. 调用 ExportService 并弹出分享面板
- 验收标准
  - ✅ 可从 Settings 一键导出 CSV（本月）
  - ✅ 分享面板可用（或保存到 Files）

---

## 9. 安全（密码/FaceID 占位 + CoreData 保护）

### 9.1 SecurityService（开关与验证占位）

- 步骤
  1. SecurityService：
     - isLockEnabled
     - authenticate()（LocalAuthentication）
  2. Settings 添加开关：启用解锁（占位）
  3. App 进入前台/启动时若启用则弹解锁（可先简单实现）
- 验收标准
  - ✅ 启用后启动/回前台会触发验证
  - ✅ 验证失败不可进入主界面（至少停留在锁屏遮罩页）

### 9.2 数据保护策略确认

- 步骤
  1. CoreData store 使用文件保护等级（Data Protection）
  2. 关键设置写入 Keychain
- 验收标准
  - ✅ 可明确指出保护策略已启用（代码与配置可追溯）
  - ✅ Keychain 读写可用（简单存取测试）

---

## 10. 收尾：质量、测试与可维护性

### 10.1 Preview 与 Mock 数据注入

- 步骤
  1. 为各页面提供 Preview 注入（inMemory CoreData）
  2. 提供少量 seed Bill 用于列表预览
- 验收标准
  - ✅ 主要页面 Preview 可正常渲染
  - ✅ 不依赖真机/真实数据

### 10.2 边界用例验收清单（最少 20 条）

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
