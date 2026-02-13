# 16-20 导入导出任务深度评审（含本轮落地）

## 1. 总体结论
- 结论：**通过（有后续优化项）**
- 阻断项：无 P0
- 一句话总结：16-20 的导入导出闭环已可用，关键稳定性与回归测试已补齐；当前主要问题集中在 `DefaultImportExportService` 体量过大，需继续按“编排层/规则层/写入层”拆分。

## 2. 任务验收对照（16-20）
- Task 16（架构与入口）：✅  
  证据：`JustOne/Features/Settings/ImportExportView.swift`、`JustOne/Services/ImportExport/ImportExportService.swift`、`JustOne/App/DIContainer.swift`
- Task 17（导出 CSV/JSON）：✅  
  证据：`JustOne/Services/ImportExport/DefaultImportExportService.swift`
- Task 18（导入 JSON 预检+执行）：✅  
  证据：`JustOne/Services/ImportExport/DefaultImportExportService.swift`
- Task 19（导入 CSV）：✅  
  证据：`JustOne/Services/ImportExport/CSVImportPipeline.swift`
- Task 20（稳定性与回归）：✅（本轮继续增强）  
  证据：`JustOneTests/CSVImportPipelineTests.swift`、`Tasks/20_Import_export_stability_and_regression.md`

## 3. 本轮已执行的抽离与封装
- 已抽离 CSV 解析与校验组件：`JustOne/Services/ImportExport/CSVImportPipeline.swift`
- 已封装 ViewModel 导入流程：`JustOne/Features/Settings/ImportExportViewModel.swift:38-163`
- 已收紧导入环境边界：`JustOne/Services/ImportExport/DefaultImportExportService.swift:112-119`
- 已补充关键回归测试：`JustOneTests/CSVImportPipelineTests.swift:224-252`
- 已补充时区稳定细节：`JustOne/Services/ImportExport/CSVImportPipeline.swift:57-64`

## 4. 关键问题清单（按严重度）

### [P1][Rigidity/Opacity] ImportExport 服务仍是“巨石文件”
- 位置：`JustOne/Services/ImportExport/DefaultImportExportService.swift:4-876`
- 影响：
  - 导出、CSV 导入、JSON 导入校验、CoreData 写入都在单文件，变更耦合高。
  - 任何新增规则都会扩大回归面，review 成本高。
- 最小修复建议：
  - 第一步：拆 `BackupImportValidator`（纯校验）和 `BackupImportWriter`（仅写库）。
  - 第二步：`DefaultImportExportService` 仅保留编排与错误映射。

### [P2][Duplication] ImportExportView 仍有双份对话框绑定逻辑
- 位置：`JustOne/Features/Settings/ImportExportView.swift:85-126`
- 影响：
  - 备份/CSV 的 `confirmationDialog` 模板重复，未来新增导入类型会继续复制。
- 最小修复建议：
  - 提取一个私有 `importPreviewDialog(...)` 视图修饰封装，参数化 `isPresented/message/confirm/cancel`。

### [P2][Fragility] 备份导入写库缺少“错误类型分层”测试
- 位置：`JustOne/Services/ImportExport/DefaultImportExportService.swift:492-567`
- 影响：
  - 当前测试覆盖了 CSV 和部分 JSON 预检，但“写库失败后回滚”没有自动化验证，后续容易回归。
- 最小修复建议：
  - 增加集成测试：构造写库中途失败，断言 parentContext 无脏提交。

### [P3][Data Clump] 预检统计与结果展示文案分散
- 位置：`JustOne/Features/Settings/ImportExportViewModel.swift:165-178`、`JustOne/Features/Settings/ImportExportViewModel.swift:261-274`
- 影响：
  - 同一统计字段在“预检文案”和“结果弹窗”各自拼接，后续本地化会重复改动。
- 最小修复建议：
  - 提取 `ImportReportFormatter`（纯文本格式化），ViewModel 仅传数据。

## 5. 本轮修复合理性评估
- 变更方向正确：
  - 从“功能可用”转向“稳定性可回归”，符合 Task 20 目标。
- 复杂度控制合理：
  - 先做最小抽离（CSV pipeline）和最小封装（ViewModel 导入统一流程），未做高风险大重构。
- 回归保障到位：
  - 新增/更新测试后多次 `xcodebuild test` 通过。

## 6. 风险与回归面
- 风险点 1：CSV 跨时区二次导入仍有天然信息损失（模板字段不足）。
- 风险点 2：JSON 导入写库流程仍集中在单文件，未来规则膨胀可能引发连锁修改。
- 风险点 3：UI 层导入对话框重复逻辑仍在，未来扩展导入类型时容易产生行为不一致。

## 7. 建议的下一步（按优先级）
1. 拆分 `DefaultImportExportService`：先拆 `BackupImportValidator/Writer`，控制文件体量和耦合。
2. 增加 JSON 写库事务回滚测试，覆盖“中途失败不落库”。
3. 抽取 ImportPreview 对话框公共封装，减少视图层重复绑定代码。

## 8. 本轮验证记录
- 命令：`xcodebuild -project JustOne.xcodeproj -scheme JustOne -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' -only-testing:JustOneTests/CSVImportPipelineTests test`
- 结果：`TEST SUCCEEDED`
- 覆盖重点：
  - CSV BOM/列头/行级校验/重复判定/10k 性能
  - 备份导入重复 ID 冲突
  - 无 `managedObjectContext` 的导入保护
