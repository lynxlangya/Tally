# 任务 24 代码自评

## 1. 总体结论
- 结论：通过
- 阻断项：无
- 一句话总结：非挂起项已按 issue 边界修复并关闭；#82 按总控要求保留在独立分支，主修复分支未合并该重构。

## 2. 任务定义与验收清单
- 任务目标摘要：处理深度扫描批次 #80–#107；跳过带 `needs-decision` 的 #87 / #100 / #102；#82 在 `feat/scan24-async-reads` 独立分支先测量后实施。
- 验收 checklist：
  - [x] 非挂起 issue closed：#80–#86、#88–#99、#101、#103–#107、#82 均为 `CLOSED`；#87/#100/#102 仍 `OPEN` 且带 `needs-decision`。
  - [x] #82 独立分支处理：`feat/scan24-async-reads` 上提交 `5ff01f6 fix(scan24): ISSUE-03 仓库读路径后台化 (#82)`；已切回 `feat/scan24-fixes`，未合并。
  - [x] 架构红线：`rg -n "import CoreData|NSManagedObjectContext|NSFetchRequest|PersistenceController" Tally/Features` 无输出。
  - [x] 临时测量脚手架清理：`rg -n "SCAN24_ISSUE82|testScan24Issue82" Tally TallyTests` 无输出。
  - [x] 构建：`xcodebuild -project Tally.xcodeproj -scheme Tally -destination 'platform=iOS Simulator,name=iPhone 17' build` -> `** BUILD SUCCEEDED **`。
  - [x] 全量测试：`xcodebuild -project Tally.xcodeproj -scheme TallyTests -destination 'platform=iOS Simulator,name=iPhone 17' test` -> `** TEST SUCCEEDED **`。

## 3. 变更范围
- 分支/状态：主线修复在 `feat/scan24-fixes`；#82 架构重构在 `feat/scan24-async-reads`。
- 当前分支说明：`feat/scan24-fixes` 不包含 #82 commit，符合总控“不合并 #82 独立分支”的规则。
- 文件清单概览：
  - App / DI：`Tally/App/DIContainer.swift`
  - Data / Repositories：`Tally/Data/Repositories/*`
  - Features：Home、QuickEntry、BillsList、Categories、Recurring、Settings、Profile、AppShell 等对应 issue 范围内文件
  - Core / Shared：金额、时间、错误文案、本地化、Widget snapshot、主题/图标等对应 issue 范围内文件
  - Tests：`TallyTests/*` 覆盖相关 ViewModel、Service、Repository、Widget、Import/Export、Localization、Persistence 等路径

## 4. 架构与整体对齐
- 对齐情况：通过。保持 `Features -> Services -> Repositories -> Data`，Feature/ViewModel 未直接依赖 Core Data；写路径仍通过既有 Repository 协议；#82 新增异步读能力也通过协议注入。
- 阻断项：无。

## 5. 具体问题清单
- 未发现 P0 / P1 / P2 / P3 阻断问题。

## 6. 优化建议
- 可维护性：#82 的 async 读路径已限制在 Bill 读能力，不扩散到 Category / Recurring，后续若要异步化其他仓库应单独立项。
- 性能/体验：#82 后台读降低 UI 侧主线程触发耗时，但完整 async wall-clock 仍受 fetch/map 成本影响；后续若数据量继续增长，可再评估分页或聚合查询。
- 可测试性：本轮主要补了行为回归测试与 Core Data in-memory 测试；UI 手工冒烟结论已写入各 issue 评论。

## 7. 风险与回归面
- 风险点：
  - 数据刷新：`.billDidChange` / `.categoryDidChange` 仍是跨页面刷新入口，需关注通知连发下的结果回写顺序。
  - 时间口径：筛选、分组、汇总继续以 `occurredLocalDate` 为准。
  - Core Data migration：#94 涉及模型索引变更，已做旧版本覆盖安装烟测。
  - #82 独立分支：主修复分支不含该重构，后续若要集成需显式合并或 PR。
- 建议回归验证步骤：
  1. 新建 / 编辑 / 删除账单后观察 Home、账单页、Widget 刷新。
  2. 切换月 / 年 / 自定义范围，检查统计、趋势、列表 dayKeys。
  3. 导出 CSV 后检查公式前缀转义与临时文件清理。
  4. 从旧 build 覆盖安装当前 build，确认 Core Data 轻量迁移成功。

## 8. 覆盖范围与假设
- 覆盖范围：任务 24 已关闭 issue、当前本地分支状态、#82 独立分支提交、GitHub issue 状态、构建与测试命令输出。
- 假设：GitHub issue 状态为当前权威进度；#87 / #100 / #102 的 `needs-decision` 挂起状态符合总控要求，不计入本轮完成缺口。

## 本次落地记录（2026-07-04）
- 完成 #80–#107 中 25 个非挂起 issue；#87 / #100 / #102 保持挂起。
- #82 前置测量：5,000 条 / 12 个月，`homeMonthMs=8.781`、`billsMonthMs=12.640`、`billsYearMs=62.354`，超过降级阈值，因此实施后台读。
- #82 实施后主线程触发耗时：`homeMainMs=0.006`、`billsMonthMainMs=0.003`、`billsYearMainMs=0.010`。
- 最小验证：
  - `git diff --check` -> 无输出
  - App build -> `** BUILD SUCCEEDED **`
  - Home / BillsList / CoreData async reader 定向测试 -> `** TEST SUCCEEDED **`
  - TallyTests 全量测试 -> `** TEST SUCCEEDED **`
