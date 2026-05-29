# [P1] 账本页日期筛选重构：周期导航 + 真·自定义区间

> 关联：补齐 #008 刻意推迟的时间逻辑 · 建议分支 `issue/018-billslist-date-filter` · 工作量 M
> 范围：仅 `Tally/Features/BillsList`，首页不动。

## 背景 / Why

#008 当初只重建了统计页的 UI（汇总卡 / sparkline / 分类排名 / 明细），并在文档里**明确**把时间逻辑列为禁区：

- `Don't change the time-range filtering logic in BillsListViewModel.`（008 第 60 行）
- `For "custom" range, the date picker is out of scope; placeholder button is acceptable.`（008 第 64 行）

因此遗留三处硬伤，本任务集中清偿：

1. **🔴 选「周/月/年」无法翻页**。`anchorDate` 默认今天，唯一改它的入口是 `.custom` 模式下的日历按钮（[BillsListView.swift:167-180](../../Tally/Features/BillsList/BillsListView.swift)）。选「月」只能看本月，回看不了历史——统计页的核心缺失。
2. **🔴 「自定义」名不副实**。`.custom` 实为 `[anchor−29, anchor]` 近 30 天滚动窗口（[BillsListViewModel.swift:317-320](../../Tally/Features/BillsList/BillsListViewModel.swift)），日历按钮只能选一个终点日，无法选 `[start, end]`。
3. **🟠 半成品 / 死代码**：右上角搜索按钮是空 `action`；环比 `summaryChange` 算了却没渲染（仅死代码 `BillsListSummaryView` 引用）；`BillsListHeader`、`TimeRangeBar`、`BillsListSummaryView`、`BillsListTrendSection`、`BillsListRankingView` 全部零引用。

## 决策（已与产品对齐）

| 维度 | 结论 |
|---|---|
| 范围 | 仅账本页；首页保持「本月速览」定位不变 |
| 粒度 | 周 / 月 / 年 / 自定义（**去掉季度**） |
| 自定义 | 真正的 起始日–结束日 双选，不再是近 30 天 |
| 锚点记忆 | 切 tab 保持当前选择；重启 App 回到「本期」 |

## 交互模型 / Do

顶部改为 **粒度 Segmented + 期间导航条** 双层结构（钱迹 / iCost / MoneyWiz 通用范式）：

```
 账本                                   [ 支出 | 收入 ]   ← 类型(保留)
┌───────────────────────────────────────────────┐
│    周      月      年      自定义                 │   ← 粒度 Segmented(复用 Segmented)
└───────────────────────────────────────────────┘
            ‹      2026年5月      ›                    ← 期间导航(新增·核心)
                 较上月 ↓ 12%                          ← 环比(接已算好的 summaryChange)
```

1. **粒度切换**：复用 `Segmented`，options 周/月/年/自定义，size `.sm`。
2. **期间导航条**（新增核心控件）：
   - `‹` 左箭头 → 上一期（上月/上周/去年）。
   - `›` 右箭头 → 下一期；**已是本期时置灰禁用**（不允许翻到未来）。
   - **中间标题可点** → 弹「快速跳转」选择器。
3. **跳转选择器**按粒度分流：
   - 月 → 年月滚轮（`YYYY年` + `MM月`）。
   - 年 → 年份列表（直接复用 VM 现成的 `availableYears`）。
   - 周 → 单日期选择，落到所在自然周。
   - 自定义 → 起始日 / 结束日 **双选** sheet（替换现有 `StatsDatePickerSheet`）。
4. **标题文案**（比「2026 年第 21 周」直观）：

   | 粒度 | 标题示例 | 区间口径 |
   |---|---|---|
   | 周 | `5月12日–5月18日` | ISO 周（周一→周日） |
   | 月 | `2026年5月` | 自然月 |
   | 年 | `2026年` | 自然年 |
   | 自定义 | `5月1日–5月20日` | 用户选定 `[start, end]` |

5. **环比上 UI**：把已有 `summaryChange` 渲染进 `StatsSummaryCard`，涨↑跌↓配色。
6. **滑动翻页**（可选 / 二期）：明细列表左右滑动 = 翻页，与箭头等价。

## 逻辑 / 状态机

```swift
enum TimeRange: String, CaseIterable { case week, month, year, custom }   // 删除 quarter

// 非 custom 用 anchorDate；custom 用区间双值
@Published var anchorDate: Date
@Published var customStart: Date
@Published var customEnd: Date

// 翻页 API
func goPrevious()                 // anchorDate ±1 week/month/year
func goNext()
var canGoNext: Bool               // anchorDate 所在期 < 今天所在期 → 右箭头禁用
```

- `dayKeyRange(for:)`：`.custom` 直接返回 `[customStart, customEnd]` 的 dayKey；其余粒度逻辑不变（已正确）。
- `summaryPrefix` 去「本」化：改中性「合计」；环比文案动态判断——锚点==本期才说「较上月」，否则「环比上一期」。
- **补 `nowProvider: () -> Date` 注入**：现 VM 直接用 `Date()`（init 无 nowProvider，与 CLAUDE.md 描述不符），未来期禁用 / 本期判断需要可注入的「今天」才能写单测。

## 边界口径（写代码时钉死）

- **未来期**：`canGoNext` 据「锚点所在期 < 今天所在期」判定，右箭头禁用。
- **自定义区间**：`customEnd ≥ customStart`（选反自动 swap）；`customEnd` 不晚于今天；跨度无硬上限，UI 给提示。
- **周边界**：沿用现有 `calendar`（`firstWeekday=2`、`minimumDaysInFirstWeek=4`），避免跨年周漂移。
- **筛选口径不动**：一律以 `occurredLocalDate` 分组筛选（CLAUDE.md 强约束），不碰 `TimePolicy` / `DayKeyFormatter`。

## 涉及文件 / Files

**Modify**
- `Tally/Features/BillsList/BillsListView.swift`（重写 header + rangeBar，接入导航条）
- `Tally/Features/BillsList/BillsListViewModel.swift`（翻页 API、custom 区间、nowProvider、去 quarter）
- `Tally/Features/BillsList/BillsListViewModel+Models.swift`（`TimeRange` 删 quarter、文案）
- `Tally/Features/BillsList/BillsListTrendBuilder.swift`（同步删除 quarter 分支）
- `Tally/Features/BillsList/BillsListLayout.swift`（导航条 / 双日期 sheet 尺寸）

**新增**
- 期间导航条组件（`‹ 标题 ›`）
- 跳转选择器 sheet（年月滚轮 / 年份列表 / 周日期 / 自定义双日期），替换 `StatsDatePickerSheet`

**Delete（已确认零引用）**
- `Views/BillsListHeaderView.swift`、`Views/BillsListTimeRangeBar.swift`、`Views/BillsListSummaryView.swift`、`Views/BillsListTrendSection.swift`、`Views/BillsListRankingView.swift`

## 分阶段实施

- **P0 — 解决最大痛点**：粒度去季 + 期间导航条（翻页）+ 标题跳转（月/年/周）。
- **P1 — 真·自定义**：双日期区间选择，替换 `StatsDatePickerSheet`。
- **P2 — 收尾**：环比上 UI + 删死代码 + 移除假搜索按钮 + 文案去「本」化。
- **P3 — 可选**：滑动翻页手势。

## 验收 / Done when

- [ ] 周/月/年可向历史翻页，右箭头在本期禁用
- [ ] 点标题可直接跳转到指定期（月/年/周各自的选择器）
- [ ] 自定义=真正起止日，`end ≥ start`、不晚于今天
- [ ] 环比展示正确；翻页后文案不再硬写「本月」
- [ ] 5 个死代码文件删除、假搜索按钮移除
- [ ] `xcodebuild build` + `test` 通过
- [ ] 补单测：注入 `nowProvider` 验证 `canGoNext` / 翻页区间 / 跨年周边界 `occurredLocalDate` 不漂移

## Don't

- 不动 `TimePolicy` / `DayKeyFormatter` / `occurredLocalDate` 筛选口径
- 不引入图表库（趋势仍用内置 `Sparkline`）
- 不动首页、不加回收站 / 导出入口
