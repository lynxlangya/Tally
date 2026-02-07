# JustOne 深度代码评审报告（2026-02-07）

## 1. 总体结论
- 结论：**需修改后再进入上架流程**。
- 阻断项：无 P0；有 **P1 3 项**（深链可达性、定时记账可执行性、跨时区编辑数据漂移）。
- 一句话总结：项目分层和组件化方向正确，但当前存在影响真实用户链路的功能闭环问题，不建议在修复前上架。

## 2. 评审范围与方法
- 评审范围：
  - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne`
  - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOneWidgets`
  - `/Users/langya/Documents/CodeHub/macOS/JustOne/Shared`
  - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne.xcodeproj`
- 增量基线：`baa6042724f47d4c34f2f463edf5f45a2f203e7d`
- 编译验证：已执行并通过
  - `xcodebuild -project /Users/langya/Documents/CodeHub/macOS/JustOne/JustOne.xcodeproj -scheme JustOne -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`
  - 结果：`BUILD SUCCEEDED`

## 3. 架构与分层评审（先看）
- 对齐项（通过）
  - 分层与注入主干清晰：`DIContainer` 汇总构造依赖，View/VM 通过仓储协议工作。
  - Feature 层未发现直连 CoreData 的违例（未扫描到 `NSManagedObjectContext` / `NSFetchRequest` / `PersistenceController` 直接使用）。
- 关键偏差（需修）
  - Services 层中 `RecurringService` 仍为 Stub，且业务链路未接入执行器，导致“定时记账”存在 UI 但缺少生产闭环（见 P1-2）。

## 4. 具体问题清单（P0-P3）

### [P1] Widget 深链未注册 URL Scheme，点击跳转可能失效
- Severity：P1
- Evidence：
  - Widget 侧明确发起 `justone://` 跳转：
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOneWidgets/WidgetViews/QuickEntryWidgetView.swift:38`
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOneWidgets/WidgetViews/QuickEntryWidgetView.swift:54`
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOneWidgets/WidgetViews/SummaryTrendWidgetView.swift:52`
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOneWidgets/WidgetViews/SummaryTrendWidgetView.swift:82`
  - App 侧依赖 `justone` scheme 解析：
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Core/DeepLink/DeepLinkRouter.swift:11`
  - 工程配置使用生成 InfoPlist，但未配置 URL Types：
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne.xcodeproj/project.pbxproj:391`
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne.xcodeproj/project.pbxproj:424`
    - 且未检索到 `CFBundleURLTypes/CFBundleURLSchemes` 键。
- Impact：桌面小组件点击“+”或卡片跳转时，可能无法唤起 App 对应页面，直接影响核心使用路径。
- Recommendation：在 App Target 的 InfoPlist 构建设置中补充 `CFBundleURLTypes`（包含 `justone`），并做 widget->app 跳转回归。
- RegressionCheck：
  1. 安装 App 与 Widget 后，从小组件点击 `quickEntry/home`。
  2. 验证是否进入 `JOTabScaffold` 并触发 `DeepLinkRouter` 正确路由。

### [P1] “定时记账”当前为“可创建不可执行”
- Severity：P1
- Evidence：
  - 设置页已对用户暴露入口：
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Features/Settings/SettingsView.swift:113`
  - 表单可成功创建 `RecurringTaskRecord`：
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Features/Recurring/RecurringBillFormViewModel.swift:43`
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Features/Recurring/RecurringBillFormViewModel.swift:80`
  - 运行时注入的是 Stub Service：
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/App/DIContainer.swift:38`
  - Service 本身未实现真实执行：
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Services/RecurringService.swift:8`
- Impact：用户能“创建任务”，但任务不会自动落账；属于功能承诺与行为不一致，发布风险高。
- Recommendation：
  1. 提供 `RecurringService` 实现（catch-up + 去重 + 生成 Bill）。
  2. 在 App 启动/前后台切换触发 `runCatchUp(maxDays:)`。
  3. 加入失败可观测性（日志或错误状态）。
- RegressionCheck：
  1. 创建“每日”任务，修改系统日期跨天。
  2. 重启 App 后验证是否自动补账且不重复。

### [P1] 编辑账单在时区变化下会隐式改写原始日期口径
- Severity：P1
- Evidence：
  - 编辑态初始化直接使用 UTC 绝对时刻：
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Features/QuickEntry/QuickEntryViewModel.swift:52`
  - 保存时按“当前时区”重新快照并写回：
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Features/QuickEntry/QuickEntryViewModel.swift:125`
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Features/QuickEntry/QuickEntryViewModel.swift:133`
- Impact：当用户跨时区后仅编辑备注/分类，也可能导致 `occurredLocalDate` 改变，出现账单“跨天漂移”。
- Recommendation：
  1. 编辑时默认沿用原账单 `tzId/tzOffset/occurredLocalDate`。
  2. 仅在用户明确修改日期/时间时才重算时区快照。
- RegressionCheck：
  1. A 时区创建账单，切到 B 时区只改备注后保存。
  2. 验证 `occurredLocalDate` 是否保持不变。

### [P2] Home 时间展示未使用账单时区，与明细页口径不一致
- Severity：P2
- Evidence：
  - Home 列表时间只基于当前时区渲染：
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Features/Home/HomeViewModel.swift:146`
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Features/Home/HomeViewModel.swift:205`
  - BillsList 已使用账单 `tzId/tzOffset` 渲染：
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Features/BillsList/BillsListViewModel.swift:346`
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Features/BillsList/BillsListViewModel.swift:351`
- Impact：同一账单在首页与统计页可能出现不同时间文本，降低用户信任。
- Recommendation：抽出统一时间展示策略，Home 与 BillsList 共用同一函数。
- RegressionCheck：构造跨时区账单，比较 Home/BillsList 显示是否一致。

### [P2] 统计与 Widget 存在 O(N×days) 计算热点，数据增长后会卡顿
- Severity：P2
- Evidence：
  - BillsList 趋势按周/月/年多次 `filter+reduce`：
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Features/BillsList/BillsListViewModel.swift:252`
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Features/BillsList/BillsListViewModel.swift:262`
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Features/BillsList/BillsListViewModel.swift:271`
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Features/BillsList/BillsListViewModel.swift:280`
  - Widget sparkline 同样按天循环过滤：
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Services/WidgetSnapshotService.swift:52`
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Services/WidgetSnapshotService.swift:69`
- Impact：账单规模上升后首页/统计/Widget 刷新成本显著上升，影响流畅度与电量。
- Recommendation：先按 dayKey / monthKey 预聚合为字典，再 O(days) 映射；必要时下沉到 Repository 查询层。
- RegressionCheck：导入大样本数据（例如 1~5 万条）对比优化前后首屏与刷新耗时。

### [P2] DayKeyFormatter 共享可变 DateFormatter，存在并发安全风险
- Severity：P2
- Evidence：
  - 全局静态 formatter 被重复改写 `timeZone`：
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Core/Utilities/DayKeyFormatter.swift:4`
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Core/Utilities/DayKeyFormatter.swift:13`
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Core/Utilities/DayKeyFormatter.swift:18`
- Impact：多线程并发时可能出现日期 key 计算错误，进而导致分组错乱。
- Recommendation：改为线程隔离 formatter（ThreadLocal / actor 封装）或使用不可变 `Date.FormatStyle`。
- RegressionCheck：并发压力下重复生成 dayKey，校验稳定性与正确性。

### [P2] 预置分类仅补系统类，缺失“默认分类增量补齐”能力
- Severity：P2
- Evidence：
  - 非空库场景仅执行 `ensureSystemCategories()`：
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Data/CoreDataSeedService.swift:68`
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Data/CoreDataSeedService.swift:97`
- Impact：后续迭代新增默认分类/图标时，老用户无法自动获得，版本体验分裂。
- Recommendation：引入“按稳定 ID 补齐缺失预置分类（非覆盖用户自定义）”策略。
- RegressionCheck：老库升级后验证新增预置是否自动补齐且不覆盖用户编辑。

### [P2] 工程缺少测试 Target，发布回归防线薄弱
- Severity：P2
- Evidence：
  - 工程仅有两个 Native Target（App + Widget），未见单测/UI 测试 target：
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne.xcodeproj/project.pbxproj:131`
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne.xcodeproj/project.pbxproj:156`
- Impact：关键口径（时区、软删、定时补跑）变更后难以及时发现回归。
- Recommendation：至少补齐 Core 与 Repository 层单测，并建立最小 UI smoke 测试。
- RegressionCheck：CI 增加 `xcodebuild test` 并设定最低通过门槛。

### [P3] 评审增量包含用户本地 scheme 排序文件，噪音高
- Severity：P3
- Evidence：
  - 变更文件位于 `xcuserdata`：
    - `/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne.xcodeproj/xcuserdata/langya.xcuserdatad/xcschemes/xcschememanagement.plist:1`
- Impact：易引发无意义冲突，不利于协作。
- Recommendation：将 `xcuserdata` 纳入忽略策略，避免提交本机状态。
- RegressionCheck：后续 PR 不再出现 `xcuserdata` 差异。

## 5. 组件封装与易用性评审
- 优点
  - `Core/UIComponents` 的原子组件拆分较完整（按钮、卡片、图标、Sheet 容器、HeaderBar），页面装配效率高。
  - `JOIcon` 已能兼容 SF Symbol / asset / emoji，减少页面层分支判断。
- 问题
  - 主题设置链路当前为展示型占位：
    - 入口可达：`/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Features/Settings/SettingsView.swift:115`
    - 行为为 `showComingSoon`：`/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Features/Settings/ThemeSettingsView.swift:32`
    - `ThemeManager` setter 仍是 no-op：`/Users/langya/Documents/CodeHub/macOS/JustOne/JustOne/Core/Theme/ThemeManager.swift:42`
  - 建议：若近期不做主题能力，入口应明确标记“预览”或在设置页降级处理，避免用户误判为可用功能。

## 6. 冗余代码、可优化空间、可扩展空间
- 冗余与重复
  - 时间/金额格式化逻辑在 Home、BillsList、Widget 分散，存在重复实现与口径漂移风险。
  - 趋势统计类逻辑可沉淀成 `AnalyticsAggregator`，减少多个 VM/Service 各自实现。
- 优化空间
  - 读取路径已支持 `list(fromDayKey:toDayKey:type:)`，可进一步下沉聚合查询，减少 UI 层 CPU 压力。
- 可扩展空间
  - Domain 与 Repository 抽象已具备扩展基础；最大短板在于 Service 实现与生命周期挂载不足。

## 7. iOS 发布标准与开发标准符合度矩阵（App Store 上架门槛）

| 维度 | 当前状态 | 结论 |
|---|---|---|
| 可编译可打包 | Debug Simulator 构建通过 | ✅ 通过 |
| 基础签名与版本号 | bundle id / team / version 已配置 | ✅ 通过 |
| Widget 能力与 App Group | entitlements 一致 | ✅ 通过 |
| 深链可达性 | 使用 `justone://` 但未注册 URL Types | ❌ 阻断 |
| 核心功能闭环 | 定时记账可创建不可执行 | ❌ 阻断 |
| 时区数据一致性 | 编辑账单存在跨时区漂移风险 | ❌ 阻断 |
| 自动化测试基线 | 无 tests target | ⚠️ 高风险 |
| 架构分层规则 | 主体符合规则 | ✅ 通过 |

## 8. 增量 Diff 专项结论（相对 `baa604...`）
- `CategoryEditSheet`：新增 Emoji 提示 toast，交互可用性提升，未发现阻断回归。
- `HomeView`：改为 `JOIcon` 渲染，修复了仅 `systemName` 下自定义图标显示受限的问题。
- `CoreDataSeedService` + `CategoryIconCatalog`：移除 `watermelon` 预置类别/图标入口，属于产品收敛；建议同步补齐“老用户预置对齐策略”（见 P2）。
- `xcschememanagement.plist`：属于本机状态文件变更，建议移出版本管理（见 P3）。

## 9. 回归验证清单（建议执行）
1. Widget 跳转：点击小组件 `quickEntry/home`，验证路由准确。
2. 定时记账：创建每日任务并跨天，验证是否自动入账且不重复。
3. 跨时区编辑：A 时区创建、B 时区仅改备注保存，验证 `occurredLocalDate` 不漂移。
4. 首页/明细时间一致性：同一账单在 Home 与 BillsList 时间文本一致。
5. 大数据性能：导入大样本后，观察统计页和 widget 刷新耗时。
6. 分类预置升级：老库升级后验证新增预置是否补齐且不覆盖用户自定义。

## 10. 假设与待确认项（需要你确认）
1. 本版本是否计划对外提供“定时记账自动落账”能力？若是，P1-2 需在发布前关闭。
2. Widget 深链是否就是发布范围内的核心能力？若是，P1-1 必须作为发布阻断处理。
3. 最低系统版本策略是否明确只支持 iOS 26.2+？若要覆盖更广设备，需要单独评估部署目标。

---

## 附：本次建议优先修复顺序
1. 先修 `CFBundleURLTypes` 与 Widget 跳转闭环（P1）。
2. 再修“定时记账执行链路”（P1）。
3. 紧接处理时区编辑漂移与 Home 时间口径统一（P1/P2）。
4. 最后补性能聚合与测试基线（P2）。
