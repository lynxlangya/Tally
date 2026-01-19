# 6 BillsList 真实数据接入（P0）

## 背景/目的

当前 BillsList 统计页使用 Mock 数据，无法反映真实账单。该任务将接入 Repository 数据源，保证统计结果与真实账单一致。

## 具体步骤

1. 在 `BillsListViewModel` 中移除强制 `useMockData` 分支或改为仅 Debug 生效。
2. 使用 `BillRepository` 与 `CategoryRepository` 拉取真实数据并填充 `allBills`、`categoriesById`。
3. 在数据拉取完成后调用 `applyFilters()`，确保汇总/趋势/排行数据更新。
4. 按 `deletedAt == nil` 过滤账单，并保持 occurredLocalDate 口径不变。
5. 在 `BillsListView` 中订阅 `billDidChange` 通知并触发 `load()`。

## 验收标准

- ✅ BillsList 统计数据来自真实账单而非 Mock（可用新增/编辑账单验证）。
- ✅ 汇总/趋势/排行与 Home 列表数据口径一致。
- ✅ `useMockData` 不再影响正式运行路径。

## 影响范围

- `JustOne/Features/BillsList/`
- `JustOne/Core/Utilities/DayKeyFormatter.swift`

## 风险与回滚

- 风险：真实数据为空导致统计区域显示空态。
- 回滚：保留 Mock 分支为 Debug 预览路径（非正式运行）。
