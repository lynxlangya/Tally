# [P2] 收敛 PersistenceController.preview 的 fatalError

> 关联：上线前只读扫描 P2-5 · 建议分支 `issue/022-preview-fatalerror` · 工作量 S
> 范围：`Tally/Data/PersistenceController.swift`。
> ⚠️ 该文件在 `000_PLAN.md` 属 UI 重构禁区；但**本批是发布整改，允许按本 issue 触碰**——仅改下述 preview 闭包，不动实时启动逻辑。

## 背景 / Why

`PersistenceController.preview`（SwiftUI 预览 / `.preview` 环境用）在 seeding 失败时 `fatalError`，代码注释本身就写着"不应在 shipping 用 fatalError"。实时启动路径已做优雅降级（`startupState.markFailed(...)`），不受影响；但该闭包未 `#if DEBUG` 包裹，属可清理项。

## 证据 / Evidence

- preview 内 fatalError：[PersistenceController.swift:28](../../Tally/Data/PersistenceController.swift)（位于 `static let preview` 闭包，line 17 起；`inMemory:true, runsStartupSeed:false`）。
- 实时启动是优雅降级，**不是**崩溃路径：同文件 store 加载失败 → `markFailed`（约 :86-90），seed/migration 失败 → `markFailed`（约 :112-116）。
- `.preview` 在 Release 不可达：唯一运行时入口 `-tallyUsePreviewData` 在 [TallyApp.swift:106-110](../../Tally/TallyApp.swift) 是 `#if DEBUG`；其余引用仅 `#Preview {}`。

## 复核点 / codex 先确认

- 复核"`.preview` 在 Release 二进制中确实不被调用"（确认 `AppEnvironment.preview` 仅被 `#if DEBUG` / `#Preview` 引用）：
  ```bash
  grep -rn "\.preview\b\|AppEnvironment.preview\|PersistenceController.preview" Tally Shared
  ```
- 若确认仅预览可达 → 本条纯属清理，低优先；可改也可标记 wontfix。

## 修复 / Do（择一）

- 方案 A（最小）：把整个 `static let preview` 闭包用 `#if DEBUG ... #endif` 包裹（preview/预览本就只在 DEBUG 用）。
- 方案 B：把 `fatalError(...)` 换成 `assertionFailure(...)` + 返回一个空的 in-memory 容器，避免编译进 release 的 `fatalError` 符号。

二选一即可，**不要改实时启动的 `init` / `markFailed` 路径**。

## 验收 / Done when

- [ ] preview 闭包不再在 release 路径残留裸 `fatalError`（DEBUG 包裹或改 assertionFailure）
- [ ] 实时启动状态机（loading/ready/failed）逻辑零改动
- [ ] `xcodebuild build` + `xcodebuild test` 通过；SwiftUI 预览仍可用

## Don't

- 不动 `init(...)` 里的 store 加载 / seed / `FileProtectionType.complete` / `markReady/markFailed`。
- 不把 `.preview` 行为带进 `.live`。
