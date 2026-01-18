# 12 时区切换展示策略补齐（P1）

## 背景/目的
当前记录了 tzId/tzOffset，但未明确“系统时区切换后的展示与统计策略”。需要给出最小可行方案并落实到展示逻辑。

## 具体步骤
1. 明确策略：分组/统计始终使用 `occurredLocalDate`（创建时快照），展示时间使用账单的 tzId/tzOffset。
2. 抽取展示时间工具函数（替代分散的 DateFormatter 逻辑）。
3. 在 BillsList/ Home 的时间显示处统一使用该工具。
4. 增加简单测试或 Debug 验证入口（切换时区后分组不变）。

## 验收标准
- ✅ 切换系统时区后历史账单分组不漂移。
- ✅ 展示时间使用账单时区快照。
- ✅ 相关函数有单一入口（可复用、可测试）。

## 影响范围
- `JustOne/Core/Utilities/TimePolicy.swift`
- `JustOne/Features/Home/`
- `JustOne/Features/BillsList/`

## 风险与回滚
- 风险：展示时间与用户当前时区预期不一致。
- 回滚：保留“按当前系统时区展示”的备选路径。
