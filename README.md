# Tally

Tally 是一个 iOS / iPadOS 单币种记账 App，使用 SwiftUI、Core Data 和 WidgetKit 构建。业务币种固定为 CNY；设置页里的 `¥` / `$` 是显示符号偏好，不改变账单数据的币种语义。

## 当前能力

- 快速记账：新增、编辑、删除支出 / 收入账单，支持分类、日期、备注。
- 首页概览：展示本月收支、结余、近 7 日趋势和最近明细。
- 账本页：支持周 / 月 / 年 / 自定义区间筛选，周期前后导航、快速跳转、分类排行和明细列表。
- 分类管理：支持自定义分类新增、编辑、删除；系统"未分类"负责兜底迁移。
- 定时账单：启动和回到前台时自动补齐到期任务，并做重复写入保护。
- 导入导出：提供本机备份 / 恢复和 CSV 导出入口。
- 外观与语言：支持主题、强调色、语言和金额显示符号设置。
- Widget：提供快速记账入口和月度趋势小组件。

## 技术栈

- Xcode 26.5
- iOS / iPadOS deployment target 26.2
- Swift 5.0
- SwiftUI + Core Data + WidgetKit
- Bundle ID：`com.langya.Tally`
- App Group：`group.com.langya.Tally`
- URL Scheme：`tally://`

## 快速开始

改代码前先读 [AGENTS.md](AGENTS.md)、[CLAUDE.md](CLAUDE.md) 和 [Tally/Core/ArchitectureRules.md](Tally/Core/ArchitectureRules.md)。这三份文档定义了架构边界、常用命令和项目协作口径。

构建 App：

```bash
xcodebuild -project Tally.xcodeproj -scheme Tally \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

运行测试：

```bash
xcodebuild -project Tally.xcodeproj -scheme TallyTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

运行单个测试：

```bash
xcodebuild -project Tally.xcodeproj -scheme TallyTests \
  -destination 'platform=iOS Simulator,name=iPhone 17' test \
  -only-testing:TallyTests/HomeViewModelTests/testDeleteBillRemovesItemFromGroupsAndRepository
```

项目没有 SwiftLint / SwiftFormat 配置，默认使用 Xcode 工具链完成构建和测试。

## 目录结构

```text
Tally/
  App/          App 入口、环境注入和启动任务
  Core/         Domain、主题、通用 UI 组件、时间 / 金额 / Deep Link 等横切能力
  Data/         Core Data stack 和真实 Repository 实现
  Features/     SwiftUI 页面与 ViewModel
  Services/     业务编排服务、导入导出、定时账单、Widget 快照
Shared/         App 与 Widget 共用的模型、格式化和本地化能力
TallyWidgets/   WidgetKit extension
TallyTests/     XCTest 单元测试与测试替身
Tasks/          任务记录与发布风险整改材料
review/         阶段性 review 记录
```

完整依赖图见 [Architecture.mmd](Architecture.mmd) 和 `Architecture.png`。

## 架构约束

- 依赖方向固定为 **Features -> Services -> Repositories -> Data**；`Core` 是横切层，不能反向依赖业务层。
- `Features/` 只能放 SwiftUI View 和 `@MainActor` ViewModel，禁止出现 `import CoreData`、`NSManagedObjectContext`、`NSFetchRequest`、`PersistenceController`。
- 真实 Repository 和 Service 由 `DIContainer` 创建，并通过 `AppEnvironment` 注入；ViewModel 不直接创建实现类。
- 金额业务类型只有 `Money(cents: Int)`，构造值不允许为负数；展示统一走 `MoneyFormatter`，不要用 `String(format:)` 拼金额。
- 时间写入走 `TimePolicy.snapshot(for:)`；分组、筛选、汇总以 `occurredLocalDate` 和 `DayKeyFormatter` 为准。
- 写操作完成后通过 `.billDidChange` 通知刷新 Home、BillsList 和 Widget；Widget 快照写入 App Group。

## 开发提醒

- 新功能优先放在对应 `Features/<Module>/` 下，跨页面复用能力再沉到 `Core/` 或 `Services/`。
- UI 优先使用 `Color.tally*`、`TallyType`、`TallySpacing`、`TallyRadii` 等 token，避免新增散色值和一次性样式。
- 修改账单写入、导入、定时账单或迁移逻辑时，必须确认 Widget 快照和 `.billDidChange` 通知链路。
- 涉及金额、日期、本地化、Widget 或 Repository 行为时，优先补单元测试；UI 变更至少在模拟器里做一次人工回归。
