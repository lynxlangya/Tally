# 7 BillsList 明细列表补齐（P0）

## 背景/目的

当前 BillsList 缺少账单明细列表，用户无法在统计页查看/编辑具体条目。该任务补齐分组列表与编辑入口。

## 具体步骤

1. 在 `BillsListView` 中新增“明细列表”区域，使用 `dayKeys` + `groupedRows` 渲染分组。
2. 每个分组展示日期标题（基于 occurredLocalDate），组内使用 `JOListRow`。
3. 点击条目时通过 `billRecord(for:)` 打开 QuickEntry 编辑。
4. 明细列表与时间范围/支收切换联动刷新。

## 验收标准

- ✅ BillsList 展示按日分组的账单列表。
- ✅ 点击列表条目可进入编辑并更新。
- ✅ 时间范围或支/收切换后列表同步刷新。

## 影响范围

- `JustOne/Features/BillsList/`
- `JustOne/Core/UIComponents/JOListRow.swift`

## 风险与回滚

- 风险：新增滚动区域导致布局拥挤。
- 回滚：先将明细列表置于折叠区或单独页面。
