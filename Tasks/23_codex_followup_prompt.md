# Codex 跟进 Prompt — 任务 23 review 整改

> 用法：把「===PROMPT START===」到「===PROMPT END===」之间整段发给 codex。
> 这是任务 23（CategorySuggestionService）通过评审后的小幅整改，**只做下面列的 3 件事，不要扩大范围**。
> 评审全文见 `review/23_review_claude.md`。

===PROMPT START===

任务 23（CategorySuggestionService）已通过评审，现做一轮**小幅整改**。完整评审在 `review/23_review_claude.md`，本轮**只处理下面 3 项**，不要改动其他逻辑、不要重构、不要碰预选（那是 v1.2）。

## 改动 1：消除时段窗口的「文档 vs 实现」偏差（P3）

现状：`Tally/Services/CategorySuggestionService.swift` 里跨午夜判定是
```swift
circularHourDistance(...) <= Constants.timeWindowHours(1.5) + Constants.hourBucketTolerance(0.5)
```
实际窗口是 **±2.0h**，但 `Tasks/23_CategorySuggestionService.md` §4.3 写的是 **±1.5h**。二者不一致。

record 与 now 都是连续小时值（带分钟/秒的 `fractionalHour`），不是离散的整点桶，所以 `hourBucketTolerance` 这个「桶相交容差」并无必要。

**做法**：删掉 `hourBucketTolerance`，窗口判定直接用 `circularHourDistance(...) <= Constants.timeWindowHours`，让实际窗口精确等于文档的 ±1.5h。
- 若你认为 ±2.0h 才是更合理的产品行为、想保留容差，则**反过来改文档**（更新 §4.3 与 §4.1 的窗口描述为实际值），并在落地记录里说明理由。二选一，目标是消除偏差，不是两边都留。
- 默认倾向：删容差、回到精确 ±1.5h（更简单、与文档一致）。

## 改动 2：补「不该覆盖」的跨午夜反向断言（防 P3 回归）

现有 `testPureScoringWrapsTimeWindowAcrossMidnight` 只验证了「23 点窗口能覆盖到 0/1 点」，没验证「23 点窗口**不该**覆盖远处时段」。

**做法**：在 `TallyTests/CategorySuggestionServiceTests.swift` 新增一个用例，构造 now=23 点，给两类历史：
- 类 A：记录落在 23 点附近（窗口内，应计入 timeAffinity）；
- 类 B：记录落在 12 点左右（距 23 点的环绕距离约 11h，**远超**窗口，不应计入 timeAffinity）。
让两类的全局频率/近因尽量对等，断言「窗口内的类 A」排在「窗口外的类 B」之前。这样窗口宽度一旦被改宽（回归），该用例会失败。

## 改动 3：补 VM 层「真实 service 接入后选中项置顶」用例（填测试缺口）

现状：`QuickEntryViewModelTests` 里关于 `suggestedCategories` 的 3 个用例都用默认的 `StubCategorySuggestionService`（排序=输入序），测不到「真实 service 改变排序后，选中项置顶逻辑仍正确」。

**做法**：在 `TallyTests/QuickEntryViewModelTests.swift` 新增一个用例：
- 注入一个**会改变排序**的 `CategorySuggestionService` 测试替身（可在测试文件内定义一个简单 fake，返回与输入不同的顺序，例如逆序，或把某个指定 ID 排到最前）；`QuickEntryViewModel.init` 已支持 `suggestionService` 形参注入。
- 让候选分类数 > `QuickEntryLayout.suggestionRowLimit`，选中一个在 service 排序里排在**尾部**（会被 prefix 截掉）的分类。
- 断言 `suggestedCategories`：① 整体顺序遵循 service 的排序（前 N 项），② 被选中但本不在前 N 的分类被置顶到第一、且长度不超过 limit（即任务 22 已有的「选中置顶」逻辑在真实 service 下仍生效）。

## 明确不要做

- **不要**改 `dayRange` 的「实例方法取 records + 静态方法再过滤」结构——静态纯函数需要自洽的日期过滤，这是有意防御，不是 bug（评审 P2，标记为可接受现状）。
- **不要**给 timeAffinity 加近因衰减、不要调权重、不要碰「高频淹没时段」——那是 v1.2 用真实数据校准的事，本轮不动。
- **不要**碰预选 / margin / `defaultCategory()`。
- **不要**动任务 22 的 UI 代码。

## 验收门槛

```bash
xcodebuild -project Tally.xcodeproj -scheme Tally \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

xcodebuild -project Tally.xcodeproj -scheme TallyTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' test \
  -only-testing:TallyTests/CategorySuggestionServiceTests \
  -only-testing:TallyTests/QuickEntryViewModelTests
```
- 两 scheme 均通过。
- 新增 2 个用例全绿；原有用例（含 QuickEntryViewModelTests 13 个）不能挂。
- 若改动 1 选择删容差，确认原有跨午夜用例 `testPureScoringWrapsTimeWindowAcrossMidnight` 仍通过（0/1 点距 23 点环绕距离分别是 1h、2h —— ⚠️ 注意：1 点距 23 点是 2h，正好等于旧的 ±2.0 边界。删容差回到 ±1.5 后，1:00 的记录将落在窗口外，该用例可能失败）。**这是关键**：删容差前先检查现有用例的小时取值，必要时把测试数据从 1:00 调到 0:30 这类确在 ±1.5 内的值，或据此决定窗口取值。务必让「窗口定义、文档、测试」三者自洽。

## 收尾

- 在 `Tasks/23_CategorySuggestionService.md` 落地记录里追加本轮整改条目 + 最小验证结果。
- 在 `review/23_review.md`（你的自评）补一句本轮整改回应。
- 仍在 `feat/quick-entry-picker` 分支，不要合并 main、不要发版，是否 commit 听用户指示。

===PROMPT END===
