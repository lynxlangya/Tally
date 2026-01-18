# 10 过期回收站自动清理（P1）

## 背景/目的
软删超过 7 天应自动永久删除，避免数据长期堆积。

## 具体步骤
1. 在 `JustOneApp` 或 `AppRootView` 监听 `ScenePhase` 进入前台/启动事件。
2. 调用 `BillRepository.purgeExpired(asOf:)` 或 `TrashRepository.clearAll` 的过期逻辑。
3. 支持注入 `nowProvider` 便于测试。

## 验收标准
- ✅ 过期账单在进入前台后被清理。
- ✅ 回收站列表不再展示过期数据。
- ✅ 不影响未过期账单。

## 影响范围
- `JustOne/JustOneApp.swift` 或 `JustOne/Features/AppRootView.swift`
- `JustOne/Data/Repositories/CoreDataBillRepository.swift`

## 风险与回滚
- 风险：时间判断错误导致误删。
- 回滚：临时关闭自动清理，保留手动清理入口。
