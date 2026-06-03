# 任务 23 代码评审

## 1. 总体结论
- 结论：通过
- 阻断项：无
- 一句话总结：新增分类建议服务落在 Services 层，QuickEntry 仅替换排序来源并点亮常用区，未改 v1.2 预选逻辑。

## 2. 任务定义与验收清单
- 任务目标摘要：新增 `CategorySuggestionService`，基于用户历史账单的时段切片、近因衰减、全局频率对分类排序，接入 QuickEntry 快捷行和 picker 常用区。
- 验收 checklist：
  - [x] 新增 service 协议、默认实现、Stub（证据：`Tally/Services/CategorySuggestionService.swift:3`）
  - [x] 纯函数打分，输入 records/candidates/now，输出完整 ID 排序（证据：`Tally/Services/CategorySuggestionService.swift:46`）
  - [x] 本地小时经 `TimePolicy.editorDate` 还原（证据：`Tally/Services/CategorySuggestionService.swift:88`）
  - [x] 90 天窗口与过滤规则覆盖 isFromRecurring / nil / 未分类 / 已删分类（证据：`Tally/Services/CategorySuggestionService.swift:60`）
  - [x] score 并列回退稳定 sortOrder（证据：`Tally/Services/CategorySuggestionService.swift:121`）
  - [x] DI live/mock 均注入（证据：`Tally/App/DIContainer.swift:39`）
  - [x] QuickEntry 排序来源换成 service，选中项置顶逻辑保留（证据：`Tally/Features/QuickEntry/QuickEntryViewModel.swift:95`）
  - [x] picker 重新传 `frequentCategories`（证据：`Tally/Features/QuickEntry/QuickEntryView.swift:49`）
  - [x] 新增建议服务测试并保留 QuickEntryViewModelTests 全绿（证据：`TallyTests/CategorySuggestionServiceTests.swift:19`）

## 3. 变更范围
- 分支/状态：`feat/quick-entry-picker`，未提交改动。
- 文件清单：
  - Services：`Tally/Services/CategorySuggestionService.swift`
  - App：`Tally/App/DIContainer.swift`
  - Features：`Tally/Features/QuickEntry/QuickEntryViewModel.swift`、`Tally/Features/QuickEntry/QuickEntryView.swift`、`Tally/Features/AppShell/TallyTabScaffold.swift`、`Tally/Features/Home/HomeView.swift`、`Tally/Features/BillsList/BillsListView.swift`
  - Tests：`TallyTests/CategorySuggestionServiceTests.swift`
  - Docs：`Tasks/23_CategorySuggestionService.md`、`review/23_review.md`

## 4. 架构与整体对齐
- 对齐情况：`DefaultCategorySuggestionService` 只依赖 `BillRepository` 协议；Features 只依赖 service 协议和 repository 协议；未新增 CoreData import 或 Feature 直连 Data。
- 阻断项：无。

## 5. 具体问题清单
- 未发现 P0-P3 问题。

## 6. 优化建议
- 可维护性：当前权重、半衰期、窗口集中为具名常量，后续 v1.2/v1.3 可在有真实数据后校准。
- 性能/体验：本任务直接扫 90 天记录，符合当前数据量预期；若后续账单量明显增大，再考虑持久化聚合缓存。
- 可测试性：纯函数和 Default service 分层测试已经覆盖核心排序和过滤规则。

## 7. 风险与回归面
- 风险点：时间口径仍是最高风险点；本次用 `TimePolicy.editorDate` 并加跨午夜测试保护。
- 建议回归验证步骤：
  1. 新建/编辑 QuickEntry，确认快捷行随历史排序且不自动预选。
  2. 打开分类 picker，确认「常用」区出现且「全部」区仍保持原分类顺序。

## 8. 覆盖范围与假设
- 覆盖范围：本次未提交差异。
- 假设：任务 22 的 v1.1a UI 重构已在当前分支完成；本任务不处理 v1.2 预选和 margin 置信门槛。

## 本次落地记录（2026-06-03）
- `xcodebuild -project Tally.xcodeproj -scheme Tally -destination 'platform=iOS Simulator,name=iPhone 17' build`：`BUILD SUCCEEDED`
- `xcodebuild -project Tally.xcodeproj -scheme TallyTests -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:TallyTests/CategorySuggestionServiceTests -only-testing:TallyTests/QuickEntryViewModelTests`：`TEST SUCCEEDED`
- `git diff --check`：无 whitespace error

## 本轮 review 整改回应（2026-06-03）
- 已处理 `review/23_review_claude.md` 中指定的 3 项小幅整改：删除 `hourBucketTolerance` 使时段窗口精确回到文档定义的 `±1.5h`；补跨午夜窗口的远端反向断言；补 VM 层在 service 改变排序后仍能保持选中项置顶的测试。
- 未处理评审里的 P2 设计观察点：`dayRange` 双重过滤、timeAffinity 叠加近因、高频淹没时段信号均按本轮要求保留现状，留给 v1.2 数据校准。
- 本轮验证：`Tally` scheme build 通过；`CategorySuggestionServiceTests` + `QuickEntryViewModelTests` 指定测试通过。

## 本轮 Codex review 修复（2026-06-03）
- 已处理 Codex review 发现的 3 项：`QuickEntryViewModel.suggestedCategories` 不再在 getter 内触发 service/repo 查询，改为 `loadCategories()` 时缓存排序结果；任务文档里的跨午夜窗口示例已改为精确 `±1.5h` 口径；`StubCategorySuggestionService` 增加 `nonisolated init()`，消除默认注入触发的 Swift actor-isolation warning。
- 本轮验证：`Tally` scheme build 通过；`CategorySuggestionServiceTests` + `QuickEntryViewModelTests` 指定测试通过；`git diff --check` 通过。
