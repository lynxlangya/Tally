# 20 导入导出稳定性与回归验证

## 目标

- 对导入导出功能做性能、稳定性、边界条件与回归验证。
- 确保功能在真实用户数据规模下可用，不引入历史账单分组漂移与统计错误。
- 为后续增强（加密备份、云同步）建立可靠基线。

## 开发步骤

1. 性能与大数据验证
   - 构造 1k / 5k / 10k 账单数据集。
   - 测试导出耗时、导入耗时、UI 卡顿情况。
   - 优化点：
     - 分批写入
     - 后台队列解析
     - 主线程仅做状态更新

2. 时区与日期口径回归
   - 验证导入后 `occurredLocalDate` 不漂移。
   - 切换系统时区后，历史分组与统计不变化。
   - 周/月/年统计结果与导入前一致。

3. 数据完整性校验
   - 导出前后对比：
     - 账单总数
     - 分类总数
     - 定时记账总数
   - 抽样校验金额、类型、备注、日期字段一致性。

4. 异常场景处理
   - 文件损坏
   - schemaVersion 不兼容
   - 缺列/空列
   - 超大备注/非法金额
   - 空文件

5. 测试与文档
   - 增加单元测试（解析器、校验器、重复判定、nextFireDate 无关不回归）。
   - 增加集成测试（导入导出闭环）。
   - 在任务文档中记录已知限制与后续计划。

## 验收标准

- ✅ 10k 级账单导入导出可完成且无崩溃。
- ✅ 导入导出前后关键统计一致，误差为 0。
- ✅ 时区切换后历史分组不漂移。
- ✅ 异常文件可被正确拦截并给出用户可理解提示。
- ✅ 关键逻辑有测试覆盖，后续改动可回归验证。

## 本次落地记录（2026-02-13）

1. 稳定性抽离
   - 已将 CSV 解析与校验逻辑从 `DefaultImportExportService` 抽离到独立组件：
     - `Tally/Services/ImportExport/CSVImportPipeline.swift`
   - `DefaultImportExportService` 改为编排职责：
     - 文件读取
     - 调用 pipeline 预检
     - 执行导入写库

2. 回归测试补齐
   - 新增测试文件：`TallyTests/CSVImportPipelineTests.swift`
   - 覆盖点：
     - UTF-8 BOM 解析
     - 列头不匹配拦截
     - 行级校验（类型/金额）
     - 重复判定（同金额+分类+occurredLocalDate）
     - 服务层 CSV 预检 + 导入闭环
     - 10k 行性能基线（`measure`）

3. 本地执行结果
   - `xcodebuild test` 结果：`TEST SUCCEEDED`
   - 新增性能用例 `testValidatePerformanceForTenThousandRows` 在当前机器单次约 `6.818s`（Debug，模拟器）

4. 已知限制（保留到后续任务）
   - CSV 模板不包含 `occurredLocalDate` 与原始时区快照，跨时区二次导入无法做到 100% 分组还原（JSON 备份可完整还原）。
   - 后续如需跨时区强一致，需扩展 CSV 模板字段（新增本地日键/时区列）。

5. 本轮补充优化（2026-02-13 第二次）
   - 修复导入环境边界：
     - `importBackup` 在无 `managedObjectContext` 时明确失败，不再走弱一致回退路径（防止跨仓库写入策略不一致）。
   - ViewModel 去重封装：
     - `ImportExportViewModel` 将「备份/CSV」两套预检与确认导入流程合并为统一私有流程，减少重复分支与回归面。
   - 时区稳定性细节：
     - CSV 本地时间解析器从 `TimeZone.current` 调整为 `TimeZone.autoupdatingCurrent`，降低运行期系统时区切换后的偏差风险。
   - 测试补充：
     - 新增 `testImportBackupRequiresManagedObjectContext`，锁定导入环境保护行为。
