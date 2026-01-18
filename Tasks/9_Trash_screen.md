# 9 回收站页面与操作（P0）

## 背景/目的
软删完成后需要提供回收站入口以便恢复或永久删除，满足 7 天撤销要求。

## 具体步骤
1. 新建 `TrashView` + `TrashViewModel`，使用 `TrashRepository.list()` 获取已删除账单。
2. 列表展示金额/分类/日期/备注，并显示剩余天数（trashUntil - now）。
3. 提供恢复、永久删除、清空全部操作。
4. 在 Profile 或 Settings 增加“回收站”入口。

## 验收标准
- ✅ 回收站可展示已删除账单及剩余天数。
- ✅ 恢复后账单回到正常列表。
- ✅ 永久删除后账单不可再查询到。

## 影响范围
- `JustOne/Features/`（新增 Trash 模块）
- `JustOne/Data/Repositories/CoreDataTrashRepository.swift`
- `JustOne/Features/Profile/ProfileView.swift` 或 `JustOne/Features/Settings/SettingsView.swift`

## 风险与回滚
- 风险：操作不可撤销带来数据丢失。
- 回滚：保留二次确认弹窗或仅开放“恢复”。
