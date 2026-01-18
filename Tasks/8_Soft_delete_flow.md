# 8 软删联动（Home/BillsList）（P0）

## 背景/目的
当前删除仅停留在确认弹窗，未执行软删。该任务补齐软删逻辑，符合“7 天可撤销”要求。

## 具体步骤
1. 在 `HomeView` 删除确认后调用 `BillRepository.softDelete`（写入 deletedAt/trashUntil）。
2. BillsList 明细列表新增滑动删除入口，调用相同软删逻辑。
3. 删除完成后发送 `billDidChange` 或直接触发列表刷新。
4. 软删后列表默认过滤 `deletedAt != nil`。

## 验收标准
- ✅ 删除后账单从 Home/BillsList 消失。
- ✅ CoreData 中 deletedAt/trashUntil 字段被写入。
- ✅ 软删后通过刷新可看到列表同步更新。

## 影响范围
- `JustOne/Features/Home/`
- `JustOne/Features/BillsList/`
- `JustOne/Data/Repositories/CoreDataBillRepository.swift`

## 风险与回滚
- 风险：误删导致数据不可见。
- 回滚：保留确认弹窗与“撤销入口”联动（见回收站任务）。
