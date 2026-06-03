# 任务 22：快速记账分类选择重构（交互 + 智能默认）

> 状态：设计阶段（v1.0 正在 App Store 审核，本任务不进 v1.0）
> 关联：本任务的 v1.0 基线「记住上次分类」已落地，见文末「已落地基线」。

## 0. 背景与现状

快速记账（`Tally/Features/QuickEntry/`）是「计算器优先」布局：金额是绝对主角（巨字号 + 闪烁光标），分类只是顶部一个小 chip（`QuickEntryView.swift` `categoryChip`）。

历史问题链：
1. **默认强选第一个**：旧逻辑 `selectedCategory = categories.first`，而 seed 里「晚餐」`sortOrder=1` 排第一（`Tally/Data/CoreDataSeedService.swift:179`），导致「每次打开都自动选中晚餐」。已由基线修复（改为 last-used，首次不预选）。
2. **改分类要走 modal 套 modal**：点顶部 chip → 弹第二层 `CategoryPickerSheet` → 找 → 选 → 弹回。每次换分类都走一遍往返。
3. **分类在最顶、拇指在最底**：快速记账时拇指停在键盘，改分类却要够到屏幕最上方，对「求快」工具是每笔都在交的税。
4. **单 chip 看不见备选**：不点开永远不知道还有什么、选中是否正确。

附带可回收资源：键盘右列 `−` / `+`（`QuickEntryKeypad.swift:29,34`）与顶部「支出/收入」开关功能重复（`testPlusAndMinusToggleBillTypeWithoutArithmetic` 已证实不做运算）。本任务**不动**它，仅记录。

## 1. 目标 / 非目标

**目标**
- 干掉「改分类必走第二层 sheet」的往返：常见分类内联可选，零 modal。
- 把分类选择下移到拇指可达区（贴键盘上方）。
- 引入「智能默认」：基于用户自己的历史（时段切片 + 近因 + 频率）排序与预选，错了不伤手。

**非目标（本轮明确不做）**
- 不改键盘 `−/+` 的现有行为（发布在审，少动肌肉记忆）。
- 不做备注文本 NLP（"星巴克"→咖啡）——太重，备注常最后才填。
- 不引入通用「平均用户」时段硬映射作为主算法（仅作冷启动兜底，见 §4.4）。
- 不改 `CategoryPickerSheet` 的全量分类**数据来源**（仍是全量 `sortOrder`），但本轮会把它的栅格分「常用 / 全部」两层（见 §9.4）。

## 2. 已定决策（来自本轮探讨）

| 维度 | 决策 | 理由 |
|---|---|---|
| 优化范围 | **预选 + 快捷行排序** 双管齐下 | 排序容错 > 预选；猜错也能一眼一点 |
| 冷启动 | **last-used 为主** → 时段表兜底 → 不预选 | 零成本，先积累真实数据再上算法 |
| 布局 | **方案 C：横向智能行 + 拇指区** | 保极简「计算器」气质 + 人机工程最优 |
| 全量区 | **永远固定 `sortOrder`**，不参与重排 | 守住空间肌肉记忆 |

## 3. 交互设计：方案 C（横向智能行 + 拇指区）

### 3.1 布局

```
取消        支出 收入            +
              −¥0 |
         📅 6月2日   备注
 ●零食  早餐  咖啡  交通   ⋯更多   ← 横向 ScrollView，贴键盘上方
   1    2    3    ⌫
   4    5    6    📅
   7    8    9    −
   .    0    00   +
            记一笔
```

把现在顶部的单 chip 移除，分类改为键盘正上方的一条横向行。分类 / 键盘 / 记一笔全压在底部三分之一，一根拇指走完全程。

### 3.2 快捷行规格

- **每项**：复用现成的 `QuickEntryCategoryItem`（`QuickEntry/QuickEntryCategoryItem.swift`，目前无人使用，正好接管），加选中态（实心 tile + 描边环，照搬 `CategoryPickerSheet.categoryButton` 的 `active` 样式）。
- **数量**：算法吐前 **5–6** 个高频；若当前选中项不在前列，**强制插到第一个**并高亮——保证「当前选中永远可见」。
- **「更多」**：固定在**最右**、不随滚动移走。点击 → 弹现有 `CategoryPickerSheet`（全量栅格）。
- **横滑提示**：最后一项露半个 + 右缘渐隐遮罩，暗示可滑。（横向方案唯一体验风险点，**必做**，否则用户不知道还能滑。）
- **滚动回位**：从「更多」选了长尾分类（如「医疗」）回来后，用 `ScrollViewReader` + `scrollTo(selectedID)` 把它滚到可见。不做会出现「选了却看不到选中」的困惑。

### 3.3 全量区（「更多」展开后）

`CategoryPickerSheet` 栅格**本轮一步到位分两层**（§9.4 决议）：
- 顶部「常用」区：算法高频，动态，3–8 个。
- 下方「全部」区：永远固定 `sortOrder`，肌肉记忆锚点。
- 两层共用同一选中态；「常用」为空时（冷启动）整层隐藏，只显示「全部」。

## 4. 智能默认算法

### 4.1 核心思想

**时段是「特征」不是「规则」**。不写「18 点→晚餐」，而是问「这个用户在 18 点前后历史上最常记什么」。时段用来切片**用户自己的**历史。

### 4.2 打分函数（伪代码）

```
score(c, now) = w_time    · timeAffinity(c, now)
              + w_recency · recency(c, now)
              + w_freq    · globalFrequency(c)
              + w_last    · (c == lastUsed(type) ? 1 : 0)
```

数据范围统一：**同 `BillType`、最近 90 天、排除「未分类」、排除 `isFromRecurring`**（定时账单是自动生成，不污染建议——**已决议排除，见 §9.1**）。

- `timeAffinity`：该分类在「当前本地小时 ±1.5h 窗口」内的历史计数（跨午夜环绕处理），归一化。
- `recency`：指数时间衰减计数，半衰期约 7–14 天（反映当前生活阶段，如最近装修则「建材」靠前）。
- `globalFrequency`：90 天总计数，归一化（兜底）。
- `w_last`：上次用过的那个给一个加成。

权重初值给合理默认，**v1.2 有真实数据后再调参**，现在不拍死具体数值（无数据支撑的精度是假精度）。

### 4.3 预选的置信门槛（关键）

预选**不用绝对分**，用 **margin**：`score(top1) / score(top2) > 阈值`（初值约 1.5）才算「有把握」并预选；否则降级到 last-used；再否则**不预选**。两个分类咬得紧时宁可不猜，让用户点。阈值同样 v1.2 调。

### 4.4 冷启动降级链

历史不足（如 <20 笔）时：
1. 有 last-used → 用它（基线已实现，零成本）。
2. 否则 → 通用时段表兜底（早 6–8 咖啡 / 8–9 早餐 / 11–12 午餐 / 18–19 晚餐）——它从「主算法」降级为「冷启动 fallback」，各得其所。
3. 否则 → 不预选。

### 4.5 本地小时还原（口径，勿踩坑）

特征里的「小时」必须从 `occurredAtUTC + tzOffset` 还原本地 wall-clock 小时，**不能直接对 UTC 取 hour**。沿用 `TimePolicy` 的还原口径（参考 `TimePolicy.editorDate(from:tzId:tzOffset:)`），与全项目「分组/筛选以 `occurredLocalDate` 为准」的时间策略保持一致。

## 5. 架构落点（符合 ArchitectureRules：Features → Services → Repositories → Data）

- **新增 `CategorySuggestionService` 协议 + 默认实现**，放 `Tally/Services/`。依赖 `BillRepository`（Services → Repositories，方向合法）。
  - 接口（草案）：`func suggest(type: BillType, at now: Date, available: [CategoryRecord]) -> CategorySuggestion`
  - `CategorySuggestion = (ordered: [UUID], preselect: UUID?)`
- **打分核心做成纯函数**：输入「账单数组 + 候选分类 + now」，输出分数；不碰 IO，便于固化时间单测。
- **DI**：`DIContainer` 创建并注入；`QuickEntryViewModel` 仅持有协议、在 `loadCategories()` 里调用，**不得**自己 `init` 任何 repo/service，**不得** `import CoreData`。
- **性能**：只扫最近 90 天（`BillRepository.list(fromDayKey:toDayKey:type:)`），内存内计数。个人记账数据量小，绰绰有余；后续可演进为增量计数表（非本任务）。
- VM 现有的 `defaultCategory()`（基线新增）将由 service 结果替代/包裹。

## 6. 分阶段与验收 checklist

### v1.1a — UI 重构（纯交互，排序先用 last-used + 固定 sortOrder）
- [x] 顶部单 chip 移除，新增键盘上方横向快捷行（复用 `QuickEntryCategoryItem` + 选中态）
- [x] 「更多」固定最右，点击弹 `CategoryPickerSheet`
- [x] `CategoryPickerSheet` 组件支持「常用 / 全部」两层（§3.3，常用为空时整层隐藏）；**v1.1a 调用点暂不传 `frequentCategories`，picker 实际呈现单层「全部」**——见下方手动验证发现
- [x] 空状态占位改「请选择分类」（复用 `select_category`），不再显示「未分类」（先于本轮由用户/codex 改入 `categoryChip`，本轮 chip 移除后该语义由空快捷行 + 置灰保存键承载）
- [x] 横滑提示（右缘渐隐 `mask` + 尾部 padding 露出半个）
- [x] `ScrollViewReader` 回位：选中项始终可见（`onChange(selectedCategoryID)` → `scrollTo(.center)`）
- [x] 当前选中项不在前列时强制插到第一并高亮（`suggestedCategories`）
- [x] sheet 高度 / 间距适配（`QuickEntryLayout` 加 9 个常量，无散落魔法值）
- [x] VM/Feature 层无 `import CoreData`，架构边界干净
- [x] 现有 `QuickEntryViewModelTests` 全绿，键盘 `−/+` 行为不变

### v1.1b — 算法接管排序
- [ ] 新增 `CategorySuggestionService` 协议 + 默认实现 + DI 注入
- [ ] 打分纯函数：时段切片 + 近因衰减 + 全局频率，可注入 `now`
- [ ] 快捷行 `ordered` 由 service 驱动
- [ ] 本地小时还原口径正确（从 `occurredAtUTC + tzOffset`，非 UTC）
- [ ] 90 天窗口、排除未分类 / 定时账单（按 §9 结论）
- [ ] 纯函数单测：固定 now + 合成账单 → 期望排序；service 用 `InMemoryBillRepository` 测

### v1.2 — 预选 + 置信门槛
- [ ] 打分结果喂 `preselect`，margin 门槛控制「没把握不预选」
- [ ] 门槛不达标时降级 last-used → 不预选
- [ ] 用真实/合成数据校准 `w_*` 与 margin 阈值
- [ ] （可选）本地统计「预选被接受 vs 被改」用于量化效果

## 7. 风险与回归面

- **肌肉记忆**：全量区必须固定 sortOrder，只有快捷行动态；违反会让高频操作「越优化越慢」。
- **横向滚动可发现性**：无提示则等于隐藏分类。
- **时间口径**：本地小时还原错误会让时段特征整体偏移（跨时区 / 跨午夜）。
- **定时账单污染**：`isFromRecurring` 若计入会把自动账单顶到建议前列。
- **空状态语义**：未选中时分类区的占位需与「真记成未分类」区分（见 §9）。
- **发布节奏**：v1.0 审核中，本任务整体不进 v1.0，避免审核期改动核心录入流。

## 8. 测试计划

- 打分纯函数：合成 `[BillRecord]` + 固定 `now`，断言 `ordered` 顺序与 `preselect`（含 margin 边界、冷启动降级、跨午夜窗口）。
- Service：`InMemoryBillRepository` 注入历史，验证端到端建议。
- VM：沿用 `await MainActor.run { }` 范式 + `nowProvider` 注入；覆盖「选中项强制可见」「切收支取对应类型建议」「无历史不预选」。
- 手动回归：iPhone 17 模拟器跑录入流，确认拇指可达、横滑提示、「更多」兜底、键盘 `−/+` 未受影响。

## 9. 决议（2026-06-02，用户已拍板）

1. **定时账单 → 排除**。`isFromRecurring=true` 不计入建议打分（房租等自动账单不顶到前列）。落到 §4.2 数据范围。
2. **空状态占位 → 改**。未选中（`selectedCategory==nil`）时分类区显示「请选择分类」引导态，不再回退显示「未分类」。复用已存在的本地化 key `select_category`（中「请选择分类」/ 英「Select a category」，`TallyLocalization.swift:566/368`），零新增文案。**时机见下方「§9.2 时机判断」。**
3. **键盘 `−/+` → 本任务不动**。维持现状，不另开回收任务（至少本轮不排期）。
4. **全量区 → 一步到位分两层**。`CategoryPickerSheet` 本轮即实现「常用 / 全部」分层，不留单层过渡。落到 §3.3 与 §6 v1.1a checklist。

### §9.2 发布依赖：基线（首次不预选）与空状态文案必须捆绑（已澄清）

**关键事实（2026-06-02 用户澄清）**：当前在审的 v1.0 包是**旧逻辑**（`selectedCategory = categories.first`，打开即预选第一个、可直接存），**不含**基线的 last-used / 首次不预选改动。因此：

- 在审包**不存在**「未分类 + 置灰保存键」空状态问题，审核员撞不到，**无被拒风险，在审包不需任何改动**。
- 基线（last-used + 首次不预选）目前**仅在本地工作区，未进任何已发布/在审包**。

**由此得到一条捆绑约束**：
> 「首次不预选」（基线）一旦进入某个发布版本，首次打开就会 `selectedCategory=nil`；若该版本未同时修好空状态文案，就会暴露「未分类 chip + 置灰保存键」的伪 bug。
> **所以 #2 空状态文案不是独立优化项，而是基线的强制配套——基线随哪个版本发，#2 就必须同版本一起发。** 二者拆开 = 自造 bug。

落地节奏：
- **在审 v1.0**：旧逻辑，无空状态问题 → **不动，等审核结果**。
- **下次发版（v1.1 或 v1.0.x 补丁，取决于审核结果）**：基线 last-used + #2 空状态文案**捆绑出**。#2 在 §6 中归入 v1.1a，但其与基线的绑定关系高于阶段划分——若先发补丁，二者也须同行。

---

## 已落地基线（2026-05-30）— 记住上次分类（v1.0 内）

- 新增 `Tally/Core/Utilities/LastUsedCategoryStore.swift`（static enum + UserDefaults，照搬 `ProfileIdentityStore` 范式，收/支各存一 key，`defaults` 可注入便于测试隔离）。
- `QuickEntryViewModel`：`categories.first` → `defaultCategory()`（取 last-used，编辑模式 / 找不到则 nil 不预选）；save 成功后回写 last-used（仅新建分支）。
- `QuickEntryViewModelTests`：setUp/tearDown 隔离独立 suite；改 1 旧用例 + 加 5 新用例（首次不预选 / save 后回填 / 收支独立 / 上次分类被删回退 nil）。
- 最小验证：`xcodebuild ... -only-testing:TallyTests/QuickEntryViewModelTests` → `** TEST SUCCEEDED **`，10/10 通过（含新增 5 个）；两个 target 均编译通过。

## 本次落地记录（2026-06-02）— v1.1a UI 重构

分支：`feat/quick-entry-picker`（从 main 切出，基线 `f8522d7` 已在底下）。

改动文件（7 改 1 新增）：
- `QuickEntryLayout.swift`：+9 个常量（横向行 tile/间距/limit/渐隐宽 + picker 分区间距）。
- `QuickEntryCategoryItem.swift`：重写为带选中态的快捷行项（此前无人使用），选中 = `.solid` tile + 描边环。
- `QuickEntrySuggestionRow.swift`（新增）：键盘上方横向行。横滑区复用 `QuickEntryCategoryItem` + 右缘 `mask` 渐隐 + `ScrollViewReader` 回位；「更多」按钮固定最右通往全量 sheet。
- `QuickEntryViewModel.swift`：新增 `suggestedCategories` 计算属性——取 `categories` 前 `suggestionRowLimit`(=6)，并保证当前选中项可见（超限时挤到第一、不破坏未超限时的 sortOrder 原位）。v1.1b 将由 `CategorySuggestionService` 替换排序来源，「保证可见」逻辑不变。
- `QuickEntryView.swift`：移除顶部 `categoryChip`，把横向行放到键盘上方；连带清理死代码 `categoryColor`/`QuickEntryChipButtonStyle`（净 −68 行）。
- `CategoryPickerSheet.swift`：栅格分「常用（`frequentCategories`，动态）/ 全部（固定 `sortOrder`）」两层；`frequentCategories` 默认空 → 冷启动 / `selectionOnly` 时整层隐藏，向后兼容。主记账流传 `viewModel.suggestedCategories`。
- `TallyLocalization.swift`：+2 key `frequent_categories`(常用/Frequent)、`all_categories`(全部/All)。
- `QuickEntryViewModelTests.swift`：+3 用例（前 N 截断、选中超限强制可见、选中在范围内不重排守肌肉记忆）。

最小验证：
- `xcodebuild ... -scheme Tally build` → `** BUILD SUCCEEDED **`（含 widget extension，新文件经 `PBXFileSystemSynchronizedRootGroup` 自动纳入，无 error/warning）。
- `xcodebuild ... -only-testing:TallyTests/QuickEntryViewModelTests test` → `** TEST SUCCEEDED **`，**13/13** 通过（基线 10 + 新增 3）。

手动验证（iPhone 17 模拟器，2026-06-02）：
- 横向行布局、拇指可达、「更多」固定最右 ✓
- 首次无历史 → 不预选、保存键置灰 ✓
- 点分类 → 选中态（实心红 tile + 描边环，放大确认渲染质量）✓
- 输金额 → 保存键激活 → 记一笔保存成功回首页、首页数据正确 ✓
- 重开记账 → last-used 生效（默认选中上次「晚餐」，非写死）✓
- 「更多」→ 全量 picker ✓

手动验证发现的体验瑕疵 + 处置：
- **全量 picker「常用 / 全部」两区开头重复**：v1.1a 阶段「常用」= `suggestedCategories` = `sortOrder` 前 6，与「全部」开头完全一致（晚餐/午餐/早餐/咖啡/房租/水电 各出现两次），视觉冗余。
- **决议（用户拍板）**：v1.1a 的 picker 先回**单层「全部」**——调用点不传 `frequentCategories`（组件两层能力保留，默认空→隐藏常用区，代码无需回退）。常用区留到 v1.1b 由算法点亮（届时「常用」由真实频率/时段驱动，不再等于 sortOrder 前缀，重复自然消失）。
- 已改 `QuickEntryView.swift` `.tallySheet` 调用点 + 重新构建（`BUILD SUCCEEDED`）+ 重装模拟器复验：picker 现为干净单层全量列表，无重复。

未做 / 遗留：
- 横滑右缘渐隐 + `ScrollViewReader` 回位：首屏分类数（4 个）未溢出，这两条仅在分类溢出时触发，本次未在 UI 上肉眼验证到（逻辑为声明式 SwiftUI，已写入但未跑到触发态）。
- `selectionOnly` / `onCategorySelected` 经查当前无任何外部调用方（既有 dead param，非本轮引入），未清理。
- v1.1b（算法）、v1.2（预选 + margin）未开始。
