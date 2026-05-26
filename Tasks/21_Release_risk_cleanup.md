# 21 发布风险整改与逐步执行

## 目标

- 用一个总控任务文件管理本轮发布风险整改，覆盖删除策略、定时记账、导入刷新闭环、首页排序和导入写路径分层。
- 严格按阶段推进，每阶段都要有落地记录和最小验证结果，避免多问题并行导致回归难定位。
- 优先关闭当前已确认的发布风险，不在本轮扩展回收站等额外能力。

## 执行规则

- 本轮不做回收站能力，删除以永久删除为准。
- 历史 review 文档不回写，只修正会误导当前执行的活文档和新 task 文件。
- 每阶段结束必须补“本次落地记录（YYYY-MM-DD）”和最小验证结果。
- 执行顺序固定为：阶段 0 -> 阶段 1 -> 阶段 2 -> 阶段 3 -> 阶段 4。

## 阶段清单

- [x] 阶段 0：建立任务清单与执行顺序
- [x] 阶段 1：删除行为改为真实永久删除
- [x] 阶段 2：定时记账改为显式首次执行时间
- [x] 阶段 3：导入成功后的刷新闭环 + 首页分组排序修正
- [x] 阶段 4：导入写路径下沉回 Data 层

## 验收标准

- 当前 5 个问题全部关闭。
- `xcodebuild test` 全量通过。
- 任务文件中每阶段都有落地记录与验证结论。

## 本次落地记录

### 2026-04-12 阶段 0

- 已建立总控任务文件，固定执行顺序与阶段目标。
- 已锁定本轮默认策略：不做回收站，删除改为永久删除。
- 最小验证：任务文件已创建，阶段清单与执行规则齐全。

### 2026-04-12 阶段 1

- 已为 `BillRepository` 增加真实永久删除入口，并同步落到 `CoreDataBillRepository`、`MockBillRepository`、`InMemoryBillRepository`。
- 首页删除已切换到 `billRepository.delete(id:)`，不再写入 `deletedAt` / `trashUntil`。
- 已修正文档现状：当前版本删除为永久删除，回收站能力 deferred / 未启用。
- 最小验证：`xcodebuild test -project Tally.xcodeproj -scheme TallyTests -destination 'platform=iOS Simulator,id=8323F09A-7C0F-47BA-85F5-6FDA28BA9CFF' CODE_SIGNING_ALLOWED=NO -only-testing:TallyTests/HomeViewModelTests` 通过。

### 2026-04-12 阶段 2

- 定时记账表单已改为显式“首次执行时间”，日期和时间在本地 sheet 内分别选择，不扩展通用日期组件。
- `RecurringBillFormViewModel` 已接入 `nowProvider`，保存前强校验 `firstDate > now`，过去时刻会明确报错，不再隐式顺延到下一天或下个周期。
- 默认首次执行时间已改为“下一整点”，并在保存时统一归一化到分钟粒度，移除不可见秒数。
- 最小验证：`xcodebuild test -project Tally.xcodeproj -scheme TallyTests -destination 'platform=iOS Simulator,id=8323F09A-7C0F-47BA-85F5-6FDA28BA9CFF' CODE_SIGNING_ALLOWED=NO -only-testing:TallyTests/RecurringBillFormViewModelTests -only-testing:TallyTests/DefaultRecurringServiceTests` 通过。

### 2026-04-12 阶段 3

- 导入成功后已补 `Notification.Name.billDidChange` 广播，失败路径保持不广播。
- `DefaultImportExportService` 的 CSV / 备份导入成功分支都已统一刷新 Widget 快照。
- 首页分组排序已改为按 `occurredLocalDate` 倒序，组内条目仍按 `occurredAtUTC` 倒序。
- 最小验证：`xcodebuild test -project Tally.xcodeproj -scheme TallyTests -destination 'platform=iOS Simulator,id=8323F09A-7C0F-47BA-85F5-6FDA28BA9CFF' CODE_SIGNING_ALLOWED=NO -only-testing:TallyTests/HomeViewModelTests -only-testing:TallyTests/ImportExportViewModelTests -only-testing:TallyTests/CSVImportPipelineTests` 通过。

### 2026-04-12 阶段 4

- 已新增 `ImportWriteRepository` 协议和共享导入 DTO，备份导入写入职责已从 `DefaultImportExportService` 下沉到 Data 层。
- 已新增 `CoreDataImportWriteRepository` 接管 child context、批量写入、事务提交与失败回滚；`DefaultImportExportService` 只保留解析、预检和调用仓储。
- `DIContainer` 已改为注入 `importWriteRepository`，备份导入无环境时明确返回 `导入环境不可用`。
- 最小验证：`xcodebuild test -project Tally.xcodeproj -scheme TallyTests -destination 'platform=iOS Simulator,id=8323F09A-7C0F-47BA-85F5-6FDA28BA9CFF' CODE_SIGNING_ALLOWED=NO -only-testing:TallyTests/CoreDataImportWriteRepositoryTests -only-testing:TallyTests/CSVImportPipelineTests` 通过。
