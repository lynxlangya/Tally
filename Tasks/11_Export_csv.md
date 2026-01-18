# 11 CSV 导出最小可用（P1）

## 背景/目的
MVP 需要具备基础导出能力，优先提供 CSV 导出并支持分享。

## 具体步骤
1. 实现 `ExportService.exportCSV(range:)`，基于 `BillRepository` 生成 CSV 字符串并写入临时文件。
2. 字段顺序：时间、类型、分类、金额、备注；金额两位小数。
3. 新增导出页面或在 Settings “导出数据”入口中调用导出。
4. 使用系统分享面板导出文件。

## 验收标准
- ✅ 可导出当前月 CSV 文件并成功分享。
- ✅ 文件名符合 `Bill_YYYYMMDD-YYYYMMDD.csv` 规则。
- ✅ CSV 字段顺序与金额格式正确。

## 影响范围
- `JustOne/Services/ExportService.swift`
- `JustOne/Features/Settings/`
- `JustOne/Data/Repositories/`（读取账单/分类）

## 风险与回滚
- 风险：数据量较大时导出耗时。
- 回滚：先限制导出范围（本月）。
