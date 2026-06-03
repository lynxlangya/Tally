# 任务 23 代码评审（Claude 独立第二意见）

> 与 codex 自评 `review/23_review.md` 并列。本文是独立复核，重点找 codex 自测/自评未覆盖的盲区。
> 评审对象：`feat/quick-entry-picker` 分支上任务 23 的未提交改动。

## 1. 总体结论

- 结论：**通过**（可合入本系列分支）。
- 阻断项：无（0 个 P0/P1）。
- 一句话总结：实现质量高——纯函数分层干净、过滤完整、最危险的时间口径坑成功规避、测试覆盖到位且未偷改测试替身。有 4 个非阻断观察点，其中 2 个 P2 建议 v1.2 一并处理。

## 2. 验证过的「做对了」（独立确认，非照抄自评）

- **时间口径坑规避正确**：`occurredAtUTC` 经 `TimePolicy.editorDate` 还原本地 wall-clock 再取小时（service:88）；`now` 与 record 的 `fractionalHour` 同走 `Calendar.current`（service:155），口径一致，不会跨时区漂移。这是本任务最高风险点，过了。
- **recency 用绝对时间戳差**（`now.timeIntervalSince(occurredAtUTC)`，service:100）：两个瞬时相减与时区无关，正确——没有错误地去用本地小时算天数。
- **排序确定性**：score 并列回退 `fallbackRank`（按 sortOrder→name→uuid 的稳定序，service:121-128/132-142），杜绝字典无序导致的排序抖动。三级 tiebreak 比文档要求的更稳。
- **过滤完整**：type / 90 天 / isFromRecurring / nil / 未分类 / 已删分类（candidateIDs 交集）全覆盖（service:60-71），且测试 `testDefaultServiceFiltersHistoryAndUsesRepositoryRange` 把这 5 类干扰数据一次性验证。
- **未偷改测试替身**：`TallyTests/TestDoubles.swift` diff 为空，`InMemoryBillRepository` 的 `init(records:)`/`listError`/dayKey 过滤都是既有能力。干净。
- **注入链完整**：DI live/mock 双工厂、3 个调用点、2 个 Home Preview、BillsList Preview 全部补齐，无遗漏（编译已过即证）。

## 3. 观察点清单（无 P0/P1）

### [P2] `dayRange` 重复计算 + 双重过滤 — service:28-44 / 46-71
实例方法 `orderedCategoryIDs` 先用 `dayRange(endingAt:now)` 拿 records，转入静态方法后**又调一次** `dayRange` 并对 `occurredLocalDate` 再过滤一遍（service:58、62-63）。
- 影响：轻微——repo 已按 dayKey 过滤过，静态方法里的日期再过滤对「实例入口」是冗余计算（虽然对「纯函数入口」是必要的防御）。两次 `dayRange` 也各建一次 Calendar。
- 非 bug，但语义重复。建议：静态方法保留日期过滤（纯函数自洽需要），实例方法不必关心；可接受现状，记录即可。

### [P2] 时段切片用「计数」未做近因加权 — service:95-98
`timeAffinity` 是「落在当前小时窗口内的笔数 / 窗口内总笔数」，纯计数。若用户**早期**频繁在某时段记 A、**近期**改记 B，timeAffinity 仍可能偏向 A（recency 维度才修正）。
- 影响：设计取舍，非错误——文档 §4.3 本就定义为计数。但「时段 × 近因」未交叉，时段维度对生活阶段变化反应偏慢。
- 建议：v1.2 校准时考虑给 timeAffinity 也叠加衰减；本任务范围内不改。

### [P3] `hourBucketTolerance = 0.5` 让窗口实际是 ±2.0h — service:17/95
跨午夜判定用 `circularHourDistance <= timeWindowHours(1.5) + hourBucketTolerance(0.5)`，即实际窗口 **±2.0h**，比文档写的 ±1.5h 宽。
- 影响：行为与文档轻微不符（23 点会覆盖到 21:00–次日 1:00）。注释说是「按小时桶相交」留容差，意图合理，但 0.5 的容差对「分钟级精确时间戳」其实没必要——record/now 都是连续小时值，不是离散桶。
- 建议：要么去掉 tolerance（窗口回到精确 ±1.5h），要么更新文档说明实际窗口。二选一，消除文档/实现偏差。

### [P3] 时段权重最高但最易被高频淹没 — 设计观察
`wTime=0.5` 名义最高，但 `timeAffinity` 归一化分母是「窗口内总笔数」，而 `frequency` 分母是「全部 90 天笔数」。当某分类全天高频时，它在任何时段窗口内也占多数 → timeAffinity 和 frequency 双高，时段信号难以让「时段专属但低频」的分类（如只在早上的咖啡）翻盘。
- 影响：算法倾向高频分类，时段个性化效果可能弱于预期。属调参问题，v1.2 有真实数据后观测。
- 无需本轮改动。

## 4. 测试覆盖评估

覆盖良好：时段切片、近因 tiebreak、跨午夜、冷启动回退、score 并列回退、过滤+repo 端到端、抛错回退——7 个用例打到了关键路径。

**缺口（建议 v1.2 补，非阻断）**：
- 没有「VM 层」用例验证 `suggestedCategories` 接 service 后「选中项置顶」与新排序的**交互**（任务 22 那 3 个用例用的是 StubService，排序=输入序，测不到真实 service 接入后的置顶行为）。建议加一个：注入会改序的 service + 选中一个排在尾部的分类 → 断言它被置顶且其余按 service 序。
- 跨午夜测试只验证了 23 点→0/1 点「能覆盖」，没验证「不该覆盖的」（如 23 点不应把 12 点的记录算进窗口）——建议加反向断言，防窗口过宽回归（呼应 P3）。

## 5. 风险与回归面

- 时段窗口实际 ±2h（P3）：用户在边界时段记账时，建议可能比预期更「泛」。
- 高频淹没时段信号（P3 设计）：上线后需观测时段个性化是否真的生效。
- 其余无回归面——纯增量，记账主流程逻辑未动，抛错全回退。

## 6. 覆盖范围与假设

- 覆盖范围：任务 23 未提交差异（service + DI + QuickEntry 接入 + 测试）。**未独立重跑** xcodebuild（codex 自评已记录 BUILD/TEST SUCCEEDED，本评审基于代码静态复核 + 接口交叉验证）。
- 假设：任务 22 v1.1a 已在本分支；预选/margin 属 v1.2 不在范围。

## 7. 给用户的处置建议

- **可合入**。4 个观察点无一阻断。
- **建议让 codex 顺手处理的**：P3 窗口 ±1.5h vs ±2.0h 的文档/实现对齐（一行常量或一句文档），以及第 4 节两个测试缺口——成本低、防回归。
- **留给 v1.2 的**：P2 时段×近因交叉、P3 高频淹没调参——都要真实数据，现在动是过早优化。
